//
//  RouteBoardViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//
//  Functions In Page
//  -------------------
//  ---RouteBoardViewModel---
//  start
//  stopListeners
//  route
//  stops
//  stop
//  reconcileRoutesWithStops [private]
//  checkForRouteOnDayAndTech
//  submitOrUpdateRoute
//  createNewRoute [private]
//  updateCurrentRoute [private]
//  onDismissOfCustomerPicker
//  removeRecurringstops
//  createNewRecurringRouteWithVerification [private]
//  modifyRecurringRouteWithVerification [private]
//  checkRecurringServiceStopListAndOrderListAreSame [private]
//  deleteRecurringRoute
//  deleteRecurringServiceStop
//  deleteRoute [private]

import Foundation

@MainActor
final class RouteBoardViewModel: ObservableObject {

    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var recurringRoutes: [RecurringRoute] = []
    @Published private(set) var recurringStops: [RecurringServiceStop] = []
    
    @Published var isInitialLoading: Bool = false
    @Published var isLoading: Bool = false

    //Alerts
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = "Error"
    
    //For editing
    @Published var selectedRoute: RecurringRoute? = nil
    @Published var selectedRecurringServiceStop: RecurringServiceStop? = nil

    @Published var editRoute: Bool = false
    @Published var editRecurringServiceStop: Bool = false
    
    @Published var showReassignRoute: Bool = false
    @Published var showModifyRoute: Bool = false
    @Published var showDelete: Bool = false
    @Published var selectedDay: DaysOfWeek? = nil
    @Published var selectedTech: CompanyUser? = nil

    @Published var showDeleteRSS: Bool = false
    @Published var showModifyRSS: Bool = false
    
    //For New Route
    @Published private(set) var currentRouteRecurringStops: [RecurringServiceStop] = []
    @Published private(set) var currentSelectedRoute: RecurringRoute? = nil
    @Published var newRouteRecurringStops: [RecurringServiceStop] = []
    @Published var newSelectedRoute: RecurringRoute? = nil
    @Published var showCustomerPicker: Bool = false
    
    @Published var newSelectedDay: DaysOfWeek = .monday

    @Published var description:String = ""
    @Published var startDate:Date = Date()
    @Published var endDate:Date = Date()
    
