//
//  UserRoleView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI
import Foundation

struct UserRoleView: View {
    @StateObject var roleVM = RoleViewModel()
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @State private var showSheet = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if isLoading && roleVM.roleList.isEmpty {
                        loadingCard
                    } else if !errorMessage.isEmpty {
                        stateCard(
                            title: "Unable to load roles.",
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle"
                        )
                    } else if roleVM.roleList.isEmpty {
                        stateCard(
                            title: "No roles found.",
                            message: "Create a role to start assigning company access.",
                            systemImage: "person.badge.plus"
                        )
                    } else {
                        rolesListCard
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .refreshable {
                await loadRoles()
            }
        }
        .navigationTitle("User Roles")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSheet, onDismiss: {
            Task { await loadRoles() }
        }) {
            NavigationStack {
                CreateCompanyRoles()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showSheet = false
                            }
                        }
                    }
            }
        }
        .task {
            await loadRoles()
        }
        .toolbar {
            ToolbarItem {
                if canCreateRole {
                    Button {
                        showSheet.toggle()
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - Sections

extension UserRoleView {

    var canCreateRole: Bool {
        masterDataManager.role?.permissionIdList.contains("862") == true
    }

    var totalPermissionCount: Int {
        roleVM.roleList.reduce(0) { $0 + $1.permissionIdList.count }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 54, height: 54)

                    Image(systemName: "person.3.sequence")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("User Roles")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(masterDataManager.currentCompany?.name ?? "Company access levels")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label("\(roleVM.roleList.count) Roles", systemImage: "square.grid.2x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Label("\(totalPermissionCount) Permissions", systemImage: "checklist")
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

    var rolesListCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Roles")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(roleVM.roleList.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
            .padding(16)

            Divider()
                .opacity(0.35)

            LazyVStack(spacing: 10) {
                ForEach(roleVM.roleList.sorted { $0.name < $1.name }) { role in
                    roleNavigationRow(role)
                }
            }
            .padding(12)
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    func roleNavigationRow(_ role: Role) -> some View {
        if UIDevice.isIPhone {
            NavigationLink(value: Route.userRoleDetailView(dataService: dataService, role: role)) {
                roleRowContent(role)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                masterDataManager.selectedRole = role
            } label: {
                roleRowContent(role)
            }
            .buttonStyle(.plain)
        }
    }

    func roleRowContent(_ role: Role) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(roleColor(role.color).opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "person.badge.key")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(roleColor(role.color))
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(role.name.isEmpty ? "Untitled Role" : role.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(role.permissionIdList.count)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }

                Text(role.description.isEmpty ? "No description" : role.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: UIDevice.isIPhone ? "chevron.right" : "sidebar.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("Loading roles...")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func stateCard(title: String, message: String, systemImage: String) -> some View {
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
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Data

extension UserRoleView {

    func loadRoles() async {
        guard let company = masterDataManager.currentCompany else {
            errorMessage = "No company selected."
            return
        }

        isLoading = true
        errorMessage = ""

        do {
            try await roleVM.getAllCompanyRoles(companyId: company.id)
        } catch {
            errorMessage = "Please try again."
        }

        isLoading = false
    }
}

// MARK: - Helpers

extension UserRoleView {

    func roleColor(_ value: String) -> Color {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return Color.accentColor
        }

        switch trimmed.lowercased() {
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "yellow":
            return .yellow
        default:
            return colorFromHex(trimmed) ?? Color.accentColor
        }
    }

    func colorFromHex(_ value: String) -> Color? {
        var hex = value
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6 else {
            return nil
        }

        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else {
            return nil
        }

        return Color(
            red: Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >> 8) / 255,
            blue: Double(rgb & 0x0000FF) / 255
        )
    }
}
