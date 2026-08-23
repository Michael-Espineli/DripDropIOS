//
//  EquipmentList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

private enum EquipmentTopFilter: String, CaseIterable, Identifiable {
    case all
    case maintenance
    case repair
    case nonOperational

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .maintenance:
            return "Maintenance"
        case .repair:
            return "Repair"
        case .nonOperational:
            return "Down"
        }
    }

    var subtitle: String {
        switch self {
        case .all:
            return "All equipment"
        case .maintenance:
            return "Needs maintenance"
        case .repair:
            return "Needs repair"
        case .nonOperational:
            return "Non-operational"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "wrench.and.screwdriver"
        case .maintenance:
            return "calendar.badge.clock"
        case .repair:
            return "exclamationmark.triangle"
        case .nonOperational:
            return "xmark.octagon"
        }
    }

    var tint: Color {
        switch self {
        case .all:
            return .poolBlue
        case .maintenance:
            return .orange
        case .repair:
            return .red
        case .nonOperational:
            return .secondary
        }
    }
}

private enum EquipmentActiveStatusFilter: String, CaseIterable, Identifiable {
    case active
    case inactive
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active:
            return "Active"
        case .inactive:
            return "Inactive"
        case .both:
            return "Both"
        }
    }
}

struct EquipmentList: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var equipmentVM: EquipmentViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
    }

    @State private var showFilerOptions = false
    @State private var selectedTopFilter: EquipmentTopFilter = .maintenance
    @State private var activeStatusFilter: EquipmentActiveStatusFilter = .active
    @State private var selectedType: EquipmentCategory?
    @FocusState private var searchField: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                equipmentHeader

                topFilterRail
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)

                if equipmentVM.showSearch {
                    searchBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                equipmentListContent
            }

            if UIDevice.isIPhone {
                equipmentActionDock
            }
        }
        .navigationTitle("Equipment")
        .onChange(of: equipmentVM.searchTerm) { _ in
            equipmentVM.filterEquipmentList()
        }
        .task {
            await reloadEquipment(reset: true)
        }
        .sheet(isPresented: $showFilerOptions) {
            equipmentFilterSheet
        }
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showFilerOptions.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }

                    Button {
                        Task { await reloadEquipment(reset: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        equipmentOpenWeb(path: "/company/equipment/createNew/")
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        equipmentVM.changeSearch()
                        searchField = equipmentVM.showSearch
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
        }
    }
}

#Preview {
    EquipmentList(dataService: ProductionDataService())
}

