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

struct ToDoRelatedEntity: Codable, Hashable {
    var type: String
    var id: String
    var label: String
}

struct ToDo: Identifiable, Codable {
    var id: String
    var companyId: String?
    var title: String
    var status: toDoStatus
    var statusRaw: String
    var description: String
    var dateCreated: Date
    
    // Old iOS compatibility fields.
    var dateFinished: Date?
    var linkedCustomerId: String?
    var linkedJobId: String?
    var assignedTechId: String
    var creatorId: String

    // New web todoItems fields.
    var boardId: String
    var boardName: String
    var boardMemberUserIds: [String]
    var boardMemberNames: [String]
    var scope: String
    var assignmentType: String
    var assignedToUserId: String
    var assignedToCompanyUserDocId: String
    var assignedToName: String
    var priority: String
    var dueAt: Date?
    var reminderAt: Date?
    var reminderEnabled: Bool
    var relatedEntity: ToDoRelatedEntity?
    var source: String
    var createdByUserId: String
    var createdByName: String
    var updatedByUserId: String
    var updatedByName: String
    var updatedAt: Date?
    var completedAt: Date?

    init(
        id: String,
        title: String,
        status: toDoStatus,
        description: String,
        dateCreated: Date,
        dateFinished: Date?,
        linkedCustomerId: String? = nil,
        linkedJobId: String? = nil,
        assignedTechId: String,
        creatorId: String,
        companyId: String? = nil,
        boardId: String = "",
        boardName: String = "",
        boardMemberUserIds: [String] = [],
        boardMemberNames: [String] = [],
        scope: String = "specific",
        assignmentType: String = "specific",
        assignedToUserId: String? = nil,
        assignedToCompanyUserDocId: String = "",
        assignedToName: String = "",
        priority: String = "normal",
        dueAt: Date? = nil,
        reminderAt: Date? = nil,
        reminderEnabled: Bool = false,
        relatedEntity: ToDoRelatedEntity? = nil,
        source: String = "ios",
        createdByName: String = "",
        updatedByUserId: String = "",
        updatedByName: String = "",
        updatedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.title = title
        self.status = status
        self.statusRaw = status.todoItemValue
        self.description = description
        self.dateCreated = dateCreated
        self.dateFinished = dateFinished
        self.linkedCustomerId = linkedCustomerId
        self.linkedJobId = linkedJobId
        self.assignedTechId = assignedTechId
        self.creatorId = creatorId
        self.boardId = boardId
        self.boardName = boardName
        self.boardMemberUserIds = boardMemberUserIds
        self.boardMemberNames = boardMemberNames
        self.scope = scope
        self.assignmentType = assignmentType
        self.assignedToUserId = assignedToUserId ?? assignedTechId
        self.assignedToCompanyUserDocId = assignedToCompanyUserDocId
        self.assignedToName = assignedToName
        self.priority = priority
        self.dueAt = dueAt
        self.reminderAt = reminderAt
        self.reminderEnabled = reminderEnabled
        self.relatedEntity = relatedEntity
        self.source = source
        self.createdByUserId = creatorId
        self.createdByName = createdByName
        self.updatedByUserId = updatedByUserId
        self.updatedByName = updatedByName
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    init(document: QueryDocumentSnapshot) {
        self.init(id: document.documentID, data: document.data())
    }

    init(document: DocumentSnapshot) {
        self.init(id: document.documentID, data: document.data() ?? [:])
    }

    init(id fallbackId: String, data: [String: Any]) {
        let rawStatus = Self.stringValue(data["status"], fallback: "open")
        let createdDate = Self.dateValue(data["createdAt"]) ?? Self.dateValue(data["dateCreated"]) ?? Date()
        let finishedDate = Self.dateValue(data["completedAt"]) ?? Self.dateValue(data["dateFinished"])
        let assignedUserId = Self.stringValue(data["assignedToUserId"], fallback: Self.stringValue(data["assignedTechId"]))
        let createdUserId = Self.stringValue(data["createdByUserId"], fallback: Self.stringValue(data["creatorId"]))

        id = Self.stringValue(data["id"], fallback: fallbackId)
        companyId = Self.optionalStringValue(data["companyId"])
        title = Self.stringValue(data["title"], fallback: "Untitled todo")
        status = toDoStatus(todoItemValue: rawStatus)
        statusRaw = rawStatus
        description = Self.stringValue(data["description"])
        dateCreated = createdDate
        dateFinished = finishedDate
        linkedCustomerId = Self.optionalStringValue(data["linkedCustomerId"]) ?? Self.optionalStringValue(data["customerId"])
        linkedJobId = Self.optionalStringValue(data["linkedJobId"]) ?? Self.optionalStringValue(data["jobId"])
        assignedTechId = assignedUserId
        creatorId = createdUserId
        boardId = Self.stringValue(data["boardId"])
        boardName = Self.stringValue(data["boardName"])
        boardMemberUserIds = Self.stringArrayValue(data["boardMemberUserIds"])
        boardMemberNames = Self.stringArrayValue(data["boardMemberNames"])
        scope = Self.stringValue(data["scope"], fallback: "team")
        assignmentType = Self.stringValue(data["assignmentType"], fallback: scope)
        assignedToUserId = assignedUserId
        assignedToCompanyUserDocId = Self.stringValue(data["assignedToCompanyUserDocId"])
        assignedToName = Self.stringValue(data["assignedToName"], fallback: "Team task")
        priority = Self.stringValue(data["priority"], fallback: "normal")
        dueAt = Self.dateValue(data["dueAt"])
        reminderAt = Self.dateValue(data["reminderAt"])
        reminderEnabled = Self.boolValue(data["reminderEnabled"])
        relatedEntity = Self.relatedEntityValue(data["relatedEntity"])
        source = Self.stringValue(data["source"], fallback: "web")
        createdByUserId = createdUserId
        createdByName = Self.stringValue(data["createdByName"], fallback: "Company user")
        updatedByUserId = Self.stringValue(data["updatedByUserId"])
        updatedByName = Self.stringValue(data["updatedByName"])
        updatedAt = Self.dateValue(data["updatedAt"])
        completedAt = finishedDate
    }
}

extension ToDo {
    enum CodingKeys: String, CodingKey {
        case id
        case companyId
        case title
        case status
        case description
        case dateCreated
        case dateFinished
        case linkedCustomerId
        case linkedJobId
        case assignedTechId
        case creatorId
        case boardId
        case boardName
        case boardMemberUserIds
        case boardMemberNames
        case scope
        case assignmentType
        case assignedToUserId
        case assignedToCompanyUserDocId
        case assignedToName
        case priority
        case dueAt
        case reminderAt
        case reminderEnabled
        case relatedEntity
        case source
        case createdByUserId
        case createdByName
        case updatedByUserId
        case updatedByName
        case updatedAt
        case completedAt
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawStatus = try container.decodeIfPresent(String.self, forKey: .status) ?? "open"
        let createdDate = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? container.decodeIfPresent(Date.self, forKey: .dateCreated)
            ?? Date()
        let finishedDate = try container.decodeIfPresent(Date.self, forKey: .completedAt)
            ?? container.decodeIfPresent(Date.self, forKey: .dateFinished)
        let assignedUserId = try container.decodeIfPresent(String.self, forKey: .assignedToUserId)
            ?? container.decodeIfPresent(String.self, forKey: .assignedTechId)
            ?? ""
        let createdUserId = try container.decodeIfPresent(String.self, forKey: .createdByUserId)
            ?? container.decodeIfPresent(String.self, forKey: .creatorId)
            ?? ""

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        companyId = try container.decodeIfPresent(String.self, forKey: .companyId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled todo"
        status = toDoStatus(todoItemValue: rawStatus)
        statusRaw = rawStatus
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        dateCreated = createdDate
        dateFinished = finishedDate
        linkedCustomerId = try container.decodeIfPresent(String.self, forKey: .linkedCustomerId)
        linkedJobId = try container.decodeIfPresent(String.self, forKey: .linkedJobId)
        assignedTechId = assignedUserId
        creatorId = createdUserId
        boardId = try container.decodeIfPresent(String.self, forKey: .boardId) ?? ""
        boardName = try container.decodeIfPresent(String.self, forKey: .boardName) ?? ""
        boardMemberUserIds = try container.decodeIfPresent([String].self, forKey: .boardMemberUserIds) ?? []
        boardMemberNames = try container.decodeIfPresent([String].self, forKey: .boardMemberNames) ?? []
        scope = try container.decodeIfPresent(String.self, forKey: .scope) ?? "team"
        assignmentType = try container.decodeIfPresent(String.self, forKey: .assignmentType) ?? scope
        assignedToUserId = assignedUserId
        assignedToCompanyUserDocId = try container.decodeIfPresent(String.self, forKey: .assignedToCompanyUserDocId) ?? ""
        assignedToName = try container.decodeIfPresent(String.self, forKey: .assignedToName) ?? "Team task"
        priority = try container.decodeIfPresent(String.self, forKey: .priority) ?? "normal"
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        reminderAt = try container.decodeIfPresent(Date.self, forKey: .reminderAt)
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        relatedEntity = try container.decodeIfPresent(ToDoRelatedEntity.self, forKey: .relatedEntity)
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? "ios"
        createdByUserId = createdUserId
        createdByName = try container.decodeIfPresent(String.self, forKey: .createdByName) ?? "Company user"
        updatedByUserId = try container.decodeIfPresent(String.self, forKey: .updatedByUserId) ?? ""
        updatedByName = try container.decodeIfPresent(String.self, forKey: .updatedByName) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        completedAt = finishedDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(companyId, forKey: .companyId)
        try container.encode(title, forKey: .title)
        try container.encode(status.todoItemValue, forKey: .status)
        try container.encode(description, forKey: .description)
        try container.encode(dateCreated, forKey: .dateCreated)
        try container.encode(dateCreated, forKey: .createdAt)
        try container.encodeIfPresent(dateFinished, forKey: .dateFinished)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(linkedCustomerId, forKey: .linkedCustomerId)
        try container.encodeIfPresent(linkedJobId, forKey: .linkedJobId)
        try container.encode(assignedTechId, forKey: .assignedTechId)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(boardId, forKey: .boardId)
        try container.encode(boardName, forKey: .boardName)
        try container.encode(boardMemberUserIds, forKey: .boardMemberUserIds)
        try container.encode(boardMemberNames, forKey: .boardMemberNames)
        try container.encode(scope, forKey: .scope)
        try container.encode(assignmentType, forKey: .assignmentType)
        try container.encode(assignedToUserId, forKey: .assignedToUserId)
        try container.encode(assignedToCompanyUserDocId, forKey: .assignedToCompanyUserDocId)
        try container.encode(assignedToName, forKey: .assignedToName)
        try container.encode(priority, forKey: .priority)
        try container.encodeIfPresent(dueAt, forKey: .dueAt)
        try container.encodeIfPresent(reminderAt, forKey: .reminderAt)
        try container.encode(reminderEnabled, forKey: .reminderEnabled)
        try container.encodeIfPresent(relatedEntity, forKey: .relatedEntity)
        try container.encode(source, forKey: .source)
        try container.encode(createdByUserId, forKey: .createdByUserId)
        try container.encode(createdByName, forKey: .createdByName)
        try container.encode(updatedByUserId, forKey: .updatedByUserId)
        try container.encode(updatedByName, forKey: .updatedByName)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

extension ToDo {
    var statusKey: String {
        statusRaw
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    var isArchived: Bool {
        statusKey == "archived"
    }

    var isOpen: Bool {
        !["done", "finished", "complete", "completed", "archived"].contains(statusKey)
    }

    var needsAttention: Bool {
        guard isOpen else { return false }

        if dueState == .overdue || dueState == .today {
            return true
        }

        if reminderEnabled, let reminderAt {
            return reminderAt <= Date()
        }

        return false
    }

    var dueState: ToDoDueState {
        guard isOpen else { return .complete }
        guard let dueAt else { return .none }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        if dueAt < todayStart {
            return .overdue
        }

        if dueAt < tomorrowStart {
            return .today
        }

        return .upcoming
    }

    var issueKey: String {
        let compactId = id.uppercased().filter { $0.isLetter || $0.isNumber }
        let suffix = String(compactId.suffix(5))
        return "TODO-\(suffix.isEmpty ? "ITEM" : suffix)"
    }

    var priorityLabel: String {
        switch priority.lowercased() {
        case "urgent":
            return "Urgent"
        case "high":
            return "High"
        case "low":
            return "Low"
        default:
            return "Normal"
        }
    }

    var statusLabel: String {
        switch statusKey {
        case "inprogress":
            return "In Progress"
        case "done", "finished", "complete", "completed":
            return "Done"
        case "archived":
            return "Archived"
        default:
            return "Open"
        }
    }

    var dueLabel: String {
        switch dueState {
        case .overdue:
            return "Overdue \(shortDate(date: dueAt))"
        case .today:
            return "Today \(shortDate(date: dueAt))"
        case .upcoming:
            return "Due \(shortDate(date: dueAt))"
        case .complete:
            return "Complete"
        case .none:
            return "No due date"
        }
    }

    var assignmentLabel: String {
        if scope == "team" {
            return "Team task"
        }

        if scope == "me" {
            return "Assigned to me"
        }

        return assignedToName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Unassigned"
            : "Assigned to \(assignedToName)"
    }

    var detailLine: String {
        let board = boardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No board" : boardName
        return "\(board) | \(assignmentLabel)"
    }

    func isAssigned(to userId: String) -> Bool {
        assignedToUserId == userId || createdByUserId == userId || (scope == "me" && !assignedToUserId.isEmpty && assignedToUserId == userId)
    }

    static func sortByUrgency(_ left: ToDo, _ right: ToDo) -> Bool {
        if left.dueState.rank != right.dueState.rank {
            return left.dueState.rank < right.dueState.rank
        }

        let leftDue = left.dueAt ?? .distantFuture
        let rightDue = right.dueAt ?? .distantFuture
        if leftDue != rightDue {
            return leftDue < rightDue
        }

        let leftPriority = priorityRank(left.priority)
        let rightPriority = priorityRank(right.priority)
        if leftPriority != rightPriority {
            return leftPriority < rightPriority
        }

        return (left.dateCreated) > (right.dateCreated)
    }

    static func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "urgent":
            return 0
        case "high":
            return 1
        case "low":
            return 3
        default:
            return 2
        }
    }
}

enum ToDoDueState {
    case overdue
    case today
    case upcoming
    case none
    case complete

