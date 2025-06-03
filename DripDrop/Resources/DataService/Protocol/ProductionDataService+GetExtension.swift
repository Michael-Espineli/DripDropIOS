//
//  ProductionDataService+GetExtension.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    //----------------------------------------------------
    //                    Read Functions
    //----------------------------------------------------
    func getEquipmentByBodyOfWaterId(companyId:String,bodyOfWaterId:String) async throws ->[Equipment] {
        return try await bodyOfWaterCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .getDocuments(as:Equipment.self)
    }
    func getEquipmentByServiceLocationId(companyId:String,serviceLocationId:String) async throws ->[Equipment] {
        print("getEquipmentByServiceLocationId - companyId: \(companyId) serviceLocationId:\(serviceLocationId) - [dataService]")
        let col = try await equipmentCollection(companyId: companyId)
            .whereField("serviceLocationId", isEqualTo: serviceLocationId)
            .getDocuments(as:Equipment.self)
        print("equipment \(col)")
        print("")
        return col
    }
    func getEquipmentByServiceLocationIdAndCategory(companyId:String,serviceLocationId:String,category:EquipmentCategory) async throws ->[Equipment] {
        print("getEquipmentByServiceLocationId - companyId: \(companyId) - serviceLocationId:\(serviceLocationId) - category \(category.rawValue)- [dataService]")
        let col = try await equipmentCollection(companyId: companyId)
            .whereField("serviceLocationId", isEqualTo: serviceLocationId)
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments(as:Equipment.self)
        print("equipment \(col)")
        print("")
        return col
    }

   

    func getEmailConfigurationSettings(companyId:String) async throws -> CompanyEmailConfiguration {
        
        return try await CompanyEmailConfigurationDocument(companyId: companyId)
            .getDocument(as:CompanyEmailConfiguration.self)
    }
    func getCustomerEmailConfigurationSettings(companyId:String) async throws -> [CustomerEmailConfiguration] {
        return try await CompanyEmailConfigurationCollection(companyId: companyId)
            .getDocuments(as:CustomerEmailConfiguration.self)
    }
    func getCustomerEmailConfigurationSettingDocument(companyId:String,id:String) async throws -> CustomerEmailConfiguration {
        return try await CompanyEmailConfigurationCollection(companyId: companyId).document(id)
            .getDocument(as:CustomerEmailConfiguration.self)
    }

    func searchForUsers(searchTerm:String) async throws -> [DBUser] {
        var userList:[DBUser] = []

        if searchTerm.contains(" ") || searchTerm.count <= 10 {
            
            userList.append(contentsOf: try await userCollection()
                .whereField("firstName", isGreaterThanOrEqualTo: searchTerm)
                .limit(to: 5)
                .getDocuments(as:DBUser.self))
            
            userList.append(contentsOf: try await userCollection()
                .whereField("lastName", isGreaterThanOrEqualTo: searchTerm)
                .limit(to: 5)
                .getDocuments(as:DBUser.self))

        } else {
            userList = try await userCollection()
                .whereField("id", isEqualTo: searchTerm)
                .getDocuments(as:DBUser.self)
            userList.append(contentsOf: try await userCollection()
                .whereField("email", isGreaterThanOrEqualTo: searchTerm)
                .limit(to: 5)
                .getDocuments(as:DBUser.self))
        }
        return userList
    }
    func getPersonalAlertsCount(userId:String) async throws -> Int {
        return try await personalAlertCollection(userId: userId)
            .count.getAggregation(source: .server).count as! Int
    }
    func getPersonalAlerts(userId:String) async throws -> [DripDropAlert] {
        return try await personalAlertCollection(userId: userId)
            .order(by: "date", descending: true)
            .getDocuments(as:DripDropAlert.self)
    }
    func getDripDropAlertsCount(companyId:String) async throws -> Int {
        return try await alertCollection(companyId: companyId)
            .count.getAggregation(source: .server).count as! Int
    }
    func getDripDropAlerts(companyId:String) async throws -> [DripDropAlert] {
        return try await alertCollection(companyId: companyId)
            .order(by: "date", descending: true)
            .getDocuments(as:DripDropAlert.self)
    }

    

    func getTermsTemplate(companyId:String,termsTemplateId:String) async throws -> TermsTemplate{
        return try await termsTemplateDocument(companyId: companyId, templateId: termsTemplateId)
            .getDocument(as:TermsTemplate.self)
    }
    func getTermsTemplateList(companyId:String) async throws -> [TermsTemplate]{
        return try await termsTemplateCollection(companyId: companyId)
            .getDocuments(as:TermsTemplate.self)
    }
    func getTermsTemplateListByCategory(companyId:String,category:String) async throws -> [TermsTemplate]{
        return try await termsTemplateCollection(companyId: companyId)
            .getDocuments(as:TermsTemplate.self)
    }
    func getTermsByTermsTemplate(companyId:String,termsTemplateId:String) async throws-> [ContractTerms] {
        return try await termsCollection(companyId: companyId, termsTempalteId: termsTemplateId)
            .getDocuments(as:ContractTerms.self)
    }
    func getToDoCount(companyId:String) async throws -> Int {
        var toDoCount = 0
        let doc = try await Firestore.firestore().collection("companies/\(companyId)/settings").document("todos").getDocument(as: Increment.self)
        toDoCount = doc.increment
        let updatedServiceStopCount = toDoCount + 1
        try await Firestore.firestore().collection("companies/\(companyId)/settings").document("todos")
            .updateData([
                "increment": updatedServiceStopCount
            ])
        print("Service Stop Count " + String(toDoCount))
        return updatedServiceStopCount
    }
    nonisolated func getAllCompanyToDoItems(companyId:String) -> [ToDo]{
        return [
            ToDo(id: "1", title: "Check Harold Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "2", title: "Check hey Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "3", title: "Check yum Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "4", title: "Check the Dude Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: "")
        ]
        
    }
    nonisolated func getAllCompanyToDoItemsCount(companyId: String) -> Int {
        return 8
    }
    
    func getAllTechnicanToDoItemsCount(companyId: String, techId: String) async throws -> Int {
        //MEMORY LEAK
        let query = ToDoCollection(companyId: companyId).whereField("assignedTechId", isEqualTo: techId).whereField("status", isNotEqualTo: "Finished")
        let countQuery = query.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return snapshot.count as! Int
        } catch {
            print(error)
            return 0
        }
        //        return 0
    }
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]{
        return try await ToDoCollection(companyId: companyId)
            .whereField("assignedTechId", isEqualTo: techId)
            .getDocuments(as:ToDo.self)
        
    }
    func getCurrentUser(userId:String) async throws -> DBUser{
        //        let DBUser = try await DBUserManager.shared.loadCurrentUser()
        
        return try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    
    func getRecentActivityByUser(userId:String) async throws -> [RecentActivityModel]{
        return try await userRecentActivityCollection(userId: userId)
            .order(by: "date", descending: true)
            .limit(to: 8)
            .getDocuments(as:RecentActivityModel.self)
    }
    func getOneUser(userId:String) async throws -> DBUser{
        try await userDocument(userId: userId).getDocument(as: DBUser.self,decoder: decoder)
        //        try await userDocument(userId: userId).getDocument(as: DBUser.self)
        
    }
    //for some reason this does not work
    func getAllTechs() async throws ->[DBUser]{
        print("Get all techs")
        
        let techList = try await userCollection()
            .getDocuments(as:DBUser.self)
        print(techList)
        return techList
    }
    func getAllCompayTechs(companyId:String) async throws ->[DBUser]{
        //DEVELOPER CHANGE THIS TO ACTUALLY ONLY GETTING THE COMPANY TECHS
        return try await userCollection()
            .getDocuments(as:DBUser.self)
    }
    func getCurrentTechs(id:String) async throws ->[DBUser]{
        
        return try await userCollection()
            .whereField("position", isEqualTo: "Owner")
            .whereField("id", isEqualTo: id)
            .getDocuments(as:DBUser.self)
    }
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    
    func getAllUserAvailableCompanies(userId:String) async throws ->[UserAccess]{
        print("Attempting to get User Access \(userId) - Page: UserAccessManager - Func: getAllUserAvailableCompanies")
        return try await userAccessCollection(userId: userId)
            .getDocuments(as:UserAccess.self) // DEVELOPER FIX LATER, BUT FOR NOW I WANNA TEST WHAT IT LOOKS LIKE WITH OUT HAVING A COMPANY
        //        return []
    }
    func getUserAccessCompanies(userId:String,companyId:String) async throws ->UserAccess{
        return try await userDocument(userId: userId, accessId: companyId).getDocument(as: UserAccess.self)
    }
    
    func getCompanyUserById(companyId:String,companyUserId:String) async throws -> CompanyUser{
        return try await companyUserDoc(companyId: companyId, companyUserId: companyUserId)
            .getDocument(as:CompanyUser.self)
    }
    
    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws -> CompanyUser{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(as:CompanyUser.self).first! // DEVELOPER PROPPERLY UNWRAP
        
    }
    func getAllRateSheetByCompanyUserId(companyId: String, companyUserId: String) async throws -> [RateSheet]{
        return try await companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId)
            .getDocuments(as:RateSheet.self)
    }
    func getAllCompanyUsers(companyId:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .getDocuments(as:CompanyUser.self)
    }
    func getAllCompanyUsersByStatus(companyId:String,status:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("status", isEqualTo: status)
            .getDocuments(as:CompanyUser.self)
    }
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
    func getPurchasesCountForTechId(companyId:String,userId:String) async throws ->Int {
        //Memory Leak
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
        //        return 0
    }
    func GetPurchasesByDateSortByDate(companyId: String,start:Date,end:Date,dateHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .order(by: "date",descending: dateHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    //Start
    func GetPurchasesByDateSortByPrice(companyId: String,start:Date,end:Date,priceHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = end.endOfDay()
        let startDate = start.startOfDay()
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "price",descending: priceHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillable(companyId: String, billable:Bool) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .limit(to: 100)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoiced(companyId: String, billable:Bool, invoiced:Bool) async throws -> [PurchasedItem] {
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
    func GetPurchasesByBillableAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool, price:Bool, techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = end.endOfDay()
        let startDate = start.startOfDay()
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "price",descending: price)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool, invoiced:Bool, price:Bool, techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = end.endOfDay()
        let startDate = start.startOfDay()
        
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
    
    func GetPurchasesByBillableAndSortByDate(companyId: String, start:Date, end:Date, billable:Bool, date:Bool, techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = end.endOfDay()
        let startDate = start.startOfDay()
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
        
    func GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: String, start:Date, end:Date, billable:Bool, invoiced:Bool, date:Bool, techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = end.endOfDay()
        let startDate = start.startOfDay()
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
        //End
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
        print("getAllpurchasedItemsByTechAndDate techId >> \(techId) \(startDate) \(endDate)")
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .getDocuments(as:PurchasedItem.self)
        
    }
    func getAllpurchasedItemsByDate(companyId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem] {
        print("getAllpurchasedItemsByDate >> \(startDate) \(endDate)")
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .getDocuments(as:PurchasedItem.self)
    }
    
    func getMostRecentPurchases(companyId:String,number:Int) async throws ->[PurchasedItem] {
        return try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date",descending: true)
            .limit(to:number)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws -> [CustomerMonthlySummary] {
        
        return  try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .limit(to: 25)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("serviceLocationId", isEqualTo: serviceLocationId)
            .limit(to: 1)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousYear().previousMonth().endOfMonth())
            .limit(to: 12)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
        
    }
    
    
    
    
    
    func getCustomerContactById(companyId:String,customerId : String,contactId:String) async throws -> Contact {
        return try await customerContactDocument(companyId: companyId, customerId: customerId, contactId: contactId)
            .getDocument(as: Contact.self)
        
    }
    
    

    
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId:String,customerId:String,companyId:String) async throws -> [BodyOfWater] {
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print("collection")
        print(collection)
        return collection
    }
    func getAllBodiesOfWater(companyId:String) async throws -> [BodyOfWater] {
        
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws -> [BodyOfWater] {
        
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocation.id)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws -> [BodyOfWater] {
        print("getAllBodiesOfWaterByServiceLocationId - \(serviceLocationId) - [dataService]")
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments(as:BodyOfWater.self)
        print("Body Of Waters: \(collection) - [dataService]")
        print("")
        return collection
    }
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId:String) async throws -> Int {
        let collection =  bodyOfWaterCollection(companyId: companyId)
        let countQuery = collection.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return Int(truncating: snapshot.count)
        } catch {
            print(error)
            return 0
        }
    }
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater{
        return try await bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId).getDocument(as:BodyOfWater.self)
    }


    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment{
        
        return try await equipmentDoc(companyId: companyId,equipmentId: equipmentId).getDocument(as: Equipment.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]{
        
        return try await equipmentPartCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentPart.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getHistoryServiceStopsBy(companyId:String,serviceStop: ServiceStop) async throws -> [History]{
        
        return try await db.collection("companies/\(companyId)/serviceStops/\(serviceStop.id)/history")
            .getDocuments(as:History.self)
    }

 

    func getAllCompanyRoles(companyId : String) async throws ->[Role] {
        return try await roleCollection(companyId: companyId)
        //            .whereField(Role.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
        //            .whereField(Role.CodingKeys.status.rawValue, isEqualTo: "Pending")
            .getDocuments(as:Role.self)
    }
    
    func getSpecificRole(companyId:String,roleId : String) async throws ->Role {
        return try await roleDoc(companyId: companyId,roleId: roleId)
            .getDocument(as: Role.self)
        
    }
    func getAllCompanies() async throws -> [Company]{
        try await companyCollection()
            .getDocuments(as:Company.self)
    }
    
    func getCompany(companyId:String) async throws -> Company{
        try await CompanyDocument(companyId: companyId).getDocument(as: Company.self)
    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).getDocument(as: ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsSnapShotByCompany(companyId:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("status", isEqualTo: "Need to Purchase")
            .limit(to: 15)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompanyCustomer(companyId: String,customerId: String) async throws -> [ShoppingListItem]{
        return try await shoppingListCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        
        //MEMORY LEAK
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .count.getAggregation(source: .server).count as! Int
        //        return 0
    }
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUserForJob(companyId: String, jobId: String,category:String) async throws -> [ShoppingListItem]{
        return try await shoppingListCollection(companyId: companyId)
            .whereField("jobId", isEqualTo: jobId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
    }
    
    func getAllGenericDataBaseItems(companyId:String) async throws -> [GenericItem]{
        
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
    

    func getAllStores(companyId:String) async throws -> [Vender]{
        return try await StoreCollection(companyId: companyId)
            .getDocuments(as:Vender.self)
        
    }
    func getSingleStore(companyId:String,storeId:String) async throws -> Vender{
        
        return try await StoreDocument(storeId: storeId, companyId: companyId).getDocument(as: Vender.self)
        
    }
    func getAllChatsByUser(userId:String) async throws -> [Chat] {
        return try await chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: true)
        
            .getDocuments(as:Chat.self)
    }
    func getSpecificChat(chatId:String) async throws ->Chat{
        
        return try await chatDocument(chatId: chatId)
            .getDocument(as: Chat.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getChatBySenderAndReceiver(companyId:String,senderId:String,receiverId:String) async throws ->Chat? {
        let chats = try await chatCollection()
            .whereField("participantIds", arrayContains: senderId)
            .getDocuments(as: Chat.self)
        print("Chats \(chats)")
        return chats.first(where: {$0.participantIds.contains(receiverId)})
    }
    
    func getChatsByCompany(companyId: String) async throws ->[Chat]{
        return try await chatCollection()
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments(as:Chat.self)
    }
    func getAllMessagesByChat(chatId: String) async throws ->[Message]{
        return try await messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: false)
            .limit(to: 10)
            .getDocuments(as:Message.self)
    }
    func getNewestMessage(chatId: String) async throws ->Message?{
        return try await messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: true)
            .limit(to: 1)
            .getDocuments(as:Message.self).first
    }
    


    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]{
        print("Getting \(amount) Recent Stop Data for \(bodyOfWaterId) ")
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .whereField("date", isLessThan: Date().startOfDay())
            .order(by: "date", descending: true)
            .limit(to: amount)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws->[StopData]{
        print("Getting Stop Data for \(serviceStopId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
        
            .order(by: "date", descending: true)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]{
        //Memory Leak
        print("Getting Stop Data for >> \(serviceStopId) and Body Of Water >> \(bodyOfWaterId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
        //        return []
    }
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByDateRange(companyId:String,startDate: Date,endDate:Date)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]{
        //        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await db.collection("workOrders/" + workOrder.id + "/history")
            .getDocuments(as:History.self)
    }

    

    
   
    
    func getAllOpenedInProgressCount(companyId: String) async throws -> Int {
        return 2
    }
    
  
    
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]{
        let workOrders = try await getAllWorkOrders(companyId: companyId)
        var workOrderList:[Job] = []
        for WO in workOrders {
            if WO.serviceStopIds.count == 0 {
                workOrderList.append(WO)
            }
        }
        return workOrderList
        
    }
   

    func getAllPastJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
    }
    
    func getAllFutureJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
        
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
    func getAllDataBaseItems(companyId:String) async throws -> [DataBaseItem]{
        
        return try await DataBaseCollection(companyId: companyId)
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

    func readFourMostRecentStops(companyId:String,customer : Customer) async throws -> [StopData]{
        
        return try await stopDataCollection( companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsById(companyId:String,customerId : String) async throws -> [StopData]{
        
        return try await stopDataCollection( companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsByCustomerIdServiceLocationIdAndBodyOfWaterId(companyId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> [StopData]{
        
        return try await stopDataCollection( companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func getStopDataFromServiceStop(companyId:String,serviceStopId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> StopData{
        print("Getting Stop Data From Service Stop")
        print("serviceStopId --> \(serviceStopId)")
        print("bodyOfWaterId --> \(bodyOfWaterId)")
        let stopData = try await stopDataCollection( companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .getDocuments(as:StopData.self)
        //        return stopData.first!
        print(stopData.first!)
        return stopData.first ?? StopData(id: "", date: Date(), serviceStopId: "", readings: [], dosages: [],
                                          observation: [], bodyOfWaterId: "",
                                          customerId: "",
                                          serviceLocationId: "",
                                          userId: "")
    }
    func readAllHistory(companyId:String,customer : Customer) async throws -> [StopData]{
        print("Trying to get data")
        return try await stopDataCollection( companyId: companyId)
            .order(by: "date", descending: true)
        //            .limit(to: 5)
            .getDocuments(as:StopData.self)
        
    }
    
    func getHistoryByCustomerByDateRange(companyId:String,customer : Customer,startDate:Date,endDate:Date) async throws -> [StopData]{
        
        return try await stopDataCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .getDocuments(as:StopData.self)
        
    }
    func getAllCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, isEqualTo: "Pending")
            .getDocuments(as:Invite.self)
    }
    func getAllAcceptedCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, isEqualTo: "Accepted")
            .getDocuments(as:Invite.self)
    }
    func getSpecificInvite(inviteId : String) async throws ->Invite {
        return try await inviteDoc(inviteId: inviteId)
            .getDocument(as: Invite.self)
        
    }
    func getAllTrainings(companyId: String,techId:String) async throws -> [Training]{
        let trainings = try await TrainingCollection(companyId: companyId, techId: techId)
            .getDocuments(as:Training.self)
        print("got all trainings for \(techId)")
        print(trainings)
        return trainings
    }
    func getSingleTraining(companyId: String,trainingId:String,techId:String) async throws -> Training{
        return try await TrainingDocument(trainingId: trainingId, companyId: companyId, techId: techId)
            .getDocument(as: Training.self)
    }
    func getAllTrainingTemplates(companyId: String) async throws -> [TrainingTemplate]{
        return try await TrainingTemplateCollection(companyId: companyId)
            .getDocuments(as:TrainingTemplate.self)
    }
    func getSingleTrainingTemplate(companyId: String,trainingTemplateId:String) async throws -> TrainingTemplate{
        return try await TrainingTemplateDocument(trainingTemplateId: trainingTemplateId, companyId: companyId)
            .getDocument(as: TrainingTemplate.self)
    }
    func getAllBillingTemplates(companyId:String) async throws -> [BillingTemplate]{
        
        return try await BillingTemplateCollection(companyId: companyId)
            .getDocuments(as:BillingTemplate.self)
    }
    func getDefaultBillingTempalte(companyId:String) async throws -> BillingTemplate{
        
        let templates = try await BillingTemplateCollection(companyId: companyId)
            .whereField("defaultSelected", isEqualTo: true)
            .getDocuments(as:BillingTemplate.self)
        return templates.first!
    }
    //start up functions
    
    func getStoreCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        try await SettingsCollection(companyId: companyId).document("serviceStops")
            .updateData([
                "increment": updatedServiceStopCount
            ])
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
        //        return 1
        
    }
    func getGenericItem(companyId:String,genericItemId:String) async throws -> GenericItem{
        return try await GenericItemDocument(genericItemId: genericItemId,companyId: companyId).getDocument(as: GenericItem.self)
    }
    func getGenericItems(companyId:String) async throws -> [GenericItem]{
        
        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)
    }
    func getInvoiceCount(companyId:String) async throws-> Int {
        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("invoices").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
        try await SettingsCollection(companyId: companyId).document("invoices")
            .updateData([
                "increment": updatedWorkOrderCount
            ])
        print("Invoice Count: " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount
    }
    func getWorkOrderCount(companyId:String) async throws-> Int{
        
        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("workOrders").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
        try await SettingsCollection(companyId: companyId).document("workOrders")
            .updateData([
                "increment": updatedWorkOrderCount
            ])
        print("Work Order Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount
        
    }
    func getRepairRequestCount(companyId:String) async throws-> Int{
        
        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("repairRequests").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
        try await SettingsCollection(companyId: companyId).document("repairRequests")
            .updateData([
                "increment": updatedWorkOrderCount
            ])
        print("Repair Request Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount
        
    }
    func getServiceOrderCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        try await SettingsCollection(companyId: companyId).document("serviceStops")
            .updateData([
                "increment": updatedServiceStopCount
            ])
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
        //        return 1
        
    }
    //recurringServiceStop Settings
    func getRecurringServiceStopCount(companyId:String) async throws-> Int{
        
        var recurringServiceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("recurringServiceStops").getDocument(as: Increment.self)
        recurringServiceStopCount = doc.increment
        sleep(1)
        let updatedRecurringServiceStopCount = recurringServiceStopCount + 1
        
        try await SettingsCollection(companyId: companyId).document("recurringServiceStops")
            .updateData([
                "increment": updatedRecurringServiceStopCount
            ])
        print("recurringServiceStop Count " + String(updatedRecurringServiceStopCount))
        return updatedRecurringServiceStopCount
        //        return 2
        
    }
    func getAllWorkOrderTemplate(companyId:String,workOrderId:String) async throws -> JobTemplate{
        return try await WorkOrderDocument(workOrderTemplateId: workOrderId,companyId: companyId)
            .getDocument(as: JobTemplate.self)
    }
    func getAllWorkOrderTemplates(companyId:String) async throws -> [JobTemplate]{
        
        return try await WorkOrderTemplateCollection(companyId: companyId)
            .getDocuments(as:JobTemplate.self)
        
    }
    func getWorkOrderEstimate(companyId:String) async throws -> [JobTemplate]{
        
        return try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: "Estimate" )
            .getDocuments(as:JobTemplate.self)
        
    }
    func getAllReadingTemplates(companyId: String) async throws -> [SavedReadingsTemplate] {
        return try await ReadingsCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:SavedReadingsTemplate.self)
    }
  
    func getAllDosageTemplates(companyId:String) async throws -> [SavedDosageTemplate]{
        
        return try await DosageCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:SavedDosageTemplate.self)
    }
    func getAllServiceStopTemplates(companyId:String) async throws -> [ServiceStopTemplate]{
        
        return try await ServiceStopTemplateCollection(companyId: companyId)
            .getDocuments(as:ServiceStopTemplate.self)
    }
}
