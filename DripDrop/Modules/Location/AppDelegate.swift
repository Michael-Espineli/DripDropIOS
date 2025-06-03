//
//
//  AppDelegate.swift
//  Pool App
//
//  Created by Michael Espinli on 5/9/2024
//

import Foundation
import UIKit
import FirebaseCore
class AppDelegate: NSObject, UIApplicationDelegate {

    // swiftlint: disable line_length
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        setupMyApp()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    private func setupMyApp() {
        // TODO: Add any intialization steps here.
        print("Application Set up!")
    }
}

//import UIKit
//import StripePaymentSheet
//
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        StripeAPI.defaultPublishableKey = "pk_test_51P39vqAUNYvyj1aECiK7vjZuhGR9WP7j4pW5ISV64mMAOLcaHFt4NSpy6QhjVdYW8aqOfHmAbhYgRMceLCCluX3J00y6jOIAbZ"
//        // do any other necessary launch configuration
//        return true
//    }
//}
