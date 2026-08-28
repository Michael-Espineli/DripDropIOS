//
//  PerformaceHistoryViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import Foundation
import FirebaseFirestore

enum PerformaceHistoryType: String, Codable, CaseIterable, Identifiable {
    case kudo = "kudo"
    case complaint = "complaint"
    case coaching = "coaching"
    case observation = "observation"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kudo:
            return "Praise"
        case .complaint:
            return "Complaint"
        case .coaching:
            return "Coaching"
        case .observation:
            return "Observation"
        }
    }

    var systemImage: String {
        switch self {
        case .kudo:
            return "hand.thumbsup.fill"
        case .complaint:
            return "exclamationmark.bubble.fill"
        case .coaching:
            return "bubble.left.and.text.bubble.right.fill"
        case .observation:
            return "eye.fill"
        }
    }

    var tint: String {
        switch self {
        case .kudo:
            return "green"
        case .complaint:
            return "red"
        case .coaching:
            return "blue"
        case .observation:
            return "orange"
        }
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        self = PerformaceHistoryType.normalized(value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func normalized(_ value: String) -> PerformaceHistoryType {
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "kudo", "praise":
            return .kudo
        case "complaint":
            return .complaint
        case "coaching":
            return .coaching
        case "observation":
            return .observation
        default:
            return .observation
        }
    }
}

struct PerformanceHistoryReference: Codable, Identifiable, Hashable {
    var id: String
    var type: String
    var label: String
    var path: String?
}

struct PerformanceHistoryReferences: Codable, Hashable {
    var serviceStops: [PerformanceHistoryReference] = []
    var jobs: [PerformanceHistoryReference] = []

    var totalCount: Int {
        serviceStops.count + jobs.count
    }

    static let empty = PerformanceHistoryReferences()
}

struct PerformanceHistoryAttachment: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var title: String
    var url: String
    var contentType: String
    var size: Int
    var storagePath: String
    var isTechnicianVisible: Bool
}

struct PerformanceHistoryAttachedReport: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var url: String
    var notes: String
    var isTechnicianVisible: Bool
    var attachments: [PerformanceHistoryAttachment]
}

struct PerformaceHistory: Codable, Identifiable, Hashable {
    var id: String
    var userId: String
    var userName: String
    var date: Date
    var description: String
    var photoUrls: [DripDropStoredImage]
    var performaceHistoryType: PerformaceHistoryType

    var title: String
    var references: PerformanceHistoryReferences
    var attachedReports: [PerformanceHistoryAttachedReport]
    var attachments: [PerformanceHistoryAttachment]
    var visibleToTechnician: Bool
    var isSummaryReport: Bool
    var companyInternal: Bool
    var companyId: String
    var companyUserId: String
    var technicianUserId: String
    var createdByUserId: String
    var createdByName: String
    var createdAt: Date?
    var updatedAt: Date?

