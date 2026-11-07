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

    private var generation = UUID()
    private var currentRoleId: String?

    func start(companyId:String?,userId:String?){
        stop()
        guard let userId, let companyId else { return }
        let token = generation
        dataService.addCurrentUserAccessListener(companyId: companyId, userId: userId) { [weak self] accesses in
            guard let self, self.generation == token else { return }
            self.userAccessList = accesses
            guard let access = accesses.first(where: { $0.hasActiveAccess }), !access.roleId.isEmpty else {
                self.dataService.removeRoleListener()
                self.currentRoleId = nil
                self.userAccess = nil
                self.role = nil
                return
            }
            self.userAccess = access
            guard self.currentRoleId != access.roleId else { return }
            self.dataService.removeRoleListener()
            self.role = nil
            self.currentRoleId = access.roleId
            self.dataService.addRoleListener(companyId: companyId, roleId: access.roleId) { [weak self] role in
                guard let self, self.generation == token, self.currentRoleId == access.roleId else { return }
                self.role = role
            }
        }
    }
    func stop(){
        generation = UUID()
        dataService.removeUserAccessListener()
        dataService.removeRoleListener()
        userAccessList = []
        companyUserList = []
        currentRoleId = nil
        userAccess = nil
        companyUser = nil
        role = nil
    }
}
