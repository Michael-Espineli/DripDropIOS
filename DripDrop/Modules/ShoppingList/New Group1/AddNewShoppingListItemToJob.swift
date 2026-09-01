//
//  AddNewShoppingListItemToJobViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//
//

 import SwiftUI

@MainActor
final class AddNewShoppingListItemToJobViewModel: ObservableObject {
    private var dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var job: Job? = nil
    @Published private(set) var dataBaseItems: [DataBaseItem] = []
    @Published private(set) var dataBaseItemsFiltered: [DataBaseItem] = []

    func onLoad(companyId: String, jobId: String) async throws {
        // Keep this light for now. The draft form currently owns item selection.
        // If needed later:
        // self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
        // self.dataBaseItems = try await dataService.getAllDataBaseItems(companyId: companyId)
    }

    func saveShoppingListItem(
        companyId: String,
        draft: ShoppingListItemDraft,
        purchaserId: String,
        purchaserName: String,
        job: Job
    ) async throws {
        let shoppingListActive = job.activatesShoppingListMaterials
        let item = buildShoppingListItem(
            draft: draft,
            purchaserId: purchaserId,
            purchaserName: purchaserName,
            jobId: job.id,
            customerId: job.customerId,
            customerName: job.customerName,
            serviceLocationId: job.serviceLocationId,
            serviceLocationName: nil,
            shoppingListActive: shoppingListActive
        )

        try await dataService.addNewShoppingListItem(
            companyId: companyId,
            shoppingListItem: item
        )
    }

    func buildShoppingListItem(
        draft: ShoppingListItemDraft,
        purchaserId: String,
        purchaserName: String,
        jobId: String?,
        customerId: String?,
        customerName: String?,
        serviceLocationId: String? = nil,
        serviceLocationName: String? = nil,
        shoppingListActive: Bool = true
    ) -> ShoppingListItem {
        let cleanJobId = jobId ?? ""
        let cleanCustomerId = customerId ?? ""
        let cleanServiceLocationId = serviceLocationId ?? ""

        let prepKeys = ShoppingPrepKeyBuilder.keysForJobMaterial(
            jobId: cleanJobId,
            customerId: cleanCustomerId,
            serviceLocationId: cleanServiceLocationId
        )

        return draft.makeJobShoppingListItem(
            purchaserId: purchaserId,
            purchaserName: purchaserName,
            jobId: jobId,
            customerId: customerId,
            customerName: customerName,
            serviceLocationId: serviceLocationId,
            serviceLocationName: serviceLocationName,
            prepKeys: prepKeys,
            shoppingListActive: shoppingListActive
        )
    }

