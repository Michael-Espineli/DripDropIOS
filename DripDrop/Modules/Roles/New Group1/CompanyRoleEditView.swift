//
//  CompanyRoleEditView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct CompanyRoleEditView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    
    var role:Role
    var companyId:String
    @State var selectedPermissionList:[String] = []
    @State var name:String = ""
    @State var description:String = ""
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    
    var body: some View {
        ScrollView(showsIndicators:false){
            VStack{
                HStack{
                    Button(action: {
                    dismiss()
                    }, label: {
                      Text("Cancel")
                    })
                    Spacer()
                    Button(action: {
                        Task{
                            let pushdescription = description
                            let pushName = name
                            let pushSelectedPermissionList = selectedPermissionList
                            print(pushSelectedPermissionList)
                            do {
                                try await roleVM.updateRole(companyId: companyId, role: Role(id: role.id,
                                                                                             name: pushName,
                                                                                             permissionIdList: pushSelectedPermissionList,
                                                                                             listOfUserIdsToManage: [],
                                                                                             color: role.color,
                                                                                             description: pushdescription))
                                
                                alertMessage = "Successfully Edited"
                                print(alertMessage)
                                showAlert = true
                                dismiss()
                            } catch {
                                alertMessage = "Failed to Edit"
                                print(alertMessage)
                                showAlert = true
                               
                            }
                        }
                    }, label: {
                      Text("Save")
                    })
                }
                .padding()
                HStack{
                    Text(role.name)
                }
                TextField(
                    "Name",
                    text: $name
                )
                .padding(5)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(5)
                
                TextField(
                    "Description",
                    text: $description
                )
                .padding(5)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(5)
                
                VStack{
                    Text("Permissions")
                        .font(.title)
                    ForEach(permissionVM.standrdPermissions){ permission in
                        PermissionSelectorView(permission: permission, listOfPermissions: $selectedPermissionList)
                    }
                }
                
            }
        }
        .onAppear(perform: {
            selectedPermissionList = role.permissionIdList
            name = role.name
            description = role.description
        })
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }    }
}
