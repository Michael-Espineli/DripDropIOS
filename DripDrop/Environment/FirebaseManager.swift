//
//  FirebaseManager.swift
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

final class FirebaseManager {
    static let shared = FirebaseManager()

    private(set) var app: FirebaseApp?
    private init() {}

    func configure() {
        if let _ = FirebaseApp.app() {
            return
        }

        let plistName: String = {
            switch AppEnvironment.current {
            case .dev: return "GoogleService-Info-Dev"
            case .prod: return "GoogleService-Info-prod"
            }
        }()

        guard let filePath = Bundle.main.path(forResource: plistName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Could not load Firebase options for \(AppEnvironment.current)")
        }

        FirebaseApp.configure(options: options)
        self.app = FirebaseApp.app()
    }

    var db: Firestore {
        // Configure Firestore if needed (e.g., local emulator)
        let db = Firestore.firestore()
        return db
    }
}
