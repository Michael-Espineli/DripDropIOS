//
//  ModifyRecurringRouteViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/15/24.
//
// Related View : ModifyRecurring Route
// Purpose:
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ModifyRecurringRouteViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    // View Based Variables
    
    //Singles
    @Published  var isLoading:Bool = false
    @Published var selectedRecurringRoute:RecurringRoute = RecurringRoute(
        id: "",
        tech: "",
        techId: "",
        day: "",
        order: [],
        description: ""
    )

    @Published  var customerSearch:String = ""
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = "Error"
    @Published var selectedDay:String = ""
    @Published var startDate:Date = Date()
    @Published var endDate:Date = Date()
    @Published var customEvery:Int = 1
    @Published var estimatedTime:String = "15"
    @Published var frequency:LaborContractFrequency = .weekly
    @Published var noEndDate:Bool = true
    @Published var description:String = "description"
    @Published var transitionDate:Date = Date()
    @Published var showCustomSheet:Bool = false
    @Published var showCustomerSheet:Bool = false
    @Published var showAddNewCustomer:Bool = false
    @Published var showCustomerPicker:Bool = false

    @State private(set) var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    
    
    @Published  var selectedCustomer: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        phoneNumber: "",
        phoneLabel: "",
        active: false,
        company: "",
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        tags: [],
        linkedInviteId: UUID().uuidString
    )
    @Published var selectedCompanyUser: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )
    @Published var selectedJobTemplate: JobTemplate = JobTemplate(
        id: "",
        name: ""
    )
    @Published var selectedLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "Location",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false
    )
    //Arrays
    @Published var listOfRecurringStops:[RecurringServiceStop] = []

    //Data Service Variables
    
    //Singles
    @Published private(set) var recurringRoute: RecurringRoute? = nil

    //Array
    @Published private(set) var displayCustomers: [Customer] = []
    @Published private(set) var customers: [Customer] = []
    
    @Published private(set) var serviceLocations: [ServiceLocation] = []

    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var jobTemplates: [JobTemplate] = []

    func onLoad(companyId:String) async throws {
        self.isLoading = true
        //Get All Company User, based on status.
        self.companyUsers = try await CompanyUserManager.shared.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        
        //Sets the Current Selected Company User to First in list
        if self.companyUsers.isEmpty {
            print("Customer List Empty")
        } else {
            self.selectedCompanyUser = self.companyUsers.first!
        }
        self.serviceLocations = []

        self.recurringRoute = try await dataService.getSingleRouteFromTechIdAndDay(companyId: companyId, techId: self.selectedCompanyUser.userId, day: selectedDay)
        if self.recurringRoute != nil {
            print("Recurring Route is not nil")
            var listOfRSS :[RecurringServiceStop] = []
            for RSS in self.recurringRoute?.order ?? [] {
                let serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: RSS.locationId)
                print("Received Location For \(RSS.customerName)")
                self.serviceLocations.append(serviceLocation)
                let recurringServiceStop = try await dataService.getSingleRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStopId: RSS.recurringServiceStopId
                )
                print("Received Recurring Service Stop For \(recurringServiceStop.customerName) on \(recurringServiceStop.daysOfWeek)")

                listOfRSS.append(recurringServiceStop)
            }
            self.listOfRecurringStops = listOfRSS
     
        } else {
            print("No Recurring Route Found For \(self.selectedCompanyUser.userName) - \(self.selectedCompanyUser.userId) on \(self.selectedDay)")
        }
    
        
        //Job Templates
        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
        if self.jobTemplates.count != 0 {
            selectedJobTemplate = self.jobTemplates.first(where: {$0.name == "Weekly Cleaning"})! //DEVELOPER FIX THIS EXPLICIT UNWRAP
            print("Received \(self.jobTemplates.count) Job Templates")
        } else {
            print("No Jobs")
        }
        //
        

        self.isLoading = false
    }
    func onDismissOfCustomerPicker() {
        if selectedJobTemplate.id == "" {
            return
        }
        if selectedLocation.id == "" {
            return
        }
        if selectedCustomer.id == "" {
            return
        }
        let techFullName = (selectedCompanyUser.userName)
        listOfRecurringStops.append(RecurringServiceStop(id: UUID().uuidString,
                                                         internalId: "", //Developer Maybe
                                                         type: selectedJobTemplate.name,
                                                         typeId: selectedJobTemplate.id,
                                                         typeImage: selectedJobTemplate.typeImage ?? "gear",
                                                         customerName: selectedLocation.customerName,
                                                         customerId: selectedLocation.customerId,
                                                         address: selectedLocation.address,
                                                         tech: techFullName,
                                                         techId: selectedCompanyUser.userId,
                                                         dateCreated: Date(),
                                                         startDate: startDate,
                                                         endDate: endDate,
                                                         noEndDate: noEndDate,
                                                         frequency: frequency,
                                                         daysOfWeek: selectedDay,
                                                         description: description,
                                                         lastCreated: Date(),
                                                         serviceLocationId: selectedLocation.id,
                                                         estimatedTime: "15",
                                                        otherCompany: false,
                                                        laborContractId: "",
                                                        contractedCompanyId: ""))
        selectedCustomer.id = ""
        selectedLocation.id = ""
    }
    func modifyRecurringRouteWithVerification(companyId: String) async throws {
        self.isLoading = true
        //Validation
        if self.selectedCompanyUser.id == "" || self.selectedCompanyUser.userName == ""{
            self.alertMessage = "No Tech Selected"
            print(self.alertMessage)
            self.showAlert = true
            return
        }
        let techFullName = (self.selectedCompanyUser.userName)
        print("techFullName \(techFullName)")
        let techId = self.selectedCompanyUser.id
        print("techId \(techId)")
        
        let pushTechEntity = selectedCompanyUser
        
        let pushDay = selectedDay
        print("pushDay \(pushDay)")
        
        let pushStartDate = startDate
        print("pushStartDate \(pushStartDate)")
        
        let pushEndDate = endDate
        print("pushEndDate \(pushEndDate)")
        
        let pushStandardFrequencyType = frequency
        print("pushStandardFrequencyType \(frequency)")
        
        let pushNoEndDate = noEndDate
        print("pushNoEndDate \(pushNoEndDate)")

        let pushCustomEvery:Int = Int(customEvery)
        print("techFullName \(techFullName)")
        
        let pushDescription = description
        print("pushDescription \(pushDescription)")
        
        let pushEstimatedTime = estimatedTime
        print("pushEstimatedTime \(pushEstimatedTime)")
        
        let pushRecurringServiceStopList = listOfRecurringStops
        print("pushRecurringServiceStopList \(pushRecurringServiceStopList)")
        
        print("list Of Selected Locations >> \(listOfRecurringStops.count)")
        let pushJob = selectedJobTemplate
 

        
        
        
        //DEVELOPER I COULD TRY AND UPDATE RATHER THAN DELETE AND CREATE NEW
        //Maybe I needed to use a different recurring route id because I cant have more than one exisiting at the same time
        if let recurringRoute = self.recurringRoute {
            print("End Recurring Route")
            try await dataService.endRecurringRoute(companyId: companyId, recurringRouteId: recurringRoute.id, endDate: transitionDate)
            print("Make Sure to End All Recurring Service Stops After End Date")
            //End Each Recurring Service Stop
            for recurringStopOrder in recurringRoute.order {
                let RSS = try await dataService.getSingleRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStopId: recurringStopOrder.recurringServiceStopId
                )
                try await dataService.endRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStopId: recurringStopOrder.recurringServiceStopId,
                    endDate: transitionDate
                )
                //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
                //DEVELOPER Make sure to add starting new Recurring route after new transition
                let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopIdAfterDate(
                    companyId: companyId,
                    recurringServiceStopId: recurringStopOrder.recurringServiceStopId,
                    date: transitionDate
                )
                
                // Delete Each Service Stop under Recurring Service Stop
                for stop in serviceStopList {
                    try await dataService.deleteServiceStopById(
                        companyId: companyId,
                        serviceStopId: stop.id
                    )
                }
                try await dataService.endRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStopId: RSS.id,
                    endDate: transitionDate
                )
            }
            
            //Create a new recurring Route
            //Create New Recurring Route
            
            let techFullName = (selectedCompanyUser.userName)
            
            print("Making Route with \(self.listOfRecurringStops.count) stops for \(techFullName) - \(self.selectedDay)")
            var binder:[recurringRouteOrder] = []
            var count:Int = 1
            for RSS in listOfRecurringStops {
                print("Creating RSS for \(RSS.customerName) - \(RSS.id) - \(RSS.frequency)")
                let locationId = RSS.serviceLocationId
                let rssId = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        internalId: RSS.internalId,
                        type: selectedJobTemplate.name,
                        typeId: selectedJobTemplate.id,
                        typeImage: selectedJobTemplate.typeImage ?? "bubbles.and.sparkles.fill",
                        customerName: RSS.customerName,
                        customerId: RSS.customerId,
                        address: RSS.address,
                        tech: techFullName,
                        techId:selectedCompanyUser.userId,
                        dateCreated: Date(),
                        startDate:startDate,
                        endDate:endDate,
                        noEndDate: noEndDate,
                        frequency: self.frequency,
                        daysOfWeek: self.selectedDay,
                        description: self.description,
                        lastCreated: Date(),
                        serviceLocationId: RSS.serviceLocationId,
                        estimatedTime: "",
                        otherCompany: false,
                        laborContractId: "",
                        contractedCompanyId: ""
                    )
                )
                if rssId == nil {
                    print("Rss Id failure")
                    return
                    
                }
                let order = count
                count = count + 1
                let page = recurringRouteOrder(id: UUID().uuidString, order: order, recurringServiceStopId: rssId!,customerId: RSS.customerId,customerName: RSS.customerName, locationId: RSS.serviceLocationId)
                binder.append(page)
            }
            let recurringRouteId = self.selectedDay + self.selectedCompanyUser.id
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: self.selectedCompanyUser.id, day: self.selectedDay, order: binder, description: "")
            try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
            
            
        }
        self.isLoading = false

    }
    func onChangeOfCustomer(companyId:String) async throws {
        if !self.isLoading {
            self.serviceLocations = []
            if self.selectedCustomer.id != "" {
                
                self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
                    companyId: companyId,
                    customerId: self.selectedCustomer.id
                )
                if self.serviceLocations.count != 0 {
                    self.selectedLocation = self.serviceLocations.first!
                }
            }
        }
    }
    func removeFromListOfRecurringStops(at offsets: IndexSet) {
        self.listOfRecurringStops.remove(atOffsets: offsets)
    }
    func filterCustomerList() {
        if self.customerSearch != "" {
            self.displayCustomers = BasicFunctions.shared.filterCustomerList(searchTerm: self.customerSearch, customers: self.customers)
            if !self.displayCustomers.isEmpty {
                self.selectedCustomer = self.displayCustomers.first!
            }
        }
    }
}
