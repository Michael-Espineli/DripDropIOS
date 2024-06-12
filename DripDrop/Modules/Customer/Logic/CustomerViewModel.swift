//
//  CustomerViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 6/24/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//                             Enum
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
enum CustomerFilterOptions:String, CaseIterable{
    case active
    case deActivate
    case all
    
    func display() -> String {
        switch self {
        case .all:
            return "All"
        case .active:
            return "Active"
        case .deActivate:
            return "Deactive"
            
        }
    }
}
enum CustomerSortOptions:String, CaseIterable{
    case durationLow
    case durationHigh
    case lastNameHigh
    case lastNameLow
    case firstNameHigh
    case firstNameLow
    
    func display() -> String {
        switch self {
        case .durationHigh:
            return "Duration High"
        case .durationLow:
            return "Duration Low"
        case .lastNameHigh:
            return "Last Name A -> Z"
        case .lastNameLow:
            return "Last Name Z -> A"
        case .firstNameHigh:
            return "First Name A -> Z"
        case .firstNameLow:
            return "First Name Z -> A"
        }
    }
}

@MainActor
final class CustomerViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //SINGLE
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil

    // ARRAY
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var customersActive: [Customer] = []
    @Published private(set) var customers2: [Customer] = []
    @Published private(set) var filteredCustomers: [Customer] = []

    
    @Published private(set) var recurringServiceStopPreview: [RecurringServiceStop] = []
//    @Published private(set) var customerChart:[customerChartSeriesData] = []
//    @Published private(set) var customerChart2:[customerChartSeriesData] = []
//    @Published private(set) var customerBarChart:[customerDateSummary2] = []

    @Published private(set) var loadingText: String? = nil
    @Published private(set) var totalCustomer: Int? = nil
    @Published private(set) var currentCustomer: Int? = nil
    @Published private(set) var bodyOfWaterCount: Int? = nil
    @Published private(set) var activeCustomers: Int? = nil
    @Published private(set) var firedCustomers: Int? = nil
    @Published private(set) var hiredCustomers: Int? = nil
    @Published private(set) var needToLoadCustomers: Bool = true
    @Published private(set) var totalCustomerBeingLoaded: Int? = nil
    @Published private(set) var currentNumberCustomerBeingLoaded: Int? = nil
    @Published private(set) var selectedFilter:CustomerFilterOptions = .active
    @Published private(set) var selectedSort:CustomerSortOptions = .durationLow

    //Variables For Company OverView Page (MyCompany.swift)
    @Published private(set) var totalCustomers: Int? = nil
    @Published private(set) var totalResidentalAccounts: Int? = nil
    @Published private(set) var totalComericalAccounts: Int? = nil

    @Published private(set) var coordinates: CLLocationCoordinate2D? = nil
