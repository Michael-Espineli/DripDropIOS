//
//  AddJobPlannedServiceStopDraftSheet.swift
//  DripDrop
//

import SwiftUI

struct AddJobPlannedServiceStopDraftSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let jobId: String
    let jobTasks: [JobTask]
    let existingPlannedStops: [JobPlannedServiceStop]
    let dataService: any ProductionDataServiceProtocol

    @Binding var plannedStops: [JobPlannedServiceStop]

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var estimatedMinutes: Int = 60
    @State private var plannedLaborCostCents: Int = 0
    @State private var plannedLaborNotes: String = ""
    @State private var selectedTaskIds: Set<String> = []

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private let fallbackUseCase: ServiceStopTypeUseCase = .jobVisit

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

        return ""
    }

    private var canSave: Bool {
        selectedCompanyServiceStopType != nil &&
        !resolvedName.isEmpty &&
        estimatedMinutes > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        typeCard
                        detailsCard
                        linkedTasksCard

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
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .alert("Planned Stop", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add Planned Stop", systemImage: "calendar.badge.plus")
                .font(.title3.weight(.semibold))

            Text("This planned stop will be saved when the repair-request job is submitted.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .repairDraftPlannedStopCard()
    }

    private var typeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Company Service Stop Type", systemImage: "flag")
                .font(.headline.weight(.semibold))

            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: fallbackUseCase,
                title: "Service Stop Type",
                subtitle: "Choose the company service stop type for this planned visit."
            )

            Text("Company service stop types are used for planning, scheduling, payroll mappings, and templates.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .repairDraftPlannedStopCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Details & Labor", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Leave blank to use selected type", text: $name)
                    .modifier(PlainTextFieldModifier())
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
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Labor Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Optional labor notes", text: $plannedLaborNotes, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Optional visit notes", text: $description, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .repairDraftPlannedStopCard()
    }

    private var linkedTasksCard: some View {
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
                    description: Text("Add tasks first, then link them to planned stops.")
                )
                .padding(.vertical, 10)
            } else {
                VStack(spacing: 8) {
                    ForEach(jobTasks) { task in
                        Button {
                            if selectedTaskIds.contains(task.id) {
                                selectedTaskIds.remove(task.id)
                            } else {
                                selectedTaskIds.insert(task.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedTaskIds.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedTaskIds.contains(task.id) ? .accent : .secondary)

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
                                selectedTaskIds.contains(task.id) ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.045),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .repairDraftPlannedStopCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                saveDraftStop()
            } label: {
                Label("Add Planned Stop", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

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

    private func saveDraftStop() {
        guard canSave else {
            alertMessage = "Please select a company service stop type and estimated minutes."
            showAlert = true
            return
        }

        guard let selectedCompanyServiceStopType else {
            alertMessage = "Please select a company service stop type."
            showAlert = true
            return
        }

        let userId = masterDataManager.user?.id ?? ""

        let plannedStop = JobPlannedServiceStop(
            companyId: companyId,
            jobId: jobId,
            name: resolvedName,
            description: description,
            serviceStopTypeId: selectedCompanyServiceStopType.id,
            serviceStopTypeName: selectedCompanyServiceStopType.name,
            serviceStopTypeImage: selectedCompanyServiceStopType.imageName ?? "",
            serviceStopTypeUseCaseRawValue: fallbackUseCase.rawValue,
            estimatedMinutes: estimatedMinutes,
            sortOrder: nextSortOrder,
            taskIds: Array(selectedTaskIds),
            plannedLaborCostCents: plannedLaborCostCents,
            plannedLaborNotes: plannedLaborNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : plannedLaborNotes,
            createdByUserId: userId
        )

        plannedStops.append(plannedStop)
        dismiss()
    }
}

private extension View {
    func repairDraftPlannedStopCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}