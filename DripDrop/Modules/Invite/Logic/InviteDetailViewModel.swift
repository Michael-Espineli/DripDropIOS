//
//  NoCompanySelectedViewModel.swift
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
                    self.invites = try await dataService.getUserInvitesByStatus(userId: user.id, status: "All")
                    //Get Chats
                    self.chats = try await dataService.getAllChatsByUser(userId: user.id)
                    
                } catch {
                    print(error)
                }
            
        }
    }