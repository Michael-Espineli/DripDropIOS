//
//  MobileHome.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
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
    @State private var todoSnapshotItems: [MobileDashboardTodoSnapshotItem] = []
    @State private var todoSnapshotListener: ListenerRegistration?
    @State private var todoSnapshotError: String?
    @State private var workOfferSnapshot: MobileDashboardWorkOfferSnapshot = .empty
    @State private var workOfferSnapshotError: String?
    @State private var purchaseReconciliationPreview: MobilePurchaseReconciliationPreview = .empty
    @State private var purchaseReconciliationPreviewError: String?
    @State private var payrollSnapshot: MobileDashboardPayrollSnapshot = .empty
    @State private var payrollSnapshotError: String?
    @State private var showPayoutRequestAlert: Bool = false

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
            stopTodoSnapshotListener()
        }
        .alert("Request payout", isPresented: $showPayoutRequestAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(payoutRequestAlertMessage)
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
                    quickActionsGrid
                    if shouldShowAlertsSection {
                        alertsOverviewSection
                    }
                    todoSnapshotSection
                    workOffersSnapshotSection
                    purchaseReconciliationSnapshotSection
                    payoutSnapshotSection

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
                    tint: .poolGreen,
                    route: .employeeMainDailyDisplayView(dataService: dataService)
                )

                summaryMetric(
                    title: "Pending",
                    value: "\(pendingRepairRequests.count)",
                    systemImage: "wrench.adjustable.fill",
                    tint: .orange,
                    route: .repairRequestList(dataService: dataService)
                )

                summaryMetric(
                    title: "Jobs",
                    value: "\(operationBoardJobs.count)",
                    systemImage: "briefcase.fill",
                    tint: .poolBlue,
                    route: .jobs(dataService: dataService)
                )
            }
        }
        .mobileMainCard(material: true)
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

    private var todoSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Todo Snapshot",
                subtitle: "\(openTodoSnapshotItems.count) open, \(todoAttentionItems.count) need attention",
                systemImage: "checklist",
                route: .toDoList(dataService: dataService)
            )

            HStack(spacing: 8) {
                snapshotMetric(title: "Open", value: "\(openTodoSnapshotItems.count)", tint: .poolBlue)
                snapshotMetric(title: "Mine", value: "\(assignedTodoSnapshotItems.count)", tint: .poolGreen)
                snapshotMetric(title: "Attention", value: "\(todoAttentionItems.count)", tint: todoAttentionItems.isEmpty ? .gray : .orange)
            }

            if let todoSnapshotError {
                Text("Todos unavailable: \(todoSnapshotError)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .mobileMainCard()
    }

    private var workOffersSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            workOffersSnapshotHeader

            LazyVGrid(columns: quickActionColumns, spacing: 8) {
                snapshotMetric(title: "Direct", value: "\(workOfferSnapshot.directOfferCount)", tint: .poolBlue)
                snapshotMetric(title: "Board", value: "\(workOfferSnapshot.boardOfferCount)", tint: .poolGreen)
                snapshotMetric(title: "Accepted", value: "\(workOfferSnapshot.acceptedOfferCount)", tint: .orange)
                snapshotMetric(title: "Scheduled", value: "\(workOfferSnapshot.scheduledOfferCount)", tint: .purple)
            }

            if let workOfferSnapshotError {
                Text("Work offers unavailable: \(workOfferSnapshotError)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .mobileMainCard()
    }

    private var purchaseReconciliationSnapshotSection: some View {
        NavigationLink {
            MobilePurchaseReconciliationView(dataService: dataService)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Reconcile Purchases")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(purchaseReconciliationPreview.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, height: 32)
                        .background(.thinMaterial, in: Circle())
                }

                HStack(spacing: 8) {
                    snapshotMetric(
                        title: "Need review",
                        value: "\(purchaseReconciliationPreview.unresolvedCount)",
                        tint: purchaseReconciliationPreview.unresolvedCount > 0 ? .orange : .gray
                    )
                    snapshotMetric(
                        title: "Showing",
                        value: "Open",
                        tint: .poolGreen
                    )
                    snapshotMetric(
                        title: "Window",
                        value: "30d",
                        tint: .poolBlue
                    )
                }

                if !purchaseReconciliationPreview.recentItemNames.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(purchaseReconciliationPreview.recentItemNames, id: \.self) { name in
                            Label(name, systemImage: "shippingbox")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                if let purchaseReconciliationPreviewError {
                    Text("Purchases unavailable: \(purchaseReconciliationPreviewError)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(.plain)
        .mobileMainCard()
    }

    @ViewBuilder
    private var workOffersSnapshotHeader: some View {
        if let companyUser = masterDataManager.companyUser {
            sectionHeader(
                title: "Work Offers",
                subtitle: workOfferSnapshot.subtitle,
                systemImage: "list.bullet.clipboard",
                route: .technicianWorkCenter(dataService: dataService, companyUser: companyUser)
            )
        } else {
            sectionLabel(
                title: "Work Offers",
                subtitle: "Connect your company user profile to see offers.",
                systemImage: "list.bullet.clipboard"
            )
        }
    }

    private var payoutSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(
                title: "Payout Snapshot",
                subtitle: payrollSnapshot.subtitle,
                systemImage: "dollarsign.circle"
            )

            HStack(spacing: 8) {
                snapshotMetric(
                    title: "Owed",
                    value: MobileDashboardMoneyFormatter.money(payrollSnapshot.owedCents),
                    tint: payrollSnapshot.owedCents > 0 ? .poolGreen : .gray
                )
                snapshotMetric(
                    title: "Work Done",
                    value: "\(payrollSnapshot.owedLineItemCount)",
                    tint: .poolBlue
                )
                snapshotMetric(
                    title: "Last Payout",
                    value: payrollSnapshot.daysSinceLastPayoutText,
                    tint: .orange
                )
            }

            if let payrollSnapshotError {
                Text("Payout unavailable: \(payrollSnapshotError)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Button {
                showPayoutRequestAlert = true
            } label: {
                HStack {
                    Image(systemName: "paperplane.fill")
                    Text("Request payout")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
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
                title: "Create Lead",
                subtitle: "New request",
                systemImage: "person.crop.circle.badge.plus",
                tint: .poolYellow
            ) {
                CompanyLeadEditorView(dataService: dataService)
            }
        }
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

    private func quickAction<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            quickActionContent(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: tint
            )
        }
        .buttonStyle(.plain)
    }

    private func quickActionContent(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
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

    private func todoSnapshotRow(_ todo: MobileDashboardTodoSnapshotItem) -> some View {
        HStack(alignment: .top, spacing: 11) {
            statusDot(color: todoSnapshotStatusColor(todo))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(todo.issueKey)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text(todo.priorityLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(todoSnapshotPriorityColor(todo.priority))
                        .lineLimit(1)
                }

                Text(todo.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(todo.detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text(todo.statusLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(todoSnapshotStatusColor(todo))
                    .lineLimit(1)

                Text(todo.dueLabel)
                    .font(.caption2)
                    .foregroundStyle(todoSnapshotDueColor(todo))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func snapshotMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryMetric(
        title: String,
        value: String,
        systemImage: String,
        tint: Color,
        route: Route
    ) -> some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
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

    private var openTodoSnapshotItems: [MobileDashboardTodoSnapshotItem] {
        todoSnapshotItems
            .filter { $0.isOpen }
            .sorted(by: MobileDashboardTodoSnapshotItem.sortByUrgency)
    }

    private var assignedTodoSnapshotItems: [MobileDashboardTodoSnapshotItem] {
        let userId = masterDataManager.user?.id ?? ""
        return openTodoSnapshotItems.filter { userId.isEmpty || $0.isAssigned(to: userId) }
    }

    private var todoAttentionItems: [MobileDashboardTodoSnapshotItem] {
        openTodoSnapshotItems.filter { $0.needsAttention }
    }

    private var payoutRequestAlertMessage: String {
        if payrollSnapshot.owedCents > 0 {
            return "Current estimated amount owed is \(MobileDashboardMoneyFormatter.money(payrollSnapshot.owedCents)). Payout request submission still needs the backend workflow connected."
        }

        return "No unpaid completed work is showing in this payout snapshot right now."
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

    private var operationBoardJobs: [Job] {
        return jobVM.workOrders
            .filter {
                operationBoardJobOperationStatuses.contains($0.operationStatus) &&
                operationBoardJobBillingStatuses.contains($0.billingStatus)
            }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    private var operationBoardJobOperationStatuses: [JobOperationStatus] {
        [
            .estimatePending,
            .unscheduled,
            .scheduled,
            .waitingForParts,
            .inProgress
        ]
    }

    private var operationBoardJobBillingStatuses: Set<JobBillingStatus> {
        [
            .draft,
            .estimate,
            .accepted,
            .inProgress
        ]
    }

    private var routeFinishedCount: Int {
        routeVM.activeRoute?.finishedStops ?? routeVM.serviceStopList.filter { $0.operationStatus == .finished }.count
    }

    private var routeTotalCount: Int {
        routeVM.activeRoute?.totalStops ?? routeVM.serviceStopList.count
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

    private var operationsBoardJobDateWindow: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        let end = calendar.date(byAdding: .year, value: 10, to: Date()) ?? Date()
        return (start, end)
    }

    private func startDashboardListeners() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            stopTodoSnapshotListener()
            todoSnapshotItems = []
            return
        }

        isLoading = true
        routeVM.start(companyId: company.id, user: user, date: Date())
        startTodoSnapshotListener(companyId: company.id)

        let window = listenerDateWindow
        let jobWindow = operationsBoardJobDateWindow
        repairRequestVM.addListenerForAllRequests(
            companyId: company.id,
            status: [],
            requesterIds: [user.id],
            startDate: window.start,
            endDate: window.end
        )
        jobVM.addListenerForAllJobsOperations(
            companyId: company.id,
            status: operationBoardJobOperationStatuses,
            requesterIds: [],
            startDate: jobWindow.start,
            endDate: jobWindow.end
        )

        if masterDataManager.isFeatureEnabled(.alertsAndNotifications) {
            do {
                try await alertVM.getAlertsByCompany(companyId: company.id)
            } catch {
                print("[MobileReimaginedMainDashboard][startDashboardListeners][alerts]")
                print(error)
            }
        }

        let payrollTechnicianId = masterDataManager.companyUser?.userId ?? user.id
        await loadWorkOfferSnapshot(companyId: company.id)
        if let purchaseTechnicianId = purchaseReconciliationTechnicianId {
            await loadPurchaseReconciliationPreview(companyId: company.id, technicianId: purchaseTechnicianId)
        } else {
            purchaseReconciliationPreview = .empty
            purchaseReconciliationPreviewError = "Company user profile not loaded."
        }
        await loadPayrollSnapshot(companyId: company.id, technicianId: payrollTechnicianId)

        isLoading = false
    }

    private func loadWorkOfferSnapshot(companyId: String) async {
        guard let companyUser = masterDataManager.companyUser else {
            workOfferSnapshot = .empty
            workOfferSnapshotError = "Company user profile not loaded."
            return
        }

        workOfferSnapshotError = nil

        do {
            async let directTask = dataService.fetchWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )
            async let boardTask = dataService.fetchOpenBoardWorkOffers(
                companyId: companyId,
                workerType: companyUser.workerType
            )
            async let acceptedTask = dataService.fetchAcceptedWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )

            let directOffers = try await directTask
            let boardOffers = try await boardTask
            let acceptedOffers = try await acceptedTask
            let acceptedUserOffers = (directOffers + boardOffers + acceptedOffers)
                .mobileDashboardUniqueWorkOffers()
                .filter {
                    $0.acceptedByUserId == companyUser.userId ||
                    $0.offeredToUserId == companyUser.userId
                }

            workOfferSnapshot = MobileDashboardWorkOfferSnapshot(
                directOfferCount: directOffers.openDirectOfferCount,
                boardOfferCount: boardOffers.openBoardOfferCount,
                acceptedOfferCount: acceptedUserOffers.filter {
                    $0.status == .accepted ||
                    $0.status == .scheduled ||
                    $0.status == .inProgress ||
                    $0.status == .completed
                }.count,
                scheduledOfferCount: acceptedUserOffers.scheduledOfferCount,
                readyToScheduleCount: acceptedUserOffers.acceptedReadyToScheduleCount
            )
        } catch {
            workOfferSnapshot = .empty
            workOfferSnapshotError = error.localizedDescription
        }
    }

    private var purchaseReconciliationTechnicianId: String? {
        let companyUserId = masterDataManager.companyUser?.userId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return companyUserId.isEmpty ? nil : companyUserId
    }

    private func loadPurchaseReconciliationPreview(companyId: String, technicianId: String) async {
        purchaseReconciliationPreviewError = nil
        let scopedTechnicianId = technicianId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !scopedTechnicianId.isEmpty else {
            purchaseReconciliationPreview = .empty
            purchaseReconciliationPreviewError = "Company user profile not loaded."
            return
        }

        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

            let snapshot = try await Firestore.firestore()
                .collection("companies")
                .document(companyId)
                .collection("purchasedItems")
                .whereField("techId", isEqualTo: scopedTechnicianId)
                .whereField("billable", isEqualTo: true)
                .whereField("invoiced", isEqualTo: false)
                .whereField("date", isGreaterThanOrEqualTo: startDate)
                .whereField("date", isLessThanOrEqualTo: endDate)
                .order(by: "date", descending: true)
                .getDocuments()

            let purchases = snapshot.documents
                .compactMap { try? $0.data(as: PurchasedItem.self) }
                .filter {
                    MobilePurchaseReconciliationFilters.needsTechnicianReconciliation(
                        $0,
                        technicianId: scopedTechnicianId
                    )
                }

            purchaseReconciliationPreview = MobilePurchaseReconciliationPreview(
                unresolvedCount: purchases.count,
                oldestPurchaseDate: purchases.map(\.date).min(),
                recentItemNames: purchases.prefix(3).map { $0.name.isEmpty ? $0.venderName : $0.name }
            )
        } catch {
            purchaseReconciliationPreview = .empty
            purchaseReconciliationPreviewError = error.localizedDescription
        }
    }

    private func loadPayrollSnapshot(companyId: String, technicianId: String) async {
        payrollSnapshotError = nil

        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -365, to: endDate) ?? endDate

            async let lineItemsTask = dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )
            async let statementsTask = dataService.fetchTechnicianPayStatements(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )

            let fetchedLineItems = try await lineItemsTask
            let fetchedStatements = try await statementsTask
            let lineItems = fetchedLineItems.filter { $0.technicianId == technicianId }
            let statements = fetchedStatements.filter { $0.technicianId == technicianId }

            let lastPayoutDate = MobileDashboardPayrollSnapshot.mostRecentPayoutDate(
                lineItems: lineItems,
                statements: statements
            )
            let owedItems = lineItems.filter { lineItem in
                MobileDashboardPayrollSnapshot.isOwedLineItem(lineItem) &&
                (lastPayoutDate == nil || lineItem.completedDate >= lastPayoutDate!)
            }

            payrollSnapshot = MobileDashboardPayrollSnapshot(
                owedCents: owedItems.reduce(0) { $0 + $1.totalAmountCents },
                owedLineItemCount: owedItems.count,
                lastPayoutDate: lastPayoutDate,
                oldestUnpaidWorkDate: owedItems.map(\.completedDate).min()
            )
        } catch {
            payrollSnapshot = .empty
            payrollSnapshotError = error.localizedDescription
        }
    }

    private func startTodoSnapshotListener(companyId: String) {
        stopTodoSnapshotListener()
        todoSnapshotError = nil

        todoSnapshotListener = Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("todoItems")
            .addSnapshotListener { snapshot, error in
                if let error {
                    DispatchQueue.main.async {
                        self.todoSnapshotItems = []
                        self.todoSnapshotError = error.localizedDescription
                    }
                    return
                }

                let items = snapshot?.documents
                    .map { MobileDashboardTodoSnapshotItem(document: $0) }
                    .filter { !$0.isArchived } ?? []

                DispatchQueue.main.async {
                    self.todoSnapshotItems = items
                    self.todoSnapshotError = nil
                }
            }
    }

    private func stopTodoSnapshotListener() {
        todoSnapshotListener?.remove()
        todoSnapshotListener = nil
    }

    private func todoSnapshotStatusColor(_ todo: MobileDashboardTodoSnapshotItem) -> Color {
        if todo.needsAttention {
            return .orange
        }

        switch todo.statusKey {
        case "inprogress":
            return .poolBlue
        case "done", "finished":
            return .poolGreen
        default:
            return .gray
        }
    }

    private func todoSnapshotPriorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent":
            return .poolRed
        case "high":
            return .orange
        case "low":
            return .poolGreen
        default:
            return .secondary
        }
    }

    private func todoSnapshotDueColor(_ todo: MobileDashboardTodoSnapshotItem) -> Color {
        switch todo.dueState {
        case .overdue:
            return .poolRed
        case .today:
            return .orange
        case .upcoming:
            return .poolBlue
        case .complete:
            return .poolGreen
        case .none:
            return .secondary
        }
    }
}

private enum MobileDashboardTodoDueState {
    case overdue
    case today
    case upcoming
    case none
    case complete

    var rank: Int {
        switch self {
        case .overdue:
            return 0
        case .today:
            return 1
        case .upcoming:
            return 2
        case .none:
            return 3
        case .complete:
            return 4
        }
    }
}

private struct MobileDashboardTodoSnapshotItem: Identifiable {
    let id: String
    let title: String
    let description: String
    let status: String
    let priority: String
    let boardName: String
    let assignedToUserId: String
    let assignedToName: String
    let scope: String
    let dueAt: Date?
    let reminderAt: Date?
    let reminderEnabled: Bool
    let createdAt: Date?
    let updatedAt: Date?

    init(document: QueryDocumentSnapshot) {
        let data = document.data()

        id = Self.stringValue(data["id"], fallback: document.documentID)
        title = Self.stringValue(data["title"], fallback: "Untitled todo")
        description = Self.stringValue(data["description"])
        status = Self.stringValue(data["status"], fallback: "open")
        priority = Self.stringValue(data["priority"], fallback: "normal")
        boardName = Self.stringValue(data["boardName"], fallback: "No board")
        assignedToUserId = Self.stringValue(data["assignedToUserId"])
        assignedToName = Self.stringValue(data["assignedToName"], fallback: "Team task")
        scope = Self.stringValue(data["scope"], fallback: "team")
        dueAt = Self.dateValue(data["dueAt"])
        reminderAt = Self.dateValue(data["reminderAt"])
        reminderEnabled = Self.boolValue(data["reminderEnabled"])
        createdAt = Self.dateValue(data["createdAt"])
        updatedAt = Self.dateValue(data["updatedAt"])
    }

    var statusKey: String {
        status
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    var isArchived: Bool {
        statusKey == "archived"
    }

    var isOpen: Bool {
        !["done", "finished", "complete", "completed", "archived"].contains(statusKey)
    }

    var needsAttention: Bool {
        guard isOpen else { return false }

        if dueState == .overdue || dueState == .today {
            return true
        }

        if reminderEnabled, let reminderAt {
            return reminderAt <= Date()
        }

        return false
    }

    var dueState: MobileDashboardTodoDueState {
        guard isOpen else { return .complete }
        guard let dueAt else { return .none }

        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart

        if dueAt < todayStart {
            return .overdue
        }

        if dueAt < tomorrowStart {
            return .today
        }

        return .upcoming
    }

    var issueKey: String {
        let compactId = id.uppercased().filter { $0.isLetter || $0.isNumber }
        let suffix = String(compactId.suffix(5))
        return "TODO-\(suffix.isEmpty ? "ITEM" : suffix)"
    }

    var priorityLabel: String {
        switch priority.lowercased() {
        case "urgent":
            return "Urgent"
        case "high":
            return "High"
        case "low":
            return "Low"
        default:
            return "Normal"
        }
    }

    var statusLabel: String {
        switch statusKey {
        case "inprogress":
            return "In Progress"
        case "done", "finished":
            return "Done"
        default:
            return "Open"
        }
    }

    var dueLabel: String {
        switch dueState {
        case .overdue:
            return "Overdue \(shortDate(date: dueAt))"
        case .today:
            return "Today \(shortDate(date: dueAt))"
        case .upcoming:
            return "Due \(shortDate(date: dueAt))"
        case .complete:
            return "Complete"
        case .none:
            return "No due date"
        }
    }

    var detailLine: String {
        let board = boardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No board" : boardName
        let owner = assignedToName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Team task" : assignedToName
        return "\(board) | \(owner)"
    }

    func isAssigned(to userId: String) -> Bool {
        assignedToUserId == userId || (scope == "me" && !assignedToUserId.isEmpty && assignedToUserId == userId)
    }

    static func sortByUrgency(_ left: MobileDashboardTodoSnapshotItem, _ right: MobileDashboardTodoSnapshotItem) -> Bool {
        if left.dueState.rank != right.dueState.rank {
            return left.dueState.rank < right.dueState.rank
        }

        let leftDue = left.dueAt ?? .distantFuture
        let rightDue = right.dueAt ?? .distantFuture
        if leftDue != rightDue {
            return leftDue < rightDue
        }

        let leftPriority = priorityRank(left.priority)
        let rightPriority = priorityRank(right.priority)
        if leftPriority != rightPriority {
            return leftPriority < rightPriority
        }

        return (left.createdAt ?? left.updatedAt ?? .distantPast) > (right.createdAt ?? right.updatedAt ?? .distantPast)
    }

    private static func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "urgent":
            return 0
        case "high":
            return 1
        case "low":
            return 3
        default:
            return 2
        }
    }

    private static func stringValue(_ value: Any?, fallback: String = "") -> String {
        if let value = value as? String {
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : value
        }

        return fallback
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let value = value as? Bool {
            return value
        }

        if let value = value as? String {
            return ["true", "yes", "1"].contains(value.lowercased())
        }

        if let value = value as? Int {
            return value != 0
        }

        return false
    }

    private static func dateValue(_ value: Any?) -> Date? {
        if let value = value as? Timestamp {
            return value.dateValue()
        }

        if let value = value as? Date {
            return value
        }

        if let value = value as? TimeInterval {
            return Date(timeIntervalSince1970: value)
        }

        return nil
    }
}

