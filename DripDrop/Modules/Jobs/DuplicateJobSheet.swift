//
//  DuplicateJobSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
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

    @State private var selectedCustomer: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )

    @State private var selectedServiceLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false,
        isActive: true
    )

    @State private var showAdminSelector: Bool = false
    @State private var showCustomerSelector: Bool = false
    @State private var showServiceLocationSelector: Bool = false

    @State private var isSaving: Bool = false
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

    private var selectedCustomerName: String {
        let name = "\(selectedCustomer.firstName) \(selectedCustomer.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? selectedCustomer.firstName : name
    }

    private var canSave: Bool {
        !newInternalId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedAdmin.userId.isEmpty &&
        !selectedCustomer.id.isEmpty &&
        !selectedServiceLocation.id.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        headerCard
                        detailsCard
                        customerLocationCard
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
                    Text("Duplicate Job Plan")
                        .font(.title3.weight(.semibold))

                    Text("Source: \(sourceJob.internalId) • \(sourceJob.customerName)")
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

            Text("This copies the reusable job plan: planned stops, tasks, materials, price, and labor snapshot. Choose the new customer and service location for the copied job.")
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

            duplicatePickerRow(
                title: "Admin / Owner",
                value: selectedAdmin.userId.isEmpty ? "Select Admin" : "\(selectedAdmin.userName) \(selectedAdmin.roleName)",
                systemImage: "person.crop.circle",
                isSelected: !selectedAdmin.userId.isEmpty
            ) {
                showAdminSelector = true
            }
            .sheet(isPresented: $showAdminSelector) {
                CompanyUserPicker(
                    dataService: dataService,
                    companyUser: $selectedAdmin
                )
            }
        }
        .jobTemplateActionCard()
    }

    private var customerLocationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("New Customer & Location", systemImage: "mappin.and.ellipse")
                .font(.headline.weight(.semibold))

            duplicatePickerRow(
                title: "Customer",
                value: selectedCustomer.id.isEmpty ? "Select Customer" : selectedCustomerName,
                systemImage: "person",
                isSelected: !selectedCustomer.id.isEmpty
            ) {
                showCustomerSelector = true
            }
            .sheet(isPresented: $showCustomerSelector, onDismiss: {
                if selectedServiceLocation.customerId != selectedCustomer.id {
                    selectedServiceLocation = emptyServiceLocation()
                }
            }) {
                CustomerPickerScreen(
                    dataService: dataService,
                    customer: $selectedCustomer
                )
            }

            duplicatePickerRow(
                title: "Service Location",
                value: selectedServiceLocation.id.isEmpty ? "Select Service Location" : serviceLocationDisplayName(selectedServiceLocation),
                systemImage: "house",
                isSelected: !selectedServiceLocation.id.isEmpty
            ) {
                guard !selectedCustomer.id.isEmpty else {
                    alertMessage = "Please select a customer first."
                    showAlert = true
                    return
                }

                showServiceLocationSelector = true
            }
            .sheet(isPresented: $showServiceLocationSelector) {
                CustomerAndLocationPicker(dataService: dataService, customer: $selectedCustomer, location: $selectedServiceLocation)
            }

            Text("The duplicated job will be created for the selected customer and selected service location. Customer-specific actual work, invoices, payroll, offers, and purchased items are not copied.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobTemplateActionCard()
    }

    private var copySnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What Will Copy", systemImage: "square.stack.3d.up")
                .font(.headline.weight(.semibold))

            JobTemplateSnapshotRow(title: "Source Customer", value: sourceJob.customerName)
            JobTemplateSnapshotRow(title: "New Customer", value: selectedCustomer.id.isEmpty ? "Required" : selectedCustomerName)
            JobTemplateSnapshotRow(title: "New Service Location", value: selectedServiceLocation.id.isEmpty ? "Required" : serviceLocationDisplayName(selectedServiceLocation))
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
            alertMessage = "Please enter a job ID, select an admin, select a customer, and select a service location."
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
                customerId: selectedCustomer.id,
                customerName: selectedCustomerName,
                serviceLocationId: selectedServiceLocation.id,
                admin: selectedAdmin,
                createdByUserId: userId
            )

            dismiss()
        } catch {
            alertMessage = "Could not duplicate job. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func duplicatePickerRow(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
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
    }

    private func serviceLocationDisplayName(_ location: ServiceLocation) -> String {
        if !location.nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return location.nickName
        }

        return location.address.streetAddress.isEmpty ? location.id : location.address.streetAddress
    }

    private func emptyServiceLocation() -> ServiceLocation {
        ServiceLocation(
            id: "",
            nickName: "",
            address: Address(
                streetAddress: "",
                city: "",
                state: "",
                zip: "",
                latitude: 0,
                longitude: 0
            ),
            gateCode: "",
            mainContact: Contact(
                id: "",
                name: "",
                phoneNumber: "",
                email: ""
            ),
            bodiesOfWaterId: [],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "",
            customerName: "",
            preText: false,
            isActive: true
        )
    }
}
