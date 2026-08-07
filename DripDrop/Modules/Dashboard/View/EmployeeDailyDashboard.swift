//
//  EmployeeDailyDashboard.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import UniformTypeIdentifiers
import MapKit

private enum EmployeeDailyDashboardRouteViewMode: String, CaseIterable, Identifiable, Hashable {
    case list
    case calendar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .list:
            return "List"
        case .calendar:
            return "Calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .list:
            return "list.bullet.rectangle"
        case .calendar:
            return "calendar.day.timeline.left"
        }
    }
}

struct EmployeeDailyDashboard: View {

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var VM: MobileDailyRouteDisplayViewModel

//    @StateObject var VM: MobileDailyRouteDisplayViewModel
//    init(dataService: any ProductionDataServiceProtocol) {
//        _VM = StateObject(wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService))
//    }

    @State var showRepairSheet: Bool = false
    @State var showNewServiceStop: Bool = false
    @State var showMilage: Bool = false

    @State var enableReorder: Bool = false
    @State var confirmMove: Bool = false
    @State var recievdJobId: String? = nil
    @State var isLoading: Bool = false

    @State var startMilage: String = "0"
    @State var endMilage: String = "0"

    @State var startTime: Date = Date()
    @State var stopList: [ServiceStop] = []
    @State private var showExpandedRouteMap: Bool = false
    @State private var selectedMapStop: ServiceStop? = nil
    @State private var routeMapCameraPosition: MapCameraPosition = .automatic
    @State private var expandedRouteMapCameraPosition: MapCameraPosition = .automatic
    @State private var routeCloseoutPromptedRouteId: String? = nil
    @State private var showPreviousRouteReview: Bool = false
    @State private var routePendingEnd: ActiveRoute? = nil
    @State private var showCreateJobOptions: Bool = false
    @State private var showCreateBlankJob: Bool = false
    @State private var showCreateFromTemplate: Bool = false

    @AppStorage("employeeDailyDashboardRouteViewMode")
    private var routeViewModeRawValue: String = EmployeeDailyDashboardRouteViewMode.list.rawValue


    
    @State var duration: Int = 0
    @State var listOfShoppingListItems: Int = 0

    @State var idItem: IdInfo? = nil

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                toolBarView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        dateSelectionView

                        if shouldUseExperimentalRouteLayout && !VM.previousRoutesNeedingReview.isEmpty {
                            previousRouteReviewSummaryCard
                        }

                        if VM.serviceStopList.isEmpty {
                            noRouteCard
                        } else {
                            routeInfo
//                            routeMapCard

                            if shouldUseExperimentalRouteLayout && !enableReorder && !VM.enableMove {
                                routeViewSelector
                            }

                            if VM.ArOrderIsDifferentThanRrORder {
                                routeOrderDifferenceCard
                            }

                            if enableReorder {
                                modeBanner(
                                    title: "Reorder Mode",
                                    message: "Drag stops into the order you want, then save the route order.",
                                    systemImage: "arrow.up.arrow.down"
                                )

                                reOrderListOfStops
                            } else if VM.enableMove {
                                modeBanner(
                                    title: "Move Mode",
                                    message: "Select one or more unfinished stops to move to another date or technician.",
                                    systemImage: "arrowshape.turn.up.right"
                                )

                                listOfStops
                            } else {
                                selectedRouteViewContent
                            }

                            Color.clear.frame(height: 18)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }

            if isLoading {
                loadingOverlay
            }
        }
        
//        .navigationTitle("Employee Dash")
        .navigationBarBackButtonHidden(true)
        .onReceive(timer) { _ in
            if var duration1 = VM.duration, duration1 > -1 {
                duration1 += 1
                duration = duration1
            }
        }
        .onChange(of: VM.selectedDate) { _, _ in
            if let company = masterDataManager.currentCompany,
               let user = masterDataManager.user {
                VM.start(companyId: company.id, user: user, date: VM.selectedDate)
            }
            refreshShoppingListBadge()
        }
        .onAppear {
            refreshShoppingListBadge()
            loadPreviousRouteReview()
            presentRouteCloseoutIfNeeded()
        }
        .onChange(of: masterDataManager.currentCompany?.id) { _, _ in
            refreshShoppingListBadge()
            loadPreviousRouteReview()
        }
        .onChange(of: masterDataManager.user?.id) { _, _ in
            refreshShoppingListBadge()
            loadPreviousRouteReview()
        }
        .onChange(of: VM.serviceStopList) { _, _ in
            updateRouteMapCamera()
            refreshShoppingListBadge()
            presentRouteCloseoutIfNeeded()
        }
        .onChange(of: VM.activeRoute) { _, _ in
            presentRouteCloseoutIfNeeded()
        }
        .sheet(isPresented: $showExpandedRouteMap) {
            expandedRouteMapSheet
                .presentationDetents([.large])
        }
        .sheet(isPresented: $VM.showEndMilage, onDismiss: {
            routePendingEnd = nil
        }) {
            routeEndMileageSheet
                .presentationDetents([.fraction(0.45), .fraction(0.6), .large])
        }
        .sheet(isPresented: $VM.showMilage) {
            routeStartMileageSheet
                .presentationDetents([.fraction(0.55), .fraction(0.7), .large])
        }
        .sheet(isPresented: $showPreviousRouteReview) {
            previousRouteReviewSheet
                .presentationDetents([.medium, .large])
        }
        .onDisappear {
            VM.selectedDate = Date()
        }
        .alert(
            "Would you like to start this stop?",
            isPresented: serviceStopStartPromptPresentedBinding
        ) {
            Button("Start Stop") {
                VM.confirmPendingServiceStopStart(companyId: masterDataManager.currentCompany?.id)
            }

            Button("Not Now", role: .cancel) {
                VM.dismissPendingServiceStopStartPrompt()
            }
        } message: {
            Text(serviceStopStartPromptMessage)
        }
        .alert(
            "Would you like to end this stop?",
            isPresented: serviceStopEndPromptPresentedBinding
        ) {
            Button("End Stop") {
                VM.confirmPendingServiceStopEnd(companyId: masterDataManager.currentCompany?.id)
            }

            Button("Not Now", role: .cancel) {
                VM.dismissPendingServiceStopEndPrompt()
            }
        } message: {
            Text(serviceStopEndPromptMessage)
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    // MARK: - Helpers
    func getColor(status: String) -> Color {
        switch status {
        case "In Progress": return .orange
        case "Did Not Start": return .black.opacity(0.5)
        case "Traveling": return .poolBlue
        case "Break": return .purple
        case "Finished": return .poolGreen
        default: return .gray
        }
    }

    private var selectedRouteViewMode: EmployeeDailyDashboardRouteViewMode {
        get {
            EmployeeDailyDashboardRouteViewMode(rawValue: routeViewModeRawValue) ?? .list
        }
        nonmutating set {
            routeViewModeRawValue = newValue.rawValue
        }
    }

    private var selectedRouteViewModeBinding: Binding<EmployeeDailyDashboardRouteViewMode> {
        Binding(
            get: { selectedRouteViewMode },
            set: { selectedRouteViewMode = $0 }
        )
    }

    private var serviceStopStartPromptPresentedBinding: Binding<Bool> {
        Binding(
            get: { VM.pendingServiceStopStartPrompt != nil },
            set: { isPresented in
                if !isPresented {
                    VM.dismissPendingServiceStopStartPrompt()
                }
            }
        )
    }

    private var serviceStopStartPromptMessage: String {
        guard let prompt = VM.pendingServiceStopStartPrompt else {
            return ""
        }

        let serviceType = prompt.serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = serviceType.isEmpty ? prompt.customerName : "\(prompt.customerName) - \(serviceType)"

        return "\(title)\nArrived at \(time(date: prompt.arrivalTime))."
    }

    private var serviceStopEndPromptPresentedBinding: Binding<Bool> {
        Binding(
            get: { VM.pendingServiceStopEndPrompt != nil },
            set: { isPresented in
                if !isPresented {
                    VM.dismissPendingServiceStopEndPrompt()
                }
            }
        )
    }

    private var serviceStopEndPromptMessage: String {
        guard let prompt = VM.pendingServiceStopEndPrompt else {
            return ""
        }

        let serviceType = prompt.serviceType.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = serviceType.isEmpty ? prompt.customerName : "\(prompt.customerName) - \(serviceType)"

        return "\(title)\nLeft stop area at \(time(date: prompt.departureTime))."
    }

    private var shouldUseExperimentalRouteLayout: Bool {
        masterDataManager.isFeatureEnabled(.iosReimaginedMain)
    }

    private func refreshShoppingListBadge() {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            listOfShoppingListItems = 0
            return
        }

        Task {
            do {
                let prepKeys = ShoppingPrepKeyBuilder.keysForRoute(
                    serviceStops: VM.serviceStopList,
                    userId: user.id
                )

                guard !prepKeys.isEmpty else {
                    listOfShoppingListItems = 0
                    return
                }

                let routePrepItems = try await dataService.getShoppingListItemsForPrepKeys(
                    companyId: company.id,
                    prepKeys: prepKeys,
                    needsAction: true
                )

                listOfShoppingListItems = routePrepItems.count
            } catch {
                listOfShoppingListItems = 0
                print("[EmployeeDailyDashboard][refreshShoppingListBadge] Error", error)
            }
        }
    }

    private func loadPreviousRouteReview() {
        guard shouldUseExperimentalRouteLayout else { return }
        guard let company = masterDataManager.currentCompany else { return }

        let technicianId =
            masterDataManager.companyUser?.userId ??
            masterDataManager.user?.id ?? ""

        guard !technicianId.isEmpty else { return }

        Task {
            await VM.loadPreviousRouteReview(
                companyId: company.id,
                technicianId: technicianId
            )
        }
    }

    private var selectedStopsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Selected Stops",
                subtitle: "\(VM.selectedServiceStops.count) stop\(VM.selectedServiceStops.count == 1 ? "" : "s") selected.",
                systemImage: "list.bullet"
            )

            if VM.selectedServiceStops.isEmpty {
                emptyStateRow(
                    title: "No stops selected",
                    message: "Select stops from the route before confirming a move.",
                    systemImage: "checklist"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.selectedServiceStops, id: \.id) { stop in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(stop.customerName)
                                    .font(.subheadline.weight(.semibold))
                                
                                Text(stop.address.streetAddress)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            selectedStopStatusPill(stop)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .employeeDashCard()
    }

    private func selectedStopStatusPill(_ stop: ServiceStop) -> some View {
        Label(
            stop.operationStatus.rawValue,
            systemImage: stop.operationStatus == .notFinished ? "circle.dotted" : "checkmark.circle.fill"
        )
        .font(.caption2.weight(.bold))
        .foregroundColor(stopAccentColor(stop))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(stopAccentColor(stop).opacity(0.12), in: Capsule())
    }

    private func modeBanner(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
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
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        )
    }
}
// MARK: - Toolbar
extension EmployeeDailyDashboard {

