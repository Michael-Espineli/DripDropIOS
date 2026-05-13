//
//  MasterRoleManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/8/26.
//

import Foundation
@MainActor
final class MasterRoleManager:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published var companyUserList:[CompanyUser] = []
    @Published var userAccessList:[UserAccess] = []
    
    @Published var company:Company? = nil
    @Published var companyUser:CompanyUser? = nil
    @Published var userAccess:UserAccess? = nil
    
    @Published var role:Role? = nil
    @Published var isLoading:Bool = false

    func start(companyId:String?,userId:String?){
        guard let userId, let companyId else {return}
        //Get User Access
        print("  [MasterRoleManager][start]")
        dataService.addCurrentUserAccessListener(companyId: companyId, userId: userId) { [weak self] userAccess in
            self?.userAccessList = userAccess
            self?.compareOptions(companyId: companyId)
        }
        print("  [MasterRoleManager][start]")
        //Get Company Access
        dataService.addCurrentCompanyUserListener(companyId: companyId, userId: userId) { [weak self] userAccess in
            self?.companyUserList = userAccess
            self?.compareOptions(companyId: companyId)
        }

    }
    func stop(){
        dataService.removeUserAccessListener()
        dataService.removeCompanyUserListener()
        dataService.removeRoleListener()
    }
    private func compareOptions(companyId:String){
        if !userAccessList.isEmpty && !companyUserList.isEmpty{
            let accessRoleIds = Set(userAccessList.map { $0.roleId })

            let matches = companyUserList
                .map { $0.roleId }
                .filter { accessRoleIds.contains($0) }
                
            if let firstMatch = matches.first , let companyUserAccess = companyUserList.first(where: {$0.roleId == firstMatch}){
                recompute(companyId: companyId, roleId: firstMatch)
                self.companyUser = companyUserAccess
            }
        }
        //compare companyUser and userAccess
    }
    private func recompute(companyId:String,roleId:String){
        
        dataService.addRoleListener(companyId: companyId, roleId: roleId) { [weak self] role in
            self?.role = role
        }
        //compare companyUser and userAccess
    }
}
