//
//  ChatViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//


import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ChatViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var chat: Chat? = nil
    @Published private(set) var unreadChatCount: Int? = nil

    //ARRAYS
    @Published private(set) var listOfChats:[Chat] = []
    @Published private(set) var listOfUnreadChats:[Chat] = []

    @Published private(set) var listOfMessages:[Message] = []
    @Published private(set) var newestMessage:Message? = nil

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadChat(userId:String,chat:Chat) async throws {
        try await dataService.uploadChat(chat: chat)
    }
    func uploadChatandMessageWithValidation(userId:String,senderName:String,participantIds:[String],participants:[BasicUserInfo],companyId:String,message:String,mostRecentChat:Date) async throws {
        let chatId = UUID().uuidString
        let chat = Chat(
            id: chatId,
            participantIds: participantIds,
            participants: participants,
            companyId: companyId,
            mostRecentChat: mostRecentChat,
            userWhoHaveNotRead: participantIds.filter { $0 != userId },
            lastMessage: message,
            visibility: .direct,
            participantCompanyIds: [companyId],
            companyIdsWhoHaveNotRead: [companyId],
            readByUserIds: [userId]
        )
        try await dataService.uploadChat(chat: chat)
        //Send Message
        try await dataService.sendMessage(message: Message(id: UUID().uuidString, senderName: senderName, senderId: userId, message: message, read: false, dateSent: Date(), chatId: chatId, senderCompanyId: companyId))
    }
    func sendNewMessage(userId:String,senderName:String,message:String,chatId:String) async throws {
        let message = Message(id: UUID().uuidString, senderName: senderName, senderId: userId, message: message, read: false, dateSent: Date(), chatId: chatId)
        try await dataService.sendMessage( message: message)

    }
    func sendNewMessage(userId:String,senderName:String,senderCompanyId:String?,senderCompanyName:String?,message:String,chatId:String) async throws {
        let message = Message(
            id: UUID().uuidString,
            senderName: senderName,
            senderId: userId,
            message: message,
            read: false,
            dateSent: Date(),
            chatId: chatId,
            senderCompanyId: senderCompanyId,
            senderCompanyName: senderCompanyName
        )
        try await dataService.sendMessage(message: message)
    }
    func sendLinkedRecordMessage(
        userId:String,
        senderName:String,
        senderCompanyId:String?,
        senderCompanyName:String?,
        chatId:String,
        note:String,
        link:ConversationLink
    ) async throws {
        let message = Message(
            id: UUID().uuidString,
            senderName: senderName,
            senderId: userId,
            message: note,
            read: false,
            dateSent: Date(),
            chatId: chatId,
            kind: .linkedRecord,
            senderCompanyId: senderCompanyId,
            senderCompanyName: senderCompanyName,
            attachments: [link],
            actionTitle: "Open"
        )
        try await dataService.sendMessage(message: message)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getallChatsByUser(userId: String) async throws {
        self.listOfChats = try await dataService.getAllChatsByUser(userId: userId)
    }
    func getVisibleChats(userId: String, companyId:String?) async throws {
        self.listOfChats = try await dataService.getVisibleChats(userId: userId, companyId: companyId)
    }
    func getSpecificChat(companyId: String,contractId:String) async throws {
        self.chat = try await dataService.getSpecificChat(chatId: contractId)
    }
    func getChatBySenderAndReceiver(companyId:String,senderId:String,receiverId:String) async throws {
        self.chat = try await dataService.getChatBySenderAndReceiver(senderId: senderId, receiverId: receiverId)
    }
    func getContractsByCompany(companyId:String) async throws {
        self.listOfChats = try await dataService.getChatsByCompany(companyId: companyId)
    }
    func getAllMessagesByChat(chatId:String) async throws {
        self.listOfMessages = try await dataService.getAllMessagesByChat(chatId:chatId)
    }
    func getNewestMessage(chatId:String) async throws {
        self.newestMessage = try await dataService.getNewestMessage(chatId: chatId)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func markChatAsRead(userId:String,chat: Chat) async throws {
        try await dataService.markChatAsRead(userId: userId, chat: chat)
    }
    func markChatAsRead(userId:String,companyId:String?,chat: Chat) async throws {
        try await dataService.markChatAsRead(userId: userId, companyId: companyId, chat: chat)
    }
    func markChatAsUnRead(userId: String, chat:Chat) async throws {
        try await dataService.markChatAsUnread(userId: userId, chat: chat)
    }
    
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------

    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func addListenerForAllChats(userId:String){
        print("Adding Chat Listener")

         dataService.addListenerForAllChats(userId: userId) { [weak self] chats in
            self?.listOfChats = chats
        }
    }
    func addListenerForVisibleChats(userId:String, companyId:String?){
        print("Adding Visible Chat Listener")

         dataService.addListenerForVisibleChats(userId: userId, companyId: companyId) { [weak self] chats in
            self?.listOfChats = chats
        }
    }
    func addListenForUnReadChats(userId:String){
        print("Adding Unread Chat Listener")

         dataService.addListenerForUnreadChats(userId: userId) { [weak self] chats in
             self?.unreadChatCount = chats.count
             self?.listOfUnreadChats = chats
        }
    }
    func addListenForUnReadChats(userId:String, companyId:String?){
        print("Adding Company-Aware Unread Chat Listener")

         dataService.addListenerForUnreadChats(userId: userId, companyId: companyId) { [weak self] chats in
             self?.unreadChatCount = chats.count
             self?.listOfUnreadChats = chats
        }
    }
    func addListenerForAllMessages(chatId:String,amount:Int){
        print("Adding Message Listener")
         dataService.addListenerForAllMessages(chatId: chatId,amount: amount) { [weak self] messages in
             self?.listOfMessages = messages
        }
    }
    func removeListenerForChats(){
        print("Removing Chat Listener")

        dataService.removeListenerForChats()
    }
    func removeListenerForMessages(){
        print("Removing Messages Listener")

        dataService.removeListenerForMessages()
    }
}
