//
//  CompanyAlertViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import Foundation
import SwiftUI

struct DripDropAlertRelatedEntity: Hashable, Codable {
    var type:String?
    var id:String?
    var label:String?
    var companyId:String?
    var collectionPath:String?
    var webPath:String?
    var deeplinkUrl:String?
}

struct DripDropAlertShare: Hashable, Codable {
    var type:String?
    var id:String?
    var recordId:String?
    var companyId:String?
    var customerId:String?
    var customerUserId:String?
    var title:String?
    var subtitle:String?
    var collectionPath:String?
    var webPath:String?
    var sharePath:String?
    var shareUrl:String?
    var deeplinkUrl:String?
    var mobileRoute:String?
    var audience:String?
}

struct DripDropAlertNotificationSource: Hashable {
    var scope:String
    var id:String
}

struct DripDropAlert:Identifiable,Hashable,Codable{
    var id:String = UUID().uuidString
    var companyId:String? = nil
    var category:MacCategories
    var route:RouteString
    var itemId:String
    var name:String
    var description:String
    var date:Date
    var read:Bool? = nil
    var readAt:Date? = nil
    var archivedAt:Date? = nil
    var scheduledFor:Date? = nil
    var deliveryAt:Date? = nil
    var dueAt:Date? = nil
    var status:String? = nil
    var severity:String? = nil
    var source:String? = nil
    var sourceId:String? = nil
    var chatId:String? = nil
    var targetScope:String? = nil
    var assignedToUserId:String? = nil
    var assignedToName:String? = nil
    var recipientUserId:String? = nil
    var recipientCompanyId:String? = nil
    var routePath:String? = nil
    var relatedEntity:DripDropAlertRelatedEntity? = nil
    var share:DripDropAlertShare? = nil
    var notificationScope:String? = nil
    var notificationSources:[DripDropAlertNotificationSource] = []

    init(
        id:String = UUID().uuidString,
        companyId:String? = nil,
        category:MacCategories,
        route:RouteString,
        itemId:String,
        name:String,
        description:String,
        date:Date,
        read:Bool? = nil,
        readAt:Date? = nil,
        archivedAt:Date? = nil,
        scheduledFor:Date? = nil,
        deliveryAt:Date? = nil,
        dueAt:Date? = nil,
        status:String? = nil,
        severity:String? = nil,
        source:String? = nil,
        sourceId:String? = nil,
        chatId:String? = nil,
        targetScope:String? = nil,
        assignedToUserId:String? = nil,
        assignedToName:String? = nil,
        recipientUserId:String? = nil,
        recipientCompanyId:String? = nil,
        routePath:String? = nil,
        relatedEntity:DripDropAlertRelatedEntity? = nil,
        share:DripDropAlertShare? = nil,
        notificationScope:String? = nil,
        notificationSources:[DripDropAlertNotificationSource] = []
    ) {
        self.id = id
        self.companyId = companyId
        self.category = category
        self.route = route
        self.itemId = itemId
        self.name = name
        self.description = description
        self.date = date
        self.read = read
        self.readAt = readAt
        self.archivedAt = archivedAt
        self.scheduledFor = scheduledFor
        self.deliveryAt = deliveryAt
        self.dueAt = dueAt
        self.status = status
        self.severity = severity
        self.source = source
        self.sourceId = sourceId
        self.chatId = chatId
        self.targetScope = targetScope
        self.assignedToUserId = assignedToUserId
        self.assignedToName = assignedToName
        self.recipientUserId = recipientUserId
        self.recipientCompanyId = recipientCompanyId
        self.routePath = routePath
        self.relatedEntity = relatedEntity
        self.share = share
        self.notificationScope = notificationScope
        self.notificationSources = notificationSources
    }

    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case category
        case route
        case itemId
        case name
        case title
        case description
        case message
        case date
        case createdAt
        case updatedAt
        case read
        case readAt
        case archivedAt
        case scheduledFor
        case deliveryAt
        case dueAt
        case status
        case severity
        case source
        case sourceId
        case chatId
        case targetScope
        case assignedToUserId
        case assignedToName
        case recipientUserId
        case recipientCompanyId
        case routePath
        case relatedEntity
        case share
        case conversationLink
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedShare = (try? container.decodeIfPresent(DripDropAlertShare.self, forKey: .share))
            ?? (try? container.decodeIfPresent(DripDropAlertShare.self, forKey: .conversationLink))
        let decodedRelatedEntity = try? container.decodeIfPresent(DripDropAlertRelatedEntity.self, forKey: .relatedEntity)
        let linkType = decodedShare?.type ?? decodedRelatedEntity?.type
        let routeAndCategory = Self.routeAndCategory(for: linkType, source: try? container.decodeIfPresent(String.self, forKey: .source))
        let rawRoute = try? container.decodeIfPresent(String.self, forKey: .route)
        let decodedRoute = rawRoute.flatMap { RouteString(rawValue: $0) }
        let routePath = rawRoute?.hasPrefix("/") == true ? rawRoute : nil

