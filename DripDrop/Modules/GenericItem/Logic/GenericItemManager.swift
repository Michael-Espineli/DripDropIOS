//
//  GenericItemManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/27/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin
struct GenericItem:Identifiable,Codable{
    var id : String
    var commonName: String
    var specificName: String

    var category : String
    var description : String
    var dateUpdated : Date
    var sku : String
    var rate : Double
    var sellPrice : Double
    var UOM : String

    var storeItems : [String]
    var storeItemsIds : [String]


}

protocol GenericItemManagerProtocol {
    func GenericItemCollection(companyId:String) -> CollectionReference
    func GenericItemDocument(companyId:String,genericItemId:String)-> DocumentReference
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws
    func createIntialGenericDataBaseItems(companyId:String) async throws

    func getAllDataBaseItems(companyId:String) async throws -> [GenericItem]
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [GenericItem]
    func getDataBaseItem(companyId:String,genericItemId:String) async throws -> GenericItem
    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) throws
}

final class MockGenericItemManager:GenericItemManagerProtocol {
    func GenericItemCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/genericItems/genericItems")
    }
    func GenericItemDocument(companyId:String,genericItemId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
        
    }
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws {

        try GenericItemDocument(companyId: companyId, genericItemId: genericItem.id).setData(from:genericItem, merge: false)
    }
    func createIntialGenericDataBaseItems(companyId:String) async throws{
        let genericItems:[GenericItem] = [
            //Chemicals
            GenericItem(id: "Chlorine", commonName: "Chlorine", specificName: "Bleach", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Acid", commonName: "Acid", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodiumBromide", commonName: "Sodium Bromide", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Tabs", commonName: "Tabs", specificName: "3in Chlorine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "BromineTabs", commonName: "Bromine Tabs", specificName: "Bromine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Salt", commonName: "Salt", specificName: "Salt", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodaAsh", commonName: "Soda Ash", specificName: "Soda Ash", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Oz", storeItems: [], storeItemsIds: []),
            //PVC
            GenericItem(id: "Pipe", commonName: "Pipe", specificName: "Pipe", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Coupler", commonName: "Coupler", specificName: "Coupler", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Elbow", commonName: "Elbow", specificName: "Elbow", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "45", commonName: "45", specificName: "45", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: [])
        ]

        for item in genericItems {
             try GenericItemDocument(companyId: companyId, genericItemId: item.id).setData(from:item, merge: false)
        }
        
    }

    func getAllDataBaseItems(companyId:String) async throws -> [GenericItem]{

        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)

    }
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [GenericItem]{
        return try await GenericItemCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .getDocuments(as:GenericItem.self)

    }
    func getDataBaseItem(companyId:String,genericItemId:String) async throws -> GenericItem{

        return try await GenericItemDocument(companyId: companyId, genericItemId: genericItemId).getDocument(as: GenericItem.self)
    }

    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem{
        
        let dbItem = try await Firestore.firestore().collection("workOrders/\(workOrderId)/installationParts").document(workOrderItemId).getDocument(as: WODBItem.self)
        
        return try await getDataBaseItem(companyId: companyId, genericItemId: dbItem.genericItemId)
    }
    
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) throws {

        var DBArray: [String] = []
        print("Throw error Here")
        DBArray = genericItem.storeItems
        DBArray.append(storeItem.id)
        print(genericItem.id)
        let ref = GenericItemCollection(companyId: companyId).document(genericItem.id)
         ref.updateData([
            "storeItems": DBArray
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }

    }

}

final class GenericItemManager:GenericItemManagerProtocol {
    
    static let shared = GenericItemManager()
    init(){}
    
    func GenericItemCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/genericItems/genericItems")
    }
    func GenericItemDocument(companyId:String,genericItemId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
        
    }
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws {

     try GenericItemDocument(companyId: companyId, genericItemId: genericItem.id).setData(from:genericItem, merge: false)
    }
    func createIntialGenericDataBaseItems(companyId:String) async throws{
        let genericItems:[GenericItem] = [
            //Chemicals
            GenericItem(id: "Chlorine", commonName: "Chlorine", specificName: "Bleach", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Acid", commonName: "Acid", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodiumBromide", commonName: "Sodium Bromide", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Tabs", commonName: "Tabs", specificName: "3in Chlorine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "BromineTabs", commonName: "Bromine Tabs", specificName: "Bromine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Salt", commonName: "Salt", specificName: "Salt", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodaAsh", commonName: "Soda Ash", specificName: "Soda Ash", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Oz", storeItems: [], storeItemsIds: []),
            //PVC
            GenericItem(id: "Pipe", commonName: "Pipe", specificName: "Pipe", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Coupler", commonName: "Coupler", specificName: "Coupler", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Elbow", commonName: "Elbow", specificName: "Elbow", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "45", commonName: "45", specificName: "45", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: [])
        ]

        for item in genericItems {
            try GenericItemDocument(companyId: companyId, genericItemId: item.id).setData(from:item, merge:false)

        }
        
    }

    func getAllDataBaseItems(companyId:String) async throws -> [GenericItem]{

        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)

    }
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [GenericItem]{
        return try await GenericItemCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .getDocuments(as:GenericItem.self)

    }
    func getDataBaseItem(companyId:String,genericItemId:String) async throws -> GenericItem{

        return try await GenericItemDocument(companyId: companyId, genericItemId: genericItemId).getDocument(as: GenericItem.self)
    }

    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem{
        
        let dbItem = try await Firestore.firestore().collection("workOrders/\(workOrderId)/installationParts").document(workOrderItemId).getDocument(as: WODBItem.self)
        
        return try await getDataBaseItem(companyId: companyId, genericItemId: dbItem.genericItemId)
    }
    
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) throws {

        var DBArray: [String] = []
        print("Throw error Here")
        DBArray = genericItem.storeItems
        DBArray.append(storeItem.id)
        print(genericItem.id)
        let ref = GenericItemCollection(companyId: companyId).document(genericItem.id)
         ref.updateData([
            "storeItems": DBArray
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }

    }
}
