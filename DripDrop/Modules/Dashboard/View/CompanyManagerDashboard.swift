import SwiftUI

private struct CompanyDashboardLoadIdentity: Hashable {
    let companyId: String
    let date: Date
    let access: CompanyDashboardAccess
}

// Mount this inside the overview, below the app's shared area navigation.
struct MobileDashboardOverview<TechnicianContent: View>: View {
    let dataService: any ProductionDataServiceProtocol
    @ViewBuilder let technicianContent: () -> TechnicianContent
    @EnvironmentObject private var masterDataManager: MasterDataManager

    var body: some View {
        if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
            MobileDashboardWorkspace(
                companyId: company.id,
                userId: user.id,
                isOwner: company.ownerId == user.id,
                dataService: dataService,
                technicianContent: technicianContent
            )
            .id("\(company.id)|\(user.id)")
        } else {
            technicianContent()
        }
    }
}

struct MobileDashboardWorkspace<TechnicianContent: View>: View {
    let companyId: String
    let userId: String
    let isOwner: Bool
    let dataService: any ProductionDataServiceProtocol
    @ViewBuilder let technicianContent: () -> TechnicianContent

    @StateObject private var accessVM = CompanyDashboardAccessViewModel()
    @AppStorage private var selectedView: String

    init(companyId: String, userId: String, isOwner: Bool, dataService: any ProductionDataServiceProtocol, @ViewBuilder technicianContent: @escaping () -> TechnicianContent) {
        self.companyId = companyId
        self.userId = userId
        self.isOwner = isOwner
        self.dataService = dataService
        self.technicianContent = technicianContent
        _selectedView = AppStorage(wrappedValue: "technician", "dashboardView.\(userId).\(companyId)")
    }

    private var effectiveView: String {
        guard let access = accessVM.access else { return "" }
        if selectedView == "manager" && access.canViewManager { return "manager" }
        return access.canViewTechnician ? "technician" : (access.canViewManager ? "manager" : "")
    }

