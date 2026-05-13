//
//  ReadingsDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI
@MainActor
final class ReadingsDetailViewModel: ObservableObject {
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var savedReadingTemplates: [SavedReadingsTemplate] = []
    @Published var amountInput: String = ""
    @Published private(set) var amountList: [String] = []

    @Published private(set) var alertMessage: String = ""
    @Published  var showAlert: Bool = false
    
    func onLoad(companyId: String,readingTemplate:SavedReadingsTemplate) {
        self.amountList = readingTemplate.amount
        print("")
        print("[ReadingsDetailViewModel][updateReadingAmount] readingTemplate \(readingTemplate)")
    }
    
    func updateReadingAmount(companyId: String,readingTemplate:SavedReadingsTemplate,amountList:[String],newAmount:String) async throws {
        print("")
        print("[ReadingsDetailViewModel][updateReadingAmount] readingTemplate \(readingTemplate.id)")
        if !newAmount.isNumber{
            //Throw Error For not Number
            self.alertMessage = "Amount Not Number"
            self.showAlert.toggle()
            return
        }
        var newAmountList = amountList
        newAmountList.append(String(newAmount).trimmingCharacters(in: .whitespacesAndNewlines))
        //Reorder
        let sortedAmountArray = newAmountList.sorted {
            (Int($0) ?? 0) < (Int($1) ?? 0)
        }
        //Update View
        self.amountList = sortedAmountArray
        //Publish
        print("")
        print("[ReadingsDetailViewModel][updateReadingAmount] amountList \(amountList)")
        try await dataService.updateSavedReadingAmount(companyId: companyId, readingTemplateId: readingTemplate.id, newArray: sortedAmountArray)
        print("[ReadingsDetailViewModel][updateReadingAmount] Successfull")
        self.amountInput = ""
    }
    
    func DeleteReadingAmount(companyId:String,readingTemplate:ReadingsTemplate,amount:String) async throws {
        try? await SettingsManager.shared.removingReadingTemplateAmountArray(companyId: companyId, readingTemplateId: readingTemplate.id, amount: amount)
    }
}
struct ReadingsDetail: View {
    
    init(dataService:any ProductionDataServiceProtocol,readingTempalte:SavedReadingsTemplate?){
        _VM = StateObject(wrappedValue: ReadingsDetailViewModel(dataService: dataService))
        _readingTemplate = State(wrappedValue: readingTempalte)
    }
    @StateObject var VM : ReadingsDetailViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var readingTemplate:SavedReadingsTemplate?
    @State var isSaved:Bool = false

    var body: some View {
        ZStack{
                Color.listColor.ignoresSafeArea()
            ScrollView{
                content
            }
            .padding(8)
        }
        .navigationTitle("\(readingTemplate?.name ?? "name")")
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            if !UIDevice.isIPhone {
                readingTemplate = masterDataManager.selectedReadingsTemplate
            }
            if let currentCompany = masterDataManager.currentCompany, let readingTemplate {
                VM.onLoad(companyId: currentCompany.id, readingTemplate: readingTemplate)
                    //Set local readingTemplate equal to globally selected reading template
            }
        }
        //Watch the globally selected reading tempalte for changes, to update screen to reflect that
        .onChange(of: masterDataManager.selectedReadingsTemplate, perform: { template in
            if !UIDevice.isIPhone {
                readingTemplate = template
            }
        })
    }
}

struct ReadingsDetail_Previews: PreviewProvider {
    static var previews: some View {
        ReadingsDetail(dataService: MockDataService(), readingTempalte: nil)
    }
}
extension ReadingsDetail {
    var content: some View {
        VStack{
            if let template = readingTemplate {
                ZStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            print("Edit Reading Detail View")
                            isSaved.toggle()
                        }, label: {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                        })
                    }
                }
                VStack{
                    Text("\(template.UOM)")
                    Text("\(template.name)")
                    
                    Text("\(template.linkedDosage)")
                    
                    Text("\(template.highWarning)")
                    
                    Text("\(template.lowWarning)")
                }
                
                HStack{
                    TextField("Input", text: $VM.amountInput)
                        .modifier(PlainTextFieldModifier())
                        .onSubmit {
                            Task{
                                do {
                                    if let currentCompany = masterDataManager.currentCompany,
                                       let readingTemplate {
                                        try await VM.updateReadingAmount(
                                            companyId: currentCompany.id,
                                            readingTemplate: readingTemplate,
                                            amountList: VM.amountList,
                                            newAmount: VM.amountInput
                                        )
                                    }
                                } catch {
                                    print("[DosageDetailView][OnSubmit] Error:UpdateDosageAmount \(error)")
                                }
                            }
                            
                        }
                    Button(
                        action: {
                            Task{
                                do {
                                    if let currentCompany = masterDataManager.currentCompany,
                                       let readingTemplate {
                                        try await VM.updateReadingAmount(
                                            companyId: currentCompany.id,
                                            readingTemplate: readingTemplate,
                                            amountList: VM.amountList,
                                            newAmount: VM.amountInput
                                        )
                                    }
                                } catch {
                                    print("[DosageDetailView][Button] Error:UpdateDosageAmount \(error)")
                                }
                            }
                            
                        },
                        label: {
                        Image(systemName: "plus.app.fill")
                            .foregroundColor(Color.accentColor)
                            .font(.headline)
                    })
                }
                ForEach(VM.amountList ,id: \.self){ amount in
                    Text("\(amount)")
                        .padding(10)
                }
                    
                
            } else {
                Text("No Reading Template Selected")
            }
        }
    }
}
