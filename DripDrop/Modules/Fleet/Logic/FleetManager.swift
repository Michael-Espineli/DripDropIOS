//
//  FleetManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/20/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

struct Vehical:Identifiable,Codable{
    var id : String
    var nickName: String
    var vehicalType: String
    var year : String
    var make : String
    var model : String
    var color : String
    var plate : String

    var datePurchased : Date
    var miles : Double
}

protocol FleetManagerProtocol {
    func readFleetList(companyId:String) -> [Vehical]
    
}
final class FleetManager:FleetManagerProtocol {
    func readFleetList(companyId:String) -> [Vehical]{
        return [
            Vehical(id: UUID().uuidString, nickName: "Betsy", vehicalType: "Truck", year: "2019", make: "Toyota", model: "Tundra", color: "White", plate: "7FKHNUD", datePurchased: Date(), miles: 2234654),
            Vehical(id: UUID().uuidString, nickName: "jordan", vehicalType: "Truck", year: "1994", make: "Toyota", model: "Pick Up", color: "Red", plate: "7FKHNUD", datePurchased: Date(), miles: 245654),
            Vehical(id: UUID().uuidString, nickName: "Green", vehicalType: "Truck", year: "2013", make: "Nissan", model: "Datsun", color: "Green", plate: "7FKHNUD", datePurchased: Date(), miles: 34566),
            Vehical(id: UUID().uuidString, nickName: "Blue", vehicalType: "Truck", year: "2000", make: "Nissan", model: "Frontier", color: "Blue", plate: "7FKHNUD", datePurchased: Date(), miles: 35463456),
            Vehical(id: UUID().uuidString, nickName: "White", vehicalType: "Truck", year: "2020", make: "Toyota", model: "Tacoma", color: "White", plate: "7FKHNUD", datePurchased: Date(), miles: 356346),
            Vehical(id: UUID().uuidString, nickName: "Black", vehicalType: "Van", year: "2004", make: "Ford", model: "Ranger", color: "Black", plate: "7FKHNUD", datePurchased: Date(), miles: 3456456)
        ]
    }
    
}
