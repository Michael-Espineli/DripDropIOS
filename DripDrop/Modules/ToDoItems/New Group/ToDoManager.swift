//
//  ToDoManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

struct ToDo:Identifiable,Codable{
    var id : String
    //Required ToDo Info
    var title : String
    var status : toDoStatus
    var description : String
    var dateCreated : Date
    
    //Optional Data
    var dateFinished : Date?
    var linkedCustomerId : String?
    var linkedJobId : String?

    var assignedTechId: String
    var creatorId : String
}

protocol ToDoManagerProtocol {
    func addNewToDo(companyId:String, todo:ToDo) async throws
    func getAllCompanyToDoItems(companyId:String) -> [ToDo]
    func getAllCompanyToDoItemsCount(companyId:String) -> Int
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]
    func getAllTechnicanToDoItemsCount(companyId:String,techId:String) async throws -> Int
    func getToDoCount(companyId:String) async throws -> Int
    //Update
    func updateToDoTitle(companyId:String,toDoId:String,newTitle:String) async throws
    func updateToDoStatus(companyId:String,toDoId:String,newStatus:toDoStatus) async throws
    func updateToDoDescription(companyId:String,toDoId:String,newDescription:String) async throws
    func updateToDoDateFinished(companyId:String,toDoId:String,newDateFinished:Date?) async throws
    func updateToDoCustomerId(companyId:String,toDoId:String,newCustomerId:String) async throws
    func updateToDoJobId(companyId:String,toDoId:String,newJobId:String) async throws
    func updateToDoTechId(companyId:String,toDoId:String,newTechId:String) async throws

    //Delete
    func deleteToDo(companyId:String,toDoId:String) async throws
}
final class ToDoManager:ToDoManagerProtocol {

    //Collections
    private func ToDoCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/toDos")
    }
    //Document
    private func ToDoDocument(toDoId:String,companyId:String)-> DocumentReference{
        ToDoCollection(companyId: companyId).document(toDoId)
    }
    //Created
    func addNewToDo(companyId:String, todo:ToDo) async throws {
        try ToDoDocument(toDoId: todo.id, companyId: companyId)
            .setData(from:todo, merge: false)
    }
    
    //Read
    func getAllCompanyToDoItems(companyId:String) -> [ToDo]{
        return [
            ToDo(id: "1", title: "Check Harold Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "2", title: "Check hey Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "3", title: "Check yum Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "4", title: "Check the Dude Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: "")
        ]
        
    }
    func getAllCompanyToDoItemsCount(companyId: String) -> Int {
        return 8
    }
    
    func getAllTechnicanToDoItemsCount(companyId: String, techId: String) async throws -> Int {

        let query = ToDoCollection(companyId: companyId).whereField("assignedTechId", isEqualTo: techId).whereField("status", isNotEqualTo: "Finished")
        let countQuery = query.count
        do {
          let snapshot = try await countQuery.getAggregation(source: .server)
          print(snapshot.count)
            return snapshot.count as! Int
        } catch {
            return 0
          print(error)
        }
    }
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]{
        return try await ToDoCollection(companyId: companyId)
            .whereField("assignedTechId", isEqualTo: techId)
            .getDocuments(as:ToDo.self)

    }

    //Update
    func updateToDoTitle(companyId:String,toDoId:String,newTitle:String) async throws {
       ToDoDocument(toDoId: toDoId, companyId: companyId)
           .updateData([
               "title": newTitle
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
    }
    func updateToDoStatus(companyId:String,toDoId:String,newStatus:toDoStatus) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "status": newStatus
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateToDoDescription(companyId:String,toDoId:String,newDescription:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "description": newDescription
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateToDoDateFinished(companyId:String,toDoId:String,newDateFinished:Date?) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "dateFinished": newDateFinished
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateToDoCustomerId(companyId:String,toDoId:String,newCustomerId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "customerId": newCustomerId
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateToDoJobId(companyId:String,toDoId:String,newJobId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "jobId": newJobId
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateToDoTechId(companyId:String,toDoId:String,newTechId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "newTechId": newTechId
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func getToDoCount(companyId:String) async throws -> Int {
        var toDoCount = 0
        let doc = try await Firestore.firestore().collection("companies/\(companyId)/settings").document("todos").getDocument(as: Increment.self)
        toDoCount = doc.increment
        let updatedServiceStopCount = toDoCount + 1
        Firestore.firestore().collection("companies/\(companyId)/settings").document("todos")
           .updateData([
               "increment": updatedServiceStopCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print("Service Stop Count " + String(toDoCount))
        return updatedServiceStopCount
    }
    //Delete
    func deleteToDo(companyId:String,toDoId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId).delete()
    }
}
