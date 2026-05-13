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

    func onFirstLoad(companyId:String?){
        guard let companyId else {return}
        dataService.addCompanyUserListener(companyId: companyId, status: "Active",
        ) { [weak self] route in
            self?.companyUsers = route
        }
        print("Company Users")
        dataService.addInviteListener(companyId: companyId, status: "Pending",
        ) { [weak self] route in
            self?.pendingInviteList = route
        }
        print("Pending Invites")
    }
    func stop() {
        dataService.removeCompanyUserListener()
        dataService.removeInviteListener()
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
