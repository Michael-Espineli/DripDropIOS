//
//  ShoppingListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//
import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var navigationManager: NavigationStateManager

    @StateObject var shoppingVM: ShoppingListViewModel
    @StateObject private var routeVM: MobileDailyRouteDisplayViewModel
    private let providedRouteServiceStops: [ServiceStop]?
    private let routeDate: Date?

    init(
        dataService: any ProductionDataServiceProtocol,
        routeServiceStops: [ServiceStop]? = nil,
        routeDate: Date? = nil,
        initialTab: ShoppingCenterTab = .routePrep,
        initialTimeScope: ShoppingCenterTimeScope = .thisWeek,
        includeAllOutstandingByDefault: Bool = false
    ) {
        self.providedRouteServiceStops = routeServiceStops
        self.routeDate = routeDate

        _shoppingVM = StateObject(
            wrappedValue: ShoppingListViewModel(dataService: dataService)
        )

        _routeVM = StateObject(
            wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService)
        )

        _selectedTab = State(initialValue: initialTab)
        _selectedTimeScope = State(initialValue: initialTimeScope)
        _includeAllOutstanding = State(initialValue: includeAllOutstandingByDefault)
        _showOtherOutstandingItems = State(initialValue: includeAllOutstandingByDefault)
    }

    @State private var selectedTab: ShoppingCenterTab
    @State private var selectedTimeScope: ShoppingCenterTimeScope
    @State private var showAddNewShoppingListItem: Bool = false
    @State private var isLoading: Bool = false
    @State private var includeAllOutstanding: Bool
    @State private var showOtherOutstandingItems: Bool
    @State private var showRecentlyPurchasedItems: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        switch selectedTab {
                        case .routePrep:
                            routePrepSection

                        case .outstanding:
                            outstandingSection

                        case .myItems:
                            itemSection(
                                title: "My Items",
                                subtitle: "All active shopping items assigned to you for \(selectedTimeScope.prepDescription).",
                                systemImage: "person.crop.circle",
                                items: shoppingVM.myItems,
                                emptyTitle: "No assigned prep items.",
                                emptyMessage: "Your assigned shopping items for this scope will appear here."
                            )

                        case .customers:
                            groupedByCustomerSection

                        case .jobs:
                            groupedByJobSection

                        case .purchased:
                            itemSection(
                                title: "Purchased",
                                subtitle: "Items purchased but not yet installed or completed.",
                                systemImage: "cart.badge.checkmark",
                                items: shoppingVM.purchasedButNotInstalledItems,
                                emptyTitle: "No purchased items need action.",
                                emptyMessage: "Purchased items that still need installation will appear here."
                            )
                        }

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Shopping Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(ShoppingCenterTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            Label(
                                tab.rawValue,
                                systemImage: selectedTab == tab ? "checkmark" : tab.systemImage
                            )
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.body.weight(.semibold))
                }

                Button {
                    showAddNewShoppingListItem.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $showAddNewShoppingListItem, onDismiss: {
            Task {
                await reloadShoppingCenter()
            }
        }) {
            NavigationStack {
                AddNewItemToShoppingList(dataService: dataService)
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await startRouteContextIfNeeded()
            await reloadShoppingCenter()
        }
        .onChange(of: routeVM.serviceStopList) { _, _ in
            guard providedRouteServiceStops == nil else { return }

            Task {
                await reloadShoppingCenter()
            }
        }
        .onChange(of: selectedTimeScope) { _, _ in
            Task {
                await reloadShoppingCenter()
            }
        }
        .refreshable {
            await reloadShoppingCenter()
        }
    }
}
extension ShoppingListView {

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: selectedTab.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Shopping Center")
                        .font(.title3.weight(.semibold))

                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                headerPill(
                    title: "\(shoppingVM.routePrepItems.count)",
                    label: "Prep",
                    systemImage: "map"
                )

