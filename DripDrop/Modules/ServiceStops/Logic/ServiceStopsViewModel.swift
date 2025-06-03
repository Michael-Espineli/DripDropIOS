//
//  ServiceStopsViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/27/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Darwin

@MainActor
final class ServiceStopsViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var serviceStops: [ServiceStop] = []
    @Published private(set) var serviceStopDictionary: [String:[ServiceStop]] = [:]

    @Published private(set) var finishesServiceStops: [ServiceStop] = []
    
    @Published private(set) var serviceStopsFilterd: [ServiceStop] = []
    
    @Published private(set) var currentTechs: [DBUser] = []
    @Published private(set) var dailyDisplayTechs: [DBUser] = []
    
    @Published private(set) var readingHistory: [StopData] = []
    
    @Published private(set) var changeHistory: [History] = []
    @Published private(set) var serviceStop: ServiceStop? = nil
    @Published private(set) var unfinishedServiceStopCount: Int? = nil
    @Published private(set) var finishedServiceStopCount: Int? = nil
    
    
    @Published private(set) var chartAbleData: [ChartDataArray] = []
    @Published private(set) var PNLData: [PNLDataPointArray] = []
    @Published private(set) var profit: Double? = nil
    @Published private(set) var laborCost: Double? = nil
    @Published private(set) var chemicalCost: Double? = nil
    @Published private(set) var totalCost: Double? = nil
    @Published private(set) var numberOfAlerts: Double? = nil
    
    
    @Published private(set) var serviceHistory: [StopHistoryDisplay] = []
    @Published private(set) var routes: [ActiveRoute] = []
    @Published private(set) var filteredWarnings: [Warning] = []
    
    @Published private(set) var biggestName: Int? = nil
    
    
    //    @Published private(set) var billableServiceStops: [ServiceStop] = []
    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedDate: Date? = nil
    
    private var lastDocument: DocumentSnapshot? = nil
    @Published private(set) var invoiceTotal: Double? = nil
    @Published private(set) var purchaseTotal: Double? = nil

    //Variables For Company OverView Page (MyCompany.swift)
    @Published private(set) var typesAndAmount: [String:Int] = [:]
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Mock Data
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var mockStopData:[StopData] =  [
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                    Reading(id: UUID().uuidString,
                            templateId: "275B1B22-9B5B-41CE-A824-56904C985ED8",
                            dosageType: "pH",
                            name: "pH",
                            amount: "7.4",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "2A2C5C31-A3B2-4DED-9D9F-ACBCAA746642",
                            dosageType: "Free Chlorine",
                            name: "Free Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "B7A23F7F-35D6-4182-8600-F7063EB0E4F8",
                            dosageType: "Total Chlorine",
                            name: "Total Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                 ],
                 dosages: [
                    Dosage(id: UUID().uuidString,
                           templateId: "C0E676E5-E9A9-4FB2-ADE3-EB1614CFAEC5",
                           name: "Liquid Chlorine",
                           amount: "3",
                           UOM: nil,
                           rate: nil,
                           linkedItem: nil,
                           bodyOfWaterId: "bodyOfWater"),
                 ],
                 observation: [],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                    Reading(id: UUID().uuidString,
                            templateId: "275B1B22-9B5B-41CE-A824-56904C985ED8",
                            dosageType: "pH",
                            name: "pH",
                            amount: "7.4",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "2A2C5C31-A3B2-4DED-9D9F-ACBCAA746642",
                            dosageType: "Free Chlorine",
                            name: "Free Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "B7A23F7F-35D6-4182-8600-F7063EB0E4F8",
                            dosageType: "Total Chlorine",
                            name: "Total Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                 ],
                 dosages: [
                    Dosage(id: UUID().uuidString,
                           templateId: "C0E676E5-E9A9-4FB2-ADE3-EB1614CFAEC5",
                           name: "Liquid Chlorine",
                           amount: "3",
                           UOM: nil,
                           rate: nil,
                           linkedItem: nil,
                           bodyOfWaterId: "bodyOfWater"),
                 ],
                 observation: [],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                    Reading(id: UUID().uuidString,
                            templateId: "275B1B22-9B5B-41CE-A824-56904C985ED8",
                            dosageType: "pH",
                            name: "pH",
                            amount: "7.4",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "2A2C5C31-A3B2-4DED-9D9F-ACBCAA746642",
                            dosageType: "Free Chlorine",
                            name: "Free Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "B7A23F7F-35D6-4182-8600-F7063EB0E4F8",
                            dosageType: "Total Chlorine",
                            name: "Total Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                 ],
                 dosages: [
                    Dosage(id: UUID().uuidString,
                           templateId: "C0E676E5-E9A9-4FB2-ADE3-EB1614CFAEC5",
                           name: "Liquid Chlorine",
                           amount: "3",
                           UOM: nil,
                           rate: nil,
                           linkedItem: nil,
                           bodyOfWaterId: "bodyOfWater"),
                 ],
                 observation: [],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -28, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                    Reading(id: UUID().uuidString,
                            templateId: "275B1B22-9B5B-41CE-A824-56904C985ED8",
                            dosageType: "pH",
                            name: "pH",
                            amount: "7.4",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "2A2C5C31-A3B2-4DED-9D9F-ACBCAA746642",
                            dosageType: "Free Chlorine",
                            name: "Free Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                    Reading(id: UUID().uuidString,
                            templateId: "B7A23F7F-35D6-4182-8600-F7063EB0E4F8",
                            dosageType: "Total Chlorine",
                            name: "Total Chlorine",
                            amount: "3",
                            UOM: nil,
                            bodyOfWaterId: "bodyOfWater"),
                 ],
                 dosages: [
                    Dosage(id: UUID().uuidString,
                           templateId: "C0E676E5-E9A9-4FB2-ADE3-EB1614CFAEC5",
                           name: "Liquid Chlorine",
                           amount: "3",
                           UOM: nil,
                           rate: nil,
                           linkedItem: nil,
                           bodyOfWaterId: "bodyOfWater")
                 ],
                 observation: [],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
    ]

    @Published private(set) var mockServiceStopData:[ServiceStop] = []
    
    /*[
        ServiceStop(
            id: UUID().uuidString,
            typeId: "Estimate",
            companyId: "",
            companyName: "",
            customerName: "Kellie Lewis",
            customerId: "",
            address: Address(
                streetAddress: "3300 W Camelback Rd",
                city: "Phoeniz",
                state: "Az",
                zip: "85017",
                latitude: 33.30389,
                longitude: -112.07432
            ),
            dateCreated: Date(),
            serviceDate: Date(),
            duration: 60,
            rate: 0,
            tech: "Keler Smith",
            techId: "2M8ws9EtYCZufCeoZDl1Z5J28pq1",
            recurringServiceStopId: "",
            description: "",
            serviceLocationId: "",
            type: "",
            typeImage: "list.bullet.clipboard",
            jobId: "",
            finished: true,
            skipped: false,
            invoiced: false,
            checkList: [],
            includeReadings: true,
            includeDosages: true,
            otherCompany: false
        ),
        ServiceStop(
            id: UUID().uuidString,
            typeId: "Weekly Cleaning",
            companyId: "",
            companyName: "",
            customerName: "Diane Greenwood",
            customerId: "",
            address: Address(
                streetAddress: "300 Soden Dr",
                city: "Oregon",
                state: "WI",
                zip: "53575",
                latitude: 42.929076,
                longitude: -89.381327
            ),
            dateCreated: Date(),
            serviceDate: Date(),
            duration: 60,
            rate: 0,
            tech: "Keler Smith",
            techId: "2M8ws9EtYCZufCeoZDl1Z5J28pq1",
            recurringServiceStopId: "",
            description: "",
            serviceLocationId: "",
            type: "",
            typeImage: "bubbles.and.sparkles.fill",
            jobId: "",
            finished: false,
            skipped: true,
            invoiced: false,
            checkList: [],
            includeReadings: true,
            includeDosages: true,
            otherCompany: false
        ),
        ServiceStop(
            id: UUID().uuidString,
            typeId: "Weekly Cleaning",
            companyId: "",
            companyName: "", //Developer420
            customerName: "Nathan Corrnet",
            customerId: "",
            address: Address(
                streetAddress: "2101 Epcot Resorts Blvd",
                city: "Orlando",
                state: "FL",
                zip: "32830",
                latitude: 28.374580,
                longitude: -81.559631
            ),
            dateCreated: Date(),
            serviceDate: Date(),
            duration: 120,
            rate: 0,
            tech: "Keler Smith",
            techId: "2M8ws9EtYCZufCeoZDl1Z5J28pq1",
            recurringServiceStopId: "",
            description: "",
            serviceLocationId: "",
            type: "",
            typeImage: "bubbles.and.sparkles.fill",
            jobId: "",
            finished: false,
            skipped: false,
            invoiced: false,
            checkList: [],
            includeReadings: true,
            includeDosages: true,
            otherCompany: false
        ),
        ServiceStop(
            id: UUID().uuidString,
            typeId: "Repair",
            companyId: "",
            companyName: "", //Developer420
            customerName: "Laurie Boggiers",
            customerId: "",
            address: Address(
                streetAddress: "6160 Broadmoor Dr",
                city: "La Mesa",
                state: "Ca",
                zip: "91942",
                latitude:  32.790065,
                longitude: -116.992345
            ),
            dateCreated: Date(),
            serviceDate: Date(),
            duration: 60,
            rate: 0,
            tech: "Keler Smith",
            techId: "2M8ws9EtYCZufCeoZDl1Z5J28pq1",
            recurringServiceStopId: "",
            description: "",
            serviceLocationId: "",
            type: "",
            typeImage: "wrench.adjustable.fill",
            jobId: "",
            finished: false,
            skipped: false,
            invoiced: false,
            checkList: [],
            includeReadings: true,
            includeDosages: true,
            otherCompany: false
        ),
    ]
     */

    //    chemicals
    //    repairs
    //    equipment
    //    parts
    
    //Unresolved, In Progress, Resolved
    @Published private(set) var mockWarnings: [Warning] = [
        Warning(id: UUID().uuidString, category: "chemicals", userIDCreated: "LDJfcgdBZafxxwhdkyoY6jV55Vo1", userNameCreated: "Brett Murdock", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 24, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "chemicals", userIDCreated: "RvnfvyD8jOQgL3UQL4nmYvJ9xAg2", userNameCreated: "Michael Espineli", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 22, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "repairs", userIDCreated: "LDJfcgdBZafxxwhdkyoY6jV55Vo1", userNameCreated: "Brett Murdock", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 19, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "repairs", userIDCreated: "RvnfvyD8jOQgL3UQL4nmYvJ9xAg2", userNameCreated: "Michael Espineli", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 10, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "equipment", userIDCreated: "LDJfcgdBZafxxwhdkyoY6jV55Vo1", userNameCreated: "Brett Murdock", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 9, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "equipment", userIDCreated: "RvnfvyD8jOQgL3UQL4nmYvJ9xAg2", userNameCreated: "Michael Espineli", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 15, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "parts", userIDCreated: "LDJfcgdBZafxxwhdkyoY6jV55Vo1", userNameCreated: "Brett Murdock", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 29, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        Warning(id: UUID().uuidString, category: "parts", userIDCreated: "RvnfvyD8jOQgL3UQL4nmYvJ9xAg2", userNameCreated: "Michael Espineli", details: "", dateCreated: makeDate(year: 2023, month: 10, day: 27, hr: 8, min: 00, sec: 00), Status: "Unresolved"),
        
    ]
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
//    func createNewServiceStops(companyId:String) async throws {
//        let recurringsSSList = try await RecurringdataService.getReucrringServiceStopsWithOutEndDate(companyId: companyId)
//        for rss in recurringsSSList {
//            if rss.noEndDate == true {
//                let listOfStops = try await dataService.getServiceStopsByRecurringsServiceStopNotFinished(companyId: companyId, recurringsServicestop: rss)
//                if listOfStops.count < 10 {
//                    var newestDate:Date = Date()
//                    //this should get the furthest out startDate
//                    for ss in listOfStops{
//                        let serviceDate = ss.serviceDate!
//                        if serviceDate > newestDate {
//                            newestDate = serviceDate
//                        }
//                        
//                    }
//                    let calendar = Calendar.current
//                    var functionalStartDate = newestDate
//                    var functionalEndDate = Date()
//                    var skipWeekEnds:Bool = false
//                    var custom:Bool = false
//                    var month:Bool = false
//                    var counter:Int = 1
//                    var monthCounter:Int = 1
//                    var numFrequency:Int = 0
//                    var recurringServiceStops:[ServiceStop] =  []
//                    
//                    switch rss.frequency{
//                        //Daily
//                    case "Daily":
//                        numFrequency = 1
//                        
//                        //Weekly
//                    case "WeekDays":
//                        numFrequency = 7
//                        
//                        //monthly
//                    case "Weekly":
//                        month = true
//                    case "Bi-Weekly":
//                        numFrequency = 30
//                        
//                    case "Monthly":
//                        numFrequency = 1
//                        skipWeekEnds = true
//                    case "Custom":
//                        custom = true
//                        switch rss.customMeasuresOfTime{
//                        case "Day":
//                            print("Day")
//                        case "Week":
//                            print("Day")
//                        case "Month":
//                            print("Day")
//                        case "Year":
//                            print("Year")
//                        default:
//                            print("Year")
//                            
//                        }
//                    default:
//                        return
//                        
//                    }
//                    if rss.noEndDate {
//                        functionalStartDate = rss.startDate ?? Date()
//                        functionalEndDate = calendar.date(byAdding: .day, value: 14, to: functionalStartDate)!
//                        
//                    } else {
//                        functionalStartDate = rss.startDate ?? Date()
//                        functionalEndDate = rss.endDate ?? Date()
//                    }
//                    let daysBetween = daysBetween(start: functionalStartDate, end:functionalEndDate )
//                    print("Num Frequency")
//                    print(numFrequency)
//                    print("Days Between")
//                    
//                    print(daysBetween)
//                    let startDate = rss.startDate ?? Date()
//                    if custom {
//                        print("Creating Custom Recurring service Stop")
//                        
//                    } else {
//                        
//                        print("Creating standard Recurring service stop")
//                        
//                        while counter < daysBetween {
//                            
//                            
//                            
//                            var pushDate = Date()
//                            if month {
//                                pushDate = Calendar.current.date(byAdding: .month, value: monthCounter, to: startDate)!
//                                
//                            } else {
//                                pushDate = Calendar.current.date(byAdding: .day, value: counter, to: startDate)!
//                            }
//                            
//                            if skipWeekEnds {
//                                print(weekDay(date: pushDate))
//                                if weekDay(date: pushDate) == "Saturday" || weekDay(date: pushDate) == "Sunday" {
//                                    print(weekDay(date: pushDate))
//                                    print("Skipped")
//                                }else {
//                                    let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
//                                                                                 typeId: rss.typeId,
//                                                                                 customerName: rss.customerName,
//                                                                                 customerId: rss.customerId,
//                                                                                 address: rss.address,
//                                                                                 dateCreated: Date(),
//                                                                                 serviceDate:pushDate,
//                                                                                 duration: 0,
//                                                                                 rate:0,
//                                                                                 tech: rss.tech,
//                                                                                 techId: rss.techId,
//                                                                                 recurringServiceStopId: rss.id,
//                                                                                 description: rss.description,
//                                                                                 serviceLocationId: rss.locationId ?? "1",
//                                                                                 type: rss.type,
//                                                                                 typeImage: rss.typeImage,
//                                                                                 jobId:"",
//                                                                                 finished: false,
//                                                                                 skipped: false,
//                                                                                 invoiced:false,
//                                                                                 checkList: []
//                                                                                 ,includeReadings: true,includeDosages: true)
//                                    
//                                    recurringServiceStops.append(singleRecurringServiceStop)
//                                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
//                                    let serviceStopId = "S" + String(serviceStopCount)
//                                    
//                                    try await dataService.uploadServiceStop(companyId: companyId,
//                                                                                          serviceStop: ServiceStop(id:serviceStopId,
//                                                                                                                               typeId: rss.typeId,
//                                                                                                                               customerName: rss.customerName,
//                                                                                                                               customerId: rss.customerId,
//                                                                                                                               address: rss.address,
//                                                                                                                               dateCreated: Date(),
//                                                                                                                               serviceDate: pushDate,
//                                                                                                                               duration: 0,
//                                                                                                                               rate:0,
//                                                                                                                               tech: rss.tech,
//                                                                                                                               techId: rss.techId,
//                                                                                                                               recurringServiceStopId: rss.id,
//                                                                                                                               description: rss.description,
//                                                                                                                               serviceLocationId: rss.locationId ?? "1",
//                                                                                                                               type: rss.type,
//                                                                                                                               typeImage: rss.typeImage,
//                                                                                                                   jobId:"",
//                                                                                                                               finished: false,
//                                                                                                                               skipped: false,
//                                                                                                                               invoiced:false,checkList: []
//                                                                                                                               ,includeReadings: true,includeDosages: true))
//                                }
//                                
//                            } else {
//                                let singleRecurringServiceStop = ServiceStop(id: UUID().uuidString,
//                                                                             typeId: rss.typeId,
//                                                                             customerName: rss.customerName,
//                                                                             customerId: rss.customerId,
//                                                                             address: rss.address,
//                                                                             dateCreated: Date(),
//                                                                             serviceDate:pushDate,
//                                                                             duration: 0,
//                                                                             rate:0,
//                                                                             tech: rss.tech,
//                                                                             techId: rss.techId,
//                                                                             recurringServiceStopId: rss.id,
//                                                                             description: rss.description,
//                                                                             serviceLocationId: rss.locationId ?? "1",
//                                                                             type: rss.type,
//                                                                             typeImage: rss.typeImage,
//                                                                             jobId:"",
//                                                                             finished: false,
//                                                                             skipped: false,
//                                                                             invoiced:false,checkList: []
//                                                                             ,includeReadings: true,includeDosages: true)
//                                
//                                recurringServiceStops.append(singleRecurringServiceStop)
//                                let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
//                                let serviceStopId = "S" + String(serviceStopCount)
//                                
//                                try await dataService.uploadServiceStop(companyId: companyId,
//                                                                                      serviceStop: ServiceStop(id:serviceStopId,
//                                                                                                               typeId: rss.typeId,
//                                                                                                               customerName: rss.customerName,
//                                                                                                               customerId: rss.customerId,
//                                                                                                               address: rss.address,
//                                                                                                               dateCreated: Date(),
//                                                                                                               serviceDate: pushDate,
//                                                                                                               duration: 0,
//                                                                                                               rate:0,
//                                                                                                               tech: rss.tech,
//                                                                                                               techId: rss.techId,
//                                                                                                               recurringServiceStopId: rss.id,
//                                                                                                               description: rss.description,
//                                                                                                               serviceLocationId: rss.locationId ?? "1",
//                                                                                                               type: rss.type,
//                                                                                                               typeImage: rss.typeImage,
//                                                                                                               jobId:"",
//                                                                                                               finished: false,
//                                                                                                               skipped: false,
//                                                                                                               invoiced:false,checkList: []
//                                                                                                               ,includeReadings: true,includeDosages: true))
//                            }
//                            if month {
//                                monthCounter = monthCounter + 1
//                                counter = counter + 30
//                            }
//                            counter = counter + numFrequency
//                        }
//                    }
//                    print(recurringServiceStops)
//                    
//                }
//                
//            }
//        }
//        
//    }
    func uploadServiceStop(companyId:String,serviceStop:ServiceStop) async throws {
        try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
    }
    func uploadGenericServicestops(user:DBUser,companyId:String) async throws {
        for stop in mockServiceStopData{
            var pushStop = stop
            pushStop.techId = user.id
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: pushStop)
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getAllServiceStops(companyId:String) async throws{
        self.serviceStops = try await dataService.getAllServiceStops(companyId: companyId)
    }
    func getAllServiceStopsByCustomer(companyId:String,customerId:String,startDate:Date,endDate:Date) async throws{
        print("Func Get All Service Stops By Customer")
        self.serviceStops = try await dataService.getAllServiceStopsByCustoer(companyId: companyId, customerId: customerId, startDate: startDate, endDate: endDate)
    }
    
    func get25ServiceStops(companyId:String) async throws{
        self.serviceStops = try await dataService.getAllServiceStopsSortedByTime(companyId: companyId, descending: true, count: 25)
    }
    func getServiceStopsBetweenDates(companyId:String,startDate:Date,endDate:Date) async throws{
        self.serviceStops = try await dataService.getAllServiceStopsBetweenDate(companyId: companyId, startDate: startDate, endDate: endDate)
    }
    func getServiceStopsBetweenDatesForUser(companyId:String,startDate:Date,endDate:Date,userId:String) async throws{
        self.serviceStops = try await dataService.getAllServiceStopsBetweenDateByUserId(companyId: companyId, startDate: startDate, endDate: endDate, userId: userId)
    }
    func getServiceStopsByRecurringsServiceStop(companyId:String,recurringsServicestop:RecurringServiceStop) async throws{
        self.serviceStops = try await dataService.getServiceStopsByRecurringsServiceStop(companyId: companyId, recurringsServicestop: recurringsServicestop)
    }
    func getServiceStopsBetweenDatesAndByType(companyId:String,startDate:Date,endDate:Date,workOrderType:String) async throws{
        self.serviceStops = try await dataService.getServiceStopsBetweenDatesAndByType(companyId: companyId, startDate: startDate, endDate: endDate,workOrderType: workOrderType)
    }
    func getServiceStopsBetweenDatesAndByCustomer(companyId:String,startDate:Date,endDate:Date,customer:Customer) async throws{
        self.serviceStops = try await dataService.getServiceStopsBetweenDatesAndByCustomer(companyId: companyId, startDate: startDate, endDate: endDate,customer: customer)
    }
    func getUnfinishedServiceStopsByCustomer(companyId:String,customer:Customer) async throws{
        self.serviceStops = try await dataService.getUnfinishedServiceStopsByCustomer(companyId: companyId,customer: customer)
    }
    func getUnfinished4ServiceStopsByCustomer(companyId:String,customer:Customer) async throws{
        self.serviceStops = try await dataService.getUnfinished4ServiceStopsByCustomer(companyId: companyId,customer: customer)
    }
    func getServiceStopById(companyId:String,serviceStopId:String) async throws {
        self.serviceStop = try await dataService.getServiceStopById(serviceStopId:serviceStopId, companyId: companyId)
    }
    func getServiceStopByListFromActiveRoutes(companyId:String,activeRoutes:[ActiveRoute]) async throws {
        var serviceStopDict:[String:[ServiceStop]] = [:]
        
        for route in activeRoutes {
            var listOfStops:[ServiceStop] = []
            for id in route.serviceStopsIds{
                let stop = try await dataService.getServiceStopById(serviceStopId:id, companyId: companyId)
                listOfStops.append(stop)
            }
            serviceStopDict[route.techName] = listOfStops
        }

        self.serviceStopDictionary = serviceStopDict
    }
    func getServiceStopByList(companyId:String,serviceStopIds:[String]) async throws {
        var listOfStops:[ServiceStop] = []
        print("Gettings List For \(serviceStopIds)")
        for id in serviceStopIds{
            print(id)
            let stop = try await dataService.getServiceStopById(serviceStopId:id, companyId: companyId)
            listOfStops.append(stop)
            print(" - Success")
        }
        self.serviceStops = listOfStops
    }
    func getServiceStopSnapShot(companyId:String) async throws {
        var typesAndAmount: [String:Int] = [:]
        let stops = try await dataService.getAllServiceStopsBetweenDate(companyId: companyId, startDate: Date().startOfDay(), endDate: Date().endOfDay())
        self.serviceStops = Array(stops.prefix(10))
        for stop in stops {
            
            if typesAndAmount[stop.type] == nil {
                //Does Not have type Yet
                print("Type Not In Dict")
                typesAndAmount[stop.type] = 1
            } else {
//Un wraps amount
                if let amount = typesAndAmount[stop.type] {
                    typesAndAmount[stop.type] = amount + 1
                } else {
                    typesAndAmount[stop.type] = 1
                }
            }
        }
        print(typesAndAmount)
        self.typesAndAmount = typesAndAmount
    }
    func getserviceStopsByJobId(companyId: String,jobId:String) async throws {
        self.serviceStops = try await dataService.getServiceStopByJobId(companyId: companyId, jobId: jobId)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateServiceStop(companyId:String,user:DBUser,originalServiceStop:ServiceStop,updatedServiceStop:ServiceStop) async throws {
        
        try await dataService.updateServiceStop(companyId: companyId, user: user, originalServiceStop: originalServiceStop, newServiceStop: updatedServiceStop)
    }
    
    func updateServiceStopOperationStatus(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: stop, operationStatus: operationStatus)
    }
    func updateServiceStopBillingStatus(companyId:String,stop:ServiceStop,billingStatus:ServiceStopBillingStatus) async throws {
        
        try await dataService.updateServicestopBillingStatus(companyId: companyId, serviceStop: stop, billingStatus: billingStatus)
    }
    func updateServiceStopWithValidation(){
        
    }
    func updateServiceStopListServiceDate(companyId:String,serviceStopList:[ServiceStop],date:Date,companyUser:CompanyUser) async throws{ //DEVELOPER ADD CHANGE IN TECHNICIAN
        if companyUser.id == "" {
            throw FireBaseRead.unableToRead
        }
        for stop in serviceStopList {
            try await dataService.updateServiceStopServiceDate(companyId: companyId, serviceStop: stop, serviceDate: date,companyUser: companyUser)
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELTE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             FUNCTIONS
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
    
    
    //    func getDailyDisplayRoutes(date: Date,user:DBUser,listOfTechs:[CompanyUser]) async throws{
    //        var routes:[Route] = []
    //        print("Attempting to retreive Service Stops for \(fullDate(date: date))")
    //        for tech in listOfTechs {
    //            let stops = try await dataService.getAllServiceStopsByDateAndTech(date: date,companyId: companyId, companyUser: tech)
    //            routes.append(Route(id: UUID().uuidString, name: tech.displayName ?? "", day: "Day", serviceStops: stops, startTime: Date(), endTime: Date(), tech: tech, durationSeconds: 0, distanceMiles: 0.0))
    //        }
    //        self.routes = routes
    //
    //    }
    //    func TechListSelectedByDate(date: Date,user:DBUser) async throws{
    ////        var routes:[Route]
    //        var serviceStopsByCompanyUser: [CompanyUser:[ServiceStop]] = [CompanyUser(id: "", email: "", photoUrl: "", dateCreated: Date(), firstName: "", lastName: "", company: "", companyId: "", displayName: "", position: "", hireDate: Date(), fireDate: Date()):[]]
    //        serviceStopsByCompanyUser.removeAll()
    //
    //        var techs:[CompanyUser] = []
    //        print("Attempting to retreive Service Stops for \(fullDate(date: date))")
    //
    //        let stops = try await dataService.getAllServiceStopsByDate(date: date,companyId: companyId)
    ////        print("Stops")
    ////        print(stops)
    ////        self.serviceStopList = stops
    //
    //        print("Retreived Service stops for \(fullDate(date: date))")
    ////        print("Attempting to retreive Techs for \(fullDate(date: date))")
    //        if stops.count > 0 {
    //            let result = try await DBUserManager.shared.FindTechs(stops: stops,companyId: user.companyId)
    //            techs = result.techs
    //            serviceStopsByCompanyUser = result.dict
    //        }
    ////        for tech in techs {
    ////            var listOfServiceStops:[ServiceStop] = []
    ////            for stop in
    ////        }
    //        print("techs")
    //        print(techs)
    //        print("serviceStopsByCompanyUser")
    //        print(serviceStopsByCompanyUser)
    //        self.dailyDisplayCompanyUsers = techs
    //        self.serviceStopsByCompanyUser = serviceStopsByCompanyUser
    ////        print("Retreived Techs for \(fullDate(date: date))")
    //
    //    }
    
    
    
    enum FilterOption:String, CaseIterable{
        case noFilter
        case priceHigh
        case priceLow
    }
    func filterSelected(companyId:String,option: FilterOption) async throws{
        //        let user = try await DBUserManager.shared.loadCurrentUser()
        
        switch option{
        case .priceHigh:
            self.serviceStops = try await dataService.getAllServiceStopsSortedByPrice(companyId: companyId, descending: true)
            break
        case .priceLow:
            self.serviceStops = try await dataService.getAllServiceStopsSortedByPrice(companyId: companyId, descending: false)
            break
        case .noFilter:
            self.serviceStops = try await dataService.getAllServiceStops(companyId: companyId)
            break
        }
        self.selectedFilter = option
    }
    
    func DateSelected(date: Date,companyId:String) async throws{
        
        self.serviceStops = try await dataService.getAllServiceStopsByDate(companyId: companyId, date: date)
        
    }
    //takes all the service stops and finds all unique techs in all of the service stops. only use on daily.
    //    func FindTechsArray(stops:[ServiceStop],companyId:String) async throws{
    //        self.currentTechs = try await DBUserManager.shared.FindTechs(stops: stops,companyId: companyId).techs
    //
    //    }
    func TechAndDate(companyId:String,date: Date,techId:String) async throws{
        var finishedServiceStops:[ServiceStop] = []
        let serviceStopList = try await dataService.getAllServiceStopsByDayAndTech(companyId: companyId, date: date,techId:techId)
        self.serviceStops = serviceStopList
        
        for serviceStop in serviceStopList {
            if serviceStop.operationStatus == .finished {
                finishedServiceStops.append(serviceStop)
            }
        }
        self.finishesServiceStops  = finishedServiceStops
    }
    func getUnfinishedStopsTechAndDate(companyId:String,date: Date,techId:String) async throws {
        //        let user = try await DBUserManager.shared.loadCurrentUser()
        
        self.unfinishedServiceStopCount = try await dataService.getAllUnfinishedServiceStopsByDayAndTech(companyId: companyId, date: date,techId:techId).count
        //        self.unfinishedServiceStopCount = 5
    }
    func getUnfinishedStopsTechAndDateFromList(serviceStopList: [ServiceStop]) {
        var serviceStopCount:Int = 0
        for stop in serviceStopList {
            
            if stop.operationStatus == .finished {
                serviceStopCount = serviceStopCount + 1
            }
        }
        self.finishedServiceStopCount = serviceStopCount
    }
    func getServiceStopBySomething(companyId:String){
        
        Task{
            //            let user = try await DBUserManager.shared.loadCurrentUser()
            let (newServiceStops,lastDocument) = try await dataService.getServiceStopBySomething(companyId: companyId, count: 5, lastDocument: lastDocument)
            self.serviceStops.append(contentsOf: newServiceStops)
        }
    }
    func addNewserviceStop(companyId:String,serviceStop:ServiceStop,workOrderTempalte:JobTemplate,tech:DBUser) async throws{
        print("Attempting to add Service Stop: \(serviceStop)")
        
        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
        print(serviceStopCount)
        try await dataService.uploadServiceStop(
            companyId: companyId,
            serviceStop: ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: "S" + String(serviceStopCount),
                companyId: "",
                companyName: "",
                customerId: serviceStop.customerId,
                customerName: serviceStop.customerName,
                address: serviceStop.address,
                dateCreated: serviceStop.dateCreated,
                serviceDate: serviceStop.serviceDate,
                duration: serviceStop.duration,
                estimatedDuration: serviceStop.estimatedDuration,
                tech: serviceStop.tech,
                techId: serviceStop.techId,
                recurringServiceStopId: serviceStop.recurringServiceStopId,
                description: serviceStop.description,
                serviceLocationId: serviceStop.serviceLocationId,
                typeId: serviceStop.typeId,
                type: serviceStop.type,
                typeImage: serviceStop.typeImage,
                jobId: serviceStop.jobId,
                operationStatus: serviceStop.operationStatus,
                billingStatus: serviceStop.billingStatus,
                includeReadings: serviceStop.includeReadings,
                includeDosages: serviceStop.includeDosages,
                otherCompany: serviceStop.otherCompany,
                laborContractId: serviceStop.laborContractId,
                contractedCompanyId: serviceStop.contractedCompanyId,
                isInvoiced: serviceStop.isInvoiced
            )
        )
    }
    func addNewServiceStopWithValidation(
        companyId:String,
        typeId: String,
        customerName: String,
        customerId: String,
        address: Address,
        dateCreated: Date,
        serviceDate: Date,
        duration: String,
        tech: String,
        techId: String,
        recurringServiceStopId: String,
        description: String,
        serviceLocationId: String,
        type: String,
        typeImage: String,
        jobId: String,
        operationStatus: ServiceStopOperationStatus,
        billingStatus: ServiceStopBillingStatus,
        includeReadings: Bool,
        includeDosages: Bool
    ) async throws -> String{
        guard let duration = Double(duration) else {
            print("Can not Convert duration to Int")
            throw FireBasePublish.unableToPublish
        }
        
        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: companyId)
        print("Service Order Count >> \(serviceStopCount)")
        let serviceStopId = "S" + String(serviceStopCount)
        try await dataService.uploadServiceStop(
            companyId: companyId,
            serviceStop: ServiceStop(
                id: "comp_ss_" + UUID().uuidString,
                internalId: serviceStopId,
                companyId: companyId,
                companyName: customerName,
                customerId: customerId,
                customerName: "",
                address: address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                startTime: nil,
                endTime: nil,
                duration: 0,
                estimatedDuration: 0, // DEVELOPER Calculate Estimated Duration
                tech: tech,
                techId: techId,
                recurringServiceStopId: recurringServiceStopId,
                description: description,
                serviceLocationId: serviceLocationId,
                typeId: typeId,
                type: type,
                typeImage: typeImage,
                jobId: jobId,
                jobName: "",
                operationStatus: operationStatus,
                billingStatus: billingStatus,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )
        )
        
        return serviceStopId
    }

    func getDosageFromTemplateAndDosage(template:DosageTemplate,dosageList:[Dosage]) -> String{
        let id = template.id
        var amountList:[String] = []
        for dosage in dosageList {
            if dosage.templateId == id {
                amountList.append(dosage.amount ?? "")
            }
        }
        return amountList.first ?? "NA"
    }
    func checkDosageListForDuplicates(dosageListChecking:[Dosage],checkingDosage:Dosage) -> [Dosage] {
        var dosageList:[Dosage] = dosageListChecking
        var templateIdList:[String] = []
        for dosage in dosageList {
            templateIdList.append(dosage.templateId)
        }
        if templateIdList.contains(checkingDosage.templateId) {
            if let index = templateIdList.firstIndex(of: checkingDosage.templateId) {
                dosageList.remove(at:index)
                dosageList.append(checkingDosage)
                
            }
        } else {
            dosageList.append(checkingDosage)
        }
        return dosageList
        
    }
    func getReadingFromTemplateAndReadingList(template:ReadingsTemplate,readingList:[Reading]) -> String{
        let id = template.id
        var amountList:[String] = []
        for reading in readingList {
            if reading.templateId == id {
                amountList.append(reading.amount ?? "")
            }
        }
        return amountList.first ?? "NA"
    }
    func checkReadingListForDuplicates(readingListChecking:[Reading],checkingReading:Reading) -> [Reading] {
        var readingList:[Reading] = readingListChecking
        var templateIdList:[String] = []
        for dosage in readingList {
            templateIdList.append(dosage.templateId)
        }
        if templateIdList.contains(checkingReading.templateId) {
            if let index = templateIdList.firstIndex(of: checkingReading.templateId) {
                readingList.remove(at:index)
                readingList.append(checkingReading)
                
            }
        } else {
            readingList.append(checkingReading)
        }
        return readingList
        
    }
    func addServiceStopToCustomerHistory(companyId: String,serviceStop:ServiceStop,stopData:StopData) async throws{
        try await dataService.uploadReadingToCustomerHistory(companyId:companyId,serviceStop: serviceStop, stopData: stopData)
        
    }
    func addServiceStopToServiceStop(companyId:String,serviceStop:ServiceStop,stopData:StopData) async throws{
        try await dataService.uploadReadingToServiceStop(companyId: companyId,serviceStop: serviceStop, stopData: stopData)
        
    }
    func finishServiceStop(companyId:String,serviceStop:ServiceStop) async throws{
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: serviceStop, operationStatus: .finished)
        
    }
    func skipServiceStop(companyId:String,serviceStop:ServiceStop) async throws{
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: serviceStop, operationStatus: .skipped)

    }
    func unfinishServiceSerop(companyId:String,serviceStop:ServiceStop) async throws{
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: serviceStop, operationStatus: .notFinished)
    }
    func getAllHistoryByCustomer(companyId:String,customer: Customer)async throws{
        print("Trying to get all History By Customer")
        let customerStopData = try await dataService.readAllHistory(companyId: companyId, customer: customer)
        print(customerStopData)
        self.readingHistory = customerStopData
        
    }
    func getHistoryByCustomerByDateRange(companyId:String,customer: Customer,startDate:Date,endDate:Date)async throws{
        self.readingHistory = try await dataService.getHistoryByCustomerByDateRange(companyId: companyId, customer: customer,startDate: startDate,endDate:endDate)
        
    }
    func showServiceHistory(stopHistory : [StopData],readingsTemplates : [ReadingsTemplate],dosageTemplates : [DosageTemplate]){
        var totalData:[StopHistoryDisplay] = []
        var biggestName = 0
        
        for stop in stopHistory {
            var dosageList:[Double] = []
            var readingList:[Double] = []
            
            for template in dosageTemplates {
                let stringCount = template.name?.count
                if stringCount ?? 0 > biggestName {
                    biggestName = stringCount ?? 0
                }
                let chemicalDosage = Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00
                
                dosageList.append(chemicalDosage)
            }
            for template in readingsTemplates {
                let stringCount = template.name.count
                if stringCount > biggestName {
                    biggestName = stringCount
                }
                let chemicalReading = Double(stop.readings[template.name] as! String) ?? 0.00
                
                readingList.append(chemicalReading)
            }
            totalData.append(StopHistoryDisplay(id: UUID().uuidString, serviceStopId: stop.serviceStopId, date:stop.date , readings: readingList, dosages: dosageList))
            
        }
        self.biggestName = biggestName
        self.serviceHistory = totalData
        
    }
    
    func convertToChartAbleData(stopHistory : [StopData],readingsTemplates : [ReadingsTemplate],dosageTemplates : [DosageTemplate]){
        //        print("stopHistory")
        //        print(stopHistory)
        //        print("readingsTemplates")
        //        print(readingsTemplates)
        //        print("dosageTemplates")
        //        print(dosageTemplates)
        //
        var totalData:[ChartDataArray] = []
        
        for template in readingsTemplates {
            var chartDataList:[ChartData] = []
            
            for stop in stopHistory {
                let chartDataPoint:ChartData = ChartData(id: UUID().uuidString, date: stop.date, amount: Double(stop.readings[template.name] as! String) ?? 0.00)
                
                chartDataList.append(chartDataPoint)
            }
            totalData.append(ChartDataArray(name: template.name, chartData: chartDataList))
        }
        for template in dosageTemplates {
            var chartDataList:[ChartData] = []
            
            for stop in stopHistory {
                let chartDataPoint:ChartData = ChartData(id: UUID().uuidString, date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00)
                
                chartDataList.append(chartDataPoint)
            }
            totalData.append(ChartDataArray(name: template.name ?? "NA", chartData: chartDataList))
        }
        self.chartAbleData = totalData
    }
    func calculatePNL(stopHistory : [StopData],readingsTemplates : [ReadingsTemplate],dosageTemplates : [DosageTemplate],monthlyRate:Double,companyId:String) async{
        
        var totalData:[PNLDataPointArray] = []
        let startDate = makeDate(year: 2023, month: 7, day: 1, hr: 0, min: 0, sec: 0)
        let endDate = makeDate(year: 2023, month: 8, day: 1, hr: 0, min: 0, sec: 0)
        var dataPoints:[PNLChem] = []
        var dataPointsByDay:[PNLChem] = []
        var dateList:[Date] = []
        for stop in stopHistory {
            
            if stop.date > startDate && stop.date < endDate {
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
                
//                totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
//                dataPointsByDay = []
            }
        }
        self.PNLData = totalData
        //        self.PNLData = dataPoints
        var chemicalCost: Double = 0.00
        var laborCost: Double = 0.00
        
        for data in dataPoints {
            chemicalCost = data.totalCost + chemicalCost
        }
        for data in totalData {
            laborCost = data.laborCost + laborCost
        }
        self.laborCost = laborCost
        self.chemicalCost = chemicalCost
        let totalCost = laborCost + chemicalCost
        self.totalCost = totalCost
        
        self.profit = monthlyRate - totalCost
        //        self.chartAbleData = totalData
    }
    
    func getFourMostRecentHistoryByCustomer(companyId:String,customer: Customer)async throws{
        self.readingHistory = try await dataService.readFourMostRecentStops(companyId: companyId, customer: customer)
        
    }
    func getFourMostRecentHistoryByCustomerId(companyId:String,customerId: String)async throws{
        self.readingHistory = try await dataService.readFourMostRecentStopsById(companyId: companyId, customerId: customerId)
        
    }
    func getFourMostRecentHistoryByCustomerIdServiceLocationAndBodyOfwater(companyId:String,customerId: String,serviceLocationId:String,bodyOfwaterId:String)async throws{
        print("Getting 4 most Recent History")
        self.readingHistory = try await dataService.readFourMostRecentStopsByCustomerIdServiceLocationIdAndBodyOfWaterId(companyId: companyId, customerId: customerId, serviceLocationId: serviceLocationId, bodyOfWaterId: bodyOfwaterId)
        
    }
    
    func getChangeHistoryByServiceStop(companyId:String,serviceStop:ServiceStop)async throws{
        
        self.changeHistory = try await dataService.getHistoryServiceStopsBy(companyId: companyId, serviceStop: serviceStop)
        
    }
    func getBillableServiceStopsByDate(companyId:String,startDate:Date,endDate:Date)async throws{
        
        self.serviceStops = try await dataService.getBillableServiceStopsByDate(startDate: startDate,endDate: endDate, companyId: companyId)
        
    }
    func changeBillingStatusOfServiceStop(companyId:String,serviceStop:ServiceStop,billingStatus:ServiceStopBillingStatus) async throws{
        
        try await dataService.updateServicestopBillingStatus(companyId: companyId, serviceStop: serviceStop, billingStatus: billingStatus)
        
    }
    // Listeners
    func addListenerForAllServiceStops(companyId:String){
        
        print(companyId)
        dataService.addListenerForAllServiceStops(companyId: companyId) { [weak self] serviceStops in
            self?.serviceStops = serviceStops
        }
    }
    func removeListenerForAllServiceStops(){
        dataService.removeListenerForAllServiceStops()
        print("Listener Cancelled")
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Search / Filter for the Customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    func filterServiceStopList(filterTerm:String,serviceStoplist:[ServiceStop]) {
        //very facncy Search Bar
        var filteredListOfServiceStops:[ServiceStop] = []
        for ss in serviceStoplist {
            
            let tech = ss.tech ?? "tech"
            let rSS = ss.recurringServiceStopId
            let StreetAddress = ss.address.streetAddress
            let City = ss.address.city
            let State = ss.address.state
            let Zip = ss.address.zip
            
            if ss.customerName.lowercased().contains(filterTerm.lowercased()) || ss.description.lowercased().contains(filterTerm.lowercased()) || tech.lowercased().contains(filterTerm.lowercased()) ||  StreetAddress.lowercased().contains(filterTerm.lowercased()) || City.lowercased().contains(filterTerm.lowercased()) || State.lowercased().contains(filterTerm.lowercased()) || Zip.lowercased().contains(filterTerm.lowercased()) || rSS.lowercased().contains(filterTerm.lowercased()) || ss.id.lowercased().contains(filterTerm.lowercased()) {
                
                filteredListOfServiceStops.append(ss)
            }
        }
        self.serviceStopsFilterd = filteredListOfServiceStops
    }
    //    func filterServiceStopByTech(tech:CompanyUser,serviceStoplist:[ServiceStop]) {
    //        //very facncy Search Bar
    //        var filteredListOfServiceStops:[ServiceStop] = []
    //        for ss in serviceStoplist {
    //            let techId = ss.techId ?? "1"
    //            if techId.lowercased().contains(tech.id.lowercased())  {
    //                filteredListOfServiceStops.append(ss)
    //            }
    //        }
    //        self.serviceStopsFilterd = filteredListOfServiceStops
    //    }
    func filterServiceStopByTime(interval:String,serviceStoplist:[ServiceStop]) {
        //very facncy Search Bar
        var filteredListOfServiceStops:[ServiceStop] = []
        for ss in serviceStoplist {
            let am = interval.suffix(2)
            let hourAndMin = interval.replacingOccurrences(of: am, with: "")
            let inBetween = hourAndMin.replacingOccurrences(of: " ", with: "")
            let min = inBetween.suffix(2)
            let hour = inBetween.replacingOccurrences(of: min, with: "")
            let serviceTime:String = time(date: ss.serviceDate)
            
            if serviceTime.lowercased().contains(hour.lowercased()) && serviceTime.lowercased().contains(am.lowercased()) {
                filteredListOfServiceStops.append(ss)
            }
        }
        self.serviceStopsFilterd = filteredListOfServiceStops
    }
    func filterWarningsByCategory(category:String,warningList:[Warning]) {
        //very facncy Search Bar
        var filteredListOfServiceStops:[Warning] = []
        for warning in warningList {
            if warning.category.lowercased().contains(category.lowercased()) {
                filteredListOfServiceStops.append(warning)
            }
        }
        self.filteredWarnings = filteredListOfServiceStops
    }
}
