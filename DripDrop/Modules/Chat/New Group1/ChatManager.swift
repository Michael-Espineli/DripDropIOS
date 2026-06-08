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
}

enum ConversationLinkType: String, Codable, Hashable, CaseIterable {
    case customer
    case serviceLocation
    case repairRequest
    case serviceRequest
    case serviceStop
    case estimate
    case serviceAgreement
    case invoice
    case contract
    case job
    case other

    var displayName: String {
        switch self {
        case .customer: return "Customer"
        case .serviceLocation: return "Service Location"
        case .repairRequest: return "Repair Request"
        case .serviceRequest: return "Service Request"
        case .serviceStop: return "Service Stop"
        case .estimate: return "Estimate"
        case .serviceAgreement: return "Service Agreement"
        case .invoice: return "Invoice"
        case .contract: return "Contract"
        case .job: return "Job"
        case .other: return "Link"
        }
    }

    var systemImage: String {
        switch self {
        case .customer: return "person.crop.circle"
        case .serviceLocation: return "mappin.and.ellipse"
        case .repairRequest: return "wrench.and.screwdriver"
        case .serviceRequest: return "tray.and.arrow.down"
        case .serviceStop: return "checklist"
        case .estimate: return "doc.text.magnifyingglass"
        case .serviceAgreement: return "signature"
        case .invoice: return "doc.richtext"
        case .contract: return "doc.badge.gearshape"
        case .job: return "hammer"
        case .other: return "link"
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
    var actionTitle:String? = nil

    var previewText:String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessage.isEmpty {
            return trimmedMessage
        }

        if let attachment = attachments?.first {
            return "\(attachment.type.displayName): \(attachment.title)"
        }

        return kind == .systemNote ? "System update" : "Message"
    }
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
        try messageDocument(messageId: message.id)
            .setData(from:message, merge: false)
        let chatRef = chatDocument(chatId: message.chatId)
        if let chat = try? await chatRef.getDocument(as: Chat.self) {
            let userTargets = chat.participantIds.filter { $0 != message.senderId }
            let companyTargets = chat.participantCompanyIds ?? chat.companyId.map { [$0] } ?? []
            try await chatRef.updateData([
                "lastMessage": message.previewText,
                "mostRecentChat": message.dateSent,
                "userWhoHaveNotRead": FieldValue.arrayUnion(userTargets),
                "companyIdsWhoHaveNotRead": FieldValue.arrayUnion(companyTargets),
                "readByUserIds": [message.senderId]
            ])
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
        var chats = try await getAllChatsByUser(userId: userId)
        if let companyId {
            let companyChats = try await chatCollection()
                .whereField("participantCompanyIds", arrayContains: companyId)
                .order(by: "mostRecentChat", descending: true)
                .getDocuments(as:Chat.self)
            chats.append(contentsOf: companyChats)
        }

        return Dictionary(grouping: chats, by: \.id)
            .compactMap { $0.value.first }
            .sorted { $0.mostRecentChat > $1.mostRecentChat }
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

        guard let companyId else { return }
        self.companyChatListener = chatCollection()
            .whereField("participantCompanyIds", arrayContains: companyId)
            .order(by: "mostRecentChat", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Company Chat Collection")
                    return
                }
                companyChats = documents.compactMap({try? $0.data(as: Chat.self)})
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

        guard let companyId else { return }
        self.companyChatListener = chatCollection()
            .whereField("companyIdsWhoHaveNotRead", arrayContains: companyId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Unread Company Chat Collection")
                    return
                }
                companyChats = documents.compactMap({try? $0.data(as: Chat.self)})
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