                headerPill(
                    title: "\(shoppingVM.outstandingItems.count)",
                    label: "Open",
                    systemImage: "exclamationmark.circle"
                )

                headerPill(
                    title: "\(shoppingVM.myItems.count)",
                    label: "Mine",
                    systemImage: "person"
                )

                Spacer()
            }

            timeScopePicker
        }
        .shoppingCenterCard(material: true)
    }

    private var timeScopePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShoppingCenterTimeScope.allCases) { scope in
                    Button {
                        guard selectedTimeScope != scope else { return }
                        selectedTimeScope = scope
                    } label: {
                        Label(scope.rawValue, systemImage: scope.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selectedTimeScope == scope ? .primary : .secondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeScope == scope ? Color.accentColor.opacity(0.16) : Color.clear,
                                in: Capsule()
                            )
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var routeContextServiceStops: [ServiceStop] {
        providedRouteServiceStops ?? routeVM.serviceStopList
    }

    private var routeContextLabel: String {
        guard let routeDate else {
            return "today’s route"
        }

        if Calendar.current.isDateInToday(routeDate) {
            return "today’s route"
        }

        return "\(weekDay(date: routeDate)) route"
    }

    private var otherOutstandingItems: [ShoppingListItem] {
        let routeItemIds = Set(shoppingVM.routePrepItems.map { $0.id })

        return shoppingVM.outstandingItems.filter { item in
            !routeItemIds.contains(item.id)
        }
    }

    private var otherOutstandingRouteItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Button {
                showOtherOutstandingItems.toggle()
                includeAllOutstanding = showOtherOutstandingItems

                Task {
                    await reloadShoppingCenter()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: showOtherOutstandingItems ? "chevron.up.circle" : "tray.full")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(showOtherOutstandingItems ? "Hide Other Open Items" : "Show Other Open Items")
                            .font(.subheadline.weight(.semibold))

                        Text("Open shopping items outside \(routeContextLabel).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if showOtherOutstandingItems {
                        Text("\(otherOutstandingItems.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if showOtherOutstandingItems {
                if otherOutstandingItems.isEmpty {
                    emptyState(
                        title: "No other open items.",
                        message: "Everything open is already tied to this route context.",
                        systemImage: "checkmark.circle"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(otherOutstandingItems) { item in
                            shoppingItemLink(item)
                        }
                    }
                }
            }
        }
    }

    private var recentlyPurchasedItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Button {
                showRecentlyPurchasedItems.toggle()

                Task {
                    await reloadShoppingCenter()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: showRecentlyPurchasedItems ? "chevron.up.circle" : "cart.badge.checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(showRecentlyPurchasedItems ? "Hide Recent Purchases" : "Show Recent Purchases")
                            .font(.subheadline.weight(.semibold))

                        Text("Recently purchased shopping items you may need to correct.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if showRecentlyPurchasedItems {
                        Text("\(shoppingVM.recentlyPurchasedItems.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())
                    } else {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if showRecentlyPurchasedItems {
                if shoppingVM.recentlyPurchasedItems.isEmpty {
                    emptyState(
                        title: "No recent purchases.",
                        message: "Purchased shopping items will appear here so mistakes are easier to fix.",
                        systemImage: "cart.badge.checkmark"
                    )
                } else {
                    VStack(spacing: 8) {
                        ForEach(shoppingVM.recentlyPurchasedItems) { item in
                            shoppingItemLink(item)
                        }
                    }
                }
            }
        }
    }

    private var routePrepSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Route Prep",
                subtitle: "Your active shopping items needed \(selectedTimeScope.prepDescription), including route, job, customer, and personal items.",
                systemImage: "map",
                count: shoppingVM.routePrepItems.count
            )

            if routeContextServiceStops.isEmpty {
                routeContextEmptyCard
            }

            if shoppingVM.routePrepItems.isEmpty {
                emptyState(
                    title: "No route prep items.",
                    message: "No open shopping actions were found for your current route.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(shoppingVM.routePrepItems) { item in
                        shoppingItemLink(item)
                    }
                }
            }

            otherOutstandingRouteItemsSection
            recentlyPurchasedItemsSection
        }
        .shoppingCenterCard()
    }

    private var outstandingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sectionHeader(
                    title: "Outstanding",
                    subtitle: "Open shopping actions for \(selectedTimeScope.prepDescription). Use company-wide mode only when planning for everyone.",
                    systemImage: "exclamationmark.circle",
                    count: shoppingVM.outstandingItems.count
                )

                Spacer()
            }

            Toggle(isOn: $includeAllOutstanding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Company-wide planning")
                        .font(.subheadline.weight(.semibold))

                    Text("Show outstanding items beyond this route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onChange(of: includeAllOutstanding) { _, isEnabled in
                showOtherOutstandingItems = isEnabled

                Task {
                    await reloadShoppingCenter()
                }
            }

            if shoppingVM.outstandingItems.isEmpty {
                emptyState(
                    title: "No outstanding items.",
                    message: "Items that need purchase or install action will appear here.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(shoppingVM.outstandingItems) { item in
                        shoppingItemLink(item)
                    }
                }
            }
        }
        .shoppingCenterCard()
    }

    private var groupedByCustomerSection: some View {
        groupedSection(
            title: "Customer Items",
            subtitle: "Customer-specific shopping actions assigned to you for \(selectedTimeScope.prepDescription).",
            systemImage: "person.text.rectangle",
            items: shoppingVM.customerItems,
            groupTitle: { item in
                item.customerName ?? "Unknown Customer"
            },
            emptyTitle: "No customer items.",
            emptyMessage: "Customer-specific shopping actions will appear here."
        )
    }

    private var groupedByJobSection: some View {
        groupedSection(
            title: "Job Items",
            subtitle: "Approved job material items assigned to you for \(selectedTimeScope.prepDescription).",
            systemImage: "briefcase",
            items: shoppingVM.jobItems,
            groupTitle: { item in
                item.jobId ?? "Unknown Job"
            },
            emptyTitle: "No job items.",
            emptyMessage: "Job materials needing route prep will appear here."
        )
    }

    private var routeContextEmptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No route context loaded", systemImage: "map")
                .font(.subheadline.weight(.semibold))

            Text("Route Prep works best when the selected day’s service stops are loaded. You can still use Outstanding to plan ahead.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
extension ShoppingListView {

    private func itemSection(
        title: String,
        subtitle: String,
        systemImage: String,
        items: [ShoppingListItem],
        emptyTitle: String,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                count: items.count
            )

            if items.isEmpty {
                emptyState(
                    title: emptyTitle,
                    message: emptyMessage,
                    systemImage: systemImage
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        shoppingItemLink(item)
                    }
                }
            }
        }
        .shoppingCenterCard()
    }

    private func groupedSection(
        title: String,
        subtitle: String,
        systemImage: String,
        items: [ShoppingListItem],
        groupTitle: @escaping (ShoppingListItem) -> String,
        emptyTitle: String,
        emptyMessage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                count: items.count
            )

            if items.isEmpty {
                emptyState(
                    title: emptyTitle,
                    message: emptyMessage,
                    systemImage: systemImage
                )
            } else {
                let grouped = Dictionary(grouping: items, by: groupTitle)
                let keys = grouped.keys.sorted()

                VStack(spacing: 12) {
                    ForEach(keys, id: \.self) { key in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(key)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(grouped[key]?.count ?? 0)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.thinMaterial, in: Capsule())
                            }

                            VStack(spacing: 8) {
                                ForEach(grouped[key] ?? []) { item in
                                    shoppingItemLink(item)
                                }
                            }
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
        .shoppingCenterCard()
    }
}
extension ShoppingListView {