    @Published var noEndDate:Bool = true
    @Published var standardFrequencyType:LaborContractFrequency = .weekly
    @Published var customEvery:Int = 1
    @Published var showCustomerSheet:Bool = false
    @Published var newSelectedTech:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor)

    @Published var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        active: false,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var location:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "Location",
        address: Address(streetAddress: "",
                         city: "",
                         state: "",
                         zip: "0",
                         latitude: 0,
                         longitude: 0),
        gateCode: "",
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false,
        isActive: true
    )
    
    
    let dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    func start(companyId: String?) {
            self.isInitialLoading = true
            guard let companyId else {return}
            print("")
            print("---------------[RouteBoardViewModel][start][companyId]---------------")
            dataService.addCompanyUserListener(companyId: companyId, status: "Active",
            ) { [weak self] route in
                Task { @MainActor in
                    self?.companyUsers = route
                }
            }
                //RecurringRoutes
            dataService.addListenerForRecurringRoute(
                companyId: companyId,
            ) { [weak self] route in
                Task { @MainActor in
                    
                    self?.recurringRoutes = route
                    self?.reconcileRoutesWithStops()
                }
            }
                //Recurring Stops
            dataService.addListenerForRecurringServiceStop(
                companyId: companyId,
            ) { [weak self] stops in
                Task { @MainActor in
                    
                    self?.recurringStops = stops
                    self?.reconcileRoutesWithStops()
                }
            }
            self.isInitialLoading = false
        
    }

    func stopListeners() {
        dataService.removeRecurringRouteListener()
        dataService.removeRecurringServiceStopListener()
        dataService.removeCompanyUserListener()
    }
    
    func forceRecompute(companyId: String?) {
    }
    func route(for techId: String, day: DaysOfWeek) -> RecurringRoute? {
        recurringRoutes.first {
            $0.techId == techId && $0.day == day
        }
    }

    func stops(for techId: String, day: DaysOfWeek) -> [RecurringServiceStop] {
        recurringStops.filter {
            $0.techId == techId && $0.day == day
        }
    }
    func stop(for recurringServiceStopId: String) -> RecurringServiceStop? {
        recurringStops.first(where: {$0.id == recurringServiceStopId})

    }
    private func reconcileRoutesWithStops() {
        print("    [RouteBoardViewModel][reconcileRoutesWithStops] Current Route : \(recurringRoutes.count)")
        print("    [RouteBoardViewModel][reconcileRoutesWithStops] Current Recurring Service Stops: \(recurringStops.count)")
    }
    func onLoad(day:DaysOfWeek, techId:String?) {
        if let techId {
            checkForRouteOnDayAndTech(techId: techId, day: day)
            if let first = companyUsers.first(where: {$0.id == techId}) {
                self.newSelectedTech = first
            } else {
                if !companyUsers.isEmpty {
                    self.newSelectedTech = companyUsers.first!
                    checkForRouteOnDayAndTech(techId: newSelectedTech.id, day: day)
                }
            }
        } else {
            if !companyUsers.isEmpty {
                self.newSelectedTech = companyUsers.first!
                checkForRouteOnDayAndTech(techId: newSelectedTech.id, day: day)
            }
        }
    }
    func checkForRouteOnDayAndTech(techId:String, day:DaysOfWeek){
        //Check to see if it exists
        print("  [RouteBoardViewModel][checkForRouteOnDayAndTech] techId: \(techId) & day: \(day.rawValue)")
        print("  [RouteBoardViewModel][checkForRouteOnDayAndTech] recurringStops: \(recurringStops.count)")
        print("  [RouteBoardViewModel][checkForRouteOnDayAndTech] recurringRoutes \(recurringRoutes.count)")
        for stop in recurringStops {
            print("\(stop.id) \(stop.day) \(stop.day.rawValue) \(stop.techId)")
        }
        self.currentRouteRecurringStops = recurringStops.filter({$0.techId == techId && $0.day == day})
        self.currentSelectedRoute = recurringRoutes.first(where: {$0.techId == techId && $0.day == day})

        print("")
        print("  RouteBoardViewModel][checkForRouteOnDayAndTech]  recurringStops")
        for stop in recurringStops {
            print("-")
            print(stop)
            
        }
        print("")
//        print(currentRouteRecurringStops)
//        print("")
//        print("  RouteBoardViewModel][checkForRouteOnDayAndTech]  recurringRoutes")
//        print(recurringRoutes)
//        print("")
//        print(currentSelectedRoute)
//        print("")
        print("  [RouteBoardViewModel][checkForRouteOnDayAndTech] currentRouteRecurringStops: \(currentRouteRecurringStops.count), currentSelectedRoute: \(currentSelectedRoute?.id ?? "nil")")
        //Update Modifyable varables
        self.newRouteRecurringStops = currentRouteRecurringStops
        self.newSelectedRoute = currentSelectedRoute
        
        //Update Form to match received Variables
        self.newSelectedDay = day

    }
    func submitOrUpdateRoute(companyId:String?){
        guard let companyId else {return}
        
        self.isLoading = true
        if currentSelectedRoute == nil && currentRouteRecurringStops.isEmpty{
            print("  [RouteBoardViewModel][submitOrUpdateRoute]Creating New Route")
            createNewRoute(companyId: companyId)
        } else {
            print("  [RouteBoardViewModel][submitOrUpdateRoute] Modifying Route")
            updateCurrentRoute(companyId: companyId)
        }
    }
    
    private func createNewRoute(companyId:String){
        if newSelectedTech.id == "" {return}
        Task{
            do {
                try await createNewRecurringRouteWithVerification(
                    companyId: companyId,
                    tech: newSelectedTech,
                    recurringStopsList: newRouteRecurringStops,
                    noEndDate: noEndDate,
                    description: description,
                    day: newSelectedDay,
                    standardFrequencyType: standardFrequencyType,
                    customFrequencyType: customEvery,
                    startDate: startDate,
                    endDate: endDate,
                )
                self.isLoading = false
                self.alertMessage = "Success"
                print(alertMessage)
                self.showAlert = true
                
            } catch {
                print("      [NewRouteViewModel][createNewRoute] Error \(error)")
            }
        }
    }
    private func updateCurrentRoute(companyId:String){
        guard let newSelectedRoute else {return}
        guard let currentSelectedRoute else {return}
        Task{
            do {
                try await modifyRecurringRouteWithVerification(
                    companyId: companyId,
                    tech: newSelectedTech,
                    noEndDate: noEndDate,
                    day: newSelectedDay,
                    frequency: standardFrequencyType,
                    perTimes: customEvery,
                    transitionDate: startDate,
                    newEndDate: endDate,
                    description: description,
                    newList: newRouteRecurringStops,
                    oldList: currentRouteRecurringStops,
                    newRoute: newSelectedRoute,
                    oldRoute: currentSelectedRoute
                )
                
                self.isLoading = false
                self.alertMessage = "Success"
                print(alertMessage)
                self.showAlert = true
            } catch {
                print("      [NewRouteViewModel][updateCurrentRoute] Error \(error)")
            }
        }
    }
    func onDismissOfCustomerPicker() {

        if location.id == "" {return}
        if customer.id == "" {return}
        let techFullName = (newSelectedTech.userName)
        print("    [NewRouteViewModel][onDismissOfCustomerPicker] Location Id: \(location.id) Customer Id: \(customer.id ) techFullName: \(techFullName)")
        let fallbackTypeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: .recurringRoute
        )

        self.newRouteRecurringStops.append(
            RecurringServiceStop(id: UUID().uuidString,
                                 internalId: "", //DEVELOPER
                                 type: fallbackTypeFields.type,
                                 typeId: fallbackTypeFields.typeId,
                                 typeImage: fallbackTypeFields.typeImage,
                                 customerName: location.customerName,
                                 customerId: location.customerId,
                                 address: location.address,
                                 tech: techFullName,
                                 techId: newSelectedTech.userId,
                                 dateCreated: Date(),
                                 startDate: startDate,
                                 endDate: endDate,
                                 noEndDate: noEndDate,
                                 frequency: standardFrequencyType,
                                 day: newSelectedDay,
                                 description: description,
                                 lastCreated: Date(),
                                 serviceLocationId: location.id,
                                 estimatedTime: location.estimatedTime ?? 15, //Min
                                 otherCompany: false,
                                 laborContractId: "",
                                 contractedCompanyId: "")
        )
        print("  [NewRouteViewModel][onDismissOfCustomerPicker] Stops Count : \(newRouteRecurringStops.count) ")

        customer.id = ""
        location.id = ""
    }
    func removeRecurringstops(at offsets: IndexSet) {
        newRouteRecurringStops.remove(atOffsets: offsets)
    }

    private func createNewRecurringRouteWithVerification(
        companyId: String,
        tech:CompanyUser,
        recurringStopsList:[RecurringServiceStop],
        noEndDate:Bool,
        description:String,
        day:DaysOfWeek,
        standardFrequencyType:LaborContractFrequency,
        customFrequencyType:Int,
        startDate:Date,
        endDate:Date,
    ) async throws {

            //Create a new recurring Route
        let techFullName = tech.userName
        
        print("    [RouteBoardViewModel][createNewRecurringRouteWithVerification] Creating Route with \(recurringStopsList.count) stops for \(techFullName) - \(day)")
        var binder:[recurringRouteOrder] = []
        var count:Int = 1
        let routeTypeFields = await dataService.resolvedServiceStopTypeFields(
            companyId: companyId,
            useCase: .recurringRoute,
            context: "RouteBoardViewModel.createNewRecurringRouteWithVerification"
        )
        for RSS in recurringStopsList {
            let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)

            print("    [RouteBoardViewModel][createNewRecurringRouteWithVerification] Creating Recurring Service Stop Id >>  \(RSS.id) - \(RSS.customerName) - \(RSS.frequency)")
            let shouldResolveRouteType = RSS.typeId.isBlank ||
                RSS.typeId == PayrollSystemSourceIds.recurringServiceStop ||
                RSS.typeId == PayrollSystemSourceIds.jobServiceStop ||
                RSS.typeId == PayrollSystemSourceIds.unknownServiceStop
            let typeFields: ServiceStopTypeFields
            if shouldResolveRouteType {
                typeFields = routeTypeFields
            } else {
                typeFields = ServiceStopTypeFields(
                    typeId: RSS.typeId,
                    type: RSS.type,
                    typeImage: RSS.typeImage
                )
            }
            let rssId = try await dataService.addNewRecurringServiceStop(
                companyId: companyId,
                recurringServiceStop: RecurringServiceStop(
                    id: "com_rss_" + UUID().uuidString,
                    internalId: "RSS" + String(rssCount),
                    type: typeFields.type,
                    typeId: typeFields.typeId,
                    typeImage: typeFields.typeImage,
                    customerName: RSS.customerName,
                    customerId: RSS.customerId,
                    address: RSS.address,
                    tech: techFullName,
                    techId: tech.userId,
                    dateCreated: Date(),
                    startDate: startDate,
                    endDate: endDate,
                    noEndDate: noEndDate,
                    frequency: standardFrequencyType,
                    day: day,
                    description: description,
                    lastCreated: Date(),
                    serviceLocationId: RSS.serviceLocationId,
                    estimatedTime: RSS.estimatedTime,
                    otherCompany: RSS.otherCompany,
                    laborContractId: RSS.laborContractId,
                    contractedCompanyId: RSS.contractedCompanyId
                )
            )
            guard let rssId else {
                print("    [RouteBoardViewModel][createNewRecurringRouteWithVerification] Rss Id failure")
                return
                
            }
            let order = count
            count = count + 1
            let page = recurringRouteOrder(
                id: UUID().uuidString,
                order: order,
                recurringServiceStopId: rssId,
                customerId: RSS.customerId,
                customerName: RSS.customerName,
                locationId: RSS.serviceLocationId
            )
            binder.append(page)
        }
