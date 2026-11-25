//
//  ReportManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import JavaScriptCore
import UIKit

enum ReportType: Int, CaseIterable, Identifiable {
    
    var id: Int { rawValue }
    case funReadingsDosages
    case readings
    case readingHealth
    case readingPerformance
    case pnlPerPool
    case chemicals
    case waste
    case users
    case job
    case vehicle
    case purchases
    case payroll
    case futurePayroll
    case pnl
    case tax
    case pipeline // Append to preserve existing integer identities.
}

extension ReportType {
    enum Category: String, CaseIterable, Identifiable {
        case operations = "Operations"
        case marketing = "Marketing"
        case performance = "Performance"
        case finance = "Finance / Accounting"

        var id: String { rawValue }
    }
    
    var webKey: String {
        switch self {
        case .funReadingsDosages: return "funReadingsDosages"
        case .readings: return "readings"
        case .readingHealth: return "readingHealth"
        case .readingPerformance: return "readingPerformance"
        case .pnlPerPool: return "pnlPerPool"
        case .chemicals: return "chemicals"
        case .waste: return "waste"
        case .users: return "users"
        case .job: return "job"
        case .vehicle: return "vehicle"
        case .purchases: return "purchases"
        case .payroll: return "payroll"
        case .futurePayroll: return "futurePayroll"
        case .pnl: return "pnl"
        case .tax: return "tax"
        case .pipeline: return "pipeline"
        }
    }
    var title: String { ReportCatalogEntry.all.first { $0.value == webKey }?.label ?? webKey }
    var source: String { ReportCatalogEntry.all.first { $0.value == webKey }?.source ?? "" }
    var requiresPayroll: Bool { self == .payroll || self == .futurePayroll }
    var hasFixedGrouping: Bool { [.funReadingsDosages, .readingHealth, .readingPerformance, .pnlPerPool, .pipeline, .users, .vehicle].contains(self) }
    var category: Category {
        switch self {
        case .funReadingsDosages, .readings, .readingHealth, .chemicals, .users, .job, .vehicle:
            return .operations
        case .pipeline: return .marketing
        case .readingPerformance, .pnlPerPool, .waste:
            return .performance
        case .purchases, .payroll, .futurePayroll, .pnl, .tax:
            return .finance
        }
    }

    var isNativeGenerationReady: Bool { true }
    var generationStatusTitle: String { "Ready" }

    var systemImage: String {
        switch self {
        case .pipeline: return "line.3.horizontal.decrease.circle"
        case .funReadingsDosages:
            return "sparkles"
        case .readings:
            return "list.bullet.clipboard"
        case .readingHealth:
            return "heart.text.square.fill"
        case .readingPerformance:
            return "person.2.badge.gearshape.fill"
        case .pnlPerPool:
            return "chart.bar.xaxis"
        case .chemicals:
            return "testtube.2"
        case .waste:
            return "trash.fill"
        case .users:
            return "person.3.fill"
        case .job:
            return "briefcase.fill"
        case .vehicle:
            return "car.fill"
        case .purchases:
            return "cart.fill"
        case .payroll:
            return "person.crop.circle.badge.dollar"
        case .futurePayroll:
            return "calendar.badge.clock"
        case .pnl:
            return "chart.line.uptrend.xyaxis"
        case .tax:
            return "percent"
        }
    }

    var tint: Color {
        switch self {
        case .funReadingsDosages, .readings, .chemicals, .purchases:
            return .poolBlue
        case .readingHealth, .users, .pnl, .futurePayroll:
            return .poolGreen
        case .readingPerformance, .pnlPerPool, .waste:
            return .teal
        case .job, .tax:
            return .orange
        case .pipeline: return .indigo
        case .vehicle:
            return .gray
        case .payroll:
            return .purple
        }
    }
}


struct ReportCatalogEntry: Decodable {
    let value: String
    let label: String
    let source: String
    static let all: [ReportCatalogEntry] = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json", subdirectory: "ReportRuntime"),
              let data = try? Data(contentsOf: url), let catalog = try? JSONDecoder().decode([ReportCatalogEntry].self, from: data) else { return [] }
        return catalog
    }()
}

