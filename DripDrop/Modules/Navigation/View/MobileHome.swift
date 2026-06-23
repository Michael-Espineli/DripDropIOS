//
//  MobileHome.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
enum MobileHomeScreenCategories:String {
    case all
    case routing
    case operations
    case finance
    case managment
    case publicView
    case myCompany
    case settings
    case sales
    case marketing
}

struct MobileHome: View {
    
    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject private var masterDataManager : MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var masterRoleManager: MasterRoleManager

    @StateObject private var VM : MobileHomeViewModel
    @Environment(\.scenePhase) private var phase
    @StateObject var termsTemplateVM : TermsTemplateListViewModel
    @StateObject var mobileRouteVM: MobileDailyRouteDisplayViewModel
    @StateObject var fleetVM : FleetViewModel
    @StateObject var techListVM : TechListViewModel
    @StateObject var routeBoardVM: RouteBoardViewModel
    @StateObject var customerVM: CustomerListViewModel
    @StateObject var customerProfileVM: CustomerProfileViewModel

    

    init(dataService:any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: MobileHomeViewModel(dataService: dataService))
        _mobileRouteVM = StateObject(wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService))
        _fleetVM = StateObject(wrappedValue: FleetViewModel(dataService: dataService))
        _termsTemplateVM = StateObject(wrappedValue: TermsTemplateListViewModel(dataService: dataService))
        _techListVM = StateObject(wrappedValue: TechListViewModel(dataService: dataService))
        _routeBoardVM = StateObject(wrappedValue: RouteBoardViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerListViewModel(dataService: dataService))
        _customerProfileVM = StateObject(wrappedValue: CustomerProfileViewModel(dataService: dataService))

    }

    @StateObject private var roleVM = RoleViewModel()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var userAccessVM = UserAccessViewModel()
    @State private var showSettings: Bool = false

    @State private var jobSettingsPicker:String = "Present"
    var body: some View {
        
            ZStack(alignment: .bottomLeading) {
            NavigationStack(path: $navigationManager.routes, root: {
                    TabView(selection: $masterDataManager.tabViewSelection) {
                        ProfileView(dataService: dataService)
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag("Profile")
                            //----------------------------------------
                            //Add Back in During Roll out of Phase 2
                            //----------------------------------------

                        mainDashboard
                            .tabItem {
                                Label("Dashboard", systemImage: "list.dash")
                            }
                            .tag("Dashboard")
                        if masterDataManager.isFeatureEnabled(.iosMessages) {
                            ChatListView(dataService: dataService)
                                .tabItem {
                                    Label("Messages", systemImage: "message")
                                }
                                .tag("Messages")
                        }
                        SettingsView(dataService: dataService)
                            .tabItem {
                                Label("Settings", systemImage: "gear")
                            }
                            .tag("Preferences")
                    }
                .navigationDestination(for: Route.self) { $0 }
            })
            .environmentObject(mobileRouteVM)
            .environmentObject(fleetVM)
            .environmentObject(termsTemplateVM)
            .environmentObject(techListVM)
            .environmentObject(routeBoardVM)
            .environmentObject(customerVM)
            .environmentObject(customerProfileVM)
                if masterDataManager.currentCompany != nil {
                routeDashboardFloatingButton
                }
            }
        .toolbar{
            ToolbarItem{
                Button(action: {
                    self.showSettings.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
            }
        }
//        .navigationTitle("Mobile Home")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbarBackground(.blue)

        .task {
            #warning("Please add listeners to get user access and role")
//            masterRoleManager.start(companyId: masterDataManager.currentCompany?.id, userId: masterDataManager.user?.id)
            await masterDataManager.loadFeatureFlags()
            
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                do{
                    try await userAccessVM.getUserAccessCompanies(userId: user.id, companyId: company.id)
                    if let access = userAccessVM.userAccess{
                        print("[MobileHome][task] \(access)")
                        try await roleVM.getSpecificRole(companyId: company.id, roleId: access.roleId)
                        if let role = roleVM.role {
                            masterDataManager.role = role
                        } else {
                            masterDataManager.showSignInView = true
                        }
                    } else {
                        masterDataManager.showSignInView = true
                    }
                } catch {
                    print("[MobileHome][task]Error 1 Mobile Home")
                    print(error)
                    
                }
                do {
                    try await userAccessVM.getAllUserAvailableCompanies(userId: user.id)
                    try await userAccessVM.getCompaniesFromAccess(accessList: userAccessVM.allAvailableAccess)
                    masterDataManager.allCompanies = userAccessVM.companies
                } catch {
                    print("Error 2 Mobile Home")
                    
                    print(error)
                }
            }
             
        }
        
        .onChange(of: masterRoleManager.role) { role in
            masterDataManager.role = role
            
        }
        .onDisappear(perform: {
            masterRoleManager.stop()
        })
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: background()
            case .active: foreground()
            default: break
            }
        }
        
        .onChange(of: navigationManager.routes,
                  perform: {
            routes in
            Task{
                if let user = masterDataManager.user,
                   let company = masterDataManager.currentCompany,
                   let selectedCategory = masterDataManager.selectedCategory,
                   
                    let route = routes.last {
                    do {
                        let routeString = convertRouteToString(route: route)
                        let itemId:String = masterDataManager.selectedID ?? ""//Developer Figure out how to get the selectedID
                        try await userVM.addRecentActivity(
                            userId: user.id,
                            recentActivity: RecentActivityModel(
                                id: routeString.rawValue+itemId,
                                companyId: company.id,
                                category: selectedCategory,
                                route: routeString,
                                itemId: itemId,
                                name: "",
                                date: Date())
                        )
                    } catch {
                        print(error)
                    }
                }
            }
        })
    }
    func background() {
        print("App Entering Background From Mobile Home")
    }
    func foreground() {
        print("App Entering Foreground From Mobile Home")
        let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        print(timer)
    }
    private var routeDashboardFloatingButton: some View {
        Button {
            masterDataManager.tabViewSelection = "Dashboard"
            masterDataManager.mobileHomeScreen = .routing
            navigationManager.replace(stack: [Route.employeeMainDailyDisplayView(dataService: dataService)])
  
        } label: {
            Image(systemName: "map.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.black.opacity(0.22), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.bottom, 72)
        .accessibilityLabel("Back to route dashboard")
    }
}

private struct MobileReimaginedMainDashboard: View {
    let dataService: any ProductionDataServiceProtocol

    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var routeVM: MobileDailyRouteDisplayViewModel

    @StateObject private var repairRequestVM: RepairRequestViewModel
    @StateObject private var jobVM: JobViewModel
    @StateObject private var alertVM: CompanyAlertViewModel
    @State private var isLoading: Bool = false

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _alertVM = StateObject(wrappedValue: CompanyAlertViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if masterDataManager.currentCompany == nil {
                NoCompanySelectedView(dataService: dataService)
            } else {
                VStack(spacing: 0) {
                    workAreaSelector
                    selectedWorkAreaContent
                }
                .overlay(alignment: .topTrailing) {
                    if isLoading {
                        ProgressView()
                            .padding(12)
                    }
                }
            }
        }
        .task(id: dashboardLoadIdentity) {
            await startDashboardListeners()
        }
        .onDisappear {
            repairRequestVM.removeListenerForRepairRequest()
            jobVM.removeListenerForJob()
        }
    }

    private var workAreaSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableWorkAreas, id: \.rawValue) { area in
                    workAreaButton(area)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var selectedWorkAreaContent: some View {
        switch masterDataManager.mobileHomeScreen {
        case .routing, .all:
            reimaginedDashboardOverview
        case .operations:
            FeatureFlaggedOperationsSectionView(dataService: dataService)
        case .sales:
            FeatureFlaggedSalesSectionView(dataService: dataService)
        case .marketing:
            FeatureFlaggedMarketingSectionView(dataService: dataService)
        case .finance:
            FeatureFlaggedFinanceSectionView(dataService: dataService)
        case .managment:
            FeatureFlaggedManagementSectionView(dataService: dataService)
        case .publicView:
            MarketPlaceView(dataService: dataService)
        case .myCompany:
            MyCompany(dataService: dataService)
        case .settings:
            FeatureFlaggedCompanySettingsSectionView(dataService: dataService)
        }
    }

    private var reimaginedDashboardOverview: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    heroHeader
                    todaysRouteCard
                    if shouldShowAlertsSection {
                        alertsOverviewSection
                    }
                    quickActionsGrid
                    technicianRepairRequestsSection
                    assignedJobsSection

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title3.weight(.semibold))

                    Text(masterDataManager.currentCompany?.name ?? "Drip Drop")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(weekDay(date: Date()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.poolBlue, in: Capsule())
            }

            HStack(spacing: 10) {
                summaryMetric(
                    title: "Route",
                    value: "\(routeFinishedCount)/\(routeTotalCount)",
                    systemImage: "map",
                    tint: .poolGreen
                )

                summaryMetric(
                    title: "Pending",
                    value: "\(pendingRepairRequests.count)",
                    systemImage: "wrench.adjustable.fill",
                    tint: .orange
                )

                summaryMetric(
                    title: "Jobs",
                    value: "\(visibleAssignedJobs.count)",
                    systemImage: "briefcase.fill",
                    tint: .poolBlue
                )
            }
        }
        .mobileMainCard(material: true)
    }

    private var todaysRouteCard: some View {
        NavigationLink(value: Route.employeeMainDailyDisplayView(dataService: dataService)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    routeProgressRing

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Today's Route")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(routeSummaryText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 8) {
                    Label("List", systemImage: "list.bullet.rectangle")
                    Label("Calendar", systemImage: "calendar.day.timeline.left")
                    Spacer()
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .mobileMainCard()
        }
        .buttonStyle(.plain)
    }

    private var alertsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(
                title: "Alerts",
                subtitle: "\(dashboardAlerts.count) item\(dashboardAlerts.count == 1 ? "" : "s") need attention.",
                systemImage: "bell.badge.fill"
            )

            VStack(spacing: 8) {
                ForEach(dashboardAlerts) { alert in
                    NavigationLink(value: Route.companyAlerts(dataService: dataService)) {
                        alertRow(alert)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(value: Route.companyAlerts(dataService: dataService)) {
                    HStack {
                        Text("View all alerts")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.poolBlue)
                    .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }
        }
        .mobileMainCard()
    }

    private func workAreaButton(_ area: MobileHomeScreenCategories) -> some View {
        let isSelected = masterDataManager.mobileHomeScreen == area

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                masterDataManager.mobileHomeScreen = area
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: workAreaIcon(area))
                    .font(.caption.weight(.semibold))

                Text(workAreaTitle(area))
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: quickActionColumns, spacing: 10) {
            quickAction(
                title: "Shopping",
                subtitle: "Items to buy",
                systemImage: "cart",
                tint: .poolGreen,
                route: .shoppingList(dataService: dataService)
            )

            quickAction(
                title: "Repair",
                subtitle: "Create request",
                systemImage: "wrench.adjustable.fill",
                tint: .orange,
                route: .createRepairRequest(dataService: dataService)
            )

            quickAction(
                title: "Jobs",
                subtitle: "Work orders",
                systemImage: "briefcase",
                tint: .poolBlue,
                route: .jobs(dataService: dataService)
            )

            quickAction(
                title: "Route",
                subtitle: "Today",
                systemImage: "map",
                tint: .purple,
                route: .employeeMainDailyDisplayView(dataService: dataService)
            )
        }
    }

    private var technicianRepairRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Pending Repair Requests",
                subtitle: "\(pendingRepairRequests.count) pending from you",
                systemImage: "wrench.and.screwdriver",
                route: .repairRequestList(dataService: dataService)
            )

            if pendingRepairRequests.isEmpty {
                emptyRow(
                    title: "No pending repair requests",
                    message: "Open requests you create will show here.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(pendingRepairRequests.prefix(4))) { request in
                        NavigationLink(value: Route.repairRequest(repairRequest: request, dataService: dataService)) {
                            repairRequestRow(request)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .mobileMainCard()
    }

    private var assignedJobsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Jobs I'm In Charge Of",
                subtitle: "\(visibleAssignedJobs.count) assigned to you",
                systemImage: "person.badge.key.fill",
                route: .jobs(dataService: dataService)
            )

            if visibleAssignedJobs.isEmpty {
                emptyRow(
                    title: "No assigned jobs",
                    message: "Jobs where you are the admin will show here.",
                    systemImage: "briefcase"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(visibleAssignedJobs.prefix(4))) { job in
                        NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                            jobRow(job)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .mobileMainCard()
    }

    private var routeProgressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.10), lineWidth: 7)

            Circle()
                .trim(from: 0, to: routeProgress)
                .stroke(Color.poolGreen, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text("\(routeFinishedCount)")
                    .font(.subheadline.weight(.bold))
                Text("of \(routeTotalCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 66, height: 66)
    }

    private func workAreaTile(_ area: MobileHomeScreenCategories) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                masterDataManager.mobileHomeScreen = area
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: workAreaIcon(area))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(workAreaTint(area))
                    .frame(width: 34, height: 34)
                    .background(workAreaTint(area).opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(workAreaTitle(area))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(workAreaSubtitle(area))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func quickAction(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        route: Route
    ) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
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

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        route: Route
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
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

            NavigationLink(value: route) {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func repairRequestRow(_ request: RepairRequest) -> some View {
        HStack(spacing: 11) {
            statusDot(color: repairRequestColor(request.status))

            VStack(alignment: .leading, spacing: 4) {
                Text(request.customerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(request.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(request.status.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(repairRequestColor(request.status))

                Text(shortDate(date: request.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func alertRow(_ alert: DripDropAlert) -> some View {
        HStack(alignment: .top, spacing: 11) {
            statusDot(color: .poolRed)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(alert.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(alert.category.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.poolRed)
                    .lineLimit(1)

                Text(shortDate(date: alert.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.poolRed.opacity(0.075), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func jobRow(_ job: Job) -> some View {
        HStack(spacing: 11) {
            statusDot(color: jobOperationColor(job.operationStatus))

            VStack(alignment: .leading, spacing: 4) {
                Text(job.customerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(job.internalId) • \(job.type)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(job.operationStatus.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(jobOperationColor(job.operationStatus))

                Text(shortDate(date: job.dateCreated))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryMetric(
        title: String,
        value: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.headline.weight(.bold))

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func emptyRow(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 11) {
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
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func statusDot(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.12), in: Circle())
    }

    private var dashboardLoadIdentity: String {
        "\(masterDataManager.currentCompany?.id ?? "no-company")-\(masterDataManager.user?.id ?? "no-user")-\(masterDataManager.featureFlagsLoaded)-\(masterDataManager.isFeatureEnabled(.alertsAndNotifications))"
    }

    private var quickActionColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var dashboardAlerts: [DripDropAlert] {
        alertVM.alertList
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    private var shouldShowAlertsSection: Bool {
        masterDataManager.isFeatureEnabled(.alertsAndNotifications) && !dashboardAlerts.isEmpty
    }

    private var availableWorkAreas: [MobileHomeScreenCategories] {
        guard let role = masterDataManager.role else {
            return [.routing]
        }

        let orderedAreas = orderedNavigationCategories.compactMap { mobileWorkArea(for: $0) }
        let areas = [.routing] + orderedAreas.filter { $0 != .routing }
        return areas.filter { areaIsAvailable($0, role: role) }.uniqueByRawValue()
    }

    private var frontPageWorkAreas: [MobileHomeScreenCategories] {
        availableWorkAreas.filter { $0 != .routing && $0 != .all }
    }

    private var orderedNavigationCategories: [String] {
        let defaultOrder = [
            "Operations",
            "Management",
            "Finance",
            "Marketing",
            "Settings"
        ]
        let savedOrder = (masterDataManager.user?.settings?.companyNavigationCategoryOrder ?? []).compactMap { category -> String? in
            switch category {
            case "Users":
                return "Management"
            case "Routing", "Migration":
                return nil
            default:
                return category
            }
        }
        let merged = savedOrder.filter { defaultOrder.contains($0) } + defaultOrder.filter { !savedOrder.contains($0) }
        var seen: Set<String> = []

        return merged.filter { category in
            guard !seen.contains(category) else { return false }
            seen.insert(category)
            return true
        }
    }

    private func mobileWorkArea(for category: String) -> MobileHomeScreenCategories? {
        switch category {
        case "Routing":
            return .routing
        case "Operations":
            return .operations
        case "Finance":
            return .finance
        case "Marketing":
            return .marketing
        case "Management":
            return .managment
        case "Settings":
            return .settings
        default:
            return nil
        }
    }

    private func areaIsAvailable(_ area: MobileHomeScreenCategories, role: Role) -> Bool {
        switch area {
        case .all, .routing:
            return true
        case .operations:
            return role.permissionIdList.contains("0")
        case .finance:
            return role.permissionIdList.contains("400")
        case .marketing:
            return masterDataManager.isFeatureEnabled(.marketing)
        case .managment:
            return role.permissionIdList.contains("200")
        case .publicView, .myCompany:
            return true
        case .settings:
            return role.permissionIdList.contains("800")
        case .sales:
            return role.permissionIdList.contains("400") && masterDataManager.isFeatureEnabled(.sales)
        }
    }

    private func workAreaTitle(_ area: MobileHomeScreenCategories) -> String {
        switch area {
        case .all:
            return "Dashboard"
        case .routing:
            return "Route"
        case .operations:
            return "Operations"
        case .finance:
            return "Finance"
        case .managment:
            return "Management"
        case .publicView:
            return "Market"
        case .myCompany:
            return "Company"
        case .settings:
            return "Settings"
        case .sales:
            return "Sales"
        case .marketing:
            return "Marketing"
        }
    }

    private func workAreaIcon(_ area: MobileHomeScreenCategories) -> String {
        switch area {
        case .all:
            return "square.grid.2x2"
        case .routing:
            return "map"
        case .operations:
            return "wrench.and.screwdriver"
        case .finance:
            return "dollarsign.circle"
        case .managment:
            return "person.3"
        case .publicView:
            return "storefront"
        case .myCompany:
            return "building.2"
        case .settings:
            return "gearshape"
        case .sales:
            return "chart.line.uptrend.xyaxis"
        case .marketing:
            return "megaphone"
        }
    }

    private func workAreaSubtitle(_ area: MobileHomeScreenCategories) -> String {
        switch area {
        case .all:
            return "Overview"
        case .routing:
            return "Route board"
        case .operations:
            return "Jobs and work"
        case .finance:
            return "Billing"
        case .managment:
            return "Team tools"
        case .publicView:
            return "Marketplace"
        case .myCompany:
            return "Company profile"
        case .settings:
            return "Company setup"
        case .sales:
            return "Sales pipeline"
        case .marketing:
            return "Leads and public page"
        }
    }

    private func workAreaTint(_ area: MobileHomeScreenCategories) -> Color {
        switch area {
        case .all, .routing:
            return .poolGreen
        case .operations:
            return .orange
        case .finance:
            return .poolBlue
        case .managment:
            return .purple
        case .publicView, .sales, .marketing:
            return .poolYellow
        case .myCompany:
            return .teal
        case .settings:
            return .gray
        }
    }

    private var visibleRepairRequests: [RepairRequest] {
        let userId = masterDataManager.user?.id ?? ""
        return repairRequestVM.listOfContrats
            .filter { userId.isEmpty || $0.requesterId == userId }
            .sorted { $0.date > $1.date }
    }

    private var pendingRepairRequests: [RepairRequest] {
        visibleRepairRequests.filter { $0.status.isOpenWorkQueueItem }
    }

    private var visibleAssignedJobs: [Job] {
        let userId = masterDataManager.user?.id ?? ""
        return jobVM.workOrders
            .filter { userId.isEmpty || $0.adminId == userId }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    private var routeFinishedCount: Int {
        routeVM.activeRoute?.finishedStops ?? routeVM.serviceStopList.filter { $0.operationStatus == .finished }.count
    }

    private var routeTotalCount: Int {
        routeVM.activeRoute?.totalStops ?? routeVM.serviceStopList.count
    }

    private var routeProgress: CGFloat {
        guard routeTotalCount > 0 else { return 0 }
        return CGFloat(routeFinishedCount) / CGFloat(routeTotalCount)
    }

    private var routeSummaryText: String {
        guard routeTotalCount > 0 else {
            return "No stops are scheduled for today."
        }

        return "\(routeFinishedCount) of \(routeTotalCount) stops complete. Open the route to use the list or calendar view."
    }

    private var greeting: String {
        let name = masterDataManager.user?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Today" : "Today, \(name)"
    }

    private var listenerDateWindow: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let end = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        return (start, end)
    }

    private func startDashboardListeners() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else { return }

        isLoading = true
        routeVM.start(companyId: company.id, user: user, date: Date())

        let window = listenerDateWindow
        repairRequestVM.addListenerForAllRequests(
            companyId: company.id,
            status: [],
            requesterIds: [user.id],
            startDate: window.start,
            endDate: window.end
        )
        jobVM.addListenerForAllJobsOperations(
            companyId: company.id,
            status: [],
            requesterIds: [user.id],
            startDate: window.start,
            endDate: window.end
        )

        if masterDataManager.isFeatureEnabled(.alertsAndNotifications) {
            do {
                try await alertVM.getAlertsByCompany(companyId: company.id)
            } catch {
                print("[MobileReimaginedMainDashboard][startDashboardListeners][alerts]")
                print(error)
            }
        }

        isLoading = false
    }

    private func repairRequestColor(_ status: RepairRequestStatus) -> Color {
        switch status {
        case .resolved:
            return .poolGreen
        case .unresolved, .cancelled, .legacyPending, .legacyPendingCapitalized:
            return .poolRed
        case .convertedToJob:
            return .gray
        case .inprogress:
            return .orange
        }
    }

    private func jobOperationColor(_ status: JobOperationStatus) -> Color {
        switch status {
        case .estimatePending, .waitingForParts:
            return .poolRed
        case .unscheduled:
            return .orange
        case .scheduled, .inProgress:
            return .poolBlue
        case .finished:
            return .poolGreen
        }
    }
}

struct FeatureFlaggedOperationsSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedOperationsSectionView(dataService: dataService)
        } else {
            Operations(dataService: dataService)
        }
    }
}

struct FeatureFlaggedSalesSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedSalesSectionView(dataService: dataService)
        } else {
            OwesMoneyView(dataService: dataService)
        }
    }
}

struct FeatureFlaggedMarketingSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedMarketingSectionView(dataService: dataService)
        } else {
            OwesMoneyView(dataService: dataService)
        }
    }
}

struct FeatureFlaggedSalesRouteView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedSalesSectionView(dataService: dataService)
        } else {
            SalesFinanceView(dataService: dataService)
        }
    }
}

struct FeatureFlaggedFinanceSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedFinanceSectionView(dataService: dataService)
        } else {
            Finance(dataService: dataService)
        }
    }
}

struct FeatureFlaggedManagementSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedManagementSectionView(dataService: dataService)
        } else {
            Managment(dataService: dataService)
        }
    }
}

struct FeatureFlaggedCompanySettingsSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
            MobileReimaginedCompanySettingsSectionView(dataService: dataService)
        } else {
            CompanySettings(dataService: dataService)
        }
    }
}

struct MobileReimaginedOperationsSectionView: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Operations",
            subtitle: "Customer work, stops, jobs, repairs, and field activity.",
            systemImage: "wrench.and.screwdriver.fill",
            tint: .orange,
            requiredPermissionId: "0",
            unavailableTitle: "No operations access.",
            unavailableMessage: "Your role does not currently include operations permissions.",
            items: [
                MobileReimaginedSectionItem(
                    title: "Customers",
                    subtitle: "Accounts and service locations",
                    systemImage: "person.2.fill",
                    tint: .poolBlue,
                    route: .customers(dataService: dataService),
                    permissionId: "10"
                ),
                MobileReimaginedSectionItem(
                    title: "Jobs",
                    subtitle: "Work orders and estimates",
                    systemImage: "briefcase.fill",
                    tint: .poolGreen,
                    route: .jobs(dataService: dataService),
                    permissionId: "20"
                ),
                MobileReimaginedSectionItem(
                    title: "Repair Requests",
                    subtitle: "Open and pending repairs",
                    systemImage: "wrench.adjustable.fill",
                    tint: .orange,
                    route: .repairRequestList(dataService: dataService),
                    permissionId: "30"
                ),
                MobileReimaginedSectionItem(
                    title: "Service Stops",
                    subtitle: "Route stops and field work",
                    systemImage: "mappin.and.ellipse",
                    tint: .purple,
                    route: .serviceStops(dataService: dataService),
                    permissionId: "240"
                ),
                MobileReimaginedSectionItem(
                    title: "Equipment",
                    subtitle: "Installed equipment records",
                    systemImage: "spigot.fill",
                    tint: .teal,
                    route: .equipmentList(dataService: dataService),
                    permissionId: "60"
                ),
                MobileReimaginedSectionItem(
                    title: "Shopping List",
                    subtitle: "Parts and supplies to buy",
                    systemImage: "cart.fill",
                    tint: .poolYellow,
                    route: .shoppingList(dataService: dataService)
                )
            ]
        )
    }
}

