//
//  InviteNewTechView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct InviteNewTechView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss
    //VMS
    @StateObject var inviteVM = InviteViewModel()
    @StateObject var roleVM = RoleViewModel()
    //Variables

    @State var firstName:String = ""
    @State var lastName:String = ""
    @State var email:String = ""
    @State var birthday:Date = Date()
    @State var role:String = ""
    @State var inviteCode:String = UUID().uuidString
    @State var selectedRole:Role = Role(id: "", name: "", permissionIdList: [], listOfUserIdsToManage: [], color: "", description: "")
    @State var showAlert:Bool = false
    @State var alertMesage:String = ""
    var body: some View {
        VStack{
            ScrollView{
                VStack{
                    VStack{
                        HStack{
                            Text("First Name")
                            TextField(
                                "First Name",
                                text: $firstName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("Last Name")
                            TextField(
                                "Last Name",
                                text: $lastName
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                        }
                        HStack{
                            Text("Email")
                            TextField(
                                "Email",
                                text: $email
                            )
                            .padding(3)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(3)
                            
                        }
                        Picker("Role", selection: $selectedRole) {
                            ForEach(roleVM.roleList) { role in
                                Text(role.name).tag(role)
                            }
                            
                        }
                        HStack{
                            ForEach(selectedRole.permissionIdList,id:\.self){
                                Text($0)
                            }
                        }
                        HStack{
                            Text("Invite Code")
                            Text("\(inviteCode)")
                                .padding(3)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(3)
                        }
                    }
                    VStack{
                        Button(action: {
                            Task{
                                if let company = masterDataManager.selectedCompany {
                                    do {
                                        try await inviteVM.createInvite(invite:Invite(id: inviteCode,
                                                                                      firstName: firstName,
                                                                                      lastName: lastName,
                                                                                      email: email,
                                                                                      companyName: company.name ?? "",
                                                                                      companyId: company.id,
                                                                                      roleId: selectedRole.id,
                                                                                      roleName: selectedRole.name,
                                                                                      status: "Pending"))
                                        alertMesage = "Successfully Sending Invite"
                                        print(alertMesage)
                                        showAlert = true
                                        dismiss()
                                    } catch FireBasePublish.unableToPublish {
                                        alertMesage = "Invalid Name"
                                        print(alertMesage)
                                        showAlert = true
                                    } catch {
                                        alertMesage = "Unable to Publish"
                                        print(alertMesage)
                                        showAlert = true
                                    }
                                }
                            }
                        }, label: {
                            Text("Invite")
                        })
                    }
                }
                .padding()

            }
        }
        .alert(alertMesage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            do {
                try await roleVM.getAllCompanyRoles(companyId: masterDataManager.selectedCompany!.id)
                if roleVM.roleList.count == 0 {
                    print("No Roles Found should not happen")
                    dismiss()
                    
                } else {
                    selectedRole = roleVM.roleList.last!
                }
            } catch {
                print("Error")
            }
        }
    }
}

