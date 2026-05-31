//
//  CompanyActiveRouteOverviewView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/30/26.
//

import Foundation
import SwiftUI
import MapKit
//MARK: View Model
@MainActor
final class CompanyActiveRouteOverviewViewModel: ObservableObject {

    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var selectedDate: Date = Date()

    @Published private(set) var activeRoutes: [ActiveRoute] = []
    @Published private(set) var serviceStopsByRouteId: [String: [ServiceStop]] = [:]
    @Published private(set) var logsByRouteId: [String: [ActiveRouteLog]] = [:]
    @Published private(set) var locationsByRouteId: [String: [ActiveRouteLocation]] = [:]

    @Published private(set) var companyUsers: [CompanyUser] = []

    @Published var selectedRoute: ActiveRoute?
    @Published var selectedStops: [ServiceStop] = []

    @Published var moveDate: Date = Date()
    @Published var selectedTech: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )

    @Published var isLoading: Bool = false
    @Published var isMoving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    var totalRoutes: Int {
        activeRoutes.count
    }

    var inProgressRoutes: Int {
        activeRoutes.filter {
            $0.status == .inProgress || $0.status == .traveling || $0.status == .onBreak
        }.count
    }

    var notStartedRoutes: Int {
        activeRoutes.filter { $0.status == .didNotStart }.count
    }

    var finishedRoutes: Int {
        activeRoutes.filter { $0.status == .finished }.count
    }

    var routesNeedingReview: [ActiveRoute] {
        activeRoutes.filter { route in
            route.status != .finished && !Calendar.current.isDate(route.date, inSameDayAs: Date())
        }
    }

    func load(companyId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let routes = try await dataService.getActiveRoutesForDate(
                companyId: companyId,
                date: selectedDate
            )

            self.activeRoutes = routes

            async let usersTask: Void = loadCompanyUsers(companyId: companyId)
            async let routeDetailsTask: Void = loadRouteDetails(companyId: companyId, routes: routes)

            _ = try await (usersTask, routeDetailsTask)
        } catch {
            print("[CompanyActiveRouteOverviewViewModel][load] Error")
            print(error)

            alertMessage = "Could not load active routes."
            showAlert = true
        }
    }

    private func loadCompanyUsers(companyId: String) async throws {
        // If you already have a better async getter, use that here.
        // This intentionally avoids listener behavior for the manager overview.
        let users = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        self.companyUsers = users.filter { $0.status == .active }
    }

    private func loadRouteDetails(
        companyId: String,
        routes: [ActiveRoute]
    ) async throws {
        var stopsDict: [String: [ServiceStop]] = [:]
        var logsDict: [String: [ActiveRouteLog]] = [:]
        var locationsDict: [String: [ActiveRouteLocation]] = [:]

        for route in routes {
            async let stops = dataService.getServiceStopsByIds(
                companyId: companyId,
                serviceStopIds: route.serviceStopsIds
            )

            async let logs = dataService.getActiveRouteLogs(
                companyId: companyId,
                activeRouteId: route.id
            )

            async let locations = dataService.getActiveRouteLocations(
                companyId: companyId,
                activeRouteId: route.id
            )

            let loadedStops = try await stops
            let loadedLogs = try await logs
            let loadedLocations = try await locations

            stopsDict[route.id] = applyOrder(
                stops: loadedStops,
                order: route.order
            )

            logsDict[route.id] = loadedLogs
            locationsDict[route.id] = loadedLocations
        }

        self.serviceStopsByRouteId = stopsDict
        self.logsByRouteId = logsDict
        self.locationsByRouteId = locationsDict
    }

    func stops(for route: ActiveRoute) -> [ServiceStop] {
        serviceStopsByRouteId[route.id] ?? []
    }

    func logs(for route: ActiveRoute) -> [ActiveRouteLog] {
        logsByRouteId[route.id] ?? []
    }

    func locations(for route: ActiveRoute) -> [ActiveRouteLocation] {
        locationsByRouteId[route.id] ?? []
    }

    func latestLocation(for route: ActiveRoute) -> ActiveRouteLocation? {
        locations(for: route).sorted { $0.time > $1.time }.first
    }

    func toggleSelectedStop(_ stop: ServiceStop) {
        if selectedStops.contains(where: { $0.id == stop.id }) {
            selectedStops.removeAll { $0.id == stop.id }
        } else {
            selectedStops.append(stop)
        }
    }

    func clearMoveState() {
        selectedStops = []
        moveDate = selectedDate
        selectedTech = CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .notAssigned
        )
    }

    func moveSelectedStops(
        companyId: String,
        route: ActiveRoute
    ) async {
        guard !selectedStops.isEmpty else {
            alertMessage = "Select at least one stop."
            showAlert = true
            return
        }

        guard !selectedTech.userId.isEmpty else {
            alertMessage = "Select a technician."
            showAlert = true
            return
        }

        isMoving = true
        defer { isMoving = false }

        do {
            var updatedOrder = route.order ?? []
            var triedToMoveFinished = false

            for stop in selectedStops {
                if stop.operationStatus == .notFinished {
                    updatedOrder.removeAll { $0.serviceStopId == stop.id }

                    try await dataService.updateServiceStopServiceDate(
                        companyId: companyId,
                        serviceStop: stop,
                        serviceDate: moveDate,
                        companyUser: selectedTech
                    )
                } else {
                    triedToMoveFinished = true
                }
            }

            try await dataService.updateActiveRouteOrderList(
                companyId: companyId,
                activeRouteId: route.id,
                serviceStopOrderList: updatedOrder
            )

            clearMoveState()

            await load(companyId: companyId)

            alertMessage = triedToMoveFinished
                ? "Some stops were not moved because they are already finished."
                : "Stops moved successfully."

            showAlert = true
        } catch {
            print("[CompanyActiveRouteOverviewViewModel][moveSelectedStops] Error")
            print(error)

            alertMessage = "Could not move selected stops."
            showAlert = true
        }
    }

    private func applyOrder(
        stops: [ServiceStop],
        order: [ServiceStopOrder]?
    ) -> [ServiceStop] {
        guard let order else {
            return stops.sorted { $0.serviceDate < $1.serviceDate }
        }

        let lookup = Dictionary(
            uniqueKeysWithValues: order.map {
                ($0.serviceStopId, $0.order)
            }
        )

        return stops.sorted { lhs, rhs in
            let lhsOrder = lookup[lhs.id]
            let rhsOrder = lookup[rhs.id]

            switch (lhsOrder, rhsOrder) {
            case let (l?, r?):
                return l < r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.serviceDate < rhs.serviceDate
            }
        }
    }
}
//MARK: CompanyActiveRouteOverviewView
struct CompanyActiveRouteOverviewView: View {

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var navigationManager: NavigationStateManager

