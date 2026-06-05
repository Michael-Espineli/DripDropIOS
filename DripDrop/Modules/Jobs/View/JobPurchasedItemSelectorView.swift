//
//  JobPurchasedItemSelectorView.swift
//  DripDrop
//
//  Created by Codex on 6/2/26.
//

import SwiftUI

private enum JobPurchasedItemBillableFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case billable = "Billable"
    case nonBillable = "Non-billable"

    var id: String { rawValue }
}

private enum JobPurchasedItemInvoiceFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case invoiced = "Invoiced"
    case notInvoiced = "Not Invoiced"

    var id: String { rawValue }
}

struct JobPurchasedItemSelectorView: View {
    let items: [PurchasedItem]
    let categoryByPurchasedItemId: [String: DataBaseItemCategory]
    let isLoading: Bool
    let onLoad: (Date, Date) async throws -> Void
    let onAttach: ([PurchasedItem]) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var selectedItemIds: Set<String> = []
    @State private var isAttaching: Bool = false
    @State private var errorMessage: String?
    @State private var selectedCategory: DataBaseItemCategory?
    @State private var billableFilter: JobPurchasedItemBillableFilter = .all
    @State private var invoiceFilter: JobPurchasedItemInvoiceFilter = .all

    private var selectedItems: [PurchasedItem] {
        items.filter { selectedItemIds.contains($0.id) }
    }

    private var filteredItems: [PurchasedItem] {
        items.filter { item in
            let categoryMatches = selectedCategory == nil || category(for: item) == selectedCategory
            let billableMatches: Bool
            switch billableFilter {
            case .all:
                billableMatches = true
            case .billable:
                billableMatches = item.isJobBillable
            case .nonBillable:
                billableMatches = !item.isJobBillable
            }

            let invoiceMatches: Bool
            switch invoiceFilter {
            case .all:
                invoiceMatches = true
            case .invoiced:
                invoiceMatches = item.invoiced
            case .notInvoiced:
                invoiceMatches = !item.invoiced
            }

            return categoryMatches && billableMatches && invoiceMatches
        }
    }

