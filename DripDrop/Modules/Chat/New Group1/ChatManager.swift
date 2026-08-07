//
//  ChatManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin
struct BasicUserInfo: Identifiable,Codable, Equatable {
    var id: String
    var userId:String
    var userName:String
    var userImage:String
    var companyId:String? = nil
    var companyName:String? = nil
    var roleName:String? = nil
}

enum ChatVisibility: String, Codable, Hashable {
    case direct
    case company
    case customer
    case companyToCompany
    case companyInternal
    case companyExternal
}

enum ConversationLinkType: String, Codable, Hashable, CaseIterable {
    case customer
    case serviceLocation
    case bodyOfWater
    case repairRequest
    case serviceRequest
    case serviceStop
    case recurringServiceStop
    case estimate
    case serviceAgreement
    case invoice
    case contract
    case job
    case equipment
    case purchase
    case shoppingListItem
    case databaseItem
    case receipt
    case vendor
    case companyUser
    case todo
    case other

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self.normalized(rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func normalized(_ rawValue:String) -> ConversationLinkType {
        switch rawValue {
        case "purchasedItem", "purchasedItems", "purchaseItem":
            return .purchase
        case "dataBaseItem", "databaseItems", "dbItem":
            return .databaseItem
        case "shoppingItem", "shoppingList":
            return .shoppingListItem
        case "bodyOfWaterDetail":
            return .bodyOfWater
        case "company_user":
            return .companyUser
        default:
            return ConversationLinkType(rawValue: rawValue) ?? .other
        }
    }

    var displayName: String {
        switch self {
        case .customer: return "Customer"
        case .serviceLocation: return "Service Location"
        case .bodyOfWater: return "Body of Water"
        case .repairRequest: return "Repair Request"
        case .serviceRequest: return "Service Request"
        case .serviceStop: return "Service Stop"
        case .recurringServiceStop: return "Recurring Stop"
        case .estimate: return "Estimate"
        case .serviceAgreement: return "Service Agreement"
        case .invoice: return "Invoice"
        case .contract: return "Contract"
        case .job: return "Job"
        case .equipment: return "Equipment"
        case .purchase: return "Purchase"
        case .shoppingListItem: return "Shopping Item"
        case .databaseItem: return "Database Item"
        case .receipt: return "Receipt"
        case .vendor: return "Vendor"
        case .companyUser: return "Company User"
        case .todo: return "Todo"
        case .other: return "Link"
        }
    }

    var systemImage: String {
        switch self {
        case .customer: return "person.crop.circle"
        case .serviceLocation: return "mappin.and.ellipse"
        case .bodyOfWater: return "drop"
        case .repairRequest: return "wrench.and.screwdriver"
        case .serviceRequest: return "tray.and.arrow.down"
        case .serviceStop: return "checklist"
        case .recurringServiceStop: return "repeat"
        case .estimate: return "doc.text.magnifyingglass"
        case .serviceAgreement: return "signature"
        case .invoice: return "doc.richtext"
        case .contract: return "doc.badge.gearshape"
        case .job: return "hammer"
        case .equipment: return "wrench.adjustable"
        case .purchase: return "cart"
        case .shoppingListItem: return "list.bullet.clipboard"
        case .databaseItem: return "archivebox"
        case .receipt: return "receipt"
        case .vendor: return "building.2"
        case .companyUser: return "person.2"
        case .todo: return "checkmark.circle"
        case .other: return "link"
        }
    }

    var mobileRouteString: String? {
        switch self {
        case .customer: return RouteString.customer.rawValue
        case .serviceLocation, .bodyOfWater: return RouteString.customers.rawValue
        case .equipment: return RouteString.equipmentDetailView.rawValue
        case .repairRequest: return RouteString.repairRequest.rawValue
        case .serviceRequest: return RouteString.leads.rawValue
        case .serviceStop: return RouteString.serviceStop.rawValue
        case .recurringServiceStop: return RouteString.serviceStops.rawValue
        case .estimate, .serviceAgreement, .contract: return RouteString.contract.rawValue
        case .invoice: return RouteString.accountsReceivableDetail.rawValue
        case .job: return RouteString.job.rawValue
        case .purchase: return RouteString.purchase.rawValue
        case .shoppingListItem: return RouteString.shoppingListDetail.rawValue
        case .databaseItem: return RouteString.dataBaseItem.rawValue
        case .receipt: return RouteString.receipt.rawValue
        case .vendor: return RouteString.vender.rawValue
        case .companyUser: return RouteString.companyUserDetailView.rawValue
        case .todo: return RouteString.toDoList.rawValue
        case .other: return nil
        }
    }

    var alertCategory: MacCategories {
        switch self {
        case .customer, .serviceLocation, .bodyOfWater:
            return .customers
        case .equipment:
            return .equipment
        case .repairRequest:
            return .repairRequest
        case .serviceRequest:
            return .alerts
        case .serviceStop, .recurringServiceStop:
            return .serviceStops
        case .estimate, .serviceAgreement, .contract:
            return .contracts
        case .invoice:
            return .accountsReceivable
        case .job:
            return .jobs
        case .purchase:
            return .purchases
        case .shoppingListItem, .todo:
            return .shoppingList
        case .databaseItem:
            return .databaseItems
        case .receipt:
            return .receipts
        case .vendor:
            return .vender
        case .companyUser:
            return .companyUser
        case .other:
            return .alerts
        }
    }
}

struct ConversationLink: Identifiable, Codable, Hashable {
    var id:String
    var type:ConversationLinkType
    var recordId:String
    var title:String
    var subtitle:String? = nil
    var companyId:String? = nil
    var customerId:String? = nil
    var serviceLocationId:String? = nil
    var status:String? = nil
    var amountLabel:String? = nil
    var routeString:String? = nil
    var customerUserId:String? = nil
    var collectionPath:String? = nil
    var webPath:String? = nil
    var companyWebPath:String? = nil
    var clientWebPath:String? = nil
    var mobileRoute:String? = nil
    var deeplinkUrl:String? = nil
    var sharePath:String? = nil
    var shareUrl:String? = nil
    var audience:String? = nil

