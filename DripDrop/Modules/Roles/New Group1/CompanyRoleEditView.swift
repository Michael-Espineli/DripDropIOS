//
//  CompanyRoleEditView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct CompanyRoleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    @State var role:Role

    init(dataService: any ProductionDataServiceProtocol, role: Role){
        _role = State(wrappedValue: role)
    }
    @State var selectedPermissionList:[String] = []
    @State var name:String = ""
    @State var description:String = ""
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView(showsIndicators:false){
                    HStack{
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("Cancel")
                                .modifier(DismissButtonModifier())
                            
                        })
                        Spacer()
                        Button(action: {
                            Task{
                                if let currentCompany = masterDataManager.currentCompany {
                                    let pushdescription = description
                                    let pushName = name
                                    let pushSelectedPermissionList = selectedPermissionList
                                    print(pushSelectedPermissionList)
                                    do {
                                        try await roleVM.updateRole(companyId: currentCompany.id, role: Role(id: role.id,
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
                            }
                        }, label: {
                            Text("Save")
                                .modifier(SubmitButtonModifier())
                        })
                    }
                    HStack{
                        Text("Name:")
                            .bold()
                        Spacer()
                    }
                    TextField(
                        "Name",
                        text: $name
                    )
                    .padding(5)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(5)
                    HStack{
                        Text("Description:")
                            .bold()
                        Spacer()
                    }
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
                .padding(.horizontal,8)
            }
        }
        .onAppear(perform: {
            selectedPermissionList = role.permissionIdList
            name = role.name
            description = role.description
        })
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
