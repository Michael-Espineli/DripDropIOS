//
//  Route+convertRouteToString+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation
func convertRouteToString(route:Route) -> RouteString {
    switch route {
    case .jobs(dataService: _):
        return .jobs
    case .billingJobs(dataService: _):
        return .jobs
    case .employeeMainDailyDisplayView(dataService: _):
        return .employeeMainDailyDisplayView

    case .operation(dataService: _):
        return .operation
    case .finace(dataService: _):
        return .finace
    case .managment(dataService: _):
        return .managment
    case .dashBoard(dataService: _):
        return .dashBoard
    case .customers(dataService: _):
        return .customers
    case .toDoDetail(dataService: _):
        return .toDoDetail
    case .repairRequestList(dataService: _):
        return .repairRequestList
    case .toDoList(dataService: _):
        return .toDoList
    case .pendingJobs(dataService: _):
        return .pendingJobs
    case .shoppingList(dataService: _):
        return .shoppingList
    case .purchasedItemsList(dataService: _):
        return .purchasedItemsList
    case .map(dataService: _):
        return .map
    case .dailyDisplay(dataService: _):
        return .dailyDisplay
    case .calendar(dataService: _):
        return .calendar
    case .profile(dataService: _):
        return .profile
    case .routeBuilder(dataService: _):
        return .routeBuilder
    case .pnl(dataService: _):
        return .pnl
    case .routeOverview(route: _, dataService: _):
        return .routeOverview
    case .allTechRouteOverview(route: _, dataService: _):
        return .allTechRouteOverview
    case .dailyDisplayStop(dataService: _, serviceStop: _):
        return .dailyDisplayStop
    case .reports(dataService: _):
        return .reports
    case .fleet(dataService: _):
        return .fleet
    case .mainDailyDisplayView(dataService: _):
        return .mainDailyDisplayView
    case .serviceStops(dataService: _):
        return .serviceStops

    case .contracts(dataService: _):
        return .contracts
    case .purchases(dataService: _):
        return .purchases
    case .receipts(dataService: _):
        return .receipts
    case .databaseItems(dataService: _):
        return .databaseItems
    case .genericItems(dataService: _):
        return .genericItems
    case .venders(dataService: _):
        return .venders
    case .users(dataService: _):
        return .users
    case .userRoles(dataService: _):
        return .userRoles
    case .readingsAndDosages(dataService: _):
        return .readingsAndDosages
    case .marketPlace(dataService: _):
        return .marketPlace
    case .jobPosting(dataService: _):
        return .jobPosing
    case .feed(dataService: _):
        return .feed
    case .chats(dataService: _):
        return .chats
    case .cart(dataService: _):
        return .cart
    case .shoppingListDetail(item: _, dataService: _):
        return .shoppingListDetail
    case .purchase(purchasedItem: _, dataService: _):
        return .purchase
    case .job(job: _, dataService: _):
        return .job
    case .editUser(user: _, dataService: _):
        return .editUser
    case .rateSheet(user: _, dataService: _):
        return .rateSheet
    case .chat(chat: _, dataService: _):
        return .chat
    case .repairRequest(repairRequest: _, dataService: _):
        return .repairRequest
    case .customer(customer: _, dataService: _):
        return .customer
    case .serviceStop(serviceStop: _, dataService: _):
        return .serviceStop
    case .dataBaseItem(dataBaseItem: _, dataService: _):
        return .dataBaseItem
    case .contract(contract: _, dataService: _):
        return .contract
    case .genericItem(item: _, dataService: _):
        return .genericItem
    case .readingTemplate(tempalte: _, dataService: _):
        return .readingTemplate
    case .dosageTemplate(template: _, dataService: _):
        return .dosageTemplate
    case .recentActivity(dataService: _):
        return .recentActivity
    case .companyProfile(company: _, dataService: _):
        return .companyProfile
    case .compileInvoice(dataService: _):
        return .compileInvoice
    case .createNewJob(dataService: _):
        return .createNewJob
    case .createRepairRequest(dataService: _):
        return .createRepairRequest
    case .createCustomer(dataService: _):
        return .createCustomer
    case .equipmentDetailView(equipment: _, dataService: _):
        return .equipmentDetailView
    case .vehicalDetailView(vehical: _, dataService: _):
        return .vehicalDetailView
    case .equipmentList(dataService: _):
        return .equipmentList
    case .routes(dataService: _):
        return .routes
    case .settings(dataService: _):
        return .settings
    case .jobTemplates(dataService: _):
        return .jobTemplates
    case .companyRouteOverView(dataService: _):
        return .companyRouteOverView
    case .accountsPayableList(dataService: _):
        return .accountsPayableList
    case .accountsReceivableList(dataService: _):
        return .accountsReceivableList
    case .accountsPayableDetail(invoice: _, dataService: _):
        return .accountsPayableDetail
    case .accountsReceivableDetail(invoice: _, dataService: _):
        return .accountsReceivableDetail
    case .userSettings(dataService: _):
        return .userSettings
    case .companySettings(dataService: _):
        return .companySettings
    case .businesses(dataService: _):
        return .businesses
    case .business(business: _, dataService: _):
        return .business
    case .vender(vender: _, dataService: _):
        return .vender
    case .companyUserDetailView(user: _, dataService: _):
        return .companyUserDetailView
    case .companyUserRateSheet(user: _, dataService: _):
        return .companyUserRateSheet
    case .receipt(receipt: _, dataService: _):
        return .receipt
    case .alerts(dataService: _):
        return .alerts
    case .recurringLaborContractDetailView(contract: _, dataService: _):
        return .laborContractDetailView
    case .jobTemplate(jobTemplate: _, dataService: _):
        return .jobTemplate
    case .companyAlerts(dataService: _):
        return .companyAlerts
    case .laborContracts(dataService: _):
        return .laborContracts
    case .externalRouteOverView(dataService: _):
        return .externalRouteOverView
    case .banks(dataService: _):
        return .banks
    case .transactions(dataService: _):
        return .transactions
    case .bankDetailView(bank: _, dataService: _):
        return .bankDetailView
    case .transactionDetailView(transaction: _, dataService: _):
        return .transactionDetailView
    case .activeRouteOverView(dataService: _):
        return .activeRouteOverView
    case .emailConfiguration(dataService: _):
        return .emailConfiguration
    case .managementTables(dataService: _):
        return .managementTables
    case .taskGroups(dataService: _):
        return .managementTables  // Developer fix
    case .taskGroupDetail(dataService: _, taskGroup: _):
        return .managementTables
    case .recurringServiceStopDetail(dataService: _, recurringServiceStop: _):
        return .managementTables
    case .customerStopDataDetailView(dataService: _, customerId: _):
        return .managementTables
    case .workLogList(dataService: _):
        return .managementTables  // Developer fix
    case .workLogDetail(dataService: _, workLog: _):
        return .managementTables  // Developer fix
    case .editRole(dataService: _, role: _):
        return .managementTables  // Developer fix
    case .receivedLaborContracts(dataService: _):
        return .managementTables  // Developer fix
    case .sentLaborContracts(dataService: _):
        return .managementTables  // Developer fix
    case .recurringLaborContracts(dataService: _):
        return .managementTables  // Developer fix
    case .internalRouteOverView(dataService: _):
        return .managementTables  // Developer fix
    case .jobBoard(dataService: _, jobBoard: _):
        return .managementTables  // Developer fix
    case .jobPost(dataService: _, jobPost: _):
        return .managementTables  // Developer fix
    case .companyPublicProfile(company: _, dataService: _):
        return .managementTables  // Developer fix
    case .laborContractDetailView(dataService: _, contract: _):
        return .laborContractDetailView
    case .buisnessContracts(dataService: _):
        return .managementTables  // Developer fix
    case .contractTermsList(dataService: _, termsList: _):
        return .managementTables  // Developer fix
    case .recurringContracts(dataService: _):
        return .managementTables  // Developer fix
    case .receivedRecurringLaborContracts(dataService: _):
        return .managementTables  // Developer fix
    case .sentRecurringLaborContracts(dataService: _):
        return .managementTables  // Developer fix
    case .lifeCycles(dataService: _):
        return .managementTables  // Developer fix
    case .invoices(dataService: _):
        return .managementTables  // Developer fix
    case .createLaborContractInvoice(dataService: _, laborContract: _):
        return .managementTables  // Developer fix
    case .createRecurringLaborContractInvoice(dataService: _, recurringLaborContract: _):
        return .managementTables  // Developer fix
    case .createBulkInvoice(dataService: _, associatedBusiness: _):
        return .managementTables  // Developer fix
    case .companyInfo(dataService: _):
        return .managementTables  // Developer fix
    case .manageSubscriptions(dataService: _):
        return .managementTables  // Developer fix
    case .stripeConfiguration(dataService: _):
        return .managementTables  // Developer fix
    case .editCompanySubscription(dataService: _):
        return .managementTables  // Developer fix
    case .inviteDetailView(dataService: let dataService, invite: let invite):
        return .managementTables  // Developer fix
    case .techInviteList(dataService: let dataService):
        return .managementTables  // Developer fix
    case .browseCompanies(dataService: let dataService):
        return .managementTables  // Developer fix
    case .createCompanyView(dataService: let dataService):
        return .managementTables  // Developer fix
    case .initiateChat(dataService: let dataService, userId: let userId):
        return .managementTables  // Developer fix
    }
}
