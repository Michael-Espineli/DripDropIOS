//
//  AllCompanyRegularRouteViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/17/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
struct BasicTechnicanInfo:Identifiable, Codable,Hashable{
    var id :String
    var techName: String
    var roleName: String
    var companyId:String
    var companyName:String
}
@MainActor
final class AllCompanyRegularRoutesViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //LOADING
    @Published var isLoading:Bool = true
    
    @Published private(set) var techList : [DBUser] = []
    @Published private(set) var companyUsers : [CompanyUser] = []

    
    @Published private(set) var recurringRoute : RecurringRoute? = nil
    @Published private(set) var recurringServiceStops : [RecurringServiceStop] = []
    
    //New Variables
    @Published private(set) var basicTechnicanInfo : [BasicTechnicanInfo] = []
    @Published private(set) var companyList : [Company] = []

    @Published private(set) var rss : [String] = []
    @Published private(set) var technicianStopsOrderedByDay : [String:[String:[RecurringServiceStop]]] = [:]
    @Published var daysOfWeekList : [String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    func loadTechs(companyId:String) async throws{
        
        self.techList = try await dataService.getAllCompayTechs(companyId: companyId)
    }
    func reload() {
        self.isLoading = true
        self.isLoading = false
    }
    func firstLoad(companyId:String) async throws{
        self.isLoading = true
        print("First Load Start - [AllCompanyRegularRoutesViewModel]")
        
        //Get all Recurring Service Stops
        var allActiveRecurringServiceStops = try await dataService.getAllRecurringServiceStop(companyId: companyId)
        print(1)
        //Until I figure out if each company should have a copy of the RSS

        let laborContracts = try await dataService.getSentLaborContractsByStatus(companyId: companyId, status: .accepted)
        print(2)

        for contract in laborContracts {
            print("")
            print("contract")
            print(contract)
            //Get all Recurring Work From Labor Contracts
            let recurringWorkList = try await dataService.getLaborContractRecurringWorkList(companyId: companyId, laborContractId: contract.id)
            print("")
            print("recurringWorkList")
            print(recurringWorkList)

            for work in recurringWorkList {
                print("")
                print("work")
                print(work)
                for RSSID in work.recurringServiceStopIdList {
                    print("")
                    print("RSSID")
                    print(RSSID)
                    let recurringServiceStop = try await dataService.getSingleRecurringServiceStop(companyId: contract.receiverId, recurringServiceStopId: RSSID.id)
                    print("Received Recurring Service STop")
                    let newRecurringServiceStop = RecurringServiceStop(
                        id: recurringServiceStop.id,
                        internalId: recurringServiceStop.internalId,
                        type: recurringServiceStop.type,
                        typeId: recurringServiceStop.typeId,
                        typeImage: recurringServiceStop.typeImage,
                        customerName: recurringServiceStop.customerName,
                        customerId: recurringServiceStop.customerId,
                        address: recurringServiceStop.address,
                        tech: recurringServiceStop.tech,
                        techId: recurringServiceStop.techId,
                        dateCreated: recurringServiceStop.dateCreated,
                        startDate: recurringServiceStop.startDate,
                        endDate: recurringServiceStop.endDate,
                        noEndDate: recurringServiceStop.noEndDate,
                        frequency: recurringServiceStop.frequency,
                        daysOfWeek: recurringServiceStop.daysOfWeek,
                        description: recurringServiceStop.description,
                        lastCreated: recurringServiceStop.lastCreated,
                        serviceLocationId: recurringServiceStop.serviceLocationId,
                        estimatedTime: recurringServiceStop.estimatedTime,
                        otherCompany: recurringServiceStop.otherCompany,
                        laborContractId: recurringServiceStop.laborContractId,
                        contractedCompanyId: contract.receiverId,
                        mainCompanyId: companyId
                    )
                    
                    allActiveRecurringServiceStops.append(newRecurringServiceStop)
                }
            }
        }
        print("allActiveRecurringServiceStops")
        print(allActiveRecurringServiceStops)
        
        //Sort into day
        //Build in for each and get a day // [Day : TechnicianId : [List of all Recurring Service Stops]]
        var technicianStopsOrderedByDay : [String:[String:[RecurringServiceStop]]] = [:]
        var basicTechnicanInfo : [BasicTechnicanInfo] = []
        var companyList : [Company] = []

        for dayOfWeek in daysOfWeekList {

            var sundayRecurringServiceStopList = allActiveRecurringServiceStops.filter({$0.daysOfWeek == dayOfWeek})
            var techIdList : [String] = []
            var techDictionary : [String:[RecurringServiceStop]] = [:]
            for recurringServiceStop in sundayRecurringServiceStopList {
                
                //Check if techIdList Contains TechId
                if techIdList.contains(where: {$0 == recurringServiceStop.techId}) {
                    
                    //techIdList Does NotContains techId
                    var newRecurringServiceStopList:[RecurringServiceStop] = techDictionary[recurringServiceStop.techId] ?? []
                    newRecurringServiceStopList.append(recurringServiceStop)
                    techDictionary[recurringServiceStop.techId] = newRecurringServiceStopList

                } else {
                    
                    //techIdList Contains techId
                    techIdList.append(recurringServiceStop.techId)
                    techDictionary[recurringServiceStop.techId] = [recurringServiceStop]

                    //Handles building List of all technicans on rss Calls
                    if !basicTechnicanInfo.contains(where: {$0.id == recurringServiceStop.techId}) {
                        
                        //Basic info not recorded in basicTechnicianInfo
                        //Adding Basic Info into basicTechnicanInfo
                        basicTechnicanInfo.append(BasicTechnicanInfo(
                            id: recurringServiceStop.techId,
                            techName: recurringServiceStop.tech,
                            roleName: "ROLE?3",
                            companyId: "companyId",
                            companyName: "companyName"
                        ))
                    }
                }
                //Get contracted company info
                if let contractedCompanyId = recurringServiceStop.contractedCompanyId {
                    if contractedCompanyId != "" {
                        if !companyList.contains(where: {$0.id == contractedCompanyId}) {
                            print("Added New Company")
                            let company = try await dataService.getCompany(companyId: contractedCompanyId)
                            companyList.append(company)
                        }
                    }
                }
                if let mainCompanyId = recurringServiceStop.mainCompanyId {
                    if mainCompanyId != "" {
                        if !companyList.contains(where: {$0.id == mainCompanyId}) {
                            print("Added New Company")
                            let company = try await dataService.getCompany(companyId: mainCompanyId)
                            companyList.append(company)
                        }
                    }
                }
                //Recurring Route Information AKA Recurring Service Stop Order
            }
            
            technicianStopsOrderedByDay[dayOfWeek] = techDictionary
        }
        self.technicianStopsOrderedByDay = technicianStopsOrderedByDay
        self.basicTechnicanInfo = basicTechnicanInfo
        self.companyList = companyList
        print("technicianStopsOrderedByDay")
        print(technicianStopsOrderedByDay)
        print("basicTechnicanInfo")
        print(basicTechnicanInfo)
        print("companyList")
        print(companyList)
        print("First Load End - [AllCompanyRegularRoutesViewModel]")

        self.isLoading = false
    }
    func deleteRecurringRoute(
        companyId:String,
        recurringRoute:RecurringRoute
    ) async throws {
        
        for order in recurringRoute.order {
            let RssId = order.recurringServiceStopId
            print(RssId)
            

            //Getting Service Stops
            let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopsAfterToday(companyId: companyId, recurringServiceStopId: RssId)
            
            //Delete Service Stops
            for stop in serviceStopList {
                
                try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
            }
            //Delete Recurring Service Stops
            try await dataService.deleteRecurringServiceStop(companyId: companyId, recurringServiceStopId: RssId)
        }
        print("Delete Recurring Route \(recurringRoute.id)")
        try await dataService.deleteRecurringRoute(companyId: companyId, recurringRouteId: recurringRoute.id)
        //Delete Reuccing Route
    }
    func getRouteForRecurringStopDay(companyId:String,day:String,techId:String,techName:String) async throws {
//        print("     Attempting to Get Recurring Route For Day \(day) and \(techId)")
        let recurringRoutes = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: day, techId: techId)
        
        if recurringRoutes.count != 0 {
            print("       Received \(recurringRoutes.first!.tech) \(recurringRoutes.first!.day)")
            print("       Count Is not Zero")
            self.recurringRoute = recurringRoutes.first!
        }
        
        //Check If there are any Reccuring Service Stops For this Day and Technician
        let recurringServiceStopList = try await dataService.getRecurringServiceStopsByDayAndTech(companyId: companyId, techId: techId, day: day)
        self.recurringServiceStops = recurringServiceStopList
        if let recurringRoute = self.recurringRoute {
            
            if recurringServiceStopList.count == recurringRoute.order.count {
                //The Recurring Route Exists and the amount of Recurring Service stops equals the amount of Recurring Route Order
                self.recurringServiceStops = recurringServiceStopList
                
            } else {
                
                // Adds Recurring Service Stops to The Route, that arent already attached.
                for recurringServiceStop in recurringServiceStopList {
                    //Checks to see which of the recurring Service Stops are not already accounted for in the Recurring Route Order
                    if !recurringRoute.order.contains(where: {$0.recurringServiceStopId == recurringServiceStop.id}){
                        let newRecurringRouteOrder:recurringRouteOrder = recurringRouteOrder(
                            id: UUID().uuidString,
                            order: recurringRoute.order.count + 1,
                            recurringServiceStopId: recurringServiceStop.id,
                            customerId: recurringServiceStop.customerId,
                            customerName: recurringServiceStop.customerName,
                            locationId: recurringServiceStop.serviceLocationId
                        )
                        self.recurringRoute?.order.append(newRecurringRouteOrder)
                        //Developer Add This To the Recurring Route Order
                    }
                }
            }
        } else {
            //There is not Recurring Route on this day.
            
            //Check if there is any Recurring Service Stops
            if recurringServiceStopList.count != 0 {
                var recurringRouteOrderList:[recurringRouteOrder] = []
                for recurringServiceStop in recurringServiceStopList {
                    let newRecurringRouteOrder:recurringRouteOrder = recurringRouteOrder(
                        id: UUID().uuidString,
                        order: recurringRouteOrderList.count + 1,
                        recurringServiceStopId: recurringServiceStop.id,
                        customerId: recurringServiceStop.customerId,
                        customerName: recurringServiceStop.customerName,
                        locationId: recurringServiceStop.serviceLocationId
                    )
                    recurringRouteOrderList.append(newRecurringRouteOrder)
                }
                self.recurringRoute = RecurringRoute(
                    id: UUID().uuidString,
                    tech: techName,
                    techId: techId,
                    day: day,
                    order: recurringRouteOrderList,
                    description: ""
                )
                //DEVELOPER ADD THIS TO BACK END
            }
        }
    }
}
