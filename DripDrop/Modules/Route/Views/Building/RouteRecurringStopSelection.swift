//
//  RouteRecurringStopSelection.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/21/26.
//


//
//  RouteRecurringStopPickerView.swift
//  DripDrop
//

import SwiftUI

struct RouteRecurringStopSelection {
    var customer: Customer
    var location: ServiceLocation
    var serviceStopType: CompanyServiceStopType?
    var typeFields: ServiceStopTypeFields
}

struct RouteRecurringStopPickerView: View {

    @Environment(\.dismiss) private var dismiss

    let dataService: any ProductionDataServiceProtocol
    let companyId: String
    let defaultUseCase: ServiceStopTypeUseCase
    let onSelect: (RouteRecurringStopSelection) -> Void

    @State private var customer: Customer = Customer(
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

    @State private var location: ServiceLocation = ServiceLocation(
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
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
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

    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var showLocationPicker: Bool = false
    @State private var hasPresentedInitialLocationPicker: Bool = false

    init(
        dataService: any ProductionDataServiceProtocol,
        companyId: String,
        defaultUseCase: ServiceStopTypeUseCase = .recurringRoute,
        onSelect: @escaping (RouteRecurringStopSelection) -> Void
    ) {
        self.dataService = dataService
        self.companyId = companyId
        self.defaultUseCase = defaultUseCase
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            Form {
                
                Section {
                    pickerButtonRow(
                        title: "Customer",
                        value: location.id == "" ? "Select Location" : "\(customer.firstName) \(customer.lastName) \(location.address.streetAddress)",
                        systemImage: "person.crop.circle",
                        isSelected: location.id != ""
                    ) {
                        showLocationPicker.toggle()
                    }
                    .sheet(isPresented: $showLocationPicker) {
                        CustomerAndLocationPicker(
                            dataService: dataService,
                            customer: $customer,
                            location: $location
                        )
                    }
                } header: {
                    Text("Customer / Location")
                }
                Section {
                    CompanyServiceStopTypePickerView(
                        companyId: companyId,
                        dataService: dataService,
                        selectedType: $selectedCompanyServiceStopType,
                        useCase: defaultUseCase,
                        title: "Service Stop Type",
                        subtitle: "Choose the type for this specific recurring stop."
                    )
                } header: {
                    Text("Stop Type")
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        Label("Add To Route", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(customer.id.isEmpty || location.id.isEmpty)
                }
            }
            .navigationTitle("Add Route Stop")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await presentInitialLocationPickerIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Route") {
                        submit()
                    }
                }
            }
        }
    }

    private func submit() {
        print("  [RouteRecurringStopPickerView][submit] start")
        let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: selectedCompanyServiceStopType,
            useCase: defaultUseCase
        )
        print("  [RouteRecurringStopPickerView][submit] typeFields")

        let selection = RouteRecurringStopSelection(
            customer: customer,
            location: location,
            serviceStopType: selectedCompanyServiceStopType,
            typeFields: typeFields
        )
        
        print("  [RouteRecurringStopPickerView][submit] selection")
        onSelect(selection)
        dismiss()
    }

    @MainActor
    private func presentInitialLocationPickerIfNeeded() async {
        guard !hasPresentedInitialLocationPicker, location.id.isEmpty else { return }

        hasPresentedInitialLocationPicker = true
        try? await Task.sleep(nanoseconds: 350_000_000)

        guard !Task.isCancelled, location.id.isEmpty else { return }
        showLocationPicker = true
    }
}
extension RouteRecurringStopPickerView {
    func pickerButtonRow(
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
}
