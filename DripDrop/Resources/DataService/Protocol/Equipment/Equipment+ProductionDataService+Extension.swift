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
    
    var id : String = "com_equ_" + UUID().uuidString
    var name: String
    var type: EquipmentCategory
    var typeId: String
    var make : String
    var makeId :String //For Universal Equipment Says Custom If Not Selected
    var model : String //
    var modelId :String //For Universal equipment. Says Custom if not selected
    var dateInstalled : Date
    var status : EquipmentStatus
    var needsService : Bool
    var cleanFilterPressure: Int?
    var currentPressure: Int?

    var lastServiceDate : Date?
    var serviceFrequency : Int? //? Maybe number
    var serviceFrequencyEvery : EquipmentFrequency? //? Time Frequencies
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
        type :EquipmentCategory,
        typeId : String,
        make : String,
        makeId : String,
        model : String,
        modelId : String,
        dateInstalled  : Date,
        status:EquipmentStatus,
        needsService:Bool,
        cleanFilterPressure : Int? = nil,
        currentPressure : Int? = nil,

        lastServiceDate : Date? = nil,
        serviceFrequency : Int? = nil,
        serviceFrequencyEvery : EquipmentFrequency? = nil,
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

        self.type = type
        self.typeId = typeId
        self.make = make
        self.makeId = makeId
        self.model = model
        self.modelId = modelId
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

            case type = "type"
            case typeId = "typeId"
            case make = "make"
            case makeId = "makeId"
            case model = "model"
            case modelId = "modelId"
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
// MARK: - Maybe update
/*struct EquipmentServiceHistory: Identifiable, Codable, Equatable, Hashable {
 var id: String = "com_equ_sh_" + UUID().uuidString
 var name: String
 var type: EquipmentServiceType
 var date: Date
 var description: String
 var performedBy: ServicePerformaceType
 var addedBy: ServiceRecordType
 var techId: String
 var techName: String
 var jobId: String
 var partIds: [String]

 init(
     id: String,
     name: String,
     type: EquipmentServiceType,
     date: Date,
     description: String,
     performedBy: ServicePerformaceType,
     addedBy: ServiceRecordType,
     techId: String,
     techName: String,
     jobId: String,
     partIds: [String]
 ) {
     self.id = id
     self.name = name
     self.type = type
     self.date = date
     self.description = description
     self.performedBy = performedBy
     self.addedBy = addedBy
     self.techId = techId
     self.techName = techName
     self.jobId = jobId
     self.partIds = partIds
 }

 enum CodingKeys: String, CodingKey {
     case id
     case name
     case type
     case date
     case description
     case performedBy
     case addedBy
     case techId
     case techName
     case jobId
     case partIds
 }

 init(from decoder: Decoder) throws {
     let container = try decoder.container(keyedBy: CodingKeys.self)

     self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? "com_equ_sh_" + UUID().uuidString
     self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""

     let typeRaw = try container.decodeIfPresent(String.self, forKey: .type) ?? "Maintenance"
     self.type = EquipmentServiceType(rawValue: typeRaw) ?? .maintenance

     self.date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
     self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""

     let performedByRaw = try container.decodeIfPresent(String.self, forKey: .performedBy) ?? ""
     self.performedBy = ServicePerformaceType(rawValue: performedByRaw) ?? .unknown

     let addedByRaw = try container.decodeIfPresent(String.self, forKey: .addedBy) ?? ""
     self.addedBy = ServiceRecordType(rawValue: addedByRaw) ?? .unknown

     self.techId = try container.decodeIfPresent(String.self, forKey: .techId) ?? ""
     self.techName = try container.decodeIfPresent(String.self, forKey: .techName) ?? ""
     self.jobId = try container.decodeIfPresent(String.self, forKey: .jobId) ?? ""
     self.partIds = try container.decodeIfPresent([String].self, forKey: .partIds) ?? []
 }
}*/
struct EquipmentServiceHistory:Identifiable,Codable,Equatable,Hashable{
    
