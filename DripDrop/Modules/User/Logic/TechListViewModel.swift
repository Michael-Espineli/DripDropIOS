//
//  TechListViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import Foundation
@MainActor
final class TechListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var acceptedInviteList: [Invite] = []
    
    @Published private(set) var pendingInviteList: [Invite] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var specificTech: DBUser? = nil

    func onFirstLoad(companyId:String) async throws {
        print("Company Users")

        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
 
        print("Pending Invites")
        self.pendingInviteList = try await dataService.getAllCompanyInvites(comapnyId: companyId)
        print("Accepted Invites")

        self.acceptedInviteList = try await dataService.getAllAcceptedCompanyInvites(comapnyId: companyId)

    }
    
    func onChangeOfSelectedStatus(companyId:String,status:String) async throws {
        
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        
    }
    func getOneTech(techId: String) async throws{
        self.specificTech = try await dataService.getOneUser(userId: techId)
    }
    func getActiveCompanyUsers(companyId: String) async throws{
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
    }
}
