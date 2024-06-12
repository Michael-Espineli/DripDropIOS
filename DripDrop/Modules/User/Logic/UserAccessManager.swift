//
//  UserAccessManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//
//
//  UserManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import Darwin
//Build another one on the Company Side.
struct UserAccess:Codable,Identifiable,Hashable{ // the Id of UserAccess Will Always be the same as the companyId
    var id :String
    var companyId : String
    var companyName : String
    var roleId: String
    var roleName: String
    var dateCreated : Date

    init(
        id: String,
        companyId: String,
        companyName: String,
        roleId: String,
        roleName: String,
        dateCreated: Date


    ){
        self.id = id
        self.companyId = companyId

        self.companyName = companyName
        self.roleId = roleId
        self.roleName = roleName
        self.dateCreated = dateCreated

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case companyId = "companyId"

            case companyName = "companyName"
            case roleId = "roleId"
            case roleName = "roleName"
            case dateCreated = "dateCreated"
        }
}

final class UserAccessManager {
    
    static let shared = UserAccessManager()
    private init(){}
    
// COLLECTIONS
    private func userAccessCollection(userId:String) -> CollectionReference{
        
        Firestore.firestore().collection("users/\(userId)/userAccess")
    }
    // DOCUMENTS

    private func userDocument(userId:String,accessId:String) -> DocumentReference{
        userAccessCollection(userId: userId).document(accessId)
    }
    // CODER AND ENCODER

    //---------------------
        //CREATE
    //---------------------
    func uploadUserAccess(userId : String,companyId:String,userAccess:UserAccess) async throws {
        print("Attempting to Up Load \(userId) Have access to \(userAccess.companyName) to Firestore")
 
        try userDocument(userId: userId, accessId: companyId).setData(from:userAccess, merge: false)
    }
    //---------------------
        //READ
    //---------------------
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    
    func getAllUserAvailableCompanies(userId:String) async throws ->[UserAccess]{
        print("Attempting to get User Access \(userId) - Page: UserAccessManager - Func: getAllUserAvailableCompanies")
        return try await userAccessCollection(userId: userId)
            .getDocuments(as:UserAccess.self) // DEVELOPER FIX LATER, BUT FOR NOW I WANNA TEST WHAT IT LOOKS LIKE WITH OUT HAVING A COMPANY
//        return []
    }
    func getUserAccessCompanies(userId:String,companyId:String) async throws ->UserAccess{
        return try await userDocument(userId: userId, accessId: companyId).getDocument(as: UserAccess.self)
    }
    //---------------------
        //UPDATE
    //---------------------

    //---------------------
        //DELETE
    //---------------------
}
