//
//  CustomerManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/15/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin

struct Customer:Identifiable, Codable,Hashable{
    var id : String
    var firstName :String
    var lastName : String
    var email : String
    var billingAddress : Address
    var phoneNumber : String?
    var phoneLabel : String?
    var active: Bool
    var rate : Double? // Remove
    var company : String?
    var displayAsCompany : Bool
    var hireDate : Date  // Remove
    var fireDate : Date?  // Remove
    var fireCategory : String?  // Remove
    var fireReason : String?  // Remove
    var billingNotes : String
    var tags : [String]?

    init(
        id: String,
        firstName :String,
        lastName : String,
        email : String,
        billingAddress: Address,
        phoneNumber : String? = nil,
        phoneLabel : String? = nil,
        active : Bool,
        rate: Double? = nil,
        company: String? = nil,
        displayAsCompany : Bool,
        hireDate : Date,
        fireDate : Date? = nil,
        fireCategory : String? = nil,
        billingNotes : String,
        tags : [String]? = nil
    ){
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.billingAddress = billingAddress
        self.phoneNumber = phoneNumber
        self.phoneLabel = phoneLabel
        self.active = active
        self.rate = rate
        self.company = company
        self.displayAsCompany = displayAsCompany
        self.hireDate = hireDate
        self.fireDate = fireDate
        self.fireCategory = fireCategory
        self.billingNotes = billingNotes
        self.tags = tags

        
    }
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case firstName = "firstName"
            case lastName = "lastName"
            case email = "email"
            case billingAddress = "billingAddress"
            case phoneNumber = "phoneNumber"
            case phoneLabel = "phoneLabel"
            case active = "active"
            case rate = "rate"
            case company = "company"
            case displayAsCompany = "displayAsCompany"
            case hireDate = "hireDate"
            case fireDate = "fireDate"
            case fireCategory = "fireCategory"
            case billingNotes = "billingNotes"
            case tags = "tags"

        }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(firstName)
        hasher.combine(lastName)
        hasher.combine(email)
        hasher.combine(phoneNumber)
        hasher.combine(rate)

    }
    
    static func == (lhs: Customer, rhs: Customer) -> Bool {
        return lhs.id == rhs.id &&
        lhs.firstName == rhs.firstName &&
        lhs.lastName == rhs.lastName &&
        lhs.email == rhs.email &&
        lhs.phoneNumber == rhs.phoneNumber &&
        lhs.rate == rhs.rate
    }
    
    
}

protocol customerManagerProtocol{
    func uploadCustomer(companyId:String,customer : Customer) async throws
    
    func GetCustomersByHireDate(companyId:String,DurationHigh:Bool) async throws -> [Customer]
    func GetCustomersByLastName(companyId:String,LastNameHigh:Bool) async throws -> [Customer]
    func GetCustomersByFirstName(companyId:String,FirstNameHigh:Bool) async throws -> [Customer]
    func getCustomersActive(companyId:String,active : Bool) async throws ->[Customer]
    func getCustomersActiveAndHireDate(companyId:String,active : Bool,hireDateHigh:Bool) async throws ->[Customer]
    func getCustomersActiveAndFirstName(companyId:String,active : Bool,firstNameHigh:Bool) async throws ->[Customer]
    func getCustomersActiveAndLastName(companyId:String,active : Bool,lastNameHigh:Bool) async throws ->[Customer]
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer
    func getAllCustomers(companyId:String) async throws ->[Customer]
    func getAllActiveCustomers(companyId:String) async throws ->[Customer]
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws ->[CustomerMonthlySummary]
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws ->[CustomerMonthlySummary]
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws ->[CustomerMonthlySummary]
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws ->[CustomerMonthlySummary]
    func getAllCustomersFilteredByRate(companyId:String,descending: Bool) async throws ->[Customer]
    func get25Customers(companyId:String) async throws ->[Customer]
    func getNext25Customers(companyId:String,lastDocument:DocumentSnapshot?) async throws ->(customers: [Customer],lastDocument:DocumentSnapshot?)
    func getMostRecentCustomers(companyId:String,number:Int) async throws ->[Customer]
    func checkCustomerCount(companyId:String) async throws ->Int
    func convertCustomerCSVToStruct(contents: String) async throws ->[CSVCustomer]
    func uploadCSVCustomerToFireStore(companyId:String,customer: CSVCustomer) async throws
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws

    func deleteCustomer(companyId:String,customer:Customer) throws
    func addListenerForAllCustomers(companyId:String,sort:CustomerSortOptions,filter:CustomerFilterOptions,completion:@escaping (_ customers:[Customer]) -> Void)
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) throws
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) throws
    func updateCustomerInfoWithValidation(currentCustomer:Customer,companyId: String,firstName:String,lastName:String,email:String,phoneNumber:String,company:String,displayAsCompany:Bool,billingAddress:Address) throws
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) throws
    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) throws
    
    func removeListenerForAllCustomers()
    
    func searchForCustomers(companyId:String,searchTerm:String) async throws ->[Customer]


}
final class MockCustomerManager:customerManagerProtocol, ObservableObject {
    
    static let shared = MockCustomerManager()
//    private init(){}
    init(){}
    private let db = Firestore.firestore()

    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil
    
    private var customerListener: ListenerRegistration? = nil
    let geoCoder = CLGeocoder()
    private let mockCustomerList:[Customer] = [

        Customer(id: "1", firstName: "Aphrodite", lastName: "Love, Sex and Beauty", email: "HotSex@hotmail.com", billingAddress: Address(streetAddress: "Akti Sachtouri 10", city: "Rhodes", state: "Greece", zip: "851 31", latitude: 36.44591, longitude: 28.22736), phoneNumber: "Aphrodite", phoneLabel: "619-555-6969", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "2", firstName: "Athena", lastName: "Reason, Wisdom and War", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "3", firstName: "Artemis", lastName: "Hunt", email: "HotSex@hotmail.com", billingAddress: Address(streetAddress: "Akti Sachtouri 10", city: "Rhodes", state: "Greece", zip: "851 31", latitude: 36.44591, longitude: 28.22736), phoneNumber: "Aphrodite", phoneLabel: "619-555-6969", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "4", firstName: "Aries", lastName: "Bloodlust and War", email: "HotSex@hotmail.com", billingAddress: Address(streetAddress: "Akti Sachtouri 10", city: "Rhodes", state: "Greece", zip: "851 31", latitude: 36.44591, longitude: 28.22736), phoneNumber: "Aphrodite", phoneLabel: "619-555-6969", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "5", firstName: "Apollo", lastName: "Son of Zeus", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "6", firstName: "Demeter", lastName: "Agriculture", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "7", firstName: "Dionysus", lastName: "Drunken Wine", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "8", firstName: "Hades", lastName: "Ruler of the Underworld", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "9", firstName: "Hera", lastName: "Hearth", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),

        Customer(id: "10", firstName: "Poseidon", lastName: "Ocean, Horses and Earthquakes", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: ""),
        
        Customer(id: "11", firstName: "Zeus", lastName: "King of the Gods", email: "Genius@gmail.com", billingAddress: Address(streetAddress: "Temple of Athena Nike", city: "Dionysiou Areopagitou", state: "Athina 105 58", zip: "Greece", latitude: 37.9716, longitude: 23.7249), phoneNumber: "Athena", phoneLabel: "619-555-0180", active: true, rate: 0, company: "", displayAsCompany: false, hireDate: Date(), fireDate: nil, fireCategory: nil, billingNotes: "")
    ]
    private let mockSummaryData:[CustomerMonthlySummary] = [
        CustomerMonthlySummary(id: "1", date: Date(), customerId: "1", customerDisplayName: "Aphrodite", serviceLocationId: "1", monthlyRate: 180, chemicalCost: 75, laborCost: 30, serviceStops: 4)
    ]
    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func customerCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/customers")
    }

    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------

    private func customerDocument(customerId:String,companyId:String)-> DocumentReference{

        customerCollection(companyId: companyId).document(customerId)
    }

    func uploadCustomer(companyId:String,customer : Customer) async throws {
  print("successfully Uploaded Mock Customer")
    }
    func updateCustomerInfoWithValidation(currentCustomer:Customer,companyId: String,firstName:String,lastName:String,email:String,phoneNumber:String,company:String,displayAsCompany:Bool,billingAddress:Address) throws {
        
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                  Get the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func GetCustomersByHireDate(companyId:String,DurationHigh:Bool) async throws -> [Customer] {
        return mockCustomerList
    }
    
    func GetCustomersByLastName(companyId:String,LastNameHigh:Bool) async throws -> [Customer] {
        return mockCustomerList

    }
    
    func GetCustomersByFirstName(companyId:String,FirstNameHigh:Bool) async throws -> [Customer] {
        return mockCustomerList

    }
    
    func getCustomersActive(companyId:String,active : Bool) async throws ->[Customer] {
        return mockCustomerList

    }
    
    func getCustomersActiveAndHireDate(companyId:String,active : Bool,hireDateHigh:Bool) async throws ->[Customer] {
        return mockCustomerList

    }
    
    func getCustomersActiveAndFirstName(companyId:String,active : Bool,firstNameHigh:Bool) async throws ->[Customer] {
        return mockCustomerList

    }
    
    func getCustomersActiveAndLastName(companyId:String,active : Bool,lastNameHigh:Bool) async throws ->[Customer] {
        return mockCustomerList

    }
    
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer {
        let customer:Customer = mockCustomerList.first(where: {$0.id == customerId})!
            
        return customer

    }
    
    func getAllCustomers(companyId:String) async throws -> [Customer] {
        return mockCustomerList

    }
    func getAllActiveCustomers(companyId:String) async throws -> [Customer] {
        return mockCustomerList

    }
    
    func searchForCustomers(companyId:String,searchTerm:String) async throws -> [Customer]{
        var customerList:[Customer] = []
        customerList = mockCustomerList
        let uniqueList = Array(Set(customerList))
        
        print(uniqueList)
        return uniqueList
    }

    func getAllCustomersFilteredByRate(companyId:String,descending: Bool) async throws -> [Customer]{
        return mockCustomerList

    }
    
    func get25Customers(companyId:String) async throws -> [Customer]{
        
        return mockCustomerList

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
        return []
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Service Locations
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    func checkCustomerCount(companyId:String) async throws -> Int{
        return mockCustomerList.count

    }
    
    func convertCustomerCSVToStruct(contents: String) async throws -> [CSVCustomer]{
        var csvToStruct = [CSVCustomer]()
        
        
        var rows = contents.components(separatedBy: "\n")
        rows.removeFirst()
        for row in rows {
            let CSVColumns = row.components(separatedBy: ",")
            var customerStruct = CSVCustomer.init(raw: CSVColumns)
            print("Converted \(customerStruct.firstName) \(customerStruct.lastName)")

            csvToStruct.append(customerStruct)
//            if customerStruct.firstName == "Sue" && customerStruct.lastName == "Thomas" {
//
//                return csvToStruct
//                print("Cut Out Early")
//
//            }
        }
        print("Successfully Converted Customer List")
        return csvToStruct
    }    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Bodies Of Water
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Converting CSV to Customers for upload to firestore
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //DEVELOPER it might be helpful
    func uploadCSVCustomerToFireStore(companyId:String,customer: CSVCustomer) async throws{
        print("Successfully upload")
    }
    
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws{
      print("Deleted")
    }
    
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws{
        print("UploadingCustomerMonthlySummary")
    }
    
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws -> [CustomerMonthlySummary] {
        
        return  mockSummaryData
        
    }
    
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return  mockSummaryData

    }
    
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws -> [CustomerMonthlySummary] {
        
        return  mockSummaryData

    }
    
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return  mockSummaryData

    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func deleteCustomer(companyId:String,customer:Customer) throws {
       print("Delete")
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Listeners the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func addListenerForAllCustomers(companyId:String,sort:CustomerSortOptions,filter:CustomerFilterOptions,completion:@escaping (_ customers:[Customer]) -> Void){
        let listener = customerCollection(companyId: companyId)
            .whereField("participantIds", arrayContains: "userId")
            .order(by: "mostRecentChat", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                completion(chats)
            }
        self.customerListener = listener
    }
    func removeListenerForAllCustomers(){
        print("Removed Listern")

    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Editing the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) throws {
        print("Updated Customer")

    }
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) throws {
        print("Updated Customer")

    }
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) throws {
        print("Updated Customer")

    }

    

    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) throws {
        print("Made Inactive")

    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Delete the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    
}

