//
//  RecurringRoute+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/11/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage
struct RecurringRoute:Identifiable, Codable,Hashable{
    static func == (lhs: RecurringRoute, rhs: RecurringRoute) -> Bool {
        return lhs.id == rhs.id &&
        lhs.tech == rhs.tech &&
        lhs.techId == rhs.techId &&
        lhs.day == rhs.day &&
        lhs.description == rhs.description
    }
    
    var id :String 
    var tech: String
    var techId: String
    var day:String
    var order:[recurringRouteOrder]
    var description: String
}
extension ProductionDataService {
    func recurringRouteCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/recurringRoutes")
    }
    func reccuringRouteDoc(companyId:String,recurringRouteId:String)-> DocumentReference{
        recurringRouteCollection(companyId: companyId).document(recurringRouteId)
    }
        //CREATE
    //READ
    func getSingleRoute(companyId:String,recurringRouteId:String) async throws -> RecurringRoute {
        print("* getSingleRoute in ProductionDataService+GetExtension *")
        
        return try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId)
            .getDocument(as: RecurringRoute.self)
    }
    func getSingleRouteFromTechIdAndDay(companyId:String,techId:String,day:String) async throws -> RecurringRoute?{
        let recurringRoutes = try await recurringRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)

        return recurringRoutes.first
    }
    func getRecurringRouteByDayCount(companyId:String,day:String) async throws ->Int {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .count.getAggregation(source: .server).count as! Int
    }
    
    func getAllActiveRoutes(companyId:String,param:String) async throws -> [RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .getDocuments(as: RecurringRoute.self)
    }
    
    func getAllActiveRoutesBasedOnDate(companyId:String,day:String,techId:String) async throws -> [RecurringRoute] {
        //MEMORY LEAK
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as: RecurringRoute.self)
    }
    func getRecurringRouteByDayAndTech(companyId:String,day:String,techId:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
    }
    func getRecurringRouteByDay(companyId:String,day:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
    }
    //UPDATE
    func endRecurringRoute(companyId:String,recurringRouteId:String,endDate:Date) async throws {
        //DEVELOPER ADD LOGIC
        print("End Recurring Route Logic")
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId).delete()
        
        //Delete Recurring Route
    }
    //DELETE
    func deleteRecurringRoute(companyId:String,recurringRouteId : String) async throws{
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId)
            .delete()
        
    }
}
