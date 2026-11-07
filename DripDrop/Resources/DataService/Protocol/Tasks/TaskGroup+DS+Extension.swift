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

struct JobTaskGroup: Identifiable, Codable, Equatable, Hashable {
    var id: String

    var name: String
    var description: String

    var defaultServiceStopTypeId: String?
    var defaultServiceStopTypeName: String?

    var numberOfTasks: Int
    var estimatedMinutes: Int
    var estimatedLaborCents: Int

    var isActive: Bool
    var createdAt: Date
    var createdByUserId: String

    static func == (lhs: JobTaskGroup, rhs: JobTaskGroup) -> Bool {
        lhs.id == rhs.id
    }
}
// Defaults preserve historical groupName-only and web-created records.
// Keep this initializer in an extension to retain the memberwise initializer used by forms.
extension JobTaskGroup {
    private enum StorageKeys: String, CodingKey {
        case id, name, groupName, description, defaultServiceStopTypeId, defaultServiceStopTypeName
        case numberOfTasks, estimatedMinutes, estimatedLaborCents, isActive, createdAt, createdByUserId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StorageKeys.self)
        id = try values.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try values.decodeIfPresent(String.self, forKey: .name)
            ?? values.decodeIfPresent(String.self, forKey: .groupName) ?? "Task Group"
        description = try values.decodeIfPresent(String.self, forKey: .description) ?? ""
        defaultServiceStopTypeId = try values.decodeIfPresent(String.self, forKey: .defaultServiceStopTypeId)
        defaultServiceStopTypeName = try values.decodeIfPresent(String.self, forKey: .defaultServiceStopTypeName)
        numberOfTasks = try values.decodeIfPresent(Int.self, forKey: .numberOfTasks) ?? 0
        estimatedMinutes = try values.decodeIfPresent(Int.self, forKey: .estimatedMinutes) ?? 0
        estimatedLaborCents = try values.decodeIfPresent(Int.self, forKey: .estimatedLaborCents) ?? 0
        isActive = try values.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date(timeIntervalSince1970: 0)
        createdByUserId = try values.decodeIfPresent(String.self, forKey: .createdByUserId) ?? ""
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
        let document = try await TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId).getDocument()
        var group = try document.data(as: JobTaskGroup.self)
        group.id = document.documentID
        return group
    }
    func getAllTaskGroups(companyId:String) async throws ->[JobTaskGroup] {
        print("trying to getAllTaskGroups")
        let snapshot = try await TaskGroupCollection(companyId: companyId).getDocuments()
        return try snapshot.documents.map { document in
            var group = try document.data(as: JobTaskGroup.self)
            group.id = document.documentID
            return group
        }
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