        self.id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
        self.companyId = try? container.decodeIfPresent(String.self, forKey: .companyId)
        self.category = (try? container.decodeIfPresent(MacCategories.self, forKey: .category)) ?? routeAndCategory.category
        self.route = decodedRoute ?? routeAndCategory.route
        self.itemId =
            (try? container.decodeIfPresent(String.self, forKey: .itemId)) ??
            decodedShare?.recordId ??
            decodedShare?.id ??
            decodedRelatedEntity?.id ??
            (try? container.decodeIfPresent(String.self, forKey: .chatId)) ??
            (try? container.decodeIfPresent(String.self, forKey: .sourceId)) ??
            ""
        let decodedName = (try? container.decodeIfPresent(String.self, forKey: .name))
            ?? (try? container.decodeIfPresent(String.self, forKey: .title))
            ?? decodedShare?.title
            ?? decodedRelatedEntity?.label
            ?? "Notification"
        let decodedDescription = (try? container.decodeIfPresent(String.self, forKey: .description))
            ?? (try? container.decodeIfPresent(String.self, forKey: .message))
            ?? decodedShare?.subtitle
            ?? ""

        self.name = decodedName
        self.description = decodedDescription
        self.date =
            (try? container.decodeIfPresent(Date.self, forKey: .date)) ??
            (try? container.decodeIfPresent(Date.self, forKey: .createdAt)) ??
            (try? container.decodeIfPresent(Date.self, forKey: .updatedAt)) ??
            Date()
        self.read = try? container.decodeIfPresent(Bool.self, forKey: .read)
        self.readAt = try? container.decodeIfPresent(Date.self, forKey: .readAt)
        self.archivedAt = try? container.decodeIfPresent(Date.self, forKey: .archivedAt)
        self.scheduledFor = try? container.decodeIfPresent(Date.self, forKey: .scheduledFor)
        self.deliveryAt = try? container.decodeIfPresent(Date.self, forKey: .deliveryAt)
        self.dueAt = try? container.decodeIfPresent(Date.self, forKey: .dueAt)
        let decodedStatus = try? container.decodeIfPresent(String.self, forKey: .status)
        self.status = decodedStatus ?? (self.read == true ? "read" : nil)
        self.severity = try? container.decodeIfPresent(String.self, forKey: .severity)
        self.source = try? container.decodeIfPresent(String.self, forKey: .source)
        self.sourceId = try? container.decodeIfPresent(String.self, forKey: .sourceId)
        self.chatId = try? container.decodeIfPresent(String.self, forKey: .chatId)
        self.targetScope = try? container.decodeIfPresent(String.self, forKey: .targetScope)
        self.assignedToUserId = try? container.decodeIfPresent(String.self, forKey: .assignedToUserId)
        self.assignedToName = try? container.decodeIfPresent(String.self, forKey: .assignedToName)
        self.recipientUserId = try? container.decodeIfPresent(String.self, forKey: .recipientUserId)
        self.recipientCompanyId = try? container.decodeIfPresent(String.self, forKey: .recipientCompanyId)
        self.routePath = routePath
        self.relatedEntity = decodedRelatedEntity
        self.share = decodedShare
        self.notificationScope = nil
        self.notificationSources = []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(companyId, forKey: .companyId)
        try container.encode(category, forKey: .category)
        try container.encode(route, forKey: .route)
        try container.encode(itemId, forKey: .itemId)
        try container.encode(name, forKey: .name)
        try container.encode(name, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(description, forKey: .message)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(read, forKey: .read)
        try container.encodeIfPresent(readAt, forKey: .readAt)
        try container.encodeIfPresent(archivedAt, forKey: .archivedAt)
        try container.encodeIfPresent(scheduledFor, forKey: .scheduledFor)
        try container.encodeIfPresent(deliveryAt, forKey: .deliveryAt)
        try container.encodeIfPresent(dueAt, forKey: .dueAt)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(severity, forKey: .severity)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(sourceId, forKey: .sourceId)
        try container.encodeIfPresent(chatId, forKey: .chatId)
        try container.encodeIfPresent(targetScope, forKey: .targetScope)
        try container.encodeIfPresent(assignedToUserId, forKey: .assignedToUserId)
        try container.encodeIfPresent(assignedToName, forKey: .assignedToName)
        try container.encodeIfPresent(recipientUserId, forKey: .recipientUserId)
        try container.encodeIfPresent(recipientCompanyId, forKey: .recipientCompanyId)
        try container.encodeIfPresent(routePath, forKey: .routePath)
        try container.encodeIfPresent(relatedEntity, forKey: .relatedEntity)
        try container.encodeIfPresent(share, forKey: .share)
    }

