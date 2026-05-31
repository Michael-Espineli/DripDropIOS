//
//  CustomerPickerScreen.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/12/24.
//

import SwiftUI

struct CustomerPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var customerVM: CustomerViewModel
    @Binding var customer: Customer

    init(dataService: any ProductionDataServiceProtocol, customer: Binding<Customer>) {
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        self._customer = customer
    }

    @State var search: String = ""
    @State var customers: [Customer] = []

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    searchCard
                    customerList
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await customerVM.filterAndSortSelected(
                        companyId: company.id,
                        filter: .active,
                        sort: .lastNameLow
                    )
                    customers = customerVM.customers
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: search) { term in
            if term == "" {
                Task {
                    do {
                        if let company = masterDataManager.currentCompany {
                            try await customerVM.filterAndSortSelected(
                                companyId: company.id,
                                filter: .active,
                                sort: .lastNameHigh
                            )
                            customers = customerVM.customers
                        }
                    } catch {
                        print("[][] Error: \(error)")
                    }
                }
            } else {
                if let _ = masterDataManager.currentCompany {
                    customerVM.filterCustomerList(
                        filterTerm: term,
                        customers: customerVM.customers
                    )
                    customers = customerVM.filteredCustomers
                    print("Received \(customers.count) Customers")
                }
            }
        }
    }
}

extension CustomerPickerScreen {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Select Customer")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Choose the customer you want to use.")
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
                Label("\(customers.count) Customers", systemImage: "person.2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                if !customer.id.isEmpty {
                    Label(customerDisplayName(customer), systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.poolGreen.opacity(0.12), in: Capsule())
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var searchCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(.secondary)

            TextField("Search customers...", text: $search)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !search.isEmpty {
                Button {
                    search = ""
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

            if customers.isEmpty {
                emptyState(
                    title: "No customers found.",
                    message: "Try adjusting your search.",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(customers) { datum in
                        customerRow(datum)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func customerRow(_ datum: Customer) -> some View {
        let isSelected = datum == customer

        return Button {
            customer = datum

            #if os(iOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif

            dismiss()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.poolGreen.opacity(0.14) : Color.primary.opacity(0.06))
                        .frame(width: 38, height: 38)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "person.crop.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                }

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

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isSelected ? Color.poolGreen : Color.poolGray.opacity(0.44))
            }
            .padding(12)
            .background(
                isSelected ? Color.poolGreen.opacity(0.08) : Color.primary.opacity(0.035),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.poolGreen.opacity(0.22) : Color.primary.opacity(0.06), lineWidth: 1)
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
