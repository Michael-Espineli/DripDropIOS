//
//  LaborContractListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/25.
//

import SwiftUI

@MainActor
final class SingleLaborContractListViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var laborContracts : [LaborContract] = []
    @Published var sentLaborContracts : [LaborContract] = []
    @Published var receivedLaborContracts : [LaborContract] = []

    @Published var showNewSheet : Bool = false
    @Published var showFilterSheet : Bool = false
    @Published var showSearchSheet : Bool = false
    
    @Published var selectedStatus : [LaborContractStatus] = [.pending, .accepted, .finished]
    @Published var invoiceStatus : [String] = ["Is Invoiced", "Not Invoiced"]
    @Published var selectedInvoiceStatus : [String] = ["Not Invoiced"]

    @Published var isInvoiced : Bool = false
    
    func onLoad(companyId:String,userId:String) async throws {
        print("On Load Single Labor Contract List View - [SingleLaborContractListViewModel]")
        if selectedInvoiceStatus.contains("Is Invoiced") && selectedInvoiceStatus.contains("Not Invoiced") {
            dataService.addListenerForSentLaborContractsAllInvoiceStatus(companyId: companyId, status: selectedStatus){ [weak self] messages in
                self?.sentLaborContracts = messages
           }

            dataService.addListenerForReceivedLaborContractsAllInvoiceStatus(companyId: companyId, status: selectedStatus){ [weak self] messages in
                self?.receivedLaborContracts = messages
           }
        } else if selectedInvoiceStatus.contains("Is Invoiced") && !selectedInvoiceStatus.contains("Not Invoiced") {
            dataService.addListenerForSentLaborContracts(companyId: companyId, status: selectedStatus, isInvoiced: true){ [weak self] messages in
                self?.sentLaborContracts = messages
            }
            dataService.addListenerForReceivedLaborContracts(companyId: companyId, status: selectedStatus, isInvoiced: true){ [weak self] messages in
                self?.receivedLaborContracts = messages
            }
        } else if !selectedInvoiceStatus.contains("Is Invoiced") && selectedInvoiceStatus.contains("Not Invoiced") {
            
            dataService.addListenerForSentLaborContracts(companyId: companyId, status: selectedStatus, isInvoiced: false){ [weak self] messages in
                self?.sentLaborContracts = messages
            }
            dataService.addListenerForReceivedLaborContracts(companyId: companyId, status: selectedStatus, isInvoiced: false){ [weak self] messages in
                self?.receivedLaborContracts = messages
            }
        }
        
          
        print("Finished")
    }
    func onDisapper(){
        dataService.removeListenerForSentLaborContracts()
        dataService.removeListenerForReceivedLaborContracts()
    }
}

struct LaborContractListView: View {
    init(dataService: any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: SingleLaborContractListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : SingleLaborContractListViewModel
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            ScrollView{
                VStack{
                    ForEach(VM.laborContracts) { contract in
                        NavigationLink(value: Route.laborContractDetailView(dataService: dataService, contract: contract), label: {
                            LaborContractCardView(laborContract: contract)
                        })
                    }
                }
                
//                VStack{
//                    ForEach(VM.sentLaborContracts) { contract in
//                        NavigationLink(value: Route.laborContractDetailView(dataService: dataService, contract: contract), label: {
//                            LaborContractCardView(laborContract: contract)
//                        })
//                    }
//                }
            }
            .padding(8)
            icons
        }
        .navigationTitle("Labor Contracts")
        .task{
            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, userId: user.id)
                } catch {
                    print("Error - [LaborContractListView]")
                    print(error)
                }
            }
        }
        .onDisappear(perform: {
            VM.onDisapper()
        })
        .onChange(of: VM.sentLaborContracts, perform: { contracts in
            VM.laborContracts = contracts + VM.receivedLaborContracts
        })
        .onChange(of: VM.receivedLaborContracts, perform: { contracts in
            VM.laborContracts = contracts + VM.sentLaborContracts
        })
    }
}

//#Preview {
//    LaborContractListView()
//}
extension LaborContractListView {
    var icons : some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        VM.showFilterSheet.toggle()
                    }, label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.orange)
                            .cornerRadius(5)
                    })
                    .padding(8)
                    .sheet(isPresented: $VM.showFilterSheet,onDismiss: {
                        Task{
                            
                            if let currentCompany = masterDataManager.currentCompany, let user = masterDataManager.user {
                                do {
                                    VM.onDisapper()
                                    try await VM.onLoad(companyId: currentCompany.id, userId: user.id)
                                } catch {
                                    print("Error - [LaborContractListView]")
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        filterOptions
                            .presentationDetents([.fraction(0.4)])
                    })
                    Button(action: {
                        VM.showNewSheet.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolGreen)
                            .cornerRadius(5)
                    })
                    .padding(8)
                    .sheet(isPresented: $VM.showNewSheet, content: {
                        Text("Add New Sheet")
                    })
                    Button(action: {
                        VM.showSearchSheet.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                    .padding(8)
                }
                .padding()
            }
        }
    }
    var filterOptions : some View {
        VStack{
            Text("Filter Options")
            HStack{
                Text("Invoice Options: ")
                Spacer()
                Menu("Options  - \(VM.selectedInvoiceStatus.count)") {
                    Button(action: {
                        print("All Selected")
                        VM.selectedInvoiceStatus = []
                        for status in VM.invoiceStatus {
                            VM.selectedInvoiceStatus.append(status)
                        }
                    }, label: {
                        Text("All \(VM.selectedInvoiceStatus.count == VM.invoiceStatus.count ? "✓" : "")")
                    })
                    
                    ForEach(VM.invoiceStatus,id:\.self) { status in
                        Button(action: {
                            if VM.selectedInvoiceStatus.contains(status) {
                                VM.selectedInvoiceStatus.removeAll(where: {$0 == status})
                                print("Removed \(status)")
                            } else {
                                print("Added \(status)")
                                
                                VM.selectedInvoiceStatus.append(status)
                            }
                        }, label: {
                            Text("\(status) \(VM.selectedInvoiceStatus.contains(status) ? "✓" : "")")
                        })
                    }
                }
                .modifier(ListButtonModifier())
            }
            HStack{
                Text("Status: ")
                Spacer()
                Menu("Status  - \(VM.selectedStatus.count)") {
                    Button(action: {
                        print("All Selected")
                        VM.selectedStatus = []
                        for status in LaborContractStatus.allCases {
                            VM.selectedStatus.append(status)
                        }
                    }, label: {
                        Text("All \(VM.selectedStatus == LaborContractStatus.allCases ? "✓" : "")")
                    })
                    
                    ForEach(LaborContractStatus.allCases,id:\.self) { status in
                        Button(action: {
                            if VM.selectedStatus.contains(status) {
                                VM.selectedStatus.removeAll(where: {$0 == status})
                                print("Removed \(status.rawValue)")
                            } else {
                                print("Added \(status.rawValue)")
                                
                                VM.selectedStatus.append(status)
                            }
                        }, label: {
                            Text("\(status.rawValue) \(VM.selectedStatus.contains(status) ? "✓" : "")")
                        })
                    }
                    Button(action: {
                        VM.selectedStatus = []
                    }, label: {
                        Text("Clear \(VM.selectedStatus == [] ? "✓" : "")")
                    })
                }
                .modifier(ListButtonModifier())
            }
        }
    }
}
