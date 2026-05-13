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
        
        PermissionModel(id: "0", name: "Operations", description: "Can See the Operations Tabs", category: "Operations"),
        PermissionModel(id: "10", name: "Customer", description: "", category: "Operations"),
        PermissionModel(id: "12", name: "Create Customer", description: "", category: "Operations"),
        PermissionModel(id: "14", name: "Update Customer", description: "", category: "Operations"),
        PermissionModel(id: "16", name: "Delete Customer", description: "", category: "Operations"),
        PermissionModel(id: "20", name: "Jobs", description: "", category: "Operations"),
        PermissionModel(id: "22", name: "Create Jobs", description: "", category: "Operations"),
        PermissionModel(id: "24", name: "Update Jobs", description: "", category: "Operations"),
        PermissionModel(id: "26", name: "Delete Jobs", description: "", category: "Operations"),
        PermissionModel(id: "30", name: "Repair Requests", description: "", category: "Operations"),
        PermissionModel(id: "32", name: "Create Repair Requests", description: "", category: "Operations"),
        PermissionModel(id: "34", name: "Update Repair Requests", description: "", category: "Operations"),
        PermissionModel(id: "36", name: "Delete Repair Requests", description: "", category: "Operations"),
        PermissionModel(id: "40", name: "Service Location", description: "", category: "Operations"),
        PermissionModel(id: "42", name: "Create Service Location", description: "", category: "Operations"),
        PermissionModel(id: "44", name: "Update Service Location", description: "", category: "Operations"),
        PermissionModel(id: "46", name: "Delete Service Location", description: "", category: "Operations"),
        PermissionModel(id: "50", name: "Bodies of Water", description: "", category: "Operations"),
        PermissionModel(id: "52", name: "Create Bodies of Water", description: "", category: "Operations"),
        PermissionModel(id: "54", name: "Update Bodies of Water", description: "", category: "Operations"),
        PermissionModel(id: "56", name: "Delete Bodies of Water", description: "", category: "Operations"),
        PermissionModel(id: "60", name: "Equipment", description: "", category: "Operations"),
        PermissionModel(id: "62", name: "Create Equipment", description: "", category: "Operations"),
        PermissionModel(id: "64", name: "Update Equipment", description: "", category: "Operations"),
        PermissionModel(id: "66", name: "Delete Equipment", description: "", category: "Operations"),

        PermissionModel(id: "200", name: "Management", description: "", category: "Operations"),
        PermissionModel(id: "210", name: "Route Over View", description: "", category: "Management"),
        PermissionModel(id: "220", name: "Live Route Access", description: "", category: "Management"),
        PermissionModel(id: "230", name: "Routes", description: "", category: "Management"),
        PermissionModel(id: "232", name: "Create Routes", description: "", category: "Management"),
        PermissionModel(id: "234", name: "Update Routes", description: "", category: "Management"),
        PermissionModel(id: "236", name: "Delete Routes", description: "", category: "Management"),
        PermissionModel(id: "240", name: "ServiceStops", description: "", category: "Management"),
        PermissionModel(id: "242", name: "Create Service Stops", description: "", category: "Management"),
        PermissionModel(id: "244", name: "Update Service Stops", description: "", category: "Management"),
        PermissionModel(id: "246", name: "Delete Service Stops", description: "", category: "Management"),
        PermissionModel(id: "250", name: "ServiceStops For Others", description: "", category: "Management"),
        PermissionModel(id: "252", name: "Create Service Stops For Others", description: "", category: "Management"),
        PermissionModel(id: "254", name: "Update Service Stops For Others", description: "", category: "Management"),
        PermissionModel(id: "256", name: "Delete Service Stops For Others", description: "", category: "Management"),
        PermissionModel(id: "260", name: "Company Users", description: "", category: "Management"),
        PermissionModel(id: "262", name: "Create Company Users", description: "", category: "Management"),
        PermissionModel(id: "264", name: "Update Company Users", description: "", category: "Management"),
        PermissionModel(id: "266", name: "Delete Company Users", description: "", category: "Management"),
        PermissionModel(id: "280", name: "WorkLogs", description: "", category: "Management"),
        PermissionModel(id: "282", name: "Create Work Logs", description: "", category: "Management"),
        PermissionModel(id: "284", name: "Update Work Logs", description: "", category: "Management"),
        PermissionModel(id: "286", name: "Delete Work Logs", description: "", category: "Management"),
        PermissionModel(id: "290", name: "Fleet", description: "", category: "Management"),
        PermissionModel(id: "292", name: "Create Fleet", description: "", category: "Management"),
        PermissionModel(id: "294", name: "Update Fleet", description: "", category: "Management"),
        PermissionModel(id: "296", name: "Delete Fleet", description: "", category: "Management"),

        PermissionModel(id: "400", name: "Finance", description: "", category: "Finance"),
        PermissionModel(id: "410", name: "Finished Jobs", description: "", category: "Finance"),
        PermissionModel(id: "412", name: "Create Finished Jobs", description: "", category: "Finance"),
        PermissionModel(id: "414", name: "Update Finished Jobs", description: "", category: "Finance"),
        PermissionModel(id: "416", name: "Delete Finished Jobs", description: "", category: "Finance"),
        
        PermissionModel(id: "600", name: "Marketing", description: "", category: "Marketing"),
        PermissionModel(id: "610", name: "Leads", description: "", category: "Marketing"),
        PermissionModel(id: "612", name: "Respond Leads", description: "", category: "Marketing"),
        PermissionModel(id: "614", name: "Update Leads", description: "", category: "Marketing"),
        PermissionModel(id: "616", name: "Delete Leads", description: "", category: "Marketing"),
        PermissionModel(id: "620", name: "Estiamtes", description: "", category: "Marketing"),
        PermissionModel(id: "622", name: "Respond Estiamtes", description: "", category: "Marketing"),
        PermissionModel(id: "624", name: "Update Estiamtes", description: "", category: "Marketing"),
        PermissionModel(id: "626", name: "Delete Estiamtes", description: "", category: "Marketing"),

        PermissionModel(id: "800", name: "Settings", description: "", category: "Settings"),
        PermissionModel(id: "810", name: "Company Information", description: "", category: "Settings"),
        PermissionModel(id: "812", name: "Create Company Information", description: "", category: "Settings"),
        PermissionModel(id: "814", name: "Update Company Information", description: "", category: "Settings"),
        PermissionModel(id: "816", name: "Delete Company Information", description: "", category: "Settings"),
        PermissionModel(id: "820", name: "Task Groups", description: "", category: "Settings"),
        PermissionModel(id: "822", name: "Create Task Groups", description: "", category: "Settings"),
        PermissionModel(id: "824", name: "Update Task Groups", description: "", category: "Settings"),
        PermissionModel(id: "826", name: "Delete Task Groups", description: "", category: "Settings"),
        PermissionModel(id: "830", name: "Email Configuration", description: "", category: "Settings"),
        PermissionModel(id: "832", name: "Create Email Configuration", description: "", category: "Settings"),
        PermissionModel(id: "834", name: "Update Email Configuration", description: "", category: "Settings"),
        PermissionModel(id: "836", name: "Delete Email Configuration", description: "", category: "Settings"),
        PermissionModel(id: "840", name: "Readings and Dosages", description: "", category: "Settings"),
        PermissionModel(id: "842", name: "Create Readings and Dosages", description: "", category: "Settings"),
        PermissionModel(id: "844", name: "Update Readings and Dosages", description: "", category: "Settings"),
        PermissionModel(id: "846", name: "Delete Readings and Dosages", description: "", category: "Settings"),
        PermissionModel(id: "850", name: "Database Items", description: "", category: "Settings"),
        PermissionModel(id: "852", name: "Create Database Items", description: "", category: "Settings"),
        PermissionModel(id: "854", name: "Update Database Items", description: "", category: "Settings"),
        PermissionModel(id: "856", name: "Delete Database Items", description: "", category: "Settings"),
        PermissionModel(id: "860", name: "User Roles", description: "", category: "Settings"),
        PermissionModel(id: "862", name: "Create User Roles", description: "", category: "Settings"),
        PermissionModel(id: "864", name: "Update User Roles", description: "", category: "Settings"),
        PermissionModel(id: "866", name: "Delete User Roles", description: "", category: "Settings"),
        PermissionModel(id: "870", name: "Reports", description: "", category: "Settings"),
        PermissionModel(id: "872", name: "Create Reports", description: "", category: "Settings"),
        PermissionModel(id: "874", name: "Update Reports", description: "", category: "Settings"),
        PermissionModel(id: "876", name: "Delete Reports", description: "", category: "Settings"),
        PermissionModel(id: "880", name: "Terms Templates", description: "", category: "Settings"),
        PermissionModel(id: "882", name: "Create Terms Templates", description: "", category: "Settings"),
        PermissionModel(id: "884", name: "Update Terms Templates", description: "", category: "Settings"),
        PermissionModel(id: "886", name: "Delete Terms Templates", description: "", category: "Settings"),
        PermissionModel(id: "890", name: "Manage Subscriptions", description: "", category: "Settings"),
        PermissionModel(id: "892", name: "Create Manage Subscriptions", description: "", category: "Settings"),
        PermissionModel(id: "894", name: "Update Manage Subscriptions", description: "", category: "Settings"),
        PermissionModel(id: "896", name: "Delete Manage Subscriptions", description: "", category: "Settings"),
    ]
    let permissionIds: [String] = [
        "0","10","12","14","16","20","22","24","26","30","32","34","36",
        "40","42","44","46","50","52","54","56","60","62","64","66",
        "200","210","220","230","232","234","236","240","242","244","246",
        "250","252","254","256","260","262","264","266","280","282","284","286",
        "290","292","294","296",
        "400","410","412","414","416",
        "600","610","612","614","616","620","622","624","626",
        "800","810","812","814","816","820","822","824","826","830","832","834","836",
        "840","842","844","846","850","852","854","856","860","862","864","866",
        "870","872","874","876","880","882","884","886",
        "890","892","894","896"
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
    let oldPermission: [PermissionModel] = [
        PermissionModel(
            id: "1",
            name: "add user roles",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "2",
            name: "manage user permissions",
            description: "",
            category: "User"
        ),
        PermissionModel(
            id: "3",
            name: "add customers",
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
            name: "ADD SERVICE STOPS FOR OTHERS",
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
            name: "VIEW SETTINGS",
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
            name: "MANAGE USER ROLES",
            description: "",
            category: "Administration"
        ),
        PermissionModel(
            id: "17",
            name: "MANAGE COMPANY SUBSCRIPTIONS",
            description: "",
            category: "Administration"
        ),
        PermissionModel(
            id: "18",
            name: "View Customers",
            description: "",
            category: "Operations"
        ),

    ]

}
