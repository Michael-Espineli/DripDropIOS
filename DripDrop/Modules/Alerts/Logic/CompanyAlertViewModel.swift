//
//  CompanyAlertViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import Foundation
import SwiftUI

struct DripDropAlert:Identifiable,Hashable,Codable{
    var id:String = UUID().uuidString
    var category:MacCategories
    var route:RouteString
    var itemId:String
    var name:String
    var description:String
    var date:Date
}
@MainActor
final class CompanyAlertViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var isLoading:Bool = false
    
    @Published private(set) var alertList:[DripDropAlert] = []
    @Published private(set) var route:Route? = nil
    @Published private(set) var category:MacCategories? = nil
    
    //SelectedItem
    
    @Published private(set) var associatedBusiness:AssociatedBusiness? = nil

    @Published private(set) var customer:Customer? = nil
    @Published private(set) var company:Company? = nil

    @Published private(set) var contract:Contract? = nil
    @Published private(set) var chat:Chat? = nil
    @Published private(set) var companyUser:CompanyUser? = nil

    @Published private(set) var dataBaseItem:DataBaseItem? = nil
    
    @Published private(set) var equipment:Equipment? = nil

    @Published private(set) var genericItem:GenericItem? = nil
    
    @Published private(set) var job:Job? = nil
    @Published private(set) var jobTemplate:JobTemplate? = nil
    
    @Published private(set) var laborContract:RepeatingLaborContract? = nil

    @Published private(set) var purchase:PurchasedItem? = nil

    @Published private(set) var receipt:Receipt? = nil
    @Published private(set) var role:Role? = nil
    @Published private(set) var repairRequest:RepairRequest? = nil
    
    @Published private(set) var stripeInvoice:StripeInvoice? = nil
    @Published private(set) var shoppingListItem:ShoppingListItem? = nil
    @Published private(set) var serviceStop:ServiceStop? = nil
    
    @Published private(set) var vender:Vender? = nil
    
    @Published private(set) var vehical:Vehical? = nil
    
    //Functions
    func getAlertsByCompany(companyId:String) async throws {
        self.alertList = try await dataService.getDripDropAlerts(companyId: companyId)
    }
    func createAlert(companyId:String,alert:DripDropAlert) async throws {
        try await dataService.addDripDropAlert(companyId: companyId, dripDropAlert: alert)
    }
    func getAlertDestination(companyId:String,alert:DripDropAlert)async throws{
        self.isLoading = true
        
        self.category = alert.category

        if alert.itemId != "" {
            if UIDevice.isIPhone {
                if alert.route.hasItem() {
                    switch alert.route {
                    case .operation, .finace, .managment , .dashBoard, .customers, .toDoDetail, .repairRequestList, .toDoList, .pendingJobs, .shoppingList, .purchasedItemsList, .map, .dailyDisplay, .calendar, .profile, .routeBuilder, .pnl, .companyRouteOverView, .reports, .fleet, .mainDailyDisplayView, .serviceStops, .jobs, .contracts, .purchases, .receipts, .databaseItems, .genericItems, .venders, .users, .userRoles, .readingsAndDosages, .marketPlace, .jobPosing, .feed, .chats, .equipmentList, .routes, .settings, .userSettings, .companySettings, .jobTemplates, .accountsPayableList, .accountsReceivableList, .businesses, .alerts, .cart, .recentActivity, .laborContracts, .companyAlerts, .externalRouteOverView, .activeRouteOverView:
                        print("No Item To Get")
                        
                    case .editUser:
                        print("Developer Update Edit User")
                        
                    case .rateSheet:
                        print("Developer Update Rate Sheet")
                        
                    case .companyUserRateSheet:
                        print("Developer Update Rate Sheet")
                        
                    case .compileInvoice:
                        print("No Item for compileInvoice")
                        
                    case .createNewJob:
                        print("No Item for createNewJob")
                        
                    case .createRepairRequest:
                        print("No Item for createRepairRequest")
                        
                    case .createCustomer:
                        print("No Item for createCustomer")
                        
                    case .equipmentDetailView:
                        print("No Item for equipmentDetailView")
                    case .allTechRouteOverview:
                        print("Developer Needs more Help")
                        self.route = Route.allTechRouteOverview(route: [], dataService: dataService)
                        
                    case .routeOverview:
                        let item = try await dataService.getActiveRoute(companyId: companyId, activeRouteId: alert.itemId)
                        self.route = Route.routeOverview(route: item, dataService: dataService)
   
                    case .dailyDisplayStop:
                        let item = try await dataService.getServiceStopById(serviceStopId: alert.itemId, companyId: companyId)
                        self.route = Route.dailyDisplayStop(dataService: dataService, serviceStop: item)
                        
                        
                    case .jobTemplate:
                        let item = try await dataService.getJobTemplate(companyId: companyId, templateId: alert.itemId)
                        self.route = Route.jobTemplate(jobTemplate: item, dataService: dataService)
                        
                    case .shoppingListDetail:
                        let item = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: alert.itemId)
                        self.route = Route.shoppingListDetail(item: item, dataService: dataService)
                        
                    case .purchase:
                        let item = try await dataService.getSingleItem(itemId: alert.itemId, companyId: companyId)
                        self.route = Route.purchase(purchasedItem: item, dataService: dataService)
                        
                    case .job:
                        let item:Job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: alert.itemId)
                        self.route = Route.job(job: item, dataService: dataService)
                        
                    case .chat:
                        let item:Chat = try await dataService.getSpecificChat(chatId: alert.itemId)
                        self.route = Route.chat(chat: item, dataService: dataService)
                        
                    case .repairRequest:
                        let item = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: alert.itemId)
                        self.route = Route.repairRequest(repairRequest: item, dataService: dataService)
                        
                    case .customer:
                        let item = try await dataService.getCustomerById(companyId: companyId, customerId: alert.itemId)
                        self.route = Route.customer(customer: item, dataService: dataService)
                        
                    case .serviceStop:
                        let item = try await dataService.getServiceStopById(serviceStopId: alert.itemId, companyId: companyId)
                        self.route = Route.serviceStop(serviceStop: item, dataService: dataService)
                        
                    case .business:
                        let item = try await dataService.getAssociatedBusiness(companyId: companyId, businessId: alert.itemId)
                        self.route = Route.business(business: item, dataService: dataService)
                        
                    case .vender:
                        let item = try await dataService.getSingleStore(companyId: companyId, storeId: alert.itemId)
                        self.route = Route.vender(vender: item, dataService: dataService)
                        
                    case .dataBaseItem:
                        let item = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: alert.itemId)
                        self.route = Route.dataBaseItem(dataBaseItem: item, dataService: dataService)
                        
                    case .contract:
                        let item = try await dataService.getSpecificContract(companyId: companyId, contractId: alert.itemId)
                        self.route = Route.contract(contract: item, dataService: dataService)
                        
                    case .genericItem:
                        let item = try await dataService.getGenericItem(companyId: companyId, genericItemId: alert.itemId)
                        self.route = Route.genericItem(item: item, dataService: dataService)
                        
                    case .readingTemplate:
                        let item = try await dataService.getReadingTemplate(companyId: companyId,readingTemplateId:alert.itemId)
                        self.route = Route.readingTemplate(tempalte: item, dataService: dataService)
                        
                    case .dosageTemplate:
                        let item = try await dataService.getDosageTemplate(companyId: companyId,dosageTemplateId:alert.itemId)
                        self.route = Route.dosageTemplate(template: item, dataService: dataService)
                        
                    case .receipt:
                        let item:Receipt = try await dataService.getReceipt(companyId: companyId, receiptId: alert.itemId)
                        self.route = Route.receipt(receipt: item, dataService: dataService)
                        
                    case .companyProfile:
                        let item = try await dataService.getCompany(companyId: alert.itemId)
                        self.route = Route.companyProfile(company: item, dataService: dataService)
                        
                    case .vehicalDetailView:
                        let item = try await dataService.getVehical(companyId: companyId, vehicalId: alert.itemId)
                        self.route = Route.vehicalDetailView(vehical: item, dataService: dataService)
                        
                    case .accountsPayableDetail:
                        let item = try await dataService.getAccountsPayableInvoice(companyId: companyId, invoiceId: alert.itemId)
                        self.route = Route.accountsPayableDetail(invoice: item, dataService: dataService)
                        
                    case .accountsReceivableDetail:
                        let item = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: alert.itemId)
                        self.route = Route.accountsReceivableDetail(invoice: item, dataService: dataService)
                        
                    case .companyUserDetailView:
                        let item = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: alert.itemId)
                        self.route = Route.companyUserDetailView(user: item, dataService: dataService)
                        
                    case .laborContractDetailView:
                        let item = try await dataService.getLaborContract(companyId: companyId, laborContractId: alert.itemId)
                        self.route = Route.laborContractDetailView(contract: item, dataService: dataService)
               
                    case .banks:
                        print("No Item To Get")

                    case .transactions:
                        print("No Item To Get")

                    case .bankDetailView:
                        print("Developer Build out")
                    case .transactionDetailView:
                        print("Developer Build out")

                    }
                }
            } else {
                switch alert.category {
                case .profile:
                    print("reports Not Built Out Yet")
                case .dashBoard:
                    print("dashBoard Does Not Need Item")
                case .dailyDisplay:
                    print("dailyDisplay Does Not Need Item")
                case .routeBuilder:
                    print("routeBuilder Need more complex Logic")
                case .management:
                    print("Developer Make function for getting management by Id")
                case .pnl:
                    print("PNL Not Built Out Yet")
                case .companyProfile:
                    print("reports Not Built Out Yet")
                case .reports:
                    print("reports Not Built Out Yet")
                case .readingsAndDosages:
                    print("routeBuilder Need more complex Logic")
                case .calendar:
                    print("Calendar Not Built Out Yet")
                case .maps:
                    print("maps Not Built Out Yet")
                case .companyAlerts:
                    print("companyAlerts Not Built Out Yet")
                case .personalAlerts:
                    print("personalAlerts Not Built Out Yet")
                case .marketPlace:
                    print("MarketPlace Not Built Out Yet")
                case .jobPosting:
                    print("JobPosting Not Built Out Yet")
                case .feed:
                    print("Feed Not Built Out Yet")
                case .companyRouteOverView:
                    print("reports Not Built Out Yet")
         
                case .settings:
                    print("Settings Not Built Out Yet")
       
                case .alerts:
                    print("alerts Not Built Out Yet")
                case .externalRoutesOverview:
                    print("No Item to get")
                case .laborContracts:
                    self.laborContract = try await dataService.getLaborContract(companyId: companyId, laborContractId: alert.itemId)
                case .accountsPayable:
                    self.stripeInvoice = try await dataService.getAccountsPayableInvoice(companyId: companyId, invoiceId: alert.itemId)
                case .accountsReceivable:
                    self.stripeInvoice = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: alert.itemId)
                case .jobTemplates:
                    self.jobTemplate = try await dataService.getJobTemplate(companyId: companyId, templateId: alert.itemId)
                case .customers:
                    self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: alert.itemId)
                case .serviceStops:
                    self.serviceStop = try await dataService.getServiceStopById(serviceStopId: alert.itemId, companyId: companyId)
                case .fleet:
                    self.vehical = try await dataService.getVehical(companyId: companyId, vehicalId: alert.itemId)
                case .jobs:
                    self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: alert.itemId)
                case .repairRequest:
                    self.repairRequest = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: alert.itemId)
                case .contract://DEVELOPER MAYBE GET RID OF
                    self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: alert.itemId)
                case .purchases:
                    self.purchase = try await dataService.getSingleItem(itemId: alert.itemId, companyId: companyId)
                case .receipts:
                    self.receipt = try await dataService.getReceipt(companyId: companyId, receiptId: alert.itemId)
                case .databaseItems:
                    self.dataBaseItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: alert.itemId)
                case .genericItems:
                    self.genericItem = try await dataService.getGenericItem(companyId: companyId, genericItemId: alert.itemId)
                case .vender:
                    self.vender = try await dataService.getSingleStore(companyId: companyId, storeId: alert.itemId)
                case .users:
                    self.companyUser = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: alert.itemId)
                case .userRoles:
                    self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: alert.itemId)
                case .chat:
                    self.chat = try await dataService.getSpecificChat(chatId: alert.itemId)
                case .equipment:
                    self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: alert.itemId)
                case .contracts:
                    self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: alert.itemId)
                case .shoppingList:
                    self.shoppingListItem = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: alert.itemId)
                case .businesses:
                    self.associatedBusiness = try await dataService.getAssociatedBusiness(companyId: companyId, businessId: alert.itemId)
                case .companyUser:
                    self.companyUser = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: alert.itemId)
                    
                }
            }
        } else {
            print("No Item Id")
                switch alert.route {
                case .cart:
                    print("Has Item")
                case .editUser:
                    print("Developer Update Edit User")
                    
                case .rateSheet:
                    print("Developer Update Rate Sheet")
                    
                case .companyUserRateSheet:
                    print("Developer Update Rate Sheet")
                    
                case .operation:
                    self.route = Route.operation(dataService: dataService)
                case .finace:
                    self.route = Route.finace(dataService: dataService)
                case .managment:
                    self.route = Route.managment(dataService: dataService)
                case .dashBoard:
                    self.route = Route.dashBoard(dataService: dataService)
                case .customers:
                    self.route = Route.customers(dataService: dataService)
                case .toDoDetail:
                    self.route = Route.toDoDetail(dataService: dataService)
                case .repairRequestList:
                    self.route = Route.repairRequestList(dataService: dataService)
                case .toDoList:
                    self.route = Route.toDoList(dataService: dataService)
                case .pendingJobs:
                    self.route = Route.pendingJobs(dataService: dataService)
                case .shoppingList:
                    self.route = Route.shoppingList(dataService: dataService)
                case .purchasedItemsList:
                     self.route = Route.purchasedItemsList(dataService: dataService)
                case .map:
                     self.route = Route.map(dataService: dataService)
                case .dailyDisplay:
                     self.route = Route.dailyDisplay(dataService: dataService)
                case .calendar:
                     self.route = Route.calendar(dataService: dataService)
                case .profile:
                     self.route = Route.profile(dataService: dataService)
                case .routeBuilder:
                     self.route = Route.routeBuilder(dataService: dataService)
                case .pnl:
                     self.route = Route.pnl(dataService: dataService)
                case .companyRouteOverView:
                     self.route = Route.companyRouteOverView(dataService: dataService)
                case .reports:
                     self.route = Route.reports(dataService: dataService)
                case .fleet:
                     self.route = Route.fleet(dataService: dataService)
                case .mainDailyDisplayView:
                     self.route = Route.mainDailyDisplayView(dataService: dataService)
                case .serviceStops:
                     self.route = Route.serviceStops(dataService: dataService)
                case .jobs:
                     self.route = Route.jobs(dataService: dataService)
                case .contracts:
                     self.route = Route.contracts(dataService: dataService)
                case .purchases:
                     self.route = Route.purchases(dataService: dataService)
                case .receipts:
                     self.route = Route.receipts(dataService: dataService)
                case .databaseItems:
                     self.route = Route.databaseItems(dataService: dataService)
                case .genericItems:
                     self.route = Route.genericItems(dataService: dataService)
                case .venders:
                     self.route = Route.venders(dataService: dataService)
                case .users:
                     self.route = Route.users(dataService: dataService)
                case .userRoles:
                     self.route = Route.userRoles(dataService: dataService)
                case .readingsAndDosages:
                     self.route = Route.readingsAndDosages(dataService: dataService)
                case .marketPlace:
                     self.route = Route.marketPlace(dataService: dataService)
                case .jobPosing:
                     self.route = Route.jobPosting(dataService: dataService)
                case .feed:
                     self.route = Route.feed(dataService: dataService)
                case .chats:
                     self.route = Route.chats(dataService: dataService)
                case .equipmentList:
                     self.route = Route.equipmentList(dataService: dataService)
                case .routes:
                     self.route = Route.routes(dataService: dataService)
                case .settings:
                     self.route = Route.settings(dataService: dataService)
                case .userSettings:
                     self.route = Route.userSettings(dataService: dataService)
                case .companySettings:
                     self.route = Route.companySettings(dataService: dataService)
                case .jobTemplates:
                     self.route = Route.jobTemplates(dataService: dataService)
                case .accountsPayableList:
                     self.route = Route.accountsPayableList(dataService: dataService)
                case .accountsReceivableList:
                     self.route = Route.accountsReceivableList(dataService: dataService)
                case .businesses:
                     self.route = Route.businesses(dataService: dataService)
                case .alerts:
                     self.route = Route.alerts(dataService: dataService)
                case .recentActivity:
                     self.route = Route.recentActivity(dataService: dataService)
                case .compileInvoice:
                    self.route = Route.compileInvoice(dataService: dataService)
                case .createNewJob:
                    self.route = Route.createNewJob(dataService: dataService)
                case .createRepairRequest:
                    self.route = Route.createRepairRequest(dataService: dataService)
                case .createCustomer:
                    self.route = Route.createCustomer(dataService: dataService)
                case .equipmentDetailView:
                    self.route = Route.equipmentDetailView(dataService: dataService)
                case .laborContracts:
                    self.route = Route.laborContracts(dataService: dataService)
                    //All the Below are detil with Higher
                case .shoppingListDetail,.purchase,.job,.chat,.repairRequest,.customer,.serviceStop,.business,.vender,.dataBaseItem,.contract,.genericItem,.readingTemplate,.dosageTemplate,.receipt,.companyProfile,.vehicalDetailView,.accountsPayableDetail,.accountsReceivableDetail,.laborContractDetailView, .companyUserDetailView, .jobTemplate, .routeOverview, .allTechRouteOverview, .dailyDisplayStop, .bankDetailView, .transactionDetailView:
                    print("Detalt With Higher Above")
                case .companyAlerts:
                    self.route = Route.companyAlerts(dataService: dataService)

                case .externalRouteOverView:
                    self.route = Route.externalRouteOverView(dataService: dataService)
                case .banks:
                    print("Developer please build out")

                case .transactions:
                    print("Developer please build out")
                case .activeRouteOverView:
                    print("Please build out")
                }
            
        }
        self.isLoading = false
    }
    
    func getRecentActivityDestination(recentActivity:RecentActivityModel)async throws{
        self.isLoading = true
        
        //Get Company
        let companyId = recentActivity.companyId
        self.company = try await dataService.getCompany(companyId: companyId)
        self.category = recentActivity.category

        if recentActivity.itemId != "" {
            if UIDevice.isIPhone {
                if recentActivity.route.hasItem() {
                    switch recentActivity.route {
                    case .operation, .finace, .managment , .dashBoard, .customers, .toDoDetail, .repairRequestList, .toDoList, .pendingJobs, .shoppingList, .purchasedItemsList, .map, .dailyDisplay, .calendar, .profile, .routeBuilder, .pnl, .companyRouteOverView, .reports, .fleet, .mainDailyDisplayView, .serviceStops, .jobs, .contracts, .purchases, .receipts, .databaseItems, .genericItems, .venders, .users, .userRoles, .readingsAndDosages, .marketPlace, .jobPosing, .feed, .chats, .equipmentList, .routes, .settings, .userSettings, .companySettings, .jobTemplates, .accountsPayableList, .accountsReceivableList, .businesses, .alerts, .cart, .recentActivity, .laborContracts, .companyAlerts, .externalRouteOverView, .banks, .transactions, .activeRouteOverView:
                        print("No Item To Get")
                        
                    case .editUser:
                        print("Developer Update Edit User")
                        
                    case .rateSheet:
                        print("Developer Update Rate Sheet")
                        
                    case .companyUserRateSheet:
                        print("Developer Update Rate Sheet")
                        
                    case .compileInvoice:
                        print("No Item for compileInvoice")
                        
                    case .createNewJob:
                        print("No Item for createNewJob")
                        
                    case .createRepairRequest:
                        print("No Item for createRepairRequest")
                        
                    case .createCustomer:
                        print("No Item for createCustomer")
                        
                    case .equipmentDetailView:
                        print("No Item for equipmentDetailView")
                    case .allTechRouteOverview:
                        print("Developer Needs more Help")
                        self.route = Route.allTechRouteOverview(route: [], dataService: dataService)
                        
                    case .routeOverview:
                        let item = try await dataService.getActiveRoute(companyId: companyId, activeRouteId: recentActivity.itemId)
                        self.route = Route.routeOverview(route: item, dataService: dataService)
   
                    case .dailyDisplayStop:
                        let item = try await dataService.getServiceStopById(serviceStopId: recentActivity.itemId, companyId: companyId)
                        self.route = Route.dailyDisplayStop(dataService: dataService, serviceStop: item)
                        
                        
                    case .jobTemplate:
                        let item = try await dataService.getJobTemplate(companyId: companyId, templateId: recentActivity.itemId)
                        self.route = Route.jobTemplate(jobTemplate: item, dataService: dataService)
                        
                    case .shoppingListDetail:
                        let item = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: recentActivity.itemId)
                        self.route = Route.shoppingListDetail(item: item, dataService: dataService)
                        
                    case .purchase:
                        let item = try await dataService.getSingleItem(itemId: recentActivity.itemId, companyId: companyId)
                        self.route = Route.purchase(purchasedItem: item, dataService: dataService)
                        
                    case .job:
                        let item:Job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: recentActivity.itemId)
                        self.route = Route.job(job: item, dataService: dataService)
                        
                    case .chat:
                        let item:Chat = try await dataService.getSpecificChat(chatId: recentActivity.itemId)
                        self.route = Route.chat(chat: item, dataService: dataService)
                        
                    case .repairRequest:
                        let item = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: recentActivity.itemId)
                        self.route = Route.repairRequest(repairRequest: item, dataService: dataService)
                        
                    case .customer:
                        let item = try await dataService.getCustomerById(companyId: companyId, customerId: recentActivity.itemId)
                        self.route = Route.customer(customer: item, dataService: dataService)
                        
                    case .serviceStop:
                        let item = try await dataService.getServiceStopById(serviceStopId: recentActivity.itemId, companyId: companyId)
                        self.route = Route.serviceStop(serviceStop: item, dataService: dataService)
                        
                    case .business:
                        let item = try await dataService.getAssociatedBusiness(companyId: companyId, businessId: recentActivity.itemId)
                        self.route = Route.business(business: item, dataService: dataService)
                        
                    case .vender:
                        let item = try await dataService.getSingleStore(companyId: companyId, storeId: recentActivity.itemId)
                        self.route = Route.vender(vender: item, dataService: dataService)
                        
                    case .dataBaseItem:
                        let item = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: recentActivity.itemId)
                        self.route = Route.dataBaseItem(dataBaseItem: item, dataService: dataService)
                        
                    case .contract:
                        let item = try await dataService.getSpecificContract(companyId: companyId, contractId: recentActivity.itemId)
                        self.route = Route.contract(contract: item, dataService: dataService)
                        
                    case .genericItem:
                        let item = try await dataService.getGenericItem(companyId: companyId, genericItemId: recentActivity.itemId)
                        self.route = Route.genericItem(item: item, dataService: dataService)
                        
                    case .readingTemplate:
                        let item = try await dataService.getReadingTemplate(companyId: companyId,readingTemplateId:recentActivity.itemId)
                        self.route = Route.readingTemplate(tempalte: item, dataService: dataService)
                        
                    case .dosageTemplate:
                        let item = try await dataService.getDosageTemplate(companyId: companyId,dosageTemplateId:recentActivity.itemId)
                        self.route = Route.dosageTemplate(template: item, dataService: dataService)
                        
                    case .receipt:
                        let item:Receipt = try await dataService.getReceipt(companyId: companyId, receiptId: recentActivity.itemId)
                        self.route = Route.receipt(receipt: item, dataService: dataService)
                        
                    case .companyProfile:
                        let item = try await dataService.getCompany(companyId: recentActivity.itemId)
                        self.route = Route.companyProfile(company: item, dataService: dataService)
                        
                    case .vehicalDetailView:
                        let item = try await dataService.getVehical(companyId: companyId, vehicalId: recentActivity.itemId)
                        self.route = Route.vehicalDetailView(vehical: item, dataService: dataService)
                        
                    case .accountsPayableDetail:
                        let item = try await dataService.getAccountsPayableInvoice(companyId: companyId, invoiceId: recentActivity.itemId)
                        self.route = Route.accountsPayableDetail(invoice: item, dataService: dataService)
                        
                    case .accountsReceivableDetail:
                        let item = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: recentActivity.itemId)
                        self.route = Route.accountsReceivableDetail(invoice: item, dataService: dataService)
                        
                    case .companyUserDetailView:
                        let item = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: recentActivity.itemId)
                        self.route = Route.companyUserDetailView(user: item, dataService: dataService)
                        
                    case .laborContractDetailView:
                        let item = try await dataService.getLaborContract(companyId: companyId, laborContractId: recentActivity.itemId)
                        self.route = Route.laborContractDetailView(contract: item, dataService: dataService)
               
                        
                    case .bankDetailView:
                        print("Developer Please Build out")
                    case .transactionDetailView:
                        print("Developer Please Build out")
                    }
                }
            } else {
                switch recentActivity.category {
                case .profile:
                    print("reports Not Built Out Yet")
                case .dashBoard:
                    print("dashBoard Does Not Need Item")
                case .dailyDisplay:
                    print("dailyDisplay Does Not Need Item")
                case .routeBuilder:
                    print("routeBuilder Need more complex Logic")
                case .management:
                    print("Developer Make function for getting management by Id")
                case .pnl:
                    print("PNL Not Built Out Yet")
                case .companyProfile:
                    print("reports Not Built Out Yet")
                case .reports:
                    print("reports Not Built Out Yet")
                case .readingsAndDosages:
                    print("routeBuilder Need more complex Logic")
                case .calendar:
                    print("Calendar Not Built Out Yet")
                case .maps:
                    print("maps Not Built Out Yet")
                case .companyAlerts:
                    print("companyAlerts Not Built Out Yet")
                case .personalAlerts:
                    print("personalAlerts Not Built Out Yet")
                case .marketPlace:
                    print("MarketPlace Not Built Out Yet")
                case .jobPosting:
                    print("JobPosting Not Built Out Yet")
                case .feed:
                    print("Feed Not Built Out Yet")
                case .companyRouteOverView:
                    print("reports Not Built Out Yet")
         
                case .settings:
                    print("Settings Not Built Out Yet")
       
                case .alerts:
                    print("alerts Not Built Out Yet")
                case .externalRoutesOverview:
                    print("Not Needed")
                case .laborContracts:
                    self.laborContract = try await dataService.getLaborContract(companyId: companyId, laborContractId: recentActivity.itemId)
                case .accountsPayable:
                    self.stripeInvoice = try await dataService.getAccountsPayableInvoice(companyId: companyId, invoiceId: recentActivity.itemId)
                case .accountsReceivable:
                    self.stripeInvoice = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: recentActivity.itemId)
                case .jobTemplates:
                    self.jobTemplate = try await dataService.getJobTemplate(companyId: companyId, templateId: recentActivity.itemId)
                case .customers:
                    self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: recentActivity.itemId)
                case .serviceStops:
                    self.serviceStop = try await dataService.getServiceStopById(serviceStopId: recentActivity.itemId, companyId: companyId)
                case .fleet:
                    self.vehical = try await dataService.getVehical(companyId: companyId, vehicalId: recentActivity.itemId)
                case .jobs:
                    self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: recentActivity.itemId)
                case .repairRequest:
                    self.repairRequest = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: recentActivity.itemId)
                case .contract://DEVELOPER MAYBE GET RID OF
                    self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: recentActivity.itemId)
                case .purchases:
                    self.purchase = try await dataService.getSingleItem(itemId: recentActivity.itemId, companyId: companyId)
                case .receipts:
                    self.receipt = try await dataService.getReceipt(companyId: companyId, receiptId: recentActivity.itemId)
                case .databaseItems:
                    self.dataBaseItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: recentActivity.itemId)
                case .genericItems:
                    self.genericItem = try await dataService.getGenericItem(companyId: companyId, genericItemId: recentActivity.itemId)
                case .vender:
                    self.vender = try await dataService.getSingleStore(companyId: companyId, storeId: recentActivity.itemId)
                case .users:
                    self.companyUser = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: recentActivity.itemId)
                case .userRoles:
                    self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: recentActivity.itemId)
                case .chat:
                    self.chat = try await dataService.getSpecificChat(chatId: recentActivity.itemId)
                case .equipment:
                    self.equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: recentActivity.itemId)
                case .contracts:
                    self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: recentActivity.itemId)
                case .shoppingList:
                    self.shoppingListItem = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: recentActivity.itemId)
                case .businesses:
                    self.associatedBusiness = try await dataService.getAssociatedBusiness(companyId: companyId, businessId: recentActivity.itemId)
                case .companyUser:
                    self.companyUser = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: recentActivity.itemId)
                }
            }
        } else {
            print("No Item Id")
                switch recentActivity.route {
                case .cart:
                    print("Has Item")
                case .editUser:
                    print("Developer Update Edit User")
                    
                case .rateSheet:
                    print("Developer Update Rate Sheet")
                    
                case .companyUserRateSheet:
                    print("Developer Update Rate Sheet")
                    
                case .operation:
                    self.route = Route.operation(dataService: dataService)
                case .finace:
                    self.route = Route.finace(dataService: dataService)
                case .managment:
                    self.route = Route.managment(dataService: dataService)
                case .dashBoard:
                    self.route = Route.dashBoard(dataService: dataService)
                case .customers:
                    self.route = Route.customers(dataService: dataService)
                case .toDoDetail:
                    self.route = Route.toDoDetail(dataService: dataService)
                case .repairRequestList:
                    self.route = Route.repairRequestList(dataService: dataService)
                case .toDoList:
                    self.route = Route.toDoList(dataService: dataService)
                case .pendingJobs:
                    self.route = Route.pendingJobs(dataService: dataService)
                case .shoppingList:
                    self.route = Route.shoppingList(dataService: dataService)
                case .purchasedItemsList:
                     self.route = Route.purchasedItemsList(dataService: dataService)
                case .map:
                     self.route = Route.map(dataService: dataService)
                case .dailyDisplay:
                     self.route = Route.dailyDisplay(dataService: dataService)
                case .calendar:
                     self.route = Route.calendar(dataService: dataService)
                case .profile:
                     self.route = Route.profile(dataService: dataService)
                case .routeBuilder:
                     self.route = Route.routeBuilder(dataService: dataService)
                case .pnl:
                     self.route = Route.pnl(dataService: dataService)
                case .companyRouteOverView:
                     self.route = Route.companyRouteOverView(dataService: dataService)
                case .reports:
                     self.route = Route.reports(dataService: dataService)
                case .fleet:
                     self.route = Route.fleet(dataService: dataService)
                case .mainDailyDisplayView:
                     self.route = Route.mainDailyDisplayView(dataService: dataService)
                case .serviceStops:
                     self.route = Route.serviceStops(dataService: dataService)
                case .jobs:
                     self.route = Route.jobs(dataService: dataService)
                case .contracts:
                     self.route = Route.contracts(dataService: dataService)
                case .purchases:
                     self.route = Route.purchases(dataService: dataService)
                case .receipts:
                     self.route = Route.receipts(dataService: dataService)
                case .databaseItems:
                     self.route = Route.databaseItems(dataService: dataService)
                case .genericItems:
                     self.route = Route.genericItems(dataService: dataService)
                case .venders:
                     self.route = Route.venders(dataService: dataService)
                case .users:
                     self.route = Route.users(dataService: dataService)
                case .userRoles:
                     self.route = Route.userRoles(dataService: dataService)
                case .readingsAndDosages:
                     self.route = Route.readingsAndDosages(dataService: dataService)
                case .marketPlace:
                     self.route = Route.marketPlace(dataService: dataService)
                case .jobPosing:
                     self.route = Route.jobPosting(dataService: dataService)
                case .feed:
                     self.route = Route.feed(dataService: dataService)
                case .chats:
                     self.route = Route.chats(dataService: dataService)
                case .equipmentList:
                     self.route = Route.equipmentList(dataService: dataService)
                case .routes:
                     self.route = Route.routes(dataService: dataService)
                case .settings:
                     self.route = Route.settings(dataService: dataService)
                case .userSettings:
                     self.route = Route.userSettings(dataService: dataService)
                case .companySettings:
                     self.route = Route.companySettings(dataService: dataService)
                case .jobTemplates:
                     self.route = Route.jobTemplates(dataService: dataService)
                case .accountsPayableList:
                     self.route = Route.accountsPayableList(dataService: dataService)
                case .accountsReceivableList:
                     self.route = Route.accountsReceivableList(dataService: dataService)
                case .businesses:
                     self.route = Route.businesses(dataService: dataService)
                case .alerts:
                     self.route = Route.alerts(dataService: dataService)
                case .recentActivity:
                     self.route = Route.recentActivity(dataService: dataService)
                case .compileInvoice:
                    self.route = Route.compileInvoice(dataService: dataService)
                case .createNewJob:
                    self.route = Route.createNewJob(dataService: dataService)
                case .createRepairRequest:
                    self.route = Route.createRepairRequest(dataService: dataService)
                case .createCustomer:
                    self.route = Route.createCustomer(dataService: dataService)
                case .equipmentDetailView:
                    self.route = Route.equipmentDetailView(dataService: dataService)
                case .laborContracts:
                    self.route = Route.laborContracts(dataService: dataService)
                case .companyAlerts:
                    self.route = Route.companyAlerts(dataService: dataService)
                    //All the Below are detil with Higher
                case .shoppingListDetail,.purchase,.job,.chat,.repairRequest,.customer,.serviceStop,.business,.vender,.dataBaseItem,.contract,.genericItem,.readingTemplate,.dosageTemplate,.receipt,.companyProfile,.vehicalDetailView,.accountsPayableDetail,.accountsReceivableDetail,.laborContractDetailView, .companyUserDetailView, .jobTemplate, .routeOverview, .allTechRouteOverview, .dailyDisplayStop, .bankDetailView, .transactionDetailView:
                    print("Detalt With Higher Above")
  
                case .externalRouteOverView:
                    self.route = Route.externalRouteOverView(dataService: dataService)
                case .banks:
                    print("Please build out")
                case .transactions:
                    print("Please build out")
                case .activeRouteOverView:
                    print("Please build out")
                }
            
        }
        self.isLoading = false
    }

}
