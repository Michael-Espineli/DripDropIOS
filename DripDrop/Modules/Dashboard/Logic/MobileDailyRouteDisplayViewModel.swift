//
//  MobileDailyRouteDisplayViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/23/24.
//
//  Functions In Page
//  -------------------
//  ---MobileDailyRouteDisplayViewModel---
//  updateVehicalMilage
//  updateActiveRoute
//  start
//  stop
//  recompute [private]
//  updateServiceStopStatus
//  startActiveRoute
//  stopActiveRoute
//  pauseActiveRoute
//  resumeActiveRoute
//  requestWhenInUseLocation
//  requestAlwaysLocation
//  updateRouteStartMilage
//  updateRouteEndtMilage
//  moveServiceStops
//  moveServiceStopsPermanently
//  updateOrderList  Delete?
//  reorderServiceStops
//  generateNewOrder [private]
//  reorderServiceStopsPermanently
//  applyOrder [private]
//  resetOrderToMatchRecurringRoute
//  reorderActiveToMatchRecurring [private]
//
//  ---Location Function---
//  startRouteLogTimer [private]
//  stopRouteLogTimer [private]
//  maybeUploadLog [private]
//  maybeUploadLocationBreadcrumb [private]
//  maybeUploadLocationBreadcrumb [private]
//  openSummaryLog [private]
//  closeCurrentSummaryLog [private]
//  publishRouteLog [private]
//  publishRouteLocationTick [private]
//  initalLoad
//
//  ---RouteBuilder---
//  build
//
//  ---RouteOrderBuilder---
//  build
//
//  ---ActiveRouteDiffer---
//  diff


import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
import CoreLocation

