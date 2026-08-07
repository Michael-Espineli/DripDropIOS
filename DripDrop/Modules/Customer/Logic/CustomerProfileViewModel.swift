//
//  CustomerProfileViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

enum CustomerNoteAudience: String, Codable, CaseIterable, Identifiable {
    case all
    case office
    case field

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .office:
            return "Office"
        case .field:
            return "Field"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "person.2"
        case .office:
            return "building.2"
        case .field:
            return "figure.pool.swim"
        }
    }

    var isVisibleFromFieldStop: Bool {
        self == .field || self == .all
    }
}

struct CustomerNote: Identifiable, Codable, Hashable {
    var storedId: String?
    var companyId: String?
    var customerId: String?
    var customerName: String?
    var bodyOfWaterId: String?
    var bodyOfWaterName: String?
    var serviceLocationId: String?
    var userId: String?
    var userName: String?
    var authorId: String?
    var authorName: String?
    var note: String?
    var comment: String?
    var audience: CustomerNoteAudience?
    var visibility: String?
    var resolved: Bool?
    var date: Date?
    var dateMillis: TimeInterval?
    var createdAt: Date?
    var createdAtMillis: TimeInterval?
    var updatedAt: Date?
    var updatedAtMillis: TimeInterval?

    var id: String {
        storedId ?? "\(dateMillis ?? createdAtMillis ?? 0)-\(displayText.hashValue)"
    }

    var displayText: String {
        note ?? comment ?? ""
    }

    var displayAuthor: String {
        userName ?? authorName ?? "Unknown"
    }

    var displayDate: Date {
        date ?? createdAt ?? Date(timeIntervalSince1970: (dateMillis ?? createdAtMillis ?? 0) / 1000)
    }

    var displayAudience: CustomerNoteAudience {
        if let audience {
            return audience
        }

        let normalizedVisibility = (visibility ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return CustomerNoteAudience(rawValue: normalizedVisibility) ?? .all
    }

    var isVisibleFromFieldStop: Bool {
        displayAudience.isVisibleFromFieldStop
    }

    init(
        storedId: String? = nil,
        companyId: String? = nil,
        customerId: String? = nil,
        customerName: String? = nil,
        bodyOfWaterId: String? = nil,
        bodyOfWaterName: String? = nil,
        serviceLocationId: String? = nil,
        userId: String? = nil,
        userName: String? = nil,
        authorId: String? = nil,
        authorName: String? = nil,
        note: String? = nil,
        comment: String? = nil,
        audience: CustomerNoteAudience? = nil,
        visibility: String? = nil,
        resolved: Bool? = nil,
        date: Date? = nil,
        dateMillis: TimeInterval? = nil,
        createdAt: Date? = nil,
        createdAtMillis: TimeInterval? = nil,
        updatedAt: Date? = nil,
        updatedAtMillis: TimeInterval? = nil
    ) {
        self.storedId = storedId
        self.companyId = companyId
        self.customerId = customerId
        self.customerName = customerName
        self.bodyOfWaterId = bodyOfWaterId
        self.bodyOfWaterName = bodyOfWaterName
        self.serviceLocationId = serviceLocationId
        self.userId = userId
        self.userName = userName
        self.authorId = authorId
        self.authorName = authorName
        self.note = note
        self.comment = comment
        self.audience = audience
        self.visibility = visibility
        self.resolved = resolved
        self.date = date
        self.dateMillis = dateMillis
        self.createdAt = createdAt
        self.createdAtMillis = createdAtMillis
        self.updatedAt = updatedAt
        self.updatedAtMillis = updatedAtMillis
    }

    enum CodingKeys: String, CodingKey {
        case storedId = "id"
        case companyId
        case customerId
        case customerName
        case bodyOfWaterId
        case bodyOfWaterName
        case serviceLocationId
        case userId
        case userName
        case authorId
        case authorName
        case note
        case comment
        case audience
        case visibility
        case resolved
        case date
        case dateMillis
        case createdAt
        case createdAtMillis
        case updatedAt
        case updatedAtMillis
    }
}

struct CustomerOutstandingWork: Identifiable, Codable, Hashable {
    var storedId: String?
    var companyId: String?
    var customerId: String?
    var customerName: String?
    var sourceType: String?
    var sourceId: String?
    var jobId: String?
    var jobInternalId: String?
    var jobType: String?
    var jobDescription: String?
    var billingStatus: String?
    var operationStatus: String?
    var outstandingStatus: String?
    var status: String?
    var serviceLocationName: String?
    var serviceLocationAddress: String?
    var bodyOfWaterName: String?
    var equipmentName: String?
    var adminName: String?
    var title: String?
    var note: String?
    var reason: String?
    var statusChangedAt: Date?
    var statusChangedAtMillis: TimeInterval?
    var updatedAt: Date?
    var updatedAtMillis: TimeInterval?
    var createdAt: Date?
    var createdAtMillis: TimeInterval?