    @StateObject private var VM: CompanyActiveRouteOverviewViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(
            wrappedValue: CompanyActiveRouteOverviewViewModel(dataService: dataService)
        )
    }

    @State private var showRouteDetail: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                dateHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        summaryGrid

                        if VM.activeRoutes.isEmpty && !VM.isLoading {
                            emptyState
                        } else {
                            routeList
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }

            if VM.isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Active Routes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .onChange(of: VM.selectedDate) { _ in
            Task {
                await load()
            }
        }
        .refreshable {
            await load()
        }
        .sheet(isPresented: $showRouteDetail) {
            if let route = VM.selectedRoute {
                CompanyActiveRouteDetailSheet(
                    route: route,
                    stops: VM.stops(for: route),
                    logs: VM.logs(for: route),
                    locations: VM.locations(for: route),
                    companyUsers: VM.companyUsers,
                    selectedStops: $VM.selectedStops,
                    moveDate: $VM.moveDate,
                    selectedTech: $VM.selectedTech,
                    isMoving: VM.isMoving,
                    onToggleStop: { stop in
                        VM.toggleSelectedStop(stop)
                    },
                    onMoveStops: {
                        Task {
                            guard let companyId = masterDataManager.currentCompany?.id else { return }

                            await VM.moveSelectedStops(
                                companyId: companyId,
                                route: route
                            )
                        }
                    },
                    onOpenStop: { stop in
                        showRouteDetail = false

                        navigationManager.push(
                            to: Route.dailyDisplayStop(
                                dataService: dataService,
                                serviceStop: stop
                            )
                        )
                    }
                )
                .presentationDetents([.large])
            }
        }
        .alert("Active Routes", isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(VM.alertMessage)
        }
    }

    private func load() async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }
        await VM.load(companyId: companyId)
    }
}
//MARK: CompanyActiveRouteOverviewView Extension
extension CompanyActiveRouteOverviewView {
        //MARK: dateHeader
    private var dateHeader: some View {
        HStack(spacing: 10) {
            Button {
                VM.selectedDate = Calendar.current.date(
                    byAdding: .day,
                    value: -1,
                    to: VM.selectedDate
                ) ?? VM.selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(spacing: 3) {
                Text(weekDay(date: VM.selectedDate))
                    .font(.headline.weight(.semibold))

                Text(fullDate(date: VM.selectedDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Button {
                VM.selectedDate = Calendar.current.date(
                    byAdding: .day,
                    value: 1,
                    to: VM.selectedDate
                ) ?? VM.selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            DatePicker("", selection: $VM.selectedDate, displayedComponents: .date)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

        //MARK: summaryGrid
    private var summaryGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 10
        ) {
            summaryTile(
                title: "Routes",
                value: "\(VM.totalRoutes)",
                systemImage: "map",
                tint: .blue
            )

            summaryTile(
                title: "In Progress",
                value: "\(VM.inProgressRoutes)",
                systemImage: "figure.walk",
                tint: .orange
            )

            summaryTile(
                title: "Not Started",
                value: "\(VM.notStartedRoutes)",
                systemImage: "clock",
                tint: .secondary
            )

            summaryTile(
                title: "Finished",
                value: "\(VM.finishedRoutes)",
                systemImage: "checkmark.circle",
                tint: .green
            )
        }
    }
    
        //MARK: summaryTile
    private func summaryTile(
        title: String,
        value: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: Circle())

                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    
        //MARK: routeList
    private var routeList: some View {
        VStack(spacing: 12) {
            ForEach(VM.activeRoutes) { route in
                Button {
                    VM.selectedRoute = route
                    VM.clearMoveState()
                    VM.moveDate = VM.selectedDate
                    showRouteDetail = true
                } label: {
                    activeRouteCard(route)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
        //MARK: loadingOverlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.10)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading active routes...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func activeRouteCard(_ route: ActiveRoute) -> some View {
        let stops = VM.stops(for: route)
        let latestLocation = VM.latestLocation(for: route)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                routeProgressRing(route)

                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name.isEmpty ? route.techName : route.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(route.techName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    routeStatusBadge(route.status)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 8) {
                metricPill(
                    title: "Stops",
                    value: "\(route.finishedStops)/\(route.totalStops)",
                    systemImage: "checklist"
                )

                metricPill(
                    title: "Logs",
                    value: "\(VM.logs(for: route).count)",
                    systemImage: "clock.badge"
                )

                metricPill(
                    title: "Locations",
                    value: "\(VM.locations(for: route).count)",
                    systemImage: "location"
                )
            }

            if let startTime = route.startTime {
                Label(timeRangeText(start: startTime, end: route.endTime), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let startMilage = route.startMilage {
                Label(mileageRangeText(start: startMilage, end: route.endMilage), systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let latestLocation {
                Label("Last location: \(fullDateAndTime(date: latestLocation.time))", systemImage: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if stops.count != route.serviceStopsIds.count {
                Label("Route stop count mismatch. Route has \(route.serviceStopsIds.count) IDs, loaded \(stops.count) stops.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .activeRouteCard()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No Active Routes")
                .font(.headline.weight(.semibold))

            Text("No active routes were found for this date.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .activeRouteCard()
    }
}

//MARK: CompanyActiveRouteDetailSheet

struct CompanyActiveRouteDetailSheet: View {

    let route: ActiveRoute
    let stops: [ServiceStop]
    let logs: [ActiveRouteLog]
    let locations: [ActiveRouteLocation]
    let companyUsers: [CompanyUser]

    @Binding var selectedStops: [ServiceStop]
    @Binding var moveDate: Date
    @Binding var selectedTech: CompanyUser

    let isMoving: Bool

    let onToggleStop: (ServiceStop) -> Void
    let onMoveStops: () -> Void
    let onOpenStop: (ServiceStop) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: ActiveRouteDetailTab = .stops
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var showExpandedMap: Bool = false
    @State private var showStopOverlay: Bool = true
    @State private var showTechTrailOverlay: Bool = true
    @State private var showTimeAreaOverlay: Bool = true
    @State private var plannedRoadRouteSegments: [[CLLocationCoordinate2D]] = []
    @State private var isLoadingRoadRoute: Bool = false
    @State private var roadRouteError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    tabBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            summaryCard

                            switch selectedTab {
                            case .stops:
                                stopsSection

                            case .logs:
                                logsSection

                            case .locations:
                                locationsSection

                            case .manager:
                                managerSection
                            }

                            Color.clear.frame(height: 24)
                        }
                        .padding(14)
                    }
                }
            }
            .navigationTitle(route.techName)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showExpandedMap) {
                expandedRouteMapSheet
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum ActiveRouteDetailTab: String, CaseIterable, Identifiable {
    case stops = "Stops"
    case logs = "Logs"
    case locations = "Locations"
    case manager = "Manager"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .stops:
            return "checklist"
        case .logs:
            return "clock.badge"
        case .locations:
            return "location"
        case .manager:
            return "slider.horizontal.3"
        }
    }
}
extension CompanyActiveRouteDetailSheet {

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActiveRouteDetailTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedTab == tab ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                selectedTab == tab ? Color.accentColor : Color.primary.opacity(0.07),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                routeProgressRing(route)

                VStack(alignment: .leading, spacing: 5) {
                    Text(route.name.isEmpty ? "Active Route" : route.name)
                        .font(.headline.weight(.semibold))

                    Text(route.techName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    routeStatusBadge(route.status)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                metricPill(title: "Stops", value: "\(route.finishedStops)/\(route.totalStops)", systemImage: "checklist")
                metricPill(title: "Logs", value: "\(logs.count)", systemImage: "clock")
                metricPill(title: "GPS", value: "\(locations.count)", systemImage: "location")
            }

            if let start = route.startTime {
                Label(timeRangeText(start: start, end: route.endTime), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let startMileage = route.startMilage {
                Label(mileageRangeText(start: startMileage, end: route.endMilage), systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .activeRouteCard()
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Service Stops", "\(stops.count) stops in route order.", "list.bullet.rectangle")

            if stops.isEmpty {
                emptyRow("No stops loaded", "This route has no loaded service stops.", "checklist")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(stops.enumerated()), id: \.element.id) { index, stop in
                        stopRow(stop, index: index)
                    }
                }
            }
        }
        .activeRouteCard()
    }

    private var logsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Route Logs", "\(logs.count) work log records.", "clock.badge")

            if logs.isEmpty {
                emptyRow("No logs", "Logs will appear here when the route starts, pauses, resumes, or ends.", "clock")
            } else {
                VStack(spacing: 10) {
                    ForEach(logs) { log in
                        logRow(log)
                    }
                }
            }
        }
        .activeRouteCard()
    }

    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                "Route Map",
                routeMapSubtitle,
                "map"
            )

            if mapPoints.isEmpty {
                emptyRow(
                    "No map locations",
                    "Service stops need address coordinates, and route breadcrumbs will appear while the route is active.",
                    "location.slash"
                )
            } else {
                routeLocationMap

                mapLegend

                areaEstimateSection

                latestLocationCard

                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(
                        "Location Timeline",
                        "Showing the most recent 20 breadcrumbs.",
                        "list.bullet"
                    )

                    ForEach(locations.suffix(20).reversed()) { location in
                        locationRow(location)
                    }
                }
            }
        }
        .activeRouteCard()
        .onAppear {
            setInitialMapCamera()
        }
        .task(id: roadRouteTaskKey) {
            await loadPlannedRoadRoute()
        }
    }

    private var routeLocationMap: some View {
        VStack(spacing: 10) {
            routeMapToolbar

            routeMapCanvas(height: 340)
        }
    }

    private var routeMapToolbar: some View {
        HStack(spacing: 8) {
            if isLoadingRoadRoute {
                ProgressView()
                    .scaleEffect(0.82)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())
            } else {
                Image(systemName: roadRouteError == nil ? "point.topleft.down.curvedto.point.bottomright.up" : "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(roadRouteError == nil ? .blue : .orange)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(roadRouteError == nil ? "Planned route follows roads" : "Using direct stop path")
                    .font(.caption.weight(.semibold))

                Text(roadRouteError ?? "Based on ordered service stop addresses.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showExpandedMap = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var mapOverlayControls: some View {
        HStack(spacing: 8) {
            overlayToggle(
                "Stops",
                color: .blue,
                systemImage: "mappin.circle.fill",
                isOn: $showStopOverlay
            )

            overlayToggle(
                "Tech trail",
                color: .orange,
                systemImage: "location.fill",
                isOn: $showTechTrailOverlay
            )

            overlayToggle(
                "Time area",
                color: .purple,
                systemImage: "timer",
                isOn: $showTimeAreaOverlay
            )
        }
    }

    private var expandedRouteMapSheet: some View {
        NavigationStack {
            VStack(spacing: 10) {
                mapOverlayControls
                    .padding(.horizontal, 14)
                    .padding(.top, 10)

                routeMapCanvas(height: nil)
                    .ignoresSafeArea(edges: .bottom)
            }
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showExpandedMap = false
                    }
                }
            }
        }
    }

    private func routeMapCanvas(height: CGFloat?) -> some View {
        Map(position: $mapCameraPosition) {
            if showStopOverlay {
                if plannedRoadRouteSegments.isEmpty && serviceStopMapPoints.count > 1 {
                    MapPolyline(coordinates: serviceStopMapPoints.map { $0.coordinate })
                        .stroke(Color.blue.opacity(0.55), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [6, 5]))
                } else {
                    ForEach(Array(plannedRoadRouteSegments.enumerated()), id: \.offset) { _, segment in
                        MapPolyline(coordinates: segment)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                }
            }

            if showTechTrailOverlay && technicianTrailPoints.count > 1 {
                MapPolyline(coordinates: technicianTrailPoints.map { $0.coordinate })
                    .stroke(Color.orange, lineWidth: 4)
            }

            ForEach(visibleMapPoints) { point in
                Annotation(point.title, coordinate: point.coordinate) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(point.tint)
                                .frame(width: point.pinSize, height: point.pinSize)
                                .shadow(color: Color.black.opacity(0.20), radius: 5, x: 0, y: 3)

                            if let badgeText = point.badgeText {
                                Text(badgeText)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .minimumScaleFactor(0.62)
                            } else if let number = point.number {
                                Text("\(number)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .minimumScaleFactor(0.7)
                            } else {
                                Image(systemName: point.systemImage)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }

                        Text(point.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(point.tint.opacity(0.85), in: Capsule())
                    }
                }
            }
        }
        .frame(height: height)
        .frame(maxHeight: height == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    private var mapLegend: some View {
        mapOverlayControls
    }

    private var areaEstimateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !showTimeAreaOverlay {
                emptyRow(
                    "Time areas hidden",
                    "Turn on the Time area overlay to see where technicians spend time near stops.",
                    "timer"
                )
            } else if dwellAreaEstimates.isEmpty {
                emptyRow(
                    "No time areas yet",
                    "Once multiple technician breadcrumbs land near each other, estimated time in that area will appear here.",
                    "timer"
                )
            } else {
                sectionHeader(
                    "Time In Area",
                    "Areas are numbered in the order the technician moved through the day.",
                    "timer"
                )

                ForEach(dwellAreaEstimates.prefix(5)) { estimate in
                    areaEstimateRow(estimate)
                }
            }
        }
    }

    private var latestLocationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let latest = sortedLocations.last {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "location.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 34)
                        .background(Color.accentColor.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest Location")
                            .font(.subheadline.weight(.semibold))

                        Text(latest.userName)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(fullDateAndTime(date: latest.time))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("\(latest.latitude), \(latest.longitude)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button {
                        openInMaps(latest)
                    } label: {
                        Image(systemName: "map")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private var sortedLocations: [ActiveRouteLocation] {
        locations.sorted { $0.time < $1.time }
    }

    private var mapPoints: [ActiveRouteMapPoint] {
        serviceStopMapPoints + areaMapPoints + technicianTrailPoints
    }

    private var visibleMapPoints: [ActiveRouteMapPoint] {
        var points: [ActiveRouteMapPoint] = []

        if showStopOverlay {
            points.append(contentsOf: serviceStopMapPoints)
        }

        if showTimeAreaOverlay {
            points.append(contentsOf: areaMapPoints)
        }

        if showTechTrailOverlay {
            points.append(contentsOf: technicianCheckpointMapPoints)
            points.append(contentsOf: latestLocationMapPoints)
        }

        return points
    }

    private var serviceStopMapPoints: [ActiveRouteMapPoint] {
        stops.enumerated().compactMap { index, stop in
            guard isValidCoordinate(stop.address.coordinates) else { return nil }

            return ActiveRouteMapPoint(
                id: "stop-\(stop.id)",
                coordinate: stop.address.coordinates,
                title: "\(index + 1)",
                subtitle: stop.customerName,
                systemImage: "mappin.circle.fill",
                tint: statusTint(stop.operationStatus),
                number: index + 1,
                badgeText: nil,
                pinSize: 32
            )
        }
    }

    private var technicianTrailPoints: [ActiveRouteMapPoint] {
        sortedLocations.compactMap { location in
            let coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )

            guard isValidCoordinate(coordinate) else { return nil }

            return ActiveRouteMapPoint(
                id: "trail-\(location.id)",
                coordinate: coordinate,
                title: "",
                subtitle: fullDateAndTime(date: location.time),
                systemImage: "location.fill",
                tint: .orange,
                number: nil,
                badgeText: nil,
                pinSize: 14
            )
        }
    }

    private var areaMapPoints: [ActiveRouteMapPoint] {
        chronologicalDwellAreaEstimates.enumerated().map { index, estimate in
            ActiveRouteMapPoint(
                id: "area-\(estimate.id)",
                coordinate: estimate.coordinate,
                title: estimate.durationText,
                subtitle: estimate.subtitle,
                systemImage: "timer",
                tint: .purple,
                number: nil,
                badgeText: "\(index + 1)",
                pinSize: 30
            )
        }
    }

    private var technicianCheckpointMapPoints: [ActiveRouteMapPoint] {
        let trailPoints = Array(technicianTrailPoints.dropLast())
        let indexes = checkpointIndexes(total: trailPoints.count, limit: 8)

        return indexes.map { index in
            let point = trailPoints[index]

            return ActiveRouteMapPoint(
                id: "checkpoint-\(point.id)",
                coordinate: point.coordinate,
                title: "GPS \(index + 1)",
                subtitle: point.subtitle,
                systemImage: "location.fill",
                tint: .orange,
                number: nil,
                badgeText: "\(index + 1)",
                pinSize: 24
            )
        }
    }

    private var latestLocationMapPoints: [ActiveRouteMapPoint] {
        guard let latest = sortedLocations.last else { return [] }

        let coordinate = CLLocationCoordinate2D(
            latitude: latest.latitude,
            longitude: latest.longitude
        )

        guard isValidCoordinate(coordinate) else { return [] }

        return [
            ActiveRouteMapPoint(
                id: "latest-\(latest.id)",
                coordinate: coordinate,
                title: "Now",
                subtitle: fullDateAndTime(date: latest.time),
                systemImage: "location.fill",
                tint: .orange,
                number: nil,
                badgeText: nil,
                pinSize: 34
            )
        ]
    }

    private var chronologicalDwellAreaEstimates: [ActiveRouteAreaEstimate] {
        buildAreaEstimates(from: sortedLocations)
            .filter { $0.locationCount > 1 && $0.durationMinutes > 0 }
    }

    private var dwellAreaEstimates: [ActiveRouteAreaEstimate] {
        chronologicalDwellAreaEstimates
            .sorted { $0.startTime > $1.startTime }
    }

    private var routeMapSubtitle: String {
        let stopCount = serviceStopMapPoints.count
        let breadcrumbCount = technicianTrailPoints.count
        let areaCount = dwellAreaEstimates.count

        return "\(stopCount) stop pin\(stopCount == 1 ? "" : "s"), \(breadcrumbCount) breadcrumb\(breadcrumbCount == 1 ? "" : "s"), \(areaCount) time area\(areaCount == 1 ? "" : "s")."
    }

    private var roadRouteTaskKey: String {
        serviceStopMapPoints
            .map { "\($0.coordinate.latitude),\($0.coordinate.longitude)" }
            .joined(separator: "|")
    }

    private func setInitialMapCamera() {
        guard !mapPoints.isEmpty else {
            mapCameraPosition = .automatic
            return
        }

        let points = mapPoints.map { MKMapPoint($0.coordinate) }
        let mapRect = points.reduce(MKMapRect.null) { partialResult, point in
            partialResult.union(
                MKMapRect(
                    x: point.x,
                    y: point.y,
                    width: 1,
                    height: 1
                )
            )
        }

        mapCameraPosition = .region(
            MKCoordinateRegion(
                mapRect.expanded(by: 0.22)
            )
        )
    }

    private func openInMaps(_ location: ActiveRouteLocation) {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )

        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(location.userName) Route Location"

        mapItem.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }

    @MainActor
    private func loadPlannedRoadRoute() async {
        let coordinates = serviceStopMapPoints.map { $0.coordinate }

        guard coordinates.count > 1 else {
            plannedRoadRouteSegments = []
            isLoadingRoadRoute = false
            roadRouteError = nil
            return
        }

        isLoadingRoadRoute = true
        roadRouteError = nil

        var segments: [[CLLocationCoordinate2D]] = []

        for pair in zip(coordinates, coordinates.dropFirst()) {
            do {
                let segment = try await roadRouteSegment(from: pair.0, to: pair.1)

                if !segment.isEmpty {
                    segments.append(segment)
                }
            } catch {
                roadRouteError = "Directions unavailable for one or more route legs."
                plannedRoadRouteSegments = []
                isLoadingRoadRoute = false
                return
            }
        }

        plannedRoadRouteSegments = segments
        isLoadingRoadRoute = false
    }

    private func roadRouteSegment(
        from sourceCoordinate: CLLocationCoordinate2D,
        to destinationCoordinate: CLLocationCoordinate2D
    ) async throws -> [CLLocationCoordinate2D] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        request.transportType = .automobile

        let response = try await MKDirections(request: request).calculate()

        return response.routes.first?.polyline.coordinates ?? []
    }

    private func buildAreaEstimates(from locations: [ActiveRouteLocation]) -> [ActiveRouteAreaEstimate] {
        let validLocations = locations.filter {
            isValidCoordinate(
                CLLocationCoordinate2D(
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            )
        }

        guard !validLocations.isEmpty else { return [] }

        var groups: [[ActiveRouteLocation]] = []
        var currentGroup: [ActiveRouteLocation] = []

        for location in validLocations {
            guard let first = currentGroup.first else {
                currentGroup = [location]
                continue
            }

            if distanceMeters(from: first, to: location) <= 140 {
                currentGroup.append(location)
            } else {
                groups.append(currentGroup)
                currentGroup = [location]
            }
        }

        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups.compactMap { group in
            guard let first = group.first,
                  let last = group.last else {
                return nil
            }

            let coordinate = centerCoordinate(for: group)
            let nearestStop = nearestServiceStop(to: coordinate)

            return ActiveRouteAreaEstimate(
                id: group.map { $0.id }.joined(separator: "-"),
                coordinate: coordinate,
                startTime: first.time,
                endTime: last.time,
                locationCount: group.count,
                nearestStopName: nearestStop?.customerName,
                nearestStopAddress: nearestStop?.address.streetAddress
            )
        }
    }

    private func centerCoordinate(for locations: [ActiveRouteLocation]) -> CLLocationCoordinate2D {
        let latitude = locations.map { $0.latitude }.reduce(0, +) / Double(max(locations.count, 1))
        let longitude = locations.map { $0.longitude }.reduce(0, +) / Double(max(locations.count, 1))

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func distanceMeters(from lhs: ActiveRouteLocation, to rhs: ActiveRouteLocation) -> CLLocationDistance {
        let lhsLocation = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
        let rhsLocation = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)

        return lhsLocation.distance(from: rhsLocation)
    }

    private func nearestServiceStop(to coordinate: CLLocationCoordinate2D) -> ServiceStop? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return stops
            .filter { isValidCoordinate($0.address.coordinates) }
            .min { lhs, rhs in
                let lhsDistance = location.distance(
                    from: CLLocation(
                        latitude: lhs.address.latitude,
                        longitude: lhs.address.longitude
                    )
                )
                let rhsDistance = location.distance(
                    from: CLLocation(
                        latitude: rhs.address.latitude,
                        longitude: rhs.address.longitude
                    )
                )

                return lhsDistance < rhsDistance
            }
    }

    private func checkpointIndexes(total: Int, limit: Int) -> [Int] {
        guard total > 0 else { return [] }
        guard total > limit else { return Array(0..<total) }
        guard limit > 1 else { return [0] }

        let step = Double(total - 1) / Double(limit - 1)
        let indexes = (0..<limit).map { Int((Double($0) * step).rounded()) }

        return Array(Set(indexes)).sorted()
    }

    //MARK: Manager Section
    private var managerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Manager Actions", "Move unfinished stops to another day or technician.", "slider.horizontal.3")

            VStack(spacing: 10) {
                DatePicker("Move Date", selection: $moveDate, displayedComponents: .date)

                HStack {
                    Text("Technician")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Picker("Technician", selection: $selectedTech) {
                        Text("Select").tag(CompanyUser(
                            id: "",
                            userId: "",
                            userName: "",
                            roleId: "",
                            roleName: "",
                            dateCreated: Date(),
                            status: .active,
                            workerType: .notAssigned
                        ))

                        ForEach(companyUsers) { user in
                            Text(user.userName).tag(user)
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("\(selectedStops.count) selected stop\(selectedStops.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    onMoveStops()
                } label: {
                    if isMoving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    } else {
                        Label("Move Selected Stops", systemImage: "arrowshape.turn.up.right")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.plain)
                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(selectedStops.isEmpty || selectedTech.userId.isEmpty || isMoving)
                .opacity(selectedStops.isEmpty || selectedTech.userId.isEmpty ? 0.55 : 1)
            }
        }
        .activeRouteCard()
    }

    private func stopRow(_ stop: ServiceStop, index: Int) -> some View {
        let isSelected = selectedStops.contains(where: { $0.id == stop.id })

        return HStack(spacing: 12) {
            Button {
                onToggleStop(stop)
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "\(index + 1).circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.customerName)
                    .font(.subheadline.weight(.semibold))

                Text(stop.address.streetAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(stop.type)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                onOpenStop(stop)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(statusBackground(stop.operationStatus), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func logRow(_ log: ActiveRouteLog) -> some View {
        HStack(spacing: 12) {
            Image(systemName: logIcon(log.type))
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(log.type.rawValue)
                    .font(.subheadline.weight(.semibold))

                Text(timeRangeText(start: log.startTime, end: log.endTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if log.current {
                    Text("Current")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func locationRow(_ location: ActiveRouteLocation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label(location.userName, systemImage: "location.fill")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(fullDateAndTime(date: location.time))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("\(location.latitude), \(location.longitude)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func legendPill(
        _ title: String,
        color: Color,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.11), in: Capsule())
    }

    private func overlayToggle(
        _ title: String,
        color: Color,
        systemImage: String,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Label(title, systemImage: isOn.wrappedValue ? systemImage : "eye.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isOn.wrappedValue ? color : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    isOn.wrappedValue ? color.opacity(0.12) : Color.primary.opacity(0.07),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private func areaEstimateRow(_ estimate: ActiveRouteAreaEstimate) -> some View {
        let areaNumber = areaOrderNumber(for: estimate)

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "timer")
                .font(.body.weight(.semibold))
                .foregroundStyle(.purple)
                .frame(width: 34, height: 34)
                .background(Color.purple.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Area \(areaNumber) - \(estimate.durationText)")
                    .font(.subheadline.weight(.semibold))

                Text(estimate.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(time(date: estimate.startTime)) - \(time(date: estimate.endTime)) - \(estimate.locationCount) breadcrumbs")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func areaOrderNumber(for estimate: ActiveRouteAreaEstimate) -> Int {
        guard let index = chronologicalDwellAreaEstimates.firstIndex(where: { $0.id == estimate.id }) else {
            return 0
        }

        return index + 1
    }
}

private func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
    coordinate.latitude.isFinite &&
    coordinate.longitude.isFinite &&
    abs(coordinate.latitude) <= 90 &&
    abs(coordinate.longitude) <= 180 &&
    !(coordinate.latitude == 0 && coordinate.longitude == 0)
}

private func routeProgressRing(_ route: ActiveRoute) -> some View {
    ZStack {
        Circle()
            .stroke(Color.primary.opacity(0.12), lineWidth: 7)
            .frame(width: 66, height: 66)

        Circle()
            .trim(
                from: 0,
                to: Double(route.finishedStops) / Double(max(route.totalStops, 1))
            )
            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: 66, height: 66)

        VStack(spacing: 0) {
            Text("\(route.finishedStops)")
                .font(.headline.weight(.bold))

            Text("of \(route.totalStops)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private func routeStatusBadge(_ status: ActiveRouteStatus) -> some View {
    Text(status.rawValue)
        .font(.caption2.weight(.bold))
        .foregroundStyle(statusTint(status))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(statusTint(status).opacity(0.13), in: Capsule())
}

private func statusTint(_ status: ActiveRouteStatus) -> Color {
    switch status {
    case .finished:
        return .green
    case .inProgress, .traveling:
        return .blue
    case .onBreak:
        return .orange
    case .didNotStart:
        return .secondary
    }
}

private func statusBackground(_ status: ServiceStopOperationStatus) -> Color {
    switch status {
    case .finished:
        return Color.green.opacity(0.10)
    case .skipped:
        return Color.orange.opacity(0.10)
    case .notFinished:
        return Color.primary.opacity(0.045)
    }
}

private func statusTint(_ status: ServiceStopOperationStatus) -> Color {
    switch status {
    case .finished:
        return .green
    case .skipped:
        return .orange
    case .notFinished:
        return .blue
    }
}

private func metricPill(
    title: String,
    value: String,
    systemImage: String
) -> some View {
    HStack(spacing: 6) {
        Image(systemName: systemImage)
        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.bold))
        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(10)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
}

private func sectionHeader(
    _ title: String,
    _ subtitle: String,
    _ systemImage: String
) -> some View {
    HStack(alignment: .top, spacing: 12) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 34, height: 34)
            .background(.thinMaterial, in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline.weight(.semibold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()
    }
}

private func emptyRow(
    _ title: String,
    _ message: String,
    _ systemImage: String
) -> some View {
    HStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: 34, height: 34)
            .background(.thinMaterial, in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Spacer()
    }
    .padding(12)
    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

private func logIcon(_ type: WorkLogType) -> String {
    switch type {
    case .working:
        return "figure.walk"
    case .onBreak:
        return "cup.and.saucer"
    case .onLunch:
        return "fork.knife"
    }
}

private func mileageRangeText(start: Double, end: Double?) -> String {
    guard let end else {
        return "\(start)"
    }

    return "\(start) → \(end)"
}

private func timeRangeText(start: Date, end: Date?) -> String {
    guard let end else {
        return time(date: start)
    }

    return "\(time(date: start)) → \(time(date: end))"
}

private extension View {
    func activeRouteCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private extension MKMapRect {
    func expanded(by percent: Double) -> MKMapRect {
        guard !isNull else { return self }

        let extraWidth = max(width * percent, 900)
        let extraHeight = max(height * percent, 900)

        return insetBy(dx: -extraWidth, dy: -extraHeight)
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var routeCoordinates = Array(
            repeating: CLLocationCoordinate2D(),
            count: pointCount
        )

        getCoordinates(
            &routeCoordinates,
            range: NSRange(location: 0, length: pointCount)
        )

        return routeCoordinates
    }
}

struct ActiveRouteMapPoint: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let number: Int?
    let badgeText: String?
    let pinSize: CGFloat
}

struct ActiveRouteAreaEstimate: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let startTime: Date
    let endTime: Date
    let locationCount: Int
    let nearestStopName: String?
    let nearestStopAddress: String?

    var durationMinutes: Int {
        max(Int(endTime.timeIntervalSince(startTime) / 60), 0)
    }

    var durationText: String {
        "\(durationMinutes) min"
    }

    var subtitle: String {
        if let nearestStopName, !nearestStopName.isEmpty {
            return "Near \(nearestStopName)"
        }

        if let nearestStopAddress, !nearestStopAddress.isEmpty {
            return "Near \(nearestStopAddress)"
        }

        return "Technician stayed in this area"
    }
}
