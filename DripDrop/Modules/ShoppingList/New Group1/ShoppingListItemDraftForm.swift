//
//  ShoppingListItemDraftForm.swift
//  DripDrop
//

import SwiftUI

struct ShoppingListItemDraftForm: View {
    @EnvironmentObject var dataService: ProductionDataService

    @Binding var draft: ShoppingListItemDraft

    @State private var showDataBaseItemPicker: Bool = false

    var title: String = "Item Details"
    var showCategoryPicker: Bool = false
    var showDescription: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.semibold))

            if showCategoryPicker {
                categorySection
            }

            itemTypeSection
            itemInputSection
            quantitySection

            if showDescription {
                descriptionSection
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Category", selection: $draft.category) {
                ForEach(ShoppingListCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var itemTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Item Type")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Item Type", selection: $draft.subCategory) {
                ForEach(ShoppingListSubCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.subCategory) { _ in
                if draft.subCategory != .dataBase {
                    draft.selectedDataBaseItem = ShoppingListItemDraft().selectedDataBaseItem
                }
            }
        }
    }

    @ViewBuilder
    private var itemInputSection: some View {
        switch draft.subCategory {
        case .dataBase:
            databaseItemSection

        case .custom:
            manualNameSection(
                title: "Custom Item",
                placeholder: "Enter item name"
            )

        case .chemical:
            manualNameSection(
                title: "Chemical",
                placeholder: "Enter chemical name"
            )

        case .part:
            manualNameSection(
                title: "Part",
                placeholder: "Enter part name"
            )
        }
    }

    private var databaseItemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Database Item")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                showDataBaseItemPicker.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(draft.selectedDataBaseItem.id.isEmpty ? "Select Database Item" : draft.selectedDataBaseItem.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(draft.selectedDataBaseItem.id.isEmpty ? .secondary : .primary)

                        if !draft.selectedDataBaseItem.id.isEmpty {
                            Text(databaseItemSubtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showDataBaseItemPicker) {
                ReceiptDataBaseItemPicker(
                    dataService: dataService,
                    addNewItem: $showDataBaseItemPicker,
                    dBItem: $draft.selectedDataBaseItem
                )
            }
            .onChange(of: draft.selectedDataBaseItem) { item in
                draft.applySelectedDataBaseItem(item)
            }
        }
    }

    private var databaseItemSubtitle: String {
        var parts: [String] = []

        if !draft.selectedDataBaseItem.sku.isEmpty {
            parts.append("SKU \(draft.selectedDataBaseItem.sku)")
        }

        if draft.selectedDataBaseItem.rate > 0 {
            parts.append(draft.selectedDataBaseItem.rate.formatted(.currency(code: "USD")))
        }

        if let sellPrice = draft.selectedDataBaseItem.sellPrice, sellPrice > 0 {
            parts.append("Sell \(sellPrice.formatted(.currency(code: "USD")))")
        }

        return parts.isEmpty ? draft.selectedDataBaseItem.description : parts.joined(separator: " • ")
    }

    private func manualNameSection(
        title: String,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $draft.name)
                .modifier(PlainTextFieldModifier())
        }
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quantity")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Quantity", text: $draft.quantity)
                .keyboardType(.decimalPad)
                .modifier(PlainTextFieldModifier())
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(
                "Optional notes...",
                text: $draft.description,
                axis: .vertical
            )
            .lineLimit(3, reservesSpace: true)
            .modifier(PlainTextFieldModifier())
        }
    }
}