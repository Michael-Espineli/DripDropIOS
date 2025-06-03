//
//  CompanyRoleLoadingView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/4/24.
//

import SwiftUI

struct CompanyRoleLoadingView: View {
    @EnvironmentObject var dataService : ProductionDataService

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    let roleId:String
    @State var role:Role? = nil
    var body: some View {
        VStack{
            if let role = roleVM.role,let selectedCompany = masterDataManager.currentCompany{
                CompanyRoleEditView(dataService: dataService, role:role)
            }
        }
        .task {
            if let selectedCompany = masterDataManager.currentCompany {
                if roleId != "" {
                    do {
                        try await roleVM.getSpecificRole(companyId: selectedCompany.id, roleId: roleId)
                        
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        }
    }
}

#Preview {
    CompanyRoleLoadingView(roleId: "")
}