    var toolBarView: some View {
        HStack(spacing: 10) {
            if UIDevice.isIPhone {
                Button {
                    masterDataManager.selectedCategory = .dashBoard
                    if !navigationManager.routes.isEmpty {
                        navigationManager.routes.removeLast()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
            Button {
                expandedRouteMapCameraPosition = routeMapCameraPosition
                showExpandedRouteMap = true
            } label: {
                Image(systemName: "map")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(routeMapPoints.isEmpty)
            .opacity(routeMapPoints.isEmpty ? 0.45 : 1)
            NavigationLink(value: Route.createRepairRequest(dataService: dataService)) {
                dashboardToolbarIcon(
                    systemImage: "wrench.adjustable.fill",
                    badgeCount: 0
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ShoppingListView(
                    dataService: dataService,
                    routeServiceStops: VM.serviceStopList,
                    routeDate: VM.selectedDate
                )
            } label: {
                dashboardToolbarIcon(
                    systemImage: "cart",
                    badgeCount: listOfShoppingListItems
                )
            }
            .buttonStyle(.plain)

            if masterDataManager.role?.canCreateAnyJob == true {
                Button {
                    showCreateJobOptions = true
                } label: {
                    dashboardToolbarIcon(
                        systemImage: "plus",
                        badgeCount: 0
                    )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showCreateJobOptions) {
                    technicianCreateJobOptionsSheet
                        .presentationDetents([.medium])
                }
                .sheet(isPresented: $showCreateBlankJob) {
                    AddNewJobView(
                        dataService: dataService,
                        customerId: nil,
                        isTechnicianCreateFlow: true,
                        canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                    )
                }
                .sheet(isPresented: $showCreateFromTemplate) {
                    if let company = masterDataManager.currentCompany {
                        JobTemplatePickerCreateJobSheet(
                            companyId: company.id,
                            dataService: dataService,
                            technicianCanAddOnly: true,
                            isTechnicianCreateFlow: true,
                            canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true
                        )
                        .presentationDetents([.large])
                    } else {
                        Text("Missing company.")
                            .presentationDetents([.medium])
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    var technicianCreateJobOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Create Job")
                                    .font(.title3.weight(.semibold))

                                Text(masterDataManager.role?.canCreateBlankJob == true ? "Start blank or use a technician-enabled template." : "Use a technician-enabled job template.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }
                    }
                    .dashboardCreateJobOptionCard()

                    if masterDataManager.role?.canCreateBlankJob == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateBlankJob = true
                            }
                        } label: {
                            technicianJobCreateOptionRow(
                                title: "Blank Job",
                                subtitle: "Create a simplified blank job.",
                                systemImage: "doc.badge.plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if masterDataManager.role?.canCreateJobFromTemplate == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateFromTemplate = true
                            }
                        } label: {
                            technicianJobCreateOptionRow(
                                title: "From Template",
                                subtitle: "Create from a template marked for technicians.",
                                systemImage: "square.stack.3d.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateJobOptions = false
                    }
                }
            }
        }
    }

    func technicianJobCreateOptionRow(
        title: String,
        subtitle: String,
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
                    .foregroundStyle(.primary)

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
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var shoppingListIcon: some View {
        ZStack {
            Image(systemName: "list.clipboard.fill")

            if listOfShoppingListItems > 0 {
                Text("\(listOfShoppingListItems)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .clipShape(Circle())
                    .offset(x: 10, y: -10)
            }
        }
    }
}

// MARK: - Date Selector
extension EmployeeDailyDashboard {
    var dateSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route Date")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(weekDay(date: VM.selectedDate))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                DatePicker("", selection: $VM.selectedDate, displayedComponents: .date)
                    .labelsHidden()
            }

            HStack(spacing: 10) {
                Button {
                    VM.selectedDate = Calendar.current.date(
                        byAdding: .day,
                        value: -1,
                        to: VM.selectedDate
                    ) ?? VM.selectedDate
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    VM.selectedDate = Date()
                } label: {
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    VM.selectedDate = Calendar.current.date(
                        byAdding: .day,
                        value: 1,
                        to: VM.selectedDate
                    ) ?? VM.selectedDate
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .employeeDashCard(padding: 12)
    }}

// MARK: - Route View Selector
extension EmployeeDailyDashboard {
    private var routeViewSelector: some View {
        Picker("Route View", selection: selectedRouteViewModeBinding) {
            ForEach(EmployeeDailyDashboardRouteViewMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.small)
        .employeeDashCard(material: true, padding: 8)
    }
}

// MARK: - Previous Route Review
extension EmployeeDailyDashboard {
    private var previousRouteReviewSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 38, height: 38)
                    .background(Color.orange.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Previous Routes Need Review")
                        .font(.subheadline.weight(.semibold))

                    Text("\(VM.previousRoutesNeedingReview.count) previous route\(VM.previousRoutesNeedingReview.count == 1 ? "" : "s") need to be finished or reviewed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                routeStatusBadge("\(VM.previousRoutesNeedingReview.count)")
            }

            Button {
                showPreviousRouteReview = true
            } label: {
                actionButton(
                    title: "Review Previous Routes",
                    systemImage: "calendar.badge.clock",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)
        }
        .employeeDashCard()
    }

    private var previousRouteReviewSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        sectionHeader(
                            title: "Previous Routes",
                            subtitle: "Finish older routes that were not stopped or are missing mileage.",
                            systemImage: "clock.arrow.circlepath"
                        )
                        .employeeDashCard(material: true)

                        if VM.previousRoutesNeedingReview.isEmpty {
                            emptyStateRow(
                                title: "No previous route issues",
                                message: "Older routes that need closeout will appear here.",
                                systemImage: "checkmark.circle"
                            )
                            .employeeDashCard()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(VM.previousRoutesNeedingReview) { route in
                                    previousRouteReviewRow(route)
                                }
                            }
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Previous Routes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showPreviousRouteReview = false
                    }
                }
            }
        }
    }

    private func previousRouteReviewRow(_ route: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: previousRouteIssueIcon(route))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name.isEmpty ? "Previous Route" : route.name)
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
                    openPreviousRouteDay(route)
                } label: {
                    actionButton(
                        title: "Open Day",
                        systemImage: "calendar",
                        tint: .accentColor
                    )
                }
                .buttonStyle(.plain)

