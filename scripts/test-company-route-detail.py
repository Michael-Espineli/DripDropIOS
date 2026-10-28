#!/usr/bin/env python3
"""Run actual route-popup selection and loading/move code with a controlled service."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'DripDrop/Modules/Route/NewViews/CompanyRouteDetailPresentation.swift').read_text()
coverage = (root / 'DripDrop/Modules/WorkOffer/JobWorkOffersView.swift').read_text()

def block(text, marker):
    start = text.index(marker)
    pos = text.index('{', start)
    depth = 1
    end = pos + 1
    while depth:
        if text[end] == '{': depth += 1
        elif text[end] == '}': depth -= 1
        end += 1
    return text[start:end] + '\n'

stubs = r'''import Foundation
import Combine
enum ServiceStopOperationStatus: String { case notFinished, finished, skipped }
enum ActiveRouteStatus { case didNotStart, inProgress, finished }
enum CompanyUserStatus { case active, pending }
struct ServiceStop: Identifiable, Equatable {
    var id: String
    var operationStatus: ServiceStopOperationStatus = .notFinished
    var techId = "tech"
    var serviceDate: Date
    var startTime: Date? = nil
    var endTime: Date? = nil
}
struct ServiceStopOrder { var serviceStopId: String; var order: Int }
struct ActiveRoute {
    var id: String
    var techId = "tech"
    var techName = "Alex"
    var date: Date
    var serviceStopsIds: [String]
    var order: [ServiceStopOrder]? = nil
    var startTime: Date? = nil
    var endTime: Date? = nil
    var status: ActiveRouteStatus = .didNotStart
}
struct ActiveRouteLog { var id: String }
struct ActiveRouteLocation { var latitude: Double; var longitude: Double }
struct CompanyUser { var userId: String; var userName: String; var status: CompanyUserStatus = .active }
@MainActor protocol ProductionDataServiceProtocol {
    func getActiveRoute(companyId: String, activeRouteId: String) async throws -> ActiveRoute
    func getActiveRoutesForDate(companyId: String, date: Date) async throws -> [ActiveRoute]
    func syncActiveRouteForServiceStops(companyId: String, date: Date, techId: String, techName: String) async throws -> ActiveRoute?
    func getServiceStopsByIds(companyId: String, serviceStopIds: [String]) async throws -> [ServiceStop]
    func getActiveRouteLogs(companyId: String, activeRouteId: String) async throws -> [ActiveRouteLog]
    func getActiveRouteLocations(companyId: String, activeRouteId: String) async throws -> [ActiveRouteLocation]
    func getAllCompanyUsersByStatus(companyId: String, status: String) async throws -> [CompanyUser]
    func moveServiceStops(companyId: String, serviceStops: [ServiceStop], serviceDate: Date, companyUser: CompanyUser) async throws
}
@MainActor final class Service: ProductionDataServiceProtocol {
    var routes: [String: [ActiveRoute]] = [:]
    var stops: [ServiceStop] = []
    var failures = Set<String>()
    var omitted = Set<String>()
    var syncCalls: [(String, String)] = []
    var moves: [[String]] = []
    var slowCompany: String?
    var materialized: ActiveRoute?
    func fail(_ source: String) throws {
        if failures.contains(source) { throw NSError(domain: source, code: 1, userInfo: [NSLocalizedDescriptionKey: source + " denied"]) }
    }
    func getActiveRoute(companyId: String, activeRouteId: String) async throws -> ActiveRoute {
        try fail("route")
        guard let route = routes[companyId]?.first(where: { $0.id == activeRouteId }) else { throw NSError(domain: "missing", code: 1) }
        return route
    }
    func getActiveRoutesForDate(companyId: String, date: Date) async throws -> [ActiveRoute] {
        if companyId == slowCompany { try await Task.sleep(nanoseconds: 30_000_000) }
        try fail("route")
        return routes[companyId] ?? []
    }
    func syncActiveRouteForServiceStops(companyId: String, date: Date, techId: String, techName: String) async throws -> ActiveRoute? {
        syncCalls.append((companyId, techId)); return materialized
    }
    func getServiceStopsByIds(companyId: String, serviceStopIds: [String]) async throws -> [ServiceStop] {
        try fail("stops"); return stops.filter { serviceStopIds.contains($0.id) && !omitted.contains($0.id) }
    }
    func getActiveRouteLogs(companyId: String, activeRouteId: String) async throws -> [ActiveRouteLog] {
        try fail("logs"); return [ActiveRouteLog(id: "log")]
    }
    func getActiveRouteLocations(companyId: String, activeRouteId: String) async throws -> [ActiveRouteLocation] {
        try fail("locations")
        return [ActiveRouteLocation(latitude: 34, longitude: -118), ActiveRouteLocation(latitude: 0, longitude: 0), ActiveRouteLocation(latitude: .nan, longitude: 90)]
    }
    func getAllCompanyUsersByStatus(companyId: String, status: String) async throws -> [CompanyUser] {
        try fail("users")
        return [CompanyUser(userId: "target", userName: "Taylor"), CompanyUser(userId: "inactive", userName: "Inactive", status: .pending), CompanyUser(userId: "", userName: "Missing identity")]
    }
    func moveServiceStops(companyId: String, serviceStops: [ServiceStop], serviceDate: Date, companyUser: CompanyUser) async throws {
        try fail("move")
        let ids = Set(serviceStops.map(\.id)); moves.append(serviceStops.map(\.id))
        for i in (routes[companyId] ?? []).indices { routes[companyId]![i].serviceStopsIds.removeAll { ids.contains($0) } }
        for i in stops.indices where ids.contains(stops[i].id) { stops[i].techId = companyUser.userId; stops[i].serviceDate = serviceDate }
    }
}
'''
production = block(coverage, 'enum RouteCoverageSelection {')
production += block(source, 'struct CompanyRouteDetailTarget:')
production += block(source, 'enum RouteManagerStopSelection {')
production += '@MainActor\n' + block(source, 'final class CompanyRouteDetailViewModel:')
checks = r'''
@main struct Checks {
    @MainActor static func main() async throws {
        var count = 0
        func check(_ condition: @autoclosure () -> Bool, _ message: String) { precondition(condition(), message); count += 1 }
        let day = Calendar.current.startOfDay(for: Date())
        let next = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        let stops = [ServiceStop(id: "first", serviceDate: day), ServiceStop(id: "second", serviceDate: day), ServiceStop(id: "done", operationStatus: .finished, serviceDate: day), ServiceStop(id: "skip", operationStatus: .skipped, serviceDate: day), ServiceStop(id: "begun", serviceDate: day, startTime: day), ServiceStop(id: "moved", techId: "other", serviceDate: day), ServiceStop(id: "rescheduled", serviceDate: next)]
        let route = ActiveRoute(id: "route", date: day, serviceStopsIds: stops.map(\.id), order: [ServiceStopOrder(serviceStopId: "second", order: 1), ServiceStopOrder(serviceStopId: "first", order: 2)])
        let target = CompanyRouteDetailTarget(companyId: "company", route: route)
        check(RouteManagerStopSelection.eligibleStops(in: stops, route: route).map(\.id) == ["first", "second"], "Exclude finished/skipped/started/reassigned/rescheduled visits")
        check(RouteManagerStopSelection.orderedStops(stops, route: route).prefix(2).map(\.id) == ["second", "first"], "Saved route order is preserved")
        var sparseOrder = route
        sparseOrder.order = [ServiceStopOrder(serviceStopId: "second", order: 10), ServiceStopOrder(serviceStopId: "first", order: 30)]
        check(RouteManagerStopSelection.orderedStops(stops, route: sparseOrder).prefix(2).map(\.id) == ["second", "first"], "Sparse saved order stays ahead of newly appended stops")
        let dashboardTarget = CompanyRouteDetailTarget(companyId: "company", technicianId: "tech", technicianName: "Alex", date: day)
        let wrongDate = ActiveRoute(id: "tomorrow", date: next, serviceStopsIds: ["first"])
        let wrongTech = ActiveRoute(id: "foreign", techId: "other", date: day, serviceStopsIds: ["first"])
        let started = ActiveRoute(id: "started", date: day, serviceStopsIds: ["first"], startTime: day, status: .inProgress)
        check(RouteManagerStopSelection.route(for: dashboardTarget, in: [wrongDate, wrongTech, route])?.id == "route", "Dashboard drill-in resolves the selected technician/date")
        check(RouteManagerStopSelection.route(for: dashboardTarget, in: [route, started])?.id == "started", "Use the canonical performed route when legacy duplicates exist")

        let service = Service(); service.routes["company"] = [route]; service.stops = stops
        let model = CompanyRouteDetailViewModel(dataService: service, date: day)
        service.failures = ["logs", "locations"]
        await model.load(target)
        check(model.stops.count == stops.count && model.errors["logs"] != nil && model.errors["locations"] != nil, "A failed GPS/log read must not erase service stops")
        check(model.selectedStops.isEmpty, "Opening Manager does not silently select the whole route")
        model.toggle(stops[0]); check(model.selectedStops.map(\.id) == ["first"], "A technician's individual stop can be selected")
        model.toggle(stops[2]); check(model.selectedStops.count == 1, "Completed stops cannot be added to selection")
        service.failures = []
        await model.load(target)
        check(model.selectedStops.map(\.id) == ["first"], "Reload keeps only the prior explicit selection")
        check(model.locations.count == 1, "Discard invalid GPS coordinates")
        check(model.companyUsers.map(\.userId) == ["target"], "Destination users must have active identities")
        model.selectedTechnicianId = "inactive"
        await model.moveSelectedStops(target)
        check(service.moves.isEmpty && model.selectedStops.count == 1, "Reject inactive or unknown destinations and retain selection")
        model.selectedTechnicianId = "target"
        service.failures = ["move"]
        await model.moveSelectedStops(target)
        check(model.selectedStops.map(\.id) == ["first"] && model.notice == "move denied", "Server move failures remain visible and preserve selection")
        service.failures = []
        await model.moveSelectedStops(target)
        check(service.moves == [["first"]] && model.selectedStops.isEmpty, "Move only explicitly selected stops through the awaited shared command")
        check(!model.stops.contains(where: { $0.id == "first" }) && model.notice?.contains("Taylor") == true, "Reload the source route and report the confirmed destination after success")

        service.omitted = ["second"]
        await model.load(target)
        check(model.errors["stops"] != nil, "Incomplete stop loads show a manager-action error instead of pretending the route is empty")
        service.omitted = []
        service.routes["company"] = [route]; service.stops = stops
        await model.load(dashboardTarget)
        check(service.syncCalls.isEmpty && model.route?.id == "route", "Existing dashboard routes open without materialization writes")
        service.routes["company"] = []
        service.materialized = route
        await model.load(dashboardTarget)
        check(service.syncCalls.count == 1 && service.syncCalls.first?.1 == "tech", "If needed, materialize only the explicitly opened technician's route")

        service.slowCompany = "slow"
        let slow = CompanyRouteDetailTarget(companyId: "slow", technicianId: "tech", technicianName: "Alex", date: day)
        let previousSyncs = service.syncCalls.count
        let staleLoad = Task { await model.load(slow) }
        try await Task.sleep(nanoseconds: 2_000_000)
        service.routes["company"] = [route]
        await model.load(target)
        await staleLoad.value
        check(model.route?.id == "route" && service.syncCalls.count == previousSyncs, "A stale company/date lookup cannot materialize an old route or overwrite the open popup")
        service.failures = ["stops"]
        await model.load(target)
        check(model.stops.isEmpty && model.errors["stops"] != nil && model.logs.count == 1, "Stop-load errors are explicit and independent of logs")
        print("\(count) route popup selection, independent loading, move, and stale-request checks passed")
    }
}
'''
with tempfile.TemporaryDirectory(prefix='dripdrop-company-route-detail-') as directory:
    fixture = Path(directory) / 'checks.swift'
    executable = Path(directory) / 'checks'
    fixture.write_text(stubs + production + checks)
    subprocess.run(['swiftc', '-parse-as-library', '-module-cache-path', '/private/tmp/dripdrop-route-detail-modules', str(fixture), '-o', str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
