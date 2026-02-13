//
//  AppEnvironment.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//

import SwiftUI
import Firebase
import StripeCore
import BackgroundTasks
import FirebaseCore
import FirebaseFirestore

enum AppEnvironment: String {
    case dev
    case prod

    static let current: AppEnvironment = {
        #if DEBUG
        // For debug, prefer reading from a compile-time flag or Info.plist key
        if let env = Bundle.main.object(forInfoDictionaryKey: "APP_ENV") as? String,
           let value = AppEnvironment(rawValue: env) {
            return value
        }
        return .dev
        #else
        return .prod
        #endif
    }()
}