    var resolvedMobileRoute:String? {
        mobileRoute ?? routeString ?? type.mobileRouteString
    }
}

enum ChatMessageKind: String, Codable, Hashable {
    case text
    case linkedRecord
    case systemNote
}

struct Chat:Identifiable, Codable, Equatable{
    var id:String
    var participantIds:[String]
    var participants:[BasicUserInfo]
    var companyId:String?
    var mostRecentChat:Date
    var userWhoHaveNotRead:[String]
    var lastMessage:String
    var visibility:ChatVisibility? = .direct
    var participantCompanyIds:[String]? = nil
    var companyIdsWhoHaveNotRead:[String]? = nil
    var readByUserIds:[String]? = nil
    var title:String? = nil
    var customerId:String? = nil
    var serviceLocationId:String? = nil
    var contextLinks:[ConversationLink]? = nil
    var companyName:String? = nil
    var senderCompanyId:String? = nil
    var receiverCompanyId:String? = nil
    var customerUserId:String? = nil
    var customerName:String? = nil
    var audience:String? = nil
    var targetType:String? = nil
    var companyVisibility:String? = nil
    var publicToCompanyId:String? = nil
    var lastMessageKind:ChatMessageKind? = nil
    var lastConversationLink:ConversationLink? = nil

    func displayTitle(currentUserId:String?) -> String {
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }

        let visibleParticipants = participants.filter { participant in
            guard let currentUserId else { return true }
            return participant.userId != currentUserId
        }

        if !visibleParticipants.isEmpty {
            return visibleParticipants.map(\.userName).joined(separator: ", ")
        }

        if visibility == .company {
            return "Company Conversation"
        }

        return participants.first?.userName ?? "Conversation"
    }

    func isVisibleTo(userId:String, companyId:String?) -> Bool {
        if participantIds.contains(userId) {
            return true
        }

        guard let companyId else { return false }
        return participantCompanyIds?.contains(companyId) == true || self.companyId == companyId
    }

    func isUnread(for userId:String, companyId:String?) -> Bool {
        if userWhoHaveNotRead.contains(userId) {
            return true
        }

        guard
            let companyId,
            companyIdsWhoHaveNotRead?.contains(companyId) == true
        else {
            return false
        }

        return readByUserIds?.contains(userId) != true
    }

