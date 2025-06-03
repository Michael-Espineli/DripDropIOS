//
//  Equipment+ProductionDataService+Extension.swift
//  DripDrop
//  EquipmentPart+ProductionDataService+Extension.swift
//  Created by Michael Espineli on 12/5/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage

struct Equipment:Identifiable,Codable,Equatable,Hashable{
    
    var id : String = "comp_equ_" + UUID().uuidString
    var name: String
    var category: EquipmentCategory
    var make : String
    var model : String
    var dateInstalled : Date
    var status : EquipmentStatus
    var needsService : Bool
    var cleanFilterPressure: Int?
    var currentPressure: Int?

    var lastServiceDate : Date?
    var serviceFrequency : String? //? Maybe number
    var serviceFrequencyEvery : String? //? Time Frequencies
    var nextServiceDate : Date?

    var notes : String
    var customerName : String
    var customerId : String

    var serviceLocationId : String
    var bodyOfWaterId : String
    var photoUrls:[DripDropStoredImage]?
    var isActive:Bool
    var dateUninstalled : Date?
    init(
        id: String,
        name :String,
        category :EquipmentCategory,
        make : String,
        model : String,
        dateInstalled  : Date,
        status:EquipmentStatus,
        needsService:Bool,
        cleanFilterPressure : Int? = nil,
        currentPressure : Int? = nil,

        lastServiceDate : Date? = nil,
        serviceFrequency : String? = nil,
        serviceFrequencyEvery : String? = nil,
        nextServiceDate : Date? = nil,
        notes : String,
        
        customerName : String,
        customerId : String,
        serviceLocationId  : String,
        bodyOfWaterId : String,
        photoUrls : [DripDropStoredImage]? = nil,
    
        isActive: Bool,
        dateUninstalled: Date? = nil
    ){
        self.id = id
        self.name = name

        self.category = category
        self.make = make
        self.model = model
        self.dateInstalled = dateInstalled
        self.status = status
        
        self.needsService = needsService
        self.cleanFilterPressure = cleanFilterPressure
        self.currentPressure = currentPressure
        self.lastServiceDate = lastServiceDate
        self.serviceFrequency = serviceFrequency
        self.serviceFrequencyEvery = serviceFrequencyEvery
        self.nextServiceDate = nextServiceDate
        self.notes = notes
        self.customerName = customerName
        self.customerId = customerId
        self.serviceLocationId = serviceLocationId
        self.bodyOfWaterId = bodyOfWaterId
        self.photoUrls = photoUrls
        
        self.isActive = isActive
        self.dateUninstalled = dateUninstalled
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case name = "name"

            case category = "category"
            case make = "make"
            case model = "model"
            case dateInstalled = "dateInstalled"
            case status = "status"
            case needsService = "needsService"
            case cleanFilterPressure = "cleanFilterPressure"
            case currentPressure = "currentPressure"
            
            case lastServiceDate = "lastServiceDate"
            case serviceFrequency = "serviceFrequency"
            case serviceFrequencyEvery = "serviceFrequencyEvery"
            case nextServiceDate = "nextServiceDate"
            case notes = "notes"
            case customerName = "customerName"
            case customerId = "customerId"
            case serviceLocationId = "serviceLocationId"
            case bodyOfWaterId = "bodyOfWaterId"
            case photoUrls = "photoUrls"
            case isActive = "isActive"
            case dateUninstalled = "dateUninstalled"
        }
}

extension ProductionDataService {
 
    func EquipmentImageRefrence(id:String)->StorageReference {
        storage.child("Equipment").child(id)
    }
     func equipmentCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment")
    }
    func equipmentDoc(companyId:String,equipmentId:String)-> DocumentReference{
       equipmentCollection(companyId: companyId).document(equipmentId)
   }
    //CREATE
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: false)
    }
    func uploadEquipmentImage(companyId: String,equipmentId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await EquipmentImageRefrence(id: equipmentId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (urlString,returnedName)
    }
    //READ
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
    //UPDATE
    func updateEquipmentName(companyId:String,equipmentId:String,name:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:name
        ])
    }
    func updateEquipmentCategory(companyId:String,equipmentId:String,category:EquipmentCategory) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.category.stringValue:category.rawValue
        ])
    }

    func updateEquipmentMake(companyId:String,equipmentId:String,make:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.make.stringValue:make
        ])
    }
    func updateEquipmentModel(companyId:String,equipmentId:String,model:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.model.stringValue:model
        ])
    }
    func updateEquipmentDateInstalled(companyId:String,equipmentId:String,dateInstalled:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.dateInstalled.stringValue:dateInstalled
        ])
    }
    func updateEquipmentStatus(companyId:String,equipmentId:String,status:EquipmentStatus) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.status.stringValue:status.rawValue
        ])
    }
    func updateEquipmentCleanFilterPressure(companyId:String,equipmentId:String,cleanFilterPressure:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.cleanFilterPressure.stringValue:cleanFilterPressure
        ])
    }
    func updateEquipmentCurrentPressure(companyId:String,equipmentId:String,currentPressure:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.currentPressure.stringValue:currentPressure
        ])
    }
    func updateEquipmentCleanLastServiceDate(companyId:String,equipmentId:String,lastServiceDate:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.lastServiceDate.stringValue:lastServiceDate
        ])
    }
    func updateEquipmentServiceFrequency(companyId:String,equipmentId:String,serviceFrequency:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequency.stringValue:serviceFrequency
        ])
    }
    func updateEquipmentServiceFrequencyEvery(companyId:String,equipmentId:String,serviceFrequencyEvery:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequencyEvery.stringValue:serviceFrequencyEvery
        ])
    }
    func updateEquipmentNextServiceDate(companyId: String, equipmentId: String, nextServiceDate: Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.nextServiceDate.stringValue:nextServiceDate
        ])
    }
    func updateEquipmentNotes(companyId:String,equipmentId:String,notes:String) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.notes.stringValue:notes
        ])
    }
    func updateEquipmentIsActive(companyId:String,equipmentId:String,isActive:Bool) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.isActive.stringValue:isActive
        ])
    }
    func updateEquipmentDateUninstalled(companyId:String,equipmentId:String,dateUninstalled:Date) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.dateUninstalled.stringValue:dateUninstalled
        ])
    }
    func updateEquipmentPhotoUrls(companyId:String,equipmentId:String,image:DripDropStoredImage) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.photoUrls.rawValue: FieldValue.arrayUnion([
                [
                "id":image.id,
                "description":image.description,
                "imageURL":image.imageURL
                ]
            ])
        ])
    }
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: true)
        
    }
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        try await equipmentRef.updateData([
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
        ])
        if equipment.needsService {
            try await equipmentRef.updateData([
                Equipment.CodingKeys.lastServiceDate.stringValue:equipment.lastServiceDate,
                Equipment.CodingKeys.serviceFrequency.stringValue:equipment.serviceFrequency,
                Equipment.CodingKeys.serviceFrequencyEvery.stringValue:equipment.serviceFrequencyEvery,
                Equipment.CodingKeys.nextServiceDate.stringValue:equipment.nextServiceDate,
            ])
        }
    }
    //DELETE
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        try await equipmentDoc(companyId: companyId, equipmentId: equipmentId).delete()
    }
}
