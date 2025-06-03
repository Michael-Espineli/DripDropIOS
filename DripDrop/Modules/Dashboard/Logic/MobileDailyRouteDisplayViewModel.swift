//
//  MobileDailyRouteDisplayViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/23/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class MobileDailyRouteDisplayViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var recurringRoute: RecurringRoute? = nil
    @Published private(set) var activeRoute: ActiveRoute? = nil
    
    @Published private(set) var routeToday: Bool = false
    @Published private(set) var reload: Bool = false
    
    @Published private(set) var totalStops: Int? = nil
    @Published private(set) var finishedStops: Int? = nil
    @Published private(set) var totalMiles: Double? = nil
    @Published private(set) var totalTime: Double? = nil
    @Published private(set) var serviceStopList:[ServiceStop] = []
    @Published private(set) var serviceStopOrderList:[ServiceStopOrder] = []

    @Published private(set) var serviceStopCompanyList:[ServiceStop:Company] = [:]
    
    @Published private(set) var duration: Int? = nil
    @Published private(set) var estimateDuration: Int? = nil
    
    @Published var startTime: Date = Date()
    @Published var endTime: Date = Date()

    @Published private(set) var startMilage: String? = nil
    @Published var showVehicalPicker: Bool = false
    @Published var selectedVehical: Vehical = Vehical(id: "", nickName: "", vehicalType: .truck, year: "", make: "", model: "", color: "", plate: "", datePurchased: Date(), miles: 1, status: .active)
    
    @Published private(set) var shoppingListCount: Int? = nil

    func initalLoad(companyId:String,user:DBUser,date:Date) async throws {
        // - Check For Recurring Route
        // - Check Active Route
        // - Update a working active Route
        // - At End of Function Update the received active Route
        print("Initial Load For Contractor Daily Dashboard \(date)")
        var serviceStopsList:[ServiceStop] = []
        
        var hasActiveRoute:Bool = false
        self.selectedVehical = Vehical(id: "", nickName: "", vehicalType: .truck, year: "", make: "", model: "", color: "", plate: "", datePurchased: Date(), miles: 1, status: .active)
        var workingActiveRoute:ActiveRoute = ActiveRoute(
            id: UUID().uuidString,
            name: "",
            date: Date(),
            serviceStopsIds: [],
            techId: "",
            techName: "",
            durationMin: 0,
            distanceMiles: 0,
            status: .inProgress,
            totalStops: 0,
            finishedStops: 0,
            vehicalId: ""
        )
        
        
        //     Get All The Necessary Info To Set Up Route Display
        
        let recurringRouteId = weekDay(date: date) + user.id
        
        self.recurringRoute = try await dataService.getSingleRouteFromTechIdAndDay(companyId: companyId, techId: user.id, day: weekDay(date: date))
        
        serviceStopsList = try await dataService.getAllServiceStopsByTechAndDate(companyId: companyId, date: date, tech: user)
        
        if serviceStopsList.count != 0 {
            
            //     Parse Through Data to create what we need
            
            print("Recurring Route Exists")
            
            self.reload = true
            
            // Need to Add Order Here from Recurring Route so that The Recurring route actually means something
            
            // Get All Service Stops For Today
            
            // If service stops exist and no route exists Create an active Route // Checks if one already exists
            
            let listOfActiveRoutes = try await dataService.getAllActiveRoutesBasedOnDate(companyId: companyId, date: date, tech: user)
            
            if listOfActiveRoutes.count == 0 {
                
                //Does not have Active Route
                hasActiveRoute = false
                
            } else if listOfActiveRoutes.count == 1 {
                
                //Query Has Active Route
                hasActiveRoute = true
                
                workingActiveRoute = listOfActiveRoutes.first!
                
                self.activeRoute = workingActiveRoute
            } else {
                //Query has more than one active route, Which is bad. DEVELOPER Maybe create better validation
                throw FireBaseRead.unableToRead
            }
            
            
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
            self.finishedStops = finishedCount
            
            self.totalStops = serviceStopsList.count
            //Order the Active Route and the Reucrring Route?
            
            //First Check if current active Route has an order already created.
            print("")
            print(" - Mobile Daily Route Order Markers -")
            print(" ------------------------------------")
            
            if let workingActiveRouteOrder = workingActiveRoute.order {
                print("Current Active Route Has Order Already Set")
                var workingOrder = workingActiveRouteOrder
                //Check to see if any service stops are not already orderd, if so. Place them at the end of array
                print(" - Order From Active Route - \(workingOrder.count)")
                for order in workingOrder {
                    print("   - \(order.order) \(order.serviceStopId)")
                }
                for id in serviceStopIdList {
                    if !workingActiveRouteOrder.contains(where: {$0.serviceStopId == id }) {
                        let orderCount = workingActiveRouteOrder.count + 1
                        workingOrder.append(ServiceStopOrder(id: UUID().uuidString, order: orderCount, serviceStopId: id))
                    }
                }
                print(" - Order From Active Route After Adding Misc Stops - \(workingOrder.count)")
                for order in workingOrder {
                    print("   - \(order.order) \(order.serviceStopId)")
                }
                let sortedOrderList = workingOrder.sorted(by: {$0.order < $1.order})
                self.serviceStopOrderList = sortedOrderList
                workingActiveRoute.order = sortedOrderList
              
            } else {
                print(" - Current Active Route Does Not Have Order Already Set")
                
                var activeRouteOrder: [ServiceStopOrder] = []
                //Check if recurring route for this day and technician exists, if so set Active Route order based on Recurring route .
                if let recurringRoute {
                    print("Recurring Route Informs Order")
                    let RROrder = recurringRoute.order
                    let sortedOrder = RROrder.sorted(by: {$0.order > $1.order})
                    for order in sortedOrder {
                        if let stop = serviceStopsList.first(where: {$0.recurringServiceStopId == order.recurringServiceStopId}) {
                            let orderCount = activeRouteOrder.count + 1
                            activeRouteOrder.append(ServiceStopOrder(id: UUID().uuidString, order: orderCount, serviceStopId: stop.id))
                        }
                    }
                    print(" - Order From Recurring Route - \(activeRouteOrder.count)")
                    for order in activeRouteOrder {
                        print("   - \(order.order) \(order.serviceStopId)")
                    }
                    for id in serviceStopIdList {
                        if !activeRouteOrder.contains(where: {$0.serviceStopId == id }) {
                            let orderCount = activeRouteOrder.count + 1
                            activeRouteOrder.append(ServiceStopOrder(id: UUID().uuidString, order: orderCount, serviceStopId: id))
                        }
                    }
                    print(" - Order From Misc Service Stops - \(activeRouteOrder.count)")
                    for order in activeRouteOrder {
                        print("   - \(order.order) \(order.serviceStopId)")
                    }
                } else {
                    print(" - Recurring Route Does Not Inform Order")
                    
                    for id in serviceStopIdList {
                        if !activeRouteOrder.contains(where: {$0.serviceStopId == id }) {
                            let orderCount = activeRouteOrder.count + 1
                            activeRouteOrder.append(ServiceStopOrder(id: UUID().uuidString, order: orderCount, serviceStopId: id))
                        }
                    }
                    print(" - Order From Misc Service Stops - \(activeRouteOrder.count)")
                    for order in activeRouteOrder {
                        print("   - \(order.order) \(order.serviceStopId)")
                    }
                }
                //Check to see if any service stops are not already orderd, if so. Place them at the end of array
                let sortedOrderList = activeRouteOrder.sorted(by: {$0.order < $1.order})
                self.serviceStopOrderList = sortedOrderList
                workingActiveRoute.order = sortedOrderList
            }
            //Ids
            workingActiveRoute.serviceStopsIds = serviceStopIdList
            
            //Duration
            
            workingActiveRoute.durationMin = timeBetweenAsSeconds(start: workingActiveRoute.startTime ?? Date(), end: workingActiveRoute.endTime ?? Date())
            print("workingActiveRoute.durationSeconds \(workingActiveRoute.durationMin)")
            //Total
            self.estimateDuration = duration
            workingActiveRoute.totalStops = serviceStopsList.count
            workingActiveRoute.finishedStops = finishedCount
            print("1")
            //Status
            if workingActiveRoute.totalStops == workingActiveRoute.finishedStops {
                workingActiveRoute.status = .finished
            } else if workingActiveRoute.finishedStops == 0 {
                workingActiveRoute.status = .didNotStart
            } else {
                workingActiveRoute.status = .inProgress
            }
            print("2")
            
            self.activeRoute = workingActiveRoute
            
            self.serviceStopList = serviceStopsList
            
            self.routeToday = false
            
            self.reload = false
            
            print("3")
            
            if hasActiveRoute {
                //Update Active Route
                
                //Adds missing service stop to active Route
                
                for id in serviceStopIdList {
                    
                    if !listOfActiveRoutes.first!.serviceStopsIds.contains(id) {
                        print("Before updateRouteServiceStopId")
                        
                        do {
                            try await dataService.updateRouteServiceStopId(companyId: companyId, activeRoute: workingActiveRoute, serviceStopId: id)
                        } catch {
                            throw MobileDisplayError.failedToUpload
                        }
                        
                    }
                }
                
                
                print("")
                print(" Updating The Active Route")
                print(" -------------------------")
                //Updating Active Route Order
                if self.serviceStopOrderList != workingActiveRoute.order {
                    print(" - Updating the active route")
                    try await dataService.updateActiveRouteOrderList(companyId: companyId, activeRouteId: workingActiveRoute.id, serviceStopOrderList: self.serviceStopOrderList)
                } else {
                    print(" - No Update Needed")
                }
                
                //Removes service stops from active route that are not in service stop Id List
                if let activeRoute = listOfActiveRoutes.first {
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
                }
                
                //Updating Active Route Start Time
                //Updating Active Route End Time
                
                if let time = workingActiveRoute.startTime {
                    
                    if let endTime = workingActiveRoute.endTime {
                        
                        if workingActiveRoute.status == .finished {
                            
                            self.duration = timeBetweenAsSeconds(start: time, end: endTime)
                            
                            self.startTime = workingActiveRoute.startTime ?? date
                            
                            self.startMilage = String(workingActiveRoute.startMilage ?? 0)
                            
                        }
                        
                    } else {
                        
                        self.duration = timeBetweenAsSeconds(start: time, end: date)
                        
                        self.startTime = workingActiveRoute.startTime ?? date
                        
                        self.startMilage = String(workingActiveRoute.startMilage ?? 0)
                        
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
            } else {
                //Generate Active Route
                workingActiveRoute.serviceStopsIds = serviceStopIdList
                do {
                    print("Before uploadRoute")
                    print(workingActiveRoute)
                    try await dataService.uploadRoute(
                        companyId: companyId,
                        activeRoute: workingActiveRoute
                    )
                } catch {
                    throw MobileDisplayError.failedToUpload
                }
                self.activeRoute = workingActiveRoute
                
            }
            self.activeRoute = workingActiveRoute
            
            
            //DEVELOPER ADD THIS IN LATER HIgher in function and better
            
            self.serviceStopCompanyList = [:]
            
            var serviceStopCompanyList:[ServiceStop:Company] = [:]
            
            let company = try await dataService.getCompany(companyId: companyId)
            print("Got \(self.serviceStopList.count) Service Stops")
            var SSCount:Int = 0
            let sortedStopList = self.serviceStopList.sorted(by: {$0.id > $1.id})
            print("")
            for stop in sortedStopList {
                serviceStopCompanyList[stop] = company
                SSCount += 1
                
                print(" - \(SSCount) / \(self.serviceStopList.count) \(company.name ?? "Company Name")")
                print(">>")
                print(stop.customerName)
            }
            print("")
            self.serviceStopCompanyList = serviceStopCompanyList
            
            //Get Shopping List
            self.shoppingListCount = try await dataService.getAllShoppingListItemsByUserCount(companyId: companyId, userId: user.id)
        } else {
            print("No Service Stops Found")
            self.serviceStopList = []
            self.serviceStopOrderList = []
            self.activeRoute = nil
        }
        //Get Vehical
        if let activeRoute {
            if activeRoute.vehicalId != "" {
                self.selectedVehical = try await dataService.getVehical(companyId: companyId, vehicalId: activeRoute.vehicalId)
            }
        }
    }
    func updateVehicalMilage(companyId:String,vehicalId:String,miles:Double) async throws {
        try await dataService.updateVehicalMilage(companyId: companyId, vehicalId: vehicalId, miles: miles)
    }
    
    func updateActiveRoute(
        companyId:String,
        activeRoute:ActiveRoute,
        name: String,
        date: Date,
        serviceStopsIds: [String],
        startTime: Date?,
        endTime: Date?,
        startMilage:String?,
        endMilage:String?,
        techId: String,
        techName: String,
        traineeId: String?,
        traineeName: String?,
        durationSeconds: Int,
        distanceMiles: Double,
        status: ActiveRouteStatus,
        vehical: Vehical
    ) {
        print("startTime")
        print(fullDateAndTime(date: startTime))
        print("endTime")
        print(fullDateAndTime(date: endTime))

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
        if startTime != activeRoute.startTime {
            if let startTime {
                print("Updaing Start Time")
                dataService.updateActiveRouteStartTime(companyId: companyId, activeRouteId: activeRoute.id, startTime: startTime)
            }
        } else {
            print("Did not update startTime, it is the same")
        }
        if activeRoute.endTime != endTime {
            if let time = endTime{
                if let endTime {
                    dataService.updateActiveRouteEndTime(companyId: companyId, activeRouteId: activeRoute.id, endTime: endTime)
                }
            } else {
                print("End Time is Nil")
            }
        } else {
            print("Did not update endTime, it is the same")
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
        if let start = Double(startMilage ?? "0"), let end = Double(endMilage ?? "0") {
            let distance = end - start
            if distance != activeRoute.distanceMiles {
                dataService.updateActiveRouteDistnace(companyId: companyId, activeRouteId: activeRoute.id, distance: distance)
            }
        }
        
        if let start = startTime, let end = endTime {
            let duration = minBetween(start: start, end: end)
            
            if duration != activeRoute.durationMin {
                dataService.updateActiveRouteDuration(companyId: companyId, activeRouteId: activeRoute.id, duration: duration)
            }
        }
        if activeRoute.status != status {
            dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: status)
        } else {
            print("Did not update status, it is the same")
        }
        if vehical.id != activeRoute.vehicalId {
            dataService.updateActiveRouteVehicalId(companyId: companyId, activeRouteId: activeRoute.id, vehicalId: vehical.id)
        }else {
            print("Did not update status, it is the same")
        }
        
    }
    func updateOrderList(companyId:String,activeRouteId:String,newOrderList:[ServiceStopOrder]) async throws {
        print("Updating Order List")
        var workingOrderList:[ServiceStopOrder] = []
        for order in newOrderList {
            
            let index:Int = newOrderList.firstIndex(of: order) ?? 0
            
            let newOrder = ServiceStopOrder(id: order.id, order: index + 1, serviceStopId: order.serviceStopId)
            
            workingOrderList.append(newOrder)
        }
        print("Old")
        for order in newOrderList {
            print(" - \(order)")
        }
        print("New")
        for order in workingOrderList {
            print(" - \(order)")
        }
        try await dataService.updateActiveRouteOrderList(
            companyId: companyId,
            activeRouteId: activeRouteId,
            serviceStopOrderList: workingOrderList
        )
    }
}
