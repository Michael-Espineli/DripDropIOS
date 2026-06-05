//
//  WorkPreviewBasedOnCompany.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/13/24.
//

import SwiftUI

struct WorkPreviewBasedOnCompany: View {
    @Environment(\.locale) var locale

    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject var mobileDailyVM: MobileDailyRouteDisplayViewModel

    @StateObject private var VM: AllViewModel

    init(
        dataService: any ProductionDataServiceProtocol,
        company: Company
    ) {
        _VM = StateObject(wrappedValue: AllViewModel(dataService: dataService))
        _company = State(wrappedValue: company)
    }
    @State private var showPreviousWork: Bool = false
    @State private var routePendingEnd: ActiveRoute? = nil
    
    @State private var company: Company
    @State private var showShift: Bool = false
    @State private var workOffersNeedingActionCount: Int = 0
    @State private var shoppingItemsNeedingActionCount: Int = 0
    
    var body: some View {
        VStack(spacing: 14) {
            todayHeaderCard
            routeControlCard
            previousWorkCard
            routeOpenCard
            actionCenterCard
            workerCard
        }
        .sheet(isPresented: $mobileDailyVM.showMilage, onDismiss: {
            mobileDailyVM.updateRouteStartMilage(
                companyId: masterDataManager.currentCompany?.id
            )
        }) {
            startMilageView
                .presentationDetents([.fraction(0.5), .fraction(0.6)])
        }
        .sheet(isPresented: $mobileDailyVM.showEndMilage) {
            endMilageView
                .presentationDetents([.fraction(0.5), .fraction(0.6), .large])
        }
        .task {
            if let user = masterDataManager.user {
                do {
                    try await VM.loadCompanyWorkPreview(
                        companyId: company.id,
                        user: user
                    )

                    await loadDashboardActionCounts()
                    await loadPreviousWork()
                } catch {
                    print("[WorkPreviewBasedOnCompany][task] Error - \(error)")
                }
            }
        }
        .onAppear {
            if let company = masterDataManager.currentCompany,
               let user = masterDataManager.user {
                print("")
                print("[WorkPreviewBasedOnCompany][onAppear] Calling start")

                mobileDailyVM.start(
                    companyId: company.id,
                    user: user,
                    date: Date()
                )
            }
        }
        .onDisappear {
            mobileDailyVM.stop()
        }
    }
    private func loadPreviousWork() async {
        guard let company = masterDataManager.currentCompany else { return }

        let technicianId =
            masterDataManager.companyUser?.userId ??
            masterDataManager.user?.id ?? ""

        guard !technicianId.isEmpty else { return }

        await mobileDailyVM.loadPreviousRouteReview(
            companyId: company.id,
            technicianId: technicianId
        )
    }
    private var routeBeingEnded: ActiveRoute? {
        routePendingEnd ?? mobileDailyVM.activeRoute
    }

    private var displayedStartMileageForEnding: Double {
        routeBeingEnded?.startMilage ?? mobileDailyVM.startMilage
    }
}

#Preview {
    WorkPreviewBasedOnCompany(
        dataService: MockDataService(),
        company: MockDataService.mockCompany
    )
}

// MARK: - Main Cards

