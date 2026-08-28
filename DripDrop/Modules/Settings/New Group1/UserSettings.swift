//
//  UserSettings.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

@MainActor
final class UserSettingsViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var listOfCompanies: [Company] = []
    @Published var company: Company? = nil
    @Published var showChangeCompanyScreen: Bool = false
    @Published var showDeleteAccountConfirmation: Bool = false

    func onLoad(user: DBUser, selectedCompany: Company?) async throws {
        let accessList = try await UserAccessManager.shared.getAllUserAvailableCompanies(userId: user.id)
        print("  [UserSettingsViewModel][onLoad] Received List of \(accessList.count) Companies available to Access")

        var listOfCompanies: [Company] = []
        for access in accessList {
            let company = try await CompanyManager.shared.getCompany(companyId: access.id)
            listOfCompanies.append(company)
        }

        self.listOfCompanies = listOfCompanies
        self.company = selectedCompany
    }

    func updateRecentlySelectedCompanyWithCompanyId(user: DBUser, companyId: String) async throws {
        print("update Recently Selected Company")
        try await dataService.updateUserRecentlySelectedCompany(user: user, recentlySelectedCompanyId: companyId)
    }

    func updateRecentlySelectedCompany(user: DBUser, companyId: String) async throws {
        print("updateRecentlySelectedCompany")
        try await dataService.updateUserRecentlySelectedCompany(user: user, recentlySelectedCompanyId: companyId)
    }

    func resetPassword() throws {
        let user = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = user.email else {
            print("Email is Optional")
            throw FireBasePublish.unableToPublish
        }

        if isValidEmail(email) {
            print("Is Valid Email")
            try AuthenticationManager.shared.resetPassword(email: email)
        } else {
            print("Is Not Valid Email")
            throw FireBasePublish.unableToPublish
        }
    }

    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
}

struct UserSettings: View {
    init(dataService: any ProductionDataServiceProtocol, isEmbedded: Bool = false) {
        self.dataService = dataService
        _VM = StateObject(wrappedValue: UserSettingsViewModel(dataService: dataService))
        _authVM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
        self.isEmbedded = isEmbedded
    }

    @EnvironmentObject var masterDataManager: MasterDataManager
    private let dataService: any ProductionDataServiceProtocol

    @StateObject private var VM: UserSettingsViewModel
    @StateObject private var authVM: AuthenticationViewModel

    @State private var showRedeemInviteCode = false
    @State private var showResetPasswordAlert = false
    @State private var resetPasswordAlertTitle = ""
    @State private var resetPasswordAlertMessage = ""

    private let isEmbedded: Bool

    var body: some View {
        Group {
            if isEmbedded {
                settingsContent
            } else {
                ZStack {
                    Color.listColor.ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        settingsContent
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                            .padding(.bottom, 28)
                    }
                }
            }
        }
        .foregroundStyle(Color.basicFontText)
        .task {
            do {
                if let user = masterDataManager.user {
                    try await VM.onLoad(user: user, selectedCompany: masterDataManager.currentCompany)
                } else {
                    masterDataManager.showSignInView = true
                }
            } catch {
                print("Failed to get User Access List - Page: Settings View")
            }
        }
        .alert(resetPasswordAlertTitle, isPresented: $showResetPasswordAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetPasswordAlertMessage)
        }
    }
}

private extension UserSettings {
    var settingsContent: some View {
        VStack(spacing: 14) {
            companySettings
            accountSettings
            signOutButton
        }
    }