@MainActor
final class MobileDailyRouteDisplayViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    // Location Tracking
    private let routeLocationManager: RouteLocationManager

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var previousRoutesNeedingReview: [ActiveRoute] = []
    @Published private(set) var recentActiveRoutes: [ActiveRoute] = []
    init(dataService:any ProductionDataServiceProtocol, routeLocationManager: RouteLocationManager = RouteLocationManager()){
        self.dataService = dataService
        self.routeLocationManager = routeLocationManager

        // Wire callbacks
        self.routeLocationManager.onAuthorizationChanged = { [weak self] status in
            Task { @MainActor in
                self?.locationAuthorizationStatus = status
            }
        }
        self.routeLocationManager.onLocationUpdate = { [weak self] location in
            Task { @MainActor in
                self?.currentLocation = location
                // Optional: Persist breadcrumb to Firestore here (throttle as needed)
                if let self = self,
                   let active = self.activeRoute,
                   active.status == .inProgress,
                   let companyId = self.cachedCompanyId,
                   let companyName = self.cachedCompanyName,
                   let user = self.cachedUser {
                    self.maybeUploadLocationBreadcrumb(companyId: companyId, activeRouteId: active.id, user: user, companyName: companyName)
                }
            }
        }
        self.routeLocationManager.onError = { error in
            print("[RouteLocationManager] error: \(error)")
        }
    }
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    //Move Stops Variables
    @Published var selectedServiceStops:[ServiceStop] = []
    @Published var moveDate: Date = Date()
    @Published var selectedTech: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )
    @Published var selectedDate: Date = Date()
    @Published var enableMove: Bool = false
    @Published var moveType: String = "One Time"
    @Published var newDay: DaysOfWeek = .sunday
    var currentDay: DaysOfWeek{
        DaysOfWeek(rawValue: weekDay(date: Date()))!
        
    }
    //Reorder Variables
    @Published var draggedStop: ServiceStop? = nil
    
    //Old Variables
    @Published private(set) var recurringRoute: RecurringRoute? = nil
    @Published private(set) var activeRoute: ActiveRoute? = nil
    @Published private(set) var ArOrderIsDifferentThanRrORder: Bool = false

    @Published private(set) var routeToday: Bool = false
    @Published private(set) var reload: Bool = false
    
    @Published private(set) var totalStops: Int? = nil
    @Published private(set) var finishedStops: Int? = nil
    @Published var serviceStopList:[ServiceStop] = []
    @Published private(set) var serviceStopOrderList:[ServiceStopOrder] = []

    @Published private(set) var serviceStopCompanyList:[ServiceStop:Company] = [:]
    @Published private(set) var companyUsers:[CompanyUser] = []

    @Published private(set) var duration: Int? = nil
    @Published private(set) var estimateDuration: Int? = nil
    
    @Published var startTime: Date = Date()
    @Published var endTime: Date = Date()

    @Published var showVehicalPicker: Bool = false
    @Published var selectedVehical: Vehical = Vehical(id: "", nickName: "", vehicalType: .truck, year: "", make: "", model: "", color: "", plate: "", datePurchased: Date(), miles: 1, status: .active)
    
    @Published private(set) var shoppingListCount: Int? = nil

    
    @Published var showMilage: Bool = false
    @Published var showEndMilage: Bool = false
    
    @Published private(set) var startMilage: Double = 0
    @Published private(set) var endMilage: Double = 0
    @Published var inputStartMilage: String = ""
    @Published var inputEndMilage: String = ""
    
    // Cached context for background uploads
    private var cachedCompanyId: String?
    private var cachedCompanyName: String?
    private var cachedUser: DBUser?

    // Summary log tracking
    @Published private(set) var currentSummaryLogId: String? = nil
    @Published private(set) var currentSummaryType: WorkLogType? = nil
    func loadPreviousRouteReview(
        companyId: String,
        technicianId: String
    ) async {
        do {
            let startOfToday = Calendar.current.startOfDay(for: Date())

            async let needsReview = dataService.getActiveRoutesNeedingReview(
                companyId: companyId,
                technicianId: technicianId,
                beforeDate: startOfToday
            )

            async let recentRoutes = dataService.getRecentActiveRoutes(
                companyId: companyId,
                technicianId: technicianId,
                limit: 10
            )

            self.previousRoutesNeedingReview = try await needsReview
            self.recentActiveRoutes = try await recentRoutes
        } catch {
            print("[MobileDailyRouteDisplayViewModel][loadPreviousRouteReview] Error")
            print(error)

            self.previousRoutesNeedingReview = []
            self.recentActiveRoutes = []
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
        if let milage = Double(startMilage ?? "0") {
            
            if activeRoute.startMilage != milage {
                print("Updaing Start Milage")
                
                dataService.updateActiveRouteStartMilage(companyId: companyId, activeRouteId: activeRoute.id, startMilage: milage)
            } else {
                print("Start Milage is Nil")
            }
        } else {
            print("Did not update startMilage, it is the same")
        }
        
        if let milage = Double(endMilage ?? "0") {
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
    

    
//    Works well on start but not on day change
    func start(
        companyId: String,
        user: DBUser,
        date: Date
    ) {
        print("  [MobileDailyRouteDisplayViewModel][start][companyId]")
        print("  [MobileDailyRouteDisplayViewModel][start] techId: \(user.id) Date: \(date) Day Of Week: \(weekDay(date: date))")
        dataService.addCompanyUserListener(companyId: companyId, status: "Active",
        ) { [weak self] route in
            self?.companyUsers = route
        }
        //For date change reset Variables so that No other variables carry over
        self.activeRoute = nil
        self.recurringRoute = nil
        self.serviceStopList.removeAll()
        
        // The issue occures because active Route comes back nil when it should not
        dataService.listenActiveRoute(
            companyId: companyId,
            date: date,
            techId: user.id
        ) { [weak self] route in
            self?.activeRoute = route
            print("")
            print("[MobileDailyRouteDisplayViewModel][start] Active Route Listener:", route?.id ?? "nil")
//            self?.recompute(companyId: companyId,whoCalled: "AR", user: user, date: date)
        }
        dataService.listenRecurringRoute(
            companyId: companyId,
            techId: user.id,
            day: weekDay(date: date)
        ) { [weak self] route in
            self?.recurringRoute = route
            print("")
            print("[MobileDailyRouteDisplayViewModel][start] Recurring Route Listener: ", route?.id ?? "nil")
//            self?.recompute(companyId: companyId, whoCalled: "RR", user: user, date: date)
        }
        dataService.listenServiceStops(
            companyId: companyId,
            date: date,
            techId: user.id
        ) { [weak self] stops in
            self?.serviceStopList = stops
            print("")
            print("[MobileDailyRouteDisplayViewModel][start] Service Stop Listener: ", stops.count)
            self?.recompute(companyId: companyId, whoCalled: "SS", user: user, date: date)
        }
    }

    func stop() {
        dataService.stopServiceStopActiveRouteRecurringRouteListenrs()
    }
    
    private func recompute(companyId:String,whoCalled:String,user:DBUser,date:Date) {
        print("  [MobileDailyRouteDisplayViewModel][Recompute] → Called by: ",whoCalled," stops:", serviceStopList.count,
              "Active:", activeRoute?.id ?? "nil",
              "Recurring:", recurringRoute?.id ?? "nil")
        
        // Builds the New Active Route
        // Coomputed Route is Active Route

        let computedRoute = RouteBuilder.build(
            date: date,
            techId: user.id,
            techName: (user.firstName + " " + user.lastName),
            serviceStops: serviceStopList,
            recurringRoute: recurringRoute,
            existingActiveRoute: activeRoute
        )
        if let computedRoute {
            
           //Update Service Stop List order based on order before checking differences
           self.serviceStopList = applyOrder(serviceStops: serviceStopList, serviceStopOrders: computedRoute.order)

            //Sees what the difference are between old and new Route
            let diff = ActiveRouteDiffer.diff(
                old: activeRoute,
                new: computedRoute
            )
            
            self.activeRoute = computedRoute
            
            // 5️⃣ Makes update to Active Route if needed
            dataService.applyRouteChanges(companyId:companyId,diff:diff,calledFrom: whoCalled) // Why does this get called 3 times on a new day
            
            let orderDiff = ArRrOrderDiffer.diff(
                active: computedRoute,
                recurring: recurringRoute
            )
            self.ArOrderIsDifferentThanRrORder = orderDiff.isDifferent
        } else {
            if let activeRoute {
                if whoCalled == "SS" {
                        //This should trigger if there is an active route and there are no service stops and should delete the active route
#warning("Should delete the active route")
                    print("  [MobileDailyRouteDisplayViewModel][recompute] Should Delete the active Route")
                }
            }
        }
    }
    
    func updateServiceStopStatus(companyId:String, stopId: String, status: ServiceStopOperationStatus) {
        Task{
            do {
                try await dataService.updateServicestopOperationStatus(
                    companyId: companyId,
                    serviceStopId: stopId,
                    operationStatus: status
                )
                print("  [MobileDailyRouteDisplayViewModel][updateServiceStopStatus] Success ")

            } catch {
                print("  [MobileDailyRouteDisplayViewModel][updateServiceStopStatus] Error \(error)")
            }
        }
    }
    func startServiceStop(companyId: String?,serviceStopId:String){
        guard let companyId else {return}

        Task{
            do {
                try await dataService.updateServiceStopStartTime(companyId: companyId, serviceStopId: serviceStopId, startTime: Date())
                var list = serviceStopList
                var first = list.first(where: {$0.id == serviceStopId})
                first?.startTime = Date()
                list.removeAll(where: {$0.id == serviceStopId})
                list.append(first!)
            } catch {
                print("[MobileDailyRouteDisplayViewModel][startServiceStop] Error \(error)")
            }
        }
    }
    func startActiveRoute(companyId: String?,companyName:String? , user:DBUser?){
        Task{
            do {
                guard let companyId else {return}
                guard let companyName else {return}
                guard let user else {return}
                guard let activeRoute else {return}
                if activeRoute.id == "" {return}
                
                // Cache context for background uploads
                self.cachedCompanyId = companyId
                self.cachedCompanyName = companyName
                self.cachedUser = user
                
                //Change Status
                self.showMilage = true
                
                
                dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .inProgress)
                
                //Update Milage
                
                dataService.updateActiveRouteStartTime(companyId: companyId, activeRouteId: activeRoute.id, startTime: Date())
                
                //Upload Location
                let startLat = self.currentLocation?.coordinate.latitude ?? 0
                let startLon = self.currentLocation?.coordinate.longitude ?? 0
                let log = ActiveRouteLog(
                    id: "com_ar_log_" + UUID().uuidString,
                    activeRouteId: activeRoute.id,
                    startTime: Date(),
                    startLatitude: startLat,
                    startLongitude: startLon,
                    type: .working,
                    companyId: companyId,
                    companyName: companyName,
                    userId: user.id,
                    userName: (user.firstName + " " + user.lastName),
                    current: true
                )
                try await dataService.upLoadActiveRouteLog(companyId: companyId, activeRouteId: activeRoute.id, log: log)
                
                // Set current summary log state
                self.currentSummaryLogId = log.id
                self.currentSummaryType = .working
                
                // Begin location tracking for active route

                //Turn on location
                routeLocationManager.startTracking()
                startRouteLogTimer(companyId: companyId, activeRouteId: activeRoute.id, user: user, companyName: companyName)
            } catch {
                print("[MobileDailyRouteDisplayViewModel][startActiveRoute] Error \(error)")
            }
        }
    }
    

    func stopActiveRoute(companyId: String?,companyName:String? , user:DBUser?){
        guard let companyId else {return}
        guard let companyName else {return}
        guard let user else {return}
        guard let activeRoute else {return}
            //Change Status
        dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .finished)
        
        Task { @MainActor in
            if let companyId = self.cachedCompanyId, let activeId = self.activeRoute?.id {
                await closeCurrentSummaryLog(companyId: companyId, activeRouteId: activeId)
            }
        }

        dataService.updateActiveRouteEndTime(companyId: companyId, activeRouteId: activeRoute.id, endTime: Date())
        // Stop location tracking at end of route
        routeLocationManager.stopTracking()
        stopRouteLogTimer(companyId: companyId, activeRouteId: activeRoute.id, user: user, companyName: companyName)

    }
    func pauseActiveRoute(companyId: String?,companyName:String? , user:DBUser?){
        guard let companyId else {return}
        guard let companyName else {return}
        guard let user else {return}
        guard let activeRoute else {return}
            //Change Status
        dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .onBreak)
        // Pause location tracking while on break
        
        Task { @MainActor in
            if let companyId = self.cachedCompanyId, let companyName = self.cachedCompanyName, let user = self.cachedUser, let activeId = self.activeRoute?.id {
                await closeCurrentSummaryLog(companyId: companyId, activeRouteId: activeId)
                await openSummaryLog(type: .onBreak, companyId: companyId, companyName: companyName, activeRouteId: activeId, user: user)
            }
        }

        routeLocationManager.stopTracking()
        stopRouteLogTimer(companyId: companyId, activeRouteId: activeRoute.id, user: user, companyName: companyName)

    }
    func resumeActiveRoute(companyId: String?){
        guard let companyId else {return}
        guard let activeRoute else {return}
            //Change Status
        dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .inProgress)
        // Resume location tracking when route resumes
        routeLocationManager.startTracking()
        
        Task { @MainActor in
            if let companyId = self.cachedCompanyId, let companyName = self.cachedCompanyName, let user = self.cachedUser, let activeId = self.activeRoute?.id {
                await closeCurrentSummaryLog(companyId: companyId, activeRouteId: activeId)
                await openSummaryLog(type: .working, companyId: companyId, companyName: companyName, activeRouteId: activeId, user: user)
                startRouteLogTimer(companyId: companyId, activeRouteId: activeId, user: user, companyName: companyName)
            }
        }
    }
    
    // Ask for permissions from your UI or when starting a route
    func requestWhenInUseLocation() {
        routeLocationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysLocation() {
        routeLocationManager.requestAlwaysAuthorization()
    }
    func updateRouteStartMilage(companyId: String?){
        print("  [MobileDailyRouteDisplayViewModel][updateRouteStartMilage]")
        guard let companyId else {return}
        guard let activeRoute else {return}
        guard let milage = Double(inputStartMilage) else {return}
        if selectedVehical.id == "" {return}
        //Update Route
        dataService.updateActiveRouteStartMilage(companyId: companyId, activeRouteId: activeRoute.id, startMilage: milage)
        
        // Update Vehicle
        Task{
            do {
                try await dataService.updateVehicalMilage(companyId: companyId, vehicalId: selectedVehical.id, miles: milage)
            } catch {
                print(error)
            }
        }
    }
    
    func updateRouteEndtMilage(companyId: String?) {
        print("  [MobileDailyRouteDisplayViewModel][updateRouteEndtMilage]")

        guard let companyId else { return }
        guard let activeRoute else { return }
        guard let milage = Double(inputEndMilage) else { return }

        dataService.updateActiveRouteEndMilage(
            companyId: companyId,
            activeRouteId: activeRoute.id,
            endMilage: milage
        )

        if let startMilage = activeRoute.startMilage {
            dataService.updateActiveRouteDistnace(
                companyId: companyId,
                activeRouteId: activeRoute.id,
                distance: milage - startMilage
            )
        }
    }
    
    func cancelMove(){
        self.selectedServiceStops = []
        self.moveDate = Date()
        self.selectedTech = CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .notAssigned)
        self.newDay = .monday
    }
    func moveServiceStops(companyId: String?){
        guard let companyId else {return}
        guard let activeRoute else {return}
        if moveDate == selectedDate {return}
        
        if selectedTech.id == "" {return}
        var triedToMoveFinished:Bool = false
        Task{
            do {
                var order:[ServiceStopOrder] = activeRoute.order ?? []
                for stop in selectedServiceStops {
                    if stop.operationStatus == .notFinished {
                        order.removeAll(where: {$0.serviceStopId == stop.id})
                        try await dataService.updateServiceStopServiceDate(companyId: companyId, serviceStop: stop, serviceDate: moveDate, companyUser: selectedTech)
                    } else {
                        triedToMoveFinished = true
                    }
                }
                //Remove Selected Stops from Order
                
                try await dataService.updateActiveRouteOrderList(
                    companyId: companyId,
                    activeRouteId: activeRoute.id,
                    serviceStopOrderList: order
                )
                //Finishing Function Actions
                self.selectedServiceStops = []
                self.moveDate = Date()
                self.selectedTech = CompanyUser(
                    id: "",
                    userId: "",
                    userName: "",
                    roleId: "",
                    roleName: "",
                    dateCreated: Date(),
                    status: .active,
                    workerType: .notAssigned
                )
                self.enableMove = false
                if triedToMoveFinished {
                    self.alertMessage = "Some service stops were not moved because they are already finished."
                } else {
                    self.alertMessage = "Successfully moved all stops"
                }
                self.showAlert = true
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][moveServiceStops] Error: \(error)")
            }
        }
    }
    
    func moveServiceStopsPermanently(companyId: String?){
        guard let companyId else {return}
        FunctionsManager.shared.updateServiceStopPermanently(
            companyId: companyId,
            serviceStopList: serviceStopList,
            newTech: selectedTech,
            newDay: newDay
        )
        self.selectedServiceStops = []
        self.moveDate = Date()
        self.selectedTech = CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .notAssigned)
        self.newDay = .monday
    }
    func updateOrderList(companyId:String,activeRouteId:String,newOrderList:[ServiceStopOrder]) async throws {
        print("**  [MobileDailyRouteDisplayViewModel][Updating Order List]")
        var workingOrderList:[ServiceStopOrder] = []
        for order in newOrderList {
            
            let index:Int = newOrderList.firstIndex(of: order) ?? 0
            
            let newOrder = ServiceStopOrder(
                id: order.id,
                order: index + 1,
                serviceStopId: order.serviceStopId,
                recurringServiceStopId: order.recurringServiceStopId
            )
            
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
    func reorderServiceStops(companyId: String?){
        guard let companyId else {return}
        guard let activeRoute else {return}
        print("**  [MobileDailyRouteDisplayViewModel][reorderServiceStops]")
 
        let newOrder = generateNewOrder(serviceStops: serviceStopList)
        
        #warning("[Developer ToDoList] Build a way to check to see if the order has changed before calling the API")
        Task{
            do {
                try await dataService.updateActiveRouteOrderList(
                    companyId: companyId,
                    activeRouteId: activeRoute.id,
                    serviceStopOrderList: newOrder
                )
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][reorderServiceStops] Error \(error)")
            }
        }
    }
    private func generateNewOrder(serviceStops:[ServiceStop])->[ServiceStopOrder]{
        var workingOrderList:[ServiceStopOrder] = []
        print("**  [MobileDailyRouteDisplayViewModel][generateNewOrder]")

        for stop in serviceStops {
            
            let index:Int = serviceStops.firstIndex(of: stop) ?? 0
            
            let newOrder = ServiceStopOrder(
                id: "com_ar_ss_ord_" + UUID().uuidString,
                order: index + 1,
                serviceStopId: stop.id,
                recurringServiceStopId: stop.recurringServiceStopId
            )
            workingOrderList.append(newOrder)
        }
        return workingOrderList
    }
    func reorderServiceStopsPermanently(companyId: String?){
        guard let companyId else {return}
        guard let recurringRoute else {return}
        guard let activeRoute else {return}
        guard let activeRouteOrder = activeRoute.order else {return}
        //Needs to be called by button and simply updates the Recurring Route order to reflect the new Active Route order.
        //** Need to figure out how to ignore service stops that are not recurring. Most likely by checking to see if the RSS ID is empty
        FunctionsManager.shared.updateRecurringRouteOrderPermanently(
            companyId: companyId,
            routeId: recurringRoute.id,
            recurringRouteOrder: recurringRoute.order,
            serviceStopOrders: activeRouteOrder
        )
    }
    
    private func applyOrder(
        serviceStops: [ServiceStop],
        serviceStopOrders: [ServiceStopOrder]?
    ) -> [ServiceStop] {
        print("    [MobileDailyRouteDisplayViewModel][applyOrder] Start")

        if let serviceStopOrders {
            //Fix Later Developer
//            return serviceStops
            print("    [MobileDailyRouteDisplayViewModel][applyOrder] 1")
            for order in serviceStopOrders {
                print(order)
            }
            
            let orderLookup: [String: Int] = Dictionary(
                uniqueKeysWithValues: serviceStopOrders.map {
                    ($0.serviceStopId, $0.order)
                }
            )

            print("    [MobileDailyRouteDisplayViewModel][applyOrder] 2")
            return serviceStops.sorted { lhs, rhs in
                let lhsOrder = orderLookup[lhs.id]
                let rhsOrder = orderLookup[rhs.id]
                
                switch (lhsOrder, rhsOrder) {
                case let (l?, r?):
                    return l < r
                case (_?, nil):
                    return true      // ordered items come first
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.serviceDate < rhs.serviceDate // fallback rule
                }
            }
        } else {
            print("    [MobileDailyRouteDisplayViewModel][applyOrder] 3")
            return serviceStops
        }
    }
    
    func resetOrderToMatchRecurringRoute(companyId: String?) {
        print("    [MobileDailyRouteDisplayViewModel][resetOrderToMatchRecurringRoute]")
        guard let companyId else {return}
        guard let recurringRoute else {return}
        guard let activeRoute else {return}
        guard let activeRouteOrder = activeRoute.order else {return}
        let defaultOrder: [ServiceStopOrder] = reorderActiveToMatchRecurring(recurring: recurringRoute.order, active: activeRouteOrder)
        Task{
            do {
                try await dataService.updateActiveRouteOrderList(
                    companyId: companyId,
                    activeRouteId: activeRoute.id,
                    serviceStopOrderList: defaultOrder
                )
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][resetOrderToMatchRecurringRoute] Error \(error)")
            }
        }
    }
    private func reorderActiveToMatchRecurring(
        recurring: [recurringRouteOrder],
        active: [ServiceStopOrder]
    ) -> [ServiceStopOrder] {

        // 1. Sorted recurring order
        let recurringSorted = recurring.sorted { $0.order < $1.order }

        // 2. Dictionary of active stops by recurringServiceStopId
        let activeDict = Dictionary(
            uniqueKeysWithValues: active.map { ($0.recurringServiceStopId, $0) }
        )

        // 3. Build reordered recurring portion
        var reorderedRecurringStops: [ServiceStopOrder] = []

        for r in recurringSorted {
            if let match = activeDict[r.recurringServiceStopId] {
                reorderedRecurringStops.append(match)
            }
        }

        // 4. Non-recurring stops (keep their relative order)
        let recurringIdSet = Set(recurring.map { $0.recurringServiceStopId })

        let nonRecurringStops = active.filter {
            !recurringIdSet.contains($0.recurringServiceStopId)
        }

        // 5. Merge back together
        return reorderedRecurringStops + nonRecurringStops
    }
    // MARK: Location Functions

    // MARK: - Periodic Route Log Publishing
    private var routeLogTimer: Timer?

    private func startRouteLogTimer(companyId: String, activeRouteId: String, user: DBUser, companyName: String) {
        // Avoid multiple timers
        routeLogTimer?.invalidate()
        routeLogTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
#if DEBUG

                await self?.publishRandomRouteLocationTick(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)

#else
                await self?.publishRouteLocationTick(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
#endif
            }
        }
        // Fire an immediate tick if desired
        Task { @MainActor in
            await publishRouteLog(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
        }
    }

    private func stopRouteLogTimer(companyId: String, activeRouteId: String, user: DBUser, companyName: String) {
        // Fire an immediate tick if desired
        Task { @MainActor in
            await publishRouteLog(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
        }
        
        routeLogTimer?.invalidate()
        routeLogTimer = nil
    }

    private var lastRouteLogUpload: Date?
    
    private var lastRouteLocationUpload: Date?

    private func maybeUploadLog(companyId: String, activeRouteId: String, user: DBUser, companyName: String) {
        let now = Date()
        if let last = lastRouteLogUpload, now.timeIntervalSince(last) < 600 { return }
        lastRouteLogUpload = now
        Task { @MainActor in
            await self.publishRouteLocationTick(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
        }
    }
    
    private func maybeUploadLocationBreadcrumb(companyId: String, activeRouteId: String, user: DBUser, companyName: String) {
        guard currentSummaryType == .working else { return }
        guard let loc = currentLocation else { return }
        let now = Date()
        if let last = lastRouteLocationUpload, now.timeIntervalSince(last) < 600 { return }
        lastRouteLocationUpload = now
        Task { @MainActor in
            await self.publishRouteLocationTick(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
        }
    }

    // MARK: - Summary Log Helpers
    @MainActor
    private func openSummaryLog(type: WorkLogType, companyId: String, companyName: String, activeRouteId: String, user: DBUser) async {
        let coord = currentLocation?.coordinate
        let log = ActiveRouteLog(
            id: "com_ar_log_" + UUID().uuidString,
            activeRouteId: activeRouteId,
            startTime: Date(),
            startLatitude: coord?.latitude ?? 0,
            startLongitude: coord?.longitude ?? 0,
            type: type,
            companyId: companyId,
            companyName: companyName,
            userId: user.id,
            userName: user.firstName + " " + user.lastName,
            current: true
        )
        do {
            try await dataService.upLoadActiveRouteLog(companyId: companyId, activeRouteId: activeRouteId, log: log)
            self.currentSummaryLogId = log.id
            self.currentSummaryType = type
        } catch {
            print("    [SummaryLog] open error: \(error)")
        }
    }

    @MainActor
    private func closeCurrentSummaryLog(companyId: String, activeRouteId: String) async {
        guard let id = currentSummaryLogId else { return }
        let coord = currentLocation?.coordinate
        // TODO: Replace with your real dataService method to close a log
        // e.g., dataService.closeActiveRouteLog(...)
        do {
            
//            try await dataService.closeActiveRouteLog(companyId: companyId, activeRouteId: activeRouteId, logId: id, endTime: Date(), endLatitude: coord?.latitude, endLongitude: coord?.longitude)
            self.currentSummaryLogId = nil
            self.currentSummaryType = nil
        } catch {
            print("    [SummaryLog] close error: \(error)")
        }
    }
    
    // Writes an ActiveRouteLocation breadcrumb (every ~10 minutes)
    @MainActor
    private func publishRouteLog(companyId: String, activeRouteId: String, user: DBUser, companyName: String) async {
        guard let loc = currentLocation else {
            print("    [RouteLog] No current location yet; skipping tick")
            return
        }

        // Build the log (standalone breadcrumb style)
        let log = ActiveRouteLog(
            id: "com_ar_log_" + UUID().uuidString,
            activeRouteId: activeRouteId,
            startTime: Date(),
            startLatitude: loc.coordinate.latitude,
            startLongitude: loc.coordinate.longitude,
            // Leave end fields nil for breadcrumb-style logs
            type: .working, // confirm your desired WorkLogType
            companyId: companyId,
            companyName: companyName,
            userId: user.id,
            userName: (user.firstName + " " + user.lastName),
            current: true
        )

        do {
            try await dataService.upLoadActiveRouteLog(companyId: companyId, activeRouteId: activeRouteId, log: log)
        } catch {
            print("    [RouteLog] upload error: \(error)")
        }
    }
    // Writes an ActiveRouteLocation breadcrumb (every ~10 minutes)
    @MainActor
    private func publishRouteLocationTick(companyId: String, activeRouteId: String, user: DBUser, companyName: String) async {
        guard let loc = currentLocation else {
            print("    [RouteLog] No current location yet; skipping tick")
            return
        }

        // Build the log (standalone breadcrumb style)
        let location = ActiveRouteLocation(
            id: "com_ar_loc_" + UUID().uuidString,
            activeRouteId: activeRouteId,
            time: Date(),
            latitude: loc.coordinate.latitude,
            longitude:loc.coordinate.longitude,
            userId: user.id,
            userName: (user.firstName + " " + user.lastName)
        )

        do {
            try await dataService.upLoadActiveRouteLocation(companyId: companyId, activeRouteId: activeRouteId, location: location)
        } catch {
            print("  [RouteLog] upload error: \(error)")
        }
    }
    @MainActor
    private func publishRandomRouteLocationTick(companyId: String, activeRouteId: String, user: DBUser, companyName: String) async {
        guard let loc = currentLocation else {
            print("    [RouteLog] No current location yet; skipping tick")
            return
        }
//        32.943777
//        
//        32.546122
//        
        let minLat = 32.546122
        let maxLat = 32.943777
        
        let minLon = -117.842707
        let maxLon = -117.251974
        
        let randomLat:Double = Double.random(in: minLat...maxLat)
        let randomLong:Double = Double.random(in: minLon...maxLon)
        // Build the log (standalone breadcrumb style)
        let location = ActiveRouteLocation(
            id: "com_ar_loc_" + UUID().uuidString,
            activeRouteId: activeRouteId,
            time: Date(),
            latitude: randomLat,
            longitude: randomLong,
            userId: user.id,
            userName: (user.firstName + " " + user.lastName)
        )
        do {
            try await dataService.upLoadActiveRouteLocation(companyId: companyId, activeRouteId: activeRouteId, location: location)
        } catch {
            print("  [RouteLog] upload error: \(error)")
        }
    }
    

}

//Step B: Domain Logic (Pure Code)

struct RouteBuilder {
    private static func activeRouteId(date: Date, techId: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"

        let safeTechId = techId.replacingOccurrences(of: "/", with: "_")
        return "com_ar_\(formatter.string(from: date.startOfDay()))_\(safeTechId)"
    }

    static func build(
        date: Date,
        techId:String,
        techName:String,
        serviceStops: [ServiceStop],
        recurringRoute: RecurringRoute?,
        existingActiveRoute: ActiveRoute?
    ) -> ActiveRoute? {
        //Here Either Create Route Or init a new Route
        var route = existingActiveRoute ?? ActiveRoute(
            id: activeRouteId(date: date, techId: techId),
            name: "",
            date: date.startOfDay(),
            serviceStopsIds: serviceStops.map { $0.id },
            techId: techId,
            techName: techName,
            durationMin: 0,
            distanceMiles: 0,
            status: .didNotStart,
            totalStops: serviceStops.count,
            finishedStops: serviceStops.filter { $0.operationStatus == .finished }.count,
            vehicalId: ""
        )
        
        if existingActiveRoute == nil && serviceStops.count == 0 {
            print("  [RouteBuilder][build] Skipping creating AR as Service Stop List is \(serviceStops.count) && existingActiveRoute is nil")
            return nil
        } else if existingActiveRoute != nil && serviceStops.count == 0  {
            return nil
        } else {
            print("  [RouteBuilder][build] Building New AR")
            print("  [RouteBuilder][build] Route Order(exisiting): \(route.order?.count ?? 0)")
            route.serviceStopsIds = serviceStops.map { $0.id }
            route.totalStops = serviceStops.count
            route.finishedStops = serviceStops.filter { $0.operationStatus == .finished }.count

            
            //Build order of Active Route Based on Recurring Route
            route.order = RouteOrderBuilder.build(
                serviceStops: serviceStops,
                recurringRoute: recurringRoute,
                existingOrder: existingActiveRoute?.order
            )
            //Check if order is different than
            print("  [RouteBuilder][build] RouteOrder(updated): \(route.order?.count ?? 0)")
            route.totalStops = serviceStops.count
            route.finishedStops = serviceStops.filter { $0.operationStatus == .finished }.count

            //Get order from recurring route

            return route
        }
    }
}
//Order Builder
struct RouteOrderBuilder {

    static func build(
        serviceStops: [ServiceStop],
        recurringRoute: RecurringRoute?,
        existingOrder: [ServiceStopOrder]?
    ) -> [ServiceStopOrder] {

        var order = existingOrder ?? []
        
        if let recurringRoute {
            //If route exists create activeRoute order from recurring route.
            //List of service stops IDs that were sorted in based on the recurring route.
            let sortedRecurringRouteOrderList = recurringRoute.order.sorted(by: { $0.order < $1.order })
            var listOfOrderedServiceStopsIds: [String] = []
// If route exists create activeRoute order from recurring route.List of service stops IDs that were sorted in based on the recurring route.
            print("    [RouteOrderBuilder][build] Recurring Route Exists")
            for rrOrder in sortedRecurringRouteOrderList {
                if !order.contains(where: { $0.recurringServiceStopId == rrOrder.recurringServiceStopId }) {
                    if let stop = serviceStops.first(where: {$0.recurringServiceStopId == rrOrder.recurringServiceStopId}) {
                        
                        listOfOrderedServiceStopsIds.append(stop.id)
                        if !order.contains(where: { $0.serviceStopId == stop.id }) {
                            order.append(
                                ServiceStopOrder(
                                    id: UUID().uuidString,
                                    order: order.count + 1,
                                    serviceStopId: stop.id,
                                    recurringServiceStopId: stop.recurringServiceStopId
                                )
                            )
                        }
                    }
                }
            }
            
            print("    [RouteOrderBuilder][build] Adding Stops Not Included in Recurring Route")
            for stop in serviceStops {
                //if the service stop has not been ordered yet, order the service stop
                if !listOfOrderedServiceStopsIds.contains(stop.id) {
                    if !order.contains(where: { $0.serviceStopId == stop.id }) {
                        
                        listOfOrderedServiceStopsIds.append(stop.id)
                        order.append(
                            ServiceStopOrder(
                                id: UUID().uuidString,
                                order: order.count + 1,
                                serviceStopId: stop.id,
                                recurringServiceStopId: stop.recurringServiceStopId
                            )
                        )
                    }
                }
            }
        } else {
            //There is no order from Recurring Route therefore you need to create a new order for cases where no stops are routes.
            
            print("    [RouteOrderBuilder][build] Recurring Route DNE")
            for stop in serviceStops {
                //Sees if service stops are not in order and adds stop that are not already ordered
                if !order.contains(where: { $0.serviceStopId == stop.id }) {
                    order.append(
                        ServiceStopOrder(
                            id: UUID().uuidString,
                            order: order.count + 1,
                            serviceStopId: stop.id,
                            recurringServiceStopId: stop.recurringServiceStopId
                        )
                    )
                }
            }
        }
        print("    [RouteOrderBuilder][build] Service Stops Count = Order Count")
        print("    [RouteOrderBuilder][build] \(serviceStops.count) = \(order.count) (Should Equal Each other)")
        let activeStopIds = Set(serviceStops.map { $0.id })
        let activeOrder = order
            .filter { activeStopIds.contains($0.serviceStopId) }
            .sorted(by: { $0.order < $1.order })

        return activeOrder.enumerated().map { index, item in
            ServiceStopOrder(
                id: item.id,
                order: index + 1,
                serviceStopId: item.serviceStopId,
                recurringServiceStopId: item.recurringServiceStopId
            )
        }
    }
}
//Step C: Diffing Domain (Pure)
struct ActiveRouteDiff {
    let addedStopIds: [String]
    let removedStopIds: [String]
    let orderChanged: Bool
    let statusChanged: Bool
    let old: ActiveRoute?
    let new: ActiveRoute
    
}
struct ActiveRouteDiffer {

    static func diff(old: ActiveRoute?, new: ActiveRoute) -> ActiveRouteDiff {
        let oldIds = Set(old?.serviceStopsIds ?? [])
        let newIds = Set(new.serviceStopsIds)

        return ActiveRouteDiff(
            addedStopIds: Array(newIds.subtracting(oldIds)),
            removedStopIds: Array(oldIds.subtracting(newIds)),
            orderChanged: old?.order != new.order,
            statusChanged: old?.status != new.status,
            old: old,
            new: new
        )
    }
}
struct ArRrOrderDiff {
    let active: ActiveRoute
    let recurring: RecurringRoute?
    let isDifferent: Bool
    
}
struct ArRrOrderDiffer {

    static func diff(active: ActiveRoute, recurring: RecurringRoute?) -> ArRrOrderDiff {
        if let recurring {
            print("    [ArRrOrderDiffer][diff] Start")
            //I only want to check stops that are in both recurring and active. and check the order of those. If they are moved over or one time I want to ignore
            if let activeOrder = active.order {
                print("    [ArRrOrderDiffer][diff] Active Order Exists")

                let expectedIndex = Dictionary(
                    uniqueKeysWithValues: recurring.order
                        .sorted { $0.order < $1.order }
                        .enumerated()
                        .map { ($1.recurringServiceStopId, $0) }
                )

                let filtered = activeOrder
                    .filter { expectedIndex[$0.recurringServiceStopId] != nil }
                    .sorted { $0.order < $1.order }

                var lastIndex = -1
                print("    [ArRrOrderDiffer][diff] Filtered \(filtered)")

                for stop in filtered {
                    guard let index = expectedIndex[stop.recurringServiceStopId] else { continue }
                    if index < lastIndex { return ArRrOrderDiff(
                        active: active,
                        recurring: recurring,
                        isDifferent: true
                    ) }
                    lastIndex = index
                }
                print("    [ArRrOrderDiffer][diff] Ordered \(filtered)")
                
                return ArRrOrderDiff(
                    active: active,
                    recurring: recurring,
                    isDifferent: false
                )
            } else {
                print("    [ArRrOrderDiffer][diff] Active Order DNE")
                //If there is no Active Route then it should return false. Because I will not display the button to update the Recurring Route. There is not need because it DNE

                return ArRrOrderDiff(
                    active: active,
                    recurring: recurring,
                    isDifferent: false
                )
            }
        } else {
            print("    [ArRrOrderDiffer][diff] Recurriug Order DNE")
            //If there is no Recurring Route then it should return false. Because I will not display the button to update the Recurring Route. There is not need because it DNE
            return ArRrOrderDiff(
                active: active,
                recurring: recurring,
                isDifferent: false
            )
        }
    }
    func isRelativeOrderCorrect(
        recurring: [recurringRouteOrder],
        active: [ServiceStopOrder]
    ) -> Bool {

        let expectedIndex = Dictionary(
            uniqueKeysWithValues: recurring
                .sorted { $0.order < $1.order }
                .enumerated()
                .map { ($1.recurringServiceStopId, $0) }
        )

        let filtered = active
            .filter { expectedIndex[$0.recurringServiceStopId] != nil }
            .sorted { $0.order < $1.order }

        var lastIndex = -1

        for stop in filtered {
            guard let index = expectedIndex[stop.recurringServiceStopId] else { continue }
            if index < lastIndex { return false }
            lastIndex = index
        }

        return true
    }

}

//Old Function
/*
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
                        
                        self.startMilage = workingActiveRoute.startMilage ?? 0
                        
                    }
                    
                } else {
                    
                    self.duration = timeBetweenAsSeconds(start: time, end: date)
                    
                    self.startTime = workingActiveRoute.startTime ?? date
                    
                    self.startMilage = workingActiveRoute.startMilage ?? 0
                    
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
            
            print(" - \(SSCount) / \(self.serviceStopList.count) \(company.name)")
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
 */
