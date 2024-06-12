//
//  ReceiptDatabaseViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//

import Foundation
import CoreXLSX
import FirebaseFirestore
@MainActor
final class ReceiptDatabaseViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //interval
    private var lastDocument:DocumentSnapshot? = nil
    
    // Published
    @Published var loadingText:String? = nil
    @Published var loadingCount:Int? = nil
    @Published var totalCount:Int? = nil
    @Published var categories:[String] = ["Installation","Chemicals","Cleaners","PVC","Electrical","Pool Supplies"]
    @Published var filteredSubCategories:[DataBaseSubCategories] = []
    @Published var commonDataBaseItems:[DataBaseItem] = []
    @Published private(set) var dataBaseItems: [DataBaseItem] = []
    @Published private(set) var dataBaseItems2: [DataBaseItem] = [] //Rename in post
    @Published private(set) var dataBaseItemsFiltered: [DataBaseItem] = [] //Rename in post

    @Published private(set) var dataBaseItem: DataBaseItem? = nil

    @Published var subCategories:[DataBaseSubCategories] = [
        DataBaseSubCategories(id: UUID().uuidString, name: "Pump", category: "Installation"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Heater", category: "Installation"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Filter", category: "Installation"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Salt Cell", category: "Installation"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Liquid Chlorine", category: "Chemicals"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Chlorine Tabs", category: "Chemicals"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Bromide Tabs", category: "Chemicals"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Sodium Bromide", category: "Chemicals"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Soda Ash", category: "Chemicals"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Tires", category: "Cleaners"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Gears", category: "Cleaners"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Whole", category: "Cleaners"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Hose", category: "Cleaners"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Wire Nut", category: "Electrical"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Elbows", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Couplers", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Sweeps", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Tee", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Pipe Extender", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Valve", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "45", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Bushing", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Pipe", category: "PVC"),
        DataBaseSubCategories(id: UUID().uuidString, name: "O Ring", category: "Pool Supplies"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Pump Basket", category: "Pool Supplies"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Floater", category: "Pool Supplies"),
        DataBaseSubCategories(id: UUID().uuidString, name: "Skimmer Basket", category: "Pool Supplies")
    ]
    func getSubCategoriesFromCategory(category:String,subCategories:[DataBaseSubCategories]){
        var subCategoryList:[DataBaseSubCategories] = []
        for sub in subCategories{
            if sub.category == category{
                subCategoryList.append(sub)
            }
        }
        self.filteredSubCategories = subCategoryList
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func uploadCsvFileTo(pathName:String,fileName:String,companyId: String) async {
        let fileURL = URL(fileURLWithPath: pathName).appendingPathExtension("csv")
        var customerCount = 0
        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            print("Successfully Read")
            let customerList = try await CustomerManager.shared.convertCustomerCSVToStruct(contents: text2)
            print("Successfully Converted")
            self.totalCount = customerList.count
            //This will Fail if there are any double spaced columns
            for customer in customerList {
                let fullName = customer.firstName + " " + customer.lastName

                try await CustomerManager.shared.uploadCSVCustomerToFireStore(companyId: companyId, customer: customer)
                //remove before Production
                customerCount = customerCount + 1
                self.loadingText = fullName
                self.loadingCount = customerCount + 1
                
                //                if customerCount > 10 {
                //                    return
                //                }
            }
            
            print("Completed Upload")
        }
        catch {
            print("Unable to read the file")
        }
    }
    
    func uploadXlsxFileTo(pathName:String,fileName:String,companyId: String,workSheetName:String,vender:Vender) async throws{
        print("PathName > \(pathName)")
        let adjustedPathName = pathName.dropFirst(1)
        print("adjustedPathName > \(adjustedPathName)")
        
        let fileURL = URL(fileURLWithPath: String(pathName)).appendingPathExtension("xlsx")
        print("fileURL >> \(fileURL)")
        
        
        //        guard let file2 = XLSXFile2(filepath: pathName) else {
        //            fatalError("XLSX file at \(pathName) is corrupted or does not exist")
        //        }
        //        print(file2)
        
        guard let file = XLSXFile(filepath: pathName) else {
            fatalError("XLSX file at \(pathName) is corrupted or does not exist")
        }
        var excelCustomerList:[CSVDataBaseItem] = []
        var exitFunc:Bool = false
        var rowCount:Int = 0
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                
                if let internalWorkSheetName = name {
                    if internalWorkSheetName == workSheetName {
                        print("WorkSheet Name: \(internalWorkSheetName)")
                        
                        
                        let worksheet = try file.parseWorksheet(at: path)
                        //                        //iterate through all the items in a column
                        //                        print("Has \((worksheet.data?.rows ?? []).count) rows")
                        //                        if let sharedStrings = try file.parseSharedStrings() {
                        //                          let columnString = worksheet.cells(atColumns: [ColumnReference("B")!])
                        //                            .compactMap { $0.stringValue(sharedStrings) }
                        //                            print("columnCStrings: \(columnString)")
                        //                            for row in columnString {
                        //                                print(row)
                        //                            }
                        //                        }
                        var numberOfLetters:[String] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
                        var numberOfColumns:Int = 0
                        for row in worksheet.data?.rows ?? [] {
                            if !exitFunc {
                                
                                
                                rowCount = rowCount + 1
                                //iterate through all the items in a row
                                
                                //                            if let sharedStrings = try file.parseSharedStrings() {
                                //                                let rowString = worksheet.cells(atRows: [UInt(rowCount)])
                                //                                .compactMap { $0.stringValue(sharedStrings) }
                                //                                print("columnCStrings: \(rowString)")
                                //                                var customerStruct = CSVCustomer.init(raw: rowString)
                                //                                print(customerStruct)
                                //                            }
                                if rowCount == 1 {
                                    if let sharedStrings = try file.parseSharedStrings() {
                                        let rowString = worksheet.cells(atRows: [UInt(rowCount)])
                                            .compactMap { $0.stringValue(sharedStrings) }
                                        //                                    print("rowCount: \(rowString)")
                                        numberOfColumns = rowString.count
                                        print("Column Count = \(numberOfColumns)")
                                    }
                                }
                                
                                var excelDatabaseRow:[String] = []
                                var letterCount:Int = 0
                                
                                for letter in numberOfLetters {
                                    if letterCount != numberOfColumns{
                                        
                                        if let sharedStrings = try file.parseSharedStrings() {
                                            let cellString = worksheet.cells(atColumns: [ColumnReference(letter)!], rows: [UInt(rowCount)])
                                                .compactMap { $0.stringValue(sharedStrings) }
                                            //                                    print("Cell: \(cellString)")
                                            excelDatabaseRow.append(cellString.first ?? "")
                                            
                                        }
                                        letterCount = letterCount + 1
                                    }
                                }
                                let databaseItemStruct = CSVDataBaseItem.init(raw: excelDatabaseRow)
                                print(databaseItemStruct)
                                
                                if databaseItemStruct.name == "" && databaseItemStruct.category == "" && databaseItemStruct.sellPrice == "" && databaseItemStruct.rate == "" && databaseItemStruct.sku == ""{
                                    print("Skipped")
                                    exitFunc = true
                                } else {
                                    excelCustomerList.append(databaseItemStruct)
                                    print("Successfully Updated Customer # \(excelCustomerList.count)")
                                }
                                //                            print("Row number: \(countRows)")
                                //                            print("Cells: \(row.cells.count)")
                                //                                for c in row.cells {
                                //                                    print("Row: \(c.reference.row) - column: \(c.reference.column) - value:\(c.reference.description)")
                                //                                }
                            } else {
                                print("Break")
                                break
                            }
                        }
                    }
                }
            }
        }
        //HERE
        self.totalCount = excelCustomerList.count
        //This will Fail if there are any double spaced columns
        print("excelCustomerList Count \(excelCustomerList.count)")
        for item in excelCustomerList {
            let fullName = item.name
            print("Full Name >> \(fullName)")
            try await ReceiptManager.shared.uploadCSVDataBaseItemToFireStore(companyId: companyId, CSVItem: item, storeId: vender.id, storeName: vender.name ?? "")
            //remove before Production
        }
    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getAllDataBaseItemsByName(companyId:String) async throws{
        

        let (datBaseItems,lastDocument) = try await DatabaseManager.shared.getAllDataBaseItemsByName(companyId: companyId, count: 25, lastDocument: lastDocument)
        self.dataBaseItems.append(contentsOf: datBaseItems)
        if let lastDocument {
            self.lastDocument = lastDocument

        }
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


//    func getAllDataBaseItems() async throws{
//        self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItems()
//    }
    func filterAndSortSelected(companyId: String,category:String,subCategories:DataBaseSubCategories) async throws{
        if category == "All" {
            self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItems(companyId: companyId)
        } else if category == "Uncategorized" {
            self.dataBaseItems = try await DatabaseManager.shared.getDataBaseItemByCategory(companyId: companyId, category: "")
        } else {
            
            if subCategories.name == "All" {
                self.dataBaseItems = try await DatabaseManager.shared.getDataBaseItemByCategory(companyId: companyId, category: category)
            } else if subCategories.name == "Uncategorized" {
                self.dataBaseItems = try await DatabaseManager.shared.getDataBaseItemByCategoryAndSubCategory(companyId: companyId, category: category, subCategory: DataBaseSubCategories(id: UUID().uuidString, name: "", category: ""))
            } else {
                self.dataBaseItems = try await DatabaseManager.shared.getDataBaseItemByCategoryAndSubCategory(companyId: companyId, category: category, subCategory: subCategories)
            }
        }
    }

    func addDataBaseItem(companyId:String,dataBaseItem:DataBaseItem) async throws{

        try await DatabaseManager.shared.uploadDataBaseItem(companyId: companyId, dataBaseItem: dataBaseItem)
        
        print("Uploaded New Data Base Item")
    }
    func editDataBaseItem(companyId:String,dataBaseItemId:String,name:String,rate:Double,description:String)  async throws{
        //DEVELOPER FIX THE UPDATING AND ADDING DATABASE ITEMS
        let DbItem = try await DatabaseManager.shared.getDataBaseItem(companyId: companyId, dataBaseItemId: dataBaseItemId)

        try await DatabaseManager.shared.editDataBaseItem(
            companyId: companyId,
            dataBaseItemId: dataBaseItemId,
            name: name,
            rate: rate,
            storeName: DbItem.storeName,
            storeId: DbItem.venderId,
            category: DbItem.category,
            subCategory: DbItem.subCategory,
            description: DbItem.description,
            sku: DbItem.sku,
            billable: DbItem.billable,
            color: DbItem.color,
            size: DbItem.size,
            UOM: DbItem.UOM
        )
        
        print("Uploaded New Data Base Item")
    }
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws{
        self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItemsByCompany(companyId: companyId, storeId: storeId)
    }
    func getItemsFromDataBaseBySearchTermAndStoreId(companyId:String,storeId:String,searchTerm:String) async throws{
        print(storeId)
        self.dataBaseItems = try await DatabaseManager.shared.getItemsFromDataBaseBySearchTermAndStoreId(companyId: companyId, storeId: storeId,searchTerm: searchTerm)
    }
    func getSingleItem(companyId:String,dataBaseItemId:String) async throws{
        self.dataBaseItem = try await DatabaseManager.shared.getDataBaseItem(companyId: companyId, dataBaseItemId: dataBaseItemId)
    }
    func getAllDataBaseItems(companyId:String) async throws{
        self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItems(companyId: companyId)

    }
    func getCommonDataBaseItems(companyId:String) async throws{
        self.commonDataBaseItems = try await DatabaseManager.shared.getCommonDataBaseItems(companyId: companyId)
    }
    func getAllDataBaseItemsByCategory(companyId:String,category:String) async throws{
        self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItemsByCategory(companyId: companyId, category: category)

    }
    func get25DataBaseItems(companyId:String) async throws{
        self.dataBaseItems = try await DatabaseManager.shared.get25DataBaseItems(companyId: companyId)

    }

    func getDataBaseItemsFromArrayOfIds(companyId:String,dataBaseIds:[String]) async throws {
        self.dataBaseItems2 = try await DatabaseManager.shared.getDataBaseItemsFromArrayOfIds(companyId: companyId, dataBaseIds:dataBaseIds)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Filter the Receipt
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func filterDataBaseList(filterTerm:String,items:[DataBaseItem]) {
        //very facncy Search Bar
        
        var filteredListOfCustomers:[DataBaseItem] = []
        for item in items {
            let rateString = String(item.rate)

            if item.sku.lowercased().contains(
                filterTerm.lowercased()
            ) || item.name.lowercased().contains(
                filterTerm.lowercased()
            ) || rateString.lowercased().contains(
                filterTerm.lowercased()
            ) || item.description.lowercased().contains(
                filterTerm.lowercased()
            ) {
                filteredListOfCustomers.append(item)
            }
        }

        self.dataBaseItemsFiltered = filteredListOfCustomers
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Receipt Subscriber
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func addListenerForAllDatabaseItems(companyId:String,storeId:String){

        print(companyId)
        DatabaseManager.shared.addListenerForAllCustomers(companyId: companyId,storeId: storeId) { [weak self] customers in
            
            self!.dataBaseItems = customers
            
        }
    }
    func removeListenerForAllDataBaseItems(){
        DatabaseManager.shared.removeListenerForAllCustomers()
        print("Listener Cancelled")
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Data Base Item Editer
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
    ) async throws {
        //DEVELOPER MAYBE DO SOME DATA VALIDATION OR
        try await DatabaseManager.shared.updateDataBaseItem(dataBaseItem: dataBaseItem, companyId: companyId, name: name, rate: rate, category: category, description: description, sku: sku, billable: billable, color: color, size: size,sellPrice: sellPrice,UOM: UOM,subCategory:subCategory, tracking: tracking)

    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Export database Items
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

}
