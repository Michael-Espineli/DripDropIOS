//
//  ShoppingCenterTab.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/26/26.
//


import SwiftUI

enum ShoppingCenterTab: String, CaseIterable, Identifiable {
    case routePrep = "Route Prep"
    case outstanding = "Outstanding"
    case myItems = "My Items"
    case customers = "Customers"
    case jobs = "Jobs"
    case purchased = "Purchased"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .routePrep:
            return "map"
        case .outstanding:
            return "exclamationmark.circle"
        case .myItems:
            return "person.crop.circle"
        case .customers:
            return "person.text.rectangle"
        case .jobs:
            return "briefcase"
        case .purchased:
            return "cart.badge.checkmark"
        }
    }
}

enum ShoppingCenterTimeScope: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case all = "All"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .today:
            return "calendar"
        case .thisWeek:
            return "calendar.badge.clock"
        case .all:
            return "tray.full"
        }
    }

    var prepDescription: String {
        switch self {
        case .today:
            return "today"
        case .thisWeek:
            return "this week"
        case .all:
            return "all active items"
        }
    }
}
