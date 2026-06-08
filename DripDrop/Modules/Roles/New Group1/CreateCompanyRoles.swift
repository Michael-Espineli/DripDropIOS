//
//  CreateCompanyRoles.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import UIKit

struct CreateCompanyRoles: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var permissionVM = PermissionViewModel()
    @StateObject var roleVM = RoleViewModel()

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedColor = Color.accentColor
    @State private var listOfPermissions: [String] = []
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""

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
        .navigationTitle("New Role")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

// MARK: - Main Sections

extension CreateCompanyRoles {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(selectedColor.opacity(0.16))
                        .frame(width: 54, height: 54)

                    Image(systemName: "person.badge.plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(name.isEmpty ? "New Role" : name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(description.isEmpty ? "Set role details and permission coverage." : description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("\(listOfPermissions.count) Selected", systemImage: "checklist")
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
                placeholder: "Role name",
                text: $name,
                focusId: "Name"
            )

            descriptionInputCard

            VStack(alignment: .leading, spacing: 8) {
                Label("Color", systemImage: "paintpalette")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ColorPicker("Role color", selection: $selectedColor)
                        .labelsHidden()

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selectedColor)
                        .frame(width: 44, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
                        )

                    Text(hexString(from: selectedColor))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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

                Text("\(listOfPermissions.count)/\(permissionVM.standrdPermissions.count)")
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
            selectedIds: listOfPermissions
        )
        let selectedCount = PermissionSelectionHelper.selectedCount(
            for: categoryGroup,
            selectedIds: listOfPermissions
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
                    listOfPermissions = PermissionSelectionHelper.toggleCategory(
                        categoryGroup,
                        selectedIds: listOfPermissions,
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

            VStack(spacing: 10) {
                ForEach(categoryGroup.groups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        PermissionSelectorView(
                            permission: group.parent,
                            listOfPermissions: $listOfPermissions,
                            allPermissions: permissionVM.standrdPermissions,
                            showsCategory: false
                        )

                        if !group.children.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(group.children) { child in
                                    PermissionSelectorView(
                                        permission: child,
                                        listOfPermissions: $listOfPermissions,
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
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Bottom Bar

extension CreateCompanyRoles {

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
                    Label(isSaving ? "Saving" : "Save", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    func saveRole() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter a role name."
            showAlert = true
            return
        }

        guard let company = masterDataManager.currentCompany else {
            alertMessage = "No company selected."
            showAlert = true
            return
        }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                let selectedIds = PermissionSelectionHelper.normalizeSelection(
                    listOfPermissions,
                    permissions: permissionVM.standrdPermissions
                )

                try await roleVM.createRole(
                    companyId: company.id,
                    role: Role(
                        id: UUID().uuidString,
                        name: trimmedName,
                        permissionIdList: selectedIds,
                        listOfUserIdsToManage: [],
                        color: hexString(from: selectedColor),
                        description: description.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                )

                dismiss()
            } catch {
                alertMessage = "Failed to create role."
                showAlert = true
            }
        }
    }
}

// MARK: - Reusable UI

extension CreateCompanyRoles {

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

    func hexString(from color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "#0EA5E9"
        }

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
