//
//  Route.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//


import Foundation
import SwiftUI
enum Route {
    
    // Main Categories
    case operation
    case finace
    case managment
    case dashBoard(dataService:any ProductionDataServiceProtocol)

    // Main Views - Lists
    case customers(dataService:any ProductionDataServiceProtocol)
    case toDoDetail(dataService:any ProductionDataServiceProtocol)
    case repairRequestList(dataService:any ProductionDataServiceProtocol)
    case toDoList(dataService:any ProductionDataServiceProtocol)
    case pendingJobs(dataService:any ProductionDataServiceProtocol)
    case shoppingList(dataService:any ProductionDataServiceProtocol)
    case purchasedItemsList(dataService:any ProductionDataServiceProtocol)
    case map(dataService:any ProductionDataServiceProtocol)
    case dailyDisplay(dataService:any ProductionDataServiceProtocol)
    case calendar(dataService:any ProductionDataServiceProtocol)
    case profile(dataService:any ProductionDataServiceProtocol)
    case routeBuilder(dataService:any ProductionDataServiceProtocol) // I can probably have route switch on a protocol
    case pnl(dataService:any ProductionDataServiceProtocol)
    case companyRouteOverView(dataService:any ProductionDataServiceProtocol)
    case routeOverview(route: ActiveRoute,dataService:any ProductionDataServiceProtocol)
    case allTechRouteOverview(route: [ActiveRoute],dataService:any ProductionDataServiceProtocol)
    case dailyDisplayStop(dataService:any ProductionDataServiceProtocol, serviceStop:ServiceStop)
    case reports(dataService:any ProductionDataServiceProtocol)
    case fleet(dataService:any ProductionDataServiceProtocol)
    case mainDailyDisplayView(dataService:any ProductionDataServiceProtocol)
    case serviceStops(dataService:any ProductionDataServiceProtocol)
    case jobs(dataService:any ProductionDataServiceProtocol)
    case contracts(dataService:any ProductionDataServiceProtocol)
    case purchases(dataService:any ProductionDataServiceProtocol)
    case receipts(dataService:any ProductionDataServiceProtocol)
    case databaseItems(dataService:any ProductionDataServiceProtocol)
    case genericItems(dataService:any ProductionDataServiceProtocol)
    case venders(dataService:any ProductionDataServiceProtocol)
    case users(dataService:any ProductionDataServiceProtocol)
    case userRoles(dataService:any ProductionDataServiceProtocol)
    case readingsAndDosages(dataService:any ProductionDataServiceProtocol)
    case marketPlace(dataService:any ProductionDataServiceProtocol)
    case jobPosing(dataService:any ProductionDataServiceProtocol)
    case feed(dataService:any ProductionDataServiceProtocol)
    case chats(dataService:any ProductionDataServiceProtocol)
    
    case equipmentList(dataService:any ProductionDataServiceProtocol)
    case routes(dataService:any ProductionDataServiceProtocol)
    case settings(dataService:any ProductionDataServiceProtocol)
    case userSettings(dataService:any ProductionDataServiceProtocol)
    case companySettings(dataService:any ProductionDataServiceProtocol)

    case jobTemplates(dataService:any ProductionDataServiceProtocol)
    case accountsPayableList(dataService:any ProductionDataServiceProtocol)
    case accountsReceivableList(dataService:any ProductionDataServiceProtocol)
    case businesses(dataService:any ProductionDataServiceProtocol)