struct MobileReimaginedSalesSectionView: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Sales Dashboard",
            subtitle: "Billing review and customer revenue.",
            systemImage: "chart.line.uptrend.xyaxis",
            tint: .poolYellow,
            requiredPermissionId: "400",
            requiresSalesFlag: true,
            unavailableTitle: "Sales dashboard unavailable.",
            unavailableMessage: "Sales is currently off or your role does not include sales access.",
            items: [
                MobileReimaginedSectionItem(
                    title: "Finished Jobs",
                    subtitle: "Ready for billing review",
                    systemImage: "checkmark.seal.fill",
                    tint: .poolGreen,
                    route: .billingJobs(dataService: dataService),
                    permissionId: "410"
                )
            ]
        )
    }
}

struct MobileReimaginedMarketingSectionView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Marketing",
            subtitle: "Leads and your public company page.",
            systemImage: "megaphone.fill",
            tint: .poolYellow,
            requiredPermissionId: nil,
            unavailableTitle: "Marketing unavailable.",
            unavailableMessage: "Marketing is currently off by feature flag 7.",
            items: marketingItems
        )
    }

    private var marketingItems: [MobileReimaginedSectionItem] {
        [
            MobileReimaginedSectionItem(
                title: "Leads",
                subtitle: "New customer requests and follow up",
                systemImage: "person.crop.circle.badge.plus",
                tint: .poolYellow,
                route: .leads(dataService: dataService),
                permissionId: "610",
                featureFlag: .marketing
            ),
            MobileReimaginedSectionItem(
                title: "Public Page",
                subtitle: "Public company profile",
                systemImage: "storefront.fill",
                tint: .teal,
                route: publicPageRoute,
                featureFlag: .marketing,
                isPlaceholder: publicPageRoute == nil
            )
        ]
    }

    private var publicPageRoute: Route? {
        guard let company = masterDataManager.currentCompany else {
            return nil
        }

        return .companyPublicProfile(company: company, dataService: dataService)
    }
}

