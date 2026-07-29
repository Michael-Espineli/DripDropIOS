//
//  ReceiptDatabaseListView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/8/23.
//

import SwiftUI

private enum DatabaseBillableFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case billable = "Billable"
    case notBillable = "Not Billable"

    var id: String { rawValue }
}

private enum DatabasePriceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case priced = "Priced"
    case missingPrice = "No Price"

    var id: String { rawValue }
}

private enum DatabaseSortOption: String, CaseIterable, Identifiable {
    case nameAZ = "Name A-Z"
    case updatedNewest = "Recently Updated"
    case priceHigh = "Price High"
    case priceLow = "Price Low"
    case costHigh = "Cost High"

    var id: String { rawValue }
}

struct ReceiptDatabaseListView: View{
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService
    init(dataService: any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }
    @StateObject private var viewModel : ReceiptDatabaseViewModel

    @State private var selected = Set<DataBaseItem.ID>()
    @State var dataBaseItemList:[DataBaseItem] = []
    @State var showItemView:Bool = false
    @State var selectedItem:DataBaseItem? = nil
    @State var searchTerm = ""

    @State var showAddNew = false
    @State var showSearch = false
    @State var showFilter = false
    @State var loadingNewProducts = false

    @State private var billableFilter: DatabaseBillableFilter = .all
    @State private var priceFilter: DatabasePriceFilter = .all
    @State private var categoryFilter: DataBaseItemCategory? = nil
    @State private var subCategoryFilter: DataBaseItemSubCategory? = nil
    @State private var storeFilter: String? = nil
    @State private var sortOption: DatabaseSortOption = .nameAZ

    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            if UIDevice.isIPhone {
                databaseItems
            } else {
                macDatabaseItems
            }
            icons
        }
        .onChange(of: searchTerm){ _ in
            refreshDisplayedItems()
        }
        .onChange(of: billableFilter) { _ in
            refreshDisplayedItems()
        }
        .onChange(of: priceFilter) { _ in
            refreshDisplayedItems()
        }
        .onChange(of: categoryFilter) { _ in
            refreshDisplayedItems()
        }
        .onChange(of: subCategoryFilter) { _ in
            refreshDisplayedItems()
        }
        .onChange(of: storeFilter) { _ in
            refreshDisplayedItems()
        }
        .onChange(of: sortOption) { _ in
            refreshDisplayedItems()
        }
        .task{
            await loadDataBaseItems()
        }
    }
}

