//
//  PermissionSelectorView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct PermissionSelectorView: View {
    var permission:PermissionModel
    @Binding var listOfPermissions:[String]
    @State var selected:Bool = false
    @State var loading:Bool = true

    var body: some View {
        VStack{
            HStack{
                Text(permission.name)
                Spacer()
                Toggle("", isOn: $selected)
                
            }
            .padding()
            if permission.id == "2" {
                Text("List of Users To Manage?")
            }
        }
        .onAppear(perform: {
            loading = true
            if listOfPermissions.contains(permission.id) {
                selected = true
            } else {
                selected = false

            }
            loading = false
        })
        .onChange(of: selected, perform: { select in
            if !loading {
                if select {
                    listOfPermissions.append(permission.id)
                    print("Added Permission: \(permission.id)")
                    
                } else {
                    listOfPermissions.removeAll(where: {$0 == permission.id})
                    print("Removed Permission: \(permission.id)")

                }
                print(listOfPermissions)
            } else {
                loading = false
            }
        })
    }
}

struct PermissionSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        @State var listOfPermissions:[String] = []

        PermissionSelectorView(permission: PermissionModel(id: "1", name: "ADD USERS", description: "",category: "User"), listOfPermissions: $listOfPermissions)
    }
}
