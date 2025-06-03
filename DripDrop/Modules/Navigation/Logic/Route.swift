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
            AddNewRepairRequest(dataService: dataService, isPresented: .constant(true))
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