struct MobileReimaginedFinanceSectionView: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Finance",
            subtitle: "Estimates, agreements, invoices, payments, billing subscriptions, and payroll.",
            systemImage: "dollarsign.circle.fill",
            tint: .poolBlue,
            requiredPermissionId: "400",
            unavailableTitle: "No finance access.",
            unavailableMessage: "Your role does not currently include finance permissions.",
            items: [
                MobileReimaginedSectionItem(
                    title: "Estimates",
                    subtitle: "Estimate list and approvals",
                    systemImage: "doc.text.magnifyingglass",
                    tint: .pink,
                    permissionId: "620",
                    featureFlag: .marketing,
                    isPlaceholder: true
                ),
                MobileReimaginedSectionItem(
                    title: "Service Agreements",
                    subtitle: "Recurring service agreements",
                    systemImage: "doc.text.fill",
                    tint: .poolGreen,
                    route: .contracts(dataService: dataService),
                    requiresSalesFlag: true
                ),
                MobileReimaginedSectionItem(
                    title: "Invoices",
                    subtitle: "Sales invoices",
                    systemImage: "receipt.fill",
                    tint: .purple,
                    route: .invoices(dataService: dataService),
                    requiresSalesFlag: true
                ),
                MobileReimaginedSectionItem(
                    title: "Payment History",
                    subtitle: "Sales payment records",
                    systemImage: "creditcard.fill",
                    tint: .pink,
                    requiresSalesFlag: true,
                    isPlaceholder: true
                ),
                MobileReimaginedSectionItem(
                    title: "Billing Subscriptions",
                    subtitle: "Customer billing subscriptions",
                    systemImage: "repeat.circle.fill",
                    tint: .pink,
                    requiresSalesFlag: true,
                    isPlaceholder: true
                ),
                MobileReimaginedSectionItem(
                    title: "Payroll",
                    subtitle: "Technician pay and exports",
                    systemImage: "person.crop.circle.badge.dollar",
                    tint: .poolGreen,
                    route: .payRoll(dataService: dataService),
                    featureFlag: .payroll
                )
            ]
        )
    }
}

