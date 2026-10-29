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
    var issuePriorityLevel: Int? = nil
    var issuePriorityLabel: String? = nil
    var priorityLevel: Int? = nil
    var priorityLabel: String? = nil
    var sourcePath: String? = nil

    var queueId: String { "\(sourcePath ?? "company"):\(id)" }

    // Web and public submissions can omit fields required by older native records.
    static func fromQueueFields(id: String, data: [String: Any], sourcePath: String) -> RepairRequest {
        let photos = (data["photoUrls"] as? [Any] ?? []).compactMap { photo -> DripDropStoredImage? in
            if let url = photo as? String { return DripDropStoredImage(description: "", imageURL: url) }
            guard let fields = photo as? [String: Any], let url = fields["imageURL"] as? String else { return nil }
            return DripDropStoredImage(id: fields["id"] as? String ?? url, description: fields["description"] as? String ?? "", imageURL: url)
        }
        return RepairRequest(
            id: id,
            customerId: data["customerId"] as? String ?? "",
            customerName: data["customerName"] as? String ?? data["homeownerName"] as? String ?? "Customer",
            requesterId: data["requesterId"] as? String ?? data["userId"] as? String ?? "",
            requesterName: data["requesterName"] as? String ?? "",
            date: RepairRequestQueue.date(data) ?? .distantPast,
            status: RepairRequestStatus.normalized(data["status"] as? String),
            description: data["description"] as? String ?? "",
            jobIds: data["jobIds"] as? [String] ?? [],
            photoUrls: photos,
            locationId: data["locationId"] as? String ?? data["serviceLocationId"] as? String,
            bodyOfWaterId: data["bodyOfWaterId"] as? String,
            equipmentId: data["equipmentId"] as? String,
            issuePriorityLevel: data["issuePriorityLevel"] as? Int,
            priorityLevel: data["priorityLevel"] as? Int,
            sourcePath: sourcePath
        )
    }

    static func submittedByUser(_ data: [String: Any], userIds: [String]) -> Bool {
        let ids = Set(userIds.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let requester = (data["requesterId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !requester.isEmpty { return ids.contains(requester) }
        return ["userId", "uid", "homeownerId", "createdBy", "createdById", "createdByUid", "createdByUserId", "requestedBy", "requestedByUid", "requestedByUserId", "submittedBy", "submittedByUserId", "authorId"]
            .compactMap { data[$0] as? String }
            .contains { ids.contains($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    }

    var normalizedIssuePriority: JobIssuePriorityLevel {
        JobIssuePriorityLevel.normalized(issuePriorityLevel ?? priorityLevel)
    }

    mutating func setIssuePriority(_ priority: JobIssuePriorityLevel) {
        issuePriorityLevel = priority.rawValue
        issuePriorityLabel = priority.label
        priorityLevel = priority.rawValue
        priorityLabel = priority.label
    }
}

extension ProductionDataService {
        //Refrences
    func repairRequestCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/repairRequests")
    }
    func repairRequestDocument(companyId:String,repairRequestId:String)-> DocumentReference{
        repairRequestCollection(companyId: companyId).document(repairRequestId)
    }
    func repairRequestCommentsCollection(companyId: String, repairRequestId: String) -> CollectionReference {
        repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
            .collection("comments")
    }
    func RepairRequestImageRefrence(companyId:String,id:String)->StorageReference {
        storage.child("companies").child(companyId).child("repairRequests").child(id)
    }
        //Create
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: false)
    }
    func addRepairRequestComment(
        companyId: String,
        repairRequestId: String,
        comment: JobComment
    ) async throws {
        try repairRequestCommentsCollection(companyId: companyId, repairRequestId: repairRequestId)
            .document(comment.id)
            .setData(from: comment, merge: false)
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
    func getRepairRequestComments(companyId: String, repairRequestId: String) async throws -> [JobComment] {
        try await repairRequestCommentsCollection(companyId: companyId, repairRequestId: repairRequestId)
            .order(by: "date", descending: true)
            .getDocuments(as: JobComment.self)
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
        async let companyRequests = repairRequestCollection(companyId: companyId).getDocuments()
        async let homeownerRequests = db.collection("homeownerRepairRequests").whereField("companyId", isEqualTo: companyId).getDocuments()
        let snapshots = try await [companyRequests, homeownerRequests]
        return snapshots.flatMap(\.documents).filter { document in
            let data = document.data()
            return RepairRequestStatus.normalized(data["status"] as? String).isOpenWorkQueueItem
                && RepairRequest.submittedByUser(data, userIds: [userId])
        }.count
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
            "photoUrls": FieldValue.arrayUnion([
                [
                    "id": UUID().uuidString,
                    "description":"",
                    "imageURL":photoUrl
                ] as [String : Any]])
        ])
    }
    func updateRepairRequestPhotoURLs(companyId: String, repairRequest: String, photoUrls: [DripDropStoredImage]) async throws {
    }
    func updateRepairRequestDescription(companyId:String,repairRequestId:String,description:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        try await ref.updateData([
            "description": description
        ])
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
        
        let returnedMetaData = try await RepairRequestImageRefrence(companyId: companyId, id: requestId).child(path)
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
