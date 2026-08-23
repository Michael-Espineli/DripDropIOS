//
//  CreateJobFromTemplateSheet.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/24/26.
//


//
//  CreateJobFromTemplateSheet.swift
//  DripDrop
//

import SwiftUI

struct CreateJobFromTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let template: JobTemplate
    let dataService: any ProductionDataServiceProtocol

    @State private var newInternalId: String = ""

    @State private var selectedAdmin: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )

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

    private var selectedCustomerName: String {
        let fullName = "\(selectedCustomer.firstName) \(selectedCustomer.lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !fullName.isEmpty {
            return fullName
        }

        return selectedCustomer.firstName
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
                        newJobDetailsCard
                        customerLocationCard
                        templateSnapshotCard

                        Color.clear.frame(height: 90)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Create Job")
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
            .alert("Create Job From Template", isPresented: $showAlert) {
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
                    Text("Create Job From Template")
                        .font(.title3.weight(.semibold))

                    Text(template.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: template.jobTypeImage ?? "plus.rectangle.on.folder")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.thinMaterial, in: Circle())
            }

            Text("This creates a new draft job from the reusable template plan. You choose the customer, service location, and admin for the new job.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .createJobTemplateCard()
    }

    private var newJobDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "New Job Details",
                systemImage: "doc.text"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("New Job ID")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Example: J-1048", text: $newInternalId)
                    .textInputAutocapitalization(.characters)
                    .modifier(PlainTextFieldModifier())

                Text("This becomes the internal job ID shown on the job detail page.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            createJobPickerRow(
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
        .createJobTemplateCard()
    }

    private var customerLocationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            JobTemplateSectionHeader(
                title: "Customer & Location",
                systemImage: "mappin.and.ellipse"
            )

            createJobPickerRow(
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
                CustomerAndLocationPicker(
                    dataService: dataService,
                    customer: $selectedCustomer,
                    location: $selectedServiceLocation
                )
            }

            createJobPickerRow(
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
                ServiceLocationPicker(
                    dataService: dataService,
                    customerId: selectedCustomer.id,
                    location: $selectedServiceLocation
                )
            }

            Text("Templates do not store customer or service location. Those are chosen here when creating a real job.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .createJobTemplateCard()
    }

    private var templateSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            JobTemplateSectionHeader(
                title: "Template Snapshot",
                systemImage: "square.stack.3d.up"
            )

            JobTemplateDetailSummaryRow(
                title: "Template",
                value: template.name
            )

            JobTemplateDetailSummaryRow(
                title: "Default Priority",
                value: template.defaultIssuePriorityDisplayName
            )

            JobTemplateDetailMoneyRow(
                title: "Default Customer Price",
                cents: template.defaultRateCents
            )

            JobTemplateDetailMoneyRow(
                title: "Default Labor Cost",
                cents: template.defaultLaborCostCents
            )

            Text("Planned stops, template tasks, and template materials will be copied into the new job.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .createJobTemplateCard()
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await createJob()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Label("Create Job", systemImage: "checkmark.circle")
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

    private func createJob() async {
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

            _ = try await service.createJobFromTemplate(
                companyId: template.companyId,
                templateId: template.id,
                newInternalId: newInternalId.trimmingCharacters(in: .whitespacesAndNewlines),
                customerId: selectedCustomer.id,
                customerName: selectedCustomerName,
                serviceLocationId: selectedServiceLocation.id,
                admin: selectedAdmin,
                createdByUserId: userId
            )

            dismiss()
        } catch {
            alertMessage = "Could not create job. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func createJobPickerRow(
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

        if !location.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return location.address.streetAddress
        }

        return location.id
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

private extension View {
    func createJobTemplateCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
