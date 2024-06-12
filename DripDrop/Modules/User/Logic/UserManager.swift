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

 struct DBUser:Codable,Identifiable,Hashable{
    var id :String
    var email :String?
    var photoUrl : String?
    var dateCreated : Date?
    var firstName: String?
    var lastName: String?
    var accountType: String? // Change to Account Type (Buisness, Technican, Client)
    var profileImagePath: String?
    var color: String?
    var bio: String?
    var exp: Int
    var stripeId: String?

    init(
        id: String,
        email :String? = nil,
        photoUrl : String? = nil,
        dateCreated : Date? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        accountType: String? = nil,
        profileImagePath: String? = nil,
        color: String? = nil,
        bio: String? = nil,
        exp: Int,
        stripeId: String? = nil


    ){
        self.id = id
        self.email = email
        self.photoUrl = photoUrl
        self.dateCreated = dateCreated
        self.firstName = firstName
        self.lastName = lastName
        self.accountType = accountType
        self.profileImagePath = profileImagePath
        self.color = color
        self.bio = bio
        self.exp = exp
        self.stripeId = stripeId

        
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case email = "email"
            case photoUrl = "photoUrl"
            case dateCreated = "dateCreated"
            case firstName = "firstName"
            case lastName = "lastName"
            case accountType = "accountType"
            case profileImagePath = "profileImagePath"
            case color = "color"
            case bio = "bio"
            case exp = "exp"
            case stripeId = "stripeId"

        }
}
struct RecentActivityModel:Codable,Identifiable,Hashable{
    
    var id : String
    var route : String
    var date : Date
    var companyId:String
    var itemId: String?
    
    init(
        id: String,
        route :String,
        date : Date,
        companyId :String,
        itemId :String? = nil

    ){
        self.id = id
        self.route = route
        self.date = date
        self.companyId = companyId
        self.itemId = itemId

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case route = "route"
            case date = "date"
            case companyId = "companyId"
            case itemId = "itemId"
        }
}

final class UserManager {
    
    static let shared = UserManager()
    private init(){}
    
// COLLECTIONS
    private func userCollection() -> CollectionReference{
        Firestore.firestore().collection("users")
    }
    private func userRecentActivityCollection(userId:String) -> CollectionReference{
        Firestore.firestore().collection("users/\(userId)/recentActivity")
    }
    // DOCUMENTS

    private func userDocument(userId:String) -> DocumentReference{
        userCollection().document(userId)
    }
    private func userActivityDocument(userId:String,recentActivityId:String) -> DocumentReference{
        userRecentActivityCollection(userId: userId).document(recentActivityId)
    }
    // CODER AND ENCODER

    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    //---------------------
        //CREATE
    //---------------------

    func createNewUser(user:DBUser) async throws{
        let DBUser = try await DBUserManager.shared.loadCurrentUser()//DEVELOPER DELETE
        try userDocument(userId: user.id).setData(from: user,merge: false,encoder: encoder)
    }
    func createFirstCompanyUser(user:DBUser) async throws{
        try userDocument(userId: user.id ).setData(from: user,merge: false)
    }
    func createNewRecentActivity(userId:String,recentActivity:RecentActivityModel) async throws{
        try userActivityDocument(userId: userId,recentActivityId: recentActivity.id).setData(from: recentActivity,merge: false)
    }
    
    
    func updateCompanyUser(user:DBUser,updatingUser:DBUser) throws {
//        let ref = userDocument(userId: updatingUser.id, companyId: user.companyId)
//
//         ref.updateData([
//            "email": updatingUser.email,
//            "photoUrl": updatingUser.photoUrl as Any,
//            "dateCreated": updatingUser.dateCreated as Any,
//            "firstName": updatingUser.firstName as Any,
//            "lastName": updatingUser.lastName as Any,
//            "company": updatingUser.company as Any,
//            "companyId": updatingUser.companyId,
//            "position": updatingUser.position,
//            "hireDate": updatingUser.hireDate as Any,
//            "fireDate": updatingUser.fireDate as Any,
//            "favorites": updatingUser.favorites as Any,
//        ]) { err in
//            if let err = err {
//                print("Error updating document: \(err)")
//            } else {
//                print("Updated Company User Successfully")
//            }
//        }
    }

    //---------------------
        //READ
    //---------------------

    func getCurrentUser(userId:String) async throws -> DBUser{
//        let DBUser = try await DBUserManager.shared.loadCurrentUser()

        return try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }

    func loadCurrentUser() async throws -> DBUser{
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        return try await UserManager.shared.getCurrentUser(userId: authDataResult.uid)
        
    }
    func getRecentActivityByUser(userId:String) async throws -> [RecentActivityModel]{
        return try await userRecentActivityCollection(userId: userId)
            .order(by: RecentActivityModel.CodingKeys.date.rawValue, descending: true)
            .limit(to: 8)
            .getDocuments(as:RecentActivityModel.self)
        
    }
    //---------------------
        //UPDATE
    //---------------------
    func updateCompanyUserFavorites(user:DBUser,updatingUser:DBUser,favorites:[String]) throws {
//        let ref = userDocument(userId: updatingUser.id)
//        //Change to Array Append
//         ref.updateData([
//            DBUser.CodingKeys.favorites.rawValue: favorites,
//        ]) { err in
//            if let err = err {
//                print("Error updating document: \(err)")
//            } else {
//                print("Updated Tech Favorite List Successfully")
//            }
//        }
    }
    func updateUserImagePath(updatingUser:DBUser,path:String) throws {
        let ref = userDocument(userId: updatingUser.id)
        
         ref.updateData([
            DBUser.CodingKeys.photoUrl.rawValue: path,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }
    //---------------------
        //DELETE
    //---------------------
}
