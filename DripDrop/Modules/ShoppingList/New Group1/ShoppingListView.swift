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
        routeDate: Date? = nil
    ) {
        self.providedRouteServiceStops = routeServiceStops
        self.routeDate = routeDate

        _shoppingVM = StateObject(
            wrappedValue: ShoppingListViewModel(dataService: dataService)
        )

        _routeVM = StateObject(
            wrappedValue: MobileDailyRouteDisplayViewModel(dataService: dataService)
        )
    }

    @State private var selectedTab: ShoppingCenterTab = .routePrep
    @State private var showAddNewShoppingListItem: Bool = false
    @State private var isLoading: Bool = false
    @State private var includeAllOutstanding: Bool = false
    @State private var showOtherOutstandingItems: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                tabBar

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
                                subtitle: "Personal or truck-stock items assigned to you.",
                                systemImage: "person.crop.circle",
                                items: shoppingVM.myItems,
                                emptyTitle: "No personal prep items.",
                                emptyMessage: "Personal shopping items for this route will appear here."
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
                                emptyMessage: "Purchased items that still need install/delivery will appear here."
                            )
                        }

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Shopping Center")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
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
                    label: "Route",
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
        }
        .shoppingCenterCard(material: true)
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

    private var routePrepSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Route Prep",
                subtitle: "Items connected to \(routeContextLabel), jobs, customers, service locations, or your personal list.",
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
        }
        .shoppingCenterCard()
    }

    private var outstandingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                sectionHeader(
                    title: "Outstanding",
                    subtitle: "Open shopping actions. Use company-wide mode for planning ahead.",
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
            subtitle: "Open customer-specific shopping actions for the route context.",
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
            subtitle: "Open job material items connected to this route context.",
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
                serviceStops: routeContextServiceStops
            )

            if includeAllOutstanding || showOtherOutstandingItems {
                try await shoppingVM.loadOutstandingShoppingItems(
                    companyId: company.id,
                    limit: 100
                )
            } else {
                // In normal technician mode, outstanding mirrors route-prep scope.
                // This avoids a company-wide outstanding read.
                shoppingVM.setOutstandingItemsForCurrentContext(
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

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ShoppingCenterTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.systemImage)
                            Text(tab.rawValue)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            selectedTab == tab
                            ? Color.accentColor.opacity(0.16)
                            : Color.primary.opacity(0.06),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedTab == tab
                                    ? Color.accentColor.opacity(0.28)
                                    : Color.primary.opacity(0.08),
                                    lineWidth: 1
                                )
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

    private var headerSubtitle: String {
        switch selectedTab {
        case .routePrep:
            return "Prep materials before leaving for today’s route."
        case .outstanding:
            return "Plan ahead using open shopping actions."
        case .myItems:
            return "Truck stock and personal assigned shopping items."
        case .customers:
            return "Customer-specific items connected to route prep."
        case .jobs:
            return "Job materials connected to route prep."
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
            NavigationLink(
                value: Route.shoppingListDetail(
                    item: item,
                    dataService: dataService
                )
            ) {
                ShoppingListItemCardView(
                    dataService: dataService,
                    shoppingListItem: item
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                masterDataManager.selectedShoppingListItem = item
            } label: {
                ShoppingListItemCardView(
                    dataService: dataService,
                    shoppingListItem: item
                )
            }
            .buttonStyle(.plain)
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
}
