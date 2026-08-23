//
//  CreateBlankJobTemplateSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import SwiftUI

struct CreateBlankJobTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let dataService: any ProductionDataServiceProtocol

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var defaultIssuePriority: JobIssuePriorityLevel = .defaultLevel
    @State private var defaultRateCents: Int = 0
    @State private var defaultLaborCostCents: Int = 0
    @State private var locked: Bool = false

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        pricingCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("New Template")
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
            .alert("Create Template", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Create Blank Template")
                        .font(.title3.weight(.semibold))

                    Text("Start a reusable job plan.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "doc.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("This creates the template shell. You can add planned stops, tasks, and materials from the detail page next.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateSettingsCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Template Details", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Template Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: Filter Install", text: $name)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Job Priority")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Default Job Priority", selection: $defaultIssuePriority) {
                    ForEach(JobIssuePriorityLevel.allCases) { priority in
                        Text(priority.displayName)
                            .tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Optional template notes...",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(4, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle("Locked Template", isOn: $locked)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateSettingsCard()
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Default Pricing", systemImage: "dollarsign.circle")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Customer Price")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $defaultRateCents)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Labor Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $defaultLaborCostCents)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateSettingsCard()
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
                    Label("Create Template", systemImage: "checkmark.circle")
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
            alertMessage = "Please enter a template name."
            showAlert = true
            return
        }

        guard let userId = masterDataManager.user?.id else {
            alertMessage = "Missing user."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            var template = JobTemplate(
                companyId: companyId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description,
                defaultRateCents: defaultRateCents,
                defaultLaborCostCents: defaultLaborCostCents,
                isActive: true,
                locked: locked,
                createdByUserId: userId
            )
            template.setDefaultIssuePriority(defaultIssuePriority)

            try await dataService.saveJobTemplate(template)

            dismiss()
        } catch {
            alertMessage = "Could not create template. \(error.localizedDescription)"
            showAlert = true
        }
    }
}






private extension View {
    func jobTemplateSettingsCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
