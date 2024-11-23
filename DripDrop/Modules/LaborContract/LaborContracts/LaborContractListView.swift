//
//  LaborContractListView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct LaborContractListView: View {
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
                .fullScreenCover(isPresented: $VM.showAddNewLaborContract, onDismiss: {
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
        .navigationTitle(VM.laborContractList.isEmpty ? "Labor Contracts" : "Labor Contracts - \(VM.laborContractList.count)")
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
    LaborContractListView(dataService: MockDataService())
}
extension LaborContractListView {
    var list: some View {
        VStack{
            if !VM.laborContractList.isEmpty {
                ForEach(VM.laborContractList) { contract in
                    Divider()
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.laborContractDetailView(contract: contract, dataService: dataService), label: {
                            LaborContractCardSmall(dataService: dataService, laborContract: contract)
                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedLaborContract = contract
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
