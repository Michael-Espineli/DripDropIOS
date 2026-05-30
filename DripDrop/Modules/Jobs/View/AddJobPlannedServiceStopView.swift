//
//  AddJobPlannedServiceStopView.swift
//  DripDrop
//

import SwiftUI

struct AddJobPlannedServiceStopView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let jobId: String
    let jobTasks: [JobTask]
    let existingPlannedStops: [JobPlannedServiceStop]
    let dataService: any ProductionDataServiceProtocol
    let onSaved: () -> Void

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit
    @State private var estimatedMinutes: Int = 60
    @State private var selectedTaskIds: Set<String> = []

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var selectedTasks: [JobTask] {
        jobTasks.filter { selectedTaskIds.contains($0.id) }
    }

    private var nextSortOrder: Int {
        (existingPlannedStops.map { $0.sortOrder }.max() ?? -1) + 1
    }

    private var canSave: Bool {
        !resolvedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        estimatedMinutes > 0
    }

    private var resolvedName: String {
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let selectedCompanyServiceStopType {
            return selectedCompanyServiceStopType.name
        }

        return serviceStopTypeUseCase.fallbackName
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
                        taskLinkCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Planned Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Planned Service Stop", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Add Planned Service Stop")
                        .font(.title3.weight(.semibold))

                    Text("Plan expected visits before they are scheduled.")
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

            Text("This does not create a real service stop yet. It helps estimate labor, build templates, and organize planned work.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .plannedStopCard()
    }

    private var serviceStopTypeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Service Stop Type", systemImage: "flag")
                .font(.headline.weight(.semibold))

            Picker("Use Case", selection: $serviceStopTypeUseCase) {
                ForEach(ServiceStopTypeUseCase.allCases, id: \.self) { useCase in
                    Text(useCase.fallbackName).tag(useCase)
                }
            }
            .pickerStyle(.menu)

            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase,
                title: "Company Service Stop Type",
                subtitle: "Choose the planned type for this job visit."
            )

            Text("The selected type will later help estimate pay and create scheduled service stops.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .plannedStopCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Details", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: First install visit", text: $name)
                    .modifier(PlainTextFieldModifier())

                Text("Leave blank to use the selected service stop type name.")
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
        .plannedStopCard()
    }

    private var taskLinkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Linked Tasks", systemImage: "checklist")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(selectedTaskIds.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if jobTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist.unchecked",
                    description: Text("Add tasks to the job, then link them to planned stops.")
                )
                .padding(.vertical, 10)
            } else {
                Button {
                    if selectedTaskIds.count == jobTasks.count {
                        selectedTaskIds.removeAll()
                    } else {
                        selectedTaskIds = Set(jobTasks.map { $0.id })
                    }
                } label: {
                    Text(selectedTaskIds.count == jobTasks.count ? "Deselect All" : "Select All")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)

                VStack(spacing: 8) {
                    ForEach(jobTasks) { task in
                        plannedStopTaskToggleRow(task)
                    }
                }
            }

            Text("Linking tasks helps you organize what work is expected during each planned visit.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .plannedStopCard()
    }

    private func plannedStopTaskToggleRow(_ task: JobTask) -> some View {
        let isSelected = selectedTaskIds.contains(task.id)

        return Button {
            if isSelected {
                selectedTaskIds.remove(task.id)
            } else {
                selectedTaskIds.insert(task.id)
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
            alertMessage = "Please provide a planned stop name or service stop type and estimated minutes."
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
            let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase
            )

            let plannedStop = JobPlannedServiceStop(
                companyId: companyId,
                jobId: jobId,
                name: resolvedName,
                description: description,
                serviceStopTypeId: typeFields.typeId,
                serviceStopTypeName: typeFields.type,
                serviceStopTypeImage: typeFields.typeImage,
                serviceStopTypeUseCaseRawValue: serviceStopTypeUseCase.rawValue,
                estimatedMinutes: estimatedMinutes,
                sortOrder: nextSortOrder,
                taskIds: Array(selectedTaskIds),
                createdByUserId: userId
            )

            try await dataService.saveJobPlannedServiceStop(plannedStop)

            onSaved()
            dismiss()
        } catch {
            alertMessage = "Could not save planned service stop. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

private extension View {
    func plannedStopCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}