struct MobileReimaginedManagementSectionView: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Management",
            subtitle: "Routing, users, vendors, work logs, and fleet operations.",
            systemImage: "person.3.fill",
            tint: .purple,
            requiredPermissionId: "200",
            unavailableTitle: "No management access.",
            unavailableMessage: "Your role does not currently include management permissions.",
            items: [
                MobileReimaginedSectionItem(
                    title: "Routes",
                    subtitle: "Route teams and assignments",
                    systemImage: "map.fill",
                    tint: .poolBlue,
                    route: .routes(dataService: dataService),
                    permissionId: "210"
                ),
                MobileReimaginedSectionItem(
                    title: "Active Routes",
                    subtitle: "Internal route overview",
                    systemImage: "map.circle.fill",
                    tint: .orange,
                    route: .companyRouteOverView(dataService: dataService),
                    permissionId: "210"
                ),
                MobileReimaginedSectionItem(
                    title: "Users",
                    subtitle: "Directory and roles",
                    systemImage: "person.3.fill",
                    tint: .purple,
                    route: .users(dataService: dataService),
                    permissionId: "260"
                ),
                MobileReimaginedSectionItem(
                    title: "Work Logs",
                    subtitle: "Time and work history",
                    systemImage: "clock.arrow.circlepath",
                    tint: .teal,
                    route: .workLogList(dataService: dataService),
                    permissionId: "280"
                ),
                MobileReimaginedSectionItem(
                    title: "Vendors",
                    subtitle: "Suppliers and purchase contacts",
                    systemImage: "building.2.fill",
                    tint: .poolGreen,
                    route: .venders(dataService: dataService)
                ),
                MobileReimaginedSectionItem(
                    title: "Fleet",
                    subtitle: "Vehicles and drivers",
                    systemImage: "car.fill",
                    tint: .gray,
                    route: .fleet(dataService: dataService),
                    permissionId: "290"
                )
            ]
        )
    }
}

