//
//  AddNewRepairRequest.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import PhotosUI
import SwiftUI
import Darwin

struct AddNewRepairRequest: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = CameraDataModel()
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @StateObject var VM: AddRepairRequestViewModel

    @Binding var isPresented: Bool
    @State var customer: Customer?

    init(
        dataService: any ProductionDataServiceProtocol,
        isPresented: Binding<Bool>,
        customer: Customer?
    ) {
        _VM = StateObject(wrappedValue: AddRepairRequestViewModel(dataService: dataService))
        _isPresented = isPresented
        _customer = State(wrappedValue: customer)
    }

    @FocusState var descriptionField: Bool

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    customerCard
                    photosCard
                    descriptionCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            VStack {
                Spacer()
                bottomActionBar
            }

            if VM.screenLoading {
                loadingOverlay
            }
        }
        .navigationTitle("Add Repair Request")
        .navigationBarTitleDisplayMode(.inline)
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            print("")
            print("On Load Add Repair Request")

            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id, customer: customer)
                }
            } catch {
                print("Error - onLoad - [AddNewRepairRequest]")
            }
        }
        .onChange(of: VM.selectedCustomer) { cus in
            if cus.id == "" { return }

            Task {
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeCustomer(companyId: company.id, cus)
                    }
                } catch {
                    print("[AddNewRepairRequest][onChange(of: VM.selectedCustomer] Error \(error)")
                }
            }
        }
        .onChange(of: VM.selectedLocation) { loc in
            Task {
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeLocation(companyId: company.id, loc)
                    }
                } catch {
                    print("[AddNewRepairRequest][onChange(of: VM.selectedLocation] Error \(error)")
                }
            }
        }
    }
}

// MARK: - Main Sections

extension AddNewRepairRequest {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Add Repair Request")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Capture the issue, location, and any helpful photos.")
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
                Label("Repair", systemImage: "wrench.and.screwdriver")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                if VM.selectedDripDropPhotos.count > 0 {
                    Label("\(VM.selectedDripDropPhotos.count) Photos", systemImage: "photo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var customerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Request Details", systemImage: "person.text.rectangle")

            pickerRow(
                title: "Customer",
                value: VM.selectedCustomer.id == "" ? "Select Customer" : "\(VM.selectedCustomer.firstName) \(VM.selectedCustomer.lastName)",
                systemImage: "person.crop.circle",
                isSelected: VM.selectedCustomer.id != ""
            ) {
                VM.showCustomerSelector.toggle()
            }
            .sheet(isPresented: $VM.showCustomerSelector) {
                CustomerAndLocationPicker(
                    dataService: dataService,
                    customer: $VM.selectedCustomer,
                    location: $VM.selectedLocation
                )
            }

            pickerRow(
                title: "Location",
                value: VM.selectedLocation.id == "" ? "Select Location" : VM.selectedLocation.address.streetAddress,
                systemImage: "mappin.and.ellipse",
                isSelected: VM.selectedLocation.id != ""
            ) {
                VM.showLocationSelector.toggle()
            }
            .sheet(isPresented: $VM.showLocationSelector) {
                ServiceLocationPicker(
                    dataService: dataService,
                    customerId: VM.selectedCustomer.id,
                    location: $VM.selectedLocation
                )
            }

            pickerRow(
                title: "Body Of Water",
                value: VM.selectedBodyOfWater.id == "" ? "Select Body Of Water" : VM.selectedBodyOfWater.name,
                systemImage: "drop",
                isSelected: VM.selectedBodyOfWater.id != ""
            ) {
                VM.showBodyOfWaterSelector.toggle()
            }
            .sheet(isPresented: $VM.showBodyOfWaterSelector) {
                BodyOfWaterPicker(
                    dataService: dataService,
                    serviceLocationId: VM.selectedLocation.id,
                    bodyOfWater: $VM.selectedBodyOfWater
                )
            }

            pickerRow(
                title: "Equipment",
                value: VM.selectedEquipment.id == "" ? "Select Equipment" : VM.selectedEquipment.name,
                systemImage: "wrench.and.screwdriver",
                isSelected: VM.selectedEquipment.id != ""
            ) {
                if VM.selectedLocation.id != "" {
                    VM.showEquipmentSelector.toggle()
                }
            }
            .sheet(isPresented: $VM.showEquipmentSelector) {
                EquipmentPickerByServiceLocationId(
                    dataService: dataService,
                    serviceLocationId: VM.selectedLocation.id,
                    equipment: $VM.selectedEquipment
                )
            }

            if VM.selectedEquipment.id != "" {
                pickerRow(
                    title: "Equipment Status",
                    value: VM.selectedEquipmentStatus.displayName,
                    systemImage: "gauge.with.dots.needle.bottom.50percent",
                    isSelected: true
                ) {
                    VM.showEquipmentStatusSelector.toggle()
                }
                .sheet(isPresented: $VM.showEquipmentStatusSelector) {
                    EquipmentStatusPicker(
                        dataService: dataService,
                        status: $VM.selectedEquipmentStatus
                    )
                    .presentationDetents([.fraction(0.3), .fraction(0.5)])
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var photosCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Photos", systemImage: "camera")

                Spacer()

                Text("\(VM.selectedDripDropPhotos.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Description", systemImage: "text.alignleft")

            TextField(
                "Describe what needs to be repaired",
                text: $VM.description,
                axis: .vertical
            )
            .font(.subheadline)
            .lineLimit(5, reservesSpace: true)
            .submitLabel(.return)
            .focused($descriptionField)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if descriptionField {
                HStack {
                    Spacer()

                    Button {
                        descriptionField = false
                    } label: {
                        Label("Done", systemImage: "keyboard.chevron.compact.down")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Bottom Bar

extension AddNewRepairRequest {

    var bottomActionBar: some View {
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
                    submitRepairRequest()
                } label: {
                    HStack(spacing: 8) {
                        if VM.screenLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark")
                        }

                        Text(VM.screenLoading ? "Submitting" : "Submit")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(descriptionField || VM.screenLoading)
                .opacity((descriptionField || VM.screenLoading) ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Submitting request...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Helpers

extension AddNewRepairRequest {

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func pickerRow(
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

    func submitRepairRequest() {
        Task {
            VM.screenLoading = true

            do {
                if let company = masterDataManager.currentCompany,
                   let user = masterDataManager.user {
                    let userFullName = "\(user.firstName) \(user.lastName)"

                    try await VM.uploadRepairRequestWithValidation(
                        companyId: company.id,
                        requesterId: user.id,
                        requesterName: userFullName
                    )

                    VM.alertMessage = "Successfully"
                    print(VM.alertMessage)
                    VM.showAlert = true

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    VM.screenLoading = false
                    dismiss()
                } else {
                    VM.alertMessage = "Add Request Error Invalid User"
                    VM.showAlert = true
                    VM.screenLoading = false
                }
            } catch RepairRequestError.invalidCustomer {
                handleSubmitError("Add Request Error Invalid Customer")
            } catch RepairRequestError.invalidUser {
                handleSubmitError("Add Request Error Invalid User")
            } catch RepairRequestError.invalidStatus {
                handleSubmitError("Add Request Error Invalid Status")
            } catch RepairRequestError.noDescription {
                handleSubmitError("Add Request Error No Description")
            } catch RepairRequestError.imagesNotLoaded {
                handleSubmitError("Add Request Error Images Not Loaded")
            } catch {
                handleSubmitError("Add Request Error Other")
            }
        }
    }

    func handleSubmitError(_ message: String) {
        VM.alertMessage = message
        print(VM.alertMessage)
        VM.showAlert = true
        VM.screenLoading = false

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}
