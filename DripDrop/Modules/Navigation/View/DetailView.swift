//
//  DetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
//
//TBH I Can Probably Get Rid Of this

import SwiftUI

struct DetailView: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    
    @StateObject private var customerVM : CustomerViewModel
    @StateObject var contractVM : ContractViewModel
    @StateObject var serviceStopVM : ServiceStopsViewModel
    @StateObject var jobVM : JobViewModel
    @StateObject var chatVM : ChatViewModel
    @StateObject var repairRequestVM : RepairRequestViewModel
    
    
    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _contractVM = StateObject(wrappedValue: ContractViewModel(dataService: dataService))
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _chatVM = StateObject(wrappedValue: ChatViewModel(dataService: dataService))
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
    }
    @StateObject var dataBaseItemVM = ReceiptDatabaseViewModel()
    @StateObject var purchaseVM = PurchasesViewModel()
    
    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    @State var isPresented:Bool = false
    let cat:MacCategories = .calendar
    var body: some View {
        Group{
            if let category = masterDataManager.selectedCategory {
                /*
                 switch category {
                 case .customers:
                 
                 if let validatedCustomer = navigationManager.selectedCustomer {
                 CustomerDetailView(customer: validatedCustomer)
                 
                 } else {
                 if navigationManager.selectedID != nil {
                 VStack{
                 ProgressView()
                 Text("Loading...")
                 }
                 } else {
                 Text("Select a Customer")
                 }
                 }
                 
                 case .serviceStops:
                 if let serviceStop = navigationManager.selectedServiceStops {
                 //                    ServiceStopDetails(serviceStop: serviceStop, showDetailsView: $showSignInView)
                 ServiceStopDetailView(serviceStop: serviceStop)
                 } else {
                 if navigationManager.selectedID != nil {
                 VStack{
                 ProgressView()
                 Text("Loading...")
                 }
                 } else {
                 Text("Select a ServiceStop")
                 }
                 }
                 case .databaseItems:
                 if let databaseItems = navigationManager.selectedDataBaseItem {
                 //                    ServiceStopDetails(serviceStop: serviceStop, showDetailsView: $showSignInView)
                 DataBaseItemView(dataBaseItem: databaseItems)
                 } else {
                 if navigationManager.selectedID != nil {
                 VStack{
                 ProgressView()
                 Text("Loading...")
                 }
                 } else {
                 Text("Select an Item")
                 }
                 
                 }
                 case .routeBuilder:
                 if let route = navigationManager.selectedRoute {
                 //                    RouteDetailView(route: route,showSignInView:$showSignInView,user: user)
                 Text("Route")
                 } else {
                 Text("Select a Customer")
                 }
                 case .maps:
                 if let location = navigationManager.selectedMapLocation {
                 VStack{
                 Text("\(location.name)")
                 
                 Text("\(location.address.streetAddress)")
                 Text("\(location.address.city)")
                 Text("\(location.address.state)")
                 Text("\(location.address.zip)")
                 
                 }
                 } else {
                 Text("Select a Location")
                 }
                 
                 case .dailyDisplay:
                 //                    MobileDailyRouteDisplay(showSignInView: $showSignInView, user: user,company: company)
                 Text("Select Service Stop")
                 case .calendar:
                 Text("Select a Calendar")
                 
                 //                case .profile:
                 //                    if navigationManager.user != nil {
                 //                        ProfileView(user: navigationManager.user!)
                 //                    } else {
                 //                        navigationManager.showSignInView = true
                 //                    }
                 //
                 case .contract:
                 if let contract = navigationManager.selectedContract {
                 ContractDetailView(contract: contract)
                 } else {
                 if navigationManager.selectedID != nil {
                 VStack{
                 ProgressView()
                 Text("Loading...")
                 }
                 } else {
                 Text("Select a Contract")
                 
                 }
                 
                 }
                 case .pnl:
                 if let summary = navigationManager.selectedPNLSummary {
                 //                    PNLDetailView(summary: summary, showSignInView: $showSignInView, user: user)
                 Text("Select a PNL")
                 
                 } else {
                 Text("Select a PNL")
                 }
                 case .purchases:
                 if let purchase = navigationManager.selectedPurchases {
                 //                    ServiceStopDetails(serviceStop: serviceStop, showDetailsView: $showSignInView)
                 PurchaseDetailView(purchasedItems: purchase)
                 
                 } else {
                 if navigationManager.selectedID != nil {
                 VStack{
                 ProgressView()
                 Text("Loading...")
                 }
                 } else {
                 Text("Select a Purchase")
                 }
                 
                 }
                 case .jobs:
                 if let workOrder = navigationManager.selectedWorkOrder {
                 //                    WorkOrderDetailView(showSignInView: $showSignInView,user: user, workOrder: workOrder)
                 Text("WorkOrder")
                 } else {
                 Text("Select a Work Order")
                 }
                 case .management:
                 if let activeRoute = navigationManager.selectedActiveRoute{
                 UserRouteDetailView(activeRoute:activeRoute)
                 } else {
                 Text("Select Route")
                 }
                 default:
                 EmptyView()
                 }
                 */
                switch category {
                case .customers:
                    
                    if let validatedCustomer = masterDataManager.selectedCustomer {
                        CustomerDetailView(customer: validatedCustomer)
                        
                    } else {
                        if masterDataManager.selectedID != nil {
                            VStack{
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Select a Customer")
                        }
                    }
                    
                case .dashBoard:
                    Dashboard()
                case .serviceStops:
                    if let serviceStop = masterDataManager.selectedServiceStops {
                        //                    ServiceStopDetails(serviceStop: serviceStop, showDetailsView: $showSignInView)
                        ServiceStopInfoView(serviceStop: serviceStop,dataService: dataService)
                        //                    ServiceStopDetailView(serviceStop: serviceStop)
                    } else {
                        if masterDataManager.selectedID != nil {
                            VStack{
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Select a ServiceStop")
                        }
                    }
                case .databaseItems:
                    if let dataBaseItem = masterDataManager.selectedDataBaseItem {
                        DataBaseItemView(dataBaseItem:dataBaseItem)
                    } else {
                        if masterDataManager.selectedID != nil {
                            VStack{
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Select an Item")
                        }
                    }
                case .genericItems:
                    if let genericItem = masterDataManager.selectedGenericItem {
                        Text("\(genericItem.commonName)")
                    } else {
                        Text("Select A Generic Item")
                    }
                case .routeBuilder:
                    if let tech = masterDataManager.routeBuilderTech {
                        if let day = masterDataManager.routeBuilderDay {
                            
                            if masterDataManager.newRoute {
                                NewRouteView(dataService: dataService, tech: tech, day: day)
                            } else if masterDataManager.modifyRoute {
                                if let reucrringRoute = masterDataManager.recurringRoute {
                                    ModifyRecurringRoute(dataService: dataService, tech: tech, day: day,  recurringRoute: reucrringRoute)
                                }
                            } else if masterDataManager.reassignRoute {
                                if let reucrringRoute = masterDataManager.recurringRoute {
                                    
                                    ReassignRouteView(dataService: dataService, tech: tech, day: day,recurringRoute: reucrringRoute)
                                }
                            } else {
                                Text("Build a New Route")
                            }
                        } else {
                            Text("Build a New Route")
                        }
                    } else {
                        Text("Build a new Route")
                    }
                    
                    
                case .receipts:
                    Text("Purchases...")
                case .vender:
                    if let vender = masterDataManager.selectedStore {
                        StoreDetailView(store: vender)
                    } else {
                        Text("Please Select a Store")
                    }
                case .purchases:
                    if let purchase = masterDataManager.selectedPurchases {
                        //                    ServiceStopDetails(serviceStop: serviceStop, showDetailsView: $showSignInView)
                        PurchaseDetailView(purchase: purchase, dataService: dataService)
                        
                    } else {
                        if masterDataManager.selectedID != nil {
                            VStack{
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Select a Purchase")
                        }
                        
                    }
                    EmptyView()
                case .dailyDisplay:
                    //                    MobileDailyRouteDisplay(showSignInView: $showSignInView, user: user,company: company)
                    if let serviceStop = masterDataManager.selectedServiceStops {
                        ServiceStopDetailView(dataService: dataService,serviceStop:serviceStop)
                        
                    } else {
                        Text("Select Service Stop")
                    }
                case .calendar:
                    Text("Select a Calendar")
                case .contract:
                    if let contract = masterDataManager.selectedContract {
                        ContractDetailView(dataService: dataService, contract: contract)
                    } else {
                        if masterDataManager.selectedID != nil {
                            VStack{
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Select a Contract")
                            
                        }
                        
                    }
                    
                case .pnl:
                    if let pnl = masterDataManager.selectedPNLSummary {
                        PNLDetailView()
                    } else {
                        Text("Select PNL")
                    }
                    
                case .jobs:
                    if let job = masterDataManager.selectedWorkOrder {
                        JobDetailView(job: job, dataService: dataService)
                    } else {
                        Text("Select a Job")
                    }
                case .management:
                    if let activeRoute = masterDataManager.selectedActiveRoute{
                        UserRouteDetailView(dataService:dataService,activeRoute:activeRoute)
                    } else if masterDataManager.selectedActiveRouteList.count != 0 {
                        UserRouteDetailViewAll(dataService: dataService, activeRoute: masterDataManager.selectedActiveRouteList)
                    } else {
                        Text("Select Route")
                    }
                case .chat:
                    if let chat = masterDataManager.selectedChat{
                        ChatDetailView(dataService:dataService,chat:chat)
                    } else {
                        Text("Select Chat")
                    }
                case .repairRequest:
                    if let repair = masterDataManager.selectedRepairRequest{
                        RepairRequestDetailView(dataService: dataService,repairRequest: repair)
                    } else {
                        Text("Selected Repair Request")
                    }
                case .marketPlace:
                    Text("Market Place")
                case .jobPosting:
                    Text("Job Posting")
                case .feed:
                    Text("Feed")
                case .reports:
                    ReportDetailView(dataService: dataService)
                case .userRoles:
                    Text("User Roles")
                case .users:
                    Text("Users")
                case .fleet:
                    FleetDetailView()
                case .readingsAndDosages:
                    if masterDataManager.selectedReadingsTemplate != nil  {
                        ReadingsDetail()
                    } else if masterDataManager.selectedDosageTemplate != nil {
                        DosageDetail()
                    } else {
                        Text("Select Reading Or Dosage")
                    }
                default:
                    EmptyView()
                }
                
            } else {
                Text("Select something")
                
            }
            
        }
        .navigationBarBackground()
        
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let company = masterDataManager.selectedCompany, let selectedId = id {
                switch masterDataManager.selectedCategory{
                case .reports:
                    Task{
                        print("Report")
                    }
                case .dailyDisplay:
                    print("Daily Display Change in id \(selectedId)")
                    Task{
                        do{
                            try await serviceStopVM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                            masterDataManager.selectedServiceStops = serviceStopVM.serviceStop
                        } catch {
                            print("Failed to get service stops")
                        }
                    }
                case .management:
                    print("Add Managment Function")
                case .repairRequest:
                    Task{
                        do {
                            try await repairRequestVM.getSpecificRepairRequest(companyId: company.id, repairRequestId: selectedId)
                            masterDataManager.selectedRepairRequest = repairRequestVM.contract
                            print("Successfully Get Repair Request")
                            
                        } catch {
                            print("Failed to Get Repair Request")
                        }
                    }
                case .chat:
                    Task{
                        do {
                            try await chatVM.getSpecificChat(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedChat = chatVM.chat
                            print("Successfully Got Chat - Detail View")
                            
                        } catch {
                            print("Failed to Get Chat")
                        }
                    }
                case .jobs:
                    Task{
                        do {
                            try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedWorkOrder = jobVM.workOrder
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                case .customers:
                    Task{
                        do {
                            try await customerVM.getCustomer(companyId : company.id, customerId : selectedId)
                            masterDataManager.selectedCustomer = customerVM.customer
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                case .serviceStops:
                    Task{
                        do {
                            try await serviceStopVM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                            masterDataManager.selectedServiceStops = serviceStopVM.serviceStop
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .databaseItems:
                    Task{
                        do {
                            try await dataBaseItemVM.getSingleItem(companyId: company.id, dataBaseItemId: selectedId)
                            masterDataManager.selectedDataBaseItem = dataBaseItemVM.dataBaseItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .purchases:
                    Task{
                        do {
                            try await purchaseVM.getSinglePurchasedItem(itemId: selectedId, companyId: company.id)
                            masterDataManager.selectedPurchases = purchaseVM.purchasedItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .contract:
                    Task{
                        do {
                            try await contractVM.getSpecificContract(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedContract = contractVM.contract
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                    
                default:
                    print("Default")
                }
                
            }
        })
    }
    
}


