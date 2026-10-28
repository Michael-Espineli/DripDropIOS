import SwiftUI

struct CompanyRouteDetailTarget: Identifiable {
    let id = UUID()
    let companyId: String
    let routeId: String?
    let technicianId: String
    let technicianName: String
    let date: Date

    init(companyId: String, route: ActiveRoute) {
        self.companyId = companyId
        routeId = route.id
        technicianId = route.techId
        technicianName = route.techName
        date = route.date
    }

    init(companyId: String, technicianId: String, technicianName: String, date: Date) {
        self.companyId = companyId
        routeId = nil
        self.technicianId = technicianId
        self.technicianName = technicianName
        self.date = date
    }
}

enum RouteManagerStopSelection {
    static func eligibleStops(in stops: [ServiceStop], route: ActiveRoute) -> [ServiceStop] {
        RouteCoverageSelection.eligibleStops(in: stops, route: route).filter { $0.startTime == nil && $0.endTime == nil }
    }

    static func orderedStops(_ stops: [ServiceStop], route: ActiveRoute) -> [ServiceStop] {
        let membership = Dictionary(route.serviceStopsIds.enumerated().map { ($0.element, $0.offset) }, uniquingKeysWith: min)
        let order = Dictionary((route.order ?? []).map { ($0.serviceStopId, $0.order) }, uniquingKeysWith: min)
        return stops.sorted {
            if let left = order[$0.id], let right = order[$1.id], left != right { return left < right }
            if (order[$0.id] != nil) != (order[$1.id] != nil) { return order[$0.id] != nil }
            let left = membership[$0.id] ?? membership.count
            let right = membership[$1.id] ?? membership.count
            return left == right ? $0.id < $1.id : left < right
        }
    }

    static func route(for target: CompanyRouteDetailTarget, in routes: [ActiveRoute]) -> ActiveRoute? {
        routes.filter { $0.techId == target.technicianId && Calendar.current.isDate($0.date, inSameDayAs: target.date) }
            .sorted {
                let leftStarted = $0.startTime != nil || $0.endTime != nil || $0.status != .didNotStart
                let rightStarted = $1.startTime != nil || $1.endTime != nil || $1.status != .didNotStart
                if leftStarted != rightStarted { return leftStarted }
                if $0.serviceStopsIds.count != $1.serviceStopsIds.count { return $0.serviceStopsIds.count > $1.serviceStopsIds.count }
                return $0.id < $1.id
            }.first
    }
}

