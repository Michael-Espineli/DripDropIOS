//
//  JobTasks+ProductionDataService+Extension.swift
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
    func workOrderTaskCollection(companyId:String,workOrderId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/workOrders/\(workOrderId)/tasks")
   }
    func workOrderTaskDocument(companyId:String,workOrderId:String,taskId:String)-> DocumentReference{
        workOrderTaskCollection(companyId: companyId,workOrderId: workOrderId).document(taskId)
   }
    //CREATE
    func uploadJobTask(companyId:String,jobId:String,task:JobTask) async throws {
        try workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: task.id)
            .setData(from:task, merge: false)
    }
    //READ
    func getJobTasks(companyId:String,jobId:String) async throws -> [JobTask] {
        return try await workOrderTaskCollection(companyId: companyId, workOrderId: jobId)
            .getDocuments(as:JobTask.self)
    }
    //UPDATE
    func updateJobTaskName(companyId:String,jobId:String,taskId:String,name:String) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
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
    func updateJobTaskType(companyId:String,jobId:String,taskId:String,type:String) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "type": type
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateJobTaskWorkerType(companyId:String,jobId:String,taskId:String,workerType:WorkerTypeEnum) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "workerType": workerType.rawValue
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateJobTaskWorkerName(companyId:String,jobId:String,taskId:String,workerName:String) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "workerName": workerName
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateJobTaskWorkerId(companyId:String,jobId:String,taskId:String,workerId:String) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "workerId": workerId
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateJobTaskStatus(companyId:String,jobId:String,taskId:String,status:JobTaskStatus) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
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
    func updateJobTaskServiceStopId(companyId:String,jobId:String,taskId:String,serviceStopId:IdInfo) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "serviceStopId":[
                    "id":serviceStopId.id,
                    "internalId":serviceStopId.internalId
                    ]
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateJobTaskLaborContractId(companyId:String,jobId:String,taskId:String,laborContractId:String) throws {
        let ref = workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: taskId)
        ref.updateData([
            "laborContractId":laborContractId
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