private struct MobileDashboardWorkOfferSnapshot {
    let directOfferCount: Int
    let boardOfferCount: Int
    let acceptedOfferCount: Int
    let scheduledOfferCount: Int
    let readyToScheduleCount: Int

    static let empty = MobileDashboardWorkOfferSnapshot(
        directOfferCount: 0,
        boardOfferCount: 0,
        acceptedOfferCount: 0,
        scheduledOfferCount: 0,
        readyToScheduleCount: 0
    )

    var openOfferCount: Int {
        directOfferCount + boardOfferCount
    }

    var subtitle: String {
        "\(openOfferCount) open, \(readyToScheduleCount) ready to schedule"
    }
}

private struct MobileDashboardPayrollSnapshot {
    let owedCents: Int
    let owedLineItemCount: Int
    let lastPayoutDate: Date?
    let oldestUnpaidWorkDate: Date?

    static let empty = MobileDashboardPayrollSnapshot(
        owedCents: 0,
        owedLineItemCount: 0,
        lastPayoutDate: nil,
        oldestUnpaidWorkDate: nil
    )

    var subtitle: String {
        if let oldestUnpaidWorkDate {
            return "Unpaid work since \(shortDate(date: oldestUnpaidWorkDate))"
        }

        if lastPayoutDate != nil {
            return "No unpaid work since the last payout."
        }

        return "No payout history found."
    }

