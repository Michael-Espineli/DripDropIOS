//
//  CompanyAccessViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/24/23.
//

import Foundation
@MainActor
final class CompanyAccessViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                              Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var companyAccess: CompanyAccess? = nil
    @Published private(set) var allAvailableAccess: [CompanyAccess] = []

    //---------------------
        //CREATE
    //---------------------
    func uploadUserAccess(companyId:String,companyAccess:CompanyAccess)async throws{
        try await CompanyAccessManager.shared.uploadCompanyAccess(companyId: companyId, companyAccess: companyAccess)
    }
    //---------------------
        //READ
    //---------------------
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    func getAllUserAvailableCompanies(companyId:String) async throws{
        self.allAvailableAccess = try await CompanyAccessManager.shared.getAllUserAvailableCompanies(companyId: companyId)
    }
    func getUserAccessCompanies(companyId:String,accessId:String) async throws{
        
        self.companyAccess = try await CompanyAccessManager.shared.getUserAccessCompanies(companyId: companyId, userId: accessId)

    }
    //---------------------
        //UPDATE
    //---------------------

    //---------------------
        //DELETE
    //---------------------
}