    var body: some View {
        VStack(spacing: 0) {
            if let access = accessVM.access {
                if access.canViewManager || access.canViewTechnician {
                    Picker("Dashboard view", selection: Binding(get: { effectiveView }, set: { selectedView = $0 })) {
                        if access.canViewTechnician { Text("Technician").tag("technician") }
                        if access.canViewManager { Text("Manager").tag("manager") }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .accessibilityIdentifier("dashboardViewPicker")

                    if effectiveView == "manager" {
                        CompanyManagerDashboard(companyId: companyId, userId: userId, access: access, dataService: dataService)
                    } else {
                        technicianContent()
                    }
                } else {
                    ContentUnavailableView("No dashboard access", systemImage: "lock.shield", description: Text("Ask your company administrator to enable a dashboard scope for your role."))
                }
            } else if let error = accessVM.error {
                ContentUnavailableView {
                    Label("Dashboard unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again", action: startAccess)
                }
            } else {
                ProgressView("Loading dashboard…").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.listColor)
        .task(id: isOwner) { startAccess() }
        .onDisappear { accessVM.stop() }
    }

    private func startAccess() { accessVM.start(companyId: companyId, userId: userId, isOwner: isOwner) }
}

struct CompanyManagerDashboard: View {
    let companyId: String
    let userId: String
    let access: CompanyDashboardAccess
    let dataService: any ProductionDataServiceProtocol

    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var model = CompanyDashboardViewModel()
    @State private var selectedDate = Date()
    @State private var routeDetailTarget: CompanyRouteDetailTarget?
    @AppStorage private var selectedTag: String

    init(companyId: String, userId: String, access: CompanyDashboardAccess, dataService: any ProductionDataServiceProtocol) {
        self.companyId = companyId
        self.userId = userId
        self.access = access
        self.dataService = dataService
        _selectedTag = AppStorage(wrappedValue: "", "dashboardArea.\(userId).\(companyId)")
    }

    private var availableTags: [String] { access.availableTags(customers: model.records["customers"] ?? []) }
    private var effectiveTag: String {
        if let tag = availableTags.first(where: { CompanyDashboardRecord.key($0) == CompanyDashboardRecord.key(selectedTag) }) { return tag }
        return access.canViewAllAreas ? "" : (availableTags.first ?? "")
    }
    private var snapshot: CompanyDashboardSnapshot { model.snapshot(access: access, tag: effectiveTag, date: selectedDate) }
    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 10), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2) }
    private var loadIdentity: CompanyDashboardLoadIdentity {
        CompanyDashboardLoadIdentity(companyId: companyId, date: Calendar.current.startOfDay(for: selectedDate), access: access)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                overviewHeader
                quickActionsGrid
                dashboardFilters
                if let error = model.errors["customers"] {
                    unavailable("Areas and customer data", message: error)
                }
                if !access.canViewAllAreas && availableTags.isEmpty && model.loaded.contains("customers") {
                    ContentUnavailableView("No areas available", systemImage: "tag", description: Text("Your regional dashboard needs an assigned customer tag."))
                } else if !access.fullRegionAccess && access.regionTags.isEmpty {
                    ContentUnavailableView("No areas assigned", systemImage: "tag", description: Text("Ask your company administrator to assign customer areas to your role."))
                } else {
                    if access.canViewStops {
                        dailyProgress
                        weeklyWorkload
                        teamWorkload
                    }
                    officeOverview
                    if access.permits("20") { schedulingQueue }
                    if access.permits("30") { repairQueue }
                }
                Text("Area filters apply to this dashboard. Open a tool to view its company list.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
        }
        .background(Color.listColor)
        .task(id: loadIdentity) { reload() }
        .refreshable { reload() }
        .onDisappear { model.stop() }
        .sheet(item: $routeDetailTarget) { target in
            CompanyRouteDetailPresentation(target: target, dataService: dataService) { stop in
                routeDetailTarget = nil
                navigationManager.push(to: .dailyDisplayStop(dataService: dataService, serviceStop: stop))
            }
            .presentationDetents([.large])
        }
        .accessibilityIdentifier("managerDashboard")
    }

    private var overviewHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Company overview")
                        .font(.title3.weight(.semibold))
                    Text(masterDataManager.currentCompany?.name ?? "Drip Drop")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(weekDay(date: selectedDate))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.poolBlue, in: Capsule())
            }

            HStack(spacing: 10) {
                if access.canViewStops {
                    MobileDashboardSummaryMetric(
                        title: "Stops",
                        value: model.isReady("stops") ? "\(snapshot.finished)/\(snapshot.dailyStops.count)" : "—",
                        systemImage: "map",
                        tint: .poolGreen,
                        route: stopsRoute
                    )
                }
                if access.permits("30") {
                    MobileDashboardSummaryMetric(title: "Pending", value: value("requests", count: snapshot.requests.count), systemImage: "wrench.adjustable.fill", tint: .orange, route: .repairRequestList(dataService: dataService))
                }
                if access.permits("20") {
                    MobileDashboardSummaryMetric(title: "Jobs", value: value("jobs", count: snapshot.jobs.count), systemImage: "briefcase.fill", tint: .poolBlue, route: .jobs(dataService: dataService))
                }
            }
        }
        .mobileMainCard(material: true)
    }

    private var dashboardFilters: some View {
        card {
            sectionTitle("Dashboard filters", subtitle: "Choose the company area and work date", image: "line.3.horizontal.decrease")
            Menu {
                Picker("Customer area", selection: Binding(get: { effectiveTag }, set: { selectedTag = $0 })) {
                    if access.canViewAllAreas {
                        Text(access.fullRegionAccess ? "Whole company" : "All permitted areas").tag("")
                    }
                    ForEach(availableTags, id: \.self) { tag in Text(tag).tag(tag) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "tag").foregroundStyle(.secondary)
                    Text(effectiveTag.isEmpty ? (access.fullRegionAccess ? "Whole company" : "All permitted areas") : effectiveTag)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.tertiary)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .accessibilityLabel("Customer area, \(effectiveTag.isEmpty ? "all available areas" : effectiveTag)")
            .accessibilityIdentifier("managerDashboardAreaPicker")

            HStack {
                Button { moveDate(-1) } label: { Image(systemName: "chevron.left").frame(width: 36, height: 44) }
                    .accessibilityLabel("Previous day")
                DatePicker("Work date", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden().frame(maxWidth: .infinity)
                Button { moveDate(1) } label: { Image(systemName: "chevron.right").frame(width: 36, height: 44) }
                    .accessibilityLabel("Next day")
                if !Calendar.current.isDateInToday(selectedDate) {
                    Button("Today") { selectedDate = Date() }.font(.caption.weight(.semibold))
                }
            }
        }
    }

    private var dailyProgress: some View {
        card {
            sectionTitle("Service progress", subtitle: "All scheduled technicians · selected day", image: "checkmark.circle", route: stopsRoute)
            if let error = model.errors["stops"] ?? model.errors["customers"] {
                unavailable("Service progress", message: error)
            } else if !model.isReady("stops") {
                ProgressView("Loading service stops…")
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(snapshot.finished)").font(.headline.weight(.bold)).monospacedDigit()
                    Text("of \(snapshot.dailyStops.count) stops complete").font(.subheadline).foregroundStyle(.secondary)
                }
                ProgressView(value: Double(snapshot.finished), total: Double(max(snapshot.dailyStops.count, 1)))
                    .tint(.poolGreen)
                    .accessibilityLabel("\(snapshot.finished) of \(snapshot.dailyStops.count) stops complete")
                LazyVGrid(columns: columns, spacing: 10) {
                    metric("Remaining", value: "\(snapshot.remaining)", tint: .poolBlue)
                    metric("Unassigned", value: "\(snapshot.unassigned)", tint: snapshot.unassigned > 0 ? .orange : .secondary)
                    metric("Technicians", value: "\(snapshot.workload.count)", tint: .poolBlue)
                    metric("Skipped", value: "\(snapshot.skipped)", tint: .secondary)
                }
                if snapshot.dailyStops.isEmpty {
                    Text("No service stops scheduled for this day and area.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var weeklyWorkload: some View {
        card {
            sectionTitle("Next 7 days", subtitle: "Scheduled stops and completed work", image: "calendar")
            if model.isReady("stops") {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate
                        let stops = snapshot.stops.filter { $0.serviceDate.map { Calendar.current.isDate($0, inSameDayAs: date) } == true }
                        let finished = stops.filter(\.isFinished).count
                        VStack(spacing: 7) {
                            Text("\(stops.count)").font(.caption.weight(.semibold)).monospacedDigit()
                            GeometryReader { geometry in
                                ZStack(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4).fill(Color.poolBlue.opacity(0.18))
                                    RoundedRectangle(cornerRadius: 4).fill(Color.poolGreen)
                                        .frame(height: geometry.size.height * Double(finished) / Double(max(stops.count, 1)))
                                }
                            }
                            .frame(height: max(5, 62 * Double(stops.count) / Double(max(weekMaximum, 1))))
                            Text(date, format: .dateTime.weekday(.narrow)).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? 70 : 32, maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)): \(stops.count) scheduled, \(finished) complete")
                    }
                  }
                }
                Label("Completed", systemImage: "circle.fill").font(.caption2).foregroundStyle(Color.poolGreen)
            } else {
                Text("Weekly workload appears when service stops are available.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var weekMaximum: Int {
        Dictionary(grouping: snapshot.stops.compactMap(\.serviceDate), by: { Calendar.current.startOfDay(for: $0) }).values.map(\.count).max() ?? 1
    }

    private var teamWorkload: some View {
        card {
            sectionTitle("Team workload", subtitle: "Selected day · most remaining work first", image: "person.2", route: stopsRoute)
            if model.isReady("stops") {
                if snapshot.workload.isEmpty {
                    Text("No assigned technician work in this area.").font(.caption).foregroundStyle(.secondary)
                }
                ForEach(Array(snapshot.workload.prefix(6))) { workload in
                    Button {
                        routeDetailTarget = CompanyRouteDetailTarget(
                            companyId: companyId, technicianId: workload.id,
                            technicianName: workload.name, date: selectedDate
                        )
                    } label: {
                      VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(workload.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Spacer()
                            Text("\(workload.finished)/\(workload.stops.count)").font(.caption.weight(.semibold)).monospacedDigit().foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        ProgressView(value: Double(workload.finished), total: Double(max(workload.stops.count, 1))).tint(.poolGreen)
                        Text("\(workload.remaining) remaining").font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                      .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Open this technician's stops, logs, locations, and manager actions")
                }
                if snapshot.workload.count > 6 {
                    Text("+\(snapshot.workload.count - 6) more technicians in company routes")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if snapshot.unassigned > 0 {
                    Label("\(snapshot.unassigned) unfinished stops need a technician", systemImage: "exclamationmark.circle")
                        .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                }
                if let stopsRoute {
                    NavigationLink("Open company routes", value: stopsRoute)
                        .font(.caption.weight(.semibold)).foregroundStyle(Color.poolBlue)
                }
            }
        }
    }

    private var officeOverview: some View {
        card {
            sectionTitle("Company snapshot", subtitle: "Customers and open work across this area", image: "building.2")
            LazyVGrid(columns: columns, spacing: 8) {
                if access.permits("10") {
                    metric("Active customers", value: value("customers", count: snapshot.customers.count), tint: .poolGreen)
                }
                if access.permits("20") {
                    metric("Open jobs", value: value("jobs", count: snapshot.jobs.count), tint: .poolBlue)
                    metric("Need scheduling", value: value("jobs", count: snapshot.schedulingQueue.count), tint: .orange)
                }
                if access.permits("30") {
                    metric("Open requests", value: value("requests", count: snapshot.requests.count), tint: .orange)
                }
            }
        }
    }

    private var schedulingQueue: some View {
        card {
            sectionTitle("Needs scheduling", subtitle: "Unscheduled jobs across this area", image: "calendar.badge.clock", route: .jobs(dataService: dataService))
            queue(snapshot.schedulingQueue, source: "jobs", empty: "No jobs waiting to be scheduled.")
        }
    }

    private var repairQueue: some View {
        card {
            sectionTitle("Repair follow-ups", subtitle: "Open requests from the whole team", image: "wrench.and.screwdriver", route: .repairRequestList(dataService: dataService))
            queue(snapshot.requests.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }, source: "requests", empty: "No open repair requests in this area.")
        }
    }

    private var stopsRoute: Route? {
        if access.permits("210") { return .companyRouteOverView(dataService: dataService) }
        if access.permits("240") { return .serviceStops(dataService: dataService) }
        return nil
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            if let stopsRoute { quickAction("Routes", subtitle: "Company workload", image: "map", tint: .poolGreen, route: stopsRoute) }
            if access.permits("20") { quickAction("Jobs", subtitle: "Work orders", image: "briefcase", tint: .poolBlue, route: .jobs(dataService: dataService)) }
            if access.permits("30") { quickAction("Requests", subtitle: "Repair follow-ups", image: "wrench.adjustable.fill", tint: .orange, route: .repairRequestList(dataService: dataService)) }
            if access.permits("260") { quickAction("Team", subtitle: "Company users", image: "person.2", tint: .poolBlue, route: .users(dataService: dataService)) }
            if access.permits("10") { quickAction("Customers", subtitle: "Company directory", image: "person.2.crop.square.stack", tint: .poolGreen, route: .customers(dataService: dataService)) }
            if access.permits("420") { quickAction("Payroll", subtitle: "Company payroll", image: "dollarsign.circle", tint: .orange, route: .payRoll(dataService: dataService)) }
        }
    }

    private func quickAction(_ title: String, subtitle: String, image: String, tint: Color, route: Route) -> some View {
        NavigationLink(value: route) {
            MobileDashboardQuickActionLabel(title: title, subtitle: subtitle, systemImage: image, tint: tint)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func queue(_ items: [CompanyDashboardRecord], source: String, empty: String) -> some View {
        if let error = model.errors[source] ?? model.errors["customers"] {
            unavailable("Work queue", message: error)
        } else if !model.isReady(source) {
            ProgressView("Loading work…")
        } else if items.isEmpty {
            Text(empty).font(.caption).foregroundStyle(.secondary)
        } else {
            ForEach(Array(items.prefix(4))) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.customerName.isEmpty ? item.title : item.customerName).font(.subheadline.weight(.semibold)).lineLimit(2)
                    if !item.customerName.isEmpty { Text(item.title).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                    Text(item.status).font(.caption2.weight(.medium)).foregroundStyle(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            if items.count > 4 { Text("+\(items.count - 4) more").font(.caption).foregroundStyle(.secondary) }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .mobileMainCard()
    }

    private func sectionTitle(_ title: String, subtitle: String, image: String, route: Route? = nil) -> some View {
        MobileDashboardSectionHeading(title: title, subtitle: subtitle, systemImage: image, route: route)
    }

    private func metric(_ title: String, value: String, tint: Color) -> some View {
        MobileDashboardSnapshotMetric(title: title, value: value, tint: tint)
    }

    private func unavailable(_ title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(title) unavailable", systemImage: "exclamationmark.circle").font(.caption.weight(.semibold))
            Text(message).font(.caption2).foregroundStyle(.secondary).lineLimit(3)
            Button("Try again") { reload() }.font(.caption.weight(.semibold))
        }
    }

    private func value(_ source: String, count: Int) -> String { model.isReady(source) ? "\(count)" : "—" }
    private func moveDate(_ days: Int) { selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate }
    private func reload() { model.start(companyId: companyId, access: access, date: selectedDate) }
}