struct MobileReimaginedCompanySettingsSectionView: View {
    let dataService: any ProductionDataServiceProtocol

    var body: some View {
        MobileReimaginedSectionHub(
            title: "Settings",
            subtitle: "Company setup, permissions, billing defaults, templates, and payroll setup.",
            systemImage: "gearshape.fill",
            tint: .gray,
            requiredPermissionId: "800",
            unavailableTitle: "No settings access.",
            unavailableMessage: "Your role does not currently include company settings permissions.",
            items: [
                MobileReimaginedSectionItem(
                    title: "Subscriptions",
                    subtitle: "Plan and billing status",
                    systemImage: "creditcard.fill",
                    tint: .poolBlue,
                    route: .manageSubscriptions(dataService: dataService),
                    permissionId: "890"
                ),
                MobileReimaginedSectionItem(
                    title: "Company Info",
                    subtitle: "Profile and contact details",
                    systemImage: "building.2.fill",
                    tint: .poolGreen,
                    route: .companyInfo(dataService: dataService),
                    permissionId: "810"
                ),
                MobileReimaginedSectionItem(
                    title: "Email",
                    subtitle: "Outbound email setup",
                    systemImage: "envelope.fill",
                    tint: .orange,
                    route: .emailConfiguration(dataService: dataService),
                    permissionId: "830"
                ),
                MobileReimaginedSectionItem(
                    title: "Reports",
                    subtitle: "Company reporting",
                    systemImage: "chart.bar.fill",
                    tint: .purple,
                    route: .reports(dataService: dataService),
                    permissionId: "870"
                ),
                MobileReimaginedSectionItem(
                    title: "Task Groups",
                    subtitle: "Reusable task templates",
                    systemImage: "checklist",
                    tint: .teal,
                    route: .taskGroups(dataService: dataService),
                    permissionId: "820"
                ),
                MobileReimaginedSectionItem(
                    title: "Readings & Dosages",
                    subtitle: "Chemistry presets",
                    systemImage: "drop.fill",
                    tint: .poolBlue,
                    route: .readingsAndDosages(dataService: dataService),
                    permissionId: "840"
                ),
                MobileReimaginedSectionItem(
                    title: "Database Items",
                    subtitle: "Parts, chemicals, and items",
                    systemImage: "shippingbox.fill",
                    tint: .poolYellow,
                    route: .databaseItems(dataService: dataService),
                    permissionId: "850"
                ),
                MobileReimaginedSectionItem(
                    title: "User Roles",
                    subtitle: "Permissions and access",
                    systemImage: "person.badge.key.fill",
                    tint: .purple,
                    route: .userRoles(dataService: dataService),
                    permissionId: "860"
                ),
                MobileReimaginedSectionItem(
                    title: "Job Templates",
                    subtitle: "Reusable job layouts",
                    systemImage: "doc.on.doc.fill",
                    tint: .poolGreen,
                    route: .jobTemplates(dataService: dataService)
                ),
                MobileReimaginedSectionItem(
                    title: "Terms Templates",
                    subtitle: "Estimate and invoice terms",
                    systemImage: "doc.text.fill",
                    tint: .orange,
                    route: .manageTermsTemplates(dataService: dataService),
                    permissionId: "880"
                ),
                MobileReimaginedSectionItem(
                    title: "Payroll Settings",
                    subtitle: "Pay rules and defaults",
                    systemImage: "person.crop.circle.badge.dollar",
                    tint: .teal,
                    route: .payRollSettings(dataService: dataService),
                    permissionId: "880"
                )
            ]
        )
    }
}

private struct MobileReimaginedSectionItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let route: Route?
    let permissionId: String?
    let requiresSalesFlag: Bool
    let featureFlag: FeatureFlagKey?
    let isPlaceholder: Bool

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        route: Route? = nil,
        permissionId: String? = nil,
        requiresSalesFlag: Bool = false,
        featureFlag: FeatureFlagKey? = nil,
        isPlaceholder: Bool = false
    ) {
        self.id = title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.route = route
        self.permissionId = permissionId
        self.requiresSalesFlag = requiresSalesFlag
        self.featureFlag = featureFlag
        self.isPlaceholder = isPlaceholder
    }
}

