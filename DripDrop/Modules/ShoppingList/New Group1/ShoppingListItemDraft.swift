//
//  ShoppingListItemDraft.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//



import Foundation

struct ShoppingListItemDraft: Hashable {
    var category: ShoppingListCategory = .job
    var subCategory: ShoppingListSubCategory = .product
    var status: ShoppingListStatus = .needToPurchase

    var name: String = ""
    var description: String = ""
    var quantity: String = "1"
    var selectedProduct: GenericItem = .emptyProductCatalogItem

    var selectedDataBaseItem: DataBaseItem = DataBaseItem(
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
        billable: false,
        color: "",
        size: "",
        UOM: .ft
    )

    var datePurchased: Date? = Date()

    var displayName: String {
        if subCategory == .product, !selectedProduct.id.isEmpty {
            return selectedProduct.productDisplayName
        }

        if subCategory == .dataBase, !selectedDataBaseItem.id.isEmpty {
            return selectedDataBaseItem.name
        }

        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var selectedProductId: String? {
        selectedProduct.id.isEmpty ? nil : selectedProduct.id
    }

    var selectedDataBaseItemId: String? {
        selectedDataBaseItem.id.isEmpty ? nil : selectedDataBaseItem.id
    }

    var canSubmit: Bool {
        switch subCategory {
        case .product:
            return !selectedProduct.id.isEmpty && !quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .dataBase:
            return !selectedDataBaseItem.id.isEmpty && !quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .custom, .chemical, .part:
            return !displayName.isEmpty && !quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    mutating func applySelectedDataBaseItem(_ item: DataBaseItem) {
        selectedDataBaseItem = item

        if !item.id.isEmpty {
            name = item.name
        }
    }

    mutating func applySelectedProduct(_ item: GenericItem) {
        selectedProduct = item

        if !item.id.isEmpty {
            name = item.productDisplayName
        }
    }

    func makeShoppingListItem(
        id: String = UUID().uuidString,
        purchaserId: String,
        purchaserName: String,
        jobId: String?,
        customerId: String?,
        customerName: String?
    ) -> ShoppingListItem {
        let productId = selectedProductId
        let vendorItemId = selectedDataBaseItemId

        return ShoppingListItem(
            id: id,
            category: category,
            subCategory: subCategory,
            status: status,
            purchaserId: purchaserId,
            purchaserName: purchaserName,
            genericItemId: productId ?? selectedDataBaseItem.linkedProductId,
            productId: productId,
            productName: productId == nil ? nil : selectedProduct.productDisplayName,
            name: displayName,
            description: description,
            datePurchased: datePurchased,
            quantity: quantity,
            jobId: jobId,
            customerId: customerId ?? "",
            customerName: customerName ?? "",
            userId: purchaserId,
            userName: purchaserName,
            dbItemId: subCategory == .dataBase ? vendorItemId : nil,
            dbItemName: subCategory == .dataBase ? selectedDataBaseItem.name : nil,
            itemId: productId ?? (subCategory == .dataBase ? vendorItemId : nil),
            itemType: subCategory.rawValue,
            invoiced: true,
            plannedUnitCostCents: plannedUnitCostCents,
            plannedUnitPriceCents: plannedUnitPriceCents,
            plannedTotalCostCents: plannedTotalCostCents,
            plannedTotalPriceCents: plannedTotalPriceCents,
        )
    }
    var quantityDouble: Double {
        Double(quantity) ?? 0
    }

    var plannedUnitCostCents: Int? {
        if subCategory == .product,
           !selectedProduct.id.isEmpty,
           selectedProduct.rate > 0 {
            return Int(selectedProduct.rate.rounded())
        }

        guard subCategory == .dataBase,
              !selectedDataBaseItem.id.isEmpty else {
            return nil
        }

        return Int(selectedDataBaseItem.rate.rounded())
    }

    var plannedUnitPriceCents: Int? {
        if subCategory == .product,
           !selectedProduct.id.isEmpty,
           selectedProduct.productSellPriceCents > 0 {
            return selectedProduct.productSellPriceCents
        }

        guard subCategory == .dataBase,
              !selectedDataBaseItem.id.isEmpty else {
            return nil
        }

        if let sellPrice = selectedDataBaseItem.sellPrice,
           sellPrice > 0 {
            return Int(sellPrice.rounded())
        }

        return nil
    }

    var plannedTotalCostCents: Int? {
        guard let plannedUnitCostCents else {
            return nil
        }

        return Int((Double(plannedUnitCostCents) * quantityDouble).rounded())
    }

    var plannedTotalPriceCents: Int? {
        guard let plannedUnitPriceCents else {
            return nil
        }

        return Int((Double(plannedUnitPriceCents) * quantityDouble).rounded())
    }
}
