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
    //Delete
}
