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
struct ServiceLocation:Identifiable, Codable,Hashable{
 
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
        photoUrls: [DripDropStoredImage]? = nil


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
    func ServiceLocationImageRefrence(id:String)->StorageReference {
        storage.child("serviceLocation").child(id)
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
        
        let returnedMetaData = try await ServiceLocationImageRefrence(id: serviceLocationId).child(path)
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
        //Delete
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws {
        try await serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId).delete()
        
    }
}