    // Detail Views - Pages
    case cart(
        dataService:any ProductionDataServiceProtocol
    )
    case shoppingListDetail(
        dataService:any ProductionDataServiceProtocol
    )
    case purchase(
        purchasedItem: PurchasedItem,
        dataService:any ProductionDataServiceProtocol
    )
    case job(
        job: Job,
        dataService:any ProductionDataServiceProtocol
    )
    case editUser(
        user:DBUser,
        dataService:any ProductionDataServiceProtocol
    )
    case rateSheet(
        user:DBUser,
        dataService:any ProductionDataServiceProtocol
    )
    case chat(
        chat:Chat,
        dataService:any ProductionDataServiceProtocol
    )
    case repairRequest(
        repairRequest:RepairRequest,
        dataService:any ProductionDataServiceProtocol
    )
    case customer(
        customer: Customer,
        dataService:any ProductionDataServiceProtocol
    )
    case serviceStop(
        serviceStop: ServiceStop,
        dataService:any ProductionDataServiceProtocol
    )
    case business(
        business:Company,
        dataService:any ProductionDataServiceProtocol
    )
    case vender(
        vender:Vender,
        dataService:any ProductionDataServiceProtocol
    )
    case dataBaseItem(
        dataBaseItem: DataBaseItem,
        dataService:any ProductionDataServiceProtocol
    )
    case contract(
        contract:Contract,
        dataService:any ProductionDataServiceProtocol
    )
    case genericItem(
        item:GenericItem,
        dataService:any ProductionDataServiceProtocol
    )
    case readingTemplate(
        tempalte:ReadingsTemplate,
        dataService:any ProductionDataServiceProtocol
    )
    case dosageTemplate(
        template: DosageTemplate,
        dataService:any ProductionDataServiceProtocol
    )
    case recentActivity(
        dataService:any ProductionDataServiceProtocol
    )
    case companyProfile(
        company:Company,
        dataService:any ProductionDataServiceProtocol
    )
    case compileInvoice(
        dataService:any ProductionDataServiceProtocol
    )
    case createNewJob(
        dataService:any ProductionDataServiceProtocol
    )
    case createRepairRequest(
        dataService:any ProductionDataServiceProtocol
    )
    case createCustomer(
        dataService:any ProductionDataServiceProtocol
    )
    case equipmentDetailView(
        dataService:any ProductionDataServiceProtocol
    )
    case vehicalDetailView(
        dataService:any ProductionDataServiceProtocol
    )
    case accountsPayableDetail(
        invoice:StripeInvoice,
        dataService:any ProductionDataServiceProtocol
    )
    case accountsReceivableDetail(
        invoice:StripeInvoice,
        dataService:any ProductionDataServiceProtocol
    )
    case companyUserDetailView(
        user:CompanyUser,
        dataService:any ProductionDataServiceProtocol
    )

}

extension Route {
    func title() ->String{
        switch self {
        case .operation:
            return "Operation"
        case .finace:
            return "Finace"
        case .managment:
            return "Managment"
        case .dashBoard:
            return "DashBoard"
        case .customers:
            return "Customers"
        case .toDoDetail:
            return "To Do"
        case .repairRequestList:
            return "Repair Request"
        case .toDoList:
            return "To Do"
        case .pendingJobs:
            return "Pending Jobs"
        case .shoppingList:
            return "Shopping List"
        case .purchasedItemsList:
            return "Purchased Items"
        case .map:
            return "Map"
        case .dailyDisplay:
            return "Daily Display"
        case .calendar:
            return "Calendar"
        case .profile:
            return "Profile"
        case .routeBuilder(dataService: _):
            return "Route Builder"
        case .pnl:
            return "P.N.L."
        case .routeOverview(route: _):
            return "Route Overview"
        case .allTechRouteOverview(route: _):
            return "Tech Overview"
        case .dailyDisplayStop:
            return "Daily Display"
        case .reports:
            return "Reports"
        case .fleet:
            return "Fleet"
        case .mainDailyDisplayView:
            return "Daily Display"
        case .serviceStops:
            return "Service Stops"
        case .jobs:
            return "Jobs"
        case .contracts:
            return "Contracts"
        case .purchases:
            return "Purchases"
        case .receipts:
            return "Receipts"
        case .databaseItems:
            return "Data Base Items"
        case .genericItems:
            return "Generic Items"
        case .venders:
            return "Venders"
        case .users:
            return "Users"
        case .userRoles:
            return "User Roles"
        case .readingsAndDosages:
            return "Reading and Dosages"
        case .marketPlace:
            return "Market Place"
        case .jobPosing:
            return "Job Posting"
        case .feed:
            return "Feed"
        case .cart:
            return "cart"
        case .shoppingListDetail:
            return "shoppingListDetail"
        case .purchase(purchasedItem: _):
            return "purchase"
        case .job(job: _):
            return "job"
        case .editUser(user: _):
            return "editUser"
        case .rateSheet(user: _):
            return "rateSheet"
        case .chat(chat: _):
            return "chat"
        case .repairRequest(repairRequest: _):
            return "repairRequest"
        case .customer(customer: _):
            return "Customer"
        case .serviceStop(serviceStop: _):
            return "Service Stop"
        case .dataBaseItem(dataBaseItem: _):
            return "Data Base Item"
        case .contract(contract: _):
            return "Contract"
        case .genericItem:
            return "Generic Item"
        case .readingTemplate:
            return "reading Template"
        case .dosageTemplate:
            return "dosage Template"
        case .recentActivity:
            return "recent Activity"
        case .companyProfile:
            return "company Profile"
        case .chats:
            return "Chats"
        case .compileInvoice:
            return "Compile Invoice"
        case .createNewJob:
            return "Create New Job"
        case .createRepairRequest:
            return "Create Repair Request"
        case .createCustomer:
            return "Create Customer"
        case .equipmentDetailView:
            return "Equipment Detail View"
        case .vehicalDetailView:
            return "Equipment Detail View"
        case .equipmentList:
            return "Equipment List"
        case .routes:
            return "Routes"
        case .settings:
            return "Settings"
        case .jobTemplates:
            return "Job Templates"
        case .companyRouteOverView:
            return "Company Route Over View"
        case .accountsPayableList:
            return "Accounts Payable List"
        case .accountsReceivableList:
            return "Accounts Receivable List"
        case .accountsPayableDetail:
            return "Accounts Payable Detail"
        case .accountsReceivableDetail:
            return "Accounts Receivable Detail"
        case .userSettings(dataService: let dataService):
            return "User Settings"
        case .companySettings(dataService: let dataService):
            return "Company Settings"
        case .businesses(dataService: let dataService):
            return "Businesses"
        case .business(business: let contractor, dataService: let dataService):
            return "Business"
        case .vender(vender: let vender, dataService: let dataService):
            return "Vender"
        case .companyUserDetailView(user: let user, dataService: let dataService):
            return "Company User"
        }
    }
}

