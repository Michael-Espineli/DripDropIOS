import Foundation

// Mirrors the web dashboard's user override > role > legacy defaults contract.
// These are presentation filters; Firestore remains the authority for data access.
struct CompanyDashboardAccess: Hashable {
    let scopes: Set<String>
    let permissions: Set<String>
    let fullRegionAccess: Bool
    let regionTags: [String]
    let isOwner: Bool

    init(userAccess: [String: Any], role: [String: Any], isOwner: Bool) {
        let defaults = ["personal", "regional", "company"]
        let scopeSource: [String: Any]
        if userAccess["dashboardScopeAccessMode"] as? String == "custom" || userAccess["dashboardScopeAccess"] is [String] {
            scopeSource = userAccess
        } else {
            scopeSource = role
        }
        let scopeValues = scopeSource["dashboardScopeAccess"] as? [String]
            ?? scopeSource["allowedDashboardScopes"] as? [String] ?? defaults
        scopes = Set(scopeValues.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { defaults.contains($0) })
        permissions = Set(CompanyDashboardRecord.strings(role["permissionIdList"]))
        self.isOwner = isOwner

        let regionSource = Self.hasRegionFields(userAccess) ? userAccess : role
        let tags = Self.tags(in: regionSource)
        if regionSource["fullCustomerRegionAccess"] as? Bool == true || regionSource["fullRegionalAccess"] as? Bool == true
            || regionSource["regionalAccessMode"] as? String == "all" || regionSource["customerRegionAccessMode"] as? String == "all" {
            fullRegionAccess = true
        } else if regionSource["fullCustomerRegionAccess"] as? Bool == false || regionSource["fullRegionalAccess"] as? Bool == false
            || regionSource["regionalAccessMode"] as? String == "limited" || regionSource["customerRegionAccessMode"] as? String == "limited" {
            fullRegionAccess = false
        } else {
            fullRegionAccess = tags.isEmpty
        }
        regionTags = fullRegionAccess ? [] : tags
    }

    var canViewTechnician: Bool { scopes.contains("personal") }
    var canViewManager: Bool { scopes.contains("company") || scopes.contains("regional") }
    var canViewAllAreas: Bool { scopes.contains("company") }
    func permits(_ permission: String) -> Bool { isOwner || permissions.contains(permission) }
    var canViewStops: Bool { permits("210") || permits("220") || permits("240") }

    func availableTags(customers: [CompanyDashboardRecord]) -> [String] {
        let tags = fullRegionAccess ? customers.flatMap(\.tags) : regionTags
        return CompanyDashboardRecord.strings(tags).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    func includes(_ record: CompanyDashboardRecord, customers: [String: CompanyDashboardRecord], selectedTag: String) -> Bool {
        guard canViewManager else { return false }
        let selected = CompanyDashboardRecord.key(selectedTag)
        // A regional-only scope must select an area; an empty limited grant grants no records.
        if !canViewAllAreas && selected.isEmpty { return false }
        if !fullRegionAccess && regionTags.isEmpty { return false }
        if fullRegionAccess && selected.isEmpty { return true }
        let tags = record.customerIds.compactMap { customers[$0] }.flatMap(\.tags)
        let keys = Set((record.customerIds.contains(where: { customers[$0] != nil }) ? tags : record.tags).map(CompanyDashboardRecord.key))
        if !fullRegionAccess && keys.isDisjoint(with: Set(regionTags.map(CompanyDashboardRecord.key))) { return false }
        return selected.isEmpty || keys.contains(selected)
    }

    private static func tags(in source: [String: Any]) -> [String] {
        for field in ["customerRegionTags", "regionalCustomerTags", "regionalTags", "customerTagAccess", "allowedCustomerTags", "customerTags"] {
            if let value = source[field] { return CompanyDashboardRecord.strings(value) }
        }
        return []
    }

    private static func hasRegionFields(_ source: [String: Any]) -> Bool {
        ["fullCustomerRegionAccess", "fullRegionalAccess"].contains { source[$0] != nil }
            || ["regionalAccessMode", "customerRegionAccessMode"].contains { !(source[$0] as? String ?? "").isEmpty }
            || !tags(in: source).isEmpty
    }
}

struct CompanyDashboardRecord: Identifiable {
    let id: String
    let customerIds: [String]
    let tags: [String]
    let title: String
    let customerName: String
    let status: String
    let billingStatus: String
    let technicianId: String
    let technicianName: String
    let serviceDate: Date?
    let requestDate: Date?
    let isActiveCustomer: Bool

