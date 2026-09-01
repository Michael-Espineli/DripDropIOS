//
//  EditShoppingListItem.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/2/26.
//

import SwiftUI

@MainActor
final class EditShoppingListItemViewModel: ObservableObject {
    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    // Data for lookup and filtering (parity with AddNewShoppingListItemToJob)
    @Published private(set) var dataBaseItems: [DataBaseItem] = []
    @Published private(set) var dataBaseItemsFiltered: [DataBaseItem] = []

    // Load any resources needed for editing (e.g., database items)
    func onLoad(companyId: String) async {
        do {
            // If you have a DB fetch, uncomment and adjust:
            // self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItems(companyId: companyId)
        } catch {
            print("EditShoppingListItemViewModel.onLoad error: \(error)")
        }
    }

    // Update the shopping list item with validation (mirroring the add flow structure)
    func updateShoppingListItem(
        companyId: String,
        original: ShoppingListItem,
        datePurchased: Date?,
        category: ShoppingListCategory,
        subCategory: ShoppingListSubCategory,
        purchaserId: String,
        itemId: String?,
        quantity: String?,
        description: String,
        jobId: String?,
        customerId: String?,
        customerName: String?,
        purchaserName: String?,
        name: String
    ) async throws {
        let cleanItemId = itemId ?? ""
        let productId = subCategory == .product ? cleanItemId : ""
        let vendorItemId = subCategory == .dataBase ? cleanItemId : ""
        let genericItemId: String

        if subCategory == .product {
            genericItemId = productId.isEmpty ? original.genericItemId : productId
        } else if subCategory == .dataBase {
            genericItemId = original.genericItemId
        } else {
            genericItemId = ""
        }

        // Build updated item by preserving original id and status, updating fields as needed
        let updated = ShoppingListItem(
            id: original.id,
            category: category,
            subCategory: subCategory,
            status: original.status, // preserve current status
            purchaserId: purchaserId,
            purchaserName: purchaserName ?? original.purchaserName,
            genericItemId: genericItemId,
            productId: productId.isEmpty ? nil : productId,
            productName: productId.isEmpty ? nil : name,
            name: name,
            description: description,
            datePurchased: datePurchased,
            quantity: quantity,
            jobId: jobId,
            customerId: customerId ?? original.customerId,
            customerName: customerName ?? original.customerName,
            dbItemId: vendorItemId.isEmpty ? nil : vendorItemId,
            dbItemName: vendorItemId.isEmpty ? nil : name,
            itemId: cleanItemId.isEmpty ? nil : cleanItemId,
            itemType: subCategory.rawValue,
            invoiced: true
        )

        // Assuming your dataService has an update method like this; adjust if needed
//        try await dataService.updateShoppingListItem(companyId: companyId, shoppingListItem: updated)
    }

    func filterDataBaseList(filterTerm: String, items: [DataBaseItem]) {
        var filtered: [DataBaseItem] = []
        for item in items {
            let rateString = String(item.rate)
            if item.sku.lowercased().contains(filterTerm.lowercased())
                || item.name.lowercased().contains(filterTerm.lowercased())
                || rateString.lowercased().contains(filterTerm.lowercased())
                || item.description.lowercased().contains(filterTerm.lowercased()) {
                filtered.append(item)
            }
        }
        self.dataBaseItemsFiltered = filtered
    }
}

