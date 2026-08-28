//
//  ReceiptDataBaseItemPicker.swift
//  DripDrop
//

import SwiftUI

struct ReceiptDataBaseItemPicker: View {

    init(
        dataService: any ProductionDataServiceProtocol,
        addNewItem: Binding<Bool>,
        dBItem: Binding<DataBaseItem>
    ) {
        self._addNewItem = addNewItem
        self._dBItem = dBItem
        _receiptDataBaseViewModel = StateObject(
            wrappedValue: ReceiptDatabaseViewModel(dataService: dataService)
        )
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var receiptDataBaseViewModel: ReceiptDatabaseViewModel

    @Binding var addNewItem: Bool
    @Binding var dBItem: DataBaseItem

    @State private var searchTerm: String = ""
    @State private var displayItems: [DataBaseItem] = []
    @State private var showNewItem: Bool = false
    @State private var isLoading: Bool = false
    @State private var showLoadError: Bool = false
    @State private var loadErrorMessage: String = ""

    private var hasSearch: Bool {
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedItemName: String {
        dBItem.id.isEmpty ? "No item selected" : dBItem.name
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        searchCard

                        if isLoading {
                            loadingCard
                        } else {
                            if !hasSearch {
                                commonItemsCard
                            }

                            allItemsCard
                        }

                        Color.clear.frame(height: 24)
                    }
                    .padding(14)
                }
            }
            .navigationTitle("Select Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismissPicker()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if !dBItem.id.isEmpty {
                        Button("Done") {
                            dismissPicker()
                        }
                    }
                }
            }
            .task {
                await loadItems()
            }
            .onChange(of: searchTerm) { term in
                filterItems(term)
            }
            .alert("Database Items", isPresented: $showLoadError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(loadErrorMessage)
            }
            .sheet(isPresented: $showNewItem, onDismiss: {
                Task {
                    await loadItems()
                }
            }) {
                newDataBaseItemFromReceiptView(
                    dataService: dataService,
                    newItemView: $showNewItem,
                    id: searchTerm
                )
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Database Item")
                        .font(.title3.weight(.semibold))

                    Text("Choose an item from your company database.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "shippingbox")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            HStack(spacing: 8) {
                Label(selectedItemName, systemImage: dBItem.id.isEmpty ? "circle" : "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(dBItem.id.isEmpty ? .secondary : .primary)
                    .lineLimit(1)

                Spacer()

                if !dBItem.id.isEmpty {
                    Button {
                        dBItem = emptyDataBaseItem
                    } label: {
                        Text("Clear")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .receiptPickerCard()
    }

    private var searchCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search name, SKU, description, or price", text: $searchTerm)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if hasSearch {
                Button {
                    searchTerm = ""
                    displayItems = receiptDataBaseViewModel.dataBaseItems
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 10) {
            ProgressView()

            Text("Loading items...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .receiptPickerCard()
    }

    @ViewBuilder
    private var commonItemsCard: some View {
        if !receiptDataBaseViewModel.commonDataBaseItems.isEmpty {
            itemSectionCard(
                title: "Common Items",
                subtitle: "Frequently used items.",
                systemImage: "star",
                items: receiptDataBaseViewModel.commonDataBaseItems
            )
        }
    }

    private var allItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: hasSearch ? "Search Results" : "All Items",
                subtitle: "\(displayItems.count) item(s)",
                systemImage: hasSearch ? "magnifyingglass" : "shippingbox"
            )

            if displayItems.isEmpty {
                emptySearchState
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(displayItems) { item in
                        DatabaseItemPickerRow(
                            item: item,
                            isSelected: item.id == dBItem.id
                        ) {
                            selectItem(item)
                        }
                    }
                }
            }
        }
        .receiptPickerCard()
    }

    private func itemSectionCard(
        title: String,
        subtitle: String,
        systemImage: String,
        items: [DataBaseItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage
            )

            LazyVStack(spacing: 8) {
                ForEach(items) { item in
                    DatabaseItemPickerRow(
                        item: item,
                        isSelected: item.id == dBItem.id
                    ) {
                        selectItem(item)
                    }
                }
            }
        }
        .receiptPickerCard()
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))

            Spacer()

            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.badge.plus")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(hasSearch ? "No matching items." : "No database items yet.")
                .font(.subheadline.weight(.semibold))

            Text(hasSearch ? "Create a new database item using this search term." : "Create a database item to use it on receipts, jobs, and material planning.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showNewItem = true
            } label: {
                Label("Create New Item", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyDataBaseItem: DataBaseItem {
        DataBaseItem(
            id: "",
            name: "",
            rate: 0,
            storeName: "",
            venderId: "",
            category: .chems,
            subCategory: .bushing,
            description: "",
            dateUpdated: Date(),
            sku: "",
            billable: true,
            color: "",
            size: "",
            UOM: .ft
        )
    }

    private func loadItems() async {
        guard let selectedCompany = masterDataManager.currentCompany else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try await receiptDataBaseViewModel.getAllDataBaseItems(
                companyId: selectedCompany.id
            )

            try await receiptDataBaseViewModel.getCommonDataBaseItems(
                companyId: selectedCompany.id
            )

            filterItems(searchTerm)
        } catch {
            loadErrorMessage = error.localizedDescription
            showLoadError = true
        }
    }

    private func filterItems(_ term: String) {
        let cleanedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedTerm.isEmpty else {
            displayItems = receiptDataBaseViewModel.dataBaseItems
            return
        }

        displayItems = receiptDataBaseViewModel.dataBaseItems.filter { item in
            let rateString = String(item.rate)
            let sellPriceString = item.sellPrice.map { String($0) } ?? ""

            return item.name.localizedCaseInsensitiveContains(cleanedTerm) ||
            item.sku.localizedCaseInsensitiveContains(cleanedTerm) ||
            item.description.localizedCaseInsensitiveContains(cleanedTerm) ||
            item.storeName.localizedCaseInsensitiveContains(cleanedTerm) ||
            rateString.localizedCaseInsensitiveContains(cleanedTerm) ||
            sellPriceString.localizedCaseInsensitiveContains(cleanedTerm)
        }
    }

    private func selectItem(_ item: DataBaseItem) {
        dBItem = item
        dismissPicker()
    }

    private func dismissPicker() {
        addNewItem = false
        dismiss()
    }
}

