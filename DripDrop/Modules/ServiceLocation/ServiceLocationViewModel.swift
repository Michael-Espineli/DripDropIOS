//
//  ServiceLocationViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ServiceLocationViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var serviceLocation: ServiceLocation? = nil
    @Published private(set) var totalRate: Double? = nil
    @Published private(set) var totalCustomerBeingLoaded: Int? = nil
    @Published private(set) var currentNumberCustomerBeingLoaded: Int? = nil
    @Published private(set) var coordinates: CLLocationCoordinate2D? = nil

    //ARRAYS
    @Published private(set) var serviceLocations: [ServiceLocation] = []
    @Published private(set) var serviceLocationsFiltered: [ServiceLocation] = []
    
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func addNewCustomerServiceLocation(
        customer:Customer,
        serviceLocation:ServiceLocation,
        companyId: String
    ) async throws{
        try await dataService.uploadCustomerServiceLocations(
            companyId: companyId,
            customer: customer,
            serviceLocation:serviceLocation
        )
    }
    func addNewCustomerServiceLocationWithValidation(
        companyId: String,
        customer:Customer,
        serviceLocationId:String,
        nickName:String,
        address:Address,
        gateCode:String,
        dogNames:[String],
        estimatedTime:String,
        mainContact:Contact,
        notes:String,
        trees:[String],
        bushes:[String],
        other:[String],
        bodyOfWaterList:[BodyOfWater],
        preText:Bool
    ) async throws{
//        if bodyOfWaterList.count == 0 {
//            throw ServiceLocationError.bodyOfWaterListEmpty
//        }
        if customer.id == "" {
            throw ServiceLocationError.invalidCustomerId
        }
        if customer.firstName == "" {
            throw ServiceLocationError.invalidCustomerName
        }
        if customer.lastName == "" {
            throw ServiceLocationError.invalidCustomerName
        }
        let fullName = customer.firstName + " " + customer.lastName
        if nickName == "" {
            throw ServiceLocationError.invalidNickName
        }

        if address.streetAddress == "" {
            throw ServiceLocationError.invalidStreetAddress
        }
        if address.city == "" {
            throw ServiceLocationError.invalidCity
        }
        if address.state == "" {
            throw ServiceLocationError.invalidState
        }
        if address.zip == "" {
            throw ServiceLocationError.invalidZip
        }
        
        if mainContact.name == "" {
            throw ServiceLocationError.invalidContactName
        }
        if mainContact.phoneNumber == "" {
            throw ServiceLocationError.invalidContactPhoneNumber
        }
        if mainContact.email == "" {
            throw ServiceLocationError.invalidContactEmail
        }
        guard let time = Int(estimatedTime) else {
            throw ServiceLocationError.invalidTime
        }
        var bowList:[String] = []
        for BOW in bodyOfWaterList{
            bowList.append(BOW.id)
            try await BodyOfWaterManager.shared.uploadBodyOfWaterByServiceLocation(
                companyId: companyId,
                bodyOfWater: BOW
            )
            try await EquipmentManager.shared.addNewEquipmentWithParts(
                companyId: companyId,
                equipment: Equipment(
                    id: UUID().uuidString,
                    name: "Pump 1",
                    
                    category: .pump,
                    make: "",
                    model: "",
                    dateInstalled: Date(),
                    status: .operational,
                    needsService: false,
                    notes: "",
                    customerName: fullName,
                    customerId: customer.id,
                    serviceLocationId: serviceLocationId,
                    bodyOfWaterId: BOW.id,
                    isActive: true
                )
            )
            try await EquipmentManager.shared.addNewEquipmentWithParts(
                companyId: companyId,
                equipment: Equipment(
                    id: UUID().uuidString,
                    name: "Filter 1",
                    
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
                    customerId: customer.id,
                    serviceLocationId: serviceLocationId,
                    bodyOfWaterId: BOW.id,
                    isActive: true
                )
            )
            
        }
        let serviceLocation = ServiceLocation(
            id: serviceLocationId,
            nickName: nickName,
            address: address,
            gateCode: gateCode,
            dogName: dogNames,
            estimatedTime: 
                time
            ,
            mainContact: mainContact,
            notes: notes,
            bodiesOfWaterId: bowList,
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: customer.id,
            customerName: fullName,
            backYardTree: trees,
            backYardBushes: bushes,
            backYardOther: other,
            preText:preText
        )
        
        try await dataService.uploadCustomerServiceLocations(
            companyId: companyId,
            customer: customer,
            serviceLocation:serviceLocation
        )
        try await dataService.uploadCustomerContact(companyId: companyId, customerId: customer.id, contact: serviceLocation.mainContact)

    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllCustomerServiceLocations(
        companyId:String
    ) async throws{
        self.serviceLocations = try await dataService.getAllCompanyServiceLocations(
            companyId: companyId
        )
        
    }
    func get4CustomerServiceLocations(
        companyId:String,
        customer:Customer
    ) async throws{
        self.serviceLocations = try await dataService.get4CustomerServiceLocations(
            companyId: companyId,
            customer: customer
        )
        
    }
    func getAllCustomerServiceableLocations(
        companyId: String
    ) async throws{
        self.serviceLocations = try await dataService.getAllCustomerServiceLocations(
            companyId: companyId
        ) //DEVELOPER
        
    }
    func getAllCustomerServiceLocationsById(
        companyId: String,
        customerId:String
    ) async throws {
        self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: customerId
        )
    }
    func getServiceLocationByCustomerAndLocationId(
        companyId:String,
        customerId:String,
        locationId:String
    ) async throws {
        self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: locationId)
    }
    func getTotalMonthlyRateFromServiceStops(
        companyId: String,
        customers:Customer
    ) async throws {
        let serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: customers.id
        )
        
        var rate: Double = 0
        for location in serviceLocations {
            
            rate = (
                Double(
                    location.rate
                ) ?? 100.00
            ) + rate
        }
        self.totalRate = rate
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateCustomerServiceLocation(
        companyId: String,
        customerId:String,
        serviceLocation:ServiceLocation,
        originalServiceLocation:ServiceLocation
    ) async throws {
        // Get Service Stop by Service Location Id
        let serviceStops = try await dataService.getServiceStopByServiceLocationId(companyId: companyId, serviceLocationId: originalServiceLocation.id)
        print("Received \(serviceStops.count) Service Stops")

        // Get Recurring Service Stops By Service Location Id
        let recurringServiceStops = try await dataService.getRecurringServiceStopByServiceLocationId(companyId: companyId, serviceLocationId: originalServiceLocation.id)
        print("Received \(recurringServiceStops.count) Recurring Service Stops")

        
        if serviceLocation.address != originalServiceLocation.address {
            // Update Service Location
            try await dataService.updateServiceLocationAddress(
                companyId: companyId,
                currentCustomerId: customerId,
                serviceLocationId: originalServiceLocation.id,
                address: serviceLocation.address
            )
            // Update Recurring Service Stops
            for recurringServiceStop in recurringServiceStops {
                try await dataService.updateRecurringServiceStopAddress(companyId: companyId, recurringServiceStopId: recurringServiceStop.id, address: serviceLocation.address)
            }
            print("Updated \(recurringServiceStops.count) Recurring Service Stops")
            // Update Service Stops
            for serviceStop in serviceStops {
                try await dataService.updateServiceStopAddress(companyId: companyId, serviceStopId: serviceStop.id, address: serviceLocation.address)
            }
            print("Updated \(serviceStops.count) Service Stops")

        }
        if serviceLocation.nickName != originalServiceLocation.nickName {
            try await dataService.updateServiceLocationNickName(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                nickName: serviceLocation.nickName
            )
            
        }
        
        if serviceLocation.gateCode != originalServiceLocation.gateCode {
            try await dataService.updateServiceLocationGateCode(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                gateCode: serviceLocation.gateCode
            )
        }
        
        if serviceLocation.dogName != originalServiceLocation.dogName {
            try await dataService.updateServiceLocationDogName(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                dogNames: serviceLocation.dogName ?? []
            )
        }
        if serviceLocation.estimatedTime != originalServiceLocation.estimatedTime {
            try await dataService.updateServiceLocationEstimatedTime(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                estimatedTime: serviceLocation.estimatedTime ?? 0
            )
        }
        if serviceLocation.notes != originalServiceLocation.notes {
            try await dataService.updateServiceLocationNotes(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                notes: serviceLocation.notes ?? ""
            )
        }
        
        if serviceLocation.mainContact != originalServiceLocation.mainContact {
            try await dataService.updateServiceLocationContact(
                companyId: companyId,
                serviceLocationId: originalServiceLocation.id,
                contact: serviceLocation.mainContact
            )
        }

    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func searchForCustomersLocations(
        searchTerm:String,
        serviceLocation:[ServiceLocation]
    ) async throws{
        self.serviceLocationsFiltered = dataService.searchForCustomersLocations(
            searchTerm:searchTerm,
            serviceLocation: serviceLocation
        )
    }
    func getServiceLocationByCustomerAndLocationIdForMap(
        companyId:String,
        recurringServiceStops:[RecurringServiceStop]
    ) async throws {
        var listOfServiceLocations:[ServiceLocation] = []
        for stop in recurringServiceStops {
            listOfServiceLocations.append(
                try await dataService.getServiceLocationById(companyId: companyId, locationId: stop.serviceLocationId)
            )
        }
        self.serviceLocationsFiltered = listOfServiceLocations
    }
    func filterLocationList(
        filterTerm:String,
        locations:[ServiceLocation]
    ) {
        var filteredListOfCustomersLocations:[ServiceLocation] = []
        let filterTermLowerCase = filterTerm.lowercased()
        for location in locations {
            if location.customerName.lowercased().contains(
                filterTermLowerCase
            ) || location.nickName.lowercased().contains(
                filterTermLowerCase
            ) || location.address.streetAddress.lowercased().contains(
                filterTermLowerCase
            ) || location.address.city.lowercased().contains(
                filterTermLowerCase
            ) || location.address.state.lowercased().contains(
                filterTermLowerCase
            ) || location.address.zip.lowercased().contains(
                filterTermLowerCase
            ) {
                filteredListOfCustomersLocations.append(
                    location
                )
            }
        }
        print(
            filteredListOfCustomersLocations
        )
        self.serviceLocationsFiltered = filteredListOfCustomersLocations
    }
    func calculateLatitudeLongitude(street:String,city:String,state:String,zip:String) async {
        let fullAddress = street + " " + city + " " + state + " " + zip
        let noSpace = fullAddress.replacingOccurrences(of: " ", with: "")
        let geoCoder = CLGeocoder()
        print("Calculating Lat Long For \(fullAddress)")
        geoCoder.geocodeAddressString(fullAddress, completionHandler: { (placemarks, error) in
//               if error != nil {
//                   print("Failed to retrieve location")
//                   return
//               }
//               
               var location: CLLocation?
               
               if let placemarks = placemarks, placemarks.count > 0 {
                   location = placemarks.first?.location
               }
               
               if let location = location {
                   let coordinate = location.coordinate
                   print("\nlat: \(coordinate.latitude), long: \(coordinate.longitude)")
                   self.coordinates = location.coordinate

               }
               else
               {
                   print("No Matching Location Found")
               }
           })
    }
}
