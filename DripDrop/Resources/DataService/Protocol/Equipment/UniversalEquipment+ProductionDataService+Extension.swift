//
//  UniversalEquipment+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/6/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
struct UniversalEquipmentType:Identifiable, Codable,Hashable{
    let id :String
    let name: String
    let description : String
}
struct UniversalEquipmentMake:Identifiable, Codable,Hashable{
    let id :String
    let name: String
    let description : String
    let types : [String]
    
}
struct UniversalEquipment:Identifiable, Codable,Hashable{
    var id :String = "univ_equi_" + UUID().uuidString
    let name: String
    let typeId: String
    let type: String
    let makeId: String
    let make: String
    let model: String
    let manualPdfLink: String
}
struct UniversalPart:Identifiable, Codable,Hashable{
    let id :String
    let name: String
    let make: String
    let model: String
    let manualPdfLink: String
}
extension ProductionDataService {
    func UniversalEquipmentStatsDoc() -> DocumentReference{
        db.collection("universal").document("equipment")
    }
    
    func UniversalEquipmentTypesCollection() -> CollectionReference{
        db.collection("universal/equipment/equipmentTypes")
    }
    func UniversalEquipmentMakesCollection() -> CollectionReference{
        db.collection("universal/equipment/equipmentMakes")
    }
    func UniversalEquipmentCollection() -> CollectionReference{
        db.collection("universal/equipment/equipment")
    }
    func UniversalEquipmentPartsCollection(equipmentId:String) -> CollectionReference{
        db.collection("universal/equipment/equipment/\(equipmentId)/parts")
    }
    //CREATE
    //READ
    func getUniversalEquipmentTypes() async throws -> [UniversalEquipmentType] {
        print("getUniversalEquipmentTypes")

        return try await UniversalEquipmentTypesCollection()
            .getDocuments(as:UniversalEquipmentType.self)
    }
    func getUniversalEquipmentBrandsByType(type:UniversalEquipmentType) async throws -> [UniversalEquipmentMake] {
        print("getUniversalEquipmentBrandsByType")
        return try await UniversalEquipmentMakesCollection()
            .whereField("types", arrayContains: type.id)
            .getDocuments(as:UniversalEquipmentMake.self)
    }
    func getUniversalEquipmentByTypeAndBrand(type:UniversalEquipmentType,make:UniversalEquipmentMake) async throws -> [UniversalEquipment] {
        print("getUniversalEquipmentByTypeAndBrand")
        
        return try await UniversalEquipmentCollection()
            .whereField("typeId", isEqualTo: type.id)
            .whereField("makeId", isEqualTo: make.id)
            .getDocuments(as:UniversalEquipment.self)
    }
    func getUniversalEquipmentPartsEquipment(equipmentId:String) async throws -> [UniversalPart] {
        print("getUniversalEquipmentPartsEquipment")

        return try await UniversalEquipmentPartsCollection(equipmentId:equipmentId)
            .getDocuments(as:UniversalPart.self)
    }
    //UPDATE
    //DELETE
}
