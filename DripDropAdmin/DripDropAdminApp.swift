//
//  DripDropAdminApp.swift
//  DripDropAdmin
//

import SwiftUI
import StripeCore

@main
struct DripDropAdminApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase

    @StateObject private var dataService: ProductionDataService
    @StateObject private var masterDataManager: MasterDataManager
    @StateObject private var navigationManager = NavigationStateManager()
    @StateObject private var masterRoleManager: MasterRoleManager

    init() {
        FirebaseManager.shared.configure()

        let productionDataService = ProductionDataService()
        _dataService = StateObject(wrappedValue: productionDataService)
        _masterDataManager = StateObject(wrappedValue: MasterDataManager(dataService: productionDataService))
        _masterRoleManager = StateObject(wrappedValue: MasterRoleManager(dataService: productionDataService))
    }

    var body: some Scene {
        WindowGroup {
            AdminRootView(dataService: dataService)
                .onOpenURL { incomingURL in
                    _ = StripeAPI.handleURLCallback(with: incomingURL)
                }
                .environmentObject(masterDataManager)
                .environmentObject(navigationManager)
                .environmentObject(dataService)
                .environmentObject(masterRoleManager)
                .onChange(of: phase) { newPhase in
                    switch newPhase {
                    case .background:
                        print("[DripDropAdminApp] App Entering Background")
                    case .active:
                        print("[DripDropAdminApp] App Entering Foreground")
                    default:
                        break
                    }
                }
        }
    }
}
