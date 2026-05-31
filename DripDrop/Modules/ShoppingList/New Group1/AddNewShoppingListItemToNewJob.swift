//
//  AddNewShoppingListItemToNewJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//

import SwiftUI

struct AddNewShoppingListItemToNewJob: View {

    init(
        dataService: any ProductionDataServiceProtocol,
        jobId: String,
        customerId: String,
        customerName: String,
        serviceLocationId: String? = nil,
        serviceLocationName: String? = nil,
        shoppingList: Binding<[ShoppingListItem]>
    ) {
        _VM = StateObject(wrappedValue: AddNewShoppingListItemToJobViewModel(dataService: dataService))
        _jobId = State(wrappedValue: jobId)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _serviceLocationName = State(wrappedValue: serviceLocationName)
        self._shoppingList = shoppingList
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: AddNewShoppingListItemToJobViewModel

    @State var jobId: String
    @Binding var shoppingList: [ShoppingListItem]

    @State var customerId: String
    @State var customerName: String
    @State var serviceLocationId: String?
    @State var serviceLocationName: String?

    @State private var draft: ShoppingListItemDraft = ShoppingListItemDraft()
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false

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

                    routePrepInfoCard

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
                    try await VM.onLoad(companyId: company.id, jobId: jobId)
                } catch {
                    print("Error - [AddNewShoppingListItemToNewJob]")
                    print(error)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            submitButton
        }
        .alert("Shopping Item", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Item To Job")
                    .font(.title3.weight(.semibold))

                Text(customerName.isEmpty ? "New Job" : customerName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let serviceLocationName, !serviceLocationName.isEmpty {
                    Text(serviceLocationName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
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

    private var routePrepInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Route Prep Ready", systemImage: "map")
                .font(.subheadline.weight(.semibold))

            Text(routePrepDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ddCard()
    }

    private var routePrepDescription: String {
        if let serviceLocationId, !serviceLocationId.isEmpty {
            return "This material will be connected to the job, customer, and service location for route prep."
        }

        return "This material will be connected to the job and customer. Add service location context later for more accurate route prep."
    }

    private var submitButton: some View {
        HStack {
            Button {
                submit()
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

    private func submit() {
        guard let user = masterDataManager.user else {
            alertMessage = "Missing user."
            showAlert = true
            return
        }

        let purchaserName = "\(user.firstName) \(user.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let item = VM.buildShoppingListItem(
            draft: draft,
            purchaserId: user.id,
            purchaserName: purchaserName,
            jobId: jobId,
            customerId: customerId,
            customerName: customerName,
            serviceLocationId: serviceLocationId,
            serviceLocationName: serviceLocationName
        )

        shoppingList.append(item)
        print("Successfully Added")
        dismiss()
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
