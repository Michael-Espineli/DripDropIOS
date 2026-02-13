import SwiftUI
import FirebaseAuth

struct BrowseCompaniesView: View {
    @StateObject private var vm = BrowseCompaniesViewModel()
    @State private var userId: String? = Auth.auth().currentUser?.uid

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Find Your Next Opportunity")
            .onAppear { vm.onAppear(userId: userId) }
            .onDisappear { vm.onDisappear() }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Find Your Next Opportunity")
                .font(.largeTitle).bold()
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
                    .shimmering() // If you have a shimmering modifier; otherwise remove
            }
        }
    }

    private var companiesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(vm.filteredCompanies) { company in
                CompanyCard(
                    company: company,
                    isSaved: vm.savedCompanyIds.contains(company.id),
                    onSaveTapped: {
                        vm.toggleSaveCompany(userId: userId, company: company)
                    }
                )
                .onTapGesture {
                    // Navigate to detail
                    // Push to your CompanyDetailView
                    // Example:
                    // navigationPath.append(NavigationDestination.company(company.id))
                }
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
                HStack(spacing: 12) {
                    avatar
                    VStack(alignment: .leading, spacing: 4) {
                        Text(company.name)
                            .font(.headline)
                        Text(company.services.first ?? "No industry specified")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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