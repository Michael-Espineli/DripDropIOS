    //
    //  WorkLog+DS+Extension.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/11/24.
    //

import Foundation
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
struct WorkShift:Identifiable, Codable,Hashable{
    
    var id:String = "comp_shi_" + UUID().uuidString
    var date:Date
    var techId:String
    var techName:String
    var isCurrent:Bool
    var estimatedTime:Int // Min
    var estimatedMiles:Int // Miles
}
struct WorkLog:Identifiable, Codable,Hashable{
    
    var id:String = UUID().uuidString
    var shiftId:String

    var startTime:Date
    var startLatitude:Double
    var startLongitude:Double
    
    var endTime:Date?
    var endLatitude:Double?
    var endLongitude:Double?
    
    var type:WorkLogType
    var companyId:String
    var companyName:String
    var userId:String
    var userName:String
    var current:Bool
    init(
        id: String,
        shiftId: String,

        startTime :Date,
        startLatitude :Double,
        startLongitude :Double,
        
        endTime :Date? = nil,
        endLatitude :Double? = nil,
        endLongitude :Double? = nil,

        type: WorkLogType,
        companyId: String,
        companyName: String,
        userId: String,
        userName: String,
        current: Bool

    ){
        self.id = id
        self.shiftId = shiftId

        self.startTime = startTime
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        
        self.endTime = endTime
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        
        self.type = type
        self.companyId = companyId
        self.companyName = companyName
        self.userId = userId
        self.userName = userName
        self.current = current

    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case shiftId = "shiftId"

        case startTime = "startTime"
        case startLatitude = "startLatitude"
        case startLongitude = "startLongitude"
        
        case endTime = "endTime"
        case endLatitude = "endLatitude"
        case endLongitude = "endLongitude"
        
        case type = "type"
        case companyId = "companyId"
        case companyName = "companyName"
        
        case userId = "userId"
        case userName = "userName"
        case current = "current"
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(startTime)
    }
    static func == (lhs: WorkLog, rhs: WorkLog) -> Bool {
        return lhs.id == rhs.id &&
        lhs.startTime == rhs.startTime
    }
}

extension ProductionDataService {
    func WorkLogCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/workLogs")
    }
    
    func WorkShiftCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/shifts")
    }
    
    func WorkLogDocument(companyId:String,workLogId:String)-> DocumentReference{
        WorkLogCollection(companyId: companyId).document(workLogId)
    }
    
    func WorkShiftDocument(companyId:String,shiftId:String)-> DocumentReference{
        WorkShiftCollection(companyId: companyId).document(shiftId)
    }
    
    //CREATE
    func uploadWorkLog(companyId:String,workLog:WorkLog) async throws {
        try WorkLogDocument(companyId: companyId, workLogId: workLog.id)
            .setData(from:workLog, merge: true)
    }
    
    func uploadWorkShift(companyId:String, workShift:WorkShift) async throws {
        
        try WorkShiftDocument(companyId: companyId, shiftId: workShift.id)
                .setData(from:workShift, merge: true)
    }
    //READ
    func getNextShiftByUserId(companyId:String, userId:String, count:Int) async throws -> [WorkShift] {
        return try await WorkShiftCollection(companyId: companyId)
            .whereField("techId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: Date())
            .order(by: "date", descending: true)
            .limit(to: count)
            .getDocuments(as: WorkShift.self)
    }
    
    func getPreviousShiftByUserId(companyId:String, userId:String, count:Int) async throws -> [WorkShift] {
        return try await WorkShiftCollection(companyId: companyId)
            .whereField("techId", isEqualTo: userId)
            .whereField("date", isLessThanOrEqualTo: Date())
            .order(by: "date", descending: true)
            .limit(to: count)
            .getDocuments(as: WorkShift.self)
    }
    
    func getShiftByUserIdBetweenDates(companyId:String, userId:String, start:Date, end:Date) async throws -> [WorkShift] {
        return try await WorkShiftCollection(companyId: companyId)
            .whereField("techId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo:start)
            .whereField("date", isLessThanOrEqualTo:end)
            .order(by: "date", descending: true)
            .getDocuments(as: WorkShift.self)
    }
    
    func getWorkLogByShift(companyId:String,shiftId:String,userId:String) async throws -> [WorkLog] {
        return try await WorkLogCollection(companyId: companyId)
            .whereField(WorkLog.CodingKeys.userId.rawValue, isEqualTo: userId)
            .whereField(WorkLog.CodingKeys.shiftId.rawValue, isEqualTo: shiftId)
            .getDocuments(as: WorkLog.self)
    }
    
    func getActiveWorkLogsByUser(companyId:String,userId:String) async throws -> [WorkLog] {
        return try await WorkLogCollection(companyId: companyId)
            .whereField(WorkLog.CodingKeys.current.rawValue, isEqualTo: true)
            .whereField(WorkLog.CodingKeys.userId.rawValue, isEqualTo: userId)
            .getDocuments(as: WorkLog.self)
    }
    
    func getCurrentShift(companyId:String,userId:String) async throws -> [WorkShift] {
        
            return try await WorkShiftCollection(companyId: companyId)
            .whereField("isCurrent", isEqualTo: true)
            .whereField("techId", isEqualTo: userId)
            .getDocuments(as: WorkShift.self)
    }

        //UPDATE
    func updateWorkLogEndTime(companyId:String, workLogId:String, endTime:Date) async throws {
        let ref = WorkLogDocument(companyId: companyId, workLogId: workLogId)
        
        try await ref.updateData([
            WorkLog.CodingKeys.endTime.rawValue: endTime,
        ])
    }
    func updateWorkLogEndLatAndLong(companyId:String, workLogId:String, lat:Double,long:Double) async throws {
        let ref = WorkLogDocument(companyId: companyId, workLogId: workLogId)
        
        try await ref.updateData([
            WorkLog.CodingKeys.endLatitude.rawValue: lat,
            WorkLog.CodingKeys.endLongitude.rawValue: long,

        ])
    }
    func updateWorkLogActive(companyId:String, workLogId:String,current:Bool) async throws {
        let ref = WorkLogDocument(companyId: companyId, workLogId: workLogId)
        
        try await ref.updateData([
            WorkLog.CodingKeys.current.rawValue: current,
        ])
    }
    func updateWorkShiftActive(companyId:String, workShiftId:String,current:Bool) async throws {
        let ref = WorkShiftDocument(companyId: companyId, shiftId: workShiftId)
        
        try await ref.updateData([
            "isCurrent": current,
        ])
    }
        //DELETE
}
