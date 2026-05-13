//
//  EditTermsTemplate.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import SwiftUI
@MainActor

final class EditTermsTemplateViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    let termsTemplate: TermsTemplate

    init(dataService:any ProductionDataServiceProtocol, termsTemplate: TermsTemplate){
        self.dataService = dataService
        self.termsTemplate = termsTemplate
    }
    @Published private(set) var selectedTerms: [ContractTerms] = []
    @Published var editableTerms: [ContractTerms] = []
    
    @Published var newTermText: String = ""
    @Published var name: String = ""
    @Published var description: String = ""

    func onLoad(companyId:String?) {
        Task{
            do {
                if let companyId {
                    self.name = termsTemplate.name
                    self.description = termsTemplate.description
                    let terms = try await dataService.getTermsByTermsTemplate(companyId: companyId, termsTemplateId: termsTemplate.id)
                    self.selectedTerms = terms
                    self.editableTerms = terms
                }
            } catch {
                print("[][] Error: \(error)")
            }
        }
    }
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addNewTerm() {
        let trimmed = newTermText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        editableTerms.append(ContractTerms(id: UUID().uuidString, description: trimmed))
        newTermText = ""
    }


    func saveChanges(companyId: String?) {
        guard let companyId else {return}
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                //Update Template Object
                try await dataService.updateTermsTemplateName(companyId: companyId, templateId: termsTemplate.id, templateName: trimmedName)
                try await dataService.updateTermsTemplateDescription(companyId: companyId, templateId: termsTemplate.id, templateDescription: trimmedDescription)

                //Update Terms List
                //Find New Terms //Find Removed Terms
                let oldDict = Dictionary(uniqueKeysWithValues: selectedTerms.map { ($0.id, $0) })
                let newDict = Dictionary(uniqueKeysWithValues: editableTerms.map { ($0.id, $0) })
                
                let oldIds = Set(oldDict.keys)
                let newIds = Set(newDict.keys)
                
                let removedItems = oldIds
                    .subtracting(newIds)
                    .compactMap { oldDict[$0] }
                let addedItems = newIds
                    .subtracting(oldIds)
                    .compactMap { newDict[$0] }
                for item in addedItems {
                    try await dataService.addTermsToTermsTemplate(
                        companyId: companyId,
                        termsTemplateId: termsTemplate.id,
                        terms: item
                    )
                    print("[EditTermsTemplateViewModel][saveChanges] Added term: \(item.id)")

                }
                for item in removedItems {
                    
                    try await dataService.deleteTerms(
                        companyId: companyId,
                        termsTemplateId: termsTemplate.id,
                        termsId: item.id
                    )
                    print("[EditTermsTemplateViewModel][saveChanges] Removed term: \(item.id)")
                }
            } catch {
                // You can add error handling UI here if desired
                print("[EditTermsTemplateViewModel][saveChanges]Failed to update terms template: \(error)")
            }
        }
    }
}

struct EditTermsTemplate: View {
    // Init
    init(dataService: any ProductionDataServiceProtocol, termsTemplate: TermsTemplate) {
        _VM = StateObject(wrappedValue: EditTermsTemplateViewModel(dataService: dataService,termsTemplate: termsTemplate))
        _termsTemplate = State(wrappedValue: termsTemplate)
    }

    // Objects
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject var VM: EditTermsTemplateViewModel

    // Variables
    @State var termsTemplate: TermsTemplate

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            VStack{
                HStack{
                    Button("Cancel") { dismiss() }
                    Spacer()
                    Button("Save") { VM.saveChanges(companyId: masterDataManager.currentCompany?.id) }
                        .disabled(!VM.canSave)
                }
                .padding(.top,20)
                Form {
                    Section(header: Text("Template")) {
                        TextField("Name", text: $VM.name)
                            .textInputAutocapitalization(.words)
                        
                        TextField("Description", text: $VM.description)
                    }
                    Section(header: Text("Terms"), footer: footerNote) {
                        if VM.editableTerms.isEmpty {
                            Text("No terms yet. Add one below.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(VM.editableTerms.indices, id: \.self) { index in
                                HStack {
                                    TextField("Term", text: Binding(
                                        get: { VM.editableTerms[index].description },
                                        set: { VM.editableTerms[index].description = $0 }
                                    ))
                                    Button(role: .destructive) {
                                        VM.editableTerms.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .onDelete(perform: delete)
                        }
                        
                        HStack {
                            TextField("New term", text: $VM.newTermText)
                            Button("Add") { VM.addNewTerm() }
                                .disabled(VM.newTermText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
//        .navigationTitle("Edit Terms Template")
//        .toolbar {
//            ToolbarItem(placement: .cancellationAction) {
//                Button("Cancel") { dismiss() }
//            }
//            ToolbarItem(placement: .confirmationAction) {
//                Button("Save") { VM.saveChanges(companyId: masterDataManager.currentCompany?.id) }
//                    .disabled(!VM.canSave)
//            }
//        }
        .onAppear {
            // Ensure VM has any needed context from master data if applicable
  
            VM.onLoad(companyId: masterDataManager.currentCompany?.id)
        }
    }

    private var footerNote: some View {
        Text("Edit, add, or remove terms. Changes will update this template.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
    func delete(at offsets: IndexSet) {
        VM.editableTerms.remove(atOffsets: offsets)
    }

}

//#Preview {
//    EditTermsTemplate(dataService: PreviewDataService(), termsTemplate: .init(id: UUID(), name: "Sample", terms: [LaborContractTerm(text: "Net 30")]))
//        .environmentObject(MasterDataManager.preview)
//}
