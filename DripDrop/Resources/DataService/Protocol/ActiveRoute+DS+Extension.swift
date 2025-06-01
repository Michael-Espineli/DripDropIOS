//
//  ActiveRoute+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/11/24.
//

import Foundation
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

extension ProductionDataService {
    
}
