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
    @Published private(set) var selectedToDo: ToDo? = nil
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    let dataService : any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //CREATE

    func createToDoWithValidation(
        companyId:String,
        title: String,
        status: toDoStatus,
        description: String,
        dateCreated: Date,
        dateFinished: Date?,
        linkedCustomerId: String?,
        linkedJobId: String?,
        assignedTechId: String,
        creatorId: String,
        assignedToCompanyUserDocId: String = "",
        assignedToName: String = "",
        createdByName: String = "",
        priority: String = "normal",
        dueAt: Date? = nil,
        reminderAt: Date? = nil,
        reminderEnabled: Bool = false,
        relatedEntity: ToDoRelatedEntity? = nil,
        boardId: String = "",
        boardName: String = "Mobile",
        scope: String? = nil,
        assignmentType: String? = nil
    ) async throws{
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAssignedTechId = assignedTechId.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedScope = scope ?? (cleanAssignedTechId.isEmpty ? "team" : "specific")
        let resolvedAssignmentType = assignmentType ?? resolvedScope

        if resolvedAssignmentType != "team" && cleanAssignedTechId.isEmpty {
            throw ToDoError.invalidTechId
        }
    
        if cleanTitle == "" {
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
        let normalizedPriority: String
        switch priority.lowercased() {
        case "low", "high", "urgent":
            normalizedPriority = priority.lowercased()
        default:
            normalizedPriority = "normal"
        }

        let toDoId = "todo_ios_\(UUID().uuidString)"
        try await dataService.addNewToDo(
            companyId: companyId,
            todo: ToDo(
                id: toDoId,
                title: cleanTitle,
                status: status,
                description: cleanDescription,
                dateCreated: dateCreated,
                dateFinished: nil,
                linkedCustomerId: pushCustomerId,
                linkedJobId: pushJobId,
                assignedTechId: cleanAssignedTechId,
                creatorId: creatorId,
                companyId: companyId,
                boardId: boardId,
                boardName: boardName,
                scope: resolvedScope,
                assignmentType: resolvedAssignmentType,
                assignedToUserId: cleanAssignedTechId,
                assignedToCompanyUserDocId: assignedToCompanyUserDocId,
                assignedToName: assignedToName,
                priority: normalizedPriority,
                dueAt: dueAt,
                reminderAt: reminderAt,
                reminderEnabled: reminderEnabled,
                relatedEntity: relatedEntity,
                source: "ios",
                createdByName: createdByName,
                updatedByUserId: creatorId,
                updatedByName: createdByName,
                updatedAt: dateCreated,
                completedAt: status == .finished ? dateCreated : nil
            )
        )
    }

    //READ
    func readToDoCompanyList(companyId:String) async throws {
        isLoading = true
        defer { isLoading = false }
        self.toDoList = try await dataService.getAllCompanyToDoItems(companyId: companyId)
    }
    func readToDoCompanyListCount(companyId:String) async throws {
        self.toDoListCount = try await dataService.getAllCompanyToDoItemsCount(companyId: companyId)
    }
    func readToDoTechList(companyId:String,techId:String) async throws {
        isLoading = true
        defer { isLoading = false }
        self.toDoList = try await dataService.getAllTechnicanToDoItems(companyId: companyId, techId: techId)
    }
    func readToDoTechListCount(companyId:String,techId:String) async throws {
        self.toDoListCount = try await dataService.getAllTechnicanToDoItemsCount(companyId: companyId, techId: techId)
    }

    func readToDo(companyId:String,toDoId:String) async throws {
        isLoading = true
        defer { isLoading = false }
        selectedToDo = try await dataService.getToDo(companyId: companyId, toDoId: toDoId)
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
