//
//  CustomerAndLocationPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import SwiftUI

@MainActor
final class CustomerAndLocationPickerModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var displayCustomer: [Customer] = []
    @Published private(set) var customers: [Customer] = []
    @Published var searchTerm: String = ""
    @Published private(set) var serviceLocations: [ServiceLocation] = []

    func onLoad(companyId: String) {
        Task {
            do {
                let allCustomers = try await dataService.getAllCustomers(companyId: companyId)
                self.customers = allCustomers
                    .filter { $0.active }
                    .sorted { customerSortValue($0) < customerSortValue($1) }
                print("[CustomerAndLocationPickerModel][onLoad] customers count: \(self.customers.count)")
                self.displayCustomer = customers
            } catch {
                print(error)
            }
        }
    }

    func filterCustomerList() {
        if searchTerm != "" {
            var filteredListOfCustomers: [Customer] = []

            for customer in customers {
                let phone = customer.phoneNumber ?? "0"
                let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
                let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
                let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
                let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
                let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
                let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")

                let address = customer.billingAddress.streetAddress + " " + customer.billingAddress.city + " " + customer.billingAddress.state + " " + customer.billingAddress.zip
                let company: String = customer.company ?? "0"
                let fullName = customer.firstName + " " + customer.lastName

                if customer.firstName.lowercased().contains(searchTerm.lowercased()) ||
                    customer.lastName.lowercased().contains(searchTerm.lowercased()) ||
                    replacedPhone6.lowercased().contains(searchTerm.lowercased()) ||
                    customer.email.lowercased().contains(searchTerm.lowercased()) ||
                    address.lowercased().contains(searchTerm.lowercased()) ||
                    company.lowercased().contains(searchTerm.lowercased()) ||
                    fullName.lowercased().contains(searchTerm.lowercased()) {
                    filteredListOfCustomers.append(customer)
                }
            }

            self.displayCustomer = filteredListOfCustomers
        } else {
            self.displayCustomer = customers
        }
    }

    func getAllCustomerServiceLocationsById(
        companyId: String,
        customerId: String
    ) async throws {
        self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: customerId
        )
        self.serviceLocations = self.serviceLocations.sorted {
            locationSortValue($0) < locationSortValue($1)
        }
        print("[CustomerAndLocationPickerModel][getAllCustomerServiceLocationsById] serviceLocations: \(self.serviceLocations.count)")
    }

    private func customerSortValue(_ customer: Customer) -> String {
        let displayName = customer.displayAsCompany
            ? (customer.company ?? "\(customer.firstName) \(customer.lastName)")
            : "\(customer.lastName) \(customer.firstName)"

        return displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func locationSortValue(_ location: ServiceLocation) -> String {
        let displayName = location.nickName.isEmpty ? location.address.streetAddress : location.nickName
        return displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct CustomerAndLocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var VM: CustomerAndLocationPickerModel

    @Binding var customer: Customer
    @Binding var location: ServiceLocation

    init(
        dataService: any ProductionDataServiceProtocol,
        customer: Binding<Customer>,
        location: Binding<ServiceLocation>
    ) {
        _VM = StateObject(wrappedValue: CustomerAndLocationPickerModel(dataService: dataService))
        self._customer = customer
        self._location = location
    }

    @State var search: String = ""
    @State var customerSearch: String = ""

    @State var customers: [Customer] = []
    @State var locations: [ServiceLocation] = []

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if customer.id == "" {
                        customerHeaderCard
                        searchBar
                        customerList
                    } else {
                        locationHeaderCard
                        searchBar
                        locationList
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    VM.onLoad(companyId: company.id)
                }
            } catch {
                print("[CustomerAndLocationPicker][task]Error \(error)")
            }
        }
        .onChange(of: VM.searchTerm) { _ in
            VM.filterCustomerList()
        }
        .onChange(of: customer) { customer in
            if customer.id != "" {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await VM.getAllCustomerServiceLocationsById(
                                companyId: company.id,
                                customerId: customer.id
                            )

                            if VM.serviceLocations.count == 1 {
                                location = VM.serviceLocations.first!
                                dismiss()
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

extension CustomerAndLocationPicker {

    var customerHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Select Customer")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Choose a customer first, then select the service location.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                Label("\(VM.displayCustomer.count) Customers", systemImage: "person.2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var locationHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Button {
                    customer.id = ""
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Select Location")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(customerDisplayName(customer))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
                Label("\(VM.serviceLocations.count) Locations", systemImage: "mappin.and.ellipse")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.secondary)

            TextField(customer.id == "" ? "Search customers..." : "Search locations...", text: $VM.searchTerm)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !VM.searchTerm.isEmpty {
                Button {
                    VM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var customerList: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Customers", systemImage: "person.crop.circle")

            if VM.displayCustomer.isEmpty {
                emptyState(
                    title: "No customers found.",
                    message: "Try adjusting your search.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.displayCustomer) { datum in
                        customerRow(datum)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var locationList: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Service Locations", systemImage: "mappin.and.ellipse")

            if VM.serviceLocations.isEmpty {
                emptyState(
                    title: "No service locations found.",
                    message: "This customer does not have any service locations available.",
                    systemImage: "mappin.slash"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.serviceLocations) { datum in
                        locationRow(datum)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func customerRow(_ datum: Customer) -> some View {
        Button {
            customer = datum

            #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.06), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(customerDisplayName(datum))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(customerSubtitle(datum))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    func locationRow(_ datum: ServiceLocation) -> some View {
        Button {
            location = datum

            #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif

            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(Color.primary.opacity(0.06), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(datum.nickName.isEmpty ? datum.address.streetAddress : datum.nickName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(locationSubtitle(datum))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    func customerDisplayName(_ datum: Customer) -> String {
        if datum.displayAsCompany {
            return datum.company ?? "\(datum.firstName) \(datum.lastName)"
        }

        return "\(datum.firstName) \(datum.lastName)"
    }

    func customerSubtitle(_ datum: Customer) -> String {
        let address = datum.billingAddress.streetAddress

        if !address.isEmpty {
            return address
        }

        if !datum.email.isEmpty {
            return datum.email
        }

        return "Active Customer"
    }

    func locationSubtitle(_ datum: ServiceLocation) -> String {
        let address = datum.address

        return "\(address.streetAddress) \(address.city), \(address.state) \(address.zip)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
