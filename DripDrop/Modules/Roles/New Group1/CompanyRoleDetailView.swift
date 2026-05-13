//
//  CompanyRoleDetailView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

@MainActor
final class CompanyRoleDetailViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var updatedRole: Role? = nil
    @Published private(set) var isLoading: Bool = false

    @Published private(set) var permissionList: [PermissionModel] = []
    @Published private(set) var selectedPermissionList:[String] = []

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
    func getUpdatedRole(companyId:String,roleId:String) {
        Task {
            do {
                self.isLoading = true
                self.updatedRole = try await dataService.getSpecificRole(companyId: companyId, roleId: roleId)
                self.isLoading = false
            } catch {
                print("[CompanyRoleDetailViewModel][getUpdatedRole] Error: \(error)")
            }
        }
    }
}
struct CompanyRoleDetailView: View {
    
    init(dataService:any ProductionDataServiceProtocol, role: Role){
        _VM = StateObject(wrappedValue: CompanyRoleDetailViewModel(dataService: dataService))
        _role = State(wrappedValue: role)
    }
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var customerViewModel: CustomerViewModel
    @StateObject private var VM : CompanyRoleDetailViewModel

    
    @State var role:Role
    @State var selectedPermissionList:[String] = []
    @State var name:String = ""
    @State var description:String = ""
    @State var showSheet:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                ScrollView{
                    
                if !VM.isLoading {
                    if let currentUserRole = masterDataManager.role {
                        if currentUserRole.permissionIdList.contains("264") {
                            HStack{
                                Spacer()
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.editRole(dataService: dataService, role: role), label: {
                                        Text("Edit")
                                    })
                                } else {
                                    Button(action: {
                                        showSheet.toggle()
                                    }, label: {
                                    })
                                    .padding()
                                    .sheet(isPresented: $showSheet,onDismiss: {
                                        if let currentCompany = masterDataManager.currentCompany {
                                            VM.getUpdatedRole(companyId: currentCompany.id, roleId: role.id)
                                        }
                                    }, content: {
                                        CompanyRoleEditView(dataService: dataService, role: role)
                                    })
                                }
                            }
                        }
                    }
                        if let updatedRole = VM.updatedRole {
                            Text("\(updatedRole.name)")
                                .font(.headline)
                            Text("UDescription: \(updatedRole.description)")
                            VStack{
                                Text("Permissions")
                                    .font(.title)
                                    ForEach(VM.standrdPermissions){ permission in
                                        PermissionDisplayView(permission: permission, listOfPermissions: updatedRole.permissionIdList)
                                        Divider()
                                    }
                            }
                            
                        } else {
                            Text("\(role.name)")
                                .font(.headline)
                            Text("Description: \(role.description)")
                            VStack{
                                Text("Permissions")
                                    .font(.title)
                                ForEach(VM.standrdPermissions){ permission in
                                    PermissionDisplayView(permission: permission, listOfPermissions: role.permissionIdList)
                                    Rectangle()
                                        .frame(height: 1)
                                }
                            }
                        }
                        
                    } else {
                        ProgressView()
                    }
                }
                .padding(.horizontal,8)
            }
        }
        .onAppear(perform: {
            print("")
            print("[CompanyRoleDetailView][onAppear] Role: \(role)")
            if let currentCompany = masterDataManager.currentCompany {
                VM.getUpdatedRole(companyId: currentCompany.id, roleId: role.id)
            }
            print("[CompanyRoleDetailView][onAppear] Updated Role: \(VM.updatedRole)")
        })
    }
}
