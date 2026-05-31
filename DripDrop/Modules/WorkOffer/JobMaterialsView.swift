//
//  JobMaterialsView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import SwiftUI

struct JobMaterialsView: View {

    let shoppingItems: [ShoppingListItem]
    let purchasedItems: [PurchasedItem]

    let plannedMaterialCostCents: Int
    let plannedMaterialPriceCents: Int
    let actualPurchasedMaterialCostCents: Int
    let billablePurchasedMaterialPriceCents: Int

    let onAddShoppingItem: () -> Void
    let onEditShoppingItem: (ShoppingListItem) -> Void
    let onDeleteShoppingItem: (ShoppingListItem) -> Void

    private var needToPurchaseItems: [ShoppingListItem] {
        shoppingItems.filter { item in
            item.status.rawValue.localizedCaseInsensitiveContains("Need")
        }
    }

    private var purchasedShoppingItems: [ShoppingListItem] {
        shoppingItems.filter { item in
            item.status.rawValue.localizedCaseInsensitiveContains("Purchased")
        }
    }

    private var installedShoppingItems: [ShoppingListItem] {
        shoppingItems.filter { item in
            item.status.rawValue.localizedCaseInsensitiveContains("Installed")
        }
    }

    private var uninvoicedPurchasedItems: [PurchasedItem] {
        purchasedItems.filter { !$0.invoiced }
    }

    private var billablePurchasedItems: [PurchasedItem] {
        purchasedItems.filter { $0.billable }
    }

    private var materialCostDifferenceCents: Int {
        actualPurchasedMaterialCostCents - plannedMaterialCostCents
    }

    private var materialPriceDifferenceCents: Int {
        billablePurchasedMaterialPriceCents - plannedMaterialPriceCents
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                summaryCard
                plannedMaterialsCard
                purchasedMaterialsCard
                uninvoicedMaterialsCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Materials")
                    .font(.title3.weight(.semibold))

                Text("Track planned materials, actual purchases, billable items, and material cost differences.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                JobMaterialsSummaryChip(
                    title: "Planned",
                    value: "\(shoppingItems.count)",
                    systemImage: "cart"
                )

                JobMaterialsSummaryChip(
                    title: "Purchased",
                    value: "\(purchasedItems.count)",
                    systemImage: "receipt"
                )

                JobMaterialsSummaryChip(
                    title: "Billable",
                    value: "\(billablePurchasedItems.count)",
                    systemImage: "dollarsign.circle"
                )
            }
        }
        .jobMaterialsCard()
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Material Summary")
                .font(.headline.weight(.semibold))

            JobMaterialsDetailRow(
                title: "Planned Cost",
                value: JobMaterialsMoneyFormatter.money(plannedMaterialCostCents)
            )

            JobMaterialsDetailRow(
                title: "Actual Purchased Cost",
                value: JobMaterialsMoneyFormatter.money(actualPurchasedMaterialCostCents)
            )

            JobMaterialsDetailRow(
                title: "Cost Difference",
                value: JobMaterialsMoneyFormatter.signedMoney(materialCostDifferenceCents),
                valueIsWarning: materialCostDifferenceCents > 0
            )

            Divider().opacity(0.2)

            JobMaterialsDetailRow(
                title: "Planned Billable Price",
                value: JobMaterialsMoneyFormatter.money(plannedMaterialPriceCents)
            )

            JobMaterialsDetailRow(
                title: "Purchased Billable Price",
                value: JobMaterialsMoneyFormatter.money(billablePurchasedMaterialPriceCents)
            )

            JobMaterialsDetailRow(
                title: "Billable Difference",
                value: JobMaterialsMoneyFormatter.signedMoney(materialPriceDifferenceCents),
                valueIsWarning: materialPriceDifferenceCents < 0
            )
        }
        .jobMaterialsCard()
    }

    private var plannedMaterialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Planned Materials", systemImage: "cart")
                    .font(.headline.weight(.semibold))

                Spacer()

                Button {
                    onAddShoppingItem()
                } label: {
                    Label("Add", systemImage: "plus.circle")
                        .font(.caption.weight(.semibold))
                }
            }

            if shoppingItems.isEmpty {
                JobMaterialsEmptyMiniState(
                    title: "No planned materials.",
                    message: "Add materials needed for this job before buying or billing.",
                    systemImage: "cart.badge.plus"
                )
            } else {
                if !needToPurchaseItems.isEmpty {
                    materialGroup(
                        title: "Need To Purchase",
                        items: needToPurchaseItems
                    )
                }

                if !purchasedShoppingItems.isEmpty {
                    materialGroup(
                        title: "Marked Purchased",
                        items: purchasedShoppingItems
                    )
                }

                if !installedShoppingItems.isEmpty {
                    materialGroup(
                        title: "Installed",
                        items: installedShoppingItems
                    )
                }

                let otherItems = shoppingItems.filter { item in
                    !needToPurchaseItems.contains(item) &&
                    !purchasedShoppingItems.contains(item) &&
                    !installedShoppingItems.contains(item)
                }

                if !otherItems.isEmpty {
                    materialGroup(
                        title: "Other",
                        items: otherItems
                    )
                }
            }
        }
        .jobMaterialsCard()
    }

    private func materialGroup(
        title: String,
        items: [ShoppingListItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(items) { item in
                    JobShoppingMaterialRow(
                        item: item,
                        onEdit: {
                            onEditShoppingItem(item)
                        },
                        onDelete: {
                            onDeleteShoppingItem(item)
                        }
                    )
                }
            }
        }
    }

    private var purchasedMaterialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Purchased Materials", systemImage: "receipt")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(purchasedItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if purchasedItems.isEmpty {
                JobMaterialsEmptyMiniState(
                    title: "No purchased items linked.",
                    message: "Vendor receipt items linked to this job will appear here.",
                    systemImage: "receipt"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(purchasedItems) { item in
                        JobPurchasedMaterialRow(item: item)
                    }
                }
            }
        }
        .jobMaterialsCard()
    }

    private var uninvoicedMaterialsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Needs Billing Review", systemImage: "exclamationmark.triangle")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(uninvoicedPurchasedItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if uninvoicedPurchasedItems.isEmpty {
                JobMaterialsEmptyMiniState(
                    title: "No material billing issues.",
                    message: "All linked purchased items are either invoiced or not billable.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(uninvoicedPurchasedItems) { item in
                        JobPurchasedMaterialRow(item: item)
                    }
                }
            }
        }
        .jobMaterialsCard()
    }
}

