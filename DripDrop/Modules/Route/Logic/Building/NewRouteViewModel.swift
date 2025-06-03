//
//  NewRouteViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/16/24.
//
// Related View : NewRouteView Route
// Purpose:
import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class NewRouteViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    // View Based Variables
    @Published var listOfRecurringStops:[RecurringServiceStop] = []
    @Published var jobType:JobTemplate = JobTemplate(id: "",
                                                 name: "Job Template",
                                                 type: "",
                                                 typeImage: "",
                                                 dateCreated: Date(),
                                                 rate: "",
                                                 color: "")
    @Published var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        active: false,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var customerSearch:String = ""
    @Published var listOfCustomers:[Customer] = []
    
    @Published var location:ServiceLocation = ServiceLocation(id: "", nickName: "Location",
                                                                  address: Address(streetAddress: "",
                                                                                   city: "",
                                                                                   state: "",
                                                                                   zip: "0",
                                                                                   latitude: 0,
                                                                                   longitude: 0),
                                                                  gateCode: "",
                                                                  mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
                                                                  bodiesOfWaterId: [],
                                                                  rateType: "", laborType: "",
                                                                  chemicalCost: "",
                                                                  laborCost: "",
                                                                  rate: "",
                                                                  customerId: "",
                                                                  customerName: "",
                                                          preText: false)
    
    @Published var techEntity:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active,workerType: .contractor)
    
    @Published var techList:[CompanyUser] = []
    @Published var startDate:Date = Date()
    @Published var endDate:Date = Date()
    
    @Published var noEndDate:Bool = true
    @Published var standardFrequencyType:LaborContractFrequency = .weekly
    @Published var customEvery:Int = 1
    @Published var showCustomSheet:Bool = false
    @Published var showCustomerSheet:Bool = false
    @Published var showAddNewCustomer:Bool = false
    @Published var showCustomerPicker:Bool = false

    @Published var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    @Published var description:String = "description"
    @Published var estimatedTime:String = "15"
    @Published var selectedDay:String = ""
    //errors
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = "Error"
    @Published var isLoading:Bool = false
  
    //Singles
    
    //DataService
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var companyUser: CompanyUser? = nil

    @Published private(set) var listOfRSS: [RecurringServiceStop] = []
    @Published private(set) var recurringRoute:RecurringRoute? = nil

    //Functions
    
    func onLoad(companyId:String) async throws {
        if !self.isLoading {
            self.isLoading = true
            
            print("Inital Load")
            //Get CompanyUsers
            var workingTech:CompanyUser? = nil
            if techEntity.id != "" {
                workingTech = techEntity
                companyUser = techEntity
            } else {
                self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                self.techEntity = companyUsers.first!
                workingTech = companyUsers.first
            }
            guard let tech = workingTech else {
                print("Error 1")
                throw FireBaseRead.unableToRead
            }
            //Check if A recurring Route Already Exists
            var recurringRoute:RecurringRoute? = nil
            print(" Getting Recurring Service Stop For \(selectedDay) \(tech.userId)")
            let listOfRecurringRoutes = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: selectedDay, techId: tech.userId)
            if listOfRecurringRoutes.count == 1 {
                recurringRoute = listOfRecurringRoutes.first!
            }
            if let recurringRoute {
                self.recurringRoute = recurringRoute
                print("Got Active recurring Route")
                
                var listOfRSS :[RecurringServiceStop] = []
                for order in recurringRoute.order {
                    print("Gettings RSS >> \(order.recurringServiceStopId)")
                    
                    let RSS = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: order.recurringServiceStopId)
                    
                    listOfRSS.append(RSS)
                    print("Got \(listOfRSS.count)")
                }
                
                self.listOfRSS = listOfRSS
            } else {
                self.listOfRSS = []
                self.recurringRoute = nil
            }
            
            //Get Jobs
            print("Getting Jobs")
            let jobTemplates = try await dataService.getAllWorkOrderTemplates(companyId: companyId)
            if jobTemplates.count != 0 {
                self.jobType = jobTemplates.first(where: {$0.name == "Weekly Cleaning"})! //DEVELOPER FIX THIS EXPLICIT UNWRAP
                print("Received \(jobTemplates.count) Job Templates")
                
            } else {
                print("No Jobs")
            }
            
            self.isLoading = false
        }
    }
    func submitOrUpdateRoute(companyId:String) async throws {
        self.isLoading = true

        if techEntity.id == "" || techEntity.userName == "" {
            alertMessage = "No Tech Selected"
            print(alertMessage)
            showAlert = true
            return
        }
        
        let techFullName = (techEntity.userName)
        print("tech Full Name: \(techFullName)")
        let techId = techEntity.userId
        print("tech Id: \(techId)")

        let pushTechEntity = techEntity

        let pushDay = selectedDay
        print("push Day: \(pushDay)")

        let pushStartDate = startDate
        print("push Start Date: \(pushStartDate)")

        let pushEndDate = endDate
        print("push End Date: \(pushEndDate)")

        let pushStandardFrequencyType = standardFrequencyType
        print("push Standard FrequencyType: \(pushStandardFrequencyType)")

        let pushNoEndDate = noEndDate
        print("push No End Date: \(pushNoEndDate)")

        let pushCustomEvery:Int = Int(customEvery)
        print("tech Full Name: \(techFullName)")

        let pushDescription = description
        print("push Description: \(pushDescription)")

        let pushEstimatedTime = estimatedTime
        print("push Estimated Time: \(pushEstimatedTime)")

        let pushRecurringServiceStopList = listOfRecurringStops
        print("push Recurring Service Stop List: \(pushRecurringServiceStopList)")

        print("list Of Selected Locations: \(listOfRecurringStops.count)")
        let pushJob = jobType
        var recurringRoute:RecurringRoute? = nil
        if let recurringRoute1 = self.recurringRoute{
            print("Updating Current Recurring Route")
            recurringRoute = recurringRoute1
            do {
                try await modifyRecurringRouteWithVerification(
                    companyId: companyId,
                    tech: pushTechEntity,
                    noEndDate: pushNoEndDate,
                    day: pushDay,
                    frequency: pushStandardFrequencyType,
                    perTimes: pushCustomEvery,
                    transitionDate: pushStartDate,
                    newEndDate: pushEndDate,
                    description: pushDescription,
                    jobTemplate: jobType,
                    recurringStopList: pushRecurringServiceStopList,
                    currentRecurringRoute: recurringRoute1
                )
                
                isLoading = false
                alertMessage = "Success"
                print(alertMessage)
                showAlert = true
                
 
            } catch {
                isLoading = false
                alertMessage = "Failed to Upload"
                showAlert = true
                print("Failed to Load - [NewRouteViewModel]")
                
                print(error)
            }
        } else {
            print("")
            print("Creating New Recurring Route")
            do {
                try await createAndUploadRecurringRouteWithVerification(
                    companyId: companyId,
                    tech: pushTechEntity,
                    recurringStopsList: pushRecurringServiceStopList,
                    job: pushJob,
                    noEndDate: pushNoEndDate,
                    description: pushDescription,
                    day: pushDay,
                    standardFrequencyType: pushStandardFrequencyType,
                    customFrequencyType: pushCustomEvery,
                    startDate: pushStartDate,
                    endDate: pushEndDate,
                    currentRecurringRoute: recurringRoute
                )
                isLoading = false
                alertMessage = "Success"
                print(alertMessage)
                showAlert = true
            } catch {
                isLoading = false
                alertMessage = "Failed to Upload"
                showAlert = true
                print("Failed to Load - [NewRouteViewModel]")
                
                print(error)
            }
        }
    }
    func modifyRecurringRouteWithVerification(companyId: String,
                                       tech:CompanyUser,
                                       noEndDate:Bool,
                                       day:String,
                                       frequency:LaborContractFrequency,
                                       perTimes:Int,
                                       transitionDate:Date,
                                       newEndDate:Date,
                                        description:String,
                                        jobTemplate:JobTemplate,
                                        recurringStopList:[RecurringServiceStop],
                                        currentRecurringRoute:RecurringRoute) async throws {
        
        //DEVELOPER I COULD TRY AND UPDATE RATHER THAN DELETE AND CREATE NEW
        //Maybe I needed to use a different recurring route id because I cant have more than one exisiting at the same time
        print("End Recurring Route")
        try await dataService.endRecurringRoute(companyId: companyId, recurringRouteId: currentRecurringRoute.id, endDate: transitionDate)
        print("Make Sure to End All Recurring Service Stops After End Date")
        //End Each Recurring Service Stop
        for recurringStopOrder in currentRecurringRoute.order {
            let RSS = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId)
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, endDate: transitionDate)
            //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
            //DEVELOPER Make sure to add starting new Recurring route after new transition
            let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, date: transitionDate)
            
            // Delete Each Service Stop under Recurring Service Stop
            for stop in serviceStopList {
                try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
            }
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
        }
        //Create New Recurring Route
        //Maybe I change up this so it just updates instead of Deletes and redos.
        print("Developer Error")