    var audienceKind:String {
        if audience == "internal" || targetType == "companyUser" || visibility == .companyInternal {
            return "internal"
        }

        return "external"
    }

    func unreadTargets(senderId:String, senderCompanyId:String?) -> (userIds:[String], companyIds:[String]) {
        let normalizedSenderCompanyId = senderCompanyId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let participantByUserId = participants.reduce(into: [String:BasicUserInfo]()) { result, participant in
            result[participant.userId] = participant
        }
        let internalChat = audienceKind == "internal"
        let userIds = participantIds.filter { participantId in
            guard !participantId.isEmpty, participantId != senderId else { return false }
            if internalChat { return true }
            guard !normalizedSenderCompanyId.isEmpty else { return true }
            return participantByUserId[participantId]?.companyId != normalizedSenderCompanyId
        }
        let companyIds: [String]

        if internalChat {
            companyIds = []
        } else if let participantCompanyIds {
            companyIds = participantCompanyIds.filter { !$0.isEmpty && $0 != normalizedSenderCompanyId }
        } else if let companyId, companyId != normalizedSenderCompanyId {
            companyIds = [companyId]
        } else {
            companyIds = []
        }

        return (Array(Set(userIds)), Array(Set(companyIds)))
    }
}
struct Message:Identifiable, Codable,Hashable{
    var id:String
    var senderName:String
    var senderId:String
    var message:String
    var read:Bool
    var dateSent:Date
    var chatId:String
    var kind:ChatMessageKind? = .text
    var senderCompanyId:String? = nil
    var senderCompanyName:String? = nil
    var attachments:[ConversationLink]? = nil
    var conversationLink:ConversationLink? = nil
    var actionTitle:String? = nil
    var receiverId:String? = nil
    var receiverCompanyId:String? = nil

    var previewText:String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            return trimmedMessage
        }

        if let attachment = messageLinks.first {
            return "\(attachment.type.displayName): \(attachment.title)"
        }

        return kind == .systemNote ? "System update" : "Message"
    }

    var messageLinks:[ConversationLink] {
        var linksByKey:[String:ConversationLink] = [:]
        if let conversationLink {
            linksByKey["\(conversationLink.type.rawValue):\(conversationLink.recordId)"] = conversationLink
        }
        for attachment in attachments ?? [] {
            linksByKey["\(attachment.type.rawValue):\(attachment.recordId)"] = attachment
        }
        return Array(linksByKey.values)
    }
}