    private static func routeAndCategory(for type:String?, source:String?) -> (route:RouteString, category:MacCategories) {
        if type == "chat" || source == "chat" {
            return (.chat, .chat)
        }

        switch ConversationLinkType.normalized(type ?? "") {
        case .customer:
            return (.customer, .customers)
        case .serviceLocation, .bodyOfWater:
            return (.customers, .customers)
        case .equipment:
            return (.equipmentDetailView, .equipment)
        case .repairRequest:
            return (.repairRequest, .repairRequest)
        case .serviceRequest:
            return (.leads, .alerts)
        case .serviceStop, .recurringServiceStop:
            return (.serviceStop, .serviceStops)
        case .estimate, .serviceAgreement, .contract:
            return (.contract, .contracts)
        case .invoice:
            return (.accountsReceivableDetail, .accountsReceivable)
        case .job:
            return (.job, .jobs)
        case .purchase:
            return (.purchase, .purchases)
        case .shoppingListItem, .todo:
            return (.shoppingListDetail, .shoppingList)
        case .databaseItem:
            return (.dataBaseItem, .databaseItems)
        case .receipt:
            return (.receipt, .receipts)
        case .vendor:
            return (.vender, .vender)
        case .companyUser:
            return (.companyUserDetailView, .companyUser)
        case .other:
            return (.alerts, .alerts)
        }
    }
}

extension DripDropAlert {
    var displayTitle:String {
        firstNonEmpty(name, share?.title, relatedEntity?.label, "Notification")
    }

    var displayDescription:String {
        firstNonEmpty(description, share?.subtitle)
    }

    var displayCategoryTitle:String {
        let type = firstNonEmpty(relatedEntity?.type, share?.type)
        if !type.isEmpty {
            return ConversationLinkType.normalized(type).displayName
        }

        return category.title()
    }

    var displayStatusTitle:String {
        switch normalizedStatus {
        case "archived":
            return "Dismissed"
        case "read":
            return "Read"
        case "scheduled":
            return "Scheduled"
        default:
            return isScheduled ? "Scheduled" : "Unread"
        }
    }

    var displaySeverityTitle:String {
        switch normalizedSeverity {
        case "critical":
            return "Critical"
        case "warning":
            return "Warning"
        case "success":
            return "Success"
        default:
            return "Info"
        }
    }

    var isArchived:Bool {
        normalizedStatus == "archived"
    }

    var isUnread:Bool {
        !isArchived && (
            normalizedStatus == "unread" ||
            read == false ||
            (status ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && readAt == nil
        )
    }

    var isScheduled:Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return !isArchived && scheduledDate > Date()
    }

