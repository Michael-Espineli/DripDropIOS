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

extension Role {
    func hasPermission(_ id: String) -> Bool {
        permissionIdList.contains(id) || (id == "860" && !Set(["862", "864", "866"]).isDisjoint(with: permissionIdList)) || (id == "420" && permissionIdList.contains("424")) || (id == "400" && permissionIdList.contains("404"))
    }
    func canDelegate(_ target: Role) -> Bool {
        guard id != target.id, target.id != "1", !["owner", "admin", "manager"].contains(target.name.lowercased()) else { return false }
        let protectedIds: Set<String> = ["262","264","266","274","404","408","424","862","864","866","890"]
        return target.permissionIdList.allSatisfy { permissionIdList.contains($0) && !protectedIds.contains($0) }
    }
    func canAccessArea(_ category: String) -> Bool {
        let ids: Set<String>
        switch category {
        case "Operations": ids = ["0","10","12","14","16","20","22","23","24","26","27","28","29","30","31","32","34","36","40","42","44","46","50","52","54","56","60","62","64","66","72","74"]
        case "Management": ids = ["200","210","220","230","232","234","236","240","242","244","246","250","252","254","256","260","262","264","266","268","274","280","282","284","286","290","292","294","296","300","310","320","322","324","326","328","330","332","334"]
        case "Finance": ids = ["100","102","104","106","400","404","408","410","412","414","416","420","424","430","432","434","436","438","628"]
        case "Settings": ids = ["800","810","812","814","816","820","822","824","826","830","832","834","836","840","842","844","846","850","852","854","856","860","862","864","866","870","872","874","876","880","882","884","886","890","892","894","896","900","910","920"]
        default: ids = []
        }
        return !ids.isDisjoint(with: permissionIdList)
    }

    var canCreateJobFromTemplate: Bool {
        permissionIdList.contains("22") || permissionIdList.contains("23") || permissionIdList.contains("29")
    }

    var canCreateBlankJob: Bool {
        permissionIdList.contains("22") || permissionIdList.contains("27") || permissionIdList.contains("31")
    }

    var canCreateAnyJob: Bool {
        canCreateJobFromTemplate || canCreateBlankJob
    }

    var canScheduleServiceStopsForOthers: Bool {
        permissionIdList.contains("252")
    }

    var canCreateTemplateJobsForOthers: Bool {
        permissionIdList.contains("22") || permissionIdList.contains("29")
    }

    var canCreateCustomJobsForOthers: Bool {
        permissionIdList.contains("22") || permissionIdList.contains("31")
    }

    var canViewOtherMessages: Bool {
        permissionIdList.contains("300")
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
        
        print("[RoleManager][updateRole] Updated Successfully")
    }
    //----------------------------------------------------
    // CRUD           DELETE
    //----------------------------------------------------
    

}
