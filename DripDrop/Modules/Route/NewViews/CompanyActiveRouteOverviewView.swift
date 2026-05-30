//
//  CompanyActiveRouteOverviewView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/30/26.
//

import Foundation
import SwiftUI
import MapKit

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
        let users = try await dataService.getCompanyUsers(companyId: companyId)
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
extension CompanyActiveRouteOverviewView {

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
            sectionHeader("Locations", "\(locations.count) location breadcrumbs.", "location")

            if locations.isEmpty {
                emptyRow("No locations", "Location breadcrumbs will appear here while the route is active.", "location.slash")
            } else {
                VStack(spacing: 10) {
                    ForEach(locations.suffix(20).reversed()) { location in
                        locationRow(location)
                    }
                }
            }
        }
        .activeRouteCard()
    }

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
