import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class JobListViewModel: ObservableObject {
    @Published var filters = JobListFilters()
    @Published var selectedRegionTag = ""
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var admins: [JobListAdmin] = []
    @Published private(set) var customers: [String: [String]] = [:]
    @Published private(set) var userAccess: [String: Any] = [:]
    @Published private(set) var role: [String: Any] = [:]
    @Published private(set) var loaded: Set<String> = []
    @Published private(set) var errors: [String: String] = [:]
    private var listeners: [ListenerRegistration] = []
    private var roleListener: ListenerRegistration?
    private var generation = UUID()
    private var roleGeneration = UUID()
    private var userId = ""
    private var companyId = ""

    init(mode: JobListMode) { filters.selectMode(mode) }

    func start(companyId: String, userId: String) {
        stop()
        self.companyId = companyId
        self.userId = userId
        selectedRegionTag = UserDefaults.standard.string(forKey: "jobListArea.\(userId).\(companyId)") ?? ""
        guard !companyId.isEmpty, !userId.isEmpty else { return }
        let company = Firestore.firestore().collection("companies").document(companyId)
        // No date/admin constraints: web company-wide lists include old and unassigned jobs.
        listen(company.collection("workOrders"), key: "jobs") { [weak self] documents in
            guard let self else { return }
            do {
                self.jobs = try documents.map { document in
                    var data = document.data()
                    data["id"] = document.documentID
                    for field in ["dateCreated", "dateEstimateAccepted", "invoiceDate", "createdAt"] {
                        if let millis = data[field] as? NSNumber {
                            data[field] = Timestamp(date: Date(timeIntervalSince1970: millis.doubleValue / 1000))
                        }
                    }
                    return try Firestore.Decoder().decode(Job.self, from: data)
                }
            } catch {
                self.jobs = []
                self.errors["jobs"] = "A job could not be read. Please refresh or check its saved data."
            }
        }
        listen(company.collection("companyUsers"), key: "admins") { [weak self] documents in
            let options = documents.map { JobListAdmin(documentId: $0.documentID, data: $0.data()) }
            var seen: Set<String> = []
            self?.admins = options.filter { seen.insert($0.id).inserted }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        listen(company.collection("customers"), key: "customers") { [weak self] documents in
            self?.customers = Dictionary(uniqueKeysWithValues: documents.map { ($0.documentID, JobListRegionAccess.strings($0.data()["tags"])) })
        }
        let token = generation
        listeners.append(Firestore.firestore().document("users/\(userId)/userAccess/\(companyId)").addSnapshotListener { [weak self] snapshot, failure in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                self.roleListener?.remove()
                self.roleGeneration = UUID()
                self.role = [:]
                self.loaded.remove("role")
                self.errors["role"] = nil
                guard failure == nil, let data = snapshot?.data() else {
                    self.errors["access"] = "Could not load customer area access."
                    return
                }
                self.userAccess = data
                self.loaded.insert("access")
                self.errors["access"] = nil
                guard let roleId = data["roleId"] as? String, !roleId.isEmpty else {
                    self.errors["role"] = "Your company role could not be loaded."
                    return
                }
                let roleToken = self.roleGeneration
                self.roleListener = company.collection("roles").document(roleId).addSnapshotListener { [weak self] snapshot, failure in
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == token, self.roleGeneration == roleToken else { return }
                        guard failure == nil, let data = snapshot?.data() else {
                            self.errors["role"] = "Your company role could not be loaded."
                            return
                        }
                        self.role = data
                        self.errors["role"] = nil
                        self.loaded.insert("role")
                    }
                }
            }
        })
    }

    func displayedJobs(regionalAccessEnabled: Bool) -> [Job] {
        let source: [Job]
        if regionalAccessEnabled {
            guard ["customers", "access", "role"].allSatisfy({ loaded.contains($0) && errors[$0] == nil }) else { return [] }
            let access = JobListRegionAccess(userAccess: userAccess, role: role)
            source = jobs.filter { access.includes(customerId: $0.customerId, customers: customers, selectedTag: selectedRegionTag) }
        } else { source = jobs }
        return filters.apply(to: source, admins: admins)
    }

    var availableRegionTags: [String] {
        JobListRegionAccess.strings(customers.values.flatMap { $0 }).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var currentAdminIds: Set<String> {
        let fields = ["id", "uid", "userId", "companyUserId", "companyUserDocId"]
        let ids = Set([userId] + fields.compactMap { userAccess[$0] as? String })
        let matches = admins.filter { !$0.aliases.isDisjoint(with: ids) }
        return matches.isEmpty ? Set([userId].filter { !$0.isEmpty }) : Set(matches.map(\.id))
    }

    func saveRegionTag() {
        UserDefaults.standard.set(selectedRegionTag, forKey: "jobListArea.\(userId).\(companyId)")
    }

    func stop() {
        generation = UUID()
        roleGeneration = UUID()
        listeners.forEach { $0.remove() }
        listeners = []
        roleListener?.remove()
        roleListener = nil
        jobs = []
        admins = []
        customers = [:]
        userAccess = [:]
        role = [:]
        loaded = []
        errors = [:]
    }

    private func listen(_ query: Query, key: String, receive: @escaping ([QueryDocumentSnapshot]) -> Void) {
        let token = generation
        listeners.append(query.addSnapshotListener { [weak self] snapshot, failure in
            Task { @MainActor [weak self] in
                guard let self, self.generation == token else { return }
                if failure != nil {
                    self.errors[key] = "Could not load \(key). Please try again."
                    if key == "jobs" { self.jobs = [] }
                } else {
                    self.errors[key] = nil
                    receive(snapshot?.documents ?? [])
                }
                self.loaded.insert(key)
            }
        })
    }

    deinit { listeners.forEach { $0.remove() }; roleListener?.remove() }
}
