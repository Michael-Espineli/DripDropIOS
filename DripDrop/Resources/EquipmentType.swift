//
//  EquipmentType List.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/9/24.
//

import Foundation
struct StandardEquipment : Identifiable, Codable {
    var id : String
    var category: EquipmentCategory
    var make : String
    var model : String
    var needsService : Bool
    var parts: [StandardEquipmentPart]
    var releaseDate: Date?
    var manualPdfLink:String
}
struct StandardEquipmentPart:Identifiable, Codable{
    var id:String
    var sku:String
    var name:String
}
///Makes
///  - Pentair
///  - Hayward
///  - Zodiac
///  - Jandy

let pentairEquipment:[StandardEquipment] = [
    StandardEquipment(
        id: UUID().uuidString,
        category: .filter,
        make: "Pentair",
        model: "FNS 48",
        needsService: true,
        parts: [
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "53003201",
                name: "Gauge, pressure"
            ),
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "98209800",
                name: "High Flow Manual Air Relief Valve (HFMARV)"
            ),
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "98201200",
                name: "Hose and retainer clips for HFMARV (Optional accy.)"
            ),
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "58001100",
                name: "Nut, knurled brass"
            ),
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "59002100",
                name: "Tie Rod, 48 sq. ft. filter"
            ),
            StandardEquipmentPart(
                id: UUID().uuidString,
                sku: "59023700",
                name: "Manifold, top with air bleed"
            )
        ],
        manualPdfLink: ""
    )
]
let haywardEquipment:[StandardEquipment] = [

]
let zodiacEquipment:[StandardEquipment] = [

]
let jandyquipment:[StandardEquipment] = [

]
