//
//  EmployeeDailyDashboard.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import UniformTypeIdentifiers
import MapKit

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

                        if VM.serviceStopList.isEmpty {
                            noRouteCard
                        } else {
                            routeInfo
//                            routeMapCard

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
                                listOfStops
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
            presentRouteCloseoutIfNeeded()
        }
        .onChange(of: masterDataManager.currentCompany?.id) { _, _ in
            refreshShoppingListBadge()
        }
        .onChange(of: masterDataManager.user?.id) { _, _ in
            refreshShoppingListBadge()
        }
        .onChange(of: VM.serviceStopList) { _, _ in
            updateRouteMapCamera()
            presentRouteCloseoutIfNeeded()
        }
        .onChange(of: VM.activeRoute) { _, _ in
            presentRouteCloseoutIfNeeded()
        }
        .sheet(isPresented: $showExpandedRouteMap) {
            expandedRouteMapSheet
                .presentationDetents([.large])
        }
        .sheet(isPresented: $VM.showEndMilage) {
            routeEndMileageSheet
                .presentationDetents([.fraction(0.45), .fraction(0.6), .large])
        }
        .onDisappear {
            VM.selectedDate = Date()
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

    private func refreshShoppingListBadge() {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            listOfShoppingListItems = 0
            return
        }

        Task {
            do {
                listOfShoppingListItems = try await dataService.getShoppingListItemByUserAndStatusCount(
                    companyId: company.id,
                    userId: user.id,
                    status: .needToPurchase
                )
            } catch {
                listOfShoppingListItems = 0
                print("[EmployeeDailyDashboard][refreshShoppingListBadge] Error", error)
            }
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

            NavigationLink(value: Route.shoppingList(dataService: dataService)) {
                dashboardToolbarIcon(
                    systemImage: "cart",
                    badgeCount: listOfShoppingListItems
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: Route.createNewJob(dataService: dataService)) {
                dashboardToolbarIcon(
                    systemImage: "plus",
                    badgeCount: 0
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
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
        .employeeDashCard(material: true)
    }}

// MARK: - Route Info
extension EmployeeDailyDashboard {
    var routeInfo: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let activeRoute = VM.activeRoute {
                HStack(alignment: .top, spacing: 14) {
                    routeProgressRing(activeRoute)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(activeRoute.name.isEmpty ? "Today’s Route" : activeRoute.name)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text("\(activeRoute.finishedStops) of \(activeRoute.totalStops) stops complete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        routeStatusBadge(activeRoute.status.rawValue)
                    }

                    Spacer()
                }

                routeMetricGrid(activeRoute)

                Divider().opacity(0.35)

                if routeNeedsCloseout(activeRoute) {
                    routeCloseoutCard(activeRoute)
                }

                routeActionButtons
            }
        }
        .employeeDashCard()
    }
    private var routeActionButtons: some View {
        HStack {

            if !VM.enableMove && !enableReorder {
                
                Button("Reorder") { enableReorder = true }
                Spacer()
                Button("Move") { VM.enableMove = true }
            }

            if enableReorder {
                Button(action: { enableReorder = false}, label: {
                    Text("Cancel")
                        .modifier(DeleteButtonModifier())
                    
                })
                Spacer()
                
                Button(action: {
                    VM.reorderServiceStops(companyId: masterDataManager.currentCompany?.id)
                    enableReorder = false
                }, label: {
                    Text("Save")
                        .modifier(SubmitButtonModifier())
                    
                })
            }

            if VM.enableMove {
                
                Button(action: {
                    VM.cancelMove()
                    VM.enableMove = false
                }, label: {
                    Text("Cancel")
                        .modifier(DeleteButtonModifier())
                    
                })
                Spacer()
                    
                Button(action: {
                    confirmMove.toggle()
                }, label: {
                    Text("Confirm")
                        .modifier(SubmitButtonModifier())
                })
                .disabled(VM.selectedServiceStops.isEmpty)
                .sheet(isPresented: $confirmMove) {
                    moveConfirmationSheet
                        .presentationDetents([.large])
                }
            }
        }
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
                                title: "End Mileage",
                                subtitle: "Enter the ending mileage to finish the route.",
                                systemImage: "flag.checkered"
                            )
                        }
                        .employeeDashCard(material: true)

                        routeEndMileageInputCard
                    }
                    .padding(14)
                }
            }
            .navigationTitle("End Mileage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        VM.showEndMilage = false
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
                Label("Submit End Mileage", systemImage: "checkmark.circle")
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

    private var displayedStartMileageForCloseout: Double {
        VM.activeRoute?.startMilage ?? VM.startMilage
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
        guard let route = VM.activeRoute else { return }

        VM.updateRouteEndtMilage(
            companyId: masterDataManager.currentCompany?.id,
            route: route
        )

        VM.stopActiveRoute(
            companyId: masterDataManager.currentCompany?.id,
            companyName: masterDataManager.currentCompany?.name,
            user: masterDataManager.user,
            route: route
        )

        VM.showEndMilage = false
        routeCloseoutPromptedRouteId = nil
    }
}

// MARK: - Stops List
extension EmployeeDailyDashboard {
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
                .stroke(Color.primary.opacity(0.12), lineWidth: 8)
                .frame(width: 76, height: 76)

            Circle()
                .trim(
                    from: 0,
                    to: Double(activeRoute.finishedStops) / Double(max(activeRoute.totalStops, 1))
                )
                .stroke(
                    Color.poolGreen,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
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
        VStack(spacing: 8) {
            if let startTime = activeRoute.startTime {
                metricRow(
                    title: "Time",
                    value: timeRangeText(start: startTime, end: activeRoute.endTime),
                    detail: timeDifferenceText(start: startTime, end: activeRoute.endTime),
                    systemImage: "clock"
                )
            }

            if let startMilage = activeRoute.startMilage {
                metricRow(
                    title: "Mileage",
                    value: mileageRangeText(start: startMilage, end: activeRoute.endMilage),
                    detail: mileageDifferenceText(start: startMilage, end: activeRoute.endMilage),
                    systemImage: "gauge.with.dots.needle.bottom.50percent"
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Route Order Changed",
                subtitle: "This active route order does not match the recurring default route.",
                systemImage: "arrow.triangle.branch"
            )

            HStack(spacing: 10) {
                Button {
                    VM.resetOrderToMatchRecurringRoute(companyId: masterDataManager.currentCompany?.id)
                } label: {
                    actionButton(
                        title: "Reset Order",
                        systemImage: "arrow.uturn.backward",
                        tint: .orange
                    )
                }
                .buttonStyle(.plain)

                Button {
                    VM.reorderServiceStopsPermanently(companyId: masterDataManager.currentCompany?.id)
                } label: {
                    actionButton(
                        title: "Update Default",
                        systemImage: "checkmark.circle",
                        tint: .green
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .employeeDashCard()
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

private extension View {
    func employeeDashCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }
}
