    //
    //  RecurringServiceStopTask+DS+Extension.swift
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
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


extension ProductionDataService {
    func RecurringServiceStopTaskCollection(companyId:String,recurringServiceStopId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/recurringServiceStop/\(recurringServiceStopId)/tasks")
    }
    func RecurringServiceStopTaskDocument(companyId:String,recurringServiceStopId:String,taskId:String)-> DocumentReference{
        RecurringServiceStopTaskCollection(companyId: companyId, recurringServiceStopId: recurringServiceStopId).document(taskId)
    }
    //Create
    func uploadRecurringServiceStopTask(companyId:String,recurringServiceStopId:String,task:RecurringServiceStopTask) async throws {
        try RecurringServiceStopTaskDocument(companyId: companyId,recurringServiceStopId: recurringServiceStopId,  taskId: task.id)
            .setData(from:task, merge: false)
    }
    //Read
    func getRecurringServiceStopTasks(companyId:String,recurringServiceStopId:String) async throws -> [RecurringServiceStopTask] {
        return try await RecurringServiceStopTaskCollection(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
            .getDocuments(as:RecurringServiceStopTask.self)
    }
    //Update
    func updateRecurringServiceStopTaskStatus(companyId:String,recurringServiceStopId:String,taskId:String,status:JobTaskStatus){
        let ref = RecurringServiceStopTaskDocument(companyId: companyId,recurringServiceStopId: recurringServiceStopId,  taskId: taskId)
        ref.updateData([
            "status": status.rawValue
        ])
    }
    //DELETE
    func deleteRecurringServiceStopTask(companyId:String,recurringServiceStopId:String,taskId:String) async throws {
        try await RecurringServiceStopTaskDocument(companyId: companyId,recurringServiceStopId: recurringServiceStopId,  taskId: taskId)
            .delete()
    }
}