private struct MobileReimaginedSectionHub: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let requiredPermissionId: String?
    let requiresSalesFlag: Bool
    let unavailableTitle: String
    let unavailableMessage: String
    let items: [MobileReimaginedSectionItem]

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        requiredPermissionId: String?,
        requiresSalesFlag: Bool = false,
        unavailableTitle: String,
        unavailableMessage: String,
        items: [MobileReimaginedSectionItem]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.requiredPermissionId = requiredPermissionId
        self.requiresSalesFlag = requiresSalesFlag
        self.unavailableTitle = unavailableTitle
        self.unavailableMessage = unavailableMessage
        self.items = items
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader

                    if !masterDataManager.featureFlagsLoaded {
                        emptyState(
                            title: "Loading feature flags.",
                            message: "This section will appear after feature flags load.",
                            systemImage: "flag"
                        )
                    } else if !isSalesFeatureAvailable {
                        emptyState(
                            title: "Sales unavailable.",
                            message: "Sales is currently turned off by feature flag 4.",
                            systemImage: "flag.slash"
                        )
                    } else if !hasSectionAccess {
                        emptyState(
                            title: unavailableTitle,
                            message: unavailableMessage,
                            systemImage: "lock.shield"
                        )
                    } else if visibleItems.isEmpty {
                        emptyState(
                            title: "No tools available.",
                            message: "More tools appear here when your role has access.",
                            systemImage: "square.grid.2x2"
                        )
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(visibleItems) { item in
                                if let route = item.route, !item.isPlaceholder {
                                    NavigationLink(value: route) {
                                        sectionTile(item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    sectionTile(item)
                                        .accessibilityHint("Placeholder. This mobile section has not been built yet.")
                                }
                            }
                        }
                    }

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("Flag 14", systemImage: "flag.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(tint.opacity(0.12), in: Capsule())

                if let role = masterDataManager.role {
                    Label("\(role.permissionIdList.count) Permissions", systemImage: "lock.shield")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionTile(_ item: MobileReimaginedSectionItem) -> some View {
        let tileTint = item.isPlaceholder ? Color.pink : item.tint

        return HStack(alignment: .top, spacing: 11) {
            Image(systemName: item.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tileTint)
                .frame(width: 38, height: 38)
                .background(tileTint.opacity(0.13), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if item.isPlaceholder {
                    Text("Needs mobile build")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.pink)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: item.isPlaceholder ? "hammer.fill" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(item.isPlaceholder ? Color.pink : Color.secondary.opacity(0.55))
                .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
        .background(
            item.isPlaceholder ? AnyShapeStyle(Color.pink.opacity(0.08)) : AnyShapeStyle(.background),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.isPlaceholder ? Color.pink.opacity(0.45) : Color.primary.opacity(0.07), lineWidth: 1)
        }
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var visibleItems: [MobileReimaginedSectionItem] {
        guard let role = masterDataManager.role else {
            return []
        }

        return items.filter { item in
            if item.isPlaceholder && !shouldShowDevelopmentPlaceholders {
                return false
            }

            let hasPermission = item.permissionId.map { role.permissionIdList.contains($0) } ?? true
            let hasSalesFlag = !item.requiresSalesFlag || masterDataManager.isFeatureEnabled(.sales)
            let hasFeatureFlag = item.featureFlag.map { masterDataManager.isFeatureEnabled($0) } ?? true
            return hasPermission && hasSalesFlag && hasFeatureFlag
        }
    }

    private var shouldShowDevelopmentPlaceholders: Bool {
        #if DEBUG
        return AppEnvironment.current == .dev
        #else
        return false
        #endif
    }

    private var hasSectionAccess: Bool {
        guard let requiredPermissionId else {
            return true
        }

        return masterDataManager.role?.permissionIdList.contains(requiredPermissionId) == true
    }

    private var isSalesFeatureAvailable: Bool {
        !requiresSalesFlag || masterDataManager.isFeatureEnabled(.sales)
    }

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }
}

private extension Array where Element == MobileHomeScreenCategories {
    func uniqueByRawValue() -> [Element] {
        var seen: Set<String> = []

        return filter { element in
            guard !seen.contains(element.rawValue) else { return false }
            seen.insert(element.rawValue)
            return true
        }
    }
}

private extension View {
    func mobileMainCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }
}
struct MobileHome_Previews: PreviewProvider {
    static let dataService = MockDataService()
    static var previews: some View {
        MobileHome(dataService: dataService)
    }
    
}
extension MobileHome {
    var mainDashboard: some View {
        Group {
            if masterDataManager.isFeatureEnabled(.iosReimaginedMain) {
                MobileReimaginedMainDashboard(dataService: dataService)
            } else {
                legacyMainDashboard
            }
        }
    }

    private var legacyMainDashboard: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if masterDataManager.currentCompany == nil {
                    NoCompanySelectedView(dataService:dataService)
                } else {
                    header
                    ScrollView{
                        screens
                    }
                    Spacer()
                }
            }
        }
    }
    var header: some View {
        ZStack{
            if let role = masterDataManager.role {
                    HStack(spacing: 10){
                        VStack{
                            HStack{
                                if let selectedCompany = masterDataManager.currentCompany{
                                    Text("\(selectedCompany.name)")
                                        .bold()
                                        .fontDesign(.monospaced)
                                    Spacer()
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack{
                                    /*
                                     Roll Out In Update 3.1
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .all
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .all {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                     .frame(minWidth: 50)
                                            .modifier(BlueButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Dashboard")
                                            }
                                            
                                     .frame(minWidth: 50)
                                            .modifier(ListButtonModifier())
                                        }
                                    })
                                     */
                                    Button(action: {
                                        masterDataManager.mobileHomeScreen = .routing
                                    }, label: {
                                        if masterDataManager.mobileHomeScreen == .routing {
                                            HStack{
                                                Text("Route")
                                            }
                                            .modifier(EditButtonModifier())
                                            .bold()
                                        } else {
                                            HStack{
                                                Text("Route")
                                            }
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(Color.poolWhite)
                                            .foregroundColor(.poolBlack)
                                            .cornerRadius(12)
                                            .bold()
                                        }
                                    })
                                    if role.permissionIdList.contains("0") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .operations
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .operations {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .modifier(EditButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Operations")
                                                }
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.poolWhite)
                                                .foregroundColor(.poolBlack)
                                                .cornerRadius(12)
                                                .bold()
                                            }
                                        })
                                    }
                                    if role.permissionIdList.contains("400") {
                                        if role.permissionIdList.contains("200") {
                                            Button(action: {
                                                masterDataManager.mobileHomeScreen = .managment
                                            }, label: {
                                                if masterDataManager.mobileHomeScreen == .managment {
                                                    HStack{
                                                        Text("Management")
                                                    }
                                                    .modifier(EditButtonModifier())
                                                    .bold()
                                                } else {
                                                    HStack{
                                                        Text("Management")
                                                    }
                                                    .font(.subheadline.weight(.semibold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color.poolWhite)
                                                    .foregroundColor(.poolBlack)
                                                    .cornerRadius(12)
                                                    .bold()
                                                }
                                            })
                                        }
                                        if masterDataManager.isFeatureEnabled(.sales) {
                                            Button(action: {
                                                masterDataManager.mobileHomeScreen = .sales
                                            }, label: {
                                                if masterDataManager.mobileHomeScreen == .sales {
                                                    HStack{
                                                        Text("Sales")
                                                    }
                                                    .modifier(EditButtonModifier())
                                                    .bold()
                                                } else {
                                                    HStack{
                                                        Text("Sales")
                                                    }
                                                    .font(.subheadline.weight(.semibold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color.poolWhite)
                                                    .foregroundColor(.poolBlack)
                                                    .cornerRadius(12)
                                                    .bold()
                                                }
                                            })
                                        }
//  MARK:                                         Update 2.1: Finance

                                        if role.permissionIdList.contains("200") {
                                            
                                            Button(action: {
                                                masterDataManager.mobileHomeScreen = .finance
                                            }, label: {
                                                if masterDataManager.mobileHomeScreen == .finance {
                                                    HStack{
                                                        Text("Finance")
                                                    }
                                                    .modifier(EditButtonModifier())
                                                    .bold()
                                                } else {
                                                    HStack{
                                                        Text("Finance")
                                                    }
                                                    .font(.subheadline.weight(.semibold))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color.poolWhite)
                                                    .foregroundColor(.poolBlack)
                                                    .cornerRadius(12)
                                                    .bold()
                                                }
                                            })
                                        }
                                    }
                                    
                                    if role.permissionIdList.contains("800") {
                                        Button(action: {
                                            masterDataManager.mobileHomeScreen = .settings
                                        }, label: {
                                            if masterDataManager.mobileHomeScreen == .settings {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .modifier(EditButtonModifier())
                                                .bold()
                                            } else {
                                                HStack{
                                                    Text("Company Settings")
                                                }
                                                .font(.subheadline.weight(.semibold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color.poolWhite)
                                                .foregroundColor(.poolBlack)
                                                .cornerRadius(12)
                                                .bold()
                                            }
                                        })
                                    }
                                
                                    // Also At Marketing Things
                                    
                                    //----------------------------------------
                                    //Add Back in During Roll out of Phase 2
                                    //----------------------------------------
                                
                                    //                                VStack{
                                    //                                    HStack{
                                    //                                        Text("1")
                                    //                                            .font(.footnote)
                                    //                                            .foregroundColor(Color.clear)
                                    //                                    }
                                    //                                    Button(action: {
                                    //                                        screen = .publicView
                                    //                                    }, label: {
                                    //                                        HStack{
                                    //                                            Text("Market Place")
                                    //                                        }
                                    //                                        .frame(minWidth: 50,maxHeight: 30)
                                    //                                        .font(.footnote)
                                    //                                        .foregroundColor(Color.poolWhite)
                                    //                                        .padding(10)
                                    //                                        .background(screen == .publicView ? Color.poolBlue : Color.darkGray)
                                    //                                        .frame(minWidth: 50,maxHeight: 30)
                                    //                                        .clipShape(Capsule())
                                    //
                                    //                                    })
                                    //                                }
                                    //                                .padding(.leading,5)
                                
                                }
//                                .font(.footnote)
                                .lineLimit(1)
//                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 0))
                            }
                            .overlay(
                                HStack{
                                    LinearGradient(colors: [
                                        Color.listColor,
                                        Color.listColor.opacity(0.5),
                                        Color.clear
                                    ],
                                       startPoint: .leading,
                                       endPoint: .trailing)
                                    .frame(width: 10)
                                    Spacer()
                                }
                            )
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
                
            }
            else {
                Text("No Role Selected")
            }
        }
        .frame(height: 100)
//        .background(Color.listColor)
        .padding(.leading,8)
    }
    var all: some View {
        VStack{
            Text("All")
        }
    }
    var screens: some View {
        VStack{
            
            switch masterDataManager.mobileHomeScreen {
            case .all:
                All(dataService: dataService)
                
            case .routing:
                CompanyRoutingView(dataService: dataService)
                
            case .operations :
                Operations(dataService: dataService)
                
            case .sales:
                OwesMoneyView(dataService: dataService)

            case .marketing:
                CompanyLeadsView(dataService: dataService)
                
            case .finance :
                Finance(dataService: dataService)
                
            case .managment :
                Managment(dataService: dataService)
                
            case .publicView:
                MarketPlaceView(dataService: dataService)
                
            case .myCompany:
                MyCompany(dataService: dataService)
                
            case .settings:
                CompanySettings(dataService: dataService)
            }
        }
    }
}
