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

    @Published private(set) var standrdPermissions: [PermissionModel] = PermissionViewModel().standrdPermissions
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
            return currentUserRole.permissionIdList.contains("864")
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
                Label("\(activePermissionIds.count) Permissions", systemImage: "checklist")
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

                Text("\(activePermissionIds.count)/\(VM.standrdPermissions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if selectedPermissionCategoryGroups.isEmpty {
                emptyState(
                    title: "No permissions assigned.",
                    message: "This role does not currently grant any catalog permissions.",
                    systemImage: "lock.slash"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(selectedPermissionCategoryGroups) { categoryGroup in
                        permissionCategoryDisplay(categoryGroup)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var activePermissionIds: [String] {
        PermissionSelectionHelper.normalizeSelection(
            activeRole.permissionIdList,
            permissions: VM.standrdPermissions
        )
    }

    var permissionCategoryGroups: [PermissionCategoryGroup] {
        PermissionSelectionHelper.categoryGroups(from: VM.standrdPermissions)
    }

    var selectedPermissionCategoryGroups: [PermissionCategoryGroup] {
        permissionCategoryGroups.filter {
            PermissionSelectionHelper.selectedCount(for: $0, selectedIds: activePermissionIds) > 0
        }
    }

    func permissionCategoryDisplay(_ categoryGroup: PermissionCategoryGroup) -> some View {
        let selectedCount = PermissionSelectionHelper.selectedCount(
            for: categoryGroup,
            selectedIds: activePermissionIds
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(categoryGroup.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(selectedCount)/\(categoryGroup.permissions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            VStack(spacing: 8) {
                ForEach(categoryGroup.groups.filter { groupHasSelection($0) }) { group in
                    permissionGroupDisplay(group)
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func groupHasSelection(_ group: PermissionSelectionGroup) -> Bool {
        activePermissionIds.contains(group.parent.id) ||
        group.children.contains { activePermissionIds.contains($0.id) }
    }

    func permissionGroupDisplay(_ group: PermissionSelectionGroup) -> some View {
        let parentSelected = activePermissionIds.contains(group.parent.id)
        let selectedChildren = group.children.filter { activePermissionIds.contains($0.id) }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: parentSelected ? "checkmark.circle.fill" : "minus.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(parentSelected ? Color.poolGreen : Color.accentColor)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.parent.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if !group.parent.description.isEmpty {
                        Text(group.parent.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                Text(parentSelected ? "View" : "Actions")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(parentSelected ? Color.poolGreen : Color.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        (parentSelected ? Color.poolGreen : Color.accentColor).opacity(0.12),
                        in: Capsule()
                    )
            }

            if !selectedChildren.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(selectedChildren) { child in
                        Text(child.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                }
                .padding(.leading, 28)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
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

    func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