extension Route: Hashable{
    func hash(into hasher:inout Hasher) {
        hasher.combine(self.hashValue)
    }
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs,rhs) {
        case(.cart, .cart):
            return true
        case (.operation, .operation):
            return true
       
        case (.finace, _):
            return true
        case (.managment, _):
            return true
        case (.dashBoard(dataService: _), _):
            return true
        case (.customers(dataService: _), _):
            return true
        case (.toDoDetail(dataService: _), _):
            return true
        case (.repairRequestList(dataService: _), _):
            return true
        case (.toDoList(dataService: _), _):
            return true
        case (.pendingJobs(dataService: _), _):
            return true
        case (.shoppingList(dataService: _), _):
            return true
        case (.purchasedItemsList(dataService: _), _):
            return true
        case (.map(dataService: _), _):
            return true
        case (.dailyDisplay(dataService: _), _):
            return true
        case (.calendar(dataService: _), _):
            return true
        case (.profile(dataService: _), _):
            return true
        case (.routeBuilder(dataService: _), _):
            return true
        case (.pnl(dataService: _), _):
            return true
        case (.companyRouteOverView(dataService: _), _):
            return true
        case (.routeOverview(route: let route, dataService: _), _):
            return true
        case (.allTechRouteOverview(route: let route, dataService: _), _):
            return true
        case (.dailyDisplayStop(dataService: _, serviceStop: let serviceStop), _):
            return true
        case (.reports(dataService: _), _):
            return true
        case (.fleet(dataService: _), _):
            return true
        case (.mainDailyDisplayView(dataService: _), _):
            return true
        case (.serviceStops(dataService: _), _):
            return true
        case (.jobs(dataService: _), _):
            return true
        case (.contracts(dataService: _), _):
            return true
        case (.purchases(dataService: _), _):
            return true
        case (.receipts(dataService: _), _):
            return true
        case (.databaseItems(dataService: _), _):
            return true
        case (.genericItems(dataService: _), _):
            return true
        case (.venders(dataService: _), _):
            return true
        case (.users(dataService: _), _):
            return true
        case (.userRoles(dataService: _), _):
            return true
        case (.readingsAndDosages(dataService: _), _):
            return true
        case (.marketPlace(dataService: _), _):
            return true
        case (.jobPosing(dataService: _), _):
            return true
        case (.feed(dataService: _), _):
            return true
        case (.chats(dataService: _), _):
            return true
        case (.equipmentList(dataService: _), _):
            return true
        case (.routes(dataService: _), _):
            return true
        case (.settings(dataService: _), _):
            return true
        case (.userSettings(dataService: _), _):
            return true
        case (.companySettings(dataService: _), _):
            return true
        case (.jobTemplates(dataService: _), _):
            return true
        case (.accountsPayableList(dataService: _), _):
            return true
        case (.accountsReceivableList(dataService: _), _):
            return true
        case (.shoppingListDetail(dataService: _), _):
            return true
        case (.purchase(purchasedItem: let purchasedItem, dataService: _), _):
            return true
        case (.job(job: let job, dataService: _), _):
            return true
        case (.editUser(user: let user, dataService: _), _):
            return true
        case (.rateSheet(user: let user, dataService: _), _):
            return true
        case (.chat(chat: let chat, dataService: _), _):
            return true
        case (.repairRequest(repairRequest: let repairRequest, dataService: _), _):
            return true
        case (.customer(customer: let customer, dataService: _), _):
            return true
        case (.serviceStop(serviceStop: let serviceStop, dataService: _), _):
            return true
        case (.dataBaseItem(dataBaseItem: let dataBaseItem, dataService: _), _):
            return true
        case (.contract(contract: let contract, dataService: _), _):
            return true
        case (.genericItem(item: let item, dataService: _), _):
            return true
        case (.readingTemplate(tempalte: let tempalte, dataService: _), _):
            return true
        case (.dosageTemplate(template: let template, dataService: _), _):
            return true
        case (.recentActivity(dataService: _), _):
            return true
        case (.companyProfile(company: let company, dataService: _), _):
            return true
        case (.compileInvoice(dataService: _), _):
            return true
        case (.createNewJob(dataService: _), _):
            return true
        case (.createRepairRequest(dataService: _), _):
            return true
        case (.createCustomer(dataService: _), _):
            return true
        case (.equipmentDetailView(dataService: _), _):
            return true
        case (.vehicalDetailView(dataService: _), _):
            return true
        case (.accountsPayableDetail(invoice: let invoice, dataService: _), _):
            return true
        case (.accountsReceivableDetail(invoice: let invoice, dataService: _), _):
            return true
        case (.operation, .cart(dataService: _)):
            return true
        case (.cart(dataService: _), .operation):
            return true
        case (_, .finace):
            return true
        case (_, .managment):
            return true
        case (_, .dashBoard(dataService: _)):
            return true
        case (_, .customers(dataService: _)):
            return true
        case (_, .toDoDetail(dataService: _)):
            return true
        case (_, .repairRequestList(dataService: _)):
            return true
        case (_, .toDoList(dataService: _)):
            return true
        case (_, .pendingJobs(dataService: _)):
            return true
        case (_, .shoppingList(dataService: _)):
            return true
        case (_, .purchasedItemsList(dataService: _)):
            return true
        case (_, .map(dataService: _)):
            return true
        case (_, .dailyDisplay(dataService: _)):
            return true
        case (_, .calendar(dataService: _)):
            return true
        case (_, .profile(dataService: _)):
            return true
        case (_, .routeBuilder(dataService: _)):
            return true
        case (_, .pnl(dataService: _)):
            return true
        case (_, .companyRouteOverView(dataService: _)):
            return true
        case (_, .routeOverview(route: let route, dataService: _)):
            return true
        case (_, .allTechRouteOverview(route: let route, dataService: _)):
            return true
        case (_, .dailyDisplayStop(dataService: _, serviceStop: let serviceStop)):
            return true
        case (_, .reports(dataService: _)):
            return true
        case (_, .fleet(dataService: _)):
            return true
        case (_, .mainDailyDisplayView(dataService: _)):
            return true
        case (_, .serviceStops(dataService: _)):
            return true
        case (_, .jobs(dataService: _)):
            return true
        case (_, .contracts(dataService: _)):
            return true
        case (_, .purchases(dataService: _)):
            return true
        case (_, .receipts(dataService: _)):
            return true
        case (_, .databaseItems(dataService: _)):
            return true
        case (_, .genericItems(dataService: _)):
            return true
        case (_, .venders(dataService: _)):
            return true
        case (_, .users(dataService: _)):
            return true
        case (_, .userRoles(dataService: _)):
            return true
        case (_, .readingsAndDosages(dataService: _)):
            return true
        case (_, .marketPlace(dataService: _)):
            return true
        case (_, .jobPosing(dataService: _)):
            return true
        case (_, .feed(dataService: _)):
            return true
        case (_, .chats(dataService: _)):
            return true
        case (_, .equipmentList(dataService: _)):
            return true
        case (_, .routes(dataService: _)):
            return true
        case (_, .settings(dataService: _)):
            return true
        case (_, .userSettings(dataService: _)):
            return true
        case (_, .companySettings(dataService: _)):
            return true
        case (_, .jobTemplates(dataService: _)):
            return true
        case (_, .accountsPayableList(dataService: _)):
            return true
        case (_, .accountsReceivableList(dataService: _)):
            return true
        case (_, .shoppingListDetail(dataService: _)):
            return true
        case (_, .purchase(purchasedItem: let purchasedItem, dataService: _)):
            return true
        case (_, .job(job: let job, dataService: _)):
            return true
        case (_, .editUser(user: let user, dataService: _)):
            return true
        case (_, .rateSheet(user: let user, dataService: _)):
            return true
        case (_, .chat(chat: let chat, dataService: _)):
            return true
        case (_, .repairRequest(repairRequest: let repairRequest, dataService: _)):
            return true
        case (_, .customer(customer: let customer, dataService: _)):
            return true
        case (_, .serviceStop(serviceStop: let serviceStop, dataService: _)):
            return true
        case (_, .dataBaseItem(dataBaseItem: let dataBaseItem, dataService: _)):
            return true
        case (_, .contract(contract: let contract, dataService: _)):
            return true
        case (_, .genericItem(item: let item, dataService: _)):
            return true
        case (_, .readingTemplate(tempalte: let tempalte, dataService: _)):
            return true
        case (_, .dosageTemplate(template: let template, dataService: _)):
            return true
        case (_, .recentActivity(dataService: _)):
            return true
        case (_, .companyProfile(company: let company, dataService: _)):
            return true
        case (_, .compileInvoice(dataService: _)):
            return true
        case (_, .createNewJob(dataService: _)):
            return true
        case (_, .createRepairRequest(dataService: _)):
            return true
        case (_, .createCustomer(dataService: _)):
            return true
        case (_, .equipmentDetailView(dataService: _)):
            return true
        case (_, .vehicalDetailView(dataService: _)):
            return true
        case (_, .accountsPayableDetail(invoice: let invoice, dataService: _)):
            return true
        case (_, .accountsReceivableDetail(invoice: let invoice, dataService: _)):
            return true
        case (.businesses(dataService: let dataService), .operation):
            return true
        case (.business(business: let contractor, dataService: let dataService), .operation):
            return true
        case (.vender(vender: let vender, dataService: let dataService), .operation):
            return true
        default:
            return false
        }
    }
}