    var rank: Int {
        switch self {
        case .overdue:
            return 0
        case .today:
            return 1
        case .upcoming:
            return 2
        case .none:
            return 3
        case .complete:
            return 4
        }
    }
}

extension toDoStatus {
    init(todoItemValue: String) {
        let normalized = todoItemValue
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")

        switch normalized {
        case "inprogress":
            self = .inProgress
        case "done", "finished", "complete", "completed", "archived":
            self = .finished
        default:
            self = .toDo
        }
    }

    var todoItemValue: String {
        switch self {
        case .toDo:
            return "open"
        case .inProgress:
            return "inProgress"
        case .finished:
            return "done"
        }
    }
}

private extension ToDo {
    static func stringValue(_ value: Any?, fallback: String = "") -> String {
        if let value = value as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? fallback : trimmed
        }

        return fallback
    }

    static func optionalStringValue(_ value: Any?) -> String? {
        let value = stringValue(value)
        return value.isEmpty ? nil : value
    }

    static func stringArrayValue(_ value: Any?) -> [String] {
        if let value = value as? [String] {
            return value
        }

        if let value = value as? [Any] {
            return value.compactMap { $0 as? String }
        }

        return []
    }

    static func boolValue(_ value: Any?) -> Bool {
        if let value = value as? Bool {
            return value
        }

        if let value = value as? String {
            return ["true", "yes", "1"].contains(value.lowercased())
        }

        if let value = value as? Int {
            return value != 0
        }

        return false
    }

