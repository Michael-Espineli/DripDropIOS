//
//  EquipmentManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin



protocol EquipmentManagerProtocol {
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadEquipment(companyId:String,equipment:Equipment) async throws
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllEquipment(companyId:String) async throws -> [Equipment]
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment]

    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment]
    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?)
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws 

    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteEquipment(companyId:String,equipmentId:String) async throws
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func addListenerForAllEquipment(companyId: String,amount:Int, completion: @escaping ([Equipment]) -> Void)
    func removeEquipmentListener()
}
final class MockEquipmentManager:EquipmentManagerProtocol {
    
    static let shared = EquipmentManager()
    init(){}
    private let db = Firestore.firestore()
    
    private var equipmentListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func equipmentCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/equipment")
    }
    private func equipmentPartCollection(companyId:String,equipmentId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/equipment/\(equipmentId)/parts")
    }
    
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func equipmentDoc(companyId:String,equipmentId:String)-> DocumentReference{
        equipmentCollection(companyId: companyId).document(equipmentId)
    }
    private func equipmentPartDoc(companyId:String,equipmentId:String,partId:String)-> DocumentReference{
        equipmentPartCollection(companyId: companyId, equipmentId: equipmentId).document(partId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: false)
        
    }
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws {
        try await EquipmentManager.shared.uploadEquipment(companyId: companyId, equipment: equipment)
        print("\(equipment.category)")
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in filterPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .pump:

            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            ]
            for part in pumpPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Returned")
            return
        }
    }
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws {
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Filter")
            
            for part in filterPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
            
        case .pump:

            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .cleaner:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Tires/Wheel",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Gear Box",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Turbine",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Hose",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            
            ]
            print("Vacuum")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .saltCell:

            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .saltCell,
                    name: "Salt Cell",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            ]
            print("Salt Cell")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .heater:

            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .heater,
                    name: "Heater",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                //DEVELOPER HERE
                
            ]
            print("Heater")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .light:

            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .light,
                    name: "Light",
                    date: Date(),
                    notes: ""
                ),
                
            ]
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Return")
            return
        }
    }
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
        try equipmentPartDoc(companyId: companyId,equipmentId: equipmentId,partId: part.id)
            .setData(from:part, merge: false)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment] {
        return []
    }
    
    func getAllEquipment(companyId:String) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .getDocuments(as:Equipment.self)
    }


    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.bodyOfWaterId.rawValue, isEqualTo: bodyOfWater.id)
            .getDocuments(as:Equipment.self)
    }
    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment{
        
        return try await equipmentDoc(companyId: companyId,equipmentId: equipmentId).getDocument(as: Equipment.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]{
        
        return try await equipmentPartCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentPart.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)

        } else {
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
    }
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws {
    }
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:equipment.name,
            Equipment.CodingKeys.category.stringValue:equipment.category,
            Equipment.CodingKeys.make.stringValue:equipment.make,
            Equipment.CodingKeys.model.stringValue:equipment.model,
            Equipment.CodingKeys.dateInstalled.stringValue:equipment.dateInstalled,
            Equipment.CodingKeys.status.stringValue:equipment.status,
            Equipment.CodingKeys.needsService.stringValue:equipment.needsService,
            Equipment.CodingKeys.customerId.stringValue:equipment.customerId,
            Equipment.CodingKeys.serviceLocationId.stringValue:equipment.serviceLocationId,
            Equipment.CodingKeys.bodyOfWaterId.stringValue:equipment.bodyOfWaterId,
        ]) { err in
            if let err = err {
                print("Error updating Equipment: \(err)")
            } else {
                print("Equipment successfully updated")
            }
        }
        if equipment.needsService {
            equipmentRef.updateData([
                Equipment.CodingKeys.lastServiceDate.stringValue:equipment.lastServiceDate,
                Equipment.CodingKeys.serviceFrequency.stringValue:equipment.serviceFrequency,
                Equipment.CodingKeys.serviceFrequencyEvery.stringValue:equipment.serviceFrequencyEvery,
                Equipment.CodingKeys.nextServiceDate.stringValue:equipment.nextServiceDate,
            ]) { err in
                if let err = err {
                    print("Error updating equipment: \(err)")
                } else {
                    print("Equipment successfully updated")
                }
            }
        }
    }
    func addListenerForAllEquipment(companyId: String,amount:Int, completion: @escaping ([Equipment]) -> Void) {
        let listener = equipmentCollection(companyId: companyId)
            .limit(to: amount)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Chat Collection")
                    return
                }
                let equipmentList: [Equipment] = documents.compactMap({try? $0.data(as: Equipment.self)})
                print("Successfully Received \(equipmentList.count) Equipments")
                completion(equipmentList)
            }
        self.equipmentListener = listener
    }
    func removeEquipmentListener() {
        self.equipmentListener?.remove()

    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        
    }

    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}