extension Route:View {
    var body: some View {
        switch self {
        case .purchases(let dataService):
            PurchasesView()//DEVELOPER THINK ABOUT REMOVING
        case .operation:
            Operations()//DEVELOPER THINK ABOUT REMOVING
        case .finace:
            Finance()//DEVELOPER THINK ABOUT REMOVING
        case .managment:
            Managment()//DEVELOPER THINK ABOUT REMOVING
        case .dashBoard(dataService: let dataService):
            Dashboard()//DEVELOPER THINK ABOUT REMOVING
        case .customers(dataService: let dataService):
            CustomerListView(dataService: dataService)
        case .toDoDetail(dataService: let dataService):
            ToDoDetailView(dataService: dataService)
        case .repairRequestList(dataService: let dataService):
            RepairRequestListView(dataService: dataService)
        case .toDoList(dataService: let dataService):
            ToDoListView(dataService: dataService)
        case .pendingJobs(dataService: let dataService):
            Text("Pending Job List")
        case .shoppingList(dataService: let dataService):
            ShoppingListView(
                dataService: dataService
            )
        case .purchasedItemsList(dataService: let dataService):
            UserPurchasedItems()
            
        case .map(dataService: let dataService):
            Text("Map")
        case .dailyDisplay(dataService: let dataService):
            Text("dailyDisplay")
            
        case .calendar(dataService: let dataService):
            Text("Calendar")
        case .profile(dataService: let dataService):
            ProfileView(dataService: dataService)
        case .routeBuilder(dataService: let dataService):
            RouteManagmentView(dataService: dataService)
        case .pnl(dataService: let dataService):
            Text("PNL")
            
        case .companyRouteOverView(dataService: let dataService):
            UserRouteOverView(dataService: dataService)
        case .routeOverview(route: let route,dataService: let dataService):
            UserRouteDetailView(dataService: dataService, activeRoute: route)
        case .allTechRouteOverview(route: let route, dataService:let dataService):
            UserRouteDetailViewAll(dataService:dataService, activeRoute: route)
        case .dailyDisplayStop(dataService: let dataService,serviceStop: let stop):
            ServiceStopDetailView(dataService:dataService, serviceStop: stop)

        case .reports(dataService: let dataService):
            ReportDetailView(dataService: dataService)
        case .fleet(dataService: let dataService):
            FleetListView(dataService: dataService as! ProductionDataService)
            
        case .mainDailyDisplayView(dataService: let dataService):
//            EmployeeDailyDashboard(dataService: dataService)//Developer Stable
            ContractorDailyDashboard(dataService: dataService) //Developer Unstable
            
        case .serviceStops(dataService: let dataService):
            ServiceStopMainView()
        case .jobs(dataService: let dataService):
            JobView()
            
        case .contracts(dataService: let dataService):
            ContractListView(dataService: dataService)
            
        case .receipts(dataService: let dataService):
            ReceiptListView()
        case .databaseItems(dataService: let dataService):
            ReceiptDatabaseView()
        case .genericItems(dataService: let dataService):
            GenericItemList(dataService:dataService)
        case .venders(dataService: let dataService):
           StoreListView()
            
        case .users(dataService: let dataService):
            TechListView(dataService: dataService)
            
        case .userRoles(dataService: let dataService):
            UserRoleView()
            
        case .readingsAndDosages(dataService: let dataService):
            ReadingsAndDosagesList()
            
        case .marketPlace(dataService: let dataService):
            Text("User")
            
        case .jobPosing(dataService: let dataService):
            Text("User")
            
        case .feed(dataService: let dataService):
            Text("User")
            
        case .chats(dataService: let dataService):
            ChatListView(dataService: dataService)
            
        case .equipmentList(dataService: let dataService):
            EquipmentList(dataService: dataService)
        case .routes(dataService: let dataService):
            RouteManagmentView(dataService: dataService)
            
        case .settings(dataService: let dataService):
            SettingsView(dataService: dataService)
            
        case .jobTemplates(dataService: let dataService):
            JobTemplateSettingsView()
        case .accountsPayableList(dataService: let dataService):
            AccountsPayableList(dataService: dataService)
            
        case .accountsReceivableList(dataService: let dataService):
            AccountsReceivableList(dataService: dataService)
            
        case .cart(dataService: let dataService):
            Text("User")
        case .shoppingListDetail(dataService: let dataService):
            ShoppingListItemDetailView(
                dataService: dataService
            )
        case .purchase(purchasedItem: let purchasedItem, dataService: let dataService):
            PurchaseDetailView(purchase: purchasedItem, dataService: dataService)
            
        case .job(job: let job, dataService: let dataService):
            JobDetailView(
                job: job,
                dataService:dataService
            )
        case .editUser(user: let user, dataService: let dataService):
            EditProfileView(tech: user)
            
        case .rateSheet(user: let user, dataService: let dataService):
            TechRateSheet(tech: user)
            
        case .chat(chat: let chat, dataService: let dataService):
            ChatDetailView(dataService:dataService,chat:chat)
            
        case .repairRequest(repairRequest: let repairRequest, dataService: let dataService):
            RepairRequestDetailView(
                dataService: dataService,
                repairRequest: repairRequest
            )
        case .customer(customer: let customer, dataService: let dataService):
            CustomerDetailView(customer: customer)
        case .serviceStop(serviceStop: let serviceStop, dataService: let dataService):
            ServiceStopInfoView(
                serviceStop: serviceStop,
                dataService:dataService
            )
        case .dataBaseItem(dataBaseItem: let dataBaseItem, dataService: let dataService):
            DataBaseItemView(dataBaseItem:dataBaseItem)
        case .contract(contract: let contract, dataService: let dataService):
            ContractDetailView(dataService: dataService, contract:contract)
            
        case .genericItem(dataService: let dataService):
            GenericItemDetailView()
            
        case .readingTemplate(dataService: let dataService):
            ReadingsDetail()
            
        case .dosageTemplate(dataService: let dataService):
            DosageDetail()
            
        case .recentActivity(dataService: let dataService):
            RecentActivity()
            
        case .companyProfile(dataService: let dataService):
           CompanyProfileView()
        case .compileInvoice(dataService: let dataService):
            CompileInvoice(dataService: dataService)
            
        case .createNewJob(dataService: let dataService):
            AddNewJobView(
                dataService: dataService
            )
        case .createRepairRequest(dataService: let dataService):
            AddNewRepairRequest(
                dataService: dataService
            )
        case .createCustomer(dataService: let dataService):
            AddNewCustomerView(dataService: dataService)
            
        case .equipmentDetailView(dataService: let dataService):
            EquipmentDetailView(dataService: dataService)
            
        case .vehicalDetailView(dataService: let dataService):
            FleetDetailView()
        case .accountsPayableDetail(let invoice,dataService: let dataService):
            AccountsPayableDetail(invoice: invoice)
            
        case .accountsReceivableDetail(let invoice,dataService: let dataService):
            AccountsReceivableDetail(invoice: invoice)
            
        case .userSettings(dataService: let dataService):
            UserSettings(dataService:dataService)
        case .companySettings(dataService: let dataService):
            CompanySettings()
        case .businesses(dataService: let dataService):
            BuisnessesListView(dataService:dataService)
        case .business(business: let contractor, dataService: let dataService):
            BuisnessDetailView(dataService: dataService,contractor:contractor)
        case .vender(vender: let vender, dataService: let dataService):
            StoreDetailView(store: vender)
        case .companyUserDetailView(user: let user, dataService: let dataService):
            CompanyUserDetailView(dataService: dataService, companyUser: user)

        }
        
    }
}
    func convertRouteToString(route:Route) -> String {
        switch route {
        case .operation:
            return "operation"
            
        case .finace:
            return "finace"
            
        case .managment:
            return "managment"
            
        case .dashBoard:
            return "dashBoard"
            
        case .customers:
            return "customers"
            
        case .toDoDetail:
            return "toDoDetail"
            
        case .repairRequestList:
            return "repairRequestList"
            
        case .toDoList:
            return "toDoList"
            
        case .pendingJobs:
            return "pendingJobs"
            
        case .shoppingList:
            return "shoppingList"
            
        case .purchasedItemsList:
            return "purchasedItemsList"
            
        case .map:
            return "map"
            
        case .dailyDisplay:
            return "dailyDisplay"
            
        case .calendar:
            return "calendar"
            
        case .profile:
            return "profile"
            
        case .routeBuilder(dataService: _):
            return "routeBuilder"
            
        case .pnl:
            return "pnl"
            
        case .routeOverview(route: _):
            return "routeOverview"
            
        case .allTechRouteOverview(route: _):
            return "allTechRouteOverview"
            
        case .dailyDisplayStop:
            return "dailyDisplayStop"
            
        case .reports:
            return "reports"
            
        case .fleet:
            return "fleet"
            
        case .mainDailyDisplayView:
            return "mainDailyDisplayView"
            
        case .serviceStops:
            return "serviceStops"
            
        case .jobs:
            return "jobs"
            
        case .contracts:
            return "contracts"
            
        case .purchases:
            return "purchases"
            
        case .receipts:
            return "receipts"
            
        case .databaseItems:
            return "databaseItems"
            
        case .genericItems:
            return "genericItems"
            
        case .venders:
            return "venders"
            
        case .users:
            return "users"
            
        case .userRoles:
            return "userRoles"
            
        case .readingsAndDosages:
            return "readingsAndDosages"
            
        case .marketPlace:
            return "marketPlace"
            
        case .jobPosing:
            return "jobPosing"
            
        case .feed:
            return "feed"
            
        case .chats:
            return "chats"
            
        case .cart:
            return "cart"
            
        case .shoppingListDetail:
            return "shoppingListDetail"
            
        case .purchase(purchasedItem: _):
            return "purchase"
            
        case .job(job: _):
            return "job"
            
        case .editUser(user: _):
            return "editUser"
            
        case .rateSheet(user: _):
            return "rateSheet"
            
        case .chat(chat: _):
            return "chat"
            
        case .repairRequest(repairRequest: _):
            return "repairRequest"
            
        case .customer(customer: _):
            return "customer"
            
        case .serviceStop(serviceStop: _):
            return "serviceStop"
            
        case .dataBaseItem(dataBaseItem: _):
            return "dataBaseItem"
            
        case .contract(contract: _):
            return "contract"
            
        case .genericItem:
            return "genericItem"
            
        case .readingTemplate:
            return "readingTemplate"
            
        case .dosageTemplate:
            return "dosageTemplate"
            
        case .recentActivity:
            return "recentActivity"
            
        case .companyProfile:
            return "companyProfile"
        case .compileInvoice:
            return "compileInvoice"
            
        case .createNewJob:
            return "createNewJob"
        case .createRepairRequest:
            return "createRepairRequest"
        case .createCustomer:
            return "createCustomer"
        case .equipmentDetailView:
            return "equipmentDetailView"
        case .vehicalDetailView:
            return "vehicalDetailView"
            
        case .equipmentList:
            return "equipmentList"
        case .routes:
            return "routes"
        case .settings:
            return "settings"
        case .jobTemplates:
            return "jobTemplates"
        case .companyRouteOverView:
            return "companyRouteOverView"
        case .accountsPayableList:
            return "accountsPayableList"
        case .accountsReceivableList:
            return "accountsReceivableList"
        case .accountsPayableDetail:
            return "accountsPayableDetail"
        case .accountsReceivableDetail:
            return "accountsReceivableDetail"
        case .userSettings(dataService: let dataService):
            return "userSettings"
        case .companySettings(dataService: let dataService):
            return "companySettings"
        case .businesses(dataService: let dataService):
            return "businesses"
        case .business(business: let contractor, dataService: let dataService):
            return "business"
        case .vender(vender: let vender, dataService: let dataService):
            return "vender"
        case .companyUserDetailView(user: let user, dataService: let dataService):
            return "companyUserDetailView"
        }
    }
