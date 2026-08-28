//
//  AdminRootView.swift
//  DripDropAdmin
//

import SwiftUI

struct AdminRootView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var authenticationViewModel: AuthenticationViewModel

    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
        _authenticationViewModel = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            AdminPalette.background.ignoresSafeArea()

            if authenticationViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(AdminPalette.gold)
                    Text("Loading admin workspace")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AdminPalette.mutedText)
                }
            } else if masterDataManager.showSignInView {
                NavigationStack {
                    SignInView(dataService: dataService)
                }
            } else {
                AdminDashboardView()
            }
        }
        .task {
            await loadSession()
        }
        .onChange(of: masterDataManager.showSignInView) { showSignIn in
            guard !showSignIn else { return }
            Task {
                await loadSession()
            }
        }
    }

    @MainActor
    private func loadSession() async {
        do {
            try await authenticationViewModel.onInitialLoad()
            masterDataManager.checkForSubscriptionStatus()
            masterDataManager.user = authenticationViewModel.user
            masterDataManager.currentCompany = authenticationViewModel.company
            masterDataManager.companyUser = authenticationViewModel.companyUser
            masterDataManager.showSignInView = false
        } catch {
            print("[AdminRootView][loadSession] \(error)")
            masterDataManager.showSignInView = true
        }
    }
}
