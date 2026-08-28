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

    @discardableResult
    func addPurchasedItemsListener(
        companyId: String,
        startDate: Date,
        endDate: Date,
        onChange: @escaping (Result<[PurchasedItem], Error>) -> Void
    ) -> ListenerRegistration {
        PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    onChange(.success([]))
                    return
                }

                do {
                    let purchasedItems = try documents.map { document in
                        try document.data(as: PurchasedItem.self)
                    }
                    onChange(.success(purchasedItems))
                } catch {
                    onChange(.failure(error))
                }
            }
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

        if techIds.isEmpty {
            return try await PurchaseItemCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate)
                .whereField("date", isLessThan: endDate)
                .order(by: "date", descending: descending)
                .getDocuments(as:PurchasedItem.self)
        } else {
            return try await PurchaseItemCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate)
                .whereField("date", isLessThan: endDate)
                .order(by: "date", descending: descending)
                .whereField("techId", in: techIds)
                .getDocuments(as:PurchasedItem.self)
        }
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
            "workOrderId": workOrderId,
            "jobId": workOrderId,
            "assignedJobId": workOrderId,
            "assignedToJob": true,
            "assignmentStatus": "assignedToJob",
            "billingOwner": "job",
            "jobBillingStatus": "handledByJob",
            "jobBillable": currentItem.isJobBillable,
            "jobBillingRate": currentItem.jobMaterialBillingRate
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

enum PurchasedItemWorkflowError: LocalizedError {
    case invalidSplitQuantity
    case missingPurchaseId

    var errorDescription: String? {
        switch self {
        case .invalidSplitQuantity:
            return "Enter a split quantity greater than 0 and less than the purchased quantity."
        case .missingPurchaseId:
            return "This purchase is missing an id."
        }
    }
}

final class PurchasedItemWorkflowService {
    static let shared = PurchasedItemWorkflowService()

    private let db = Firestore.firestore()

    private init() {}

    func markReturnedAndDetach(
        purchase: PurchasedItem,
        companyId: String,
        actorId: String,
        actorName: String
    ) async throws {
        guard !purchase.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PurchasedItemWorkflowError.missingPurchaseId
        }

        let now = Timestamp(date: Date())
        let linkedJobIds = try await jobIdsLinkedToPurchase(purchase, companyId: companyId)
        let linkedShoppingItemIds = try await shoppingItemIdsLinkedToPurchase(purchase, companyId: companyId)

        var purchaseUpdates: [String: Any] = [
            "returned": true,
            "returnedAt": now,
            "returnedByUserId": actorId,
            "returnedByUserName": actorName,
            "status": "Returned",
            "jobId": "",
            "assignedToJob": false,
            "assignmentStatus": "returned",
            "jobBillingStatus": "returned",
            "updatedAt": now
        ]

        [
            "shoppingListItemId",
            "workOrderId",
            "assignedJobId",
            "billingOwner",
            "jobInternalId",
            "jobName",
            "installationJobId",
            "installationTaskId",
            "installedEquipmentId",
            "installedAt"
        ].forEach { field in
            purchaseUpdates[field] = FieldValue.delete()
        }

        try await purchaseDocument(companyId: companyId, purchaseId: purchase.id)
            .updateData(purchaseUpdates)

        for shoppingItemId in linkedShoppingItemIds {
            try? await shoppingDocument(companyId: companyId, shoppingItemId: shoppingItemId)
                .updateData([
                    "purchasedItem": FieldValue.delete(),
                    "status": ShoppingListStatus.needToPurchase.rawValue,
                    "datePurchased": FieldValue.delete(),
                    "invoiced": false,
                    "needsAction": true,
                    "actionDate": now,
                    "updatedAt": now
                ])
        }

        for jobId in linkedJobIds {
            try? await workOrderDocument(companyId: companyId, jobId: jobId)
                .updateData([
                    "purchasedItemsIds": FieldValue.arrayRemove([purchase.id]),
                    "updatedAt": now
                ])

            try? await clearTaskPurchaseLinks(companyId: companyId, jobId: jobId, purchaseId: purchase.id, timestamp: now)
        }

        let changes = [
            historyChange("Returned", from: yesNo(purchase.returned == true), to: "Yes"),
            historyChange("Status", from: purchase.status ?? "", to: "Returned"),
            linkedShoppingItemIds.isEmpty ? nil : historyChange("Shopping List", from: "Connected", to: "Disconnected"),
            linkedJobIds.isEmpty ? nil : historyChange("Job", from: "Connected", to: "Disconnected")
        ].compactMap { $0 }

