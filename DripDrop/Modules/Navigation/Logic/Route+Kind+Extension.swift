//
//  Route+Kind+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation

extension Route {
    // A simple discriminator for the case
    private var kindDiscriminator: Int {
        switch self {
        case .jobs: return 1
        case .billingJobs: return 2
        case .employeeMainDailyDisplayView: return 3
        // ... keep numbering for every case
        case .chat: return 100
        case .customer: return 101
        // etc.
        }
    }

    // Extract only identity-defining values
    private func identityComponents(into hasher: inout Hasher) {
        switch self {
        case .jobs:
            break // no associated identity
        case .chat(let chat, _):
            hasher.combine(chat.id) // use a stable identifier, not the entire object
        case .customer(let customer, _):
            hasher.combine(customer.id)
        // ... for other cases, combine IDs or key fields
        default:
            break
        }
    }
}
