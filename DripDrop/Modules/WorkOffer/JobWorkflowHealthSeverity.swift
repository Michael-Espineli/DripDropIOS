//
//  JobWorkflowHealthModels.swift
//  DripDrop
//

import Foundation
import SwiftUI

enum JobWorkflowHealthSeverity: String, Codable, Hashable, CaseIterable, Identifiable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
    case success = "Success"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .critical:
            return "exclamationmark.octagon"
        case .success:
            return "checkmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        case .success:
            return .green
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical:
            return 0
        case .warning:
            return 1
        case .info:
            return 2
        case .success:
            return 3
        }
    }
}

enum JobWorkflowHealthCategory: String, Codable, Hashable, CaseIterable, Identifiable {
    case planning = "Planning"
    case offers = "Offers"
    case schedule = "Schedule"
    case actualWork = "Actual Work"
    case payroll = "Payroll"
    case materials = "Materials"
    case billing = "Billing"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .planning:
            return "checklist"
        case .offers:
            return "person.crop.circle.badge.plus"
        case .schedule:
            return "calendar"
        case .actualWork:
            return "checkmark.seal"
        case .payroll:
            return "dollarsign.circle"
        case .materials:
            return "cart"
        case .billing:
            return "doc.text"
        }
    }
}

struct JobWorkflowHealthIssue: Identifiable, Hashable {
    var id: String
    var severity: JobWorkflowHealthSeverity
    var category: JobWorkflowHealthCategory
    var title: String
    var message: String
    var actionTitle: String?
    var destinationTab: String?

    init(
        id: String,
        severity: JobWorkflowHealthSeverity,
        category: JobWorkflowHealthCategory,
        title: String,
        message: String,
        actionTitle: String? = nil,
        destinationTab: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.category = category
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.destinationTab = destinationTab
    }
}

struct JobWorkflowHealthReport: Hashable {
    var issues: [JobWorkflowHealthIssue]

    var criticalCount: Int {
        issues.filter { $0.severity == .critical }.count
    }

    var warningCount: Int {
        issues.filter { $0.severity == .warning }.count
    }

    var infoCount: Int {
        issues.filter { $0.severity == .info }.count
    }

    var successCount: Int {
        issues.filter { $0.severity == .success }.count
    }

    var needsAttentionCount: Int {
        criticalCount + warningCount
    }

    var isHealthy: Bool {
        criticalCount == 0 && warningCount == 0
    }

    var sortedIssues: [JobWorkflowHealthIssue] {
        issues.sorted {
            if $0.severity.sortOrder == $1.severity.sortOrder {
                return $0.category.rawValue < $1.category.rawValue
            }

            return $0.severity.sortOrder < $1.severity.sortOrder
        }
    }
}