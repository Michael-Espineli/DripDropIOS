import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class BrowseCompaniesViewModel: ObservableObject {
    @Published var companies: [Company] = []
    @Published var savedCompanyIds: Set<String> = []
    @Published var loading: Bool = true
    @Published var searchTerm: String = ""

    private let repo = CompanyRepository()
    private var savedListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    var filteredCompanies: [Company] {
        guard !searchTerm.isEmpty else { return companies }
        return companies.filter { $0.name.lowercased().contains(searchTerm.lowercased()) }
    }

    func onAppear(userId: String?) {
        Task {
            await loadCompanies()
        }
        setupSavedListener(userId: userId)
    }

    func onDisappear() {
        savedListener?.remove()
        savedListener = nil
    }

    func loadCompanies() async {
        loading = true
        do {
            let list = try await repo.fetchCompanies()
            self.companies = list
        } catch {
            print("Error fetching companies: \(error)")
        }
        loading = false
    }

    func setupSavedListener(userId: String?) {
        savedListener?.remove()
        savedListener = nil
        guard let uid = userId else { return }
        savedListener = repo.listenSavedCompanies(userId: uid) { [weak self] ids in
            Task { @MainActor in
                self?.savedCompanyIds = ids
            }
        }
    }

    func toggleSaveCompany(userId: String?, company: Company) {
        guard let uid = userId else { return }
        if savedCompanyIds.contains(company.id) {
            // No delete path here, same as your React behavior
            print("Company already saved")
            return
        }
        Task {
            do {
                try await repo.saveCompany(userId: uid, company: company)
            } catch {
                print("Error saving company: \(error)")
            }
        }
    }
}