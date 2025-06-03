//
//  RecurringServiceStop+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import CoreLocation
import MapKit
import Darwin
struct RecurringServiceStop:Identifiable, Codable,Equatable, Hashable{
    static func == (lhs: RecurringServiceStop, rhs: RecurringServiceStop) -> Bool {
        return lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.typeId == rhs.typeId &&
        lhs.customerId == rhs.customerId &&
        lhs.serviceLocationId == rhs.serviceLocationId
    }
    var id :String
    var internalId : String
    let type: String
    let typeId: String
    let typeImage: String
    let customerName : String
    let customerId : String
    let address: Address
    let tech: String
    let techId: String
    let dateCreated : Date
    let startDate :Date
    let endDate :Date?
    let noEndDate: Bool
    let frequency: LaborContractFrequency // was customMeasuresOfTime
    let daysOfWeek:String //DEVELOPER there is going to be only one day in here but it should work.
    let description : String
    var lastCreated : Date
    let serviceLocationId : String	
    let estimatedTime : String
    let otherCompany:Bool
    let laborContractId:String? //Actually Optional
    let contractedCompanyId:String? //Actually Optional
    var mainCompanyId : String?

    init(
        id: String,
        internalId :String,
        type :String,
        typeId : String,
        typeImage : String,
        customerName : String,
        customerId : String,
        address : Address,
        tech : String,
        techId: String,
        dateCreated : Date,
        startDate: Date,
        endDate : Date? = nil,
        noEndDate: Bool,
        frequency : LaborContractFrequency,
        daysOfWeek: String,
        description: String,
        lastCreated: Date,
        serviceLocationId: String,
        estimatedTime: String,
        otherCompany: Bool,
        laborContractId: String? = nil,
        contractedCompanyId: String? = nil,
        mainCompanyId: String? = nil
        
    ){
        self.id = id
        self.internalId = internalId
        self.type = type
        self.typeId = typeId
        self.typeImage = typeImage
        self.customerName = customerName
        self.customerId = customerId
        self.address = address
        self.tech = tech
        self.techId = techId
        self.dateCreated = dateCreated
        self.startDate = startDate
        self.endDate = endDate
        self.noEndDate = noEndDate
        self.frequency = frequency
        self.daysOfWeek = daysOfWeek
        self.description = description
        self.lastCreated = lastCreated
        self.serviceLocationId = serviceLocationId
        self.estimatedTime = estimatedTime
        self.otherCompany = otherCompany
        self.laborContractId = laborContractId
        self.contractedCompanyId = contractedCompanyId
        self.mainCompanyId = mainCompanyId
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case internalId = "internalId"
            case type = "type"
            case typeId = "typeId"
            case typeImage = "typeImage"
            case customerName = "customerName"
            case customerId = "customerId"
            case address = "address"
            case tech = "tech"
            case techId = "techId"
            case dateCreated = "dateCreated"
            case endDate = "endDate"
            case startDate = "startDate"
            case noEndDate = "noEndDate"
            case frequency = "frequency"
            case daysOfWeek = "daysOfWeek"
            case description = "description"
            case lastCreated = "lastCreated"
            case serviceLocationId = "serviceLocationId"
            case estimatedTime = "estimatedTime"
            case otherCompany = "otherCompany"
            case laborContractId = "laborContractId"
            case contractedCompanyId = "contractedCompanyId"
            case mainCompanyId = "mainCompanyId"
        }
}

