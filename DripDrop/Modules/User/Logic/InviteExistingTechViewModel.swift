//
//  InviteExistingTechViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/24/24.
//

import Foundation
import Foundation
@MainActor
final class InviteExistingTechViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var selectedUser: DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    @Published private (set) var userList: [DBUser] = []
    @Published private (set) var currentUsers: [CompanyUser] = []
    @Published private(set) var role: Role? = nil
    
    @Published private(set) var roleList: [Role] = []

    @Published var search: String = ""
    
    func changeOfSearchTerm() async throws {
        if search != "" {
            var users = try await dataService.searchForUsers(searchTerm: search)
            users.removeDuplicates()
            users.sort {
                $0.firstName < $1.firstName
            }
            self.userList = users

        }
    }
    func getCurrentUsers(companyId:String) async throws {
        self.currentUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
    }
    func onLoad(companyId:String) async throws {
        self.currentUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        self.roleList = try await dataService.getAllCompanyRoles(companyId: companyId)
    }
    func createInviteForExistingUser(companyId:String,invite:Invite) async throws {
        //Creates Invite
        try await dataService.uploadInvite(invite: invite)
        //Creates Notification For Receiving Person //DEVELOPER Create Personal Alerts, not just Company Alerts.// Developer Add Route For INvite
        try await dataService.addPersonalAlert(userId: invite.userId, dripDropAlert: DripDropAlert(category: .accountsPayable, route: .accountsPayableDetail, itemId: invite.id, name: "Invite From \(invite.companyName)", description: "An Invitation to gain access to Murdock Pool Service", date: Date()))
    }
}