                Button {
                    prepareToEndPreviousRoute(route)
                } label: {
                    actionButton(
                        title: "Complete",
                        systemImage: "stop.circle",
                        tint: .red
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.orange.opacity(0.18), lineWidth: 1)
        )
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

    private func openPreviousRouteDay(_ route: ActiveRoute) {
        showPreviousRouteReview = false
        routePendingEnd = nil
        VM.selectedDate = route.date
    }

    private func prepareToEndPreviousRoute(_ route: ActiveRoute) {
        routePendingEnd = route
        prepareEndMileageInput(for: route)
        showPreviousRouteReview = false

        Task { @MainActor in
            await Task.yield()
            VM.showEndMilage = true
        }
    }
}

// MARK: - Route Info
extension EmployeeDailyDashboard {
    var routeInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let activeRoute = VM.activeRoute {
                HStack(alignment: .center, spacing: 10) {
                    routeProgressRing(activeRoute)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(activeRoute.name.isEmpty ? "Today’s Route" : activeRoute.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)

                            Spacer(minLength: 4)

                            routeStatusBadge(activeRoute.status.rawValue)
                        }

                        Text("\(activeRoute.finishedStops) of \(activeRoute.totalStops) stops complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                routeMetricGrid(activeRoute)

                if routeNeedsStartMileage(activeRoute) {
                    Divider().opacity(0.25)
                    routeStartMileageCard(activeRoute)
                }

                if routeNeedsCloseout(activeRoute) {
                    if !routeNeedsStartMileage(activeRoute) {
                        Divider().opacity(0.25)
                    }
                    routeCloseoutCard(activeRoute)
                }

                routeActionButtons
            }
        }
        .employeeDashCard(padding: 12)
    }
    private var routeActionButtons: some View {
        HStack(spacing: 8) {

            if !VM.enableMove && !enableReorder {
                Button {
                    VM.autoOrderServiceStopsForRoute()
                    enableReorder = true
                } label: {
                    routeSummaryButton(
                        title: "Reorder",
                        systemImage: "arrow.up.arrow.down",
                        foreground: .accentColor,
                        background: Color.accentColor.opacity(0.12)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    VM.enableMove = true
                } label: {
                    routeSummaryButton(
                        title: "Move",
                        systemImage: "arrowshape.turn.up.right",
                        foreground: .accentColor,
                        background: Color.accentColor.opacity(0.12)
                    )
                }
                .buttonStyle(.plain)
            }

            if enableReorder {
                Button(action: { enableReorder = false}, label: {
                    routeSummaryButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        foreground: .red,
                        background: Color.red.opacity(0.12)
                    )
                })
                .buttonStyle(.plain)

                Button(action: {
                    VM.reorderServiceStops(companyId: masterDataManager.currentCompany?.id)
                    enableReorder = false
                }, label: {
                    routeSummaryButton(
                        title: "Save",
                        systemImage: "checkmark",
                        foreground: .white,
                        background: Color.accentColor
                    )
                })
                .buttonStyle(.plain)
            }

            if VM.enableMove {
                Button(action: {
                    VM.cancelMove()
                    VM.enableMove = false
                }, label: {
                    routeSummaryButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        foreground: .red,
                        background: Color.red.opacity(0.12)
                    )
                })
                .buttonStyle(.plain)

                Button(action: {
                    confirmMove.toggle()
                }, label: {
                    routeSummaryButton(
                        title: "Confirm",
                        systemImage: "checkmark",
                        foreground: VM.selectedServiceStops.isEmpty ? Color.secondary : .white,
                        background: VM.selectedServiceStops.isEmpty ? Color.secondary.opacity(0.12) : Color.accentColor
                    )
                })
                .buttonStyle(.plain)
                .disabled(VM.selectedServiceStops.isEmpty)
                .sheet(isPresented: $confirmMove) {
                    moveConfirmationSheet
                        .presentationDetents([.large])
                }
            }
        }
    }

    private func routeSummaryButton(
        title: String,
        systemImage: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }
}

// MARK: - Route Start
extension EmployeeDailyDashboard {
    private func routeNeedsStartMileage(_ route: ActiveRoute) -> Bool {
        route.status == .didNotStart ||
        (route.status != .finished && route.startMilage == nil)
    }

    private func routeStartMileageCard(_ route: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: route.status == .didNotStart ? "play.circle" : "gauge.with.dots.needle.bottom.50percent")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(route.status == .didNotStart ? "Start Route" : "Add Start Mileage")
                        .font(.subheadline.weight(.semibold))

