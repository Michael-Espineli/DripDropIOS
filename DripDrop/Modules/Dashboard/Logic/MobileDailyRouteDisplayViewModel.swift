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

struct ServiceStopStartPrompt: Identifiable, Equatable {
    var id: String { serviceStopId }

    let serviceStopId: String
    let customerName: String
    let serviceType: String
    let arrivalTime: Date
    let distanceMeters: CLLocationDistance
}

struct ServiceStopEndPrompt: Identifiable, Equatable {
    var id: String { serviceStopId }

    let serviceStopId: String
    let customerName: String
    let serviceType: String
    let departureTime: Date
    let distanceMeters: CLLocationDistance
}

@MainActor
final class MobileDailyRouteDisplayViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    private static let emptyMoveTech = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )

    private var defaultMoveTech: CompanyUser {
        companyUsers.first ?? Self.emptyMoveTech
    }

    // Location Tracking
    private let routeLocationManager: RouteLocationManager

    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var previousRoutesNeedingReview: [ActiveRoute] = []
    @Published private(set) var recentActiveRoutes: [ActiveRoute] = []
    @Published private(set) var pendingServiceStopStartPrompt: ServiceStopStartPrompt?
    @Published private(set) var pendingServiceStopEndPrompt: ServiceStopEndPrompt?
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
                guard let self else { return }
                guard Self.isFreshUsableRouteLocation(location) else {
                    print("[RouteLocationManager] Ignoring stale or unusable location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    return
                }

                self.currentLocation = location
                await self.evaluateServiceStopArrival(for: location)
                await self.evaluateServiceStopDeparture(for: location)
                // Optional: Persist breadcrumb to Firestore here (throttle as needed)
                if let active = self.activeRoute,
                   active.status == .inProgress,
                   let companyId = self.cachedCompanyId,
                   let companyName = self.cachedCompanyName,
                   let user = self.cachedUser {
                    if self.currentSummaryLogId == nil, self.currentSummaryType == .working {
                        await self.openSummaryLog(type: .working, companyId: companyId, companyName: companyName, activeRouteId: active.id, user: user)
                    }
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
    @Published var selectedTech: CompanyUser = MobileDailyRouteDisplayViewModel.emptyMoveTech
    @Published var selectedDate: Date = Date()
    @Published var enableMove: Bool = false
    @Published var moveType: String = "One Time"
    @Published var newDay: DaysOfWeek = .sunday
    private static let maximumAcceptedLocationAge: TimeInterval = 300
    private static let maximumAcceptedHorizontalAccuracy: CLLocationAccuracy = 500
    private static let serviceStopArrivalRadiusMeters: CLLocationDistance = 120

    private var currentRouteLocation: CLLocation? {
        guard let location = currentLocation else { return nil }
        guard Self.isUsableCoordinate(location.coordinate) else { return nil }
        guard location.horizontalAccuracy >= 0 else { return nil }
        return location
    }

    private static func isFreshUsableRouteLocation(_ location: CLLocation) -> Bool {
        isUsableCoordinate(location.coordinate) &&
        location.horizontalAccuracy >= 0 &&
        location.horizontalAccuracy <= maximumAcceptedHorizontalAccuracy &&
        abs(location.timestamp.timeIntervalSinceNow) <= maximumAcceptedLocationAge
    }

    private static func isUsableCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite &&
        coordinate.longitude.isFinite &&
        abs(coordinate.latitude) <= 90 &&
        abs(coordinate.longitude) <= 180 &&
        !(coordinate.latitude == 0 && coordinate.longitude == 0)
    }

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
    @Published private(set) var currentCompanyUser: CompanyUser?

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
    
    var selectedVehicleIsPersonal: Bool {
        selectedVehical.id.hasPrefix("personal:")
    }
    
    // Cached context for background uploads
    private var cachedCompanyId: String?
    private var cachedCompanyName: String?
    private var cachedUser: DBUser?
    private var serviceStopArrivalTimes: [String: Date] = [:]
    private var dismissedServiceStopStartPromptIds: Set<String> = []
    private var notifiedServiceStopStartPromptIds: Set<String> = []
    private var serviceStopDepartureTimes: [String: Date] = [:]
    private var dismissedServiceStopEndPromptIds: Set<String> = []
    private var notifiedServiceStopEndPromptIds: Set<String> = []

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
            dataService.updateActiveRouteCompanyFleetVehicle(companyId: companyId, activeRouteId: activeRoute.id, vehical: vehical)
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
            self?.currentCompanyUser = route.first { $0.userId == user.id }

            if self?.selectedTech.id.isEmpty == true, let firstTech = route.first {
                self?.selectedTech = firstTech
            }
        }
        //For date change reset Variables so that No other variables carry over
        self.activeRoute = nil
        self.recurringRoute = nil
        self.serviceStopList.removeAll()
        resetServiceStopArrivalState()
        
        // The issue occures because active Route comes back nil when it should not
        dataService.listenActiveRoute(
            companyId: companyId,
            date: date,
            techId: user.id
        ) { [weak self] route in
            guard let self else { return }
            self.activeRoute = route
            if let route {
                self.loadSelectedVehicleForActiveRoute(companyId: companyId, activeRoute: route)
            }
            print("")
            print("[MobileDailyRouteDisplayViewModel][start] Active Route Listener:", route?.id ?? "nil")
            self.refreshRoutePresentationFromCurrentState()
        }
        dataService.listenRecurringRoute(
            companyId: companyId,
            techId: user.id,
            day: weekDay(date: date)
        ) { [weak self] route in
            guard let self else { return }
            self.recurringRoute = route
            print("")
            print("[MobileDailyRouteDisplayViewModel][start] Recurring Route Listener: ", route?.id ?? "nil")
            self.refreshRoutePresentationFromCurrentState()
        }
        dataService.listenServiceStops(
            companyId: companyId,
            date: date,
            techId: user.id
        ) { [weak self] stops in
            self?.serviceStopList = stops
            self?.reconcileServiceStopArrivalState()
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
            self.serviceStopOrderList = computedRoute.order ?? []

            //Sees what the difference are between old and new Route
            let diff = ActiveRouteDiffer.diff(
                old: activeRoute,
                new: computedRoute
            )
            
            self.activeRoute = computedRoute
            
            if whoCalled == "SS" {
                dataService.applyRouteChanges(companyId:companyId,diff:diff,calledFrom: whoCalled)
            }
            
            let orderDiff = ArRrOrderDiffer.diff(
                active: computedRoute,
                recurring: recurringRoute
            )
            self.ArOrderIsDifferentThanRrORder = orderDiff.isDifferent
        } else {
            if let activeRoute {
                if whoCalled == "SS" {
                    print("  [MobileDailyRouteDisplayViewModel][recompute] Sync active route with zero service stops")
                    Task { [weak self] in
                        guard let self else { return }

                        do {
                            let syncedRoute = try await dataService.syncActiveRouteForServiceStops(
                                companyId: companyId,
                                date: date,
                                techId: activeRoute.techId,
                                techName: activeRoute.techName
                            )
                            await MainActor.run {
                                self.activeRoute = syncedRoute
                            }
                        } catch {
                            print("  [MobileDailyRouteDisplayViewModel][recompute] Zero-stop sync error \(error)")
                        }
                    }
                }
            }
        }
    }

    private func refreshRoutePresentationFromCurrentState() {
        guard let activeRoute else {
            serviceStopOrderList = []
            ArOrderIsDifferentThanRrORder = false
            return
        }

        serviceStopOrderList = activeRoute.order ?? []
        if !serviceStopList.isEmpty {
            serviceStopList = applyOrder(
                serviceStops: serviceStopList,
                serviceStopOrders: activeRoute.order
            )
        }

        let orderDiff = ArRrOrderDiffer.diff(
            active: activeRoute,
            recurring: recurringRoute
        )
        ArOrderIsDifferentThanRrORder = orderDiff.isDifferent
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
    func startServiceStop(companyId: String?, serviceStopId: String, startTime: Date = Date()){
        guard let companyId else {return}

        Task{
            do {
                try await dataService.updateServiceStopStartTime(companyId: companyId, serviceStopId: serviceStopId, startTime: startTime)
                if let index = serviceStopList.firstIndex(where: { $0.id == serviceStopId }) {
                    serviceStopList[index].startTime = startTime
                }

                clearServiceStopStartPrompt(serviceStopId: serviceStopId)
                clearServiceStopEndPrompt(serviceStopId: serviceStopId)
            } catch {
                print("[MobileDailyRouteDisplayViewModel][startServiceStop] Error \(error)")
            }
        }
    }

    func finishServiceStop(companyId: String?, serviceStopId: String, endTime: Date = Date()) {
        guard let companyId else { return }

        Task {
            do {
                try await dataService.updateServicestopOperationStatus(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    operationStatus: .finished
                )
                try await dataService.updateServiceStopEndTime(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    endTime: endTime
                )

                if let index = serviceStopList.firstIndex(where: { $0.id == serviceStopId }) {
                    serviceStopList[index].operationStatus = .finished
                    serviceStopList[index].endTime = endTime
                }

                clearServiceStopEndPrompt(serviceStopId: serviceStopId)
                clearServiceStopStartPrompt(serviceStopId: serviceStopId)
            } catch {
                print("[MobileDailyRouteDisplayViewModel][finishServiceStop] Error \(error)")
            }
        }
    }
    func startActiveRoute(
        companyId: String?,
        companyName:String?,
        user:DBUser?,
        showMileageSheet: Bool = true
    ){
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
                if showMileageSheet {
                    self.showMilage = true
                }
                
                
                dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .inProgress)
                
                //Update Milage
                
                dataService.updateActiveRouteStartTime(companyId: companyId, activeRouteId: activeRoute.id, startTime: Date())
                
                //Upload Location
                routeLocationManager.startTracking()
                Task {
                    _ = await NotificationViewModel.shared.requestAuthorizationIfNeeded()
                }

                if let location = self.currentRouteLocation {
                    let log = ActiveRouteLog(
                        id: "com_ar_log_" + UUID().uuidString,
                        activeRouteId: activeRoute.id,
                        startTime: Date(),
                        startLatitude: location.coordinate.latitude,
                        startLongitude: location.coordinate.longitude,
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
                } else {
                    self.currentSummaryLogId = nil
                    self.currentSummaryType = .working
                    print("[RouteLog] No usable current location at route start; deferring start location log")
                }

                startRouteLogTimer(companyId: companyId, activeRouteId: activeRoute.id, user: user, companyName: companyName)
            } catch {
                print("[MobileDailyRouteDisplayViewModel][startActiveRoute] Error \(error)")
            }
        }
    }
    

    func stopActiveRoute(
        companyId: String?,
        companyName:String?,
        user:DBUser?,
        route routeToStop: ActiveRoute? = nil
    ){
        guard let companyId else {return}
        guard let companyName else {return}
        guard let user else {return}
        guard var route = routeToStop ?? activeRoute else {return}
            //Change Status
        let endTime = routeEndTime(for: route)
        route.status = .finished
        route.endTime = endTime

        dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: route.id, status: .finished)
        
        if route.id == activeRoute?.id {
            self.activeRoute = route
            Task { @MainActor in
                if let companyId = self.cachedCompanyId, let activeId = self.activeRoute?.id {
                    await closeCurrentSummaryLog(companyId: companyId, activeRouteId: activeId)
                }
            }

            // Stop location tracking at end of route
            routeLocationManager.stopTracking()
            stopRouteLogTimer(companyId: companyId, activeRouteId: route.id, user: user, companyName: companyName)
        }

        dataService.updateActiveRouteEndTime(companyId: companyId, activeRouteId: route.id, endTime: endTime)

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
    func resumeActiveRoute(
        companyId: String?,
        companyName: String?,
        user: DBUser?,
        route routeToResume: ActiveRoute? = nil
    ) {
        guard let companyId else {return}
        guard let companyName else {return}
        guard let user else {return}
        guard var activeRoute = routeToResume ?? activeRoute else {return}
        if activeRoute.id == "" { return }
        
        self.cachedCompanyId = companyId
        self.cachedCompanyName = companyName
        self.cachedUser = user
            //Change Status
        activeRoute.status = .inProgress
        if let existingStartTime = activeRoute.startTime {
            self.startTime = existingStartTime
        }
        self.activeRoute = activeRoute

        dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: activeRoute.id, status: .inProgress)
        // Resume location tracking when route resumes
        routeLocationManager.startTracking()
        
        Task { @MainActor in
            await closeCurrentSummaryLog(companyId: companyId, activeRouteId: activeRoute.id)
            await openSummaryLog(type: .working, companyId: companyId, companyName: companyName, activeRouteId: activeRoute.id, user: user)
            startRouteLogTimer(companyId: companyId, activeRouteId: activeRoute.id, user: user, companyName: companyName)
        }
    }
    
    // Ask for permissions from your UI or when starting a route
    func requestWhenInUseLocation() {
        routeLocationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysLocation() {
        routeLocationManager.requestAlwaysAuthorization()
    }
    
    private func personalVehicleForCurrentUser(withMiles miles: Double? = nil) -> PersonalVehicle? {
        guard var personalVehicle = currentCompanyUser?.personalVehicle else { return nil }
        
        if let miles {
            personalVehicle.miles = miles
        }
        
        return personalVehicle
    }
    
    private func loadSelectedVehicleForActiveRoute(companyId: String, activeRoute: ActiveRoute) {
        if activeRoute.vehicleSource == "Personal",
           let personalVehicle = activeRoute.personalVehicle,
           let ownerId = activeRoute.personalVehicleOwnerId ?? currentCompanyUser?.userId {
            selectedVehical = personalVehicle.asVehical(ownerId: ownerId)
            return
        }
        
        guard !activeRoute.vehicalId.isEmpty else { return }
        
        Task {
            do {
                let vehicle = try await dataService.getVehical(companyId: companyId, vehicalId: activeRoute.vehicalId)
                await MainActor.run {
                    self.selectedVehical = vehicle
                }
            } catch {
                print("[MobileDailyRouteDisplayViewModel][loadSelectedVehicleForActiveRoute] \(error)")
            }
        }
    }
    
    private func updateActiveRouteSelectedVehicle(companyId: String, activeRouteId: String, miles: Double? = nil) {
        guard !selectedVehical.id.isEmpty else { return }
        
        if selectedVehicleIsPersonal {
            if let personalVehicle = personalVehicleForCurrentUser(withMiles: miles),
               let ownerId = currentCompanyUser?.userId {
                dataService.updateActiveRoutePersonalVehicle(
                    companyId: companyId,
                    activeRouteId: activeRouteId,
                    ownerId: ownerId,
                    personalVehicle: personalVehicle
                )
            }
            return
        }
        
        dataService.updateActiveRouteCompanyFleetVehicle(
            companyId: companyId,
            activeRouteId: activeRouteId,
            vehical: selectedVehical
        )
    }
    
    private func updateSelectedCompanyFleetMileage(companyId: String, miles: Double) {
        guard !selectedVehical.id.isEmpty,
              !selectedVehicleIsPersonal
        else { return }
        
        Task {
            do {
                try await dataService.updateVehicalMilage(companyId: companyId, vehicalId: selectedVehical.id, miles: miles)
            } catch {
                print(error)
            }
        }
    }

    private func routeEndTime(for route: ActiveRoute) -> Date {
        if Calendar.current.isDate(route.date, inSameDayAs: Date()) {
            return Date()
        }

        return Calendar.current.date(
            byAdding: .second,
            value: -1,
            to: route.date.endOfDay()
        ) ?? route.date
    }
    
    func updateRouteStartMilage(companyId: String?){
        print("  [MobileDailyRouteDisplayViewModel][updateRouteStartMilage]")
        guard let companyId else {return}
        guard let activeRoute else {return}
        guard let milage = Double(inputStartMilage) else {return}
        //Update Route
        dataService.updateActiveRouteStartMilage(companyId: companyId, activeRouteId: activeRoute.id, startMilage: milage)
        updateActiveRouteSelectedVehicle(companyId: companyId, activeRouteId: activeRoute.id, miles: milage)
        updateSelectedCompanyFleetMileage(companyId: companyId, miles: milage)
    }
    
    func updateRouteEndtMilage(
        companyId: String?,
        route routeToUpdate: ActiveRoute? = nil,
        syncSelectedVehicle: Bool = true
    ) {
        print("  [MobileDailyRouteDisplayViewModel][updateRouteEndtMilage]")

        guard let companyId else { return }
        guard var route = routeToUpdate ?? activeRoute else { return }
        guard let milage = Double(inputEndMilage) else { return }

        dataService.updateActiveRouteEndMilage(
            companyId: companyId,
            activeRouteId: route.id,
            endMilage: milage
        )
        if syncSelectedVehicle {
            updateActiveRouteSelectedVehicle(companyId: companyId, activeRouteId: route.id, miles: milage)
            updateSelectedCompanyFleetMileage(companyId: companyId, miles: milage)
        }

        if let startMilage = route.startMilage {
            dataService.updateActiveRouteDistnace(
                companyId: companyId,
                activeRouteId: route.id,
                distance: milage - startMilage
            )
        }

        route.endMilage = milage
        if route.id == activeRoute?.id {
            activeRoute = route
            endMilage = milage
        }
    }
    
    func cancelMove(){
        self.selectedServiceStops = []
        self.moveDate = Date()
        self.selectedTech = defaultMoveTech
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
                self.selectedTech = defaultMoveTech
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
        let movableStops = selectedServiceStops.filter { $0.operationStatus == .notFinished }
        guard !movableStops.isEmpty else {
            alertMessage = "Select at least one unfinished stop to move."
            showAlert = true
            return
        }

        FunctionsManager.shared.updateServiceStopPermanently(
            companyId: companyId,
            serviceStopList: movableStops,
            newTech: selectedTech,
            newDay: newDay
        )
        self.selectedServiceStops = []
        self.moveDate = Date()
        self.selectedTech = defaultMoveTech
        self.newDay = .monday
        self.enableMove = false
        self.alertMessage = "Permanent move submitted."
        self.showAlert = true
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
 
        let newOrder = generateNewOrder(
            serviceStops: serviceStopList,
            existingOrder: activeRoute.order
        )
        applyActiveRouteOrder(newOrder)
        
        Task{
            do {
                try await dataService.updateActiveRouteOrderList(
                    companyId: companyId,
                    activeRouteId: activeRoute.id,
                    serviceStopOrderList: newOrder
                )
                self.alertMessage = "Route order saved."
                self.showAlert = true
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][reorderServiceStops] Error \(error)")
                self.alertMessage = "Failed to save route order."
                self.showAlert = true
            }
        }
    }
    func autoOrderServiceStopsForRoute() {
        let autoOrderedStops = RouteAutoOrderBuilder.order(
            serviceStops: serviceStopList,
            activeRoute: activeRoute,
            currentLocation: currentRouteLocation
        )

        guard autoOrderedStops.map(\.id) != serviceStopList.map(\.id) else {
            alertMessage = "Route is already in the suggested order."
            showAlert = true
            return
        }

        serviceStopList = autoOrderedStops
    }

    private func generateNewOrder(
        serviceStops: [ServiceStop],
        existingOrder: [ServiceStopOrder]? = nil
    ) -> [ServiceStopOrder] {
        var workingOrderList:[ServiceStopOrder] = []
        var existingByStopId: [String: ServiceStopOrder] = [:]
        for item in existingOrder ?? [] where existingByStopId[item.serviceStopId] == nil {
            existingByStopId[item.serviceStopId] = item
        }
        print("**  [MobileDailyRouteDisplayViewModel][generateNewOrder]")

        for stop in serviceStops {
            
            let index:Int = serviceStops.firstIndex(of: stop) ?? 0
            let existingOrderItem = existingByStopId[stop.id]
            
            let newOrder = ServiceStopOrder(
                id: existingOrderItem?.id ?? "com_ar_ss_ord_" + UUID().uuidString,
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
        let activeRouteOrder = activeRoute.order ?? generateNewOrder(serviceStops: serviceStopList)
        let nextRecurringOrder = recurringOrderMatchingActiveOrder(
            recurring: recurringRoute.order,
            active: activeRouteOrder
        )

        var updatedRecurringRoute = recurringRoute
        updatedRecurringRoute.order = nextRecurringOrder
        self.recurringRoute = updatedRecurringRoute
        self.ArOrderIsDifferentThanRrORder = false
        //Needs to be called by button and simply updates the Recurring Route order to reflect the new Active Route order.
        //** Need to figure out how to ignore service stops that are not recurring. Most likely by checking to see if the RSS ID is empty
        Task {
            do {
                try await FunctionsManager.shared.updateRecurringRouteOrderPermanently(
                    companyId: companyId,
                    routeId: recurringRoute.id,
                    recurringRouteOrder: recurringRoute.order,
                    serviceStopOrders: activeRouteOrder
                )
                self.alertMessage = "Default route order updated."
                self.showAlert = true
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][reorderServiceStopsPermanently] Error \(error)")
                self.alertMessage = "Failed to update default route order."
                self.showAlert = true
            }
        }
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
            
            var orderLookup: [String: Int] = [:]
            for order in serviceStopOrders {
                if let existingOrder = orderLookup[order.serviceStopId] {
                    let keptOrder = min(existingOrder, order.order)
                    orderLookup[order.serviceStopId] = keptOrder
                    print("    [MobileDailyRouteDisplayViewModel][applyOrder] Duplicate serviceStopId \(order.serviceStopId) in order list. Keeping order \(keptOrder)")
                } else {
                    orderLookup[order.serviceStopId] = order.order
                }
            }

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
        let activeRouteOrder = activeRoute.order ?? generateNewOrder(serviceStops: serviceStopList)
        let defaultOrder = activeOrderMatchingRecurringDefault(
            recurring: recurringRoute.order,
            active: activeRouteOrder
        )
        applyActiveRouteOrder(defaultOrder)

        Task{
            do {
                try await dataService.updateActiveRouteOrderList(
                    companyId: companyId,
                    activeRouteId: activeRoute.id,
                    serviceStopOrderList: defaultOrder
                )
                self.alertMessage = "Route order reset to default."
                self.showAlert = true
            } catch {
                print("  [MobileDailyRouteDisplayViewModel][resetOrderToMatchRecurringRoute] Error \(error)")
                self.alertMessage = "Failed to reset route order."
                self.showAlert = true
            }
        }
    }
    private func activeOrderMatchingRecurringDefault(
        recurring: [recurringRouteOrder],
        active: [ServiceStopOrder]
    ) -> [ServiceStopOrder] {

        let recurringSorted = recurring.sorted { $0.order < $1.order }
        let activeSorted = active.sorted { $0.order < $1.order }
        var activeByRecurringId: [String: ServiceStopOrder] = [:]
        for item in activeSorted where !item.recurringServiceStopId.isEmpty {
            if activeByRecurringId[item.recurringServiceStopId] == nil {
                activeByRecurringId[item.recurringServiceStopId] = item
            }
        }
        
        var usedServiceStopIds = Set<String>()
        var reorderedRecurringStops: [ServiceStopOrder] = []
        for r in recurringSorted {
            if let match = activeByRecurringId[r.recurringServiceStopId] {
                reorderedRecurringStops.append(match)
                usedServiceStopIds.insert(match.serviceStopId)
            }
        }

        let remainingStops = activeSorted.filter {
            !usedServiceStopIds.contains($0.serviceStopId)
        }

        return renumberActiveOrder(reorderedRecurringStops + remainingStops)
    }

    private func recurringOrderMatchingActiveOrder(
        recurring: [recurringRouteOrder],
        active: [ServiceStopOrder]
    ) -> [recurringRouteOrder] {
        let recurringSorted = recurring.sorted { $0.order < $1.order }
        let activeSorted = active.sorted { $0.order < $1.order }
        var recurringById: [String: recurringRouteOrder] = [:]

        for item in recurringSorted where !item.recurringServiceStopId.isEmpty {
            if recurringById[item.recurringServiceStopId] == nil {
                recurringById[item.recurringServiceStopId] = item
            }
        }

        var updatedOrder: [recurringRouteOrder] = []
        var usedRecurringIds = Set<String>()

        for stopOrder in activeSorted where !stopOrder.recurringServiceStopId.isEmpty {
            if let existing = recurringById[stopOrder.recurringServiceStopId] {
                updatedOrder.append(existing)
                usedRecurringIds.insert(existing.recurringServiceStopId)
            } else if let stop = serviceStopList.first(where: { $0.recurringServiceStopId == stopOrder.recurringServiceStopId }) {
                updatedOrder.append(
                    recurringRouteOrder(
                        id: "com_rr_ord_" + UUID().uuidString,
                        order: updatedOrder.count + 1,
                        recurringServiceStopId: stop.recurringServiceStopId,
                        customerId: stop.customerId,
                        customerName: stop.customerName,
                        locationId: stop.serviceLocationId
                    )
                )
                usedRecurringIds.insert(stop.recurringServiceStopId)
            }
        }

        updatedOrder.append(
            contentsOf: recurringSorted.filter {
                !usedRecurringIds.contains($0.recurringServiceStopId)
            }
        )

        return updatedOrder.enumerated().map { index, item in
            recurringRouteOrder(
                id: item.id,
                order: index + 1,
                recurringServiceStopId: item.recurringServiceStopId,
                customerId: item.customerId,
                customerName: item.customerName,
                locationId: item.locationId
            )
        }
    }

    private func applyActiveRouteOrder(_ order: [ServiceStopOrder]) {
        let normalizedOrder = renumberActiveOrder(order)
        serviceStopOrderList = normalizedOrder
        serviceStopList = applyOrder(
            serviceStops: serviceStopList,
            serviceStopOrders: normalizedOrder
        )

        if var route = activeRoute {
            route.order = normalizedOrder
            activeRoute = route
            let orderDiff = ArRrOrderDiffer.diff(
                active: route,
                recurring: recurringRoute
            )
            ArOrderIsDifferentThanRrORder = orderDiff.isDifferent
        }
    }

    private func renumberActiveOrder(_ order: [ServiceStopOrder]) -> [ServiceStopOrder] {
        order.enumerated().map { index, item in
            ServiceStopOrder(
                id: item.id,
                order: index + 1,
                serviceStopId: item.serviceStopId,
                recurringServiceStopId: item.recurringServiceStopId
            )
        }
    }

    func confirmPendingServiceStopStart(companyId: String?) {
        guard let prompt = pendingServiceStopStartPrompt else { return }

        startServiceStop(
            companyId: companyId,
            serviceStopId: prompt.serviceStopId,
            startTime: prompt.arrivalTime
        )
    }

    func confirmPendingServiceStopEnd(companyId: String?) {
        guard let prompt = pendingServiceStopEndPrompt else { return }

        finishServiceStop(
            companyId: companyId,
            serviceStopId: prompt.serviceStopId,
            endTime: prompt.departureTime
        )
    }

    func dismissPendingServiceStopStartPrompt() {
        guard let prompt = pendingServiceStopStartPrompt else { return }

        dismissedServiceStopStartPromptIds.insert(prompt.serviceStopId)
        pendingServiceStopStartPrompt = nil
        NotificationViewModel.shared.cancelServiceStopStartPrompt(serviceStopId: prompt.serviceStopId)
    }

    func dismissPendingServiceStopEndPrompt() {
        guard let prompt = pendingServiceStopEndPrompt else { return }

        dismissedServiceStopEndPromptIds.insert(prompt.serviceStopId)
        pendingServiceStopEndPrompt = nil
        NotificationViewModel.shared.cancelServiceStopEndPrompt(serviceStopId: prompt.serviceStopId)
    }

    func arrivalTimeForServiceStop(_ serviceStopId: String) -> Date? {
        serviceStopArrivalTimes[serviceStopId]
    }

    private func evaluateServiceStopArrival(for location: CLLocation) async {
        guard let activeRoute,
              activeRoute.status == .inProgress else {
            pendingServiceStopStartPrompt = nil
            return
        }

        let nearbyStops = nearbyUnstartedStops(for: location)
        let nearbyStopIds = Set(nearbyStops.map { $0.stop.id })

        clearArrivalStateForStopsNoLongerNearby(nearbyStopIds: nearbyStopIds)

        guard let nearest = nearbyStops.first else {
            pendingServiceStopStartPrompt = nil
            return
        }

        let stop = nearest.stop
        let arrivalTime = serviceStopArrivalTimes[stop.id] ?? location.timestamp
        serviceStopArrivalTimes[stop.id] = arrivalTime

        guard !dismissedServiceStopStartPromptIds.contains(stop.id) else { return }

        let prompt = ServiceStopStartPrompt(
            serviceStopId: stop.id,
            customerName: stop.customerName,
            serviceType: stop.type,
            arrivalTime: arrivalTime,
            distanceMeters: nearest.distance
        )

        if pendingServiceStopStartPrompt != prompt {
            pendingServiceStopStartPrompt = prompt
        }

        guard !notifiedServiceStopStartPromptIds.contains(stop.id) else { return }
        notifiedServiceStopStartPromptIds.insert(stop.id)

        await NotificationViewModel.shared.scheduleServiceStopStartPrompt(
            serviceStopId: stop.id,
            customerName: stop.customerName,
            serviceType: stop.type,
            arrivalTime: arrivalTime
        )
    }

    private func nearbyUnstartedStops(
        for location: CLLocation
    ) -> [(index: Int, stop: ServiceStop, distance: CLLocationDistance)] {
        serviceStopList
            .enumerated()
            .compactMap { index, stop -> (index: Int, stop: ServiceStop, distance: CLLocationDistance)? in
                guard stop.operationStatus == .notFinished,
                      stop.startTime == nil,
                      Self.isUsableCoordinate(stop.address.coordinates) else {
                    return nil
                }

                let stopLocation = CLLocation(
                    latitude: stop.address.latitude,
                    longitude: stop.address.longitude
                )
                let distance = location.distance(from: stopLocation)

                guard distance <= Self.serviceStopArrivalRadiusMeters else { return nil }

                return (index, stop, distance)
            }
            .sorted { lhs, rhs in
                if abs(lhs.distance - rhs.distance) < 10 {
                    return lhs.index < rhs.index
                }

                return lhs.distance < rhs.distance
            }
    }

    private func evaluateServiceStopDeparture(for location: CLLocation) async {
        guard let activeRoute,
              activeRoute.status == .inProgress else {
            pendingServiceStopEndPrompt = nil
            return
        }

        let departedStops = departedStartedStops(for: location)
        let departedStopIds = Set(departedStops.map { $0.stop.id })

        clearDepartureStateForStopsNoLongerDeparted(departedStopIds: departedStopIds)

        guard let nearest = departedStops.first else {
            pendingServiceStopEndPrompt = nil
            return
        }

        let stop = nearest.stop
        let departureTime = serviceStopDepartureTimes[stop.id] ?? location.timestamp
        serviceStopDepartureTimes[stop.id] = departureTime

        guard !dismissedServiceStopEndPromptIds.contains(stop.id) else { return }

        let prompt = ServiceStopEndPrompt(
            serviceStopId: stop.id,
            customerName: stop.customerName,
            serviceType: stop.type,
            departureTime: departureTime,
            distanceMeters: nearest.distance
        )

        if pendingServiceStopEndPrompt != prompt {
            pendingServiceStopEndPrompt = prompt
        }

        guard !notifiedServiceStopEndPromptIds.contains(stop.id) else { return }
        notifiedServiceStopEndPromptIds.insert(stop.id)

        await NotificationViewModel.shared.scheduleServiceStopEndPrompt(
            serviceStopId: stop.id,
            customerName: stop.customerName,
            serviceType: stop.type,
            departureTime: departureTime
        )
    }

    private func departedStartedStops(
        for location: CLLocation
    ) -> [(index: Int, stop: ServiceStop, distance: CLLocationDistance)] {
        serviceStopList
            .enumerated()
            .compactMap { index, stop -> (index: Int, stop: ServiceStop, distance: CLLocationDistance)? in
                guard stop.operationStatus == .notFinished,
                      stop.startTime != nil,
                      stop.endTime == nil,
                      Self.isUsableCoordinate(stop.address.coordinates) else {
                    return nil
                }

                let stopLocation = CLLocation(
                    latitude: stop.address.latitude,
                    longitude: stop.address.longitude
                )
                let distance = location.distance(from: stopLocation)

                guard distance > Self.serviceStopArrivalRadiusMeters else { return nil }

                return (index, stop, distance)
            }
            .sorted { lhs, rhs in
                if abs(lhs.distance - rhs.distance) < 10 {
                    return lhs.index < rhs.index
                }

                return lhs.distance < rhs.distance
            }
    }

    private func clearDepartureStateForStopsNoLongerDeparted(departedStopIds: Set<String>) {
        let trackedStopIds = Set(serviceStopDepartureTimes.keys)
            .union(dismissedServiceStopEndPromptIds)
            .union(notifiedServiceStopEndPromptIds)

        for serviceStopId in trackedStopIds where !departedStopIds.contains(serviceStopId) {
            serviceStopDepartureTimes.removeValue(forKey: serviceStopId)
            dismissedServiceStopEndPromptIds.remove(serviceStopId)
            notifiedServiceStopEndPromptIds.remove(serviceStopId)
            NotificationViewModel.shared.cancelServiceStopEndPrompt(serviceStopId: serviceStopId)
        }

        if let prompt = pendingServiceStopEndPrompt,
           !departedStopIds.contains(prompt.serviceStopId) {
            pendingServiceStopEndPrompt = nil
        }
    }

    private func clearArrivalStateForStopsNoLongerNearby(nearbyStopIds: Set<String>) {
        let trackedStopIds = Set(serviceStopArrivalTimes.keys)
            .union(dismissedServiceStopStartPromptIds)
            .union(notifiedServiceStopStartPromptIds)

        for serviceStopId in trackedStopIds where !nearbyStopIds.contains(serviceStopId) {
            serviceStopArrivalTimes.removeValue(forKey: serviceStopId)
            dismissedServiceStopStartPromptIds.remove(serviceStopId)
            notifiedServiceStopStartPromptIds.remove(serviceStopId)
            NotificationViewModel.shared.cancelServiceStopStartPrompt(serviceStopId: serviceStopId)
        }

        if let prompt = pendingServiceStopStartPrompt,
           !nearbyStopIds.contains(prompt.serviceStopId) {
            pendingServiceStopStartPrompt = nil
        }
    }

    private func clearServiceStopStartPrompt(serviceStopId: String) {
        serviceStopArrivalTimes.removeValue(forKey: serviceStopId)
        dismissedServiceStopStartPromptIds.remove(serviceStopId)
        notifiedServiceStopStartPromptIds.remove(serviceStopId)

        if pendingServiceStopStartPrompt?.serviceStopId == serviceStopId {
            pendingServiceStopStartPrompt = nil
        }

        NotificationViewModel.shared.cancelServiceStopStartPrompt(serviceStopId: serviceStopId)
    }

    private func clearServiceStopEndPrompt(serviceStopId: String) {
        serviceStopDepartureTimes.removeValue(forKey: serviceStopId)
        dismissedServiceStopEndPromptIds.remove(serviceStopId)
        notifiedServiceStopEndPromptIds.remove(serviceStopId)

        if pendingServiceStopEndPrompt?.serviceStopId == serviceStopId {
            pendingServiceStopEndPrompt = nil
        }

        NotificationViewModel.shared.cancelServiceStopEndPrompt(serviceStopId: serviceStopId)
    }

    private func resetServiceStopArrivalState() {
        if let prompt = pendingServiceStopStartPrompt {
            NotificationViewModel.shared.cancelServiceStopStartPrompt(serviceStopId: prompt.serviceStopId)
        }
        if let prompt = pendingServiceStopEndPrompt {
            NotificationViewModel.shared.cancelServiceStopEndPrompt(serviceStopId: prompt.serviceStopId)
        }

        serviceStopArrivalTimes.removeAll()
        dismissedServiceStopStartPromptIds.removeAll()
        notifiedServiceStopStartPromptIds.removeAll()
        pendingServiceStopStartPrompt = nil
        serviceStopDepartureTimes.removeAll()
        dismissedServiceStopEndPromptIds.removeAll()
        notifiedServiceStopEndPromptIds.removeAll()
        pendingServiceStopEndPrompt = nil
    }

    private func reconcileServiceStopArrivalState() {
        let unstartedStopIds = Set(
            serviceStopList
                .filter { $0.operationStatus == .notFinished && $0.startTime == nil }
                .map(\.id)
        )

        let trackedStopIds = Set(serviceStopArrivalTimes.keys)
            .union(dismissedServiceStopStartPromptIds)
            .union(notifiedServiceStopStartPromptIds)

        for serviceStopId in trackedStopIds where !unstartedStopIds.contains(serviceStopId) {
            clearServiceStopStartPrompt(serviceStopId: serviceStopId)
        }

        if let prompt = pendingServiceStopStartPrompt,
           !unstartedStopIds.contains(prompt.serviceStopId) {
            pendingServiceStopStartPrompt = nil
        }

        let startedUnfinishedStopIds = Set(
            serviceStopList
                .filter { $0.operationStatus == .notFinished && $0.startTime != nil && $0.endTime == nil }
                .map(\.id)
        )

        let trackedEndStopIds = Set(serviceStopDepartureTimes.keys)
            .union(dismissedServiceStopEndPromptIds)
            .union(notifiedServiceStopEndPromptIds)

        for serviceStopId in trackedEndStopIds where !startedUnfinishedStopIds.contains(serviceStopId) {
            clearServiceStopEndPrompt(serviceStopId: serviceStopId)
        }

        if let prompt = pendingServiceStopEndPrompt,
           !startedUnfinishedStopIds.contains(prompt.serviceStopId) {
            pendingServiceStopEndPrompt = nil
        }
    }

    // MARK: Location Functions

    // MARK: - Periodic Route Log Publishing
    private var routeLogTimer: Timer?

    private func startRouteLogTimer(companyId: String, activeRouteId: String, user: DBUser, companyName: String) {
        // Avoid multiple timers
        routeLogTimer?.invalidate()
        routeLogTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.publishRouteLocationTick(companyId: companyId, activeRouteId: activeRouteId, user: user, companyName: companyName)
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
        guard currentRouteLocation != nil else { return }
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
        guard let location = currentRouteLocation else {
            currentSummaryType = type
            print("    [SummaryLog] No usable current location; deferring \(type.rawValue) summary log")
            return
        }

        let log = ActiveRouteLog(
            id: "com_ar_log_" + UUID().uuidString,
            activeRouteId: activeRouteId,
            startTime: Date(),
            startLatitude: location.coordinate.latitude,
            startLongitude: location.coordinate.longitude,
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
        guard currentSummaryLogId != nil else { return }
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
        guard let loc = currentRouteLocation else {
            print("    [RouteLog] No usable current location yet; skipping tick")
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
        guard let loc = currentRouteLocation else {
            print("    [RouteLog] No usable current location yet; skipping tick")
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

        let stopsById = Dictionary(uniqueKeysWithValues: serviceStops.map { ($0.id, $0) })
        var order: [ServiceStopOrder] = []
        var orderedStopIds = Set<String>()

        for item in (existingOrder ?? []).sorted(by: { $0.order < $1.order }) {
            guard let stop = stopsById[item.serviceStopId],
                  orderedStopIds.insert(item.serviceStopId).inserted
            else {
                continue
            }

            order.append(
                ServiceStopOrder(
                    id: item.id,
                    order: order.count + 1,
                    serviceStopId: item.serviceStopId,
                    recurringServiceStopId: resolvedRecurringServiceStopId(
                        order: item,
                        stop: stop
                    )
                )
            )
        }
        
        if let recurringRoute {
            //If route exists create activeRoute order from recurring route.
            //List of service stops IDs that were sorted in based on the recurring route.
            let sortedRecurringRouteOrderList = recurringRoute.order.sorted(by: { $0.order < $1.order })
// If route exists create activeRoute order from recurring route.List of service stops IDs that were sorted in based on the recurring route.
            print("    [RouteOrderBuilder][build] Recurring Route Exists")
            for rrOrder in sortedRecurringRouteOrderList {
                if let stop = serviceStops.first(where: { $0.recurringServiceStopId == rrOrder.recurringServiceStopId }),
                   !orderedStopIds.contains(stop.id) {
                    order.append(
                        ServiceStopOrder(
                            id: "com_ar_ss_ord_" + UUID().uuidString,
                            order: order.count + 1,
                            serviceStopId: stop.id,
                            recurringServiceStopId: stop.recurringServiceStopId
                        )
                    )
                    orderedStopIds.insert(stop.id)
                }
            }
            
            print("    [RouteOrderBuilder][build] Adding Stops Not Included in Recurring Route")
            for stop in serviceStops {
                //if the service stop has not been ordered yet, order the service stop
                if !orderedStopIds.contains(stop.id) {
                    order.append(
                        ServiceStopOrder(
                            id: "com_ar_ss_ord_" + UUID().uuidString,
                            order: order.count + 1,
                            serviceStopId: stop.id,
                            recurringServiceStopId: stop.recurringServiceStopId
                        )
                    )
                    orderedStopIds.insert(stop.id)
                }
            }
        } else {
            //There is no order from Recurring Route therefore you need to create a new order for cases where no stops are routes.
            
            print("    [RouteOrderBuilder][build] Recurring Route DNE")
            for stop in serviceStops {
                //Sees if service stops are not in order and adds stop that are not already ordered
                if !orderedStopIds.contains(stop.id) {
                    order.append(
                        ServiceStopOrder(
                            id: "com_ar_ss_ord_" + UUID().uuidString,
                            order: order.count + 1,
                            serviceStopId: stop.id,
                            recurringServiceStopId: stop.recurringServiceStopId
                        )
                    )
                    orderedStopIds.insert(stop.id)
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

    private static func resolvedRecurringServiceStopId(
        order: ServiceStopOrder,
        stop: ServiceStop
    ) -> String {
        order.recurringServiceStopId.isEmpty
            ? stop.recurringServiceStopId
            : order.recurringServiceStopId
    }
}

struct RouteAutoOrderBuilder {
    static func order(
        serviceStops: [ServiceStop],
        activeRoute: ActiveRoute?,
        currentLocation: CLLocation?
    ) -> [ServiceStop] {
        guard serviceStops.count > 1 else { return serviceStops }

        let routeHasStarted = activeRoute.map { $0.status != .didNotStart } ?? false
        let lockedStops = routeHasStarted
            ? serviceStops.filter { $0.operationStatus != .notFinished }
            : []
        let reorderableStops = routeHasStarted
            ? serviceStops.filter { $0.operationStatus == .notFinished }
            : serviceStops

        guard reorderableStops.count > 1 else { return serviceStops }

        let startLocation = currentLocation
            ?? lockedStops.reversed().compactMap(location(for:)).first
            ?? reorderableStops.compactMap(location(for:)).first

        guard let startLocation else { return serviceStops }

        return lockedStops + nearestNeighborOrder(
            stops: reorderableStops,
            startLocation: startLocation
        )
    }

    private static func nearestNeighborOrder(
        stops: [ServiceStop],
        startLocation: CLLocation
    ) -> [ServiceStop] {
        var remaining = stops
        var ordered: [ServiceStop] = []
        var cursor = startLocation

        while !remaining.isEmpty {
            guard let nextIndex = remaining
                .enumerated()
                .filter({ location(for: $0.element) != nil })
                .min(by: { lhs, rhs in
                    let lhsDistance = location(for: lhs.element)?.distance(from: cursor) ?? .greatestFiniteMagnitude
                    let rhsDistance = location(for: rhs.element)?.distance(from: cursor) ?? .greatestFiniteMagnitude

                    if abs(lhsDistance - rhsDistance) < 1 {
                        return lhs.offset < rhs.offset
                    }

                    return lhsDistance < rhsDistance
                })?
                .offset
            else {
                ordered.append(contentsOf: remaining)
                break
            }

            let nextStop = remaining.remove(at: nextIndex)
            ordered.append(nextStop)

            if let nextLocation = location(for: nextStop) {
                cursor = nextLocation
            }
        }

        return ordered
    }

    private static func location(for stop: ServiceStop) -> CLLocation? {
        guard isValidCoordinate(stop.address.coordinates) else { return nil }

        return CLLocation(
            latitude: stop.address.latitude,
            longitude: stop.address.longitude
        )
    }

    private static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite &&
        coordinate.longitude.isFinite &&
        abs(coordinate.latitude) <= 90 &&
        abs(coordinate.longitude) <= 180 &&
        !(coordinate.latitude == 0 && coordinate.longitude == 0)
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
            orderChanged: !ordersMatch(old?.order, new.order),
            statusChanged: old?.status != new.status,
            old: old,
            new: new
        )
    }

    private static func ordersMatch(
        _ lhs: [ServiceStopOrder]?,
        _ rhs: [ServiceStopOrder]?
    ) -> Bool {
        orderSignature(lhs) == orderSignature(rhs)
    }

    private static func orderSignature(_ order: [ServiceStopOrder]?) -> [String] {
        (order ?? [])
            .sorted { $0.order < $1.order }
            .map { "\($0.serviceStopId)|\($0.recurringServiceStopId)" }
    }
}
struct ArRrOrderDiff {
    let active: ActiveRoute
    let recurring: RecurringRoute?
    let isDifferent: Bool
    
}
struct ArRrOrderDiffer {

    static func diff(active: ActiveRoute, recurring: RecurringRoute?) -> ArRrOrderDiff {
        guard let recurring,
              let activeOrder = active.order
        else {
            return ArRrOrderDiff(
                active: active,
                recurring: recurring,
                isDifferent: false
            )
        }

        let activeRecurringIds = recurringIdsInActiveOrder(
            active: activeOrder,
            recurring: recurring.order
        )
        let defaultRecurringIds = recurringIdsInDefaultOrder(
            active: activeOrder,
            recurring: recurring.order
        )
        let hasComparableRoute = activeRecurringIds.count > 1 && defaultRecurringIds.count > 1

        return ArRrOrderDiff(
            active: active,
            recurring: recurring,
            isDifferent: hasComparableRoute && activeRecurringIds != defaultRecurringIds
        )
    }

    private static func recurringIdsInActiveOrder(
        active: [ServiceStopOrder],
        recurring: [recurringRouteOrder]
    ) -> [String] {
        let recurringIds = Set(
            recurring
                .map(\.recurringServiceStopId)
                .filter { !$0.isEmpty }
        )
        var seenIds = Set<String>()

        return active
            .sorted { $0.order < $1.order }
            .compactMap { item in
                let id = item.recurringServiceStopId
                guard !id.isEmpty,
                      recurringIds.contains(id),
                      !seenIds.contains(id)
                else {
                    return nil
                }

                seenIds.insert(id)
                return id
            }
    }

    private static func recurringIdsInDefaultOrder(
        active: [ServiceStopOrder],
        recurring: [recurringRouteOrder]
    ) -> [String] {
        let activeRecurringIds = Set(
            active
                .map(\.recurringServiceStopId)
                .filter { !$0.isEmpty }
        )
        var seenIds = Set<String>()

        return recurring
            .sorted { $0.order < $1.order }
            .compactMap { item in
                let id = item.recurringServiceStopId
                guard !id.isEmpty,
                      activeRecurringIds.contains(id),
                      !seenIds.contains(id)
                else {
                    return nil
                }

                seenIds.insert(id)
                return id
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
            if workingActiveRoute.endMilage != nil && workingActiveRoute.endTime != nil {
                workingActiveRoute.status = .finished
            } else {
                workingActiveRoute.status = .inProgress
            }
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
                
                let routeHasCloseout = workingActiveRoute.endMilage != nil && workingActiveRoute.endTime != nil
                let nextStatus: ActiveRouteStatus = routeHasCloseout ? .finished : .inProgress
                
                if workingActiveRoute.status != nextStatus{
                    
                    print("Updating Active Route Status")
                    
                    dataService.updateActiveRouteStatus(companyId: companyId, activeRouteId: workingActiveRoute.id, status: nextStatus)
                    
                }
                
                if !routeHasCloseout {
                    
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
