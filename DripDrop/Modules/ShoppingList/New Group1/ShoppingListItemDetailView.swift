//
//  ShoppingListItemDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI
import FirebaseFirestore

struct ShoppingListItemDetailView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @Environment(\.dismiss) private var dismiss

    @StateObject var shoppingVM: ShoppingListViewModel

    init(
        item: ShoppingListItem,
        dataService: any ProductionDataServiceProtocol
    ) {
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _receivedItem = State(wrappedValue: item)
    }

    @State private var receivedItem: ShoppingListItem? = nil
    @State private var shoppingListItem: ShoppingListItem? = nil
    @State private var dataBaseItem: DataBaseItem? = nil
    @State private var productItem: GenericItem? = nil

    @State private var description: String = ""
    @State private var isSavingDescription: Bool = false
    @State private var showStatusSheet: Bool = false

    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if let item = shoppingListItem {
                        headerCard(item)
                        statusCard(item)
                        detailCard(item)
                        moneyCard(item)
                        if let companyId = masterDataManager.currentCompany?.id {
                            PartInvoiceStatusCard(companyId: companyId, collection: "shoppingList", recordId: item.id)
                        }
                        descriptionCard
                        dangerZone
                    } else {
                        emptyState
                    }

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Shopping Item")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStatusSheet) {
            if let item = shoppingListItem {
                ShoppingListItemStatusSheet(item: item, shoppingVM: shoppingVM)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: itemIcon(item))
                .font(.body.weight(.semibold))
                .foregroundStyle(statusTint(item))
                .frame(width: 40, height: 40)
                .background(statusTint(item).opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName(item))
                    .font(.headline)
                    .lineLimit(2)

                Text("\(item.subCategory.rawValue) • Qty: \(item.quantity ?? "-")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                categoryBadge(item)
            }
            Spacer(minLength: 0)
        }
        .shoppingDetailCard(material: true)
    }

    private func statusCard(_ item: ShoppingListItem) -> some View {
        Button {
            showStatusSheet = true
        } label: {
            HStack(spacing: 10) {
                Label(item.status.rawValue, systemImage: item.status.shoppingSystemImage)
                    .foregroundStyle(statusTint(item))
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Text("Change")
                    .font(.caption.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .shoppingDetailCard()
    }

    @ViewBuilder
    private func detailCard(_ item: ShoppingListItem) -> some View {
        let rows = detailRows(item)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(title: "Details", systemImage: "info.circle")

                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    detailRow(title: row.title, value: row.value, systemImage: row.systemImage)
                }
            }
            .shoppingDetailCard()
        }
    }

    private func detailRows(_ item: ShoppingListItem) -> [(title: String, value: String, systemImage: String)] {
        var rows: [(title: String, value: String, systemImage: String)] = []
        let context: [(String, String?, String)] = [
            ("Customer", item.customerName, "person.text.rectangle"),
            ("Job", item.jobId, "briefcase"),
            ("Assigned to", item.userName, "person.crop.circle"),
            ("Purchaser", item.purchaserName == item.userName ? nil : item.purchaserName, "person"),
            ("Location", item.serviceLocationName, "mappin.and.ellipse"),
            ("Stop", item.serviceStopInternalId, "calendar.badge.clock")
        ]
        for (title, value, systemImage) in context {
            if let value, !value.isEmpty {
                rows.append((title, value, systemImage))
            }
        }
        if let datePurchased = item.datePurchased {
            rows.append(("Purchased", fullDate(date: datePurchased), "calendar"))
        }
        return rows
    }

    @ViewBuilder
    private func moneyCard(_ item: ShoppingListItem) -> some View {
        if hasPlannedMoney(item) || hasCustomerPrice(item) || productItemId(for: item) != nil || databaseItemId(for: item) != nil {
            VStack(alignment: .leading, spacing: 10) {
                sectionHeader(
                    title: "Customer Price",
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
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                title: "Description",
                systemImage: "note.text"
            )

            TextField(
                "Description",
                text: $description,
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(.subheadline)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if description != shoppingListItem?.description {
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
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
                .disabled(isSavingDescription)
            }
        }
        .shoppingDetailCard()
    }

    private var dangerZone: some View {
        Button(role: .destructive) {
            alertMessage = "This will permanently delete this shopping list item."
            showDeleteConfirmation = true
        } label: {
            Label("Delete Item", systemImage: "trash")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .rose))
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

                if UIDevice.isIPhone {
                    dismiss()
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
        productItem = nil

        guard let company = masterDataManager.currentCompany else {
            return
        }

        if let productItemId = productItemId(for: item) {
            productItem = try? await shoppingVM.dataService.getDataBaseItem(
                companyId: company.id,
                genericItemId: productItemId
            )
            return
        }

        guard let databaseItemId = databaseItemId(for: item) else {
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

    private func productItemId(for item: ShoppingListItem) -> String? {
        if let productId = item.productId,
           !productId.isEmpty {
            return productId
        }

        if item.subCategory == .product,
           !item.genericItemId.isEmpty {
            return item.genericItemId
        }

        if item.itemType == ShoppingListSubCategory.product.rawValue,
           let itemId = item.itemId,
           !itemId.isEmpty {
            return itemId
        }

        return nil
    }
}

extension ShoppingListItemDetailView {

    private func sectionHeader(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func detailRow(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Spacer(minLength: 12)
                Text(value)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 3) {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
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

        if let productName = item.productName,
           !productName.isEmpty {
            return productName
        }

        if let dbItemName = item.dbItemName,
           !dbItemName.isEmpty {
            return dbItemName
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
        if let productItem {
            let sellPrice = productItem.productSellPriceCents
            if sellPrice > 0 {
                return sellPrice
            }
        }

        if let sellPrice = dataBaseItem?.sellPrice,
           sellPrice > 0 {
            return Int(sellPrice.rounded())
        }

        return item.plannedUnitPriceCents
    }

    private func customerTotalPriceCents(_ item: ShoppingListItem) -> Int? {
        let quantity = Double(item.quantity ?? "") ?? 1

        if let productItem {
            let sellPrice = productItem.productSellPriceCents
            if sellPrice > 0 {
                return Int((Double(sellPrice) * quantity).rounded())
            }
        }

        if let sellPrice = dataBaseItem?.sellPrice,
           sellPrice > 0 {
            return Int((sellPrice * quantity).rounded())
        }

        return item.plannedTotalPriceCents
    }

    private func itemIcon(_ item: ShoppingListItem) -> String {
        switch item.subCategory {
        case .product:
            return "shippingbox.fill"

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
        item.status.shoppingTint
    }
}

private extension View {
    func shoppingDetailCard(material: Bool = false) -> some View {
        self
            .padding(12)
            .background(
                material ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
    }
}

// Reads live invoice links without coupling the shopping/purchase Codable models to billing.
struct PartInvoiceStatusCard: View {
    let companyId: String
    let collection: String
    let recordId: String
    @State private var invoiceId = ""
    @State private var status = ""
    @State private var workflow = ""
    @State private var message = ""
    @State private var observedPath = ""
    @State private var listener: ListenerRegistration?
    private var path: String { "companies/\(companyId)/\(collection)/\(recordId)" }
    private var invoiceURL: URL? {
        let base = AppEnvironment.current == .dev ? "https://the-pool-app-dev.web.app" : "https://dripdrop-poolapp.com"
        return URL(string: base)?.appendingPathComponent("company/sales/invoices").appendingPathComponent(invoiceId)
    }
    var body: some View {
        Group {
            if !invoiceId.isEmpty || !workflow.isEmpty || !message.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Invoice", systemImage: "doc.text").font(.headline)
                    Text(workflow == "awaitingNextBill" ? "Queued for the next recurring service bill." : workflow == "nextBillAttached" ? "Included on the recurring service invoice." : workflow == "awaitingDelivery" ? "Invoice will be created after delivery or installation." : "Status: \(status.isEmpty ? workflow : status)")
                        .font(.subheadline)
                    if !message.isEmpty { Text(message).font(.caption).foregroundStyle(.orange) }
                    if !invoiceId.isEmpty, let invoiceURL {
                        Link("Open Invoice in Sales", destination: invoiceURL)
                            .buttonStyle(WorkspaceOutlinedButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .task(id: path) {
            listener?.remove()
            let requestedPath = path
            observedPath = requestedPath
            invoiceId = ""; status = ""; workflow = ""; message = ""
            listener = Firestore.firestore().document(requestedPath).addSnapshotListener { snapshot, error in
                Task { @MainActor in
                    guard observedPath == requestedPath else { return }
                    if let error { message = error.userFacingMessage; return }
                    let data = snapshot?.data() ?? [:]
                    invoiceId = data["salesInvoiceId"] as? String ?? data["invoiceId"] as? String ?? ""
                    status = data["invoiceStatus"] as? String ?? ""
                    workflow = data["billingAutomationStatus"] as? String ?? ""
                    message = data["billingAutomationError"] as? String ?? ""
                }
            }
        }
        .onDisappear { observedPath = ""; listener?.remove(); listener = nil }
    }
}