extension EquipmentList {
    private var equipmentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Equipment")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(equipmentSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                equipmentMetric(title: "Showing", value: "\(visibleEquipment.count)", tint: .poolBlue)
                equipmentMetric(title: "Maintenance", value: "\(count(for: .maintenance))", tint: .orange)
                equipmentMetric(title: "Repair", value: "\(count(for: .repair))", tint: .red)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var topFilterRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(EquipmentTopFilter.allCases) { filter in
                    Button {
                        selectedTopFilter = filter
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: filter.systemImage)
                                .font(.caption.weight(.bold))

                            Text(filter.title)
                                .font(.caption.weight(.bold))

                            Text("\(count(for: filter))")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(
                                    selectedTopFilter == filter ? AnyShapeStyle(Color.white.opacity(0.22)) : AnyShapeStyle(.thinMaterial),
                                    in: Capsule()
                                )
                        }
                        .foregroundStyle(selectedTopFilter == filter ? .white : filter.tint)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 9)
                        .background(
                            selectedTopFilter == filter ? AnyShapeStyle(filter.tint) : AnyShapeStyle(filter.tint.opacity(0.10)),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var equipmentListContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 10) {
                if equipmentVM.isLoadingEquipmentPage && equipmentVM.listOfEquipment.isEmpty {
                    ProgressView("Loading equipment...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if visibleEquipment.isEmpty {
                    emptyState
                } else {
                    ForEach(visibleEquipment) { equipment in
                        if UIDevice.isIPhone {
                            NavigationLink(value: Route.equipmentDetailView(equipment: equipment, dataService: dataService)) {
                                EquipmentCardView(equipment: equipment)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                masterDataManager.selectedEquipment = equipment
                            } label: {
                                EquipmentCardView(equipment: equipment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if equipmentVM.hasMoreEquipment {
                    loadMoreButton
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
        }
        .refreshable {
            await reloadEquipment(reset: true)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search equipment", text: $equipmentVM.searchTerm)
                .focused($searchField, equals: true)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    equipmentVM.filterEquipmentList()
                }

            if !equipmentVM.searchTerm.isEmpty {
                Button {
                    equipmentVM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: selectedTopFilter.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("No equipment found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(equipmentVM.searchTerm.isEmpty ? "Adjust filters or create a new equipment record." : "Try a different customer, address, make, model, or status.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if equipmentVM.searchTerm.isEmpty {
                Button {
                    equipmentOpenWeb(path: "/company/equipment/createNew/")
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Create Equipment")
                        Spacer()
                        Image(systemName: "arrow.up.right")
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
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var loadMoreButton: some View {
        Button {
            Task { await reloadEquipment(reset: false) }
        } label: {
            HStack(spacing: 8) {
                if equipmentVM.isLoadingEquipmentPage {
                    ProgressView()
                }

                Text(equipmentVM.isLoadingEquipmentPage ? "Loading..." : "Load More")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(equipmentVM.isLoadingEquipmentPage)
        .padding(.top, 4)
    }

    private var equipmentActionDock: some View {
        VStack(spacing: 10) {
            Button {
                showFilerOptions.toggle()
            } label: {
                mobileDockIcon(systemName: "slider.horizontal.3", tint: .poolBlue, isSelected: showFilerOptions)
            }
            .buttonStyle(.plain)

            Button {
                Task { await reloadEquipment(reset: true) }
            } label: {
                mobileDockIcon(systemName: "arrow.clockwise", tint: .orange, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                equipmentOpenWeb(path: "/company/equipment/createNew/")
            } label: {
                mobileDockIcon(systemName: "plus", tint: .poolGreen, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    equipmentVM.changeSearch()
                }
                searchField = equipmentVM.showSearch
            } label: {
                mobileDockIcon(systemName: "magnifyingglass", tint: .poolBlue, isSelected: equipmentVM.showSearch)
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private var equipmentFilterSheet: some View {
        DripDropFilterSheet(
            title: "Equipment Filters",
            isPresented: $showFilerOptions,
            isResetDisabled: equipmentActiveFilterCount == 0,
            onReset: resetEquipmentFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(visibleEquipment.count) equipment shown",
                subtitle: "\(selectedTopFilter.subtitle), \(activeStatusFilter.title.lowercased()), \(selectedType?.rawValue ?? "all types").",
                systemImage: "wrench.and.screwdriver.fill",
                tint: .poolBlue
            )

            DripDropFilterSection(
                title: "Board",
                systemImage: "square.grid.2x2",
                tint: .poolBlue
            ) {
                DripDropFilterRow(
                    title: "Status Board",
                    subtitle: selectedTopFilter.subtitle,
                    systemImage: selectedTopFilter.systemImage,
                    tint: selectedTopFilter.tint
                ) {
                    Menu {
                        ForEach(EquipmentTopFilter.allCases) { filter in
                            Button {
                                selectedTopFilter = filter
                            } label: {
                                Label(filter.subtitle, systemImage: selectedTopFilter == filter ? "checkmark" : "circle")
                            }
                        }
                    } label: {
                        filterMenuLabel(selectedTopFilter.title, tint: selectedTopFilter.tint)
                    }
                }

                DripDropFilterRow(
                    title: "Active",
                    subtitle: activeStatusFilter.title,
                    systemImage: "power",
                    tint: .poolGreen
                ) {
                    Menu {
                        ForEach(EquipmentActiveStatusFilter.allCases) { filter in
                            Button {
                                activeStatusFilter = filter
                            } label: {
                                Label(filter.title, systemImage: activeStatusFilter == filter ? "checkmark" : "circle")
                            }
                        }
                    } label: {
                        filterMenuLabel(activeStatusFilter.title, tint: .poolGreen)
                    }
                }

                DripDropFilterRow(
                    title: "Type",
                    subtitle: selectedType?.rawValue ?? "All types",
                    systemImage: "tag",
                    tint: .orange
                ) {
                    Menu {
                        Button {
                            selectedType = nil
                        } label: {
                            Label("All types", systemImage: selectedType == nil ? "checkmark" : "circle")
                        }

                        ForEach(EquipmentCategory.allCases, id: \.self) { category in
                            Button {
                                selectedType = category
                            } label: {
                                Label(category.rawValue, systemImage: selectedType == category ? "checkmark" : "circle")
                            }
                        }
                    } label: {
                        filterMenuLabel(selectedType?.rawValue ?? "All types", tint: .orange)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func filterMenuLabel(_ title: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(tint.opacity(0.10), in: Capsule())
    }

    private func equipmentMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileDockIcon(systemName: String, tint: Color, isSelected: Bool) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    private var visibleEquipment: [Equipment] {
        filteredForBoard(equipmentVM.displayEquipment)
            .sorted { left, right in
                let leftDate = left.maintenanceDueDateForFollowUp ?? left.nextServiceDate ?? left.createdAt ?? Date.distantFuture
                let rightDate = right.maintenanceDueDateForFollowUp ?? right.nextServiceDate ?? right.createdAt ?? Date.distantFuture

                if leftDate != rightDate {
                    return leftDate < rightDate
                }

                return left.customerName.localizedCaseInsensitiveCompare(right.customerName) == .orderedAscending
            }
    }

    private var countableEquipment: [Equipment] {
        equipmentVM.displayEquipment.filter { matchesActiveStatus($0) && matchesType($0) }
    }

    private func count(for filter: EquipmentTopFilter) -> Int {
        countableEquipment.filter { matchesTopFilter($0, filter: filter) }.count
    }

    private func filteredForBoard(_ equipment: [Equipment]) -> [Equipment] {
        equipment.filter {
            matchesActiveStatus($0) &&
            matchesType($0) &&
            matchesTopFilter($0, filter: selectedTopFilter)
        }
    }

    private func matchesTopFilter(_ equipment: Equipment, filter: EquipmentTopFilter) -> Bool {
        switch filter {
        case .all:
            return true
        case .maintenance:
            return equipmentNeedsMaintenance(equipment)
        case .repair:
            return equipment.status == .needsRepair
        case .nonOperational:
            return equipment.status == .nonoperational || equipment.status == .replaced
        }
    }

    private func matchesActiveStatus(_ equipment: Equipment) -> Bool {
        switch activeStatusFilter {
        case .active:
            return equipment.isActive
        case .inactive:
            return !equipment.isActive
        case .both:
            return true
        }
    }

    private func matchesType(_ equipment: Equipment) -> Bool {
        guard let selectedType else { return true }
        return equipment.type == selectedType
    }

    private func equipmentNeedsMaintenance(_ equipment: Equipment) -> Bool {
        equipment.status == .needsMaintenance || equipment.currentlyNeedsMaintenanceFollowUp
    }

    private var equipmentSubtitle: String {
        if !equipmentVM.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Search results for \"\(equipmentVM.searchTerm)\"."
        }

        return "\(selectedTopFilter.subtitle) for \(activeStatusFilter.title.lowercased()) equipment."
    }

    private var equipmentActiveFilterCount: Int {
        var count = 0

        if selectedTopFilter != .maintenance { count += 1 }
        if activeStatusFilter != .active { count += 1 }
        if selectedType != nil { count += 1 }

        return count
    }

    private func resetEquipmentFilters() {
        selectedTopFilter = .maintenance
        activeStatusFilter = .active
        selectedType = nil
    }

    @MainActor
    private func reloadEquipment(reset: Bool) async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await equipmentVM.getAllEquipmentBy25(companyId: company.id, reset: reset)
        } catch {
            print("[EquipmentList][reload] equipmentVM.getAllEquipmentBy25")
            print(error)
        }
    }
}

private func equipmentOpenWeb(path: String) {
    guard let url = URL(string: "https://dripdrop-poolapp.com\(path)") else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}
