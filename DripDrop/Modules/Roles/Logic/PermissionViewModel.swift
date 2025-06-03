//
//  PermissionViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//
//  This will be standard across all Companies and therefor no manager, because no one will be able to change permissions

import Foundation
struct PermissionModel:Identifiable,Codable,Equatable,Hashable{
    var id : String
    var name : String
    var description : String
    var category : String

    init(
        id: String,
        name: String,
        description: String,
        category: String

    ){
        self.id = id
        self.name = name
        self.description = description
        self.category = category

    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"
            case description = "description"
            case category = "category"

        }
}
@MainActor
final class PermissionViewModel:ObservableObject{
    @Published private(set) var permission: PermissionModel? = nil

    @Published private(set) var permissionList: [PermissionModel] = []
    @Published private(set) var standrdPermissions: [PermissionModel] = [
        PermissionModel(
            id: "1",
            name: "ADD USER ROLES",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "2",
            name: "MANAGE USER PERMISSIONS",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "3",
            name: "ADD CUSTOMERS",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "16",
            name: "EDIT CUSTOMERS",
            description: "",
            category: "Operations"
        ),
        
        PermissionModel(
            id: "4",
            name: "ADD SERVICE STOPS FOR SELF",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "5",
            name: "ADD SERVICE STOPS FOR Others",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "8",
            name: "FIRE USERS",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "9",
            name: "INVITE USERS",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "10",
            name: "MOVE SERVICE STOPS",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "11",
            name: "VIEW OPERATIONS",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "12",
            name: "VIEW ROUTE",
            description: "",
            category: "Operations"
        ),
        PermissionModel(
            id: "13",
            name: "VIEW FINANCE",
            description: "",
            category: "Finance"
        ),
        PermissionModel(
            id: "6",
            name: "VIEW Settings",
            description: "",
            category: "Inventory"
        ),
        PermissionModel(
            id: "7",
            name: "VIEW MANAGEMENT",
            description: "",
            category: "Administration"
        ),
        PermissionModel(
            id: "14",
            name: "VIEW",
            description: "",
            category: "Administration"
        ),
        PermissionModel(
            id: "15",
            name: "MANAGE USER Roles",
            description: "",
            category: "Administration"
        ),

    ]
    func getPermissionsByIdList(ids:[String]){
        var list:[PermissionModel] = []
        for permission in standrdPermissions {
            let permissionId = permission.id
            if ids.contains(permissionId){
                list.append(permission)
            }
        }
        
        self.permissionList = list
    }
}