    var needsAttention:Bool {
        !isArchived && isUnread && !isScheduled
    }

    var scheduledDate:Date? {
        scheduledFor ?? deliveryAt ?? dueAt
    }

    var notificationSourceList:[DripDropAlertNotificationSource] {
        if !notificationSources.isEmpty {
            return notificationSources
        }

        return [
            DripDropAlertNotificationSource(
                scope: notificationScope ?? "company",
                id: id
            )
        ]
    }

    var mergeKey:String {
        let cleanSourceId = firstNonEmpty(sourceId)
        if !cleanSourceId.isEmpty {
            return "\(firstNonEmpty(source, "source")):\(cleanSourceId)"
        }

        let sharedRecordId = firstNonEmpty(share?.recordId, share?.id, relatedEntity?.id)
        let cleanChatId = firstNonEmpty(chatId)
        if !cleanChatId.isEmpty && !sharedRecordId.isEmpty {
            return "chat:\(cleanChatId):\(sharedRecordId)"
        }

        return "\(notificationScope ?? "alert"):\(id)"
    }

    func taggedForNotificationSource(scope:String) -> DripDropAlert {
        var copy = self
        copy.notificationScope = scope
        copy.notificationSources = [
            DripDropAlertNotificationSource(scope: scope, id: id)
        ]
        return copy
    }

    func belongsToCompany(_ companyId:String) -> Bool {
        let cleanCompanyId = companyId.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanCompanyId.isEmpty {
            return true
        }

        return [
            self.companyId,
            recipientCompanyId,
            relatedEntity?.companyId,
            share?.companyId
        ].contains { value in
            value?.trimmingCharacters(in: .whitespacesAndNewlines) == cleanCompanyId
        }
    }

