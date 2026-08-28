//
//  EditRepairRequest.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/2/26.
//

import SwiftUI

@MainActor
final class EditRepairRequestViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    // The full model
    @Published var repairRequest: RepairRequest
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showDeleteConfirmation:Bool = false

    // Editable fields (based on provided schema)
    @Published var date: Date
    @Published var status: RepairRequestStatus
    @Published var description: String
    @Published var locationId: String?
    @Published var bodyOfWaterId: String?
    @Published var equipmentId: String?
    
    //Pickers
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
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
        isActive: true
    )
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "" ,
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        notes: "",
        shape: "",
        length: [],
        depth: [],
        width: [],
        lastFilled: Date(),
        isActive: true
    )
    @Published var selectedEquipment: Equipment = Equipment(
        id: "",
        name: "",
        type: .filter,
        typeId: "",
        make: "",
        makeId: "",
        model: "",
        modelId: "",
        dateInstalled: Date(),
        status: .operational,
        needsService: true,
        notes: "",
        customerName: "",
        customerId: "",
        serviceLocationId: "",
        bodyOfWaterId: "",
        isActive: true
    )
    
    @Published var showBodyOfWaterPicker: Bool = false
    @Published var showLocationPicker: Bool = false
    @Published var showEquipmentPicker: Bool = false
    @Published var isLoadingContext: Bool = false

    // Non-editable but displayed for context
    let id: String
    let customerId: String
    let customerName: String
    let requesterId: String
    let requesterName: String
    let jobIds: [String]
    let photoUrls: [DripDropStoredImage]



    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    init(dataService: any ProductionDataServiceProtocol, repairRequest: RepairRequest) {
        self.dataService = dataService
        self.repairRequest = repairRequest

        // Non-editable mirrors
        self.id = repairRequest.id
        self.customerId = repairRequest.customerId
        self.customerName = repairRequest.customerName
        self.requesterId = repairRequest.requesterId
        self.requesterName = repairRequest.requesterName
        self.jobIds = repairRequest.jobIds
        self.photoUrls = repairRequest.photoUrls

        // Editable mirrors
        self.date = repairRequest.date
        self.status = repairRequest.status.selectableValue
        self.description = repairRequest.description
        self.locationId = repairRequest.locationId
        self.bodyOfWaterId = repairRequest.bodyOfWaterId
        self.equipmentId = repairRequest.equipmentId
    }

    func onLoad(companyId: String?) async {
        guard let companyId else { return }
        guard !isLoadingContext else { return }

        isLoadingContext = true
        defer { isLoadingContext = false }

        let loadedLocationId = cleanId(locationId)
        let loadedBodyOfWaterId = cleanId(bodyOfWaterId)
        let loadedEquipmentId = cleanId(equipmentId)

        if !loadedLocationId.isEmpty {
            do {
                selectedLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: loadedLocationId)
            } catch {
                print("[EditRepairRequestViewModel][onLoad][location] \(error)")
            }
        }

        if !loadedBodyOfWaterId.isEmpty {
            do {
                selectedBodyOfWater = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: loadedBodyOfWaterId)
            } catch {
                print("[EditRepairRequestViewModel][onLoad][bodyOfWater] \(error)")
            }
        }

        if !loadedEquipmentId.isEmpty {
            do {
                let equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: loadedEquipmentId)
                selectedEquipment = equipment

                if selectedLocation.id.isEmpty, !equipment.serviceLocationId.isEmpty {
                    selectedLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: equipment.serviceLocationId)
                    locationId = equipment.serviceLocationId
                }

                if selectedBodyOfWater.id.isEmpty, !equipment.bodyOfWaterId.isEmpty {
                    selectedBodyOfWater = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: equipment.bodyOfWaterId)
                    bodyOfWaterId = equipment.bodyOfWaterId
                }
            } catch {
                print("[EditRepairRequestViewModel][onLoad][equipment] \(error)")
            }
        }
    }

    func applySelectedLocation(_ location: ServiceLocation) {
        let selectedId = cleanId(location.id)
        locationId = selectedId

        if selectedId.isEmpty || selectedBodyOfWater.serviceLocationId != selectedId {
            bodyOfWaterId = ""
            selectedBodyOfWater = Self.emptyBodyOfWater
        }

        if selectedId.isEmpty || selectedEquipment.serviceLocationId != selectedId {
            equipmentId = ""
            selectedEquipment = Self.emptyEquipment
        }
    }

    func applySelectedBodyOfWater(_ bodyOfWater: BodyOfWater) {
        let selectedId = cleanId(bodyOfWater.id)
        bodyOfWaterId = selectedId

        if selectedId.isEmpty || selectedEquipment.bodyOfWaterId != selectedId {
            equipmentId = ""
            selectedEquipment = Self.emptyEquipment
        }
    }

    func applySelectedEquipment(_ equipment: Equipment) {
        let selectedId = cleanId(equipment.id)
        equipmentId = selectedId

        if !equipment.serviceLocationId.isEmpty, selectedLocation.id.isEmpty {
            locationId = equipment.serviceLocationId
        }

        if !equipment.bodyOfWaterId.isEmpty, selectedBodyOfWater.id.isEmpty {
            bodyOfWaterId = equipment.bodyOfWaterId
        }
    }

    private func cleanId(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private static var emptyBodyOfWater: BodyOfWater {
        BodyOfWater(
            id: "" ,
            name: "",
            gallons: "",
            material: "",
            customerId: "",
            serviceLocationId: "",
            notes: "",
            shape: "",
            length: [],
            depth: [],
            width: [],
            lastFilled: Date(),
            isActive: true
        )
    }

    private static var emptyEquipment: Equipment {
        Equipment(
            id: "",
            name: "",
            type: .filter,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: true,
            notes: "",
            customerName: "",
            customerId: "",
            serviceLocationId: "",
            bodyOfWaterId: "",
            isActive: true
        )
    }

    func save(companyId:String?) async {
        if let companyId {
            guard !isSaving else { return }
            isSaving = true
            defer { isSaving = false }
            errorMessage = nil
            
            var updated = repairRequest
            updated.date = date
            updated.status = status
            updated.description = description
            updated.locationId = cleanId(locationId)
            updated.bodyOfWaterId = cleanId(bodyOfWaterId)
            updated.equipmentId = cleanId(equipmentId)
            
            do {
                try await dataService.updateRepairRequest(companyId: companyId, repairRequest: updated)
                self.repairRequest = updated
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    func ondelete(companyId: String?){
        Task{
            if let companyId {
                do {
                    //I dont think I want to delete all of thes things
//                    for job in repairRequest.jobIds {
//                        try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: job)
//                        if let job = jobVM.workOrder {
//                            for stop in job.serviceStopIds {
//                                try await dataService.deleteServiceStopById(companyId: company.id, serviceStopId: stop)
//                            }
//                        }
//                        try await jobVM.deleteJob(companyId: company.id, jobId: job)
//                    }
                    
                    try await dataService.deleteRepairRequest(companyId: companyId, repairRequestId: repairRequest.id)
                } catch {
                    print("[RepairRequestDetailViewModel][ondelete] Error: \(error)")
                }
            }
        }
    }
}

struct EditRepairRequest: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService

    @StateObject var viewModel: EditRepairRequestViewModel
    @State private var showStatusPicker: Bool = false

    init(dataService: any ProductionDataServiceProtocol, repairRequest: RepairRequest) {
        _viewModel = StateObject(wrappedValue: EditRepairRequestViewModel(dataService: dataService, repairRequest: repairRequest))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    formCard
                    dangerCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            VStack {
                Spacer()
                bottomActionBar
            }
        }
        .navigationTitle("Edit Repair Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task {
            await viewModel.onLoad(companyId: masterDataManager.currentCompany?.id)
        }
        .onChange(of: viewModel.selectedLocation) { location in
            guard !viewModel.isLoadingContext else { return }
            viewModel.applySelectedLocation(location)
        }
        .onChange(of: viewModel.selectedBodyOfWater) { bodyOfWater in
            guard !viewModel.isLoadingContext else { return }
            viewModel.applySelectedBodyOfWater(bodyOfWater)
        }
        .onChange(of: viewModel.selectedEquipment) { equipment in
            guard !viewModel.isLoadingContext else { return }
            viewModel.applySelectedEquipment(equipment)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        ), actions: {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .alert(isPresented: $viewModel.showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(viewModel.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                    viewModel.ondelete(companyId: masterDataManager.currentCompany?.id)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Edit Repair Request")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Update the issue, site, and related equipment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Label(viewModel.status.displayName, systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint(viewModel.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(statusTint(viewModel.status).opacity(0.14), in: Capsule())

                Label(fullDate(date: viewModel.date), systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Request Details", systemImage: "person.text.rectangle")

            pickerRow(
                title: "Status",
                value: viewModel.status.displayName,
                systemImage: "checklist",
                isSelected: true
            ) {
                showStatusPicker = true
            }
            .confirmationDialog("Change Status", isPresented: $showStatusPicker, titleVisibility: .visible) {
                ForEach(RepairRequestStatus.allCases, id: \.self) { status in
                    Button(status.displayName) {
                        viewModel.status = status
                    }
                }

                Button("Cancel", role: .cancel) { }
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Date", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            detailRow(title: "Customer", value: viewModel.customerName, systemImage: "person")
            detailRow(title: "Requester", value: viewModel.requesterName, systemImage: "person.crop.circle")

            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextEditor(text: $viewModel.description)
                    .font(.subheadline)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            sectionHeader("Site", systemImage: "mappin.and.ellipse")

            pickerRow(
                title: "Location",
                value: viewModel.selectedLocation.id.isEmpty ? "Select Location" : locationSummary(viewModel.selectedLocation),
                systemImage: "house",
                isSelected: !viewModel.selectedLocation.id.isEmpty
            ) {
                viewModel.showLocationPicker.toggle()
            }
            .sheet(isPresented: $viewModel.showLocationPicker) {
                ServiceLocationPicker(
                    dataService: dataService,
                    customerId: viewModel.repairRequest.customerId,
                    location: $viewModel.selectedLocation
                )
            }

            pickerRow(
                title: "Body of Water",
                value: bodyOfWaterPickerText,
                systemImage: "drop",
                isSelected: !viewModel.selectedBodyOfWater.id.isEmpty,
                isEnabled: !viewModel.selectedLocation.id.isEmpty
            ) {
                viewModel.showBodyOfWaterPicker.toggle()
            }
            .sheet(isPresented: $viewModel.showBodyOfWaterPicker) {
                BodyOfWaterPicker(
                    dataService: dataService,
                    serviceLocationId: viewModel.selectedLocation.id,
                    bodyOfWater: $viewModel.selectedBodyOfWater
                )
            }

            pickerRow(
                title: "Equipment",
                value: equipmentPickerText,
                systemImage: "wrench.and.screwdriver",
                isSelected: !viewModel.selectedEquipment.id.isEmpty,
                isEnabled: !viewModel.selectedLocation.id.isEmpty
            ) {
                viewModel.showEquipmentPicker.toggle()
            }
            .sheet(isPresented: $viewModel.showEquipmentPicker) {
                EquipmentPickerByServiceLocationId(
                    dataService: dataService,
                    serviceLocationId: viewModel.selectedLocation.id,
                    equipment: $viewModel.selectedEquipment
                )
            }

            if !viewModel.jobIds.isEmpty {
                detailRow(title: "Connected Jobs", value: "\(viewModel.jobIds.count)", systemImage: "briefcase")
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var dangerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Danger Zone", systemImage: "trash")

            Button(action: {
                viewModel.alertMessage = "Confirm Delete"
                viewModel.showDeleteConfirmation.toggle()
            }, label: {
                Label("Delete Repair Request", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.poolRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.poolRed.opacity(0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            })
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    saveAndDismiss()
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                        }

                        Text(viewModel.isSaving ? "Saving" : "Save")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        viewModel.isSaving ? Color.blue.opacity(0.65) : Color.blue,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                saveAndDismiss()
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Text("Save")
                }
            }
            .disabled(viewModel.isSaving)
        }
    }

    private func saveAndDismiss() {
        Task {
            await viewModel.save(companyId: masterDataManager.currentCompany?.id)
            if viewModel.errorMessage == nil {
                dismiss()
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func pickerRow(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.45))
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEnabled ? Color.secondary : Color.secondary.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func detailRow(title: String, value: String, systemImage: String) -> some View {
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

                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var bodyOfWaterPickerText: String {
        if viewModel.selectedBodyOfWater.id.isEmpty {
            return viewModel.selectedLocation.id.isEmpty ? "Select a location first" : "Select Body of Water"
        }

        return bodyOfWaterSummary(viewModel.selectedBodyOfWater)
    }

    private var equipmentPickerText: String {
        if viewModel.selectedEquipment.id.isEmpty {
            return viewModel.selectedLocation.id.isEmpty ? "Select a location first" : "Select Equipment"
        }

        return equipmentSummary(viewModel.selectedEquipment)
    }

    private func locationSummary(_ location: ServiceLocation) -> String {
        let title = location.nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? location.address.streetAddress
            : location.nickName
        let address = addressSummary(location.address)

        if address.isEmpty || address == title {
            return title.isEmpty ? "Location" : title
        }

        return "\(title.isEmpty ? "Location" : title)\n\(address)"
    }

    private func addressSummary(_ address: Address) -> String {
        let cityLine = [address.city, address.state, address.zip]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return [address.streetAddress, cityLine]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func bodyOfWaterSummary(_ bodyOfWater: BodyOfWater) -> String {
        let name = bodyOfWater.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Body of water"
            : bodyOfWater.name
        let details = [bodyOfWater.gallons, bodyOfWater.material]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        return details.isEmpty ? name : "\(name)\n\(details)"
    }

    private func equipmentSummary(_ equipment: Equipment) -> String {
        let name = equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? equipment.type.rawValue
            : equipment.name
        let details = [equipment.type.rawValue, equipment.make, equipment.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        return details.isEmpty ? name : "\(name)\n\(details)"
    }

    private func statusTint(_ status: RepairRequestStatus) -> Color {
        switch status.selectableValue {
        case .resolved:
            return Color.poolGreen
        case .convertedToJob:
            return Color.gray
        case .cancelled, .unresolved:
            return Color.poolRed
        case .inprogress, .legacyPending, .legacyPendingCapitalized:
            return Color.yellow
        }
    }
}

// MARK: - Preview
#Preview {
    // Provide your real companyId, dataService, and a sample RepairRequest here when available.
    // EditRepairRequest(companyId: "company-123", dataService: MockDataService(), repairRequest: sample)
    Text("EditRepairRequest Preview")
}
