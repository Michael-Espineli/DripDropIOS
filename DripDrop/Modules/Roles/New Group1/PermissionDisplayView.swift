//
//  PermissionDisplayView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct PermissionDisplayView: View {
    var permission:PermissionModel
    @Binding var listOfPermissions:[String]
    @State var selected:Bool = false
    @State var loading:Bool = true

    var body: some View {
        VStack{
            HStack{
                Text(permission.id)
                Text(permission.name)
                Spacer()
                Image(systemName: selected ? "checkmark.square":"square")
                    .padding(5)
                    .background(selected ? Color.green : Color.clear)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
            }
            .padding(8)
            if permission.id == "2" {
                Text("List of Users To Manage?")
            }
        }
        .onAppear(perform: {
            if listOfPermissions.contains(permission.id) {
                selected = true
            } else {
                selected = false

            }
        })
        .onChange(of: selected, perform: { select in
            if !loading {
                if select {
                    listOfPermissions.append(permission.id)
                    
                } else {
                    listOfPermissions.removeAll(where: {$0 == permission.id})
                }
                print(listOfPermissions)
            } else {
                loading = false
            }
        })
    }
}