@MainActor
final class CompanyRouteDetailViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    @Published private(set) var route: ActiveRoute?
    @Published private(set) var stops: [ServiceStop] = []
    @Published private(set) var logs: [ActiveRouteLog] = []
    @Published private(set) var locations: [ActiveRouteLocation] = []
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var errors: [String: String] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var isMoving = false
    @Published var selectedStops: [ServiceStop] = []
    @Published var moveDate: Date
    @Published var selectedTechnicianId = ""
    @Published var notice: String?
    private var generation = UUID()

    init(dataService: any ProductionDataServiceProtocol, date: Date) {
        self.dataService = dataService
        moveDate = date
    }

    func load(_ target: CompanyRouteDetailTarget) async {
        let token = UUID()
        generation = token
        isLoading = true
        errors = [:]
        defer { if generation == token { isLoading = false } }
        do {
            let loadedRoute: ActiveRoute?
            if let routeId = target.routeId {
                loadedRoute = try await dataService.getActiveRoute(companyId: target.companyId, activeRouteId: routeId)
            } else {
                let routes = try await dataService.getActiveRoutesForDate(companyId: target.companyId, date: target.date)
                guard generation == token, !Task.isCancelled else { return }
                if let existing = RouteManagerStopSelection.route(for: target, in: routes) {
                    loadedRoute = existing
                } else {
                    // Materialize only this worker's dated route when explicitly opened.
                    loadedRoute = try await dataService.syncActiveRouteForServiceStops(companyId: target.companyId, date: target.date, techId: target.technicianId, techName: target.technicianName)
                }
            }
            guard generation == token, !Task.isCancelled else { return }
            guard let loadedRoute, loadedRoute.techId == target.technicianId,
                  Calendar.current.isDate(loadedRoute.date, inSameDayAs: target.date) else {
                route = nil
                errors["route"] = "No route is available for this technician on the selected day."
                return
            }
            route = loadedRoute
            stops = []; logs = []; locations = []; companyUsers = []
            // A denied GPS/log read must not discard successfully loaded service stops.
            do {
                let loaded = try await dataService.getServiceStopsByIds(companyId: target.companyId, serviceStopIds: loadedRoute.serviceStopsIds)
                guard generation == token, !Task.isCancelled else { return }
                stops = RouteManagerStopSelection.orderedStops(loaded, route: loadedRoute)
                if !Set(loadedRoute.serviceStopsIds).isSubset(of: Set(stops.map(\.id))) {
                    errors["stops"] = "Some route stops could not be loaded. Refresh before moving or offering work."
                }
                let eligible = Set(RouteManagerStopSelection.eligibleStops(in: stops, route: loadedRoute).map(\.id))
                let previousSelection = Set(selectedStops.map(\.id))
                selectedStops = stops.filter { eligible.contains($0.id) && previousSelection.contains($0.id) }
            } catch { if generation == token { errors["stops"] = error.localizedDescription } }
            guard generation == token, !Task.isCancelled else { return }
            do {
                let loaded = try await dataService.getActiveRouteLogs(companyId: target.companyId, activeRouteId: loadedRoute.id)
                guard generation == token, !Task.isCancelled else { return }
                logs = loaded
            } catch { if generation == token { errors["logs"] = error.localizedDescription } }
            guard generation == token, !Task.isCancelled else { return }
            do {
                let loaded = try await dataService.getActiveRouteLocations(companyId: target.companyId, activeRouteId: loadedRoute.id)
                guard generation == token, !Task.isCancelled else { return }
                locations = loaded.filter { $0.latitude.isFinite && $0.longitude.isFinite && abs($0.latitude) <= 90 && abs($0.longitude) <= 180 && !($0.latitude == 0 && $0.longitude == 0) }
            } catch { if generation == token { errors["locations"] = error.localizedDescription } }
            guard generation == token, !Task.isCancelled else { return }
            do {
                let loaded = try await dataService.getAllCompanyUsersByStatus(companyId: target.companyId, status: "Active")
                guard generation == token, !Task.isCancelled else { return }
                companyUsers = loaded.filter { $0.status == .active && !$0.userId.isEmpty }
                if !companyUsers.contains(where: { $0.userId == selectedTechnicianId }) { selectedTechnicianId = "" }
            } catch { if generation == token { errors["users"] = error.localizedDescription } }
        } catch {
            guard generation == token, !Task.isCancelled else { return }
            route = nil
            errors["route"] = error.localizedDescription
        }
    }

    func toggle(_ stop: ServiceStop) {
        guard !isLoading, !isMoving, let route,
              RouteManagerStopSelection.eligibleStops(in: stops, route: route).contains(where: { $0.id == stop.id }) else { return }
        if selectedStops.contains(where: { $0.id == stop.id }) { selectedStops.removeAll { $0.id == stop.id } }
        else { selectedStops.append(stop) }
    }

    func moveSelectedStops(_ target: CompanyRouteDetailTarget) async {
        guard !isMoving, !isLoading, let route, errors["stops"] == nil else { return }
        let selectedIds = Set(selectedStops.map(\.id))
        let current = RouteManagerStopSelection.eligibleStops(in: stops, route: route).filter { selectedIds.contains($0.id) }
        guard !current.isEmpty, current.count == selectedIds.count else { notice = "Select the unfinished, unstarted stops you want to move."; return }
        guard let technician = companyUsers.first(where: { $0.userId == selectedTechnicianId && $0.status == .active }) else { notice = "Select an active destination technician."; return }
        isMoving = true
        defer { isMoving = false }
        do {
            try await dataService.moveServiceStops(companyId: target.companyId, serviceStops: current, serviceDate: moveDate, companyUser: technician)
            selectedStops = []
            await load(target)
            notice = "Moved \(current.count) stop\(current.count == 1 ? "" : "s") to \(technician.userName)."
        } catch { notice = error.localizedDescription }
    }

    func stop() { generation = UUID(); isLoading = false }
}

// The dashboard and Active Routes page present the exact same route workspace.
struct CompanyRouteDetailPresentation: View {
    let target: CompanyRouteDetailTarget
    let dataService: any ProductionDataServiceProtocol
    let onOpenStop: (ServiceStop) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: CompanyRouteDetailViewModel

    init(target: CompanyRouteDetailTarget, dataService: any ProductionDataServiceProtocol, onOpenStop: @escaping (ServiceStop) -> Void) {
        self.target = target
        self.dataService = dataService
        self.onOpenStop = onOpenStop
        _model = StateObject(wrappedValue: CompanyRouteDetailViewModel(dataService: dataService, date: target.date))
    }

    var body: some View {
        Group {
            if let route = model.route {
                CompanyActiveRouteDetailSheet(
                    companyId: target.companyId, dataService: dataService,
                    route: route, stops: model.stops, logs: model.logs, locations: model.locations,
                    companyUsers: model.companyUsers, errors: model.errors,
                    selectedStops: $model.selectedStops, moveDate: $model.moveDate,
                    selectedTechnicianId: $model.selectedTechnicianId,
                    isMoving: model.isMoving, isLoading: model.isLoading,
                    onToggleStop: model.toggle,
                    onMoveStops: { Task { await model.moveSelectedStops(target) } },
                    onOpenStop: onOpenStop,
                    onReload: { Task { await model.load(target) } }
                )
            } else {
                NavigationStack {
                    Group {
                        if model.isLoading { ProgressView("Loading route…") }
                        else {
                            ContentUnavailableView {
                                Label("Route unavailable", systemImage: "map")
                            } description: {
                                Text(model.errors["route"] ?? "No route was found for this day.")
                            } actions: {
                                Button("Try again") { Task { await model.load(target) } }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.listColor)
                    .navigationTitle(target.technicianName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
                }
            }
        }
        .task(id: target.id) { await model.load(target) }
        .onDisappear { model.stop() }
        .alert("Route management", isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button("OK") { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }
}
