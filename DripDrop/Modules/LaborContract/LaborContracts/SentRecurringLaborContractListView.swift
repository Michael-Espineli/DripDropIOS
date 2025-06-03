//
//  SentRecurringLaborContractListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import Foundation
import SwiftUI

@MainActor
final class SentRecurringLaborContractListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var searchTerm:String = ""

    @Published var showSearch:Bool = false
    @Published var showFilters:Bool = false
    @Published var showAddNewLaborContract:Bool = false
    @Published var selectedStatus:LaborContractStatus = .accepted

    @Published var statusList:[LaborContractStatus] = [.accepted]

    @Published private(set) var recurringLaborContractList:[ReccuringLaborContract] = []

    //Get
    func getLaborContracts(companyId:String) async throws {
        self.recurringLaborContractList = try await dataService.getSentLaborContracts(companyId: companyId)
    }
}
struct SentRecurringLaborContractListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject var VM : SentRecurringLaborContractListViewModel
    
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: SentRecurringLaborContractListViewModel(dataService: dataService))
    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if VM.showSearch && !UIDevice.isIPhone{
                    HStack{
                        Button(action: {
                            VM.searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                        TextField(
                            "Search",
                            text: $VM.searchTerm
                        )
                        
                    }
                    .modifier(SearchTextFieldModifier())
                    .padding(8)
                }
                ScrollView{
                    list
                }
                if VM.showSearch && UIDevice.isIPhone{
                    HStack{
                        Button(action: {
                            VM.searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                        TextField(
                            "Search",
                            text: $VM.searchTerm
                        )
                    }
                    .modifier(SearchTextFieldModifier())
                    .padding(8)
                }
            }
            icons
            Text("")
                .sheet(isPresented: $VM.showFilters, onDismiss: {
                    
                }, content: {
                    filters
                })
            Text("")
                .sheet(isPresented: $VM.showAddNewLaborContract, onDismiss: {
                    Task{
                        if let selectedCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.getLaborContracts(companyId: selectedCompany.id)
                            } catch {
                                print("Error")
                                print(error)
                            }
                        }
                    }
                }, content: {
                    AddNewLaborContract(dataService: dataService,isPresented: $VM.showAddNewLaborContract,isFullScreen: true)
                })
        }
        .navigationTitle("Sent Recurring Labor Contracts")
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await VM.getLaborContracts(companyId: selectedCompany.id)
                } catch {
                    print("Error")
                    print(error)
                }
            }
        }
    }
}
#Preview {
    SentRecurringLaborContractListView(dataService: MockDataService())
}
extension SentRecurringLaborContractListView {
    var list: some View {
        VStack{
            if !VM.recurringLaborContractList.isEmpty {
                ForEach(VM.recurringLaborContractList) { contract in
                    Divider()
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.recurringLaborContractDetailView(contract: contract, dataService: dataService), label: {
                            LaborContractCardSmall(dataService: dataService, laborContract: contract)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedRecurringLaborContract = contract
                        }, label: {
                            LaborContractCardSmall(dataService: dataService, laborContract: contract)
                        })
                    }
                }
            } else {
                Spacer()
                Button(action: {
                    VM.showAddNewLaborContract.toggle()
                    
                }, label: {
                    Text("Add New Labor Contract")
                        .modifier(AddButtonModifier())
                })
                Spacer()
            }
        }
    }
    var filters: some View {
        VStack{
            Menu("Filter") {
                Button(action: {
                    print("All Selected")
                    for status in LaborContractStatus.allCases {
                        VM.statusList.append(status)
                    }
                }, label: {
                    Text("All \(VM.statusList.count == LaborContractStatus.allCases.count ? "✓" : "")")
                })
                ForEach(LaborContractStatus.allCases,id:\.self) { status in
                    Button(action: {
                        if VM.statusList.contains(status) {
                            VM.statusList.removeAll(where: {$0 == status})
                            print("Removed \(status.rawValue)")
                        } else {
                            print("Added \(status.rawValue)")
                            
                            VM.statusList.append(status)
                        }
                    }, label: {
                        Text("\(status.rawValue) \(VM.statusList.contains(status) ? "✓" : "")")
                    })
                }
                Button(action: {
                    VM.statusList = []
                }, label: {
                    Text("Clear \(VM.statusList == [] ? "✓" : "")")
                })
            }
            .modifier(AddButtonModifier())
        }
    }
    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack{
                    Button(action: {
                        VM.showFilters.toggle()
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "slider.horizontal.3")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundColor(Color.white)
                                )
                        }
                    })
                    Button(action: {
                        VM.showAddNewLaborContract.toggle()
                        
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.green)
                        }
                    })
                    .padding(10)
                    Button(action: {
                        Task{
                            VM.showSearch = true
                        }
                    }, label: {
                        ZStack{
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "magnifyingglass.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(Color.blue)
                        }
                    })
                    .padding(10)
                }
            }
        }
    }
}
