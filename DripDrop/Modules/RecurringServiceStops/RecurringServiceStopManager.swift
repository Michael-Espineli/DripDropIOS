//
//  recurringServiceStopManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/15/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct RecurringServiceStop:Identifiable, Codable,Equatable, Hashable{
    static func == (lhs: RecurringServiceStop, rhs: RecurringServiceStop) -> Bool {
        return lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.typeId == rhs.typeId &&
        lhs.customerId == rhs.customerId &&
        lhs.locationId == rhs.locationId
    }
    
    var id :String
    let type: String
    let typeId: String
    let typeImage: String
    let customerName : String
    let customerId : String
    let locationId : String? // No Need we already Have Service Location Id
    
    let frequency : String?
    let address: Address
    let dateCreated : Date?
    let tech: String
    let endDate :Date?
    let startDate :Date?
    let techId: String?
    let noEndDate: Bool
    
    let customMeasuresOfTime: String
    let customEvery:String
    
    let daysOfWeek:[String]// there is going to be only one day in here but it should work.
    let description : String
    var lastCreated : Date
    let serviceLocationId : String
    let estimatedTime : String?
    init(
        id: String,
        type :String,
        typeId : String,
        typeImage : String,
        customerName : String,
        customerId : String,
        locationId : String? = nil,
        frequency : String? = nil,
        address : Address,
        dateCreated : Date? = nil,
        tech : String,
        endDate : Date? = nil,
        startDate: Date? = nil,
        techId: String? = nil,
        noEndDate: Bool,
        customMeasuresOfTime: String,
        customEvery: String,
        daysOfWeek: [String],
        description: String,
        lastCreated: Date,
        serviceLocationId: String,
        estimatedTime: String? = nil

    ){
        self.id = id
        self.type = type
        self.typeId = typeId
        self.typeImage = typeImage
        self.customerName = customerName
        self.customerId = customerId
        self.locationId = locationId
        self.frequency = frequency
        self.address = address
        self.dateCreated = dateCreated
        self.tech = tech
        self.endDate = endDate
        self.startDate = startDate
        self.techId = techId
        self.noEndDate = noEndDate
        self.customMeasuresOfTime = customMeasuresOfTime
        self.customEvery = customEvery
        self.daysOfWeek = daysOfWeek
        self.description = description
        self.lastCreated = lastCreated
        self.serviceLocationId = serviceLocationId
        self.estimatedTime = estimatedTime

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case type = "type"
            case typeId = "typeId"
            case typeImage = "typeImage"
            case customerName = "customerName"
            case customerId = "customerId"
            case locationId = "locationId"
            case frequency = "frequency"
            case address = "address"
            case dateCreated = "dateCreated"
            case tech = "tech"
            case endDate = "endDate"
            case startDate = "startDate"
            case techId = "techId"
            case noEndDate = "noEndDate"
            case customMeasuresOfTime = "customMeasuresOfTime"
            case customEvery = "customEvery"
            case daysOfWeek = "daysOfWeek"
            case description = "description"
            case lastCreated = "lastCreated"
            case serviceLocationId = "serviceLocationId"
            case estimatedTime = "estimatedTime"
        }
}


final class RecurringServiceStopManager {
    
