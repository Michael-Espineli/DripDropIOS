import SwiftUI

struct RootView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State var layoutExperience: LayoutExperienceSetting = .threeColumn
    @StateObject private var loadingState = AppLoadingState()
    @StateObject private var VM: AuthenticationViewModel
    @State private var attemptedInitialLoad = false

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: AuthenticationViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack {
            if loadingState.hasLoadedAccount && !masterDataManager.showSignInView {
                home
                    .allowsHitTesting(!loadingState.isVisible)
                    .accessibilityHidden(loadingState.isVisible)
            } else if !loadingState.isVisible {
                NavigationStack {
                    SignInView(dataService: dataService)
                }
            }

            // Keep this exact view mounted while the home screen loads beneath it.
            if loadingState.isVisible {
                WaterLevelLoading(fillTarget: loadingState.fillTarget, message: loadingState.message)
                    .transition(.opacity)
                    .zIndex(1)
            }
            EnvironmentBanner()
                .zIndex(2)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: loadingState.isVisible)
        .task(id: masterDataManager.showSignInView) {
            await updateSession()
        }
        .task(id: loadingState.phase) {
            guard loadingState.phase == .finishing else { return }
            // Let the last pour cover the screen before revealing the ready app.
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 750))
                loadingState.finish()
            } catch {
                // A sign-out or a new session cancels this completion.
            }
        }
    }

    private var home: some View {
        let session = loadingState.sessionID
        let didLoad = { loadingState.workspaceLoaded(for: session) }
        return Group {
            if UIDevice.isIPhone || masterDataManager.currentCompany == nil {
                MobileHome(dataService: dataService, onInitialLoadFinished: didLoad)
            } else {
                ThreeColumnMenuView(dataService: dataService, layoutExperience: $layoutExperience,
                                    onInitialLoadFinished: didLoad)
            }
        }
    }

    @MainActor
    private func updateSession() async {
        if !attemptedInitialLoad {
            attemptedInitialLoad = true
            await loadAccount()
        } else if masterDataManager.showSignInView {
            loadingState.showSignIn()
        } else if !loadingState.hasLoadedAccount {
            await loadAccount()
        }
    }

    @MainActor
    private func loadAccount() async {
        loadingState.beginAccountLoad()
        let session = loadingState.sessionID
        do {
            try await VM.onInitialLoad()
            try Task.checkCancellation()
            guard session == loadingState.sessionID else { return }
            masterDataManager.user = VM.user
            masterDataManager.currentCompany = VM.company
            masterDataManager.companyUser = VM.companyUser
            masterDataManager.checkForSubscriptionStatus()
            // Mark the account ready before changing sign-in state. The task
            // restarted by that change must not fetch the account a second time.
            loadingState.accountLoaded(for: session)
            masterDataManager.showSignInView = false
        } catch {
            guard !Task.isCancelled, session == loadingState.sessionID else { return }
            print("[RootView][loadAccount] \(error)")
            loadingState.showSignIn()
            masterDataManager.showSignInView = true
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(dataService: MockDataService())
    }
}
