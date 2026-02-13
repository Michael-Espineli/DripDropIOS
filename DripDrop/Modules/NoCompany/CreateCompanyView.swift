//
//  CreateCompanyView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import SwiftUI

struct CreateCompanyView: View {
    @StateObject private var vm = CreateCompanyViewModel()
    @Environment(\.dismiss) private var dismiss

    // If you support navigation to a dashboard, inject a callback or use a NavigationStack
    var onSuccessNavigate: ((String) -> Void)?

    // Services equivalent to your React options
    private let availableServices: [ServiceOption] = [
        .init(value: "pool_cleaning", label: "Pool Cleaning"),
        .init(value: "equipment_repair", label: "Equipment Repair"),
        .init(value: "chemical_balancing", label: "Chemical Balancing"),
        .init(value: "leak_detection", label: "Leak Detection"),
        .init(value: "pool_inspection", label: "Pool Inspection")
    ]

    @State private var showServicesPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Create Your Company")
                    .font(.title)
                    .bold()

                Text("All companies start on our Free plan. Fill in the details below to get set up.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if !vm.errorMessage.isEmpty {
                    Text(vm.errorMessage)
                        .foregroundColor(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Group {
                    TextField("Company Name", text: $vm.name)
                        .textContentType(.organizationName)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                    // Replace AddressAutocompleteView with your component
                    AddressAutocompleteView(selectedAddress: $vm.address)
                        .frame(height: 48)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                    TextField("Phone Number", text: $vm.phoneNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                    HStack(spacing: 8) {
                        TextField("Email Address", text: $vm.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                        Button("Use My Email") {
                            vm.useUserEmail()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 8) {
                        TextField("Website URL (Optional)", text: $vm.websiteURL)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                        Button {
                            Task { await vm.paste(into: \.websiteURL) }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .padding(12)
                        }
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(spacing: 8) {
                        TextField("Yelp URL (Optional)", text: $vm.yelpURL)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

                        Button {
                            Task { await vm.paste(into: \.yelpURL) }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .padding(12)
                        }
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Service Zip Codes (Separate with commas)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        TextField("e.g., 90210, 10001", text: $vm.serviceZipCodes)
                            .keyboardType(.numbersAndPunctuation)
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Services Offered")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Button {
                            showServicesPicker = true
                        } label: {
                            HStack {
                                Text(vm.selectedServices.isEmpty ? "Select services..." :
                                     vm.selectedServices.map { $0.label }.joined(separator: ", "))
                                    .foregroundColor(vm.selectedServices.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        }
                    }
                }

                Button {
                    Task { await vm.submit() }
                } label: {
                    Text(vm.isLoading ? "Creating Company..." : "Create Company")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(vm.isLoading ? Color.blue.opacity(0.6) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(vm.isLoading)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showServicesPicker) {
            MultiSelectServicesView(
                allOptions: availableServices,
                selected: $vm.selectedServices
            )
        }
        .onChange(of: vm.didSucceed) { _, success in
            guard success, let id = vm.recentlySelectedCompanyId else { return }
            // Navigate or dismiss + callback
            onSuccessNavigate?(id)
        }
    }
}

// Replace this with your own address autocomplete implementation
struct AddressAutocompleteView: View {
    @Binding var selectedAddress: Address?

    var body: some View {
        // Placeholder UI
        HStack {
            Text(selectedAddress?.line1 ?? "Company Address")
                .foregroundColor(selectedAddress == nil ? .secondary : .primary)
            Spacer()
            Image(systemName: "mappin.and.ellipse")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Present your real autocomplete UI and assign to selectedAddress
        }
        .padding(.horizontal)
    }
}

struct MultiSelectServicesView: View {
    let allOptions: [ServiceOption]
    @Binding var selected: [ServiceOption]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(allOptions) { option in
                    let isSelected = selected.contains(option)
                    Button {
                        if isSelected {
                            selected.removeAll { $0 == option }
                        } else {
                            selected.append(option)
                        }
                    } label: {
                        HStack {
                            Text(option.label)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Services")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}