//            let recurringRouteId = day + tech.userId // DEVELOPER
        let recurringRouteId = UUID().uuidString
        print("    [RouteBoardViewModel][createNewRecurringRouteWithVerification] Uploading Recurring Route Id >> \(recurringRouteId)")
        let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.userId, day: day, order: binder, description: "")
        try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
    
    }
    
    private func modifyRecurringRouteWithVerification(
        companyId: String,
        tech:CompanyUser,
        noEndDate:Bool,
        day:DaysOfWeek,
        frequency:LaborContractFrequency,
        perTimes:Int,
        transitionDate:Date,
        newEndDate:Date,
        description:String,
        newList:[RecurringServiceStop],
        oldList:[RecurringServiceStop],
        newRoute:RecurringRoute,
        oldRoute:RecurringRoute
    ) async throws {
        //Update the Curring Recurring route

        var routeListChanged: Bool = false
        var EndDateChanged: Bool = false
        print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] Updating Existing Recurring Route For \(oldRoute.tech) - \(oldRoute.day)")
        //Handle Day / Tech Change in Reassign Route
        
        //Check if each reecurring service stop is in the recurring route.
        if checkRecurringServiceStopListAndOrderListAreSame(recurringServiceStops: newList, order: newRoute.order) {
            print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] No Changes in Recurring Service Stops List Have Been Made")
            routeListChanged = false
        } else {
            print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] Changes to Recurring Service Stop List Have been Made")
            routeListChanged = true
            //Update RecurringService Stops and Order list
            let result = diffStops(old: oldList, new: newList, key: { $0.id })
            print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] Recurring Service Stops List Changes:")
            print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] Added: \(result.added)")
            print("      [RouteBoardViewModel][createNewRecurringRouteWithVerification] Removed: \(result.removed)")
            for RSS in result.added {
                let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)

                print("    [RouteBoardViewModel][createNewRecurringRouteWithVerification] Creating Recurring Service Stop Id >>  \(RSS.id) - \(RSS.customerName) - \(RSS.frequency)")
                var pushRSS = RSS
                pushRSS.internalId = "RSS" + String(rssCount)
                let rssId = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: pushRSS
                )
            }
            for RSS in result.removed {
                try await FunctionsManager.shared.deleteRecurringServiceStop(companyId: companyId,stopId: RSS.id)
            }
            #warning("Need to do Delete of Recurring Service Stops")
        }
        // Checks End Date
        // Add End Date TO Recurring Route
        // Make updates
        
    }
    struct DiffRecurringServiceStops<T> {
        let added: [T]
        let removed: [T]
    }

    func diffStops(
        old: [RecurringServiceStop],
        new: [RecurringServiceStop],
        key: (RecurringServiceStop) -> String
    ) -> DiffRecurringServiceStops<RecurringServiceStop> {
        let oldByKey = Dictionary(uniqueKeysWithValues: old.map { (key($0), $0) })
        let newByKey = Dictionary(uniqueKeysWithValues: new.map { (key($0), $0) })

        let oldKeys = Set(oldByKey.keys)
        let newKeys = Set(newByKey.keys)

        let addedKeys = newKeys.subtracting(oldKeys)
        let removedKeys = oldKeys.subtracting(newKeys)

        let added = addedKeys.compactMap { newByKey[$0] }
        let removed = removedKeys.compactMap { oldByKey[$0] }

        return DiffRecurringServiceStops(added: added, removed: removed)
    }
    private func checkRecurringServiceStopListAndOrderListAreSame(recurringServiceStops:[RecurringServiceStop],order:[recurringRouteOrder])-> Bool {
        for RSS in recurringServiceStops {
            //Check Each Recurring Stop To make Sure all are in the order list
            if !order.contains(where: {$0.recurringServiceStopId == RSS.id}){
                return false
            }
        }
        for recurringRouteOrder in order {
            //Check Each Recurring Stop To make Sure all are in the order list
            if !recurringServiceStops.contains(where: {$0.id == recurringRouteOrder.recurringServiceStopId}){
                return false
            }
        }
        return true
    }
    func deleteRecurringRoute(companyId:String?) {
        guard let companyId else {return}
        guard let selectedTech else {return}
        guard let selectedRoute else {return}
        
        if !isLoading {
            self.isLoading = true
            Task{
                do {
                    try await self.deleteRoute(
                        companyId: companyId,
                        transitionDate: Date(),
                        route: selectedRoute
                    )
                } catch {
                    print("[][] Error \(error)")
                }
            }
            self.isLoading = false
        }
    }
    func deleteRecurringServiceStop(companyId:String?) {
        guard let companyId else {return}
        guard let selectedRecurringServiceStop else {return}
        if !isLoading {
            self.isLoading = true
            Task{
                do {
//                    try await self.deleteRecurringServiceStop(
//                        companyId: companyId,
//                        transitionDate: Date(),
//                        rss: selectedRecurringServiceStop
//                    )
                    try await FunctionsManager.shared.deleteRecurringServiceStop(companyId: companyId, stopId: selectedRecurringServiceStop.id)
                } catch {
                    print("[][] Error \(error)")
                }
            }
            self.isLoading = false
        }
    }
    private func deleteRoute(
        companyId: String,
        transitionDate:Date,
        route:RecurringRoute,
    ) async throws {
        //DEVELOPER I COULD TRY AND UPDATE RATHER THAN DELETE AND CREATE NEW
        print("    [NewRouteViewModel][modifyRecurringRouteWithVerification] End Recurring Route")
        try await dataService.endRecurringRoute(companyId: companyId, recurringRouteId: route.id, endDate: transitionDate)
        print("    [NewRouteViewModel][modifyRecurringRouteWithVerification] Make Sure to End All Recurring Service Stops After End Date")
        
        //End Each Recurring Service Stop
        for recurringStopOrder in route.order {
            
            let RSS = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId)
            
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, endDate: transitionDate)
            
            //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
            //DEVELOPER Make sure to add starting new Recurring route after new transition
            let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, date: transitionDate)
            
            // Delete Each Service Stop under Recurring Service Stop
            for stop in serviceStopList {
                try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
            }
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
        }
        
        //Create New Recurring Route
        //Maybe I change up this so it just updates instead of Deletes and redos.
        
        print("    [NewRouteViewModel][modifyRecurringRouteWithVerification] Developer Error")
        