        try await recordHistory(
            companyId: companyId,
            purchaseId: purchase.id,
            actorId: actorId,
            actorName: actorName,
            title: "Purchase marked returned",
            eventType: "returned",
            changes: changes
        )
    }

    func markPersonalAndDetach(
        purchase: PurchasedItem,
        companyId: String,
        actorId: String,
        actorName: String
    ) async throws {
        guard !purchase.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PurchasedItemWorkflowError.missingPurchaseId
        }

        let now = Timestamp(date: Date())
        let linkedJobIds = try await jobIdsLinkedToPurchase(purchase, companyId: companyId)
        let linkedShoppingItemIds = try await shoppingItemIdsLinkedToPurchase(purchase, companyId: companyId)

        var purchaseUpdates: [String: Any] = [
            "billable": false,
            "invoiced": false,
            "returned": false,
            "personalPurchase": true,
            "personalPurchaseAssignedAt": now,
            "personalPurchaseAssignedByUserId": actorId,
            "personalPurchaseAssignedByUserName": actorName,
            "status": "Personal Purchase",
            "customerId": "",
            "customerName": "",
            "jobId": "",
            "assignedToJob": false,
            "assignmentStatus": "personal",
            "billingOwner": "personal",
            "jobBillingStatus": "personal",
            "jobBillable": false,
            "jobBillingRate": 0,
            "updatedAt": now
        ]

        [
            "shoppingListItemId",
            "workOrderId",
            "assignedJobId",
            "jobInternalId",
            "jobName",
            "invoiceStatus",
            "invoiceId",
            "invoiceRef",
            "invoiceType",
            "invoicedAt",
            "jobInvoicedAt",
            "installationJobId",
            "installationTaskId",
            "installedEquipmentId",
            "installedAt"
        ].forEach { field in
            purchaseUpdates[field] = FieldValue.delete()
        }

        try await purchaseDocument(companyId: companyId, purchaseId: purchase.id)
            .updateData(purchaseUpdates)

        for shoppingItemId in linkedShoppingItemIds {
            try? await shoppingDocument(companyId: companyId, shoppingItemId: shoppingItemId)
                .updateData([
                    "purchasedItem": FieldValue.delete(),
                    "status": ShoppingListStatus.needToPurchase.rawValue,
                    "datePurchased": FieldValue.delete(),
                    "invoiced": false,
                    "needsAction": true,
                    "actionDate": now,
                    "updatedAt": now
                ])
        }

        for jobId in linkedJobIds {
            try? await workOrderDocument(companyId: companyId, jobId: jobId)
                .updateData([
                    "purchasedItemsIds": FieldValue.arrayRemove([purchase.id]),
                    "updatedAt": now
                ])

            try? await clearTaskPurchaseLinks(companyId: companyId, jobId: jobId, purchaseId: purchase.id, timestamp: now)
        }

        let changes = [
            historyChange("Personal Purchase", from: "No", to: "Yes"),
            historyChange("Status", from: purchase.status ?? "", to: "Personal Purchase"),
            historyChange("Billable", from: yesNo(purchase.billable), to: "No"),
            historyChange("Invoiced", from: yesNo(purchase.invoiced), to: "No"),
            historyChange("Customer", from: purchase.customerName, to: ""),
            linkedShoppingItemIds.isEmpty ? nil : historyChange("Shopping List", from: "Connected", to: "Disconnected"),
            linkedJobIds.isEmpty ? nil : historyChange("Job", from: "Connected", to: "Disconnected")
        ].compactMap { $0 }

        try await recordHistory(
            companyId: companyId,
            purchaseId: purchase.id,
            actorId: actorId,
            actorName: actorName,
            title: "Purchase marked personal",
            eventType: "personal_purchase",
            changes: changes
        )
    }

    @discardableResult
    func splitPurchase(
        purchase: PurchasedItem,
        companyId: String,
        splitQuantity: Double,
        customer: Customer?,
        job: Job?,
        notes: String,
        actorId: String,
        actorName: String
    ) async throws -> PurchasedItem {
        guard !purchase.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PurchasedItemWorkflowError.missingPurchaseId
        }

        let originalQuantity = purchase.quantity
        guard splitQuantity > 0, splitQuantity < originalQuantity else {
            throw PurchasedItemWorkflowError.invalidSplitQuantity
        }

        let remainingQuantity = originalQuantity - splitQuantity
        let nowDate = Date()
        let now = Timestamp(date: nowDate)
        let splitPurchaseId = UUID().uuidString
        let selectedCustomerName = customer.map(customerDisplayName) ?? ""
        let jobCustomerName = job?.customerName ?? ""
        let nextCustomerId = firstNonEmpty(customer?.id ?? "", job?.customerId ?? "")
        let nextCustomerName = firstNonEmpty(selectedCustomerName, jobCustomerName)

        var splitPurchase = purchase
        splitPurchase.id = splitPurchaseId
        splitPurchase.quantityString = formattedQuantity(splitQuantity)
        splitPurchase.customerId = nextCustomerId
        splitPurchase.customerName = nextCustomerName
        splitPurchase.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? purchase.notes : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        splitPurchase.shoppingListItemId = nil
        splitPurchase.returned = false
        splitPurchase.invoiced = false
        splitPurchase.status = job == nil ? "Split" : "Connected to Job"
        splitPurchase.workOrderId = nil
        splitPurchase.assignedJobId = nil
        splitPurchase.assignedToJob = false
        splitPurchase.assignmentStatus = "split"
        splitPurchase.billingOwner = nil
        splitPurchase.jobBillingStatus = nil
        splitPurchase.jobInternalId = nil
        splitPurchase.jobName = nil
        splitPurchase.installationJobId = nil
        splitPurchase.installationTaskId = nil
        splitPurchase.installedEquipmentId = nil
        splitPurchase.installedAt = nil

        if let job {
            let shouldMarkInvoiced = job.billingStatus == .invoiced || job.billingStatus == .paid
            splitPurchase.jobId = job.id
            splitPurchase.workOrderId = job.id
            splitPurchase.assignedJobId = job.id
            splitPurchase.assignedToJob = true
            splitPurchase.assignmentStatus = "assignedToJob"
            splitPurchase.billingOwner = "job"
            splitPurchase.jobBillingStatus = shouldMarkInvoiced ? "invoiced" : "handledByJob"
            splitPurchase.jobInternalId = job.internalId
            splitPurchase.jobName = job.type
            splitPurchase.status = shouldMarkInvoiced ? "Invoiced" : "Connected to Job"
            splitPurchase.invoiced = shouldMarkInvoiced
        } else {
            splitPurchase.jobId = ""
        }

        try purchaseDocument(companyId: companyId, purchaseId: splitPurchase.id)
            .setData(from: splitPurchase, merge: false)

        try await purchaseDocument(companyId: companyId, purchaseId: splitPurchase.id)
            .setData([
                "splitFromPurchasedItemId": purchase.id,
                "splitRootPurchasedItemId": purchase.id,
                "splitCreatedAt": now,
                "splitCreatedByUserId": actorId,
                "splitCreatedByUserName": actorName,
                "createdAt": now,
                "updatedAt": now
            ], merge: true)

        try await purchaseDocument(companyId: companyId, purchaseId: purchase.id)
            .updateData([
                "quantityString": formattedQuantity(remainingQuantity),
                "splitChildPurchasedItemIds": FieldValue.arrayUnion([splitPurchase.id]),
                "lastSplitAt": now,
                "updatedAt": now
            ])

        if !purchase.receiptId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try? await receiptDocument(companyId: companyId, receiptId: purchase.receiptId)
                .updateData([
                    "purchasedItemIds": FieldValue.arrayUnion([splitPurchase.id]),
                    "numberOfItems": FieldValue.increment(Int64(1)),
                    "updatedAt": now
                ])
        }

        if let job {
            try? await workOrderDocument(companyId: companyId, jobId: job.id)
                .updateData([
                    "purchasedItemsIds": FieldValue.arrayUnion([splitPurchase.id]),
                    "updatedAt": now
                ])
        }

        try await recordHistory(
            companyId: companyId,
            purchaseId: purchase.id,
            actorId: actorId,
            actorName: actorName,
            title: "Purchase split",
            eventType: "split",
            changes: [
                historyChange("Quantity", from: formattedQuantity(originalQuantity), to: formattedQuantity(remainingQuantity)),
                historyChange("Split Quantity", from: "Blank", to: formattedQuantity(splitQuantity)),
                historyChange("New Purchase", from: "Blank", to: splitPurchase.id)
            ].compactMap { $0 }
        )

        try await recordHistory(
            companyId: companyId,
            purchaseId: splitPurchase.id,
            actorId: actorId,
            actorName: actorName,
            title: "Purchase created from split",
            eventType: "split_created",
            changes: [
                historyChange("Source Purchase", from: "Blank", to: purchase.id),
                historyChange("Quantity", from: "Blank", to: formattedQuantity(splitQuantity)),
                historyChange("Customer", from: "Blank", to: nextCustomerName),
                historyChange("Job", from: "Blank", to: jobLabel(job))
            ].compactMap { $0 }
        )

        return splitPurchase
    }

    private func jobIdsLinkedToPurchase(_ purchase: PurchasedItem, companyId: String) async throws -> Set<String> {
        var jobIds = Set([
            purchase.jobId,
            purchase.workOrderId ?? "",
            purchase.assignedJobId ?? "",
            purchase.installationJobId ?? ""
        ].map(clean).filter { !$0.isEmpty })

        let snapshot = try await workOrderCollection(companyId: companyId)
            .whereField("purchasedItemsIds", arrayContains: purchase.id)
            .getDocuments()

        for document in snapshot.documents {
            jobIds.insert(document.documentID)
        }

        return jobIds
    }

    private func shoppingItemIdsLinkedToPurchase(_ purchase: PurchasedItem, companyId: String) async throws -> Set<String> {
        var shoppingItemIds = Set([
            purchase.shoppingListItemId ?? ""
        ].map(clean).filter { !$0.isEmpty })

        let snapshot = try await shoppingCollection(companyId: companyId)
            .whereField("purchasedItem", isEqualTo: purchase.id)
            .getDocuments()

        for document in snapshot.documents {
            shoppingItemIds.insert(document.documentID)
        }

        return shoppingItemIds
    }

    private func clearTaskPurchaseLinks(
        companyId: String,
        jobId: String,
        purchaseId: String,
        timestamp: Timestamp
    ) async throws {
        let snapshot = try await workOrderDocument(companyId: companyId, jobId: jobId)
            .collection("tasks")
            .whereField("purchasedItemId", isEqualTo: purchaseId)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.updateData([
                "purchasedItemId": FieldValue.delete(),
                "updatedAt": timestamp
            ])
        }
    }

    private func recordHistory(
        companyId: String,
        purchaseId: String,
        actorId: String,
        actorName: String,
        title: String,
        eventType: String,
        changes: [String]
    ) async throws {
        guard !changes.isEmpty else { return }

        let now = Timestamp(date: Date())
        let historyId = UUID().uuidString
        let purchaseRef = purchaseDocument(companyId: companyId, purchaseId: purchaseId)
        let cleanActorName = actorName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayActorName = cleanActorName.isEmpty ? "DripDrop" : cleanActorName

        try await purchaseRef.collection("history").document(historyId).setData([
            "id": historyId,
            "date": now,
            "tech": displayActorName,
            "actorId": actorId,
            "actorName": displayActorName,
            "source": "purchase-workflow",
            "eventType": eventType,
            "title": title,
            "changes": changes,
            "createdAt": now
        ])

        try await purchaseRef.updateData([
            "lastHistoryEventId": historyId,
            "lastHistoryEventTitle": title,
            "lastHistoryEventType": eventType,
            "lastHistoryEventAt": now,
            "updatedAt": now
        ])
    }

    private func purchaseDocument(companyId: String, purchaseId: String) -> DocumentReference {
        purchaseCollection(companyId: companyId).document(purchaseId)
    }

    private func purchaseCollection(companyId: String) -> CollectionReference {
        db.collection("companies").document(companyId).collection("purchasedItems")
    }

    private func shoppingDocument(companyId: String, shoppingItemId: String) -> DocumentReference {
        shoppingCollection(companyId: companyId).document(shoppingItemId)
    }

    private func shoppingCollection(companyId: String) -> CollectionReference {
        db.collection("companies").document(companyId).collection("shoppingList")
    }

    private func workOrderDocument(companyId: String, jobId: String) -> DocumentReference {
        workOrderCollection(companyId: companyId).document(jobId)
    }

    private func workOrderCollection(companyId: String) -> CollectionReference {
        db.collection("companies").document(companyId).collection("workOrders")
    }

    private func receiptDocument(companyId: String, receiptId: String) -> DocumentReference {
        db.collection("companies").document(companyId).collection("receipts").document(receiptId)
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func firstNonEmpty(_ values: String...) -> String {
        for value in values {
            let cleanValue = clean(value)
            if !cleanValue.isEmpty {
                return cleanValue
            }
        }

        return ""
    }

    private func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany {
            return firstNonEmpty(customer.company ?? "", "\(customer.firstName) \(customer.lastName)")
        }

        return firstNonEmpty("\(customer.firstName) \(customer.lastName)", customer.company ?? "")
    }

    private func jobLabel(_ job: Job?) -> String {
        guard let job else { return "" }
        return firstNonEmpty(job.internalId, job.type, job.id)
    }

    private func historyChange(_ label: String, from previousValue: String, to nextValue: String) -> String? {
        let previous = compactHistoryValue(previousValue)
        let next = compactHistoryValue(nextValue)
        guard previous != next else { return nil }
        return "\(label): \(previous) -> \(next)"
    }

    private func compactHistoryValue(_ value: String) -> String {
        let cleanValue = clean(value)
        guard !cleanValue.isEmpty else { return "Blank" }
        guard cleanValue.count > 140 else { return cleanValue }
        return "\(String(cleanValue.prefix(137)))..."
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func formattedQuantity(_ quantity: Double) -> String {
        if quantity.rounded() == quantity {
            return String(Int(quantity))
        }

        return String(format: "%.3f", quantity)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}