    static let shared = RecurringServiceStopManager()
    private init(){}
    private func recurringServiceStopCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/recurringServiceStop")
    }

    private func recurringServiceStopDocument(recurringServiceStopId:String,companyId:String)-> DocumentReference{
        recurringServiceStopCollection(companyId: companyId).document(recurringServiceStopId)
        
    }
    func uploadRecurringServiceStop(companyId:String,recurringServiceStop : RecurringServiceStop) async throws {

        try recurringServiceStopDocument(recurringServiceStopId: recurringServiceStop.id,companyId: companyId).setData(from:recurringServiceStop, merge: true)
    }
    func deleteRecurringServiceStop(companyId:String,recurringServiceStopId : String) async throws {
        try? await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId).delete()

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
            .limit(to:5)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RecurringServiceStop.self)

    }
    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop,
                              standardFrequencyNumber:Int,
                              customFrequencyType:String,
                              CustomFrequency:String,
                              daysOfWeek:[String]) async throws{
        let calendar = Calendar.current
//~~~~~~~~~~~~~~~~Variables Received~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        //here
//        let standardFrequencyNumber:Int = 4
//        let customFrequencyType:String = "Year"
//        let CustomFrequency:String = "1"
//        let daysOfWeek:[String] = ["Monday","Wednesday","Friday"]
        if recurringServiceStop.startDate == nil {return}
        let startDate:Date = recurringServiceStop.startDate ?? Date()

        let endDate:Date = recurringServiceStop.endDate ?? Date()
        let noEndDate:Bool = recurringServiceStop.noEndDate
        var daysOfWeekList:[String] = daysOfWeek
        if standardFrequencyNumber == 1 {
            daysOfWeekList = [weekDay(date: recurringServiceStop.startDate)]

        }
        daysOfWeekList = daysOfWeek
         //initial Creating of the Route
        let recurringServiceStopCount = try await SettingsManager.shared.getRecurringServiceStopCount(companyId: companyId)
        sleep(1)
        let recurringServiceStopId = "R" + String(recurringServiceStopCount)
        
        let pushRecurringServiceStop = RecurringServiceStop(id: recurringServiceStopId,
                                                            type: recurringServiceStop.type,
                                                            typeId: recurringServiceStop.typeId,
                                                            typeImage: recurringServiceStop.typeImage,
                                                            customerName: recurringServiceStop.customerName,
                                                            customerId: recurringServiceStop.customerId,
                                                            locationId: recurringServiceStop.locationId,
                                                            frequency: recurringServiceStop.frequency,
                                                            address: recurringServiceStop.address,
                                                            dateCreated: recurringServiceStop.dateCreated,
                                                            tech: recurringServiceStop.tech,
                                                            endDate: recurringServiceStop.endDate,
                                                            startDate: recurringServiceStop.startDate,
                                                            techId: recurringServiceStop.techId,
                                                            noEndDate: recurringServiceStop.noEndDate,
                                                            customMeasuresOfTime: customFrequencyType,
                                                            customEvery: CustomFrequency,
                                                            daysOfWeek: daysOfWeekList,
                                                            description: recurringServiceStop.description,
                                                            lastCreated: Date(),
                                                            serviceLocationId: recurringServiceStop.serviceLocationId,
                                                            estimatedTime: recurringServiceStop.estimatedTime ?? "15")
        
        try? await RecurringServiceStopManager.shared.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: pushRecurringServiceStop)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"//String Day of the Week
        let dateDisplayFornmatter = DateFormatter()
        dateDisplayFornmatter.dateFormat = "MM-dd-yy"//this your string date format
        let numberOfWeek = DateFormatter()
        numberOfWeek.dateFormat = "EEEEE"//Number Day of the Week

        var functionalStartDate = Date()
        var functionalEndDate = Date()
        var skipWeekEnds:Bool = false
        var custom:Bool = false
        var month:Bool = false
        var counter:Int = 0
        var monthCounter:Int = 0
        var numFrequency:Int = 0
        var lastCreated:Date = Date()
        switch standardFrequencyNumber{
        case 0:
            numFrequency = 1
            print("Making Stops Daily")

            //Daily
        case 1:
            numFrequency = 7
            //weekly
            print("Making Stops Weekly")
            
        case 2:
            month = true
            //Monthly
            print("Making Stops Monthly")
        case 3:
            numFrequency = 30
            //30 days
            print("Making Stops 30 days")

        case 4:
            numFrequency = 1
            skipWeekEnds = true
            //skipped weekends
            print("Making Stops on Weekdays")

        case 5:
            custom = true
            numFrequency = 1
            print("Making Stops every \(CustomFrequency) \(customFrequencyType) on =>")
            if customFrequencyType == "Week" {
                for day in daysOfWeek {
                    print(day)
                }
            }
        default:
            numFrequency = 100
        }
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
        if custom {
            print("Creating Custom: ")
            while counter < daysBetween {
                var pushDate = Date()
                pushDate = startDate
                switch customFrequencyType{
                case "Day":
                    numFrequency = Int(CustomFrequency) ?? 1
                    while counter < daysBetween {
//                        var customCounter = counter

                            pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
                        
                        let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                     typeId: recurringServiceStop.typeId,
                                                                     customerName: recurringServiceStop.customerName,
                                                                     customerId: recurringServiceStop.customerId,
                                                                     address: recurringServiceStop.address,
                                                                     dateCreated: Date(),
                                                                     serviceDate: pushDate,
                                                                     duration: 0,
                                                                     rate:0,
                                                                     tech: pushRecurringServiceStop.tech,
                                                                     techId: pushRecurringServiceStop.techId,
                                                                     recurringServiceStopId: pushRecurringServiceStop.id,
                                                                     description: pushRecurringServiceStop.id,
                                                                     serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                     type: recurringServiceStop.type,
                                                                     typeImage: recurringServiceStop.typeImage,
                                                                     jobId: "",
                                                                     finished: false,
                                                                     skipped: false,
                                                                     invoiced: false,
                                                                     checkList: [],
                        includeReadings: true,
                        includeDosages: true)

//                        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                        let serviceStopId = "S" + String(serviceStopCount)
                        
                        try await ServiceStopManager.shared.uploadServiceStop(companyId:companyId, serviceStop: singleRecurringServiceStop)
                        
                            if pushDate > lastCreated {
                                lastCreated = pushDate
                            }
                        
                        counter = counter + numFrequency
                    }
                case "Week":
                    numFrequency = 7
                    while counter < daysBetween {
                        let customCounter = counter
                        for day in daysOfWeek {
                            let dayOfWeek = String(dateFormatter.string(from:startDate))
                            var dayOfWeekNum:Int = 0
                            var dayNum:Int = 0
                            var C:Int = 0
                            //A
                            switch dayOfWeek{
                            case "Sunday":
                                dayOfWeekNum = 1
                            case "Monday":
                                dayOfWeekNum = 2
                            case "Tuesday":
                                dayOfWeekNum = 3
                            case "Wednesday":
                                dayOfWeekNum = 4
                            case "Thursday":
                                dayOfWeekNum = 5
                            case "Friday":
                                dayOfWeekNum = 6
                            case "Saturday":
                                dayOfWeekNum = 7
                            default:
                                dayOfWeekNum = 0
                            }
                            //B
                            switch day{
                            case "Sunday":
                                dayNum = 1
                            case "Monday":
                                dayNum = 2
                            case "Tuesday":
                                dayNum = 3
                            case "Wednesday":
                                dayNum = 4
                            case "Thursday":
                                dayNum = 5
                            case "Friday":
                                dayNum = 6
                            case "Saturday":
                                dayNum = 7
                            default:
                                dayNum = 0
                            }
                            if dayNum >= dayOfWeekNum{
                                C =  dayNum - dayOfWeekNum
                            } else {
                                C =  dayNum - dayOfWeekNum + 7
                            }
                            let intCounter = C + customCounter

                            pushDate = Calendar.current.date(byAdding: .day, value: intCounter, to: startDate)!
                            let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                         typeId: recurringServiceStop.typeId,
                                                                         customerName: recurringServiceStop.customerName,
                                                                         customerId: recurringServiceStop.customerId,
                                                                         address: recurringServiceStop.address,
                                                                         dateCreated: Date(),
                                                                         serviceDate: pushDate,
                                                                         duration: 0,
                                                                         rate:0,
                                                                         tech: pushRecurringServiceStop.tech,
                                                                         techId: pushRecurringServiceStop.techId,
                                                                         recurringServiceStopId: pushRecurringServiceStop.id,
                                                                         description: pushRecurringServiceStop.id,
                                                                         serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                         type: recurringServiceStop.type,
                                                                         typeImage: recurringServiceStop.typeImage,
                                                                         jobId: "",
                                                                         finished: false,
                                                                         skipped: false,
                                                                         invoiced: false,
                                                                         checkList: [],
                            includeReadings: true,
                            includeDosages: true)

//                            let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                            let serviceStopId = "S" + String(serviceStopCount)
                            
                            try await ServiceStopManager.shared.uploadServiceStop(companyId:companyId, serviceStop: singleRecurringServiceStop)
                                                        
                            if pushDate > lastCreated {
                                lastCreated = pushDate
                            }
                            
                        }
                        counter = counter + 7
                    }
                    
                case "Month":
                    numFrequency = 30

                            pushDate = Calendar.current.date(byAdding: .day, value: 0, to: startDate)!
                    let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                 typeId: recurringServiceStop.typeId,
                                                                 customerName: recurringServiceStop.customerName,
                                                                 customerId: recurringServiceStop.customerId,
                                                                 address: recurringServiceStop.address,
                                                                 dateCreated: Date(),
                                                                 serviceDate: pushDate,
                                                                 duration: 0,
                                                                 rate:0,
                                                                 tech: pushRecurringServiceStop.tech,
                                                                 techId: pushRecurringServiceStop.techId,
                                                                 recurringServiceStopId: pushRecurringServiceStop.id,
                                                                 description: pushRecurringServiceStop.id,
                                                                 serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                 type: recurringServiceStop.type,
                                                                 typeImage: recurringServiceStop.typeImage,
                                                                 jobId: "",
                                                                 finished: false,
                                                                 skipped: false,
                                                                 invoiced: false,
                                                                 checkList: [],
                    includeReadings: true,
                    includeDosages: true)

