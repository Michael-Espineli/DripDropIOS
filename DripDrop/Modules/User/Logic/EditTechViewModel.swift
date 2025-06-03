//
//  EditTechViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/19/24.
//

import Foundation
@MainActor
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
    func updateCompanyUser(
        companyId:String,
        user: CompanyUser,
        userId: String,
        userName: String,
        roleId: String,
        roleName: String,
        dateCreated: Date,
        status: CompanyUserStatus,
        workerType:WorkerTypeEnum
    ) async throws{
        print("")
        print("Updating Company User For")

        if user.roleId != roleId || user.roleName != roleName{
            print("Updating Role Id")
            try await dataService.updateCompanyUserRole(companyId: companyId, companyUserId: user.id, roleId: roleId, roleName: roleName)
        }
        if user.workerType != workerType{
            print("Updating workerType")
            try await dataService.updateCompanyUserWorkerType(companyId: companyId, companyUserId: user.id, workerType: workerType)

        }
    }
}
