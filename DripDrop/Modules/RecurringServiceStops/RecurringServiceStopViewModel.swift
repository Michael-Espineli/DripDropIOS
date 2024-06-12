//
//  recurringServiceStopViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/24/23.
//

import Foundation
@MainActor
final class RecurringStopViewModel:ObservableObject{
    @Published private(set) var recurringServiceStops: [RecurringServiceStop] = []
    @Published private(set) var recurringServiceStop: RecurringServiceStop? = nil
    @Published private(set) var selectedRecurringServiceStop: RecurringServiceStop? = nil

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getReucrringServiceStopById(companyId: String,recurringServiceStopId:String) async throws{
        self.recurringServiceStop = try await RecurringServiceStopManager.shared.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
    }
    func getAllRecurringServiceStops(companyId: String) async throws{
        self.recurringServiceStops = try await RecurringServiceStopManager.shared.getAllRecurringServiceStop(companyId: companyId)
    }
    func getAllRecurringServiceStopsByDay(companyId:String,days:[String]) async throws{
        var recurringServiceStopsList:[RecurringServiceStop] = []
        for day in days {
            let stops = try await RecurringServiceStopManager.shared.getRecurringServiceStopsByDays(companyId: companyId, day: day)
            for stop in stops {
                recurringServiceStopsList.append(stop)
            }
        }
        self.recurringServiceStops = recurringServiceStopsList
    }
    func getAllRecurringServiceStopsByDayAndTech(companyId:String,techId:String,days:[String]) async throws{
        var recurringServiceStopsList:[RecurringServiceStop] = []
        for day in days {
            let stops = try await RecurringServiceStopManager.shared.getRecurringServiceStopsByDayAndTech(companyId: companyId,techId: techId, day: day)
            for stop in stops {
                recurringServiceStopsList.append(stop)
            }
        }
        self.recurringServiceStops = recurringServiceStopsList
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    func deleteRecurringServiceStop(recurringServiceStopId : String,companyId: String) async throws {
        print("Delete Recurring Service Stop")
        try await RecurringServiceStopManager.shared.deleteRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
        let serviceStopList = try await ServiceStopManager.shared.getAllServiceStopsSortedByRecurringServiceStops(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
        for ss in serviceStopList {
            try await ServiceStopManager.shared.deleteServiceStop(companyId: companyId, serviceStopId: ss.id)

        }
    }
    func addNewRecurringServiceStop(companyId: String,recurringServiceStop:RecurringServiceStop,
                              standardFrequencyNumber:Int,
                              customFrequencyType:String,
                              CustomFrequency:String,
                              daysOfWeek:[String]) async throws {
        let calendar = Calendar.current
//~~~~~~~~~~~~~~~~Variables Received~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//        let standardFrequencyNumber:Int = 4
//        let customFrequencyType:String = "Year"
//        let CustomFrequency:String = "1"
//        let daysOfWeek:[String] = ["Monday","Wednesday","Friday"]
        if recurringServiceStop.startDate == nil {return}
        let startDate:Date = recurringServiceStop.startDate ?? Date()

        let endDate:Date = recurringServiceStop.endDate ?? Date()
        let noEndDate:Bool = recurringServiceStop.noEndDate

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
                                                            customMeasuresOfTime    : customFrequencyType,
                                                            customEvery: CustomFrequency,
                                                            daysOfWeek: daysOfWeek,
                                                            description: recurringServiceStop.description,
                                                            lastCreated: Date(),
                                                            serviceLocationId: recurringServiceStop.serviceLocationId,
                                                            estimatedTime: recurringServiceStop.estimatedTime ?? "15")


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

    func addNewRecurringStop2(companyId: String,recurringServiceStop:RecurringServiceStop,
                                    standardFrequencyNumber:Int,
                                    customFrequencyType:String,
                                    customFrequency:String) async throws{
        let calendar = Calendar.current
        var functionalStartDate = Date()
        var functionalEndDate = Date()
        var skipWeekEnds:Bool = false
        var custom:Bool = false
        var month:Bool = false

        let recurringServiceStopCount = try await SettingsManager.shared.getRecurringServiceStopCount(companyId: companyId)
        sleep(1)
        let recurringServiceStopId = "R" + String(recurringServiceStopCount)

        var pushRecurringServiceStop = RecurringServiceStop(id: recurringServiceStopId,
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
                                                            customEvery: customFrequency,
                                                            daysOfWeek: [""],                                                            description: recurringServiceStop.description,
                                                            lastCreated: Date(),
                                                            serviceLocationId: recurringServiceStop.serviceLocationId,
                                                            estimatedTime: recurringServiceStop.estimatedTime ?? "15")


        var counter:Int = 0
        var monthCounter:Int = 0
        var numFrequency:Int = 0
        var recurringServiceStops:[ServiceStop] =  []
        var lastCreated:Date = Date()
        switch standardFrequencyNumber{
            //Daily
        case 0:
            numFrequency = 1

            //Weekly
        case 1:
            numFrequency = 7

            //monthly
        case 2:
            month = true
            //annually
        case 3:
            numFrequency = 30

            //everyweekday
        case 4:
            numFrequency = 1
            skipWeekEnds = true
            //custom
        case 5:
            custom = true
            switch customFrequencyType{
            case "Day":
                print("Day")
            case "Week":
                print("Day")
            case "Month":
                print("Day")
            case "Year":
                print("Year")
            default:
                print("Year")

            }
        default:
            numFrequency = 100
        }
        if recurringServiceStop.noEndDate {
            functionalStartDate = pushRecurringServiceStop.startDate ?? Date()
            functionalEndDate = calendar.date(byAdding: .day, value: 28, to: functionalStartDate)!

        } else {
            functionalStartDate = pushRecurringServiceStop.startDate ?? Date()
            functionalEndDate = pushRecurringServiceStop.endDate ?? Date()
        }
        let daysBetween = daysBetween(start: functionalStartDate, end:functionalEndDate )
        print("Num Frequency")
        print(numFrequency)
        print("Days Between")

        print(daysBetween)
        let startDate = pushRecurringServiceStop.startDate ?? Date()
        if custom {
            print("Creating Custom Recurring service Stop")

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
                    print(weekDay(date: pushDate))
                    if weekDay(date: pushDate) == "Saturday" || weekDay(date: pushDate) == "Sunday" {
                        print(weekDay(date: pushDate))
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
                        lastCreated = pushDate

                        recurringServiceStops.append(singleRecurringServiceStop)
//                        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                        let serviceStopId = "S" + String(serviceStopCount)

                        try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)

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
                    lastCreated = pushDate

                          recurringServiceStops.append(singleRecurringServiceStop)
//                          let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                          let serviceStopId = "S" + String(serviceStopCount)

                    try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)

                }
                if month {
                    monthCounter = monthCounter + 1
                    counter = counter + 30
                }
                counter = counter + numFrequency
            }
        }
        pushRecurringServiceStop.lastCreated = lastCreated
        try await RecurringServiceStopManager.shared.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: pushRecurringServiceStop)

    }

    func addAditionAllServiceStops(companyId: String,recurringServiceStop:RecurringServiceStop,standardFrequencyNumber:Int,customFrequencyType:String,CustomFrequency:String,startingDate:Date) async throws{
        let pushRecurringServiceStop = recurringServiceStop
        let calendar = Calendar.current
        var functionalStartDate = Date()
        var functionalEndDate = Date()
        var skipWeekEnds:Bool = false
        var custom:Bool = false
        var month:Bool = false
        var counter:Int = 0
        var monthCounter:Int = 0
        var numFrequency:Int = 0
        var recurringServiceStops:[ServiceStop] =  []
//        switch pushRecurringServiceStop.frequency{
//        case "Weekly":
//            numFrequency = 7
//        case "Bi-Weekly":
//            numFrequency = 14
//
//        case "Tri-Weekly":
//            numFrequency = 21
//
//        case "Quad-Weekly":
//            numFrequency = 28
//
//        default:
//            numFrequency = 100
//
//        }
        switch standardFrequencyNumber{
        //Daily
        case 0:
            numFrequency = 1

        //Weekly
        case 1:
            numFrequency = 7

        //monthly
        case 2:
            month = true
        //annually
        case 3:
            numFrequency = 30

        //everyweekday
        case 4:
            numFrequency = 1
            skipWeekEnds = true
        //custom
        case 5:
            custom = true
            switch customFrequencyType{
            case "Day":
                print("Day")
            case "Week":
                print("Day")
            case "Month":
                print("Day")
            case "Year":
                print("Year")
            default:
                print("Year")

            }
        default:
            numFrequency = 100

        }
        if recurringServiceStop.noEndDate {
            functionalStartDate = recurringServiceStop.startDate ?? Date()
            functionalEndDate = calendar.date(byAdding: .day, value: 14, to: functionalStartDate)!

        } else {
            functionalStartDate = recurringServiceStop.startDate ?? Date()
            functionalEndDate = recurringServiceStop.endDate ?? Date()
        }
        let daysBetween = daysBetween(start: functionalStartDate, end:functionalEndDate )
        print("Num Frequency")
        print(numFrequency)
        print("Days Between")

        print(daysBetween)
        let startDate = recurringServiceStop.startDate ?? Date()
        if custom {
            print("Creating Custom Recurring service Stop")

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
                    print(weekDay(date: pushDate))
                    if weekDay(date: pushDate) == "Saturday" || weekDay(date: pushDate) == "Sunday" {
                        print(weekDay(date: pushDate))
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

                        recurringServiceStops.append(singleRecurringServiceStop)
//                        let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                        let serviceStopId = "S" + String(serviceStopCount)

                        try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)


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
                                                                 tech: recurringServiceStop.tech,
                                                                 techId: recurringServiceStop.techId,
                                                                 recurringServiceStopId: recurringServiceStop.id,
                                                                 description: recurringServiceStop.id,
                                                                 serviceLocationId: recurringServiceStop.locationId ?? "1",
                                                                 type: recurringServiceStop.type,
                                                                 typeImage: recurringServiceStop.typeImage,

                                                                 jobId: "",
                                                                 finished: false,
                                                                 skipped: false,
                                                                 invoiced: false,
                    checkList: [],includeReadings: true,
                    includeDosages: true)

                    recurringServiceStops.append(singleRecurringServiceStop)
//                    let serviceStopCount = try await SettingsManager.shared.getServiceOrderCount()
//                    let serviceStopId = "S" + String(serviceStopCount)

                    try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: singleRecurringServiceStop)

                }
                if month {
                    monthCounter = monthCounter + 1
                    counter = counter + 30
                }
                    counter = counter + numFrequency
            }
        }
        print(recurringServiceStops)

    }


}
