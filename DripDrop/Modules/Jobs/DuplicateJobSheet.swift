//
//  DuplicateJobSheet.swift
//  DripDrop
//

import SwiftUI

struct DuplicateJobSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let sourceJob: Job
    let plannedServiceStops: [JobPlannedServiceStop]
    let jobTasks: [JobTask]
    let shoppingItems: [ShoppingListItem]
    let dataService: any ProductionDataServiceProtocol

    @State private var newInternalId: String
    @State private var selectedAdmin: CompanyUser

    @State private var isSaving: Bool = false
    @State private var showAdminSelector: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        companyId: String,
        sourceJob: Job,
        plannedServiceStops: [JobPlannedServiceStop],
        jobTasks: [JobTask],
        shoppingItems: [ShoppingListItem],
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.sourceJob = sourceJob
        self.plannedServiceStops = plannedServiceStops
        self.jobTasks = jobTasks
        self.shoppingItems = shoppingItems
        self.dataService = dataService

        _newInternalId = State(initialValue: "\(sourceJob.internalId)-COPY")
        _selectedAdmin = State(
            initialValue: CompanyUser(
                id: "",
                userId: sourceJob.adminId,
                userName: sourceJob.adminName,
                roleId: "",
                roleName: "",
                dateCreated: Date(),
                status: .active,
                workerType: .employee
            )
        )
    }

    private var canSave: Bool {
        !newInternalId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedAdmin.userId.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        copySnapshotCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Duplicate Job")
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
            .alert("Duplicate Job", isPresented: $showAlert) {
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
                    Text("Duplicate Job")
                        .font(.title3.weight(.semibold))

                    Text("\(sourceJob.internalId) • \(sourceJob.customerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "doc.on.doc")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("This creates a new draft job with the same plan: planned stops, tasks, materials, price, and labor snapshot. It does not copy service stops, offers, payroll, invoices, or purchased items.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateActionCard()
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("New Job Details", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                Text("New Job ID")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("New internal ID", text: $newInternalId)
                    .textInputAutocapitalization(.characters)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button {
                showAdminSelector = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Admin / Owner")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(selectedAdmin.userId.isEmpty ? "Select Admin" : "\(selectedAdmin.userName) \(selectedAdmin.roleName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedAdmin.userId.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAdminSelector) {
                CompanyUserPicker(
                    dataService: dataService,
                    companyUser: $selectedAdmin
                )
            }

            Text("This version duplicates to the same customer and service location. We can add customer/location pickers in the next pass.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateActionCard()
    }

    private var copySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What Will Copy", systemImage: "square.stack.3d.up")
                .font(.headline.weight(.semibold))

            JobTemplateSnapshotRow(title: "Customer", value: sourceJob.customerName)
            JobTemplateSnapshotRow(title: "Service Location ID", value: sourceJob.serviceLocationId)
            JobTemplateSnapshotRow(title: "Planned Stops", value: "\(plannedServiceStops.count)")
            JobTemplateSnapshotRow(title: "Tasks", value: "\(jobTasks.count)")
            JobTemplateSnapshotRow(title: "Materials", value: "\(shoppingItems.count)")
            JobTemplateSnapshotRow(title: "Customer Price", value: JobTemplateActionMoneyFormatter.money(sourceJob.rate))
            JobTemplateSnapshotRow(title: "Labor Cost", value: JobTemplateActionMoneyFormatter.money(sourceJob.laborCost))
        }
        .jobTemplateActionCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await duplicate()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Label("Create Copy", systemImage: "doc.on.doc")
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

    private func duplicate() async {
        guard canSave else {
            alertMessage = "Please enter a job ID and select an admin."
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
            let service = JobTemplateWorkflowService(dataService: dataService)

            _ = try await service.duplicateJob(
                companyId: companyId,
                sourceJob: sourceJob,
                plannedServiceStops: plannedServiceStops,
                jobTasks: jobTasks,
                shoppingItems: shoppingItems,
                newInternalId: newInternalId.trimmingCharacters(in: .whitespacesAndNewlines),
                customerId: sourceJob.customerId,
                customerName: sourceJob.customerName,
                serviceLocationId: sourceJob.serviceLocationId,
                admin: selectedAdmin,
                createdByUserId: userId
            )

            dismiss()
        } catch {
            alertMessage = "Could not duplicate job. \(error.localizedDescription)"
            showAlert = true
        }
    }
}