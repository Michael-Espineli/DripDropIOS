//
//  ReportManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation

enum ReportType: Int, CaseIterable, Identifiable {
    
    var id: Int { rawValue }
    case chemicals
    case waste
    case users
    case purchases
    case pnl
    case job
    case vehical
    case tax
}

extension ReportType {
    
    var title: String {
        switch self {
        case .chemicals:
            return "Chemicals"

        case .waste:
            return "Waste"

        case .users:
            return "Users"

        case .purchases:
            return "Purchases"
        case .job:
            return "Jobs"

        case .pnl:
            return "P.N.L."
            
        case .vehical:
            return "Vehical"
            
        case .tax:
            return "Tax"

        }
    }
    
    var systemImage: String {
        switch self {
        case .chemicals:
            return "testtube.2"

        case .waste:
            return "trash.fill"

        case .users:
            return "person.3.fill"

        case .purchases:
            return "cart"
        case .job:
            return "doc"
        case .pnl:
            return "dollarsign"
        case .vehical:
            return "dollarsign"
        case .tax:
            return "dollarsign"

        }
    }
}