    static func dateValue(_ value: Any?) -> Date? {
        if let value = value as? Timestamp {
            return value.dateValue()
        }

        if let value = value as? Date {
            return value
        }

        if let value = value as? TimeInterval {
            return Date(timeIntervalSince1970: value)
        }

        if let value = value as? String {
            return ISO8601DateFormatter().date(from: value)
        }

        return nil
    }

    static func relatedEntityValue(_ value: Any?) -> ToDoRelatedEntity? {
        guard let value = value as? [String: Any] else { return nil }
        let type = stringValue(value["type"])
        let id = stringValue(value["id"])
        let label = stringValue(value["label"])

        if type.isEmpty && id.isEmpty && label.isEmpty {
            return nil
        }

        return ToDoRelatedEntity(type: type, id: id, label: label)
    }
}

protocol ToDoManagerProtocol {
    func addNewToDo(companyId:String, todo:ToDo) async throws
    func getToDo(companyId:String,toDoId:String) async throws -> ToDo
    func getAllCompanyToDoItems(companyId:String) async throws -> [ToDo]
    func getAllCompanyToDoItemsCount(companyId:String) async throws -> Int
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
        Firestore.firestore().collection("companies/\(companyId)/todoItems")
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
    func getToDo(companyId:String,toDoId:String) async throws -> ToDo {
        let snapshot = try await ToDoDocument(toDoId: toDoId, companyId: companyId).getDocument()
        return ToDo(document: snapshot)
    }

