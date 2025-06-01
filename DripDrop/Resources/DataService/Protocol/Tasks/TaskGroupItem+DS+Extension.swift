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

struct JobTaskGroupItem:Identifiable, Codable, Equatable{
    var id:String
    var name:String
    var type:String
    var description:String
    var contractedRate:Int // Cents
    var estimatedTime:Int // Seconds
    
    static func == (lhs: JobTaskGroupItem, rhs: JobTaskGroupItem) -> Bool {
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
        
    }
    //READ
    func getAllTaskGroupById(companyId:String,taskGroupId:String) async throws -> JobTaskGroup {
        return try await TaskGroupDocument(companyId: companyId, taskGroupId: taskGroupId)
            .getDocument(as: JobTaskGroup.self)

    }
    func getAllTaskGroups(companyId:String) async throws ->[JobTaskGroup] {
        return try await TaskGroupCollection(companyId: companyId)
            .getDocuments(as:JobTaskGroup.self)
    }
    //UPDATE
    
    //DELETE
    
}
