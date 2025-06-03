//
//  TaskGroup+DS+Extension.swift
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

struct JobTaskGroup:Identifiable, Codable, Equatable{
    var id:String
    var name:String
    var description:String
    var numberOfTasks:Int
    static func == (lhs: JobTaskGroup, rhs: JobTaskGroup) -> Bool {
        return lhs.id == rhs.id
    }
}
extension ProductionDataService {
    func TaskGroupSettingsDocument(companyId:String) -> DocumentReference{
        db.collection("companies/\(companyId)/settings").document("taskGroup")
   }
     func TaskGroupCollection(companyId:String) -> CollectionReference{
         db.collection("companies/\(companyId)/settings/taskGroup/taskGroup")
    }
      func TaskGroupDocument(companyId:String,taskGroupId:String)-> DocumentReference{
          TaskGroupCollection(companyId: companyId).document(taskGroupId)
     }
    //CREATE
    func uploadNewTaskGroup(companyId:String,taskGroup:JobTaskGroup) async throws {
        try TaskGroupDocument(companyId: companyId, taskGroupId: taskGroup.id)
            .setData(from:taskGroup, merge: false)
    }
    //READ
    func getAllTaskGroupById(companyId:String,taskGroupId:String) async throws -> JobTaskGroup {
        return try await TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .getDocument(as: JobTaskGroup.self)

    }
    func getAllTaskGroups(companyId:String) async throws ->[JobTaskGroup] {
        print("trying to getAllTaskGroups")
        return try await TaskGroupCollection(companyId: companyId)
            .getDocuments(as:JobTaskGroup.self)
    }
    //UPDATE
    func updateTaskGroupName(companyId: String, taskGroupId: String, name: String) async throws {
        try await  TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .updateData([
                "name":name
            ])
    }
    func updateTaskGroupDescription(companyId: String, taskGroupId: String, description: String) async throws {
        try await  TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .updateData([
                "description":description
            ])
    }
    func updateTaskGroupNumberOfTasks(companyId: String, taskGroupId: String, numberOfTasks: Int) async throws {
        try await  TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .updateData([
                "numberOfTasks":numberOfTasks
            ])
    }
    //DELETE
    func deleteTaskGroup(companyId:String,taskGroupId:String) async throws {
        try await TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .delete()
    }
    
}
