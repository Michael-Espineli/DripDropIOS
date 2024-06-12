//
//  ServiceLocationManager.swift
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
        preText: Bool? = nil


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
protocol ServiceLocationManagerProtocol {
 
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllCompanyServiceLocations(companyId:String) async throws -> [ServiceLocation]
    func getAllCustomerServiceLocations(companyId:String) async throws -> [ServiceLocation]
    func get4CustomerServiceLocations(companyId:String,customer:Customer) async throws -> [ServiceLocation]
    func getAllCustomerServiceLocationsId(companyId:String,customerId:String) async throws -> [ServiceLocation]
    func getServiceLocationsCustomerAndLocationId(companyId:String,customerId:String,locationId:String) async throws -> ServiceLocation
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) throws
    func updateServiceLocation(companyId:String,currentCustomerId:String,serviceLocation:ServiceLocation) throws
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func searchForCustomersLocations(searchTerm:String,serviceLocation:[ServiceLocation])->[ServiceLocation]
}

final class MockServiceLocationManager:ServiceLocationManagerProtocol {
    
    static let shared = MockServiceLocationManager()
    init(){}
    private let mockServiceLocations:[ServiceLocation] = [
        ServiceLocation(
            id: "1",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Aphrodite",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "1",
            customerName: "Aphrodite",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [], 
            preText: false
        ),
        
        ServiceLocation(
            id: "2",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Athena",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "2",
            customerName: "Athena",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "3",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Artemis",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "3",
            customerName: "Artemis",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "4",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Aries",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "4",
            customerName: "Aries",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "5",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Apollo",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "5",
            customerName: "Apollo",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "6",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Demeter",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "6",
            customerName: "Demeter",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "7",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Dionysus",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "7",
            customerName: "Dionysus",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "8",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Hades",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "8",
            customerName: "Hades",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "9",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Hera",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "9",
            customerName: "Hera",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "10",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Poseidon",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "10",
            customerName: "Poseidon",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "11",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Zeus",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "11",
            customerName: "Zeus",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        )
    ]


    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func serviceLocationCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/serviceLocations")
    }

    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func serviceLocationDoc(companyId:String,serviceLocationId:String)-> DocumentReference{
        serviceLocationCollection(companyId: companyId).document(serviceLocationId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws{
    print("Successfulyy uploaded")
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllCompanyServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return mockServiceLocations
        
    }
    func getAllCustomerServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return mockServiceLocations

        
    }
    func get4CustomerServiceLocations(companyId:String,customer:Customer) async throws -> [ServiceLocation] {
        
        return mockServiceLocations

        
    }
    func getAllCustomerServiceLocationsId(companyId:String,customerId:String) async throws -> [ServiceLocation] {
        
        return mockServiceLocations
        
    }
    func getServiceLocationsCustomerAndLocationId(companyId:String,customerId:String,locationId:String) async throws -> ServiceLocation {
        let serviceableLocation = mockServiceLocations.first(where: {$0.customerId == customerId && $0.id == locationId})
        guard let location = serviceableLocation else {
            throw FireBaseRead.unableToRead
        }
        return location
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) throws {
        print("SuccessFully Updated")
    }
    func updateServiceLocation(companyId:String,currentCustomerId:String,serviceLocation:ServiceLocation) throws {
        print("SuccessFully Updated")

    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws {
        print("SuccessFully Deleted")

    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func searchForCustomersLocations(searchTerm:String,serviceLocation:[ServiceLocation])->[ServiceLocation]{
        var locationList:[ServiceLocation] = []
        let term = searchTerm.replacingOccurrences(of: " ", with: "")
        for location in serviceLocation {
            if location.address.streetAddress.lowercased().contains(term) || location.address.city.lowercased().contains(term) || location.address.state.lowercased().contains(term) || location.address.zip.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.customerName.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.mainContact.name.contains(term) {
                locationList.append(location)
            }
        }

        return locationList
    }
    
}

final class ServiceLocationManager:ServiceLocationManagerProtocol {
    
    static let shared = ServiceLocationManager()
    init(){}
    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func serviceLocationCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/serviceLocations")
    }

    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func serviceLocationDoc(companyId:String,serviceLocationId:String)-> DocumentReference{
        serviceLocationCollection(companyId: companyId).document(serviceLocationId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws{
        print("Uploading Service Location >>\(serviceLocation.id) For customer >> \(customer.firstName)")
        let coordinates = try await convertAddressToCordinates1(address: serviceLocation.address)
        print("Received Coordinates \(String(describing: coordinates))")
        var pushLocation = serviceLocation
        pushLocation.address.latitude = coordinates.latitude
        pushLocation.address.longitude = coordinates.longitude

        try serviceLocationCollection(companyId: companyId).document(serviceLocation.id).setData(from:serviceLocation, merge: true)
    }
    func updateServiceLocationLatLong(companyId:String,serviceLocationId:String,lat:Double,long:Double) throws{
      

        let locationRef = serviceLocationCollection(companyId: companyId).document(serviceLocationId)
        try locationRef.updateData([

            "address": [
                "latitude":lat ,
                "longitude":long ,
            ] as [String : Any],
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
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
    func getServiceLocationsCustomerAndLocationId(companyId:String,customerId:String,locationId:String) async throws -> ServiceLocation {
        return  try await serviceLocationDoc(companyId: companyId, serviceLocationId: locationId)
            .getDocument(as:ServiceLocation.self)
        
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) throws {
        let customerRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
        // Set the "capital" field of the city 'DC'
        customerRef.updateData([

            "address": [
                "City": address.city,
                "State": address.state,
                "StreetAddress": address.streetAddress,
                "Zip": address.zip,
                "latitude":address.latitude ,
                "longitude":address.longitude ,
            ] as [String : Any],
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceLocation(companyId:String,currentCustomerId:String,serviceLocation:ServiceLocation) throws {
        
        let customerRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocation.id)
        // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            "nickName": serviceLocation.nickName,
            "gateCode": serviceLocation.gateCode,
            "dogName": serviceLocation.dogName as Any,
            "estimatedTime": serviceLocation.estimatedTime as Any,
            "mainContact": [
                "Name": serviceLocation.mainContact.name,
                "phoneNumber": serviceLocation.mainContact.phoneNumber,
                "email": serviceLocation.mainContact.email,
                "notes": serviceLocation.mainContact.notes,
            ],
            "notes": serviceLocation.notes as Any,
            "rateType": serviceLocation.rateType,
            "laborType": serviceLocation.laborType,
            "chemicalCost": serviceLocation.chemicalCost,
            "laborCost": serviceLocation.laborCost,
            "rate": serviceLocation.rate,
            "customerName": serviceLocation.customerName,
            "address": [
                "City": serviceLocation.address.city,
                "State": serviceLocation.address.state,
                "StreetAddress": serviceLocation.address.streetAddress,
                "Zip": serviceLocation.address.zip,
                "latitude":serviceLocation.address.latitude ,
                "longitude":serviceLocation.address.longitude,
            ] as [String : Any],
            
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
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws {
        try await serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId).delete()
        
    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    func searchForCustomersLocations(searchTerm:String,serviceLocation:[ServiceLocation])->[ServiceLocation]{
        var locationList:[ServiceLocation] = []
        let term = searchTerm.replacingOccurrences(of: " ", with: "")
        for location in serviceLocation {
            if location.address.streetAddress.lowercased().contains(term) || location.address.city.lowercased().contains(term) || location.address.state.lowercased().contains(term) || location.address.zip.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.customerName.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.mainContact.name.contains(term) {
                locationList.append(location)
            }
        }

        return locationList
    }
    
}
