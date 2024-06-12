//
//  ReceiptViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//

import Foundation
import Darwin
@MainActor
final class ReceiptViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var receiptItems: [Receipt] = []
    @Published private(set) var filteredReceipts: [Receipt] = []

    @Published private(set) var receipt: Receipt? = nil
    
    @Published private(set) var purchaseSummary: [PurchasedItemSummary] = []
    @Published private(set) var itemsPurchased: Int? = nil
    @Published private(set) var itemsPurchasedAndBilled: Int? = nil

    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func uploadFileTo(companyId:String,pathName:String,fileName:String,storeName:String,storeId:String) async{
        let fileURL = URL(fileURLWithPath: pathName).appendingPathExtension("csv")

        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            print("Successfully Read")
            let DbList = try await ReceiptManager.shared.convertDatabaseItemToCSVStruct(contents: text2)
            for DbItem in DbList {
                try await ReceiptManager.shared.uploadCSVDataBaseItemToFireStore(companyId:companyId,CSVItem: DbItem, storeId: storeId, storeName: storeName)
            }
            print("Completed Upload")

        }
        catch {
                     print("Unable to read the file")
        }
    }
    func addNewReceipt(companyId:String,receipt:Receipt,date:Date,lineItems:[LineItem]) async throws{
        print(receipt)
        //Adds all the line items inside of the receipt which are of type purchased item. to their own dayabase
        var totalCost:Double = 0
        var totalCostAfterTax:Double = 0
        var totalNumberOfItems:Int = 0
        var listOfPurchasedItems:[String] = []
        for item in lineItems {
            //get the info from the database about the item ID
            let dbItem = try await DatabaseManager.shared.getDataBaseItem(companyId:companyId,dataBaseItemId: item.itemId)
                let purchaseItemId = UUID().uuidString
            var pushItem = PurchasedItem(id: purchaseItemId,
                                         receiptId: receipt.id,
                                         invoiceNum: receipt.invoiceNum!,
                                         venderId: receipt.storeId!,
                                         venderName: receipt.storeName!,
                                         techId: receipt.techId!,
                                         techName: receipt.tech!,
                                         itemId: item.itemId,
                                         name: dbItem.name,
                                         price: Double(dbItem.rate),
                                         quantityString: item.quantityString,
                                         date: receipt.date ?? Date(),
                                         billable: item.billable,
                                         invoiced: item.invoiced,
                                         customerId: "",
                                         customerName: "",
                                         sku: item.sku,
                                         notes: item.notes,
                                         jobId: "",
                                         billingRate: item.sellPrice)
            
            totalCost = totalCost + Double(dbItem.rate)
            listOfPurchasedItems.append(purchaseItemId)
            totalNumberOfItems = totalNumberOfItems + 1
            let timesPurchased:Int = dbItem.timesPurchased ?? 0
            let quantity:Int = Int(item.quantityString) ?? 0
            let newTimesPurcahsed = timesPurchased + quantity

            print("New timesPurchased \(newTimesPurcahsed)")
            let newItem:DataBaseItem = DataBaseItem(
                id: dbItem.id,
                name: dbItem.name,
                rate: dbItem.rate,
                storeName: dbItem.storeName,
                venderId: dbItem.venderId,
                category: dbItem.category,
                subCategory: dbItem.subCategory,
                description: dbItem.description,
                dateUpdated: dbItem.dateUpdated,
                sku: dbItem.sku,
                billable: dbItem.billable,
                color: dbItem.color,
                size: dbItem.size,
                UOM: dbItem.UOM,
                tracking: dbItem.tracking,
                sellPrice: dbItem.sellPrice,
                timesPurchased: newTimesPurcahsed
            )
            try await DatabaseManager.shared.updateDataBaseItemtimesPurchased(companyId: companyId, dataBaseItem: newItem)
            try await PurchasedItemsManager.shared.uploadPurchaseItem(companyId: companyId, purchaseItem: pushItem)

        }
        totalCostAfterTax = totalCost * 1.085
        try await ReceiptManager.shared.uploadReceipt(companyId: companyId,receiptItem: Receipt(id: receipt.id,
                                                                                     invoiceNum: receipt.invoiceNum,
                                                                                     date: receipt.date,
                                                                                     storeId: receipt.storeId,
                                                                                     storeName: receipt.storeName,
                                                                                     tech: receipt.tech,
                                                                                     techId: receipt.techId,
                                                                                     purchasedItemIds: listOfPurchasedItems,
                                                                                     numberOfItems: totalNumberOfItems,
                                                                                     cost: totalCost,
                                                                                     costAfterTax: totalCostAfterTax)
        )
        print("Uploaded Receipt as line Items")
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getAllReceipts(companyId: String) async throws{
//        self.receiptItems = try await ReceiptManager.shared.getAllReceiptItems()
        self.receiptItems = try await ReceiptManager.shared.getAllReceipts(companyId: companyId)

    }
    func getAllBillableReceipts(startDate:Date,endDate:Date,viewBillable:Bool) async throws{
//        self.receiptItems = try await ReceiptManager.shared.getAllReceiptItems()
//        self.receiptItems = try await PurchasedItemsManager.shared.getAllBillableReceipts(startDate: startDate, endDate: endDate,viewBillable: viewBillable)

    }
    func getallReceiptsLast30Days(startDate:Date,endDate:Date,viewBillable:Bool) async throws{
//        self.receiptItems = try await ReceiptManager.shared.getAllReceiptItems()
//        self.receiptItems = try await PurchasedItemsManager.shared.getallReceiptsLast30Days(startDate: startDate, endDate: endDate,viewBillable: viewBillable)

    }
    func getAllpurchasedItemsByTechSummary(techId: String) async throws{
//        let items = try await PurchasedItemsManager.shared.getAllpurchasedItemsByTech(techId: techId)
//        self.receiptItems = items
//        var purchasedItemSummary: [PurchasedItemSummary] = []
//        var uniqueItems:[String] = []
//        for item in items {
//            uniqueItems.append(item.sku)
//
//        }
//        uniqueItems.removeDuplicates()
//        print("Unique Itmes")
//        print(uniqueItems)
//
//        for uniqueItem in uniqueItems {
//            var quantity:Double = 0.00
//            var itemName:String = ""
//            var rate:Double = 0
//
//            for item in items {
//                if item.sku == uniqueItem {
//                    quantity = item.quantity + quantity
//                    itemName = item.name
//                    rate = item.price
//
//                }
//            }
//            let purchasedItem = PurchasedItemSummary(id: UUID().uuidString, purchasedItemId: uniqueItem, purchasedItemName: itemName, purchasedItemRate: rate, quantityPurchased: quantity)
//
//            purchasedItemSummary.append(purchasedItem)
//        }
//
//        self.purchaseSummary = purchasedItemSummary
//
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func filterReceipts(filter:String,purchases:[Receipt]){
        var list:[Receipt] = []
        self.filteredReceipts = list
    }

}
