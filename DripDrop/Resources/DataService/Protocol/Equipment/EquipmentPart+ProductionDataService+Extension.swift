//
//  EquipmentPart+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/5/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
struct EquipmentPart:Identifiable, Codable{
    var id:String
    var equipmentType:EquipmentCategory
    var name:String
    var date:Date
    var notes:String

}
extension ProductionDataService {
    
    func equipmentPartCollection(companyId:String,equipmentId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment/\(equipmentId)/parts")
    }
    func equipmentMeasurmentsCollection(companyId:String,equipmentId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment/\(equipmentId)/equipmentMeasurments")
    }
    
}
