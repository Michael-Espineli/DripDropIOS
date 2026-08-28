//
//  ShoppingListItemDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ShoppingListItemDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject private var navigationManager: NavigationStateManager

    @StateObject var jobVM: JobViewModel
    @StateObject var shoppingVM: ShoppingListViewModel
    @StateObject var customerVM: CustomerViewModel

    init(
        item: ShoppingListItem,
        dataService: any ProductionDataServiceProtocol
    ) {
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _receivedItem = State(wrappedValue: item)
    }

    @State private var receivedItem: ShoppingListItem? = nil
    @State private var shoppingListItem: ShoppingListItem? = nil
    @State private var dataBaseItem: DataBaseItem? = nil

    @State private var description: String = ""
    @State private var isSavingDescription: Bool = false
    @State private var isUpdatingStatus: Bool = false

    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let item = shoppingListItem {
                        headerCard(item)
                        statusCard(item)
                        detailCard(item)
                        moneyCard(item)
                        descriptionCard
                        dangerZone
                    } else {
                        emptyState
                    }

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Shopping Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button(role: .destructive) {
                    alertMessage = "This will permanently delete this shopping list item."
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .task {
            shoppingListItem = receivedItem

            if let shoppingListItem {
                masterDataManager.selectedShoppingListItem = shoppingListItem
                description = shoppingListItem.description
                await loadDataBaseItem(for: shoppingListItem)
            }
        }
        .onChange(of: masterDataManager.selectedShoppingListItem) { item in
            shoppingListItem = item

            if let item {
                description = item.description
                Task {
                    await loadDataBaseItem(for: item)
                }
            }
        }
        .alert("Please Confirm Delete", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteItem()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Shopping Item", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
extension ShoppingListItemDetailView {

    private func headerCard(_ item: ShoppingListItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(statusTint(item).opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: itemIcon(item))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(statusTint(item))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(displayName(item))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("\(item.subCategory.rawValue) • Qty: \(item.quantity ?? "-")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !item.purchaserName.isEmpty {
                        Label(item.purchaserName, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            HStack(spacing: 8) {
                statusBadge(item)
                categoryBadge(item)

                if item.needsAction {
                    smallBadge(
                        title: "Needs Action",
                        systemImage: "exclamationmark.circle",
                        tint: .orange
                    )
                }

                Spacer()
            }
        }
        .shoppingDetailCard(material: true)
    }

    private func statusCard(_ item: ShoppingListItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Status",
                subtitle: "Move this item through the shopping workflow.",
                systemImage: "checklist"
            )

            HStack(spacing: 8) {
                statusActionButton(
                    title: "Need",
                    status: .needToPurchase,
                    currentItem: item,
                    systemImage: "cart.badge.plus"
                )

                statusActionButton(
                    title: "Purchased",
                    status: .purchased,
                    currentItem: item,
                    systemImage: "cart.badge.checkmark"
                )

                statusActionButton(
                    title: "Delivered",
                    status: .delivered,
                    currentItem: item,
                    systemImage: "shippingbox"
                )

                statusActionButton(
                    title: "Installed",
                    status: .installed,
                    currentItem: item,
                    systemImage: "checkmark.seal"
                )
            }

            if item.status == .purchased {
                Text("Purchased items still show in prep until they are installed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if item.status == .installed {
                Text("Installed items no longer need shopping action.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .shoppingDetailCard()
    }

    private func detailCard(_ item: ShoppingListItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Details",
                subtitle: "Assignment and routing context.",
                systemImage: "info.circle"
            )

            VStack(spacing: 8) {
                detailRow(
                    title: "Category",
                    value: item.category.rawValue,
                    systemImage: categoryIcon(item)
                )

                detailRow(
                    title: "Subcategory",
                    value: item.subCategory.rawValue,
                    systemImage: itemIcon(item)
                )

                if let customerName = item.customerName, !customerName.isEmpty {
                    detailRow(
                        title: "Customer",
                        value: customerName,
                        systemImage: "person.text.rectangle"
                    )
                }

                if let jobId = item.jobId, !jobId.isEmpty {
                    detailRow(
                        title: "Job",
                        value: jobId,
                        systemImage: "briefcase"
                    )
                }

                if let userName = item.userName, !userName.isEmpty {
                    detailRow(
                        title: "Assigned User",
                        value: userName,
                        systemImage: "person.crop.circle"
                    )
                }

                if let serviceLocationName = item.serviceLocationName,
                   !serviceLocationName.isEmpty {
                    detailRow(
                        title: "Service Location",
                        value: serviceLocationName,
                        systemImage: "mappin.and.ellipse"
                    )
                }

                if let serviceStopInternalId = item.serviceStopInternalId,
                   !serviceStopInternalId.isEmpty {
                    detailRow(
                        title: "Service Stop",
                        value: serviceStopInternalId,
                        systemImage: "calendar.badge.clock"
                    )
                }

                if let datePurchased = item.datePurchased {
                    detailRow(
                        title: "Date Purchased",
                        value: fullDate(date: datePurchased),
                        systemImage: "calendar"
                    )
                }
            }
        }
        .shoppingDetailCard()
    }

    @ViewBuilder
    private func moneyCard(_ item: ShoppingListItem) -> some View {
        if hasPlannedMoney(item) || hasCustomerPrice(item) || databaseItemId(for: item) != nil {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(
                    title: "Customer Price",
                    subtitle: "Uses the linked database item's sellPrice when available.",
                    systemImage: "dollarsign.circle"
                )

                if hasCustomerPrice(item) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 10
                    ) {
                        if let customerUnitPriceCents = customerUnitPriceCents(item) {
                            moneyTile(
                                title: "Price",
                                value: JobMaterialsMoneyFormatter.money(customerUnitPriceCents)
                            )
                        }

                        if let customerTotalPriceCents = customerTotalPriceCents(item) {
                            moneyTile(
                                title: "Total Price",
                                value: JobMaterialsMoneyFormatter.money(customerTotalPriceCents)
                            )
                        }
                    }
                } else {
                    Label("No customer price set", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .shoppingDetailCard()
        }
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Description",
                subtitle: "Add notes or details for this item.",
                systemImage: "note.text"
            )

            TextField(
                "Description",
                text: $description,
                axis: .vertical
            )
            .lineLimit(4...8)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                Task {
                    await saveDescription()
                }
            } label: {
                HStack {
                    if isSavingDescription {
                        ProgressView()
                    }

                    Text(isSavingDescription ? "Saving..." : "Save Description")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSavingDescription)
        }
        .shoppingDetailCard()
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Danger Zone",
                subtitle: "Delete this shopping list item permanently.",
                systemImage: "trash"
            )

            Button(role: .destructive) {
                alertMessage = "This will permanently delete this shopping list item."
                showDeleteConfirmation = true
            } label: {
                Label("Delete Item", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .shoppingDetailCard()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "cart")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No item selected.")
                .font(.subheadline.weight(.semibold))

            Text("Go back and select a shopping list item.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .shoppingDetailCard()
    }
}
extension ShoppingListItemDetailView {

    private func updateStatus(_ status: ShoppingListStatus) async {
        guard let company = masterDataManager.currentCompany,
              var item = shoppingListItem else {
            return
        }

        guard item.status != status else { return }

        isUpdatingStatus = true
        defer { isUpdatingStatus = false }

        do {
            let now = Date()

            try await shoppingVM.updateShoppingListStatus(
                companyId: company.id,
                shoppingListItemId: item.id,
                status: status
            )

            item.status = status
            item.needsAction = status.needsShoppingAction
            item.actionDate = now

            if status == .purchased {
                item.datePurchased = now
            }

            shoppingListItem = item
            masterDataManager.selectedShoppingListItem = item

            alertMessage = "Status updated to \(status.rawValue)."
            showAlert = true
        } catch {
            print("[ShoppingListItemDetailView][updateStatus] Error")
            print(error)

            alertMessage = "Failed to update status."
            showAlert = true
        }
    }

    private func saveDescription() async {
        guard let company = masterDataManager.currentCompany,
              var item = shoppingListItem else {
            return
        }

        guard description != item.description else {
            alertMessage = "No description changes to save."
            showAlert = true
            return
        }

        isSavingDescription = true
        defer { isSavingDescription = false }

        do {
            try await shoppingVM.updateShoppingListDescription(
                companyId: company.id,
                shoppingListItemId: item.id,
                newDescription: description
            )

            item.description = description
            shoppingListItem = item
            masterDataManager.selectedShoppingListItem = item

            alertMessage = "Description saved."
            showAlert = true
        } catch {
            print("[ShoppingListItemDetailView][saveDescription] Error")
            print(error)

            alertMessage = "Failed to save description."
            showAlert = true
        }
    }

    private func deleteItem() {
        Task {
            guard let company = masterDataManager.currentCompany,
                  let item = shoppingListItem else {
                alertMessage = "Missing company or item."
                showAlert = true
                return
            }

            do {
                try await shoppingVM.deleteShoppingListItem(
                    companyId: company.id,
                    shoppingListItemId: item.id
                )

                masterDataManager.selectedShoppingListItem = nil

                if !navigationManager.routes.isEmpty {
                    navigationManager.routes.removeLast()
                }
            } catch {
                print("[ShoppingListItemDetailView][deleteItem] Error")
                print(error)

                alertMessage = "Failed to delete item."
                showAlert = true
            }
        }
    }

    private func loadDataBaseItem(for item: ShoppingListItem) async {
        dataBaseItem = nil

        guard let company = masterDataManager.currentCompany,
              let databaseItemId = databaseItemId(for: item) else {
            return
        }

        dataBaseItem = try? await shoppingVM.dataService.getDataBaseItem(
            companyId: company.id,
            dataBaseItemId: databaseItemId
        )
    }

    private func databaseItemId(for item: ShoppingListItem) -> String? {
        if let dbItemId = item.dbItemId,
           !dbItemId.isEmpty {
            return dbItemId
        }

        if item.subCategory == .dataBase,
           !item.genericItemId.isEmpty {
            return item.genericItemId
        }

        return nil
    }
}

extension ShoppingListItemDetailView {

    private func statusActionButton(
        title: String,
        status: ShoppingListStatus,
        currentItem: ShoppingListItem,
        systemImage: String
    ) -> some View {
        let isSelected = currentItem.status == status

        return Button {
            Task {
                await updateStatus(status)
            }
        } label: {
            VStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? statusTint(currentItem) : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                ? statusTint(currentItem).opacity(0.14)
                : Color.primary.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? statusTint(currentItem).opacity(0.28) : Color.primary.opacity(0.06),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isUpdatingStatus)
    }

    private func sectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func detailRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func moneyTile(
        title: String,
        value: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusBadge(_ item: ShoppingListItem) -> some View {
        Text(item.status.rawValue)
            .font(.caption2.weight(.bold))
            .foregroundStyle(statusTint(item))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(statusTint(item).opacity(0.12), in: Capsule())
    }

    private func categoryBadge(_ item: ShoppingListItem) -> some View {
        smallBadge(
            title: item.category.rawValue,
            systemImage: categoryIcon(item),
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

    private func displayName(_ item: ShoppingListItem) -> String {
        if !item.name.isEmpty {
            return item.name
        }

        if let purchasedItem = item.purchasedItem,
           !purchasedItem.isEmpty {
            return purchasedItem
        }

        return "Shopping Item"
    }

    private func hasPlannedMoney(_ item: ShoppingListItem) -> Bool {
        item.plannedUnitCostCents != nil ||
        item.plannedUnitPriceCents != nil ||
        item.plannedTotalCostCents != nil ||
        item.plannedTotalPriceCents != nil
    }

    private func hasCustomerPrice(_ item: ShoppingListItem) -> Bool {
        customerUnitPriceCents(item) != nil || customerTotalPriceCents(item) != nil
    }

    private func customerUnitPriceCents(_ item: ShoppingListItem) -> Int? {
        if let sellPrice = dataBaseItem?.sellPrice,
           sellPrice > 0 {
            return Int(sellPrice.rounded())
        }

        return item.plannedUnitPriceCents
    }

    private func customerTotalPriceCents(_ item: ShoppingListItem) -> Int? {
        if let sellPrice = dataBaseItem?.sellPrice,
           sellPrice > 0 {
            let quantity = Double(item.quantity ?? "") ?? 1

            return Int((sellPrice * quantity).rounded())
        }

        return item.plannedTotalPriceCents
    }

    private func itemIcon(_ item: ShoppingListItem) -> String {
        switch item.subCategory {
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

    private func categoryIcon(_ item: ShoppingListItem) -> String {
        switch item.category {
        case .personal:
            return "person.crop.circle"

        case .customer:
            return "person.text.rectangle"

        case .job:
            return "briefcase"
        }
    }

    private func statusTint(_ item: ShoppingListItem) -> Color {
        switch item.status {
        case .delivered, .installed, .invoiced:
            return .green

        case .purchased:
            return .blue

        case .needToPurchase:
            return .orange
        }
    }
}

private extension View {
    func shoppingDetailCard(material: Bool = false) -> some View {
        self
            .padding(16)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
    }
}