    var daysSinceLastPayoutText: String {
        guard let lastPayoutDate else {
            return "None"
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: lastPayoutDate)
        let end = calendar.startOfDay(for: Date())
        let days = max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)

        if days == 0 {
            return "Today"
        }

        if days == 1 {
            return "1 day"
        }

        return "\(days) days"
    }

    static func isOwedLineItem(_ lineItem: TechnicianPayLineItem) -> Bool {
        guard lineItem.voidedAt == nil, lineItem.paidAt == nil else {
            return false
        }

        switch lineItem.calculationStatus {
        case .pending, .calculated, .needsReview, .approved, .adjusted:
            return true
        case .paid, .voided:
            return false
        }
    }

    static func mostRecentPayoutDate(
        lineItems: [TechnicianPayLineItem],
        statements: [TechnicianPayStatement]
    ) -> Date? {
        let statementDates = statements.compactMap { statement -> Date? in
            if let paidAt = statement.paidAt {
                return paidAt
            }

            return statement.status == .paid ? statement.endDate : nil
        }
        let lineItemDates = lineItems.compactMap(\.paidAt)

        return (statementDates + lineItemDates).max()
    }
}

private enum MobileDashboardMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

private extension Array where Element == WorkOffer {
    func mobileDashboardUniqueWorkOffers() -> [WorkOffer] {
        var seen: Set<String> = []
        var result: [WorkOffer] = []

        for offer in self {
            if !seen.contains(offer.id) {
                result.append(offer)
                seen.insert(offer.id)
            }
        }

        return result
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
                    title: "Offered Work",
                    subtitle: "Offers for all technicians",
                    systemImage: "list.bullet.clipboard.fill",
                    tint: .poolBlue,
                    route: .offeredWork(dataService: dataService),
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
                    title: "Equipment Scanner",
                    subtitle: "Identify gear and pipe paths",
                    systemImage: "viewfinder.circle.fill",
                    tint: .poolBlue,
                    route: .poolEquipmentScanner(dataService: dataService),
                    permissionId: "60",
                    featureFlag: .poolEquipmentScanner
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

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: systemImage)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(tint)
                            .frame(width: 48, height: 48)
                            .background(tint.opacity(0.14), in: Circle())
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
            

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

private enum MobilePurchaseReconciliationFilters {
    static func needsTechnicianReconciliation(_ purchase: PurchasedItem) -> Bool {
        purchase.billable &&
        !purchase.invoiced &&
        purchase.returned != true &&
        !isPersonalPurchase(purchase) &&
        !hasShoppingConnection(purchase) &&
        !hasJobConnection(purchase) &&
        !hasCustomerConnection(purchase)
    }

    static func needsTechnicianReconciliation(_ purchase: PurchasedItem, technicianId: String) -> Bool {
        belongsToTechnician(purchase, technicianId: technicianId) &&
        needsTechnicianReconciliation(purchase)
    }

