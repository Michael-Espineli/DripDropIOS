//
//  UserRouteOverViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/11/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class UserRouteOverViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var activeRoute: ActiveRoute? = nil
    @Published private(set) var recurringRoute: RecurringRoute? = nil
    @Published private(set) var activeRoutes: [ActiveRoute] = []

    func initalLoad(companyId: String,date:Date) async throws{
        print("")
        print("\(fullDate(date: date))")

        var finalListOfActiveRoutes:[ActiveRoute] = []
        
        let techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        let techNames = techList.map { $0.userName }
        print(techNames)
        print("")
        for tech in techList {
            print("\(tech.userName)")

            var serviceStopsList:[ServiceStop] = []
            
            var hasActiveRoute:Bool = false
            
            var workingActiveRoute:ActiveRoute = ActiveRoute(
                id: UUID().uuidString,
                name: "",
                date: Date(),
                serviceStopsIds: [],
                techId: tech.userId,
                techName: tech.userName,
                durationMin: 0,
                distanceMiles: 0,
                status: .inProgress,
                totalStops: 0,
                finishedStops: 0,
                vehicalId: ""
            )
            
            //     Get All The Necessary Info To Set Up Route Display
            
            let recurringRouteId = weekDay(date: date) + tech.userId
            
            self.recurringRoute = try? await dataService.getSingleRoute(companyId: companyId, recurringRouteId: recurringRouteId)
            //DEVELOPER CHANGE TO COMPANY USER
            serviceStopsList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
            if !serviceStopsList.isEmpty{
                if recurringRoute == nil {
                    print("No Need to Order based on Recurring Route")
                }
                //     Parse Through Data to create what we need
                
                print("Recurring Route Exists")
                
                //            self.reload = true
                
                // Need to Add Order Here from Recurring Route so that The Recurring route actually means something
                
                // Get All Service Stops For Today
                
                // If service stops exist and no route exists Create an active Route // Checks if one already exists
                
                let listOfActiveRoutes = try? await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: tech)
                print("4")
                if let activeRouteList = listOfActiveRoutes {
                    if activeRouteList.count == 0 {
                        print("No Active Route")
                        //Does not have Active Route
                        hasActiveRoute = false
                        print("5")

                    } else if activeRouteList.count == 1 {
                        print("One Active Route")

                        print("6")

                        //Query Has Active Route
                        hasActiveRoute = true
                        
                        workingActiveRoute = activeRouteList.first!
                        
                        self.activeRoute = workingActiveRoute
                    } else {
                        print("Many Active Routes")

                        //Query has more than one active route, Which is bad. DEVELOPER Maybe create better validation
                        print("7")

                        throw FireBaseRead.unableToRead
                    }
                } else {
                    print("No Active Route")
                    //Does not have Active Route
                    hasActiveRoute = false
                    print("5")

                }

                print("8")

                
                //     Updating Active Route Info
                var serviceStopIdList:[String] = []
                var duration:Int = 0
                var finishedCount:Int = 0 // In Seconds
                
                for stop in serviceStopsList {
                    
                    //Ids
                    serviceStopIdList.append(stop.id)
                    
                    //Estimated Duration
                    duration += stop.duration // In Seconds
                    
                    //Total
                    if stop.operationStatus == .finished {
                        finishedCount = finishedCount + 1
                    }
                    
                }
                
                //Ids
                workingActiveRoute.serviceStopsIds = serviceStopIdList
                print("9")

                //Duration
                
                workingActiveRoute.durationMin = timeBetweenAsSeconds(start: workingActiveRoute.startTime ?? Date(), end: workingActiveRoute.endTime ?? Date())
                print("workingActiveRoute.durationSeconds \(workingActiveRoute.durationMin)")
                //Total
                workingActiveRoute.totalStops = serviceStopsList.count
                workingActiveRoute.finishedStops = finishedCount
                
                //Status
                if workingActiveRoute.totalStops == workingActiveRoute.finishedStops {
                    workingActiveRoute.status = .finished
                } else if workingActiveRoute.finishedStops == 0 {
                    workingActiveRoute.status = .didNotStart
                } else {
                    workingActiveRoute.status = .inProgress
                }
                self.activeRoute = workingActiveRoute
                print("10")

                
                
                if hasActiveRoute {
                    if let activeRoute = listOfActiveRoutes?.first {
                        print("Has Active Route")
                        //Update Active Route
                        
                        //Update Active Route serviceStopsIds
                        
                        //Adds missing service stop to active Route
                        
                        for id in serviceStopIdList {
                            
                            if !activeRoute.serviceStopsIds.contains(id) {
                                
                                do {
                                    try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: workingActiveRoute, serviceStopId: id)
                                } catch {
                                    throw MobileDisplayError.failedToUpload
                                }
                                
                            }
                        }
                        //Removes service stops from active route that are not in service stop Id List
                            for id in activeRoute.serviceStopsIds {
                                //If Id from active Route Service Stop Id list is not in list of service stops from today, Then remove it from active Route
                                if !serviceStopIdList.contains(id){
                                    do {
                                        try await dataService.removeRouteServiceStopId(companyId: companyId, activeRoute: workingActiveRoute, serviceStopId: id)
                                    } catch {
                                        throw MobileDisplayError.failedToUpload
                                    }
                                }
                            }
                        
                        //Updating Active Route Start Time
                        //Updating Active Route End Time
                        
                        if let time = workingActiveRoute.startTime {
                            
                            if let endTime = workingActiveRoute.endTime {
                                
                                if workingActiveRoute.status == .finished {
                                    
                                }
                                
                            } else {
                                
                            }
                            
                        }
                        self.activeRoute = workingActiveRoute
                        
                        //Updating Active Route Duration
                        
                        //Updating Active Route Start Milage
                        //Updating Active Route End Milage
                        //Updating Active Route Distance Miles
                        
                        //Updating Active Route TraineeId and Trainee Name
                        
                        //Updating Active Route Status
                        
                        if workingActiveRoute.totalStops == workingActiveRoute.finishedStops {
                            
                            print("Active Route Finished")
                            
                            print(" - Stops equal total stops")
                            
                            if workingActiveRoute.status != .finished{
                                
                                print("Updating Active Route Status")
                                
                                dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: workingActiveRoute.id, status: .finished)
                                
                            }
                            
                            if workingActiveRoute.endMilage == nil || workingActiveRoute.endTime == nil{
                                
                                print("Either endMilage or end time is optional")
                                
                            } else {
                                
                                print("End Of Route Already Submitted")
                                
                            }
                            
                        } else {
                            
                            dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: workingActiveRoute.id, status: .inProgress)
                            
                            print("Active Route Not Finished")
                            
                        }
                        self.activeRoute = workingActiveRoute
                        
                        //Updating Active Route Total Stops
                        
                        dataService.updateActiveRouteTotalStop(companyId: companyId, activeRouteId: workingActiveRoute.id, totalStops: workingActiveRoute.totalStops)
                        
                        // Updating Active Route Finished Stops
                        
                        dataService.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: workingActiveRoute.id, finishedStops: workingActiveRoute.finishedStops)
                    }
                } else {
                    print("Does Not Have Active Route")

                    //Generate Active Route
                    workingActiveRoute.serviceStopsIds = serviceStopIdList
                    do {
//                        try await RouteManager.shared.uploadRoute(
//                            companyId: companyId,
//                            activeRoute: workingActiveRoute
//                        )
                        print("Should Upload Route")
                    } catch {
                        print("11")

                        throw MobileDisplayError.failedToUpload
                    }
                    print("12")

                }
                finalListOfActiveRoutes.append(workingActiveRoute)
                self.activeRoutes = finalListOfActiveRoutes
                print("13")

            } else {
                print("Service Stop is Empty for \(tech.userName)")
            }
            print("")
        }
        self.activeRoutes = finalListOfActiveRoutes
    }
}
