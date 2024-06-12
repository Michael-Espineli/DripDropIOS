//
//  LandingViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/27/24.
//

import Foundation

@MainActor
final class LandingViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var companyUser: CompanyUser? = nil

    @Published private(set) var listOfCompanies: [Company] = []
    @Published private(set) var company: Company? = nil

    func initalLoad() async throws{
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        let user = try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)
        self.user = user
        guard let user = self.user else {
            throw FireBaseRead.unableToRead
        }
            let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: user.id)
            print("Received List of \(accessList.count) Companies available to Access")
            var listOfCompanies:[Company] = []
            for access in accessList{
                let company = try await CompanyManager.shared.getCompany(companyId: access.id)// access id is company id
                listOfCompanies.append(company)
            }
            self.listOfCompanies = listOfCompanies
            if listOfCompanies.count != 0 {
                self.company = listOfCompanies.first
            }
            guard let company = self.company else {
                throw FireBaseRead.unableToRead
            }
                let companyUser = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: company.id, userId: user.id)
                self.companyUser = companyUser
            
        
    }
}
