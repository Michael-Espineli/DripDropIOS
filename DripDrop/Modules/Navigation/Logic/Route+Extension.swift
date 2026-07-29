//
//  Route+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/2/25.
//

import Foundation

extension Route {
    func title() ->String{
        switch self {
        case .jobs:
            return "Jobs"
        case .billingJobs:
            return "Billing Jobs"
        case .leads:
            return "Leads"
        case .sales:
            return "Sales"
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
        case .todoItemDetail:
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
        case .offeredWork:
            return "Offered Work"
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
        case .companyInfo:
            return "companyInfo"
        case .manageSubscriptions:
            return "manageSubscriptions"
        case .stripeConfiguration:
            return "stripeConfiguration"
        case .editCompanySubscription:
            return "editCompanySubscription"
            
        case .inviteDetailView:
            return "Invite Detail View"
        case .techInviteList:
            return "Tech Invite List"
        case .browseCompanies:
            return "Browse Companies"
        case .createCompanyView:
            return "Create Company View"
        case .initiateChat:
            return "Initiate Chat"
        case .manageTermsTemplates:
            return "Manage Terms Templates"
        case .userRoleDetailView:
            return "Role Detail View"
        case .termsTemplateDetailView:
            return "Terms Template Detail"
        case .payRoll:
            return "Pay Roll"
        case .payRollSettings:
            return "Pay Roll Settings"
        case .technicianWorkCenter:
            return "Technician Work Center"
        }
    }
}
