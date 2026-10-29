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
    @Published private(set) var companyUsers: [CompanyUser] = []
    private var loadGeneration = UUID()

    @Published var isLoading: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    var totalRoutes: Int {
        activeRoutes.count
    }

    var startedRoutes: Int {
        activeRoutes.filter {
            $0.status != .didNotStart && $0.status != .finished
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
        let token = UUID()
        loadGeneration = token
        let date = selectedDate
        isLoading = true
        activeRoutes = []
        defer { if loadGeneration == token { isLoading = false } }
        do {
            do {
                let users = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                guard loadGeneration == token, !Task.isCancelled else { return }
                companyUsers = users.filter { $0.status == .active }
            } catch {
                guard loadGeneration == token, !Task.isCancelled else { return }
                companyUsers = []
            }
            await syncScheduledRoutes(companyId: companyId, date: date, generation: token)
            let routes = try await dataService.getActiveRoutesForDate(companyId: companyId, date: date)
            guard loadGeneration == token, !Task.isCancelled else { return }
            activeRoutes = routes
        } catch {
            guard loadGeneration == token, !Task.isCancelled else { return }
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func syncScheduledRoutes(companyId: String, date: Date, generation: UUID) async {
        for user in companyUsers {
            guard loadGeneration == generation, !Task.isCancelled else { return }
            let technicianId = user.userId.isEmpty ? user.id : user.userId
            guard !technicianId.isEmpty else { continue }

            do {
                _ = try await dataService.syncActiveRouteForServiceStops(
                    companyId: companyId,
                    date: date,
                    techId: technicianId,
                    techName: user.userName
                )
            } catch {
                print("[CompanyActiveRouteOverviewViewModel][syncScheduledRoutes] Technician \(technicianId) Error")
                print(error)
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

    @State private var routeDetailTarget: CompanyRouteDetailTarget?

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                dateHeader

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        if !VM.activeRoutes.isEmpty && !VM.isLoading { summaryGrid }

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
        .task(id: "\(masterDataManager.currentCompany?.id ?? "")-\(Calendar.current.startOfDay(for: VM.selectedDate))") {
            await load()
        }
        .refreshable { await load() }
        .sheet(item: $routeDetailTarget, onDismiss: { Task { await load() } }) { target in
            CompanyRouteDetailPresentation(target: target, dataService: dataService) { stop in
                routeDetailTarget = nil
                navigationManager.push(to: .dailyDisplayStop(dataService: dataService, serviceStop: stop))
            }
            .presentationDetents([.large])
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
            Button { changeDate(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 38, height: 44)
            }
            .accessibilityLabel("Previous day")
            DatePicker("Route date", selection: $VM.selectedDate, displayedComponents: .date)
                .labelsHidden().frame(maxWidth: .infinity)
            Button { changeDate(1) } label: {
                Image(systemName: "chevron.right").frame(width: 38, height: 44)
            }
            .accessibilityLabel("Next day")
            if !Calendar.current.isDateInToday(VM.selectedDate) {
                Button("Today") { VM.selectedDate = Date() }.font(.caption.weight(.semibold))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
        .background(.regularMaterial)
    }

    private func changeDate(_ days: Int) {
        VM.selectedDate = Calendar.current.date(byAdding: .day, value: days, to: VM.selectedDate) ?? VM.selectedDate
    }

        //MARK: summaryGrid
    private var summaryGrid: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { routeSummaryMetrics }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) { routeSummaryMetrics }
        }
    }

    @ViewBuilder private var routeSummaryMetrics: some View {
        MobileDashboardSnapshotMetric(title: "Routes", value: "\(VM.totalRoutes)", tint: .poolBlue)
        MobileDashboardSnapshotMetric(title: "Working", value: "\(VM.startedRoutes)", tint: .orange)
        MobileDashboardSnapshotMetric(title: "Waiting", value: "\(VM.notStartedRoutes)", tint: .secondary)
        MobileDashboardSnapshotMetric(title: "Finished", value: "\(VM.finishedRoutes)", tint: .poolGreen)
    }

        //MARK: routeList
    private var routeList: some View {
        VStack(spacing: 12) {
            ForEach(VM.activeRoutes) { route in
                Button {
                    guard let companyId = masterDataManager.currentCompany?.id else { return }
                    routeDetailTarget = CompanyRouteDetailTarget(companyId: companyId, route: route)
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func activeRouteCard(_ route: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "map")
                    .font(.body.weight(.semibold)).foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.techName).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    if !route.name.isEmpty && route.name != route.techName {
                        Text(route.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                routeStatusBadge(route.status)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            HStack(spacing: 10) {
                ProgressView(value: Double(min(route.finishedStops, route.totalStops)), total: Double(max(route.totalStops, 1)))
                    .tint(.poolGreen)
                Text("\(route.finishedStops)/\(route.totalStops) stops")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary).monospacedDigit()
            }
            if let start = route.startTime {
                Label(timeRangeText(start: start, end: route.endTime), systemImage: "clock")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .mobileMainCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Open stops, logs, locations, and manager actions")
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
    let companyId: String
    let dataService: any ProductionDataServiceProtocol
    let route: ActiveRoute
    let stops: [ServiceStop]
    let logs: [ActiveRouteLog]
    let locations: [ActiveRouteLocation]
    let companyUsers: [CompanyUser]
    let errors: [String: String]

    @Binding var selectedStops: [ServiceStop]
    @Binding var moveDate: Date
    @Binding var selectedTechnicianId: String

    let isMoving: Bool
    let isLoading: Bool

    let onToggleStop: (ServiceStop) -> Void
    let onMoveStops: () -> Void
    let onOpenStop: (ServiceStop) -> Void
    let onReload: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @State private var showCoverageOffer = false
    @State private var showMoveConfirmation = false

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
                            if isLoading { ProgressView("Refreshing route…") }

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
            .sheet(isPresented: $showCoverageOffer, onDismiss: onReload) {
                RouteCoverageOfferSheet(
                    companyId: companyId, route: route, dataService: dataService,
                    initialSelectedStopIds: Set(selectedStops.map(\.id)), initialReason: "Sick day"
                )
            }
            .confirmationDialog("Move \(selectedStops.count) selected stops?", isPresented: $showMoveConfirmation, titleVisibility: .visible) {
                Button("Move selected stops") { onMoveStops() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Move these dated visits to \(companyUsers.first { $0.userId == selectedTechnicianId }?.userName ?? "the selected technician") on \(moveDate.formatted(date: .abbreviated, time: .omitted)). Recurring assignments stay the same.")
            }
            .interactiveDismissDisabled(isMoving)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { onReload() } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(isMoving || isLoading).accessibilityLabel("Refresh route")
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.disabled(isMoving)
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
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .disabled(isMoving)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.name.isEmpty ? "Daily route" : route.name).font(.subheadline.weight(.semibold))
                    Text(route.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                routeStatusBadge(route.status)
            }
            HStack(spacing: 8) {
                MobileDashboardSnapshotMetric(title: "Stops", value: "\(route.finishedStops)/\(route.totalStops)", tint: .poolGreen)
                MobileDashboardSnapshotMetric(title: "Logs", value: errors["logs"] == nil && !isLoading ? "\(logs.count)" : "—", tint: .poolBlue)
                MobileDashboardSnapshotMetric(title: "Locations", value: errors["locations"] == nil && !isLoading ? "\(locations.count)" : "—", tint: .poolBlue)
            }
        }
        .mobileMainCard(material: true)
    }

    @ViewBuilder private func sourceError(_ key: String) -> some View {
        if let message = errors[key] {
            VStack(alignment: .leading, spacing: 6) {
                Label(message, systemImage: "exclamationmark.circle").font(.caption).foregroundStyle(.secondary)
                Button("Reload route", action: onReload).font(.caption.weight(.semibold)).disabled(isLoading || isMoving)
            }
        }
    }

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Service Stops", "\(stops.count) stops in route order.", "list.bullet.rectangle")
            sourceError("stops")

            if stops.isEmpty {
                if !isLoading && errors["stops"] == nil {
                    emptyRow("No stops", "This route has no service stops.", "checklist")
                }
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
            sourceError("logs")

            if logs.isEmpty {
                if !isLoading && errors["logs"] == nil {
                    emptyRow("No logs", "Logs will appear here when the route starts, pauses, resumes, or ends.", "clock")
                }
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
            sourceError("locations")
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
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
    private var eligibleStops: [ServiceStop] { RouteManagerStopSelection.eligibleStops(in: stops, route: route) }
    private var isOwner: Bool { masterDataManager.currentCompany?.ownerId == masterDataManager.user?.id && masterDataManager.user != nil }
    private var canMoveStops: Bool {
        isOwner || masterDataManager.role?.permissionIdList.contains(where: { ["244", "234"].contains($0) }) == true
    }
    private var canOfferCoverage: Bool {
        isOwner || (masterDataManager.role?.permissionIdList.contains("322") == true &&
            (route.techId == masterDataManager.user?.id || masterDataManager.role?.permissionIdList.contains("324") == true))
    }
    private var canManageStops: Bool { canMoveStops || canOfferCoverage }
    private var hasValidSelection: Bool {
        let selectedIds = Set(selectedStops.map(\.id))
        return !selectedIds.isEmpty && selectedIds.isSubset(of: Set(eligibleStops.map(\.id))) && errors["stops"] == nil
    }

    private var managerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Manage route work", "Select the stops to move or offer for coverage.", "slider.horizontal.3")
            sourceError("stops")
            if !canManageStops {
                Text("Your role can view this route. Moving stops or posting coverage requires company permission.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                if canMoveStops {
                    sourceError("users")
                    DatePicker("Move date", selection: $moveDate, displayedComponents: .date)
                        .font(.subheadline)
                    Picker("Destination technician", selection: $selectedTechnicianId) {
                        Text("Select technician").tag("")
                        ForEach(companyUsers) { user in Text(user.userName).tag(user.userId) }
                    }
                    .pickerStyle(.menu)
                    .font(.subheadline)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { managerActionButtons }
                    VStack(alignment: .leading, spacing: 8) { managerActionButtons }
                }
                .controlSize(.small)
                .font(.caption.weight(.semibold))

                if canOfferCoverage {
                    Text("Offer the selected stops for sick-day coverage on the company work board or directly to another technician.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Divider()
                Text("\(selectedStops.count) selected · \(eligibleStops.count) available")
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                HStack {
                    Button("Select all remaining") { selectedStops = eligibleStops }
                    Spacer()
                    Button("Clear") { selectedStops = [] }
                }
                .font(.caption.weight(.semibold))
                .disabled(isLoading || isMoving)
                ForEach(stops) { stop in managerStopRow(stop) }
                if stops.isEmpty && !isLoading && errors["stops"] == nil {
                    Text("There are no stops on this route.").font(.caption).foregroundStyle(.secondary)
                }
                Text("Completed, skipped, and started stops cannot be moved or offered here.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .activeRouteCard()
        .disabled(isLoading || isMoving)
    }

    @ViewBuilder private var managerActionButtons: some View {
        if canMoveStops {
            Button { showMoveConfirmation = true } label: {
                HStack(spacing: 6) {
                    if isMoving { ProgressView().controlSize(.mini) }
                    Label(isMoving ? "Moving stops…" : "Move selected stops", systemImage: "arrowshape.turn.up.right")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasValidSelection || selectedTechnicianId.isEmpty || isLoading || isMoving || errors["users"] != nil)
        }
        if canOfferCoverage {
            Button { showCoverageOffer = true } label: {
                Label("Create work offer", systemImage: "person.2.badge.plus")
            }
            .buttonStyle(.bordered)
            .disabled(!hasValidSelection || isLoading || isMoving)
        }
    }

    private func managerStopRow(_ stop: ServiceStop) -> some View {
        let available = eligibleStops.contains { $0.id == stop.id }
        let selected = selectedStops.contains { $0.id == stop.id }
        return Button { onToggleStop(stop) } label: {
            HStack(spacing: 10) {
                Image(systemName: selected ? "checkmark.square.fill" : "square")
                    .font(.body.weight(.semibold)).foregroundStyle(available ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(stop.customerName).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(stop.address.streetAddress).font(.caption).foregroundStyle(.secondary)
                    Text(available ? stop.type : selectionUnavailableReason(stop))
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(12)
            .background(selected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!available || isLoading || isMoving)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("\(stop.customerName), \(selected ? "selected" : "not selected")\(available ? "" : ", unavailable")")
    }

    private func selectionUnavailableReason(_ stop: ServiceStop) -> String {
        if stop.operationStatus != .notFinished { return stop.operationStatus.rawValue }
        if stop.startTime != nil || stop.endTime != nil { return "Work already started" }
        if stop.techId != route.techId { return "Assigned to another technician" }
        if !Calendar.current.isDate(stop.serviceDate, inSameDayAs: route.date) { return "Scheduled for another day" }
        return "Unavailable for this route"
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
            .disabled(!canManageStops || !eligibleStops.contains(where: { $0.id == stop.id }) || isMoving || isLoading)

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
            .disabled(isMoving)
        }
        .padding(12)
        .background(statusBackground(stop.operationStatus), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

private func sectionHeader(_ title: String, _ subtitle: String, _ systemImage: String) -> some View {
    MobileDashboardSectionHeading(title: title, subtitle: subtitle, systemImage: systemImage)
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
    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        self.mobileMainCard()
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
