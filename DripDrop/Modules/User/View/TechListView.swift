//
//  TechListView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/6/23.
//

import SwiftUI

struct TechListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var VM: TechListViewModel

    init(dataService: any ProductionDataServiceProtocol) {
    }

    @State private var showInviteSheet = false
    @State private var showInviteSheetForTechWithApp = false
    @State private var showPick = false
    @State private var selected = "Active"
    @State private var searchTerm = ""
    @FocusState private var searchField: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                directoryHeader

                Picker("User status", selection: $selected) {
                    Text("Active").tag("Active")
                    Text("Pending").tag("Pending")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)

                if !searchTerm.isEmpty || searchField {
                    searchBar
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                directoryList
            }

            if UIDevice.isIPhone {
                userActionDock
            }
        }
        .navigationTitle("Users")
        .confirmationDialog("Select Type", isPresented: $showPick) {
            Button("Add tech without app") {
                showInviteSheet.toggle()
            }

            Button("Add tech with app") {
                showInviteSheetForTechWithApp.toggle()
            }
        }
        .sheet(isPresented: $showInviteSheetForTechWithApp) {
            InviteExistingTechView(dataService: dataService)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteNewTechView()
        }
        .onAppear {
            VM.onFirstLoad(companyId: masterDataManager.currentCompany?.id)
        }
        .onDisappear {
            VM.stop()
        }
        .onChange(of: selected) { status in
            Task {
                await reloadDirectory(for: status)
            }
        }
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        searchField.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await reloadDirectory(for: selected) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        showPick.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

extension TechListView {
    private var directoryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Users")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(directorySubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                directoryMetric(title: "Showing", value: "\(displayedDirectoryCount)", tint: .poolBlue)
                directoryMetric(title: "Active", value: "\(VM.companyUsers.count)", tint: .poolGreen)
                directoryMetric(title: "Pending", value: "\(VM.pendingInviteList.count)", tint: .orange)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var directoryList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 10) {
                switch selected {
                case "Pending":
                    if filteredPendingInvites.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredPendingInvites) { invite in
                            NavigationLink(value: Route.inviteDetailView(dataService: dataService, invite: invite)) {
                                InviteCardView(invite: invite)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                default:
                    if filteredCompanyUsers.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredCompanyUsers) { user in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.companyUserDetailView(user: user, dataService: dataService)) {
                                    CompanyUserCardView(dataService: dataService, companyUser: user)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button {
                                    masterDataManager.selectedCompanyUser = user
                                } label: {
                                    CompanyUserCardView(dataService: dataService, companyUser: user)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
        }
        .refreshable {
            await reloadDirectory(for: selected)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search users", text: $searchTerm)
                .focused($searchField, equals: true)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchTerm.isEmpty {
                Button {
                    searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: selected == "Pending" ? "envelope.badge" : "person.crop.circle.badge.questionmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(searchTerm.isEmpty ? "No \(selected.lowercased()) users found." : "No matches found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(searchTerm.isEmpty ? "Use the add action to invite a user." : "Try a different name, role, company, or status.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if searchTerm.isEmpty {
                Button {
                    showPick.toggle()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Invite User")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var userActionDock: some View {
        VStack(spacing: 10) {
            Button {
                Task { await reloadDirectory(for: selected) }
            } label: {
                mobileDockIcon(systemName: "arrow.clockwise", tint: .orange, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                showPick.toggle()
            } label: {
                mobileDockIcon(systemName: "plus", tint: .poolGreen, isSelected: false)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                    searchField.toggle()
                }
            } label: {
                mobileDockIcon(systemName: "magnifyingglass", tint: .poolBlue, isSelected: searchField || !searchTerm.isEmpty)
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private func directoryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileDockIcon(systemName: String, tint: Color, isSelected: Bool) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    private var filteredCompanyUsers: [CompanyUser] {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let users = VM.companyUsers.sorted { $0.userName.localizedCaseInsensitiveCompare($1.userName) == .orderedAscending }

        guard !query.isEmpty else { return users }

        return users.filter { user in
            [
                user.userName,
                user.roleName,
                user.status.rawValue,
                user.workerType.rawValue,
                user.linkedCompanyName ?? "",
                companyUserVehicleLabel(user)
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    private var filteredPendingInvites: [Invite] {
        let query = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let invites = VM.pendingInviteList.sorted {
            "\($0.firstName) \($0.lastName)".localizedCaseInsensitiveCompare("\($1.firstName) \($1.lastName)") == .orderedAscending
        }

        guard !query.isEmpty else { return invites }

        return invites.filter { invite in
            [
                invite.firstName,
                invite.lastName,
                invite.email,
                invite.roleName,
                invite.workerType.rawValue,
                invite.displayStatus
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    private var displayedDirectoryCount: Int {
        selected == "Pending" ? filteredPendingInvites.count : filteredCompanyUsers.count
    }

    private var directorySubtitle: String {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return selected == "Pending" ? "Pending invitations awaiting a response." : "Active company users, roles, worker types, and vehicle access."
        }

        return "Search results for \"\(searchTerm)\"."
    }

    private func companyUserVehicleLabel(_ user: CompanyUser) -> String {
        switch user.normalizedRouteVehicleAccess {
        case "personal":
            return "Personal vehicle"
        case "both":
            return "Company or personal"
        default:
            return "Company vehicle"
        }
    }

    @MainActor
    private func reloadDirectory(for status: String) async {
        guard let company = masterDataManager.currentCompany else { return }

        do {
            if status == "Pending" {
                try await VM.getPendingInvites(companyId: company.id)
            } else {
                try await VM.onChangeOfSelectedStatus(companyId: company.id, status: status)
            }
        } catch {
            print("Error refreshing directory")
            print(error)
        }
    }
}

struct TechListView_Previews: PreviewProvider {
    static var previews: some View {
        TechListView(dataService: MockDataService())
    }
}
