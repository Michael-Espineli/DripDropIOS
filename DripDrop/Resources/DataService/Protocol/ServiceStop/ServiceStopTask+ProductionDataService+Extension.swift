//
//  ServiceStopTask+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/4/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit



extension ProductionDataService {
    
    func serviceStopTaskCollection(companyId:String,serviceStopId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/serviceStops/\(serviceStopId)/tasks")
   }
    func serviceStopTaskDocument(serviceStopId:String,companyId:String,taskId:String)-> DocumentReference{
        serviceStopTaskCollection(companyId: companyId, serviceStopId: serviceStopId).document(taskId)
   }
    //Create
    func uploadServiceStopTask(companyId:String,serviceStopId:String,task:ServiceStopTask) async throws {
        try serviceStopTaskDocument(serviceStopId: serviceStopId, companyId: companyId, taskId: task.id)
            .setData(from:task, merge: false)
    }
    //Read
    func getServiceStopTasks(companyId:String,serviceStopId:String) async throws -> [ServiceStopTask] {
        return try await serviceStopTaskCollection(companyId: companyId, serviceStopId: serviceStopId)
            .getDocuments(as:ServiceStopTask.self)
    }
    //Update
    func updateServiceStopTaskStatus(companyId:String,serviceStopId:String,taskId:String,status:JobTaskStatus) async throws {
        let ref = serviceStopTaskDocument(serviceStopId: serviceStopId, companyId: companyId, taskId: taskId)
        try await updateConfirmedTaskStatus(ref, status: status)
    }

    func updateConfirmedTaskStatus(_ ref: DocumentReference, status: JobTaskStatus) async throws {
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let current = try transaction.getDocument(ref).data() ?? [:]
                var update: [String: Any] = ["status": status.rawValue]
                if status == .finished {
                    if current["status"] as? String != status.rawValue || current["completedAt"] == nil || current["completedAt"] is NSNull {
                        update["completedAt"] = FieldValue.serverTimestamp()
                    }
                } else {
                    update["completedAt"] = FieldValue.delete()
                    update["finishedAt"] = FieldValue.delete()
                }
                transaction.updateData(update, forDocument: ref)
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    //Delete
    func deleteServiceStopTask(companyId:String,serviceStopId:String,taskId:String) async throws {
        try await serviceStopTaskDocument(
            serviceStopId: serviceStopId,
            companyId: companyId,
            taskId: taskId
        )
        .delete()
    }
}