struct EditShoppingListItem: View {
    init(dataService: any ProductionDataServiceProtocol, item: ShoppingListItem) {
        _VM = StateObject(wrappedValue: EditShoppingListItemViewModel(dataService: dataService))
        _item = State(wrappedValue: item)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EditShoppingListItemViewModel

    // The item being edited
    @State var item: ShoppingListItem

    // Editable fields (aligned with Add flow)
    @State private var descriptionText: String = ""
    @State private var type: ShoppingListCategory = .job
    @State private var itemType: ShoppingListSubCategory = .dataBase
    @State private var quantity: String = "1"

    @State private var name: String = ""
    @State private var dataBaseItem: DataBaseItem = DataBaseItem(
        id: "", name: "", rate: 0, storeName: "", venderId: "",
        category: .chems, subCategory: .bushing, description: "",
        dateUpdated: Date(), sku: "", billable: false, color: "", size: "", UOM: .ft
    )
    @State private var productItem: GenericItem = .emptyProductCatalogItem

    // Search state (parity with Add flow)
    @State private var search: String = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            VStack {
                ScrollView {
                    form
                    Rectangle()
                        .frame(height: 1)
                    submitButton
                }
            }
        }
        .padding(8)
        .navigationTitle("Edit Item")
        .toolbar {
            ToolbarItem {
                submitButton
            }
        }
        .task {
            // Seed current values from the incoming item
            seedFromItem()
            if let company = masterDataManager.currentCompany {
                await VM.onLoad(companyId: company.id)
            }
        }
        .onChange(of: dataBaseItem) { dbItem in
            if dbItem.id != "" {
                name = dbItem.name
            }
        }
        .onChange(of: productItem) { product in
            if product.id != "" {
                name = product.productDisplayName
            }
        }
        .onChange(of: search) { term in
            if term != "" {
                VM.filterDataBaseList(filterTerm: term, items: VM.dataBaseItems)
                if VM.dataBaseItemsFiltered.count != 0 {
                    dataBaseItem = VM.dataBaseItemsFiltered.first!
                }
            }
        }
    }

    private func seedFromItem() {
        // Map existing item fields into local state for editing
        self.descriptionText = item.description
        self.type = item.category
        self.itemType = item.subCategory
        self.quantity = item.quantity ?? "1"
        self.name = item.name

        if item.subCategory == .product {
            let productId = item.productId ?? (item.genericItemId.isEmpty ? "" : item.genericItemId)
            if !productId.isEmpty {
                var existingProduct = GenericItem.emptyProductCatalogItem
                existingProduct.id = productId
                existingProduct.name = item.productName ?? item.name
                existingProduct.commonName = item.productName ?? item.name
                existingProduct.description = item.description
                existingProduct.rate = Double(item.plannedUnitCostCents ?? 0)
                existingProduct.sellPrice = Double(item.plannedUnitPriceCents ?? 0)
                productItem = existingProduct
            }
        }

        if item.subCategory == .dataBase,
           let dbItemId = item.dbItemId,
           !dbItemId.isEmpty {
            dataBaseItem.id = dbItemId
            dataBaseItem.name = item.dbItemName ?? item.name
        }
    }

    private var form: some View {
        VStack {
            HStack {
                Text(fullDate(date: item.datePurchased ?? Date()))
                Spacer()
                if let internalId = item.jobId {
                    Text(internalId)
                }
            }
            // Reuse the same component the Add flow uses for consistency
            CreateShoppingListItemView(
                itemType: $itemType,
                name: $name,
                quantity: $quantity,
                addNewItem: .constant(false),
                dataBaseItem: $dataBaseItem,
                productItem: $productItem
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .bold(true)
                TextField(
                    "Description",
                    text: $descriptionText,
                    axis: .vertical
                )
                .lineLimit(3, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(.top, 8)
        }
    }

    private var submitButton: some View {
        Button(action: {
            Task {
                guard let company = masterDataManager.currentCompany,
                      let user = masterDataManager.user
                else { return }
                do {
                    let purchaserName = (user.firstName) + " " + (user.lastName)
                    try await VM.updateShoppingListItem(
                        companyId: company.id,
                        original: item,
                        datePurchased: item.datePurchased, // keep existing unless you want to allow editing
                        category: type,
                        subCategory: itemType,
                        purchaserId: user.id,
                        itemId: selectedItemId,
                        quantity: quantity,
                        description: descriptionText,
                        jobId: item.jobId,
                        customerId: item.customerId,
                        customerName: item.customerName,
                        purchaserName: purchaserName,
                        name: selectedItemName
                    )
                    dismiss()
                } catch {
                    print("Error updating shopping list item: \(error)")
                }
            }
        }, label: {
            Text("Save")
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())
        })
        .padding(.horizontal, 8)
    }

    private var selectedItemId: String? {
        switch itemType {
        case .product:
            if !productItem.id.isEmpty {
                return productItem.id
            }

            return item.productId ?? (item.genericItemId.isEmpty ? nil : item.genericItemId)

        case .dataBase:
            if !dataBaseItem.id.isEmpty {
                return dataBaseItem.id
            }

            return item.dbItemId

        case .chemical, .part, .custom:
            return nil
        }
    }

    private var selectedItemName: String {
        switch itemType {
        case .product:
            if !productItem.id.isEmpty {
                return productItem.productDisplayName
            }

            return item.productName ?? name

        case .dataBase:
            if !dataBaseItem.id.isEmpty {
                return dataBaseItem.name
            }

            return item.dbItemName ?? name

        case .chemical, .part, .custom:
            return name
        }
    }
}

//#Preview {
//    // Provide a lightweight preview item
//    let item = ShoppingListItem(
//        id: "preview",
//        category: .job,
//        subCategory: .dataBase,
//        status: .needToPurchase,
//        purchaserId: "u1",
//        purchaserName: "Preview User",
//        genericItemId: "",
//        name: "Chlorine",
//        description: "Pool chlorine tablets",
//        datePurchased: Date(),
//        quantiy: "2",
//        jobId: "JOB-123",
//        customerId: "CUST-1",
//        customerName: "Preview Customer",
//        dbItemId: nil
//    )
//    return EditShoppingListItem(dataService: ProductionDataService(), item: item)
//        .environmentObject(ProductionDataService())
//        .environmentObject(MasterDataManager())
//}