    func getAllCompanyToDoItems(companyId:String) async throws -> [ToDo]{
        let snapshot = try await ToDoCollection(companyId: companyId).getDocuments()
        return snapshot.documents
            .map { ToDo(document: $0) }
            .filter { !$0.isArchived }
            .sorted(by: ToDo.sortByUrgency)
    }
    func getAllCompanyToDoItemsCount(companyId: String) async throws -> Int {
        let query = ToDoCollection(companyId: companyId).whereField("status", isNotEqualTo: "archived")
        let snapshot = try await query.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    func getAllTechnicanToDoItemsCount(companyId: String, techId: String) async throws -> Int {

        let query = ToDoCollection(companyId: companyId).whereField("assignedToUserId", isEqualTo: techId).whereField("status", isNotEqualTo: "archived")
        let countQuery = query.count
        do {
          let snapshot = try await countQuery.getAggregation(source: .server)
          print(snapshot.count)
            return Int(truncating: snapshot.count)
        } catch {
            return 0
          print(error)
        }
    }
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]{
        let snapshot = try await ToDoCollection(companyId: companyId)
            .whereField("assignedToUserId", isEqualTo: techId)
            .getDocuments()
        return snapshot.documents
            .map { ToDo(document: $0) }
            .filter { !$0.isArchived }
            .sorted(by: ToDo.sortByUrgency)

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
                "status": newStatus.todoItemValue,
                "completedAt": newStatus == .finished ? FieldValue.serverTimestamp() : NSNull(),
                "updatedAt": FieldValue.serverTimestamp()
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
        let finishedValue: Any = newDateFinished.map { $0 as Any } ?? NSNull()

        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "completedAt": finishedValue,
                "dateFinished": finishedValue,
                "updatedAt": FieldValue.serverTimestamp()
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
                "assignedToUserId": newTechId,
                "assignedTechId": newTechId,
                "updatedAt": FieldValue.serverTimestamp()
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
