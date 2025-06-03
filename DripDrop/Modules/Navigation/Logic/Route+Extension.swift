//
//  Route+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/2/25.
//

import Foundation
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