final class EquipmentManager:EquipmentManagerProtocol {
    
    static let shared = EquipmentManager()
    init(){}
    private let db = Firestore.firestore()
    private var equipmentListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func equipmentCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/equipment")
    }
    private func equipmentPartCollection(companyId:String,equipmentId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/equipment/\(equipmentId)/parts")
    }
    
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func equipmentDoc(companyId:String,equipmentId:String)-> DocumentReference{
        equipmentCollection(companyId: companyId).document(equipmentId)
    }
    private func equipmentPartDoc(companyId:String,equipmentId:String,partId:String)-> DocumentReference{
        equipmentPartCollection(companyId: companyId, equipmentId: equipmentId).document(partId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: false)
        
    }
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws {
        try await EquipmentManager.shared.uploadEquipment(companyId: companyId, equipment: equipment)
        print("\(equipment.category)")
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in filterPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            
            ]
            for part in pumpPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Returned")
            return
        }
    }
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws {
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Filter")
            
            for part in filterPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
            
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            
            ]
            
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .cleaner:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Tires/Wheel",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Gear Box",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Turbine",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Hose",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            
            ]
            print("Vacuum")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .saltCell:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .saltCell,
                    name: "Salt Cell",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            ]
            print("Salt Cell")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .heater:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .heater,
                    name: "Heater",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                //DEVELOPER HERE
                
            ]
            print("Heater")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .light:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .light,
                    name: "Light",
                    date: Date(),
                    notes: ""
                ),
                
            ]
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Return")
            return
        }
    }
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
        try equipmentPartDoc(companyId: companyId,equipmentId: equipmentId,partId: part.id)
            .setData(from:part, merge: false)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            print(" - - - Has Old Doc")
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)

        } else {
            print(" - - - Does Not have First Doc")

            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment] {
        return try await equipmentCollection(companyId: companyId)
            .limit(to: 10)
            .getDocuments(as:Equipment.self)
    }
    func getAllEquipment(companyId:String) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .getDocuments(as:Equipment.self)
    }
    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.bodyOfWaterId.rawValue, isEqualTo: bodyOfWater.id)
            .getDocuments(as:Equipment.self)
    }
    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment{
        
        return try await equipmentDoc(companyId: companyId,equipmentId: equipmentId).getDocument(as: Equipment.self)
        //            .getDocuments(as:Equipment.self)
    }
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]{
        
        return try await equipmentPartCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentPart.self)
        //            .getDocuments(as:Equipment.self)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
    }
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:equipment.name,
            Equipment.CodingKeys.category.stringValue:equipment.category,
            Equipment.CodingKeys.make.stringValue:equipment.make,
            Equipment.CodingKeys.model.stringValue:equipment.model,
            Equipment.CodingKeys.dateInstalled.stringValue:equipment.dateInstalled,
            Equipment.CodingKeys.status.stringValue:equipment.status,
            Equipment.CodingKeys.needsService.stringValue:equipment.needsService,
            Equipment.CodingKeys.customerId.stringValue:equipment.customerId,
            Equipment.CodingKeys.serviceLocationId.stringValue:equipment.serviceLocationId,
            Equipment.CodingKeys.bodyOfWaterId.stringValue:equipment.bodyOfWaterId,
        ]) { err in
            if let err = err {
                print("Error updating Equipment: \(err)")
            } else {
                print("Equipment successfully updated")
            }
        }
        if equipment.needsService {
            equipmentRef.updateData([
                Equipment.CodingKeys.lastServiceDate.stringValue:equipment.lastServiceDate,
                Equipment.CodingKeys.serviceFrequency.stringValue:equipment.serviceFrequency,
                Equipment.CodingKeys.serviceFrequencyEvery.stringValue:equipment.serviceFrequencyEvery,
                Equipment.CodingKeys.nextServiceDate.stringValue:equipment.nextServiceDate,
            ]) { err in
                if let err = err {
                    print("Error updating equipment: \(err)")
                } else {
                    print("Equipment successfully updated")
                }
            }
        }
    }
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: true)

    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        try await equipmentDoc(companyId: companyId, equipmentId: equipmentId).delete()
    }

    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func addListenerForAllEquipment(companyId: String,amount:Int, completion: @escaping ([Equipment]) -> Void) {
        let listener = equipmentCollection(companyId: companyId)
            .limit(to: amount)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Chat Collection")
                    return
                }
                let equipmentList: [Equipment] = documents.compactMap({try? $0.data(as: Equipment.self)})
                print("Successfully Received \(equipmentList.count) Equipments")
                completion(equipmentList)
            }
        self.equipmentListener = listener
    }
    func removeEquipmentListener() {
        self.equipmentListener?.remove()

    }
}