    private var categoryOptions: [DataBaseItemCategory] {
        let categories = Set(items.compactMap { category(for: $0) }.filter { $0 != .na })
        return categories.sorted { $0.rawValue < $1.rawValue }
    }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || billableFilter != .all || invoiceFilter != .all
    }

    private var selectedCategoryTitle: String {
        guard let selectedCategory, !selectedCategory.rawValue.isEmpty else {
            return "All"
        }

        return selectedCategory.rawValue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateRangeCard
                filterCard

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                if isLoading {
                    ProgressView("Loading unassigned purchased items...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if items.isEmpty {
                    ContentUnavailableView(
                        "No Unassigned Purchased Items",
                        systemImage: "receipt",
                        description: Text("Adjust the date range to search more receipt items.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No Matching Purchased Items",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Adjust the filters or load a wider date range.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredItems) { item in
                        Button {
                            toggle(item)
                        } label: {
                            purchasedItemRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Attach Purchases")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .disabled(isAttaching)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(attachButtonTitle) {
                        Task {
                            await attachSelectedItems()
                        }
                    }
                    .disabled(selectedItemIds.isEmpty || isAttaching)
                }
            }
            .task {
                await loadItems()
            }
        }
    }

    private var attachButtonTitle: String {
        if isAttaching {
            return "Attaching..."
        }

        if selectedItemIds.isEmpty {
            return "Attach"
        }

        return "Attach \(selectedItemIds.count)"
    }

    private var dateRangeCard: some View {
        VStack(spacing: 12) {
            HStack {
                DatePicker("Start", selection: $startDate, displayedComponents: .date)
                DatePicker("End", selection: $endDate, displayedComponents: .date)
            }
            .font(.subheadline)

            Button {
                Task {
                    await loadItems()
                }
            } label: {
                Label(isLoading ? "Loading..." : "Load Items", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isLoading || isAttaching)
        }
        .padding()
    }

    private var filterCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Filters")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text("\(filteredItems.count) of \(items.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                Menu {
                    Button("All Categories") {
                        selectedCategory = nil
                    }

                    if categoryOptions.isEmpty {
                        Button("No Categories Loaded") {}
                            .disabled(true)
                    } else {
                        Divider()

                        ForEach(categoryOptions, id: \.self) { category in
                            Button(category.rawValue) {
                                selectedCategory = category
                            }
                        }
                    }
                } label: {
                    filterMenuLabel(
                        title: "Category",
                        value: selectedCategoryTitle,
                        systemImage: "tag"
                    )
                }

                Menu {
                    ForEach(JobPurchasedItemBillableFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            billableFilter = filter
                        }
                    }
                } label: {
                    filterMenuLabel(
                        title: "Billable",
                        value: billableFilter.rawValue,
                        systemImage: "dollarsign.circle"
                    )
                }

                Menu {
                    ForEach(JobPurchasedItemInvoiceFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            invoiceFilter = filter
                        }
                    }
                } label: {
                    filterMenuLabel(
                        title: "Invoice",
                        value: invoiceFilter.rawValue,
                        systemImage: "doc.text"
                    )
                }

                Button {
                    clearFilters()
                } label: {
                    Label("Clear", systemImage: "xmark.circle")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(hasActiveFilters ? 0.08 : 0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!hasActiveFilters)
            }

            if !selectedItemIds.isEmpty {
                Text("\(selectedItemIds.count) selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    private func filterMenuLabel(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func purchasedItemRow(_ item: PurchasedItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: selectedItemIds.contains(item.id) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectedItemIds.contains(item.id) ? Color.accentColor : .secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(JobMaterialsMoneyFormatter.moneyFromDollars(item.totalAfterTax))
                        .font(.subheadline.weight(.semibold))
                }

                Text("\(item.venderName) • \(item.date.formatted(date: .abbreviated, time: .omitted)) • Qty: \(item.quantityString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    if let category = category(for: item), !category.rawValue.isEmpty {
                        filterPill(category.rawValue, systemImage: "tag")
                    }

                    filterPill(item.isJobBillable ? "Billable" : "Non-billable", systemImage: item.isJobBillable ? "dollarsign.circle" : "nosign")
                    filterPill(item.invoiced ? "Invoiced" : "Not Invoiced", systemImage: item.invoiced ? "checkmark.seal" : "doc.text")
                }

                if !item.invoiceNum.isEmpty || !item.sku.isEmpty {
                    Text([item.invoiceNum.isEmpty ? "" : "Invoice: \(item.invoiceNum)", item.sku.isEmpty ? "" : "SKU: \(item.sku)"].filter { !$0.isEmpty }.joined(separator: " • "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func filterPill(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.06), in: Capsule())
    }

    private func toggle(_ item: PurchasedItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
    }

    private func loadItems() async {
        errorMessage = nil
        selectedItemIds.removeAll()

        do {
            try await onLoad(startDate, endDate)
        } catch {
            errorMessage = "Unable to load purchased items."
            print("[JobPurchasedItemSelectorView][loadItems] \(error)")
        }
    }

    private func attachSelectedItems() async {
        errorMessage = nil
        isAttaching = true
        defer { isAttaching = false }

        do {
            try await onAttach(selectedItems)
            dismiss()
        } catch {
            errorMessage = "Unable to attach selected items."
            print("[JobPurchasedItemSelectorView][attachSelectedItems] \(error)")
        }
    }

    private func category(for item: PurchasedItem) -> DataBaseItemCategory? {
        categoryByPurchasedItemId[item.id] ?? categoryByPurchasedItemId[item.itemId]
    }

    private func clearFilters() {
        selectedCategory = nil
        billableFilter = .all
        invoiceFilter = .all
    }
}