//                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                    let serviceStopId = "S" + String(serviceStopCount)
                    
                    try await ServiceStopManager.shared.uploadServiceStop(companyId:companyId, serviceStop: singleRecurringServiceStop)
                                        if pushDate > lastCreated {
                        lastCreated = pushDate
                    }
                    counter = counter + numFrequency

                case "Year":
                    numFrequency = 365

                            pushDate = Calendar.current.date(byAdding: .day, value: 0, to: startDate)!
                    let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                 typeId: recurringServiceStop.typeId,
                                                                 customerName: recurringServiceStop.customerName,
                                                                 customerId: recurringServiceStop.customerId,
                                                                 address: recurringServiceStop.address,
                                                                 dateCreated: Date(),
                                                                 serviceDate: pushDate,
                                                                 duration: 0,
                                                                 rate:0,
                                                                 tech: pushRecurringServiceStop.tech,
                                                                 techId: pushRecurringServiceStop.techId,
                                                                 recurringServiceStopId: pushRecurringServiceStop.id,
                                                                 description: pushRecurringServiceStop.id,
                                                                 serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                 type: recurringServiceStop.type,
                                                                 typeImage: recurringServiceStop.typeImage,
                                                                 jobId: "",
                                                                 finished: false,
                                                                 skipped: false,
                                                                 invoiced: false,
                                                                 checkList: [],
                    includeReadings: true,
                    includeDosages: true)

