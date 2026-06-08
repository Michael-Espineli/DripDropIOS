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
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class NoCompanySelectedViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var chats : [Chat] = []
    @Published private(set) var invites : [Invite] = []

    private func loadInvites(user: DBUser) async throws -> [Invite] {
        let statusVariants = InviteStatusValue.pending.queryVariants
        let normalizedEmail = user.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var inviteMap: [String: Invite] = [:]

        if !normalizedEmail.isEmpty {
            let emailSnapshot = try await Firestore.firestore()
                .collection("invites")
                .whereField(Invite.CodingKeys.email.rawValue, isEqualTo: normalizedEmail)
                .whereField(Invite.CodingKeys.status.rawValue, in: statusVariants)
                .getDocuments()

            for document in emailSnapshot.documents {
                if let invite = try? document.data(as: Invite.self) {
                    inviteMap[invite.id] = invite
                }
            }
        }

        let userSnapshot = try await Firestore.firestore()
            .collection("invites")
            .whereField(Invite.CodingKeys.userId.rawValue, isEqualTo: user.id)
            .whereField(Invite.CodingKeys.status.rawValue, in: statusVariants)
            .getDocuments()

        for document in userSnapshot.documents {
            if let invite = try? document.data(as: Invite.self) {
                inviteMap[invite.id] = invite
            }
        }

        return inviteMap.values.sorted { $0.companyName < $1.companyName }
    }

    func onLoad(user:DBUser?) async {
        guard let user else {return}
            do {
                //Get Invites
                print("User Id: \(user.id)")
                self.invites = try await loadInvites(user: user)
                print("Received Invites \(invites.count)")
                
                //Get Chats
                self.chats = try await dataService.getrecentChatsByUser(userId: user.id, numberOfChats: 5)
                print("Received Chats \(chats.count)")
                
            } catch {
                print(error)
            }
        
    }
}
