//
//  DetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//
//
//TBH I Can Probably Get Rid Of this

import SwiftUI
@MainActor
final class DetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var serviceStop: ServiceStop? = nil
    @Published private(set) var repairRequest: RepairRequest? = nil
    @Published private(set) var chat: Chat? = nil
    @Published private(set) var workOrder: Job? = nil
    @Published private(set) var dataBaseItem: DataBaseItem? = nil
    @Published private(set) var purchasedItem: PurchasedItem? = nil
    @Published private(set) var contract: RecurringContract? = nil
    @Published private(set) var customer: Customer? = nil

    func getServiceStopById(companyId:String,serviceStopId:String) async throws {
        self.serviceStop = try await dataService.getServiceStopById(serviceStopId:serviceStopId, companyId: companyId)
    }
    func getSpecificRepairRequest(companyId: String,repairRequestId:String) async throws {
        self.repairRequest = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: repairRequestId)
    }
    
    func getSpecificChat(companyId: String,contractId:String) async throws {
        self.chat = try await dataService.getSpecificChat(chatId: contractId)
    }
    
    func getSingleWorkOrder(companyId: String,WorkOrderId:String) async throws{
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: WorkOrderId)
    }
    func getSingleItem(companyId:String,dataBaseItemId:String) async throws{
        self.dataBaseItem = try await DatabaseManager.shared.getDataBaseItem(companyId: companyId, dataBaseItemId: dataBaseItemId)
    }
    func getSinglePurchasedItem(itemId:String,companyId: String) async throws {
                self.purchasedItem = try await dataService.getSingleItem(itemId: itemId, companyId: companyId)
    }
    func getSpecificContract(companyId: String,contractId:String) async throws {
        self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: contractId)
    }
    func getCustomer(companyId: String,customerId:String) async throws{
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        
    }
}
struct DetailView: View {
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : DetailViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: DetailViewModel(dataService: dataService))
    }
    
    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    @State var isPresented:Bool = false
    let cat:MacCategories = .calendar
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if let category = masterDataManager.selectedCategory {
                    switch category {
                    case .taskGroups:
                        if let selectedTaskGroup = masterDataManager.selectedTaskGroup {
                            TaskGroupDetailView(dataService: dataService, taskGroup: selectedTaskGroup)
                        } else {
                            Text("Select a Task Group")
                        }
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
                            DataBaseItemView(dataService: dataService, dataBaseItem:dataBaseItem)
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
                        //Internal Routes
                    case .routeBuilder:
                        if let tech = masterDataManager.selectedRouteBuilderTech {
                            if let day = masterDataManager.selectedRouteBuilderDay {
                                
                                if masterDataManager.newRoute {
                                    NewRouteView(dataService: dataService, tech: tech, day: day)
                                } else if masterDataManager.modifyRoute {
                                    if let reucrringRoute = masterDataManager.selectedRecurringRoute {
                                       ModifyRecurringRoute(dataService: dataService, tech: tech, day: day, recurringRoute: reucrringRoute)
                                    } else {
                                        Text("ModifyRecurringRoute")
                                    }
                                } else if masterDataManager.reassignRoute {
                                    if let reucrringRoute = masterDataManager.selectedRecurringRoute {
                                        ReassignRouteView(dataService: dataService, tech: tech, day: day,recurringRoute: reucrringRoute)
                                    } else {
                                        Text("ReassignRouteView")
                                    }
                                } else {
                                    Text("Build a New Route 1")
                                }
                            } else {
                                Text("Build a New Route 2")
                            }
                        } else {
                            Text("Build a new Route 3")
                        }
                    case .receipts:
                        if let receipt = masterDataManager.selectedReceipt {
                            ReceiptDetailView(receipt: receipt)
                        } else {
                            Text("Please Selected A Receipt To View")
                        }
                    case .vender:
                        if let vender = masterDataManager.selectedVender {
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
                        if let job = masterDataManager.selectedJob {
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
                            Text("Please Select Repair Request To View")
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
                        if let role = masterDataManager.selectedRole {
                            CompanyRoleDetailView(role:role)
                        } else {
                            Text("Please Select A Role To View")
                        }
                        
                        
                    case .users:
                        //                    if let tech = masterDataManager.selectedTech1 {
                        //                        TechDetailView(dataService: dataService, tech: tech)
                        //                    } else {
                        //                        Text("Please Select A User To View")
                        //                    }
                        if let user = masterDataManager.selectedCompanyUser {
                            CompanyUserDetailView(dataService: dataService, companyUser: user)
                        } else {
                            Text("Please Select A User To View")
                        }
                    case .companyUser:
                        if let user = masterDataManager.selectedCompanyUser {
                            CompanyUserDetailView(dataService: dataService, companyUser: user)
                        } else {
                            Text("Please Select A Company User To View")
                        }
                    case .fleet:
                        if let vehical = masterDataManager.selectedVehical {
                            VehicalDetailView(dataService:dataService,vehical:vehical)
                        } else {
                            Text("Please Select A Vehical")
                        }
                    case .readingsAndDosages:
                        if masterDataManager.selectedReadingsTemplate != nil  {
                            ReadingsDetail()
                        } else if masterDataManager.selectedDosageTemplate != nil {
                            DosageDetail()
                        } else {
                            Text("Select Reading Or Dosage")
                        }
                    case .profile:
                        EmptyView()
                    case .companyProfile:
                        if let currentCompany = masterDataManager.currentCompany { //DEVELOPER FIX BEFORE MAC RELEASE
                            CompanyProfileView(dataService: dataService, company: currentCompany)
                        }
                    case .maps:
                        EmptyView()
                    case .companyRouteOverView:
                        EmptyView()
                    case .accountsPayable:
                        if let accountsPayableInvoice = masterDataManager.selectedAccountsPayableInvoice {
                            AccountsPayableDetail(invoice: accountsPayableInvoice)
                        } else {
                            Text("Please Select An Invoice")
                        }
                    case .accountsReceivable:
                        if let accountsReceivableInvoice = masterDataManager.selectedAccountsReceivableInvoice {
                            AccountsReceivableDetail(invoice: accountsReceivableInvoice)
                        } else {
                            Text("Please Select An Invoice")
                        }
                    case .equipment:
                        if let equipment = masterDataManager.selectedEquipment {
                            EquipmentDetailView(dataService: dataService, equipment: equipment)
                        } else {
                            Text("Please Select An Equipment")
                        }
                    case .settings:
                        EmptyView()
                    case .jobTemplates:
                        if let jobTemplate = masterDataManager.selectedJobTemplate {
                            JobTemplateDetailView(template: jobTemplate)
                        } else {
                            Text("Please Select An Job Template")
                        }
                    case .contracts:
                        if let contract = masterDataManager.selectedContract {
                            ContractDetailView(dataService: dataService, contract: contract)
                        } else {
                            Text("Please selected a Contract")
                        }
                    case .alerts:
                        AlertDetailView()
                    case .shoppingList:
                        if let item = masterDataManager.selectedShoppingListItem {
                            ShoppingListItemDetailView(item: item, dataService: dataService)
                        } else {
                            Text("Please Selected a Shopping List Item")
                        }
                    case .businesses:
                        if let business = masterDataManager.selectedBuisness {
                            BusinessDetailView(dataService: dataService, business: business)
                        } else {
                            Text("Please Selected a Buisness")
                        }
                    case .companyAlerts:
                        Text("Actually I do not Know if there is anything I want to Be Here")
                    case .personalAlerts:
                        Text("DEVELOPER DEAL WITH something")

                    case .sentLaborContracts, .receivedLaborContracts:
                        if let laborContract = masterDataManager.selectedRecurringLaborContract {
                            RecurringLaborContractDetailView(dataService: dataService, laborContract: laborContract)
                        } else {
                            Text("Please Select a Labor Contract")
                        }
                    case .externalRoutesOverview:
                        Text("DEVELOPER Need to Build Out")
                    case .managementTables:
//                        Text("Please Stop Fucking About")
                        ManagementTablesView(dataService: dataService)
                    }
                } else {
                    Text("Select a Category")
                }
            }
        }
        .navigationBarBackground()
        .task {
            if let company = masterDataManager.currentCompany, let selectedId = masterDataManager.selectedID {
                switch masterDataManager.selectedCategory{
                case .reports:
                    Task{
                        print("Report")
                    }
                case .dailyDisplay:
                    print("Daily Display Change in id \(selectedId)")
                    
                    Task{
                        if selectedId != masterDataManager.selectedServiceStops?.id {
                            do {
                                masterDataManager.selectedServiceStops = nil
                                try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                                masterDataManager.selectedServiceStops = VM.serviceStop
                                print("Success")
                            } catch {
                                print("Failed")
                            }
                        } else {
                            do {
                                try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                                masterDataManager.selectedServiceStops = VM.serviceStop
                                print("Success")
                            } catch {
                                print("Failed")
                            }
                        }
                    }
                case .management:
                    print("Add Managment Function")
                case .repairRequest:
                    Task{
                        do {
                            try await VM.getSpecificRepairRequest(companyId: company.id, repairRequestId: selectedId)
                            masterDataManager.selectedRepairRequest = VM.repairRequest
                            print("Successfully Get Repair Request")
                            
                        } catch {
                            print("Failed to Get Repair Request")
                        }
                    }
                case .chat:
                    Task{
                        do {
                            try await VM.getSpecificChat(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedChat = VM.chat
                            print("Successfully Got Chat - Detail View")
                            
                        } catch {
                            print("Failed to Get Chat")
                        }
                    }
                case .jobs:
                    Task{
                        do {
                            try await VM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedJob = VM.workOrder
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                case .customers:
                    Task{
                        do {
                            try await VM.getCustomer(companyId : company.id, customerId : selectedId)
                            masterDataManager.selectedCustomer = VM.customer
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                    print("Customer Detail View Logic")
                case .serviceStops:
                    Task{
                        do {
                            try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                            masterDataManager.selectedServiceStops = VM.serviceStop
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .databaseItems:
                    Task{
                        do {
                            try await VM.getSingleItem(companyId: company.id, dataBaseItemId: selectedId)
                            masterDataManager.selectedDataBaseItem = VM.dataBaseItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .purchases:
                    Task{
                        do {
                            try await VM.getSinglePurchasedItem(itemId: selectedId, companyId: company.id)
                            masterDataManager.selectedPurchases = VM.purchasedItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .contract:
                    Task{
                        do {
                            try await VM.getSpecificContract(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedContract = VM.contract
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
               
                default:
                    print("Default")
                }
                
            }
        }
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let company = masterDataManager.currentCompany, let selectedId = id {
                switch masterDataManager.selectedCategory{
                case .reports:
                    Task{
                        print("Report")
                    }
                case .dailyDisplay:
                    print("Daily Display Change in id \(selectedId)")
                    
                    Task{
                        if selectedId != masterDataManager.selectedServiceStops?.id {
                            do {
                                masterDataManager.selectedServiceStops = nil
                                try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                                masterDataManager.selectedServiceStops = VM.serviceStop
                                print("Success")
                            } catch {
                                print("Failed")
                            }
                        } else {
                            do {
                                try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                                masterDataManager.selectedServiceStops = VM.serviceStop
                                print("Success")
                            } catch {
                                print("Failed")
                            }
                        }
                    }
                case .management:
                    print("Add Managment Function")
                case .repairRequest:
                    Task{
                        do {
                            try await VM.getSpecificRepairRequest(companyId: company.id, repairRequestId: selectedId)
                            masterDataManager.selectedRepairRequest = VM.repairRequest
                            print("Successfully Get Repair Request")
                            
                        } catch {
                            print("Failed to Get Repair Request")
                        }
                    }
                case .chat:
                    Task{
                        do {
                            try await VM.getSpecificChat(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedChat = VM.chat
                            print("Successfully Got Chat - Detail View")
                            
                        } catch {
                            print("Failed to Get Chat")
                        }
                    }
                case .jobs:
                    Task{
                        do {
                            try await VM.getSingleWorkOrder(companyId: company.id, WorkOrderId: selectedId)
                            masterDataManager.selectedJob = VM.workOrder
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                case .customers:
                    Task{
                        do {
                            try await VM.getCustomer(companyId : company.id, customerId : selectedId)
                            masterDataManager.selectedCustomer = VM.customer
                            print("Successfully Get Customer")
                            
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                    print("Customer Detail View Logic")
                case .serviceStops:
                    Task{
                        do {
                            try await VM.getServiceStopById(companyId: company.id, serviceStopId: selectedId)
                            masterDataManager.selectedServiceStops = VM.serviceStop
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .databaseItems:
                    Task{
                        do {
                            try await VM.getSingleItem(companyId: company.id, dataBaseItemId: selectedId)
                            masterDataManager.selectedDataBaseItem = VM.dataBaseItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .purchases:
                    Task{
                        do {
                            try await VM.getSinglePurchasedItem(itemId: selectedId, companyId: company.id)
                            masterDataManager.selectedPurchases = VM.purchasedItem
                            print("Success")
                        } catch {
                            print("Failed")
                        }
                    }
                case .contract:
                    Task{
                        do {
                            try await VM.getSpecificContract(companyId: company.id, contractId: selectedId)
                            masterDataManager.selectedContract = VM.contract
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
        .onChange(of: masterDataManager.selectedCategory, perform: { cat in
            print("Detail View  Selected Category \(cat)")
        })
    }
}
