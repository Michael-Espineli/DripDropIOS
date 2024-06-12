//
//  RoleViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class RoleViewModel:ObservableObject{
    //----------------------------------------------------
    // INVITE VARIABLES
    //----------------------------------------------------

    @Published private(set) var role: Role? = nil
    
    @Published private(set) var roleList: [Role] = []

    //----------------------------------------------------
    // CRUD           READ
    //----------------------------------------------------
    func getAllCompanyRoles(companyId:String) async throws{
        self.roleList = try await RoleManager.shared.getAllCompanyRoles(companyId: companyId)
    }
    func getSpecificRole(companyId:String,roleId:String) async throws{
        self.role = try await RoleManager.shared.getSpecificRole(companyId: companyId, roleId: roleId)
    }
    //----------------------------------------------------
    // CRUD           CREATE
    //----------------------------------------------------
    func createRole(companyId:String,role:Role) async throws {
        try? await RoleManager.shared.uploadRole(companyId: companyId, role: role)
    }
    //----------------------------------------------------
    // CRUD           UPDATE
    //----------------------------------------------------
    func updateRole(companyId:String,role:Role) async throws {
        try? await RoleManager.shared.updateRole(companyId: companyId, role: role)
    }
}
