//
//  ShoppingListItemCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/19/24.
//
//

import SwiftUI

@MainActor
final class ShoppingListItemCardViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var dataBaseItem: DataBaseItem? = nil
    @Published private(set) var job: Job? = nil

    func onLoad(
        companyId: String,
        shoppingListItem: ShoppingListItem
    ) async throws {
        if let databaseItemId = databaseItemId(for: shoppingListItem) {
            self.dataBaseItem = try? await dataService.getDataBaseItem(
                companyId: companyId,
                dataBaseItemId: databaseItemId
            )
        }

        switch shoppingListItem.category {
        case .personal:
            break

        case .customer:
            break

        case .job:
            if let jobId = shoppingListItem.jobId,
               !jobId.isEmpty {
                self.job = try? await dataService.getWorkOrderById(
                    companyId: companyId,
                    workOrderId: jobId
                )
            }
        }

    }

    private func databaseItemId(for shoppingListItem: ShoppingListItem) -> String? {
        if let dbItemId = shoppingListItem.dbItemId,
           !dbItemId.isEmpty {
            return dbItemId
        }

        if shoppingListItem.subCategory == .dataBase,
           !shoppingListItem.genericItemId.isEmpty {
            return shoppingListItem.genericItemId
        }

        return nil
    }

    func updateShoppingListItemStatus(
        companyId: String,
        shoppingListItemId: String,
        status: ShoppingListStatus
    ) async throws {
        try await dataService.updateShoppingListItemStatus(
            companyId: companyId,
            shoppingListItemId: shoppingListItemId,
            status: status
        )
//        try await dataService.updateShoppingListItemStatus(
//            companyId: companyId,
//            itemId: item.id,
//            status: newStatus,
//            needsAction: newStatus != .installed
//        )
    }
}


