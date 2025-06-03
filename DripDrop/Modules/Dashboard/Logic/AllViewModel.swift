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
    @Published var isChatLoading:Bool = true
    @Published var isAlertLoading:Bool = true

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
    @Published private(set) var role: Role? = nil
    @Published private(set) var companyUser: CompanyUser? = nil
    
    @Published var currentShift: WorkLog? = nil
    @Published var shiftDuration : Int = 0
    
    @Published private(set) var receivedRecurringLaborContracts:[ReccuringLaborContract] = []
    @Published private(set) var receivedLaborContracts:[LaborContract] = []
    
        //ARRAYS
    @Published private(set) var listOfUnreadChats:[Chat] = []
    
    @Published private(set) var listOfChats:[Chat] = []
    
    @Published private(set) var serviceStopList:[ServiceStop] = []
    @Published private(set) var recentActivityList: [RecentActivityModel] = []
    
    
    func onLoad(companyId:String,user:DBUser) async throws {
        print("")
        print("All View Model - On Load")
        
        //Get Current Shift
        self.isLoading = true
        self.isAlertLoading = true
        self.isChatLoading = true
        
        //Recent Activity
        self.recentActivityList = try await dataService.getRecentActivityByUser(userId: user.id)
        
        //Get Labor Contracts Received Labor Contracts
        
        //Get alert notifications
        
        //To do List Count
        self.toDoListCount = try await dataService.getAllTechnicanToDoItemsCount(companyId: companyId, techId: user.id)
        print("To Do List Count \(String(describing: toDoListCount))")
        
        // Shopping List
        self.shoppingListItemCount = try await dataService.getAllShoppingListItemsByUserCount(companyId: companyId, userId: user.id)
        print("Shopping List Count \(String(describing: shoppingListItemCount))")
        
        //Repair Request Count
        self.repairRequestCount = try await dataService.getRepairRequestsByUserCount(companyId: companyId, userId: user.id)
        print("Repair Requests List Count \(String(describing: repairRequestCount))")
        
        //Purchase Count
        self.purchaseCount = try await dataService.getPurchasesCountForTechId(companyId: companyId, userId: user.id)
        print("Purchase List Count \(String(describing: purchaseCount))")
        
        self.isAlertLoading = false
        dataService.addListenerForUnreadChats(userId: user.id) { [weak self] chats in
            self?.unreadChatCount = chats.count
            self?.listOfUnreadChats = chats
        }
        dataService.addListenerForAllChats(userId: user.id) { [weak self] chats in
            self?.listOfChats = chats
        }
        self.isChatLoading = false
        self.isLoading = false
    }
    func loadCompanyWorkPreview(companyId:String,user:DBUser) async throws {
            //Get RecurringRoute
        print("")
        print("Load Company Work Preview")

        print("Company Id : \(companyId)")
        
        let userAccess = try await dataService.getUserAccessCompanies(userId: user.id, companyId: companyId)
        print("User Access: \(userAccess)")
        
        let companyUsers = try await dataService.getAllCompanyUsers(companyId: companyId)
        print("Company Users: \(companyUsers.count)")
        
        self.companyUser = companyUsers.first(where: {$0.userId == user.id})
        self.role = try await dataService.getSpecificRole(companyId: companyId, roleId: userAccess.roleId)
        
        print("Role: \(String(describing: role))")
        
            //Developer I amay need to change how  I get this ID
        let recurringRoute = try? await dataService.getSingleRouteFromTechIdAndDay(companyId: companyId, techId: user.id, day: weekDay(date: Date()))
        print("Successfully Got Recurring Route from  - \(String(describing: recurringRoute))")
        
        if recurringRoute == nil {
                //checks for one off Service stops not on Route.
            print("Recurring Route is Nil")
            print("Creating New Active Route")
            
            let serviceStopListFromToday = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: Date(), tech: user)
            if serviceStopListFromToday.isEmpty {
                    // no stops on this day for this tech. so returns nothing
                print("No Service stops Received")
                self.serviceStopList = []
                self.totalStops = 0
                self.finishedStops = 0
                self.routeToday = false
            } else {
                print("Received at Least 1 Service stop for \(user.firstName) \(user.lastName) on \(weekDay(date: Date())) ")
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
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (user.firstName) + " " + (user.lastName)
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: Date(),
                                                serviceStopsIds: serviceStopIdList,
                                                techId: user.id,
                                                techName: techName,
                                                durationMin: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount,
                                                vehicalId: "")
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
                        if stop.operationStatus == .finished {
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
                            if stop.operationStatus == .finished {
                                finishedCount = finishedCount + 1
                            }
                        }
                        let techName = (user.firstName) + " " + (user.lastName)
                        
                        let route = ActiveRoute(id: UUID().uuidString,
                                                name: "Name",
                                                date: Date(),
                                                serviceStopsIds: serviceStopIdList,
                                                techId: user.id,
                                                techName: techName,
                                                durationMin: duration,
                                                distanceMiles: 69,
                                                status: .didNotStart,
                                                totalStops: serviceStopList.count,
                                                finishedStops:finishedCount,
                                                vehicalId: "")
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
                        if stop.operationStatus == .finished {
                            finishedCount = finishedCount + 1
                        }
                    }
                    self.serviceStopList = serviceStopListFromToday
                    self.totalStops = serviceStopList.count
                    self.finishedStops = finishedCount
                    self.routeToday = true
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
    func startShift(company:Company,user:DBUser) {
        Task{
            do {
                
                var list:[WorkLog] = []
                
                let name = user.firstName + " " + user.lastName

                self.currentShift = WorkLog(
                    id: UUID().uuidString,
                    shiftId: "",
                    startTime: Date(),
                    startLatitude: 0,
                    startLongitude: 0,
                    type: .working,
                    companyId: company.id,
                    companyName: company.name,
                    userId: user.id,
                    userName: name,
                    current: true
                )
                
                //Upload Shift
                
                self.shiftDuration = 0
              
            } catch {
                print(error)
            }
        }
    }
    func updateCurrentShift(company:Company,user:DBUser,newType:WorkLogType?) {
        Task{
            do {
                
                var list:[WorkLog] = []
                
                
                self.currentShift?.endTime = Date()
                self.currentShift?.endLatitude = 0
                self.currentShift?.endLongitude = 0
                self.currentShift?.current = false
                
                if let log = self.currentShift {
                    list.append(log)
                }
                    //Update workLog
                
                
                if let newType {
                        //Create New work log
                    
                    let name = user.firstName + " " + user.lastName
                    self.shiftDuration = 0
                    self.currentShift = WorkLog(
                        id: UUID().uuidString,
                        shiftId: "",
                        startTime: Date(),
                        startLatitude: 0,
                        startLongitude: 0,
                        type: newType,
                        companyId: company.id,
                        companyName: company.name,
                        userId: user.id,
                        userName: name,
                        current: true
                    )
                } else {
                    print("Just Log Out")
                    self.currentShift = nil
                }
            } catch {
                print(error)
            }
        }
    }
    func onLeavePage(){
        dataService.removeListenerForChats()
    }
}
