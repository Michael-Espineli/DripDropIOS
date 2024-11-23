//
//  RouteManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin
enum ActiveRouteStatus:String,Codable,CaseIterable {
    case inProgress = "In Progress"
    case didNotStart = "Did Not Start"
    case traveling = "Traveling"
    case onBreak = "Break"
    case finished = "Finished"

}
struct ActiveRoute:Identifiable, Codable,Equatable{
    
    let id :String
    var name: String
    var date : Date
    var serviceStopsIds : [String]
    var order : [ServiceStopOrder]?
//    let serviceStops : [ServiceStop]
    var startTime : Date?
    var endTime : Date?
    var startMilage: Int?
    var endMilage: Int?
    var techId : String
    var techName : String

    var traineeId : String?
    var traineeName : String?

    var durationSeconds : Int
    var distanceMiles : Double
    var status : ActiveRouteStatus
    var totalStops : Int
    var finishedStops : Int

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

        durationSeconds: Int,
        distanceMiles: Double,
        status: ActiveRouteStatus,
        totalStops: Int,
        finishedStops: Int


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
        self.durationSeconds = durationSeconds
        self.distanceMiles = distanceMiles
        self.status = status
        self.totalStops = totalStops
        self.finishedStops = finishedStops

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
            case durationSeconds = "durationSeconds"
            case distanceMiles = "distanceMiles"
            case status = "status"
            case finishedStops = "finishedStops"
            case totalStops = "totalStops"

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

final class ActiveRouteManager {

    static let shared = ActiveRouteManager()
    private init(){}

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func routeCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/activeRoutes")
    }


    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func routeDoc(companyId:String,activeRouteId:String)-> DocumentReference{
        routeCollection(companyId: companyId).document(activeRouteId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------

    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRoute(companyId: String,activeRoute:ActiveRoute) async throws {
        try routeCollection(companyId: companyId).document(activeRoute.id).setData(from:activeRoute, merge: false)
    }

    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getSingleRoute(companyId: String,activeRouteId:String) async throws -> ActiveRoute {

        return try await routeDoc(companyId: companyId, activeRouteId: activeRouteId)
            .getDocument(as: ActiveRoute.self)
    }
    func getAllActiveRoutes(companyId: String,param:String) async throws -> [ActiveRoute] {

        return try await  routeCollection(companyId: companyId)
            .getDocuments(as: ActiveRoute.self)
//            .getDocuments(as:Equipment.self)
    }
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:DBUser) async throws -> [ActiveRoute] {
        print("Date - \(date) - Route Manager : getAllActiveRoutesBasedOnDate ")
       let routes = try await  routeCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .getDocuments(as: ActiveRoute.self)
        return routes
    }
    func getRecentActiveRouteForTech(companyId: String,techId:String,days:Int) async throws -> [ActiveRoute] {
        @State var startDate: Date = Calendar.current.date(byAdding: .day, value: -days, to: Date())!

       let routes = try await  routeCollection(companyId: companyId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThan: startDate.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: Date().startOfDay())
            .whereField(ActiveRoute.CodingKeys.techId.rawValue, isEqualTo: techId)
            .getDocuments(as: ActiveRoute.self)
        return routes
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRouteServiceStopId(companyId: String,activeRoute:ActiveRoute,serviceStopId:String) async throws {
        try await routeDoc(companyId: companyId, activeRouteId: activeRoute.id)
            .updateData([
                ActiveRoute.CodingKeys.serviceStopsIds.rawValue:FieldValue.arrayUnion([serviceStopId])
        ])
        
    }
    func updateActiveRouteName(companyId:String,activeRouteId:String,name:String){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "name": name
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteDate(companyId:String,activeRouteId:String,date:Date){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "date": date
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteStartTime(companyId:String,activeRouteId:String,startTime:Date){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "startTime": startTime
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteEndTime(companyId:String,activeRouteId:String,endTime:Date){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "endTime": endTime
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteDuration(companyId:String,activeRouteId:String,duration:Int){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "duration": duration
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteDistnace(companyId:String,activeRouteId:String,distance:Double){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                "distance": distance
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteStatus(companyId:String,activeRouteId:String,status:ActiveRouteStatus){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                
                "status": status.rawValue
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteStartMilage(companyId:String,activeRouteId:String,startMilage:Int){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                
                "startMilage": startMilage
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteEndMilage(companyId:String,activeRouteId:String,endMilage:Int){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                
                "endMilage": endMilage
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateActiveRouteFinishedStop(companyId:String,activeRouteId:String,finishedStops:Int){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                
                "finishedStops": finishedStops
                
                ]) { err in
                if let err = err {
                    print("Error updating Finished Stop \(finishedStops): \(err)")
                } else {
                    print("Document successfully updated Active Route to Finished Stops \(finishedStops)")
                }
            }
    }
    func updateActiveRouteTotalStop(companyId:String,activeRouteId:String,totalStops:Int){
        let ref = routeDoc(companyId: companyId, activeRouteId: activeRouteId)
             ref.updateData([
                
                "totalStops": totalStops
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------

}