    private func startRouteContextIfNeeded() async {
        guard providedRouteServiceStops == nil else {
            return
        }

        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            return
        }

        routeVM.start(
            companyId: company.id,
            user: user,
            date: routeDate ?? Date()
        )
    }

    private func reloadShoppingCenter() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await shoppingVM.loadRoutePrepShoppingItems(
                companyId: company.id,
                userId: user.id,
                serviceStops: routeContextServiceStops,
                timeScope: selectedTimeScope,
                referenceDate: routeDate ?? Date()
            )

            if includeAllOutstanding || showOtherOutstandingItems {
                try await shoppingVM.loadOutstandingShoppingItems(
                    companyId: company.id,
                    limit: 100,
                    timeScope: selectedTimeScope,
                    referenceDate: routeDate ?? Date()
                )
            } else {
                // In normal technician mode, outstanding mirrors route-prep scope.
                // This avoids a company-wide outstanding read.
                shoppingVM.setOutstandingItemsForCurrentContext(
                    shoppingVM.routePrepItems
                )
            }

            if showRecentlyPurchasedItems {
                try await shoppingVM.loadRecentlyPurchasedShoppingItems(
                    companyId: company.id,
                    limit: 100
                )
            } else {
                shoppingVM.setRecentlyPurchasedItemsForCurrentContext(
                    shoppingVM.routePrepItems
                )
            }
        } catch {
            print("[ShoppingListView][reloadShoppingCenter] Error")
            print(error)
        }
    }
}
extension ShoppingListView {