//        try await modifyRecurringRouteHelperFunction(companyId: companyId, tech: tech, recurringStopsList: recurringStopList, job: jobTemplate, noEndDate: noEndDate, description: description, day: day, standardFrequencyType: standardFrequencyType, customFrequencyType: customFrequencyType, customFrequencyNumber: customFrequencyNumber, startDate: transitionDate, endDate: newEndDate, currentRecurringRoute: nil)
    }
    func createAndUploadRecurringRouteWithVerification(
        companyId: String,
        tech:CompanyUser,
        recurringStopsList:[RecurringServiceStop],
        job:JobTemplate,
        noEndDate:Bool,
        description:String,
        day:String,
        standardFrequencyType:LaborContractFrequency,
        customFrequencyType:Int,
        startDate:Date,
        endDate:Date,
        currentRecurringRoute:RecurringRoute?
    ) async throws {
        print("")

        if let recurringRoute = currentRecurringRoute {
            //Update the Curring Recurring route

            var routeListChanged: Bool = false
            var EndDateChanged: Bool = false
            print(" - Updating Existing Recurring Route For \(recurringRoute.tech) - \(recurringRoute.day)")
            //Handle Day / Tech Change in Reassign Route
            //Check if each reecurring service stop is in the recurring route.
            if checkRecurringServiceStopListAndOrderListAreSame(recurringServiceStops: recurringStopsList, order: recurringRoute.order) {
                print("No Changes in Recurring Service Stops List Have Been Made")
                routeListChanged = false
            } else {
                print("Changes to Recurring Service Stop List Have been Made")
                routeListChanged = true
                //Update RecurringService Stops and Order list
            }
            //Checks End Date
            // Add End Date TO Recurring Route
            //Make updates
            
        } else {
            //Create a new recurring Route
            let techFullName = tech.userName
            
            print(" - Creating Route with \(recurringStopsList.count) stops for \(techFullName) - \(day)")
            var binder:[recurringRouteOrder] = []
            var count:Int = 1
            for RSS in recurringStopsList {
                let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)

                print(" - Creating Recurring Service Stop Id >>  \(RSS.id) - \(RSS.customerName) - \(RSS.frequency)")
                let rssId = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: "comp_rss_" + UUID().uuidString,
                        internalId: "RSS" + String(rssCount),
                        type: job.name,
                        typeId: job.id,
                        typeImage: job.typeImage ?? "bubbles.and.sparkles.fill",
                        customerName: RSS.customerName,
                        customerId: RSS.customerId,
                        address: RSS.address,
                        tech: techFullName,
                        techId:tech.userId,
                        dateCreated: Date(),
                        startDate:startDate,
                        endDate:endDate,
                        noEndDate: noEndDate,
                        frequency: standardFrequencyType,
                        daysOfWeek: day,
                        description: description,
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
//            let recurringRouteId = day + tech.userId // DEVELOPER
            let recurringRouteId = UUID().uuidString

            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.userId, day: day, order: binder, description: "")
            try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
        }
    }
    func onDismissOfCustomerPicker() {
        if jobType.id == "" {
            return
        }
        if location.id == "" {
            return
        }
        if customer.id == "" {
            return
        }
        let techFullName = (techEntity.userName)
        listOfRecurringStops.append(RecurringServiceStop(id: UUID().uuidString,
                                                         internalId: "", //DEVELOPER
                                                         type: jobType.name,
                                                         typeId: jobType.id,
                                                         typeImage: jobType.typeImage ?? "gear",
                                                         customerName: location.customerName,
                                                         customerId: location.customerId,
                                                         address: location.address,
                                                         tech: techFullName,
                                                         techId: techEntity.userId,
                                                         dateCreated: Date(),
                                                         startDate: startDate,
                                                         endDate: endDate,
                                                         noEndDate: noEndDate,
                                                         frequency: standardFrequencyType,
                                                         daysOfWeek: selectedDay,
                                                         description: description,
                                                         lastCreated: Date(),
                                                         serviceLocationId: location.id,
                                                         estimatedTime: "15",
                                                        otherCompany: false,
                                                        laborContractId: "",
                                                        contractedCompanyId: ""))
        customer.id = ""
        location.id = ""
    }
    func checkRecurringServiceStopListAndOrderListAreSame(recurringServiceStops:[RecurringServiceStop],order:[recurringRouteOrder])-> Bool {
        for RSS in recurringServiceStops {
            //Check Each Recurring Stop To make Sure all are in the order list
            if !order.contains(where: {$0.recurringServiceStopId == RSS.id}){
                return false
            }
        }
        for recurringRouteOrder in order {
            //Check Each Recurring Stop To make Sure all are in the order list
            if !recurringServiceStops.contains(where: {$0.id == recurringRouteOrder.recurringServiceStopId}){
                return false
            }
        }
        return true
    }
    func removeRecurringstops(at offsets: IndexSet) {
        listOfRecurringStops.remove(atOffsets: offsets)
    }
}
