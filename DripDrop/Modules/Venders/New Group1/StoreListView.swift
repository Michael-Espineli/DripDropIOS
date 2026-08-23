//
//  StoreListView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/28/23.
//

import SwiftUI

struct StoreListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var viewModel = StoreViewModel()

    @State private var showAddNew = false
    @State private var showSearch = false
    @State private var searchTerm = ""
    @State private var isLoading = false
    @FocusState private var searchField: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                vendorsHeader

                if showSearch {
                    searchBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                vendorsList
            }

            if UIDevice.isIPhone {
                vendorActionDock
            }
        }
        .navigationTitle("Vendors")
        .task {
            await loadStores()
        }
        .sheet(isPresented: $showAddNew, onDismiss: {
            Task { await loadStores() }
        }) {
            AddNewVenderView()
        }
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                        searchField = showSearch
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await loadStores() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        showAddNew.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

extension StoreListView {
    private var vendorsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "storefront.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vendors")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(vendorSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                vendorMetric(title: "Showing", value: "\(filteredStores.count)", tint: .poolBlue)
                vendorMetric(title: "Email", value: "\(viewModel.stores.filter { vendorHasEmail($0) }.count)", tint: .poolGreen)
                vendorMetric(title: "Phone", value: "\(viewModel.stores.filter { vendorHasPhone($0) }.count)", tint: .orange)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var vendorsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 10) {
                if isLoading && viewModel.stores.isEmpty {
                    ProgressView("Loading vendors...")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if filteredStores.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredStores) { store in
                        NavigationLink {
                            StoreDetailView(store: store)
                        } label: {
                            StoreCardView(store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
        }
        .refreshable {
            await loadStores()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search vendors", text: $searchTerm)
                .focused($searchField, equals: true)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchTerm.isEmpty {
                Button {
                    searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "storefront")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(searchTerm.isEmpty ? "No vendors found." : "No matches found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(searchTerm.isEmpty ? "Add a vendor to connect purchasing, billing, and inventory records." : "Try a different vendor, phone, email, or address.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if searchTerm.isEmpty {
                Button {
                    showAddNew.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("New Vendor")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var vendorActionDock: some View {
        VStack(spacing: 10) {
            Button {
                Task { await loadStores() }
            } label: {
                mobileDockIcon(systemName: "arrow.clockwise", tint: .orange, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                showAddNew.toggle()
            } label: {
                mobileDockIcon(systemName: "plus", tint: .poolGreen, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    showSearch.toggle()
                }
                searchField = showSearch
            } label: {
                mobileDockIcon(systemName: "magnifyingglass", tint: .poolBlue, isSelected: showSearch)
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private func vendorMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileDockIcon(systemName: String, tint: Color, isSelected: Bool) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    private var filteredStores: [Vender] {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stores = viewModel.stores.sorted { vendorName($0).localizedCaseInsensitiveCompare(vendorName($1)) == .orderedAscending }

        guard !query.isEmpty else { return stores }

        return stores.filter { store in
            [
                vendorName(store),
                store.email ?? "",
                store.phoneNumber ?? "",
                vendorAddress(store)
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    private var vendorSubtitle: String {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Suppliers, billing contacts, purchase sources, and inventory vendors."
        }

        return "Search results for \"\(searchTerm)\"."
    }

    @MainActor
    private func loadStores() async {
        guard let company = masterDataManager.currentCompany else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await viewModel.getAllStores(companyId: company.id)
        } catch {
            print("Error loading vendors")
            print(error)
        }
    }

    private func vendorName(_ store: Vender) -> String {
        let name = store.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "Unnamed vendor" : name
    }

    private func vendorAddress(_ store: Vender) -> String {
        [
            store.address.streetAddress,
            store.address.city,
            store.address.state,
            store.address.zip
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: ", ")
    }

    private func vendorHasEmail(_ store: Vender) -> Bool {
        !(store.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func vendorHasPhone(_ store: Vender) -> Bool {
        !(store.phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}
