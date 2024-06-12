//
//  PurchasesViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/31/23.
//

import Foundation
enum PurchaseFilterOptions:String, CaseIterable{
    case all
    case billable
    case nonBillable
    case billableAndNotInvoiced
    case billableAndInvoiced

    
    func display() -> String {
        switch self {
        case .all:
            return "All"
        case .billable:
            return "Billable"
        case .nonBillable:
            return "Non Billable"
        case .billableAndNotInvoiced:
            return "Billable And Not Invoiced"
        case .billableAndInvoiced:
            return "Billable And Invoiced"
            
        }
    }
}
enum PurchaseSortOptions:String, CaseIterable{
    case priceHigh
    case priceLow
    case purchaseDateFirst
    case purchaseDateLast

    
    func display() -> String {
        switch self {
        case .priceHigh:
            return "Price High"
        case .priceLow:
            return "Price Low"
        case .purchaseDateFirst:
            return "Recent"
        case .purchaseDateLast:
            return "Oldest"
        }
    }
}
@MainActor
final class PurchasesViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var purchasedItems: [PurchasedItem] = []
    @Published private(set) var purchasedItem2: [PurchasedItem] = []
    @Published private(set) var dataBaseItemList: [DataBaseItem] = []
    @Published private(set) var techNames: [String] = []
    @Published private(set) var purchaseCount : Int? = nil
    @Published private(set) var purchasedItemsSummary: [String:Double] = [:]

    @Published private(set) var filteredPurchasedItems: [PurchasedItem] = []
    @Published private(set) var filterPurchasesByName: [PurchasedItem] = []

    @Published private(set) var purchasedItem: PurchasedItem? = nil
    @Published private(set) var percentage: Double? = nil
    @Published private(set) var totalSpent: Double? = nil

    @Published private(set) var totalSpentOnBillables: Double? = nil
    @Published private(set) var totalBilled: Double? = nil
    @Published private(set) var percentageBilled: Double? = nil
    @Published private(set) var totalProfitInDollars: Double? = nil
    @Published private(set) var totalSoldInDollars: Double? = nil
    @Published private(set) var percentageProfit: Double? = nil
    @Published private(set) var itemsPurchased: Double? = nil
    @Published private(set) var itemsPurchasedBillable: Double? = nil
    @Published private(set) var itemsPurchasedAndBilled: Double? = nil
    @Published private(set) var totalSpentBillable: Double? = nil
    @Published private(set) var techItemSummary: [WasteSummary] = []
    @Published private(set) var purchasedAuxilaryPartsFromWorkOrder: Double? = nil
    @Published private(set) var purchasedInstallationPartsFromWorkOrder: Double? = nil
    @Published private(set) var electricalPartsFromWorkOrder: Double? = nil
    @Published private(set) var pvcPartsFromWorkOrder: Double? = nil
    @Published private(set) var chemicalsFromWorkOrder: Double? = nil
    @Published private(set) var miscPartsFromWorkOrder: Double? = nil
    @Published private(set) var totalSpentOnWO: Double? = nil
    @Published private(set) var selectedFilter:PurchaseFilterOptions = .billable
    @Published private(set) var selectedSort:PurchaseSortOptions = .purchaseDateFirst



    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Enum
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func filterAndSortSelected(companyId: String,filter:PurchaseFilterOptions,sort:PurchaseSortOptions,startDate:Date,endDate:Date,techIds:[String]) async throws{
        print(filter)
        print(sort)
        self.selectedFilter = filter
        self.selectedSort = sort

        switch filter {
        case .all:
            self.purchasedItems = try await PurchasedItemsManager.shared.getAllpurchasedItemsByPrice(companyId: companyId, descending: true,techIds: techIds)

            switch sort {
            case .priceLow:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByDateSortByPrice(companyId: companyId, start: startDate, end: endDate, priceHigh: false,techIds: techIds)
            case .priceHigh:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByDateSortByPrice(companyId: companyId, start: startDate, end: endDate, priceHigh: true,techIds: techIds)
            case .purchaseDateFirst:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByDateSortByDate(companyId: companyId, start: startDate, end: endDate, dateHigh: true,techIds: techIds)
            case .purchaseDateLast:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByDateSortByDate(companyId: companyId, start: startDate, end: endDate, dateHigh: false,techIds: techIds)
            }
        case .billable:
            switch sort {
            case .priceHigh:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByPrice(companyId: companyId, billable: true, price: false,techIds: techIds)
            case .priceLow:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByPrice(companyId: companyId, billable: true, price: true,techIds: techIds)
            case .purchaseDateFirst:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByDate(companyId: companyId, billable: true, date: true,techIds: techIds)
            case .purchaseDateLast:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByDate(companyId: companyId, billable: true, date: false,techIds: techIds)

            }
        case .nonBillable:
            switch sort {
            case .priceHigh:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByPrice(companyId: companyId, billable: false, price: false,techIds: techIds)
            case .priceLow:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByPrice(companyId: companyId, billable: false, price: true,techIds: techIds)
            case .purchaseDateFirst:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByDate(companyId: companyId, billable: false, date: true,techIds: techIds)
            case .purchaseDateLast:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndSortByDate(companyId: companyId, billable: false, date: false,techIds: techIds)
            }
        case .billableAndNotInvoiced:
            switch sort {
                
            case .priceHigh:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: companyId, billable: true, invoiced: false, price: false,techIds: techIds)
            case .priceLow:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: companyId, billable: true, invoiced: false, price: true,techIds: techIds)
            case .purchaseDateFirst:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: companyId, billable: true, invoiced: false, date: true,techIds: techIds)
            case .purchaseDateLast:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: companyId, billable: true, invoiced: false, date: false,techIds: techIds)

            }
        case .billableAndInvoiced:
            switch sort {
            case .priceHigh:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: companyId, billable: true, invoiced: true, price: false,techIds: techIds)
            case .priceLow:
                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: companyId, billable: true, invoiced: true, price: true,techIds: techIds)
            case .purchaseDateFirst:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: companyId, billable: true, invoiced: true, date: true,techIds: techIds)
            case .purchaseDateLast:

                self.purchasedItems = try await PurchasedItemsManager.shared.GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: companyId, billable: true, invoiced: true, date: false,techIds: techIds)


            }
        }
 


    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Uploading Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Get Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getPurchasesCountForTechId(companyId:String,userId:String) async throws {
        self.purchaseCount = try await PurchasedItemsManager.shared.getPurchasesCountForTechId(companyId: companyId, userId: userId)
    }
    func getAllPurchases() async throws{
        //        self.purchasedItems = try await ProductManager.shared.getAllPurchasedItems()
    }
    func getSinglePurchasedItem(itemId:String,companyId: String) async throws {
                self.purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: itemId, companyId: companyId)
        
    }
    func getNumberOfItemsPurchasedIn30Days(companyId: String) async throws{
        //Get 10 Most Recent Purchases
        self.purchasedItems = try await PurchasedItemsManager.shared.getMostRecentPurchases(companyId: companyId, number: 10)
        //Details
        let result = try await PurchasedItemsManager.shared.getNumberOfItemsPurchasedIn30Days(companyId: companyId)
        self.itemsPurchased = result.total
        self.itemsPurchasedBillable = result.totalBillable

        self.itemsPurchasedAndBilled = result.Invoiced
        self.totalSpentOnBillables = result.TotalSpentBillable
        self.totalSpent = result.TotalSpent

        self.totalBilled = result.TotalBilled
        self.percentageBilled = (result.TotalBilled / result.TotalSpentBillable)*100
        self.purchasedItems = result.NonBillableList
        self.percentage = (result.Invoiced/result.totalBillable)*100
        self.totalSoldInDollars = result.totalSoldInDollars
        self.totalProfitInDollars = result.totalSoldInDollars - result.TotalSpentBillable

    }
    func getNumberOfItemsPurchasedIn30DaysPrior(companyId: String) async throws{
//        let result = try await PurchasedItemsManager.shared.getNumberOfItemsPurchasedIn30DaysPrior(companyId: companyId)
//        self.purchasedItemsChartPrior = result.purchasedItemsChart

    }
    func getNumberOfItemsPurchasedAndBilledIn30Days(companyId: String) async throws{
//        self.itemsPurchasedAndBilled = try await PurchasedItemsManager.shared.getNumberOfItemsPurchasedAndBilledIn30Days(companyId: companyId)
 
    }
    func getNumberOfItemsNonBillable(companyId: String,purchaseList:[PurchasedItem]) async throws{
        
        let listOfDataBaseItems = try await DatabaseManager.shared.getallNonBillableTemplates(companyId: companyId)
        var nonBillableItemList:[DataBaseItem] = []
        for item in listOfDataBaseItems {
            if !item.billable{
                nonBillableItemList.append(item)
            }
            
        }
        self.dataBaseItemList = nonBillableItemList
    }
    
    func getSummaryItems(companyId: String,dataBaseItems:[DataBaseItem]) async throws{
        var purchasedItemsSummary:[String:Double] = [:]

        for item in dataBaseItems {
            let listOfPurchasedItem = try await PurchasedItemsManager.shared.getItemsBasedOnDBItem(companyId: companyId, DataBaseItemSku: item.sku)
            var count:Double = 0
            print(item.name)
            for purchaseItem in listOfPurchasedItem {
                count = count + purchaseItem.quantity
                print(count)
            }
            purchasedItemsSummary[item.name] = count

        }
        print(purchasedItemsSummary)
        self.purchasedItemsSummary = purchasedItemsSummary
    }
    func getSummaryFromDBItemList(companyId: String,dataBaseItems:[PurchasedItem]){
        var purchasedItemsSummary:[String:Double] = [:]
        var skuList:[String] = []
        for item in dataBaseItems {
            if !skuList.contains(item.sku) {
                skuList.append(item.sku)
            }
        }
        for sku in skuList {
            var count:Double = 0
            for item in dataBaseItems {
                if item.sku == sku {
                    count = count + item.quantity
                    print(count)
                }
            }
            purchasedItemsSummary[sku] = count
        }
        print(purchasedItemsSummary)
        self.purchasedItemsSummary = purchasedItemsSummary
    }
    func getallPurchasesLast30Days(companyId:String,startDate:Date,endDate:Date,viewBillable:Bool) async throws{
//        self.receiptItems = try await ReceiptManager.shared.getAllReceiptItems()
        self.purchasedItems = try await PurchasedItemsManager.shared.getallReceiptsLast30Days(companyId: companyId, startDate: startDate, endDate: endDate,viewBillable: viewBillable)

    }

    func getAllPurchasesByItem(companyId: String,sku:String) async throws{
        let listOfPurchasedItem = try await PurchasedItemsManager.shared.getItemsBasedOnDBItem(companyId: companyId, DataBaseItemSku: sku)
        var listOfTechIds:[String] = []
        var dictOfTechs:[String:String] = [:]

        for item in listOfPurchasedItem {
            if !listOfTechIds.contains(item.techId) {
                listOfTechIds.append(item.techId)
                dictOfTechs[item.techId] = item.techName
            }
            
        }
        var techSummary: [WasteSummary] = [] //[Tech Name[total/used/waste:int]

        for techId in listOfTechIds {
            var total:Double = 0
            var used:Double = 0
            for item in listOfPurchasedItem {
                if item.techId == techId {
                    total = item.quantity + total
                }
            }
            //Get used Item List
            used = 20
            let wasteSummary:WasteSummary = WasteSummary(id: UUID().uuidString, techId: techId,techName: dictOfTechs[techId] ?? "NA", total: total, used: used)
            techSummary.append(wasteSummary)
        }
        self.techItemSummary = techSummary
    }
    func getTotalFromSumOfPurchaseIds(installParts:[WODBItem],pvcParts:[WODBItem],chemicals:[WODBItem],electricalParts:[WODBItem],miscParts:[WODBItem],companyId: String) async throws {
        
        var totalSpent:Double = 0
        var totalInstall:Double = 0
        var totalPVC:Double = 0
        var totalElectrical:Double = 0
        var totalChemicals:Double = 0
        var totalMisc:Double = 0
        
        for item in installParts {
            let cost = item.cost * item.quantity

            totalInstall = totalInstall + cost
            totalSpent = totalSpent + totalInstall
        }
        for item in pvcParts {
            let cost = item.cost * item.quantity

            totalPVC = totalPVC + cost
            totalSpent = totalSpent + totalPVC
        }
        for item in chemicals {
            let cost = item.cost * item.quantity

            totalChemicals = totalChemicals + cost
            totalSpent = totalSpent + totalChemicals
        }
        for item in electricalParts {
            let cost = item.cost * item.quantity

            totalElectrical = totalElectrical + cost
            totalSpent = totalSpent + totalElectrical
        }
        for item in miscParts {
            let cost = item.cost * item.quantity

            totalMisc = totalMisc + cost
            totalSpent = totalSpent + totalMisc
        }


        self.purchasedInstallationPartsFromWorkOrder = totalInstall
        self.electricalPartsFromWorkOrder = totalElectrical
        self.pvcPartsFromWorkOrder = totalPVC
        self.chemicalsFromWorkOrder = totalChemicals
        self.miscPartsFromWorkOrder = totalMisc
        self.totalSpentOnWO = totalSpent

    }
    func getTotalFromSumOfPurchaseAuxIds(ids:[String],companyId: String) async throws {
        var total:Double = 0
        for id in ids {
            let purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: id, companyId: companyId)
            total = total + purchasedItem.totalAfterTax
        }
        self.purchasedAuxilaryPartsFromWorkOrder = total
    }
    func getInstallationTotalFromSumOfPurchaseIds(ids:[String],companyId: String) async throws {
        var total:Double = 0
        for id in ids {
            let purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: id, companyId: companyId)
            total = total + purchasedItem.totalAfterTax
        }
        self.purchasedInstallationPartsFromWorkOrder = total
    }
    func totalSumOfWorkOrder(Auxids:[String],Installids:[String],companyId: String) async throws {
        var total:Double = 0
        for id in Auxids {
            let purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: id, companyId: companyId)
            total = total + purchasedItem.totalAfterTax
        }
        for id in Installids {
            let purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: id, companyId: companyId)
            total = total + purchasedItem.totalAfterTax
        }
        self.totalSpentOnWO = total
    }
    func getPurchasesSnapShot(companyId:String) async throws {
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateReciptBillingStatus(currentItem:PurchasedItem,newBillingStatus:Bool,companyId: String) async throws {
        try await PurchasedItemsManager.shared.updatePurchasedItemBillingStatus(currentItem: currentItem, newBillingStatus: newBillingStatus, companyId: companyId)


    }
    func updateReceiptCustomer(currentItem:PurchasedItem,newCustomer:Customer,companyId: String) async throws {
        try await PurchasedItemsManager.shared.updatePurchasedCustomer(currentItem: currentItem, newCustomer: newCustomer, companyId: companyId)
    }
    func updateReceiptWorkOrder(currentItem:PurchasedItem,workOrderID:String,companyId: String) async throws {
        try await PurchasedItemsManager.shared.updatePurchasedWorkOrderId(currentItem: currentItem, workOrderId: workOrderID, companyId: companyId)
    }
    func updateNotes(currentItem:PurchasedItem,notes:String,companyId: String) async throws {
        try await PurchasedItemsManager.shared.updateNotes(currentItem: currentItem, notes: notes, companyId: companyId)
    }
    func updateBillingRate(currentItem:PurchasedItem,rate:Double,companyId: String) async throws {
        try await PurchasedItemsManager.shared.updateBilling(currentItem: currentItem, billingRate: rate, companyId: companyId)
    }
    func updatePurchaseItem(companyId: String,techIds:[String]) async throws {
        let purchaseItemList = try await PurchasedItemsManager.shared.getAllpurchasedItemsByPrice(companyId: companyId, descending: true, techIds: techIds)

        for purchase in purchaseItemList{
            try await PurchasedItemsManager.shared.updatePurchaseItem(purchaseItem: purchase, companyId: companyId)
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func summaryOfPurchasedItems(purchasedItems:[PurchasedItem]) {

        

        var totalSpentBillableCount = 0
        var totalSpentNonBillableCount = 0
        var itemsBillableCount = 0
        var itemsNonBillableCount = 0

        for item in purchasedItems {
            if item.billable {
                totalSpentBillableCount = totalSpentBillableCount + Int(item.totalAfterTax)
                itemsBillableCount = itemsBillableCount + Int(item.quantity)

            } else {
                totalSpentNonBillableCount = totalSpentNonBillableCount + Int(item.totalAfterTax)
                itemsNonBillableCount = itemsNonBillableCount + Int(item.quantity)

            }
        }
        self.totalSpentBillable = Double(totalSpentBillableCount)
        self.totalSpentOnBillables = Double(totalSpentNonBillableCount)

        self.itemsPurchasedBillable = Double(itemsBillableCount)
        self.itemsPurchased = Double(itemsNonBillableCount)
    }
    //
    // Listeners
    //
    func addListenerForAllPurchases(companyId:String,filter:CustomerFilterOptions,sort:CustomerSortOptions){
//        print("Adding Customer Listener")
//        dataService.addListenerForAllCustomers(companyId: companyId, sort: sort, filter: filter) { [weak self] customers in
//             self?.customers = customers
//        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Filter
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func filterReceiptListByBillable(billable:Bool,purchasedItems:[PurchasedItem]) {
        //very fancy Search Bar
        var filteredListOfItems:[PurchasedItem] = []
        if billable {
            for item in purchasedItems {
                if item.billable  {
                    filteredListOfItems.append(item)
                }
            }
        } else {
            for item in purchasedItems {
                if !item.billable  {
                    filteredListOfItems.append(item)
                }
            }
        }
        self.purchasedItem2 = filteredListOfItems
    }
    func filterReceiptListByBillableAndInvoice(billable:Bool,invoiced:Bool,purchasedItems:[PurchasedItem]) {
        //very fancy Search Bar
        var filteredListOfItems:[PurchasedItem] = []
        if billable {
            for item in purchasedItems {
                if item.billable  {
                    if invoiced {
                        if item.invoiced  {
                            filteredListOfItems.append(item)
                        }
                    } else {
                        if !item.invoiced  {
                            filteredListOfItems.append(item)
                        }
                    }
                }
            }
        } else {
            for item in purchasedItems {
                if !item.billable  {
                    filteredListOfItems.append(item)
                }
            }
        }
        self.purchasedItem2 = filteredListOfItems
    }
    func filterPurchaseList(filterTerm:String,purchasedItems:[PurchasedItem]) {
        //very fancy Search Bar
        var filteredListOfItems:[PurchasedItem] = []
        for item in purchasedItems {

            if item.customerName.lowercased().contains(filterTerm.lowercased()) || item.sku.lowercased().contains(filterTerm.lowercased()) || item.name.lowercased().contains(filterTerm.lowercased()) || item.invoiceNum.lowercased().contains(filterTerm.lowercased()) || item.techName.lowercased().contains(filterTerm.lowercased()){
                filteredListOfItems.append(item)
            }
        }
        self.filteredPurchasedItems = filteredListOfItems
    }
    func getUniqueTechsFromPurchases(purchaseList:[PurchasedItem]){
        var techList:[String] = []
        for item in purchaseList {
            if !techList.contains(where: {$0 == item.techName}) {
                techList.append(item.techName)
            }
        }
        self.techNames = techList
    }
    func filterPurchaseListByTechName(techName:String,purchasedItems:[PurchasedItem]) {
        //very fancy Search Bar
        var filteredListOfItems:[PurchasedItem] = []
        for item in purchasedItems {

            if  item.techName.lowercased() == techName.lowercased(){
                filteredListOfItems.append(item)
            } else {
                print("Did not match Tech Name")
            }
        }
        self.filterPurchasesByName = filteredListOfItems
    }
    func getPurchaseById(companyId:String,purchaseId:String) async throws {
        self.purchasedItem = try await PurchasedItemsManager.shared.getSingleItem(itemId: purchaseId, companyId: companyId)
    }
}