func convertStringToRoute(route:RecentActivityModel,dataService: any ProductionDataServiceProtocol,item:Any?) -> Route? {
        
        switch route.route {
            
        case "operation":
            return .operation
            
        case "finace":
            return .finace
            
        case "managment":
            return .managment
            
        case "dashBoard":
            return .dashBoard(dataService: dataService)
            
        case "toDoDetail":
            return .toDoDetail(dataService: dataService)
            
        case "repairRequestList":
            return .repairRequestList(dataService: dataService)
            
        case "toDoList":
            return .toDoList(dataService: dataService)
            
        case "pendingJobs":
            return .pendingJobs(dataService: dataService)
            
        case "shoppingList":
            return .shoppingList(dataService: dataService)
            
        case "purchasedItemsList":
            return .purchasedItemsList(dataService: dataService)
            
        case "map":
            return .map(dataService: dataService)
            
        case "dailyDisplay":
            return .dailyDisplay(dataService: dataService)
            
        case "calendar":
            return .calendar(dataService: dataService)
            
        case "profile":
            return .profile(dataService: dataService)
            
        case "pnl":
            return .pnl(dataService: dataService)
            
        case "dailyDisplayStop":
            if let stop:ServiceStop = item as? ServiceStop {
                return .dailyDisplayStop(dataService: dataService, serviceStop: stop)
            }
//                case .routeBuilder(route: let route):
//                    return "routeBuilder"
//            
//                case .routeOverview(route: let route):
//                    return "routeOverview"
//            
//                case .allTechRouteOverview(route: let route):
//                    return "allTechRouteOverview"
            
        case "reports":
            return .reports(dataService: dataService)
            
        case "fleet":
            return .fleet(dataService: dataService)
            
            
        case "mainDailyDisplayView":
            return .mainDailyDisplayView(dataService: dataService)
            
        case "serviceStops":
            return .serviceStops(dataService: dataService)
            
            
        case "jobs":
            return .jobs(dataService: dataService)
            
        case "contracts":
            return .contracts(dataService: dataService)
            
            
        case "purchases":
            return .purchases(dataService: dataService)
            
        case "receipts":
            return .receipts(dataService: dataService)
            
        case "databaseItems":
            return .databaseItems(dataService: dataService)
            
        case "genericItems":
            return .genericItems(dataService: dataService)
            
        case "venders":
            return .venders(dataService: dataService)
            
        case "users":
            return .users(dataService: dataService)
            
        case "userRoles":
            return .userRoles(dataService: dataService)
            
        case "readingsAndDosages":
            return .readingsAndDosages(dataService: dataService)
            
        case "marketPlace":
            return .marketPlace(dataService: dataService)
            
        case "jobPosing":
            return .jobPosing(dataService: dataService)
            
        case "feed":
            return .feed(dataService: dataService)
            
        case "chats":
            return .chats(dataService: dataService)
            
        case "cart":
            return .cart(dataService: dataService)
            
        case "shoppingListDetail":
            return .shoppingListDetail(dataService: dataService)
            
//                case .purchase(purchasedItem: let purchasedItem):
//                    return "purchase"
//            
//                case .job(job: let job):
//                    return "job"
//            
//                case .editUser(user: let user):
//                    return "editUser"
//            
//                case .rateSheet(user: let user):
//                    return "rateSheet"
//            
//                case .chat(chat: let chat):
//                    return "chat"
//            
//                case .repairRequest(repairRequest: let repairRequest):
//                    return "repairRequest"
//            
//                case .customer(customer: let customer):
//                    return "customer"
//            
//                case .serviceStop(serviceStop: let serviceStop):
//                    return "serviceStop"
//            
//                case .dataBaseItem(dataBaseItem: let dataBaseItem):
//                    return "dataBaseItem"
//            
//                case .contract(contract: let contract):
//                    return "contract"
        case "genericItem":
            if let genericItem:GenericItem = item as? GenericItem {
                return .genericItem(item: genericItem, dataService: dataService)
            }
        case "readingTemplate":
            if let template:ReadingsTemplate = item as? ReadingsTemplate {
                
                return .readingTemplate(tempalte: template, dataService: dataService)
            }
        case "dosageTemplate":
            if let template:DosageTemplate = item as? DosageTemplate {
                
                return .dosageTemplate(template: template, dataService: dataService)
            }
        case "recentActivity":
            return .recentActivity(dataService: dataService)
            
        case "companyProfile":
            if let company:Company = item as? Company {
                
                return .companyProfile(company: company, dataService: dataService)
            }
        case "customers":
            return .customers(dataService: dataService)
            
        case "compileInvoice":
            return .compileInvoice(dataService: dataService)
            
        case "createNewJob":
            return .createNewJob(dataService: dataService)
            
        case "createRepairRequest":
            return .createRepairRequest(dataService: dataService)
            
        case "createCustomer":
            return .createRepairRequest(dataService: dataService)
            
        case "equipmentDetailView":
            return .equipmentDetailView(dataService: dataService)
            
        case "vehicalDetailView":
            return .vehicalDetailView(dataService: dataService)
            
        case "equipmentList":
            return .equipmentList(dataService: dataService)
            
        case "routes":
            return .routes(dataService: dataService)
            
        case "settings":
            return .settings(dataService: dataService)
            
        case "jobTemplates":
            return .jobTemplates(dataService: dataService)
            
        case "companyRouteOverView":
            return .companyRouteOverView(dataService: dataService)
            
        case "accountsPayableList":
            return .accountsPayableList(dataService: dataService)
            
        case "accountsReceivableList":
            return .accountsReceivableList(dataService: dataService)
            
        case "accountsPayableDetail":
            if let invoice:StripeInvoice = item as? StripeInvoice {
                
                return .accountsPayableDetail(invoice: invoice, dataService: dataService)
            }
        case "accountsReceivableDetail":
            if let invoice:StripeInvoice = item as? StripeInvoice {
                
                return .accountsReceivableDetail(invoice: invoice, dataService: dataService)
            }
        case "companyUserDetailView":
            
            return nil
        default:
            return .chats(dataService: dataService)
        }
        
        return .dashBoard(dataService: dataService)
    }