struct BooksControls: Codable, Equatable {
    var reportType = "readings"
    var mode = "summary"
    var groupBy = "company"
    var quickDateRange = "thisMonth"
    var dateRange = BooksDateRange.currentMonth
    var selectedCustomerTags: [String] = []
    var readingHealthFilters = BooksReadingRule()
    var readingPerformanceView = "users"
    var readingPerformanceStandards: [BooksReadingRule] = []
}
struct BooksDateRange: Codable, Equatable {
    var start: String
    var end: String
    static func string(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    static func date(_ string: String) -> Date {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX"); formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string) ?? Date()
    }
    static var currentMonth: Self {
        let interval = Calendar.current.dateInterval(of: .month, for: Date())!
        return Self(start: string(interval.start), end: string(interval.end.addingTimeInterval(-1)))
    }
    static func preset(_ key: String) -> Self {
        let calendar = Calendar.current, now = Date()
        switch key {
        case "thisMonth": return currentMonth
        case "lastMonth":
            let previous = calendar.date(byAdding: .month, value: -1, to: now)!
            let interval = calendar.dateInterval(of: .month, for: previous)!
            return Self(start: string(interval.start), end: string(interval.end.addingTimeInterval(-1)))
        case "thisWeek", "lastWeek":
            var sundayCalendar = calendar; sundayCalendar.firstWeekday = 1
            let date = key == "lastWeek" ? calendar.date(byAdding: .day, value: -7, to: now)! : now
            let interval = sundayCalendar.dateInterval(of: .weekOfYear, for: date)!
            return Self(start: string(interval.start), end: string(interval.end.addingTimeInterval(-1)))
        default:
            return Self(start: string(calendar.date(byAdding: .day, value: key == "last7Days" ? -6 : -29, to: now)!), end: string(now))
        }
    }
}
struct BooksReadingRule: Codable, Equatable, Identifiable {
    var id = UUID().uuidString
    var templateId = ""
    var `operator` = "gt"
    var threshold = ""
}
struct BooksReport: Decodable {
    struct Metric: Decodable { let label: String; let value: String; let subtitle: String? }
    struct Column: Decodable { let key: String; let label: String }
    struct Section: Decodable { let title: String; let columns: [Column]; let rows: [[String]] }
    struct ChartSection: Decodable {
        struct Item: Decodable {
            struct Point: Decodable { let date: String; let average: Double }
            let name: String
            let unit: String?
            let chartPoints: [Point]
        }
        let title: String
        let items: [Item]
    }
    let title: String
    let description: String
    let warnings: [String]
    let stats: [Metric]
    let total: Metric?
    let sections: [Section]
    struct IndividualUser: Decodable, Identifiable { let id: String; let name: String; let companyUserId: String }
    let individualUsers: [IndividualUser]
    let chartSections: [ChartSection]
}
struct BooksSavedReport: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let controls: [String: Any]
}

/// Executes only the signed app's bundled report code. No network or credentials enter JavaScript.
@MainActor
final class BooksEngine {
    private let context: JSContext
    init() throws {
        guard let context = JSContext(),
              let url = Bundle.main.url(forResource: "reports", withExtension: "js", subdirectory: "ReportRuntime") else {
            throw BooksFailure.message("The report engine is missing. Rebuild the iOS report resources.")
        }
        self.context = context
        context.evaluateScript(try String(contentsOf: url, encoding: .utf8))
        if let failure = context.exception { throw BooksFailure.message(failure.toString()) }
    }
    func call(_ name: String, arguments: [Any]) throws -> String {
        context.exception = nil
        let result = context.objectForKeyedSubscript("ReportRuntime")?.objectForKeyedSubscript(name)?.call(withArguments: arguments)
        if let failure = context.exception { throw BooksFailure.message(failure.toString()) }
        guard let string = result?.toString(), string != "undefined" else { throw BooksFailure.message("The report engine returned no result.") }
        return string
    }
    static func json(_ value: Any) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: normalized(value), options: [.sortedKeys]), as: UTF8.self)
    }
    private static func normalized(_ value: Any) -> Any {
        if let timestamp = value as? Timestamp { return normalized(timestamp.dateValue()) }
        if let date = value as? Date {
            let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: date)
        }
        if let reference = value as? DocumentReference { return ["id": reference.documentID] }
        if let values = value as? [String: Any] { return values.mapValues(normalized) }
        if let values = value as? [Any] { return values.map(normalized) }
        if value is NSNull || value is String || value is NSNumber { return value }
        return NSNull()
    }
}
enum BooksFailure: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(message) = self { return message }; return nil }
}

