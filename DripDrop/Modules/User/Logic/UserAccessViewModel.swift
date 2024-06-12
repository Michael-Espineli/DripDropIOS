//
//  UserAccessViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//


import Foundation
@MainActor
final class UserAccessViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                              Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var userAccess: UserAccess? = nil
    @Published private(set) var allAvailableAccess: [UserAccess] = []
    @Published private(set) var companies: [Company] = []

    //---------------------
        //CREATE
    //---------------------
    func uploadUserAccess(userId:String,companyId:String,userAccess:UserAccess)async throws{
        try await UserAccessManager.shared.uploadUserAccess(userId: userId, companyId: companyId, userAccess: userAccess)
    }
    //---------------------
        //READ
    //---------------------
    func getCompaniesFromAccess(accessList:[UserAccess]) async throws {
        var companies: [Company] = []
        for access in accessList {
            companies.append(try await CompanyManager.shared.getCompany(companyId: access.companyId))
        }
        self.companies = companies
    }
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    func getAllUserAvailableCompanies(userId:String) async throws{
        self.allAvailableAccess = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: userId)
    }
    func getUserAccessCompanies(userId:String,companyId:String) async throws{
        
        self.userAccess = try await UserAccessManager.shared.getUserAccessCompanies(userId: userId,companyId: companyId)

    }
    //---------------------
        //UPDATE
    //---------------------

    //---------------------
        //DELETE
    //---------------------
}
