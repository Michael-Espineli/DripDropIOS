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
    
    init(dataService: any ProductionDataServiceProtocol, role: Role) {
        _VM = StateObject(wrappedValue: CompanyRoleDetailViewModel(dataService: dataService))
        _role = State(wrappedValue: role)
    }

    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var customerViewModel: CustomerViewModel

    @StateObject private var VM: CompanyRoleDetailViewModel

    @State var role: Role
    @State var selectedPermissionList: [String] = []
    @State var name: String = ""
    @State var description: String = ""
    @State var showSheet: Bool = false

    var activeRole: Role {
        VM.updatedRole ?? role
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if VM.isLoading {
                        loadingCard
                    } else {
                        roleInfoCard
                        permissionsCard
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(activeRole.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                if canEditRole {
                    editButton
                }
            }
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            if let currentCompany = masterDataManager.currentCompany {
                VM.getUpdatedRole(companyId: currentCompany.id, roleId: role.id)
            }
        }) {
            CompanyRoleEditView(dataService: dataService, role: role)
        }
        .onAppear {
            print("")
            print("[CompanyRoleDetailView][onAppear] Role: \(role)")

            if let currentCompany = masterDataManager.currentCompany {
                VM.getUpdatedRole(companyId: currentCompany.id, roleId: role.id)
            }

            print("[CompanyRoleDetailView][onAppear] Updated Role: \(VM.updatedRole)")
        }
    }
}
extension CompanyRoleDetailView {

    var canEditRole: Bool {
        if let currentUserRole = masterDataManager.role {
            return currentUserRole.permissionIdList.contains("264")
        }

        return false
    }

    @ViewBuilder
    var editButton: some View {
        if UIDevice.isIPhone {
            NavigationLink(value: Route.editRole(dataService: dataService, role: role)) {
                Text("Edit")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        } else {
            Button {
                showSheet.toggle()
            } label: {
                Text("Edit")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 54, height: 54)

                    Image(systemName: "person.badge.key")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(activeRole.name.isEmpty ? "Role" : activeRole.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(activeRole.description.isEmpty ? "No description provided." : activeRole.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("\(activeRole.permissionIdList.count) Permissions", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                if canEditRole {
                    Label("Editable", systemImage: "square.and.pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Loading role...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var roleInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Role Details", systemImage: "info.circle")

            detailRow(
                title: "Name",
                value: activeRole.name,
                systemImage: "tag"
            )

            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(activeRole.description.isEmpty ? "No description provided." : activeRole.description)
                    .font(.subheadline)
                    .foregroundStyle(activeRole.description.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Permissions", systemImage: "lock.shield")

                Spacer()

                Text("\(activeRole.permissionIdList.count)/\(VM.standrdPermissions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            VStack(spacing: 8) {
                ForEach(VM.standrdPermissions) { permission in
                    PermissionDisplayView(
                        permission: permission,
                        listOfPermissions: activeRole.permissionIdList
                    )
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func detailRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.isEmpty ? "-" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
