//
//  JobTemplate+Helpers.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import Foundation

enum JobIssuePriorityLevel: Int, CaseIterable, Identifiable, Codable {
    case critical = 1
    case recommended = 2
    case preventive = 3
    case optionalUpgrade = 4

    static let defaultLevel: JobIssuePriorityLevel = .recommended

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .critical:
            return "Critical"
        case .recommended:
            return "Recommended"
        case .preventive:
            return "Preventive"
        case .optionalUpgrade:
            return "Optional Upgrade"
        }
    }

    var displayName: String {
        "\(rawValue) - \(label)"
    }

    static func normalized(_ value: Int?) -> JobIssuePriorityLevel {
        JobIssuePriorityLevel(rawValue: value ?? defaultLevel.rawValue) ?? defaultLevel
    }
}

extension JobTemplate {
    var normalizedDefaultIssuePriority: JobIssuePriorityLevel {
        JobIssuePriorityLevel.normalized(
            defaultIssuePriorityLevel ?? issuePriorityLevel ?? priorityLevel ?? solutionTier
        )
    }

    var defaultIssuePriorityDisplayName: String {
        normalizedDefaultIssuePriority.displayName
    }

    mutating func setDefaultIssuePriority(_ priority: JobIssuePriorityLevel) {
        defaultIssuePriorityLevel = priority.rawValue
        defaultIssuePriorityLabel = priority.label
        issuePriorityLevel = priority.rawValue
        issuePriorityLabel = priority.label
        priorityLevel = priority.rawValue
        priorityLabel = priority.label
        solutionTier = priority.rawValue
        solutionTierLabel = priority.label
    }
}

extension Job {
    var normalizedIssuePriority: JobIssuePriorityLevel? {
        guard issuePriorityLevel != nil || priorityLevel != nil || solutionTier != nil else {
            return nil
        }

        return JobIssuePriorityLevel.normalized(issuePriorityLevel ?? priorityLevel ?? solutionTier)
    }

    mutating func setIssuePriority(_ priority: JobIssuePriorityLevel) {
        issuePriorityLevel = priority.rawValue
        issuePriorityLabel = priority.label
        priorityLevel = priority.rawValue
        priorityLabel = priority.label
        solutionTier = priority.rawValue
        solutionTierLabel = priority.label
    }
}
