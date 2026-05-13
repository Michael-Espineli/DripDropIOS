//
//  BrowseCompaniesView.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import SwiftUI
import FirebaseAuth

struct BrowseCompaniesView: View {
    init( dataService:any ProductionDataServiceProtocol){
        _vm = StateObject(wrappedValue: BrowseCompaniesViewModel(dataService: dataService))

    }
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var vm : BrowseCompaniesViewModel
    
    @State private var showingFilters: Bool = false
    @State private var selectedService: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                searchBarCard

                if vm.loading {
                    skeletonGrid
                } else {
                    companiesGrid
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .onAppear { vm.onAppear(userId: masterDataManager.user?.id) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheet(selectedService: $selectedService, availableServices: Array(Set(vm.companies.flatMap { $0.services })).sorted()) {
                showingFilters = false
            } applyAction: {
                showingFilters = false
            }
            .presentationDetents([.medium, .large])
        }
        .onDisappear { vm.onDisappear() }
    }
    private var header: some View {
        VStack(spacing: 6) {
            Text("Find Your Next Opportunity")
                .font(.title).bold()
                .foregroundStyle(.primary)
            Text("Search and connect with companies that match your criteria.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchBarCard: some View {
        VStack {
            HStack {
                TextField("Company name...", text: $vm.searchTerm)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 2, y: 1)
        }
    }

    private var skeletonGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 120)
                    .redacted(reason: .placeholder)
            }
        }
    }

    private var companiesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(vm.filteredCompanies.filter { selectedService.isEmpty || $0.services.contains(selectedService) }) { company in
                NavigationLink(value: Route.companyPublicProfile(company: company, dataService: dataService), label: {
                    CompanyCard(
                        company: company,
                        isSaved: vm.savedCompanyIds.contains(company.id),
                        onSaveTapped: {
                            Task {
                                if vm.savedCompanyIds.contains(company.id) {
                                    if let userId = masterDataManager.user?.id {
                                        do {
                                            try await vm.deleteSavedCompany(userId: userId, businessId: company.id)
                                        } catch {
                                            print("Failed to unsave: \(error)")
                                        }
                                    }
                                } else {
                                    vm.toggleSaveCompany(userId: masterDataManager.user?.id, company: company)
                                }
                            }
                        }
                    )
                })
            }
        }
    }
}

private struct CompanyCard: View {
    let company: Company
    let isSaved: Bool
    let onSaveTapped: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack{
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(company.name)
                                .font(.headline)
                        }
                        
                        Spacer()
                        Button(action: onSaveTapped) {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .imageScale(.large)
                                .foregroundStyle(isSaved ? .blue : .gray)
                                .padding(6)
                                .background(
                                    Circle().fill(Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 12) {
                        avatar
                        Text(company.services.first ?? "No industry specified")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.1))
            if let urlString = company.photoUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "building.2.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                            .foregroundStyle(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "building.2.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundStyle(.gray)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }
}
private struct FilterSheet: View {
    @Binding var selectedService: String
    let availableServices: [String]
    let cancelAction: () -> Void
    let applyAction: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Service")) {
                    Picker("Service", selection: $selectedService) {
                        Text("Any").tag("")
                        ForEach(availableServices, id: \.self) { svc in
                            Text(svc).tag(svc)
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancelAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply", action: applyAction)
                }
            }
        }
    }
}

extension BrowseCompaniesViewModel {
    func deleteSavedCompany(userId: String, businessId: String) async throws {
        try await dataService.deleteSavedCompany(userId: userId, businessId: businessId)
        self.savedCompanyIds.remove(businessId)
    }
}

