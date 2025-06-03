//
//  RecurringLaborContractListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct RecurringLaborContractListView: View {
    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: LaborContractListViewModel(dataService: dataService))
    }
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : LaborContractListViewModel
    
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
                    AddNewLaborContract(dataService: dataService,isPresented: $VM.showAddNewLaborContract,isFullScreen: false)
                })
        }
        .navigationTitle("Recurring Labor Contracts")
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
    RecurringLaborContractListView(dataService: MockDataService())
}
extension RecurringLaborContractListView {
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
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.orange)
                            .cornerRadius(5)
                    })
                    .padding(8)
                    Button(action: {
                        VM.showAddNewLaborContract.toggle()

                    }, label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolGreen)
                            .cornerRadius(5)
                    })
                    .padding(8)
                    Button(action: {
                        Task{
                            VM.showSearch = true
                        }
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
            }
        }
    }
}
