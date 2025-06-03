//
//  ShoppingListManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin

struct ShoppingListItem:Identifiable, Codable,Hashable{
    var id:String
    
    var category:ShoppingListCategory // Personal , Customer , Job
    var subCategory:ShoppingListSubCategory // Data Base , Chemical , Part , Custom
    var status:ShoppingListStatus //Need to Purchase, Purchased, Installed
    var purchaserId:String
    var purchaserName:String
    
    var genericItemId:String // Generic Id
    var name:String
    var description:String
    var datePurchased:Date?
    var quantiy:String? //I SPElled QUANTITY WRONG
    
    //Job
    var jobId:String?
    
    //Customer
    var customerId:String?
    var customerName:String?
    //Personal
    var userId:String?
    var userName:String?
    
    //DataBaseItem
    var dbItemId: String?
}

protocol ShoppingListManagerProtocol {
    func addNewShoppingListItem(companyId:String,shoppingListItem:ShoppingListItem) async throws
    
    func getSpecificShoppingListItem(companyId:String,shoppingListItemId:String) async throws -> ShoppingListItem
    func getAllShoppingListItemsByCompany(companyId:String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUser(companyId:String,userId:String) async throws  -> [ShoppingListItem]
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws
}

final class MockShoppingListtManager:ShoppingListManagerProtocol {
  
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        
    }
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        print("Successfully addNewShoppingListItemWithValidation")

    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return ShoppingListItem(id: "", category: .customer, subCategory: .chemical, status: .needToPurchase, purchaserId: "", purchaserName: "", genericItemId: "", name: "",description:"")
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByCompany")
        return []
    }
    
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByUser")
        return []

    }
    
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByUserForCategory")
        return []
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        return 8
    }
}

final class ShoppingListManager:ShoppingListManagerProtocol {


    static let shared = ShoppingListManager()
    init(){}
    private let db = Firestore.firestore()
    private var chatListener: ListenerRegistration? = nil
    private var messageListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func shoppingListCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/shoppingList")
    }
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func shoppingListDoc(companyId:String,shoppingListItemId:String)-> DocumentReference{
        shoppingListCollection(companyId: companyId).document(shoppingListItemId)
    }
    //CRUD
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        try shoppingListCollection(companyId: companyId).document(shoppingListItem.id).setData(from:shoppingListItem, merge: false)

    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).getDocument(as: ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .getDocuments(as:ShoppingListItem.self)
    }
    
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        return Int(try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .count.getAggregation(source: .server).count)
    }
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
    }

    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).delete()

    }
    
}
