//
//  RepairRequest+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
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
    var photoUrls:[DripDropStoredImage]
    var locationId:String?
    var bodyOfWaterId:String?
    var equipmentId:String?
}

extension ProductionDataService {
        //Refrences
    func repairRequestCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/repairRequests")
    }
    func repairRequestDocument(companyId:String,repairRequestId:String)-> DocumentReference{
        repairRequestCollection(companyId: companyId).document(repairRequestId)
    }
    func RepairRequestImageRefrence(id:String)->StorageReference {
        storage.child("repairRequest").child(id)
    }
        //Create
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: false)
    }
        //Read
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest{
        
        return try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId)
            .getDocument(as: RepairRequest.self)
    }
    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest] {
        
        return try await repairRequestCollection(companyId: companyId)
            .getDocuments(as:RepairRequest.self)
    }
    
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]{
        return try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RepairRequest.self)
    }
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        return try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId).count.getAggregation(source: .server).count as? Int
    }
    func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?{
            //MEMORY LEAK
        let status = [RepairRequestStatus.unresolved.rawValue,RepairRequestStatus.inprogress.rawValue]
        return try await repairRequestCollection(companyId: companyId)
            .whereField("status", in: status)
            .whereField("requesterId", isEqualTo: userId)
            .count.getAggregation(source: .server).count as? Int
            //        return 0
    }
        //Update
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: true)
    }
    func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:RepairRequestStatus) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        try await ref.updateData([
            "status": status.rawValue
        ])
    }
    func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        try await ref.updateData([
            "jobIds": FieldValue.arrayUnion([jobId])
            
        ])
    }
    func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        try await ref.updateData([
            "photoUrls": FieldValue.arrayUnion([photoUrl])
            
        ])
    }
    func updateRepairRequestPhotoURLs(companyId: String, repairRequest: String, photoUrls: [DripDropStoredImage]) async throws {
    }
    func uploadRepairRequestImage(companyId: String,requestId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await EquipmentImageRefrence(id: requestId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (urlString,returnedName)
    }

    //Delete
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws{
        try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId).delete()
    }
}
