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
        try await dataService.uploadChat(userId: userId, chat: chat)
    }
    func uploadChatandMessageWithValidation(userId:String,senderName:String,participantIds:[String],participants:[BasicUserInfo],companyId:String,message:String,mostRecentChat:Date) async throws {
        let chatId = UUID().uuidString
        let chat = Chat(id: chatId,participantIds: participantIds, participants: participants, companyId: companyId,mostRecentChat: mostRecentChat, userWhoHaveNotRead: participantIds)
        try await dataService.uploadChat(userId: userId, chat: chat)
        //Send Message
        try await dataService.sendMessage(userId: userId, message: Message(id: UUID().uuidString, senderName: senderName, senderId: userId, message: message, read: false, dateSent: Date(), chatId: chatId))
    }
    func sendNewMessage(userId:String,senderName:String,message:String,chatId:String) async throws {
        let message = Message(id: UUID().uuidString, senderName: senderName, senderId: userId, message: message, read: false, dateSent: Date(), chatId: chatId)
        try await dataService.sendMessage(userId: userId, message: message)

    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getallChatsByUser(userId: String) async throws {
        self.listOfChats = try await dataService.getAllChatsByUser(userId: userId)
    }
    func getSpecificChat(companyId: String,contractId:String) async throws {
        self.chat = try await dataService.getSpecificChat(userID: companyId, chatId: contractId)
    }
    func getChatBySenderAndReceiver(companyId:String,senderId:String,receiverId:String) async throws {
        self.chat = try await dataService.getChatBySenderAndReceiver(companyId: companyId, senderId: senderId, receiverId: receiverId)
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
    func addListenForUnReadChats(userId:String){
        print("Adding Unread Chat Listener")

         dataService.addListenerForUnreadChats(userId: userId) { [weak self] chats in
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
        print("Removing ChatListener")

        dataService.removeListenerForChats()
    }
    func removeListenerForMessages(){
        print("Removing MessagesListener")

        dataService.removeListenerForMessages()
    }
}