extension ReceiptDatabaseListView {
    var databaseItems: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(spacing: 10){
                if dataBaseItemList.isEmpty {
                    databaseEmptyState
                }

                ForEach(dataBaseItemList) { item in
                    NavigationLink(value: Route.dataBaseItem(dataBaseItem: item,dataService:dataService), label: {
                        DataBaseItemCardView(dataBaseItem: item)
                    })
                    .buttonStyle(.plain)

                    if item == dataBaseItemList.last{
                        loadingMoreView
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    var macDatabaseItems: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(spacing: 10){
                if dataBaseItemList.isEmpty {
                    databaseEmptyState
                }

                ForEach(dataBaseItemList) { item in
                    Button(action: {
                        masterDataManager.selectedDataBaseItem = item
                    }, label: {
                        DataBaseItemCardView(dataBaseItem: item)
                    })
                    .buttonStyle(.plain)

                    if item == dataBaseItemList.last{
                        loadingMoreView
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    var databaseEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle" : "shippingbox")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(hasActiveFilters ? "No matching items." : "No database items yet.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(hasActiveFilters ? "Clear search or filters to expand the database list." : "Add a database item to set material details and customer pricing.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var icons: some View {
        VStack{
            Spacer()
            HStack{
                Spacer()
                VStack(spacing: 8){
                    Button(action: {
                        showFilter.toggle()
                    }, label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                                .modifier(FilterIconModifer())

                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(Color.accentColor, in: Circle())
                                    .offset(x: 7, y: -7)
                            }
                        }
                    })
                    .padding(8)
                    .sheet(isPresented: $showFilter, content: {
                        filterSheet
                    })

                    Button(action: {
                        showAddNew.toggle()
                    }, label: {
                        Image(systemName: "plus")
                            .modifier(PlusIconModifer())
                    })
                    .padding(8)
                    .sheet(isPresented: $showAddNew, onDismiss: {
                        Task {
                            await loadDataBaseItems()
                        }
                    }, content: {
                        NavigationView{
                            AddNewDatabaseItem(dataService: dataService)
                        }
                    })

                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass")
                            .modifier(SearchIconModifer())
                    })
                    .padding(10)
                }
                .padding(.trailing, 6)
            }
            if showSearch {
                searchBar
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10){
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search items, SKU, category, or store", text: $searchTerm)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if !searchTerm.isEmpty {
                Button(action: {
                    searchTerm = ""
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                })
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var loadingMoreView: some View {
        HStack{
            if loadingNewProducts {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear{
            Task{
                await loadDataBaseItems(showPagingIndicator: true)
            }
        }
    }
}

extension ReceiptDatabaseListView {
    private var filterSheet: some View {
        NavigationView {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        filterSummaryCard

                        filterSection(title: "Billable", systemImage: "checkmark.seal") {
                            Picker("Billable", selection: $billableFilter) {
                                ForEach(DatabaseBillableFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        filterSection(title: "Price", systemImage: "dollarsign.circle") {
                            Picker("Price", selection: $priceFilter) {
                                ForEach(DatabasePriceFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        filterSection(title: "Classification", systemImage: "square.grid.2x2") {
                            pickerRow(title: "Category") {
                                Picker("Category", selection: $categoryFilter) {
                                    Text("All categories").tag(nil as DataBaseItemCategory?)
                                    ForEach(DataBaseItemCategory.allCases.filter { $0 != .na }, id: \.self) { category in
                                        Text(category.rawValue).tag(category as DataBaseItemCategory?)
                                    }
                                }
                            }

                            pickerRow(title: "Subcategory") {
                                Picker("Subcategory", selection: $subCategoryFilter) {
                                    Text("All subcategories").tag(nil as DataBaseItemSubCategory?)
                                    ForEach(DataBaseItemSubCategory.allCases.filter { $0 != .na }, id: \.self) { subCategory in
                                        Text(subCategory.rawValue).tag(subCategory as DataBaseItemSubCategory?)
                                    }
                                }
                            }
                        }

                        filterSection(title: "Store", systemImage: "storefront") {
                            pickerRow(title: "Vendor") {
                                Picker("Store", selection: $storeFilter) {
                                    Text("All stores").tag(nil as String?)
                                    ForEach(storeOptions, id: \.self) { storeName in
                                        Text(storeName).tag(storeName as String?)
                                    }
                                }
                            }
                        }

                        filterSection(title: "Sort", systemImage: "arrow.up.arrow.down") {
                            pickerRow(title: "Order") {
                                Picker("Sort", selection: $sortOption) {
                                    ForEach(DatabaseSortOption.allCases) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .disabled(!hasActiveFilters)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showFilter = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filterSummaryCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "shippingbox.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 42, height: 42)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("\(dataBaseItemList.count) of \(viewModel.dataBaseItems.count) items")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(activeFilterCount == 0 ? "No filters applied" : "\(activeFilterCount) active filter\(activeFilterCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func filterSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            content()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func pickerRow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            content()
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension ReceiptDatabaseListView {
    private var storeOptions: [String] {
        Array(Set(viewModel.dataBaseItems.map { $0.storeName.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var hasActiveFilters: Bool {
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        billableFilter != .all ||
        priceFilter != .all ||
        categoryFilter != nil ||
        subCategoryFilter != nil ||
        storeFilter != nil ||
        sortOption != .nameAZ
    }

    private var activeFilterCount: Int {
        var count = 0
        if !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if billableFilter != .all { count += 1 }
        if priceFilter != .all { count += 1 }
        if categoryFilter != nil { count += 1 }
        if subCategoryFilter != nil { count += 1 }
        if storeFilter != nil { count += 1 }
        if sortOption != .nameAZ { count += 1 }

        return count
    }

    private func loadDataBaseItems(showPagingIndicator: Bool = false) async {
        if loadingNewProducts { return }

        if showPagingIndicator {
            loadingNewProducts = true
        }
        defer {
            if showPagingIndicator {
                loadingNewProducts = false
            }
        }

        guard let company = masterDataManager.currentCompany else { return }

        do {
            try await viewModel.getAllDataBaseItemsByName(companyId: company.id)
            refreshDisplayedItems()
        } catch {
            print(error)
        }
    }

    private func refreshDisplayedItems() {
        var items = viewModel.dataBaseItems
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if !term.isEmpty {
            items = items.filter { item in
                searchableText(for: item).contains(term)
            }
        }

        switch billableFilter {
        case .all:
            break
        case .billable:
            items = items.filter { $0.billable }
        case .notBillable:
            items = items.filter { !$0.billable }
        }

        switch priceFilter {
        case .all:
            break
        case .priced:
            items = items.filter { $0.billable && DataBaseItemMoneyFormatter.hasCustomerPrice($0) }
        case .missingPrice:
            items = items.filter { $0.billable && !DataBaseItemMoneyFormatter.hasCustomerPrice($0) }
        }

        if let categoryFilter {
            items = items.filter { $0.category == categoryFilter }
        }

        if let subCategoryFilter {
            items = items.filter { $0.subCategory == subCategoryFilter }
        }

        if let storeFilter {
            items = items.filter { $0.storeName == storeFilter }
        }

        dataBaseItemList = sortedItems(items)
    }

    private func resetFilters() {
        searchTerm = ""
        billableFilter = .all
        priceFilter = .all
        categoryFilter = nil
        subCategoryFilter = nil
        storeFilter = nil
        sortOption = .nameAZ
        refreshDisplayedItems()
    }

    private func searchableText(for item: DataBaseItem) -> String {
        [
            item.name,
            item.sku,
            item.description,
            item.category.rawValue,
            item.subCategory.rawValue,
            item.storeName,
            item.size,
            item.color,
            item.UOM.rawValue,
            item.billable ? "billable" : "not billable",
            DataBaseItemMoneyFormatter.customerPriceText(for: item),
            DataBaseItemMoneyFormatter.costText(for: item)
        ]
            .joined(separator: " ")
            .lowercased()
    }

    private func sortedItems(_ items: [DataBaseItem]) -> [DataBaseItem] {
        items.sorted { lhs, rhs in
            switch sortOption {
            case .nameAZ:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .updatedNewest:
                return lhs.dateUpdated > rhs.dateUpdated
            case .priceHigh:
                if customerPriceCents(lhs) == customerPriceCents(rhs) {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return customerPriceCents(lhs) > customerPriceCents(rhs)
            case .priceLow:
                if customerPriceCents(lhs) == customerPriceCents(rhs) {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return customerPriceCents(lhs) < customerPriceCents(rhs)
            case .costHigh:
                if lhs.rate == rhs.rate {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.rate > rhs.rate
            }
        }
    }

    private func customerPriceCents(_ item: DataBaseItem) -> Double {
        guard item.billable else { return 0 }

        return item.sellPrice ?? 0
    }
}
