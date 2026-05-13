//
//  EnvironmentBanner.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/27/26.
//
import SwiftUI

import Foundation
import UIKit
import FirebaseCore

struct EnvironmentBanner: View {
    var body: some View {
        #if DEBUG
        if AppEnvironment.current == .dev {
            Text("DEV")
                .font(.caption2)
                .bold()
                .padding(6)
                .background(Color.red.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding()
                .accessibilityHidden(true)
        }
        #endif
    }
}
