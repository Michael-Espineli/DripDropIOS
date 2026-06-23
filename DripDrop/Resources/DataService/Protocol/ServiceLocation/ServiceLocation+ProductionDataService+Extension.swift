    //
    //  ServiceLocation+ProductionDataService+Extension.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 12/7/24.
    //

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage
struct ServiceLocation: Identifiable, Codable,Hashable{
 
    var id:String
    var nickName:String
    var address:Address
    var gateCode:String
    var dogName:[String]?
    var estimatedTime:Int?
    var mainContact:Contact
    var notes:String?
    var bodiesOfWaterId:[String]
    let rateType : String //DEVELOPER Remove
    let laborType : String //DEVELOPER Remove
    let chemicalCost : String //DEVELOPER Remove
    let laborCost : String //DEVELOPER Remove
    let rate : String //DEVELOPER Remove
    var customerId:String
    var customerName:String
    var backYardTree:[String]?
    var backYardBushes:[String]?
    var backYardOther:[String]?
    var preText:Bool? //DEVELOPER Make Required
    var verified:Bool? //DEVELOPER Make Required

    var photoUrls:[DripDropStoredImage]? //DEVELOPER Make Required
    
    var isActive:Bool
    init(
        id: String,
        nickName :String,
        address : Address,
        gateCode : String,
        dogName: [String]? = nil,
        estimatedTime: Int? = nil,
        mainContact: Contact,
        notes : String? = nil,
        bodiesOfWaterId : [String],
        rateType: String,
        laborType: String,
        chemicalCost : String,
        laborCost : String,
        rate: String,
        customerId: String,
        customerName: String,
        backYardTree: [String]? = nil,
        backYardBushes: [String]? = nil,
        backYardOther: [String]? = nil,
        preText: Bool? = nil,
        verified: Bool? = nil,
        photoUrls: [DripDropStoredImage]? = nil,
        isActive: Bool


    ){
        self.id = id
        self.nickName = nickName
        self.address = address
        self.gateCode = gateCode
        self.dogName = dogName
        self.estimatedTime = estimatedTime
        self.mainContact = mainContact
        self.notes = notes
        self.bodiesOfWaterId = bodiesOfWaterId
        self.rateType = rateType
        self.laborType = laborType
        self.chemicalCost = chemicalCost
        self.laborCost = laborCost
        self.rate = rate

        self.customerId = customerId
        self.customerName = customerName
        self.backYardTree = backYardTree
        self.backYardBushes = backYardBushes
        self.backYardOther = backYardOther
        self.preText = preText
        self.verified = verified
        self.photoUrls = photoUrls
        self.isActive = isActive
        
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case nickName = "nickName"
            case address = "address"
            case gateCode = "gateCode"
            case dogName = "dogName"
            case estimatedTime = "estimatedTime"
            case mainContact = "mainContact"
            case notes = "notes"
            case bodiesOfWaterId = "bodiesOfWaterId"
            case rateType = "rateType"
            case laborType = "laborType"
            case chemicalCost = "chemicalCost"
            case laborCost = "laborCost"
            case rate = "rate"

            case customerId = "customerId"
            case customerName = "customerName"
            case backYardTree = "backYardTree"
            case backYardBushes = "backYardBushes"
            case backYardOther = "backYardOther"
            case preText = "preText"
            case verified = "verified"
            case photoUrls = "photoUrls"
            case isActive = "isActive"
        }
    private enum CompatibilityCodingKeys: String, CodingKey {
        case active
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let compatibilityContainer = try decoder.container(keyedBy: CompatibilityCodingKeys.self)

        func decodeString(_ key: CodingKeys) -> String {
            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                return value
            }

            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }

