//
//  Subscription+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/10/25.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

enum SubscriptionTypes : String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    case free = "Free"
    case starter = "Starter"
    case Commercial = "Commercial"
    //case Commercial = "Commercial" //When I release Enterprise
}
struct StripeSubscription:Identifiable, Codable{ // work order data base item
    var id:String
    var stripeProductId:String
    var stripePriceId:String
    var price:Int
    var name:SubscriptionTypes
    var description:String
    var longDescription:String
    var internalNotes:String
    var active:Bool
    var dateCreated:Date
    var lastUpdated:Date
    var featureSet:[String]
}

struct UserSubscription:Identifiable, Codable{ // Maybe Delete
    var id: String
    var stripeSubscriptionId: String
    var stripeProductId: String
    var stripePriceId: String
    var price: Int
    var name: SubscriptionTypes // Should Identify Kind of subscription
    var description: String
    var status: String
    var lastPaid: Date
    var started: Date
}

struct CompanySubscription:Identifiable, Codable{
    var id: String
    var currentPeriodEnd: Date?
    var currentPeriodStart: Date?
    var description: String
    var dripDropSubscriptionId: String
    var lastPaid: Date?
    var name: SubscriptionTypes
    var price:Int
    var started: Date
    var status: String
    var stripeCustomerId: String
    var stripePriceId: String
    var stripeProductId: String
    var stripeSubscriptionId: String
    var userId: String

}

extension ProductionDataService{
    func SubscriptionCollection() -> CollectionReference{
        db.collection("subscriptions")
    }
    func UserSubscriptionCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/subscriptions/")
    }
    func CompanySubscriptionCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/subscriptions/")
    }
    
    func SubscriptionDocument(subscriptionId:String)-> DocumentReference{
        SubscriptionCollection().document(subscriptionId)
    }
    func UserSubscriptionDocument(userId:String,subscriptionId:String)-> DocumentReference{
        UserSubscriptionCollection(userId:userId).document(subscriptionId)
    }
    func CompanySubscriptionDocument(companyId:String,subscriptionId:String)-> DocumentReference{
        CompanySubscriptionCollection(companyId:companyId).document(subscriptionId)
    }
    func getActiveSubscriptions(active:Bool) async throws -> [StripeSubscription] {
        return try await SubscriptionCollection()
            .whereField("active", isEqualTo: active)
            .getDocuments(as: StripeSubscription.self)
    }
    
    //Maybe Remove, I transiation to using the company Subscription
    func getUserSubscription(userId:String) async throws -> UserSubscription?{
        return try await UserSubscriptionCollection(userId:userId)
            .getDocuments(as: UserSubscription.self).first
    }

    func getCompanySubscription(companyId:String) async throws -> CompanySubscription?{
        return try await CompanySubscriptionCollection(companyId:companyId)
            .whereField("status", isEqualTo: "active")
            .limit(to: 1)
            .getDocuments(as: CompanySubscription.self).first
    }
    
    //Maybe Remove, I transiation to using the company Subscription
    func createSubscription(subscription:UserSubscription,user:DBUser,company:Company) async throws{
        try UserSubscriptionCollection(userId:user.id).document(subscription.id).setData(from: subscription)
    }
    func createCompanySubscription(subscription:CompanySubscription,company:Company) async throws{
        try CompanySubscriptionCollection(companyId: company.id).document(subscription.id).setData(from: subscription)
    }
}
