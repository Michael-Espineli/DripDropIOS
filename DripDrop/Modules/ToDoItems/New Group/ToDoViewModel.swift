//
//  ToDoViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ToDoViewModel:ObservableObject{
    @Published private(set) var toDoList:[ToDo] = []
    @Published private(set) var toDoListCount:Int? = nil

    let dataService : any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //CREATE

    func createToDoWithValidation(companyId:String, title: String, status: toDoStatus, description: String, dateCreated: Date, dateFinished: Date?, linkedCustomerId: String?, linkedJobId: String?, assignedTechId: String, creatorId: String) async throws{
        //Check All Values of Todo
        if assignedTechId == "" {
            throw ToDoError.invalidTechId
        }
    
        if title == "" {
            throw ToDoError.invalidTitle
        }
        var pushJobId:String? = nil
        var pushCustomerId:String? = nil

        if linkedJobId == "" {
            pushJobId = nil
        } else {
            pushJobId = linkedJobId
        }
        if linkedCustomerId == "" {
            pushCustomerId = nil
        } else {
            pushCustomerId = linkedCustomerId
        }
        //Try and get Id For ToDo
        let toDoId = "T" + String(try await dataService.getToDoCount(companyId: companyId))
        try await dataService.addNewToDo(companyId: companyId, todo: ToDo(id: toDoId, title: title, status: status, description: description, dateCreated: dateCreated, dateFinished: nil, linkedCustomerId: pushCustomerId, linkedJobId: pushJobId, assignedTechId: assignedTechId, creatorId: creatorId))
    }

    //READ
    func readToDoCompanyList(companyId:String) async throws {
        self.toDoList = try await dataService.getAllCompanyToDoItems(companyId: companyId)
    }
    func readToDoCompanyListCount(companyId:String) async throws {
        self.toDoListCount = try await dataService.getAllCompanyToDoItemsCount(companyId: companyId)
    }
    func readToDoTechList(companyId:String,techId:String) async throws {
        self.toDoList = try await dataService.getAllTechnicanToDoItems(companyId: companyId, techId: techId)
    }
    func readToDoTechListCount(companyId:String,techId:String) async throws {
        self.toDoListCount = try await dataService.getAllTechnicanToDoItemsCount(companyId: companyId, techId: techId)
    }
    
    //UPDATE
    func updateToDoWithValidation(companyId:String, title: String, status: toDoStatus, description: String,dateFinished: Date?, linkedCustomerId: String?, linkedJobId: String?, assignedTechId: String,toDo:ToDo) async throws{
        if status != toDo.status {
            print("Change in To Do")
            try await dataService.updateToDoStatus(companyId: companyId, toDoId: toDo.id, newStatus: status)
            switch status {
                
            case .toDo:
                try await dataService.updateToDoDateFinished(companyId: companyId, toDoId: toDo.id, newDateFinished: nil)
            case .inProgress:
                try await dataService.updateToDoDateFinished(companyId: companyId, toDoId: toDo.id, newDateFinished: nil)

            case .finished:
                try await dataService.updateToDoDateFinished(companyId: companyId, toDoId: toDo.id, newDateFinished: dateFinished)

            }
        }
        if title != toDo.title {
            print("Change in To Do")
            try await dataService.updateToDoTitle(companyId: companyId, toDoId: toDo.id, newTitle: title)
        }
        if description != toDo.description {
            print("Change in To Do")
            try await dataService.updateToDoDescription(companyId: companyId, toDoId: toDo.id, newDescription: description)
        }
        if let customerId = linkedCustomerId {
            if customerId != toDo.linkedCustomerId {
                print("Change in To Do")
                try await dataService.updateToDoCustomerId(companyId: companyId, toDoId: toDo.id, newCustomerId: customerId)
            }
        }
        if let jobId = linkedJobId {
            if jobId != toDo.linkedJobId {
                print("Change in To Do")
                try await dataService.updateToDoJobId(companyId: companyId, toDoId: toDo.id, newJobId: jobId)
            }
        }
            if assignedTechId != toDo.assignedTechId {
                print("Change in To Do")
                try await dataService.updateToDoTechId(companyId: companyId, toDoId: toDo.id, newTechId: assignedTechId)
            }
        
    }
    
    //DELETE
    func deleteToDoItem(companyId:String,toDoId:String) async throws {
        try await dataService.deleteToDo(companyId: companyId, toDoId: toDoId)
    }
}
