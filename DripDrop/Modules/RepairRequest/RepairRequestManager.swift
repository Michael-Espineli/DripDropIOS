//
//  RepairRequestManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin
struct RepairRequest:Identifiable, Codable,Equatable{
    var id:String
    var customerId:String
    var customerName:String
    var requesterId:String
    var requesterName:String
    var date:Date
    var status:RepairRequestStatus
    var description:String
    var jobIds:[String]
    var photoUrls:[String]
}
enum RepairRequestStatus:String,Codable, CaseIterable{
    case resolved = "Resolved"
    case unresolved = "Unresolved"
    case inprogress = "In Progress"
}

protocol RepairRequestManagerProtocol {

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest]
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws
    func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:String) async throws

    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func addListenerForAllChats(companyId:String,status:String,requesterId:String,startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[RepairRequest]) -> Void)
    func removeListenerForChats()
    func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws
    func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws
    func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?
    
}

    final class MockRepairRequestManager:RepairRequestManagerProtocol {

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
        let mockRepairRequests:[RepairRequest] = [

        ]

    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
      print("Successfully upLoaded RepairRequest")
    }
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest] {
        
        return mockRepairRequests
    }
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest{
        
        guard let repairRequest = mockRepairRequests.first(where: {$0.id == repairRequestId}) else {
            throw FireBaseRead.unableToRead
        }
        return repairRequest
//            .getDocuments(as:Equipment.self)
    }
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]{
        return mockRepairRequests

    }
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        var count: Int = 0
        for repairRequest in mockRepairRequests {
            if repairRequest.customerId == customerId {
                count += count
            }
        }
        return count
    }
        func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws{
            
        }
        func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws{
            
        }

    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        print("Successfully Uploaded")
    }
        func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:String) async throws {
        }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws{
        print("Successfully Deleted")
    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
        func addListenerForAllChats(companyId:String,status:String,requesterId:String,startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[RepairRequest]) -> Void) {
            
        }
        func removeListenerForChats(){
        }
        func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?{
            return 9
        }
}

final class RepairRequestManager:RepairRequestManagerProtocol {

    
    
    static let shared = RepairRequestManager()
    init(){}
    private let db = Firestore.firestore()
    private var requestListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func repairRequestCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/repairRequests")
    }


    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func repairRequestDocument(companyId:String,repairRequestId:String)-> DocumentReference{
        repairRequestCollection(companyId: companyId).document(repairRequestId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: false)
    }
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest] {
        
        return try await repairRequestCollection(companyId: companyId)
            .getDocuments(as:RepairRequest.self)
    }
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest{
        
        return try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId).getDocument(as: RepairRequest.self)
//            .getDocuments(as:Equipment.self)
    }
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]{
        return try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RepairRequest.self)
    }
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        let count = try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId).count.getAggregation(source: .server).count
        
        return count as! Int
    }
    func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?{
        let count = try await repairRequestCollection(companyId: companyId)
            .whereField("requesterId", isEqualTo: userId)
            .count.getAggregation(source: .server).count
        
        return count as! Int
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: true)
    }
    func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
             ref.updateData([
                "status": status
            ]) { err in
                if let err = err {
                    print("Error updating Repair Request Doc: \(err)")
                } else {
                    print("Updated Repair Request Status Successfully")
                }
            }
    }
    func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
             ref.updateData([
                "jobIds": FieldValue.arrayUnion([jobId])
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
             ref.updateData([
                "photoUrls": FieldValue.arrayUnion([photoUrl])
                
                ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully Updated photoURl String")
                }
            }
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws{
        try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId).delete()
    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  LISTENER  ---------------------
    //----------------------------------------------------
    func addListenerForAllChats(companyId:String,status:String,requesterId:String,startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[RepairRequest]) -> Void){

        var listener:ListenerRegistration? = nil
        if status == "All" && requesterId == "All"{
            print("Status All Requesters All, Filer By Date ")
            listener = repairRequestCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else if status == "All" {
            print("Status All")

            listener = repairRequestCollection(companyId: companyId)
                .whereField("requesterId", isEqualTo: requesterId)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else if requesterId == "All" {
            print("Requesters All, Filer By Date ")

            listener = repairRequestCollection(companyId: companyId)
                .whereField("status", isEqualTo: status)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else {
            print("All Filters ")

            listener = repairRequestCollection(companyId: companyId)
                .whereField("status", isEqualTo: status)
                .whereField("requesterId", isEqualTo: requesterId)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        }
        self.requestListener = listener
    }
    func removeListenerForChats(){
        self.requestListener?.remove()
    }
}
