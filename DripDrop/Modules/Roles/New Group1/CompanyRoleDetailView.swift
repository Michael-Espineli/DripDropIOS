//
//  CompanyRoleDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct CompanyRoleDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    
    var role:Role
    @State var selectedPermissionList:[String] = []
    @State var name:String = ""
    @State var description:String = ""
    @State var showSheet:Bool = false
    var body: some View {
        ScrollView{
                if let currentUserRole = masterDataManager.role {
                    
                    if currentUserRole.permissionIdList.contains("2") {
                        HStack{
                            Spacer()
                            Button(action: {
                                showSheet.toggle()
                            }, label: {
                                Text("Edit")
                            })
                            .padding()
                            .sheet(isPresented: $showSheet, content: {
                                if let company = masterDataManager.selectedCompany {
                                    CompanyRoleEditView(role: role, companyId: company.id)
                                }
                            })
                        }
                    }
                }
                if let currentUserRole = masterDataManager.role {

                    Text("Name: \(currentUserRole.name)")
                    Text("Description: \(currentUserRole.description)")
                    VStack{
                        Text("Permissions")
                            .font(.title)
                        ForEach(permissionVM.standrdPermissions){ permission in
                            PermissionDisplayView(permission: permission, listOfPermissions: $selectedPermissionList)
                        }
                    }
                }
            }
        
        .onAppear(perform: {
            selectedPermissionList = role.permissionIdList
        })
    }
}
