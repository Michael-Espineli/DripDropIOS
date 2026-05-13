//
//  DBUser+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    //Refrences
    func userCollection() -> CollectionReference{
        db.collection("users")
    }
    func userRecentActivityCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/recentActivity")
    }
    func userAccessCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/userAccess")
    }
    func personalAlertCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/alerts")
    }

    func userDocument(userId:String) -> DocumentReference{
        userCollection().document(userId)
    }
    func userActivityDocument(userId:String,recentActivityId:String) -> DocumentReference{
        userRecentActivityCollection(userId: userId).document(recentActivityId)
    }
    func userDocument(userId:String,accessId:String) -> DocumentReference{
        userAccessCollection(userId: userId).document(accessId)
    }
    func personalAlertDocument(userId:String,alertId:String)-> DocumentReference{
        personalAlertCollection(userId:userId).document(alertId)
    }
    func updateDBUserEmail(userId:String,email:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "email": email
        ])
    }
    
    func updateDBUserPhotoUrl(userId:String,photoUrl:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "photoUrl": photoUrl
        ])
    }
    
    func updateDBUserProfileImagePath(userId:String,profileImagePath:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "profileImagePath": profileImagePath
        ])
    }
    
    func updateDBUserFirstName(userId:String,firstName:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "firstName": firstName
        ])
    }
    
    func updateDBUserLastName(userId:String,lastName:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "lastName": lastName
        ])
    }
    
    func updateDBUserBio(userId:String,bio:String) throws {
        try userDocument(userId: userId)
        .updateData([
            "bio": bio
        ])
    }
    
    func updateDBUserExp(userId:String,exp:Int) throws {
        try userDocument(userId: userId)
        .updateData([
            "exp": exp
        ])
    }
    
    func updateDBUserPhoneNumber(userId:String,phoneNumber:String) throws {
        
        try userDocument(userId: userId)
        .updateData([
            "phoneNumber": phoneNumber
        ])
    }
}
