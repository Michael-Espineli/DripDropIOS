//
//  Route+Kind+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation

extension Route {
    // A simple discriminator for the case
    private var kindDiscriminator: Int {
        switch self {
        case .jobs: return 1
        case .billingJobs: return 2
        case .employeeMainDailyDisplayView: return 3
        case .operation:
            return 4
        case .finace:
            return 5
        case .managment:
            return 6
        case .dashBoard:
            return 7
        case .lifeCycles:
            return 8
        case .managementTables:
            return 9
        case .customers:
            return 10
        case .toDoDetail:
            return 11
        case .repairRequestList:
            return 12
        case .toDoList:
            return 13
        case .pendingJobs:
            return 14
        case .shoppingList:
            return 15
        case .purchasedItemsList:
            return 16
        case .map:
            return 17
        case .dailyDisplay:
            return 18
        case .calendar:
            return 19
        case .profile:
            return 20
        case .activeRouteOverView:
            return 21
        case .routeBuilder:
            return 22
        case .pnl:
            return 23
        case .companyRouteOverView:
            return 24
        case .internalRouteOverView:
            return 25
        case .externalRouteOverView:
            return 26
        case .routeOverview:
            return 27
        case .allTechRouteOverview:
            return 28
        case .dailyDisplayStop:
            return 29
        case .reports:
            return 30
        case .fleet:
            return 31
        case .mainDailyDisplayView:
            return 32
        case .serviceStops:
            return 33
        case .purchases:
            return 34
        case .receipts:
            return 35
        case .databaseItems:
            return 36
        case .genericItems:
            return 37
        case .venders:
            return 38
        case .users:
            return 39
        case .userRoles:
            return 40
        case .readingsAndDosages:
            return 41
        case .emailConfiguration:
            return 42
        case .marketPlace:
            return 43
        case .jobPosting:
            return 44
        case .jobBoard:
            return 45
        case .jobPost:
            return 46
        case .feed:
            return 47
        case .chats:
            return 48
        case .equipmentList:
            return 49
        case .routes:
            return 50
        case .settings:
            return 51
        case .userSettings:
            return 52
        case .companySettings:
            return 53
        case .jobTemplates:
            return 54
        case .accountsPayableList:
            return 55
        case .accountsReceivableList:
            return 56
        case .businesses:
            return 57
        case .alerts:
            return 58
        case .companyAlerts:
            return 59
        case .buisnessContracts:
            return 60
        case .contracts:
            return 61
        case .recurringContracts:
            return 62
        case .recurringLaborContracts:
            return 63
        case .sentRecurringLaborContracts:
            return 64
        case .receivedRecurringLaborContracts:
            return 65
        case .laborContracts:
            return 66
        case .sentLaborContracts:
            return 67
        case .receivedLaborContracts:
            return 68
        case .banks:
            return 69
        case .transactions:
            return 70
        case .taskGroups:
            return 71
        case .workLogList:
            return 72
        case .invoices:
            return 73
        case .companyInfo:
            return 74
        case .manageSubscriptions:
            return 75
        case .stripeConfiguration:
            return 76
        case .workLogDetail:
            return 77
        case .editRole:
            return 78
        case .taskGroupDetail:
            return 79
        case .cart:
            return 80
        case .bankDetailView:
            return 81
        case .transactionDetailView:
            return 82
        case .shoppingListDetail:
            return 83
        case .purchase:
            return 84
        case .job:
            return 85
        case .editUser:
            return 86
        case .rateSheet:
            return 87
        case .companyUserRateSheet:
            return 88
        case .chat:
            return 89
        case .repairRequest:
            return 90
        case .customer:
            return 91
        case .serviceStop:
            return 92
        case .business:
            return 93
        case .vender:
            return 94
        case .dataBaseItem:
            return 95
        case .contract:
            return 96
        case .genericItem:
            return 97
        case .readingTemplate:
            return 98
        case .dosageTemplate:
            return 99
        case .recentActivity:
            return 100
        case .receipt:
            return 101
        case .companyProfile:
            return 102
        case .companyPublicProfile:
            return 103
        case .compileInvoice:
            return 104
        case .createNewJob:
            return 105
        case .createRepairRequest:
            return 106
        case .createCustomer:
            return 107
        case .equipmentDetailView:
            return 108
        case .vehicalDetailView:
            return 109
        case .accountsPayableDetail:
            return 110
        case .accountsReceivableDetail:
            return 111
        case .companyUserDetailView:
            return 112
        case .recurringLaborContractDetailView:
            return 113
        case .laborContractDetailView:
            return 114
        case .jobTemplate:
            return 115
        case .recurringServiceStopDetail:
            return 116
        case .customerStopDataDetailView:
            return 117
        case .contractTermsList:
            return 118
        case .createLaborContractInvoice:
            return 119
        case .createRecurringLaborContractInvoice:
            return 120
        case .createBulkInvoice:
            return 121
        case .editCompanySubscription:
            return 122
        case .inviteDetailView:
            return 123
        case .techInviteList:
            return 124
        case .browseCompanies:
            return 125
        case .createCompanyView:
            return 126
        case .initiateChat:
            return 127
        case .manageTermsTemplates:
            return 128
        case .userRoleDetailView:
            return 129
        case .termsTemplateDetailView:
            return 130
        case .payRoll:
            return 131
        case .payRollSettings:
            return 132
        case .technicianWorkCenter:
            return 133
        }
    }