// MARK: - Row

private struct DatabaseItemPickerRow: View {
    let item: DataBaseItem
    let isSelected: Bool
    let onSelect: () -> Void

    private var priceText: String {
        if let sellPrice = item.sellPrice, sellPrice > 0 {
            return "Price \(DataBaseItemMoneyFormatter.moneyFromCents(sellPrice))"
        }

        return "No customer price"
    }

    private var costText: String {
        "Cost \(DataBaseItemMoneyFormatter.moneyFromCents(item.rate))"
    }

    private var detailText: String {
        var parts: [String] = []

        if !item.sku.isEmpty {
            parts.append("SKU \(item.sku)")
        }

        if !item.storeName.isEmpty {
            parts.append(item.storeName)
        }

        parts.append(item.UOM.rawValue)

        return parts.joined(separator: " • ")
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : itemIcon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? .accent : .secondary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(priceText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DataBaseItemMoneyFormatter.hasCustomerPrice(item) ? .green : .orange)
                                .lineLimit(1)

                            Text(costText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if !detailText.isEmpty {
                        Text(detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if !item.description.isEmpty {
                        Text(item.description)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        Text(item.category.rawValue)
                        Text("•")
                        Text(item.subCategory.rawValue)

                        if item.billable {
                            Text("•")
                            Label("Billable", systemImage: "dollarsign.circle")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private var itemIcon: String {
        switch item.category {
        case .chems:
            return "drop"
        default:
            switch item.subCategory.rawValue.lowercased() {
            case let value where value.contains("pump"):
                return "gearshape"
            case let value where value.contains("filter"):
                return "line.3.horizontal.decrease.circle"
            case let value where value.contains("chemical"):
                return "drop"
            default:
                return "shippingbox"
            }
        }
    }

}

// MARK: - Styling

private extension View {
    func receiptPickerCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