    var id : String = "com_equ_sh_" + UUID().uuidString
    var name: String
    var type: EquipmentServiceType
    var date: Date
    var description: String
    var performedBy: ServicePerformaceType
    var addedBy: ServiceRecordType
    var techId: String
    var techName: String
    var jobId: String
    var partIds: [String]
    init(
        id: String,
        name : String,
        type : EquipmentServiceType,
        date : Date,
        description : String,
        performedBy : ServicePerformaceType,
        addedBy : ServiceRecordType,
        techId:String,
        techName:String,
        jobId : String,
        partIds : [String],
    ){
        self.id = id
        self.name = name
        self.type = type
        self.date = date
        self.description = description
        self.performedBy = performedBy
        self.addedBy = addedBy
        self.techId = techId
        self.techName = techName
        self.jobId = jobId
        self.partIds = partIds
    }
    enum CodingKeys:String, CodingKey {
        case id = "id"
        case name = "name"
        case type = "type"
        case date = "date"
        case description = "description"
        case performedBy = "performedBy"
        case addedBy = "addedBy"
        case techId = "techId"
        case techName = "techName"
        case jobId = "jobId"
        case partIds = "partIds"
    }
}
struct EquipmentScheduledWork: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var type: EquipmentServiceType
    var serviceDate: Date?
    var techId: String
    var techName: String

    var serviceStopId: String
    var serviceStopInternalId: String

    var jobId: String
    var jobInternalId: String

    var status: EquipmentScheduledWorkStatus
    var description: String
    var dateCreated: Date
    var dateCompleted: Date?

    init(
        id: String = "com_equ_sw_" + UUID().uuidString,
        name: String,
        type: EquipmentServiceType,
        serviceDate: Date? = nil,
        techId: String = "",
        techName: String = "",
        serviceStopId: String = "",
        serviceStopInternalId: String = "",
        jobId: String = "",
        jobInternalId: String = "",
        status: EquipmentScheduledWorkStatus,
        description: String = "",
        dateCreated: Date = Date(),
        dateCompleted: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.serviceDate = serviceDate
        self.techId = techId
        self.techName = techName
        self.serviceStopId = serviceStopId
        self.serviceStopInternalId = serviceStopInternalId
        self.jobId = jobId
        self.jobInternalId = jobInternalId
        self.status = status
        self.description = description
        self.dateCreated = dateCreated
        self.dateCompleted = dateCompleted
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case serviceDate
        case techId
        case techName
        case serviceStopId
        case serviceStopInternalId
        case jobId
        case jobInternalId
        case status
        case description
        case dateCreated
        case dateCompleted
    }
}
enum EquipmentScheduledWorkStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    var id: String { rawValue }

    case draft = "Draft"
    case estimatePending = "Estimate Pending"
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case canceled = "Canceled"
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
    func equipmentServiceHistoryCollection(companyId:String,equipmentId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/equipment/\(equipmentId)/serviceHistory")
   }
    func equipmentServiceHistoryDoc(companyId:String,equipmentId:String,historyId:String)-> DocumentReference{
        equipmentServiceHistoryCollection(companyId: companyId, equipmentId:equipmentId).document(historyId)
  }
    //CREATE
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: false)
    }
    func uploadEquipmentHistory(companyId:String,equipmentId:String,history:EquipmentServiceHistory) async throws {
        try equipmentServiceHistoryCollection(companyId: companyId,equipmentId:equipmentId).document(history.id).setData(from:history, merge: false)
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
    
    func getAllEquipmentServiceHistory(companyId:String, equipmentId:String) async throws -> [EquipmentServiceHistory] {
        
        return try await equipmentServiceHistoryCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentServiceHistory.self)
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
            Equipment.CodingKeys.type.stringValue:category.rawValue
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
    func updateEquipmentServiceFrequency(companyId:String,equipmentId:String,serviceFrequency:Int) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequency.stringValue:serviceFrequency
        ])
    }
    func updateEquipmentServiceFrequencyEvery(companyId:String,equipmentId:String,serviceFrequencyEvery:EquipmentFrequency) throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.serviceFrequencyEvery.stringValue:serviceFrequencyEvery.rawValue
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
            Equipment.CodingKeys.type.stringValue:equipment.type,
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
                Equipment.CodingKeys.lastServiceDate.stringValue:equipment.lastServiceDate as Any,
                Equipment.CodingKeys.serviceFrequency.stringValue:equipment.serviceFrequency as Any,
                Equipment.CodingKeys.serviceFrequencyEvery.stringValue:equipment.serviceFrequencyEvery as Any,
                Equipment.CodingKeys.nextServiceDate.stringValue:equipment.nextServiceDate as Any,
            ])
        }
    }
    //DELETE
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        try await equipmentDoc(companyId: companyId, equipmentId: equipmentId).delete()
    }
}
