import Foundation
import FirebaseFirestore

@MainActor
final class CompanyDashboardAccessViewModel: ObservableObject {
    @Published private(set) var access: CompanyDashboardAccess?
    @Published private(set) var error: String?
    private var userListener: ListenerRegistration?
    private var roleListener: ListenerRegistration?
    private var generation = UUID()
    private var roleGeneration = UUID()

    func start(companyId: String, userId: String, isOwner: Bool) {
        stop()
        access = nil
        error = nil
        let token = generation
        userListener = Firestore.firestore().document("users/\(userId)/userAccess/\(companyId)").addSnapshotListener { [weak self] snapshot, failure in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                self.roleListener?.remove()
                self.roleGeneration = UUID()
                let roleToken = self.roleGeneration
                self.access = nil
                guard failure == nil, let userAccess = snapshot?.data(), let roleId = userAccess["roleId"] as? String, !roleId.isEmpty else {
                    self.error = "Dashboard access could not be loaded."
                    return
                }
                self.roleListener = Firestore.firestore().document("companies/\(companyId)/roles/\(roleId)").addSnapshotListener { [weak self] roleSnapshot, roleFailure in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == token, self.roleGeneration == roleToken else { return }
                        guard roleFailure == nil, let role = roleSnapshot?.data() else {
                            self.access = nil
                            self.error = "Your company role could not be loaded."
                            return
                        }
                        self.error = nil
                        self.access = CompanyDashboardAccess(userAccess: userAccess, role: role, isOwner: isOwner)
                    }
                }
            }
        }
    }

    func stop() {
        generation = UUID()
        userListener?.remove()
        roleListener?.remove()
        userListener = nil
        roleListener = nil
    }

    deinit { userListener?.remove(); roleListener?.remove() }
}

@MainActor
final class CompanyDashboardViewModel: ObservableObject {
    @Published private(set) var records: [String: [CompanyDashboardRecord]] = [:]
    @Published private(set) var loaded: Set<String> = []
    @Published private(set) var errors: [String: String] = [:]
    private var listeners: [ListenerRegistration] = []
    private var generation = UUID()

    func start(companyId: String, access: CompanyDashboardAccess, date: Date) {
        stop()
        guard access.canViewManager else { return }
        let company = Firestore.firestore().collection("companies").document(companyId)
        listen(company.collection("customers"), key: "customers")
        if access.canViewStops {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start
            listen(company.collection("serviceStops").whereField("serviceDate", isGreaterThanOrEqualTo: start).whereField("serviceDate", isLessThan: end), key: "stops")
        }
        if access.permits("20") {
            listen(company.collection("workOrders").whereField("operationStatus", in: ["Draft", "Estimate Pending", "Unscheduled", "Scheduled", "In Progress", "Waiting for Parts", "Accepted"]), key: "jobs")
        }
        if access.permits("30") {
            listen(company.collection("repairRequests").whereField("status", in: ["Unresolved", "unresolved", "Pending", "pending", "In Progress"]), key: "requests")
        }
    }

    func stop() {
        generation = UUID()
        listeners.forEach { $0.remove() }
        listeners = []
        records = [:]
        loaded = []
        errors = [:]
    }

    func isReady(_ key: String) -> Bool { loaded.contains(key) && errors[key] == nil && loaded.contains("customers") && errors["customers"] == nil }

    func snapshot(access: CompanyDashboardAccess, tag: String, date: Date) -> CompanyDashboardSnapshot {
        let customerMap = Dictionary((records["customers"] ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        func scoped(_ key: String) -> [CompanyDashboardRecord] {
            guard isReady(key) else { return [] }
            return (records[key] ?? []).filter { access.includes($0, customers: customerMap, selectedTag: tag) }
        }
        let customers = (records["customers"] ?? []).filter { customer in
            // Customer records own their tags rather than linking to another customer.
            access.includes(customer, customers: [:], selectedTag: tag) && customer.isActiveCustomer
        }
        return CompanyDashboardSnapshot(customers: customers, stops: scoped("stops"), jobs: scoped("jobs").filter(\.isOpenJob), requests: scoped("requests").filter(\.isOpenRequest), selectedDate: date)
    }

    private func listen(_ query: Query, key: String) {
        let token = generation
        listeners.append(query.addSnapshotListener { [weak self] snapshot, failure in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                if let failure {
                    self.records[key] = []
                    self.errors[key] = failure.localizedDescription
                } else {
                    self.errors[key] = nil
                    self.records[key] = (snapshot?.documents ?? []).map { document in
                        var data = document.data()
                        data["serviceDate"] = (data["serviceDate"] as? Timestamp)?.dateValue() ?? data["serviceDate"]
                        return CompanyDashboardRecord(id: document.documentID, data: data)
                    }
                }
                self.loaded.insert(key)
            }
        })
    }

    deinit { listeners.forEach { $0.remove() } }
}
