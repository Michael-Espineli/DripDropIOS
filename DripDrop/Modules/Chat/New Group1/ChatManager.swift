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
}
struct Chat:Identifiable, Codable, Equatable{
    var id:String
    var participantIds:[String]
    var participants:[BasicUserInfo]
    var companyId:String?
    var mostRecentChat:Date
    var userWhoHaveNotRead:[String]
}
struct Message:Identifiable, Codable,Hashable{
    var id:String
    var senderName:String
    var senderId:String
    var message:String
    var read:Bool
    var dateSent:Date
    var chatId:String
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
    func getAllMessagesByChat(chatId: String) async throws ->[Message]
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func markChatAsRead(userId:String,chat: Chat) async throws

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
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void)

    func addListenerForAllMessages(chatId:String,amount:Int,completion:@escaping (_ serviceStops:[Message]) -> Void)
    
    func removeListenerForMessages()
    func removeListenerForChats()
}

final class MockChatManager:ChatManagerProtocol {

    
    func markChatAsRead(userId:String,chat: Chat) async throws {
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
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("Added Chat Listener")

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
        
        var array:[String] = chat.participantIds
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)

        chatRef.updateData([
            "userWhoHaveNotRead": FieldValue.arrayRemove([userId])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func markChatAsUnread(userId:String,chat:Chat) async throws {
        print("Trying to mark the chat as unread")
        var array:[String] = chat.participantIds
        
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        chatRef.updateData([
          "userWhoHaveNotRead" : FieldValue.arrayUnion(array)
        ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
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
    }
}
