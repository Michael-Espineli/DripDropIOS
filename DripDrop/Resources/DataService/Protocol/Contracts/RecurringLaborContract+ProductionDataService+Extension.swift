//
//  RecurringLaborContract+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/28/24.
//

import Foundation
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

    /// Contract - Between Client and Company
    /// Recurring Contract - Between Client and Company (For Weekly Cleaning)
    /// LaborContract - between Company and Sub
    /// RecurringLaborContract - between Company and Sub (For Weekly Cleaning)
    ///
struct ReccuringLaborContract:Identifiable, Codable, Hashable{
    var id:String = "rlc_" + UUID().uuidString
    var senderName:String
    var senderId:String
    var senderAcceptance:Bool
    var receiverName:String
    var receiverId:String
    var receiverAcceptance:Bool
    var dateSent:Date
    var lastDateToAccept:Date
    var dateAccepted:Date?
    var startDate:Date
    var endDate:Date
    var status:LaborContractStatus
    var isActive:Bool
    var terms:[ContractTerms]
    var notes:String
    var atWill:Bool
    var contractLengthInMonths:Int?
}
extension ProductionDataService {
    
    //Refrences
    func RecurringLaborContractCollection() -> CollectionReference{
        db.collection("recurringLaborContracts")
    }
    func RecurringLaborContractDocument(laborContractId:String)-> DocumentReference{
        RecurringLaborContractCollection().document(laborContractId)
    }
    
    

    //Create
    func addLaborContract(companyId:String,laborContract:ReccuringLaborContract) async throws {
        try RecurringLaborContractDocument(laborContractId: laborContract.id)
            .setData(from:laborContract, merge: false)
    }
    
