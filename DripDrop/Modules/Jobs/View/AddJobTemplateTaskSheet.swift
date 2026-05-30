//
//  AddJobTemplateTaskSheet.swift
//  DripDrop
//

import SwiftUI

struct AddJobTemplateTaskSheet: View {
    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let templateId: String
    let existingTasks: [JobTemplateTask]
    let dataService: any ProductionDataServiceProtocol
    let onSaved: () -> Void

    @State private var name: String = ""
    @State private var type: JobTaskType = .basic
    @State private var description: String = ""
    @State private var contractedRate: Int = 0
    @State private var estimatedTime: Int = 30
    @State private var customerApproval: Bool = false

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var nextSortOrder: Int {
        (existingTasks.map { $0.sortOrder }.max() ?? -1) + 1
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        estimatedTime > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        laborCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Add Template Task")
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
            .alert("Template Task", isPresented: $showAlert) {
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
                    Text("Add Template Task")
                        .font(.title3.weight(.semibold))

                    Text("Create a reusable task for this job template.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "checklist.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("Template tasks become planned job tasks when a new job is created from this template.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .jobTemplateTaskSheetCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Task Details",
                systemImage: "doc.text"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Task Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: Replace filter", text: $name)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Task Type")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Task Type", selection: $type) {
                    ForEach(JobTaskType.allCases, id: \.self) { taskType in
                        Text(taskType.rawValue).tag(taskType)
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
                    "Optional task notes...",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(3, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Toggle("Requires Customer Approval", isOn: $customerApproval)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateTaskSheetCard()
    }

    private var laborCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Labor Planning",
                systemImage: "dollarsign.circle"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Contracted / Planned Labor")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                MoneyTextField(cents: $contractedRate)

                Text("This becomes the planned task labor when creating a job from this template.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Time")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Stepper("\(estimatedTime) min", value: $estimatedTime, in: 5...720, step: 5)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateTaskSheetCard()
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
                    Label("Save Task", systemImage: "checkmark.circle")
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
            alertMessage = "Please enter a task name and estimated time."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let task = JobTemplateTask(
                companyId: companyId,
                templateId: templateId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                description: description,
                contractedRate: contractedRate,
                estimatedTime: estimatedTime,
                customerApproval: customerApproval,
                sortOrder: nextSortOrder
            )

            try await dataService.saveJobTemplateTasks([task])

            onSaved()
            dismiss()
        } catch {
            alertMessage = "Could not save task. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

private extension View {
    func jobTemplateTaskSheetCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}