    static func belongsToTechnician(_ purchase: PurchasedItem, technicianId: String) -> Bool {
        let cleanTechnicianId = clean(technicianId)
        return !cleanTechnicianId.isEmpty && clean(purchase.techId) == cleanTechnicianId
    }

    static func hasShoppingConnection(_ purchase: PurchasedItem) -> Bool {
        !clean(purchase.shoppingListItemId ?? "").isEmpty
    }

    static func hasCustomerConnection(_ purchase: PurchasedItem) -> Bool {
        !clean(purchase.customerId).isEmpty ||
        !clean(purchase.customerName).isEmpty ||
        normalizedStatus(purchase.billingOwner) == "customer"
    }

    static func hasJobConnection(_ purchase: PurchasedItem) -> Bool {
        if purchase.assignedToJob == true {
            return true
        }

        if !clean(purchase.jobId).isEmpty ||
            !clean(purchase.workOrderId ?? "").isEmpty ||
            !clean(purchase.assignedJobId ?? "").isEmpty ||
            !clean(purchase.installationJobId ?? "").isEmpty ||
            !clean(purchase.installationTaskId ?? "").isEmpty ||
            !clean(purchase.jobInternalId ?? "").isEmpty ||
            !clean(purchase.jobName ?? "").isEmpty {
            return true
        }

        let assignmentStatus = normalizedStatus(purchase.assignmentStatus)
        if assignmentStatus == "assignedtojob" || assignmentStatus == "connectedtojob" {
            return true
        }

        if normalizedStatus(purchase.billingOwner) == "job" {
            return true
        }

        let jobBillingStatus = normalizedStatus(purchase.jobBillingStatus)
        if jobBillingStatus == "handledbyjob" || jobBillingStatus == "invoiced" || jobBillingStatus == "paid" {
            return true
        }

        let status = normalizedStatus(purchase.status)
        return status == "connectedtojob" || status == "assignedtojob"
    }

    static func isPersonalPurchase(_ purchase: PurchasedItem) -> Bool {
        let assignmentStatus = normalizedStatus(purchase.assignmentStatus)
        let billingOwner = normalizedStatus(purchase.billingOwner)
        let status = normalizedStatus(purchase.status)

        return assignmentStatus == "personal" ||
            billingOwner == "personal" ||
            status == "personalpurchase"
    }

    private static func normalizedStatus(_ value: String?) -> String {
        clean(value ?? "")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct MobilePurchaseReconciliationPreview {
    let unresolvedCount: Int
    let oldestPurchaseDate: Date?
    let recentItemNames: [String]

    static let empty = MobilePurchaseReconciliationPreview(
        unresolvedCount: 0,
        oldestPurchaseDate: nil,
        recentItemNames: []
    )

    var subtitle: String {
        if unresolvedCount == 0 {
            return "No unlinked billable purchases in the last 30 days."
        }

        if let oldestPurchaseDate {
            return "\(unresolvedCount) unlinked billable since \(shortDate(date: oldestPurchaseDate))."
        }

        return "\(unresolvedCount) unlinked billable purchase\(unresolvedCount == 1 ? "" : "s")."
    }
}

private struct MobilePurchaseReconciliationRangeOption: Identifiable {
    let days: Int
    let label: String

    var id: Int { days }
}

private struct MobilePurchaseDatabaseItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let subCategory: String
    let sku: String
    let storeName: String

    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = Self.string(data["name"])
        self.category = Self.string(data["category"])
        self.subCategory = Self.string(data["subCategory"])
        self.sku = Self.string(data["sku"])
        self.storeName = Self.string(data["storeName"])
    }

    var detailLine: String {
        [category, subCategory, sku.isEmpty ? "" : "SKU \(sku)", storeName]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " | ")
    }

