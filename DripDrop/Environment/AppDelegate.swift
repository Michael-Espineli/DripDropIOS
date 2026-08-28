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
import UserNotifications

extension Notification.Name {
    static let dripDropNotificationRouteRequested = Notification.Name("dripDropNotificationRouteRequested")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // swiftlint: disable line_length
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
//        FirebaseApp.configure()
        FirebaseManager.shared.configure()
        UNUserNotificationCenter.current().delegate = self
        #if DEBUG
        // Optional: connect to Firestore emulator for local testing
        // let settings = Firestore.firestore().settings
        // settings.host = "localhost:8080"
        // settings.isSSLEnabled = false
        // Firestore.firestore().settings = settings
        #endif
        
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .dripDropNotificationRouteRequested,
                object: nil,
                userInfo: response.notification.request.content.userInfo
            )
        }
    }
}

//import UIKit
//import StripePaymentSheet
//
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        StripeAPI.defaultPublishableKey = "<configured by subscription checkout response>"
//        // do any other necessary launch configuration
//        return true
//    }
//}
