//
//  ReportManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation
import SwiftUI

enum ReportType: Int, CaseIterable, Identifiable {
    
    var id: Int { rawValue }
    case funReadingsDosages
    case readings
    case readingHealth
    case readingPerformance
    case pnlPerPool
    case chemicals
    case waste
    case users
    case job
    case vehicle
    case purchases
    case payroll
    case futurePayroll
    case pnl
    case tax
}

extension ReportType {
    enum Category: String, CaseIterable, Identifiable {
        case operations = "Operations"
        case performance = "Performance"
        case finance = "Finance / Accounting"

        var id: String { rawValue }
    }
    
    var title: String {
        switch self {
        case .funReadingsDosages:
            return "Fun Readings & Dosages"
        case .readings:
            return "Readings & Dosages Summary"
        case .readingHealth:
            return "Reading Health"
        case .readingPerformance:
            return "Reading Performance"
        case .pnlPerPool:
            return "PNL Per Pool"
        case .chemicals:
            return "Chemicals"
        case .waste:
            return "Waste"
        case .users:
            return "Users"
        case .job:
            return "Jobs"
        case .vehicle:
            return "Vehicle"
        case .purchases:
            return "Purchases"
        case .payroll:
            return "Payroll"
        case .futurePayroll:
            return "Future Payroll"
        case .pnl:
            return "P.N.L."
        case .tax:
            return "Tax"
        }
    }

    var source: String {
        switch self {
        case .funReadingsDosages:
            return "Daily reading and dosage ranges"
        case .readings:
            return "StopData readings and dosages"
        case .readingHealth:
            return "Reading thresholds by pool"
        case .readingPerformance:
            return "StopData standards by user or customer"
        case .pnlPerPool:
            return "Service agreements, labor, chemicals"
        case .chemicals:
            return "StopData dosages"
        case .waste:
            return "Linked dosages and purchased items"
        case .users:
            return "Users, stops, jobs, purchases, payroll"
        case .job:
            return "Work orders, purchases, payroll"
        case .vehicle:
            return "Vehicles and active routes"
        case .purchases:
            return "Purchased items and vendor items"
        case .payroll:
            return "Technician payroll line items"
        case .futurePayroll:
            return "Unpaid payroll and scheduled service stop estimates"
        case .pnl:
            return "Service agreements, jobs, purchases, payroll"
        case .tax:
            return "Purchases and invoiced jobs"
        }
    }

    var category: Category {
        switch self {
        case .funReadingsDosages, .readings, .readingHealth, .chemicals, .users, .job, .vehicle:
            return .operations
        case .readingPerformance, .pnlPerPool, .waste:
            return .performance
        case .purchases, .payroll, .futurePayroll, .pnl, .tax:
            return .finance
        }
    }

    var isNativeGenerationReady: Bool {
        switch self {
        case .chemicals, .waste, .purchases, .pnl:
            return true
        case .funReadingsDosages, .readings, .readingHealth, .readingPerformance, .pnlPerPool, .users, .job, .vehicle, .payroll, .futurePayroll, .tax:
            return false
        }
    }

    var generationStatusTitle: String {
        isNativeGenerationReady ? "Ready" : "Listed"
    }
    
    var systemImage: String {
        switch self {
        case .funReadingsDosages:
            return "sparkles"
        case .readings:
            return "list.bullet.clipboard"
        case .readingHealth:
            return "heart.text.square.fill"
        case .readingPerformance:
            return "person.2.badge.gearshape.fill"
        case .pnlPerPool:
            return "chart.bar.xaxis"
        case .chemicals:
            return "testtube.2"
        case .waste:
            return "trash.fill"
        case .users:
            return "person.3.fill"
        case .job:
            return "briefcase.fill"
        case .vehicle:
            return "car.fill"
        case .purchases:
            return "cart.fill"
        case .payroll:
            return "person.crop.circle.badge.dollar"
        case .futurePayroll:
            return "calendar.badge.clock"
        case .pnl:
            return "chart.line.uptrend.xyaxis"
        case .tax:
            return "percent"
        }
    }

    var tint: Color {
        switch self {
        case .funReadingsDosages, .readings, .chemicals, .purchases:
            return .poolBlue
        case .readingHealth, .users, .pnl, .futurePayroll:
            return .poolGreen
        case .readingPerformance, .pnlPerPool, .waste:
            return .teal
        case .job, .tax:
            return .orange
        case .vehicle:
            return .gray
        case .payroll:
            return .purple
        }
    }
}
