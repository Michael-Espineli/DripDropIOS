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

    func loadTechs(companyId:String) async throws{
        
        self.techList = try await dataService.getAllCompayTechs(companyId: companyId)
    }
    func reload() {
        self.isLoading = true
        self.isLoading = false
    }
    func firstLoad(companyId:String) async throws{
        self.isLoading = true
        
        //Get all Recurring Service Stops
        let allActiveRecurringServiceStops = try await dataService.getAllRecurringServiceStop(companyId: companyId)
        
        //Sort into day
        //Sunday
        let sundayRecurringServiceStopList = allActiveRecurringServiceStops.filter({$0.daysOfWeek == "Saturday"})
        
        
        //Sort into Technicians
        
        
        
        
        
        
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
