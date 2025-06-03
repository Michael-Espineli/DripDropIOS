//
//  ReadingsManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/22/23.
//
import SwiftUI
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Darwin

struct Reading:Identifiable, Codable,Hashable{
    
    let id :String
    let templateId :String //Universal Template Id
    let dosageType :String
//    let itemId :String
    let name: String?
    let amount : String?
    let UOM : String?
    let bodyOfWaterId : String
}


struct ReadingsTemplate:Identifiable, Codable,Hashable{
    
    let id :String
    let name: String
    let amount : [String]
    let UOM : String
    let chemType: String
    let linkedDosage:String
    let editable:Bool
    let order : Int
    let highWarning : Double?
    let lowWarning : Double?
}

struct SavedReadingsTemplate:Identifiable, Codable,Hashable{ // Same as ReadingTemplate, but it universallized the Readings Themplates
    
    let id :String
    let readingsTemplateId: String
    let name: String
    let amount : [String]
    let UOM : String
    let chemType: String
    let linkedDosage:String
    let editable:Bool
    let order : Int
    let highWarning : Double?
    let lowWarning : Double?
}
/*
final class ReadingsManager {
    
    static let shared = ReadingsManager()
    private init(){}
    
    private let db = Firestore.firestore()
    // Collections
    private func readingCollectionForServiceStop(serviceStopId:String,companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/serviceStops/\(serviceStopId)/stores")
    }
    private func readingCollectionForCustomerHistory(customerId:String,companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/stopData")
    }
    
    private func WorkOrderTemplateCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/workOrders/workOrders")
    }
    //Documents
    
    private func readingDocumentToServiceStop(serviceStopId:String,stopDataId:String,companyId:String)-> DocumentReference{
        readingCollectionForServiceStop(serviceStopId: serviceStopId, companyId: companyId).document(stopDataId)
        
    }
    
    private func readingDocumentToCustomerHistory(customerId:String,stopDataId:String,companyId:String)-> DocumentReference{
        readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId).document(stopDataId)
        
    }
    
    //functions
    func uploadReadingToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    func uploadDosagesToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    func uploadReadingAndDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) throws {
        print("Attempting to Upload Reading and Dosages List")
        let itemRef = readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId)
        itemRef.setData([
            "id": stopData.id,
            "date": stopData.date,
            "serviceStopId": stopData.serviceStopId,
            "bodyOfWaterId": stopData.bodyOfWaterId,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Uploaded Reading and Dosages List Info Successfully")
            }
        }
        var readingData:[String:Any] = [:]
        var dosageData:[String:Any] = [:]
        //Attempting to append each reading to the reading array in firestore .In side of Stop Data in the specific Customer Document
        if stopData.readings.isEmpty {
            readingData = [
                "readings": [[
                    "id": "",
                    "templateId": "",
                    "dosageType": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "bodyOfWaterId": "",

                ]]
                
            ]
            itemRef.updateData(readingData) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Uploaded Empty Reading List Successfully")
                }
            }
        }else {
            for reading in stopData.readings {
                print("Attempt To Upload Reading for \(reading.id)")

                readingData = [
                "readings": FieldValue.arrayUnion([
                        [
                            "id": reading.id,
                            "templateId": reading.templateId,
                            "dosageType": reading.dosageType,
                            "name": reading.name,
                            "amount": reading.amount,
                            "UOM": reading.UOM,
                            "bodyOfWaterId": reading.bodyOfWaterId,
                        ]])
                ]
                itemRef.updateData(readingData) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Uploaded Reading \(String(describing: reading.name)) to List Successfully")
                    }
                }
            }
        }
        //Attempting to append each reading to the reading array in firestore. In side of Stop Data in the specific Customer Document

        if stopData.dosages.isEmpty {
            dosageData = [
                "dosages": [[
                    "id": "",
                    "templateId": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "rate": "",
                    "linkedItem": "",
                    "bodyOfWaterId": "",
                ]]
                
            ]
            itemRef.updateData(dosageData) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Uploaded Empty Dosage List Successfully")
                }
            }
        } else {
            for dosage in stopData.dosages {
                print("Attempt To Upload Dosage for \(dosage.id)")

                dosageData = [
                "dosages": FieldValue.arrayUnion([[
                            "id": dosage.id,
                            "templateId": dosage.templateId,
                            "name": dosage.name,
                            "amount": dosage.amount,
                            "UOM": dosage.UOM,
                            "rate": dosage.rate,
                            "linkedItem": dosage.linkedItem,

                            "bodyOfWaterId": dosage.bodyOfWaterId,
                        ]])
                ]

                itemRef.updateData(dosageData) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Uploaded Dosage \(String(describing: dosage.name)) to List Successfully")
                    }
                }
            }
        }
    
    }
    func uploadReadingToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
        print("Uploaded Reading List")

    }
    func uploadDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
        print("Uploaded Dosage List")
    }
    
    func readFourMostRecentStops(companyId:String,customer : Customer) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsById(companyId:String,customerId : String) async throws -> [StopData]{
        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsByCustomerIdServiceLocationIdAndBodyOfWaterId(companyId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func getStopDataFromServiceStop(companyId:String,serviceStopId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> StopData{
        print("Getting Stop Data From Service Stop")
        print("serviceStopId --> \(serviceStopId)")
        print("bodyOfWaterId --> \(bodyOfWaterId)")
        let stopData = try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .getDocuments(as:StopData.self)
//        return stopData.first!
        print(stopData.first!)
        return stopData.first ?? StopData(id: "", date: Date(), serviceStopId: "", readings: [], dosages: [], bodyOfWaterId: "",
                                          customerId: "",
                                          serviceLocationId: "",
        userId: "")
    }
    func readAllHistory(companyId:String,customer : Customer) async throws -> [StopData]{
        print("Trying to get data")
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .order(by: "date", descending: true)
//            .limit(to: 5)
            .getDocuments(as:StopData.self)
        
    }
    
    func getHistoryByCustomerByDateRange(companyId:String,customer : Customer,startDate:Date,endDate:Date) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .getDocuments(as:StopData.self)
        
    }
    func RegenerateCustomerSummaries(companyId:String,customers:[Customer],dosageTemplates:[DosageTemplate]) async throws {
        for customer in customers {
            //Delete all current monthlySummaries
            try await CustomerManager.shared.deleteAllCustomerSummaries(companyId: companyId, customer: customer)
            let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
            
            for location in serviceLocations {
                for months in 1...13 {
                    let multiplier = (months * -1) + 1
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.year, .month, .day], from: Date())
                    let dateComponents = calendar.date(from: components)!
                    let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
                    
                    let pushEndDate = changingDate.endOfMonth()
                    let pushStartDate = changingDate.startOfMonth()
                    //working spot
                    print(pushStartDate)
                    print(pushEndDate)
                    
                    let specificSummary = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId: companyId, customer: customer,month: pushStartDate,serviceLocationId: location.id).first
                    
                    
                    let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
                        .whereField("date", isGreaterThan: pushStartDate)
                        .whereField("date", isLessThan: pushEndDate)
                        .getDocuments(as:StopData.self)
                    
                    //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
                    
                    print("stopHistory")
                    print(stopHistory)
                    
                    var totalData:[PNLDataPointArray] = []
                    var dataPoints:[PNLChem] = []
                    var dataPointsByDay:[PNLChem] = []
                    var dateList:[Date] = []
                    for stop in stopHistory {
                        print("stop")
                        print(stop)
                        if stop.date > pushStartDate && stop.date < pushEndDate {
                            for template in dosageTemplates {
                                let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
                                dataPoints.append(PNLDataPoint)
                            }
                            
                        }
                    }
                    for uniqueDay in dataPoints{
                        if !dateList.contains(uniqueDay.date) {
                            dateList.append(uniqueDay.date)
                            for day in dataPoints {
                                if uniqueDay.date == day.date {
                                    dataPointsByDay.append(day)
                                }
                            }
                            let serviceStop = try! await dataService.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
                            
                            totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
                            dataPointsByDay = []
                        }
                    }
                    var chemicalCost: Double = 0.00
                    var laborCost: Double = 0.00
                    
                    for data in dataPoints {
                        chemicalCost = data.totalCost + chemicalCost
                    }
                    for data in totalData {
                        laborCost = data.laborCost + laborCost
                    }
                    let totalCost = laborCost + chemicalCost
                    print("chemicalCost")
                    print(chemicalCost)
                    print("laborCost")
                    print(laborCost)
                    print("totalCost")
                    print(totalCost)
                    let fullName = (customer.firstName ) + " " + (customer.lastName )
                    
                    try await CustomerManager.shared.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: specificSummary?.id ?? "1",date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
                }
            }
            
        }
        
        
    }
    func RegenerateSingleCustomer(companyId:String,customer:Customer,dosageTemplates:[DosageTemplate]) async throws {
        //Delete all current monthlySummaries
        try await CustomerManager.shared.deleteAllCustomerSummaries(companyId:companyId,customer: customer)
        let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
        
        for location in serviceLocations {
            for months in 1...13 {
                let multiplier = (months * -1) + 1
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: Date())
                let dateComponents = calendar.date(from: components)!
                let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
                
                let pushEndDate = changingDate.endOfMonth()
                let pushStartDate = changingDate.startOfMonth()
                //working spot
                print(pushStartDate)
                print(pushEndDate)
                
//                let specificSummary = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonthAndServiceLocation(customer: customer, companyId: companyId,month: pushStartDate,serviceLocationId: location.id).first
                
                
                let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
                    .whereField("date", isGreaterThan: pushStartDate)
                    .whereField("date", isLessThan: pushEndDate)
                    .getDocuments(as:StopData.self)
                
                //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
                
                print("stopHistory")
                print(stopHistory)
                
                var totalData:[PNLDataPointArray] = []
                var dataPoints:[PNLChem] = []
                var dataPointsByDay:[PNLChem] = []
                var dateList:[Date] = []
                for stop in stopHistory {
                    print("stop")
                    print(stop)
                    if stop.date > pushStartDate && stop.date < pushEndDate {
                        for template in dosageTemplates {
                            for dosage in stop.dosages{
                                if dosage.templateId == template.id {
                                    let amount:String = dosage.amount ?? "0.00"
                                    
                                    let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(amount) ?? 0, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
                                    dataPoints.append(PNLDataPoint)
                                }
                            }
                        }
                        
                    }
                }
                for uniqueDay in dataPoints{
                    if !dateList.contains(uniqueDay.date) {
                        dateList.append(uniqueDay.date)
                        for day in dataPoints {
                            if uniqueDay.date == day.date {
                                dataPointsByDay.append(day)
                            }
                        }
                        let serviceStop = try? await dataService.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
                        
                        totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop?.techId! ?? "1",tech:serviceStop?.tech! ?? "1", laborCost: Double(serviceStop?.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
                        
                        dataPointsByDay = []
                    }
                }
                var chemicalCost: Double = 0.00
                var laborCost: Double = 0.00
                
                for data in dataPoints {
                    chemicalCost = data.totalCost + chemicalCost
                }
                for data in totalData {
                    laborCost = data.laborCost + laborCost
                }
                let totalCost = laborCost + chemicalCost
                print("chemicalCost")
                print(chemicalCost)
                print("laborCost")
                print(laborCost)
                print("totalCost")
                print(totalCost)
                let fullName = (customer.firstName ) + " " + (customer.lastName )
                
                try await CustomerManager.shared.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
            }
            
            
        }
        
        
    }

    func addStopHistory(serviceStop:ServiceStop,stopData:StopData,companyId:String) async throws{
        print("breaks here")
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
        
    }
    /*
        func CreateGenericHistory(companyId:String,customerList:[Customer],ServiceLocation:[ServiceableLocation]) async throws {
            let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
            let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
            let calendar = Calendar.current
    
            let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: user.companyId)
                .whereField("type", isEqualTo: "Weekly Cleaning")
                .getDocuments(as:WorkOrderTemplate.self)
            let weeklyCleaningTemplate = workOrderTempaltes.first
    
            var customerCount = 0
            var locationsCount = 0
    
            var serviceStopCount = 0
    
            for customer in customerList{
                var customerFullName = (customer.firstName ?? "") + " " + (customer.lastName ?? "")
    
                print("Customer \(customerFullName)")
                var counter = 0
    
                let serviceLocations = try await CustomerManager.shared.getAllCustomerServiceLocations(customer: customer)
    
                for location in serviceLocations {
    
                    for _ in 1...56 {
                        var date = Date()
    
                        var readingList:[String:String] = [:]
                        var dosageList:[String:String] = [:]
                        for readings in readingTemplates {
                            if readings.amount?.count != 0 {
                                let randomReading = readings.amount?.randomElement()
                                readingList[readings.name ?? ""] = randomReading
                            }
                        }
                        for dosage in dosageTemplates {
                            if dosage.amount?.count != 0 {
                                let randomDosage = dosage.amount?.randomElement()
                                dosageList[dosage.name ?? ""] = randomDosage
                            }
                        }
                        date = calendar.date(byAdding: .day, value: counter, to: date)!
                        let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount()
                        let id = "S" + String(dataBaseServiceStopCount)
    
                        var serviceStop = ServiceStop(id: id, typeId: weeklyCleaningTemplate?.id ?? "1", finished: true, customerName: customerFullName, customerId: customer.id, address: customer.billingAddress, dateCreated: date, serviceDate: date, duration: 15, rate: 15, tech: user.displayName, techId: user.id, invoiced: false, description: "NA", serviceLocationId: location.id, type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning")//It might get fuckie without a real serviceLocationId
    
                        try await dataService.uploadServiceStop(serviceStop: serviceStop)
    
                        print("Created servcice stop on \(fullDate(date: date))")
    
                        var stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList)
    
                        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: user.companyId).setData(from:stopData, merge: false)
    
                        print("Added Stop Data")
                        counter = counter - 7
                        serviceStopCount = serviceStopCount + 1
                        print("Service Stop Count \(serviceStopCount)")
    
                    }
                    locationsCount = locationsCount + 1
                    print("Service Location Count \(locationsCount)")
    
                    for months in 1...13 {
                        let multiplier = (months * -1) + 1
                        let calendar = Calendar.current
                        let components = calendar.dateComponents([.year, .month, .day], from: Date())
                        let dateComponents = calendar.date(from: components)!
                        let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
    
                        var pushEndDate = changingDate.endOfMonth()
                        var pushStartDate = changingDate.startOfMonth()
    
    
                        //working spot
                        print(pushStartDate)
                        print(pushEndDate)
    
                        let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: user.companyId)
                            .whereField("date", isGreaterThan: pushStartDate)
                            .whereField("date", isLessThan: pushEndDate)
                            .getDocuments(as:StopData.self)
    
        //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
    
                        print("stopHistory")
                        print(stopHistory)
    
                        var totalData:[PNLDataPointArray] = []
                        var dataPoints:[PNLChem] = []
                        var dataPointsByDay:[PNLChem] = []
                        var dateList:[Date] = []
                        for stop in stopHistory {
                            print("stop")
                            print(stop)
                            if stop.date > pushStartDate && stop.date < pushEndDate {
                                for template in dosageTemplates {
                                    let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
                                    dataPoints.append(PNLDataPoint)
                                }
    
                            }
                        }
                        for uniqueDay in dataPoints{
                            if !dateList.contains(uniqueDay.date) {
                                dateList.append(uniqueDay.date)
                                for day in dataPoints {
                                    if uniqueDay.date == day.date {
                                        dataPointsByDay.append(day)
                                    }
                                }
                                let serviceStop = try! await dataService.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: user.companyId)
    
                                totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
                                dataPointsByDay = []
                            }
                        }
                        var chemicalCost: Double = 0.00
                        var laborCost: Double = 0.00
    
                        for data in dataPoints {
                            chemicalCost = data.totalCost + chemicalCost
                        }
                        for data in totalData {
                            laborCost = data.laborCost + laborCost
                        }
                        let totalCost = laborCost + chemicalCost
                        print("chemicalCost")
                        print(chemicalCost)
                        print("laborCost")
                        print(laborCost)
                        print("totalCost")
                        print(totalCost)
                        let fullName = (customer.firstName ) + " " + (customer.lastName )
    
                        try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
                    }
    
                }
    
                customerCount = customerCount + 1
                print("Customer Count \(customerCount)")
                //remove before Production
    
                if customerCount > 10{
                    return
                }
    
            }
        }
    func CreateGenericHistory2(companyId:String,customer:Customer,ServiceLocation:[ServiceableLocation]) async throws {
        let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        let calendar = Calendar.current
        
        let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("type", isEqualTo: "Weekly Cleaning")
            .getDocuments(as:JobTemplate.self)
        let weeklyCleaningTemplate = workOrderTempaltes.first
        
        var customerCount = 0
        var locationsCount = 0
        
        var serviceStopCount = 0
        
        let customerFullName = (customer.firstName ) + " " + (customer.lastName )
        
        print("Customer \(customerFullName)")
        var counter = 0
        
        let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
        
        for location in serviceLocations {
            
            for _ in 1...56 {
                print("Service Location Id")
                print(location.id)
                let bodiesOfWater = try await BodyOfWaterManager.shared.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: location)
                
                //creates service Stop
                var date = Date()
                
                
                date = calendar.date(byAdding: .day, value: counter, to: date)!
                let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: company.id)
                let id = "S" + String(dataBaseServiceStopCount)
                
                let serviceStop = ServiceStop(id: id,
                                              typeId: weeklyCleaningTemplate?.id ?? "1",
                                              customerName: customerFullName,
                                              customerId: customer.id,
                                              address: customer.billingAddress,
                                              dateCreated: date,
                                              serviceDate: date,
                                              duration: 15,
                                              rate: 15,
                                              techId: user.id,
                                              recurringServiceStopId: "NA",
                                              description: "",
                                              serviceLocationId: location.id,
                                              type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning",
                                              typeImage: weeklyCleaningTemplate?.typeImage ?? "bubbles.and.sparkles.fill",
                                              workOrderId: "",
                                              finished: true,
                                              skipped: false,
                                              invoiced: true,checkList: []
                                              ,includeReadings: true,includeDosages: true)
                
                
                try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
                
                print("Created servcice stop on \(fullDate(date: date))")
                
                
                for bodyOfWater in bodiesOfWater {
                    
                    var readingList:[Reading] = []
                    var dosageList:[Dosage] = []
                    for readings in readingTemplates {
                        if readings.amount.count != 0 {
                            let randomReading = readings.amount.randomElement()
                            readingList.append(Reading(id: UUID().uuidString, templateId: readings.id, dosageType: readings.chemType, name: readings.name, amount: randomReading, UOM: readings.UOM, bodyOfWaterId: bodyOfWater.id))
                        }
                    }
                    for dosage in dosageTemplates {
                        if dosage.amount?.count != 0 {
                            let randomDosage = dosage.amount?.randomElement()
                            dosageList.append(Dosage(id: UUID().uuidString, templateId: dosage.id, name: dosage.name,amount:randomDosage, UOM: dosage.UOM, rate: dosage.rate, linkedItem:dosage.linkedItemId ?? "1" , bodyOfWaterId: bodyOfWater.id))
                        }
                    }
                    let stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList, bodyOfWaterId: bodyOfWater.id)
                    
                    try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
                    
                    print("Added Stop Data")
                    counter = counter - 7
                    serviceStopCount = serviceStopCount + 1
                    print("Service Stop Count \(serviceStopCount)")
                }
                
            }
            locationsCount = locationsCount + 1
            print("Service Location Count \(locationsCount)")
            
            for months in 1...13 {
                let multiplier = (months * -1) + 1
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month, .day], from: Date())
                let dateComponents = calendar.date(from: components)!
                let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
                
                let pushEndDate = changingDate.endOfMonth()
                let pushStartDate = changingDate.startOfMonth()
                
                
                //working spot
                print(pushStartDate)
                print(pushEndDate)
                
                let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
                    .whereField("date", isGreaterThan: pushStartDate)
                    .whereField("date", isLessThan: pushEndDate)
                    .getDocuments(as:StopData.self)
                
                //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
                
                print("stopHistory")
                print(stopHistory)
                
                var totalData:[PNLDataPointArray] = []
                var dataPoints:[PNLChem] = []
                var dataPointsByDay:[PNLChem] = []
                var dateList:[Date] = []
                for stop in stopHistory {
                    print("stop")
                    print(stop)
                    if stop.date > pushStartDate && stop.date < pushEndDate {
                        for template in dosageTemplates {
                            let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
                            dataPoints.append(PNLDataPoint)
                        }
                        
                    }
                }
                for uniqueDay in dataPoints{
                    if !dateList.contains(uniqueDay.date) {
                        dateList.append(uniqueDay.date)
                        for day in dataPoints {
                            if uniqueDay.date == day.date {
                                dataPointsByDay.append(day)
                            }
                        }
                        let serviceStop = try! await dataService.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
                        
                        totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
                        dataPointsByDay = []
                    }
                }
                var chemicalCost: Double = 0.00
                var laborCost: Double = 0.00
                
                for data in dataPoints {
                    chemicalCost = data.totalCost + chemicalCost
                }
                for data in totalData {
                    laborCost = data.laborCost + laborCost
                }
                let totalCost = laborCost + chemicalCost
                print("chemicalCost")
                print(chemicalCost)
                print("laborCost")
                print(laborCost)
                print("totalCost")
                print(totalCost)
                let fullName = (customer.firstName ) + " " + (customer.lastName )
                
                try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
            }
            
        }
        
        customerCount = customerCount + 1
        print("Customer Count \(customerCount)")
        //remove before Production
        
        //            if customerCount > 0{
        //                return
        //            }
        
        
    }
    func CreateGenericHistory3(companyId:String,customer:Customer,location:ServiceableLocation) async throws {
        let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        let calendar = Calendar.current
        
        let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("type", isEqualTo: "Weekly Cleaning")
            .getDocuments(as:JobTemplate.self)
        let weeklyCleaningTemplate = workOrderTempaltes.first
        
        var customerCount = 0
        var locationsCount = 0
        
        var serviceStopCount = 0
        
        let customerFullName = (customer.firstName ) + " " + (customer.lastName )
        
        print("Customer \(customerFullName)")
        var counter = 0
        
//        let serviceLocations = try await CustomerManager.shared.getAllCustomerServiceLocations(customer: customer)
        
        
        for _ in 1...56 {
            print("Service Location Id")
            print(location.id)
            let bodiesOfWater = try await BodyOfWaterManager.shared.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: location)
            
            //creates service Stop
            var date = Date()
            
            
            date = calendar.date(byAdding: .day, value: counter, to: date)!
            let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount()
            let id = "S" + String(dataBaseServiceStopCount)
            
            let serviceStop = ServiceStop(id: id,
                                          typeId: weeklyCleaningTemplate?.id ?? "1",
                                          customerName: customerFullName,
                                          customerId: customer.id,
                                          address: customer.billingAddress,
                                          dateCreated: date,
                                          serviceDate: date,
                                          duration: 15,
                                          rate: 15,
                                          techId: user.id,
                                          recurringServiceStopId: "NA",
                                          description: "",
                                          serviceLocationId: location.id,
                                          type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning",
                                          typeImage: weeklyCleaningTemplate?.typeImage ?? "bubbles.and.sparkles.fill",
                                          workOrderId: "",
                                          finished: true,
                                          skipped: false,
                                          invoiced: true,checkList: []
                                          ,includeReadings: true,includeDosages: true)
            
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
            
            print("Created servcice stop on \(fullDate(date: date))")
            
            
            for bodyOfWater in bodiesOfWater {
                
                var readingList:[Reading] = []
                var dosageList:[Dosage] = []
                for readings in readingTemplates {
                    if readings.amount.count != 0 {
                        let randomReading = readings.amount.randomElement()
//                        print(randomReading)
                        readingList.append(Reading(id: UUID().uuidString, templateId: readings.id, dosageType: readings.chemType, name: readings.name, amount: randomReading, UOM: readings.UOM, bodyOfWaterId: bodyOfWater.id))
                    }
                }
                for dosage in dosageTemplates {
                    if dosage.amount?.count != 0 {
                        var amount = "0"
                        if dosage.name == "Liquid Chlorine"{
                            amount = "1.00"
                            
                        }
                        dosageList.append(Dosage(id: UUID().uuidString, templateId: dosage.id, name: dosage.name,amount:amount, UOM: dosage.UOM, rate: dosage.rate, linkedItem:dosage.linkedItemId ?? "1" , bodyOfWaterId: bodyOfWater.id))
                        
                    }
                }
                let stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList, bodyOfWaterId: bodyOfWater.id)
                
                try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
                
                print("Added Stop Data")
                counter = counter - 7
                serviceStopCount = serviceStopCount + 1
                print("Service Stop Count \(serviceStopCount)")
            }
            
        }
        locationsCount = locationsCount + 1
        print("Service Location Count \(locationsCount)")
        
        for months in 1...13 {
            let multiplier = (months * -1) + 1
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: Date())
            let dateComponents = calendar.date(from: components)!
            let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
            
            let pushEndDate = changingDate.endOfMonth()
            let pushStartDate = changingDate.startOfMonth()
            
            
            //working spot
            print(pushStartDate)
            print(pushEndDate)
            
            let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
                .whereField("date", isGreaterThan: pushStartDate)
                .whereField("date", isLessThan: pushEndDate)
                .getDocuments(as:StopData.self)
            
            //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
            
            print("stopHistory")
            print(stopHistory)
            
            var totalData:[PNLDataPointArray] = []
            var dataPoints:[PNLChem] = []
            var dataPointsByDay:[PNLChem] = []
            var dateList:[Date] = []
            for stop in stopHistory {
                print("stop")
                print(stop)
                if stop.date > pushStartDate && stop.date < pushEndDate {
                    for template in dosageTemplates {
                        for dosage in stop.dosages {
                            if dosage.templateId == template.id {
                                let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(dosage.amount ?? "0.00") ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
                                dataPoints.append(PNLDataPoint)
                            }
                        }
                    }
                    
                }
            }
            for uniqueDay in dataPoints{
                if !dateList.contains(uniqueDay.date) {
                    dateList.append(uniqueDay.date)
                    for day in dataPoints {
                        if uniqueDay.date == day.date {
                            dataPointsByDay.append(day)
                        }
                    }
                    let serviceStop = try! await dataService.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
                    
                    totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
                    dataPointsByDay = []
                }
            }
            var chemicalCost: Double = 0.00
            var laborCost: Double = 0.00
            
            for data in dataPoints {
                chemicalCost = data.totalCost + chemicalCost
            }
            for data in totalData {
                laborCost = data.laborCost + laborCost
            }
            let totalCost = laborCost + chemicalCost
            print("chemicalCost")
            print(chemicalCost)
            print("laborCost")
            print(laborCost)
            print("totalCost")
            print(totalCost)
            let fullName = (customer.firstName ) + " " + (customer.lastName )
            
            try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
        }
        
        
        
        customerCount = customerCount + 1
        print("Customer Count \(customerCount)")
        //remove before Production
        
        //            if customerCount > 0{
        //                return
        //            }
        
        
    }
    */
}
*/
