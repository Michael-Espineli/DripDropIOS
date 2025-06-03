//
//  RecurringRouteManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/11/23.
//
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit	
import Darwin
struct recurringRouteOrder:Identifiable,Equatable, Codable,Hashable{
    var id:String
    var order:Int
    var recurringServiceStopId:String
    var customerId:String
    var customerName:String
    var locationId:String
}
struct ServiceStopOrder:Identifiable,Equatable, Codable,Hashable{
    var id:String
    var order:Int
    var serviceStopId:String
}
/*
final class RecurringRouteManager {
    
    static let shared = RecurringRouteManager()
    private init(){}
    
    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func recurringRouteCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/recurringRoutes")
    }
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func reccuringRouteDoc(companyId:String,recurringRouteId:String)-> DocumentReference{
        recurringRouteCollection(companyId: companyId).document(recurringRouteId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRoute(companyId:String,recurringRoute:RecurringRoute) async throws {
        print("Upload Route >> \(recurringRoute.id)")
        try recurringRouteCollection(companyId: companyId).document(recurringRoute.id).setData(from:recurringRoute, merge: false)
    }
    */

 
/*
    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop,
                                    customFrequencyType:String,
                                    CustomFrequency:String,
                                    daysOfWeek:[String]) async throws ->(String?){
        print("")
        print(" - addNewRecurringServiceStop - RecurringRouteManager")
        let calendar = Calendar.current
        guard let startDate:Date = recurringServiceStop.startDate else {
            return nil
        }
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
        
//        var functionalStartDate = Date()
//        var functionalEndDate = Date()
//        var skipWeekEnds:Bool = false
//        var custom:Bool = false
//        var month:Bool = false
//        var counter:Int = 0
//        var monthCounter:Int = 0
//        var numFrequency:Int = 0
//        var lastCreated:Date = Date()
        var pushRecurring = recurringServiceStop
        pushRecurring.id = recurringServiceStopId
        switch recurringServiceStop.frequency{
        case "Daily":
            print(" - Making Stops Daily")
            try await helpCreateDailyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)
            
            //Daily
        case "WeekDay":
            //skipped weekends
            print(" - Making Stops on Week days")
            try await helpCreateWeekDayRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

        case "Weekly":
            //weekly
            print(" - Making Stops Weekly")
            try await helpCreateWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

        case "Bi-Weekly":
            //weekly
            print(" - Making Stops Bi Weekly")
            try await helpCreateBiWeeklyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

            
        case "Monthly":
            //Monthly
            print(" - Making Stops Monthly")
            try await helpCreateMonthlyRecurringRoute(companyId: companyId, recurringServiceStop: pushRecurring, noEndDate: noEndDate, startDate: startDate, endDate: endDate)

            
        case "Custom":
            print(" - Making Custom Stops")

//            helpCreateCustomRecurringRoute()

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
            
            
            let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                         typeId: recurringServiceStop.typeId,
                                                         customerName: recurringServiceStop.customerName,
                                                         customerId: recurringServiceStop.customerId,
                                                         address: recurringServiceStop.address,
                                                         dateCreated: Date(),
                                                         serviceDate: pushDate,
                                                         duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                         rate:0,
                                                         tech: recurringServiceStop.tech,
                                                         techId: recurringServiceStop.techId,
                                                         recurringServiceStopId: recurringServiceStop.id,
                                                         description: recurringServiceStop.id,
                                                         serviceLocationId: recurringServiceStop.serviceLocationId,
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
                let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                             typeId: recurringServiceStop.typeId,
                                                             customerName: recurringServiceStop.customerName,
                                                             customerId: recurringServiceStop.customerId,
                                                             address: recurringServiceStop.address,
                                                             dateCreated: Date(),
                                                             serviceDate: pushDate,
                                                             duration: Int(recurringServiceStop.estimatedTime!) ?? 15,
                                                             rate:0,
                                                             tech: recurringServiceStop.tech,
                                                             techId: recurringServiceStop.techId,
                                                             recurringServiceStopId: recurringServiceStop.id,
                                                             description: recurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
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
            
            counter = counter + 1
        }
    }
    //Weeekly
    func helpCreateWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
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
        
        var counter : Int = 0
        
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
        print("Creating standard Recurring service stop")
        print("days Between \(daysBetween)")
       
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
                if let serviceDayOfWeek = recurringServiceStop.daysOfWeek.first {
                    var serviceDayOfWeekAsNumber = 0
                    switch serviceDayOfWeek {
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
                    case "Satruday":
                        serviceDayOfWeekAsNumber = 7
                    default:
                        print(" - serviceDayOfWeekAsNumber Error")
                        throw FireBasePublish.unableToPublish
                    }
                    var startDayOfWeekAsNumber = 0  //This ONly Works For Monday
                    print("startDate \(startDate) \(dateFormatter.string(from:startDate))")
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
                        print(" - startDayOfWeekAsNumber Error")

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
                } else {
                    throw FireBasePublish.unableToPublish
                }
            }
            print("Create Stops on \(fullDate(date: pushDate)) - \(dateFormatter.string(from:pushDate)) - days Of Week \(recurringServiceStop.daysOfWeek)")

            let SSId = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
            
            let singleRecurringServiceStop = ServiceStop(id: "S" + String(SSId),
                                                         typeId: recurringServiceStop.typeId,
                                                         customerName: recurringServiceStop.customerName,
                                                         customerId: recurringServiceStop.customerId,
                                                         address: recurringServiceStop.address,
                                                         dateCreated: Date(),
                                                         serviceDate: pushDate,
                                                         duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                         rate:0,
                                                         tech: recurringServiceStop.tech,
                                                         techId: recurringServiceStop.techId,
                                                         recurringServiceStopId: recurringServiceStop.id,
                                                         description: recurringServiceStop.id,
                                                         serviceLocationId: recurringServiceStop.serviceLocationId,
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
            

            
            counter = counter + 7
        }
        print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")
var pushRecurring = recurringServiceStop
        pushRecurring.lastCreated = lastCreated
        print("Adding Recurring Service Stop with id - \(pushRecurring.id) *helpCreateWeeklyRecurringRoute on RecurringRouteManager")
        try await RecurringServiceStopManager.shared.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: pushRecurring)
    }
    func helpModifyWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        noEndDate:Bool,startDate:Date,endDate:Date,RSS:RecurringServiceStop,serviceStopsList:[ServiceStop]) async throws{
        //Orders them to Correct Dates.
        //DEVELOPER CHANGE EXPLICITE UNWRAP, ALL SERVICE STOPS SHOULD HAVE A SERVIEC DATE
        var workingSS = serviceStopsList.sorted(by: { $0.serviceDate!.compare($1.serviceDate!) == .orderedDescending })

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
        print("Creating standard Recurring service stop")
        print("days Between \(daysBetween)")
       
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
                if let serviceDayOfWeek = recurringServiceStop.daysOfWeek.first {
                    var serviceDayOfWeekAsNumber = 0
                    switch serviceDayOfWeek {
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
                    case "Satruday":
                        serviceDayOfWeekAsNumber = 7
                    default:
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
                    case "Satruday":
                        startDayOfWeekAsNumber = 7
                    default:
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
                } else {
                    throw FireBasePublish.unableToPublish
                }
            }
            print("Modify Stops on \(fullDate(date: pushDate)) - \(dateFormatter.string(from:pushDate)) - days Of Week \(recurringServiceStop.daysOfWeek)")

            
            if let oldSS = workingSS.first {
                let SSId = oldSS.id
                let newSS = ServiceStop(id:String(SSId),
                                                             typeId: recurringServiceStop.typeId,
                                                             customerName: recurringServiceStop.customerName,
                                                             customerId: recurringServiceStop.customerId,
                                                             address: recurringServiceStop.address,
                                                             dateCreated: Date(),
                                                             serviceDate: pushDate,
                                                             duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                             rate:0,
                                                             tech: recurringServiceStop.tech,
                                                             techId: recurringServiceStop.techId,
                                                             recurringServiceStopId: recurringServiceStop.id,
                                                             description: recurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
                                                             type: recurringServiceStop.type,
                                                             typeImage: recurringServiceStop.typeImage,
                                                             jobId: "",
                                                             finished: false,
                                                             skipped: false,
                                                             invoiced: false,
                                                             checkList: [],
                                                             includeReadings: true,
                                                             includeDosages: true)
                //Compare Differences and Update Based on them
                if oldSS.serviceDate != newSS.serviceDate {
                    try ServiceStopManager.shared.updateServiceStopDate(companyId: companyId, serviceStop: oldSS, date: newSS.serviceDate!)
                }
                if oldSS.tech != newSS.tech || oldSS.techId != newSS.techId {
                    try await ServiceStopManager.shared.updateServiceStopTech(companyId: companyId, serviceStop: oldSS, techId: newSS.techId!, tech: newSS.tech!)
                }
                //Remove From List
                workingSS.removeFirst()
            } else {
                let SSId = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
                let singleRecurringServiceStop = ServiceStop(id:"S" + String(SSId),
                                                             typeId: recurringServiceStop.typeId,
                                                             customerName: recurringServiceStop.customerName,
                                                             customerId: recurringServiceStop.customerId,
                                                             address: recurringServiceStop.address,
                                                             dateCreated: Date(),
                                                             serviceDate: pushDate,
                                                             duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                             rate:0,
                                                             tech: recurringServiceStop.tech,
                                                             techId: recurringServiceStop.techId,
                                                             recurringServiceStopId: recurringServiceStop.id,
                                                             description: recurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
                                                             type: recurringServiceStop.type,
                                                             typeImage: recurringServiceStop.typeImage,
                                                             jobId: "",
                                                             finished: false,
                                                             skipped: false,
                                                             invoiced: false,
                                                             checkList: [],
                                                             includeReadings: true,
                                                             includeDosages: true)
                try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
            }
            
            
            if pushDate > lastCreated {
                lastCreated = pushDate
            }
            

            
            counter = counter + 7
        }
        print("Last Created: \(String(dateDisplayFornmatter.string(from:lastCreated)))")
var pushRecurring = recurringServiceStop
        pushRecurring.lastCreated = lastCreated
        print("Adding Recurring Service Stop with id - \(pushRecurring.id) *helpCreateWeeklyRecurringRoute on RecurringRouteManager")
        try await RecurringServiceStopManager.shared.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: pushRecurring)
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
            
            
            let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                         typeId: recurringServiceStop.typeId,
                                                         customerName: recurringServiceStop.customerName,
                                                         customerId: recurringServiceStop.customerId,
                                                         address: recurringServiceStop.address,
                                                         dateCreated: Date(),
                                                         serviceDate: pushDate,
                                                         duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                         rate:0,
                                                         tech: recurringServiceStop.tech,
                                                         techId: recurringServiceStop.techId,
                                                         recurringServiceStopId: recurringServiceStop.id,
                                                         description: recurringServiceStop.id,
                                                         serviceLocationId: recurringServiceStop.serviceLocationId,
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
  
                let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
                                                             typeId: recurringServiceStop.typeId,
                                                             customerName: recurringServiceStop.customerName,
                                                             customerId: recurringServiceStop.customerId,
                                                             address: recurringServiceStop.address,
                                                             dateCreated: Date(),
                                                             serviceDate: pushDate,
                                                             duration: Int(recurringServiceStop.estimatedTime ?? "15") ?? 15,
                                                             rate:0,
                                                             tech: recurringServiceStop.tech,
                                                             techId: recurringServiceStop.techId,
                                                             recurringServiceStopId: recurringServiceStop.id,
                                                             description: recurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
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
                monthCounter = monthCounter + 1
                counter = counter + 30
            
        }
    
    //Custom
    func helpCreateCustomRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        standardFrequencyNumber:Int,
                                        customFrequencyType:String,
                                        CustomFrequency:String,
                                        daysOfWeek:[String]){
        /*
        let calendar = Calendar.current
        
        if noEndDate {
            functionalStartDate = startDate
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!
        } else {
            functionalStartDate = startDate
            functionalEndDate = endDate
        }
        let daysBetween = Calendar.current.dateComponents([.day], from: functionalStartDate, to: functionalEndDate).day!
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
                                                                 duration: Int(recurringServiceStop.estimatedTime!) ?? 15,
                                                                 rate:0,
                                                                 tech: pushRecurringServiceStop.tech,
                                                                 techId: pushRecurringServiceStop.techId,
                                                                 recurringServiceStopId: pushRecurringServiceStop.id,
                                                                 description: pushRecurringServiceStop.id,
                                                                 serviceLocationId: recurringServiceStop.serviceLocationId,
                                                                 type: recurringServiceStop.type,
                                                                 typeImage: recurringServiceStop.typeImage,
                                                                 workOrderId: "",
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
                                                                     duration: Int(recurringServiceStop.estimatedTime!) ?? 15,
                                                                     
                                                                     rate:0,
                                                                     tech: pushRecurringServiceStop.tech,
                                                                     techId: pushRecurringServiceStop.techId,
                                                                     recurringServiceStopId: pushRecurringServiceStop.id,
                                                                     description: pushRecurringServiceStop.id,
                                                                     serviceLocationId: recurringServiceStop.serviceLocationId,
                                                                     type: recurringServiceStop.type,
                                                                     typeImage: recurringServiceStop.typeImage,
                                                                     
                                                                     workOrderId: "",
                                                                     finished: false,
                                                                     skipped: false,
                                                                     invoiced: false,
                                                                     checkList: [],
                                                                     includeReadings: true,
                                                                     includeDosages: true)
                        
                        //                            let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
                        //                            let serviceStopId = "S" + String(serviceStopCount)
                        
                        try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
                        
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
                                                             duration: Int(recurringServiceStop.estimatedTime!) ?? 15,
                                                             rate:0,
                                                             tech: pushRecurringServiceStop.tech,
                                                             techId: pushRecurringServiceStop.techId,
                                                             recurringServiceStopId: pushRecurringServiceStop.id,
                                                             description: pushRecurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
                                                             type: recurringServiceStop.type,
                                                             typeImage: recurringServiceStop.typeImage,
                                                             
                                                             workOrderId: "",
                                                             finished: false,
                                                             skipped: false,
                                                             invoiced: false,
                                                             checkList: [],
                                                             includeReadings: true,
                                                             includeDosages: true)
                
                //                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
                //                    let serviceStopId = "S" + String(serviceStopCount)
                //
                try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)
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
                                                             duration: Int(recurringServiceStop.estimatedTime!) ?? 15,
                                                             rate:0,
                                                             tech: pushRecurringServiceStop.tech,
                                                             techId: pushRecurringServiceStop.techId,
                                                             recurringServiceStopId: pushRecurringServiceStop.id,
                                                             description: pushRecurringServiceStop.id,
                                                             serviceLocationId: recurringServiceStop.serviceLocationId,
                                                             type: recurringServiceStop.type,
                                                             typeImage: recurringServiceStop.typeImage,
                                                             
                                                             workOrderId: "",
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
         */
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getSingleRoute(companyId:String,recurringRouteId:String) async throws -> RecurringRoute {
        return try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId)
            .getDocument(as: RecurringRoute.self)
    }
    func getAllActiveRoutes(companyId:String,param:String) async throws -> [RecurringRoute] {
        
        return try await  recurringRouteCollection(companyId: companyId)
            .getDocuments(as: RecurringRoute.self)
        //            .getDocuments(as:Equipment.self)
    }
    
    func getAllActiveRoutesBasedOnDate(companyId:String,day:String,techId:String) async throws -> [RecurringRoute] {
        
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as: RecurringRoute.self)
    }
    func getRecurringRouteByDayAndTech(companyId:String,day:String,techId:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
        
        //            .whereField(recurringRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
        //            .whereField(recurringRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
        //            .whereField(recurringRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
    }
    func getRecurringRouteByDay(companyId:String,day:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
        
        //            .whereField(recurringRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
        //            .whereField(recurringRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
        //            .whereField(recurringRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws {
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: activeRoute.id)
            .updateData([
                ActiveRoute.CodingKeys.serviceStopsIds.rawValue:FieldValue.arrayUnion([serviceStopId])
            ])
        
    }
    func endRecurringRoute(companyId:String,recurringRouteId:String,endDate:Date) async throws {
        //DEVELOPER ADD LOGIC
        print("End Recurring Route Logic")
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId).delete()
  
        //Delete Recurring Route
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}
*/
