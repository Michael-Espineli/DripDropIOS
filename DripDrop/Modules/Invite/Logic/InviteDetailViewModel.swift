//
//  InviteDetailViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFirestore

@MainActor
final class InviteDetailViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var updatedInvite : Invite? = nil
    @Published private(set) var company: Company? = nil
    @Published private(set) var reviews: [Review] = []
    @Published private(set) var isLoadingCompany: Bool = false
    @Published private(set) var isUpdatingInvite: Bool = false
    @Published private(set) var alertMessage : String = ""
    @Published private(set) var showAlert : Bool = false

    func dismissAlert() {
        showAlert = false
    }

    func onLoad(invite:Invite) async {
        self.updatedInvite = Invite(
            id: invite.id,
            userId: invite.userId,
            firstName: invite.firstName,
            lastName: invite.lastName,
            email: invite.email,
            companyName: invite.companyName,
            companyId: invite.companyId,
            roleId: invite.roleId,
            roleName: invite.roleName,
            status: invite.status,
            workerType: invite.workerType,
            currentUser: invite.currentUser
        )
        await loadCompanyPublicInfo(companyId: invite.companyId)
    }

    private func loadCompanyPublicInfo(companyId: String) async {
        guard !companyId.isEmpty else { return }
        isLoadingCompany = true
        defer { isLoadingCompany = false }

        do {
            company = try await dataService.getCompany(companyId: companyId)
            let snapshot = try await Firestore.firestore()
                .collection("companies")
                .document(companyId)
                .collection("reviews")
                .getDocuments()

            reviews = snapshot.documents.compactMap { document in
                let data = document.data()
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                    ?? (data["dateCreated"] as? Timestamp)?.dateValue()
                    ?? Date()
                return Review(
                    id: document.documentID,
                    rating: data["rating"] as? Double ?? Double(data["rating"] as? Int ?? 0),
                    description: data["description"] as? String ?? "",
                    reviewerName: data["reviewerName"] as? String ?? data["reviewer"] as? String ?? "Customer",
                    verified: data["verified"] as? Bool ?? false,
                    createdAt: createdAt
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("[InviteDetailViewModel][loadCompanyPublicInfo] \(error)")
        }
    }

    func acceptInvite(user:DBUser?,invite:Invite) async {
        guard let user else {return}
        if !InviteStatusValue.isPending(invite.status){return}
        guard !isUpdatingInvite else { return }
        isUpdatingInvite = true
        defer { isUpdatingInvite = false }
        do {
            try await FunctionsManager.shared.acceptTechInvite(inviteId: invite.id, userId: user.id)
            self.updatedInvite = Invite(
                id: invite.id,
                userId: invite.userId,
                firstName: invite.firstName,
                lastName: invite.lastName,
                email: invite.email,
                companyName: invite.companyName,
                companyId: invite.companyId,
                roleId: invite.roleId,
                roleName: invite.roleName,
                status: InviteStatusValue.accepted.rawValue,
                workerType: invite.workerType,
                currentUser: invite.currentUser
            )
            self.alertMessage = "Invite Accepted"
            self.showAlert.toggle()
        } catch {
            print("Accept Invite Error: ")
            print(error)
            self.alertMessage = error.localizedDescription
            self.showAlert.toggle()
        }
        
    }
    func rejectInvite(user:DBUser?,invite:Invite) async {
        guard let user else {return}
        guard !isUpdatingInvite else { return }
        isUpdatingInvite = true
        defer { isUpdatingInvite = false }
        do {
            //Reject Invite
            try await dataService.updateInviteStatus(invite: invite.id, status: InviteStatusValue.rejected.rawValue)
            self.updatedInvite = Invite(
                id: invite.id,
                userId: invite.userId,
                firstName: invite.firstName,
                lastName: invite.lastName,
                email: invite.email,
                companyName: invite.companyName,
                companyId: invite.companyId,
                roleId: invite.roleId,
                roleName: invite.roleName,
                status: InviteStatusValue.rejected.rawValue,
                workerType: invite.workerType,
                currentUser: invite.currentUser
            )
            self.alertMessage = "Invite Rejected"
            self.showAlert.toggle()
            //Just Update Status
        } catch {
            print(error)
            self.alertMessage = error.localizedDescription
            self.showAlert.toggle()
        }
        
    }
}