extension ConversationLink {
    func queryItems(companyId fallbackCompanyId:String?, audience fallbackAudience:String?, chatId:String?) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "id", value: recordId)
        ]

        if let companyId = companyId ?? fallbackCompanyId, !companyId.isEmpty {
            items.append(URLQueryItem(name: "companyId", value: companyId))
        }
        if let customerId, !customerId.isEmpty {
            items.append(URLQueryItem(name: "customerId", value: customerId))
        }
        if let customerUserId, !customerUserId.isEmpty {
            items.append(URLQueryItem(name: "customerUserId", value: customerUserId))
        }
        if let audience = audience ?? fallbackAudience, !audience.isEmpty {
            items.append(URLQueryItem(name: "audience", value: audience))
        }
        if let chatId, !chatId.isEmpty {
            items.append(URLQueryItem(name: "chatId", value: chatId))
        }

        return items
    }

    func appURLString(companyId fallbackCompanyId:String?, audience fallbackAudience:String?, chatId:String?) -> String {
        var components = URLComponents()
        components.scheme = "dripdrop"
        components.host = "share"
        components.queryItems = queryItems(companyId: fallbackCompanyId, audience: fallbackAudience, chatId: chatId)
        return components.url?.absoluteString ?? "dripdrop://share"
    }

    func resolvedSharePath(companyId fallbackCompanyId:String?, audience fallbackAudience:String?, chatId:String?) -> String {
        var components = URLComponents()
        components.path = "/share"
        components.queryItems = queryItems(companyId: fallbackCompanyId, audience: fallbackAudience, chatId: chatId)
        return components.string ?? "/share"
    }

    func resolvedWebPath(for audience:String) -> String {
        if audience == "client", let clientWebPath, !clientWebPath.isEmpty {
            return clientWebPath
        }
        if audience != "client", let companyWebPath, !companyWebPath.isEmpty {
            return companyWebPath
        }
        if let webPath, !webPath.isEmpty {
            let isCompanyPath = webPath.hasPrefix("/company") || webPath.contains("/company/")
            let isClientPath = webPath.hasPrefix("/client") || webPath.contains("/client/")
            if audience == "client", !isCompanyPath { return webPath }
            if audience != "client", !isClientPath { return webPath }
        }

        let encodedId = recordId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? recordId
        if audience == "client" {
            switch type {
            case .serviceRequest:
                return "/client/service-requests/\(encodedId)"
            case .repairRequest:
                return "/client/repair-requests/\(encodedId)"
            case .serviceStop:
                return "/serviceStop/detail/\(encodedId)"
            case .serviceAgreement, .estimate, .contract:
                return "/client/service-agreements/\(encodedId)"
            case .invoice:
                return "/client/billing/invoices/\(encodedId)"
            case .equipment:
                return "/client/equipment/\(encodedId)"
            case .bodyOfWater:
                return "/client/pools-spas/\(encodedId)"
            case .serviceLocation:
                return "/client/my-pool"
            default:
                return ""
            }
        }

        switch type {
        case .serviceRequest:
            return "/company/leads/\(encodedId)"
        case .repairRequest:
            return "/company/repair-requests/detail/\(encodedId)"
        case .serviceStop:
            return "/company/serviceStops/detail/\(encodedId)"
        case .recurringServiceStop:
            return "/company/recurringServiceStop/details/\(encodedId)"
        case .estimate:
            return "/company/leads/\(encodedId)"
        case .serviceAgreement, .contract:
            return "/company/sales/agreements/\(encodedId)"
        case .invoice:
            return "/company/sales/invoices/\(encodedId)"
        case .job:
            return "/company/jobs/detail/\(encodedId)"
        case .customer:
            return "/company/customers/details/\(encodedId)"
        case .serviceLocation:
            return "/company/serviceLocations/detail/\(encodedId)"
        case .bodyOfWater:
            return "/company/bodiesOfWater/detail/\(encodedId)"
        case .equipment:
            return "/company/equipment/detail/\(encodedId)"
        case .purchase:
            return "/company/purchased-items/detail/\(encodedId)"
        case .receipt:
            return "/company/receipts/detail/\(encodedId)"
        case .shoppingListItem:
            return "/company/shopping-list/detail/\(encodedId)"
        case .databaseItem:
            return "/company/items/detail/\(encodedId)"
        case .vendor:
            return "/company/vendors/detail/\(encodedId)"
        case .companyUser:
            return "/company/companyUsers/\(encodedId)/general"
        case .todo:
            return "/company/todo-list?todoId=\(encodedId)"
        case .other:
            return ""
        }
    }

    func enriched(companyId fallbackCompanyId:String?, audience fallbackAudience:String?, chatId:String?) -> ConversationLink {
        var copy = self
        let resolvedCompanyId = copy.companyId ?? fallbackCompanyId
        let resolvedAudience = copy.audience ?? fallbackAudience
        copy.companyId = resolvedCompanyId
        copy.audience = resolvedAudience
        copy.mobileRoute = copy.mobileRoute ?? copy.resolvedMobileRoute
        copy.webPath = copy.webPath ?? copy.resolvedWebPath(for: resolvedAudience ?? "company")
        copy.sharePath = copy.sharePath ?? copy.resolvedSharePath(companyId: resolvedCompanyId, audience: resolvedAudience, chatId: chatId)
        copy.deeplinkUrl = copy.deeplinkUrl ?? copy.appURLString(companyId: resolvedCompanyId, audience: resolvedAudience, chatId: chatId)
        return copy
    }

    func relatedEntityDictionary(companyId fallbackCompanyId:String?, audience:String, chatId:String?) -> [String:Any] {
        let resolvedCompanyId = companyId ?? fallbackCompanyId ?? ""
        return [
            "type": type.rawValue,
            "id": recordId,
            "label": title,
            "companyId": resolvedCompanyId,
            "collectionPath": collectionPath ?? "",
            "webPath": resolvedWebPath(for: audience),
            "deeplinkUrl": deeplinkUrl ?? appURLString(companyId: resolvedCompanyId, audience: audience, chatId: chatId)
        ]
    }

    func notificationShareDictionary(companyId fallbackCompanyId:String?, audience:String, chatId:String?) -> [String:Any] {
        let resolvedCompanyId = companyId ?? fallbackCompanyId ?? ""
        return [
            "type": type.rawValue,
            "id": recordId,
            "recordId": recordId,
            "companyId": resolvedCompanyId,
            "customerId": customerId ?? "",
            "customerUserId": customerUserId ?? "",
            "title": title,
            "subtitle": subtitle ?? "",
            "collectionPath": collectionPath ?? "",
            "webPath": resolvedWebPath(for: audience),
            "sharePath": sharePath ?? resolvedSharePath(companyId: resolvedCompanyId, audience: audience, chatId: chatId),
            "shareUrl": shareUrl ?? resolvedSharePath(companyId: resolvedCompanyId, audience: audience, chatId: chatId),
            "deeplinkUrl": deeplinkUrl ?? appURLString(companyId: resolvedCompanyId, audience: audience, chatId: chatId),
            "mobileRoute": resolvedMobileRoute ?? "",
            "audience": audience
        ]
    }
}

