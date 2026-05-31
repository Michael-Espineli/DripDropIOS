//
//  SaveJobAsTemplateSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


import SwiftUI

struct SaveJobAsTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let job: Job
    let plannedServiceStops: [JobPlannedServiceStop]
    let jobTasks: [JobTask]
    let shoppingItems: [ShoppingListItem]
    let dataService: any ProductionDataServiceProtocol

    @State private var templateName: String
    @State private var templateDescription: String

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        companyId: String,
        job: Job,
        plannedServiceStops: [JobPlannedServiceStop],
        jobTasks: [JobTask],
        shoppingItems: [ShoppingListItem],
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.job = job
        self.plannedServiceStops = plannedServiceStops
        self.jobTasks = jobTasks
        self.shoppingItems = shoppingItems
        self.dataService = dataService

        _templateName = State(initialValue: job.type.isEmpty ? job.internalId : job.type)
        _templateDescription = State(initialValue: job.description)
    }

    private var canSave: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        snapshotCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Save Template")
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
            .alert("Save Template", isPresented: $showAlert) {
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
                    Text("Save Job As Template")
                        .font(.title3.weight(.semibold))

                    Text("\(job.internalId) • \(job.customerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "doc.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("This saves the reusable plan: planned service stops, tasks, materials, customer price, and labor snapshot. It does not save customer, invoices, offers, payroll, or actual service stops.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateActionCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Template Details", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("Template Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: Filter Install", text: $templateName)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Optional template notes...",
                    text: $templateDescription,
                    axis: .vertical
                )
                .lineLimit(4, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .jobTemplateActionCard()
    }

    private var snapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Template Snapshot", systemImage: "square.stack.3d.up")
                .font(.headline.weight(.semibold))

            JobTemplateSnapshotRow(title: "Planned Stops", value: "\(plannedServiceStops.count)")
            JobTemplateSnapshotRow(title: "Tasks", value: "\(jobTasks.count)")
            JobTemplateSnapshotRow(title: "Materials", value: "\(shoppingItems.count)")
            JobTemplateSnapshotRow(title: "Default Customer Price", value: JobTemplateActionMoneyFormatter.money(job.rate))
            JobTemplateSnapshotRow(title: "Default Labor Cost", value: JobTemplateActionMoneyFormatter.money(job.laborCost))
        }
        .jobTemplateActionCard()
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
                    Label("Save Template", systemImage: "checkmark.circle")
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
            print("  [SaveJobAsTemplateSheet][save] \(alertMessage)")
            return
        }

        guard let userId = masterDataManager.user?.id else {
            alertMessage = "Missing user."
            showAlert = true
            print("  [SaveJobAsTemplateSheet][save] \(alertMessage)")
            return
        }

        isSaving = true
        defer { isSaving = false }
        
    print("  [SaveJobAsTemplateSheet][save] 1")
        do {
            let service = JobTemplateWorkflowService(dataService: dataService)
            
        print("  [SaveJobAsTemplateSheet][save] 2")
            _ = try await service.saveJobAsTemplate(
                companyId: companyId,
                sourceJob: job,
                plannedServiceStops: plannedServiceStops,
                jobTasks: jobTasks,
                shoppingItems: shoppingItems,
                templateName: templateName.trimmingCharacters(in: .whitespacesAndNewlines),
                createdByUserId: userId
            )
            print("  [SaveJobAsTemplateSheet][save] 3")

                alertMessage = "Successfully Added"
                showAlert = true
            print("  [SaveJobAsTemplateSheet][save] \(alertMessage)")
            dismiss()
        } catch {
            alertMessage = "Could not save template. \(error.localizedDescription)"
            showAlert = true
        }
    }
}