extension WorkPreviewBasedOnCompany {
        // MARK: - previousWorkCard
    private var previousWorkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Previous Work", systemImage: "clock.arrow.circlepath")

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Button {
                showPreviousWork = true
            } label: {
                dashboardActionRow(
                    title: "Routes & Timesheets",
                    subtitle: "Review previous days, unfinished routes, and forgotten time sheets.",
                    systemImage: "calendar.badge.clock",
                    badgeCount: previousWorkNeedsActionCount,
                    tint: .purple
                )
            }
            .buttonStyle(.plain)
        }
        .workPreviewCard()
        .sheet(isPresented: $showPreviousWork) {
            previousWorkSheet
                .presentationDetents([.medium, .large])
        }
    }

        // MARK: - previousWorkNeedsActionCount
    private var previousWorkNeedsActionCount: Int {
        mobileDailyVM.previousRoutesNeedingReview.count
    }
    // MARK: - previousWorkSheet

    private var previousWorkSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        mileageHeaderCard(
                            title: "Previous Work",
                            message: "Review older routes, unfinished routes, missing mileage, and open time sheets.",
                            systemImage: "clock.arrow.circlepath"
                        )

                        unfinishedRouteReviewCard
                        previousRoutesPlaceholderCard
                        timeSheetsPlaceholderCard

                        Color.clear.frame(height: 20)
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Previous Work")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showPreviousWork = false
                    }
                }
            }
        }
    }
    //MARK: unfinishedRouteReviewCard
    private var unfinishedRouteReviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Needs Review", systemImage: "exclamationmark.triangle")

            if mobileDailyVM.previousRoutesNeedingReview.isEmpty {
                emptyStateRow(
                    title: "No previous route issues",
                    message: "Routes needing review will appear here.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(mobileDailyVM.previousRoutesNeedingReview) { route in
                        previousRouteReviewRow(route)
                    }
                }
            }
        }
        .workPreviewCard()
    }
    
    //MARK: previousRouteReviewRow
    private func previousRouteReviewRow(_ route: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: previousRouteIssueIcon(route))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.subheadline.weight(.semibold))

                    Text(fullDate(date: route.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(previousRouteIssueText(route))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                routeStatusBadge(route.status.rawValue)
            }

            routeMetricGrid(route)

            HStack(spacing: 10) {
                Button {
                    prepareToEndPreviousRoute(route)
                } label: {
                    routeControlButton(
                        title: "Complete Route",
                        systemImage: "stop.circle",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)

                Button {
                    mobileDailyVM.resumeActiveRoute(
                        companyId: masterDataManager.currentCompany?.id,
                        companyName: masterDataManager.currentCompany?.name,
                        user: masterDataManager.user,
                        route: route
                    )
                    showPreviousWork = false
                } label: {
                    routeControlButton(
                        title: "Resume",
                        systemImage: "arrow.clockwise.circle",
                        tint: .accentColor
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private func previousRouteIssueIcon(_ route: ActiveRoute) -> String {
        if route.endMilage == nil {
            return "gauge.with.dots.needle.bottom.50percent"
        }

        if route.endTime == nil {
            return "clock.badge.exclamationmark"
        }

        return "exclamationmark.triangle"
    }

    private func previousRouteIssueText(_ route: ActiveRoute) -> String {
        if route.status != .finished {
            return "This previous route was not marked finished."
        }

        if route.endMilage == nil {
            return "This route is missing ending mileage."
        }

        if route.endTime == nil {
            return "This route is missing an end time."
        }

        return "This route needs review."
    }

    private func prepareToEndPreviousRoute(_ route: ActiveRoute) {
        routePendingEnd = route

        if let endMilage = route.endMilage {
            mobileDailyVM.inputEndMilage = String(endMilage)
        } else if let startMilage = route.startMilage {
            mobileDailyVM.inputEndMilage = String(startMilage)
        } else {
            mobileDailyVM.inputEndMilage = ""
        }

        mobileDailyVM.showEndMilage = true
    }
    private var previousRoutesPlaceholderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Recent Routes", systemImage: "calendar")

            if mobileDailyVM.recentActiveRoutes.isEmpty {
                emptyStateRow(
                    title: "No recent routes",
                    message: "Recent route history will appear here.",
                    systemImage: "map"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(mobileDailyVM.recentActiveRoutes) { route in
                        recentRouteRow(route)
                    }
                }
            }
        }
        .workPreviewCard()
    }
    private func recentRouteRow(_ route: ActiveRoute) -> some View {
        HStack(spacing: 12) {
            routeProgressRing(route)

            VStack(alignment: .leading, spacing: 5) {
                Text(route.name)
                    .font(.subheadline.weight(.semibold))

                Text(fullDate(date: route.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(route.finishedStops) of \(route.totalStops) stops complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let startMilage = route.startMilage {
                    Text(mileageRangeText(start: startMilage, end: route.endMilage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            routeStatusBadge(route.status.rawValue)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private var timeSheetsPlaceholderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Time Sheets", systemImage: "person.badge.clock")

            emptyStateRow(
                title: "Timesheet list not wired yet",
                message: "Next, load open or previous WorkLog / timesheet records for this employee.",
                systemImage: "clock"
            )
        }
        .workPreviewCard()
    }
        // MARK: - todayHeaderCard
    private var todayHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "map")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Today’s Route")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(company.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let activeRoute = mobileDailyVM.activeRoute {
                    routeStatusBadge(activeRoute.status.rawValue)
                }
            }

            HStack(spacing: 8) {
                if let role = VM.role {
                    Label(role.name, systemImage: "lock.shield")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                if let companyUser = VM.companyUser {
                    Label(companyUser.workerType.rawValue, systemImage: "person.crop.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()
            }
        }
        .workPreviewCard(material: true)
    }
        // MARK: - actionCenterCard

    private var actionCenterCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Action Center", systemImage: "bolt.circle")

                Spacer()

                let totalNeedsAction = workOffersNeedingActionCount + shoppingItemsNeedingActionCount

                if totalNeedsAction > 0 {
                    Text("\(totalNeedsAction)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.red, in: Capsule())
                }
            }

            VStack(spacing: 10) {
                workOffersActionRow
                shoppingListActionRow
            }
        }
        .workPreviewCard()
    }

    @ViewBuilder
    private var workOffersActionRow: some View {
        if let companyUser = masterDataManager.companyUser {
            NavigationLink(
                value: Route.technicianWorkCenter(
                    dataService: dataService,
                    companyUser: companyUser
                )
            ) {
                dashboardActionRow(
                    title: "My Work Offers",
                    subtitle: workOffersNeedingActionCount > 0
                    ? "\(workOffersNeedingActionCount) offer\(workOffersNeedingActionCount == 1 ? "" : "s") need action"
                    : "Review offered work, accepted work, and internal work boards.",
                    systemImage: "briefcase",
                    badgeCount: workOffersNeedingActionCount,
                    tint: .blue
                )
            }
            .buttonStyle(.plain)
        } else {
            dashboardActionRow(
                title: "My Work Offers",
                subtitle: "Company user record has not loaded yet.",
                systemImage: "briefcase",
                badgeCount: 0,
                tint: .blue,
                disabled: true
            )
        }
    }

    private var shoppingListActionRow: some View {
        NavigationLink(
            value: Route.shoppingList(dataService: dataService)
        ) {
            dashboardActionRow(
                title: "Shopping List",
                subtitle: shoppingItemsNeedingActionCount > 0
                ? "\(shoppingItemsNeedingActionCount) item\(shoppingItemsNeedingActionCount == 1 ? "" : "s") need purchase or install action"
                : "Track personal, customer, and job material needs.",
                systemImage: "cart",
                badgeCount: shoppingItemsNeedingActionCount,
                tint: .green
            )
        }
        .buttonStyle(.plain)
    }
    private var routeControlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Route Controls", systemImage: "slider.horizontal.3")

                Spacer()

                if let activeRoute = mobileDailyVM.activeRoute {
                    Text(activeRoute.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(getColor(status: activeRoute.status.rawValue), in: Capsule())
                }
            }

            if let activeRoute = mobileDailyVM.activeRoute {
                routeActionButtons(for: activeRoute)
            } else {
                noRouteControls
            }
        }
        .workPreviewCard()
    }

    private var routeOpenCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Route Preview", systemImage: "point.topleft.down.curvedto.point.bottomright.up")

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            routeLinkContent
        }
        .workPreviewCard()
    }

    private var workerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Worker Status", systemImage: "person.badge.clock")
                Spacer()
            }

            if let companyUser = VM.companyUser {
                HStack(spacing: 12) {
                    Image(systemName: workerIcon(companyUser.workerType))
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(companyUser.workerType.rawValue)
                            .font(.subheadline.weight(.semibold))

                        Text(companyUser.userName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if companyUser.workerType == .employee {
                        Button {
                            showShift = true
                        } label: {
                            Text("Clock In")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showShift) {
                            WorkLogIn(dataService: dataService)
                                .presentationDetents([.fraction(0.2), .fraction(0.6)])
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                emptyStateRow(
                    title: "No company user loaded",
                    message: "Route access will appear after your company user record loads.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
            }
        }
        .workPreviewCard()
    }
}

// MARK: - Route Links

extension WorkPreviewBasedOnCompany {

    private var routeLinkContent: some View {
        Group {
            if let companyUser = VM.companyUser {
                switch companyUser.workerType {
                case .contractor:
                    if UIDevice.isIPhone {
                        NavigationLink(
                            value: Route.employeeMainDailyDisplayView(dataService: dataService)
                        ) {
                            routePreview
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            masterDataManager.selectedCategory = .dailyDisplay
                        } label: {
                            routePreview
                        }
                        .buttonStyle(.plain)
                    }

                case .employee:
                    if UIDevice.isIPhone {
                        NavigationLink(
                            value: Route.employeeMainDailyDisplayView(dataService: dataService)
                        ) {
                            routePreview
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            masterDataManager.selectedCategory = .dailyDisplay
                        } label: {
                            routePreview
                        }
                        .buttonStyle(.plain)
                    }

                case .notAssigned:
                    if UIDevice.isIPhone {
                        NavigationLink(
                            value: Route.employeeMainDailyDisplayView(dataService: dataService)
                        ) {
                            routePreview
                        }
                        .disabled(true)
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            masterDataManager.selectedCategory = .dailyDisplay
                        } label: {
                            routePreview
                        }
                        .disabled(true)
                        .buttonStyle(.plain)
                    }
                }
            } else {
                emptyStateRow(
                    title: "Route unavailable",
                    message: "Could not determine your worker type.",
                    systemImage: "map"
                )
            }
        }
    }

    private var routePreview: some View {
        Group {
            if let activeRoute = mobileDailyVM.activeRoute {
                HStack(spacing: 16) {
                    routeProgressRing(activeRoute)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Open Today’s Route")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("\(activeRoute.finishedStops) of \(activeRoute.totalStops) stops complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        routeMetricGrid(activeRoute)
                    }

                    Spacer()
                }
                .padding(12)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                noWorkTodayPreview
            }
        }
    }

    private var noWorkTodayPreview: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("No Work Today")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("There is no active route assigned for today.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Route Controls

extension WorkPreviewBasedOnCompany {

    @ViewBuilder
    private func routeActionButtons(for activeRoute: ActiveRoute) -> some View {
        switch activeRoute.status {
        case .inProgress, .traveling:
            HStack(spacing: 12) {
                Button {
                    routePendingEnd = activeRoute

                    if let endMilage = activeRoute.endMilage {
                        mobileDailyVM.inputEndMilage = String(endMilage)
                    } else if let startMilage = activeRoute.startMilage {
                        mobileDailyVM.inputEndMilage = String(startMilage)
                    }

                    mobileDailyVM.showEndMilage = true
                } label: {
                    routeControlButton(
                        title: "Stop Route",
                        systemImage: "stop.circle",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)

                Button {
                    mobileDailyVM.pauseActiveRoute(
                        companyId: masterDataManager.currentCompany?.id,
                        companyName: masterDataManager.currentCompany?.name,
                        user: masterDataManager.user
                    )
                } label: {
                    routeControlButton(
                        title: "Pause",
                        systemImage: "pause.circle",
                        tint: .orange
                    )
                }
                .buttonStyle(.plain)
            }

        case .didNotStart:
            Button {
                mobileDailyVM.startActiveRoute(
                    companyId: masterDataManager.currentCompany?.id,
                    companyName: masterDataManager.currentCompany?.name,
                    user: masterDataManager.user
                )
            } label: {
                routeControlButton(
                    title: "Start Route",
                    systemImage: "play.circle",
                    tint: .accentColor
                )
            }
            .buttonStyle(.plain)

        case .onBreak:
            Button {
                mobileDailyVM.resumeActiveRoute(
                    companyId: masterDataManager.currentCompany?.id,
                    companyName: masterDataManager.currentCompany?.name,
                    user: masterDataManager.user
                )
            } label: {
                routeControlButton(
                    title: "Resume Route",
                    systemImage: "play.circle",
                    tint: .accentColor
                )
            }
            .buttonStyle(.plain)

        case .finished:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Route Finished")
                            .font(.subheadline.weight(.semibold))

                        Text("You can resume the route if more work needs to be completed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Button {
                    mobileDailyVM.resumeActiveRoute(
                        companyId: masterDataManager.currentCompany?.id,
                        companyName: masterDataManager.currentCompany?.name,
                        user: masterDataManager.user
                    )
                } label: {
                    routeControlButton(
                        title: "Resume Route",
                        systemImage: "arrow.clockwise.circle",
                        tint: .accentColor
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var noRouteControls: some View {
        emptyStateRow(
            title: "No active route",
            message: "There is no route to start or manage right now.",
            systemImage: "map"
        )
    }

    private func routeControlButton(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint == .accentColor ? .white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                tint == .accentColor
                ? tint
                : tint.opacity(0.13),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

// MARK: - Route Metrics

extension WorkPreviewBasedOnCompany {

    private func routeProgressRing(_ activeRoute: ActiveRoute) -> some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 8)
                .frame(width: 76, height: 76)

            Circle()
                .trim(
                    from: 0,
                    to: Double(activeRoute.finishedStops) / Double(max(activeRoute.totalStops, 1))
                )
                .stroke(
                    Color.poolGreen,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 76, height: 76)

            VStack(spacing: 1) {
                Text("\(activeRoute.finishedStops)")
                    .font(.headline.weight(.bold))

                Text("of \(activeRoute.totalStops)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 82, height: 82)
    }

    private func routeMetricGrid(_ activeRoute: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let startMilage = activeRoute.startMilage {
                metricRow(
                    title: "Mileage",
                    value: mileageRangeText(
                        start: startMilage,
                        end: activeRoute.endMilage
                    ),
                    detail: mileageDifferenceText(
                        start: startMilage,
                        end: activeRoute.endMilage
                    ),
                    systemImage: "gauge.with.dots.needle.bottom.50percent"
                )
            }

            if let startTime = activeRoute.startTime {
                metricRow(
                    title: "Time",
                    value: timeRangeText(
                        start: startTime,
                        end: activeRoute.endTime
                    ),
                    detail: timeDifferenceText(
                        start: startTime,
                        end: activeRoute.endTime
                    ),
                    systemImage: "clock"
                )
            }

            if activeRoute.distanceMiles > 0 {
                metricRow(
                    title: "Distance",
                    value: Measurement(
                        value: activeRoute.distanceMiles,
                        unit: UnitLength.miles
                    )
                    .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)),
                    detail: nil,
                    systemImage: "road.lanes"
                )
            }

            if activeRoute.durationMin > 0 {
                metricRow(
                    title: "Planned Duration",
                    value: displayMinAsMinAndHour(min: activeRoute.durationMin),
                    detail: nil,
                    systemImage: "timer"
                )
            }
        }
    }

    private func metricRow(
        title: String,
        value: String,
        detail: String?,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let detail,
                   !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func mileageRangeText(
        start: Double,
        end: Double?
    ) -> String {
        let startText = Measurement(
            value: start,
            unit: UnitLength.miles
        )
        .formatted(
            .measurement(width: .abbreviated, usage: .road)
            .locale(locale)
        )

        guard let end else {
            return startText
        }

        let endText = Measurement(
            value: end,
            unit: UnitLength.miles
        )
        .formatted(
            .measurement(width: .abbreviated, usage: .road)
            .locale(locale)
        )

        return "\(startText) → \(endText)"
    }

    private func mileageDifferenceText(
        start: Double,
        end: Double?
    ) -> String? {
        guard let end else { return nil }

        return Measurement(
            value: end - start,
            unit: UnitLength.miles
        )
        .formatted(
            .measurement(width: .abbreviated, usage: .road)
            .locale(locale)
        )
    }

    private func timeRangeText(
        start: Date,
        end: Date?
    ) -> String {
        guard let end else {
            return time(date: start)
        }

        return "\(time(date: start)) → \(time(date: end))"
    }

    private func timeDifferenceText(
        start: Date,
        end: Date?
    ) -> String? {
        guard let end else { return nil }

        return displayMinAsMinAndHour(
            min: minBetween(
                start: start,
                end: end
            )
        )
    }
}

// MARK: - Mileage Sheets

extension WorkPreviewBasedOnCompany {
    
    private var startMilageView: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    mileageHeaderCard(
                        title: "Start Mileage",
                        message: "Select a vehicle and enter the starting mileage before beginning the route.",
                        systemImage: "gauge.with.dots.needle.bottom.50percent"
                    )
                    
                    vehiclePickerCard
                    
                    if !mobileDailyVM.selectedVehical.id.isEmpty {
                        startMileageInputCard
                    }
                    
                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("Start Mileage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var endMilageView: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()
                
                VStack(spacing: 14) {
                    mileageHeaderCard(
                        title: "End Mileage",
                        message: mobileDailyVM.selectedVehical.id.isEmpty
                        ? "Enter the ending mileage to finish the route. Vehicle selection is optional for routes that started without one."
                        : "Enter the ending mileage when the route is complete.",
                        systemImage: "flag.checkered"
                    )
                    
                    if mobileDailyVM.selectedVehical.id.isEmpty {
                        emptyStateRow(
                            title: "No vehicle on this route",
                            message: "You can still finish the route. Pick a vehicle only if you want to attach one now.",
                            systemImage: "car"
                        )
                        .workPreviewCard()
                        
                        vehiclePickerCard
                    }
                    
                    endMileageInputCard
                    
                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("End Mileage")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func mileageHeaderCard(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
        .workPreviewCard()
    }
    
    private var vehiclePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Vehicle", systemImage: "car")
            
            Button {
                mobileDailyVM.showVehicalPicker.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "car")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Selected Vehicle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text(
                            mobileDailyVM.selectedVehical.id.isEmpty
                            ? "Pick Vehicle"
                            : "\(mobileDailyVM.selectedVehical.nickName) \(mobileDailyVM.selectedVehical.plate)"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $mobileDailyVM.showVehicalPicker) {
                VehicalPickerView(
                    dataService: dataService,
                    vehical: $mobileDailyVM.selectedVehical,
                    companyUser: mobileDailyVM.currentCompanyUser
                )
            }
        }
        .workPreviewCard()
    }
    
    private var startMileageInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Mileage", systemImage: "number")
            
            HStack {
                Text("Recent Mileage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(
                    Measurement(
                        value: mobileDailyVM.selectedVehical.miles,
                        unit: UnitLength.miles
                    )
                    .formatted(.measurement(width: .abbreviated))
                )
                .font(.subheadline.weight(.semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Mileage")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                MilesField(text: $mobileDailyVM.inputStartMilage)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            Button {
                mobileDailyVM.showMilage.toggle()
            } label: {
                Label("Submit Mileage", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .workPreviewCard()
    }
        //MARK: endMileageInputCard
    private var endMileageInputCard: some View {
        
        VStack(alignment: .leading, spacing: 14) {
            
            Button {
                submitEndMileageAndStopRoute()
            } label: {
                Label("Submit End Mileage", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmitEndMileage)
            .opacity(canSubmitEndMileage ? 1.0 : 0.55)
            sectionHeader("Mileage", systemImage: "number")
            
            HStack {
                Text("Route Start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(
                    Measurement(
                        value: displayedStartMileageForEnding,
                        unit: UnitLength.miles
                    )
                    .formatted(.measurement(width: .abbreviated))
                )
                .font(.subheadline.weight(.semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("End Mileage")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                MilesField(text: $mobileDailyVM.inputEndMilage)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            if let mileageWarningText {
                Text(mileageWarningText)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
        }
        .workPreviewCard()
    }
    private var parsedEndMileage: Double? {
        Double(
            mobileDailyVM.inputEndMilage
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private var canSubmitEndMileage: Bool {
        guard let endMileage = parsedEndMileage else {
            return false
        }

        if displayedStartMileageForEnding > 0 {
            return endMileage >= displayedStartMileageForEnding
        }

        return endMileage >= 0
    }

    private var mileageWarningText: String? {
        guard let endMileage = parsedEndMileage else {
            return "Enter a valid ending mileage."
        }

        if displayedStartMileageForEnding > 0,
           endMileage < displayedStartMileageForEnding {
            return "Ending mileage cannot be less than starting mileage."
        }

        return nil
    }

    private func submitEndMileageAndStopRoute() {
        guard canSubmitEndMileage else { return }
        guard let route = routeBeingEnded else { return }

        mobileDailyVM.updateRouteEndtMilage(
            companyId: masterDataManager.currentCompany?.id,
            route: route,
            syncSelectedVehicle: route.id == mobileDailyVM.activeRoute?.id
        )

        mobileDailyVM.stopActiveRoute(
            companyId: masterDataManager.currentCompany?.id,
            companyName: masterDataManager.currentCompany?.name,
            user: masterDataManager.user,
            route: route
        )

        routePendingEnd = nil
        mobileDailyVM.showEndMilage = false

        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await loadPreviousWork()
        }
    }
}

// MARK: - Helpers

extension WorkPreviewBasedOnCompany {
    private func dashboardActionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        badgeCount: Int,
        tint: Color,
        disabled: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(disabled ? .black : tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(disabled ? 0.05 : 0.12), in: Circle())

                if badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .padding(2)
                        .background(Color.red, in: Circle())
                        .offset(x: 6, y: -6)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(disabled ? .secondary : .primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            disabled
            ? Color.primary.opacity(0.025)
            : tint.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    badgeCount > 0 ? tint.opacity(0.22) : Color.primary.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
    private func loadDashboardActionCounts() async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            /*
             Replace these two values with your exact dataService methods.

             Examples of what these should represent:

             workOffersNeedingActionCount:
             - offers where receiverId/userId matches current companyUser/user
             - status is pending/open/offered
             - or board posts available to this worker

             shoppingItemsNeedingActionCount:
             - shopping list items with status Need to Purchase
             - optionally include Purchased if install action is needed
            */

            // Temporary safe defaults until wired to dataService.
            workOffersNeedingActionCount = 0
            shoppingItemsNeedingActionCount = 0

            // Example shape once methods exist:
            //
            // if let companyUser = masterDataManager.companyUser {
            //     workOffersNeedingActionCount =
            //         try await dataService.getWorkOffersNeedingActionCount(
            //             companyId: company.id,
            //             companyUserId: companyUser.userId
            //         )
            // }
            //
            // shoppingItemsNeedingActionCount =
            //     try await dataService.getShoppingListItemsNeedingActionCount(
            //         companyId: company.id
            //     )

            _ = company
        } catch {
            print("[WorkPreviewBasedOnCompany][loadDashboardActionCounts] Error")
            print(error)
        }
    }
    private func sectionHeader(
        _ title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func routeStatusBadge(_ status: String) -> some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(getColor(status: status), in: Capsule())
    }

    private func emptyStateRow(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func workerIcon(_ workerType: WorkerTypeEnum) -> String {
        switch workerType {
        case .contractor:
            return "person.crop.circle.badge.checkmark"
        case .employee:
            return "person.crop.circle"
        case .notAssigned:
            return "person.crop.circle.badge.questionmark"
        }
    }

    private func getColor(status: String) -> Color {
        switch status {
        case "In Progress":
            return .orange
        case "Did Not Start":
            return .black.opacity(0.55)
        case "Traveling":
            return .poolBlue
        case "Break":
            return .purple
        case "Finished":
            return .poolGreen
        default:
            return .gray
        }
    }
}

private extension View {
    func workPreviewCard(material: Bool = false) -> some View {
        self
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            }
    }
}
