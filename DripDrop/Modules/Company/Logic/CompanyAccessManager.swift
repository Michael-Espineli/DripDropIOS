//
//  CompanyAccessManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/24/23.
//

import Foundation

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase

struct CompanyAccess:Codable,Identifiable,Hashable{ // the Id of CompanyAccess Will Always be the same as the userId
    var id :String
    var userName : String
    var roleId: String
    var roleName: String
    var dateCreated : Date

    init(
        id: String,
        userName: String,
        roleId: String,
        roleName: String,
        dateCreated: Date


    ){
        self.id = id
        self.userName = userName
        self.roleId = roleId
        self.roleName = roleName
        self.dateCreated = dateCreated

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case userName = "userName"
            case roleId = "roleId"
            case roleName = "roleName"
            case dateCreated = "dateCreated"
        }
}

final class CompanyAccessManager {
    
    static let shared = CompanyAccessManager()
    private init(){}
    
// COLLECTIONS
    private func companyAccessCollection(companyId:String) -> CollectionReference{
        
        Firestore.firestore().collection("companies/\(companyId)/companyAccess")
    }
    // DOCUMENTS

    private func companyAccessDocument(companyId:String,accessId:String) -> DocumentReference{
        companyAccessCollection(companyId:companyId).document(accessId)
    }
    // CODER AND ENCODER

    //---------------------
        //CREATE
    //---------------------
    func uploadCompanyAccess(companyId:String,companyAccess:CompanyAccess) async throws {
        print("Attempting to Up Load \(companyAccess.userName) Have access to \(companyId) to Firestore")
 
        try companyAccessDocument(companyId: companyId, accessId: companyAccess.id)
            .setData(from:companyAccess, merge: false)
    }
    //---------------------
        //READ
    //---------------------
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    
    func getAllUserAvailableCompanies(companyId:String) async throws ->[CompanyAccess]{
        print("Attempting to get User Access \(companyId) - Page: UserAccessManager - Func: getAllUserAvailableCompanies")
        return try await companyAccessCollection(companyId: companyId)
            .getDocuments(as:CompanyAccess.self)
    }
    func getUserAccessCompanies(companyId:String,userId:String) async throws ->CompanyAccess{
        return try await companyAccessDocument(companyId: companyId, accessId: userId).getDocument(as: CompanyAccess.self)
    }
    //---------------------
        //UPDATE
    //---------------------

    //---------------------
        //DELETE
    //---------------------
}
