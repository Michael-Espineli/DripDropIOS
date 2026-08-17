//
//  AddJobTemplatePlannedStopSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/24/26.
//


import SwiftUI

struct AddJobTemplatePlannedStopSheet: View {
    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let templateId: String
    let existingPlannedStops: [JobTemplatePlannedServiceStop]
    let templateTasks: [JobTemplateTask]
    let dataService: any ProductionDataServiceProtocol
    let onSaved: () -> Void

    @State private var name: String = ""
    @State private var description: String = ""

    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit

    @State private var estimatedMinutes: Int = 60
    @State private var plannedLaborCostCents: Int = 0
    @State private var plannedLaborNotes: String = ""

    @State private var selectedTaskTemplateIds: Set<String> = []

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var nextSortOrder: Int {
        (existingPlannedStops.map { $0.sortOrder }.max() ?? -1) + 1
    }

    private var resolvedName: String {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleanedName.isEmpty {
            return cleanedName
        }

        if let selectedCompanyServiceStopType {
            return selectedCompanyServiceStopType.name
        }

        return serviceStopTypeUseCase.fallbackName
    }

    private var canSave: Bool {
        !resolvedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        estimatedMinutes > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        serviceStopTypeCard
                        detailsCard
                        linkedTasksCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Add Planned Stop")
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
            .alert("Template Planned Stop", isPresented: $showAlert) {
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
                    Text("Add Planned Stop")
                        .font(.title3.weight(.semibold))

                    Text("Create an expected visit for this job template.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "calendar.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("Planned stops become planned job visits when a new job is created from this template. They do not create real service stops until the job is scheduled.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .jobTemplatePlannedStopSheetCard()
    }

    private var serviceStopTypeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Pay Type",
                systemImage: "flag"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Use Case")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Use Case", selection: $serviceStopTypeUseCase) {
                    ForEach(ServiceStopTypeUseCase.allCases, id: \.self) { useCase in
                        Text(useCase.fallbackName).tag(useCase)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase,
                title: "Company Pay Type",
                subtitle: "Choose the planned visit type for this template."
            )

            Text("The selected pay type helps carry over planned labor and pay expectations when creating jobs from this template.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplatePlannedStopSheetCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Details & Planned Labor",
                systemImage: "doc.text"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: Install Visit", text: $name)
                    .modifier(PlainTextFieldModifier())

                Text("Leave blank to use the selected pay type name.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Minutes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Stepper("\(estimatedMinutes) min", value: $estimatedMinutes, in: 5...720, step: 5)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Planned Labor Cost")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $plannedLaborCostCents)

                Text("This is the expected cost for this planned visit before the work is actually scheduled.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Labor Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Example: Estimated route visit + startup labor",
                    text: $plannedLaborNotes,
                    axis: .vertical
                )
                .lineLimit(2, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Optional notes about this planned visit...",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(3, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplatePlannedStopSheetCard()
    }

    private var linkedTasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                JobTemplateSectionHeader(
                    title: "Linked Template Tasks",
                    systemImage: "checklist"
                )

                Spacer()

                Text("\(selectedTaskTemplateIds.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if templateTasks.isEmpty {
                ContentUnavailableView(
                    "No Template Tasks",
                    systemImage: "checklist.unchecked",
                    description: Text("Add template tasks first, then link them to planned stops.")
                )
                .padding(.vertical, 10)
            } else {
                Button {
                    if selectedTaskTemplateIds.count == templateTasks.count {
                        selectedTaskTemplateIds.removeAll()
                    } else {
                        selectedTaskTemplateIds = Set(templateTasks.map { $0.id })
                    }
                } label: {
                    Text(selectedTaskTemplateIds.count == templateTasks.count ? "Deselect All" : "Select All")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)

                VStack(spacing: 8) {
                    ForEach(templateTasks.sorted(by: { $0.sortOrder < $1.sortOrder })) { task in
                        linkedTaskToggleRow(task)
                    }
                }
            }

            Text("Linked tasks help organize what work belongs to this planned visit when the template creates a real job.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplatePlannedStopSheetCard()
    }

    private func linkedTaskToggleRow(_ task: JobTemplateTask) -> some View {
        let isSelected = selectedTaskTemplateIds.contains(task.id)

        return Button {
            if isSelected {
                selectedTaskTemplateIds.remove(task.id)
            } else {
                selectedTaskTemplateIds.insert(task.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .accent : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("\(task.type.rawValue) • \(task.estimatedTime) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if task.contractedRate > 0 {
                        Text("Planned labor: \(JobTemplateDetailMoneyFormatter.money(task.contractedRate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
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
                    Label("Save Planned Stop", systemImage: "checkmark.circle")
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
            alertMessage = "Please enter a name or select a pay type, and provide estimated minutes."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase
            )

            let plannedStop = JobTemplatePlannedServiceStop(
                companyId: companyId,
                templateId: templateId,
                name: resolvedName,
                description: description,
                serviceStopTypeId: typeFields.typeId,
                serviceStopTypeName: typeFields.type,
                serviceStopTypeImage: typeFields.typeImage,
                serviceStopTypeUseCaseRawValue: serviceStopTypeUseCase.rawValue,
                estimatedMinutes: estimatedMinutes,
                sortOrder: nextSortOrder,
                taskTemplateIds: Array(selectedTaskTemplateIds),
                plannedLaborCostCents: plannedLaborCostCents,
                plannedLaborNotes: plannedLaborNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : plannedLaborNotes
            )

            try await dataService.saveJobTemplatePlannedServiceStops([plannedStop])

            onSaved()
            dismiss()
        } catch {
            alertMessage = "Could not save planned stop. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

private extension View {
    func jobTemplatePlannedStopSheetCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
