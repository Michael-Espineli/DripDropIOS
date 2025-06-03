//
//  TaskGroupItem+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit


extension ProductionDataService {
    func TaskGroupItemCollection(companyId:String,taskGroupId:String) -> CollectionReference{
         db.collection("companies/\(companyId)/settings/taskGroup/taskGroup/\(taskGroupId)/taskItems")
    }
    func TaskGroupItemDocument(companyId:String,taskGroupId:String,taskId:String)-> DocumentReference{
        TaskGroupItemCollection(companyId: companyId,taskGroupId: taskGroupId)
            .document(taskId)
     }
    //CREATE
    func uploadNewTaskGroupItem(companyId:String,taskGroupId:String,taskGroupItem:JobTaskGroupItem) async throws {
        try TaskGroupItemDocument(companyId: companyId, taskGroupId: taskGroupId, taskId: taskGroupItem.id)
            .setData(from:taskGroupItem, merge: false)
    }

    //READ
    func getTaskGroupItemById(companyId:String, taskGroupId:String,taskItemId:String) async throws -> JobTaskGroupItem {
        return try await TaskGroupItemDocument(companyId: companyId, taskGroupId: taskGroupId, taskId: taskItemId)
            .getDocument(as: JobTaskGroupItem.self)

    }
    func getAllTaskGroupItems(companyId:String, taskGroupId:String) async throws ->[JobTaskGroupItem] {
        return try await TaskGroupItemCollection(companyId: companyId, taskGroupId: taskGroupId)
            .getDocuments(as:JobTaskGroupItem.self)
    }
    //UPDATE
    
    //DELETE
    func deleteTaskGroupItem(companyId:String,taskGroupId:String,taskId:String) async throws {
        try await TaskGroupItemDocument(companyId: companyId, taskGroupId: taskGroupId, taskId: taskId)
            .delete()
    }
}
