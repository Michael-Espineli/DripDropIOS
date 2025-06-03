//
//  CreateCompanyRoles.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct CreateCompanyRoles: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()
    
    @State var selectPermission:Bool = false
    @State var name:String = ""
    @State var color:String = ""
    @State var description:String = ""
    @State private var selectedColor = Color.red
    @State var listOfPermissions:[String] = []
    
    var body: some View {
        VStack{
            ScrollView{
                VStack{
                    Text("Info")
                        .font(.title)
                    HStack{
                        Text("Name")
                        
                        TextField(
                            "Name",
                            text: $name
                        )
                    }
                    HStack{
                        Text("Color")
                        
                        ColorPicker("Set the background color", selection: $selectedColor)
                    }
                    HStack{
                        Text("Description")
                        
                        TextField(
                            "Description",
                            text: $description
                        )
                    }
                    
                }
                //DEVELOPER CREATE LIST OF PERMISSIONS TO ADD TO SUBTRACT FROM ROUTE
                VStack{
                    Text("Permissions")
                        .font(.title)
                    ForEach(permissionVM.standrdPermissions){ permission in
                        PermissionSelectorView(permission: permission, listOfPermissions: $listOfPermissions)
                    }
                }
                Button(action: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            do {
                                try await roleVM.createRole(companyId:company.id,
                                                            role:Role(id: UUID().uuidString,
                                                                      name: name,
                                                                      permissionIdList: listOfPermissions,
                                                                      listOfUserIdsToManage: [],
                                                                      color: color,
                                                                      description: description))
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Text("Save")
                        .modifier(SubmitButtonModifier())

                })
            }
        }
    }
}