extension ProductionDataService {
    //Refrences
    func recurringServiceStopCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/recurringServiceStop")
    }
    func recurringServiceStopDocument(recurringServiceStopId:String,companyId:String)-> DocumentReference{
        recurringServiceStopCollection(companyId: companyId).document(recurringServiceStopId)
    }
    //CREATE - More in below Extension
    func uploadRecurringServiceStop(companyId:String,recurringServiceStop : RecurringServiceStop) async throws {
        
        try recurringServiceStopDocument(recurringServiceStopId: recurringServiceStop.id,companyId: companyId).setData(from:recurringServiceStop, merge: true)
    }

    //READ
    func getRecurringServiceStopByServiceLocationId(companyId: String, serviceLocationId: String) async throws -> [RecurringServiceStop] {
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments(as:RecurringServiceStop.self)
    }
    func getSingleRecurringServiceStop(companyId:String,recurringServiceStopId:String) async throws -> RecurringServiceStop {
        return try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId).getDocument(as:RecurringServiceStop.self)
    }
    func getAllRecurringServiceStop(companyId:String) async throws -> [RecurringServiceStop] {
        return try await recurringServiceStopCollection(companyId: companyId)
            .getDocuments(as:RecurringServiceStop.self)
    }
    //    func getRecurringServiceStopsByTechAndDay(user:DBUser,tech:CompanyUser,day:String) async throws -> [RecurringServiceStop] {
    //
    //        return try await recurringServiceStopCollection(companyId: user.companyId)
    //            .whereField("techId", isEqualTo: tech.id)
    //            .whereField("daysOfWeek", arrayContains: day)
    //            .getDocuments(as:RecurringServiceStop.self)
    //
    //    }
    func getReucrringServiceStopsWithOutEndDate(companyId:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField("noEndDate", isEqualTo: true)
            .getDocuments(as:RecurringServiceStop.self)
        
    }
    func getRecurringServiceStopsByDays(companyId:String,day:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.daysOfWeek.rawValue, arrayContains: day)
            .getDocuments(as:RecurringServiceStop.self)
    }
    
    func getRecurringServiceStopsByDayAndTech(companyId:String,techId:String,day:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.daysOfWeek.rawValue, arrayContains: day)
            .whereField(RecurringServiceStop.CodingKeys.techId.rawValue, isEqualTo: techId)
        
            .getDocuments(as:RecurringServiceStop.self)
    }
    
    func getAllRecurringServiceStopByCustomerId(companyId:String,customerId:String) async throws -> [RecurringServiceStop]{
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RecurringServiceStop.self)
        
    }
    //UPDATE
    func updateRecurringServiceStopAddress(companyId: String, recurringServiceStopId: String, address: Address) async throws {
        let recurringServiceStopRef = recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId)
        try await recurringServiceStopRef.updateData(
            [
                RecurringServiceStop.CodingKeys.address.stringValue: [
                    Address.CodingKeys.streetAddress.stringValue: address.streetAddress,
                    Address.CodingKeys.city.stringValue: address.city,
                    Address.CodingKeys.state.stringValue: address.state,
                    Address.CodingKeys.zip.stringValue: address.zip,
                    Address.CodingKeys.latitude.stringValue:address.latitude ,
                    Address.CodingKeys.longitude.stringValue:address.longitude ,
                ] as [String : Any]
            ]
        )
    }
    func endRecurringServiceStop(companyId:String,recurringServiceStopId:String,endDate:Date) async throws {
        //DEVELOPER ADD LOGIC
        print("End Recurring Service Stop Logic")
        try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId)
            .updateData([
                "noEndDate": false,
                "endDate":endDate
            ])
    }
    //DELETE
    func deleteRecurringServiceStop(companyId:String,recurringServiceStopId : String) async throws {
        try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId)
            .delete()
        
    }
}
//ADDITIONAL CREATE FUNCTIONS
extension ProductionDataService {
    func addNewRecurringServiceStopFromLaborContract(companyId:String,recurringServiceStop:RecurringServiceStop,laborContract:ReccuringLaborContract) async throws ->(String?) {
        print("addNewRecurringServiceStop - [DataService]")
        let startDate:Date = recurringServiceStop.startDate
        
        guard let endDate:Date = recurringServiceStop.endDate else {
            return nil
        }
        let noEndDate:Bool = recurringServiceStop.noEndDate
        //initial Creating of the Route
        

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        var pushRecurring = recurringServiceStop
        
        switch recurringServiceStop.frequency{
        case .daily:
            print("Making Stops Daily")
            try await helpCreateDailyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            //Daily
        case .weekDay:
            //skipped weekends
            print("Making Stops on Week days")
            try await helpCreateWeekDayRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
        case .weekly:
            //weekly
            print("Making Stops Weekly")
            try await helpCreateWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
        case .biWeekly:
            //weekly
            print("Making Stops Bi Weekly")
            try await helpCreateBiWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
            
        case .monthly:
            //Monthly
            print("Making Stops Monthly")
            try await helpCreateMonthlyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

        case .yearly:
            print("Developer Make Daily")
        }
        print("Finished Creating Recurring Route and Returning recurringServiceStopId >>\(pushRecurring.id)")

        return pushRecurring.id
    }

    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop) async throws ->(String?){
        print("addNewRecurringServiceStop - [DataService]")
        let startDate:Date = recurringServiceStop.startDate
        
        guard let endDate:Date = recurringServiceStop.endDate else {
            return nil
        }
        let noEndDate:Bool = recurringServiceStop.noEndDate
        //initial Creating of the Route
        
        let recurringServiceStopCount = try await SettingsManager.shared.getRecurringServiceStopCount(companyId: companyId)
        sleep(1)
        let recurringServiceStopId = "R" + String(recurringServiceStopCount)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        var pushRecurring = recurringServiceStop
        pushRecurring.id = recurringServiceStopId
        switch recurringServiceStop.frequency{
        case .daily:
            print("Making Stops Daily")
            try await helpCreateDailyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            //Daily
        case .weekDay:
            //skipped weekends
            print("Making Stops on Week days")
            try await helpCreateWeekDayRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
        case .weekly:
            //weekly
            print("Making Stops Weekly")
            try await helpCreateWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
        case .biWeekly:
            //weekly
            print("Making Stops Bi Weekly")
            try await helpCreateBiWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
            
        case .monthly:
            //Monthly
            print("Making Stops Monthly")
            try await helpCreateMonthlyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

        case .yearly:
            print("Developer Make Daily")
        }
        print("Finished Creating Recurring Route and Returning recurringServiceStopId >>\(recurringServiceStopId)")

        return recurringServiceStopId
    }
    
    func modifyRecurringServiceStopToNew(
        companyId:String,
        recurringServiceStop:RecurringServiceStop,
        customFrequencyType:String,
        CustomFrequency:String,
        daysOfWeek:[String],
        oldRss:RecurringServiceStop,
        old:[ServiceStop]
    ) async throws ->(String?){
        //Developer Create Functions that will Update Service Stops based on NEw RSS Rather than Create New ones

        let calendar = Calendar.current
        let startDate:Date = recurringServiceStop.startDate
        guard let endDate:Date = recurringServiceStop.endDate else {
            return nil
        }
        let noEndDate:Bool = recurringServiceStop.noEndDate
        //initial Creating of the Route
        let recurringServiceStopCount = try await SettingsManager.shared.getRecurringServiceStopCount(companyId: companyId)
        sleep(1)
        let recurringServiceStopId = "R" + String(recurringServiceStopCount)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week

        var pushRecurring = recurringServiceStop
        pushRecurring.id = recurringServiceStopId
        switch recurringServiceStop.frequency{
        case .daily:
            print("Making Stops Daily")
         //   try await helpCreateDailyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
            //Daily
        case .weekDay:
            //skipped weekends
            print("Making Stops on Week days")
//            try await helpCreateWeekDayRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

        case .weekly:
            //weekly
            print("Making Stops Weekly")
//            try await helpModifyWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate,RSS: oldRss,serviceStopsList: old)

        case .biWeekly:
            //weekly
            print("Making Stops Bi Weekly")
//            try await helpCreateBiWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

            
        case .monthly:
            //Monthly
            print("Making Stops Monthly")
//            try await helpCreateMonthlyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
        default:
            print("Error in add New Recurring Service Stop - Recurring Route Manager")
        }
        print("Finished Creating Recurring Route and Returning recurringServiceStopId >>\(recurringServiceStopId)")
        return recurringServiceStopId
    }
    func helpCreateDailyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                       noEndDate:Bool,startDate:Date,endDate:Date) async throws{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        var functionalStartDate:Date = Date()
        var functionalEndDate:Date = Date()
        let calendar = Calendar.current
        var lastCreated:Date = Date()
        
        var counter :Int = 0
        
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        print("Creating standard Recurring service stop")
        while counter < daysBetween {
            var pushDate = Date()
            pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
            
            var otherCompany = false
            if recurringServiceStop.otherCompany {
                otherCompany = true
            } else {
                otherCompany = true
            }
            
            let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)

            let singleRecurringServiceStop = ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: "SS" + String(doc.increment),
                companyId: companyId,
                companyName: "",
                customerId: recurringServiceStop.customerId,
                customerName: recurringServiceStop.customerName,
                address: recurringServiceStop.address,
                dateCreated: Date(),
                serviceDate: pushDate,
                startTime: nil,
                endTime: nil,
                duration: Int(recurringServiceStop.estimatedTime) ?? 15,
                estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                tech: recurringServiceStop.tech,
                techId: recurringServiceStop.techId,
                recurringServiceStopId: recurringServiceStop.id,
                description: recurringServiceStop.description,
                serviceLocationId: recurringServiceStop.serviceLocationId,
                typeId: recurringServiceStop.typeId,
                type: recurringServiceStop.type,
                typeImage: recurringServiceStop.typeImage,
                jobId: "",
                jobName: "",
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: otherCompany,
                laborContractId: recurringServiceStop.laborContractId ?? "",
                contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                isInvoiced: false
            )
            
            //                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
            //                    let serviceStopId = "S" + String(serviceStopCount)
            
            try await uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
            if pushDate > lastCreated {
                lastCreated = pushDate
            }
            
            print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")
            
            counter = counter + 1
        }
    }
    //WeekDay
    func helpCreateWeekDayRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async throws{
        var functionalStartDate:Date = Date()
        var functionalEndDate:Date = Date()
        let calendar = Calendar.current
        var lastCreated:Date = Date()
        var counter :Int = 0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        print("Creating standard Recurring service stop")
        while counter < daysBetween {
            var pushDate = Date()
            
            pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
            
            
            
            if String(dateFormatter.string(from:pushDate)) == "Saturday" || String(dateFormatter.string(from:pushDate)) == "Sunday" {
                print(String(dateFormatter.string(from:pushDate)))
                
                print("Skipped")
            }else {
                var otherCompany = false
                if recurringServiceStop.otherCompany {
                    otherCompany = true
                } else {
                    otherCompany = true
                }
                let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)

                let singleRecurringServiceStop = ServiceStop(
                    id: "comp_ss_" + UUID().uuidString,
                    internalId: "S" + String(doc.increment),
                    companyId: companyId,
                    companyName: "",
                    customerId: recurringServiceStop.customerId,
                    customerName: recurringServiceStop.customerName,
                    address: recurringServiceStop.address,
                    dateCreated: Date(),
                    serviceDate: pushDate,
                    startTime: nil,
                    endTime: nil,
                    duration: 0,
                    estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                    tech: recurringServiceStop.tech,
                    techId: recurringServiceStop.techId,
                    recurringServiceStopId: recurringServiceStop.id,
                    description: recurringServiceStop.description,
                    serviceLocationId: recurringServiceStop.serviceLocationId,
                    typeId: recurringServiceStop.typeId,
                    type: recurringServiceStop.type,
                    typeImage: recurringServiceStop.typeImage,
                    jobId: "",
                    jobName: "",
                    operationStatus: .notFinished,
                    billingStatus: .notInvoiced,
                    includeReadings: true,
                    includeDosages: true,
                    otherCompany: otherCompany,
                    laborContractId: recurringServiceStop.laborContractId ?? "",
                    contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                    isInvoiced: false
                )
                
                //                        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
                //                        let serviceStopId = "S" + String(serviceStopCount)
                
                
                try await uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
                if pushDate > lastCreated {
                    lastCreated = pushDate
                }
                
            }
            
            counter = counter + 1
        }
    }
    //Weeekly
    func helpCreateWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        noEndDate:Bool,startDate:Date,endDate:Date) async throws{
        print("Create Weekly Recurring Route helper Function")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week
        
        var functionalStartDate:Date = Date()
        var functionalEndDate:Date = Date()
        let calendar = Calendar.current
        var lastCreated:Date = Date()
        
        var counter :Int = 0
        
        if noEndDate {
            print("No End Date")
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            print("Has End Date")
            
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        print("Creating standard Recurring service stop on ")
        print("Day \(recurringServiceStop.daysOfWeek)")
        print("\(daysBetween) Days Between")
        
        while counter < daysBetween {
            //Check to Make sure the day you are adding is the proper day.
            
            
            print("\(counter) / \(daysBetween)")
            var pushDate = Date()
            let startDayOfWeek = String(dateDisplayFornmatter.string(from:startDate))
            //Check if the start day is the day of the week you would like to be adding.
            if recurringServiceStop.daysOfWeek.contains(startDayOfWeek) {
                pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
            } else {
                //Get the actual start Day
                    
                    var serviceDayOfWeekAsNumber = 0
                    switch recurringServiceStop.daysOfWeek {
                    case "Sunday":
                        serviceDayOfWeekAsNumber = 1
                    case "Monday":
                        serviceDayOfWeekAsNumber = 2
                    case "Tuesday":
                        serviceDayOfWeekAsNumber = 3
                    case "Wednesday":
                        serviceDayOfWeekAsNumber = 4
                    case "Thursday":
                        serviceDayOfWeekAsNumber = 5
                    case "Friday":
                        serviceDayOfWeekAsNumber = 6
                    case "Saturday":
                        serviceDayOfWeekAsNumber = 7
                    default:
                        print("Error No days of Week Selected")
                        throw FireBasePublish.unableToPublish
                    }
                    var startDayOfWeekAsNumber = 0  //This ONly Works For Monday
                    switch dateFormatter.string(from:startDate) {
                    case "Sunday":
                        startDayOfWeekAsNumber = 1
                    case "Monday":
                        startDayOfWeekAsNumber = 2
                    case "Tuesday":
                        startDayOfWeekAsNumber = 3
                    case "Wednesday":
                        startDayOfWeekAsNumber = 4
                    case "Thursday":
                        startDayOfWeekAsNumber = 5
                    case "Friday":
                        startDayOfWeekAsNumber = 6
                    case "Saturday":
                        startDayOfWeekAsNumber = 7
                    default:
                        print("Error No days of Week Selected For Start Date")
                        throw FireBasePublish.unableToPublish
                    }
                    let difference = serviceDayOfWeekAsNumber - startDayOfWeekAsNumber
                    print("startDayOfWeekAsNumber \(startDayOfWeekAsNumber)")
                    print("serviceDayOfWeekAsNumber \(serviceDayOfWeekAsNumber)")
                    print("difference \(difference)")
                    
                    if difference >= 0 {
                        
                        pushDate = Calendar.current.date(byAdding: .day, value: difference + counter, to: startDate)!
                    } else {
                        pushDate = Calendar.current.date(byAdding: .day, value: difference + counter + 7, to: startDate)!
                    }
            }
            print("Create Stops on \(fullDate(date: pushDate)) - \(dateFormatter.string(from:pushDate)) - days Of Week \(recurringServiceStop.daysOfWeek)")
            
            let SSId = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
            var otherCompany = false
            if recurringServiceStop.otherCompany {
                otherCompany = true
            } else {
                otherCompany = true
            }
            let singleRecurringServiceStop = ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: "S" + String(SSId),
                companyId: companyId,
                companyName: "",
                customerId: recurringServiceStop.customerId,
                customerName: recurringServiceStop.customerName,
                address: recurringServiceStop.address,
                dateCreated: Date(),
                serviceDate: pushDate,
                startTime: nil,
                endTime: nil,
                duration: 0,
                estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                tech: recurringServiceStop.tech,
                techId: recurringServiceStop.techId,
                recurringServiceStopId: recurringServiceStop.id,
                description: recurringServiceStop.description,
                serviceLocationId: recurringServiceStop.serviceLocationId,
                typeId: recurringServiceStop.typeId,
                type: recurringServiceStop.type,
                typeImage: recurringServiceStop.typeImage,
                jobId: "",
                jobName: "",
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: otherCompany,
                laborContractId: recurringServiceStop.laborContractId ?? "",
                contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                isInvoiced: false
            )
            
            //                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
            //                    let serviceStopId = "S" + String(serviceStopCount)
            
            try await uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
            if pushDate > lastCreated {
                lastCreated = pushDate
            }
            counter = counter + 7
        }
        print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")
        var pushRecurring = recurringServiceStop
        pushRecurring.lastCreated = lastCreated
        print("Adding Recurring Service Stop with id - \(pushRecurring.id) *helpCreateWeeklyRecurringRoute on RecurringRouteManager")
        try recurringServiceStopDocument(recurringServiceStopId: pushRecurring.id, companyId: companyId).setData(from:pushRecurring, merge: true)
    }
    
    //Bi Weekly
    
    func helpCreateBiWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                          noEndDate:Bool,startDate:Date,endDate:Date) async throws{
        var functionalStartDate:Date = Date()
        var functionalEndDate:Date = Date()
        let calendar = Calendar.current
        var lastCreated:Date = Date()
        
        var counter :Int = 0
        
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        print("Creating standard Recurring service stop")
        while counter < daysBetween {
            var pushDate = Date()
            pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
            var otherCompany = false
            if recurringServiceStop.otherCompany {
                otherCompany = true
            } else {
                otherCompany = true
            }
            let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)

            let singleRecurringServiceStop = ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: "S" + String(doc.increment),
                companyId: companyId,
                companyName: "",
                customerId: recurringServiceStop.customerId,
                customerName: recurringServiceStop.customerName,
                address: recurringServiceStop.address,
                dateCreated: Date(),
                serviceDate: pushDate,
                startTime: nil,
                endTime: nil,
                duration: 0,
                estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                tech: recurringServiceStop.tech,
                techId: recurringServiceStop.techId,
                recurringServiceStopId: recurringServiceStop.id,
                description: recurringServiceStop.description,
                serviceLocationId: recurringServiceStop.serviceLocationId,
                typeId: recurringServiceStop.typeId,
                type: recurringServiceStop.type,
                typeImage: recurringServiceStop.typeImage,
                jobId: "",
                jobName: "",
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: otherCompany,
                laborContractId: recurringServiceStop.laborContractId ?? "",
                contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                isInvoiced: false
            )
            
            //                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
            //                    let serviceStopId = "S" + String(serviceStopCount)
            
            try await uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
            if pushDate > lastCreated {
                lastCreated = pushDate
            }
            
            
            
            counter = counter + 14
        }
    }
    //Monthly
    
    func helpCreateMonthlyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async throws{
        var functionalStartDate:Date = Date()
        var functionalEndDate:Date = Date()
        let calendar = Calendar.current
        var lastCreated:Date = Date()
        var counter :Int = 0
        var monthCounter :Int = 0
        
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        print("Creating standard Recurring service stop")
        while counter < daysBetween {
            var pushDate = Date()
            pushDate = Calendar.current.date(byAdding: .month, value: monthCounter, to: startDate)!
            var otherCompany = false
            if recurringServiceStop.otherCompany {
                otherCompany = true
            } else {
                otherCompany = true
            }
            
            let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)

            let singleRecurringServiceStop = ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: "S" + String(doc.increment),
                companyId: companyId,
                companyName: "",
                customerId: recurringServiceStop.customerId,
                customerName: recurringServiceStop.customerName,
                address: recurringServiceStop.address,
                dateCreated: Date(),
                serviceDate: pushDate,
                startTime: nil,
                endTime: nil,
                duration: 0,
                estimatedDuration: Int(recurringServiceStop.estimatedTime) ?? 15,
                tech: recurringServiceStop.tech,
                techId: recurringServiceStop.techId,
                recurringServiceStopId: recurringServiceStop.id,
                description: recurringServiceStop.description,
                serviceLocationId: recurringServiceStop.serviceLocationId,
                typeId: recurringServiceStop.typeId,
                type: recurringServiceStop.type,
                typeImage: recurringServiceStop.typeImage,
                jobId: "",
                jobName: "",
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: otherCompany,
                laborContractId: recurringServiceStop.laborContractId ?? "",
                contractedCompanyId: recurringServiceStop.contractedCompanyId ?? "",
                isInvoiced: false
            )
            
            //                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
            //                    let serviceStopId = "S" + String(serviceStopCount)
            
            try await uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
            if pushDate > lastCreated {
                lastCreated = pushDate
            }
            
        }
        monthCounter = monthCounter + 1
        counter = counter + 30
        
    }
    
    //Custom
    nonisolated func helpCreateCustomRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                                    standardFrequencyNumber:Int,
                                                    customFrequencyType:String,
                                                    CustomFrequency:String,
                                                    daysOfWeek:[String]){
    }
}