func dripDropRecipientAudience(chat:Chat, recipientUserId:String) -> String {
    if chat.audienceKind == "internal" {
        return "company"
    }

    let participant = chat.participants.first { $0.userId == recipientUserId }
    if participant?.companyId?.isEmpty == false {
        return "company"
    }

    return "client"
}

func dripDropChatNotificationPayload(
    alertId:String,
    chat:Chat,
    message:Message,
    preview:String,
    link:ConversationLink?,
    recipientUserId:String? = nil,
    recipientCompanyId:String? = nil,
    recipientAudience:String
) -> [String:Any] {
    let fallbackCompanyId = recipientCompanyId ?? link?.companyId ?? chat.companyId ?? chat.senderCompanyId ?? chat.receiverCompanyId ?? message.senderCompanyId ?? ""
    let title = link.map { "\(message.senderName) shared \($0.type.displayName)" } ?? "New message from \(message.senderName)"
    let route = link?.resolvedWebPath(for: recipientAudience) ?? (recipientAudience == "client" ? "/client/chat/details/\(message.chatId)" : "/companies-chat/detail/\(message.chatId)")
    let relatedRoute = link?.resolvedMobileRoute ?? RouteString.chat.rawValue
    let relatedCategory = link?.type.alertCategory ?? MacCategories.chat
    var payload:[String:Any] = [
        "id": alertId,
        "companyId": fallbackCompanyId,
        "title": title,
        "name": title,
        "message": preview,
        "description": preview,
        "status": "unread",
        "read": false,
        "severity": "info",
        "type": link == nil ? "chat_message" : "chat_shared_record",
        "source": "chat",
        "sourceId": message.id,
        "chatId": message.chatId,
        "conversationId": message.chatId,
        "route": route,
        "category": relatedCategory.rawValue,
        "itemId": link?.recordId ?? message.chatId,
        "date": message.dateSent,
        "audience": chat.audienceKind,
        "targetScope": recipientUserId == nil ? "company" : "specific",
        "assignedToUserId": recipientUserId ?? "",
        "recipientUserId": recipientUserId ?? "",
        "recipientCompanyId": recipientCompanyId ?? "",
        "deliveryTargets": ["web", "ios"],
        "channels": [
            "dashboard": true,
            "ios": true,
            "push": true
        ],
        "createdByUserId": message.senderId,
        "createdByName": message.senderName,
        "createdByCompanyId": message.senderCompanyId ?? "",
        "createdByCompanyName": message.senderCompanyName ?? "",
        "createdAt": message.dateSent,
        "updatedAt": Date()
    ]

    if let link {
        payload["hasItem"] = true
        payload["itemName"] = link.title
        payload["mobileRoute"] = relatedRoute
        payload["relatedEntity"] = link.relatedEntityDictionary(companyId: fallbackCompanyId, audience: recipientAudience, chatId: message.chatId)
        payload["share"] = link.notificationShareDictionary(companyId: fallbackCompanyId, audience: recipientAudience, chatId: message.chatId)
    } else {
        payload["hasItem"] = false
        payload["itemName"] = ""
        payload["relatedEntity"] = [
            "type": "chat",
            "id": message.chatId,
            "label": chat.title ?? "Conversation",
            "companyId": fallbackCompanyId
        ]
    }

    return payload
}

