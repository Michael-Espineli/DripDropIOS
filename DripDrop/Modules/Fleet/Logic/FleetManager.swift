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


struct Vehical:Identifiable,Codable,Equatable{
    var id : String
    var nickName: String
    var vehicalType: VehicalType
    var year : String
    var make : String
    var model : String
    var color : String
    var plate : String
    var datePurchased : Date
    var miles : Double
    var status: VehicalStatus
    
    static func == (lhs: Vehical, rhs: Vehical) -> Bool {
        return lhs.id == rhs.id
    }
}
struct VehicalTrips:Identifiable,Codable,Equatable{
    var id : String = UUID().uuidString

}
protocol FleetManagerProtocol {
    func readFleetList(companyId:String) -> [Vehical]
    
}
final class FleetManager:FleetManagerProtocol {
    func readFleetList(companyId:String) -> [Vehical]{
        return []
    }
    
}
