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
    case operation(dataService:any ProductionDataServiceProtocol)
    case finace(dataService:any ProductionDataServiceProtocol)
    case managment(dataService:any ProductionDataServiceProtocol)
    case dashBoard(dataService:any ProductionDataServiceProtocol)
    //DEVELOPER MAYBE DELETE LATER ?? MOSTLY FOR MY VISUALIZATION
    case lifeCycles(dataService:any ProductionDataServiceProtocol)

    // Main Views - Lists
    case managementTables(dataService:any ProductionDataServiceProtocol)

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
    
    case activeRouteOverView(dataService:any ProductionDataServiceProtocol)

    case routeBuilder(dataService:any ProductionDataServiceProtocol) // I can probably have route switch on a protocol
    case pnl(dataService:any ProductionDataServiceProtocol)
    case companyRouteOverView(dataService:any ProductionDataServiceProtocol)
    case internalRouteOverView(dataService:any ProductionDataServiceProtocol)
    case externalRouteOverView(dataService:any ProductionDataServiceProtocol)//For Routes extablished View outside contracts
    case routeOverview(route: ActiveRoute,dataService:any ProductionDataServiceProtocol)
    case allTechRouteOverview(route: [ActiveRoute],dataService:any ProductionDataServiceProtocol)
    case dailyDisplayStop(dataService:any ProductionDataServiceProtocol, serviceStop:ServiceStop)
    case reports(dataService:any ProductionDataServiceProtocol)
    case fleet(dataService:any ProductionDataServiceProtocol)
    case mainDailyDisplayView(dataService:any ProductionDataServiceProtocol)
    
    
    case employeeMainDailyDisplayView(dataService:any ProductionDataServiceProtocol)
    case jobs(dataService:any ProductionDataServiceProtocol)
    case billingJobs(dataService:any ProductionDataServiceProtocol)

    case serviceStops(dataService:any ProductionDataServiceProtocol)
    case purchases(dataService:any ProductionDataServiceProtocol)
    case receipts(dataService:any ProductionDataServiceProtocol)
    case databaseItems(dataService:any ProductionDataServiceProtocol)
    case genericItems(dataService:any ProductionDataServiceProtocol)
    case venders(dataService:any ProductionDataServiceProtocol)
    
        //settings
    case users(dataService:any ProductionDataServiceProtocol)
    case userRoles(dataService:any ProductionDataServiceProtocol)
    case readingsAndDosages(dataService:any ProductionDataServiceProtocol)
    case emailConfiguration(dataService:any ProductionDataServiceProtocol)
    
    case marketPlace(dataService:any ProductionDataServiceProtocol)
    
    case jobPosting(dataService:any ProductionDataServiceProtocol)
    case jobBoard(
        dataService:any ProductionDataServiceProtocol,
        jobBoard:JobBoard
    )
    case jobPost(
        dataService:any ProductionDataServiceProtocol,
        jobPost:JobPost

    )
    case feed(dataService:any ProductionDataServiceProtocol)//Are these the Same
    case chats(dataService:any ProductionDataServiceProtocol)//Are these the Same
    
    case equipmentList(dataService:any ProductionDataServiceProtocol)
    case routes(dataService:any ProductionDataServiceProtocol)
    case settings(dataService:any ProductionDataServiceProtocol)
    case userSettings(dataService:any ProductionDataServiceProtocol)
    case companySettings(dataService:any ProductionDataServiceProtocol)

    case jobTemplates(dataService:any ProductionDataServiceProtocol)
    case accountsPayableList(dataService:any ProductionDataServiceProtocol)
    case accountsReceivableList(dataService:any ProductionDataServiceProtocol)
    case businesses(dataService:any ProductionDataServiceProtocol)
    case alerts(dataService:any ProductionDataServiceProtocol)
    case companyAlerts(dataService:any ProductionDataServiceProtocol)
    
    case buisnessContracts(dataService:any ProductionDataServiceProtocol)
    
    
    case contracts(dataService:any ProductionDataServiceProtocol)
    case recurringContracts(dataService:any ProductionDataServiceProtocol)
    
    case recurringLaborContracts(dataService:any ProductionDataServiceProtocol)
    case sentRecurringLaborContracts(dataService:any ProductionDataServiceProtocol)
    case receivedRecurringLaborContracts(dataService:any ProductionDataServiceProtocol)
    
    case laborContracts(dataService:any ProductionDataServiceProtocol)
    
    case sentLaborContracts(dataService:any ProductionDataServiceProtocol)
    case receivedLaborContracts(dataService:any ProductionDataServiceProtocol)

    case banks(dataService:any ProductionDataServiceProtocol)
    case transactions(dataService:any ProductionDataServiceProtocol)
    case taskGroups(dataService : any ProductionDataServiceProtocol)
    case workLogList(dataService:any ProductionDataServiceProtocol)
    case invoices(dataService:any ProductionDataServiceProtocol)

    // Detail Views - Pages

    
    case workLogDetail(
        dataService:any ProductionDataServiceProtocol,
        workLog : WorkLog
    )
    case editRole(
        dataService:any ProductionDataServiceProtocol,
        role : Role
    )

    case taskGroupDetail(
        dataService:any ProductionDataServiceProtocol,
        taskGroup:JobTaskGroup
    )
    case cart(
        dataService:any ProductionDataServiceProtocol
    )
    case bankDetailView(
        bank:Bank,
        dataService:any ProductionDataServiceProtocol
    )
    case transactionDetailView(
        transaction:Transaction,
        dataService:any ProductionDataServiceProtocol
    )
    case shoppingListDetail(
        item: ShoppingListItem,

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
    case companyUserRateSheet(
        user:CompanyUser,
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
        business:AssociatedBusiness,
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
        contract:RecurringContract,
        dataService:any ProductionDataServiceProtocol
    )
    case genericItem(
        item:GenericItem,
        dataService:any ProductionDataServiceProtocol
    )
    case readingTemplate(
        tempalte:SavedReadingsTemplate,
        dataService:any ProductionDataServiceProtocol
    )
    case dosageTemplate(
        template: SavedDosageTemplate,
        dataService:any ProductionDataServiceProtocol
    )
    case recentActivity(
        dataService:any ProductionDataServiceProtocol
    )
    case receipt(
        receipt:Receipt,
        dataService:any ProductionDataServiceProtocol
    )

    case companyProfile(
        company:Company,
        dataService:any ProductionDataServiceProtocol
    )
    case companyPublicProfile(
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
        equipment:Equipment,
        dataService:any ProductionDataServiceProtocol
    )
    case vehicalDetailView(
        vehical:Vehical,

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
    case recurringLaborContractDetailView(
        contract:ReccuringLaborContract,
        dataService:any ProductionDataServiceProtocol
    )
    case laborContractDetailView(
        dataService:any ProductionDataServiceProtocol,
        contract:LaborContract
    )
    case jobTemplate(
        jobTemplate:JobTemplate,
                     dataService:any ProductionDataServiceProtocol
    )
    case recurringServiceStopDetail(
        dataService:any ProductionDataServiceProtocol,
        recurringServiceStop : RecurringServiceStop
    )
    case customerStopDataDetailView(
        dataService:any ProductionDataServiceProtocol,
        customerId:String
    )
    
    case contractTermsList(
        dataService:any ProductionDataServiceProtocol,
        termsList:[ContractTerms]
    )
    case createLaborContractInvoice(
        dataService:any ProductionDataServiceProtocol,
        laborContract : LaborContract
    )
    case createRecurringLaborContractInvoice(
        dataService:any ProductionDataServiceProtocol,
        recurringLaborContract : ReccuringLaborContract
    )
    case createBulkInvoice(
        dataService:any ProductionDataServiceProtocol,
        associatedBusiness : AssociatedBusiness
    )
}

extension Route {
    func title() ->String{
        switch self {
        case .jobs:
            return "Jobs"
        case .billingJobs:
            return "Billing Jobs"

        case .employeeMainDailyDisplayView:
            return "Employee Dashboard"
            
        case .operation:
            return "Operation"
        case .managementTables:
            return "Management Tables"
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
        case .jobPosting:
            return "Job Posting"
        case .jobBoard:
            return "Job Board"
        case .feed:
            return "Feed"
        case .cart:
            return "cart"
        case .shoppingListDetail:
            return "Shopping List Detail"
        case .purchase(purchasedItem: _):
            return "Purchase"
        case .job(job: _):
            return "Job"
        case .editUser(user: _):
            return "Edit User"
        case .rateSheet(user: _):
            return "Rate Sheet"
        case .chat(chat: _):
            return "Chat"
        case .repairRequest(repairRequest: _):
            return "Repair Request"
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
            return "Reading Template"
        case .dosageTemplate:
            return "Dosage Template"
        case .recentActivity:
            return "Recent Activity"
        case .companyProfile:
            return "Company Profile"
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
        case .userSettings:
            return "User Settings"
        case .companySettings:
            return "Company Settings"
        case .businesses:
            return "Businesses"
        case .business:
            return "Business"
        case .vender:
            return "Vender"
        case .companyUserDetailView:
            return "Company User"
        case .companyUserRateSheet:
            return "Company User Rate Sheet"
        case .receipt:
            return "Recipt"
        case .alerts:
            return "Alerts"
  
        case .recurringLaborContractDetailView:
            return "Labor Contract Detail View"

        case .jobTemplate:
            return "Job Template"
        case .companyAlerts:
            return "Company Alerts"
        case .laborContracts:
            return "Labor Contracts"
        case .externalRouteOverView:
            return "External Route Overview"
        case .banks:
            return "Banks"
        case .transactions:
            return "Transactions"
        case .bankDetailView(bank: let bank, dataService: _):
            return "\(bank.name)"
        case .transactionDetailView(transaction: let transaction, dataService: _):
            return "\(transaction.amount)"
        case .activeRouteOverView:
            return "Todays Route Overview"
        
        case .emailConfiguration:
            return "Email Configuration"
        case .taskGroups:
            return "Task Groups"
            
        case .taskGroupDetail:
            return "Task Group Details"
        case .recurringServiceStopDetail:
            return "Recurring Service Stop Detail"

        case .customerStopDataDetailView:
            return "Stop History"
        case .workLogList:
            return "work Log List"
        case .workLogDetail:
            return "work Log Detail"
        case .editRole:
            return "Edit Role"
            
            

        case .receivedLaborContracts:
            return "Received Labor Contracts"
        case .sentLaborContracts:
            return "Sent Labor Contracts"
        case .recurringLaborContracts:
            return "Recurring Labor Contracts"
        case .internalRouteOverView:
            return "Internal Routes"
        case .jobPost:
            return "Job Post"
        case .companyPublicProfile:
            return "Public  Profile"
        case .laborContractDetailView:
            return "Labor Contract Detail View"
        case .buisnessContracts:
            return "buisnessContracts"
        case .contractTermsList:
            return "contractTermsList"

        case .recurringContracts:
                return "recurringContracts"
            
        case .receivedRecurringLaborContracts:
                return "receivedRecurringLaborContracts"
            
        case .sentRecurringLaborContracts:
            return "sentRecurringLaborContracts"
        case .invoices:
            return "Invoices"
        case .lifeCycles:
            return "Life Cycles"
        case .createLaborContractInvoice:
            return "createLaborContractInvoice"
        case .createRecurringLaborContractInvoice:
            return "createRecurringLaborContractInvoice"
        case .createBulkInvoice:
            return "createBulkInvoice"
        }
    }
}


extension Route:View {
    var body: some View {
        switch self {
        case .employeeMainDailyDisplayView(dataService: let dataService):
            EmployeeDailyDashboard(dataService: dataService) //Developer Stable
        case .jobs(dataService: let dataService):
            JobView(dataService: dataService)
        case .billingJobs(dataService: let dataService):
            BillingJobList(dataService: dataService)
            
            
        case .managementTables(let dataService):
            ManagementTablesView(dataService: dataService)
        case .purchases(let dataService):
            PurchasesView(dataService: dataService)//DEVELOPER THINK ABOUT REMOVING
        case .operation(let dataService):
            Operations(dataService: dataService)//DEVELOPER THINK ABOUT REMOVING
        case .finace(let dataService):
            Finance(dataService: dataService)//DEVELOPER THINK ABOUT REMOVING
        case .managment(let dataService):
            Managment(dataService: dataService)//DEVELOPER THINK ABOUT REMOVING
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
            ShoppingListView(dataService: dataService)
        case .purchasedItemsList(dataService: let dataService):
            UserPurchasedItems(dataService: dataService)
        case .map(dataService: let dataService):
            Text("Map")
        case .dailyDisplay(dataService: let dataService):
            Text("dailyDisplay")
        case .calendar(dataService: let dataService):
            Text("Calendar")
        case .profile(dataService: let dataService):
            ProfileView(dataService: dataService)
        case .pnl(dataService: let dataService):
            Text("PNL")
        case .routeBuilder(dataService: let dataService):
//            Text("Route Mangagment ?")
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
            ContractorDailyDashboard(dataService: dataService) //Developer Unstable
            

        case .serviceStops(dataService: let dataService):
            ServiceStopMainView()
        case .receipts(dataService: let dataService):
            ReceiptListView()
        case .databaseItems(dataService: let dataService):
            ReceiptDatabaseView(dataService: dataService)
        case .genericItems(dataService: let dataService):
            GenericItemList(dataService:dataService)
        case .venders(dataService: let dataService):
           StoreListView()
        case .users(dataService: let dataService):
            TechListView(dataService: dataService)
            //Settings
        case .userRoles(dataService: let dataService):
            UserRoleView()
        case .readingsAndDosages(dataService: let dataService):
            ReadingsAndDosagesList()
        case .emailConfiguration(dataService: let dataService):
            EmailConfigurationView()
        case .marketPlace(dataService: let dataService):
            MarketPlaceView(dataService: dataService)
        case .jobPosting(dataService: let dataService):
            JobBoardListView(dataService: dataService)
        case .jobBoard(dataService: let dataService, let jobBoard):
            JobBoardView(dataService: dataService, jobBoard:jobBoard)
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
            JobTemplateSettingsView(dataService: dataService)
        case .accountsPayableList(dataService: let dataService):
            AccountsPayableList(dataService: dataService)
        case .accountsReceivableList(dataService: let dataService):
            AccountsReceivableList(dataService: dataService)
        case .cart(dataService: let dataService):
            Text("Cart")
        case .shoppingListDetail(item: let item,dataService: let dataService):
            ShoppingListItemDetailView(item:item,dataService: dataService)
        case .purchase(purchasedItem: let purchasedItem, dataService: let dataService):
            PurchaseDetailView(purchase: purchasedItem, dataService: dataService)
        case .job(job: let job, dataService: let dataService):
            JobDetailView(job: job,dataService:dataService)
        case .editUser(user: let user, dataService: let dataService):
            EditProfileView(tech: user)
        case .rateSheet(user: let user, dataService: let dataService):
            TechRateSheet(tech: user)
        case .chat(chat: let chat, dataService: let dataService):
            ChatDetailView(dataService:dataService,chat:chat)
        case .repairRequest(repairRequest: let repairRequest, dataService: let dataService):
            RepairRequestDetailView(dataService: dataService,repairRequest: repairRequest)
        case .customer(customer: let customer, dataService: let dataService):
            CustomerDetailView(customer: customer)
        case .serviceStop(serviceStop: let serviceStop, dataService: let dataService):
            ServiceStopInfoView(serviceStop: serviceStop,dataService:dataService)
        case .dataBaseItem(dataBaseItem: let dataBaseItem, dataService: let dataService):
            DataBaseItemView(dataService: dataService, dataBaseItem:dataBaseItem)

        case .genericItem(dataService: let dataService):
            GenericItemDetailView()
        case .readingTemplate(tempalte:let template,dataService: let dataService):
            ReadingsDetail(readingTemplate:template)
        case .dosageTemplate(template:let template,dataService: let dataService):
            DosageDetail(dosageTemplate: template)
        case .recentActivity(dataService: let dataService):
            RecentActivity(dataService: dataService)
            //Company Profiles
        case .companyProfile(company: let company, dataService: let dataService):
           CompanyProfileView(dataService: dataService, company: company)
        case .companyPublicProfile(company: let company, dataService: let dataService):
            OtherCompanyProfileView(dataService: dataService, company: company)
            
        case .compileInvoice(dataService: let dataService):
            CompileInvoice(dataService: dataService)
        case .createNewJob(dataService: let dataService):
            AddNewJobView(dataService: dataService)
        case .createRepairRequest(dataService: let dataService):
            Text("Add Repair Request?")
        case .createCustomer(dataService: let dataService):
            AddNewCustomerView(dataService: dataService)
        case .equipmentDetailView(let equipment, dataService: let dataService):
            EquipmentDetailView(dataService: dataService, equipment: equipment)
        case .vehicalDetailView(let vehical,dataService: let dataService):
            VehicalDetailView(dataService: dataService, vehical:vehical)
        case .accountsPayableDetail(let invoice,dataService: let dataService):
            AccountsPayableDetail(invoice: invoice)
        case .accountsReceivableDetail(let invoice,dataService: let dataService):
            AccountsReceivableDetail(invoice: invoice)
        case .userSettings(dataService: let dataService):
            UserSettings(dataService:dataService)
        case .companySettings(dataService: let dataService):
            CompanySettings(dataService: dataService)
        case .businesses(dataService: let dataService):
            BusinessesListView(dataService:dataService)
        case .business(business: let business, dataService: let dataService):
            BusinessDetailView(dataService: dataService,business:business)
        case .vender(vender: let vender, dataService: let dataService):
            StoreDetailView(store: vender)
        case .companyUserDetailView(user: let user, dataService: let dataService):
            CompanyUserDetailView(dataService: dataService, companyUser: user)
        case .companyUserRateSheet(user: let user, dataService: let dataService):
            CompanyUserRateSheet(tech: user)
        case .receipt(receipt: let receipt, dataService: let dataService):
            ReceiptDetailView(receipt: receipt)
        case .alerts(dataService: let dataService):
            PersonalAlertView(dataService: dataService)
        case .jobTemplate(jobTemplate: let jobTemplate, dataService: let dataService):
            JobTemplateDetailView(template: jobTemplate)
        case .companyAlerts(dataService: let dataService):
            CompanyAlerts(dataService: dataService)
        case .companyRouteOverView(dataService: let dataService):
            AllCompanyRegularRoutes(dataService: dataService)
        case .internalRouteOverView(dataService: let dataService):
            RouteManagmentView(dataService: dataService)
        case .externalRouteOverView(dataService: let dataService):
            ExternalRouteListView(dataService: dataService)
        case .banks(dataService: let dataService):
            BankListView()
        case .transactions(dataService: let dataService):
            TransactionListView()
        case .bankDetailView(bank: let bank, dataService: let dataService):
            BankDetailView()
        case .transactionDetailView(transaction: let transaction, dataService: let dataService):
            TransactionDetailView()
        case .activeRouteOverView(dataService: let dataService):
            UserRouteOverView(dataService: dataService)
        case .taskGroups(dataService: let dataService):
            TaskGroupListView(dataService: dataService)
        case .taskGroupDetail(dataService: let dataService, taskGroup: let taskGroup):
            TaskGroupDetailView(dataService: dataService, taskGroup: taskGroup)
        case .recurringServiceStopDetail(dataService: let dataService, recurringServiceStop: let recurringServiceStop):
            RecurringServiceStopDetailView(dataService: dataService, RSS: recurringServiceStop)
        case .customerStopDataDetailView(dataService: let dataService, customerId: let customerId):
            CustomerStopDataDetailView(dataService: dataService, customerId: customerId)
        case .workLogList(dataService: let dataService):
            WorkLogListView(dataService: dataService)
        case .workLogDetail(dataService: let dataService, workLog: let workLog):
            WorkLogDetailView(dataService: dataService, workLog: workLog)
        case .editRole(dataService: let dataService, role: let role):
            CompanyRoleEditView(dataService: dataService, role: role)
            
        case .jobPost(dataService: let dataService, jobPost: let jobPost):
            JobPostDetailView(dataService: dataService, jobPost: jobPost)
        //Invoices
        case .invoices(dataService: let dataService):
            Invoices()
            
        //All Contracts
            //B to C
        case .contracts(dataService: let dataService):
            ContractListView(dataService: dataService)
        case .recurringContracts(dataService: let dataService):
            RecurringContractListView()
            
        case .contract(contract: let contract, dataService: let dataService):
            ContractDetailView(dataService: dataService, contract:contract)
            
            
        case .recurringLaborContracts(dataService: let dataService):
            RecurringLaborContractListView(dataService: dataService)
        case .receivedRecurringLaborContracts(dataService: let dataService):
            ReceivedRecurringLaborContractListView(dataService: dataService)
        case .sentRecurringLaborContracts(dataService: let dataService):
            SentRecurringLaborContractListView(dataService: dataService)
        case .recurringLaborContractDetailView(contract: let contract, dataService: let dataService):
            RecurringLaborContractDetailView(dataService:dataService,laborContract: contract)
            
            
        case .laborContracts(dataService: let dataService):
            LaborContractListView(dataService: dataService)
        case .receivedLaborContracts(dataService: let dataService):
            ReceivedLaborContractListView(dataService: dataService)
        case .sentLaborContracts(dataService: let dataService):
            SentLaborContractListView(dataService: dataService)
        case .laborContractDetailView(dataService: let dataService, contract: let contract):
            SingleLaborContractDetailView(dataService: dataService, laborContract: contract)
            
            
        case .buisnessContracts(dataService: let dataService):
            BuisnessContracts()
            
        case .contractTermsList(dataService: let dataService, termsList: let termsList):
            ContractTermsList(contractTerms: termsList)
        
            
        case .lifeCycles(dataService: let dataService):
            LifeCyclesView(dataService:dataService)
            
            
        case .createLaborContractInvoice(dataService: let dataService, laborContract: let laborContract):
            CreateLaborContractInvoice(dataService: dataService, laborContract: laborContract)
        case .createRecurringLaborContractInvoice(dataService: let dataService, recurringLaborContract: let recurringLaborContract):
            CreateRecurringContractInvoice(dataService: dataService, recurringLaborContract: recurringLaborContract)
        case .createBulkInvoice(dataService: let dataService, associatedBusiness: let associatedBusiness):
            CreateBulkInvoice(dataService: dataService, associatedBusiness: associatedBusiness)
        }
    }
}
    func convertRouteToString(route:Route) -> RouteString {
        switch route {
        case .jobs:
            return .jobs
        case .billingJobs:
            return .jobs
        case .employeeMainDailyDisplayView:
            return .employeeMainDailyDisplayView //DEVELOPER PLEASE FIX
            
            
        case .operation:
            return .operation
            
        case .finace:
            return .finace
            
        case .managment:
            return .managment
            
        case .dashBoard:
            return .dashBoard
            
        case .customers:
            return .customers
            
        case .toDoDetail:
            return .toDoDetail
            
        case .repairRequestList:
            return .repairRequestList
            
        case .toDoList:
            return .toDoList
            
        case .pendingJobs:
            return .pendingJobs
            
        case .shoppingList:
            return .shoppingList
            
        case .purchasedItemsList:
            return .purchasedItemsList
            
        case .map:
            return .map
            
        case .dailyDisplay:
            return .dailyDisplay
            
        case .calendar:
            return .calendar
            
        case .profile:
            return .profile
            
        case .routeBuilder(dataService: _):
            return .routeBuilder
            
        case .pnl:
            return .pnl
            
        case .routeOverview(route: _):
            return .routeOverview
            
        case .allTechRouteOverview(route: _):
            return .allTechRouteOverview
            
        case .dailyDisplayStop:
            return .dailyDisplayStop
            
        case .reports:
            return .reports
            
        case .fleet:
            return .fleet
            
        case .mainDailyDisplayView:
            return .mainDailyDisplayView
            
        case .serviceStops:
            return .serviceStops
            

            
        case .contracts:
            return .contracts
            
        case .purchases:
            return .purchases
            
        case .receipts:
            return .receipts
            
        case .databaseItems:
            return .databaseItems
            
        case .genericItems:
            return .genericItems
            
        case .venders:
            return .venders
            
        case .users:
            return .users
            
        case .userRoles:
            return .userRoles
            
        case .readingsAndDosages:
            return .readingsAndDosages
            
        case .marketPlace:
            return .marketPlace
            
        case .jobPosting:
            return .jobPosing
            
        case .feed:
            return .feed
            
        case .chats:
            return .chats
            
        case .cart:
            return .cart
            
        case .shoppingListDetail:
            return .shoppingListDetail
            
        case .purchase(purchasedItem: _):
            return .purchase
            
        case .job(job: _):
            return .job
            
        case .editUser(user: _):
            return .editUser
            
        case .rateSheet(user: _):
            return .rateSheet
            
        case .chat(chat: _):
            return .chat
            
        case .repairRequest(repairRequest: _):
            return .repairRequest
            
        case .customer(customer: _):
            return .customer
            
        case .serviceStop(serviceStop: _):
            return .serviceStop
            
        case .dataBaseItem(dataBaseItem: _):
            return .dataBaseItem
            
        case .contract(contract: _):
            return .contract
            
        case .genericItem:
            return .genericItem
            
        case .readingTemplate:
            return .readingTemplate
            
        case .dosageTemplate:
            return .dosageTemplate
            
        case .recentActivity:
            return .recentActivity
            
        case .companyProfile:
            return .companyProfile
        case .compileInvoice:
            return .compileInvoice
            
        case .createNewJob:
            return .createNewJob
        case .createRepairRequest:
            return .createRepairRequest
        case .createCustomer:
            return .createCustomer
        case .equipmentDetailView:
            return .equipmentDetailView
        case .vehicalDetailView:
            return .vehicalDetailView
            
        case .equipmentList:
            return .equipmentList
        case .routes:
            return .routes
        case .settings:
            return .settings
        case .jobTemplates:
            return .jobTemplates
        case .companyRouteOverView:
            return .companyRouteOverView
        case .accountsPayableList:
            return .accountsPayableList
        case .accountsReceivableList:
            return .accountsReceivableList
        case .accountsPayableDetail:
            return .accountsPayableDetail
        case .accountsReceivableDetail:
            return .accountsReceivableDetail
        case .userSettings:
            return .userSettings
        case .companySettings:
            return .companySettings
        case .businesses:
            return .businesses
        case .business:
            return .business
        case .vender:
            return .vender
        case .companyUserDetailView:
            return .companyUserDetailView
        case .companyUserRateSheet:
            return .companyUserRateSheet
        case .receipt:
            return .receipt
        case .alerts:
            return .alerts
        case .recurringLaborContractDetailView:
            return .laborContractDetailView
        case .jobTemplate:
            return .jobTemplate
        case .companyAlerts:
            return .companyAlerts
        case .laborContracts:
            return .laborContracts
        case .externalRouteOverView:
            return .externalRouteOverView
        case .banks:
            return .banks
        case .transactions:
            return .transactions
        case .bankDetailView:
            return .bankDetailView
        case .transactionDetailView:
            return .transactionDetailView
        case .activeRouteOverView:
            return .activeRouteOverView
        case .emailConfiguration:
            return .emailConfiguration
        case .managementTables:
            return .managementTables
        case .taskGroups:
            return .managementTables //DEVELOPER PLEASE FIX
        case .taskGroupDetail:
            return .managementTables //DEVELOPER PLEASE FIX
        case .recurringServiceStopDetail:
            return .managementTables //DEVELOPER PLEASE FIX
        case .customerStopDataDetailView:
            return .managementTables //DEVELOPER PLEASE FIX
        case .workLogList:
            return .managementTables //DEVELOPER PLEASE FIX
        case .workLogDetail:
            return .managementTables //DEVELOPER PLEASE FIX
        case .editRole:
            return .managementTables //DEVELOPER PLEASE FIX

        case .receivedLaborContracts:
            return .managementTables //DEVELOPER PLEASE FIX
        case .sentLaborContracts:
            return .managementTables //DEVELOPER PLEASE FIX
            
        case .recurringLaborContracts:
            return .laborContracts //DEVELOPER PLEASE FIX
            
        case .internalRouteOverView:
            return .laborContracts //DEVELOPER PLEASE FIX

        case .jobBoard:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .jobPost:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .companyPublicProfile:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .laborContractDetailView:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .buisnessContracts:
            return .laborContracts //DEVELOPER PLEASE FIX

        case .contractTermsList:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .recurringContracts:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .receivedRecurringLaborContracts:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .sentRecurringLaborContracts:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .lifeCycles:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .invoices:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .createLaborContractInvoice:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .createRecurringLaborContractInvoice:
            return .laborContracts //DEVELOPER PLEASE FIX
        case .createBulkInvoice:
            return .laborContracts //DEVELOPER PLEASE FIX
        }
    }

extension Route: Hashable{
    func hash(into hasher:inout Hasher) {
        hasher.combine(self.hashValue)
    }
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs,rhs) {
        case (.jobs(dataService: _), _):
            return true
        case (.billingJobs(dataService: _), _):
            return true
            
        case (.employeeMainDailyDisplayView(dataService: _), _):
            return true

//------------- Here down
        case (.operation(dataService: _), _):
            return true
        case (.finace(dataService: _), _):
            return true
        case (.managment(dataService: _), _):
            return true
        case (.dashBoard(dataService: _), _):
            return true
        case (.managementTables(dataService: _), _):
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

        case (.activeRouteOverView(dataService: _), _):
        
            return true

        case (.routeBuilder(dataService: _), _):
        
            return true

        case (.pnl(dataService: _), _):
        
            return true

        case (.companyRouteOverView(dataService: _), _):
        
            return true

        case (.internalRouteOverView(dataService: _), _):
            return true

        case (.externalRouteOverView(dataService: _), _):
            return true

        case (.reports(dataService: _), _):
            return true

        case (.fleet(dataService: _), _):
            return true

        case (.mainDailyDisplayView(dataService: _), _):
            return true


        case (.serviceStops(dataService: _), _):
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

        case (.emailConfiguration(dataService: _), _):
        
            return true

        case (.marketPlace(dataService: _), _):
        
            return true

        case (.jobPosting(dataService: _), _):
        
        
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

        case (.businesses(dataService: _), _):
        
            return true

        case (.alerts(dataService: _), _):
        
            return true

        case (.companyAlerts(dataService: _), _):
        
            return true

        case (.contracts(dataService: _), _):
        
            return true

        case (.buisnessContracts(dataService: _), _):
        
            return true

        case (.laborContracts(dataService: _), _):
            return true

        case (.recurringLaborContracts(dataService: _), _):
            return true

        case (.receivedLaborContracts(dataService: _), _):
            return true

        case (.sentLaborContracts(dataService: _), _):
            return true

        case (.banks(dataService: _), _):
            return true

        case (.transactions(dataService: _), _):
            return true

        case (.taskGroups(dataService: _), _):
            return true

        case (.workLogList(dataService: _), _):
            return true
        case (.cart(dataService: _), _):
            return true
                
        

        // Detail Views - Pages
        case (.routeOverview(route: _, dataService: _), _):
            return true
        case (.allTechRouteOverview(route: _, dataService: _), _):
            return true
        case (.dailyDisplayStop(dataService: _, serviceStop: _), _):
            return true
        case (.jobBoard(dataService: _, jobBoard: _), _):
            return true
        case (.jobPost(dataService: _, jobPost: _), _):
            return true
        case (.workLogDetail(dataService: _, workLog: _), _):
            return true
            
        case (.editRole(dataService: _, role: _), _):
            return true
        case (.taskGroupDetail(dataService: _, taskGroup: _), _):
            return true
        case (.bankDetailView(bank: _, dataService: _), _):
            return true
        case (.transactionDetailView(transaction: _, dataService: _), _):
            return true
        case (.shoppingListDetail(item: _, dataService: _), _):
            return true
        case (.purchase(purchasedItem: _, dataService: _), _):
            return true
        case (.job(job: _, dataService: _), _):
            return true
        case (.editUser(user: _, dataService: _), _):
            return true
        case (.rateSheet(user: _, dataService: _), _):
            return true
        case (.companyUserRateSheet(user: _, dataService: _), _):
            return true
        case (.chat(chat: _, dataService: _), _):
            return true
        case (.repairRequest(repairRequest: _, dataService: _), _):
            return true

        case (.customer(customer: _, dataService: _), _):
            return true
            

        case (.serviceStop(serviceStop: _, dataService: _), _):
            return true
            

        case (.business(business: _, dataService: _), _):
            return true
            

        case (.vender(vender: _, dataService: _), _):
            return true
            

            
        case (.dataBaseItem(dataBaseItem: _, dataService: _), _):
            return true
            

        case (.contract(contract: _, dataService: _), _):
            return true
            

            
        case (.genericItem(item: _, dataService: _), _):
            return true
            

            
        case (.readingTemplate(tempalte: _, dataService: _), _):
            return true
            

            
        case (.dosageTemplate(template: _, dataService: _), _):
            return true
            

            
        case (.recentActivity(dataService: _), _):
            return true
            

            
        case (.receipt(receipt: _, dataService: _), _):
            return true
            


            
        case (.companyProfile(company: _, dataService: _), _):
            return true
            

            
        case (.companyPublicProfile(company: _, dataService: _), _):
            return true
            

            
        case (.compileInvoice(dataService: _), _):
            return true
            

            
        case (.createNewJob(dataService: _), _):
            return true
            

            
        case (.createRepairRequest(dataService: _), _):
            return true
        case (.createCustomer(dataService: _), _):
            return true
        case (.equipmentDetailView(equipment: _, dataService: _), _):
            return true
        case (.vehicalDetailView(vehical: _, dataService: _), _):
            return true
        case (.accountsPayableDetail(invoice: _, dataService: _), _):
            return true
        case (.accountsReceivableDetail(invoice: _, dataService: _), _):
            return true
        case (.companyUserDetailView(user: _, dataService: _), _):
            return true
        case (.recurringLaborContractDetailView(contract: _, dataService: _), _):
            return true
        case (.laborContractDetailView(dataService: _, contract: _), _):
            return true
        case (.jobTemplate(jobTemplate: _, dataService: _), _):
            return true
        case (.recurringServiceStopDetail(dataService: _, recurringServiceStop: _), _):
            return true
        case (.customerStopDataDetailView(dataService: _, customerId: _), _):
            return true
        case (.contractTermsList(dataService: _, termsList: _), _):
            return true
        case (.recurringContracts(dataService: _), _):
            return true
        case (.receivedRecurringLaborContracts(dataService: _), _):
            return true
        case (.sentRecurringLaborContracts(dataService: _), _):
            return true
        case (.lifeCycles(dataService: _), _):
            return true
        case (.invoices(dataService: _), _):
            return true
        case (.createLaborContractInvoice(dataService: _, laborContract: _), _):
            return true
        case (.createRecurringLaborContractInvoice(dataService: _, recurringLaborContract: _), _):
            return true
        case (.createBulkInvoice(dataService: _, associatedBusiness: _), _):
            return true
        }
    }
}