    private var headerSubtitle: String {
        switch selectedTab {
        case .routePrep:
            return "Prep your assigned materials for \(selectedTimeScope.prepDescription)."
        case .outstanding:
            return "Plan ahead using active shopping actions."
        case .myItems:
            return "Shopping actions assigned to you."
        case .customers:
            return "Customer-specific items assigned to you."
        case .jobs:
            return "Approved job materials assigned to you."
        case .purchased:
            return "Purchased items that still need follow-up."
        }
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        count: Int
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
                    .lineLimit(2)
            }

            Spacer()

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private func emptyState(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func headerPill(
        title: String,
        label: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading shopping center...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
extension ShoppingListView {

    @ViewBuilder
    private func shoppingItemLink(_ item: ShoppingListItem) -> some View {
        if UIDevice.isIPhone {
            NavigationLink {
                ShoppingListItemDetailView(
                    item: item,
                    dataService: dataService
                )
            } label: {
                ShoppingListItemCardView(
                    dataService: dataService,
                    shoppingListItem: item,
                    compact: true
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                masterDataManager.selectedShoppingListItem = item
            } label: {
                ShoppingListItemCardView(
                    dataService: dataService,
                    shoppingListItem: item,
                    compact: true
                )
            }
            .buttonStyle(.plain)
        }
    }
}

struct CompanyShoppingListView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol

    @StateObject private var shoppingVM: ShoppingListViewModel
    @State private var searchTerm = ""
    @State private var selectedStatus: ShoppingListStatus?
    @State private var showAddNewShoppingListItem = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
        _shoppingVM = StateObject(
            wrappedValue: ShoppingListViewModel(dataService: dataService)
        )
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    filterCard
                    itemsSection

                    Color.clear.frame(height: 90)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Company Shopping List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    Task { await reloadCompanyShoppingList() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.body.weight(.semibold))
                }

                Button {
                    showAddNewShoppingListItem.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $showAddNewShoppingListItem, onDismiss: {
            Task { await reloadCompanyShoppingList() }
        }) {
            NavigationStack {
                AddNewItemToShoppingList(dataService: dataService)
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await reloadCompanyShoppingList()
        }
        .refreshable {
            await reloadCompanyShoppingList()
        }
    }
}

private extension CompanyShoppingListView {
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Company Shopping List")
                        .font(.title3.weight(.semibold))

                    Text("All shopping items across jobs, customers, route prep, and personal lists.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                headerPill(title: "\(openItems.count)", label: "Open", systemImage: "tray.full")
                headerPill(title: "\(purchasedItems.count)", label: "Purchased", systemImage: "cart.badge.checkmark")
                headerPill(title: "\(companyItems.count)", label: "Total", systemImage: "number")
                Spacer()
            }
        }
        .companyShoppingListSurface(material: true)
    }

