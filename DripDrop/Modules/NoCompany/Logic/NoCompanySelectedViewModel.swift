//
//  SubscriptionPickerViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class NoCompanySelectedViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var chats : [Chat] = []
    @Published private(set) var invites : [Invite] = []

    func onLoad(user:DBUser?) async {
        guard let user else {return}
            do {
                //Get Invites
                print("User Id: \(user.id)")
                self.invites = try await dataService.getUserInvitesByStatus(userId: user.id, status: "pending")
                print("Received Invites \(invites.count)")
                
                //Get Chats
                self.chats = try await dataService.getrecentChatsByUser(userId: user.id, numberOfChats: 5)
                print("Received Chats \(chats.count)")
                
            } catch {
                print(error)
            }
        
    }
}