                    Text(route.status == .didNotStart
                         ? "Select a vehicle and enter starting mileage before beginning this route."
                         : "This route is missing starting mileage. Add it before route closeout.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                prepareStartMileageInput(for: route)
                VM.showMilage = true
            } label: {
                actionButton(
                    title: route.status == .didNotStart ? "Start Route" : "Enter Start Mileage",
                    systemImage: route.status == .didNotStart ? "play.fill" : "gauge.with.dots.needle.bottom.50percent",
                    tint: .accentColor
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeStartMileageSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        sectionHeader(
                            title: VM.activeRoute?.status == .didNotStart ? "Start Route" : "Start Mileage",
                            subtitle: "Choose the vehicle and enter the odometer reading for this route.",
                            systemImage: "play.circle"
                        )
                        .employeeDashCard(material: true)

                        routeStartVehiclePickerCard

                        if VM.selectedVehical.id.isEmpty {
                            routeStartEmptyVehicleCard
                        } else {
                            routeStartMileageInputCard
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(14)
                }
            }
            .navigationTitle(VM.activeRoute?.status == .didNotStart ? "Start Route" : "Start Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        VM.showMilage = false
                    }
                }
            }
        }
    }

    private var routeStartVehiclePickerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Vehicle",
                subtitle: "Attach the company or personal vehicle being used for the route.",
                systemImage: "car"
            )

            Button {
                VM.showVehicalPicker.toggle()
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
                            VM.selectedVehical.id.isEmpty
                            ? "Pick Vehicle"
                            : "\(VM.selectedVehical.nickName) \(VM.selectedVehical.plate)"
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
            .sheet(isPresented: $VM.showVehicalPicker) {
                VehicalPickerView(
                    dataService: dataService,
                    vehical: $VM.selectedVehical,
                    companyUser: VM.currentCompanyUser
                )
            }
        }
        .employeeDashCard()
    }

    private var routeStartEmptyVehicleCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "car")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Pick a vehicle first")
                    .font(.subheadline.weight(.semibold))

                Text("Starting mileage is tied to the selected vehicle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeStartMileageInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Mileage",
                subtitle: "Use the current odometer reading before the route begins.",
                systemImage: "number"
            )

            HStack {
                Text("Recent Mileage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(
                    Measurement(
                        value: VM.selectedVehical.miles,
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

                MilesField(text: $VM.inputStartMilage)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let routeStartMileageWarningText {
                Text(routeStartMileageWarningText)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                submitActiveRouteStartMileage()
            } label: {
                Label(VM.activeRoute?.status == .didNotStart ? "Start Route" : "Submit Start Mileage", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmitActiveRouteStartMileage)
            .opacity(canSubmitActiveRouteStartMileage ? 1.0 : 0.55)
        }
        .employeeDashCard()
    }

    private func prepareStartMileageInput(for route: ActiveRoute) {
        if let startMilage = route.startMilage {
            VM.inputStartMilage = String(startMilage)
        } else if !VM.selectedVehical.id.isEmpty {
            VM.inputStartMilage = String(VM.selectedVehical.miles)
        } else {
            VM.inputStartMilage = ""
        }
    }

    private var parsedActiveRouteStartMileage: Double? {
        Double(VM.inputStartMilage.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var canSubmitActiveRouteStartMileage: Bool {
        guard !VM.selectedVehical.id.isEmpty,
              let startMileage = parsedActiveRouteStartMileage else {
            return false
        }

        return startMileage >= 0
    }

    private var routeStartMileageWarningText: String? {
        if VM.selectedVehical.id.isEmpty {
            return "Select a vehicle first."
        }

        guard let startMileage = parsedActiveRouteStartMileage else {
            return "Enter a valid starting mileage."
        }

        return startMileage >= 0 ? nil : "Starting mileage cannot be negative."
    }

    private func submitActiveRouteStartMileage() {
        guard canSubmitActiveRouteStartMileage else { return }
        guard let route = VM.activeRoute else { return }

        VM.updateRouteStartMilage(companyId: masterDataManager.currentCompany?.id)

        if route.status == .didNotStart {
            VM.startActiveRoute(
                companyId: masterDataManager.currentCompany?.id,
                companyName: masterDataManager.currentCompany?.name,
                user: masterDataManager.user,
                showMileageSheet: false
            )
        }

        VM.showMilage = false
    }
}

// MARK: - Route Closeout
extension EmployeeDailyDashboard {
    private func routeNeedsCloseout(_ route: ActiveRoute) -> Bool {
        route.totalStops > 0 &&
        route.finishedStops == route.totalStops &&
        (route.endMilage == nil || route.endTime == nil)
    }

    private func presentRouteCloseoutIfNeeded() {
        guard let route = VM.activeRoute, routeNeedsCloseout(route) else { return }
        guard routeCloseoutPromptedRouteId != route.id else { return }

        routePendingEnd = nil
        routeCloseoutPromptedRouteId = route.id
        prepareEndMileageInput(for: route)
        VM.showEndMilage = true
    }

    private func prepareEndMileageInput(for route: ActiveRoute) {
        if let endMilage = route.endMilage {
            VM.inputEndMilage = String(endMilage)
        } else if let startMilage = route.startMilage {
            VM.inputEndMilage = String(startMilage)
        } else if VM.startMilage > 0 {
            VM.inputEndMilage = String(VM.startMilage)
        } else {
            VM.inputEndMilage = ""
        }
    }

    private func routeCloseoutCard(_ route: ActiveRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 34, height: 34)
                    .background(Color.orange.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("Finish Route Mileage")
                        .font(.subheadline.weight(.semibold))

                    Text("All stops are complete. Enter ending mileage to close this route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                routePendingEnd = nil
                prepareEndMileageInput(for: route)
                VM.showEndMilage = true
            } label: {
                actionButton(
                    title: "Enter End Mileage",
                    systemImage: "gauge.with.dots.needle.bottom.50percent",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeEndMileageSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader(
                                title: routeEndMileageSheetTitle,
                                subtitle: routeEndMileageSheetSubtitle,
                                systemImage: "flag.checkered"
                            )
                        }
                        .employeeDashCard(material: true)

                        routeEndMileageInputCard
                    }
                    .padding(14)
                }
            }
            .navigationTitle(routeEndMileageSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        VM.showEndMilage = false
                        routePendingEnd = nil
                    }
                }
            }
        }
    }

    private var routeEndMileageInputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Route Start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(
                    Measurement(
                        value: displayedStartMileageForCloseout,
                        unit: UnitLength.miles
                    )
                    .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
                )
                .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("End Mileage")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MilesField(text: $VM.inputEndMilage)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if let routeEndMileageWarningText {
                Text(routeEndMileageWarningText)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                submitActiveRouteEndMileage()
            } label: {
                Label(routeEndMileageSubmitTitle, systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canSubmitActiveRouteEndMileage)
            .opacity(canSubmitActiveRouteEndMileage ? 1.0 : 0.55)
        }
        .employeeDashCard()
    }

    private var routeBeingEnded: ActiveRoute? {
        routePendingEnd ?? VM.activeRoute
    }

    private var isEditingFinishedRouteEndMileage: Bool {
        guard let route = routeBeingEnded else { return false }
        return route.status == .finished && route.endTime != nil && route.endMilage != nil
    }

    private var routeEndMileageSheetTitle: String {
        isEditingFinishedRouteEndMileage ? "Edit End Mileage" : "End Mileage"
    }

    private var routeEndMileageSheetSubtitle: String {
        isEditingFinishedRouteEndMileage
        ? "Correct the ending mileage for this finished route."
        : "Enter the ending mileage to finish the route."
    }

    private var routeEndMileageSubmitTitle: String {
        isEditingFinishedRouteEndMileage ? "Save End Mileage" : "Submit End Mileage"
    }

    private var displayedStartMileageForCloseout: Double {
        routeBeingEnded?.startMilage ?? VM.startMilage
    }

    private var parsedActiveRouteEndMileage: Double? {
        Double(VM.inputEndMilage.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var canSubmitActiveRouteEndMileage: Bool {
        guard let endMileage = parsedActiveRouteEndMileage else { return false }

        if displayedStartMileageForCloseout > 0 {
            return endMileage >= displayedStartMileageForCloseout
        }

        return endMileage >= 0
    }

    private var routeEndMileageWarningText: String? {
        guard let endMileage = parsedActiveRouteEndMileage else {
            return "Enter a valid ending mileage."
        }

        if displayedStartMileageForCloseout > 0,
           endMileage < displayedStartMileageForCloseout {
            return "Ending mileage cannot be less than starting mileage."
        }

        return nil
    }

    private func submitActiveRouteEndMileage() {
        guard canSubmitActiveRouteEndMileage else { return }
        guard let route = routeBeingEnded else { return }
        let isCurrentRoute = route.id == VM.activeRoute?.id
        let shouldStopRoute = route.status != .finished || route.endTime == nil

        VM.updateRouteEndtMilage(
            companyId: masterDataManager.currentCompany?.id,
            route: route,
            syncSelectedVehicle: isCurrentRoute
        )

        if shouldStopRoute {
            VM.stopActiveRoute(
                companyId: masterDataManager.currentCompany?.id,
                companyName: masterDataManager.currentCompany?.name,
                user: masterDataManager.user,
                route: route
            )
        }

        VM.showEndMilage = false
        routePendingEnd = nil
        routeCloseoutPromptedRouteId = nil
        loadPreviousRouteReview()
    }
}

// MARK: - Stops List
extension EmployeeDailyDashboard {
    @ViewBuilder
    private var selectedRouteViewContent: some View {
        if !shouldUseExperimentalRouteLayout {
            listOfStops
        } else {
            switch selectedRouteViewMode {
            case .list:
                listOfStops
            case .calendar:
                routeCalendarDashboard
            }
        }
    }

    var listOfStops: some View {
        LazyVStack(spacing: 10) {
            ForEach(Array(VM.serviceStopList.enumerated()), id: \.element.id) { index, stop in
                if VM.enableMove {
                    Button {
                        if VM.selectedServiceStops.contains(stop) {
                            VM.selectedServiceStops.removeAll { $0 == stop }
                        } else {
                            VM.selectedServiceStops.append(stop)
                        }
                    } label: {
                        stopCardWrapper(
                            stop: stop,
                            index: index,
                            isSelected: VM.selectedServiceStops.contains(stop),
                            isReorderMode: false
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        navigationManager.push(to: Route.dailyDisplayStop(
                            dataService: dataService,
                            serviceStop: stop
                        ))
                    } label: {
                        stopCardWrapper(
                            stop: stop,
                            index: index,
                            isSelected: false,
                            isReorderMode: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    var reOrderListOfStops: some View {
        
        LazyVStack(spacing: 8) {
            ForEach(VM.serviceStopList) { stop in
                    //For Re ordering stops
                Group{
                    ZStack{
                        Rectangle()
                            .padding(.horizontal,6)
                            .padding(.vertical,4)
                            .background(VM.selectedServiceStops.contains(stop) ? Color.poolBlue : Color.poolGray)
                            .cornerRadius(16)
                            .foregroundColor(Color.clear)
                            .fontDesign(.monospaced)
                            .opacity(0.5)
                        RouteStopCardView(
                            dataService: dataService,
                            stop: stop,
                            index: VM.serviceStopList.firstIndex(of: stop) ?? 0
                        )
                        .disabled(true)
                    }
                    .onDrag({
                        VM.draggedStop = stop
                        return NSItemProvider(item: nil, typeIdentifier: stop.id)
                    })
                    .onDrop(of: [UTType.text], delegate: MyDropDelegate(targetStop: stop, stopList: $VM.serviceStopList, draggedStop: $VM.draggedStop))
                }
                .padding(8)
            }
            .padding(.horizontal)
        }
    }

    private var routeCalendarDashboard: some View {
        EmployeeRouteCalendarDashboard(
            selectedDate: VM.selectedDate,
            activeRoute: VM.activeRoute,
            serviceStops: VM.serviceStopList
        ) { stop in
            navigationManager.push(to: Route.dailyDisplayStop(
                dataService: dataService,
                serviceStop: stop
            ))
        }
    }

    private var moveConfirmationSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(
                                title: "Move Selected Stops",
                                subtitle: "\(VM.selectedServiceStops.count) selected for \(VM.selectedTech.id.isEmpty ? "reassignment" : VM.selectedTech.userName).",
                                systemImage: "arrow.triangle.swap"
                            )

                            moveTypeSelector
                        }
                        .employeeDashCard(material: true)

                        if VM.moveType == "One Time" {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(
                                    title: "One-Time Move",
                                    subtitle: "Move only this route occurrence.",
                                    systemImage: "calendar"
                                )

                                moveDatePickerRow

                                employeePickerRow

                                submitMoveButton {
                                    VM.moveServiceStops(companyId: masterDataManager.currentCompany?.id)
                                    confirmMove = false
                                }
                            }
                            .employeeDashCard()
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(
                                    title: "Permanent Move",
                                    subtitle: "Update the recurring route going forward.",
                                    systemImage: "repeat"
                                )

                                permanentDayPickerRow

                                Text("If the selected day has already passed this week, changes will apply next week.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                employeePickerRow

                                submitMoveButton {
                                    VM.moveServiceStopsPermanently(companyId: masterDataManager.currentCompany?.id)
                                    confirmMove = false
                                }
                            }
                            .employeeDashCard()
                        }

                        selectedStopsPreviewCard
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Confirm Move")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        confirmMove = false
                    }
                }
            }
        }
    }

    private var moveTypeSelector: some View {
        HStack(spacing: 10) {
            moveTypeButton(
                title: "One Time",
                subtitle: "This route only",
                systemImage: "calendar.badge.clock"
            )

            moveTypeButton(
                title: "Permanent",
                subtitle: "Future route",
                systemImage: "repeat.circle"
            )
        }
    }

    private func moveTypeButton(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        let isSelected = VM.moveType == title

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                VM.moveType = title
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .frame(width: 30, height: 30)
                    .foregroundColor(isSelected ? .white : Color.accentColor)
                    .background(
                        isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color.accentColor.opacity(0.12)),
                        in: Circle()
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(isSelected ? Color.white.opacity(0.86) : Color.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.thinMaterial),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var moveDatePickerRow: some View {
        moveFieldRow(title: "Move Date", systemImage: "calendar") {
            DatePicker(
                "Move Date",
                selection: $VM.moveDate,
                in: Date()...,
                displayedComponents: .date
            )
            .labelsHidden()
        }
    }

    private var permanentDayPickerRow: some View {
        moveFieldRow(title: "Day of Week", systemImage: "calendar.badge.plus") {
            Picker("Day of Week", selection: $VM.newDay) {
                ForEach(DaysOfWeek.allCases) { day in
                    Text(day.rawValue).tag(day)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func moveFieldRow<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 8)

            content()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var employeePickerRow: some View {
        moveFieldRow(title: "Employee", systemImage: "person.crop.circle") {
            Picker("Employee", selection: $VM.selectedTech) {
                Text("Select User").tag(CompanyUser(
                    id: "",
                    userId: "",
                    userName: "",
                    roleId: "",
                    roleName: "",
                    dateCreated: Date(),
                    status: .active,
                    workerType: .notAssigned
                ))

                ForEach(VM.companyUsers) { user in
                    Text(user.userName).tag(user)
                }
            }
            .pickerStyle(.menu)
        }
    }

    
    private func submitMoveButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label("Submit Move", systemImage: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(canSubmitMove ? .white : .secondary)
                .background(canSubmitMove ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmitMove)
    }

    private var canSubmitMove: Bool {
        !VM.selectedTech.id.isEmpty && !VM.selectedServiceStops.isEmpty
    }
}
extension EmployeeDailyDashboard {

    private func routeProgressRing(_ activeRoute: ActiveRoute) -> some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 5)
                .frame(width: 48, height: 48)

            Circle()
                .trim(
                    from: 0,
                    to: Double(activeRoute.finishedStops) / Double(max(activeRoute.totalStops, 1))
                )
                .stroke(
                    Color.poolGreen,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 48, height: 48)

            VStack(spacing: 1) {
                Text("\(activeRoute.finishedStops)")
                    .font(.caption.weight(.bold))

                Text("of \(activeRoute.totalStops)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
    }

    private func routeMetricGrid(_ activeRoute: ActiveRoute) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            if let startTime = activeRoute.startTime {
                metricRow(
                    title: "Time",
                    value: timeRangeText(start: startTime, end: activeRoute.endTime),
                    detail: timeDifferenceText(start: startTime, end: activeRoute.endTime),
                    systemImage: "clock"
                )
            }

            if let startMilage = activeRoute.startMilage {
                mileageMetricRow(activeRoute, startMilage: startMilage)
            }

            if activeRoute.durationMin > 0 {
                metricRow(
                    title: "Planned Duration",
                    value: displayMinAsMinAndHour(min: activeRoute.durationMin),
                    detail: nil,
                    systemImage: "timer"
                )
            }

            if activeRoute.distanceMiles > 0 {
                metricRow(
                    title: "Distance",
                    value: Measurement(value: activeRoute.distanceMiles, unit: UnitLength.miles)
                        .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale)),
                    detail: nil,
                    systemImage: "road.lanes"
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
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func mileageMetricRow(_ activeRoute: ActiveRoute, startMilage: Double) -> some View {
        let value = mileageRangeText(start: startMilage, end: activeRoute.endMilage)
        let detail = mileageDifferenceText(start: startMilage, end: activeRoute.endMilage)
        let systemImage = "gauge.with.dots.needle.bottom.50percent"

        if canEditEndMileage(for: activeRoute) {
            Button {
                beginEditingEndMileage(for: activeRoute)
            } label: {
                metricRow(
                    title: "Mileage",
                    value: value,
                    detail: detail,
                    systemImage: systemImage
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(10)
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit end mileage")
        } else {
            metricRow(
                title: "Mileage",
                value: value,
                detail: detail,
                systemImage: systemImage
            )
        }
    }

    private func canEditEndMileage(for route: ActiveRoute) -> Bool {
        route.status == .finished && route.endMilage != nil
    }

    private func beginEditingEndMileage(for route: ActiveRoute) {
        routePendingEnd = route
        prepareEndMileageInput(for: route)
        VM.showEndMilage = true
    }

    private func mileageRangeText(start: Double, end: Double?) -> String {
        let startText = Measurement(value: start, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))

        guard let end else {
            return startText
        }

        let endText = Measurement(value: end, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))

        return "\(startText) → \(endText)"
    }

    private func mileageDifferenceText(start: Double, end: Double?) -> String? {
        guard let end else { return nil }

        return Measurement(value: end - start, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
    }

    private func timeRangeText(start: Date, end: Date?) -> String {
        guard let end else {
            return time(date: start)
        }

        return "\(time(date: start)) → \(time(date: end))"
    }

    private func timeDifferenceText(start: Date, end: Date?) -> String? {
        guard let end else { return nil }

        return displayMinAsMinAndHour(
            min: minBetween(start: start, end: end)
        )
    }
}
extension EmployeeDailyDashboard {

    private var noRouteCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No Route")
                .font(.headline.weight(.semibold))

            Text("There are no service stops assigned for this date.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .employeeDashCard()
    }

    private var routeOrderDifferenceCard: some View {
        HStack(spacing: 8) {
            Button {
                VM.resetOrderToMatchRecurringRoute(companyId: masterDataManager.currentCompany?.id)
            } label: {
                routeSummaryButton(
                    title: "Reset Order",
                    systemImage: "arrow.uturn.backward",
                    foreground: .orange,
                    background: Color.orange.opacity(0.12)
                )
            }
            .buttonStyle(.plain)

            Button {
                VM.reorderServiceStopsPermanently(companyId: masterDataManager.currentCompany?.id)
            } label: {
                routeSummaryButton(
                    title: "Update Default",
                    systemImage: "checkmark.circle",
                    foreground: .green,
                    background: Color.green.opacity(0.12)
                )
            }
            .buttonStyle(.plain)
        }
        .employeeDashCard(padding: 12)
    }

    private func stopCardWrapper(
        stop: ServiceStop,
        index: Int,
        isSelected: Bool,
        isReorderMode: Bool
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            RouteStopCardView(
                dataService: dataService,
                stop: stop,
                index: index
            )
            .disabled(isReorderMode || VM.enableMove)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .padding(10)
            }

            if isReorderMode {
                Image(systemName: "line.3.horizontal")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(10)
            }

            if stop.operationStatus != .notFinished {
                statusBadge(stop)
                    .padding(.top, isSelected ? 42 : 10)
                    .padding(.trailing, 10)
            }
        }
        .padding(6)
        .background(
            stopBackgroundColor(stop, isSelected: isSelected),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isSelected ? Color.accentColor.opacity(0.35) : stopBorderColor(stop),
                    lineWidth: stop.operationStatus == .notFinished ? 1 : 2
                )
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(stopAccentColor(stop))
                .frame(width: stop.operationStatus == .notFinished ? 4 : 7)
                .padding(.vertical, 12)
        }
    }

    private func stopBackgroundColor(
        _ stop: ServiceStop,
        isSelected: Bool
    ) -> Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        }

        switch stop.operationStatus {
        case .finished:
            return Color.poolGreen.opacity(colorScheme == .dark ? 0.32 : 0.22)

        case .notFinished:
            return Color.primary.opacity(0.035)

        case .skipped:
            return Color.orange.opacity(colorScheme == .dark ? 0.34 : 0.24)
        }
    }

    private func stopBorderColor(_ stop: ServiceStop) -> Color {
        switch stop.operationStatus {
        case .finished:
            return Color.poolGreen.opacity(0.82)

        case .notFinished:
            return Color.primary.opacity(0.06)

        case .skipped:
            return Color.orange.opacity(0.88)
        }
    }

    private func stopAccentColor(_ stop: ServiceStop) -> Color {
        switch stop.operationStatus {
        case .finished:
            return .poolGreen
        case .notFinished:
            return .secondary.opacity(0.35)
        case .skipped:
            return .orange
        }
    }

    private func statusBadge(_ stop: ServiceStop) -> some View {
        Label(
            stop.operationStatus.rawValue,
            systemImage: stop.operationStatus == .finished ? "checkmark.circle.fill" : "forward.end.fill"
        )
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(stopAccentColor(stop), in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
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

    private func routeStatusBadge(_ status: String) -> some View {
        Text(status)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(getColor(status: status), in: Capsule())
    }

    private func actionButton(
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
                tint == .accentColor ? tint : tint.opacity(0.13),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }

    private func dashboardToolbarIcon(
        systemImage: String,
        badgeCount: Int
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())

            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 18, minHeight: 18)
                    .padding(2)
                    .background(Color.red, in: Circle())
                    .offset(x: 5, y: -5)
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.10)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading route...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
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
            }

            Spacer()
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
// MARK: - Route Map
extension EmployeeDailyDashboard {
    private var routeMapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                sectionHeader(
                    title: "Route Map",
                    subtitle: routeMapSubtitle,
                    systemImage: "map"
                )

                Spacer()

                Button {
                    expandedRouteMapCameraPosition = routeMapCameraPosition
                    showExpandedRouteMap = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(routeMapPoints.isEmpty)
                .opacity(routeMapPoints.isEmpty ? 0.45 : 1)
            }

            routeMapView(position: $routeMapCameraPosition, height: 240)

            if let selectedMapStop {
                selectedMapStopRow(selectedMapStop)
            }

            if missingCoordinateCount > 0 {
                emptyStateRow(
                    title: "\(missingCoordinateCount) stop\(missingCoordinateCount == 1 ? "" : "s") missing map location",
                    message: "Add coordinates to the service stop address to show it on the route map.",
                    systemImage: "location.slash"
                )
            }
        }
        .employeeDashCard()
        .onAppear {
            updateRouteMapCamera()
        }
    }

    private var expandedRouteMapSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 12) {
                    routeMapView(position: $expandedRouteMapCameraPosition, height: 420)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(routeMapPoints) { point in
                                Button {
                                    selectedMapStop = point.stop
                                    expandedRouteMapCameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: point.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    )
                                } label: {
                                    routeMapStopRow(point)
                                }
                                .buttonStyle(.plain)
                            }

                            Color.clear.frame(height: 18)
                        }
                        .padding(.horizontal, 14)
                    }
                }
            }
            .navigationTitle("Route Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showExpandedRouteMap = false
                    }
                }
            }
            .onAppear {
                expandedRouteMapCameraPosition = routeMapCameraPosition
            }
        }
    }

    private func routeMapView(
        position: Binding<MapCameraPosition>,
        height: CGFloat
    ) -> some View {
        ZStack {
            if routeMapPoints.isEmpty {
                emptyMapState
            } else {
                Map(position: position) {
                    if routePolylineCoordinates.count > 1 {
                        MapPolyline(coordinates: routePolylineCoordinates)
                            .stroke(
                                Color.poolBlue,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                            )
                    }

                    ForEach(routeMapPoints) { point in
                        Annotation(point.title, coordinate: point.coordinate, anchor: .bottom) {
                            Button {
                                selectedMapStop = point.stop
                            } label: {
                                routeMapPin(point)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func routeMapPin(_ point: TechnicianRouteMapPoint) -> some View {
        VStack(spacing: 0) {
            Text("\(point.order)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(routeMapPinColor(point.stop), in: Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: selectedMapStop?.id == point.stop.id ? 3 : 2)
                )

            Image(systemName: "triangle.fill")
                .font(.system(size: 9))
                .foregroundStyle(routeMapPinColor(point.stop))
                .rotationEffect(.degrees(180))
                .offset(y: -2)
        }
        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
    }

    private var emptyMapState: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No mapped stops")
                .font(.subheadline.weight(.semibold))

            Text("Stops with saved latitude and longitude will appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.035))
    }

    private func selectedMapStopRow(_ stop: ServiceStop) -> some View {
        Button {
            navigationManager.push(to: Route.dailyDisplayStop(
                dataService: dataService,
                serviceStop: stop
            ))
            showExpandedRouteMap = false
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(routeMapPinColor(stop))

                VStack(alignment: .leading, spacing: 3) {
                    Text(stop.customerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(stop.address.streetAddress)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    }

    private func routeMapStopRow(_ point: TechnicianRouteMapPoint) -> some View {
        HStack(spacing: 12) {
            Text("\(point.order)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(routeMapPinColor(point.stop), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(point.stop.customerName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(point.stop.address.streetAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(point.stop.operationStatus.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var routeMapSubtitle: String {
        let mappedCount = routeMapPoints.count
        let totalCount = VM.serviceStopList.count
        return "\(mappedCount) of \(totalCount) stops mapped"
    }

    private var routeMapPoints: [TechnicianRouteMapPoint] {
        VM.serviceStopList.enumerated().compactMap { index, stop in
            guard isValidRouteCoordinate(stop.address.coordinates) else { return nil }

            return TechnicianRouteMapPoint(
                stop: stop,
                order: index + 1,
                coordinate: stop.address.coordinates
            )
        }
    }

    private var routePolylineCoordinates: [CLLocationCoordinate2D] {
        routeMapPoints.map(\.coordinate)
    }

    private var missingCoordinateCount: Int {
        VM.serviceStopList.filter { !isValidRouteCoordinate($0.address.coordinates) }.count
    }

    private func routeMapPinColor(_ stop: ServiceStop) -> Color {
        switch stop.operationStatus {
        case .finished:
            return .poolGreen
        case .skipped:
            return .orange
        case .notFinished:
            return .poolBlue
        }
    }

    private func updateRouteMapCamera() {
        guard let region = routeMapRegion(for: routeMapPoints.map(\.coordinate)) else {
            routeMapCameraPosition = .automatic
            expandedRouteMapCameraPosition = .automatic
            return
        }

        routeMapCameraPosition = .region(region)
        expandedRouteMapCameraPosition = .region(region)
    }

    private func routeMapRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard !coordinates.isEmpty else { return nil }

        if coordinates.count == 1, let coordinate = coordinates.first {
            return MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)

        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max() else {
            return nil
        }

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.35, 0.02)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.35, 0.02)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }

    private func isValidRouteCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude.isFinite &&
        coordinate.longitude.isFinite &&
        abs(coordinate.latitude) <= 90 &&
        abs(coordinate.longitude) <= 180 &&
        !(coordinate.latitude == 0 && coordinate.longitude == 0)
    }
}

// MARK: - Mileage Sheet
extension EmployeeDailyDashboard {
    
    var startMilageView: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Button {
                    VM.showVehicalPicker.toggle()
                } label: {
                    Text(
                        VM.selectedVehical.id.isEmpty
                        ? "Pick Vehicle"
                        : "\(VM.selectedVehical.nickName) \(VM.selectedVehical.plate)"
                    )
                }
                .sheet(isPresented: $VM.showVehicalPicker) {
                    VehicalPickerView(
                        dataService: dataService,
                        vehical: $VM.selectedVehical,
                        companyUser: VM.currentCompanyUser
                    )
                }

                if !VM.selectedVehical.id.isEmpty {
                    Divider()

                    HStack {
                        Text("Recent Mileage")
                        Spacer()
                        Text(
                            Measurement(value: VM.selectedVehical.miles, unit: UnitLength.miles)
                                .formatted(.measurement(width: .abbreviated))
                        )
                    }
                    Divider()
                    TextField("Start Mileage", text: $startMilage)
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                    TextField("End Mileage", text: $endMilage)
                        .keyboardType(.decimalPad)
                        .modifier(TextFieldModifier())
                }
            }
            .padding()
            Spacer()
        }
    }
}
struct MyDropDelegate : DropDelegate {

    let targetStop: ServiceStop
    @Binding var stopList: [ServiceStop]
    @Binding var draggedStop: ServiceStop?

    func dropEntered(info: DropInfo) {
        guard
            let dragged = draggedStop,
            dragged != targetStop,
            let fromIndex = stopList.firstIndex(of: dragged),
            let toIndex = stopList.firstIndex(of: targetStop)
        else { return }

        withAnimation {
            stopList.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedStop = nil
        return true
    }
}

private struct TechnicianRouteMapPoint: Identifiable {
    let stop: ServiceStop
    let order: Int
    let coordinate: CLLocationCoordinate2D

    var id: String { stop.id }
    var title: String { "#\(order) \(stop.customerName)" }
}

private struct EmployeeRouteCalendarDashboard: View {
    let selectedDate: Date
    let activeRoute: ActiveRoute?
    let serviceStops: [ServiceStop]
    let onSelectStop: (ServiceStop) -> Void

    private let calendar = Calendar.current
    private let slotMinutes: Int = 15
    private let slotHeight: CGFloat = 56
    private let interEventGapMinutes: Int = 5
    private let timeColumnWidth: CGFloat = 54
    private let eventLaneSpacing: CGFloat = 12
    private let minimumEventHeight: CGFloat = 72

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if entries.isEmpty {
                emptyBoard
            } else {
                TimelineView(.periodic(from: Date(), by: 60)) { context in
                    GeometryReader { proxy in
                        timeline(width: proxy.size.width, now: context.date)
                    }
                    .frame(height: timelineHeight)
                }
            }
        }
        .employeeDashCard()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar.day.timeline.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Route Timeline")
                    .font(.headline.weight(.semibold))

                Text(boardSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var emptyBoard: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("No stops to schedule")
                .font(.subheadline.weight(.semibold))

            Text("Stops assigned to this date will appear on the day timeline.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func timeline(width: CGFloat, now: Date) -> some View {
        let eventLaneWidth = max(width - timeColumnWidth - eventLaneSpacing, 0)

        return ZStack(alignment: .topLeading) {
            hourGrid

            ForEach(entries) { entry in
                Button {
                    onSelectStop(entry.stop)
                } label: {
                    eventBlock(entry)
                }
                .buttonStyle(.plain)
                .frame(width: eventLaneWidth, height: eventHeight(entry), alignment: .topLeading)
                .offset(x: timeColumnWidth + eventLaneSpacing, y: yOffset(for: entry.start))
            }

            if shouldShowNowLine(now) {
                nowLine(now: now, width: width)
                    .offset(y: yOffset(for: now) - 8)
            }
        }
        .frame(width: width, height: timelineHeight, alignment: .topLeading)
        .clipped()
    }

    private var hourGrid: some View {
        VStack(spacing: 0) {
            ForEach(timelineSegments) { segment in
                if segment.isDetailed {
                    ForEach(0..<segment.slotCount, id: \.self) { slot in
                        let date = calendar.date(
                            byAdding: .minute,
                            value: slot * slotMinutes,
                            to: segment.start
                        ) ?? segment.start
                        gridLine(date: date, isHour: slot == 0)
                    }
                } else {
                    gridLine(date: segment.start, isHour: true)
                }
            }
        }
    }

    private func gridLine(date: Date, isHour: Bool) -> some View {
        HStack(alignment: .top, spacing: eventLaneSpacing) {
            Text(time(date: date))
                .font(isHour ? .caption2.weight(.semibold) : .caption2)
                .foregroundStyle(.secondary)
                .frame(width: timeColumnWidth, alignment: .trailing)
                .padding(.top, -5)
                .opacity(isHour ? 1.0 : 0.72)

            Rectangle()
                .fill(Color.primary.opacity(isHour ? 0.10 : 0.045))
                .frame(height: 1)
                .padding(.top, 1)
        }
        .frame(height: slotHeight, alignment: .top)
    }

    private func eventBlock(_ entry: EmployeeRouteCalendarEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(entry.accentColor)
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("#\(entry.index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(entry.accentColor)

                    Text(entry.stop.customerName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 6)

                    Text(entry.stop.operationStatus.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(entry.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(entry.accentColor.opacity(0.12), in: Capsule())
                }

                Text(entry.stop.address.streetAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(entry.timeRangeText, systemImage: "clock")
                    Label(entry.durationText, systemImage: "timer")

                    if entry.usesProjectedTime {
                        Label("Projected", systemImage: "sparkles")
                    }
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(entry.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(entry.accentColor.opacity(0.24), lineWidth: 1)
        )
    }

    private func nowLine(now: Date, width: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(time(date: now))
                .font(.caption2.weight(.bold))
                .foregroundStyle(.red)
                .frame(width: timeColumnWidth, alignment: .trailing)

            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)

            Rectangle()
                .fill(.red)
                .frame(width: max(width - timeColumnWidth - eventLaneSpacing, 0), height: 2)
        }
    }

    private var entries: [EmployeeRouteCalendarEntry] {
        var nextAvailableStart = routeStartAnchor

        return serviceStops.enumerated().map { index, stop in
            let actualStart = sameDayDate(stop.startTime)
            let preferredStart = actualStart ?? nextAvailableStart
            let start = max(preferredStart, nextAvailableStart)
            let end = endTime(for: stop, start: start)
            nextAvailableStart = calendar.date(
                byAdding: .minute,
                value: interEventGapMinutes,
                to: end
            ) ?? end

            return EmployeeRouteCalendarEntry(
                index: index,
                stop: stop,
                start: start,
                end: end,
                usesProjectedTime: actualStart == nil
            )
        }
    }

    private var routeStartAnchor: Date {
        if let startTime = sameDayDate(activeRoute?.startTime) {
            return startTime
        }

        if let firstActualStart = serviceStops.compactMap({ sameDayDate($0.startTime) }).min() {
            return firstActualStart
        }

        return calendar.date(bySettingHour: 8, minute: 0, second: 0, of: selectedDate) ?? selectedDate.startOfDay()
    }

    private var boardSubtitle: String {
        guard let first = entries.first, let last = entries.last else {
            return "No route blocks scheduled."
        }

        return "\(entries.count) stop\(entries.count == 1 ? "" : "s") - \(time(date: first.start)) to \(time(date: last.end))"
    }

    private var visibleStartHour: Int {
        let dates = relevantTimelineDates
        let earliestHour = dates.map { calendar.component(.hour, from: $0) }.min() ?? 8
        return max(min(earliestHour - 1, 7), 0)
    }

    private var visibleEndHour: Int {
        let dates = relevantTimelineDates
        let latestHour = dates.map { calendar.component(.hour, from: $0) }.max() ?? 17
        return min(max(latestHour + 2, 18), 24)
    }

    private var relevantTimelineDates: [Date] {
        var dates = entries.flatMap { [$0.start, $0.end] }

        if calendar.isDateInToday(selectedDate) {
            dates.append(Date())
        }

        return dates.isEmpty ? [routeStartAnchor] : dates
    }

    private var timelineHeight: CGFloat {
        timelineSegments.reduce(CGFloat.zero) { total, segment in
            total + segment.height(slotHeight: slotHeight)
        }
    }

    private var visibleTimelineStart: Date {
        calendar.date(
            bySettingHour: visibleStartHour,
            minute: 0,
            second: 0,
            of: selectedDate
        ) ?? selectedDate.startOfDay()
    }

    private var visibleTimelineEnd: Date {
        calendar.date(
            byAdding: .hour,
            value: visibleEndHour - visibleStartHour,
            to: visibleTimelineStart
        ) ?? visibleTimelineStart
    }

    private var timelineSegments: [EmployeeRouteTimelineHourSegment] {
        guard visibleEndHour > visibleStartHour else { return [] }

        return (visibleStartHour..<visibleEndHour).compactMap { hour in
            guard let start = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate),
                  let end = calendar.date(byAdding: .hour, value: 1, to: start) else {
                return nil
            }

            let hasStopsInHour = entries.contains { entry in
                entry.start < end && entry.end > start
            }

            return EmployeeRouteTimelineHourSegment(
                hour: hour,
                start: start,
                end: end,
                isDetailed: hasStopsInHour
            )
        }
    }

    private func endTime(for stop: ServiceStop, start: Date) -> Date {
        if let endTime = sameDayDate(stop.endTime), endTime > start {
            return endTime
        }

        return calendar.date(
            byAdding: .minute,
            value: plannedDurationMinutes(for: stop),
            to: start
        ) ?? start.addingTimeInterval(TimeInterval(plannedDurationMinutes(for: stop) * 60))
    }

    private func plannedDurationMinutes(for stop: ServiceStop) -> Int {
        max(stop.duration, stop.estimatedDuration, 15)
    }

    private func yOffset(for date: Date) -> CGFloat {
        var y: CGFloat = 0

        for segment in timelineSegments {
            if date >= segment.end {
                y += segment.height(slotHeight: slotHeight)
                continue
            }

            if date <= segment.start {
                return y
            }

            let minutesIntoHour = max(date.timeIntervalSince(segment.start) / 60, 0)
            let hourMinutes = max(segment.end.timeIntervalSince(segment.start) / 60, 1)
            let progress = min(max(minutesIntoHour / hourMinutes, 0), 1)
            return y + (segment.height(slotHeight: slotHeight) * CGFloat(progress))
        }

        return y
    }

    private func eventHeight(_ entry: EmployeeRouteCalendarEntry) -> CGFloat {
        max(yOffset(for: entry.end) - yOffset(for: entry.start), minimumEventHeight)
    }

    private func shouldShowNowLine(_ now: Date) -> Bool {
        guard calendar.isDate(now, inSameDayAs: selectedDate) else { return false }
        guard now >= visibleTimelineStart, now <= visibleTimelineEnd else { return false }

        let y = yOffset(for: now)
        return y >= 0 && y <= timelineHeight
    }

    private func sameDayDate(_ date: Date?) -> Date? {
        guard let date else { return nil }
        return calendar.isDate(date, inSameDayAs: selectedDate) ? date : nil
    }
}

private struct EmployeeRouteTimelineHourSegment: Identifiable {
    let hour: Int
    let start: Date
    let end: Date
    let isDetailed: Bool

    var id: Int { hour }
    var slotCount: Int { isDetailed ? 4 : 1 }

    func height(slotHeight: CGFloat) -> CGFloat {
        CGFloat(slotCount) * slotHeight
    }
}

private struct EmployeeRouteCalendarEntry: Identifiable {
    let index: Int
    let stop: ServiceStop
    let start: Date
    let end: Date
    let usesProjectedTime: Bool

    var id: String { stop.id }

    var accentColor: Color {
        switch stop.operationStatus {
        case .finished:
            return .poolGreen
        case .notFinished:
            return .poolBlue
        case .skipped:
            return .orange
        }
    }

    var timeRangeText: String {
        "\(time(date: start)) - \(time(date: end))"
    }

    var durationText: String {
        displayMinAsMinAndHour(min: max(Int(end.timeIntervalSince(start) / 60), 1))
    }
}

private extension View {
    func employeeDashCard(material: Bool = false, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }

    func dashboardCreateJobOptionCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