    var filterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search company shopping list", text: $searchTerm)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    statusFilterButton(
                        title: "All",
                        count: companyItems.count,
                        isSelected: selectedStatus == nil
                    ) {
                        selectedStatus = nil
                    }

                    ForEach(ShoppingListStatus.allCases) { status in
                        statusFilterButton(
                            title: status.rawValue,
                            count: companyItems.filter { $0.status == status }.count,
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = status
                        }
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .companyShoppingListSurface()
    }

    var itemsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: selectedStatus?.rawValue ?? "All Items",
                subtitle: "Company-wide shopping list items, separate from Shopping Center route prep.",
                systemImage: selectedStatus == nil ? "list.bullet" : "line.3.horizontal.decrease.circle",
                count: filteredItems.count
            )

            if let errorMessage {
                emptyState(
                    title: "Could not load shopping list.",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle"
                )
            } else if filteredItems.isEmpty {
                emptyState(
                    title: "No shopping items found.",
                    message: "Try another search or status filter.",
                    systemImage: "cart"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredItems) { item in
                        NavigationLink(value: Route.shoppingListDetail(item: item, dataService: dataService)) {
                            ShoppingListItemCardView(
                                dataService: dataService,
                                shoppingListItem: item,
                                compact: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .companyShoppingListSurface()
    }

    var companyItems: [ShoppingListItem] {
        shoppingVM.allShoppingItems
            .filter { $0.shoppingListActive }
            .sorted { lhs, rhs in
            if lhs.status == rhs.status {
                return sortDate(lhs) > sortDate(rhs)
            }

            return lhs.status.rawValue < rhs.status.rawValue
        }
    }

    var filteredItems: [ShoppingListItem] {
        let statusFiltered = companyItems.filter { item in
            selectedStatus.map { item.status == $0 } ?? true
        }

        let cleanSearch = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanSearch.isEmpty else { return statusFiltered }

        return statusFiltered.filter { item in
            [
                item.name,
                item.description,
                item.status.rawValue,
                item.category.rawValue,
                item.subCategory.rawValue,
                item.customerName ?? "",
                item.jobId ?? "",
                item.userName ?? "",
                item.purchaserName,
                item.dbItemId ?? "",
                item.purchasedItem ?? ""
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(cleanSearch)
        }
    }

    var openItems: [ShoppingListItem] {
        companyItems.filter { $0.status.needsShoppingAction }
    }

    var purchasedItems: [ShoppingListItem] {
        companyItems.filter { $0.status == .purchased }
    }

    func sortDate(_ item: ShoppingListItem) -> Date {
        item.actionDate ?? item.datePurchased ?? .distantPast
    }

    func statusFilterButton(
        title: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.thinMaterial, in: Capsule())
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                isSelected ? AnyShapeStyle(Color.poolBlue) : AnyShapeStyle(.thinMaterial),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String,
        count: Int
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
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
    }

    func emptyState(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func headerPill(
        title: String,
        label: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
            Text(label)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading company shopping list...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    @MainActor
    func reloadCompanyShoppingList() async {
        guard let company = masterDataManager.currentCompany else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await shoppingVM.getAllShoppingListItemsByCompany(companyId: company.id)
        } catch {
            errorMessage = error.localizedDescription
            print("[CompanyShoppingListView][reloadCompanyShoppingList] \(error)")
        }
    }
}

private extension View {
    func shoppingCenterCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }

    func companyShoppingListSurface(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }
}