struct ShoppingListItemCardView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let shoppingListItem: ShoppingListItem

    @StateObject private var viewModel: ShoppingListItemCardViewModel

    init(
        dataService: any ProductionDataServiceProtocol,
        shoppingListItem: ShoppingListItem
    ) {
        self.dataService = dataService
        self.shoppingListItem = shoppingListItem
        _viewModel = StateObject(
            wrappedValue: ShoppingListItemCardViewModel(dataService: dataService)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            topRow

            if !shoppingListItem.description.isEmpty {
                Text(shoppingListItem.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            contextRows

            moneyRows

            footerBadges
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(statusTint.opacity(0.22), lineWidth: 1)
        }
        .task(id: shoppingListItem.id) {
            guard let company = masterDataManager.currentCompany else { return }

            try? await viewModel.onLoad(
                companyId: company.id,
                shoppingListItem: shoppingListItem
            )
        }
    }
}

// MARK: - Sections

extension ShoppingListItemCardView {

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusTint.opacity(0.14))
                    .frame(width: 40, height: 40)

                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(statusTint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(shoppingListItem.subCategory.rawValue) • Qty: \(quantityText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            statusBadge
        }
    }

    private var contextRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let contextText {
                Label(contextText, systemImage: contextIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let serviceLocationName = shoppingListItem.serviceLocationName,
               !serviceLocationName.isEmpty {
                Label(serviceLocationName, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let serviceStopInternalId = shoppingListItem.serviceStopInternalId,
               !serviceStopInternalId.isEmpty {
                Label("Stop \(serviceStopInternalId)", systemImage: "calendar.badge.clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var moneyRows: some View {
        if hasCustomerPrice {
            HStack {
                if let customerUnitPriceCents {
                    moneyChip(
                        title: "Price",
                        value: ShoppingListItemMoneyFormatter.money(customerUnitPriceCents)
                    )
                }

                if let customerTotalPriceCents {
                    moneyChip(
                        title: "Total Price",
                        value: ShoppingListItemMoneyFormatter.money(customerTotalPriceCents)
                    )
                }
            }
        } else if hasPlannedMoney || hasDatabaseItemPricingContext {
            Label("No customer price set", systemImage: "exclamationmark.triangle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var footerBadges: some View {
        HStack(spacing: 8) {
            categoryBadge

            if shoppingListItem.needsAction {
                smallBadge(
                    title: "Needs Action",
                    systemImage: "exclamationmark.circle",
                    tint: .orange
                )
            }

            if shoppingListItem.invoiced {
                smallBadge(
                    title: "Invoiced",
                    systemImage: "checkmark.seal",
                    tint: .green
                )
            }

            Spacer()
        }
    }
}

// MARK: - Components

extension ShoppingListItemCardView {

    private var statusBadge: some View {
        Text(shoppingListItem.status.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(statusTint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(statusTint.opacity(0.12), in: Capsule())
    }

    private var categoryBadge: some View {
        smallBadge(
            title: shoppingListItem.category.rawValue,
            systemImage: categoryIcon,
            tint: .secondary
        )
    }

    private func smallBadge(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
    }

    private func moneyChip(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Computed Values

extension ShoppingListItemCardView {

    private var displayName: String {
        if !shoppingListItem.name.isEmpty {
            return shoppingListItem.name
        }

        if let purchasedItem = shoppingListItem.purchasedItem,
           !purchasedItem.isEmpty {
            return purchasedItem
        }

        return "Shopping Item"
    }

    private var quantityText: String {
        guard let quantity = shoppingListItem.quantity,
              !quantity.isEmpty else {
            return "-"
        }

        return quantity
    }

    private var hasPlannedMoney: Bool {
        shoppingListItem.plannedUnitCostCents != nil ||
        shoppingListItem.plannedUnitPriceCents != nil ||
        shoppingListItem.plannedTotalCostCents != nil ||
        shoppingListItem.plannedTotalPriceCents != nil
    }

    private var hasCustomerPrice: Bool {
        customerUnitPriceCents != nil || customerTotalPriceCents != nil
    }

    private var hasDatabaseItemPricingContext: Bool {
        if viewModel.dataBaseItem != nil {
            return true
        }

        if let dbItemId = shoppingListItem.dbItemId,
           !dbItemId.isEmpty {
            return true
        }

        return shoppingListItem.subCategory == .dataBase && !shoppingListItem.genericItemId.isEmpty
    }

    private var customerUnitPriceCents: Int? {
        if let sellPrice = viewModel.dataBaseItem?.sellPrice,
           sellPrice > 0 {
            return Int(sellPrice.rounded())
        }

        return shoppingListItem.plannedUnitPriceCents
    }

    private var customerTotalPriceCents: Int? {
        if let sellPrice = viewModel.dataBaseItem?.sellPrice,
           sellPrice > 0 {
            let quantity = Double(shoppingListItem.quantity ?? "") ?? 1

            return Int((sellPrice * quantity).rounded())
        }

        return shoppingListItem.plannedTotalPriceCents
    }

    private var contextText: String? {
        switch shoppingListItem.category {
        case .personal:
            if let userName = shoppingListItem.userName,
               !userName.isEmpty {
                return userName
            }

            return shoppingListItem.purchaserName.isEmpty ? nil : shoppingListItem.purchaserName

        case .customer:
            if let customerName = shoppingListItem.customerName,
               !customerName.isEmpty {
                return customerName
            }

            return nil

        case .job:
            if let jobId = shoppingListItem.jobId,
               !jobId.isEmpty {
                if let customerName = shoppingListItem.customerName,
                   !customerName.isEmpty {
                    return "\(customerName) • Job"
                }

                return "Job \(jobId)"
            }

            return nil
        }
    }

    private var contextIcon: String {
        switch shoppingListItem.category {
        case .personal:
            return "person.crop.circle"

        case .customer:
            return "person.text.rectangle"

        case .job:
            return "briefcase"
        }
    }

    private var categoryIcon: String {
        switch shoppingListItem.category {
        case .personal:
            return "person.crop.circle"

        case .customer:
            return "person.text.rectangle"

        case .job:
            return "briefcase"
        }
    }

    private var iconName: String {
        switch shoppingListItem.subCategory {
        case .chemical:
            return "drop"

        case .part:
            return "wrench.and.screwdriver"

        case .custom:
            return "shippingbox"

        case .dataBase:
            return "tray.full"
        }
    }

    private var statusTint: Color {
        let status = shoppingListItem.status.rawValue.lowercased()

        if status.contains("installed") {
            return .green
        }

        if status.contains("purchased") {
            return .blue
        }

        if status.contains("need") || status.contains("purchase") {
            return .orange
        }

        return .secondary
    }
}
private enum ShoppingListItemMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}
