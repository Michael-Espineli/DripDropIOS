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
    
    let id :String
    var name: String
    var date : Date
    var serviceStopsIds : [String]
    var order : [ServiceStopOrder]?
    var startTime : Date?
    var endTime : Date?
    var startMilage: Int?
    var endMilage: Int?
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
    init(
        id: String,
        name :String,
        date : Date,

        serviceStopsIds : [String],
        order : [ServiceStopOrder]? = nil,

        startTime: Date? = nil,
        endTime: Date? = nil,
        startMilage : Int? = nil,
        endMilage : Int? = nil,
        techId: String,
        techName: String,

        traineeId: String? = nil,
        traineeName: String? = nil,

        durationMin: Int,
        distanceMiles: Double,
        status: ActiveRouteStatus,
        totalStops: Int,
        finishedStops: Int,
        vehicalId: String
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
    func ActiveRouteDocument(companyId:String,activeRouteId:String)-> DocumentReference{
        ActiveRouteCollection(companyId: companyId).document(activeRouteId)
    }
        //
        //CREATE
    func uploadRoute(companyId: String,activeRoute:ActiveRoute) async throws {
        try ActiveRouteCollection(companyId: companyId).document(activeRoute.id).setData(from:activeRoute, merge: false)
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
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .getDocuments(as: ActiveRoute.self)
            //        return []
    }
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ActiveRoute] {
            //MEMORY LEAK
        print("Date - \(date) - Route Manager : getAllActiveRoutesBasedOnDate ")
        return try await  ActiveRouteCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
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
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        try await ref.updateData([
            "order": nil
        ])
        
        for order in serviceStopOrderList {
            let data =  [
                "order": FieldValue.arrayUnion([
                    [
                        "id": order.id,
                        "order": order.order,
                        "serviceStopId": order.serviceStopId,
                    ]
                ])
            ]
            try await ref.updateData(data)
        }
        
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
        let ref = ActiveRouteDocument(companyId: companyId, activeRouteId: activeRouteId)
        ref.updateData([
            
            ActiveRoute.CodingKeys.status.rawValue: status.rawValue
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateActiveRouteStartMilage(companyId:String,activeRouteId:String,startMilage:Int){
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
    func updateActiveRouteEndMilage(companyId:String,activeRouteId:String,endMilage:Int){
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
        //DELETE
}
