//
//  PermissionDisplayView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/3/24.
//

import SwiftUI

struct PermissionDisplayView: View {
    var permission: PermissionModel
    //    @Binding var listOfPermissions:[String]
    @State var listOfPermissions: [String]
    @State var selected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.poolGreen.opacity(0.14) : Color.primary.opacity(0.06))
                        .frame(width: 34, height: 34)

                    Text(permission.id)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selected ? Color.poolGreen : .secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(permission.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if !permission.category.isEmpty {
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
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.poolGreen : .secondary)
                    .padding(.top, 2)
            }

            if permission.id == "2" {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)

                    Text("List of Users To Manage?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(12)
        .background(
            selected ? Color.poolGreen.opacity(0.08) : Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selected ? Color.poolGreen.opacity(0.22) : Color.primary.opacity(0.06), lineWidth: 1)
        )
        .onAppear {
            if listOfPermissions.contains(permission.id) {
                selected = true
            } else {
                selected = false
            }
        }
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