    private static func string(_ value: Any?) -> String {
        if let value = value as? String {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let value = value {
            return String(describing: value).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ""
    }
}

private struct MobilePurchaseReconciliationView: View {
    let dataService: any ProductionDataServiceProtocol

    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var lookbackDays: Int = 30
    @State private var purchases: [PurchasedItem] = []
    @State private var shoppingListItems: [ShoppingListItem] = []
    @State private var databaseItemsById: [String: MobilePurchaseDatabaseItem] = [:]
    @State private var selectedPurchase: PurchasedItem?
    @State private var isLoading = false
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var loadRequestId = UUID()

    private let shoppingCandidateFetchLimit = 75

    private let rangeOptions: [MobilePurchaseReconciliationRangeOption] = [
        MobilePurchaseReconciliationRangeOption(days: 30, label: "30d"),
        MobilePurchaseReconciliationRangeOption(days: 60, label: "60d"),
        MobilePurchaseReconciliationRangeOption(days: 90, label: "90d"),
        MobilePurchaseReconciliationRangeOption(days: 180, label: "6mo"),
        MobilePurchaseReconciliationRangeOption(days: 365, label: "1yr")
    ]

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summaryCard
                    rangeSelector
                    purchaseList

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
            }

            if isLoading || isUpdating {
                Color.black.opacity(0.18).ignoresSafeArea()
                ProgressView(isLoading ? "Loading purchases..." : "Saving changes...")
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .navigationTitle("Reconcile Purchases")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: loadIdentity) {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
        .sheet(item: $selectedPurchase) { purchase in
            MobilePurchaseReconciliationDetailSheet(
                dataService: dataService,
                purchase: purchase,
                databaseItem: databaseItemsById[purchase.itemId],
                connectedShoppingItem: connectedShoppingItem(for: purchase),
                shoppingCandidates: shoppingCandidates(for: purchase),
                isUpdating: isUpdating,
                onSaveNotes: { purchase, notes in
                    await saveNotes(for: purchase, notes: notes)
                },
                onConnectShoppingItem: { purchase, item in
                    await connectShoppingItem(item, to: purchase)
                },
                onConnectCustomer: { purchase, customer in
                    await connectCustomer(customer, to: purchase)
                },
                onConnectJob: { purchase, job in
                    await connectJob(job, to: purchase)
                },
                onMarkReturned: { purchase in
                    await markReturned(purchase)
                },
                onMarkPersonal: { purchase in
                    await markPersonal(purchase)
                },
                onSplitPurchase: { purchase, quantity, customer, job, notes in
                    await splitPurchase(
                        purchase,
                        quantity: quantity,
                        customer: customer,
                        job: job,
                        notes: notes
                    )
                }
            )
            .presentationDetents([.large])
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cart.badge.questionmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 42, height: 42)
                    .background(Color.orange.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reconcile Purchases")
                        .font(.title3.weight(.semibold))

                    Text("\(visiblePurchases.count) unlinked billable purchase\(visiblePurchases.count == 1 ? "" : "s") need review.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                metricPill(title: "Need review", value: "\(visiblePurchases.count)", tint: visiblePurchases.isEmpty ? .gray : .orange)
                metricPill(title: "Showing", value: "Open", tint: .poolGreen)
                metricPill(title: "Range", value: "\(lookbackDays)d", tint: .poolBlue)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .mobileMainCard(material: true)
    }

    private var rangeSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date Range")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(rangeOptions) { option in
                    Button {
                        lookbackDays = option.days
                    } label: {
                        Text(option.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(lookbackDays == option.days ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                lookbackDays == option.days ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mobileMainCard()
    }

    @ViewBuilder
    private var purchaseList: some View {
        if visiblePurchases.isEmpty && !isLoading {
            ContentUnavailableView(
                "No Purchases To Reconcile",
                systemImage: "checkmark.seal",
                description: Text("There are no unlinked billable purchases for this technician in the selected range.")
            )
            .mobileMainCard()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Purchases")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                ForEach(visiblePurchases) { purchase in
                    Button {
                        selectedPurchase = purchase
                    } label: {
                        MobilePurchaseReconciliationPurchaseRow(
                            purchase: purchase,
                            databaseItem: databaseItemsById[purchase.itemId],
                            connectedShoppingItem: connectedShoppingItem(for: purchase),
                            candidateCount: shoppingCandidates(for: purchase).count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var visiblePurchases: [PurchasedItem] {
        purchases.filter { purchase in
            MobilePurchaseReconciliationFilters.needsTechnicianReconciliation(
                purchase,
                technicianId: technicianId
            ) &&
            connectedShoppingItem(for: purchase) == nil
        }
    }

    private var loadIdentity: String {
        "\(masterDataManager.currentCompany?.id ?? "no-company")-\(technicianId)-\(lookbackDays)"
    }

    private var technicianId: String {
        masterDataManager.companyUser?.userId.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var actorId: String {
        masterDataManager.companyUser?.userId ?? masterDataManager.user?.id ?? ""
    }

    private var actorName: String {
        let companyUserName = masterDataManager.companyUser?.userName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !companyUserName.isEmpty {
            return companyUserName
        }

        let firstName = masterDataManager.user?.firstName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = masterDataManager.user?.lastName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)

        return fullName.isEmpty ? "Mobile technician" : fullName
    }

    private func metricPill(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadData() async {
        guard let companyId = masterDataManager.currentCompany?.id else {
            errorMessage = "Select a company before reconciling purchases."
            purchases = []
            shoppingListItems = []
            databaseItemsById = [:]
            isLoading = false
            return
        }

        guard !technicianId.isEmpty else {
            errorMessage = "Technician profile is not loaded yet."
            purchases = []
            shoppingListItems = []
            databaseItemsById = [:]
            isLoading = false
            return
        }

        let requestId = UUID()
        loadRequestId = requestId

        isLoading = true
        errorMessage = nil
        shoppingListItems = []

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: endDate) ?? endDate

        do {
            let loadedPurchases = try await fetchPurchases(
                companyId: companyId,
                technicianId: technicianId,
                startDate: startDate,
                endDate: endDate
            )
            let loadedDatabaseItems = await fetchDatabaseItems(
                companyId: companyId,
                purchases: loadedPurchases,
                shoppingItems: []
            )

            guard loadRequestId == requestId else { return }

            purchases = loadedPurchases
            shoppingListItems = []
            databaseItemsById = loadedDatabaseItems
            isLoading = false

            let loadedShoppingItems = await fetchShoppingItems(
                companyId: companyId,
                technicianId: technicianId,
                purchases: loadedPurchases
            )

            guard loadRequestId == requestId else { return }

            shoppingListItems = loadedShoppingItems
        } catch {
            guard loadRequestId == requestId else { return }

            purchases = []
            shoppingListItems = []
            databaseItemsById = [:]
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fetchPurchases(
        companyId: String,
        technicianId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [PurchasedItem] {
        let snapshot = try await Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("purchasedItems")
            .whereField("techId", isEqualTo: technicianId)
            .whereField("billable", isEqualTo: true)
            .whereField("invoiced", isEqualTo: false)
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents
            .compactMap { document -> PurchasedItem? in
                do {
                    var item = try document.data(as: PurchasedItem.self)
                    if item.id.isEmpty {
                        item.id = document.documentID
                    }
                    return item
                } catch {
                    print("[MobilePurchaseReconciliationView][decodePurchase] \(error)")
                    return nil
                }
            }
            .filter {
                MobilePurchaseReconciliationFilters.needsTechnicianReconciliation(
                    $0,
                    technicianId: technicianId
                )
            }
    }

    private func fetchShoppingItems(
        companyId: String,
        technicianId: String,
        purchases: [PurchasedItem]
    ) async -> [ShoppingListItem] {
        let collectionRef = Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("shoppingList")

        var itemsById: [String: ShoppingListItem] = [:]

        func mergeSnapshot(_ snapshot: QuerySnapshot?) {
            snapshot?.documents.forEach { document in
                do {
                    var item = try document.data(as: ShoppingListItem.self)
                    if item.id.isEmpty {
                        item.id = document.documentID
                    }
                    itemsById[item.id] = item
                } catch {
                    print("[MobilePurchaseReconciliationView][decodeShopping] \(error)")
                }
            }
        }

        do {
            mergeSnapshot(
                try await collectionRef
                    .whereField("purchaserId", isEqualTo: technicianId)
                    .limit(to: shoppingCandidateFetchLimit)
                    .getDocuments()
            )
        } catch {
            print("[MobilePurchaseReconciliationView][shoppingByPurchaser] \(error)")
        }

        do {
            mergeSnapshot(
                try await collectionRef
                    .whereField("userId", isEqualTo: technicianId)
                    .limit(to: shoppingCandidateFetchLimit)
                    .getDocuments()
            )
        } catch {
            print("[MobilePurchaseReconciliationView][shoppingByUser] \(error)")
        }

        do {
            mergeSnapshot(
                try await collectionRef
                    .whereField("assignedTechIds", arrayContains: technicianId)
                    .limit(to: shoppingCandidateFetchLimit)
                    .getDocuments()
            )
        } catch {
            print("[MobilePurchaseReconciliationView][shoppingByAssignedTech] \(error)")
        }

        let purchaseIds = purchases.map(\.id).filter { !$0.isEmpty }
        let purchaseIdSet = Set(purchaseIds)
        var purchaseIdStartIndex = 0
        while purchaseIdStartIndex < purchaseIds.count {
            let purchaseIdEndIndex = min(purchaseIdStartIndex + 10, purchaseIds.count)
            let purchaseIdChunk = Array(purchaseIds[purchaseIdStartIndex..<purchaseIdEndIndex])
            do {
                mergeSnapshot(try await collectionRef.whereField("purchasedItem", in: purchaseIdChunk).getDocuments())
            } catch {
                print("[MobilePurchaseReconciliationView][shoppingByPurchases] \(error)")
            }
            purchaseIdStartIndex = purchaseIdEndIndex
        }

        return itemsById.values
            .filter { item in
                let purchasedItem = item.purchasedItem?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let reverseLinkedToLoadedPurchase = purchaseIdSet.contains(purchasedItem)
                let belongsToTech = item.purchaserId == technicianId ||
                    item.userId == technicianId ||
                    item.assignedTechIds.contains(technicianId) ||
                    reverseLinkedToLoadedPurchase

                return belongsToTech &&
                    (reverseLinkedToLoadedPurchase || item.status.needsShoppingAction) &&
                    (purchasedItem.isEmpty || reverseLinkedToLoadedPurchase)
            }
            .sorted {
                ($0.datePurchased ?? .distantPast) > ($1.datePurchased ?? .distantPast)
            }
    }

    private func fetchDatabaseItems(
        companyId: String,
        purchases: [PurchasedItem],
        shoppingItems: [ShoppingListItem]
    ) async -> [String: MobilePurchaseDatabaseItem] {
        var databaseIds = Set<String>()

        purchases
            .map(\.itemId)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .forEach { databaseIds.insert($0) }

        shoppingItems.forEach { item in
            [item.dbItemId, item.genericItemId]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .forEach { databaseIds.insert($0) }
        }

        guard !databaseIds.isEmpty else { return [:] }

        let databaseCollection = Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("settings")
            .document("dataBase")
            .collection("dataBase")

        var result: [String: MobilePurchaseDatabaseItem] = [:]

        for chunk in Array(databaseIds).chunked(into: 10) {
            do {
                let snapshot = try await databaseCollection
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                for document in snapshot.documents {
                    result[document.documentID] = MobilePurchaseDatabaseItem(id: document.documentID, data: document.data())
                }
            } catch {
                print("[MobilePurchaseReconciliationView][databaseItem] \(error)")
            }
        }

        return result
    }

    private func connectedShoppingItem(for purchase: PurchasedItem) -> ShoppingListItem? {
        let shoppingListItemId = purchase.shoppingListItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return shoppingListItems.first { item in
            (!shoppingListItemId.isEmpty && item.id == shoppingListItemId) ||
            ((item.purchasedItem ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == purchase.id)
        }
    }

    private func shoppingCandidates(for purchase: PurchasedItem) -> [ShoppingListItem] {
        let connected = connectedShoppingItem(for: purchase)
        let purchaseDatabaseId = purchase.itemId.trimmingCharacters(in: .whitespacesAndNewlines)
        let purchaseCustomerId = purchase.customerId.trimmingCharacters(in: .whitespacesAndNewlines)
        let purchaseJobId = firstNonEmpty(purchase.jobId, purchase.workOrderId ?? "", purchase.assignedJobId ?? "")

        let candidates = shoppingListItems.filter { item in
            if item.id == connected?.id {
                return true
            }

            let existingPurchaseId = item.purchasedItem?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !existingPurchaseId.isEmpty {
                return existingPurchaseId == purchase.id
            }

            let shoppingDatabaseIds = [
                item.dbItemId,
                item.genericItemId
            ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

            if !purchaseDatabaseId.isEmpty && shoppingDatabaseIds.contains(purchaseDatabaseId) {
                return true
            }

            if !purchaseCustomerId.isEmpty && item.customerId == purchaseCustomerId {
                return true
            }

            if !purchaseJobId.isEmpty && item.jobId == purchaseJobId {
                return true
            }

            return false
        }

        return candidates.uniqueByShoppingItemId().sorted { left, right in
            let leftSameDatabase = shoppingItem(left, matchesDatabaseId: purchaseDatabaseId)
            let rightSameDatabase = shoppingItem(right, matchesDatabaseId: purchaseDatabaseId)
            if leftSameDatabase != rightSameDatabase {
                return leftSameDatabase && !rightSameDatabase
            }

            return left.name.localizedCaseInsensitiveCompare(right.name) == .orderedAscending
        }
    }

    private func shoppingItem(_ item: ShoppingListItem, matchesDatabaseId databaseId: String) -> Bool {
        guard !databaseId.isEmpty else { return false }
        return item.dbItemId == databaseId || item.genericItemId == databaseId
    }

    private func saveNotes(for purchase: PurchasedItem, notes: String) async {
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanNotes != purchase.notes.trimmingCharacters(in: .whitespacesAndNewlines) else { return }

        await performPurchaseUpdate(
            purchase: purchase,
            updates: ["notes": cleanNotes],
            title: "Purchase notes updated",
            eventType: "notes_updated",
            changes: [
                historyChange("Notes", from: purchase.notes, to: cleanNotes)
            ].compactMap { $0 }
        )
    }

    private func connectShoppingItem(_ shoppingItem: ShoppingListItem, to purchase: PurchasedItem) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        let purchaseRef = purchaseDocument(companyId: companyId, purchaseId: purchase.id)
        let shoppingRef = shoppingDocument(companyId: companyId, shoppingItemId: shoppingItem.id)
        let previousShoppingItemId = purchase.shoppingListItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let customerName = firstNonEmpty(purchase.customerName, shoppingItem.customerName ?? "")
        let customerId = firstNonEmpty(purchase.customerId, shoppingItem.customerId ?? "")
        let jobId = firstNonEmpty(purchase.jobId, purchase.workOrderId ?? "", shoppingItem.jobId ?? "")
        let now = Timestamp(date: Date())

        var purchaseUpdates: [String: Any] = [
            "shoppingListItemId": shoppingItem.id,
            "personalPurchase": false,
            "personalPurchaseAssignedAt": FieldValue.delete(),
            "personalPurchaseAssignedByUserId": FieldValue.delete(),
            "personalPurchaseAssignedByUserName": FieldValue.delete(),
            "updatedAt": now
        ]
        if purchase.customerId.isEmpty && !customerId.isEmpty {
            purchaseUpdates["customerId"] = customerId
            purchaseUpdates["customerName"] = customerName
        }
        if firstNonEmpty(purchase.jobId, purchase.workOrderId ?? "").isEmpty && !jobId.isEmpty {
            purchaseUpdates["jobId"] = jobId
            purchaseUpdates["workOrderId"] = jobId
            purchaseUpdates["assignedJobId"] = jobId
            purchaseUpdates["assignedToJob"] = true
            purchaseUpdates["assignmentStatus"] = "assignedToJob"
            purchaseUpdates["billingOwner"] = "job"
            purchaseUpdates["jobBillingStatus"] = purchase.invoiced ? "invoiced" : "handledByJob"
            purchaseUpdates["status"] = purchase.invoiced ? "Invoiced" : "Connected to Job"
        }

        var shoppingUpdates: [String: Any] = [
            "purchasedItem": purchase.id,
            "status": ShoppingListStatus.purchased.rawValue,
            "datePurchased": Timestamp(date: purchase.date),
            "invoiced": purchase.invoiced,
            "needsAction": true,
            "updatedAt": now
        ]
        if !customerId.isEmpty {
            shoppingUpdates["customerId"] = customerId
            shoppingUpdates["customerName"] = customerName
        }
        if !jobId.isEmpty {
            shoppingUpdates["category"] = ShoppingListCategory.job.rawValue
            shoppingUpdates["jobId"] = jobId
        }

        do {
            try await purchaseRef.updateData(purchaseUpdates)
            try await shoppingRef.updateData(shoppingUpdates)

            if !previousShoppingItemId.isEmpty && previousShoppingItemId != shoppingItem.id {
                try? await shoppingDocument(companyId: companyId, shoppingItemId: previousShoppingItemId)
                    .updateData(["purchasedItem": "", "updatedAt": now])
            }

            try await recordHistory(
                companyId: companyId,
                purchaseId: purchase.id,
                title: "Shopping list item connected",
                eventType: "shopping_item_connected",
                changes: [
                    historyChange("Shopping Item", from: connectedShoppingItem(for: purchase)?.name ?? "", to: shoppingItem.name),
                    historyChange("Customer", from: purchase.customerName, to: customerName),
                    historyChange("Job", from: purchaseJobLabel(purchase), to: jobId.isEmpty ? purchaseJobLabel(purchase) : "Job connected")
                ].compactMap { $0 }
            )
            await loadData()
        } catch {
            errorMessage = "Could not connect that shopping list item."
            print("[MobilePurchaseReconciliationView][connectShoppingItem] \(error)")
        }
    }

    private func connectCustomer(_ customer: Customer, to purchase: PurchasedItem) async {
        guard !customer.id.isEmpty else { return }

        let nextName = customerDisplayName(customer)
        await performPurchaseUpdate(
            purchase: purchase,
            updates: [
                "customerId": customer.id,
                "customerName": nextName,
                "personalPurchase": false,
                "personalPurchaseAssignedAt": FieldValue.delete(),
                "personalPurchaseAssignedByUserId": FieldValue.delete(),
                "personalPurchaseAssignedByUserName": FieldValue.delete()
            ],
            title: "Purchase customer updated",
            eventType: "customer_updated",
            changes: [
                historyChange("Customer", from: purchase.customerName, to: nextName)
            ].compactMap { $0 },
            shoppingUpdates: [
                "customerId": customer.id,
                "customerName": nextName
            ]
        )
    }

    private func connectJob(_ job: Job, to purchase: PurchasedItem) async {
        guard let companyId = masterDataManager.currentCompany?.id, !job.id.isEmpty else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        let purchaseRef = purchaseDocument(companyId: companyId, purchaseId: purchase.id)
        let previousJobId = firstNonEmpty(purchase.jobId, purchase.workOrderId ?? "", purchase.assignedJobId ?? "")
        let shouldMarkInvoiced = job.billingStatus == .invoiced || job.billingStatus == .paid
        let jobLabel = job.internalId.isEmpty ? job.type : job.internalId
        let now = Timestamp(date: Date())

        var updates: [String: Any] = [
            "jobId": job.id,
            "workOrderId": job.id,
            "assignedJobId": job.id,
            "assignedToJob": true,
            "assignmentStatus": "assignedToJob",
            "billingOwner": "job",
            "jobBillingStatus": shouldMarkInvoiced ? "invoiced" : "handledByJob",
            "jobBillable": purchase.jobBillable ?? purchase.billable,
            "jobBillingRate": purchase.jobBillingRate ?? purchase.billingRate ?? purchase.price,
            "jobInternalId": job.internalId,
            "jobName": job.type,
            "customerId": firstNonEmpty(purchase.customerId, job.customerId),
            "customerName": firstNonEmpty(purchase.customerName, job.customerName),
            "personalPurchase": false,
            "personalPurchaseAssignedAt": FieldValue.delete(),
            "personalPurchaseAssignedByUserId": FieldValue.delete(),
            "personalPurchaseAssignedByUserName": FieldValue.delete(),
            "status": shouldMarkInvoiced ? "Invoiced" : "Connected to Job",
            "updatedAt": now
        ]

        if shouldMarkInvoiced {
            updates["invoiced"] = true
            updates["invoiceStatus"] = "Invoiced"
            updates["invoicedAt"] = now
            updates["jobInvoicedAt"] = now
        }

        do {
            try await purchaseRef.updateData(updates)
            try? await Firestore.firestore()
                .collection("companies")
                .document(companyId)
                .collection("workOrders")
                .document(job.id)
                .updateData(["purchasedItemsIds": FieldValue.arrayUnion([purchase.id])])

            if !previousJobId.isEmpty && previousJobId != job.id {
                try? await Firestore.firestore()
                    .collection("companies")
                    .document(companyId)
                    .collection("workOrders")
                    .document(previousJobId)
                    .updateData(["purchasedItemsIds": FieldValue.arrayRemove([purchase.id])])
            }

            if let shoppingItem = connectedShoppingItem(for: purchase) {
                try? await shoppingDocument(companyId: companyId, shoppingItemId: shoppingItem.id)
                    .updateData([
                        "category": ShoppingListCategory.job.rawValue,
                        "jobId": job.id,
                        "jobName": jobLabel,
                        "customerId": firstNonEmpty(purchase.customerId, job.customerId),
                        "customerName": firstNonEmpty(purchase.customerName, job.customerName),
                        "invoiced": shouldMarkInvoiced || purchase.invoiced,
                        "invoiceStatus": shouldMarkInvoiced ? "Invoiced" : "",
                        "status": shouldMarkInvoiced ? "Invoiced" : ShoppingListStatus.purchased.rawValue,
                        "updatedAt": now
                    ])
            }

            try await recordHistory(
                companyId: companyId,
                purchaseId: purchase.id,
                title: "Purchase job updated",
                eventType: "job_updated",
                changes: [
                    historyChange("Job", from: purchaseJobLabel(purchase), to: jobLabel.isEmpty ? "Job connected" : jobLabel),
                    historyChange("Customer", from: purchase.customerName, to: firstNonEmpty(purchase.customerName, job.customerName)),
                    historyChange("Status", from: purchase.status ?? "", to: shouldMarkInvoiced ? "Invoiced" : "Connected to Job"),
                    shouldMarkInvoiced ? historyChange("Invoiced", from: yesNo(purchase.invoiced), to: "Yes") : nil
                ].compactMap { $0 }
            )
            await loadData()
        } catch {
            errorMessage = "Could not connect that job."
            print("[MobilePurchaseReconciliationView][connectJob] \(error)")
        }
    }

    private func markReturned(_ purchase: PurchasedItem) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            try await PurchasedItemWorkflowService.shared.markReturnedAndDetach(
                purchase: purchase,
                companyId: companyId,
                actorId: actorId,
                actorName: actorName
            )
            await loadData()
        } catch {
            errorMessage = "Could not mark that purchase returned."
            print("[MobilePurchaseReconciliationView][markReturned] \(error)")
        }
    }

    private func markPersonal(_ purchase: PurchasedItem) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            try await PurchasedItemWorkflowService.shared.markPersonalAndDetach(
                purchase: purchase,
                companyId: companyId,
                actorId: actorId,
                actorName: actorName
            )
            await loadData()
        } catch {
            errorMessage = "Could not mark that purchase personal."
            print("[MobilePurchaseReconciliationView][markPersonal] \(error)")
        }
    }

    private func splitPurchase(
        _ purchase: PurchasedItem,
        quantity: Double,
        customer: Customer?,
        job: Job?,
        notes: String
    ) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        do {
            _ = try await PurchasedItemWorkflowService.shared.splitPurchase(
                purchase: purchase,
                companyId: companyId,
                splitQuantity: quantity,
                customer: customer,
                job: job,
                notes: notes,
                actorId: actorId,
                actorName: actorName
            )
            await loadData()
        } catch {
            errorMessage = "Could not split that purchase."
            print("[MobilePurchaseReconciliationView][splitPurchase] \(error)")
        }
    }

    private func performPurchaseUpdate(
        purchase: PurchasedItem,
        updates: [String: Any],
        title: String,
        eventType: String,
        changes: [String],
        shoppingUpdates: [String: Any] = [:]
    ) async {
        guard let companyId = masterDataManager.currentCompany?.id else { return }
        guard !changes.isEmpty else { return }

        isUpdating = true
        errorMessage = nil
        defer { isUpdating = false }

        var updatePayload = updates
        updatePayload["updatedAt"] = Timestamp(date: Date())

        do {
            try await purchaseDocument(companyId: companyId, purchaseId: purchase.id)
                .updateData(updatePayload)

            if !shoppingUpdates.isEmpty, let shoppingItem = connectedShoppingItem(for: purchase) {
                var linkedShoppingUpdates = shoppingUpdates
                linkedShoppingUpdates["updatedAt"] = Timestamp(date: Date())
                try? await shoppingDocument(companyId: companyId, shoppingItemId: shoppingItem.id)
                    .updateData(linkedShoppingUpdates)
            }

            try await recordHistory(
                companyId: companyId,
                purchaseId: purchase.id,
                title: title,
                eventType: eventType,
                changes: changes
            )
            await loadData()
        } catch {
            errorMessage = "Could not save purchase changes."
            print("[MobilePurchaseReconciliationView][performPurchaseUpdate] \(error)")
        }
    }

    private func recordHistory(
        companyId: String,
        purchaseId: String,
        title: String,
        eventType: String,
        changes: [String]
    ) async throws {
        guard !changes.isEmpty else { return }

        let now = Date()
        let historyId = UUID().uuidString
        let purchaseRef = purchaseDocument(companyId: companyId, purchaseId: purchaseId)
        let payload: [String: Any] = [
            "id": historyId,
            "date": Timestamp(date: now),
            "tech": actorName,
            "actorId": actorId,
            "actorName": actorName,
            "source": "mobile",
            "eventType": eventType,
            "title": title,
            "changes": changes,
            "createdAt": Timestamp(date: now)
        ]

        try await purchaseRef.collection("history").document(historyId).setData(payload)
        try await purchaseRef.updateData([
            "lastHistoryEventId": historyId,
            "lastHistoryEventTitle": title,
            "lastHistoryEventType": eventType,
            "lastHistoryEventAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ])
    }

    private func purchaseDocument(companyId: String, purchaseId: String) -> DocumentReference {
        Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("purchasedItems")
            .document(purchaseId)
    }

    private func shoppingDocument(companyId: String, shoppingItemId: String) -> DocumentReference {
        Firestore.firestore()
            .collection("companies")
            .document(companyId)
            .collection("shoppingList")
            .document(shoppingItemId)
    }

    private func purchaseJobLabel(_ purchase: PurchasedItem) -> String {
        firstNonEmpty(purchase.jobInternalId ?? "", purchase.jobName ?? "", purchase.jobId.isEmpty ? "" : "Job connected")
    }

    private func customerDisplayName(_ customer: Customer) -> String {
        if customer.displayAsCompany {
            return firstNonEmpty(customer.company ?? "", "\(customer.firstName) \(customer.lastName)")
        }

        return firstNonEmpty("\(customer.firstName) \(customer.lastName)", customer.company ?? "")
    }

    private func historyChange(_ label: String, from previousValue: String, to nextValue: String) -> String? {
        let previous = compactHistoryValue(previousValue)
        let next = compactHistoryValue(nextValue)
        guard previous != next else { return nil }
        return "\(label): \(previous) -> \(next)"
    }

    private func compactHistoryValue(_ value: String) -> String {
        let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanValue.isEmpty else { return "Blank" }
        guard cleanValue.count > 140 else { return cleanValue }
        return "\(String(cleanValue.prefix(137)))..."
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private func firstNonEmpty(_ values: String...) -> String {
        for value in values {
            let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanValue.isEmpty {
                return cleanValue
            }
        }

        return ""
    }
}

private struct MobilePurchaseReconciliationPurchaseRow: View {
    let purchase: PurchasedItem
    let databaseItem: MobilePurchaseDatabaseItem?
    let connectedShoppingItem: ShoppingListItem?
    let candidateCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: connectedShoppingItem == nil ? "shippingbox" : "link.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(connectedShoppingItem == nil ? Color.orange : Color.poolGreen)
                    .frame(width: 36, height: 36)
                    .background((connectedShoppingItem == nil ? Color.orange : Color.poolGreen).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(purchase.name.isEmpty ? "Unnamed purchase" : purchase.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(purchase.venderName.isEmpty ? "Unknown vendor" : purchase.venderName) | \(shortDate(date: purchase.date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 5) {
                detailLine(title: "Database", value: databaseLabel)
                detailLine(title: "Customer", value: purchase.customerName.isEmpty ? "No customer connected" : purchase.customerName)
                detailLine(title: "Job", value: jobLabel)
                detailLine(title: "Shopping", value: shoppingLabel)
            }

            HStack(spacing: 6) {
                statusChip(
                    title: connectedShoppingItem == nil ? "\(candidateCount) candidate\(candidateCount == 1 ? "" : "s")" : "Connected",
                    tint: connectedShoppingItem == nil ? .orange : .poolGreen
                )
                statusChip(title: purchase.returned == true ? "Returned" : "Not returned", tint: purchase.returned == true ? .orange : .gray)
                statusChip(title: purchase.invoiced ? "Invoiced" : "Not invoiced", tint: purchase.invoiced ? .poolGreen : .poolRed)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private var databaseLabel: String {
        if let databaseItem {
            return databaseItem.name.isEmpty ? "Database item linked" : databaseItem.name
        }

        return purchase.itemId.isEmpty ? "No database item" : "Database item linked"
    }

    private var jobLabel: String {
        if let jobInternalId = purchase.jobInternalId, !jobInternalId.isEmpty {
            return jobInternalId
        }

        if let jobName = purchase.jobName, !jobName.isEmpty {
            return jobName
        }

        return purchase.jobId.isEmpty && (purchase.workOrderId ?? "").isEmpty ? "No job connected" : "Job connected"
    }

    private var shoppingLabel: String {
        connectedShoppingItem?.name ?? "Not connected"
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
    }

    private func statusChip(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

private struct MobilePurchaseReconciliationDetailSheet: View {
    let dataService: any ProductionDataServiceProtocol
    let purchase: PurchasedItem
    let databaseItem: MobilePurchaseDatabaseItem?
    let connectedShoppingItem: ShoppingListItem?
    let shoppingCandidates: [ShoppingListItem]
    let isUpdating: Bool
    let onSaveNotes: (PurchasedItem, String) async -> Void
    let onConnectShoppingItem: (PurchasedItem, ShoppingListItem) async -> Void
    let onConnectCustomer: (PurchasedItem, Customer) async -> Void
    let onConnectJob: (PurchasedItem, Job) async -> Void
    let onMarkReturned: (PurchasedItem) async -> Void
    let onMarkPersonal: (PurchasedItem) async -> Void
    let onSplitPurchase: (PurchasedItem, Double, Customer?, Job?, String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draftNotes: String
    @State private var showingCustomerPicker = false
    @State private var showingJobPicker = false
    @State private var showingSplitSheet = false
    @State private var selectedCustomer = MobilePurchaseReconciliationDefaults.emptyCustomer()
    @State private var selectedJob = MobilePurchaseReconciliationDefaults.emptyJob()

    init(
        dataService: any ProductionDataServiceProtocol,
        purchase: PurchasedItem,
        databaseItem: MobilePurchaseDatabaseItem?,
        connectedShoppingItem: ShoppingListItem?,
        shoppingCandidates: [ShoppingListItem],
        isUpdating: Bool,
        onSaveNotes: @escaping (PurchasedItem, String) async -> Void,
        onConnectShoppingItem: @escaping (PurchasedItem, ShoppingListItem) async -> Void,
        onConnectCustomer: @escaping (PurchasedItem, Customer) async -> Void,
        onConnectJob: @escaping (PurchasedItem, Job) async -> Void,
        onMarkReturned: @escaping (PurchasedItem) async -> Void,
        onMarkPersonal: @escaping (PurchasedItem) async -> Void,
        onSplitPurchase: @escaping (PurchasedItem, Double, Customer?, Job?, String) async -> Void
    ) {
        self.dataService = dataService
        self.purchase = purchase
        self.databaseItem = databaseItem
        self.connectedShoppingItem = connectedShoppingItem
        self.shoppingCandidates = shoppingCandidates
        self.isUpdating = isUpdating
        self.onSaveNotes = onSaveNotes
        self.onConnectShoppingItem = onConnectShoppingItem
        self.onConnectCustomer = onConnectCustomer
        self.onConnectJob = onConnectJob
        self.onMarkReturned = onMarkReturned
        self.onMarkPersonal = onMarkPersonal
        self.onSplitPurchase = onSplitPurchase
        _draftNotes = State(wrappedValue: purchase.notes)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    purchaseDetailLink
                    databaseSection
                    contextSection
                    shoppingSection
                    notesSection
                    actionsSection
                }
                .padding(14)
            }
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Purchase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomerPicker) {
                NavigationStack {
                    CustomerPickerScreen(dataService: dataService, customer: $selectedCustomer)
                }
            }
            .sheet(isPresented: $showingJobPicker) {
                NavigationStack {
                    JobPickerScreen(dataService: dataService, job: $selectedJob)
                }
            }
            .sheet(isPresented: $showingSplitSheet) {
                PurchasedItemSplitSheet(
                    dataService: dataService,
                    purchase: purchase,
                    isUpdating: isUpdating
                ) { quantity, customer, job, notes in
                    await onSplitPurchase(purchase, quantity, customer, job, notes)
                    dismiss()
                }
                .presentationDetents([.medium, .large])
            }
            .onChange(of: selectedCustomer) { customer in
                guard !customer.id.isEmpty else { return }
                Task {
                    await onConnectCustomer(purchase, customer)
                    dismiss()
                }
            }
            .onChange(of: selectedJob) { job in
                guard !job.id.isEmpty else { return }
                Task {
                    await onConnectJob(purchase, job)
                    dismiss()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(purchase.name.isEmpty ? "Unnamed purchase" : purchase.name)
                .font(.title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label(purchase.venderName.isEmpty ? "Unknown vendor" : purchase.venderName, systemImage: "storefront")
                Label(shortDate(date: purchase.date), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

            HStack(spacing: 6) {
                statusChip(title: purchase.billable ? "Billable" : "Not billable", tint: purchase.billable ? .poolGreen : .gray)
                statusChip(title: purchase.invoiced ? "Invoiced" : "Not invoiced", tint: purchase.invoiced ? .poolGreen : .poolRed)
                statusChip(title: purchase.returned == true ? "Returned" : "Not returned", tint: purchase.returned == true ? .orange : .gray)
            }
        }
        .mobileMainCard(material: true)
    }

    private var purchaseDetailLink: some View {
        NavigationLink {
            PurchaseDetailView(purchase: purchase, dataService: dataService)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Purchased Item Detail")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Open the full purchase record")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var databaseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Database Item", systemImage: "square.stack.3d.up")

            Text(databaseItem?.name.isEmpty == false ? databaseItem!.name : (purchase.itemId.isEmpty ? "No database item connected" : "Database item linked"))
                .font(.subheadline.weight(.semibold))

            if let detailLine = databaseItem?.detailLine, !detailLine.isEmpty {
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .mobileMainCard()
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Customer / Job", systemImage: "person.text.rectangle")

            detailLine(title: "Customer", value: purchase.customerName.isEmpty ? "No customer connected" : purchase.customerName)
            detailLine(title: "Job", value: jobLabel)

            HStack(spacing: 8) {
                Button {
                    showingCustomerPicker = true
                } label: {
                    Label(purchase.customerName.isEmpty ? "Add Customer" : "Change Customer", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.bordered)
                .disabled(isUpdating)

                Button {
                    showingJobPicker = true
                } label: {
                    Label(jobLabel == "No job connected" ? "Add Job" : "Change Job", systemImage: "briefcase")
                }
                .buttonStyle(.bordered)
                .disabled(isUpdating)
            }
            .font(.caption.weight(.semibold))

            Button {
                Task {
                    await onMarkPersonal(purchase)
                    dismiss()
                }
            } label: {
                HStack {
                    Label("Mark Personal Purchase", systemImage: "person.crop.circle.badge.checkmark")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isUpdating || purchase.returned == true || purchase.invoiced)
        }
        .mobileMainCard()
    }

    private var shoppingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Shopping List Match", systemImage: "link")

            if let connectedShoppingItem {
                shoppingItemSummary(connectedShoppingItem, connected: true)
            } else if shoppingCandidates.isEmpty {
                Text("No matching shopping list item found. You can still update notes, customer, job, mark it personal, or mark it returned.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(shoppingCandidates.prefix(5)) { item in
                    Button {
                        Task {
                            await onConnectShoppingItem(purchase, item)
                            dismiss()
                        }
                    } label: {
                        shoppingItemSummary(item, connected: false)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUpdating)
                }
            }
        }
        .mobileMainCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Notes", systemImage: "note.text")
                Spacer()
                Button {
                    Task {
                        await onSaveNotes(purchase, draftNotes)
                        dismiss()
                    }
                } label: {
                    Text("Save")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(isUpdating || draftNotes.trimmingCharacters(in: .whitespacesAndNewlines) == purchase.notes.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            TextEditor(text: $draftNotes)
                .frame(minHeight: 110)
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
        }
        .mobileMainCard()
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Status", systemImage: "checklist")

            Button(role: .destructive) {
                Task {
                    await onMarkReturned(purchase)
                    dismiss()
                }
            } label: {
                HStack {
                    Label("Mark Item Returned", systemImage: "arrow.uturn.backward.circle")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(isUpdating || purchase.returned == true)

            Button {
                showingSplitSheet = true
            } label: {
                HStack {
                    Label("Split Purchase", systemImage: "rectangle.split.2x1")
                    Spacer()
                }
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(isUpdating || purchase.returned == true || purchase.invoiced || purchase.quantity <= 0)
        }
        .mobileMainCard()
    }

    private var jobLabel: String {
        if let jobInternalId = purchase.jobInternalId, !jobInternalId.isEmpty {
            return jobInternalId
        }

        if let jobName = purchase.jobName, !jobName.isEmpty {
            return jobName
        }

        return purchase.jobId.isEmpty && (purchase.workOrderId ?? "").isEmpty ? "No job connected" : "Job connected"
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func detailLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private func shoppingItemSummary(_ item: ShoppingListItem, connected: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: connected ? "checkmark.circle.fill" : "cart")
                .font(.body.weight(.semibold))
                .foregroundStyle(connected ? Color.poolGreen : Color.poolBlue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name.isEmpty ? "Unnamed shopping item" : item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text(item.status.rawValue)
                    if let customerName = item.customerName, !customerName.isEmpty {
                        Text(customerName)
                    }
                    if let quantity = item.quantity, !quantity.isEmpty {
                        Text("Qty \(quantity)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background((connected ? Color.poolGreen : Color.poolBlue).opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func statusChip(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

private enum MobilePurchaseReconciliationDefaults {
    static func emptyCustomer() -> Customer {
        Customer(
            id: "",
            firstName: "",
            lastName: "",
            email: "",
            billingAddress: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
            active: true,
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        )
    }

    static func emptyJob() -> Job {
        Job(
            id: "",
            internalId: "",
            type: "",
            dateCreated: Date(),
            description: "",
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: "",
            customerName: "",
            serviceLocationId: "",
            serviceStopIds: [],
            laborContractIds: [],
            adminId: "",
            adminName: "",
            rate: 0,
            laborCost: 0,
            otherCompany: false,
            receivedLaborContractId: "",
            receiverId: "",
            senderId: "",
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: nil,
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
    }
}

private extension Array where Element == ShoppingListItem {
    func uniqueByShoppingItemId() -> [ShoppingListItem] {
        var seen: Set<String> = []

        return filter { item in
            guard !seen.contains(item.id) else { return false }
            seen.insert(item.id)
            return true
        }
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
