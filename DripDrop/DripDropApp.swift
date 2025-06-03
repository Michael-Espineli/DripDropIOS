//
//  DripDropApp.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI
import Firebase
import StripeCore
import BackgroundTasks

@main
struct DripDropApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase

    @StateObject private var navigationManager = NavigationStateManager()
    @StateObject private var masterDataManager = MasterDataManager()
    @StateObject private var dataService = ProductionDataService()
//    @StateObject private var dataService = MockDataService()

    static let fleetDataService = FleetManager()
    
    func background() {
       print("App Entering Background")
    }
    func foreground() {
       print("App Entering Foreground")
    }
    var body: some Scene {
        WindowGroup {
                RootView(dataService: dataService)
                    .onOpenURL { incomingURL in
                        let routeFinder = RouteFinder()
                        if let route = routeFinder.find2(from: incomingURL) {
                            print(route)
                        }
                    }
                //                .onOpenURL { incomingURL in
                //                    let stripeHandled = StripeAPI.handleURLCallback(with: incomingURL)
                //                    if (!stripeHandled) {
                //                        let routeFinder = RouteFinder()
                //                         if let route = routeFinder.find2(from: incomingURL) {
                //                             navigationManager.selectedCategory = route.category
                //                             navigationManager.selectedID = route.id
                //                         }
                //                    }
                //                  }
                    .environmentObject(masterDataManager)
                    .environmentObject(navigationManager)
                    .environmentObject(dataService)

                    .onChange(of: phase) { newPhase in
                            switch newPhase {
                            case .background: background()
                            case .active: foreground()
                            default: break
                            }
                        }
           
        }
    }
}


