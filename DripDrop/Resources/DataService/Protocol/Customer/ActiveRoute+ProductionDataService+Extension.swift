    //
    //  ActiveRoute+ProductionDataService+Extension.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/3/24.
    //

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
struct ActiveRoute:Identifiable, Codable,Equatable{
    
    var id :String
    var name: String
    var date : Date
    var serviceStopsIds : [String]
    var order : [ServiceStopOrder]?
    var startTime : Date?
    var endTime : Date?
    var startMilage: Double?
    var endMilage: Double?
    var techId : String
    var techName : String

    var traineeId : String?
    var traineeName : String?

    var durationMin : Int
    var distanceMiles : Double
    var status : ActiveRouteStatus
    var totalStops : Int
    var finishedStops : Int
    
    var vehicalId: String
    var vehicleSource: String?
    var personalVehicleOwnerId: String?
    var vehicleLabel: String?
    var vehiclePlate: String?
    var vehicleKind: String?
    var vehicleMake: String?
    var vehicleModel: String?
    var personalVehicle: PersonalVehicle?
    init(
        id: String,
        name :String,
        date : Date,

        serviceStopsIds : [String],
        order : [ServiceStopOrder]? = nil,

        startTime: Date? = nil,
        endTime: Date? = nil,
        startMilage : Double? = nil,
        endMilage : Double? = nil,
        techId: String,
        techName: String,

        traineeId: String? = nil,
        traineeName: String? = nil,

        durationMin: Int,
        distanceMiles: Double,
        status: ActiveRouteStatus,
        totalStops: Int,
        finishedStops: Int,
        vehicalId: String,
        vehicleSource: String? = nil,
        personalVehicleOwnerId: String? = nil,
        vehicleLabel: String? = nil,
        vehiclePlate: String? = nil,
        vehicleKind: String? = nil,
        vehicleMake: String? = nil,
        vehicleModel: String? = nil,
        personalVehicle: PersonalVehicle? = nil
    ){
        self.id = id
        self.name = name
        self.date = date
        self.startMilage = startMilage
        self.endMilage = endMilage

        self.serviceStopsIds = serviceStopsIds
        self.order = order

        self.startTime = startTime
        self.endTime = endTime
        self.techId = techId
        self.techName = techName
        self.traineeId = traineeId
        self.traineeName = traineeName
        self.durationMin = durationMin
        self.distanceMiles = distanceMiles
        self.status = status
        self.totalStops = totalStops
        self.finishedStops = finishedStops
        
        self.vehicalId = vehicalId
        self.vehicleSource = vehicleSource
        self.personalVehicleOwnerId = personalVehicleOwnerId
        self.vehicleLabel = vehicleLabel
        self.vehiclePlate = vehiclePlate
        self.vehicleKind = vehicleKind
        self.vehicleMake = vehicleMake
        self.vehicleModel = vehicleModel
        self.personalVehicle = personalVehicle
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"
            case date = "date"
            case startMilage = "startMilage"
            case endMilage = "endMilage"
            case serviceStopsIds = "serviceStopsIds"
            case order = "order"
            case startTime = "startTime"
            case endTime = "endTime"
            case techId = "techId"
            case techName = "techName"
            case traineeId = "traineeId"
            case traineeName = "traineeName"
            case durationMin = "durationSeconds"
            case distanceMiles = "distanceMiles"
            case status = "status"
            case finishedStops = "finishedStops"
            case totalStops = "totalStops"
            case vehicalId = "vehicalId"
            case vehicleSource = "vehicleSource"
            case personalVehicleOwnerId = "personalVehicleOwnerId"
            case vehicleLabel = "vehicleLabel"
            case vehiclePlate = "vehiclePlate"
            case vehicleKind = "vehicleKind"
            case vehicleMake = "vehicleMake"
            case vehicleModel = "vehicleModel"
            case personalVehicle = "personalVehicle"
        }
    static func == (lhs: ActiveRoute, rhs: ActiveRoute) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.date == rhs.date &&
        lhs.serviceStopsIds == rhs.serviceStopsIds &&
        lhs.startTime == rhs.startTime &&
        lhs.endTime == rhs.endTime &&
        lhs.techId == rhs.techId
    }
}

