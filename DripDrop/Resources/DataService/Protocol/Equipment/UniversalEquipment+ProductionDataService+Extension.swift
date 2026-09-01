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
    var id :String
    let name: String
    let description : String
}
struct UniversalEquipmentMake:Identifiable, Codable,Hashable{
    var id :String
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

private func universalCatalogString(_ data: [String: Any], _ key: String) -> String {
    if let value = data[key] as? String {
        return value
    }

    if let value = data[key] {
        return String(describing: value)
    }

    return ""
}

private func universalCatalogStringArray(_ data: [String: Any], _ key: String) -> [String] {
    data[key] as? [String] ?? []
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

        let snapshot = try await UniversalEquipmentTypesCollection().getDocuments()
        return snapshot.documents.map { document in
            let data = document.data()
            return UniversalEquipmentType(
                id: universalCatalogString(data, "id").isEmpty ? document.documentID : universalCatalogString(data, "id"),
                name: universalCatalogString(data, "name"),
                description: universalCatalogString(data, "description")
            )
        }
    }
    func getUniversalEquipmentBrandsByType(type:UniversalEquipmentType) async throws -> [UniversalEquipmentMake] {
        print("getUniversalEquipmentBrandsByType")
        let snapshot = try await UniversalEquipmentMakesCollection()
            .whereField("types", arrayContains: type.id)
            .getDocuments()
        return snapshot.documents.map { document in
            let data = document.data()
            return UniversalEquipmentMake(
                id: universalCatalogString(data, "id").isEmpty ? document.documentID : universalCatalogString(data, "id"),
                name: universalCatalogString(data, "name"),
                description: universalCatalogString(data, "description"),
                types: universalCatalogStringArray(data, "types")
            )
        }
    }
    func getUniversalEquipmentByTypeAndBrand(type:UniversalEquipmentType,make:UniversalEquipmentMake) async throws -> [UniversalEquipment] {
        print("getUniversalEquipmentByTypeAndBrand")
        
        let snapshot = try await UniversalEquipmentCollection()
            .whereField("typeId", isEqualTo: type.id)
            .whereField("makeId", isEqualTo: make.id)
            .getDocuments()
        return snapshot.documents.map { document in
            let data = document.data()
            return UniversalEquipment(
                id: universalCatalogString(data, "id").isEmpty ? document.documentID : universalCatalogString(data, "id"),
                name: universalCatalogString(data, "name"),
                typeId: universalCatalogString(data, "typeId"),
                type: universalCatalogString(data, "type"),
                makeId: universalCatalogString(data, "makeId"),
                make: universalCatalogString(data, "make"),
                model: universalCatalogString(data, "model").isEmpty ? universalCatalogString(data, "name") : universalCatalogString(data, "model"),
                manualPdfLink: universalCatalogString(data, "manualPdfLink")
            )
        }
    }
    func getUniversalEquipmentPartsEquipment(equipmentId:String) async throws -> [UniversalPart] {
        print("getUniversalEquipmentPartsEquipment")

        let snapshot = try await UniversalEquipmentPartsCollection(equipmentId:equipmentId).getDocuments()
        return snapshot.documents.map { document in
            let data = document.data()
            return UniversalPart(
                id: universalCatalogString(data, "id").isEmpty ? document.documentID : universalCatalogString(data, "id"),
                name: universalCatalogString(data, "name"),
                make: universalCatalogString(data, "make"),
                model: universalCatalogString(data, "model"),
                manualPdfLink: universalCatalogString(data, "manualPdfLink")
            )
        }
    }
    //UPDATE
    //DELETE
}
