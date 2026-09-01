//
//  ShoppingListItemDraftForm.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


//
//  ShoppingListItemDraftForm.swift
//  DripDrop
//

import SwiftUI

struct ShoppingListItemDraftForm: View {
    @EnvironmentObject var dataService: ProductionDataService

    @Binding var draft: ShoppingListItemDraft

    @State private var showDataBaseItemPicker: Bool = false
    @State private var showProductCatalogPicker: Bool = false

    var title: String = "Item Details"
    var showCategoryPicker: Bool = false
    var showDescription: Bool = true

    private let itemTypeOptions: [ShoppingListSubCategory] = [
        .product,
        .custom,
        .chemical,
        .part
    ]

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
                ForEach(itemTypeOptions, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: draft.subCategory) { _ in
                if draft.subCategory != .product {
                    draft.selectedProduct = .emptyProductCatalogItem
                }

                if draft.subCategory != .dataBase {
                    draft.selectedDataBaseItem = ShoppingListItemDraft().selectedDataBaseItem
                }
            }
        }
    }

    @ViewBuilder
    private var itemInputSection: some View {
        switch draft.subCategory {
        case .product:
            productCatalogSection

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

    private var productCatalogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Product")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                showProductCatalogPicker.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(draft.selectedProduct.id.isEmpty ? "Select Product" : draft.selectedProduct.productDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(draft.selectedProduct.id.isEmpty ? .secondary : .primary)

                        if !draft.selectedProduct.id.isEmpty {
                            Text(productSubtitle)
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
            .sheet(isPresented: $showProductCatalogPicker) {
                ProductCatalogPicker(
                    dataService: dataService,
                    product: $draft.selectedProduct,
                    onlyPartPurchaseAvailable: true
                )
            }
            .onChange(of: draft.selectedProduct) { item in
                draft.applySelectedProduct(item)
            }
        }
    }

    private var databaseItemSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vendor Item")
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
                        Text(draft.selectedDataBaseItem.id.isEmpty ? "Select Vendor Item" : draft.selectedDataBaseItem.name)
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

    private var productSubtitle: String {
        var parts: [String] = []

        if draft.selectedProduct.productSellPriceCents > 0 {
            parts.append("Price \(DataBaseItemMoneyFormatter.moneyFromCents(draft.selectedProduct.productSellPriceCents))")
        }

        if !draft.selectedProduct.category.isEmpty {
            parts.append(draft.selectedProduct.category)
        }

        if !draft.selectedProduct.UOM.isEmpty {
            parts.append(draft.selectedProduct.UOM)
        }

        return parts.isEmpty ? draft.selectedProduct.productDescription : parts.joined(separator: " • ")
    }

    private var databaseItemSubtitle: String {
        var parts: [String] = []

        if !draft.selectedDataBaseItem.sku.isEmpty {
            parts.append("SKU \(draft.selectedDataBaseItem.sku)")
        }

        if let sellPrice = draft.selectedDataBaseItem.sellPrice, sellPrice > 0 {
            parts.append("Price \(DataBaseItemMoneyFormatter.moneyFromCents(sellPrice))")
        }

        if draft.selectedDataBaseItem.rate > 0 {
            parts.append("Cost \(DataBaseItemMoneyFormatter.moneyFromCents(draft.selectedDataBaseItem.rate))")
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