    func isVisible(toUserId userId:String) -> Bool {
        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanUserId.isEmpty {
            return true
        }

        let directRecipientIds = [
            recipientUserId,
            assignedToUserId
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if directRecipientIds.contains(cleanUserId) {
            return true
        }

        if notificationScope == "personal" {
            return true
        }

        let cleanTargetScope = firstNonEmpty(targetScope).lowercased()
        if cleanTargetScope == "specific" {
            return false
        }

        return directRecipientIds.isEmpty
    }

    static func mergeForDisplay(_ alerts:[DripDropAlert]) -> [DripDropAlert] {
        var merged:[String:DripDropAlert] = [:]

        for alert in alerts {
            let key = alert.mergeKey
            guard var existing = merged[key] else {
                merged[key] = alert
                continue
            }

            var sources = existing.notificationSourceList
            for source in alert.notificationSourceList where !sources.contains(source) {
                sources.append(source)
            }

            if existing.isArchived && !alert.isArchived {
                existing = alert
            } else if existing.isScheduled && alert.needsAttention {
                existing = alert
            } else if !existing.isUnread && alert.isUnread {
                existing = alert
            }

            existing.notificationSources = sources
            merged[key] = existing
        }

        return Array(merged.values)
    }

    private var normalizedStatus:String {
        firstNonEmpty(status, read == true ? "read" : "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private var normalizedSeverity:String {
        firstNonEmpty(severity, "info")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func firstNonEmpty(_ values:String?...) -> String {
        for value in values {
            let cleanValue = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanValue.isEmpty {
                return cleanValue
            }
        }

        return ""
    }
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

    @Published private(set) var contract:RecurringContract? = nil
    @Published private(set) var chat:Chat? = nil
    @Published private(set) var companyUser:CompanyUser? = nil

    @Published private(set) var dataBaseItem:DataBaseItem? = nil
    
    @Published private(set) var equipment:Equipment? = nil

    @Published private(set) var genericItem:GenericItem? = nil
    
    @Published private(set) var job:Job? = nil
    @Published private(set) var jobTemplate:JobTemplate? = nil
    
    @Published private(set) var laborContract:ReccuringLaborContract? = nil

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
    func getAlertsByCompany(companyId:String, userId:String? = nil) async throws {
        let companyAlertRecords = try await dataService.getDripDropAlerts(companyId: companyId)
        let companyAlerts = companyAlertRecords.map { $0.taggedForNotificationSource(scope: "company") }
        let cleanUserId = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let personalAlerts:[DripDropAlert]

        if cleanUserId.isEmpty {
            personalAlerts = []
        } else {
            let personalAlertRecords = try await dataService.getPersonalAlerts(userId: cleanUserId)
            personalAlerts = personalAlertRecords.map { $0.taggedForNotificationSource(scope: "personal") }
        }

        self.alertList = DripDropAlert.mergeForDisplay(personalAlerts + companyAlerts)
            .filter { $0.belongsToCompany(companyId) }
            .filter { $0.isVisible(toUserId: cleanUserId) }
            .sorted { $0.date > $1.date }
    }
    func createAlert(companyId:String,alert:DripDropAlert) async throws {
        try await dataService.addDripDropAlert(companyId: companyId, dripDropAlert: alert)
    }
    func markAlertAsRead(companyId:String, userId:String?, alert:DripDropAlert) async throws {
        try await updateAlertStatus(companyId: companyId, userId: userId, alert: alert, status: "read")
    }
    func dismissAlert(companyId:String, userId:String?, alert:DripDropAlert) async throws {
        try await updateAlertStatus(companyId: companyId, userId: userId, alert: alert, status: "archived")
    }
    func dismissAlerts(companyId:String, userId:String?, alerts:[DripDropAlert]) async throws {
        for alert in alerts {
            try await dismissAlert(companyId: companyId, userId: userId, alert: alert)
        }
    }
    private func updateAlertStatus(companyId:String, userId:String?, alert:DripDropAlert, status:String) async throws {
        let cleanUserId = (userId ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        for source in alert.notificationSourceList {
            if source.scope == "personal" {
                guard !cleanUserId.isEmpty else { continue }
                try await dataService.updatePersonalAlertStatus(userId: cleanUserId, alertId: source.id, status: status)
            } else {
                try await dataService.updateDripDropAlertStatus(companyId: companyId, alertId: source.id, status: status)
            }
        }

        alertList = alertList.compactMap { currentAlert in
            guard currentAlert.mergeKey == alert.mergeKey else {
                return currentAlert
            }

            if status == "archived" {
                return nil
            }

            var updatedAlert = currentAlert
            updatedAlert.status = status
            updatedAlert.read = status == "read"
            updatedAlert.readAt = status == "read" ? Date() : nil
            updatedAlert.archivedAt = status == "archived" ? Date() : nil
            return updatedAlert
        }
    }
    func getAlertDestination(companyId:String,alert:DripDropAlert)async throws{
        self.isLoading = true
        
        self.category = alert.category

        if alert.itemId != "" {
            if UIDevice.isIPhone {
                if alert.route.hasItem() {
                    switch alert.route {
                    case .operation, .finace, .managment , .dashBoard, .customers, .toDoDetail, .repairRequestList, .toDoList, .pendingJobs, .shoppingList, .purchasedItemsList, .map, .dailyDisplay, .calendar, .profile, .routeBuilder, .pnl, .companyRouteOverView, .reports, .fleet, .mainDailyDisplayView, .serviceStops, .jobs, .leads, .sales, .contracts, .purchases, .receipts, .databaseItems, .genericItems, .venders, .users, .userRoles, .readingsAndDosages, .marketPlace, .jobPosing, .feed, .chats, .equipmentList, .routes, .settings, .userSettings, .companySettings, .jobTemplates, .accountsPayableList, .accountsReceivableList, .businesses, .alerts, .cart, .recentActivity, .laborContracts, .companyAlerts, .externalRouteOverView, .activeRouteOverView, .managementTables:
                        print("No Item To Get")
                        
                    case .editUser:
                        print("Update Edit User")
#warning("[Update 2.5] Update Edit User")

                    case .rateSheet:
                        print("Update Rate Sheet")
#warning("[Update 2.5] Update Rate Sheet")
                        
                    case .companyUserRateSheet:
                        print("Update Rate Sheet")
#warning("[Update 2.5] Update Rate Sheet")
                        
                    case .compileInvoice:
                        print("No Item for compileInvoice")
                        
                    case .createNewJob:
                        print("No Item for createNewJob")
                        
                    case .createRepairRequest:
                        print("No Item for createRepairRequest")
                        
                    case .createCustomer:
                        print("No Item for createCustomer")
                        
                    case .equipmentDetailView:
                        let item = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: alert.itemId)
                        self.route = Route.equipmentDetailView(equipment: item, dataService: dataService)
                    case .allTechRouteOverview:
#warning("[Update 2.5] Needs more Help")
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
                        self.route = Route.recurringLaborContractDetailView(contract: item, dataService: dataService)
               
                    case .banks:
                        print("No Item To Get")

                    case .transactions:
                        print("No Item To Get")

                    case .bankDetailView:
                        print(" Build out")
#warning("[Update 2.5] Build out")

                    case .transactionDetailView:
                        print(" Build out")
#warning("Update 2.5 Build out")

                    case .emailConfiguration:
                        print(" Please Build out")
#warning("Update 2.5 Build out")
                    case .employeeMainDailyDisplayView:
                        print(" Please Build out")
#warning("Update 2.5 Build out")

                    case .companyShoppingList:
                        
        #warning("Update 2.5   please build out")
                    }
                }
            } else {
                switch alert.category {
                case .sentLaborContracts:
                    print("")
#warning("Update 2.5 Build out")
                case .managementTables:
                    print("Management Tables")
                case .profile:
                    print("reports Not Built Out Yet")
                case .dashBoard:
                    print("dashBoard Does Not Need Item")
                case .dailyDisplay:
                    print("dailyDisplay Does Not Need Item")
                case .routeBuilder:
                    print("routeBuilder Need more complex Logic")
                case .management:
                    print(" Make function for getting management by Id")
                    
#warning("Update 2.5 Make function for getting management by Id")
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
                case .receivedLaborContracts:
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
                    
                case .taskGroups:
                    print(" FIX")
#warning("Update 2.5 FIX")
                case .emailConfirguration:
                    print(" FIX")
#warning("Update 2.5 FIX")
                case .companyInfo:
                    print(" FIX")
#warning("Update 2.5 FIX")
                case .manageSubscriptions:
                    print(" FIX")
#warning("Update 2.5 FIX")
                case .stripeConfiguration:
                    print(" FIX")
#warning("Update 2.5 FIX")
                }
            }
        } else {
            print("No Item Id")
                switch alert.route {
                case .cart:
                    print("Has Item")
                    
                case .editUser:
                    print("Update Edit User")
    #warning("Update 2.5  Update Edit User")
                    
                case .rateSheet:
                    print("Update Rate Sheet")
#warning("Update 2.5  Update Rate Sheet")
                    
                case .companyUserRateSheet:
                    print("Update Rate Sheet")
#warning("Update 2.5   Update Rate Sheet")
                    
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
                case .leads:
                     self.route = Route.leads(dataService: dataService)
                case .sales:
                     self.route = Route.sales(dataService: dataService)
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
                    print("Fix")
//                    self.route = Route.equipmentDetailView(equipment: Equipment, dataService: dataService)
                case .laborContracts:
                    self.route = Route.laborContracts(dataService: dataService)
                    //All the Below are detil with Higher
                case .shoppingListDetail,.purchase,.job,.chat,.repairRequest,.customer,.serviceStop,.business,.vender,.dataBaseItem,.contract,.genericItem,.readingTemplate,.dosageTemplate,.receipt,.companyProfile,.vehicalDetailView,.accountsPayableDetail,.accountsReceivableDetail,.laborContractDetailView, .companyUserDetailView, .jobTemplate, .routeOverview, .allTechRouteOverview, .dailyDisplayStop, .bankDetailView, .transactionDetailView, .managementTables:
                    print("Detalt With Higher Above")
                case .companyAlerts:
                    self.route = Route.companyAlerts(dataService: dataService)

                case .externalRouteOverView:
                    self.route = Route.externalRouteOverView(dataService: dataService)
                case .banks:
                    print(" please build out")
                    
    #warning("Update 2.5   please build out")
                case .transactions:
                    print(" please build out")
                    
    #warning("Update 2.5   please build out")
                case .activeRouteOverView:
                    print(" please build out")
                    
    #warning("Update 2.5   please build out")
                case .emailConfiguration:
                    print(" please build out")
                    
    #warning("Update 2.5   please build out")
                    
                case .employeeMainDailyDisplayView:
                    print(" please build out")
                    
    #warning("Update 2.5   please build out")
                case .companyShoppingList:
                    
    #warning("Update 2.5   please build out")
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
                    case .operation, .finace, .managment , .dashBoard, .customers, .toDoDetail, .repairRequestList, .toDoList, .pendingJobs, .shoppingList, .purchasedItemsList, .map, .dailyDisplay, .calendar, .profile, .routeBuilder, .pnl, .companyRouteOverView, .reports, .fleet, .mainDailyDisplayView, .serviceStops, .jobs, .leads, .sales, .contracts, .purchases, .receipts, .databaseItems, .genericItems, .venders, .users, .userRoles, .readingsAndDosages, .marketPlace, .jobPosing, .feed, .chats, .equipmentList, .routes, .settings, .userSettings, .companySettings, .jobTemplates, .accountsPayableList, .accountsReceivableList, .businesses, .alerts, .cart, .recentActivity, .laborContracts, .companyAlerts, .externalRouteOverView, .banks, .transactions, .activeRouteOverView, .managementTables:
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
                        print(" please build out")
                        
        #warning("Update 2.5   please build out")
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
                        self.route = Route.recurringLaborContractDetailView(contract: item, dataService: dataService)
               
                        
                    case .bankDetailView:
                        print(" please build out")
                        
        #warning("Update 2.5   please build out")
                    case .transactionDetailView:
                        print(" please build out")
                        
        #warning("Update 2.5   please build out")
                    case .emailConfiguration:
                        print(" please build out")
                        
        #warning("Update 2.5   please build out")
                    case .employeeMainDailyDisplayView:
                        print(" please build out")
                        
        #warning("Update 2.5   please build out")
                    case .companyShoppingList:
                        
        #warning("Update 2.5   please build out")
                    }
                }
            } else {
                switch recentActivity.category {
                case .sentLaborContracts:
                    print(".managementTables")
                case .managementTables:
                    print(".managementTables")
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
                case .receivedLaborContracts:
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
                case .taskGroups:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .emailConfirguration:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .companyInfo:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                case .manageSubscriptions:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .stripeConfiguration:
                    print(" please build out")
    #warning("Update 2.5   please build out")
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
                case .leads:
                     self.route = Route.leads(dataService: dataService)
                case .sales:
                     self.route = Route.sales(dataService: dataService)
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
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
//                    self.route = Route.equipmentDetailView(dataService: dataService)
                case .laborContracts:
                    self.route = Route.laborContracts(dataService: dataService)
                case .companyAlerts:
                    self.route = Route.companyAlerts(dataService: dataService)
                    //All the Below are detil with Higher
                case .shoppingListDetail,.purchase,.job,.chat,.repairRequest,.customer,.serviceStop,.business,.vender,.dataBaseItem,.contract,.genericItem,.readingTemplate,.dosageTemplate,.receipt,.companyProfile,.vehicalDetailView,.accountsPayableDetail,.accountsReceivableDetail,.laborContractDetailView, .companyUserDetailView, .jobTemplate, .routeOverview, .allTechRouteOverview, .dailyDisplayStop, .bankDetailView, .transactionDetailView, .managementTables:
                    print("Detalt With Higher Above")
  
                case .externalRouteOverView:
                    self.route = Route.externalRouteOverView(dataService: dataService)
                case .banks:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .transactions:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .activeRouteOverView:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .emailConfiguration:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .employeeMainDailyDisplayView:
                    print(" please build out")
    #warning("Update 2.5   please build out")
                    
                case .companyShoppingList:
                    
    #warning("Update 2.5   please build out")
                }
            
        }
        self.isLoading = false
    }

}
