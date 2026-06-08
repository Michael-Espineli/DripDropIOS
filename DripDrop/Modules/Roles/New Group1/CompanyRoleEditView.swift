//
//  CompanyRoleEditView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct CompanyRoleEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()

    @State var role: Role

    init(dataService: any ProductionDataServiceProtocol, role: Role) {
        _role = State(wrappedValue: role)
    }

    @State var selectedPermissionList: [String] = []
    @State var name: String = ""
    @State var description: String = ""
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""

    @FocusState private var focusedField: String?

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    roleDetailsCard
                    permissionsCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .navigationTitle("Edit Role")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedPermissionList = PermissionSelectionHelper.normalizeSelection(
                role.permissionIdList,
                permissions: permissionVM.standrdPermissions
            )
            name = role.name
            description = role.description
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

// MARK: - Main Sections

extension CompanyRoleEditView {

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
                    Text(name.isEmpty ? "Edit Role" : name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(description.isEmpty ? "Update the role name, description, and permissions." : description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("\(selectedPermissionList.count) Selected", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Label("Role", systemImage: "lock.shield")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var roleDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Role Details", systemImage: "info.circle")

            textInputRow(
                title: "Name",
                systemImage: "tag",
                placeholder: "Name",
                text: $name,
                focusId: "Name"
            )

            descriptionInputCard
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Permissions", systemImage: "lock.shield")

                Spacer()

                Text("\(selectedPermissionList.count)/\(permissionVM.standrdPermissions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            ForEach(permissionCategoryGroups) { categoryGroup in
                permissionCategorySection(categoryGroup)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var permissionCategoryGroups: [PermissionCategoryGroup] {
        PermissionSelectionHelper.categoryGroups(from: permissionVM.standrdPermissions)
    }

    func permissionCategorySection(_ categoryGroup: PermissionCategoryGroup) -> some View {
        let state = PermissionSelectionHelper.selectionState(
            for: categoryGroup,
            selectedIds: selectedPermissionList
        )
        let selectedCount = PermissionSelectionHelper.selectedCount(
            for: categoryGroup,
            selectedIds: selectedPermissionList
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

                Button {
                    selectedPermissionList = PermissionSelectionHelper.toggleCategory(
                        categoryGroup,
                        selectedIds: selectedPermissionList,
                        permissions: permissionVM.standrdPermissions
                    )
                } label: {
                    Label(
                        state == .selected ? "Clear" : "All",
                        systemImage: state == .selected ? "xmark.circle" : "checkmark.circle"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(state == .selected ? .secondary : Color.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            if categoryGroup.permissions.isEmpty {
                emptyState(
                    title: "No \(categoryGroup.name) permissions.",
                    message: "Permissions for this category will show here.",
                    systemImage: "lock.slash"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(categoryGroup.groups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            PermissionSelectorView(
                                permission: group.parent,
                                listOfPermissions: $selectedPermissionList,
                                allPermissions: permissionVM.standrdPermissions,
                                showsCategory: false
                            )

                            if !group.children.isEmpty {
                                VStack(spacing: 8) {
                                    ForEach(group.children) { child in
                                        PermissionSelectorView(
                                            permission: child,
                                            listOfPermissions: $selectedPermissionList,
                                            allPermissions: permissionVM.standrdPermissions,
                                            showsCategory: false,
                                            isChild: true
                                        )
                                    }
                                }
                                .padding(.leading, 18)
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.primary.opacity(0.10))
                                        .frame(width: 1)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Bottom Bar

extension CompanyRoleEditView {

    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    saveRole()
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    func saveRole() {
        Task {
            if let currentCompany = masterDataManager.currentCompany {
                let pushDescription = description
                let pushName = name
                let pushSelectedPermissionList = PermissionSelectionHelper.normalizeSelection(
                    selectedPermissionList,
                    permissions: permissionVM.standrdPermissions
                )

                print(pushSelectedPermissionList)

                do {
                    try await roleVM.updateRole(
                        companyId: currentCompany.id,
                        role: Role(
                            id: role.id,
                            name: pushName,
                            permissionIdList: pushSelectedPermissionList,
                            listOfUserIdsToManage: [],
                            color: role.color,
                            description: pushDescription
                        )
                    )

                    alertMessage = "Successfully Edited"
                    print("[CompanyRoleEditView][Button Action] \(alertMessage)")
                    showAlert = true
                    dismiss()
                } catch {
                    alertMessage = "Failed to Edit"
                    print(alertMessage)
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Reusable UI

extension CompanyRoleEditView {

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func textInputRow(
        title: String,
        systemImage: String,
        placeholder: String,
        text: Binding<String>,
        focusId: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .font(.subheadline)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .focused($focusedField, equals: focusId)
                .submitLabel(.done)
        }
    }

    var descriptionInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    description = ""
                } label: {
                    Text("Clear")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            TextField("Description", text: $description, axis: .vertical)
                .font(.subheadline)
                .lineLimit(4, reservesSpace: true)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .focused($focusedField, equals: "Description")
                .submitLabel(.return)
        }
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
