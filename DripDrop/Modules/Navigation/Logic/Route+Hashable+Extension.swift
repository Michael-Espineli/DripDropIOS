//
//  Route+Hashable+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation



/*
 
 //Old Hasher
 
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
        case (.companyInfo(dataService: _), _):
            return true
        case (.manageSubscriptions(dataService: _), _):
            return true
        case (.stripeConfiguration(dataService: _), _):
            return true
        case (.editCompanySubscription(dataService:  _), _):
            return true
        case (.inviteDetailView(dataService:  _, invite:  _), _):
            return true
        case (.techInviteList(dataService:  _), _):
            return true
        case (.browseCompanies(dataService:  _), _):
            return true
        case (.createCompanyView(dataService:  _), _):
            return true
        case (.initiateChat(dataService:  _, userId:  _), _):
            return true
        }
    }
}
*/
