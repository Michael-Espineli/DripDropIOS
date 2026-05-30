//
//  AddJobTemplateMaterialSheet.swift
//  DripDrop
//

import SwiftUI

struct AddJobTemplateMaterialSheet: View {
    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let templateId: String
    let existingItems: [JobTemplateShoppingItem]
    let dataService: any ProductionDataServiceProtocol
    let onSaved: () -> Void

    @State private var draft: ShoppingListItemDraft = ShoppingListItemDraft()
    @State private var billable: Bool = true

    @State private var plannedUnitCostCents: Int = 0
    @State private var plannedUnitPriceCents: Int = 0

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var nextSortOrder: Int {
        (existingItems.map { $0.sortOrder }.max() ?? -1) + 1
    }

    private var quantityValue: Double {
        Double(draft.quantity) ?? 0
    }

    private var plannedTotalCostCents: Int {
        Int((Double(plannedUnitCostCents) * quantityValue).rounded())
    }

    private var plannedTotalPriceCents: Int {
        guard billable else { return 0 }
        return Int((Double(plannedUnitPriceCents) * quantityValue).rounded())
    }

    private var canSave: Bool {
        draft.canSubmit && quantityValue > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard

                        ShoppingListItemDraftForm(
                            draft: $draft,
                            title: "Material Details",
                            showCategoryPicker: false,
                            showDescription: true
                        )
                        .jobTemplateMaterialSheetCard()
                        .onChange(of: draft.selectedDataBaseItem) { item in
                            applyDatabaseItemSnapshot(item)
                        }

                        pricingCard
                        snapshotCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .alert("Template Material", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .onAppear {
            draft.category = .job
            draft.quantity = draft.quantity.isEmpty ? "1" : draft.quantity
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Add Template Material")
                        .font(.title3.weight(.semibold))

                    Text("Create reusable planned material for this job template.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "cart.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("Template materials become planned job shopping items when a new job is created from this template.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .jobTemplateMaterialSheetCard()
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Planned Pricing",
                systemImage: "dollarsign.circle"
            )

            Toggle("Billable To Customer", isOn: $billable)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Unit Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $plannedUnitCostCents)

                Text("Your expected cost per unit.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if billable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit Billable Price")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    MoneyTextField(cents: $plannedUnitPriceCents)

                    Text("What you expect to charge the customer per unit.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .jobTemplateMaterialSheetCard()
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JobTemplateSectionHeader(
                title: "Material Snapshot",
                systemImage: "sum"
            )

            JobTemplateDetailSummaryRow(
                title: "Quantity",
                value: draft.quantity.isEmpty ? "-" : draft.quantity
            )

            JobTemplateDetailMoneyRow(
                title: "Total Cost",
                cents: plannedTotalCostCents
            )

            if billable {
                JobTemplateDetailMoneyRow(
                    title: "Total Billable",
                    cents: plannedTotalPriceCents
                )
            }

            Text("These values are saved as a planning snapshot. If database item pricing changes later, this template keeps the expected values unless you update it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .jobTemplateMaterialSheetCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await save()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Label("Save Material", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button {
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private func save() async {
        guard canSave else {
            alertMessage = "Please select or name a material and enter a valid quantity."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let item = JobTemplateShoppingItem(
                companyId: companyId,
                templateId: templateId,
                subCategory: draft.subCategory,
                name: draft.displayName,
                description: draft.description,
                quantity: draft.quantity,
                dbItemId: draft.selectedDataBaseItemId,
                genericItemId: "",
                plannedUnitCostCents: plannedUnitCostCents,
                plannedUnitPriceCents: billable ? plannedUnitPriceCents : nil,
                plannedTotalCostCents: plannedTotalCostCents,
                plannedTotalPriceCents: billable ? plannedTotalPriceCents : nil,
                billable: billable,
                sortOrder: nextSortOrder
            )

            try await dataService.saveJobTemplateShoppingItems([item])

            onSaved()
            dismiss()
        } catch {
            alertMessage = "Could not save material. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func applyDatabaseItemSnapshot(_ item: DataBaseItem) {
        guard !item.id.isEmpty else { return }

        if plannedUnitCostCents == 0 {
            plannedUnitCostCents = Int(item.rate)
        }

        if plannedUnitPriceCents == 0,
           let sellPrice = item.sellPrice {
            plannedUnitPriceCents = Int(sellPrice)
        }

        if draft.name.isEmpty {
            draft.name = item.name
        }
    }
}

private extension View {
    func jobTemplateMaterialSheetCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}