import Foundation

// Keep these defaults and predicates aligned with web Jobs.jsx and jobStatusFilters.js.
enum JobListMode: String, CaseIterable, Identifiable {
    case operations = "Operations"
    case billing = "Billing"
    var id: String { rawValue }

    var operationStatuses: Set<JobOperationStatus> {
        self == .billing ? [.finished] : [.estimatePending, .unscheduled, .scheduled, .waitingForParts, .inProgress]
    }

    var billingStatuses: Set<JobBillingStatus> {
        let operations: Set<JobBillingStatus> = [.draft, .estimate, .accepted, .inProgress]
        return self == .billing ? operations.union([.expired, .rejected]) : operations
    }
}

enum JobListSortField: String, CaseIterable, Identifiable {
    case dateCreated = "Date Created", internalId = "Job ID", customerName = "Customer"
    case adminName = "Admin", type = "Job Type", billingStatus = "Billing Status"
    case operationStatus = "Operation Status", priority = "Priority"
    case rate = "Rate", laborCost = "Labor Cost", profit = "Profit"
    var id: String { rawValue }
    var defaultsAscending: Bool { ![.dateCreated, .rate, .laborCost, .profit].contains(self) }
}

struct JobListAdmin: Identifiable {
    let id: String
    let name: String
    let aliases: Set<String>

    init(documentId: String, data: [String: Any]) {
        let ids = ["userId", "id", "uid"].compactMap { data[$0] as? String }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        id = ids.first ?? documentId
        aliases = Set((ids + [documentId] + ["companyUserId", "companyUserDocId"].compactMap { data[$0] as? String })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let fullName = [data["firstName"] as? String, data["lastName"] as? String].compactMap { $0 }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: " ")
        name = [data["userName"] as? String, data["displayName"] as? String, fullName, data["name"] as? String,
                data["fullName"] as? String, data["label"] as? String, data["email"] as? String, data["userId"] as? String, data["id"] as? String]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty } ?? "Admin"
    }
}

struct JobListFilters {
    var mode: JobListMode = .operations
    var operationStatuses: Set<JobOperationStatus> = JobListMode.operations.operationStatuses
    var billingStatuses: Set<JobBillingStatus> = JobListMode.operations.billingStatuses
    var priorities = Set(JobIssuePriorityLevel.allCases.map(\.rawValue))
    var adminFilterActive = false
    var adminIds: Set<String> = []
    var search = ""
    var sortField: JobListSortField = .dateCreated
    var ascending = false

    var usesDefaultStatusesAndPriorities: Bool {
        operationStatuses == mode.operationStatuses && billingStatuses == mode.billingStatuses
            && priorities == Set(JobIssuePriorityLevel.allCases.map(\.rawValue))
    }

    mutating func selectMode(_ mode: JobListMode) {
        self.mode = mode
        operationStatuses = mode.operationStatuses
        billingStatuses = mode.billingStatuses
        priorities = Set(JobIssuePriorityLevel.allCases.map(\.rawValue))
    }

