import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/michaelespineli/Desktop/DripDrop/DripDrop/Modules/New Group5/Views/CreateBulkInvoice.swift", line: 1)
//
//  CreateBulkInvoice.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

struct CreateBulkInvoice: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var VM : CreateBulkInvoiceViewModel

    init(dataService:any ProductionDataServiceProtocol,associatedBusiness:AssociatedBusiness){
        _VM = StateObject(wrappedValue: CreateBulkInvoiceViewModel(dataService: dataService))
        _associatedBusiness = State(wrappedValue: associatedBusiness)
    }
    
    @State var associatedBusiness: AssociatedBusiness
    var body: some View {
        ZStack{
            Color.darkGray.ignoresSafeArea()
            ScrollView{
                header
                info
            }
            .background(Color.listColor.ignoresSafeArea())
            footer
        }
        .navigationTitle(__designTimeString("#6239_0", fallback: "Create Bulk Invoice"))
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id,associatedBusiness:associatedBusiness)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: VM.selectedLaborContracts, perform: { contracts in
            VM.onChangeOfContracts(contracts: contracts)
        })
        .onChange(of: VM.selectedRecurringLaborContracts, perform: { contracts in
            VM.onChangeOfRecurringContracts(recurringContracts: contracts)
        })
    }
}

#Preview {
    @StateObject var masterDataManager : MasterDataManager = MasterDataManager()
    @StateObject var dataService : ProductionDataService = ProductionDataService()

    CreateBulkInvoice(
        dataService: MockDataService(),
        associatedBusiness: MockDataService.mockAssociatedBusiness
    )
    .environmentObject(masterDataManager)
    .environmentObject(dataService)
}
extension CreateBulkInvoice {
    var header: some View {
        VStack{
            HStack{
                Text(associatedBusiness.companyName)
                Spacer()
            }
 
        }
        .padding(__designTimeInteger("#6239_1", fallback: 8))
        .foregroundColor(Color.poolWhite)
        .background(Color.darkGray)
    }
    var info: some View {
        VStack{
            Text(__designTimeString("#6239_2", fallback: "Last Invoice Sent"))
            HStack{
                Spacer()
                HStack{
                    Text(__designTimeString("#6239_3", fallback: "Invoice History"))
                    Image(systemName: __designTimeString("#6239_4", fallback: "chevron.right"))
                }
                    .modifier(RedLinkModifier())
            }
            if VM.selectedRecurringLaborContracts.isEmpty || VM.selectedLaborContracts.isEmpty {
                VStack{
                    Text(__designTimeString("#6239_5", fallback: "Invoice Information"))
                    HStack{
                        Text(__designTimeString("#6239_6", fallback: "Total:"))
                        Spacer()
                        Text("\(Double(VM.totalAmount)/__designTimeInteger("#6239_7", fallback: 100), format: .currency(code: __designTimeString("#6239_8", fallback: "USD")).precision(.fractionLength(__designTimeInteger("#6239_9", fallback: 2))))")

                    }
                }
                .padding(__designTimeInteger("#6239_10", fallback: 8))
            }
            contractsNotBilled
            recurringContractsNotBilled
        }
    }
    var contractsNotBilled: some View {
        VStack{
            Text("Contracts Not Billed For - \(String(VM.laborContracts.count))")
                .font(.headline)
            HStack{
                Button(action: {
                    if VM.selectedLaborContracts == VM.laborContracts {
                        VM.selectedLaborContracts = []
                    } else {
                        VM.selectedLaborContracts = VM.laborContracts
                    }
                }, label: {
                    
                    if VM.selectedLaborContracts == VM.laborContracts {
                        Image(systemName: __designTimeString("#6239_11", fallback: "checkmark.square.fill"))
                    } else {
                        Image(systemName: __designTimeString("#6239_12", fallback: "square"))}
                })
                Spacer()
                Text("Selected \(VM.selectedLaborContracts.count)")
            }
            .padding(__designTimeInteger("#6239_13", fallback: 8))
            ForEach(VM.laborContracts){ contract in
                HStack{
                    Button(action: {
                        if VM.selectedLaborContracts.contains(where: {$0.id == contract.id}){
                            VM.selectedLaborContracts.remove(contract)
                        } else {
                            VM.selectedLaborContracts.append(contract)
                        }
                    }, label: {
                        if VM.selectedLaborContracts.contains(where: {$0.id == contract.id}){
                            Image(systemName: __designTimeString("#6239_14", fallback: "checkmark.square.fill"))
                        } else {
                            Image(systemName: __designTimeString("#6239_15", fallback: "square"))
                        }
                    })
                    Spacer()
                    Text("\(contract.customerName) \(Double(contract.rate)/__designTimeInteger("#6239_16", fallback: 100), format: .currency(code: __designTimeString("#6239_17", fallback: "USD")).precision(.fractionLength(__designTimeInteger("#6239_18", fallback: 2))))")
                }
            }
        }
        .padding(__designTimeInteger("#6239_19", fallback: 8))
    }
    
    var recurringContractsNotBilled: some View {
        VStack{
            Text("Recurring Contracts Not Billed For - \(String(VM.recurringLaborContracts.count))")
                .font(.headline)
            HStack{
                Button(action: {
                    if VM.selectedRecurringLaborContracts == VM.recurringLaborContracts {
                        VM.selectedRecurringLaborContracts = []
                    } else {
                        VM.selectedRecurringLaborContracts = VM.recurringLaborContracts
                    }
                }, label: {
                    
                    if VM.selectedRecurringLaborContracts == VM.recurringLaborContracts {
                        Image(systemName: __designTimeString("#6239_20", fallback: "checkmark.square.fill"))
                    } else {
                        Image(systemName: __designTimeString("#6239_21", fallback: "square"))}
                })
                Spacer()
                Text("Selected \(VM.selectedRecurringLaborContracts.count)")
            }
            .padding(__designTimeInteger("#6239_22", fallback: 8))
            ForEach(VM.recurringLaborContracts){ contract in
                HStack{
                    Button(action: {
                        if VM.selectedRecurringLaborContracts.contains(where: {$0.id == contract.id}){
                            VM.selectedRecurringLaborContracts.remove(contract)
                        } else {
                            VM.selectedRecurringLaborContracts.append(contract)
                        }
                    }, label: {
                        if VM.selectedRecurringLaborContracts.contains(where: {$0.id == contract.id}){
                            Image(systemName: __designTimeString("#6239_23", fallback: "checkmark.square.fill"))
                        } else {
                            Image(systemName: __designTimeString("#6239_24", fallback: "square"))
                        }
                    })
                    Spacer()
                    RecurringLaborContractInvoiceCardView(dataService: dataService, recurringContract: contract)
                    Text("\(contract.status.rawValue)")
//                    Text("\(contract.customerName) \(Double(contract.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                }
            }
        }
        .padding(__designTimeInteger("#6239_25", fallback: 8))
    }

    var footer: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                Button(action: {
                    
                }, label: {
                    Text(__designTimeString("#6239_26", fallback: "Send"))
                        .modifier(SubmitButtonModifier())
                })
            }
            .padding(__designTimeInteger("#6239_27", fallback: 8))
            .background(Color.darkGray)
        }
    }
}
