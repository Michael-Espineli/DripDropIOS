//
//  PurchasedItemsManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/31/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

final class PurchasedItemsManager {
    
    static let shared = PurchasedItemsManager()
    private init(){}
    
    private func PurchaseItemCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/purchasedItems")
    }
    private func PurchaseItemDocument(purchaseItemId:String,companyId:String)-> DocumentReference{
        PurchaseItemCollection(companyId: companyId).document(purchaseItemId)
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func uploadPurchaseItem(companyId: String,purchaseItem : PurchasedItem) async throws {
        
        try PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData(from:purchaseItem, merge: false)
    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getPurchasesCountForTechId(companyId:String,userId:String) async throws ->Int {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!


        let count = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("techId", isEqualTo: userId)
            .whereField("billable", isEqualTo: true)
            .whereField("invoiced", isEqualTo: false)
            .whereField("customerId", isEqualTo: "")
            .count.getAggregation(source: .server).count
        return count as! Int

    }
    func GetPurchasesByDateSortByDate(companyId: String,start:Date,end:Date,dateHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .order(by: "date",descending: dateHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByDateSortByPrice(companyId: String,start:Date,end:Date,priceHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .order(by: "price",descending: priceHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillable(companyId: String,billable:Bool) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .limit(to: 100)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoiced(companyId: String,billable:Bool,invoiced:Bool) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .limit(to: 100)

            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndSortByPrice(companyId: String,billable:Bool,price:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "price",descending: price)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: String,billable:Bool,invoiced:Bool,price:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .order(by: "date",descending: true)
            .order(by: "price",descending: price)
            .whereField("techId", in: techIds)

            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndSortByDate(companyId: String,billable:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: String,billable:Bool,invoiced:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func getSingleItem(itemId:String,companyId: String) async throws -> PurchasedItem{
        return try await PurchaseItemDocument(purchaseItemId: itemId, companyId: companyId).getDocument(as: PurchasedItem.self)
    }

    func getItemsBasedOnDBItem(companyId: String,DataBaseItemSku:String) async throws -> [PurchasedItem] {
        let calendar = Calendar.current
        let previousMonth = calendar.date(byAdding: .month, value: -30, to: Date())!
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: previousMonth)
            .whereField("date", isLessThan: Date())
            .whereField("sku", isEqualTo: DataBaseItemSku)
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getallReceiptsLast30Days(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date", descending: true)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
//            .limit(to: 30)
//            .order(by: "invoiceNum")
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getallReceiptsLast30DaysBillable(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date", descending: true)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: viewBillable)
//            .limit(to: 30)
//            .order(by: "invoiceNum")
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllBillableReceipts(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: viewBillable)
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllReceiptItems(companyId: String) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId).getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllpurchasedItemsByPrice(companyId: String,descending: Bool,techIds:[String]) async throws -> [PurchasedItem]{
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!

        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: descending)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
        
    }
    func getAllpurchasedItemsByTech(companyId: String,techId: String) async throws -> [PurchasedItem]{
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllpurchasedItemsByVender(companyId: String,venderId:String) async throws -> [PurchasedItem]{
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllpurchasedItemsByTechAndDate(companyId: String,techId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem]{
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:PurchasedItem.self)
        
    }
    func getMostRecentPurchases(companyId:String,number:Int) async throws ->[PurchasedItem] {
        return try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date",descending: true)
            .limit(to:number)
            .getDocuments(as:PurchasedItem.self)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                  UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updatePurchaseItem(purchaseItem:PurchasedItem,companyId: String) throws   {
        
        // Add a new document in collection "cities"
        PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData([
            "workOrderId": "0"
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    func updateNotes(currentItem:PurchasedItem,notes:String,companyId: String) throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "notes":notes
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateBilling(currentItem:PurchasedItem,billingRate:Double,companyId: String) throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "billingRate":billingRate
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedItemBillingStatus(currentItem:PurchasedItem,newBillingStatus:Bool,companyId: String) throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            "invoiced":newBillingStatus
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedCustomer(currentItem:PurchasedItem,newCustomer:Customer,companyId: String) throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        let fullName = newCustomer.firstName + " " + newCustomer.lastName
        print(fullName)
        itemRef.updateData([
            "customerId":newCustomer.id,
            "customerName":fullName
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedWorkOrderId(currentItem:PurchasedItem,workOrderId:String,companyId: String) throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "jobId":workOrderId
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Counting the PurchasedItems
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getNumberOfItemsPurchasedIn30Days(companyId: String) async throws->(total:Double,totalBillable:Double,Invoiced:Double,TotalSpent:Double,totalSoldInDollars:Double,TotalSpentBillable:Double,TotalBilled:Double,NonBillableList:[PurchasedItem]){

        let calendar = Calendar(identifier: .gregorian)
        let endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!

        let nonBillableList = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: false)
            .getDocuments(as:PurchasedItem.self)
        let list = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: true)
            .getDocuments(as:PurchasedItem.self)
        var countOfInvoiced:Double = 0
        var countOfTotalBillable:Double = 0
        var costOfTotal:Double = 0
        var counterOfTotalBilled:Double = 0
        var totalProfitDolalrsOfBillable:Double = 0


        for item in list {
            if item.invoiced{
                countOfInvoiced = countOfInvoiced + 1
                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
            }
            totalProfitDolalrsOfBillable = (item.billingRate ?? 0) + totalProfitDolalrsOfBillable
            countOfTotalBillable = item.totalAfterTax + countOfTotalBillable
        }

        for item in nonBillableList {
            if item.invoiced{
                countOfInvoiced = countOfInvoiced + 1
                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
            }
            costOfTotal = item.totalAfterTax + costOfTotal
        }
        let twoLists = list.count + nonBillableList.count
        let totalBillabledAndNonBillable = countOfTotalBillable + costOfTotal
        let twoItemList = nonBillableList + list
        var total:Double = 0
        var i = 30
        while i > 1 {
            var billableCount:Double = 0
            var nonbillableCount:Double = 0
            let adding = i * -1
            let initalDate = Calendar.current.date(byAdding: .day, value: adding, to: Date())!
            let startDate = initalDate.startOfDay()
            let endDate = initalDate.endOfDay()
            for item in twoItemList {
                if item.billable == false {

                    if item.date > startDate && item.date < endDate {
                        nonbillableCount = nonbillableCount + item.totalAfterTax
                    }
                }
                if item.billable == true {
                    if item.date > startDate && item.date < endDate {
                        billableCount = billableCount + item.totalAfterTax
                    }
                }
            }
            let both = billableCount + nonbillableCount
            total = total + both

            i = i - 1
        }

        return (total:Double(twoLists),
                totalBillable:Double(list.count),
                Invoiced:countOfInvoiced,
                TotalSpent:totalBillabledAndNonBillable,
                totalSoldInDollars:totalProfitDolalrsOfBillable,
                TotalSpentBillable:countOfTotalBillable,
                TotalBilled:counterOfTotalBilled,
                NonBillableList:nonBillableList)
    }
    
    
//    func getNumberOfItemsPurchasedIn30DaysPrior(companyId: String) async throws->(total:Double,totalBillable:Double,Invoiced:Double,TotalSpent:Double,totalSoldInDollars:Double,TotalSpentBillable:Double,TotalBilled:Double,NonBillableList:[PurchasedItem],purchasedItemsChart:[customerChartSeriesData]){
//
//        let calendar = Calendar(identifier: .gregorian)
//        var purchasedItemsChart:[customerChartSeriesData] = []
//        var endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
//        endDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
//
//        let startDate = calendar.date(byAdding: .month, value: -2, to: endDate)!
//        let nonBillableList = try await ReceiptItemCollection(companyId: user.companyId)
//            .whereField("date", isGreaterThan: startDate)
//            .whereField("date", isLessThan: endDate)
//            .whereField("billable", isEqualTo: false)
//            .getDocuments(as:PurchasedItem.self)
//
//        let list = try await ReceiptItemCollection(companyId: user.companyId)
//            .whereField("date", isGreaterThan: startDate)
//            .whereField("date", isLessThan: endDate)
//            .whereField("billable", isEqualTo: true)
//            .getDocuments(as:PurchasedItem.self)
//        var countOfInvoiced:Double = 0
//        var countOfTotalBillable:Double = 0
//        var costOfTotal:Double = 0
//        var counterOfTotalBilled:Double = 0
//        var totalProfitDolalrsOfBillable:Double = 0
//
//
//        for item in list {
//            if item.invoiced{
//                countOfInvoiced = countOfInvoiced + 1
//                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
//            }
//            totalProfitDolalrsOfBillable = (item.billingRate ?? 0) + totalProfitDolalrsOfBillable
//            countOfTotalBillable = item.totalAfterTax + countOfTotalBillable
//        }
//
//        for item in nonBillableList {
//            if item.invoiced{
//                countOfInvoiced = countOfInvoiced + 1
//                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
//            }
//            costOfTotal = item.totalAfterTax + costOfTotal
//        }
//        let twoLists = list.count + nonBillableList.count
//        let totalBillabledAndNonBillable = countOfTotalBillable + costOfTotal
//        let twoItemList = nonBillableList + list
//
//        var billableChartList:[customerDateSummary] = []
//        var nonBillableChartList:[customerDateSummary] = []
//        var totalChartList:[customerDateSummary] = []
//        var bothChartList:[customerDateSummary] = []
//
//        var total:Double = 0
//        var i = 30
//        while i > 1 {
//            var billableCount:Double = 0
//            var nonbillableCount:Double = 0
//            let adding = i * -1
//            let initalDate = Calendar.current.date(byAdding: .day, value: adding, to:endDate)!
//            let startDate = initalDate.startOfDay()
//            let endDate = initalDate.endOfDay()
//            for item in twoItemList {
//                if item.billable == false {
//
//                    if item.date > startDate && item.date < endDate {
//                        nonbillableCount = nonbillableCount + item.totalAfterTax
//                    }
//                }
//                if item.billable == true {
//                    if item.date > startDate && item.date < endDate {
//                        billableCount = billableCount + item.totalAfterTax
//                    }
//                }
//            }
//            let both = billableCount + nonbillableCount
//            total = total + both
//            billableChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: billableCount))
//            nonBillableChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: nonbillableCount))
//            totalChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: total))
//            bothChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: both))
//
//            i = i - 1
//        }
//        purchasedItemsChart = [
//            customerChartSeriesData(id:UUID().uuidString,type: "Both", data: bothChartList),
//            customerChartSeriesData(id:UUID().uuidString,type: "Billable", data: billableChartList),
//            customerChartSeriesData(id:UUID().uuidString,type: "Non Billable", data: nonBillableChartList),
//            customerChartSeriesData(id:UUID().uuidString,type: "Total", data: totalChartList)
//        ]
//        return (total:Double(twoLists),
//                totalBillable:Double(list.count),
//                Invoiced:countOfInvoiced,
//                TotalSpent:totalBillabledAndNonBillable,
//                totalSoldInDollars:totalProfitDolalrsOfBillable,
//                TotalSpentBillable:countOfTotalBillable,
//                TotalBilled:counterOfTotalBilled,
//                NonBillableList:nonBillableList,
//                purchasedItemsChart:purchasedItemsChart)
//    }
    func getNumberOfItemsPurchasedAndBilledIn30Days(companyId: String) async throws -> Double{
        let calendar = Calendar(identifier: .gregorian)

        let endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!

        let query = PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: true)
            .whereField("invoiced", isEqualTo: true)

        let countQuery = query.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return Double(truncating: snapshot.count)

        } catch {
            print(error)
            return 0
        }
    }
}
