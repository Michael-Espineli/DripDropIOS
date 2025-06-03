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
    @EnvironmentObject var navigationStateManager : NavigationStateManager

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
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders,.sectionFooters], content: {
                    Section(content: {
                        ScrollView{
                            info
                        }
                        .background(Color.listColor.ignoresSafeArea())
                    }, header: {
                        header
                    }, footer: {
                        footer
                    })
                })
                .clipped()
            }
            if VM.isLoading {
                VStack{
                    Text("Calculating")
                    ProgressView()
                }
                .padding(8)
                .background(Color.darkGray)
                .cornerRadius(8)
            }
        }
        .navigationTitle("Create Bulk Invoice")
        .alert(VM.alertMessage, isPresented: $VM.showAlertMessage) {
            Button("OK", role: .cancel) { }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id,associatedBusiness:associatedBusiness)
                } catch {
                    print("Error - CreateBulkInvoice - onLoad")
                    print(error)
                }
            }
        }
        .onChange(of: VM.selectedLaborContracts, perform: { contracts in
            Task {
                if let currentCompany = masterDataManager.currentCompany{
                    do {
                        try await VM.onChangeOfContracts(companyId: currentCompany.id, contracts: contracts)
                    } catch {
                        print("Error - CreateBulkInvoice - selectedLaborContracts")
                        VM.isLoading = false
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedRecurringLaborContracts, perform: { contracts in
            Task {
                if let currentCompany = masterDataManager.currentCompany{
                    do {
                        try await VM.onChangeOfRecurringContracts(companyId: currentCompany.id, recurringContracts: contracts)
                    } catch {
                        print("Error - CreateBulkInvoice - selectedRecurringLaborContracts")
                        VM.isLoading = false
                        print(error)
                    }
                }
            }
        })
    }
}

#Preview {
    @StateObject var masterDataManager : MasterDataManager = MasterDataManager()
    @StateObject var dataService : ProductionDataService = ProductionDataService()
    @StateObject var navigationStateManager : NavigationStateManager = NavigationStateManager()

    CreateBulkInvoice(
        dataService: MockDataService(),
        associatedBusiness: MockDataService.mockAssociatedBusiness
    )
    .environmentObject(masterDataManager)
    .environmentObject(dataService)
    .environmentObject(navigationStateManager)
}
extension CreateBulkInvoice {
    var header: some View {
        VStack{
            HStack{
                Text(associatedBusiness.companyName)
                Spacer()
            }
 
        }
        .padding(8)
        .foregroundColor(Color.poolWhite)
        .background(Color.darkGray)
    }
    var info: some View {
        VStack{
            Text("Last Invoice Sent")
                .font(.headline)
            HStack{
                Spacer()
                HStack{
                    Text("Invoice History")
                    Image(systemName: "chevron.right")
                }
                    .modifier(RedLinkModifier())
            }
            VStack{
                Text("Invoice Information")
                    .font(.headline)
                HStack{
                    Text("Total:")
                    Spacer()
                    Text("\(Double(VM.totalAmount)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                }
            }
            .padding(8)
            Rectangle()
                .frame(height: 1)
            contractsNotBilled
            Rectangle()
                .frame(height: 1)
            recurringContractsNotBilled
            Text("W")
                .foregroundColor(.clear)
                .padding(8)
        }
    }
    var contractsNotBilled: some View {
        VStack{
            Text("Contracts Not Billed For")
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
                        Image(systemName: "checkmark.square.fill")
                    } else {
                        Image(systemName: "square")}
                })
                .font(.headline)
                .disabled(VM.isConfirmSendInvoice)
                Text("Selected \(VM.selectedLaborContracts.count)")
                Spacer()
            }
            .padding(.top,8)
            Divider()
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
                            Image(systemName: "checkmark.square.fill")
                        } else {
                            Image(systemName: "square")
                        }
                    })
                    .font(.headline)
                    .disabled(VM.isConfirmSendInvoice)
                    Text("\(contract.customerName)")

                    Spacer()
                    Text("\(Double(contract.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                }
                .padding(.horizontal,8)
            }
        }
        .padding(8)
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
                        Image(systemName: "checkmark.square.fill")
                    } else {
                        Image(systemName: "square")}
                })
                .disabled(VM.isConfirmSendInvoice)
                .font(.headline)
                Text("Selected \(VM.selectedRecurringLaborContracts.count)")
                Spacer()
            }
            .padding(.top,8)
            Divider()
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
                            Image(systemName: "checkmark.square.fill")
                        } else {
                            Image(systemName: "square")
                        }
                    })
                    .font(.headline)
                    .disabled(VM.isConfirmSendInvoice)
                    RecurringLaborContractInvoiceCardView(dataService: dataService, recurringContract: contract)
                }
                .padding(.horizontal,8)
            }
        }
        .padding(8)
    }

    var footer: some View {
        HStack{
            if let invoice = VM.invoice {
                NavigationLink(value: Route.accountsReceivableDetail(invoice: invoice, dataService: dataService), label: {
                    HStack{
                        Spacer()
                        Text("See Invoice")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                })
            } else {
                Button(action: {
                    VM.isConfirmSendInvoice.toggle()
                }, label: {
                    HStack{
                        Spacer()
                        Text("Confirm")
                        Spacer()
                    }
                    .modifier(SubmitButtonModifier())
                })
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.75 : 1)
                .padding(8)
                .background(Color.darkGray)
                
                .sheet(isPresented: $VM.isConfirmSendInvoice,onDismiss: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                
                                try await VM.onLoad(companyId: currentCompany.id,associatedBusiness:associatedBusiness)
                                if let invoice = VM.invoice {
                                    navigationStateManager.push(to: Route.accountsReceivableDetail(invoice: invoice, dataService: dataService))
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, content: {
                    VStack{
                        Picker("Type", selection: $VM.terms) {
                            ForEach(AcountingTermsTypes.allCases, id:\.self){ datum in
                                Text(datum.rawValue).tag(datum)
                            }
                        }
                        Button(action: {
                            Task{
                                if !VM.isLoading {
                                    if let currentCompany = masterDataManager.currentCompany{
                                        do {
                                            try await VM.generateInvoice(company: currentCompany, associatedBusiness: associatedBusiness)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }
                        }, label: {
                            Text("Send Invoice")
                                .modifier(SubmitButtonModifier())
                        })
                        .disabled(VM.isLoading)
                        .opacity(VM.isLoading ? 0.75 : 1)
                    }
                    .presentationDetents([.fraction(0.2),.fraction(0.4)])
                })
            }
        }
        .background(Color.darkGray)
    }
}