    var id: String {
        storedId ?? jobId ?? sourceId ?? "\(statusChangedAtMillis ?? updatedAtMillis ?? createdAtMillis ?? 0)-\(displayTitle.hashValue)"
    }

    var displayTitle: String {
        title ?? jobType ?? jobInternalId ?? "Outstanding work"
    }

    var displayDetail: String {
        note ?? jobDescription ?? ""
    }

    var displayStatus: String {
        billingStatus ?? outstandingStatus ?? status ?? "Open"
    }

    var displayDate: Date {
        statusChangedAt ?? updatedAt ?? createdAt ?? Date(timeIntervalSince1970: (statusChangedAtMillis ?? updatedAtMillis ?? createdAtMillis ?? 0) / 1000)
    }

    var isOpen: Bool {
        let value = (outstandingStatus ?? status ?? "Open").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !["resolved", "done", "completed", "closed", "cancelled", "canceled"].contains(value)
    }

    enum CodingKeys: String, CodingKey {
        case storedId = "id"
        case companyId
        case customerId
        case customerName
        case sourceType
        case sourceId
        case jobId
        case jobInternalId
        case jobType
        case jobDescription
        case billingStatus
        case operationStatus
        case outstandingStatus
        case status
        case serviceLocationName
        case serviceLocationAddress
        case bodyOfWaterName
        case equipmentName
        case adminName
        case title
        case note
        case reason
        case statusChangedAt
        case statusChangedAtMillis
        case updatedAt
        case updatedAtMillis
        case createdAt
        case createdAtMillis
    }
}

struct CustomerPartApprovalHistoryItem: Identifiable, Codable, Hashable {
    var id: String = "cpa_hist_" + UUID().uuidString
    var action: String?
    var status: String?
    var note: String?
    var source: String?
    var sourceLabel: String?
    var actorUserId: String?
    var actorUserName: String?
    var actorEmail: String?
    var createdAt: Date?
}

struct CustomerPartApproval: Identifiable, Codable, Hashable {
    var id: String = "cpa_" + UUID().uuidString
    var companyId: String?
    var companyName: String?
    var customerApprovalUrl: String?
    var customerId: String?
    var customerUserId: String?
    var customerName: String?
    var customerEmail: String?
    var email: String?
    var billingEmail: String?
    var serviceLocationId: String?
    var serviceLocationName: String?
    var serviceLocationAddress: String?
    var shoppingListItemId: String?
    var shoppingListPath: String?
    var itemName: String?
    var name: String?
    var description: String?
    var quantity: String?
    var dbItemId: String?
    var dbItemName: String?
    var genericItemId: String?
    var subCategory: String?
    var plannedUnitCostCents: Int?
    var plannedUnitPriceCents: Int?
    var plannedTotalCostCents: Int?
    var plannedTotalPriceCents: Int?
    var status: String?
    var approvalStatus: String?
    var fulfillmentStatus: String?
    var sourceType: String?
    var requestedAt: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var requestedByUserId: String?
    var requestedByUserName: String?
    var jobId: String?
    var jobName: String?
    var jobInternalId: String?
    var linkedTaskId: String?
    var linkedTaskName: String?
    var linkedTaskType: String?
    var serviceStopId: String?
    var serviceStopInternalId: String?
    var scheduledServiceStopId: String?
    var scheduledServiceStopInternalId: String?
    var scheduledDate: Date?
    var techId: String?
    var techName: String?
    var assignedTechId: String?
    var assignedTechName: String?
    var assignedToUserId: String?
    var assignedToUserName: String?
    var assignedTechIds: [String]?
    var assignedTechNames: [String]?
    var purchaserId: String?
    var purchaserName: String?
    var prepKeys: [String]?
    var response: String?
    var responseNote: String?
    var respondedAt: Date?
    var respondedByUserId: String?
    var respondedByUserName: String?
    var respondedByEmail: String?
    var responseSource: String?
    var responseSourceLabel: String?
    var respondedOnBehalfOfCustomer: Bool?
    var customerConversationRecorded: Bool?
    var approvedInPerson: Bool?
    var deniedInPerson: Bool?
    var inPersonApprovedByUserId: String?
    var inPersonDeniedByUserId: String?
    var shoppingListGeneratedAt: Date?
    var lastResentAt: Date?
    var resendCount: Int?
    var history: [CustomerPartApprovalHistoryItem]?