    func apply(to jobs: [Job], admins: [JobListAdmin]) -> [Job] {
        var adminLookup = Set(adminIds.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        let selectedIds = adminLookup
        for admin in admins where !admin.aliases.isDisjoint(with: selectedIds) {
            adminLookup.formUnion(admin.aliases)
        }
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return jobs.filter { job in
            // The web Billing preset includes *all* finished, outstanding jobs.
            // Custom filters instead use the intersection of the selected statuses.
            if mode == .billing && usesDefaultStatusesAndPriorities {
                guard Self.isFinishedOutstanding(job) else { return false }
            } else {
                guard (operationStatuses.isEmpty || operationStatuses.contains(job.operationStatus)),
                      (billingStatuses.isEmpty || billingStatuses.contains(job.billingStatus)) else { return false }
            }
            let priority = Self.priority(job)
            guard priorities.contains(priority.rawValue) else { return false }
            if adminFilterActive && !adminLookup.contains(job.adminId.trimmingCharacters(in: .whitespacesAndNewlines)) { return false }
            let fields = [job.customerName, job.adminName, job.internalId, job.type, job.description,
                          job.billingStatus.rawValue, job.operationStatus.rawValue, priority.label]
            return term.isEmpty || fields.contains { $0.lowercased().contains(term) }
        }.sorted { left, right in
            let result = compare(left, right)
            if result != .orderedSame { return result == .orderedAscending }
            if left.dateCreated != right.dateCreated { return left.dateCreated > right.dateCreated }
            return Self.compareText(left.internalId, right.internalId, ascending: true) == .orderedAscending
        }
    }

    static func isFinishedOutstanding(_ job: Job) -> Bool {
        job.operationStatus == .finished && ![JobBillingStatus.invoiced, .paid, .comped, .customerResolved, .canceled].contains(job.billingStatus)
    }

    private static func priority(_ job: Job) -> JobIssuePriorityLevel {
        // Job.fromFirestore fills issuePriorityLevel and solutionTier before the
        // web list applies its truthy fallback (including legacy zero values).
        let issue = job.issuePriorityLevel ?? job.priorityLevel ?? job.solutionTier ?? 2
        let solution = job.solutionTier ?? job.priorityLevel ?? 2
        return .normalized(issue == 0 ? solution : issue)
    }

    private func compare(_ left: Job, _ right: Job) -> ComparisonResult {
        switch sortField {
        case .dateCreated:
            // Undated legacy records sort last in either direction, like the web.
            if left.dateCreated == Date(timeIntervalSince1970: 0) || right.dateCreated == Date(timeIntervalSince1970: 0) {
                return Self.compareText(left.dateCreated == Date(timeIntervalSince1970: 0) ? "" : "dated", right.dateCreated == Date(timeIntervalSince1970: 0) ? "" : "dated", ascending: true)
            }
            return compareNumber(left.dateCreated.timeIntervalSince1970, right.dateCreated.timeIntervalSince1970)
        case .internalId: return Self.compareText(left.internalId, right.internalId, ascending: ascending)
        case .customerName: return Self.compareText(left.customerName, right.customerName, ascending: ascending)
        case .adminName: return Self.compareText(left.adminName, right.adminName, ascending: ascending)
        case .type: return Self.compareText(left.type, right.type, ascending: ascending)
        case .billingStatus: return compareStatus(left.billingStatus.rawValue, right.billingStatus.rawValue, order: JobBillingStatus.allCases.map(\.rawValue))
        case .operationStatus: return compareStatus(left.operationStatus.rawValue, right.operationStatus.rawValue, order: JobOperationStatus.allCases.map(\.rawValue))
        case .priority: return compareNumber(Double(Self.priority(left).rawValue), Double(Self.priority(right).rawValue))
        case .rate: return compareNumber(Double(left.rate), Double(right.rate))
        case .laborCost: return compareNumber(Double(left.laborCost), Double(right.laborCost))
        case .profit: return compareNumber(Double(left.profit), Double(right.profit))
        }
    }

    private func compareNumber(_ left: Double, _ right: Double) -> ComparisonResult {
        if left == right { return .orderedSame }
        return (ascending ? left < right : left > right) ? .orderedAscending : .orderedDescending
    }

    private func compareStatus(_ left: String, _ right: String, order: [String]) -> ComparisonResult {
        if left.isEmpty || right.isEmpty { return Self.compareText(left, right, ascending: ascending) }
        let result = compareNumber(Double(order.firstIndex(of: left) ?? 999), Double(order.firstIndex(of: right) ?? 999))
        return result == .orderedSame ? Self.compareText(left, right, ascending: ascending) : result
    }

    private static func compareText(_ left: String, _ right: String, ascending: Bool) -> ComparisonResult {
        let left = left.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = right.trimmingCharacters(in: .whitespacesAndNewlines)
        if left.isEmpty && right.isEmpty { return .orderedSame }
        if left.isEmpty { return .orderedDescending }
        if right.isEmpty { return .orderedAscending }
        let result = left.compare(right, options: [.numeric, .caseInsensitive, .diacriticInsensitive], locale: .current)
        return ascending ? result : (result == .orderedAscending ? .orderedDescending : result == .orderedDescending ? .orderedAscending : .orderedSame)
    }
}

// Mirrors customerTags.js without applying dashboard-specific scope restrictions.
struct JobListRegionAccess {
    let fullAccess: Bool
    let tags: [String]

    init(userAccess: [String: Any], role: [String: Any]) {
        let fields = ["fullCustomerRegionAccess", "fullRegionalAccess", "regionalAccessMode", "customerRegionAccessMode"]
        let hasOverride = fields.prefix(2).contains { userAccess[$0] != nil }
            || fields.suffix(2).contains { !(userAccess[$0] as? String ?? "").isEmpty } || !Self.tags(userAccess).isEmpty
        let source = hasOverride ? userAccess : role
        let tags = Self.tags(source)
        if source["fullCustomerRegionAccess"] as? Bool == true || source["fullRegionalAccess"] as? Bool == true
            || source["regionalAccessMode"] as? String == "all" || source["customerRegionAccessMode"] as? String == "all" {
            fullAccess = true
        } else if source["fullCustomerRegionAccess"] as? Bool == false || source["fullRegionalAccess"] as? Bool == false
            || source["regionalAccessMode"] as? String == "limited" || source["customerRegionAccessMode"] as? String == "limited" {
            fullAccess = false
        } else { fullAccess = tags.isEmpty }
        self.tags = fullAccess ? [] : tags
    }

    func includes(customerId: String, customers: [String: [String]], selectedTag: String) -> Bool {
        let selectedTag = Self.key(selectedTag)
        if fullAccess && selectedTag.isEmpty { return true }
        guard let tags = customers[customerId] else { return false }
        let keys = Set(tags.map(Self.key))
        return (fullAccess || self.tags.isEmpty || !keys.isDisjoint(with: self.tags.map(Self.key)))
            && (selectedTag.isEmpty || keys.contains(selectedTag))
    }

    static func key(_ text: String) -> String { text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    static func strings(_ value: Any?) -> [String] {
        let values = value as? [String] ?? (value as? String)?.components(separatedBy: ",") ?? []
        var seen: Set<String> = []
        return values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty && seen.insert(key($0)).inserted }
    }
    private static func tags(_ source: [String: Any]) -> [String] {
        for field in ["customerRegionTags", "regionalCustomerTags", "regionalTags", "customerTagAccess", "allowedCustomerTags", "customerTags"] {
            if let value = source[field], !(value is NSNull) { return strings(value) }
        }
        return []
    }
}
