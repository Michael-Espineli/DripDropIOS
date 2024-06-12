//
//  CompanyUserManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import Darwin
enum CompanyUserStatus:String, Codable {
    case active = "Active"
    case pending = "Pending"
    case past = "Past"
}
struct CompanyUser:Codable,Identifiable,Hashable{ // the Id of UserAccess Will Always be the same as the companyId
    var id :String
    var userId : String
    var userName : String
    var roleId: String
    var roleName: String
    var dateCreated : Date
    var status : CompanyUserStatus
}
struct RateSheet:Codable,Identifiable,Hashable{
    var id :String
    var templateId : String
    var rate : Double
    var dateImplemented : Date
    var status : RateSheetStatus
}
enum RateSheetStatus:String ,Codable{
    case active = "Active"
    case inactive = "Inactive"
    case past = "Past"
    case offered = "Offered"
    case rejected = "Rejected"

}
final class CompanyUserManager {
    
    static let shared = CompanyUserManager()
    private init(){}
    
    // COLLECTIONS
    private func companyUsersCollection(companyId:String) -> CollectionReference{
        
        Firestore.firestore().collection("companies/\(companyId)/companyUsers")
    }
    private func companyUsersRateSheetCollection(companyId:String,companyUserId:String) -> CollectionReference{
        
        Firestore.firestore().collection("companies/\(companyId)/companyUsers/\(companyUserId)/rateSheet")
    }
    // DOCUMENTS

    private func companyUserDoc(companyId:String,companyUserId:String) -> DocumentReference{
        companyUsersCollection(companyId: companyId).document(companyUserId)
    }
    private func companyUserRateSheetDoc(companyId:String,companyUserId:String,rateSheetId:String) -> DocumentReference{
        companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId).document(rateSheetId)
    }
    //Create
    func addCompanyUser(companyId:String,companyUser:CompanyUser) async throws{
        try companyUserDoc(companyId: companyId, companyUserId: companyUser.id).setData(from:companyUser, merge: false)

    }
    func addNewRateSheet(companyId:String,companyUserId:String,rateSheet:RateSheet) async throws {
        try companyUserRateSheetDoc(companyId: companyId, companyUserId: companyUserId, rateSheetId: rateSheet.id).setData(from:rateSheet, merge: false)
    }
    //Read
    func getCompanyUserById(companyId:String,companyUserId:String) async throws -> CompanyUser{
        return try await companyUserDoc(companyId: companyId, companyUserId: companyUserId)
            .getDocument(as:CompanyUser.self)
    }

    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws -> CompanyUser{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(as:CompanyUser.self).first! // DEVELOPER PROPPERLY UNWRAP
        
    }
    func getAllRateSheetByCompanyUserId(companyId: String, companyUserId: String) async throws -> [RateSheet]{
        return try await companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId)
            .getDocuments(as:RateSheet.self)
    }
    func getAllCompanyUsers(companyId:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .getDocuments(as:CompanyUser.self)
    }
    func getAllCompanyUsersByStatus(companyId:String,status:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("status", isEqualTo: status)
            .getDocuments(as:CompanyUser.self)
    }
    

    //Update
    //Delete
}
