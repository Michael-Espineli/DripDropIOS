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

struct PersonalVehicle: Codable, Hashable {
    var nickName: String?
    var vehicalType: String?
    var year: String?
    var make: String?
    var model: String?
    var color: String?
    var plate: String?
    var miles: Double?
    
    var displayName: String {
        let vehicleName = [year, make, model]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        if let nickName, !nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nickName
        }
        
        return vehicleName.isEmpty ? "Personal Vehicle" : vehicleName
    }
    
    func asVehical(ownerId: String) -> Vehical {
        Vehical(
            id: "personal:\(ownerId)",
            nickName: displayName,
            vehicalType: VehicalType(rawValue: vehicalType ?? "") ?? .car,
            year: year ?? "",
            make: make ?? "",
            model: model ?? "",
            color: color ?? "",
            plate: plate ?? "",
            datePurchased: Date(),
            miles: miles ?? 0,
            status: .active
        )
    }
}

struct CompanyUser:Codable,Identifiable,Hashable{ // the Id of UserAccess Will Always be the same as the companyId
    var id :String
    var userId : String
    var userName : String
    var roleId: String
    var roleName: String
    var dateCreated : Date
    var status : CompanyUserStatus
    var workerType : WorkerTypeEnum
    var linkedCompanyId : String?
    var linkedCompanyName : String?
    var allowPersonalVehicle: Bool?
    var personalVehicle: PersonalVehicle?
    
    init(
        id: String,
        userId: String,
        userName: String,
        roleId: String,
        roleName: String,
        dateCreated: Date,
        status: CompanyUserStatus,
        workerType: WorkerTypeEnum,
        linkedCompanyId: String? = nil,
        linkedCompanyName: String? = nil,
        allowPersonalVehicle: Bool? = nil,
        personalVehicle: PersonalVehicle? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.roleId = roleId
        self.roleName = roleName
        self.dateCreated = dateCreated
        self.status = status
        self.workerType = workerType
        self.linkedCompanyId = linkedCompanyId
        self.linkedCompanyName = linkedCompanyName
        self.allowPersonalVehicle = allowPersonalVehicle
        self.personalVehicle = personalVehicle
    }
}

//struct RateSheet:Codable,Identifiable,Hashable{
//    var id :String
//    var templateName : String
//    var templateId : String
//    var rate : Double
//    var dateImplemented : Date
//    var status : RateSheetStatus
//    var laborType:RateSheetLaborType
//}

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

    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws -> CompanyUser {
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
            .order(by: "userName", descending: false)
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