    // Extract only identity-defining values
    private func identityComponents(into hasher: inout Hasher) {
        switch self {
        case .jobs:
            break // no associated identity
        case .operation:
            break
        case .finace:
            break
        case .managment:
            break
        case .dashBoard:
            break
        case .lifeCycles:
            break
        case .managementTables:
            break
        case .customers:
            break
        case .toDoDetail:
            break
        case .repairRequestList:
            break
        case .toDoList:
            break
        case .pendingJobs:
            break
        case .shoppingList:
            break
        case .purchasedItemsList:
            break
        case .map:
            break
        case .dailyDisplay:
            break
        case .calendar:
            break
        case .profile:
            break
        case .activeRouteOverView:
            break
        case .routeBuilder:
            break
        case .pnl:
            break
        case .companyRouteOverView:
            break
        case .internalRouteOverView:
            break
        case .externalRouteOverView:
            break
        case .reports:
            break
        case .fleet:
            break
        case .mainDailyDisplayView:
            break
        case .employeeMainDailyDisplayView:
            break
        case .billingJobs:
            break
        case .serviceStops:
            break
        case .purchases:
            break
        case .receipts:
            break
        case .databaseItems:
            break
        case .genericItems:
            break
        case .venders:
            break
        case .users:
            break
        case .userRoles:
            break
        case .readingsAndDosages:
            break
        case .emailConfiguration:
            break
        case .marketPlace:
            break
        case .jobPosting:
            break
        case .feed:
            break
        case .chats:
            break
        case .equipmentList:
            break
        case .routes:
            break
        case .settings:
            break
        case .userSettings:
            break
        case .companySettings:
            break
        case .jobTemplates:
            break
        case .accountsPayableList:
            break
        case .accountsReceivableList:
            break
        case .businesses:
            break
        case .alerts:
            break
        case .companyAlerts:
            break
        case .buisnessContracts:
            break
        case .contracts:
            break
        case .recurringContracts:
            break
        case .recurringLaborContracts:
            break
        case .sentRecurringLaborContracts:
            break
        case .receivedRecurringLaborContracts:
            break
        case .laborContracts:
            break
        case .sentLaborContracts:
            break
        case .receivedLaborContracts:
            break
        case .banks:
            break
        case .transactions:
            break
        case .taskGroups:
            break
        case .workLogList:
            break
        case .invoices:
            break
        case .companyInfo:
            break
        case .manageSubscriptions:
            break
        case .stripeConfiguration:
            break
        case .cart:
            break
        case .recentActivity:
            break
        case .techInviteList:
            break
        case .browseCompanies:
            break
        case .createCompanyView:
            break
        case .compileInvoice:
            break
        case .createNewJob:
            break
        case .createRepairRequest:
            break
        case .createCustomer:
            break
        case .editCompanySubscription:
            break
            
        //Routes having Ids: use a stable identifier, not the entire object
        case .chat(let chat, _):
            hasher.combine(chat.id)
        case .customer(let customer, _):
            hasher.combine(customer.id)
        case .routeOverview(route: let route, _):
            hasher.combine(route.id)
        case .allTechRouteOverview(route: let route, _):
            hasher.combine(route.map { $0.id })
        case .dailyDisplayStop(_, serviceStop: let serviceStop):
            hasher.combine(serviceStop.id)
        case .jobBoard(_, jobBoard: let jobBoard):
            hasher.combine(jobBoard.id)
        case .jobPost(_, jobPost: let jobPost):
            hasher.combine(jobPost.id)
        case .workLogDetail(_, workLog: let workLog):
            hasher.combine(workLog.id)
        case .editRole(_, role: let role):
            hasher.combine(role.id)
        case .taskGroupDetail(_, taskGroup: let taskGroup):
            hasher.combine(taskGroup.id)
        case .bankDetailView(bank: let bank, _):
            hasher.combine(bank.id)
        case .transactionDetailView(transaction: let transaction, _):
            hasher.combine(transaction.id)
        case .shoppingListDetail(item: let item, _):
            hasher.combine(item.id)
        case .purchase(purchasedItem: let purchasedItem, _):
            hasher.combine(purchasedItem.id)
        case .job(job: let job, _):
            hasher.combine(job.id)
        case .editUser(user: let user, _):
            hasher.combine(user.id)
        case .rateSheet(user: let user, _):
            hasher.combine(user.id)
        case .companyUserRateSheet(user: let user, _):
            hasher.combine(user.id)
        case .repairRequest(repairRequest: let repairRequest, _):
            hasher.combine(repairRequest.id)
        case .serviceStop(serviceStop: let serviceStop, _):
            hasher.combine(serviceStop.id)
        case .business(business: let business, _):
            hasher.combine(business.id)
        case .vender(vender: let vender, _):
            hasher.combine(vender.id)
        case .dataBaseItem(dataBaseItem: let dataBaseItem, _):
            hasher.combine(dataBaseItem.id)
        case .contract(contract: let contract, _):
            hasher.combine(contract.id)
        case .genericItem(item: let item, _):
            hasher.combine(item.id)
        case .readingTemplate(tempalte: let tempalte, _):
            hasher.combine(tempalte.id)
        case .dosageTemplate(template: let template, _):
            hasher.combine(template.id)
        case .receipt(receipt: let receipt, _):
            hasher.combine(receipt.id)
        case .companyProfile(company: let company, _):
            hasher.combine(company.id)
        case .companyPublicProfile(company: let company, _):
            hasher.combine(company.id)
        case .equipmentDetailView(equipment: let equipment, _):
            hasher.combine(equipment.id)
        case .vehicalDetailView(vehical: let vehical, _):
            hasher.combine(vehical.id)
        case .accountsPayableDetail(invoice: let invoice, _):
            hasher.combine(invoice.id)
        case .accountsReceivableDetail(invoice: let invoice, _):
            hasher.combine(invoice.id)
        case .companyUserDetailView(user: let user, _):
            hasher.combine(user.id)
        case .recurringLaborContractDetailView(contract: let contract, _):
            hasher.combine(contract.id)
        case .laborContractDetailView(_, contract: let contract):
            hasher.combine(contract.id)
        case .jobTemplate(jobTemplate: let jobTemplate, _):
            hasher.combine(jobTemplate.id)
        case .recurringServiceStopDetail(_, recurringServiceStop: let recurringServiceStop):
            hasher.combine(recurringServiceStop.id)
        case .customerStopDataDetailView(_, customerId: let customerId):
            hasher.combine(customerId)
        case .contractTermsList(_, termsList: let termsList):
            hasher.combine(termsList.first?.id)
        case .createLaborContractInvoice(_, laborContract: let laborContract):
            hasher.combine(laborContract.id)
        case .createRecurringLaborContractInvoice(_, recurringLaborContract: let recurringLaborContract):
            hasher.combine(recurringLaborContract.id)
        case .createBulkInvoice(_, associatedBusiness: let associatedBusiness):
            hasher.combine(associatedBusiness.id)
        case .inviteDetailView(_, invite: let invite):
            hasher.combine(invite.id)
        case .initiateChat(_, userId: let userId):
            hasher.combine(userId)
        case .userRoleDetailView(_ , role: let role):
            hasher.combine(role.id)
        case .termsTemplateDetailView(_, termsTemplate: let template):
            hasher.combine(template.id)
        default:
            break
        }
    }
}

