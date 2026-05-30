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