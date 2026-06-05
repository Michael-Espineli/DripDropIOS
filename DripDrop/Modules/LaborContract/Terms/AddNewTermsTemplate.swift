//
//  AddNewTermsTemplate.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/6/25.
//

import SwiftUI

struct AddNewTermsTemplate: View {
    init(dataService: some ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss
    
    private let dataService: any ProductionDataServiceProtocol
    
    @State private var templateName: String = ""
    @State private var templateDescription: String = ""

    @State private var terms: [ContractTerms] = [ContractTerms(id: UUID().uuidString, description: "")]
    @State private var isSubmitting: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var dismissOnSuccess: Bool = false
    

    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Info")) {
                    TextField("Enter template name", text: $templateName)
                        .autocapitalization(.words)
                    TextField("Enter template Description", text: $templateDescription)
                        .autocapitalization(.words)
                }
                HStack{
                    Spacer()
                    Button(action: {
                        terms.append(ContractTerms(id: UUID().uuidString, description: ""))
                    }) {
                        Label("Add Term", systemImage: "plus.circle")
                    }
                }
                Section(header: Text("Contract Terms")) {
                    ForEach(terms.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Term Description", text: $terms[index].description)
                                .autocapitalization(.sentences)
                                .disableAutocorrection(false)
                        }
                        .padding(.vertical, 4)
                    }
                    if terms.count > 1 {
                        HStack {
                            Spacer()
                            Button(role: .destructive, action: {
                                terms.removeLast()
                            }) {
                                Label("Remove Last Term", systemImage: "minus.circle")
                            }
                        }
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await submitTemplate()
                        }
                    } label: {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Submit")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("New Terms Template")
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") {
                    if dismissOnSuccess {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitTemplate() async {
        guard let currentCompany = masterDataManager.currentCompany else {
            alertMessage = "No company selected. Please select a company before adding a terms template."
            showAlert = true
            return
        }
        
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = templateDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            alertMessage = "Please enter a valid template name."
            showAlert = true
            return
        }
        
        // At least one term with non-empty title
        let validTerms = terms.filter { !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if validTerms.isEmpty {
            alertMessage = "Please provide at least one contract term with a title."
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        let newTemplateId = "terms_" + UUID().uuidString
        // Assuming TermsTemplate has id, name, dateCreated and other fields optional or defaulted
        let newTemplate = TermsTemplate(
            id: newTemplateId,
            name: trimmedName,
            description: trimmedDescription
            // Add other required properties with defaults if needed
        )
        
        do {
            try await dataService.addTermsTemplate(companyId: currentCompany.id, termsTemplate: newTemplate)
            
            for term in validTerms {
                let newTermId = "term_" + UUID().uuidString
                let newTerm = ContractTerms(
                    id: newTermId,
                    description: term.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Add other properties if needed, else defaults
                )
                try await dataService.addTermsToTermsTemplate(
                    companyId: currentCompany.id,
                    termsTemplateId: newTemplate.id,
                    terms: newTerm
                )
            }
            
            alertMessage = "Terms template and its contract terms were successfully added."
            dismissOnSuccess = true
        } catch {
            alertMessage = "Failed to add terms template: \(error.localizedDescription)"
        }
        
        showAlert = true
        isSubmitting = false
    }
}

//#Preview {
//    // Mock implementations to avoid build errors
//    class MockDataService: ProductionDataServiceProtocol {
//        func addTermsTemplate(companyId: String, termsTemplate: TermsTemplate) async throws {}
//        func addTermsToTermsTemplate(companyId: String, termsTemplateId: String, terms: ContractTerms) async throws {}
//    }
//    class MockMasterDataManager: MasterDataManager, ObservableObject {
//        override init() {
//            super.init()
//            self.currentCompany = Company(id: "company_1", name: "Mock Company")
//        }
//    }
//    
//    AddNewTermsTemplate(dataService: MockDataService())
//        .environmentObject(MockMasterDataManager())
//}