    init(id: String, data: [String: Any]) {
        self.id = id
        let nestedCustomer = data["customer"] as? [String: Any] ?? [:]
        customerIds = Self.strings([data["customerId"] as? String ?? "", data["internalCustomerId"] as? String ?? "", nestedCustomer["id"] as? String ?? ""])
        tags = Self.strings(data["tags"] ?? data["customerTags"] ?? data["regionalTags"])
        customerName = data["customerName"] as? String ?? ""
        title = Self.strings([data["description"] as? String ?? "", data["name"] as? String ?? "", data["internalId"] as? String ?? ""]).first ?? "Untitled work"
        status = data["operationStatus"] as? String ?? data["status"] as? String ?? ""
        billingStatus = data["billingStatus"] as? String ?? ""
        technicianId = (data["techId"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        technicianName = Self.strings([data["tech"] as? String ?? "", data["techName"] as? String ?? ""]).first ?? "Technician"
        serviceDate = data["serviceDate"] as? Date
        requestDate = RepairRequestQueue.date(data)
        isActiveCustomer = (data["active"] as? Bool ?? data["isActive"] as? Bool) != false
    }

    var isFinished: Bool { Self.key(status) == "finished" || Self.key(status) == "completed" }
    var isSkipped: Bool { ["skipped", "canceled", "cancelled"].contains(Self.key(status)) }
    var isUnassigned: Bool { ["", "unassigned", "notassigned"].contains(Self.key(technicianId).replacingOccurrences(of: " ", with: "")) }
    var isOpenJob: Bool {
        !isFinished && !isSkipped && !["expired", "rejected", "comped"].contains(Self.key(billingStatus))
            && !["expired", "rejected", "closed"].contains(Self.key(status))
    }
    var needsScheduling: Bool { isOpenJob && ["unscheduled", "accepted"].contains(Self.key(status)) }
    var isOpenRequest: Bool { RepairRequestStatus.normalized(status).isOpenWorkQueueItem }

    static func key(_ value: String) -> String { value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
    static func strings(_ value: Any?) -> [String] {
        let values = value as? [String] ?? (value as? String)?.components(separatedBy: ",") ?? []
        var seen: Set<String> = []
        return values.compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty && seen.insert(key(trimmed)).inserted ? trimmed : nil
        }
    }
}

struct CompanyDashboardWorkload: Identifiable {
    let id: String
    let name: String
    let stops: [CompanyDashboardRecord]
    var finished: Int { stops.filter(\.isFinished).count }
    var remaining: Int { stops.filter { !$0.isFinished && !$0.isSkipped }.count }
}

struct CompanyDashboardSnapshot {
    let customers: [CompanyDashboardRecord]
    let stops: [CompanyDashboardRecord]
    let jobs: [CompanyDashboardRecord]
    let requests: [CompanyDashboardRecord]
    let selectedDate: Date

    var dailyStops: [CompanyDashboardRecord] { stops.filter { $0.serviceDate.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } == true } }
    var finished: Int { dailyStops.filter(\.isFinished).count }
    var skipped: Int { dailyStops.filter(\.isSkipped).count }
    var remaining: Int { dailyStops.count - finished - skipped }
    var unassigned: Int { dailyStops.filter { $0.isUnassigned && !$0.isFinished && !$0.isSkipped }.count }
    var schedulingQueue: [CompanyDashboardRecord] { jobs.filter(\.needsScheduling).sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending } }
    var workload: [CompanyDashboardWorkload] {
        Dictionary(grouping: dailyStops.filter { !$0.isUnassigned }, by: \.technicianId).map { id, stops in
            CompanyDashboardWorkload(id: id, name: stops.first?.technicianName ?? "Technician", stops: stops)
        }.sorted { $0.remaining == $1.remaining ? $0.name.localizedStandardCompare($1.name) == .orderedAscending : $0.remaining > $1.remaining }
    }
}
