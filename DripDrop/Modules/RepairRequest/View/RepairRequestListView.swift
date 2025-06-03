//
//  RepairRequestListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct RepairRequestListView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject private var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject var repairRequestVM : RepairRequestViewModel
    @StateObject var techVM = TechViewModel()
    @StateObject var companyUserVM = CompanyUserViewModel()

    init(dataService:any ProductionDataServiceProtocol){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        
    }
    @State var searchTerm:String = ""
    @State var showFilters:Bool = false
    @State var showSearch:Bool = false
    @State var showAddNewRequest:Bool = false
    @State var requestList:[RepairRequest] = []
    @State var selectedStatus:[RepairRequestStatus] = [.inprogress,.unresolved]
    @State var techIds:[String] = []

    @State var startDate:Date = Date()
    @State var endDate:Date = Date()

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
        list
            icons
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    techIds = []

                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    for companyUser in companyUserVM.companyUsers {
                        techIds.append(companyUser.userId)
                    }
                    
                } catch {
                    print("Error Getting Users By status")
                }
            do {
                startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
                repairRequestVM.addListenerForAllRequests(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                } catch {
                    print("Failed")
                }
            }
        }
        .onChange(of: repairRequestVM.listOfContrats, perform: { list in
            requestList = list
        })
        .onDisappear(perform: {
            repairRequestVM.removeListenerForRepairRequest()
        })
    }
}

extension RepairRequestListView{
    var list: some View{
        VStack{
            if repairRequestVM.listOfContrats.count == 0 {
                Button(action: {
                    showAddNewRequest.toggle()
                }, label: {
                    Text("Add First Request")
                        .modifier(AddButtonModifier())

                })
            } else {
                List(selection:$masterDataManager.selectedID){
                ForEach(repairRequestVM.listOfContrats){ repair in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.repairRequest(repairRequest: repair,dataService:dataService), label: {
                            RepairRequestCardView(repairRequest: repair)

                        })
                    } else {
                        Button(action: {
                            masterDataManager.selectedRepairRequest = repair
                            navigationManager.routes.append(Route.repairRequest(repairRequest: repair,dataService:dataService))
                        }, label: {
                            RepairRequestCardView(repairRequest: repair)
                        })
                    }
                }
            }
            }
        }
    }
var icons: some View{
    VStack{
        Spacer()
        HStack{
            Spacer()
            VStack{
                Button(action: {
                    showFilters.toggle()
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
                .padding(10)
                .sheet(isPresented: $showFilters, onDismiss: {
             
                    if let company = masterDataManager.currentCompany {
                        repairRequestVM.removeListenerForRepairRequest()
                        repairRequestVM.addListenerForAllRequests(companyId: company.id, status: selectedStatus, requesterIds: techIds, startDate: startDate, endDate: endDate)
                    }
                },content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        VStack{
                            VStack(alignment: .leading){
                                HStack{
                                    Text("Start Date: ")
                                    DatePicker(selection: $startDate, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Text("End Date: ")
                                    
                                    DatePicker(selection: $endDate, displayedComponents: .date) {
                                    }
                                }
                                HStack{
                                    Text("Status: ")
                                    Menu("Status") {
                                        Button(action: {
                                            print("All Selected")
                                            selectedStatus = []
                                            for status in RepairRequestStatus.allCases {
                                                selectedStatus.append(status)
                                            }

                                        }, label: {
                                            Text("All \(selectedStatus == RepairRequestStatus.allCases ? "✓" : "")")
                                        })
                                        
                                        ForEach(RepairRequestStatus.allCases,id:\.self) { status in
                                            Button(action: {
                                                if selectedStatus.contains(status) {
                                                    selectedStatus.removeAll(where: {$0 == status})
                                                    print("Removed \(status.rawValue)")
                                                } else {
                                                    print("Added \(status.rawValue)")

                                                    selectedStatus.append(status)
                                                }
                                            }, label: {
                                                Text("\(status.rawValue) \(selectedStatus.contains(status) ? "✓" : "")")
                                            })
                                        }
                                        Button(action: {
                                            techIds = []
                                        }, label: {
                                            Text("Clear \(selectedStatus == [] ? "✓" : "")")
                                        })
                                    }
                                    Spacer()
                                }
                                HStack{
                                    Text("Techs: ")
                                    Menu("Techs") {
                                        Button(action: {
                                            print("All Selected")
                                            techIds = []
                                            for tech in companyUserVM.companyUsers {
                                                techIds.append(tech.userId)
                                            }

                                        }, label: {
                                            Text("All \(techIds.count == companyUserVM.companyUsers.count ? "✓" : "")")
                                        })
                                        
                                        ForEach(companyUserVM.companyUsers) { tech in
                                            Button(action: {
                                                if techIds.contains(tech.userId) {
                                                    techIds.removeAll(where: {$0 == tech.userId})
                                                    print("Removed \(tech.userName)")
                                                } else {
                                                    print("Added \(tech.userName)")

                                                    techIds.append(tech.userId)
                                                }
                                            }, label: {
                                                Text("\(tech.userName) \(techIds.contains(tech.userId) ? "✓" : "")")
                                            })
                                        }
                                        Button(action: {
                                            techIds = []
                                        }, label: {
                                            Text("Clear \(techIds == [] ? "✓" : "")")
                                        })
                                    }
                                    Spacer()
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                        }
                       
                    }
                  
                })
                Button(action: {
                    showAddNewRequest.toggle()
                }, label: {
                    ZStack{
                        Circle()
                            .fill(Color.green)
                            .frame(width: 50, height: 50)
                            .overlay(
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundColor(Color.white)
                        )
                    }
                    
                   
                })
                .padding(10)
                .sheet(isPresented: $showAddNewRequest, content: {
                        AddNewRepairRequest(dataService: dataService,isPresented: $showAddNewRequest)
                })
                Button(action: {
                    showSearch.toggle()
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
        if showSearch {
            HStack{
                TextField(
                    "Search",
                    text: $searchTerm
                )
                Button(action: {
                    searchTerm = ""
                }, label: {
                    Image(systemName: "xmark")
                })
            }
            .modifier(SearchTextFieldModifier())
            .padding(8)
        }
        
    }

}
}
