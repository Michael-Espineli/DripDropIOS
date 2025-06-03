//
//  Customer+ProductionDataService+Extension.swift
//  DripDrop
//  
//  Created by Michael Espineli on 12/1/24.
// 

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    func customerCollection(companyId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/customers")
   }
    func customerDocument(customerId:String,companyId:String)-> DocumentReference{
       customerCollection(companyId: companyId).document(customerId)
   }
    func customerContactCollection(companyId:String,customerId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/customers/\(customerId)/contacts")
    }
    //CREATE
    func uploadCSVCustomerToFireStore(companyId:String,customer: CSVCustomer) async throws{
        
        print("Begin to UpLoad \(customer.firstName) \(customer.lastName) to Firestore 1")
        let identification:String = UUID().uuidString
        var DBAddress = Address(streetAddress: customer.streetAddress, city: customer.city, state: customer.state, zip: customer.zip,latitude: 0.0,longitude: 0.0)
        
        let fulladdress = DBAddress.streetAddress + " " + DBAddress.city + " " + DBAddress.state + " " + DBAddress.zip
        let fullName = customer.firstName + " " + customer.lastName
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate
        }
        //add back in before production or if I am adding more than 50 customers
        let hireDateString = customer.hireDate
        
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        
        // Convert String to Date
        let hireDate:Date = dateFormatter.date(from: hireDateString) ?? Date()
        
        usleep(1201000)
        
        let pushCoordinates = self.Coordinates
        DBAddress.latitude = pushCoordinates?.latitude ?? 32.8
        DBAddress.longitude = pushCoordinates?.longitude ?? -117.8
        print("Received Coordinates from geoCoder : \(String(describing: pushCoordinates))")
        
        let DBCustomer:Customer = Customer(
            id: identification,
            firstName: customer.firstName ,
            lastName:customer.lastName,
            email:customer.email,
            billingAddress:DBAddress ,
            phoneNumber: customer.phone,
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: hireDate,
            billingNotes: "NA",
            linkedInviteId: UUID().uuidString
        )
        
        print("Uploading Customer - \(customer.firstName) - \(customer.lastName)")
        try await customerDocument(customerId: DBCustomer.id, companyId: companyId).setData(from:DBCustomer, merge: false)
        let serviceLocationId:String = UUID().uuidString
        let bodyOfWaterId:String = UUID().uuidString
        
        sleep(1)
        //Uploading Customer Billing Type
        let billingTempalte = try await BillingManager.shared.getDefaultBillingTempalte(companyId: companyId)
        
        //Uploading Customer Service Locations
        
        let serviceLocation:ServiceLocation = ServiceLocation(
            id: serviceLocationId,
            nickName: (
                (
                    DBCustomer.firstName
                ) + " " + (
                    DBCustomer.lastName
                )
            ),
            address: DBCustomer.billingAddress,
            gateCode: "",
            estimatedTime: 15,
            mainContact: Contact(
                id: UUID().uuidString,
                name: (
                    (
                        DBCustomer.firstName
                    ) + " " + (
                        DBCustomer.lastName
                    )
                ),
                phoneNumber: DBCustomer.phoneNumber ?? "",
                email: DBCustomer.email,
                notes: ""
            ),
            bodiesOfWaterId: [bodyOfWaterId],
            rateType: billingTempalte.title,
            laborType: billingTempalte.laborType,
            chemicalCost: billingTempalte.chemType,
            laborCost: "15",
            rate: customer.rate,
            customerId: DBCustomer.id,
            customerName: (
                (
                    DBCustomer.firstName
                ) + " " + (
                    DBCustomer.lastName
                )
            ),
            preText: false
        )
        
        try await ServiceLocationManager.shared.uploadCustomerServiceLocations(
            companyId: companyId,
            customer: DBCustomer,
            serviceLocation: serviceLocation
        )
        print(
            " - Service Location - Check"
        )
        
        //Uploading Body of water
        
        let bodyOfwater = BodyOfWater(
            id: bodyOfWaterId,
            name: "Main",
            gallons: "16000",
            material: "Plaster",
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            lastFilled: Date()
        )
        try await BodyOfWaterManager.shared.uploadBodyOfWaterByServiceLocation(
            companyId:companyId,
            bodyOfWater: bodyOfwater
        )
        print(
            " - Body Of Water - Check"
        )
        let pump = Equipment(
            id: UUID().uuidString,
            name:"Pump 1",
            category: .pump,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id,
            isActive: true
        )
        let filter = Equipment(
            id: UUID().uuidString,
            name:"Filter 1",
            category: .filter,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: true,
            lastServiceDate: Date(),
            serviceFrequency: "Month",
            serviceFrequencyEvery: "6",
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id,
            isActive: true
        )
        
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: pump
        )
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: filter
        )
        print(" - Equipment - Check")
        
        
        print("Finished Uploaded \(customer.firstName) \(customer.lastName) to Firestore")
        
    }
    //READ
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer {
        return try await customerDocument(customerId: customerId,companyId: companyId)
            .getDocument(as: Customer.self)
    }
    func checkCustomerCount(companyId:String) async throws -> Int{
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: true)
            .count.getAggregation(source: .server).count as! Int
    }
    func GetCustomersByHireDate(companyId:String,DurationHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: DurationHigh)
            .getDocuments(as:Customer.self)
    }
    func GetCustomersByLastName(companyId:String,LastNameHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.lastName.rawValue,descending: LastNameHigh)
            .getDocuments(as:Customer.self)
    }
    
    func GetCustomersByFirstName(companyId:String,FirstNameHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.firstName.rawValue,descending: FirstNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActive(companyId:String,active : Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: false)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndHireDate(companyId:String,active : Bool,hireDateHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: hireDateHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndFirstName(companyId:String,active : Bool,firstNameHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.firstName.rawValue,descending: firstNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndLastName(companyId:String,active : Bool,lastNameHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.lastName.rawValue,descending: lastNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getAllContactsByCustomer(companyId:String,customerId:String) async throws -> [Contact] {
        return try await customerContactCollection(companyId: companyId, customerId: customerId)
            .getDocuments(as:Contact.self)
    }
    
    func getAllCustomers(companyId:String) async throws -> [Customer] {
        
        let snapshot = try await customerCollection(companyId: companyId).getDocuments()
        
        var customers: [Customer] = []
        
        for document in snapshot.documents{
            let customer = try document.data(as: Customer.self)
            customers.append(customer)
        }
        return customers
    }
    func getAllActiveCustomers(companyId:String) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: true)
            .getDocuments(as:Customer.self)
    }
    func searchForCustomers(companyId:String,searchTerm:String) async throws -> [Customer]{
        var customerList:[Customer] = []
        
        
        let customerListFirstName =  try await customerCollection(companyId: companyId)
            .limit(to:5)
            .whereField(Customer.CodingKeys.firstName.rawValue, isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:Customer.self)
        
        let customerListByLastName =  try await customerCollection(companyId: companyId)
            .limit(to:5)
            .whereField(Customer.CodingKeys.lastName.rawValue, isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:Customer.self)
        customerList = customerListFirstName + customerListByLastName
        let uniqueList = Array(Set(customerList))
        
        print(uniqueList)
        return uniqueList
    }
    func getAllCustomersFilteredByRate(companyId:String,descending: Bool) async throws -> [Customer]{
        _ = try await DBUserManager.shared.loadCurrentUser()
        
        return try await customerCollection(companyId: companyId)
            .order(by: "rate", descending: descending).getDocuments(as:Customer.self)
        
    }
    func get25Customers(companyId:String) async throws -> [Customer]{
        
        return try await customerCollection(companyId: companyId)
            .limit(to:25)
            .getDocuments(as:Customer.self)
        
    }
    func getNext25Customers(companyId:String,lastDocument:DocumentSnapshot?) async throws -> (customers: [Customer],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            return try await customerCollection(companyId: companyId)
                .order(by: Customer.CodingKeys.lastName.rawValue,descending: false)
                .limit(to:25)
                .start(afterDocument: lastDocument)
                .getCustomerDocumentsWithSnapshot(as:Customer.self)
        } else {
            return try await customerCollection(companyId: companyId)
                .order(by: Customer.CodingKeys.lastName.rawValue,descending: false)
                .limit(to:25)
                .getCustomerDocumentsWithSnapshot(as:Customer.self)
        }
        
    }
    func getMostRecentCustomers(companyId:String,number:Int) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: true)
            .limit(to:number)
            .getDocuments(as:Customer.self)
    }
    //UPDATE
    func updateCustomerActive(companyId:String,customerId:String,active:Bool) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        try await customerRef.updateData([
            Customer.CodingKeys.active.rawValue:active,
        ])
    }
    func updateCustomerFirstName(companyId:String,customerId:String,firstName:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.firstName.rawValue:firstName,
        ])
    }
    func updateCustomerLastName(companyId:String,customerId:String,lastName:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.lastName.rawValue:lastName,
        ])
    }
    func updateCustomerEmail(companyId:String,customerId:String,email:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.email.rawValue:email,
        ])
    }
    func updateCustomerAddress(companyId:String,customerId:String,billingAddress:Address) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        try await customerRef.updateData([
            Customer.CodingKeys.billingAddress.stringValue: [
                Address.CodingKeys.city.stringValue: billingAddress.city,
                Address.CodingKeys.state.stringValue: billingAddress.state,
                Address.CodingKeys.streetAddress.stringValue: billingAddress.streetAddress,
                Address.CodingKeys.zip.stringValue: billingAddress.zip,
                Address.CodingKeys.latitude.stringValue:billingAddress.latitude ,
                Address.CodingKeys.longitude.stringValue:billingAddress.longitude ,
            ]
        ])
    }
    func updateCustomerPhoneNumber(companyId:String,customerId:String,phoneNumber:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.phoneNumber.rawValue:phoneNumber,
        ])
    }
    func updateCustomerPhoneLabel(companyId:String,customerId:String,phoneLabel:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.phoneLabel.rawValue:phoneLabel,
        ])
    }
    func updateCustomerCompany(companyId:String,customerId:String,company:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.company.rawValue:company,
        ])
    }
    func updateCustomerDisplayAsCompany(companyId:String,customerId:String,displayAsCompany:Bool) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.displayAsCompany.rawValue:displayAsCompany,
        ])
    }
    func updateCustomerBillingNotes(companyId:String,customerId:String,billingNotes:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.billingNotes.rawValue:billingNotes,
        ])
    }
    func updateCustomerTags(companyId:String,customerId:String,tags:[String]) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.tags.rawValue:tags,
        ])
    }
    func updateCustomerLinkedInviteId(companyId:String,customerId:String,linkedInviteId:String) async throws {
        let customerRef = customerDocument(customerId: customerId, companyId: companyId)
        
        try await customerRef.updateData([
            Customer.CodingKeys.linkedInviteId.rawValue:linkedInviteId,
        ])
    }
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) async  throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        var pushLat = customerWithUpdates.billingAddress.latitude
        var pushLong = customerWithUpdates.billingAddress.longitude
        
        if currentCustomer.billingAddress.streetAddress != customerWithUpdates.billingAddress.streetAddress || currentCustomer.billingAddress.city != customerWithUpdates.billingAddress.city || currentCustomer.billingAddress.state != customerWithUpdates.billingAddress.state || currentCustomer.billingAddress.zip != customerWithUpdates.billingAddress.zip {
            let fulladdress = customerWithUpdates.billingAddress.streetAddress + " " + customerWithUpdates.billingAddress.city + " " + customerWithUpdates.billingAddress.state + " " + customerWithUpdates.billingAddress.zip
            geoCoder.geocodeAddressString(fulladdress) {
                placemarks, error in
                let placemark = placemarks?.first
                self.Coordinates = placemark?.location?.coordinate
                
                pushLat = self.Coordinates?.latitude ?? 0
                pushLong = self.Coordinates?.longitude ?? 0
            }
            
        }
        // Set the "capital" field of the city 'DC'
        try await customerRef.updateData([
            "firstName":customerWithUpdates.firstName,
            "lastName":customerWithUpdates.lastName,
            "email":customerWithUpdates.email,
            "billingAddress": [
                "City": customerWithUpdates.billingAddress.city,
                "State": customerWithUpdates.billingAddress.state,
                "StreetAddress": customerWithUpdates.billingAddress.streetAddress,
                "Zip": customerWithUpdates.billingAddress.zip,
            ],
            "phoneNumber":customerWithUpdates.phoneNumber ?? "",
            "phoneLabel":customerWithUpdates.phoneLabel ?? "",
            "company":customerWithUpdates.company ?? "",
            "displayAsCompany":customerWithUpdates.displayAsCompany,
            "hireDate":customerWithUpdates.hireDate,
            "latitude":pushLat,
            "longitidue":pushLong
            
        ])
    }
    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) async throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)
        
        // Set the "capital" field of the city 'DC'
        try await customerRef.updateData([
            
            "active":false,
            "fireDate":fireDate,
            "fireCategory":fireCategory,
            "fireReason":fireReason,
        ])
    }
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) async throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)
        // Set the "capital" field of the city 'DC'
        try await customerRef.updateData([
            
            "billingAddress": [
                "city": address.city,
                "state": address.state,
                "streetAddress": address.streetAddress,
                "zip": address.zip,
                "latitude":address.latitude ,
                "longitude":address.longitude ,
            ] as [String : Any],
        ])
    }
    func updateCustomerInfoWithValidation(
        currentCustomer:Customer,
        companyId: String,
        firstName:String,
        lastName:String,
        email:String,
        phoneNumber:String,
        company:String,
        displayAsCompany:Bool,
        billingAddress:Address,
        active:Bool
    ) async throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        print("Customer id \(currentCustomer.id)")
        if currentCustomer.firstName != firstName {
            try await customerRef.updateData([
                Customer.CodingKeys.firstName.stringValue:firstName,
            ])
        }
        if currentCustomer.lastName != lastName {
            try await customerRef.updateData([
                Customer.CodingKeys.lastName.stringValue:lastName,
            ])
        }
        if currentCustomer.email != email {
            try await customerRef.updateData([
                Customer.CodingKeys.email.stringValue:email,
            ])
        }
        if currentCustomer.phoneNumber != phoneNumber {
            try await customerRef.updateData([
                Customer.CodingKeys.phoneNumber.stringValue:phoneNumber,
            ])
        }
        if currentCustomer.company != company {
            try await customerRef.updateData([
                Customer.CodingKeys.company.stringValue:company,
            ])
        }
        if currentCustomer.displayAsCompany != displayAsCompany {
            try await customerRef.updateData([
                Customer.CodingKeys.displayAsCompany.stringValue:displayAsCompany,
            ])
        }
        
        if currentCustomer.billingAddress != billingAddress {
            try await customerRef.updateData([
                Customer.CodingKeys.billingAddress.stringValue: [
                    Address.CodingKeys.city.stringValue: billingAddress.city,
                    Address.CodingKeys.state.stringValue: billingAddress.state,
                    Address.CodingKeys.streetAddress.stringValue: billingAddress.streetAddress,
                    Address.CodingKeys.zip.stringValue: billingAddress.zip,
                    Address.CodingKeys.latitude.stringValue:billingAddress.latitude ,
                    Address.CodingKeys.longitude.stringValue:billingAddress.longitude ,
                ]
            ])
        }
        if currentCustomer.active != active {
            try await customerRef.updateData([
                Customer.CodingKeys.active.stringValue:active,
            ])
        }
    }
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) async throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        
        // Set the "capital" field of the city 'DC'
        try await customerRef.updateData([
            "firstName":currentCustomer.firstName,
            "lastName":currentCustomer.lastName,
            "email":currentCustomer.email,
            //            "billingAddress": [
            //                "City": customerWithUpdates.billingAddress.city,
            //                "State": customerWithUpdates.billingAddress.state,
            //                "StreetAddress": customerWithUpdates.billingAddress.streetAddress,
            //                "Zip": customerWithUpdates.billingAddress.zip,
            //            ],
            "phoneNumber":currentCustomer.phoneNumber ?? "",
            //            "phoneLabel":customerWithUpdates.phoneLabel ?? "",
            "company":currentCustomer.company ?? "",
            "displayAsCompany":currentCustomer.displayAsCompany,
            //            "hireDate":customerWithUpdates.hireDate,
            //            "latitude":pushLat,
            //            "longitidue":pushLong
            
        ])
    }
    //DELETE
    func deleteCustomer(companyId:String,customer:Customer)async throws {
        try await customerDocument(customerId: customer.id,companyId: companyId)
            .delete()
    }
    func deleteCustomer(companyId:String,customer:Customer) throws {
        print("Attempting to Delete \(customer.firstName) \(customer.lastName)")
        customerCollection(companyId: companyId)
            .document(customer.id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Customer successfully Deleted \(customer.firstName) \(customer.lastName)!")
                }
            }
    }
    //FUNCTIONS
    
    //Listeners
    //                    customers Collections

}