//Subscribers Variables
    private var lastDocument :DocumentSnapshot? = nil

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func filterSelected(companyId: String,option:CustomerFilterOptions) async throws{
        self.selectedFilter = option

        switch option {
        case .all:
            self.customers = try await dataService.getAllCustomers(companyId: companyId)
            self.selectedFilter = .all

        case .active:
            self.customers = try await dataService.getCustomersActive(companyId: companyId, active: true)
            self.selectedFilter = .active

        case .deActivate:
            self.customers = try await dataService.getCustomersActive(companyId: companyId, active: false)
            self.selectedFilter = .deActivate


        }

    }
    func sortSelected(companyId: String,option:CustomerSortOptions) async throws {
        
        switch option {
        case .durationHigh:
            self.customers = try await dataService.GetCustomersByHireDate(companyId: companyId, DurationHigh: false)
            self.selectedSort = .durationHigh

        case .durationLow:
            self.customers = try await dataService.GetCustomersByHireDate(companyId: companyId, DurationHigh: true)
            self.selectedSort = .durationLow

        case .lastNameHigh:
            self.customers = try await dataService.GetCustomersByLastName(companyId: companyId, LastNameHigh: false)
            self.selectedSort = .lastNameHigh

            
        case .lastNameLow:
            self.customers = try await dataService.GetCustomersByLastName(companyId: companyId, LastNameHigh: true)
            self.selectedSort = .lastNameLow

        case .firstNameHigh:
            self.customers = try await dataService.GetCustomersByFirstName(companyId: companyId, FirstNameHigh: false)
            self.selectedSort = .firstNameHigh

        case .firstNameLow:
            self.customers = try await dataService.GetCustomersByFirstName(companyId: companyId, FirstNameHigh: true)
            self.selectedSort = .firstNameLow

        }
        print(option)
    }
    func filterAndSortSelected(companyId: String,filter:CustomerFilterOptions,sort:CustomerSortOptions) async throws{
        self.selectedFilter = filter
        self.selectedSort = sort
        
        switch filter {
        case .all:
            print("All Customers")

            switch sort {
            case .durationHigh:
                print("Get all with Duration High")
                self.customers = try await dataService.GetCustomersByHireDate(companyId: companyId, DurationHigh: true)
                self.selectedFilter = .all
                self.selectedSort = .durationHigh
            case .durationLow:
                print("Get all with Duration Low")

                self.customers = try await dataService.GetCustomersByHireDate(companyId: companyId, DurationHigh: true)
                self.selectedFilter = .all
                self.selectedSort = .durationLow
            case .lastNameHigh:
                print("Get all with Last Name High")

                self.customers = try await dataService.GetCustomersByLastName(companyId: companyId, LastNameHigh: true)
                self.selectedFilter = .all
                self.selectedSort = .lastNameHigh
            case .lastNameLow:
                print("Get all with Last Name Low")

                self.customers = try await dataService.GetCustomersByLastName(companyId: companyId, LastNameHigh: false)
                self.selectedFilter = .all
                self.selectedSort = .lastNameLow
            case .firstNameHigh:
                print("Get all with First Name High")

                self.customers = try await dataService.GetCustomersByFirstName(companyId: companyId, FirstNameHigh: true)
                self.selectedFilter = .all
                self.selectedSort = .firstNameHigh
            case .firstNameLow:
                print("Get all with Firsr Name Low")

                self.customers = try await dataService.GetCustomersByFirstName(companyId: companyId, FirstNameHigh: false)
                self.selectedFilter = .all
                self.selectedSort = .firstNameLow
            }
            self.customers = try await dataService.getAllCustomers(companyId: companyId)
        case .active:
            print("Active Customers")
            switch sort {
            case .durationHigh:
                print("Get active with Duration High")

                self.customers = try await dataService.getCustomersActiveAndHireDate(companyId: companyId, active: true, hireDateHigh: false)
                self.selectedFilter = .active
                self.selectedSort = .durationHigh
                
            case .durationLow:
                print("Get active with Duration Low")

                self.customers = try await dataService.getCustomersActiveAndHireDate(companyId: companyId, active: true, hireDateHigh: true)
                self.selectedFilter = .active
                self.selectedSort = .durationLow
                
            case .lastNameHigh:
                print("Get active with Last Name High")

                self.customers = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: true, lastNameHigh: false)
                self.selectedFilter = .active
                self.selectedSort = .lastNameHigh
                
            case .lastNameLow:
                print("Get active with Last Name Low")

                self.customers = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: true, lastNameHigh: true)
                self.selectedFilter = .active
                self.selectedSort = .lastNameLow
                
            case .firstNameHigh:
                print("Get active with First Name High")

                self.customers = try await dataService.getCustomersActiveAndFirstName(companyId: companyId, active: true, firstNameHigh: false)
                self.selectedFilter = .active
                self.selectedSort = .firstNameHigh
                
            case .firstNameLow:
                print("Get active with First Name Low")

                self.customers = try await dataService.getCustomersActiveAndFirstName(companyId: companyId, active: true, firstNameHigh: true)
                self.selectedFilter = .active
                self.selectedSort = .firstNameLow

            }
            self.customers = try await dataService.getCustomersActive(companyId: companyId, active: true)
            self.selectedFilter = .active
            
        case .deActivate:
            switch sort {
            case .durationHigh:
                print("Get deActivate with Duration High")

                self.customers = try await dataService.getCustomersActiveAndHireDate(companyId: companyId, active: false, hireDateHigh: false)
                self.selectedFilter = .deActivate
                self.selectedSort = .durationHigh
            case .durationLow:
                print("Get deActivate with Duration Low")

                self.customers = try await dataService.getCustomersActiveAndHireDate(companyId: companyId, active: false, hireDateHigh: true)
                self.selectedFilter = .deActivate
                self.selectedSort = .durationLow
                
            case .lastNameHigh:
                print("Get deActivate with Last Name High")

                self.customers = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: false, lastNameHigh: false)
                self.selectedFilter = .deActivate
                self.selectedSort = .lastNameHigh
                
            case .lastNameLow:
                print("Get deActivate with Last Name Low")

                self.customers = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: false, lastNameHigh: true)
                self.selectedFilter = .deActivate
                self.selectedSort = .lastNameLow
                
            case .firstNameHigh:
                print("Get deActivate with First Name High")

                self.customers = try await dataService.getCustomersActiveAndFirstName(companyId: companyId, active: false, firstNameHigh: false)
                self.selectedFilter = .deActivate
                self.selectedSort = .firstNameHigh
                
            case .firstNameLow:
                print("Get deActivate with First Name Low")

                self.customers = try await dataService.getCustomersActiveAndFirstName(companyId: companyId, active: false, firstNameHigh: true)
                self.selectedFilter = .deActivate
                self.selectedSort = .firstNameLow
                
            }
            self.selectedFilter = .deActivate
            self.customers = try await dataService.getCustomersActive(companyId: companyId, active: false)

        }
    }
    func getAllCustomers(companyId:String) async throws{
        self.customers = try await dataService.getAllCustomers(companyId: companyId)
    }
    func getAllActiveCustomers(companyId: String) async throws{
        self.customers = try await dataService.getAllActiveCustomers(companyId: companyId)
    }
    func getCustomerSnapShot(companyId:String) async throws {
        //Returns Items Mainly For Company Overview SnapShot
        
        //Total Active Customers
        self.totalCustomers = try await dataService.checkCustomerCount(companyId: companyId)
        //Total Residential - DEVELOPER >> ADD TAGS To Customer Accounts so that I can tag them as Comerical or Residental
        self.totalResidentalAccounts = 5
        //Total Comerical
        self.totalComericalAccounts = 5
        //10 Most Recent Customers.
        self.customers = try await dataService.getMostRecentCustomers(companyId: companyId, number: 10)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func updateCustomer(currentCustomer:Customer,companyId: String) async throws {
        try await dataService.updateCurrentCustomer(companyId: companyId, currentCustomer: currentCustomer)
        
    }
    func makeCustomerInactive(currentCustomerId:String,companyId: String,fireDate:Date,fireReason:String,fireCategory:String) async throws {
        try await dataService.makeCustomerInactive(companyId: companyId, currentCustomerId: currentCustomerId, fireDate: fireDate, fireReason: fireReason, fireCategory: fireCategory)
    }
    func updateCustomerInfo(currentCustomer:Customer,companyId: String) async throws {
        try await dataService.updateCurrentCustomer(companyId: companyId, currentCustomer: currentCustomer)
        
    }
    func updateCustomerInfoWithValidation(currentCustomer:Customer,companyId: String,firstName:String,lastName:String,email:String,phoneNumber:String,company:String,displayAsCompany:Bool,billingAddress:Address) async throws {
        
        try await dataService.updateCustomerInfoWithValidation(currentCustomer: currentCustomer, companyId: companyId, firstName: firstName, lastName: lastName, email: email, phoneNumber: phoneNumber, company: company, displayAsCompany: displayAsCompany,billingAddress: billingAddress)
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func deleteCustomer(companyId: String,customer:Customer) async throws {
        try await dataService.deleteCustomer( companyId: companyId,customer: customer)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             FUNCTIONS
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    
 

    func get25Customers(companyId: String) async throws{
        self.customers = try await dataService.get25Customers(companyId: companyId)
    }
    func getCustomer(companyId: String,customerId:String) async throws{
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        
    }

    func checkCustomerCount(companyId: String,count:Int) async throws {

        let comparableCount = try await dataService.checkCustomerCount(companyId: companyId)
        if count < comparableCount {
            needToLoadCustomers = true
        }
    }
    

    func getnext25Customers(companyId:String) {
        Task{
            let (newCustomers,lastDocument) = try await dataService.getNext25Customers(companyId: companyId, lastDocument: lastDocument)
            //            self.customers.append(contentsOf:newCustomers)
            self.customers = newCustomers
            self.lastDocument = lastDocument
        }
    }
    
    func getRecurringServiceStopPreview(companyId: String,customerId:String) async throws{
        self.recurringServiceStopPreview = try await RecurringServiceStopManager.shared.getAllRecurringServiceStopByCustomerId( companyId: companyId, customerId: customerId)
    }
    func uploadCsvFileTo(pathName:String,fileName:String,companyId: String) async {
        let fileURL = URL(fileURLWithPath: pathName).appendingPathExtension("csv")
        var customerCount = 0
        do {
            let text2 = try String(contentsOf: fileURL, encoding: .utf8)
            print("Successfully Read")
            let customerList = try await dataService.convertCustomerCSVToStruct(contents: text2)
            print("Successfully Converted")
            self.totalCustomer = customerList.count
            //This will Fail if there are any double spaced columns
            for customer in customerList {
                let fullName = customer.firstName + " " + customer.lastName

                try await dataService.uploadCSVCustomerToFireStore(companyId: companyId, customer: customer)
                //remove before Production
                customerCount = customerCount + 1
                self.loadingText = fullName
                self.currentCustomer = customerCount + 1
                
                //                if customerCount > 10 {
                //                    return
                //                }
            }
            
            print("Completed Upload")
            
        }
        catch {
            print("Unable to read the file")
        }
    }
    func addNewCustomerWithOutLocation(customer:Customer,companyId:String) async throws {
        print("Uploading Customer >> \(customer.firstName)")
        let customerId = customer.id

        var DBAddress = Address(streetAddress: customer.billingAddress.streetAddress, city: customer.billingAddress.city, state: customer.billingAddress.state, zip: customer.billingAddress.zip,latitude: 0.0,longitude: 0.0)
        
        let fulladdress = DBAddress.streetAddress + " " + DBAddress.city + " " + DBAddress.state + " " + DBAddress.zip
        let fullName = customer.firstName + " " + customer.lastName
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate
        }

        usleep(1201000)
        
        let pushCoordinates = self.Coordinates
        DBAddress.latitude = pushCoordinates?.latitude ?? 32.8
        DBAddress.longitude = pushCoordinates?.longitude ?? -117.8
        print("Received Coordinates from geoCoder : \(String(describing: pushCoordinates))")
        let finalCustomer:Customer = Customer(id: customerId,
                                              firstName: customer.firstName,
                                              lastName: customer.lastName,
                                              email: customer.email,
                                              billingAddress: DBAddress,
                                              phoneNumber: customer.phoneNumber,
                                              phoneLabel: customer.phoneLabel,
                                              active: customer.active,
                                              rate: customer.rate,
                                              company: customer.company,
                                              displayAsCompany: customer.displayAsCompany,
                                              hireDate: customer.hireDate,
                                              fireDate: customer.fireDate,
                                              fireCategory: customer.fireCategory,
                                              billingNotes: customer.billingNotes)
        try await dataService.uploadCustomer(companyId: companyId, customer: finalCustomer)
    }
    func addNewCustomerWithLocation(customer:Customer,serviceLocation:ServiceLocation,companyId: String) async throws{
        print("Uploading Customer >> \(customer.firstName)")
        let customerId = customer.id
        let serviceLocationId = serviceLocation.id
        let bodyOfWaterId = UUID().uuidString
        var DBAddress = Address(streetAddress: customer.billingAddress.streetAddress, city: customer.billingAddress.city, state: customer.billingAddress.state, zip: customer.billingAddress.zip,latitude: 0.0,longitude: 0.0)
        
        let fulladdress = DBAddress.streetAddress + " " + DBAddress.city + " " + DBAddress.state + " " + DBAddress.zip
        let fullName = customer.firstName + " " + customer.lastName
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate

                try? ServiceLocationManager.shared.updateServiceLocationLatLong(companyId: companyId, serviceLocationId: serviceLocationId, lat: placemark?.location?.coordinate.latitude ?? 69, long: placemark?.location?.coordinate.longitude ?? 69)
 
        }

        
        let pushCoordinates = self.Coordinates
        DBAddress.latitude = pushCoordinates?.latitude ?? 32.8
        DBAddress.longitude = pushCoordinates?.longitude ?? -117.8
        print("Received Coordinates from geoCoder : \(String(describing: pushCoordinates))")
        let finalCustomer:Customer = Customer(id: customerId,
                                              firstName: customer.firstName,
                                              lastName: customer.lastName,
                                              email: customer.email,
                                              billingAddress: DBAddress,
                                              phoneNumber: customer.phoneNumber,
                                              phoneLabel: customer.phoneLabel,
                                              active: customer.active,
                                              rate: customer.rate,
                                              company: customer.company,
                                              displayAsCompany: customer.displayAsCompany,
                                              hireDate: customer.hireDate,
                                              fireDate: customer.fireDate,
                                              fireCategory: customer.fireCategory,
                                              billingNotes: customer.billingNotes)
        try await dataService.uploadCustomer(companyId: companyId, customer: finalCustomer)
        print("Uploading Service Location For >> \(serviceLocation.customerName)")
        try await ServiceLocationManager.shared.uploadCustomerServiceLocations(companyId: companyId, customer: finalCustomer,serviceLocation:serviceLocation)
        print("Uploading Body Of Water For >> \(serviceLocation.customerName)")

        try await BodyOfWaterManager.shared.uploadServiceLocationBodyOfWater(
            companyId: companyId,
            bodyOfWater: BodyOfWater(
                id: bodyOfWaterId,
                name: "Main",
                gallons: "20000",
                material: "Plaster",
                customerId: customerId,
                serviceLocationId: serviceLocationId,
                notes: "",
                shape: "",
                length: [],
                depth: [],
                width: []
            )
        )
        print(
            "Uploading Equipment For >> \(serviceLocation.customerName)"
        )
        let filterId = UUID().uuidString
        let pumpId = UUID().uuidString
        
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: Equipment(
                id: filterId,
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
                nextServiceDate: getNextServiceDate(
                    lastServiceDate: Date(),
                    every: "6",
                    frequency: "Month"
                ),
                
                notes: "",
                customerName: fullName,
                customerId: customerId,
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: bodyOfWaterId
            )
        )
        // Add Basic Parts for Filter
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: Equipment(
                id: pumpId,
                name:"Pump 1",
                category: .pump,
                make: "",
                model: "",
                dateInstalled: Date(),
                status: .operational,
                needsService: false,
                notes: "",
                customerName: fullName,
                customerId: customerId,
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: bodyOfWaterId
            )
        )
    }
    func uploadingCustomerMonthlySummary(startDate:Date,endDate:Date,customer: Customer, customerMonthlySummary: CustomerMonthlySummary, companyId: String) async throws {
        try await dataService.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: customerMonthlySummary)
    }

    func getActiveCustomers(customers:[Customer]){
        let calendar = Calendar.current
//        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let startDate = calendar.date(byAdding: .month, value: -1, to: Date())!
        
        
        var customerCount = 0
        var customerFiredCount = 0
        var customerHireCount = 0

        for customer in customers {
            if customer.active == true {
                customerCount = customerCount + 1
            }
            if customer.active == false && customer.fireDate != nil   {
                if customer.fireDate! > startDate {
                    customerFiredCount = customerFiredCount + 1
                }
            }
            
            if customer.active == true && customer.hireDate > startDate  {
                    customerHireCount = customerHireCount + 1
            }
        }
        self.activeCustomers = customerCount
        self.hiredCustomers = customerHireCount
        self.firedCustomers = customerFiredCount

    }



    func filterCustomerActiveAndNonActive(active:Bool,customers:[Customer]) {
        //very facncy Search Bar
        var filteredListOfCustomers:[Customer] = []
        for customer in customers {
            if customer.active {
                filteredListOfCustomers.append(customer)
            }
        }
        self.customersActive = filteredListOfCustomers
    }
    func filterCustomerList(filterTerm:String,customers:[Customer]) {
        //very facncy Search Bar
        var filteredListOfCustomers:[Customer] = []
        for customer in customers {
            let phone = customer.phoneNumber ?? "0"
            let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
            let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
            let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
            let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
            let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
            let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")

            let address = (customer.billingAddress.streetAddress ) + " " + (customer.billingAddress.city ) + " " + (customer.billingAddress.state ) + " " + (customer.billingAddress.zip )
            let company:String = customer.company ?? "0"
            let fullName = customer.firstName + " " + customer.lastName
            if customer.firstName.lowercased().contains(filterTerm.lowercased()) || customer.lastName.lowercased().contains(filterTerm.lowercased()) || replacedPhone6.lowercased().contains(filterTerm.lowercased()) || customer.email.lowercased().contains(filterTerm.lowercased()) || address.lowercased().contains(filterTerm.lowercased()) || company.lowercased().contains(filterTerm.lowercased()) || fullName.lowercased().contains(filterTerm.lowercased()){
                filteredListOfCustomers.append(customer)
            }
        }
        self.filteredCustomers = filteredListOfCustomers
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Customer Listener
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func addListenerForAllCustomers(companyId:String,filter:CustomerFilterOptions,sort:CustomerSortOptions){
        print("Adding Customer Listener")
        dataService.addListenerForAllCustomers(companyId: companyId, sort: sort, filter: filter) { [weak self] customers in
             self?.customers = customers
        }
    }
    func removeListener(){
        dataService.removeListenerForAllCustomers()

    }
}
