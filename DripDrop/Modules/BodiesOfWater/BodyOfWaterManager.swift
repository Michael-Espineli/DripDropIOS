//
//  BodyOfWaterManager.swift
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
enum BodyOfWaterMaterial:String,Codable,CaseIterable {
    case plaster = "Plaster"
    case fiberGlass = "Fiber Glass"
    case vinyl = "Vinyl"
    case pebble = "Pebble"
    case tile = "Tile"

}
struct BodyOfWater:Identifiable, Codable,Equatable,Hashable{
    static func == (lhs: BodyOfWater, rhs: BodyOfWater) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.gallons == rhs.gallons &&
        lhs.material == rhs.material &&
        lhs.serviceLocationId == rhs.serviceLocationId &&
        lhs.notes == rhs.notes &&
        lhs.shape == rhs.shape
    }
    var id:String
    var name:String
    var gallons:String
    var material:String
    var customerId : String
    var serviceLocationId : String
    var notes:String?
    var shape:String?
    var length:[String]?
    var depth:[String]?
    var width:[String]?
    init(
        id: String,
        name :String,
        gallons : String,
        material : String,
        customerId : String,
        serviceLocationId:String,
        notes: String? = nil,
        shape : String? = nil,
        length : [String]? = nil,
        depth : [String]? = nil,
        width : [String]? = nil
    ){
        self.id = id
        self.name = name
        self.gallons = gallons
        self.material = material
        self.customerId = customerId
        self.serviceLocationId = serviceLocationId
        self.notes = notes
        self.shape = shape
        self.length = length
        self.depth = depth
        self.width = width
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"
            case gallons = "gallons"
            case material = "material"
            case customerId = "customerId"
            case serviceLocationId = "serviceLocationId"
            case notes = "notes"
            case shape = "shape"
            case length = "length"
            case depth = "depth"
            case width = "width"
        }
}
protocol BodyOfWaterManagerProtocol {

    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadServiceLocationBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws
    func uploadBodyOfWaterByServiceLocation(companyId:String,bodyOfWater:BodyOfWater) async throws
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId:String,customerId:String,companyId:String) async throws -> [BodyOfWater]
    func getAllBodiesOfWaterByServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws -> [BodyOfWater]
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws -> [BodyOfWater]
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId:String) async throws -> Int
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) throws
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) throws
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) throws
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) throws
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) throws
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) throws
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) throws
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) throws
    func editBodyOfWater(companyId:String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) throws
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}

final class MockBodyOfWaterManager:BodyOfWaterManagerProtocol {
    
    let mockBodiesOfWater:[BodyOfWater] = [
    ]
    func uploadServiceLocationBodyOfWater(companyId: String, bodyOfWater: BodyOfWater) async throws {
        print("Upload Successful")
    }
    
    func uploadBodyOfWaterByServiceLocation(companyId: String, bodyOfWater: BodyOfWater) async throws {
        print("Upload Successful")

    }
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater{
        print("Upload Successful")
        return BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "")

    }
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId: String, customerId: String, companyId: String) async throws -> [BodyOfWater] {
        return mockBodiesOfWater
    }
    
    func getAllBodiesOfWaterByServiceLocation(companyId: String, serviceLocation: ServiceLocation) async throws -> [BodyOfWater] {
        return mockBodiesOfWater
    }
    
    func getAllBodiesOfWaterByServiceLocationId(companyId: String, serviceLocationId: String) async throws -> [BodyOfWater] {
        return mockBodiesOfWater
    }
    
    func getBodiesOfWaterCount(serviceLocationId: String, customerId: String, companyId: String) async throws -> Int {
        return 1
    }
    
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) throws{

    }
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) throws{

    }
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) throws{

    }
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) throws{

    }
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) throws{

    }
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) throws{

    }
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) throws{
  
    }
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) throws{

    }
    func editBodyOfWater(companyId: String, bodyOfWater: BodyOfWater, updatedBodyOfWater: BodyOfWater) throws {
        print("Edited Body Of Water")
    }
   
}

final class BodyOfWaterManager:BodyOfWaterManagerProtocol {
    
    static let shared = BodyOfWaterManager()
    init(){}
    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func bodyOfWaterCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/bodiesOfWater")
    }

    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func bodyOfWaterDoc(companyId:String,bodyOfWaterId:String)-> DocumentReference{
        bodyOfWaterCollection(companyId: companyId).document(bodyOfWaterId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadServiceLocationBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        print(companyId)
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }
    func uploadBodyOfWaterByServiceLocation(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }

    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId:String,customerId:String,companyId:String) async throws -> [BodyOfWater] {
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print("collection")
        print(collection)
        return collection
    }
    func getAllBodiesOfWater(companyId:String) async throws -> [BodyOfWater] {

        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws -> [BodyOfWater] {

        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocation.id)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws -> [BodyOfWater] {
print(serviceLocationId)
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId:String) async throws -> Int {
        let collection =  bodyOfWaterCollection(companyId: companyId)
        let countQuery = collection.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return Int(truncating: snapshot.count)
        } catch {
            print(error)
            return 0
        }
    }
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater{
        return try await bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId).getDocument(as:BodyOfWater.self)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "name":name
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Name: \(err)")
            } else {
                print("Document successfully updated Body Of Water Name")
            }
        }
    }
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "gallons":gallons
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Gallons: \(err)")
            } else {
                print("Document successfully updated Body Of Water Gallons")
            }
        }
    }
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "material":material
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Material: \(err)")
            } else {
                print("Document successfully updated Material")
            }
        }
    }
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "notes":notes
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Notes: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Notes")
            }
        }
    }
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "shape":shape
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Shape: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Shape")
            }
        }
    }
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "length":length
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Length: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Length")
            }
        }
    }
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "depth":depth
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Depth: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Depth")
            }
        }
    }
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "width":width
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Width: \(err)")
            } else {
                print("Document successfully updated Body Of Water Width")
            }
        }
    }

    func editBodyOfWater(companyId:String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)

        
        bodyOfWaterRef.updateData([
            "gallons":updatedBodyOfWater.gallons,
            "material":updatedBodyOfWater.material,
            "name":updatedBodyOfWater.name
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}
