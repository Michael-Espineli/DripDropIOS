#!/usr/bin/env python3
"""Exercise actual route models, transaction writer, and technician start/reopen/finish code."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
writer = (root / 'DripDrop/Resources/DataService/Protocol/Customer/ActiveRoute+ProductionDataService+Extension.swift').read_text()
view_model = (root / 'DripDrop/Modules/Dashboard/Logic/MobileDailyRouteDisplayViewModel.swift').read_text()
dashboard = (root / 'DripDrop/Modules/Dashboard/View/EmployeeDailyDashboard.swift').read_text()
errors = (root / 'DripDrop/Resources/Errors.swift').read_text()


def block(source, marker):
    start = source.index(marker)
    opening = source.index('{', start)
    depth, end = 1, opening + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end].replace('private ', '')


stubs = r'''
import Foundation
struct PersonalVehicle: Codable, Equatable { var make: String; var model: String; var miles: Double }
struct ServiceStopOrder: Codable, Equatable { var id: String; var order: Int; var serviceStopId: String; var recurringServiceStopId: String }
enum ActiveRouteStatus: String, Codable { case didNotStart = "Did Not Start", inProgress = "In Progress", traveling = "Traveling", onBreak = "Break", finished = "Finished" }
enum FireBaseRead: Error { case unableToRead }
enum Failure: Error { case denied }
extension Date {
    func endOfDay() -> Date { Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: self))! }
}
struct DBUser { var id = "tech" }
enum WorkLogType { case working }
@MainActor final class NotificationViewModel {
    static let shared = NotificationViewModel()
    func requestAuthorizationIfNeeded() async -> Bool { true }
}
@MainActor final class LocationManager {
    var starts = 0; var stops = 0
    func startTracking() { starts += 1 }
    func stopTracking() { stops += 1 }
}
enum FieldValue { case remove; static func delete() -> FieldValue { .remove } }
@MainActor final class Reference {
    var stored: [String: Any] = [:]
    var exists = true; var deferCommit = false; var failRead = false
    var pending: CheckedContinuation<Void, Error>?
    var writes: [[String: Any]] = []
    func updateData(_ fields: [String: Any]) async throws {
        if deferCommit { try await withCheckedThrowingContinuation { pending = $0 } }
        writes.append(fields)
        apply(fields)
    }
    func apply(_ fields: [String: Any]) {
        for (key, value) in fields {
            if value is FieldValue { stored.removeValue(forKey: key) }
            else if let date = value as? Date { stored[key] = date.timeIntervalSince1970 }
            else { stored[key] = value }
        }
    }
    func resolve(_ error: Error? = nil) {
        let continuation = pending; pending = nil
        if let error { continuation?.resume(throwing: error) }
        else { continuation?.resume() }
    }
    func route() throws -> ActiveRoute {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(ActiveRoute.self, from: JSONSerialization.data(withJSONObject: stored))
    }
}
@MainActor struct Snapshot {
    let ref: Reference
    var exists: Bool { ref.exists }
    func data<T: Decodable>(as type: T.Type) throws -> T {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(type, from: JSONSerialization.data(withJSONObject: ref.stored))
    }
}
@MainActor final class Transaction {
    var fields: [String: Any] = [:]; var ref: Reference?
    func getDocument(_ ref: Reference) throws -> Snapshot {
        if ref.failRead { throw Failure.denied }; return Snapshot(ref: ref)
    }
    func updateData(_ fields: [String: Any], forDocument ref: Reference) { self.fields = fields; self.ref = ref }
}
@MainActor final class Database {
    var calls = 0
    func runTransaction(_ body: (Transaction, UnsafeMutablePointer<NSError?>?) -> Any?) async throws -> Any? {
        calls += 1
        let transaction = Transaction(); var error: NSError?
        let result = body(transaction, &error)
        if let error { throw error }
        if let ref = transaction.ref { try await ref.updateData(transaction.fields) }
        return result
    }
}
@MainActor final class Writer {
    let db = Database(); let ref = Reference(); var requestedId = ""
    func ActiveRouteDocument(companyId: String, activeRouteId: String) -> Reference { requestedId = activeRouteId; return ref }
    func updateActiveRouteStatus(companyId: String, activeRouteId: String, status: ActiveRouteStatus) { ref.apply(["status": status.rawValue]) }
    func updateActiveRouteEndTime(companyId: String, activeRouteId: String, endTime: Date) { ref.apply(["endTime": endTime]) }
    func updateActiveRouteEndMilage(companyId: String, activeRouteId: String, endMilage: Double) { ref.apply(["endMilage": endMilage]) }
    func updateActiveRouteDistnace(companyId: String, activeRouteId: String, distance: Double) { ref.apply(["distanceMiles": distance]) }
'''
harness = r'''
}
@MainActor final class Harness {
    let dataService = Writer(); let routeLocationManager = LocationManager()
    var activeRoute: ActiveRoute?; var isChangingRouteState = false
    var cachedCompanyId: String? = "company"; var cachedCompanyName: String?; var cachedUser: DBUser?
    var startTime = Date(); var startMilage = 0.0; var endMilage = 0.0
    var inputEndMilage = ""; var showEndMilage = false; var showMilage = false
    var alertMessage = ""; var showAlert = false
    var openedLogs = 0; var closedLogs = 0; var timers = 0; var stoppedTimers = 0
    func closeCurrentSummaryLog(companyId: String, activeRouteId: String) async { closedLogs += 1 }
    func openSummaryLog(type: WorkLogType, companyId: String, companyName: String, activeRouteId: String, user: DBUser) async { openedLogs += 1 }
    func startRouteLogTimer(companyId: String, activeRouteId: String, user: DBUser, companyName: String) { timers += 1 }
    func stopRouteLogTimer(companyId: String, activeRouteId: String, user: DBUser, companyName: String) { stoppedTimers += 1 }
    func syncRouteVehicleMileage(companyId: String, route: ActiveRoute, miles: Double, syncSelectedVehicle: Bool) {}
'''
ui_harness = r'''
}
@MainActor final class Dashboard {
    let VM: Harness
    var routeCloseoutPromptedRouteId: String?; var routePendingEnd: ActiveRoute?
    init(_ model: Harness) { VM = model }
'''
checks = r'''
}
@main struct Checks {
    @MainActor static func drain() async { for _ in 0..<200 { await Task.yield() } }
    @MainActor static func main() async throws {
        var count = 0
        func check(_ condition: @autoclosure () -> Bool, _ label: String) { precondition(condition(), label); count += 1; print("PASS: \(label)") }
        let day = Calendar.current.startOfDay(for: Date())
        let start = day.addingTimeInterval(8 * 3600)
        let finish = day.addingTimeInterval(12 * 3600)
        let original: [String: Any] = [
            "id": "saved-route", "name": "Tuesday route", "date": day.timeIntervalSince1970,
            "startTime": start.timeIntervalSince1970, "endTime": finish.timeIntervalSince1970,
            "startMilage": 1000.5, "startMileage": 1000.5, "endMilage": 1040.5, "endMileage": 1040.5,
            "techId": "tech", "techName": "Alex", "traineeId": "trainee", "traineeName": "Taylor",
            "vehicalId": "truck", "vehicleSource": "Personal", "personalVehicleOwnerId": "tech",
            "vehicleLabel": "My truck", "vehiclePlate": "TEST", "vehicleMake": "Ford", "vehicleModel": "Ranger",
            "personalVehicle": ["make": "Ford", "model": "Ranger", "miles": 1040.5],
            "status": "Finished", "finishedStops": 2, "totalStops": 2, "serviceStopsIds": ["one", "two"],
            "order": [["id": "order", "order": 1, "serviceStopId": "two", "recurringServiceStopId": "recurring"]],
            "distanceMiles": 40, "distance": 40, "durationSeconds": 3600,
            "unmodeledHistory": ["keep": "existing payroll/log metadata"]
        ]
        func model(_ fields: [String: Any]) throws -> Harness {
            let value = Harness(); value.dataService.ref.stored = fields
            value.activeRoute = try value.dataService.ref.route(); return value
        }
        let m = try model(original)
        m.dataService.ref.deferCommit = true
        m.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser())
        m.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser())
        await drain()
        check(m.isChangingRouteState && m.dataService.db.calls == 1, "Repeated taps issue one reopen transaction")
        check(m.activeRoute?.status == .finished && m.routeLocationManager.starts == 0 && m.openedLogs == 0, "Wait for server confirmation before changing the route or tracking")
        m.dataService.ref.resolve(); await drain()
        let reopened = try m.dataService.ref.route()
        check(!m.isChangingRouteState && reopened.id == "saved-route" && m.dataService.requestedId == "saved-route", "Reopen the saved document without generating a new route")
        check(reopened.startTime == start && reopened.startMilage == 1000.5, "Preserve the original starting time and mileage")
        check(reopened.status == .inProgress && reopened.endTime == nil && reopened.endMilage == nil, "Clear the old closeout and mark the route in progress together")
        check(m.dataService.ref.stored["endMileage"] == nil && m.dataService.ref.stored["distance"] == nil && reopened.distanceMiles == 0, "Remove legacy end-mileage and completed-distance fallbacks")
        check(reopened.serviceStopsIds == ["one", "two"] && reopened.order?.first?.serviceStopId == "two" && reopened.finishedStops == 2, "Preserve stops, completion counts, and saved order")
        check(reopened.vehicalId == "truck" && reopened.personalVehicle?.miles == 1040.5 && reopened.traineeId == "trainee", "Preserve vehicle, personal-vehicle snapshot, and trainee")
        check(m.dataService.ref.stored["unmodeledHistory"] != nil && reopened.durationMin == 3600, "Sparse reopen writes preserve other history and planned duration")
        check(m.startTime == start && m.startMilage == 1000.5 && !m.showMilage && !m.showEndMilage, "Reopening does not ask for new start details")
        check(m.routeLocationManager.starts == 1 && m.openedLogs == 1 && m.timers == 1, "Confirmed reopen resumes tracking and working logs once")
        m.dataService.ref.deferCommit = false
        let retried = try await m.dataService.startOrResumeActiveRoute(companyId: "company", activeRouteId: "saved-route", startTime: Date())
        check(retried.startTime == start && retried.endTime == nil && retried.order == reopened.order, "Retrying an already reopened route preserves original information")
        m.inputEndMilage = "1065.5"
        m.finishRouteWithEndMileage(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        let finished = try m.dataService.ref.route()
        check(finished.status == .finished && finished.endMilage == 1065.5 && finished.endTime != nil, "Finish the reopened route with fresh ending information")
        check(finished.startTime == start && finished.startMilage == 1000.5 && finished.distanceMiles == 65, "Second finish calculates total mileage from the original start")
        check(m.stoppedTimers == 1 && m.routeLocationManager.stops == 1, "Second finish stops tracking normally")

        let denied = try model(original); denied.dataService.ref.deferCommit = true
        denied.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        denied.dataService.ref.resolve(NSError(domain: "FIRFirestoreErrorDomain", code: 7)); await drain()
        check(denied.activeRoute?.status == .finished && denied.activeRoute?.endTime == finish && denied.dataService.ref.writes.isEmpty, "Failed reopen leaves saved and displayed closeout intact")
        check(denied.showAlert && !denied.alertMessage.isEmpty && !denied.isChangingRouteState && denied.openedLogs == 0, "Failed reopen shows an error, allows retry, and does not create working logs")
        check(denied.alertMessage.contains("Firebase Firestore permission denied"), "Assigned-route permission failures retain the actual Firebase error source")
        denied.dataService.ref.deferCommit = false
        denied.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(denied.activeRoute?.status == .inProgress && denied.activeRoute?.startTime == start, "A denied reopen can be retried without resetting the original start")

        let stale = try model(original); stale.dataService.ref.deferCommit = true
        stale.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        stale.activeRoute?.id = "tomorrow"
        stale.dataService.ref.resolve(); await drain()
        check(stale.activeRoute?.id == "tomorrow" && stale.routeLocationManager.starts == 0 && stale.openedLogs == 0, "Changing route during a write prevents stale response and tracking takeover")

        let switchCompany = try model(original); switchCompany.dataService.ref.deferCommit = true
        switchCompany.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        switchCompany.cachedCompanyId = "other-company"
        switchCompany.dataService.ref.resolve(); await drain()
        check(switchCompany.activeRoute?.status == .finished && switchCompany.routeLocationManager.starts == 0, "Changing company while reopening cannot replace the displayed route or restart tracking")

        let staleDetails = try model(original)
        staleDetails.activeRoute?.startTime = Date(); staleDetails.activeRoute?.startMilage = 2000; staleDetails.activeRoute?.vehicalId = "unsaved-truck"
        staleDetails.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(staleDetails.activeRoute?.startTime == start && staleDetails.activeRoute?.startMilage == 1000.5 && staleDetails.activeRoute?.vehicalId == "truck", "Use saved server start and vehicle information instead of stale UI values")

        let missing = try model(original); missing.dataService.ref.exists = false
        missing.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(missing.showAlert && missing.dataService.ref.writes.isEmpty && missing.activeRoute?.status == .finished, "Missing route is reported without creating a replacement route")

        let failedRead = try model(original); failedRead.dataService.ref.failRead = true
        failedRead.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(failedRead.showAlert && failedRead.dataService.ref.writes.isEmpty && failedRead.openedLogs == 0, "Failed route reads cannot write a partial reopen or create logs")

        var noVehicle = original
        noVehicle["vehicalId"] = ""
        for key in ["vehicleSource", "personalVehicle", "personalVehicleOwnerId"] { noVehicle.removeValue(forKey: key) }
        let vehicleless = try model(noVehicle)
        vehicleless.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(vehicleless.activeRoute?.status == .inProgress && vehicleless.activeRoute?.vehicalId == "" && !vehicleless.showMilage, "A route originally started without a vehicle can reopen without selecting one")

        var legacy = original; legacy.removeValue(forKey: "startMilage"); legacy.removeValue(forKey: "endMilage")
        let old = try model(legacy)
        old.startActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(old.activeRoute?.startMilage == 1000.5 && old.activeRoute?.startTime == start && !old.showMilage, "Start entry point also reopens legacy routes without replacing their start")
        let reloadedLegacy = try old.dataService.ref.route()
        check(reloadedLegacy.endMilage == nil, "Legacy end-mileage cannot reappear after reload")

        var empty = original
        for key in ["startTime", "startMilage", "startMileage", "endTime", "endMilage", "endMileage"] { empty.removeValue(forKey: key) }
        empty["status"] = "Did Not Start"; empty["finishedStops"] = 0
        let fresh = try model(empty)
        fresh.startActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(fresh.activeRoute?.status == .inProgress && fresh.activeRoute?.startTime != nil && fresh.showMilage, "A new route still starts and opens its start-mileage sheet")
        var paused = original
        for key in ["endTime", "endMilage", "endMileage"] { paused.removeValue(forKey: key) }
        paused["status"] = "Break"; paused["distanceMiles"] = 10
        let pause = try model(paused)
        pause.resumeActiveRoute(companyId: "company", companyName: "Pool", user: DBUser()); await drain()
        check(pause.activeRoute?.status == .inProgress && pause.activeRoute?.startTime == start && pause.activeRoute?.distanceMiles == 10 && !pause.showMilage, "Resuming a break retains original start and current route distance")

        let page = try model(original); let pageUI = Dashboard(page)
        pageUI.presentRouteCloseoutIfNeeded()
        check(!page.showEndMilage && !pageUI.routeNeedsStartMileage(page.activeRoute!), "A completed route does not ask for a new start or immediately show closeout")
        page.isChangingRouteState = true; page.activeRoute = reopened
        pageUI.presentRouteCloseoutIfNeeded()
        check(!page.showEndMilage, "Reopening with all stops still complete does not immediately force finishing again")
        page.isChangingRouteState = false; pageUI.routeCloseoutPromptedRouteId = reopened.id
        pageUI.presentRouteCloseoutIfNeeded()
        check(!page.showEndMilage, "Explicit reopen suppresses the repeat automatic closeout prompt")
        check(!pageUI.routeNeedsStartMileage(reopened), "Reopened routes with saved mileage need no start sheet")
        var partiallyReopened = reopened; partiallyReopened.endTime = finish
        check(partiallyReopened.needsReopening, "Stale in-progress status with an ending time still offers reopening")
        print("\(count) route reopening, start/resume/finish, legacy, confirmation, failure, and stale-response checks passed")
    }
}
'''
production = block(writer, 'struct ActiveRoute:')
production += '\n' + block(writer, 'func startOrResumeActiveRoute(')
vm_methods = '\n'.join(block(view_model, marker) for marker in [
    'func startActiveRoute(', 'private func activateRoute(', 'func resumeActiveRoute(',
    'func finishRouteWithEndMileage(', 'func stopActiveRoute(', 'private func routeEndTime('])
ui_methods = '\n'.join(block(dashboard, marker) for marker in [
    'private func routeNeedsStartMileage(', 'private func routeNeedsCloseout(',
    'private func presentRouteCloseoutIfNeeded(', 'private func prepareEndMileageInput('])
# The model belongs before the controlled Writer class, then use the actual method bodies.
model_source, writer_method = production.split('func startOrResumeActiveRoute(', 1)
stubs = stubs.replace('@MainActor final class Writer {', model_source + '\n@MainActor final class Writer {')
presenter = block(errors, 'enum PermissionErrorPresentation {') + '\n' + block(errors, 'extension Error {')
stubs = stubs.replace('import Foundation', 'import Foundation\n' + presenter, 1)
with tempfile.TemporaryDirectory(prefix='dripdrop-route-reopening-') as directory:
    fixture = Path(directory) / 'checks.swift'
    executable = Path(directory) / 'checks'
    fixture.write_text(stubs + 'func startOrResumeActiveRoute(' + writer_method + harness + vm_methods + ui_harness + ui_methods + checks)
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', '/private/tmp/dripdrop-route-reopening-modules', str(fixture), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