// MARK: - Rows

struct JobShoppingMaterialRow: View {
    var item: ShoppingListItem
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(item.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text("\(item.subCategory.rawValue) • Qty: \(item.quantity ?? "-")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !plannedPriceText.isEmpty {
                    Text(plannedPriceText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if let plannedTotalCostCents = item.plannedTotalCostCents {
                    Text("Planned cost: \(JobMaterialsMoneyFormatter.money(plannedTotalCostCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let plannedTotalPriceCents = item.plannedTotalPriceCents {
                    Text("Planned billable: \(JobMaterialsMoneyFormatter.money(plannedTotalPriceCents))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Button("Edit") {
                        onEdit()
                    }
                    .font(.caption.weight(.semibold))

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Text("Delete")
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iconName: String {
        switch item.subCategory.rawValue.lowercased() {
        case let value where value.contains("chemical"):
            return "drop"
        case let value where value.contains("part"):
            return "wrench.adjustable"
        case let value where value.contains("data"):
            return "shippingbox"
        default:
            return "cart"
        }
    }
    private var plannedPriceText: String {
        var parts: [String] = []

        if let unitCost = item.plannedUnitCostCents {
            parts.append("Cost \(JobMaterialsMoneyFormatter.money(unitCost))")
        }

        if let unitPrice = item.plannedUnitPriceCents {
            parts.append("Bill \(JobMaterialsMoneyFormatter.money(unitPrice))")
        }

        return parts.joined(separator: " • ")
    }
}

struct JobPurchasedMaterialRow: View {
    var item: PurchasedItem

    private var billablePrice: Double {
        item.billingRate ?? item.price
    }

    private var billableTotal: Double {
        billablePrice * item.quantity
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.billable ? "receipt.badge.plus" : "receipt")
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(JobMaterialsMoneyFormatter.moneyFromDollars(item.totalAfterTax))
                        .font(.subheadline.weight(.semibold))
                }

                Text("\(item.venderName) • Qty: \(item.quantityString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(item.billable ? "Billable" : "Not Billable")
                    Text("•")
                    Text(item.invoiced ? "Invoiced" : "Not Invoiced")
                }
                .font(.caption2)
                .foregroundStyle(item.billable && !item.invoiced ? .orange : .secondary)

                if item.billable {
                    Text("Billable total: \(JobMaterialsMoneyFormatter.moneyFromDollars(billableTotal))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct JobMaterialsSummaryChip: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct JobMaterialsDetailRow: View {
    var title: String
    var value: String
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct JobMaterialsEmptyMiniState: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Formatter

enum JobMaterialsMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }

    static func signedMoney(_ cents: Int) -> String {
        if cents == 0 {
            return "$0.00"
        }

        let prefix = cents > 0 ? "+" : "-"
        return prefix + money(abs(cents))
    }

    static func moneyFromDollars(_ dollars: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

private extension View {
    func jobMaterialsCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
