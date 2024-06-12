//
//  AllViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/23/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class AllViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //LOADING
    @Published var isLoading:Bool = true
    
    //SINGLES
    @Published private(set) var totalStops: Int? = nil
    @Published private(set) var finishedStops: Int? = nil
    @Published private(set) var toDoListCount:Int? = nil
    @Published private(set) var shoppingListItemCount: Int? = nil
    @Published private(set) var repairRequestCount: Int? = nil
    @Published private(set) var purchaseCount : Int? = nil
    
    @Published private var routeToday:Bool = true
    @Published private(set) var activeRoute: ActiveRoute? = nil
    @Published private(set) var unreadChatCount: Int? = nil

    //ARRAYS
    @Published private(set) var listOfUnreadChats:[Chat] = []

    @Published private(set) var listOfChats:[Chat] = []
    
    @Published private(set) var serviceStopList:[ServiceStop] = []
    @Published private(set) var recentActivityList: [RecentActivityModel] = []

    
    func onLoad(companyId:String,user:DBUser) async throws {
        self.isLoading = true
        
        
        self.recentActivityList = try await dataService.getRecentActivityByUser(userId: user.id)
        //Get alert notifications
        self.toDoListCount = try await dataService.getAllTechnicanToDoItemsCount(companyId: companyId, techId: user.id)
        self.shoppingListItemCount = try await dataService.getAllShoppingListItemsByUserCount(companyId: companyId, userId: user.id)
        self.repairRequestCount = try await dataService.getRepairRequestsByUserCount(companyId: companyId, userId: user.id)
        self.purchaseCount = try await dataService.getPurchasesCountForTechId(companyId: companyId, userId: user.id)
        print("")

        dataService.addListenerForUnreadChats(userId: user.id) { [weak self] chats in
            self?.unreadChatCount = chats.count
            self?.listOfUnreadChats = chats
       }
        print("")
        dataService.addListenerForAllChats(userId: user.id) { [weak self] chats in
           self?.listOfChats = chats
       }
        self.isLoading = false
    }
    func loadCompanyWorkPreview(companyId:String,user:DBUser) async throws {
        //Get RecurringRoute
            //Developer I amay need to change how  I get this ID
        let recurringRouteId = weekDay(date: Date()) + user.id
        let recurringRoute = try? await dataService.getSingleRoute(companyId: companyId, recurringRouteId: recurringRouteId)
        print("    Successfully Got Recurring Route")
        if recurringRoute == nil {
            //checks for one off Service stops not on Route.
            print("Recurring Route is Nil")
            print("Creating New Active Route")

            let serviceStopListFromToday = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: Date(), tech: user)
            if serviceStopListFromToday.isEmpty {
                // no stops on this day for this tech. so returns nothing
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
                self.routeToday = false
            } else {
                //if service stops exist and no route exists Create an active Route // Checks if one already exists
                let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: Date(), tech: user)
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
                            if stop.finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: Date(),
                                                serviceStopsIds: serviceStopIdList,
                                                techId: user.id,
                                                techName: techName,
                                                durationSeconds: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount)
                        do {
                            try await dataService.uploadRoute(companyId: companyId,
                                                                      activeRoute: route)
                        } catch {
                            print("Error 1 All ViewModel")
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
                    let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: Date(), tech: user)
                        var finishedCount:Int = 0
                        for stop in serviceStopListFromToday {
                            if !activeRoute.serviceStopsIds.contains(stop.id) {
                                do {
                                    try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: activeRoute, serviceStopId: stop.id)
                                } catch {
                                    print("Error 2 All ViewModel")

                                    throw MobileDisplayError.failedToUpload
                                }
                            }
                            if stop.finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        self.serviceStopList = serviceStopListFromToday
                        self.totalStops = serviceStopList.count
                        self.finishedStops = finishedCount
                        self.routeToday = true
                        
                    
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
            
            let serviceStopListFromToday = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: Date(), tech: user)
            if serviceStopListFromToday.isEmpty {
                // no stops on this day for this tech. so returns nothing
                print("No Service Stops Today \(fullDateAndDay(date: Date()))")
                self.routeToday = false
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
            } else {
                print("Has \(serviceStopListFromToday.count) stops on  \(fullDateAndDay(date: Date()))")
                
                //if service stops exist and no route exists Create an active Route // Checks if one already exists
                let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: Date(), tech: user)
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
                            if stop.finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: Date(),
                                                serviceStopsIds: serviceStopIdList,
                                                techId: user.id,
                                                techName: techName,
                                                durationSeconds: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount)
                        do {
                            try await dataService.uploadRoute(companyId: companyId,
                                                                      activeRoute: route)
                        } catch {
                            print("Error 3 All ViewModel")

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
                    let actualServiceStopCount = try await dataService.getAllServiceStopsByTechAndDateCount(companyId: companyId, date: Date(), tech: user)
                    
                    //Compares service stops on this day with this tech, by the amount held in the route.
                    /*
                    if actualServiceStopCount == activeRoute.serviceStopsIds.count{
                        self.serviceStopList = try await ServiceStopManager.shared.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: tech)
                        let finishedServiceStopCount = try await ServiceStopManager.shared.getAllServiceStopsByTechAndDateAndFinishedCount(companyId: companyId, date: date, tech: tech)
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
                                    print("Error 4 All ViewModel")

                                    throw MobileDisplayError.failedToUpload
                                }
                            }
                            if stop.finished {
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
    func onLeavePage(){
        dataService.removeListenerForChats()
    }
}
