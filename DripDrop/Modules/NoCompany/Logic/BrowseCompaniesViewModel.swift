//
//  BrowseCompaniesViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//


import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class BrowseCompaniesViewModel: ObservableObject {
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var companies: [Company] = []
    @Published var savedCompanyIds: Set<String> = []
    @Published var savedCompanys: Set<AssociatedBusiness> = []

    @Published var loading: Bool = true
    @Published var searchTerm: String = ""

    private var savedListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    var filteredCompanies: [Company] {
        guard !searchTerm.isEmpty else { return companies }
        return companies.filter { $0.name.lowercased().contains(searchTerm.lowercased()) }
    }

    func onAppear(userId: String?) {
        Task {
            
            await loadCompanies(userId:userId)
        }
        setupSavedListener(userId: userId)
    }

    func onDisappear() {
        savedListener?.remove()
        savedListener = nil
    }

    func loadCompanies(userId: String?) async {
        loading = true
        do {
//            guard let userId else {return}
            self.companies = try await dataService.getAllCompanies()
                .filter { !($0.hideFromBrowse ?? false) }
        } catch {
            print("Error fetching companies: \(error)")
        }
        loading = false
    }

    func setupSavedListener(userId: String?) {
        savedListener?.remove()
        savedListener = nil
        guard let uid = userId else { return }
        dataService.addSavedCompanyListener(userId: uid){ [weak self] companies in
           self?.savedCompanyIds = Set(companies.map { $0.companyId })
       }
        
    }

    func toggleSaveCompany(userId: String?, company: Company) {
        guard let uid = userId else { return }
        Task {
            do {
                if savedCompanyIds.contains(company.id) {
                    print("Company already saved")
                    if let saved:AssociatedBusiness = savedCompanys.first(where: {$0.companyId == company.id}) {
                        try await dataService.deleteSavedCompany(userId: uid, businessId: saved.id)
                    }
                    return
                } else {
                    try await dataService.saveAssociatedBusinessToUser(
                        userId: uid,
                        business: AssociatedBusiness(
                            companyId: company.id,
                            companyName: company.name
                        )
                    )
                }
            } catch {
                print("Error saving company: \(error)")
            }
        }
    }
}
