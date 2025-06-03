//
//  ActiveRouteViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//



import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ActiveRouteViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var routeToday: Bool = false
    
    @Published private(set) var activeRoute: ActiveRoute? = nil
    @Published private(set) var totalStops: Int? = nil
    @Published private(set) var finishedStops: Int? = nil
    
    //Summary Variables
    @Published private(set) var totalMiles: Double? = nil
    @Published private(set) var totalTime: Double? = nil

    //ARRAYS
    @Published private(set) var listOfActiveRoutes:[ActiveRoute] = []
    @Published private(set) var serviceStopList:[ServiceStop] = []
    
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRoute(companyId: String,activeRoute:ActiveRoute) async throws {
        try await dataService.uploadRoute(companyId: companyId, activeRoute: activeRoute)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllActiveRoutes(companyId: String,param:String) async throws{
        
        self.listOfActiveRoutes = []
        //try await dataService.getAllActiveRoutes(companyId: companyId, param: param)
    }
    func getAllActiveRoutesAndCheck(companyId: String,day:String,date:Date) async throws{
        
         
             //DEVELOPER FIX THIS SHOULD NOT CREATE ACTIVE ROUTES IF THERE ARE NO SERVICE STOPS
             var finalListOfActiveRoutes:[ActiveRoute] = []
             let techList = try await DBUserManager.shared.getAllCompayTechs(companyId: companyId)
             for tech in techList {
                 print("Getting Active Routes on \(day) for \(tech.firstName) \(tech.lastName)")
                 let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: tech)
                 if listOfActiveRoutes.count == 0 {
                     print("Should Generate A New Active Route")
                     let serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                     if serviceStopList.count != 0 {
                         print("Create Route with \(serviceStopList.count) Service Stops")
                         var serviceStopIdList:[String] = []
                         var duration:Int = 0
                         var finishedCount:Int = 0
                         
                         for stop in serviceStopList {
                             serviceStopIdList.append(stop.id)
                             duration = duration + stop.duration
                             if stop.operationStatus == .finished {
                                 finishedCount = finishedCount + 1
                             }
                         }
                         let techName = (tech.firstName) + " " + (tech.lastName)
                         let route = ActiveRoute(id: UUID().uuidString,
                                                 name: "Name",
                                                 date: date,
                                                 serviceStopsIds: serviceStopIdList,
                                                 techId: tech.id,
                                                 techName: techName,
                                                 durationMin: duration,
                                                 distanceMiles: 69,
                                                 status: .didNotStart,
                                                 totalStops: serviceStopList.count,
                                                 finishedStops:finishedCount,
                                                 vehicalId: ""
                         )
                         
                         try await dataService.uploadRoute(companyId: companyId,
                                                                   activeRoute: route)
                         finalListOfActiveRoutes.append(route)
                         self.serviceStopList = serviceStopList
                         self.totalStops = serviceStopList.count
                         self.finishedStops = finishedCount
                     } else {
                         print("No Service Stop")
                         self.serviceStopList = []
                         self.totalStops = 0
                         self.finishedStops = 0
                         self.routeToday = false
                         
                     }
                 } else if listOfActiveRoutes.count == 1 {
                     print("Get Current Active Route")
                     let activeRoute = listOfActiveRoutes.first!
                     
                     print("Getting Service Stops From Route")
                     let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: date, tech: tech)
                     //Compares service stops on this day with this tech, by the amount held in the route.
                     if actualServiceStopCount == activeRoute.serviceStopsIds.count{
                         if actualServiceStopCount != 0 {
                             
                             self.serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                             let finishedServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateAndFinishedCount(companyId: companyId, date: date, tech: tech)
                             self.totalStops = actualServiceStopCount
                             self.finishedStops = finishedServiceStopCount
                             finalListOfActiveRoutes.append(activeRoute)
                             
                         }
                     } else {
                         var finishedCount:Int = 0
                         
                         let serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                         if serviceStopList.count != 0 {
                             for stop in serviceStopList {
                                 if !activeRoute.serviceStopsIds.contains(stop.id) {
                                     try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: activeRoute, serviceStopId: stop.id)
                                 }
                                 if stop.operationStatus == .finished{
                                     finishedCount = finishedCount + 1
                                 }
                             }
                             finalListOfActiveRoutes.append(activeRoute)
                             self.serviceStopList = serviceStopList
                             self.totalStops = serviceStopList.count
                             self.finishedStops = finishedCount
                         }
                     }
                 } else {
                     print("This should Never Happen 1")
                     print("No Service Stop")
                     self.serviceStopList = []
                     self.totalStops = 0
                     self.finishedStops = 0
                     self.routeToday = false
                 }
             }
             self.listOfActiveRoutes = finalListOfActiveRoutes
             //        self.listOfActiveRoutes = try await RouteManager.shared.getAllActiveRoutes(companyId: companyId, param: param)
         }
         
    
    

    func getSingleRoute(companyId: String,activeRouteId:String) async throws{
        self.activeRoute = try await dataService.getActiveRoute(companyId: companyId, activeRouteId: activeRouteId)
    }
    func getRecentActiveRouteForTech(companyId:String,techId:String,days:Int) async throws {
        self.listOfActiveRoutes = try await dataService.getRecentActiveRouteForTech(companyId: companyId, techId: techId, days: days)
    }
    func checkForActiveRouteOnDateForUser(companyId: String,date:Date,tech:DBUser) async throws{
        let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: tech)
        if listOfActiveRoutes.count == 0 {
            print("Should Generate A New Active Route")
            //Generate New Active Route
            let serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
            print("Create Route with \(serviceStopList.count) Service Stops")
            var serviceStopIdList:[String] = []
            var duration:Int = 0
            var finishedCount:Int = 0
            if serviceStopList.count != 0 {
                for stop in serviceStopList {
                    serviceStopIdList.append(stop.id)
                    duration = duration + stop.duration
                    if stop.operationStatus == .finished {
                        finishedCount = finishedCount + 1
                    }
                }
                let techName = (tech.firstName) + " " + (tech.lastName)
                
                let route = ActiveRoute(id: UUID().uuidString,
                                        name: "Name",
                                        date: date,
                                        serviceStopsIds: serviceStopIdList,
                                        techId: tech.id,
                                        techName: techName,
                                        durationMin: duration,
                                        distanceMiles: 69,
                                        status: .didNotStart,
                                        totalStops: serviceStopList.count,
                                        finishedStops:finishedCount,
                                        vehicalId: ""
                )
                
                try await dataService.uploadRoute(companyId: companyId,
                                                          activeRoute: route)
                self.activeRoute = route
                self.serviceStopList = serviceStopList
                self.totalStops = serviceStopList.count
                self.finishedStops = finishedCount
            } else {
                print("No Service Stop")
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
                self.routeToday = false
            }
        } else if listOfActiveRoutes.count == 1 {
            
            print("Get Current Active Route")
            let activeRoute = listOfActiveRoutes.first!
            self.activeRoute = activeRoute
            
            print("Getting Service Stops From Route")
            let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: date, tech: tech)
            //Compares service stops on this day with this tech, by the amount held in the route.
            if actualServiceStopCount == activeRoute.serviceStopsIds.count{
                self.serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                let finishedServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateAndFinishedCount(companyId: companyId, date: date, tech: tech)
                self.totalStops = actualServiceStopCount
                self.finishedStops = finishedServiceStopCount
            } else {
                var finishedCount:Int = 0
                
                let serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                for stop in serviceStopList {
                    if !activeRoute.serviceStopsIds.contains(stop.id) {
                        try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: activeRoute, serviceStopId: stop.id)
                    }
                    if stop.operationStatus == .finished {
                        finishedCount = finishedCount + 1
                    }
                }
                self.serviceStopList = serviceStopList
                self.totalStops = serviceStopList.count
                self.finishedStops = finishedCount
                
            }
        } else {
            print("No Service Stop")
            self.serviceStopList = []
            self.totalStops = 0
            self.finishedStops = 0
            self.routeToday = false
            print("This should Never Happen 2")
        }
    }
    func checkForActiveRouteOnDateForUserFromRecurringRoute(companyId: String,date:Date,tech:DBUser,recurringRoute:RecurringRoute?) async throws{
        if recurringRoute == nil {
            //checks for one off Service stops not on Route.
            print("Recurring Route is Nil")
            let serviceStopListFromToday = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
            if serviceStopListFromToday.isEmpty {
                // no stops on this day for this tech. so returns nothing
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
                self.routeToday = false
            } else {
                //if service stops exist and no route exists Create an active Route // Checks if one already exists
                let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: tech)
                if listOfActiveRoutes.count == 0 {
                    print("Should Generate A New Active Route")
                    //Generate New Active Route
                    print("Create Route with \(serviceStopListFromToday.count) Service Stops")
                    
                    var serviceStopIdList:[String] = []
                    var duration:Int = 0
                    var finishedCount:Int = 0
                    if serviceStopListFromToday.count != 0 {
                        for stop in serviceStopListFromToday {
                            serviceStopIdList.append(stop.id)
                            duration = duration + stop.duration
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (tech.firstName) + " " + (tech.lastName)
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: date,
                                                serviceStopsIds: serviceStopIdList,
                                                techId: tech.id,
                                                techName: techName,
                                                durationMin: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount,
                                                vehicalId: ""
                        )
                        do {
                            try await dataService.uploadRoute(companyId: companyId,
                                                                      activeRoute: route)
                        } catch {
                            throw MobileDisplayError.failedToUpload
                        }
                        self.activeRoute = route
                        self.serviceStopList = serviceStopListFromToday
                        self.totalStops = serviceStopList.count
                        self.finishedStops = finishedCount
                        self.routeToday = true
                        
                    } else {
                        print("No Service Stop")
                        self.serviceStopList = []
                        self.totalStops = 0
                        self.finishedStops = 0
                        self.routeToday = false
                    }
                } else if listOfActiveRoutes.count == 1 {
                    
                    print("Get Current Active Route")
                    let activeRoute = listOfActiveRoutes.first!
                    self.activeRoute = activeRoute
                    
                    print("Getting Service Stops From Route")
                    let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: date, tech: tech)
                  
                    //Compares service stops on this day with this tech, by the amount held in the route.
                    if actualServiceStopCount == activeRoute.serviceStopsIds.count{
                        self.serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                        let finishedServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateAndFinishedCount(companyId: companyId, date: date, tech: tech)
                        self.totalStops = actualServiceStopCount
                        self.finishedStops = finishedServiceStopCount
                        self.routeToday = true
                        
                    } else {
                        var finishedCount:Int = 0
                        for stop in serviceStopListFromToday {
                            if !activeRoute.serviceStopsIds.contains(stop.id) {
                                do {
                                    try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: activeRoute, serviceStopId: stop.id)
                                } catch {
                                    throw MobileDisplayError.failedToUpload
                                }
                            }
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        self.serviceStopList = serviceStopListFromToday
                        self.totalStops = serviceStopList.count
                        self.finishedStops = finishedCount
                        self.routeToday = true
                        
                    }
                } else {
                    print("This should Never Happen 3")
                    print("No Service Stop")
                    self.serviceStopList = []
                    self.totalStops = 0
                    self.finishedStops = 0
                    self.routeToday = false
                }
            }
        } else {
            print("Recurring Route Exists")

            // Need to Add Order Here from Recurring Route so that The Recurring route actually means something
            
            let serviceStopListFromToday = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
        
            if serviceStopListFromToday.isEmpty {
                // no stops on this day for this tech. so returns nothing
                print("No Service Stops Today \(fullDateAndDay(date: date))")
                self.routeToday = false
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
            } else {
                print("Has \(serviceStopListFromToday.count) stops on  \(fullDateAndDay(date: date))")
                
                //if service stops exist and no route exists Create an active Route // Checks if one already exists
                let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: tech)
                if listOfActiveRoutes.count == 0 {
                    print("Should Generate A New Active Route")
                    //Generate New Active Route
                    print("Create Route with \(serviceStopListFromToday.count) Service Stops")
                    var serviceStopIdList:[String] = []
                    var duration:Int = 0
                    var finishedCount:Int = 0
                    if serviceStopListFromToday.count != 0 {
                        for stop in serviceStopListFromToday {
                            serviceStopIdList.append(stop.id)
                            duration = duration + stop.duration
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (tech.firstName) + " " + (tech.lastName)
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: date,
                                                serviceStopsIds: serviceStopIdList,
                                                techId: tech.id,
                                                techName: techName,
                                                durationMin: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount,
                                                vehicalId: ""
                        )
                        do {
                            try await dataService.uploadRoute(companyId: companyId,
                                                                      activeRoute: route)
                        } catch {
                            throw MobileDisplayError.failedToUpload
                        }
                        self.activeRoute = route
                        self.serviceStopList = serviceStopListFromToday
                        self.totalStops = serviceStopList.count
                        self.finishedStops = finishedCount
                        self.routeToday = true
                        
                    } else {
                        print("No Service Stop")
                        self.serviceStopList = []
                        self.totalStops = 0
                        self.finishedStops = 0
                        self.routeToday = false
                    }
                } else if listOfActiveRoutes.count == 1 {
                    
                    print("Get Current Active Route")
                    let activeRoute = listOfActiveRoutes.first!
                    self.activeRoute = activeRoute
                    
                    print("Getting Service Stops From Route")
                    let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: date, tech: tech)
                    //Compares service stops on this day with this tech, by the amount held in the route.
                    /*
                    if actualServiceStopCount == activeRoute.serviceStopsIds.count{
                        self.serviceStopList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                        let finishedServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateAndFinishedCount(companyId: companyId, date: date, tech: tech)
                        self.totalStops = Double(actualServiceStopCount)
                        self.finishedStops = Double(finishedServiceStopCount)
                    } else {
                     */
                        var finishedCount:Int = 0
                        for stop in serviceStopListFromToday {
                            if !activeRoute.serviceStopsIds.contains(stop.id) {
                                do {
                                try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: activeRoute, serviceStopId: stop.id)
                                } catch {
                                    throw MobileDisplayError.failedToUpload
                                }
                            }
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        self.serviceStopList = serviceStopListFromToday
                        self.totalStops = serviceStopList.count
                        self.finishedStops = finishedCount
                        self.routeToday = true
                        /*
                    }
                         */
                } else {
                    print("This should Never Happen 4")
                    self.serviceStopList = []
                    self.totalStops = 0
                    self.finishedStops = 0
                    self.routeToday = false
                }
            }
            
        }
    }
    
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateActiveRouteFinishedCount(companyId:String,activeRoute:ActiveRoute,positive:Bool) throws {
        if positive {
            let count = activeRoute.finishedStops + 1
            dataService.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        } else {
            let count = activeRoute.finishedStops + -1
            dataService.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        }
    }
    func updateActiveRouteMilage(companyId:String,activeRoute:ActiveRoute,milage:String) {
        
    }
    
    func updateActiveRoute(companyId:String,activeRoute:ActiveRoute,name: String, date: Date, serviceStopsIds: [String], startTime: Date, endTime: Date?, startMilage:String?,endMilage:String?,techId: String, techName: String, traineeId: String?, traineeName: String?, durationSeconds: Int, distanceMiles: Double, status: ActiveRouteStatus) {
        print("Updating Active Route")
        if activeRoute.name != name {
            dataService.updateActiveRouteName(companyId: companyId, activeRouteId: activeRoute.id, name: name)
        } else {
            print("Did not update name, it is the same")
        }
        if activeRoute.date != date {
            dataService.updateActiveRouteDate(companyId: companyId, activeRouteId: activeRoute.id, date: date)
        } else {
            print("Did not update date, it is the same")
        }
        if activeRoute.startTime != startTime {
            print("Updaing Start Time")
            dataService.updateActiveRouteStartTime(companyId: companyId, activeRouteId: activeRoute.id, startTime: startTime)
            
        } else {
            print("Did not update startTime, it is the same")
        }
        if let milage = Int(startMilage ?? "0") {
            
            if activeRoute.startMilage != milage {
                print("Updaing Start Milage")
                
                dataService.updateActiveRouteStartMilage(companyId: companyId, activeRouteId: activeRoute.id, startMilage: milage)
            } else {
                print("Start Milage is Nil")
            }
        } else {
            print("Did not update startMilage, it is the same")
        }
        if activeRoute.endTime != endTime {
            if let time = endTime{
                dataService.updateActiveRouteEndTime(companyId: companyId, activeRouteId: activeRoute.id, endTime: time)
            } else {
                print("End Time is Nil")
            }
        } else {
            print("Did not update endTime, it is the same")
        }
        if let milage = Int(endMilage ?? "0") {
            print("Updating End Milage")

            if activeRoute.endMilage != milage {
                print("End Milage is Different")

                dataService.updateActiveRouteEndMilage(companyId: companyId, activeRouteId: activeRoute.id, endMilage: milage)
            }
            else {
                print("End Mialge is Nil")
            }
        } else {
            print("Did not update endMilage, it is the same")
        }
        if activeRoute.status != status {
            dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: status)
        }else {
            print("Did not update status, it is the same")
        }
        
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func calculateRouteSummary(activeRouteList:[ActiveRoute]) {
        var totalStops:Int = 0
        var finishedStops:Int = 0
        var totalMilage:Double = 0
        var totalTime:Double = 0

        for route in activeRouteList {
       
            if let end = route.endMilage, let start = route.startMilage {
                let milage = end - start
                totalMilage += Double(milage)
            }
            if let end = route.endTime, let start = route.startTime {
                let time = timeBetweenAsSeconds(start: start, end: end)
                totalTime += Double(time)
            }
            totalStops += route.totalStops
            finishedStops += route.finishedStops
        }
        self.totalStops = totalStops
        self.finishedStops = finishedStops
        self.totalMiles = totalMilage
        self.totalTime = totalTime

    }
}