protocol ChatManagerProtocol {
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadChat(userId:String,chat:Chat) async throws
    func sendMessage(userId:String,message:Message) async throws
    func markChatAsUnread(userId:String,chat:Chat) async throws

    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllChatsByUser(userId:String) async throws -> [Chat]
    func getSpecificChat(userID:String,chatId:String) async throws ->Chat
    func getChatsByCompany(companyId: String) async throws ->[Chat]
    func getVisibleChats(userId:String, companyId:String?) async throws ->[Chat]
    func getAllMessagesByChat(chatId: String) async throws ->[Message]
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func markChatAsRead(userId:String,chat: Chat) async throws
    func markChatAsRead(userId:String,companyId:String?,chat: Chat) async throws

    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //------------------  LISTENER  ---------------------
    //----------------------------------------------------
    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void)
    func addListenerForVisibleChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void)
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void)
    func addListenerForUnreadChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void)

    func addListenerForAllMessages(chatId:String,amount:Int,completion:@escaping (_ serviceStops:[Message]) -> Void)
    
    func removeListenerForMessages()
    func removeListenerForChats()
}

final class MockChatManager:ChatManagerProtocol {

    
    func markChatAsRead(userId:String,chat: Chat) async throws {
        print("Read")
    }
    func markChatAsRead(userId:String,companyId:String?,chat: Chat) async throws {
        print("Read")
    }
    
    func sendMessage(userId: String, message: Message) async throws {
        print("sent")
    }
    

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
        let mockContracts:[Chat] = [
        ]

    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadChat(userId:String,chat:Chat) async throws {
        
      print("Successfully upLoaded Chat")
    }
    func markChatAsUnread(userId:String,chat:Chat) async throws {

    }

    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllChatsByUser(userId:String) async throws -> [Chat] {
        
        return mockContracts
    }
    func getSpecificChat(userID:String,chatId:String) async throws ->Chat{
        
        guard let chat = mockContracts.first(where: {$0.id == chatId}) else {
            throw FireBaseRead.unableToRead
        }
        return chat
//            .getDocuments(as:Equipment.self)
    }
    func getChatsByCompany(companyId: String) async throws ->[Chat]{
        return []

    }
    func getVisibleChats(userId:String, companyId:String?) async throws ->[Chat]{
        return mockContracts.filter { $0.isVisibleTo(userId: userId, companyId: companyId) }
    }

    func getAllMessagesByChat(chatId: String) async throws ->[Message]{
        return []
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------

    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------

    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //------------------  LISTENER  ---------------------
    //----------------------------------------------------
    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
print("Added Chat Listener")
    }
    func addListenerForVisibleChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        completion(mockContracts.filter { $0.isVisibleTo(userId: userId, companyId: companyId) })
    }
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("Added Chat Listener")

    }
    func addListenerForUnreadChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        completion(mockContracts.filter { $0.isUnread(for: userId, companyId: companyId) })
    }

    func addListenerForAllMessages(chatId: String,amount:Int, completion: @escaping ([Message]) -> Void) {
        print("Added Chat Listener")

    }
    
    func removeListenerForMessages() {
        print("Removed Chat Listener")

    }
    func removeListenerForChats(){
        print("Removed Chat Listener")
    }
}

final class ChatManager:ChatManagerProtocol {