extension Route {
    // A compact identity key used for equality comparisons.
    // It should only include stable identifiers that define navigation identity.
    fileprivate var identityKey: AnyHashable? {
        switch self {
        // No associated identity — equal if kinds match
        case .jobs,
             .operation,
             .finace,
             .managment,
             .dashBoard,
             .lifeCycles,
             .managementTables,
             .customers,
             .toDoDetail,
             .repairRequestList,
             .toDoList,
             .pendingJobs,
             .shoppingList,
             .purchasedItemsList,
             .map,
             .dailyDisplay,
             .calendar,
             .profile,
             .activeRouteOverView,
             .routeBuilder,
             .pnl,
             .companyRouteOverView,
             .internalRouteOverView,
             .externalRouteOverView,
             .reports,
             .fleet,
             .mainDailyDisplayView,
             .employeeMainDailyDisplayView,
             .billingJobs,
             .serviceStops,
             .purchases,
             .receipts,
             .databaseItems,
             .genericItems,
             .venders,
             .users,
             .userRoles,
             .readingsAndDosages,
             .emailConfiguration,
             .marketPlace,
             .jobPosting,
             .feed,
             .chats,
             .equipmentList,
             .routes,
             .settings,
             .userSettings,
             .companySettings,
             .jobTemplates,
             .accountsPayableList,
             .accountsReceivableList,
             .businesses,
             .alerts,
             .companyAlerts,
             .buisnessContracts,
             .contracts,
             .recurringContracts,
             .recurringLaborContracts,
             .sentRecurringLaborContracts,
             .receivedRecurringLaborContracts,
             .laborContracts,
             .sentLaborContracts,
             .receivedLaborContracts,
             .banks,
             .transactions,
             .taskGroups,
             .workLogList,
             .invoices,
             .companyInfo,
             .manageSubscriptions,
             .stripeConfiguration,
             .cart,
             .recentActivity,
             .techInviteList,
             .browseCompanies,
             .createCompanyView,
             .compileInvoice,
             .createNewJob,
             .createRepairRequest,
             .createCustomer,
             .editCompanySubscription,
            .manageTermsTemplates,
            .payRoll,
            .payRollSettings,
            .technicianWorkCenter:
            return nil

        // Cases with identity — return a stable identifier only
        case .chat(let chat, _):
            return AnyHashable(chat.id)
        case .customer(let customer, _):
            return AnyHashable(customer.id)
        case .routeOverview(route: let route, _):
            return AnyHashable(route.id)
        case .allTechRouteOverview(route: let route, _):
            // If this is an array, combine the IDs in a stable way
            let ids = route.map { $0.id }
            return AnyHashable(ids)
        case .dailyDisplayStop(_, let serviceStop):
            return AnyHashable(serviceStop.id)
        case .jobBoard(_, let jobBoard):
            return AnyHashable(jobBoard.id)
        case .jobPost(_, let jobPost):
            return AnyHashable(jobPost.id)
        case .workLogDetail(_, let workLog):
            return AnyHashable(workLog.id)
        case .editRole(_, let role):
            return AnyHashable(role.id)
        case .taskGroupDetail(_, let taskGroup):
            return AnyHashable(taskGroup.id)
        case .bankDetailView(let bank, _):
            return AnyHashable(bank.id)
        case .transactionDetailView(let transaction, _):
            return AnyHashable(transaction.id)
        case .shoppingListDetail(let item, _):
            return AnyHashable(item.id)
        case .purchase(let purchasedItem, _):
            return AnyHashable(purchasedItem.id)
        case .job(let job, _):
            return AnyHashable(job.id)
        case .editUser(let user, _):
            return AnyHashable(user.id)
        case .rateSheet(let user, _):
            return AnyHashable(user.id)
        case .companyUserRateSheet(let user, _):
            return AnyHashable(user.id)
        case .repairRequest(let repairRequest, _):
            return AnyHashable(repairRequest.id)
        case .serviceStop(let serviceStop, _):
            return AnyHashable(serviceStop.id)
        case .business(let business, _):
            return AnyHashable(business.id)
        case .vender(let vender, _):
            return AnyHashable(vender.id)
        case .dataBaseItem(let dataBaseItem, _):
            return AnyHashable(dataBaseItem.id)
        case .contract(let contract, _):
            return AnyHashable(contract.id)
        case .genericItem(let item, _):
            return AnyHashable(item.id)
        case .readingTemplate(let tempalte, _):
            return AnyHashable(tempalte.id)
        case .dosageTemplate(let template, _):
            return AnyHashable(template.id)
        case .receipt(let receipt, _):
            return AnyHashable(receipt.id)
        case .companyProfile(let company, _):
            return AnyHashable(company.id)
        case .companyPublicProfile(let company, _):
            return AnyHashable(company.id)
        case .equipmentDetailView(let equipment, _):
            return AnyHashable(equipment.id)
        case .vehicalDetailView(let vehical, _):
            return AnyHashable(vehical.id)
        case .accountsPayableDetail(let invoice, _):
            return AnyHashable(invoice.id)
        case .accountsReceivableDetail(let invoice, _):
            return AnyHashable(invoice.id)
        case .companyUserDetailView(let user, _):
            return AnyHashable(user.id)
        case .recurringLaborContractDetailView(let contract, _):
            return AnyHashable(contract.id)
        case .laborContractDetailView(_, let contract):
            return AnyHashable(contract.id)
        case .jobTemplate(let jobTemplate, _):
            return AnyHashable(jobTemplate.id)
        case .recurringServiceStopDetail(_, let recurringServiceStop):
            return AnyHashable(recurringServiceStop.id)
        case .customerStopDataDetailView(_, let customerId):
            return AnyHashable(customerId)
        case .contractTermsList(_, let termsList):
            // Use a stable summary key (e.g., first ID) to avoid hashing entire arrays of complex types
            let firstID = termsList.first?.id
            return AnyHashable(firstID ?? "")
        case .createLaborContractInvoice(_, let laborContract):
            return AnyHashable(laborContract.id)
        case .createRecurringLaborContractInvoice(_, let recurringLaborContract):
            return AnyHashable(recurringLaborContract.id)
        case .createBulkInvoice(_, let associatedBusiness):
            return AnyHashable(associatedBusiness.id)
        case .inviteDetailView(_, let invite):
            return AnyHashable(invite.id)
        case .initiateChat(_, let userId):
            return AnyHashable(userId)
        case .userRoleDetailView(dataService: let dataService, role: let role):
            return AnyHashable(role.id)
        case .termsTemplateDetailView(dataService: let dataService, termsTemplate: let template):
            return AnyHashable(template.id)
        }
    }
}

extension Route: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(kindDiscriminator)
        if let key = identityKey { hasher.combine(key) }
    }

    static func == (lhs: Route, rhs: Route) -> Bool {
        // First ensure we are comparing the same case kind
        guard lhs.kindDiscriminator == rhs.kindDiscriminator else { return false }
        // Then ensure identity (if any) matches
        return lhs.identityKey == rhs.identityKey
    }
}
