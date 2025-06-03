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

    @State var showSheet:Bool = false
    var body: some View {
        VStack{
            ScrollView{
                ForEach(roleVM.roleList){ role in
                    HStack{
                        if UIDevice.isIPhone {
                            HStack{
                                NavigationLink(destination: {
                                    CompanyRoleDetailView(role: role)
                                }, label: {
                                    Text(role.name)
                                    Text("\(String(role.permissionIdList.count))")
                                    Spacer()
                                    Text("Detail")
                                })
                            }
                            .padding(8)
                            .modifier(ListButtonModifier())

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
                    if role.permissionIdList.contains("1") {
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

