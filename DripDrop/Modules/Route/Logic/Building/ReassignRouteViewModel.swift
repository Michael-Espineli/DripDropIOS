//
//  ReassignRouteViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/16/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ReassignRouteViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    // View Based Variables
    @Published var listOfRecurringStops:[RecurringServiceStop] = []
 
    
    @Published var selectedTechEntity:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor
    )
    @Published var receivedTechEntity:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor
    )
    @Published var selectedDay:String = ""
    @Published var receivedDay:String = ""

    @Published var transitionDate:Date = Date()
    @Published var endDate:Date = Date()
    
    @Published var noEndDate:Bool = true
    @Published var standardFrequencyType:String = "Weekly"
    
    @Published var customMeasurmentsOfTime:String = "Daily"
    @Published var customEvery:Int = 1
    @Published var showCustomSheet:Bool = false
    @Published var showCustomerSheet:Bool = false
    @Published var showAddNewCustomer:Bool = false

    @Published var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @Published var measurementsOfTime:[String] = ["Daily","WeekDay","Weekly","Bi-Weekly","Monthly","Custom"]

    @Published var description:String = "description"
    @Published var estimatedTime:String = "15"
    //errors
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = "Error"
    @Published var isLoading:Bool = false
    @Published var showChangeConfirmation : Bool = false
    
    
    //DataService Variables
    @Published private(set) var recurringRoute:RecurringRoute? = nil
    @Published private(set) var recurringServiceStop:RecurringServiceStop? = nil

    @Published private(set) var recurringServiceStops:[RecurringServiceStop] = []
    @Published private(set) var serviceLocations:[ServiceLocation] = []

    @Published private(set) var techList:[CompanyUser] = []
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var jobTemplates: [JobTemplate] = []
    @Published private(set) var jobType:JobTemplate = JobTemplate(
        id: "",
        name: "Job Template",
        type: "",
        typeImage: "",
        dateCreated: Date(),
        rate: "",
        color: ""
    )

    func onLoad(companyId:String) async throws {
        
        self.isLoading = true
        
        //Get The Route based on day and companyUserId. I wonder how that will work with other Companies Contracted Work.
        let recurringRouteId = selectedDay + receivedTechEntity.id
        
        //Recurring Route may come back optional because thye might not have a route set up yet or something of the like. The Recurring Routes are stored using the day and the DBUser ID / CompanyUser userID
        self.serviceLocations = []
        self.recurringRoute = try await dataService.getSingleRouteFromTechIdAndDay(companyId: companyId, techId: self.receivedTechEntity.userId, day: self.selectedDay)
        
        //If there is already a Recurring route created for that
        if self.recurringRoute != nil {
            var listOfRSS :[RecurringServiceStop] = []
            for RSS in self.recurringRoute?.order ?? [] {
                do {
                     let location = try await dataService.getServiceLocationById(companyId: companyId, locationId: RSS.locationId)
                    self.serviceLocations.append(location)
                    self.recurringServiceStop = try await dataService.getSingleRecurringServiceStop(
                        companyId: companyId,
                        recurringServiceStopId: RSS.id
                    )
                    if let recurringStop = self.recurringServiceStop {
                        listOfRSS.append(recurringStop)
                    }
                    
                } catch {
                    print("No Location at spot")
                }
            }
            self.listOfRecurringStops = listOfRSS
        }

        //Getting Company Users
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
        if self.companyUsers.count != 0 {
      
            print("Received \(self.companyUsers.count) Techs")
            techList = self.companyUsers
        } else {
            print("No Techs Received")
        }
        self.jobTemplates = try await dataService.getAllWorkOrderTemplates(companyId: companyId)
        
        if self.jobTemplates.count != 0 {
            self.jobType = self.jobTemplates.first(where: {$0.name == "Weekly Cleaning"})! //DEVELOPER FIX THIS EXPLICIT UNWRAP
            print("Received \(self.jobTemplates.count) Job Templates")
            
        } else {
            print("No Jobs")
        }
        self.isLoading = false
    }
    func saveChanges(companyId:String) async throws {
    }
    func confirmChanges(){
        if !self.isLoading {
            self.isLoading = true
            if self.receivedDay != self.selectedDay && self.receivedTechEntity != self.selectedTechEntity {
                self.alertMessage = "Please confirm, \(self.receivedTechEntity.userName) -> \(self.selectedTechEntity.userName) and \(self.receivedDay) -> \(self.selectedDay)"
                self.showChangeConfirmation = true
            } else if self.receivedDay != self.selectedDay {
                self.alertMessage = "Please confirm, \(self.receivedTechEntity.userName) and \(self.receivedDay) -> \(self.selectedDay)"
                self.showChangeConfirmation = true
            } else if self.receivedTechEntity != self.selectedTechEntity {
                self.alertMessage = "Please confirm, \(self.receivedTechEntity.userName) -> \(self.selectedTechEntity.userName)"
                self.showChangeConfirmation = true
            } else {
                self.alertMessage = "No Change in Day or Tech"
                print(self.alertMessage)
                self.showAlert = true
            }
            self.isLoading = false
        }
    }
    func removeItemRecurringStopList(at offsets: IndexSet) {
        listOfRecurringStops.remove(atOffsets: offsets)
    }
    func reassigndRecurringRouteWithVerification(companyId: String,
                                       tech:CompanyUser,
                                       noEndDate:Bool,
                                       day:String,
                                    standardFrequencyType:LaborContractFrequency,
                                        timesPerFrequency:Int,
                                       transitionDate:Date,
                                       newEndDate:Date,
                                                 description:String,
                                                 jobTemplate:JobTemplate,
                                                 recurringStopList:[RecurringServiceStop],
                                       currentRecurringRoute:RecurringRoute) async throws {
        //DEVELOPER I COULD TRY AND UPDATE RATHER THAN DELETE AND CREATE NEW
        print("End Recurring Route")
        try await dataService.endRecurringRoute(companyId: companyId, recurringRouteId: currentRecurringRoute.id, endDate: transitionDate)
        print("Make Sure to End All Recurring Service Stops After End Date")
        //End Each Recurring Service Stop
        var recurringRouteServiceStopDic : [RecurringServiceStop:[ServiceStop]] = [:]
        var oldRecurringStopList:[RecurringServiceStop] = []
        for recurringStopOrder in currentRecurringRoute.order {
            let RSS = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId)
            oldRecurringStopList.append(RSS)
            print("Old Recurring Stop List Count \(oldRecurringStopList.count)")
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, endDate: transitionDate)
            //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
            //DEVELOPER Make sure to add starting new Recurring route after new transition
            let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, date: transitionDate)
            
            // Delete Each Service Stop under Recurring Service Stop
//                for stop in serviceStopList {
//                    try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
//                }
            recurringRouteServiceStopDic[RSS] = serviceStopList
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
        }
        //DEVELOPER MAYBE CHANGE LATER
//        try await createAndUploadRecurringRouteWithOutAddingNewServiceStops(
//            companyId: companyId,
//            tech: tech,
//            recurringStopsList: oldRecurringStopList,
//            job: jobTemplate,
//            noEndDate: noEndDate,
//            description: description,
//            day: day,
//            standardFrequencyType: standardFrequencyType,
//            timesPerFrequency: timesPerFrequency,
//            startDate: transitionDate,
//            endDate: newEndDate,
//            currentRecurringRoute: nil,
//            serviceStopsListDic: recurringRouteServiceStopDic
//        )
    }
}
