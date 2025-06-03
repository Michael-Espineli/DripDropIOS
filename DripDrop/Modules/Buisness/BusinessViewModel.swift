//
//  BuisnessViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class BuisnessViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var findNewBusiness : Bool = false

    @Published private(set) var buisness : AssociatedBusiness? = nil
    @Published private(set) var buisnessList : [AssociatedBusiness] = []
    @Published private(set) var company : Company? = nil
    @Published private(set) var companyList : [Company] = []
    
    @Published private(set) var companyUsers: [CompanyUser] = []

    @Published private(set) var owner : DBUser? = nil

    @Published private(set) var sentContracts : [ReccuringLaborContract] = []
    @Published private(set) var receivedContracts : [ReccuringLaborContract] = []

    //On Load Functions
    func onLoadBusinessDetailView(companyId:String,associatedBusinessCompanyId:String) async throws {
        //AssociatedBusiness Info Gettings the company info
        self.company = try await dataService.getCompany(companyId: associatedBusinessCompanyId)
        if let company = self.company {
            self.owner = try await dataService.getOneUser(userId: company.ownerId)
        }
        //AssociatedBusiness Dealings
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
        self.sentContracts = try await dataService.getLaborContractsByAssociatedBusiness(companyId: companyId, associatedBusinessCompanyId: associatedBusinessCompanyId)
        self.receivedContracts = try await dataService.getLaborContractsByAssociatedBusiness(companyId: companyId, associatedBusinessCompanyId: companyId)
    }
    func onLoadAddNewLaborContractView(companyId:String) async throws {
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
        let companyUserList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        self.companyUsers = companyUserList.filter({$0.workerType == .contractor})
    }
    //Induvidual Functions
    
    //Read
    func getAssociatedBuisnesses(companyId:String) async throws {
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
    }
    func getAssociatedBuisness(companyId:String,buisnessId:String) async throws {
        self.buisness = try await dataService.getAssociatedBusiness(companyId: companyId, businessId: buisnessId)
    }
    func getWorkContracts(companyId:String,associatedBusinessCompanyId:String)async throws {
        self.sentContracts = try await dataService.getLaborContractsByAssociatedBusiness(companyId: companyId, associatedBusinessCompanyId: associatedBusinessCompanyId)
    }
    //Write
    func saveAssociatedBusinessToCompany(companyId:String,business:AssociatedBusiness) async throws {
        try await dataService.saveAssociatedBusinessToCompany(companyId: companyId, business: business)
    }
    func sendNewLaborContractToAssociatedBusiness(companyId:String,laborContract:ReccuringLaborContract,recurringWork:[LaborContractRecurringWork]) async throws {
        try await dataService.addLaborContract(companyId: companyId, laborContract: laborContract)
        try await dataService.addLaborContract(companyId: laborContract.receiverId, laborContract: laborContract)

        for work in recurringWork {
            try await dataService.addLaborContractRecurringWork(companyId: companyId, laborContractId: laborContract.id, laborContractRecurringWork: work)
            try await dataService.addLaborContractRecurringWork(companyId: laborContract.receiverId, laborContractId: laborContract.id, laborContractRecurringWork: work)
        }

        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .receivedLaborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "New Labor Contract",
                description: "From \(laborContract.senderName)",
                date: Date()
            )
        )
    }
    //Search Functions
    func searchForBuisnesses(searchTerm:String) async throws {
        
        self.companyList = try await dataService.getCompanysBySearchTerm(searchTerm: searchTerm)
    }
    //Delete
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws {
//        try await dataService.deleteAssociatedBusinessToCompany(companyId: companyId, businessId: businessId)
    }
}

@MainActor
final class BuisnessListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //LOADING
    @Published var buisnesses:[Company] = []
    func getBuisnesses(companyId:String) async throws {
        //Companies
        //DEVELOPER
        let companyAccess = try await dataService.getAllUserAvailableCompanies(userId: "userId")
        var companies:[Company] = []
        for access in companyAccess {
            if companyId != access.companyId {
                let company = try await dataService.getCompany(companyId: access.companyId)
                companies.append(company)
            }
        }
        self.buisnesses = companies
    }
}