    //Read
    func getLaborContractsTotal(companyId: String) async throws -> Double {
        return 4_206.9
    }
    func getLaborContractsByAssociatedBusiness(companyId:String,associatedBusinessCompanyId:String) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("receiverId", isEqualTo: associatedBusinessCompanyId)
            .getDocuments(as:ReccuringLaborContract.self)
    }
    
    func getLaborContractsByAssociatedBusinessIsActive(companyId:String,associatedBusinessCompanyId:String,isActive:Bool) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("receiverId", isEqualTo: companyId)
            .whereField("senderId", isEqualTo: associatedBusinessCompanyId)
            .whereField("isActive", isEqualTo: isActive)
            .getDocuments(as:ReccuringLaborContract.self)
    }
    
    func getLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .getDocuments(as:ReccuringLaborContract.self)
    }
    func getReceivedLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("receiverId", isEqualTo: companyId)
            .getDocuments(as:ReccuringLaborContract.self)
    }
    func getSentLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("senderId", isEqualTo: companyId)

            .getDocuments(as:ReccuringLaborContract.self)
    }
    
    
    func getSentLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("senderId", isEqualTo: companyId)
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments(as:ReccuringLaborContract.self)
    }
    func getLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments(as:ReccuringLaborContract.self)
    }

    func getLaborContractsSnapShot(companyId: String) async throws -> [ReccuringLaborContract] {
        return try await RecurringLaborContractCollection()
            .limit(to: 8)
            .order(by: "dateSent", descending: true)
            .getDocuments(as:ReccuringLaborContract.self)
    }
    
    func getLaborContractsCount(companyId: String) async throws -> Int {
        return try await RecurringLaborContractCollection()
            .count.getAggregation(source: .server).count as! Int
    }


    func getLaborContractsSentCountByStatus(companyId: String,status:LaborContractStatus) async throws -> Int {
        return try await RecurringLaborContractCollection()
            .whereField("status", isEqualTo: status.rawValue)
            .count.getAggregation(source: .server).count as! Int
    }
    
    func getLaborContractsReceivedCountByStatus(companyId: String,status:LaborContractStatus) async throws -> Int {
        return try await RecurringLaborContractCollection()
            .whereField("status", isEqualTo: status.rawValue)
            .count.getAggregation(source: .server).count as! Int
    }
    
    //Update
    func updateLaborContractIsActive(contractId:String,isActive:Bool)  async throws {
        let ref = RecurringLaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "isActive": isActive
            ])
    }
    func updateLaborContractAsAcceptedByReceiver(companyId:String,contractId:String,accepted:Bool)  async throws {
        let ref = RecurringLaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "status":LaborContractStatus.accepted.rawValue,
                "receiverAcceptance": accepted
            ])
    }
    func updateLaborContractAsAcceptedBySender(companyId:String,contractId:String,accepted:Bool)  async throws {
        let ref = RecurringLaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "status":LaborContractStatus.accepted.rawValue,
                "senderAcceptance": accepted
            ])
    }
    //Delete
    func deleteRecurringLaborContract(companyId:String,contractId:String) async throws {
        try await RecurringLaborContractDocument(laborContractId: contractId)
            .delete()
    }
}
// A sub collection of Recurring Labor Contract
struct LaborContractRecurringWork:Identifiable, Codable, Hashable{
    var id:String
    var customerId:String
    var customerName:String
    var serviceLocationId:String
    var serviceLocationName:String
    var jobTemplateId:String
    var jobTemplateName:String
    var rate: Int
    var laborType:RateSheetLaborType
    var frequency: LaborContractFrequency
    var timesPerFrequency: Int
    var timesPerFrequencySetUp: Int
    var routeSetUp:Bool
    var recurringServiceStopIdList:[IdInfo]
    var isActive: Bool
    var lastBilled: Date
}
//Labor Contract Recurring Work
extension ProductionDataService {
    //Refrences
    func RecurringLaborContractRecurringWorkCollection(laborContractId:String) -> CollectionReference{
        db.collection("recurringLaborContracts/\(laborContractId)/recurringWork")
    }
    func RecurringLaborContractRecurringWorkDocument(laborContractId:String,recurringWorkId:String)-> DocumentReference{
        RecurringLaborContractRecurringWorkCollection(laborContractId: laborContractId).document(recurringWorkId)
    }
    //Create
    func addLaborContractRecurringWork(companyId: String, laborContractId: String, laborContractRecurringWork: LaborContractRecurringWork) async throws {
        try RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWork.id)
            .setData(from:laborContractRecurringWork, merge: false)
    }
    
    //Read
    func getLaborContractRecurringWork(companyId: String, laborContractId: String, recurringWorkId: String) async throws -> LaborContractRecurringWork {
        return try await RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: recurringWorkId)
            .getDocument(as: LaborContractRecurringWork.self)
    }
    
    func getLaborContractRecurringWorkList(companyId: String, laborContractId: String) async throws -> [LaborContractRecurringWork] {
        return try await RecurringLaborContractRecurringWorkCollection(laborContractId: laborContractId)
            .getDocuments(as: LaborContractRecurringWork.self)
    }
    //Update
    func updateLaborContractRecurringWorkRate(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, rate: Double) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "rate": rate
            ])
    }
    func updateLaborContractRecurringWorkLastBilled(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, lastBilled: Date) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "lastBilled": lastBilled
            ])
    }
    func updateLaborContractRecurringWorkIsActive(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, isActive: Bool) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "isActive": isActive
            ])
    }
    
    func updateLaborContractRecurringWorkRateRateSheetLaborType(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, laborType: RateSheetLaborType) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "laborType": laborType.rawValue
            ])
    }
    
    func updateLaborContractRecurringWorkRateLaborContractFrequency(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, frequency: LaborContractFrequency) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "frequency": frequency.rawValue
            ])
    }
    
    func updateLaborContractRecurringWorkSetUpRoute(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, setUpRoute: Bool) async throws {
        let ref = RecurringLaborContractRecurringWorkDocument(laborContractId: laborContractId, recurringWorkId: laborContractRecurringWorkId)
        try await ref
            .updateData([
                "setUpRoute": setUpRoute
            ])
    }
    
    //Read
    //Update
    //Delete
}
