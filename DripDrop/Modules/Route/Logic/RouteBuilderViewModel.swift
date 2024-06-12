//
//  RouteBuilderViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class RouteBuilderViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var companyUsers: [CompanyUser] = []
    @Published var companyUser: CompanyUser? = nil

    @Published var listOfRSS: [RecurringServiceStop] = []
    @Published var jobType:JobTemplate? = nil
    @Published var recurringRoute:RecurringRoute? = nil

    func initialLoad(companyId:String,tech:CompanyUser?,day:String) async throws {
        print("Inital Load")
        //Get CompanyUsers
        var workingTech:CompanyUser? = nil
        if let tech {
            workingTech = tech
            companyUser = tech
        } else {
            self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
            workingTech = companyUsers.first
        }
        guard let tech = workingTech else {
            print("Error 1")
            throw FireBaseRead.unableToRead
        }
        //Check if A recurring Route Already Exists
        var recurringRoute:RecurringRoute? = nil
        print(" Getting Recurring Service Stop For \(day) \(tech.userId)")
        let listOfRecurringRoutes = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: day, techId: tech.userId)
        if listOfRecurringRoutes.count == 1 {
            recurringRoute = listOfRecurringRoutes.first!
        }
        if let recurringRoute {
            self.recurringRoute = recurringRoute
            print("Got Active recurring Route")

            var listOfRSS :[RecurringServiceStop] = []
            for order in recurringRoute.order {
//                    let serviceLocation =  try await dataService.getServiceLocationsCustomerAndLocationId(
//                        companyId: companyId,
//                        customerId: order.customerId,
//                        locationId: order.locationId
//                    )
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
    }
    func reLoad(companyId:String,tech:CompanyUser,day:String) async throws {
        print("Reload")

        if tech.userId == "" {
            throw FireBasePublish.unableToPublish
        }
        //Check if A recurring Route Already Exists
        var recurringRoute:RecurringRoute? = nil
        
        let listOfRecurringRoutes = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: day, techId: tech.userId)
        if listOfRecurringRoutes.count == 1 {
            recurringRoute = listOfRecurringRoutes.first!
        }
        if let recurringRoute {
            print("Recurring Route is not nil")

            var listOfRSS :[RecurringServiceStop] = []
            for order in recurringRoute.order {
                    let serviceLocation =  try await dataService.getServiceLocationsCustomerAndLocationId(
                        companyId: companyId,
                        customerId: order.customerId,
                        locationId: order.locationId
                    )
                let RSS = try await RecurringServiceStopManager.shared.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: order.id)
                listOfRSS.append(RSS)

            }
            self.listOfRSS = listOfRSS
        } else {
            print("Recurring Route is nil")
            self.listOfRSS = []
            self.recurringRoute = nil
        }
    }
    func createAndUploadRecurringRouteWithVerification(companyId: String,
                                       tech:CompanyUser,
                                       recurringStopsList:[RecurringServiceStop],
                                       job:JobTemplate,
                                       noEndDate:Bool,
                                       description:String,
                                       day:String,
                                       standardFrequencyType:String,
                                       customFrequencyType:String,
                                       customFrequencyNumber:Int,
                                       startDate:Date,
                                       endDate:Date,
                                                       currentRecurringRoute:RecurringRoute?) async throws {
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
                print(" - Creating Recurring Service Stop Id >>  \(RSS.id) - \(RSS.customerName) - \(RSS.frequency)")
                let locationId = RSS.locationId
                let rssId = try await RecurringRouteManager.shared.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        type: job.name,
                        typeId: job.id,
                        typeImage: job.typeImage ?? "bubbles.and.sparkles.fill",
                        customerName: RSS.customerName,
                        customerId: RSS.customerId,
                        frequency: standardFrequencyType,
                        address: RSS.address,
                        dateCreated: Date(),
                        tech: techFullName,
                        endDate:endDate,
                        startDate:startDate,
                        techId:tech.userId,
                        noEndDate: noEndDate,
                        customMeasuresOfTime: customFrequencyType,
                        customEvery: String(
                            customFrequencyNumber
                        ),
                        daysOfWeek: [day],
                        description: description,
                        lastCreated: Date(),
                        serviceLocationId: RSS.locationId!
                    ),
                    customFrequencyType: customFrequencyType,
                    CustomFrequency: String(
                        customFrequencyNumber
                    ),
                    daysOfWeek: [day]
                )
                if rssId == nil {
                    print("Rss Id failure")
                    return
                    
                }

                let order = count
                count = count + 1
                let page = recurringRouteOrder(id: UUID().uuidString, order: order, recurringServiceStopId: rssId!,customerId: RSS.customerId,customerName: RSS.customerName, locationId: RSS.locationId!)
                binder.append(page)
            }
            let recurringRouteId = day + tech.userId
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.userId, day: day, order: binder, description: "")
            try await RecurringRouteManager.shared.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)


        }
    }
    
    func modifyRecurringRouteWithVerification(companyId: String,
                                       tech:CompanyUser,
                                       noEndDate:Bool,
                                       day:String,
                                       standardFrequencyType:String,
                                       customFrequencyType:String,
                                       customFrequencyNumber:Int,
                                       transitionDate:Date,
                                       newEndDate:Date,
                                        description:String,
                                        jobTemplate:JobTemplate,
                                        recurringStopList:[RecurringServiceStop],
                                        currentRecurringRoute:RecurringRoute) async throws {
        //DEVELOPER I COULD TRY AND UPDATE RATHER THAN DELETE AND CREATE NEW
        //Maybe I needed to use a different recurring route id because I cant have more than one exisiting at the same time
        print("End Recurring Route")
        try await RecurringRouteManager.shared.endRecurringRoute(companyId: companyId, recurringRouteId: currentRecurringRoute.id, endDate: transitionDate)
        print("Make Sure to End All Recurring Service Stops After End Date")
        //End Each Recurring Service Stop
        for recurringStopOrder in currentRecurringRoute.order {
            let RSS = try await RecurringServiceStopManager.shared.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId)
            try await RecurringServiceStopManager.shared.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, endDate: transitionDate)
            //Get Each Service Stop that has this Recurring Service Stop Id after Transition Date.
            //DEVELOPER Make sure to add starting new Recurring route after new transition
            let serviceStopList = try await ServiceStopManager.shared.getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: companyId, recurringServiceStopId: recurringStopOrder.recurringServiceStopId, date: transitionDate)
            
            // Delete Each Service Stop under Recurring Service Stop
            for stop in serviceStopList {
                try await ServiceStopManager.shared.deleteServiceStop(companyId: companyId, serviceStopId: stop.id)
            }
            try await RecurringServiceStopManager.shared.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
        }
        //Create New Recurring Route
        try await createAndUploadRecurringRoute(companyId: companyId, tech: tech, recurringStopsList: recurringStopList, job: jobTemplate, noEndDate: noEndDate, description: description, day: day, standardFrequencyType: standardFrequencyType, customFrequencyType: customFrequencyType, customFrequencyNumber: customFrequencyNumber, startDate: transitionDate, endDate: newEndDate, currentRecurringRoute: nil)
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
    func createAndUploadRecurringRoute(companyId: String,
                                       tech:CompanyUser,
                                       recurringStopsList:[RecurringServiceStop],
                                       job:JobTemplate,
                                       noEndDate:Bool,
                                       description:String,
                                       day:String,
                                       standardFrequencyType:String,
                                       customFrequencyType:String,
                                       customFrequencyNumber:Int,
                                       startDate:Date,
                                       endDate:Date,
                                       currentRecurringRoute:RecurringRoute?) async throws {
        if let recurringRoute = currentRecurringRoute {
            //Update the Curring Recurring route
            print("Current Equals Reucurring")
            ///Check if each reecurring service stop is in the recurring route.
            ///Check if Frequency has changed.
            ///Check if Duration has Changed.
            ///Make updates
        } else {
            //Create a new recurring Route
            let techFullName = (tech.userName)
            
            print("Making Route with \(recurringStopsList.count) stops for \(techFullName) - \(day)")
            var binder:[recurringRouteOrder] = []
            var count:Int = 1
            for RSS in recurringStopsList {
                print("Creating RSS for \(RSS.customerName) - \(RSS.id) - \(RSS.frequency)")
                let locationId = RSS.locationId
                let rssId = try await RecurringRouteManager.shared.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        type: job.name,
                        typeId: job.id,
                        typeImage: job.typeImage ?? "bubbles.and.sparkles.fill",
                        customerName: RSS.customerName,
                        customerId: RSS.customerId,
                        frequency: standardFrequencyType,
                        address: RSS.address,
                        dateCreated: Date(),
                        tech: techFullName,
                        endDate:endDate,
                        startDate:startDate,
                        techId:tech.userId,
                        noEndDate: noEndDate,
                        customMeasuresOfTime: customFrequencyType,
                        customEvery: String(
                            customFrequencyNumber
                        ),
                        daysOfWeek: [day],
                        description: description,
                        lastCreated: Date(),
                        serviceLocationId: RSS.serviceLocationId
                    ),
                    customFrequencyType: customFrequencyType,
                    CustomFrequency: String(
                        customFrequencyNumber
                    ),
                    daysOfWeek: [day]
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
            let recurringRouteId = day + tech.userId
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.userId, day: day, order: binder, description: "")
            try await RecurringRouteManager.shared.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)

     
        }
    }
}