final class CustomerManager:customerManagerProtocol {
    
    static let shared = CustomerManager()
    init(){}
    private let db = Firestore.firestore()

    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil
    
    private var customerListener: ListenerRegistration? = nil
    let geoCoder = CLGeocoder()
    
    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func customerCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/customers")
    }

    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------

    private func customerDocument(customerId:String,companyId:String)-> DocumentReference{

        customerCollection(companyId: companyId).document(customerId)
    }


    func uploadCustomer(companyId:String,customer : Customer) async throws {
        print("Attempting to Up Load \(customer.firstName) \(customer.lastName) to Firestore")
 
        let coordinates = try await convertAddressToCordinates1(address: customer.billingAddress)
        print("Received Coordinates \(String(describing: coordinates))")
        var pushCustomer = customer
        pushCustomer.billingAddress.latitude = coordinates.latitude
        pushCustomer.billingAddress.longitude = coordinates.longitude

        pushCustomer.id = customer.id
        pushCustomer.firstName = customer.firstName
        pushCustomer.lastName = customer.lastName
        
        pushCustomer.email = customer.email
        pushCustomer.company = customer.company
        pushCustomer.displayAsCompany = customer.displayAsCompany
        
        try customerDocument(customerId: pushCustomer.id,companyId: companyId).setData(from:pushCustomer, merge: false)
    }
    

 
 

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                  Get the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
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
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer {
        return try await customerDocument(customerId: customerId,companyId: companyId)
            .getDocument(as: Customer.self)
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
        let user = try await DBUserManager.shared.loadCurrentUser()
        
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
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Service Locations
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    func checkCustomerCount(companyId:String) async throws -> Int{
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: true)
            .count.getAggregation(source: .server).count as! Int
    }

    

 
    func convertCustomerCSVToStruct(contents: String) async throws -> [CSVCustomer]{
        var csvToStruct = [CSVCustomer]()
        
        
        var rows = contents.components(separatedBy: "\n")
        rows.removeFirst()
        for row in rows {
            let CSVColumns = row.components(separatedBy: ",")
            var customerStruct = CSVCustomer.init(raw: CSVColumns)
            print("Converted \(customerStruct.firstName) \(customerStruct.lastName)")

            csvToStruct.append(customerStruct)
//            if customerStruct.firstName == "Sue" && customerStruct.lastName == "Thomas" {
//
//                return csvToStruct
//                print("Cut Out Early")
//
//            }
        }
        print("Successfully Converted Customer List")
        return csvToStruct
    }    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Bodies Of Water
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Converting CSV to Customers for upload to firestore
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //DEVELOPER it might be helpful
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
        
        let DBCustomer:Customer = Customer(id: identification,firstName: customer.firstName ,lastName:customer.lastName,email:customer.email, billingAddress:DBAddress , phoneNumber: customer.phone, active: true, rate: Double(customer.rate), company: "", displayAsCompany: false, hireDate: hireDate, billingNotes: "NA")
        
        print("Uploading Customer - \(customer.firstName) - \(customer.lastName)")
        try await CustomerManager.shared.uploadCustomer(companyId: companyId, customer: DBCustomer)
        let serviceLocationId:String = UUID().uuidString
        let bodyOfWaterId:String = UUID().uuidString
 
        
  

        sleep(1)
        //Uploading Customer Billing Type
        let billingTempalte = try await BillingManager.shared.getDefaultBillingTempalte(companyId: companyId)
        
        //Uploading Customer Service Locations

        let serviceLocation:ServiceLocation = ServiceLocation(id: serviceLocationId,
                                                                      nickName: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                                      address: DBCustomer.billingAddress,
                                                                      gateCode: "",
                                                                      mainContact: Contact(id: UUID().uuidString,
                                                                                           name: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                                                           phoneNumber: DBCustomer.phoneNumber ?? "",
                                                                                           email: DBCustomer.email,
                                                                                           notes: ""),
                                                                      bodiesOfWaterId: [bodyOfWaterId],
                                                                      rateType: billingTempalte.title,
                                                                      laborType: billingTempalte.laborType,
                                                                      chemicalCost: billingTempalte.chemType,
                                                                      laborCost: "15",
                                                                      rate: customer.rate,
                                                                      customerId: DBCustomer.id,
                                                                      customerName: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                              preText: false)
        
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
            serviceLocationId: serviceLocation.id
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
            bodyOfWaterId: bodyOfwater.id
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
            bodyOfWaterId: bodyOfwater.id
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
    
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws{
            
        let summaryList = try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .getDocuments(as:CustomerMonthlySummary.self)
        
        for summary in summaryList {
            print("Deleted \(summary)")
            try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(summary.id)
                .delete()
        }
    }
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws{
        print("UploadingCustomerMonthlySummary")
        print(companyId)
        
        try db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(customerMonthlySummary.id)
            .setData(from:customerMonthlySummary, merge: false)
    }
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws -> [CustomerMonthlySummary] {
        
        return  try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .limit(to: 25)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("serviceLocationId", isEqualTo: serviceLocationId)
            .limit(to: 1)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousYear().previousMonth().endOfMonth())
            .limit(to: 12)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Listeners the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
  
    func addListenerForAllCustomers(companyId:String,sort:CustomerSortOptions,filter:CustomerFilterOptions,completion:@escaping (_ customers:[Customer]) -> Void){
        var listener: ListenerRegistration? = nil
        print("Sort: \(sort)")
        print("Filter: \(filter)")

        switch sort {
        case .durationLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .durationHigh:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }

        case .lastNameHigh:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }

        case .lastNameLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }

        case .firstNameHigh:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }

        case .firstNameLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }

        }
   
        self.customerListener = listener
    }
    
    func removeListenerForAllCustomers(){
        print("Removed Listern")

    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Editing the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) throws {
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
        customerRef.updateData([
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
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)

        // Set the "capital" field of the city 'DC'
        customerRef.updateData([
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
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCustomerInfoWithValidation(currentCustomer:Customer,companyId: String,firstName:String,lastName:String,email:String,phoneNumber:String,company:String,displayAsCompany:Bool,billingAddress:Address) throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        print("Customer id \(currentCustomer.id)")
        customerRef.updateData([
            Customer.CodingKeys.firstName.stringValue:firstName,
            Customer.CodingKeys.lastName.stringValue:lastName,
            Customer.CodingKeys.email.stringValue:email,
            Customer.CodingKeys.phoneNumber.stringValue:phoneNumber,
            Customer.CodingKeys.company.stringValue:company,
            Customer.CodingKeys.displayAsCompany.stringValue:displayAsCompany,
            Customer.CodingKeys.billingAddress.stringValue: [
                Address.CodingKeys.city.stringValue: billingAddress.city,
                Address.CodingKeys.state.stringValue: billingAddress.state,
                Address.CodingKeys.streetAddress.stringValue: billingAddress.streetAddress,
                Address.CodingKeys.zip.stringValue: billingAddress.zip,
                Address.CodingKeys.latitude.stringValue:billingAddress.latitude ,
                Address.CodingKeys.longitude.stringValue:billingAddress.longitude ,
            ]
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)
        // Set the "capital" field of the city 'DC'
        customerRef.updateData([

            "billingAddress": [
                "city": address.city,
                "state": address.state,
                "streetAddress": address.streetAddress,
                "zip": address.zip,
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

    

    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)

        // Set the "capital" field of the city 'DC'
        customerRef.updateData([

            "active":false,
            "fireDate":fireDate,
            "fireCategory":fireCategory,
            "fireReason":fireReason,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Delete the customers
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func deleteCustomer(companyId:String,customer:Customer)async throws {
        try? await customerDocument(customerId: customer.id,companyId: companyId)
            .delete()
        
    }
    
}