    static let shared = ChatManager()
    init(){}
    private let db = Firestore.firestore()
    private var chatListener: ListenerRegistration? = nil
    private var companyChatListener: ListenerRegistration? = nil
    private var messageListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func chatCollection() -> CollectionReference{
        Firestore.firestore().collection("chats")
    }
        private func messageCollection() -> CollectionReference{
            Firestore.firestore().collection("messages")
        }
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func chatDocument(chatId:String)-> DocumentReference{
        chatCollection().document(chatId)
    }
        private func messageDocument(messageId:String)-> DocumentReference{
            messageCollection().document(messageId)
        }
    private func personalAlertDocument(userId:String, alertId:String) -> DocumentReference {
        db.collection("users").document(userId).collection("alerts").document(alertId)
    }
    private func companyAlertDocument(companyId:String, alertId:String) -> DocumentReference {
        db.collection("companies").document(companyId).collection("alerts").document(alertId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadChat(userId:String,chat:Chat) async throws {
        try chatDocument(chatId: chat.id)
            .setData(from:chat, merge: false)
    }
    func sendMessage(userId: String, message: Message) async throws {
        let chatRef = chatDocument(chatId: message.chatId)
        var outboundMessage = message
        var enrichedLink:ConversationLink? = nil

        if let chat = try? await chatRef.getDocument(as: Chat.self) {
            if let link = message.conversationLink ?? message.messageLinks.first {
                enrichedLink = link.enriched(
                    companyId: link.companyId ?? chat.companyId ?? chat.senderCompanyId ?? chat.receiverCompanyId,
                    audience: link.audience ?? (message.senderCompanyId?.isEmpty == false ? "company" : "client"),
                    chatId: message.chatId
                )
                outboundMessage.conversationLink = enrichedLink
                outboundMessage.attachments = enrichedLink.map { [$0] }
            }

            let targets = chat.unreadTargets(
                senderId: outboundMessage.senderId,
                senderCompanyId: outboundMessage.senderCompanyId
            )
            outboundMessage.receiverId = targets.userIds.first
            outboundMessage.receiverCompanyId = targets.companyIds.first

            try messageDocument(messageId: outboundMessage.id)
                .setData(from:outboundMessage, merge: false)

            var updatePayload:[String:Any] = [
                "lastMessage": outboundMessage.previewText,
                "lastMessageKind": outboundMessage.kind?.rawValue ?? ChatMessageKind.text.rawValue,
                "mostRecentChat": outboundMessage.dateSent,
                "userWhoHaveNotRead": targets.userIds,
                "companyIdsWhoHaveNotRead": targets.companyIds,
                "readByUserIds": [outboundMessage.senderId],
                "updatedAt": Date()
            ]
            if let enrichedLink {
                updatePayload["lastConversationLink"] = try Firestore.Encoder().encode(enrichedLink)
            } else {
                updatePayload["lastConversationLink"] = FieldValue.delete()
            }

            try await chatRef.updateData(updatePayload)
            try await createMessageNotifications(
                chat: chat,
                message: outboundMessage,
                link: enrichedLink,
                userTargets: targets.userIds,
                companyTargets: targets.companyIds
            )
        } else {
            try messageDocument(messageId: outboundMessage.id)
                .setData(from:outboundMessage, merge: false)
        }
    }

    private func createMessageNotifications(
        chat:Chat,
        message:Message,
        link:ConversationLink?,
        userTargets:[String],
        companyTargets:[String]
    ) async throws {
        for recipientUserId in Set(userTargets) {
            let recipientAudience = dripDropRecipientAudience(chat: chat, recipientUserId: recipientUserId)
            let alertId = "alert_\(message.id)_\(recipientUserId)"
            let payload = dripDropChatNotificationPayload(
                alertId: alertId,
                chat: chat,
                message: message,
                preview: message.previewText,
                link: link,
                recipientUserId: recipientUserId,
                recipientAudience: recipientAudience
            )
            try await personalAlertDocument(userId: recipientUserId, alertId: alertId).setData(payload, merge: false)
        }

        for recipientCompanyId in Set(companyTargets) {
            let alertId = "alert_\(message.id)_\(recipientCompanyId)"
            let payload = dripDropChatNotificationPayload(
                alertId: alertId,
                chat: chat,
                message: message,
                preview: message.previewText,
                link: link,
                recipientCompanyId: recipientCompanyId,
                recipientAudience: "company"
            )
            try await companyAlertDocument(companyId: recipientCompanyId, alertId: alertId).setData(payload, merge: false)
        }
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllChatsByUser(userId:String) async throws -> [Chat] {
        return try await chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: true)
        
            .getDocuments(as:Chat.self)
    }
    func getSpecificChat(userID:String,chatId:String) async throws ->Chat{
        
        return try await chatDocument(chatId: chatId)
        .getDocument(as: Chat.self)
//            .getDocuments(as:Equipment.self)
    }
    func getChatsByCompany(companyId: String) async throws ->[Chat]{
        return try await chatCollection()
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments(as:Chat.self)
    }
    func getVisibleChats(userId:String, companyId:String?) async throws ->[Chat]{
        if let companyId {
            return try await chatCollection()
                .whereField("companyId", isEqualTo: companyId)
                .getDocuments(as:Chat.self)
                .sorted { $0.mostRecentChat > $1.mostRecentChat }
        }

        return try await getAllChatsByUser(userId: userId)
    }
    func getAllMessagesByChat(chatId: String) async throws ->[Message]{
        return try await messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: false)
            .limit(to: 10)
            .getDocuments(as:Message.self)
    }

    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func markChatAsRead(userId:String, chat: Chat) async throws {
        try await markChatAsRead(userId: userId, companyId: nil, chat: chat)
    }
    func markChatAsRead(userId:String, companyId:String?, chat: Chat) async throws {
        
        var array:[String] = chat.participantIds
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)

        try await chatRef.updateData([
            "userWhoHaveNotRead": FieldValue.arrayRemove([userId]),
            "readByUserIds": FieldValue.arrayUnion([userId])
            ])
    }
    func markChatAsUnread(userId:String,chat:Chat) async throws {
        print("Trying to mark the chat as unread")
        var array:[String] = chat.participantIds
        
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        try await chatRef.updateData([
          "userWhoHaveNotRead" : FieldValue.arrayUnion(array),
          "readByUserIds": [userId]
        ])
    }

    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------

    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //------------------  LISTENER  ---------------------
    //----------------------------------------------------
    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        
        let listener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                completion(chats)
            }
        self.chatListener = listener
    }
    func addListenerForVisibleChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        var directChats:[Chat] = []
        var companyChats:[Chat] = []

        func emitMergedChats() {
            let chats = Dictionary(grouping: directChats + companyChats, by: \.id)
                .compactMap { $0.value.first }
                .sorted { $0.mostRecentChat > $1.mostRecentChat }
            completion(chats)
        }

        chatListener?.remove()
        companyChatListener?.remove()

        if let companyId {
            self.companyChatListener = chatCollection()
                .whereField("companyId", isEqualTo: companyId)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Company Chat Collection")
                        return
                    }
                    companyChats = documents.compactMap({try? $0.data(as: Chat.self)})
                    emitMergedChats()
                }
            return
        }

        self.chatListener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Direct Chat Collection")
                    return
                }
                directChats = documents.compactMap({try? $0.data(as: Chat.self)})
                emitMergedChats()
            }
    }
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("add Listener For UnreadChats \(userId)")
        let listener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .whereField("userWhoHaveNotRead", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                completion(chats)
            }
        self.chatListener = listener
    }
    func addListenerForUnreadChats(userId:String,companyId:String?,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        var directChats:[Chat] = []
        var companyChats:[Chat] = []

        func emitMergedChats() {
            let chats = Dictionary(grouping: directChats + companyChats, by: \.id)
                .compactMap { $0.value.first }
                .filter { $0.isUnread(for: userId, companyId: companyId) }
            completion(chats)
        }

        chatListener?.remove()
        companyChatListener?.remove()

        if let companyId {
            self.companyChatListener = chatCollection()
                .whereField("companyId", isEqualTo: companyId)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Unread Company Chat Collection")
                        return
                    }
                    companyChats = documents.compactMap({try? $0.data(as: Chat.self)})
                    emitMergedChats()
                }
            return
        }

        self.chatListener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .whereField("userWhoHaveNotRead", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Unread Direct Chat Collection")
                    return
                }
                directChats = documents.compactMap({try? $0.data(as: Chat.self)})
                emitMergedChats()
            }
    }
    func addListenerForAllMessages(chatId: String,amount:Int, completion: @escaping ([Message]) -> Void) {
        print("For Chat - \(chatId)")
        let listener = messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: true)
            .limit(to: amount)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Chat Collection")
                    return
                }
                let messages: [Message] = documents.compactMap({try? $0.data(as: Message.self)})
                print("Successfully Received \(messages.count) Messages")
                completion(messages)
            }
        self.messageListener = listener
    }
    
    func removeListenerForMessages() {
        self.messageListener?.remove()

    }
    func removeListenerForChats(){
        self.chatListener?.remove()
        self.companyChatListener?.remove()
    }
}
