//
//  ReceiptManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/31/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ReceiptManager {
    
    static let shared = ReceiptManager()
    private init(){}
    
    //-------------------------------------------------
    //                      COLLECTIONS
    //-------------------------------------------------
    private func ReceiptItemCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/receipts")
    }

    //-------------------------------------------------
    //                      DOCUMENTS
    //-------------------------------------------------
    private func ReceiptItemDocument(receiptItemId:String,companyId:String)-> DocumentReference{
        ReceiptItemCollection(companyId: companyId).document(receiptItemId)
        
    }
    
    //-------------------------------------------------
    //                      CREATE
    //-------------------------------------------------
    //-------------------------------------------------
    //                      READ
    //-------------------------------------------------
    //-------------------------------------------------
    //                      UPDATE
    //-------------------------------------------------
    func updateReceiptPDFPath(companyId: String,receiptItemId:String,path:String) throws {
        
        let ref = ReceiptItemDocument(receiptItemId: receiptItemId, companyId: companyId)
        
         ref.updateData([
            Receipt.CodingKeys.pdfUrlList.rawValue: FieldValue.arrayUnion([path])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }
    //-------------------------------------------------
    //                      DELETE
    //-------------------------------------------------

    //-------------------------------------------------
    //                      FUNCTIONS
    //-------------------------------------------------


    func uploadCSVDataBaseItemToFireStore(companyId:String,CSVItem: CSVDataBaseItem,storeId:String,storeName:String) async throws{
        let identification:String = UUID().uuidString
        var boolToken:Bool = true
        if CSVItem.billable == "NB" {
            boolToken = false
        } else if CSVItem.billable == "B" {
            boolToken = true
        } else {
            boolToken = true

        }
//DEVELOPER FIX
//        let DBItem:DataBaseItem = DataBaseItem(id: identification, name: CSVItem.name, rate: Double(CSVItem.rate) ?? 12.34, storeName: storeName, venderId:storeId, category: CSVItem.category, description: CSVItem.description, dateUpdated: Date(), sku: CSVItem.sku, billable: boolToken,color: CSVItem.color,size: CSVItem.size)
//        print(DBItem)
//        try await DatabaseManager.shared.uploadDataBaseItemWithUser(dataBaseItem: DBItem,companyId: companyId)
        
    }
    func convertDatabaseItemToCSVStruct(contents: String) async throws -> [CSVDataBaseItem]{
        var csvToStruct = [CSVDataBaseItem]()
        
        var rows = contents.components(separatedBy: "\n")
        rows.removeFirst()
        
        for row in rows {
            let CSVColumns = row.components(separatedBy: ",")
            let customerStruct = CSVDataBaseItem.init(raw: CSVColumns)
            print(customerStruct)
            csvToStruct.append(customerStruct)
        }
        
        
        print("Successfully Converted Database List")

        return csvToStruct

    }
    func uploadReceipt(companyId: String,receiptItem : Receipt) async throws {
        return try ReceiptItemDocument(receiptItemId: receiptItem.id, companyId: companyId).setData(from:receiptItem, merge: false)
    }
    
    func getAllReceipts(companyId: String) async throws -> [Receipt] {

        let snapshot = try await ReceiptItemCollection(companyId: companyId).getDocuments()
        
        var receiptItems: [Receipt] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: Receipt.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllpurchasedItemsByPrice(companyId:String,descending: Bool) async throws -> [Receipt]{

        return try await ReceiptItemCollection(companyId: companyId)
//            .order(by: "price", descending: descending)
            .getDocuments(as:Receipt.self)

    }


}