    var companySettings: some View {
        settingsCard(title: "Workspace", systemImage: "building.2") {
            Button {
                VM.company = masterDataManager.currentCompany
                VM.showChangeCompanyScreen.toggle()
            } label: {
                settingsRow(
                    title: currentCompanyName,
                    subtitle: currentCompanySubtitle,
                    systemImage: "building.2"
                ) {
                    Text("Change")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.showChangeCompanyScreen, onDismiss: updateSelectedCompany) {
                MyCompanyPickerView(dataService: dataService, company: $VM.company)
            }

            Divider()
                .padding(.leading, 46)

            Button {
                showRedeemInviteCode.toggle()
            } label: {
                settingsRow(
                    title: "Redeem Invite Code",
                    subtitle: "Join another company workspace.",
                    systemImage: "ticket"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showRedeemInviteCode) {
                RedeemInviteCode(dataService: dataService)
            }
        }
    }

    var displayPreferences: some View {
        settingsCard(title: "Display", systemImage: "rectangle.grid.1x2") {
            settingsRow(
                title: "Dashboard Layout",
                subtitle: masterDataManager.mainScreenDisplayType.rawValue,
                systemImage: "rectangle.grid.1x2"
            ) {
                Picker("Dashboard Layout", selection: $masterDataManager.mainScreenDisplayType) {
                    ForEach(MainScreenDisplayType.allCases, id: \.self) { displayType in
                        Text(displayType.rawValue).tag(displayType)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    var accountSettings: some View {
        settingsCard(title: "Account", systemImage: "person.crop.circle") {
            Button(action: sendPasswordReset) {
                settingsRow(
                    title: "Reset Password",
                    subtitle: "Send a password reset email.",
                    systemImage: "key"
                ) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.leading, 46)

            Button {
                VM.showDeleteAccountConfirmation.toggle()
            } label: {
                settingsRow(
                    title: "Delete Account",
                    subtitle: "Confirm before removing your account.",
                    systemImage: "trash",
                    tint: .red
                ) {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.showDeleteAccountConfirmation, onDismiss: refreshAuthenticationState) {
                DeleteUserConfirmation(dataService: dataService)
            }
        }
    }

    var signOutButton: some View {
        Button(action: signOut) {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.poolRed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
    }

    var currentCompanyName: String {
        masterDataManager.currentCompany?.name ?? "Tech Hub"
    }

    var currentCompanySubtitle: String {
        if let currentCompany = masterDataManager.currentCompany {
            return currentCompany.email.isEmpty ? "Current company workspace" : currentCompany.email
        }

        return "No company selected"
    }

    func settingsCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                content()
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    func settingsRow<Accessory: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color = .accentColor,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 8)

            accessory()
        }
        .contentShape(Rectangle())
        .padding(.vertical, 10)
    }

    func updateSelectedCompany() {
        Task {
            do {
                guard let user = masterDataManager.user else {
                    masterDataManager.showSignInView = true
                    return
                }

                if masterDataManager.currentCompany?.id == VM.company?.id {
                    return
                }

                if let changedCompany = VM.company {
                    masterDataManager.currentCompany = changedCompany
                    try await VM.updateRecentlySelectedCompany(user: user, companyId: changedCompany.id)

                    let userAccess = try await UserAccessManager.shared.getUserAccessCompanies(
                        userId: user.id,
                        companyId: changedCompany.id
                    )
                    masterDataManager.role = try await RoleManager.shared.getSpecificRole(
                        companyId: changedCompany.id,
                        roleId: userAccess.roleId
                    )
                } else {
                    masterDataManager.currentCompany = nil
                    masterDataManager.role = nil
                    try await VM.updateRecentlySelectedCompany(user: user, companyId: "")
                }
            } catch {
                print(error)
            }
        }
    }

    func sendPasswordReset() {
        do {
            try VM.resetPassword()
            resetPasswordAlertTitle = "Check Your Email"
            resetPasswordAlertMessage = "A password reset email has been sent to your account."
        } catch {
            print("Error Reseting Password")
            resetPasswordAlertTitle = "Password Reset Failed"
            resetPasswordAlertMessage = "We could not send a password reset email for this account."
        }

        showResetPasswordAlert = true
    }

    func refreshAuthenticationState() {
        Task {
            print("Checking if User Exists")
            do {
                print("[User Settings][On Dismiss Show Delete Account Confirmation]")
                try await authVM.onInitialLoad()
            } catch {
                print("Error Root View")
                print(error)
                masterDataManager.showSignInView = true
            }
        }
    }

    func signOut() {
        Task {
            do {
                try VM.signOut()
                masterDataManager.showSignInView = true
                masterDataManager.user = nil
                masterDataManager.currentCompany = nil
                masterDataManager.role = nil
                masterDataManager.selectedCategory = nil
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
