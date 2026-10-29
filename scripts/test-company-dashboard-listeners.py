#!/usr/bin/env python3
"""Run the actual dashboard view models against controllable snapshot listeners."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
models = (root / 'DripDrop/Modules/Dashboard/Logic/CompanyDashboardSnapshot.swift').read_text()
view_models = (root / 'DripDrop/Modules/Dashboard/Logic/CompanyDashboardViewModel.swift').read_text().replace('import FirebaseFirestore', 'import Combine')
fake_firestore = r'''
protocol ListenerRegistration { func remove() }
final class FakeRegistration: ListenerRegistration {
    var removed = false
    func remove() { removed = true }
}
struct Timestamp {
    let value: Date
    func dateValue() -> Date { value }
}
class DocumentSnapshot {
    let documentID: String
    private let fields: [String: Any]?
    init(_ id: String, _ fields: [String: Any]?) { documentID = id; self.fields = fields }
    func data() -> [String: Any]? { fields }
}
final class QueryDocumentSnapshot {
    let documentID: String
    let fields: [String: Any]
    init(_ id: String, _ fields: [String: Any]) { documentID = id; self.fields = fields }
    func data() -> [String: Any] { fields }
}
struct QuerySnapshot { let documents: [QueryDocumentSnapshot] }
final class FakeDocumentSubscription {
    let registration = FakeRegistration()
    let callback: (DocumentSnapshot?, Error?) -> Void
    init(_ callback: @escaping (DocumentSnapshot?, Error?) -> Void) { self.callback = callback }
}
final class FakeQuerySubscription {
    let registration = FakeRegistration()
    let callback: (QuerySnapshot?, Error?) -> Void
    init(_ callback: @escaping (QuerySnapshot?, Error?) -> Void) { self.callback = callback }
}
class Query {
    let path: String
    init(_ path: String) { self.path = path }
    func whereField(_ name: String, isGreaterThanOrEqualTo value: Any) -> Query { self }
    func whereField(_ name: String, isLessThan value: Any) -> Query { self }
    func whereField(_ name: String, isEqualTo value: Any) -> Query { self }
    func whereField(_ name: String, in values: [String]) -> Query { self }
    func addSnapshotListener(_ callback: @escaping (QuerySnapshot?, Error?) -> Void) -> ListenerRegistration {
        let listener = FakeQuerySubscription(callback)
        Firestore.shared.queries[path, default: []].append(listener)
        return listener.registration
    }
}
final class CollectionReference: Query {
    func document(_ id: String) -> DocumentReference { DocumentReference(path + "/" + id) }
}
final class DocumentReference {
    let path: String
    init(_ path: String) { self.path = path }
    func collection(_ name: String) -> CollectionReference { CollectionReference(path + "/" + name) }
    func addSnapshotListener(_ callback: @escaping (DocumentSnapshot?, Error?) -> Void) -> ListenerRegistration {
        let listener = FakeDocumentSubscription(callback)
        Firestore.shared.documents[path, default: []].append(listener)
        return listener.registration
    }
}
final class Firestore {
    static let shared = Firestore()
    static func firestore() -> Firestore { shared }
    var documents: [String: [FakeDocumentSubscription]] = [:]
    var queries: [String: [FakeQuerySubscription]] = [:]
    func document(_ path: String) -> DocumentReference { DocumentReference(path) }
    func collection(_ path: String) -> CollectionReference { CollectionReference(path) }
}
'''
enums = (root / 'DripDrop/Resources/ListOfEnum.swift').read_text()
status = enums[enums.index('enum RepairRequestStatus:'):enums.index('enum RateSheetStatus:')]
checks = r'''
@MainActor func runChecks() async {
    var count = 0
    func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
        count += 1
    }
    func settle() async { for _ in 0..<8 { await Task.yield() } }
    let db = Firestore.shared
    let accessVM = CompanyDashboardAccessViewModel()
    accessVM.start(companyId: "one", userId: "user", isOwner: false)
    check(accessVM.access == nil, "Wait for access documents before exposing a dashboard")
    let membership = db.documents["users/user/userAccess/one"]!.last!
    membership.callback(DocumentSnapshot("one", ["roleId": "old"]), nil)
    await settle()
    let oldRole = db.documents["companies/one/roles/old"]!.last!
    membership.callback(DocumentSnapshot("one", ["roleId": "new"]), nil)
    await settle()
    oldRole.callback(DocumentSnapshot("old", ["dashboardScopeAccess": ["company"]]), nil)
    await settle()
    check(oldRole.registration.removed && accessVM.access == nil, "Queued old-role callbacks must be ignored")
    let newRole = db.documents["companies/one/roles/new"]!.last!
    newRole.callback(DocumentSnapshot("new", ["dashboardScopeAccess": ["personal"]]), nil)
    await settle()
    check(accessVM.access?.canViewTechnician == true && accessVM.access?.canViewManager == false, "Use the current role")
    accessVM.start(companyId: "two", userId: "user", isOwner: false)
    newRole.callback(DocumentSnapshot("new", ["dashboardScopeAccess": ["company"]]), nil)
    await settle()
    check(membership.registration.removed && newRole.registration.removed && accessVM.access == nil, "Company changes remove listeners and ignore old callbacks")
    accessVM.stop()
    check(db.documents["users/user/userAccess/two"]!.last!.registration.removed, "Stop access listener when leaving")

    let access = CompanyDashboardAccess(userAccess: [:], role: ["permissionIdList": ["20", "30", "240"]], isOwner: false)
    let model = CompanyDashboardViewModel()
    let date = Calendar.current.startOfDay(for: Date())
    model.start(companyId: "one", access: access, date: date)
    let jobs = db.queries["companies/one/workOrders"]!.last!
    jobs.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("job", ["customerId": "north", "operationStatus": "Unscheduled"])]), nil)
    await settle()
    check(!model.isReady("jobs"), "Wait for canonical customer tags before presenting counts")
    let customers = db.queries["companies/one/customers"]!.last!
    customers.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("north", ["tags": ["North"]])]), nil)
    let stops = db.queries["companies/one/serviceStops"]!.last!
    stops.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("stop", ["customerId": "north", "serviceDate": Timestamp(value: date), "operationStatus": "Finished", "techId": "tech"])]), nil)
    await settle()
    let snapshot = model.snapshot(access: access, tag: "North", date: date)
    check(model.isReady("jobs") && snapshot.jobs.count == 1 && snapshot.finished == 1, "Live snapshots normalize timestamps and join canonical tags")
    let companyRequests = db.queries["companies/one/repairRequests"]!.last!
    let homeownerRequests = db.queries["homeownerRepairRequests"]!.last!
    companyRequests.callback(QuerySnapshot(documents: [
        QueryDocumentSnapshot("shared", ["customerId": "north", "status": "Unresolved"]),
        QueryDocumentSnapshot("legacy", ["customerId": "north", "status": " Pending "]),
        QueryDocumentSnapshot("converted", ["customerId": "north", "status": "In Progress"])
    ]), nil)
    await settle()
    check(!model.isReady("requests"), "Wait for both request sources before showing a total")
    homeownerRequests.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("shared", ["customerId": "north", "status": "Unresolved"])]), nil)
    await settle()
    let requests = model.snapshot(access: access, tag: "North", date: date).requests
    check(model.isReady("requests") && requests.count == 3, "Both sources share the unresolved/legacy-pending queue and exclude converted progress")
    check(Set(requests.map(\.id)).count == 3, "Matching document IDs in different sources stay distinct")
    homeownerRequests.callback(nil, NSError(domain: "test", code: 2))
    await settle()
    check(!model.isReady("requests") && model.errors["requests"] != nil, "A request source failure must not present a partial count as complete")
    homeownerRequests.callback(QuerySnapshot(documents: []), nil)
    await settle()
    check(model.isReady("requests") && model.errors["requests"] == nil, "A recovered source clears the combined request error")
    customers.callback(nil, NSError(domain: "test", code: 1))
    await settle()
    check(!model.isReady("jobs") && model.snapshot(access: access, tag: "North", date: date).jobs.isEmpty, "Dependency failure clears visible counts")
    model.start(companyId: "two", access: access, date: date)
    jobs.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("stale", ["operationStatus": "Unscheduled"])]), nil)
    await settle()
    check(jobs.registration.removed && stops.registration.removed && customers.registration.removed, "Remove all previous-company subscriptions")
    check(model.records.isEmpty, "Late previous-company query results cannot repopulate records")
    let currentCustomers = db.queries["companies/two/customers"]!.last!
    model.stop()
    currentCustomers.callback(QuerySnapshot(documents: [QueryDocumentSnapshot("stale", ["tags": ["North"]])]), nil)
    await settle()
    check(model.records.isEmpty && model.loaded.isEmpty && model.errors.isEmpty, "Hidden manager views clear data and ignore callbacks")
    let subscriptionsBefore = db.queries.values.reduce(0) { $0 + $1.count }
    let personal = CompanyDashboardAccess(userAccess: ["dashboardScopeAccess": ["personal"]], role: [:], isOwner: false)
    model.start(companyId: "personal", access: personal, date: date)
    check(db.queries.values.reduce(0) { $0 + $1.count } == subscriptionsBefore, "Personal-only access must not subscribe to company data")
    let jobsBefore = db.queries["companies/one/workOrders"]!.count
    let stopsOnly = CompanyDashboardAccess(userAccess: [:], role: ["permissionIdList": ["240"]], isOwner: false)
    model.start(companyId: "one", access: stopsOnly, date: date)
    check(db.queries["companies/one/workOrders"]!.count == jobsBefore, "Query only permitted company sections")
    model.stop()
    print("\(count) dashboard listener lifecycle, access-change, error, and stale-callback checks passed")
}
await runChecks()
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-dashboard-listeners-') as directory:
    fixture = Path(directory) / 'main.swift'
    fixture.write_text(status + models + fake_firestore + view_models + checks)
    subprocess.run(['swift', '-module-cache-path', '/private/tmp/dripdrop-dashboard-modules', str(fixture)], check=True)
