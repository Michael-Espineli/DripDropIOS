//
//  ShoppingListItemDraft.swift
//  DripDrop
//

import Foundation

struct ShoppingListItemDraft: Hashable {
    var category: ShoppingListCategory = .job
    var subCategory: ShoppingListSubCategory = .dataBase
    var status: ShoppingListStatus = .needToPurchase

    var name: String = ""
    var description: String = ""
    var quantity: String = "1"

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
        if subCategory == .dataBase, !selectedDataBaseItem.id.isEmpty {
            return selectedDataBaseItem.name
        }

        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var selectedDataBaseItemId: String? {
        selectedDataBaseItem.id.isEmpty ? nil : selectedDataBaseItem.id
    }

    var canSubmit: Bool {
        switch subCategory {
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

    func makeShoppingListItem(
        id: String = UUID().uuidString,
        purchaserId: String,
        purchaserName: String,
        jobId: String?,
        customerId: String?,
        customerName: String?
    ) -> ShoppingListItem {
        ShoppingListItem(
            id: id,
            category: category,
            subCategory: subCategory,
            status: status,
            purchaserId: purchaserId,
            purchaserName: purchaserName,
            genericItemId: "",
            name: displayName,
            description: description,
            datePurchased: datePurchased,
            quantity: quantity,
            jobId: jobId,
            customerId: customerId ?? "",
            customerName: customerName ?? "",
            dbItemId: selectedDataBaseItemId,
            invoiced: true
        )
    }
}