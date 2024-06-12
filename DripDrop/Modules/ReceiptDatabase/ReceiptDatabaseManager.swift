//
//  DatabaseManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    private init(){}
    private var dataBaseListener: ListenerRegistration? = nil

    private func DataBaseCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/dataBase/dataBase")
    }

    
    private func DataBaseDocument(dataBaseId:String,companyId:String)-> DocumentReference{
        DataBaseCollection(companyId: companyId).document(dataBaseId)
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func uploadDataBaseItem(companyId:String,dataBaseItem : DataBaseItem) async throws {

    try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
}
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getAllDataBaseItems(companyId:String) async throws -> [DataBaseItem]{

        return try await DataBaseCollection(companyId: companyId)
            .getDocuments(as:DataBaseItem.self)

    }
    func getCommonDataBaseItems(companyId:String) async throws -> [DataBaseItem]{

        return try await DataBaseCollection(companyId: companyId)
            .order(by: "timesPurchased", descending: true)
            .limit(to: 5)
            .getDocuments(as:DataBaseItem.self)

    }
    func getAllDataBaseItemsByName(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (dataBase:[DataBaseItem],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            let snap = try await DataBaseCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:DataBaseItem.self)
            return (dataBase:snap.serviceStops,lastDocument:snap.lastDocument)

        } else {
            let snap = try await DataBaseCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:DataBaseItem.self)
            return (dataBase:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    func getDataBaseItemByCategory(companyId: String,category:String) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:DataBaseItem.self)

    }
    func getDataBaseItemByVender(companyId: String,venderId:String) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:DataBaseItem.self)
    }
    func getDataBaseItemByVenderItemTotal(companyId: String,venderId:String) async throws -> Int {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:DataBaseItem.self).count
    }
    func getDataBaseItemByCategoryAndSubCategory(companyId: String,category:String,subCategory:DataBaseSubCategories) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .whereField("subCategory", isEqualTo:subCategory.name)
            .getDocuments(as:DataBaseItem.self)

    }
    func editDataBaseItem(
        companyId:String,
        dataBaseItemId:String,
        name:String,
        rate:Double,
        storeName:String,
        storeId:String,
        category:DataBaseItemCategory,
        subCategory:DataBaseItemSubCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        UOM:UnitOfMeasurment
    ) async throws {
        let dataBaseItem = DataBaseItem(id: dataBaseItemId, name: name, rate: rate, storeName: storeName, venderId: storeId, category: category, subCategory:subCategory,description: description, dateUpdated: Date(), sku: sku, billable: billable, color: color, size: size,UOM:UOM)
        try DataBaseDocument(dataBaseId: dataBaseItemId,companyId: companyId).setData(from:dataBaseItem, merge: true)
    }
    func uploadDataBaseItemWithUser(dataBaseItem : DataBaseItem,companyId:String) async throws {

        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
    }

    func getAllDataBaseItemsByCategory(companyId:String,category:String) async throws -> [DataBaseItem]{

        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:DataBaseItem.self)

    }
    func get25DataBaseItems(companyId:String) async throws -> [DataBaseItem]{

        return try await DataBaseCollection(companyId: companyId)
            .limit(to:25)
            .getDocuments(as:DataBaseItem.self)

    }
    
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [DataBaseItem]{
        return try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .getDocuments(as:DataBaseItem.self)

    }
    func getItemsFromDataBaseBySearchTermAndStoreId(companyId:String,storeId:String,searchTerm:String) async throws -> [DataBaseItem]{
        var DatabaseItemList:[DataBaseItem] = []

        let DatabaseItemListByName =  try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .whereField("name", isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:DataBaseItem.self)
        print(DatabaseItemListByName)
        let DatabaseItemListBySKU =  try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .whereField("sku", isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:DataBaseItem.self)
        print(DatabaseItemListBySKU)

        DatabaseItemList = DatabaseItemListBySKU + DatabaseItemListByName
        let uniqueList = Array(Set(DatabaseItemList))

        print(uniqueList)
        return uniqueList

    }
    func getDataBaseItem(companyId:String,dataBaseItemId:String) async throws -> DataBaseItem{
        return try await DataBaseDocument(dataBaseId: dataBaseItemId, companyId: companyId).getDocument(as: DataBaseItem.self)
    }
    
    func updateDataBaseItemtimesPurchased(companyId:String,dataBaseItem:DataBaseItem) async throws {
        print("Trying to Update Data Base Item \(dataBaseItem.id)")
        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: true)
        print("Successfully Updated")
    }
    
    func getDataBaseItemsFromArrayOfIds(companyId:String,dataBaseIds:[String]) async throws -> [DataBaseItem]{
        var dataBaseItemList: [DataBaseItem] = []
        for id in dataBaseIds {
            try await dataBaseItemList.append(getDataBaseItem(companyId: companyId, dataBaseItemId: id))
        }
        return dataBaseItemList
    }
    func getallNonBillableTemplates(companyId:String) async throws -> [DataBaseItem]{

        return try await DataBaseCollection(companyId: companyId)
            .whereField("billable", isEqualTo: false)
            .getDocuments(as:DataBaseItem.self)

    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Editing the Database Items
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateDataBaseItem(
        dataBaseItem:DataBaseItem,
        companyId: String,
        name:String,
        rate:Double,
        category:DataBaseItemCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        sellPrice:Double,
        UOM:UnitOfMeasurment,
        subCategory:DataBaseItemSubCategory,
        tracking:String
    ) throws {
        let itemRef = DataBaseDocument(dataBaseId: dataBaseItem.id, companyId: companyId)
        // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            "name":name,
            "rate":rate,
            "category":category.rawValue,
            "description":description,
            "dateUpdated":Date(),
            "billable":billable,
            "color":color,
            "size":size,
            "sellPrice":sellPrice,
            "UOM":UOM.rawValue,
            "subCategory":subCategory.rawValue,
            "tracking":tracking,
            "sku":sku,

        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Listeners the Database Items
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func addListenerForAllCustomers(companyId:String,storeId:String,completion:@escaping (_ serviceStops:[DataBaseItem]) -> Void){
        
        let listener = DataBaseCollection(companyId: companyId)
            .whereField("storeId", isEqualTo: storeId)
            .order(by: "name",descending: false)
            .addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("There are no documents in the Customer Collection")
                return
            }
            let serviceStops: [DataBaseItem] = documents.compactMap({try? $0.data(as: DataBaseItem.self)})
            completion(serviceStops)
        }
        self.dataBaseListener = listener
    }
    
    func removeListenerForAllCustomers(){
        self.dataBaseListener?.remove()
    }

}