    var displayTitle: String {
        itemName ?? name ?? dbItemName ?? "Part Approval"
    }

    var displayStatus: String {
        approvalStatus ?? status ?? "pending"
    }

    var displayDate: Date {
        updatedAt ?? requestedAt ?? createdAt ?? .distantPast
    }

    var displayTotalCents: Int {
        if let plannedTotalPriceCents, plannedTotalPriceCents > 0 {
            return plannedTotalPriceCents
        }

        let quantityValue = Double(quantity ?? "1") ?? 1
        let unitPrice = plannedUnitPriceCents ?? 0
        return Int((Double(unitPrice) * quantityValue).rounded())
    }

    var isOpen: Bool {
        let normalized = (approvalStatus ?? status ?? fulfillmentStatus ?? "pending")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return ![
            "resolved",
            "installed",
            "invoiced",
            "paid",
            "cancelled",
            "canceled",
            "rejected",
            "declined",
            "completed",
            "fulfilled"
        ].contains(normalized)
    }
}

@MainActor
final class CustomerProfileViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var recurringServiceStops: [RecurringServiceStop] = []
    @Published var repairRequest: [RepairRequest] = []
    @Published var jobs: [Job] = []
    @Published var shoppingListItems: [ShoppingListItem] = []
    @Published var serviceStops: [ServiceStop] = []
    @Published var customerNotes: [CustomerNote] = []
    @Published var customerOutstandingWork: [CustomerOutstandingWork] = []
    @Published var customerBodiesOfWater: [BodyOfWater] = []

    // For Service Stop Detail View
    @Published var serviceLocation: ServiceLocation? = nil

    private var recurringServiceStopsListener: ListenerRegistration?
    private var repairRequestsListener: ListenerRegistration?
    private var jobsListener: ListenerRegistration?
    private var customerNotesListener: ListenerRegistration?
    private var outstandingWorkListener: ListenerRegistration?

    deinit {
        recurringServiceStopsListener?.remove()
        repairRequestsListener?.remove()
        jobsListener?.remove()
        customerNotesListener?.remove()
        outstandingWorkListener?.remove()
        dataService.removeListenerForAllServiceStops()
    }

    // MARK: - Initial Load

    func onLoad(companyId: String, customerId: String) async throws {
        print("")
        print("[CustomerProfileViewModel][onLoad] customerId: \(customerId) companyId: \(companyId)")

        startUpcomingWorkListeners(companyId: companyId, customerId: customerId)

        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(
            companyId: companyId,
            customerId: customerId
        )

        print("")
        print("[CustomerProfileViewModel][onLoad] shoppingListItems: \(shoppingListItems.count)")
    }

    // MARK: - Live Upcoming Work Listeners

    func startUpcomingWorkListeners(companyId: String, customerId: String) {
        print("")
        print("[CustomerProfileViewModel][startUpcomingWorkListeners] customerId: \(customerId) companyId: \(companyId)")

        stopUpcomingWorkListeners()

        listenToRecurringServiceStops(companyId: companyId, customerId: customerId)
        listenToRepairRequests(companyId: companyId, customerId: customerId)
        listenToJobs(companyId: companyId, customerId: customerId)
        listenToCustomerNotes(companyId: companyId, customerId: customerId)
        listenToOutstandingWork(companyId: companyId, customerId: customerId)
        listenToFutureCustomerServiceStops(companyId: companyId, customerId: customerId)
    }

