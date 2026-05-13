//
//  InviteDetailViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class InviteDetailViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var updatedInvite : Invite? = nil
    @Published private(set) var alertMessage : String = ""
    @Published private(set) var showAlert : Bool = false

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
    }
    func acceptInvite(user:DBUser?,invite:Invite) async {
        guard let user else {return}
        if invite.status != "pending"{return}
        do {
            //Accept Invite
            try await dataService.updateInviteStatus(invite: invite.id, status: "accepted")
            //Update Status
            let data:[String:Any] = [
                "inviteId": invite.id,
                "userId": user.id,
            ]
            print(data)
            let result = try await Functions.functions().httpsCallable("acceptTechInvite").call(data)
            print(result)
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
                status: "accepted",
                workerType: invite.workerType,
                currentUser: invite.currentUser
            )
            self.alertMessage = "Invite Rejected"
            self.showAlert.toggle()
        } catch {
            print("Accept Invite Error: ")
            print(error)
        }
        
    }
    func rejectInvite(user:DBUser?,invite:Invite) async {
        guard let user else {return}
        do {
            //Reject Invite
            try await dataService.updateInviteStatus(invite: invite.id, status: "rejected")
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
                status: "rejected",
                workerType: invite.workerType,
                currentUser: invite.currentUser
            )
            self.alertMessage = "Invite Rejected"
            self.showAlert.toggle()
            //Just Update Status
        } catch {
            print(error)
        }
        
    }
}