    init(
        id: String,
        userId: String,
        userName: String,
        date: Date,
        description: String,
        photoUrls: [DripDropStoredImage],
        performaceHistoryType: PerformaceHistoryType,
        title: String = "",
        references: PerformanceHistoryReferences = .empty,
        attachedReports: [PerformanceHistoryAttachedReport] = [],
        attachments: [PerformanceHistoryAttachment] = [],
        visibleToTechnician: Bool = false,
        isSummaryReport: Bool = false,
        companyInternal: Bool = true,
        companyId: String = "",
        companyUserId: String = "",
        technicianUserId: String = "",
        createdByUserId: String = "",
        createdByName: String = "Management",
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.date = date
        self.description = description
        self.photoUrls = photoUrls
        self.performaceHistoryType = performaceHistoryType
        self.title = title
        self.references = references
        self.attachedReports = attachedReports
        self.attachments = attachments
        self.visibleToTechnician = visibleToTechnician
        self.isSummaryReport = isSummaryReport
        self.companyInternal = companyInternal
        self.companyId = companyId
        self.companyUserId = companyUserId
        self.technicianUserId = technicianUserId
        self.createdByUserId = createdByUserId
        self.createdByName = createdByName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(id documentId: String, data: [String: Any]) {
        let typeValue = Self.stringValue(data["type"]) ?? Self.stringValue(data["performaceHistoryType"]) ?? "observation"
        let dateValue = Self.dateValue(data["date"]) ?? Self.dateValue(data["createdAt"]) ?? Date()
        let note = Self.stringValue(data["note"]) ?? Self.stringValue(data["description"]) ?? ""
        let companyUserIdValue = Self.stringValue(data["companyUserId"]) ?? Self.stringValue(data["userId"]) ?? ""
        let technicianUserIdValue = Self.stringValue(data["technicianUserId"]) ?? Self.stringValue(data["userId"]) ?? ""
        let technicianName = Self.stringValue(data["technicianName"]) ?? Self.stringValue(data["userName"]) ?? ""

        self.init(
            id: documentId,
            userId: companyUserIdValue,
            userName: technicianName,
            date: dateValue,
            description: note,
            photoUrls: Self.photoUrls(data["photoUrls"]),
            performaceHistoryType: .normalized(typeValue),
            title: Self.stringValue(data["title"]) ?? "",
            references: Self.references(data["references"]),
            attachedReports: Self.attachedReports(data["attachedReports"]),
            attachments: Self.attachments(data["attachments"]),
            visibleToTechnician: Self.boolValue(data["visibleToTechnician"]) ?? false,
            isSummaryReport: Self.boolValue(data["isSummaryReport"]) ?? false,
            companyInternal: Self.boolValue(data["companyInternal"]) ?? true,
            companyId: Self.stringValue(data["companyId"]) ?? "",
            companyUserId: companyUserIdValue,
            technicianUserId: technicianUserIdValue,
            createdByUserId: Self.stringValue(data["createdByUserId"]) ?? "",
            createdByName: Self.stringValue(data["createdByName"]) ?? "Management",
            createdAt: Self.dateValue(data["createdAt"]),
            updatedAt: Self.dateValue(data["updatedAt"])
        )
    }

    func firestorePayload(companyId: String, companyUser: CompanyUser) -> [String: Any] {
        [
            "type": performaceHistoryType.rawValue,
            "note": description.trimmingCharacters(in: .whitespacesAndNewlines),
            "date": date,
            "references": [
                "serviceStops": references.serviceStops.map(Self.referencePayload),
                "jobs": references.jobs.map(Self.referencePayload),
            ],
            "attachedReports": attachedReports.map(Self.reportPayload),
            "attachments": attachments.map(Self.attachmentPayload),
            "visibleToTechnician": visibleToTechnician,
            "isSummaryReport": isSummaryReport,
            "companyInternal": companyInternal,
            "companyId": companyId,
            "companyUserId": companyUser.id,
            "technicianUserId": companyUser.userId,
            "technicianName": companyUser.userName,
            "createdByUserId": createdByUserId,
            "createdByName": createdByName.isEmpty ? "Management" : createdByName,
            "createdAt": createdAt ?? Date(),
            "updatedAt": updatedAt ?? Date(),
        ]
    }

    var fileAndReportCount: Int {
        attachments.count + attachedReports.count
    }

    private static func stringValue(_ value: Any?) -> String? {
        value as? String
    }

    private static func boolValue(_ value: Any?) -> Bool? {
        value as? Bool
    }

    private static func dateValue(_ value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        return nil
    }

    private static func references(_ value: Any?) -> PerformanceHistoryReferences {
        guard let dictionary = value as? [String: Any] else { return .empty }

        return PerformanceHistoryReferences(
            serviceStops: referenceList(dictionary["serviceStops"]),
            jobs: referenceList(dictionary["jobs"])
        )
    }

    private static func referenceList(_ value: Any?) -> [PerformanceHistoryReference] {
        guard let dictionaries = value as? [[String: Any]] else { return [] }

        return dictionaries.compactMap { dictionary in
            guard let id = stringValue(dictionary["id"]) else { return nil }
            return PerformanceHistoryReference(
                id: id,
                type: stringValue(dictionary["type"]) ?? "",
                label: stringValue(dictionary["label"]) ?? id,
                path: stringValue(dictionary["path"])
            )
        }
    }

    private static func attachedReports(_ value: Any?) -> [PerformanceHistoryAttachedReport] {
        guard let dictionaries = value as? [[String: Any]] else { return [] }

        return dictionaries.enumerated().map { index, dictionary in
            PerformanceHistoryAttachedReport(
                id: stringValue(dictionary["id"]) ?? "report_\(index)",
                title: stringValue(dictionary["title"]) ?? "Report",
                url: stringValue(dictionary["url"]) ?? "",
                notes: stringValue(dictionary["notes"]) ?? "",
                isTechnicianVisible: boolValue(dictionary["isTechnicianVisible"]) ?? false,
                attachments: attachments(dictionary["attachments"])
            )
        }
    }

    private static func attachments(_ value: Any?) -> [PerformanceHistoryAttachment] {
        guard let dictionaries = value as? [[String: Any]] else { return [] }

        return dictionaries.enumerated().compactMap { index, dictionary in
            let url = stringValue(dictionary["url"]) ?? stringValue(dictionary["downloadUrl"]) ?? ""
            guard !url.isEmpty else { return nil }

            return PerformanceHistoryAttachment(
                id: stringValue(dictionary["id"]) ?? "file_\(index)",
                name: stringValue(dictionary["name"]) ?? stringValue(dictionary["title"]) ?? "Attachment",
                title: stringValue(dictionary["title"]) ?? stringValue(dictionary["name"]) ?? "Attachment",
                url: url,
                contentType: stringValue(dictionary["contentType"]) ?? "",
                size: dictionary["size"] as? Int ?? 0,
                storagePath: stringValue(dictionary["storagePath"]) ?? "",
                isTechnicianVisible: boolValue(dictionary["isTechnicianVisible"]) ?? false
            )
        }
    }

    private static func photoUrls(_ value: Any?) -> [DripDropStoredImage] {
        guard let dictionaries = value as? [[String: Any]] else { return [] }

        return dictionaries.compactMap { dictionary in
            guard let url = stringValue(dictionary["imageURL"]) ?? stringValue(dictionary["url"]) else { return nil }
            return DripDropStoredImage(
                id: stringValue(dictionary["id"]) ?? UUID().uuidString,
                description: stringValue(dictionary["description"]) ?? stringValue(dictionary["name"]) ?? "Photo",
                imageURL: url
            )
        }
    }

    private static func referencePayload(_ reference: PerformanceHistoryReference) -> [String: Any] {
        [
            "id": reference.id,
            "type": reference.type,
            "label": reference.label,
            "path": reference.path ?? "",
        ]
    }

    private static func reportPayload(_ report: PerformanceHistoryAttachedReport) -> [String: Any] {
        [
            "id": report.id,
            "title": report.title,
            "url": report.url,
            "notes": report.notes,
            "isTechnicianVisible": report.isTechnicianVisible,
            "attachments": report.attachments.map(attachmentPayload),
            "attachedAt": Date(),
        ]
    }

    private static func attachmentPayload(_ attachment: PerformanceHistoryAttachment) -> [String: Any] {
        [
            "id": attachment.id,
            "name": attachment.name,
            "title": attachment.title,
            "url": attachment.url,
            "contentType": attachment.contentType,
            "size": attachment.size,
            "storagePath": attachment.storagePath,
            "isTechnicianVisible": attachment.isTechnicianVisible,
            "attachedAt": Date(),
        ]
    }
}

@MainActor
final class PerformaceHistoryViewModel:ObservableObject{
    @Published var performaceHistoryList:[PerformaceHistory] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var alertMessage = ""
    @Published var showAlert = false

    let dataService:any ProductionDataServiceProtocol
    
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    func createNewPerformanceReview(companyId:String,companyUser:CompanyUser,performaceHistory:PerformaceHistory) async throws {
        isSaving = true
        defer { isSaving = false }

        try await dataService.createNewPerformanceReview(
            companyId: companyId,
            companyUser: companyUser,
            performaceHistory: performaceHistory
        )
    }

    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws {
        isLoading = true
        defer { isLoading = false }

        self.performaceHistoryList = try await dataService.getPerformaceReivewByUserId(
            companyId: companyId,
            companyUserId: companyUserId
        )
    }
}