    func filterDataBaseList(filterTerm: String, items: [DataBaseItem]) {
        var dataBaseItemsFiltered: [DataBaseItem] = []

        for item in items {
            let rateString = String(item.rate)

            if item.sku.lowercased().contains(filterTerm.lowercased()) ||
                item.name.lowercased().contains(filterTerm.lowercased()) ||
                rateString.lowercased().contains(filterTerm.lowercased()) ||
                item.description.lowercased().contains(filterTerm.lowercased()) {
                dataBaseItemsFiltered.append(item)
            }
        }

        self.dataBaseItemsFiltered = dataBaseItemsFiltered
    }
}
extension ShoppingListItemDraft {
    func makeJobShoppingListItem(
        purchaserId: String,
        purchaserName: String,
        jobId: String?,
        customerId: String?,
        customerName: String?,
        serviceLocationId: String?,
        serviceLocationName: String?,
        prepKeys: [String],
        shoppingListActive: Bool = true
    ) -> ShoppingListItem {
        let quantityValue = Double(quantity) ?? 0

        let plannedTotalCostCents: Int? = {
            guard let plannedUnitCostCents else { return nil }
            return Int((Double(plannedUnitCostCents) * quantityValue).rounded())
        }()

        let plannedTotalPriceCents: Int? = {
            guard let plannedUnitPriceCents else { return nil }
            return Int((Double(plannedUnitPriceCents) * quantityValue).rounded())
        }()

        let status: ShoppingListStatus = .needToPurchase
        let productId = selectedProductId
        let vendorItemId = selectedDataBaseItemId

        return ShoppingListItem(
            id: "comp_shop_" + UUID().uuidString,
            category: .job,
            subCategory: subCategory,
            status: status,
            purchaserId: purchaserId,
            purchaserName: purchaserName,
            genericItemId: productId ?? selectedDataBaseItem.linkedProductId,
            productId: productId,
            productName: productId == nil ? nil : selectedProduct.productDisplayName,
            name: displayName,
            description: description,
            datePurchased: nil,
            quantity: quantity,

            jobId: jobId,

            customerId: customerId ?? "",
            customerName: customerName ?? "",

            userId: nil,
            userName: nil,

            serviceStopId: nil,
            serviceStopInternalId: nil,
            serviceLocationId: serviceLocationId,
            serviceLocationName: serviceLocationName,
            scheduledDate: nil,

            prepKeys: prepKeys,
            needsAction: shoppingListActive && status.needsShoppingAction,
            shoppingListActive: shoppingListActive,
            actionDate: shoppingListActive ? Date() : nil,
            assignedTechIds: [],

            dbItemId: subCategory == .dataBase ? vendorItemId : nil,
            dbItemName: subCategory == .dataBase ? selectedDataBaseItem.name : nil,
            itemId: productId ?? (subCategory == .dataBase ? vendorItemId : nil),
            itemType: subCategory.rawValue,
            purchasedItem: nil,
            invoiced: false,

            plannedUnitCostCents: plannedUnitCostCents,
            plannedUnitPriceCents: plannedUnitPriceCents,
            plannedTotalCostCents: plannedTotalCostCents,
            plannedTotalPriceCents: plannedTotalPriceCents
        )
    }
}
struct AddNewShoppingListItemToJob: View {

    init(dataService: any ProductionDataServiceProtocol, job: Job) {
        _VM = StateObject(wrappedValue: AddNewShoppingListItemToJobViewModel(dataService: dataService))
        _job = State(wrappedValue: job)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: AddNewShoppingListItemToJobViewModel

    @State var job: Job
    @State private var draft: ShoppingListItemDraft = ShoppingListItemDraft()

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    headerCard

                    ShoppingListItemDraftForm(
                        draft: $draft,
                        title: "Item Details",
                        showCategoryPicker: false,
                        showDescription: true
                    )
                    .ddCard()

                    Color.clear.frame(height: 88)
                }
                .padding(12)
            }
        }
        .navigationTitle("Add Item To Job")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: company.id, jobId: job.id)
                } catch {
                    print("Error - [AddNewShoppingListItemToJob]")
                    print(error)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            submitButton
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Item To Job")
                    .font(.title3.weight(.semibold))

                Text(job.internalId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(fullDate(date: Date()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Capsule().fill(Color.primary.opacity(0.08)))
        }
        .ddCard()
    }

    private var submitButton: some View {
        HStack {
            Button {
                Task {
                    await submit()
                }
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .modifier(SubmitButtonModifier())
            }
            .disabled(!draft.canSubmit)
            .opacity(draft.canSubmit ? 1.0 : 0.55)
        }
        .ddBottomBar()
    }

    private func submit() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            return
        }

        do {
            let purchaserName = "\(user.firstName) \(user.lastName)"
                .trimmingCharacters(in: .whitespacesAndNewlines)

            try await VM.saveShoppingListItem(
                companyId: company.id,
                draft: draft,
                purchaserId: user.id,
                purchaserName: purchaserName,
                job: job
            )

            print("Successfully Added")
            dismiss()
        } catch {
            print("Error Uploading New shopping List Item")
            print(error)
        }
    }
}

private extension View {
    func ddCard() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
    }

    func ddBottomBar() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color.black.opacity(0.02)
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .overlay(Divider().opacity(0.12), alignment: .top)
    }
}