//                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                    let serviceStopId = "S" + String(serviceStopCount)
                    
                    try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
                                        
                    if pushDate > lastCreated {
                        lastCreated = pushDate
                    }
                    counter = counter + numFrequency

                default:
                    numFrequency = 365
                }
                counter = counter + numFrequency
            }
        } else {
            print("Creating standard Recurring service stop")
            while counter < daysBetween {
                var pushDate = Date()
                if month {
                    pushDate = Calendar.current.date(byAdding: .month, value: monthCounter, to: startDate)!
                } else {
                    pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
                }
                if skipWeekEnds {
                    
                    if String(dateFormatter.string(from:pushDate)) == "Saturday" || String(dateFormatter.string(from:pushDate)) == "Sunday" {
                        print(String(dateFormatter.string(from:pushDate)))
                        
                        print("Skipped")
                    }else {
                        let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                     typeId: recurringServiceStop.typeId,
                                                                     customerName: recurringServiceStop.customerName,
                                                                     customerId: recurringServiceStop.customerId,
                                                                     address: recurringServiceStop.address,
                                                                     dateCreated: Date(),
                                                                     serviceDate: pushDate,
                                                                     duration: 0,
                                                                     rate:0,
                                                                     tech: pushRecurringServiceStop.tech,
                                                                     techId: pushRecurringServiceStop.techId,
                                                                     recurringServiceStopId: pushRecurringServiceStop.id,
                                                                     description: pushRecurringServiceStop.id,
                                                                     serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                     type: recurringServiceStop.type,
                                                                     typeImage: recurringServiceStop.typeImage,
                                                                     jobId: "",
                                                                     finished: false,
                                                                     skipped: false,
                                                                     invoiced: false,
                                                                     checkList: [],
                        includeReadings: true,
                        includeDosages: true)

//                        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                        let serviceStopId = "S" + String(serviceStopCount)
                        
                        try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
                                                
                        if pushDate > lastCreated {
                            lastCreated = pushDate
                        }
                    }
                } else {
                    let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                                 typeId: recurringServiceStop.typeId,
                                                                 customerName: recurringServiceStop.customerName,
                                                                 customerId: recurringServiceStop.customerId,
                                                                 address: recurringServiceStop.address,
                                                                 dateCreated: Date(),
                                                                 serviceDate: pushDate,
                                                                 duration: 0,
                                                                 rate:0,
                                                                 tech: pushRecurringServiceStop.tech,
                                                                 techId: pushRecurringServiceStop.techId,
                                                                 recurringServiceStopId: pushRecurringServiceStop.id,
                                                                 description: pushRecurringServiceStop.id,
                                                                 serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                 type: recurringServiceStop.type,
                                                                 typeImage: recurringServiceStop.typeImage,
                                                                 jobId: "",
                                                                 finished: false,
                                                                 skipped: false,
                                                                 invoiced: false,
                                                                 checkList: [],
                    includeReadings: true,
                    includeDosages: true)

//                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                    let serviceStopId = "S" + String(serviceStopCount)
                    
                    try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
                                        if pushDate > lastCreated {
                        lastCreated = pushDate
                    }
                    
                }
                if month {
                    monthCounter = monthCounter + 1
                    counter = counter + 30
                }
                counter = counter + numFrequency
            }
        }
        print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")

    }
    //UPDATE
    func endRecurringServiceStop(companyId:String,recurringServiceStopId:String,endDate:Date) async throws {
        //DEVELOPER ADD LOGIC
        print("End Recurring Service Stop Logic")
        try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId)
            .updateData([
                "noEndDate": false,
                "endDate":endDate
            ])
    }
}

