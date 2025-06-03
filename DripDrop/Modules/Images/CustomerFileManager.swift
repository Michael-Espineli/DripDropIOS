//
//  CustomerFileManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/9/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
import CoreXLSX
import XMLCoder
import ZIPFoundation

public struct XLSXFile2 {
    public let filepath: String
    private let archive: Archive
    private let decoder: XMLDecoder
    
    public init?(filepath: String) {
        let archiveURL = URL(fileURLWithPath: filepath)
        
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            return nil
        }
        
        self.archive = archive
        self.filepath = filepath
        
        decoder = XMLDecoder()
    }
}
@MainActor
final class CustomerFileManager:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var isLoading: Bool? = nil
    @Published private(set) var loadingText: String? = nil
    @Published private(set) var totalCustomer: Int? = nil
    @Published private(set) var currentCustomer: Int? = nil
    @Published private(set) var listOfWorkSheets: [String] = []
    
    
    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil
    func getWorkSheetsInXslxFile(pathName:String,fileName:String,companyId: String) async throws{
        var listOfWorkSheets:[String] = []
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
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                    listOfWorkSheets.append(worksheetName)
                }
                let worksheet = try file.parseWorksheet(at: path)
                print("Has \((worksheet.data?.rows ?? []).count) rows")
            }
            self.listOfWorkSheets = listOfWorkSheets
        }
    }
    
    func uploadXlsxFileTo(pathName:String,fileName:String,companyId: String,workSheetName:String) async throws{
        self.isLoading = true
        self.loadingText = "Handling the Excel File Step 1/2"
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
        var excelCustomerList:[CSVCustomer] = []
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
                        var numberOfLetters:[String] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"]
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
                                
                                var excelCustomerRow:[String] = []
                                var letterCount:Int = 0
                                
                                for letter in numberOfLetters {
                                    if letterCount != numberOfColumns{
                                        
                                        if let sharedStrings = try file.parseSharedStrings() {
                                            let cellString = worksheet.cells(atColumns: [ColumnReference(letter)!], rows: [UInt(rowCount)])
                                                .compactMap { $0.stringValue(sharedStrings) }
                                            //                                    print("Cell: \(cellString)")
                                            excelCustomerRow.append(cellString.first ?? "")
                                            
                                        }
                                        letterCount = letterCount + 1
                                    }
                                }
                                let customerStruct = CSVCustomer.init(raw: excelCustomerRow)
                                print(customerStruct)
                                if customerStruct.firstName == "" && customerStruct.lastName == "" && customerStruct.streetAddress == "" && customerStruct.city == "" && customerStruct.phone == ""  && customerStruct.email == ""  && customerStruct.rate == ""{
                                    print("Skipped")
                                    exitFunc = true
                                } else {
                                    if customerStruct.firstName == "First Name" {
                                        print("Skipped the frirst Title Row")
                                    } else {
                                        excelCustomerList.append(customerStruct)
                                        self.currentCustomer = excelCustomerList.count
                                        print("Successfully added Customer # \(excelCustomerList.count)")
                                    }
                                }
                       
                            }
                            else {
                                print("Break")
                                break
                            }
                        }
                    }
                }
            }
        }
        //HERE
        self.currentCustomer = 0
        self.loadingText = "Uploading to the cloud Step 2/2"
        self.totalCustomer = excelCustomerList.count
        //This will Fail if there are any double spaced columns
        print("Excel Customer List Count \(excelCustomerList.count)")
        var customerCount = 0
        for customer in excelCustomerList {
            let fullName = customer.firstName + " " + customer.lastName
            try await dataService.uploadCSVCustomerToFireStore(companyId: companyId, customer: customer)
            //remove before Production
            customerCount = customerCount + 1
            self.currentCustomer = customerCount
            print(" \(fullName) To FirstStore #\(customerCount)")

        }
        self.isLoading = false

    }
    
    func uploadCsvFileTo(pathName:String,fileName:String,companyId: String) async {
        let fileURL = URL(fileURLWithPath: pathName).appendingPathExtension("csv")
        var customerCount = 0
        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            print("Successfully Read")
            let customerList = try await dataService.convertCustomerCSVToStruct(contents: text2)
            print("Successfully Converted")
            self.totalCustomer = customerList.count
            //This will Fail if there are any double spaced columns
            for customer in customerList {
                let fullName = customer.firstName + " " + customer.lastName
                
                try await dataService.uploadCSVCustomerToFireStore(companyId: companyId, customer: customer)
                //remove before Production
                customerCount = customerCount + 1
                self.loadingText = fullName
                self.currentCustomer = customerCount + 1
                
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
    
    func uploadCSVCustomerToFireStore(customer: CSVCustomer,companyId: String) async throws{
        
        print("Begin to UpLoad \(customer.firstName) \(customer.lastName) to Firestore 1")
        let identification:String = UUID().uuidString
        var DBAddress = Address(streetAddress: customer.streetAddress, city: customer.city, state: customer.state, zip: customer.zip,latitude: 0.0,longitude: 0.0)
        
        let fulladdress = DBAddress.streetAddress + " " + DBAddress.city + " " + DBAddress.state + " " + DBAddress.zip
        let fullName = customer.firstName + " " + customer.lastName
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate
        }
        //add back in before production or if I am adding more than 50 customers
        let hireDateString = customer.hireDate
        
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        
        // Convert String to Date
        let hireDate:Date = dateFormatter.date(from: hireDateString) ?? Date()
        
        usleep(1201000)
        
        let pushCoordinates = self.Coordinates
        DBAddress.latitude = pushCoordinates?.latitude ?? 32.8
        DBAddress.longitude = pushCoordinates?.longitude ?? -117.8
        print("Received Coordinates from geoCoder : \(String(describing: pushCoordinates))")
        
        let DBCustomer:Customer = Customer(
            id: identification,
            firstName: customer.firstName ,
            lastName:customer.lastName,
            email:customer.email,
            billingAddress:DBAddress ,
            phoneNumber: customer.phone,
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: hireDate,
            billingNotes: "NA",
            linkedInviteId: UUID().uuidString
        )
        
        print("Uploading Customer")
        try await dataService.uploadCustomer(companyId: companyId, customer: DBCustomer)
        let serviceLocationId:String = UUID().uuidString
        let bodyOfWaterId:String = UUID().uuidString
        
        sleep(1)
        //Uploading Customer Billing Type
        let billingTempalte = try await BillingManager.shared.getDefaultBillingTempalte(companyId: companyId)
        
        //Uploading Customer Service Locations
        
        let serviceLocation:ServiceLocation = ServiceLocation(
            id: serviceLocationId,
            nickName: (
                (
                    DBCustomer.firstName
                ) + " " + (
                    DBCustomer.lastName
                )
            ),
            address: DBCustomer.billingAddress,
            gateCode: "",
            mainContact: Contact(
                id: UUID().uuidString,
                name: (
                    (
                        DBCustomer.firstName
                    ) + " " + (
                        DBCustomer.lastName
                    )
                ),
                phoneNumber: DBCustomer.phoneNumber ?? "",
                email: DBCustomer.email,
                notes: ""
            ),
            bodiesOfWaterId: [bodyOfWaterId],
            rateType: billingTempalte.title,
            laborType: billingTempalte.laborType,
            chemicalCost: billingTempalte.chemType,
            laborCost: "15",
            rate: customer.rate,
            customerId: DBCustomer.id,
            customerName: (
                (
                    DBCustomer.firstName
                ) + " " + (
                    DBCustomer.lastName
                )
            ),
            preText: false
        )
        
        try await ServiceLocationManager.shared.uploadCustomerServiceLocations(companyId: companyId,
                                                                               customer: DBCustomer,
                                                                               serviceLocation: serviceLocation)
        print(
            "Sucessfully uploading customer Service Location"
        )
        //Uploading Body of water
        let bodyOfwater = BodyOfWater(
            id: bodyOfWaterId,
            name: "Main",
            gallons: "16000",
            material: "Plaster",
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id, 
            lastFilled: Date()
        )
        try await BodyOfWaterManager.shared.uploadBodyOfWaterByServiceLocation(
            companyId: companyId,
            bodyOfWater: bodyOfwater
        )
        print(
            "Sucessfully uploading Body of water for \(DBCustomer.firstName) \(DBCustomer.lastName)"
        )
        
        let pump = Equipment(
            id: UUID().uuidString,
            name:"Pump 1",
            category: .pump,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id, 
            isActive: true
        )
        try await EquipmentManager.shared.uploadEquipment(
            companyId: companyId,
            equipment: pump
        )
        print(
            "Sucessfully uploading \(pump.category) for \(DBCustomer.firstName) \(DBCustomer.lastName)"
        )
        
        let filter = Equipment(
            id: UUID().uuidString,
            name:"Filter 1",
            category: .filter,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: true,
            lastServiceDate: Date(),
            serviceFrequency: "Month",
            serviceFrequencyEvery: "6",
            nextServiceDate: getNextServiceDate(
                lastServiceDate: Date(),
                every: "6",
                frequency: "Month"
            ),
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id, 
            isActive: true
        )
        try await EquipmentManager.shared.uploadEquipment(
            companyId: companyId,
            equipment: filter
        )
        print(
            "Sucessfully uploading \(filter.category) for \(DBCustomer.firstName) \(DBCustomer.lastName)"
        )
        
        print(
            "Successfully Uploaded \(customer.firstName) \(customer.lastName) to Firestore"
        )
        
    }
    
}
