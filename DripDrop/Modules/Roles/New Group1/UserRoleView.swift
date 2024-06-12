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
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("1") {
                        HStack{
                            Spacer()
                            Button(action: {
                                showSheet.toggle()
                            }, label: {
                                Text("Create New Role")
                                    .padding(5)
                                    .background(Color.teal)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(5)
                            })
                        }
                        .padding(10)
                    }
                }
                ForEach(roleVM.roleList){ role in
                    HStack{
                        
                        Text(role.name)
                        Text("\(String(role.permissionIdList.count))")
                        Spacer()
                        NavigationLink(destination: {
                            CompanyRoleDetailView(role: role)
                        }, label: {
                               Text("Detail")
                        })
                        .padding(5)
                        .foregroundColor(Color.reverseFontText)
                        .background(Color.accentColor)
                        .cornerRadius(5)
                    }
                    .padding(5)
                }
            }
        }
        .sheet(isPresented: $showSheet, content: {
            CreateCompanyRoles()
        })
        .task {
            if let company = masterDataManager.selectedCompany {
                do {
                    try await roleVM.getAllCompanyRoles(companyId: company.id)
                } catch {
                    print(error)
                }
            }
        }
    }
}

