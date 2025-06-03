    //
    //  RecurringStopDayView.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 12/8/23.
    //


import SwiftUI

struct RouteTechView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : RouteManagmentViewModel
    @StateObject var routeVM : RecurringRouteViewModel
    @StateObject var recurringStopVM : RecurringStopViewModel
    
    init( dataService:any ProductionDataServiceProtocol,day:String,tech:CompanyUser){
        _VM = StateObject(wrappedValue: RouteManagmentViewModel(dataService: dataService))
        _recurringStopVM = StateObject(wrappedValue: RecurringStopViewModel(dataService: dataService))
        _routeVM = StateObject(wrappedValue: RecurringRouteViewModel(dataService: dataService))
        _day = State(wrappedValue: day)
        _tech = State(wrappedValue: tech)
    }
    
    @State var tech:CompanyUser
    @State var day:String
    @State var rss:RecurringRoute = RecurringRoute(id: "", tech: "", techId: "", day: "", order: [], description: "")
    @State var showStops:Bool = false
    @State var showRouteModifier:Bool = false
    @State var showDelete:Bool = false
    @State var showNewRoute:Bool = false
    @State var showReassignRoute:Bool = false
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    var body: some View {
        ZStack{
            ScrollView{
                
                VStack(spacing:0){
                    if VM.recurringRoute != nil {
                        info
                        Divider()
                        if showStops {
                            stops
                            Divider()
                        }
                    }
                }
            }
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
//                    print("Getting \(tech.userName)")
                    try await VM.getRouteForRecurringStopDay(companyId: company.id, day: day, techId: tech.userId, techName: tech.userName)
                } catch {
                    print("Error on page RecurringStopDayView")
                }
                    //            print("Received \(recurringStopVM.recurringServiceStops.count) RSS on \(day) for \(tech.firstName) \(tech.lastName)")
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert(isPresented:$showDelete) {
            Alert(
                title: Text("Alert"),
                message: Text("Deleting This Route Can Not Be Undone"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleteing Recurring Stop \(rss.id)")
                    
                    Task{
                        if let company = masterDataManager.currentCompany, let recurringRoute = VM.recurringRoute {
                            do {
                                try await VM.deleteRecurringRoute(companyId: company.id, recurringRoute: recurringRoute)
                                alertMessage = "Successfully Deleted"
                                showAlert = true
                                print("")
                                print(alertMessage)
                                print("")
                                masterDataManager.reloadBuilderView = true
                            } catch {
                                alertMessage = "Failed to  Deleted"
                                showAlert = true
                                print("")
                                print(alertMessage)
                                print(error)
                                print("")
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct RecurringStopDayView_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        @State var showSignInView: Bool = false
        RouteTechView(dataService:dataService,day: "Sunday", tech: CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor))
        
    }
}
extension RouteTechView {
    var info: some View {
        VStack(spacing:0){
            HStack{
                Text("\(VM.recurringRoute?.tech ?? "")")
                Spacer()
                Button(action: {
                    showRouteModifier.toggle()
                }, label: {
                    Image(systemName: "line.3.horizontal")
                        .padding(4)
                })
                .confirmationDialog("Select Type", isPresented: self.$showRouteModifier, actions: {
                    Button(action: {
                        if UIDevice.isIPhone {
                            showReassignRoute = true
                        } else {
                            masterDataManager.selectedRouteBuilderTech = tech
                            masterDataManager.selectedRouteBuilderDay = day
                            masterDataManager.selectedRecurringRoute = VM.recurringRoute
                            
                            masterDataManager.newRoute = false
                            masterDataManager.modifyRoute = false
                            masterDataManager.reassignRoute = true
                        }
                        
                    }, label: {
                        Text("Reassign")
                    })
                    Button(action: {
                        if UIDevice.isIPhone {
                            showNewRoute = true
                        } else {
                            
                            masterDataManager.selectedRouteBuilderTech = tech
                            masterDataManager.selectedRouteBuilderDay = day
                            masterDataManager.selectedRecurringRoute = VM.recurringRoute
                            masterDataManager.newRoute = false
                            masterDataManager.reassignRoute = false
                            masterDataManager.modifyRoute = true
                            
                        }
                    }, label: {
                        Text("Edit")
                    })
                    Button(action: {
                        showDelete.toggle()
                    }, label: {
                        Text("Delete")
                    })
                })
                .sheet(isPresented: $showNewRoute, onDismiss: {
                    print("done")
                }, content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        ModifyRecurringRoute(dataService: dataService, tech: tech, day: day, recurringRoute: VM.recurringRoute!) //Developer fix and remove explicit unwrap
                    }
                })
                Button(action: {
                    showStops.toggle()
                }, label: {
                    HStack{
                        Text("\(String((VM.recurringRoute?.order ?? []).count))")
                        Image(systemName: showStops ? "chevron.up.square" : "chevron.down.square")
                    }
                })
                .sheet(isPresented: $showReassignRoute, onDismiss: {
                    print("done")
                }, content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        VStack{
                            HStack{
                                Spacer()
                                Button(action: {
                                    showReassignRoute = false
                                }, label: {
                                    Image(systemName: "xmark")
                                })
                            }
                            ReassignRouteView(dataService: dataService, tech: tech, day: day, recurringRoute: VM.recurringRoute!)//Developer fix and remove explicit unwrap
                        }
                    }
                    
                })
            }
            .padding(10)
        }
    }
    var stops: some View {
        VStack(spacing:0){
            ForEach(VM.recurringRoute?.order ?? []){ num in
                RecurringRouteStopView(
                    dataService: dataService,
                    order: num,
                    day: day,
                    tech: tech
                )
            }
        }
    }
}
struct RecurringRouteStopView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var recurringStopVM : RecurringStopViewModel
    init(
        dataService: any ProductionDataServiceProtocol,
        order:recurringRouteOrder,
        day:String,
        tech:CompanyUser
    ){
        _recurringStopVM = StateObject(wrappedValue: RecurringStopViewModel(dataService: dataService))
        _order = State(wrappedValue: order)
        _day = State(wrappedValue: day)
        _tech = State(wrappedValue: tech)
        
    }
    @State var order:recurringRouteOrder
    @State var day:String
    @State var tech:CompanyUser
    @State var showRecurringStopModifier:Bool = false
    @State var editRecurringServiceStop : Bool = false
    
    @State var showNewRoute : Bool = false
    var body: some View {
        HStack{
            Image(systemName: "\(String(order.order)).square.fill")
            Spacer()
            VStack{
                HStack{
                    Text("\(order.customerName)")
                        .padding(5)
                        .background(Color.blue)
                        .foregroundColor(Color.white)
                        .cornerRadius(5)
                    if let reucrringServiceStop = recurringStopVM.recurringServiceStop {
                        switch reucrringServiceStop.frequency {
                        case .daily:
                            Text("- Daily")
                        case .weekDay:
                            Text("- Week Day")
                        case .weekly:
                            Text("- Weekly")
                        case .monthly:
                            Text("- Monthly")
                        case .yearly:
                            Text("- Annually")
                        default:
                            Text("Frequency")
                        }
                        
                    }
                }
                HStack{
                    if let reucrringServiceStop = recurringStopVM.recurringServiceStop {
                        Text("\(fullDate(date:reucrringServiceStop.startDate))")
                            .font(.footnote)
                        
                        Text(" - ")
                            .font(.footnote)
                        
                        if reucrringServiceStop.noEndDate {
                            Text("No End Date")
                                .font(.footnote)
                            
                        } else {
                            if let endDate = reucrringServiceStop.endDate {
                                Text("\(fullDate(date:endDate))")
                                    .font(.footnote)
                                
                            } else  {
                                Text("No End Date")
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                        RecurringServiceStopCompanyNameCardView(dataService: dataService, recurringServiceStopId: reucrringServiceStop.id)
                    }
                }
            }
            Spacer()
            Button(action: {
                showRecurringStopModifier.toggle()
            }, label: {
                Image(systemName: "pencil")
                
            })
            .confirmationDialog("Select Type", isPresented: self.$showRecurringStopModifier, actions: {
                
                Button(action: {
                    print("Edit Specific recurring Stop")
                    if UIDevice.isIPhone {
                        editRecurringServiceStop = true
                        print("Edit Recurring Service Stop")
                    } else {
                        masterDataManager.selectedRouteBuilderTech = tech
                        masterDataManager.selectedRouteBuilderDay = day
                    }
                    
                }, label: {
                    Text("Edit")
                })
                
                Button(action: {
                    print("Delete Recurring Service Stop")
                }, label: {
                    Text("Delete")
                })
            })
            .sheet(isPresented: $editRecurringServiceStop, content: {
                VStack{
                    Text("Edit Recurring Route")
                }
            })
        }
        .padding(5)
        .task {
            do {
                try await recurringStopVM.getReucrringServiceStopById(companyId: masterDataManager.currentCompany!.id, recurringServiceStopId: order.recurringServiceStopId)
            } catch {
                
            }
        }
    }
}
struct modifyRouteDay: View {
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Button(action: {
                    
                }, label: {
                    HStack{
                        
                    }
                    .frame(maxWidth: .infinity)
                })
                .padding(.horizontal,20)
                Divider()
            }
        }
    }
}