            if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
                return String(value)
            }

            if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
                return value ? "true" : "false"
            }

            return ""
        }

        func decodeBool(_ key: CodingKeys, defaultValue: Bool) -> Bool {
            if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
                return value
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if ["true", "yes", "1"].contains(normalized) {
                    return true
                }
                if ["false", "no", "0"].contains(normalized) {
                    return false
                }
            }

            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value != 0
            }

            return defaultValue
        }

        func decodeInt(_ key: CodingKeys) -> Int? {
            if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }

            if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
                return Int(value)
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                return Int(value)
            }

            return nil
        }

        func decodeStringArray(_ key: CodingKeys) -> [String] {
            if let values = try? container.decodeIfPresent([String].self, forKey: key) {
                return values
            }

            if let value = try? container.decodeIfPresent(String.self, forKey: key) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? [] : [trimmed]
            }

            return []
        }

        self.id = decodeString(.id)
        self.nickName = decodeString(.nickName)
        self.address = (try? container.decodeIfPresent(Address.self, forKey: .address)) ?? Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0)
        self.gateCode = decodeString(.gateCode)
        self.dogName = decodeStringArray(.dogName)
        self.estimatedTime = decodeInt(.estimatedTime)
        self.mainContact = (try? container.decodeIfPresent(Contact.self, forKey: .mainContact)) ?? Contact(id: "", name: "", phoneNumber: "", email: "")
        self.notes = try? container.decodeIfPresent(String.self, forKey: .notes)
        self.bodiesOfWaterId = decodeStringArray(.bodiesOfWaterId)
        self.rateType = decodeString(.rateType)
        self.laborType = decodeString(.laborType)
        self.chemicalCost = decodeString(.chemicalCost)
        self.laborCost = decodeString(.laborCost)
        self.rate = decodeString(.rate)
        self.customerId = decodeString(.customerId)
        self.customerName = decodeString(.customerName)
        self.backYardTree = decodeStringArray(.backYardTree)
        self.backYardBushes = decodeStringArray(.backYardBushes)
        self.backYardOther = decodeStringArray(.backYardOther)
        self.preText = decodeBool(.preText, defaultValue: false)
        self.verified = decodeBool(.verified, defaultValue: false)
        if let decodedPhotoUrls = try? container.decodeIfPresent([DripDropStoredImage].self, forKey: .photoUrls) {
            self.photoUrls = decodedPhotoUrls
        } else {
            self.photoUrls = nil
        }
        let compatibilityActive = (try? compatibilityContainer.decodeIfPresent(Bool.self, forKey: .active)) ?? true
        self.isActive = decodeBool(.isActive, defaultValue: compatibilityActive)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(nickName)
        hasher.combine(gateCode)
        hasher.combine(estimatedTime)
        hasher.combine(notes)
        hasher.combine(rate)

    }
    
    static func == (lhs: ServiceLocation, rhs: ServiceLocation) -> Bool {
        return lhs.id == rhs.id &&
        lhs.nickName == rhs.nickName &&
        lhs.gateCode == rhs.gateCode &&
        lhs.estimatedTime == rhs.estimatedTime &&
        lhs.notes == rhs.notes &&
        lhs.rate == rhs.rate


    }

}

