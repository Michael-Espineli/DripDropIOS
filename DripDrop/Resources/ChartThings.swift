//
//  ChartThings.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/30/24.
//

import Foundation
import Charts

struct BuildActivity: Identifiable, Codable {
    var id: TimeInterval { date.timeIntervalSince1970 }
    let date: Date
    let name: String
    let numberOfUnits: Int
}
struct BuildActivityDouble: Identifiable, Codable {
    var id: TimeInterval { date.timeIntervalSince1970 }
    let date: Date
    let name: String
    let numberOfUnits: Double
}
