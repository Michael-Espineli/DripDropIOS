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
                    CustomerAndLocationPicker(
                        dataService: dataService,
                        customer: $customer,
                        location: $location
                    )
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submit() {
        let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: selectedCompanyServiceStopType,
            useCase: defaultUseCase
        )

        let selection = RouteRecurringStopSelection(
            customer: customer,
            location: location,
            serviceStopType: selectedCompanyServiceStopType,
            typeFields: typeFields
        )

        onSelect(selection)
        dismiss()
    }
}