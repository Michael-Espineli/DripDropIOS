//
//  ShoppingListItemStatusPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/27/25.
//

import SwiftUI

struct ShoppingListItemStatusPicker: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    
    init(dataService:any ProductionDataServiceProtocol,status:Binding<ShoppingListStatus>){
        self._status = status
    }
    @Binding var status : ShoppingListStatus
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ForEach(ShoppingListStatus.allCases){ datum in
                    Button(action: {
                        status = datum
                        dismiss()
                    }, label: {
                        HStack{
                            Spacer()
                                Text("\(datum.rawValue)")
                            Spacer()
                        }
                        .padding(.horizontal,8)
                        .foregroundColor(Color.basicFontText)
                    })
                    Divider()
                }
            }
        }
    }
}

struct ShoppingListItemStatusSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let item: ShoppingListItem
    @ObservedObject var shoppingVM: ShoppingListViewModel

    @State private var savingStatus: ShoppingListStatus?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name.isEmpty ? (item.productName ?? item.dbItemName ?? "Shopping Item") : item.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)

                    VStack(spacing: 0) {
                        ForEach(ShoppingListStatus.prepStatuses) { status in
                            Button {
                                Task {
                                    await saveStatus(status)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: status.shoppingSystemImage)
                                        .foregroundStyle(status.shoppingTint)
                                        .frame(width: 24)

                                    Text(status.shoppingTitle)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if savingStatus == status {
                                        ProgressView()
                                    } else if item.status == status {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(status.shoppingTint)
                                    }
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 48)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(savingStatus != nil || item.status == status)
                            .accessibilityValue(item.status == status ? "Current status" : "")

                            if status != ShoppingListStatus.prepStatuses.last {
                                Divider().padding(.leading, 48)
                            }
                        }
                    }
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(16)
            }
            .background(Color.listColor)
            .navigationTitle("Change Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(savingStatus != nil)
                }
            }
            .interactiveDismissDisabled(savingStatus != nil)
        }
    }

    @MainActor
    private func saveStatus(_ status: ShoppingListStatus) async {
        guard savingStatus == nil, item.status != status else { return }
        guard let companyId = masterDataManager.currentCompany?.id else {
            errorMessage = "Select a company to change this status."
            return
        }

        savingStatus = status
        errorMessage = nil
        defer { savingStatus = nil }

        do {
            try await shoppingVM.updateShoppingListStatus(
                companyId: companyId,
                shoppingListItemId: item.id,
                status: status
            )

            var updatedItem = item
            updatedItem.status = status
            updatedItem.needsAction = status.needsShoppingAction
            updatedItem.actionDate = Date()
            if status == .purchased {
                updatedItem.datePurchased = updatedItem.actionDate
            }
            masterDataManager.selectedShoppingListItem = updatedItem
            dismiss()
        } catch {
            errorMessage = error.userFacingMessage
        }
    }
}

extension ShoppingListStatus {
    static var prepStatuses: [ShoppingListStatus] {
        [.needToPurchase, .purchased, .delivered, .installed]
    }

    var shoppingTitle: String {
        self == .needToPurchase ? "Need" : rawValue
    }

    var shoppingSystemImage: String {
        switch self {
        case .needToPurchase: return "cart.badge.plus"
        case .purchased: return "cart.fill"
        case .delivered: return "shippingbox"
        case .installed: return "checkmark.seal"
        case .invoiced: return "doc.text"
        }
    }

    var shoppingTint: Color {
        switch self {
        case .needToPurchase: return .orange
        case .purchased: return .blue
        case .delivered, .installed, .invoiced: return .green
        }
    }
}