    func stopUpcomingWorkListeners() {
        recurringServiceStopsListener?.remove()
        recurringServiceStopsListener = nil

        repairRequestsListener?.remove()
        repairRequestsListener = nil

        jobsListener?.remove()
        jobsListener = nil

        customerNotesListener?.remove()
        customerNotesListener = nil

        outstandingWorkListener?.remove()
        outstandingWorkListener = nil

        dataService.removeListenerForAllServiceStops()
    }

    private func listenToRecurringServiceStops(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        recurringServiceStopsListener = db
            .collection("companies")
            .document(companyId)
            .collection("recurringServiceStop")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToRecurringServiceStops] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.recurringServiceStops = []
                    }
                    return
                }

                let stops: [RecurringServiceStop] = documents.compactMap { document in
                    do {
                        return try document.data(as: RecurringServiceStop.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToRecurringServiceStops] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.recurringServiceStops = stops.sorted {
                        $0.startDate < $1.startDate
                    }

                    print("")
                    print("[CustomerProfileViewModel][listenToRecurringServiceStops] recurringServiceStops: \(self.recurringServiceStops.count)")
                }
            }
    }

    private func listenToRepairRequests(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        repairRequestsListener = db
            .collection("companies")
            .document(companyId)
            .collection("repairRequests")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToRepairRequests] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.repairRequest = []
                    }
                    return
                }

                let repairs: [RepairRequest] = documents.compactMap { document in
                    do {
                        return try document.data(as: RepairRequest.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToRepairRequests] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.repairRequest = repairs

                    print("")
                    print("[CustomerProfileViewModel][listenToRepairRequests] repairRequest: \(self.repairRequest.count)")
                }
            }
    }

    private func listenToJobs(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        jobsListener = db
            .collection("companies")
            .document(companyId)
            .collection("workOrders")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToJobs] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.jobs = []
                    }
                    return
                }

                let jobs: [Job] = documents.compactMap { document in
                    do {
                        return try document.data(as: Job.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToJobs] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.jobs = jobs

                    print("")
                    print("[CustomerProfileViewModel][listenToJobs] jobs: \(self.jobs.count)")
                }
            }
    }

    private func listenToCustomerNotes(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        customerNotesListener = db
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customerId)
            .collection("notes")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToCustomerNotes] Error: \(error)")
                    return
                }

                let notes: [CustomerNote] = snapshot?.documents.compactMap { document in
                    do {
                        return try document.data(as: CustomerNote.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToCustomerNotes] Decode Error: \(error)")
                        return nil
                    }
                } ?? []

                Task { @MainActor in
                    self.customerNotes = notes.sorted { $0.displayDate > $1.displayDate }
                }
            }
    }

    private func listenToOutstandingWork(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        outstandingWorkListener = db
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customerId)
            .collection("outstandingWork")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToOutstandingWork] Error: \(error)")
                    return
                }

                let work: [CustomerOutstandingWork] = snapshot?.documents.compactMap { document in
                    do {
                        return try document.data(as: CustomerOutstandingWork.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToOutstandingWork] Decode Error: \(error)")
                        return nil
                    }
                } ?? []

                Task { @MainActor in
                    self.customerOutstandingWork = work
                        .filter { $0.isOpen }
                        .sorted { $0.displayDate > $1.displayDate }
                }
            }
    }

    private func listenToFutureCustomerServiceStops(companyId: String, customerId: String) {
        dataService.removeListenerForAllServiceStops()

        dataService.addListenerForFutureCustomerServiceStops(
            companyId: companyId,
            customerId: customerId
        ) { [weak self] stops in
            Task { @MainActor in
                self?.serviceStops = stops.sorted {
                    $0.serviceDate < $1.serviceDate
                }

                print("")
                print("[CustomerProfileViewModel][listenToFutureCustomerServiceStops] serviceStops: \(self?.serviceStops.count ?? 0)")
            }
        }
    }

    // MARK: - Service Stop Detail

    func onLoadCustomerProfileView(companyId: String?, serviceStop: ServiceStop) {
        guard let companyId else { return }

        Task {
            do {
                self.serviceLocation = try await dataService.getServiceLocationById(
                    companyId: companyId,
                    locationId: serviceStop.serviceLocationId
                )
            } catch {
                print("  [CustomerProfileViewModel][onLoadCustomerProfileView] Error \(error)")
            }
        }
    }

    // MARK: - Deletes

    func deleteRecurringServiceStop(companyId: String, RecurringServiceStopId: String) async throws {
        print("")
        print("[CustomerProfileViewModel][deleteRecurringServiceStop] Delete")
        print(RecurringServiceStopId)

        let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopsAfterToday(
            companyId: companyId,
            recurringServiceStopId: RecurringServiceStopId
        )

        for stop in serviceStopList {
            try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
        }

        try await dataService.deleteRecurringServiceStop(
            companyId: companyId,
            recurringServiceStopId: RecurringServiceStopId
        )

        print("[CustomerProfileViewModel][deleteRecurringServiceStop] Successful")
        print("")
    }

    // MARK: - Manual Reloads

    func reloadShoppingListItem(companyId: String, customerId: String) async throws {
        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadJobs(companyId: String, customerId: String) async throws {
        self.jobs = try await dataService.getAllJobsByCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadRepairRequests(companyId: String, customerId: String) async throws {
        self.repairRequest = try await dataService.getRepairRequestsByCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadRecurringServiceStops(companyId: String, customerId: String) async throws {
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStopByCustomerId(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadCustomerBodiesOfWater(companyId: String, customerId: String) async throws {
        let locations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: customerId
        )

        var bodies: [BodyOfWater] = []
        for location in locations {
            let locationBodies = try await dataService.getAllBodiesOfWaterByServiceLocationIdAndCustomerId(
                serviceLocationId: location.id,
                customerId: customerId,
                companyId: companyId
            )
            bodies.append(contentsOf: locationBodies)
        }

        customerBodiesOfWater = bodies.sorted { $0.name < $1.name }
    }

    func addCustomerNote(
        companyId: String,
        customer: Customer,
        bodyOfWater: BodyOfWater?,
        note: String,
        authorId: String,
        authorName: String
    ) async throws {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }

        let noteId = "comp_cus_note_" + UUID().uuidString
        let nowMillis = Date().timeIntervalSince1970 * 1000
        let customerName = [customer.firstName, customer.lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        try await Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customer.id)
            .collection("notes")
            .document(noteId)
            .setData([
                "id": noteId,
                "companyId": companyId,
                "customerId": customer.id,
                "customerName": customerName,
                "bodyOfWaterId": bodyOfWater?.id ?? "",
                "bodyOfWaterName": bodyOfWater?.name ?? "",
                "serviceLocationId": bodyOfWater?.serviceLocationId ?? "",
                "userId": authorId,
                "userName": authorName,
                "authorId": authorId,
                "authorName": authorName,
                "note": trimmedNote,
                "comment": trimmedNote,
                "resolved": false,
                "date": FieldValue.serverTimestamp(),
                "dateMillis": nowMillis,
                "createdAt": FieldValue.serverTimestamp(),
                "createdAtMillis": nowMillis,
                "updatedAt": FieldValue.serverTimestamp(),
                "updatedAtMillis": nowMillis
            ])
    }

    func setCustomerNoteResolved(
        companyId: String,
        customerId: String,
        noteId: String,
        resolved: Bool,
        authorId: String,
        authorName: String
    ) async throws {
        let nowMillis = Date().timeIntervalSince1970 * 1000

        try await Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("customers")
            .document(customerId)
            .collection("notes")
            .document(noteId)
            .updateData([
                "resolved": resolved,
                "resolvedAt": resolved ? FieldValue.serverTimestamp() : NSNull(),
                "resolvedAtMillis": resolved ? nowMillis : NSNull(),
                "resolvedByUserId": resolved ? authorId : "",
                "resolvedByUserName": resolved ? authorName : "",
                "updatedAt": FieldValue.serverTimestamp(),
                "updatedAtMillis": nowMillis
            ])
    }
}
