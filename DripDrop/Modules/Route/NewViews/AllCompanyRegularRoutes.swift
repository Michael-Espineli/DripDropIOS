//
//  AllCompanyRegularRoutes.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/17/25.
//

import SwiftUI


struct AllCompanyRegularRoutes: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var VM : AllCompanyRegularRoutesViewModel

    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AllCompanyRegularRoutesViewModel(dataService: dataService))
    }
    @State var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @State var isLoading:Bool = false
    @State var showAddNewRoute:Bool = false
    @State var showStops:Bool = false
    
    //New Variables 5/18/25
    @State var showDialogConfirmation : Bool = false
    @State var selectedDay : String = ""
    @State var selectedTechId : String = ""
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false){
                LazyVStack{
                    if VM.isLoading {
                        VStack{
                            ProgressView()
                            Text("Loading")
                        }
                    } else {
                            dayThenTech
                    }
                }
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 10))
            }
        }
        .navigationTitle("Internal and External")
        .toolbar{
            ToolbarItem{
                Button(action: {
                   VM.reload()
                }, label: {
                    Image(systemName: "gobackward")
                })
            }
        }
        .refreshable {
            Task{
                if let company = masterDataManager.currentCompany {
                    do {
                        try await VM.firstLoad(companyId: company.id)
                    } catch {
                        print("Error")
                    }
                }
            }
                }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.firstLoad(companyId: company.id)
                } catch {
                    print("Error")
                }
            }
        }
        .onChange(of: masterDataManager.reloadBuilderView, perform: { reload in
            Task{
                if let company = masterDataManager.currentCompany {
                    do {
                        try await VM.firstLoad(companyId: company.id)
                        masterDataManager.reloadBuilderView = false
                    } catch {
                        print("Error")
                    }
                }
            }
        })
    }
}

struct AllCompanyRegularRoutes_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        @State var showSignInView: Bool = false
        AllCompanyRegularRoutes(dataService:dataService)
        
    }
}
extension AllCompanyRegularRoutes {
    var dayThenTech: some View {
        VStack{
            ForEach(VM.daysOfWeekList,id:\.self){ day in
                VStack(spacing: 10){
                    //Day
                    HStack{
                        Text("\(day)")
                        Spacer()
                        Button(action: {
                            if UIDevice.isIPhone {
                                showAddNewRoute.toggle()
                            } else {
                                masterDataManager.newRoute = true
                                masterDataManager.modifyRoute = false
                                masterDataManager.reassignRoute = false
                                masterDataManager.selectedRouteBuilderDay = day
                                showAddNewRoute.toggle()
                            }
                        }, label: {
                            Image(systemName: "plus")
                        })
                        .sheet(isPresented: $showAddNewRoute, content: {
                            //DEVLOPER PLEASE FIX
                            NewRouteView(dataService: dataService, tech: CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor), day: day)
                        })
                    }
                    .modifier(ListButtonModifier())
                    if let techniciansAndStops = VM.technicianStopsOrderedByDay[day] {
                        ForEach(Array(techniciansAndStops.keys) ,id:\.self){ techId in
                            if let recurringServiceStops = techniciansAndStops[techId] {

                                AllCompanyRouteTechStopView(
                                    showDialog: $showDialogConfirmation,
                                    selectedDay: $selectedDay,
                                    selectedTechId: $selectedTechId,
                                    companyList: VM.companyList,
                                    recurringServiceStops: recurringServiceStops,
                                    basicTechnicanInfo: VM.basicTechnicanInfo,
                                    techId: techId,
                                    day: day
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    var techView: some View {
        VStack(spacing:0){
            if VM.recurringRoute != nil {
//                info
                TechnicianRouteSummaryCardView(
                    technicianName: "Michael Espineli",
                    roleName: "Employee",
                    isOtherCompany: true,
                    companyName: "Murdock Pool Service",
                    showDialogConfirmation: $showDialogConfirmation
                )
                Divider()
                if showStops {
//                    stops
                    Divider()
                }
            }
        }
    }
    
//    var info: some View {
//        VStack(spacing:0){
//            HStack{
//                Text("\(VM.recurringRoute?.tech ?? "")")
//                Spacer()
//                Button(action: {
//                    showRouteModifier.toggle()
//                }, label: {
//                    Image(systemName: "line.3.horizontal")
//                        .padding(4)
//                })
//                .confirmationDialog("Select Type", isPresented: self.$showRouteModifier, actions: {
//                    Button(action: {
//                        if UIDevice.isIPhone {
//                            showReassignRoute = true
//                        } else {
//                            masterDataManager.selectedRouteBuilderTech = tech
//                            masterDataManager.selectedRouteBuilderDay = day
//                            masterDataManager.selectedRecurringRoute = VM.recurringRoute
//                            
//                            masterDataManager.newRoute = false
//                            masterDataManager.modifyRoute = false
//                            masterDataManager.reassignRoute = true
//                        }
//                        
//                    }, label: {
//                        Text("Reassign")
//                    })
//                    Button(action: {
//                        if UIDevice.isIPhone {
//                            showNewRoute = true
//                        } else {
//                            
//                            masterDataManager.selectedRouteBuilderTech = tech
//                            masterDataManager.selectedRouteBuilderDay = day
//                            masterDataManager.selectedRecurringRoute = VM.recurringRoute
//                            masterDataManager.newRoute = false
//                            masterDataManager.reassignRoute = false
//                            masterDataManager.modifyRoute = true
//                            
//                        }
//                    }, label: {
//                        Text("Edit")
//                    })
//                    Button(action: {
//                        showDelete.toggle()
//                    }, label: {
//                        Text("Delete")
//                    })
//                })
//                .sheet(isPresented: $showNewRoute, onDismiss: {
//                    print("done")
//                }, content: {
//                    ZStack{
//                        Color.listColor.ignoresSafeArea()
//                        ModifyRecurringRoute(dataService: dataService, tech: tech, day: day, recurringRoute: VM.recurringRoute!) //Developer fix and remove explicit unwrap
//                    }
//                })
//                Button(action: {
//                    showStops.toggle()
//                }, label: {
//                    HStack{
//                        Text("\(String((VM.recurringRoute?.order ?? []).count))")
//                        Image(systemName: showStops ? "chevron.up.square" : "chevron.down.square")
//                    }
//                })
//                .sheet(isPresented: $showReassignRoute, onDismiss: {
//                    print("done")
//                }, content: {
//                    ZStack{
//                        Color.listColor.ignoresSafeArea()
//                        VStack{
//                            HStack{
//                                Spacer()
//                                Button(action: {
//                                    showReassignRoute = false
//                                }, label: {
//                                    Image(systemName: "xmark")
//                                })
//                            }
//                            ReassignRouteView(dataService: dataService, tech: tech, day: day, recurringRoute: VM.recurringRoute!)//Developer fix and remove explicit unwrap
//                        }
//                    }
//                    
//                })
//            }
//            .padding(10)
//        }
//    }
    var stops: some View {
        VStack(spacing:0){
            
        }
    }
}
