//
//  RecurringRouteViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/11/23.
//



import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class RecurringRouteViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var recurringRoute: RecurringRoute? = nil
    
    @Published private(set) var listOfRecurringRoutes:[RecurringRoute] = []
    
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadRoute(companyId: String,recurringRoute:RecurringRoute) async throws {
        try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
    }
    
    func createAndUploadRecurringRouteWithOutAddingNewServiceStops(
        companyId: String,
        tech:CompanyUser,
        recurringStopsList:[RecurringServiceStop],
        job:JobTemplate,
        noEndDate:Bool,
        description:String,
        day:String,
        standardFrequencyType:LaborContractFrequency,
        timesPerFrequency:Int,
        startDate:Date,
        endDate:Date,
        currentRecurringRoute:RecurringRoute?,
        serviceStopsListDic:[RecurringServiceStop:[ServiceStop]]
    ) async throws {
        var workingStopDick = serviceStopsListDic
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
            var accountedFor:Bool = false
            for RSS in recurringStopsList {
                accountedFor = false
                print("Creating RSS for \(RSS.customerName) - \(RSS.id) - \(RSS.frequency)")
                let locationId = RSS.serviceLocationId
                var rssId1: String? = nil
                //see if any match
                for stopDick in workingStopDick {
                    if !accountedFor {
                        if RSS.customerId == stopDick.key.customerId || RSS.serviceLocationId == stopDick.key.serviceLocationId {
                            rssId1 = try await dataService.modifyRecurringServiceStopToNew(
                                    companyId: companyId,
                                    recurringServiceStop: RecurringServiceStop(
                                        id: UUID().uuidString,
                                        internalId: RSS.internalId,
                                        type: job.name,
                                        typeId: job.id,
                                        typeImage: job.typeImage ?? "bubbles.and.sparkles.fill",
                                        customerName: RSS.customerName,
                                        customerId: RSS.customerId,
                                        address: RSS.address,
                                        tech: techFullName,
                                        techId:tech.id,
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
                                        laborContractId: nil,
                                        contractedCompanyId: nil
                                    ),
                                    customFrequencyType: "",
                                    CustomFrequency: String(
                                        timesPerFrequency
                                    ),
                                    daysOfWeek: [day],
                                    oldRss:stopDick.key,
                                    old:stopDick.value
                                )
                            accountedFor = true
                            workingStopDick[stopDick.key] = nil
                        }
                    }
                }
                //if none Match Create New One
                if !accountedFor {
                    rssId1 = try await dataService.addNewRecurringServiceStop(
                        companyId: companyId,
                        recurringServiceStop: RecurringServiceStop(
                            id: UUID().uuidString,
                            internalId: RSS.internalId,
                            type: job.name,
                            typeId: job.id,
                            typeImage: job.typeImage ?? "bubbles.and.sparkles.fill",
                            customerName: RSS.customerName,
                            customerId: RSS.customerId,
                            address: RSS.address,
                            tech: techFullName,
                            techId:tech.id,
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
                
                } else {
                    rssId1 = RSS.id
                }
                guard let rssId = rssId1 else {
                    print("Rss Id failure")
                    throw FireBaseRead.unableToRead
                }

                let order = count
                count = count + 1
                let page = recurringRouteOrder(id: UUID().uuidString, order: order, recurringServiceStopId: rssId,customerId: RSS.customerId,customerName: RSS.customerName, locationId: RSS.serviceLocationId)
                binder.append(page)
            }
            let recurringRouteId = day + tech.id
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.id, day: day, order: binder, description: "")
            try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)

            //Check RSS: Service Stop Dict to see any removed one and delete them
            for RSS in workingStopDick {
                for ss in RSS.value {
                    try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: ss.id)
                }
            }
        }
    }
    
    func createAndUploadRecurringRoute(companyId: String,
                                       tech:CompanyUser,
                                       recurringStopsList:[RecurringServiceStop],
                                       job:JobTemplate,
                                       noEndDate:Bool,
                                       description:String,
                                       day:String,
                                       standardFrequencyType:LaborContractFrequency,
                                       timesPerFrequency:Int,
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
                let locationId = RSS.serviceLocationId
                let rssId = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        internalId: RSS.internalId,
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
            let recurringRouteId = day + tech.id
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.id, day: day, order: binder, description: "")
            try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)
        }
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
        timesPerFrequency:Int,
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
                print(" - Creating Recurring Service Stop Id >>  \(RSS.id) - \(RSS.customerName) - \(RSS.frequency)")
                let locationId = RSS.serviceLocationId
                let rssId = try await dataService.addNewRecurringServiceStop(
                    companyId: companyId,
                    recurringServiceStop: RecurringServiceStop(
                        id: UUID().uuidString,
                        internalId: RSS.internalId,
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
            let recurringRouteId = day + tech.id
            print("Uploading Recurring Route Id >> \(recurringRouteId)")
            let recurringRoute:RecurringRoute = RecurringRoute(id: recurringRouteId, tech: techFullName, techId: tech.userId, day: day, order: binder, description: "")
            try await dataService.uploadRoute(companyId: companyId, recurringRoute: recurringRoute)


        }
    }
    
    func modifyRecurringRouteWithVerification(companyId: String,
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
                try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stop.id)
            }
            try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
        }
        //Create New Recurring Route
        try await createAndUploadRecurringRoute(
            companyId: companyId,
            tech: tech,
            recurringStopsList: recurringStopList,
            job: jobTemplate,
            noEndDate: noEndDate,
            description: description,
            day: day,
            standardFrequencyType: standardFrequencyType,
            timesPerFrequency: timesPerFrequency,
            startDate: transitionDate,
            endDate: newEndDate,
            currentRecurringRoute: nil
        )
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
//                    try await ServiceStopManager.shared.deleteServiceStop(companyId: companyId, serviceStop: stop)
//                }
                recurringRouteServiceStopDic[RSS] = serviceStopList
                try await dataService.endRecurringServiceStop(companyId: companyId, recurringServiceStopId: RSS.id, endDate: transitionDate)
            }
            //Create New Recurring Route
            //DEVELOPER MAYBE CHANGE LATER
            try await createAndUploadRecurringRouteWithOutAddingNewServiceStops(
                companyId: companyId,
                tech: tech,
                recurringStopsList: oldRecurringStopList,
                job: jobTemplate,
                noEndDate: noEndDate,
                description: description,
                day: day,
                standardFrequencyType: standardFrequencyType,
                timesPerFrequency: timesPerFrequency,
                startDate: transitionDate,
                endDate: newEndDate,
                currentRecurringRoute: nil,
                serviceStopsListDic: recurringRouteServiceStopDic
            )
        }
     
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllActiveRoutes(companyId: String,param:String) async throws{
        
        self.listOfRecurringRoutes = try await dataService.getAllActiveRoutes(companyId: companyId, param: param)
    }
    
    func getSingleRoute(companyId:String,recurringRouteId:String) async throws{
        print("* getSingleRoute in RecurringRouteViewModel *")
        self.recurringRoute = try await dataService.getSingleRoute(companyId: companyId, recurringRouteId: recurringRouteId)
    }
    func getRecurringRouteByDayAndTech(companyId:String,day:String,techId:String) async throws {
        let recurringServiceStops = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: day, techId: techId)
        if recurringServiceStops.count != 0 {
            self.recurringRoute = recurringServiceStops.first
        }
    }
    func getRecurringRouteByDay(companyId:String,day:String) async throws {
        let recurringRoutes = try await dataService.getRecurringRouteByDay(companyId: companyId, day: day)
        if recurringRoutes.count != 0 {
            self.recurringRoute = recurringRoutes.first
        }
        self.listOfRecurringRoutes = recurringRoutes
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
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
     

}