extension ProductionDataService {
    //Refrences
    func serviceLocationCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/serviceLocations")
    }
    func serviceLocationDoc(companyId:String,serviceLocationId:String)-> DocumentReference{
        serviceLocationCollection(companyId: companyId).document(serviceLocationId)
    }    
    func ServiceLocationImageRefrence(companyId:String,id:String)->StorageReference {
        storage
            .child("companies")
            .child(companyId)
            .child("serviceLocations")
            .child(id)
    }

        //CREATE
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws{
        print("Uploading Service Location >>\(serviceLocation.id) For customer >> \(customer.firstName)")
        let coordinates = try await convertAddressToCordinates1(address: serviceLocation.address)
        print("Received Coordinates \(String(describing: coordinates))")
        var pushLocation = serviceLocation
        pushLocation.address.latitude = coordinates.latitude
        pushLocation.address.longitude = coordinates.longitude
        
        try serviceLocationCollection(companyId: companyId).document(serviceLocation.id).setData(from:serviceLocation, merge: false)
    }
    func uploadServiceLocationImage(companyId: String,serviceLocationId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await ServiceLocationImageRefrence(companyId: companyId, id: serviceLocationId).child(path)
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
    func getServiceLocationById(companyId:String,locationId:String) async throws -> ServiceLocation {
        return  try await serviceLocationDoc(companyId: companyId, serviceLocationId: locationId)
            .getDocument(as:ServiceLocation.self)
        
    }
    func getAllCompanyServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return try await serviceLocationCollection(companyId:companyId)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func getAllCustomerServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return try await serviceLocationCollection(companyId:companyId)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func get4CustomerServiceLocations(companyId:String,customer:Customer) async throws -> [ServiceLocation] {
        
        return  try await serviceLocationCollection(companyId:companyId)
            .limit(to: 4)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func getAllCustomerServiceLocationsId(companyId:String,customerId:String) async throws -> [ServiceLocation] {
        
        return  try await serviceLocationCollection(companyId: companyId)
            .whereField(ServiceLocation.CodingKeys.customerId.rawValue, isEqualTo: customerId)
            .getDocuments(as:ServiceLocation.self)
        
    }
        //Update

    func updateServiceLocationPhotoURLs(companyId: String, serviceLocationId: String, photoUrls: [DripDropStoredImage]) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        for image in photoUrls {
            try await serviceLocationRef.updateData([
                ServiceLocation.CodingKeys.photoUrls.rawValue: FieldValue.arrayUnion([
                    [
                    "id":image.id,
                    "description":image.description,
                    "imageURL":image.imageURL
                    ]
                ])
            ])
        }
        
    }
    func updateServiceLocationNickName(companyId: String, serviceLocationId: String, nickName: String) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.nickName.rawValue: nickName,
        ])
    }
    
    func updateServiceLocationGateCode(companyId: String, serviceLocationId: String, gateCode: String) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.gateCode.rawValue: gateCode,
        ])
    }
    
    func updateServiceLocationDogName(companyId:String,serviceLocationId:String,dogNames:[String])async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.dogName.rawValue: FieldValue.arrayUnion([dogNames]),
        ])
    }
    
    func updateServiceLocationEstimatedTime(companyId: String, serviceLocationId: String, estimatedTime: Int) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.estimatedTime.rawValue: estimatedTime,
        ])
    }
    
    func updateServiceLocationNotes(companyId: String, serviceLocationId: String, notes: String) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.notes.rawValue: notes,
        ])
    }
    
    func updateServiceLocationContact(companyId: String, serviceLocationId: String, contact: Contact) async throws {
        let customerRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        
        try await customerRef.updateData([
            ServiceLocation.CodingKeys.mainContact.rawValue: [
                Contact.CodingKeys.id.rawValue: contact.id,
                Contact.CodingKeys.name.rawValue: contact.name,
                Contact.CodingKeys.phoneNumber.rawValue: contact.phoneNumber,
                Contact.CodingKeys.email.rawValue: contact.email,
                Contact.CodingKeys.notes.rawValue: contact.notes,
            ] as [String : Any]
        ])
    }
    func updateServiceLocationPreText(companyId: String, serviceLocationId: String, preText: Bool) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)

        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.preText.rawValue: preText,
        ])
    }
    func updateServiceLocationIsActive(companyId: String, serviceLocationId: String, isActive: Bool) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)

        try await serviceLocationRef.updateData([
            ServiceLocation.CodingKeys.isActive.rawValue: isActive,
        ])
    }
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) async throws {
        let serviceLocationRef = serviceLocationDoc(companyId: companyId,serviceLocationId: serviceLocationId)
        
        try await serviceLocationRef.updateData(
            [
                ServiceLocation.CodingKeys.address.stringValue: [
                    Address.CodingKeys.streetAddress.stringValue: address.streetAddress,
                    Address.CodingKeys.city.stringValue: address.city,
                    Address.CodingKeys.state.stringValue: address.state,
                    Address.CodingKeys.zip.stringValue: address.zip,
                    Address.CodingKeys.latitude.stringValue:address.latitude ,
                    Address.CodingKeys.longitude.stringValue:address.longitude ,
                ] as [String : Any]
            ]
        )
    }
    
    func deactivateServiceLocationRelatedRecords(companyId:String,serviceLocationId:String)async throws {
        let equipmentSnapshot = try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in equipmentSnapshot.documents {
            try await document.reference.updateData([
                Equipment.CodingKeys.isActive.rawValue: false,
                "active": false
            ])
        }

        let bodyOfWaterSnapshot = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in bodyOfWaterSnapshot.documents {
            try await document.reference.updateData([
                BodyOfWater.CodingKeys.isActive.rawValue: false
            ])
        }

        let recurringServiceStopSnapshot = try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in recurringServiceStopSnapshot.documents {
            try await document.reference.delete()
        }

        let serviceStopSnapshot = try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in serviceStopSnapshot.documents {
            try await document.reference.delete()
        }
    }

        //Delete
    func deleteLocation(companyId:String,serviceLocationId:String)async throws {
        let equipmentSnapshot = try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in equipmentSnapshot.documents {
            try await document.reference.delete()
        }

        let bodyOfWaterSnapshot = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in bodyOfWaterSnapshot.documents {
            try await document.reference.delete()
        }

        let recurringServiceStopSnapshot = try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in recurringServiceStopSnapshot.documents {
            try await document.reference.delete()
        }

        let serviceStopSnapshot = try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments()
        for document in serviceStopSnapshot.documents {
            try await document.reference.delete()
        }

        try await serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId).delete()
    }
}