extension ProductionDataService {
        //Doucments and Collections
    func ActiveRouteCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/activeRoutes")
    }
    
    func ActiveRouteLocationCollection(companyId:String,activeRouteId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/activeRouteLocations")
    }
    func ActiveRouteLogCollection(companyId:String,activeRouteId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/activeRouteLogs")
    }
    func ActiveRouteDocument(companyId:String,activeRouteId:String)-> DocumentReference{
        ActiveRouteCollection(companyId: companyId).document(activeRouteId)
    }
    func activeRouteLocationDocument(companyId:String,activeRouteId:String,locationId:String)-> DocumentReference{
        ActiveRouteLocationCollection(companyId: companyId, activeRouteId: activeRouteId).document(locationId)
    }
    func activeRouteLogDocument(companyId:String,activeRouteId:String,logId:String)-> DocumentReference{
        ActiveRouteLogCollection(companyId: companyId, activeRouteId: activeRouteId).document(logId)
    }
        //
        //CREATE
    private func activeRouteStableDocumentId(date: Date, techId: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"

        let safeTechId = techId.replacingOccurrences(of: "/", with: "_")
        return "com_ar_\(formatter.string(from: date.startOfDay()))_\(safeTechId)"
    }

    private func canonicalActiveRoute(from routes: [ActiveRoute]) -> ActiveRoute? {
        routes.sorted { lhs, rhs in
            let lhsHasWork = lhs.startTime != nil || lhs.endTime != nil || lhs.status != .didNotStart
            let rhsHasWork = rhs.startTime != nil || rhs.endTime != nil || rhs.status != .didNotStart

            if lhsHasWork != rhsHasWork {
                return lhsHasWork
            }

            if lhs.serviceStopsIds.count != rhs.serviceStopsIds.count {
                return lhs.serviceStopsIds.count > rhs.serviceStopsIds.count
            }

            return lhs.id < rhs.id
        }
        .first
    }

    private func getActiveRoutesForDateAndTech(
        companyId: String,
        date: Date,
        techId: String
    ) async throws -> [ActiveRoute] {
        try await ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: techId)
            .getDocuments(as: ActiveRoute.self)
    }

    private func routeStatus(
        existingRoute: ActiveRoute?,
        totalStops: Int,
        finishedStops: Int
    ) -> ActiveRouteStatus {
        if totalStops > 0 && totalStops == finishedStops {
            if existingRoute?.endMilage != nil && existingRoute?.endTime != nil {
                return .finished
            }

            if let existingRoute,
               existingRoute.status == .traveling ||
                existingRoute.status == .onBreak {
                return existingRoute.status
            }

            return .inProgress
        }

        if let existingRoute,
           existingRoute.status == .inProgress ||
            existingRoute.status == .traveling ||
            existingRoute.status == .onBreak {
            return existingRoute.status
        }

        return finishedStops > 0 ? .inProgress : .didNotStart
    }

    private func reconcileDuplicateActiveRoutes(
        companyId: String,
        routes: [ActiveRoute],
        primaryRouteId: String
    ) async {
        for route in routes where route.id != primaryRouteId {
            do {
                try await ActiveRouteDocument(companyId: companyId, activeRouteId: route.id)
                    .updateData([
                        "duplicateOf": primaryRouteId,
                        ActiveRoute.CodingKeys.serviceStopsIds.rawValue: [],
                        ActiveRoute.CodingKeys.order.rawValue: [],
                        ActiveRoute.CodingKeys.totalStops.rawValue: 0,
                        ActiveRoute.CodingKeys.finishedStops.rawValue: 0
                    ])
            } catch {
                print("[ProductionDataService][reconcileDuplicateActiveRoutes] Error: \(error)")
            }
        }
    }

    func uploadRoute(companyId: String,activeRoute:ActiveRoute) async throws -> ActiveRoute {
        let existingRoutes = try await getActiveRoutesForDateAndTech(
            companyId: companyId,
            date: activeRoute.date,
            techId: activeRoute.techId
        )

        let existingRoute = canonicalActiveRoute(from: existingRoutes)
        var routeToSave = activeRoute
        routeToSave.id = existingRoute?.id ?? activeRouteStableDocumentId(
            date: activeRoute.date,
            techId: activeRoute.techId
        )
        routeToSave.date = activeRoute.date.startOfDay()

        if let existingRoute {
            routeToSave.name = existingRoute.name.isEmpty ? activeRoute.name : existingRoute.name
            routeToSave.startTime = existingRoute.startTime
            routeToSave.endTime = existingRoute.endTime
            routeToSave.startMilage = existingRoute.startMilage
            routeToSave.endMilage = existingRoute.endMilage
            routeToSave.vehicalId = existingRoute.vehicalId
            routeToSave.vehicleSource = existingRoute.vehicleSource
            routeToSave.personalVehicleOwnerId = existingRoute.personalVehicleOwnerId
            routeToSave.vehicleLabel = existingRoute.vehicleLabel
            routeToSave.vehiclePlate = existingRoute.vehiclePlate
            routeToSave.vehicleKind = existingRoute.vehicleKind
            routeToSave.vehicleMake = existingRoute.vehicleMake
            routeToSave.vehicleModel = existingRoute.vehicleModel
            routeToSave.personalVehicle = existingRoute.personalVehicle
            routeToSave.status = routeStatus(
                existingRoute: existingRoute,
                totalStops: activeRoute.totalStops,
                finishedStops: activeRoute.finishedStops
            )
        }

        try ActiveRouteDocument(companyId: companyId, activeRouteId: routeToSave.id)
            .setData(from: routeToSave, merge: true)

        await reconcileDuplicateActiveRoutes(
            companyId: companyId,
            routes: existingRoutes,
            primaryRouteId: routeToSave.id
        )

        return routeToSave
    }
    func upLoadActiveRouteLocation(companyId:String,activeRouteId:String,location: ActiveRouteLocation) async throws {
        try ActiveRouteLocationCollection(companyId: companyId, activeRouteId: activeRouteId).document(location.id).setData(from:location, merge: false)
    }
    func upLoadActiveRouteLog(companyId:String,activeRouteId:String, log: ActiveRouteLog) async throws {
        try ActiveRouteLogCollection(companyId: companyId, activeRouteId: activeRouteId).document(log.id).setData(from:log, merge: false)

    }
        //READ
    func getRecentActiveRouteForTech(companyId: String,techId:String,days:Int) async throws -> [ActiveRoute] {
        @State var startDate: Date = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

       let routes = try await  ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThan: startDate.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: Date().startOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: techId)
            .getDocuments(as: ActiveRoute.self)
        return routes
    }
    func getActiveRoute(companyId: String, activeRouteId: String) async throws -> ActiveRoute {
        return try await ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
            .getDocument(as: ActiveRoute.self)
    }
    
    
    func getAllActiveRoutesBasedOnVehical(companyId: String, vehicalId:String, count: Int) async throws -> [ActiveRoute] {
        return try await  ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.vehicalId.rawValue, isEqualTo: vehicalId)
            .limit(to: count)
            .order(by: ActiveRoute.CodingKeys.date.rawValue, descending: true)
            .getDocuments(as: ActiveRoute.self)
    }
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:DBUser) async throws -> [ActiveRoute] {
            //MEMORY LEAK
        print("Date - \(date) - Route Manager : getAllActiveRoutesBasedOnDate ")
        return try await  ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .getDocuments(as: ActiveRoute.self)
            //        return []
    }
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ActiveRoute] {
            //MEMORY LEAK
        print("Date - \(date) - Route Manager : getAllActiveRoutesBasedOnDate ")
        return try await  ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: tech.userId)
            .getDocuments(as: ActiveRoute.self)
    }
        //UPDATE
    func updateRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws {
        try await ActiveRouteDocument(companyId: companyId, activeRouteId: activeRoute.id)
            .updateData([
                ActiveRoute.CodingKeys.serviceStopsIds.rawValue:FieldValue.arrayUnion([serviceStopId])
            ])
        
    }
    func removeRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws{
        try await ActiveRouteDocument(companyId: companyId, activeRouteId: activeRoute.id)
            .updateData([
                ActiveRoute.CodingKeys.serviceStopsIds.rawValue:FieldValue.arrayRemove([serviceStopId])
            ])
    }
    func updateActiveRouteOrderList(companyId:String,activeRouteId:String,serviceStopOrderList:[ServiceStopOrder]) async throws {
        //Replaced order with new order
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        var orderArray:[[String:Any]] = []
        //Convert to JSON
        for order in serviceStopOrderList {
            let data:[String:Any] = [
                "id": order.id,
                "order": order.order,
                "recurringServiceStopId":order.recurringServiceStopId,
                "serviceStopId": order.serviceStopId,
            ]
            orderArray.append(data)
        }
        try await ref.updateData(["order":orderArray])
        
    }
    func updateActiveRouteName(companyId:String,activeRouteId:String,name:String){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.name.rawValue: name
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteDate(companyId:String,activeRouteId:String,date:Date){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.date.rawValue: date
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteStartTime(companyId:String,activeRouteId:String,startTime:Date){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.startTime.rawValue: startTime
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        print("Updated Start Time \(activeRouteId) - \(fullDateAndTime(date: startTime))")
    }
    func updateActiveRouteEndTime(companyId:String,activeRouteId:String,endTime:Date){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.endTime.rawValue: endTime
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteDuration(companyId:String,activeRouteId:String,duration:Int){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.durationMin.rawValue: duration
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteDistnace(companyId:String,activeRouteId:String,distance:Double){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            ActiveRoute.CodingKeys.distanceMiles.rawValue: distance
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteStatus(companyId:String,activeRouteId:String,status:ActiveRouteStatus){
        Task{
            do {
                let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
                try await ref.updateData([
                    ActiveRoute.CodingKeys.status.rawValue: status.rawValue
                ])
                
            } catch {
                print("[][] Error \(error)")
            }
        }
    }
    func updateActiveRouteStartMilage(companyId:String,activeRouteId:String,startMilage:Double){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.startMilage.rawValue: startMilage
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteEndMilage(companyId:String,activeRouteId:String,endMilage:Double){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.endMilage.rawValue: endMilage
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteFinishedStop(companyId:String,activeRouteId:String,finishedStops:Int){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.finishedStops.rawValue: finishedStops
            
        ]) { err in
            if let err = err {
                print("Error updating Finished Stop \(finishedStops): \(err)")
            } else {
                print("Document successfully updated Active Route to Finished Stops \(finishedStops)")
            }
        }
    }
    func updateActiveRouteTotalStop(companyId:String,activeRouteId:String,totalStops:Int){
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.totalStops.rawValue: totalStops
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteVehicalId(companyId:String,activeRouteId:String,vehicalId:String) {
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.vehicalId.rawValue: vehicalId
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateActiveRouteCompanyFleetVehicle(companyId:String,activeRouteId:String,vehical:Vehical) {
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        let vehicleLabel = "\(vehical.nickName) \(vehical.plate)".trimmingCharacters(in: .whitespacesAndNewlines)
        
        ref.updateData([
            ActiveRoute.CodingKeys.vehicalId.rawValue: vehical.id,
            ActiveRoute.CodingKeys.vehicleSource.rawValue: "Company Fleet",
            ActiveRoute.CodingKeys.personalVehicleOwnerId.rawValue: "",
            ActiveRoute.CodingKeys.vehicleLabel.rawValue: vehicleLabel,
            ActiveRoute.CodingKeys.vehiclePlate.rawValue: vehical.plate,
            ActiveRoute.CodingKeys.vehicleKind.rawValue: vehical.vehicalType.rawValue,
            ActiveRoute.CodingKeys.vehicleMake.rawValue: vehical.make,
            ActiveRoute.CodingKeys.vehicleModel.rawValue: vehical.model,
            ActiveRoute.CodingKeys.personalVehicle.rawValue: FieldValue.delete()
        ]) { err in
            if let err = err {
                print("Error updating active route company fleet vehicle: \(err)")
            } else {
                print("Document successfully updated active route company fleet vehicle")
            }
        }
    }
    
    func updateActiveRoutePersonalVehicle(companyId:String,activeRouteId:String,ownerId:String,personalVehicle:PersonalVehicle) {
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        
        ref.updateData([
            ActiveRoute.CodingKeys.vehicalId.rawValue: "",
            ActiveRoute.CodingKeys.vehicleSource.rawValue: "Personal",
            ActiveRoute.CodingKeys.personalVehicleOwnerId.rawValue: ownerId,
            ActiveRoute.CodingKeys.vehicleLabel.rawValue: personalVehicle.displayName,
            ActiveRoute.CodingKeys.vehiclePlate.rawValue: personalVehicle.plate ?? "",
            ActiveRoute.CodingKeys.vehicleKind.rawValue: personalVehicle.vehicalType ?? "",
            ActiveRoute.CodingKeys.vehicleMake.rawValue: personalVehicle.make ?? "",
            ActiveRoute.CodingKeys.vehicleModel.rawValue: personalVehicle.model ?? "",
            ActiveRoute.CodingKeys.personalVehicle.rawValue: [
                "nickName": personalVehicle.nickName ?? "",
                "vehicalType": personalVehicle.vehicalType ?? "",
                "year": personalVehicle.year ?? "",
                "make": personalVehicle.make ?? "",
                "model": personalVehicle.model ?? "",
                "color": personalVehicle.color ?? "",
                "plate": personalVehicle.plate ?? "",
                "miles": personalVehicle.miles ?? 0
            ]
        ]) { err in
            if let err = err {
                print("Error updating active route personal vehicle: \(err)")
            } else {
                print("Document successfully updated active route personal vehicle")
            }
        }
    }

    @discardableResult
    func syncActiveRouteForServiceStops(
        companyId: String,
        date: Date,
        techId: String,
        techName: String
    ) async throws -> ActiveRoute? {
        let serviceStops = try await getAllServiceStopsByDayAndTech(
            companyId: companyId,
            date: date,
            techId: techId
        )

        let existingRoutes = try await getActiveRoutesForDateAndTech(
            companyId: companyId,
            date: date,
            techId: techId
        )

        guard !serviceStops.isEmpty || !existingRoutes.isEmpty else {
            return nil
        }

        let existingRoute = canonicalActiveRoute(from: existingRoutes)
        let serviceStopIds = serviceStops.map { $0.id }
        let finishedStops = serviceStops.filter { $0.operationStatus == .finished }.count
        let existingOrder = existingRoute?.order ?? []
        let order = RouteOrderBuilder.build(
            serviceStops: serviceStops,
            recurringRoute: nil,
            existingOrder: existingOrder
        )

        var route = existingRoute ?? ActiveRoute(
            id: activeRouteStableDocumentId(date: date, techId: techId),
            name: "\(techName)'s Route",
            date: date.startOfDay(),
            serviceStopsIds: serviceStopIds,
            order: order,
            techId: techId,
            techName: techName,
            durationMin: serviceStops.reduce(0) { $0 + $1.duration },
            distanceMiles: 0,
            status: .didNotStart,
            totalStops: serviceStops.count,
            finishedStops: finishedStops,
            vehicalId: ""
        )

        route.date = date.startOfDay()
        route.techId = techId
        route.techName = techName
        route.serviceStopsIds = serviceStopIds
        route.order = order
        route.durationMin = serviceStops.reduce(0) { $0 + $1.duration }
        route.totalStops = serviceStops.count
        route.finishedStops = finishedStops
        route.status = routeStatus(
            existingRoute: existingRoute,
            totalStops: route.totalStops,
            finishedStops: route.finishedStops
        )

        try ActiveRouteDocument(companyId: companyId, activeRouteId: route.id)
            .setData(from: route, merge: true)

        await reconcileDuplicateActiveRoutes(
            companyId: companyId,
            routes: existingRoutes,
            primaryRouteId: route.id
        )

        return route
    }
        //DELETE
    
    //Extra
    func getRecentActiveRoutes(
        companyId: String,
        technicianId: String,
        limit: Int = 10
    ) async throws -> [ActiveRoute] {
        let snapshot = try await db
            .collection("companies")
            .document(companyId)
            .collection("activeRoutes")
            .whereField("techId", isEqualTo: technicianId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: ActiveRoute.self)
        }
    }
    func applyRouteChanges(companyId:String,diff:ActiveRouteDiff,calledFrom:String){
        Task{
            do {
                print("")
                print("    [ProductionDataService][applyRouteChanges] Called From \(calledFrom) Listener")
                //if Diff oldRoute is nil then upload the new ActiveRoute. Other wise update the status and order
                if diff.old == nil {
                    print("    [ProductionDataService][applyRouteChanges] Old Route is nil")
                    print("    [ProductionDataService][applyRouteChanges] Upload New Active route because Old Route is nil")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: ID: \(diff.new.id)")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Date: \(diff.new.date)")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Total Stops: \(diff.new.totalStops)")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Service Stop Ids: \(diff.new.serviceStopsIds.count)")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Service Stop Order: \(String(describing: diff.new.order?.count))")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Tech Id: \(diff.new.techId)")
                    print("      [ProductionDataService][applyRouteChanges] New Active Route: Tech Name: \(diff.new.techName)")
                    _ = try await uploadRoute(companyId: companyId, activeRoute: diff.new)
                } else {
                    let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: diff.new.id)
                    try await ref.updateData([
                        ActiveRoute.CodingKeys.serviceStopsIds.rawValue: diff.new.serviceStopsIds,
                        ActiveRoute.CodingKeys.totalStops.rawValue: diff.new.totalStops,
                        ActiveRoute.CodingKeys.finishedStops.rawValue: diff.new.finishedStops,
                        ActiveRoute.CodingKeys.durationMin.rawValue: diff.new.durationMin,
                        ActiveRoute.CodingKeys.status.rawValue: diff.new.status.rawValue
                    ])

                    //If Order is Changed make updates to Ar Order
                    if diff.orderChanged {
                     print("    [ProductionDataService][applyRouteChanges] Update Order Changed")
                        try await ref.updateData([
                            "order": []
                        ])
                        
                        for order in diff.new.order ?? [] {
                            let data =  [
                                "order": FieldValue.arrayUnion([
                                    [
                                        "id": order.id,
                                        "order": order.order,
                                        "serviceStopId": order.serviceStopId,
                                        "recurringServiceStopId": order.recurringServiceStopId,
                                    ]
                                ])
                            ]
                            try await ref.updateData(data)
                        }
                        
                    } else {
                        print("    [ProductionDataService][applyRouteChanges] No Change To Order")
                    }
//                    if Status has changed make updates
                    if diff.statusChanged {
                     print("    [ProductionDataService][applyRouteChanges]Update Status Changed")
                        try await ref.updateData([
                            "status": diff.new.status.rawValue
                        ])
                    } else {
                        print("    [ProductionDataService][applyRouteChanges] No Change To Status")
                    }
                }
            } catch {
                print("[ProductionDataService][applyRouteChanges] [Build] Error \(error)")
            }
        }
    }
    
    func getActiveRoutesNeedingReview(
        companyId: String,
        technicianId: String,
        beforeDate: Date
    ) async throws -> [ActiveRoute] {
        let snapshot = try await db
            .collection("companies")
            .document(companyId)
            .collection("activeRoutes")
            .whereField("techId", isEqualTo: technicianId)
            .whereField("date", isLessThan: beforeDate)
            .getDocuments()

        let routes = snapshot.documents.compactMap { document in
            try? document.data(as: ActiveRoute.self)
        }

        return routes.filter { route in
            route.status != .finished || route.endMilage == nil || route.endTime == nil
        }
        .sorted { lhs, rhs in
            lhs.date > rhs.date
        }
    }
    func getActiveRoutesForDate(
        companyId: String,
        date: Date
    ) async throws -> [ActiveRoute] {
        let routes = try await ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .getDocuments(as: ActiveRoute.self)

        return routes.sorted {
            if $0.status.rawValue == $1.status.rawValue {
                return $0.techName < $1.techName
            }

            return $0.status.rawValue < $1.status.rawValue
        }
    }

    func getActiveRouteLogs(
        companyId: String,
        activeRouteId: String
    ) async throws -> [ActiveRouteLog] {
        let logs = try await ActiveRouteLogCollection(
            companyId: companyId,
            activeRouteId: activeRouteId
        )
        .whereField(ActiveRouteLog.CodingKeys.activeRouteId.rawValue, isEqualTo: activeRouteId)
        .getDocuments(as: ActiveRouteLog.self)

        return logs.sorted { $0.startTime < $1.startTime }
    }

    func getActiveRouteLocations(
        companyId: String,
        activeRouteId: String
    ) async throws -> [ActiveRouteLocation] {
        let locations = try await ActiveRouteLocationCollection(
            companyId: companyId,
            activeRouteId: activeRouteId
        )
        .whereField(ActiveRouteLocation.CodingKeys.activeRouteId.rawValue, isEqualTo: activeRouteId)
        .getDocuments(as: ActiveRouteLocation.self)

        return locations.sorted { $0.time < $1.time }
    }

    func getServiceStopsByIds(
        companyId: String,
        serviceStopIds: [String]
    ) async throws -> [ServiceStop] {
        let uniqueServiceStopIds = serviceStopIds.reduce(into: [String]()) { ids, serviceStopId in
            guard !serviceStopId.isEmpty,
                  !ids.contains(serviceStopId) else { return }

            ids.append(serviceStopId)
        }

        guard !uniqueServiceStopIds.isEmpty else { return [] }

        var allStops: [ServiceStop] = []

        let chunks = uniqueServiceStopIds.chunked(into: 10)

        for chunk in chunks {
            let snapshot = try await serviceStopCollection(companyId: companyId)
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let stops = try snapshot.documents.map {
                try $0.data(as: ServiceStop.self)
            }

            allStops.append(contentsOf: stops)
        }

        return allStops
    }

}
