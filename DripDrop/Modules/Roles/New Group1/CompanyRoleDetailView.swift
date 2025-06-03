//
//  CompanyRoleDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct CompanyRoleDetailView: View {
    @EnvironmentObject var dataService : ProductionDataService

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    
    @State var role:Role
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
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.editRole(dataService: dataService, role: currentUserRole), label: {
                                    Text("Edit")
                                })
                            } else {
                                Button(action: {
                                    showSheet.toggle()
                                }, label: {
                                })
                                .padding()
                                .sheet(isPresented: $showSheet, content: {
                                    if let company = masterDataManager.currentCompany {
                                        CompanyRoleEditView(dataService: dataService, role: role)
                                    }
                                })
                            }
                        }
                    }
                }
                if let currentUserRole = masterDataManager.role {

                    Text("\(currentUserRole.name)")
                        .font(.headline)
                    Text("Description: \(currentUserRole.description)")
                    VStack{
                        Text("Permissions")
                            .font(.title)
                        ForEach(permissionVM.standrdPermissions){ permission in
                            PermissionDisplayView(permission: permission, listOfPermissions: $selectedPermissionList)
                            Rectangle()
                                .frame(height: 1)
                        }
                    }
                }
            }
        
        .onAppear(perform: {
            selectedPermissionList = role.permissionIdList
        })
    }
}
