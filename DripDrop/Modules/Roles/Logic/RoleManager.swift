//
//  RoleModule.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Role:Identifiable,Codable,Equatable,Hashable{
    var id : String
    var name : String
    var permissionIdList : [String]
    var listOfUserIdsToManage : [String]
    var color : String
    var description : String


    init(
        id: String,
        name: String,
        permissionIdList: [String],
        listOfUserIdsToManage: [String],
        color: String,
        description: String

    ){
        self.id = id
        self.name = name
        self.permissionIdList = permissionIdList
        self.listOfUserIdsToManage = listOfUserIdsToManage
        self.color = color
        self.description = description
    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case name = "name"
        case permissionIdList = "permissionIdList"
        case listOfUserIdsToManage = "listOfUserIdsToManage"
        case color = "color"
        case description = "description"

    }
}


final class RoleManager {
    static let shared = RoleManager()

    private init(){}
    //----------------------------------------------------
    // INVITE COLLECTIONS AND DOCUMENTS
    //----------------------------------------------------

    private func roleCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/roles")
    }

    private func roleDoc(companyId:String,roleId:String)-> DocumentReference{
        roleCollection(companyId: companyId).document(roleId)
    }
    
    //----------------------------------------------------
    // CRUD           CREATE
    //----------------------------------------------------
    func uploadRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }
    //----------------------------------------------------
    // CRUD           READ
    //----------------------------------------------------
    func getAllCompanyRoles(companyId : String) async throws ->[Role] {
        return try await roleCollection(companyId: companyId)
//            .whereField(Role.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
//            .whereField(Role.CodingKeys.status.rawValue, isEqualTo: "Pending")
            .getDocuments(as:Role.self)
    }

    func getSpecificRole(companyId:String,roleId : String) async throws ->Role {
        return try await roleDoc(companyId: companyId,roleId: roleId)
            .getDocument(as: Role.self)

    }
    //----------------------------------------------------
    // CRUD           UPDATE
    //----------------------------------------------------
    func updateRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }
    //----------------------------------------------------
    // CRUD           DELETE
    //----------------------------------------------------
    

}
