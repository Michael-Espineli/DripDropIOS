//
//  PermissionSelectorView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/7/23.
//

import SwiftUI

struct PermissionSelectorView: View {
    var permission: PermissionModel
    @Binding var listOfPermissions: [String]
    var allPermissions: [PermissionModel]
    var showsCategory: Bool
    var isChild: Bool

    init(
        permission: PermissionModel,
        listOfPermissions: Binding<[String]>,
        allPermissions: [PermissionModel] = [],
        showsCategory: Bool = true,
        isChild: Bool = false
    ) {
        self.permission = permission
        _listOfPermissions = listOfPermissions
        self.allPermissions = allPermissions.isEmpty ? [permission] : allPermissions
        self.showsCategory = showsCategory
        self.isChild = isChild
    }

    private var selectionState: PermissionSelectionState {
        PermissionSelectionHelper.selectionState(
            for: permission,
            selectedIds: listOfPermissions,
            permissions: allPermissions
        )
    }

    private var isSelected: Bool {
        selectionState == .selected
    }

    private var isPartial: Bool {
        selectionState == .partial
    }

    private var isParentWithChildren: Bool {
        !isChild && !PermissionSelectionHelper.children(for: permission, in: allPermissions).isEmpty
    }

    private var symbolName: String {
        if isSelected {
            return "checkmark.circle.fill"
        }

        if isPartial {
            return "minus.circle.fill"
        }

        return "circle"
    }

    private var tintColor: Color {
        if isSelected {
            return Color.poolGreen
        }

        if isPartial {
            return Color.accentColor
        }

        return .secondary
    }

    var body: some View {
        Button {
            listOfPermissions = PermissionSelectionHelper.togglePermission(
                permission,
                selectedIds: listOfPermissions,
                permissions: allPermissions
            )
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(tintColor.opacity(isSelected || isPartial ? 0.14 : 0.08))
                        .frame(width: isChild ? 28 : 34, height: isChild ? 28 : 34)

                    Text(permission.id)
                        .font((isChild ? Font.caption2 : Font.caption).weight(.semibold))
                        .foregroundStyle(tintColor)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(permission.name)
                            .font(isChild ? .footnote.weight(.semibold) : .subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        if isPartial {
                            Text("Partial")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }

                        if isParentWithChildren {
                            Text("View")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(Color.primary.opacity(0.06), in: Capsule())
                        }
                    }

                    if showsCategory && !permission.category.isEmpty {
                        Text(permission.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())
                    }

                    if !permission.description.isEmpty {
                        Text(permission.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: symbolName)
                    .font(isChild ? .body.weight(.semibold) : .title3)
                    .foregroundStyle(tintColor)
                    .padding(.top, 2)
            }
            .padding(isChild ? 10 : 12)
            .background(
                rowBackground,
                in: RoundedRectangle(cornerRadius: isChild ? 14 : 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isChild ? 14 : 16, style: .continuous)
                    .stroke(tintColor.opacity(isSelected || isPartial ? 0.24 : 0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.poolGreen.opacity(0.08)
        }

        if isPartial {
            return Color.accentColor.opacity(0.08)
        }

        return Color.primary.opacity(0.035)
    }
}

struct PermissionSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        @State var listOfPermissions: [String] = []
        let permissions = [
            PermissionModel(
                id: "230",
                name: "Routes",
                description: "",
                category: "Management"
            )
        ]

        PermissionSelectorView(
            permission: permissions[0],
            listOfPermissions: $listOfPermissions,
            allPermissions: permissions
        )
        .padding()
        .background(Color.listColor)
    }
}