//        try await modifyRecurringRouteHelperFunction(companyId: companyId, tech: tech, recurringStopsList: recurringStopList, job: jobTemplate, noEndDate: noEndDate, description: description, day: day, standardFrequencyType: standardFrequencyType, customFrequencyType: customFrequencyType, customFrequencyNumber: customFrequencyNumber, startDate: transitionDate, endDate: newEndDate, currentRecurringRoute: nil)
    }
    private func deleteRecurringServiceStop(
        companyId: String,
        transitionDate:Date,
        rss:RecurringServiceStop,
    ) async throws {
        
        try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: rss.id, endDate: transitionDate)
        
        //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
        //DEVELOPER Make sure to add starting new Recurring route after new transition
        let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: companyId, recurringServiceStopId: rss.id, date: transitionDate)
        
        // Delete Each Service Stop under Recurring Service Stop
        for stop in serviceStopList {
            try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
        }
        try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: rss.id, endDate: transitionDate)
  
    }
    func addRecurringStopSelectionToNewRoute(
        selection: RouteRecurringStopSelection
    ) {
        print("  [RouteBoardViewModel][addRecurringStopSelectionToNewRoute] Adding Recurring Service Stop to New Route")
        customer = selection.customer
        location = selection.location
        
            print("  [RouteBoardViewModel][addRecurringStopSelectionToNewRoute] 1")
        let recurringStop = RecurringServiceStop(
            id: "comp_rss_" + UUID().uuidString,
            internalId: "",
            type: selection.typeFields.type,
            typeId: selection.typeFields.typeId,
            typeImage: selection.typeFields.typeImage,
            customerName: resolvedCustomerName(selection.customer),
            customerId: selection.customer.id,
            address: selection.location.address,
            tech: newSelectedTech.userName,
            techId: newSelectedTech.userId,
            dateCreated: Date(),
            startDate: startDate,
            endDate: noEndDate ? nil : endDate,
            noEndDate: noEndDate,
            frequency: standardFrequencyType,
            day: newSelectedDay,
            description: description,
            lastCreated: Date(),
            serviceLocationId: selection.location.id,
            estimatedTime: selection.location.estimatedTime ?? 15,
            otherCompany: false
        )
        
        print("  [RouteBoardViewModel][addRecurringStopSelectionToNewRoute] before newRouteRecurringStops \(newRouteRecurringStops.count)")
        self.newRouteRecurringStops.append(recurringStop)
        print("  [RouteBoardViewModel][addRecurringStopSelectionToNewRoute] after newRouteRecurringStops \(newRouteRecurringStops.count)")
        
        print("  [RouteBoardViewModel][addRecurringStopSelectionToNewRoute] 3")
 
    }
    private func resolvedCustomerName(_ customer: Customer) -> String {
        if customer.displayAsCompany {
            return customer.company ?? "Company Name"
        }

        return "\(customer.firstName) \(customer.lastName)"
    }
}
