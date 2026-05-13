//
//  DosageDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/23/24.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class DosageDetailViewModel: ObservableObject {
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var savedDosageTemplates: [SavedDosageTemplate] = []
    @Published private(set) var amountList: [String] = []

    @Published var amountInput: String = ""

    @Published private(set) var alertMessage: String = ""
    @Published  var showAlert: Bool = false
    func onLoad(companyId: String,dosageTemplate:SavedDosageTemplate){
        self.amountList = dosageTemplate.amount ?? []
    }
    
    func updateDosageAmount(companyId: String,dosageTemplate:SavedDosageTemplate,amountList:[String],newAmount:String) async throws {
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
        try await dataService.updateSavedDosageAmount(companyId: companyId, dosageTemplateId: dosageTemplate.id, newArray: sortedAmountArray)
        
        self.amountInput = ""
    }
    
    func DeleteDosageAmount(companyId:String,dosageTemplate:DosageTemplate,amount:String) async throws {
        try? await SettingsManager.shared.removingDosageTemplateAmountArray(companyId: companyId, dosageTemplateId: dosageTemplate.id, amount: amount)
    }

}
struct DosageDetail: View {
    
    init(dataService:any ProductionDataServiceProtocol,dosageTemplate:SavedDosageTemplate?){
        _VM = StateObject(wrappedValue: DosageDetailViewModel(dataService: dataService))
        _dosageTemplate = State(wrappedValue: dosageTemplate)
    }
    @StateObject var VM : DosageDetailViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager
    @State var dosageTemplate:SavedDosageTemplate?
    @State var isSaved:Bool = false
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                content
            }
            .padding(8)
        }
        .navigationTitle("\(dosageTemplate?.name ?? "name")")
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            if !UIDevice.isIPhone {
                dosageTemplate = masterDataManager.selectedDosageTemplate
            }
            if let currentCompany = masterDataManager.currentCompany, let dosageTemplate {
                
                VM.onLoad(companyId: currentCompany.id, dosageTemplate: dosageTemplate)
                    //Set local dosage Template equal to globally selected dosage template
            }
        }
        
        //Watch the globally selected dosage template for changes, to update screen to reflect that
        .onChange(of: masterDataManager.selectedDosageTemplate, perform: { template in
            if !UIDevice.isIPhone {
                dosageTemplate = template
            }
        })
    }
}

struct DosageDetail_Previews: PreviewProvider {
    static var previews: some View {
        DosageDetail(dataService: MockDataService(), dosageTemplate: nil)
    }
}
extension DosageDetail {
    var content: some View {
        VStack{
            if let template = dosageTemplate {
                ZStack{
                    HStack{
                        Spacer()
                        Button(action: {
                            print("Edit Dosage Detail View")
                            isSaved.toggle()
                        }, label: {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                        })
                    }
                }
                VStack{
                    Text("\(template.UOM ?? "UOM")")
                    Text("Rate: \(Double(template.rate ?? "0") ?? 0, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    
                    Text("\(template.strength )")
                    
                    Text("\(template.linkedItemId ?? "UOM")")
                }
                
                HStack{
                    TextField("Input", text: $VM.amountInput)
                        .modifier(PlainTextFieldModifier())
                        .onSubmit {
                            
                            Task{
                                do {
                                    if let currentCompany = masterDataManager.currentCompany, let dosageTemplate {
                                        try await VM.updateDosageAmount(
                                            companyId: currentCompany.id,
                                            dosageTemplate: dosageTemplate,
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
                                    if let currentCompany = masterDataManager.currentCompany, let dosageTemplate {
                                        try await VM.updateDosageAmount(
                                            companyId: currentCompany.id,
                                            dosageTemplate: dosageTemplate,
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
                ForEach(VM.amountList,id: \.self){ amount in
                    Text("\(amount)")
                        .padding(10)
                }
                
            } else {
                Text("No Dosage Template Selected")
            }
        }
    }
}
