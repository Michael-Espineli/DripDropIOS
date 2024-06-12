//
//  CompanyUserViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation
@MainActor
final class CompanyUserViewModel:ObservableObject{
    @Published var companyUser : CompanyUser? = nil
    @Published var rateSheet : RateSheet? = nil

    @Published var companyUsers: [CompanyUser] = []
    @Published var rateSheetList: [RateSheet] = []

    //Create
    func addCompanyUser(companyId:String,companyUser:CompanyUser) async throws{
        try await CompanyUserManager.shared.addCompanyUser(companyId: companyId, companyUser: companyUser)
        }
    func addCompanyUserRateSheet(companyId:String,companyUserId:String,rateSheet:RateSheet) async throws{
        try await CompanyUserManager.shared.addNewRateSheet(companyId: companyId, companyUserId: companyUserId, rateSheet: rateSheet)
        }
    //Read

    func getCompanyUserById(companyId:String,companyUserId:String) async throws{
        self.companyUser = try await CompanyUserManager.shared.getCompanyUserById(companyId: companyId, companyUserId: companyUserId)
    }
    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws{
        self.companyUser = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: companyId, userId: userId)
    }
    func getAllCompanyUsers(companyId:String) async throws{
        self.companyUsers = try await CompanyUserManager.shared.getAllCompanyUsers(companyId: companyId)
    }
    func getAllRateSheetByCompanyUserId(companyId: String, companyUserId: String) async throws {
        self.rateSheetList = try await CompanyUserManager.shared.getAllRateSheetByCompanyUserId(companyId: companyId, companyUserId: companyUserId)
    }
    func getAllCompanyUsersByStatus(companyId:String,status:String) async throws {
        self.companyUsers = try await CompanyUserManager.shared.getAllCompanyUsersByStatus(companyId: companyId, status: status)
    }
    //Update
    //Delete
}
