//
//  PermissionDisplayView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct PermissionDisplayView: View {
    var permission:PermissionModel
//    @Binding var listOfPermissions:[String]
    @State var listOfPermissions:[String]
    @State var selected:Bool = false

    var body: some View {
        VStack{
            HStack{
                Text("\(permission.id))")
                Text(permission.name)
                Spacer()
                Image(systemName: selected ? "checkmark.square.fill":"square")
                    .padding(5)
                    .background(selected ? Color.listColor : Color.clear)
                    .foregroundColor(selected ? Color.green : Color.white)
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
//        .onChange(of: selected, perform: { select in
//            if select {
//                listOfPermissions.append(permission.id)
//
//            } else {
//                listOfPermissions.removeAll(where: {$0 == permission.id})
//            }
//            print(listOfPermissions)
//        })
    }
}
