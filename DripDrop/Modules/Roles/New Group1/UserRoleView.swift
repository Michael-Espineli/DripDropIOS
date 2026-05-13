//
//  UserRoleView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct UserRoleView: View {
    @StateObject var roleVM = RoleViewModel()
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @State var showSheet:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView{
                    ForEach(roleVM.roleList){ role in
                        HStack{
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.userRoleDetailView(dataService: dataService, role: role), label: {
                                    
                                    HStack{
                                        Text(role.name)
                                        Text("\(String(role.permissionIdList.count))")
                                        Spacer()
                                        Text("Detail")
                                    }
                                    .padding(8)
                                    .modifier(ListButtonModifier())
                                })
                            } else {
                                HStack{
                                    Button(action: {
                                        masterDataManager.selectedRole = role
                                    }, label: {
                                        Text(role.name)
                                        Text("\(String(role.permissionIdList.count))")
                                        Spacer()
                                        Text("Detail")
                                    })
                                }
                                .padding(8)
                                .modifier(ListButtonModifier())
                            }
                        }
                        .padding(.horizontal,8)
                        .padding(.vertical,3)
                        Divider()
                    }
                }
            }
        }
        .navigationTitle("User Roles")
        .sheet(isPresented: $showSheet, content: {
            CreateCompanyRoles()
        })
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await roleVM.getAllCompanyRoles(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
        .toolbar{
            ToolbarItem(content: {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("862") {
                        Button(action: {
                            showSheet.toggle()
                        }, label: {
                            Text("Create")
                        })
                        
                    }
                }
            })
        }
    }
}

