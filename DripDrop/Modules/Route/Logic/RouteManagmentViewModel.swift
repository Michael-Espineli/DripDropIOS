//
//  RouteManagmentViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/24/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class RouteManagmentViewModel:ObservableObject{
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
        self.companyUsers = try await CompanyUserManager.shared.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
//        self.techList = try await dataService.getAllCompayTechs(companyId: companyId)
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
    func getRouteForRecurringStopDay(companyId:String,day:String,techId:String) async throws {
        print(" - - Attemping to Get Recurring Route For Day \(day) and \(techId) ID: \(day)\(techId)")
        let rss = try await dataService.getRecurringRouteByDayAndTech(companyId: companyId, day: day, techId: techId)
        if rss.count != 0 {
            print("Received \(rss.first!.tech) \(rss.first!.day)")
            print("Count Is not Zero")
            self.recurringRoute = rss.first!
        }
        
        var recurringServiceStopsList:[RecurringServiceStop] = []
            let stops = try await dataService.getRecurringServiceStopsByDayAndTech(companyId: companyId,techId: techId, day: day)
            for stop in stops {
                recurringServiceStopsList.append(stop)
            }
        self.recurringServiceStops = recurringServiceStopsList
    }
}
