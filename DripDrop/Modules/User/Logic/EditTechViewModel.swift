//
//  EditTechViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import Foundation

final class EditTechViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var roleList: [Role] = []
    @Published private(set) var user: DBUser? = nil

    func onFirstLoad(companyId:String,userId:String) async throws {
        self.user = try await dataService.getOneUser(userId: userId)
        self.roleList = try await dataService.getAllCompanyRoles(companyId: companyId)
        
    }
    func updateTech(user: DBUser,tech:DBUser) async throws{
    }
    func updateCompanyUser(user: CompanyUser,userId: String, userName: String, roleId: String, roleName: String, dateCreated: Date, status: CompanyUserStatus) async throws{
        
    }
}