@MainActor
final class BooksViewModel: ObservableObject {
    @Published private(set) var report: BooksReport?
    @Published private(set) var loading = false
    @Published var error: String?
    @Published private(set) var ready = false
    @Published private(set) var accessRevision = UUID()
    @Published private(set) var templates: [[String: Any]] = []
    @Published private(set) var customerTags: [String] = []
    @Published private(set) var saved: [BooksSavedReport] = []
    @Published private(set) var busySaving = false
    @Published private(set) var savingPerformanceNote = false
    @Published private(set) var lastSavedReportId: String?
    @Published var notice: String?
    @Published var exportURL: URL?
    private var engine: BooksEngine?
    private var userListener: ListenerRegistration?
    private var roleListener: ListenerRegistration?
    private var session = UUID()
    private var roleSession = UUID()
    private var request = UUID()
    private var companyId = ""
    private var owner = false
    private var role: [String: Any] = [:]
    private var userAccess: [String: Any] = [:]
    private var reportIdentity = UUID().uuidString
    private var lastInput: String?
    private var generatedFiles: [URL] = []

    func can(_ permission: String) -> Bool {
        guard ready else { return false }
        let ids = role["permissionIdList"] as? [String] ?? []
        return owner || ids.contains(permission) || (permission == "420" && ids.contains("424"))
    }
    func invalidate() { request = UUID(); report = nil; lastInput = nil; loading = false; exportURL = nil; error = nil; notice = nil }
    func start(companyId: String, userId: String, owner: Bool) {
        stop(); self.companyId = companyId; self.owner = owner
        guard !companyId.isEmpty, !userId.isEmpty else { return }
        let token = session
        userListener = Firestore.firestore().document("users/\(userId)/userAccess/\(companyId)").addSnapshotListener { [weak self] snapshot, failure in
            Task { @MainActor [weak self] in
                guard let self, self.session == token else { return }
                self.invalidate(); self.ready = false; self.roleListener?.remove(); self.roleSession = UUID()
                self.templates = []; self.customerTags = []; self.saved = []; self.busySaving = false; self.savingPerformanceNote = false
                let roleToken = self.roleSession
                if let failure { self.error = failure.userFacingMessage; return }
                let access = snapshot?.data() ?? [:]
                self.userAccess = access
                let inactive = ["inactive", "revoked", "past", "deleted", "declined", "pending", "invited", "rejected", "canceled", "cancelled", "expired"]
                let active = !["active", "isActive", "accessActive"].contains { access[$0] as? Bool == false } && access["revoked"] as? Bool != true &&
                    !["status", "userStatus", "companyUserStatus", "accessStatus", "userAccessStatus"].contains { inactive.contains((access[$0] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) }
                guard self.owner || (snapshot?.exists == true && active) else { self.error = "Active company access is required."; return }
                guard let roleId = access["roleId"] as? String, !roleId.isEmpty else {
                    if self.owner { self.role = [:]; self.ready = true; self.accessRevision = UUID() }
                    else { self.error = "Your company role could not be loaded." }
                    return
                }
                self.roleListener = Firestore.firestore().document("companies/\(companyId)/roles/\(roleId)").addSnapshotListener { [weak self] roleSnapshot, failure in
                    Task { @MainActor [weak self] in
                        guard let self, self.session == token, self.roleSession == roleToken else { return }
                        self.invalidate(); self.ready = false; self.saved = []; self.templates = []; self.customerTags = []
                        if let failure { self.error = failure.userFacingMessage; return }
                        guard let data = roleSnapshot?.data() else { self.error = "Your company role could not be loaded."; return }
                        self.role = data; self.ready = true; self.accessRevision = UUID()
                    }
                }
            }
        }
    }
    func stop() {
        session = UUID(); roleSession = UUID(); invalidate(); ready = false
        userListener?.remove(); roleListener?.remove(); userListener = nil; roleListener = nil
        templates = []; customerTags = []; saved = []; busySaving = false; savingPerformanceNote = false; lastSavedReportId = nil; role = [:]; userAccess = [:]
        for url in generatedFiles { try? FileManager.default.removeItem(at: url) }; generatedFiles = []
    }
    deinit { userListener?.remove(); roleListener?.remove() }
    private func runtime() throws -> BooksEngine {
        if let engine { return engine }; let engine = try BooksEngine(); self.engine = engine; return engine
    }
    private func options(_ controls: BooksControls, regional: Bool) throws -> [String: Any] {
        var options = try JSONSerialization.jsonObject(with: JSONEncoder().encode(controls)) as! [String: Any]
        options["companyId"] = companyId; options["role"] = role; options["userAccess"] = userAccess
        options["canViewPayrollInformation"] = can("420"); options["regionalAccessEnabled"] = regional
        options["includeLegacyPipeline"] = can("910")
        return options
    }
    func loadControls(type: ReportType, regional: Bool) async {
        guard can("870") else { return }
        let token = session, revision = accessRevision
        do {
            if [.funReadingsDosages, .readings, .readingHealth, .readingPerformance].contains(type) {
                let snapshot = try await Firestore.firestore().collection("companies/\(companyId)/settings/readings/readings").getDocuments()
                guard session == token, revision == accessRevision else { return }
                templates = snapshot.documents.map { var data = $0.data(); data["id"] = $0.documentID; return data }
                    .sorted { ($0["name"] as? String ?? "") < ($1["name"] as? String ?? "") }
            }
            if can("10") {
                let snapshot = try await Firestore.firestore().collection("companies/\(companyId)/customers").getDocuments()
                guard session == token, revision == accessRevision else { return }
                let access = CompanyDashboardAccess(userAccess: userAccess, role: role, isOwner: owner)
                let allowed = !regional || access.fullRegionAccess ? snapshot.documents : snapshot.documents.filter { document in
                    let tags = CompanyDashboardRecord.strings(document.data()["tags"])
                    return !Set(tags.map { $0.lowercased() }).isDisjoint(with: Set(access.regionTags.map { $0.lowercased() }))
                }
                customerTags = Array(Set(allowed.flatMap { CompanyDashboardRecord.strings($0.data()["tags"]) })).sorted()
            }
        } catch { if session == token, revision == accessRevision { self.error = error.userFacingMessage } }
    }
    func generate(controls: BooksControls, regional: Bool) async {
        guard can("870"), !loading else { return }
        invalidate(); loading = true
        let token = request, sessionToken = session
        defer { if request == token { loading = false } }
        do {
            let options = try options(controls, regional: regional), engine = try runtime()
            let planJSON = try engine.call("sourcePlanJSON", arguments: [BooksEngine.json(options)])
            let plan = try JSONSerialization.jsonObject(with: Data(planJSON.utf8)) as! [[String: Any]]
            var sources: [String: Any] = [:]
            for source in plan {
                guard request == token, session == sessionToken else { return }
                let path = source["path"] as! String
                do {
                    if source["kind"] as? String == "document" {
                        sources[source["key"] as! String] = try await Firestore.firestore().document(path).getDocument().data() ?? [:]
                    } else {
                        var query: Query = Firestore.firestore().collection(path)
                        if source["companyFilter"] as? Bool == true { query = query.whereField("companyId", isEqualTo: companyId) }
                        if source["dateFilter"] as? Bool == true {
                            let end = Calendar.current.date(byAdding: .day, value: 1, to: BooksDateRange.date(controls.dateRange.end))!
                            query = query.whereField("date", isGreaterThanOrEqualTo: BooksDateRange.date(controls.dateRange.start)).whereField("date", isLessThan: end)
                        }
                        sources[source["key"] as! String] = try await query.getDocuments().documents.map { var data = $0.data(); data["id"] = $0.documentID; return data }
                    }
                } catch { throw BooksFailure.message("Could not read \(source["key"] as? String ?? "report data"): \(error.userFacingMessage)") }
            }
            guard request == token, session == sessionToken else { return }
            let input = try BooksEngine.json(["options": options, "sources": sources])
            let idsJSON = try engine.call("taskStopIdsJSON", arguments: [input])
            let stopIds = try JSONDecoder().decode([String].self, from: Data(idsJSON.utf8))
            var tasks: [String: Any] = [:]
            for stopId in stopIds {
                guard request == token, session == sessionToken else { return }
                tasks[stopId] = try await Firestore.firestore().collection("companies/\(companyId)/serviceStops/\(stopId)/tasks").getDocuments().documents.map { var data = $0.data(); data["id"] = $0.documentID; return data }
            }
            sources["serviceStopTasksById"] = tasks
            guard request == token, session == sessionToken else { return }
            let finalInput = try BooksEngine.json(["options": options, "sources": sources])
            let result = try engine.call("generateJSON", arguments: [finalInput])
            report = try JSONDecoder().decode(BooksReport.self, from: Data(result.utf8)); lastInput = finalInput; reportIdentity = UUID().uuidString
        } catch { if request == token, session == sessionToken { self.error = error.userFacingMessage } }
    }
    func loadSaved() async {
        guard can("870") else { return }
        let token = session, revision = accessRevision
        do {
            let documents = try await Firestore.firestore().collection("companies/\(companyId)/customReports").getDocuments().documents
            guard session == token, revision == accessRevision else { return }
            saved = documents.compactMap { doc in
                let data = doc.data()
                var controls = data["controls"] as? [String: Any] ?? [:]
                if controls["reportType"] == nil { controls["reportType"] = data["reportType"] }
                if !can("420"), ["payroll", "futurePayroll"].contains(controls["reportType"] as? String ?? "") { return nil }
                return BooksSavedReport(id: doc.documentID, title: data["title"] as? String ?? "Custom Report", subtitle: data["subtitle"] as? String ?? "", controls: controls)
            }.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        } catch { if session == token, revision == accessRevision { self.error = error.userFacingMessage } }
    }
    func save(controls: BooksControls, title: String, subtitle: String, existingId: String?, userId: String) async -> Bool {
        guard !busySaving, can(existingId == nil ? "872" : "874"), !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        busySaving = true; let token = session, revision = accessRevision
        defer { if token == session { busySaving = false } }
        do {
            let controlsData = try JSONSerialization.jsonObject(with: JSONEncoder().encode(controls))
            var data: [String: Any] = ["title": title.trimmingCharacters(in: .whitespacesAndNewlines), "subtitle": subtitle, "reportType": controls.reportType, "controls": controlsData, "updatedAt": FieldValue.serverTimestamp(), "updatedByUserId": userId]
            let collection = Firestore.firestore().collection("companies/\(companyId)/customReports")
            if let existingId { try await collection.document(existingId).updateData(data) }
            else { data["createdAt"] = FieldValue.serverTimestamp(); data["createdByUserId"] = userId; let ref = collection.document(); try await ref.setData(data); if session == token, revision == accessRevision { lastSavedReportId = ref.documentID } }
            guard session == token, revision == accessRevision else { return false }
            if let existingId { lastSavedReportId = existingId }; await loadSaved(); return true
        } catch { if session == token, revision == accessRevision { self.error = error.userFacingMessage }; return false }
    }
    func delete(_ savedReport: BooksSavedReport) async {
        guard can("876"), !busySaving else { return }
        busySaving = true; let token = session, revision = accessRevision
        defer { if token == session { busySaving = false } }
        do { try await Firestore.firestore().document("companies/\(companyId)/customReports/\(savedReport.id)").delete()
            if session == token, revision == accessRevision { saved.removeAll { $0.id == savedReport.id } }
        } catch { if session == token, revision == accessRevision { self.error = error.userFacingMessage } }
    }
    func createPerformanceNote(user: BooksReport.IndividualUser, copyToCustomers: Bool, actorId: String, actorName: String) async {
        guard can("274"), !savingPerformanceNote, !user.companyUserId.isEmpty, let lastInput else { return }
        guard !copyToCustomers || can("12") else { error = "Customer creation permission (12) is required for copied notes."; return }
        savingPerformanceNote = true; let token = request, sessionToken = session
        defer { if session == sessionToken { savingPerformanceNote = false } }
        do {
            let planJSON = try runtime().call("performanceNoteJSON", arguments: [lastInput, user.id])
            let plan = try JSONSerialization.jsonObject(with: Data(planJSON.utf8)) as! [String: Any]
            let company = companyId, identity = reportIdentity
            let reviewId = "report_\(identity)_\(user.companyUserId)"
            let path = "companies/\(company)/performanceReviews/\(user.companyUserId)/shared/\(reviewId).html"
            let data = Data((plan["html"] as? String ?? "").utf8), metadata = StorageMetadata()
            metadata.contentType = "text/html"
            let storageRef = Storage.storage().reference(withPath: path)
            _ = try await storageRef.putDataAsync(data, metadata: metadata)
            guard request == token, session == sessionToken else { return }
            let url = try await storageRef.downloadURL(), timestamp = Timestamp(date: Date())
            guard request == token, session == sessionToken else { return }
            let attachment: [String: Any] = ["id": reviewId, "name": "\(reviewId).html", "title": plan["title"] ?? "Report", "url": url.absoluteString,
                "contentType": "text/html", "size": data.count, "storagePath": path, "isTechnicianVisible": true, "attachedAt": timestamp]
            let attachedReport: [String: Any] = ["id": reviewId, "title": plan["title"] ?? "Report", "url": url.absoluteString,
                "notes": "Individual reading performance report generated from Reports.", "isTechnicianVisible": true, "attachments": [attachment], "attachedAt": timestamp]
            let review: [String: Any] = ["type": "observation", "title": plan["title"] ?? "Report", "note": plan["note"] ?? "", "date": timestamp,
                "references": ["serviceStops": [String](), "jobs": [String]()], "attachedReports": [attachedReport], "attachments": [attachment],
                "visibleToTechnician": true, "isSummaryReport": false, "companyInternal": true, "companyId": company, "companyUserId": user.companyUserId,
                "technicianUserId": plan["technicianUserId"] ?? "", "technicianName": user.name,
                "createdByUserId": actorId, "createdByName": actorName, "createdAt": FieldValue.serverTimestamp(), "updatedAt": FieldValue.serverTimestamp(),
                "sourceReport": ["type": "readingPerformance", "title": plan["reportTitle"] ?? "", "groupId": user.id, "generatedAt": timestamp]]
            try await Firestore.firestore().document("companyUserPerformanceReviews/\(company)/companyUsers/\(user.companyUserId)/reviews/\(reviewId)").setData(review)
            if copyToCustomers {
                for customer in plan["customerNotes"] as? [[String: Any]] ?? [] {
                    guard request == token, session == sessionToken else { return }
                    guard let id = customer["customerId"] as? String, !id.isEmpty else { continue }
                    let noteId = "comp_cus_note_\(identity)_\(user.companyUserId)_\(id)"
                    let noteRef = Firestore.firestore().document("companies/\(company)/customers/\(id)/notes/\(noteId)")
                    if try await noteRef.getDocument().exists { continue }
                    guard request == token, session == sessionToken else { return }
                    try await noteRef.setData([
                        "id": noteId, "companyId": company, "customerId": id, "customerName": customer["customerName"] ?? "",
                        "note": customer["note"] ?? "", "comment": customer["note"] ?? "", "authorId": actorId, "authorName": actorName,
                        "userId": actorId, "userName": actorName, "audience": "office", "visibility": "office", "resolved": false,
                        "date": timestamp, "createdAt": FieldValue.serverTimestamp(), "updatedAt": FieldValue.serverTimestamp(),
                        "source": "readingPerformanceReport", "sourceReport": ["type": "readingPerformance", "groupId": user.id, "performanceReviewId": reviewId],
                        "attachedReports": [attachedReport], "attachments": [attachment]
                    ])
                }
            }
            if request == token, session == sessionToken { notice = "Performance report attached for \(user.name)." }
        } catch { if request == token, session == sessionToken { self.error = error.userFacingMessage } }
    }
    func export(_ type: String, groupId: String = "") {
        guard can("870"), let lastInput else { return }
        do {
            let contents = try runtime().call("exportJSON", arguments: [lastInput, type == "pdf" ? "html" : type, groupId])
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Report-\(UUID().uuidString).\(type)")
            let data: Data
            if type == "xlsx" {
                guard let decoded = Data(base64Encoded: contents) else { throw BooksFailure.message("Could not create the Excel file.") }; data = decoded
            } else if type == "pdf" {
                let renderer = UIPrintPageRenderer()
                renderer.addPrintFormatter(UIMarkupTextPrintFormatter(markupText: contents), startingAtPageAt: 0)
                renderer.setValue(NSValue(cgRect: CGRect(x: 0, y: 0, width: 842, height: 595)), forKey: "paperRect")
                renderer.setValue(NSValue(cgRect: CGRect(x: 24, y: 24, width: 794, height: 547)), forKey: "printableRect")
                data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 842, height: 595)).pdfData { context in
                    for page in 0..<renderer.numberOfPages { context.beginPage(); renderer.drawPage(at: page, in: CGRect(x: 0, y: 0, width: 842, height: 595)) }
                }
            } else { data = Data(contents.utf8) }
            try data.write(to: url, options: [.atomic, .completeFileProtection]); generatedFiles.append(url); exportURL = url
        } catch { self.error = error.userFacingMessage }
    }
}
