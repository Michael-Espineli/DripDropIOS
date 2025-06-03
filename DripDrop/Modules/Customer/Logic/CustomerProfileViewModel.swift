//
//  CustomerProfileViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class CustomerProfileViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var recurringServiceStops:[RecurringServiceStop] = []
    @Published var repairRequest:[RepairRequest] = []
    @Published var jobs:[Job] = []
    @Published var shoppingListItems:[ShoppingListItem] = []

    func onLoad(companyId:String,customerId:String) async throws {
        
        //Get Recurring Service Stops
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStopByCustomerId(companyId: companyId, customerId: customerId)
        
        //Get Repair Requests
        self.repairRequest = try await dataService.getRepairRequestsByCustomer(companyId: companyId, customerId: customerId)
        
        //Get Jobs
        self.jobs = try await dataService.getAllJobsByCustomer(companyId: companyId, customerId: customerId)
        
        //Get Recent Service Stops
        
        //Get Shopping List Items
        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(companyId: companyId ,customerId: customerId)
    }
    func deleteRecurringServiceStop(companyId:String,RecurringServiceStopId:String) async throws {
        print("")
            print("Delete")
            print(RecurringServiceStopId)
            //Getting Service Stops
            let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopsAfterToday(companyId: companyId, recurringServiceStopId: RecurringServiceStopId)
            
            //Delete Service Stops
            for stop in serviceStopList {
                
                try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
            }
            //Delete Recurring Service Stops
            try await dataService.deleteRecurringServiceStop(companyId: companyId, recurringServiceStopId: RecurringServiceStopId)
        print("SuccessFull")
            print("")
    }
    //Reloads
    func reloadShoppingListItem(companyId:String,customerId:String) async throws {
        //Get Shopping List Items
        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(companyId: companyId ,customerId: customerId)
    }
    func reloadJobs(companyId:String,customerId:String) async throws {
        //Get Jobs
        self.jobs = try await dataService.getAllJobsByCustomer(companyId: companyId, customerId: customerId)
    }
    func reloadRepairRequests(companyId:String,customerId:String) async throws {
        //Get Repair Requests
        self.repairRequest = try await dataService.getRepairRequestsByCustomer(companyId: companyId, customerId: customerId)
    }
    func reloadRecurringServiceStops(companyId:String,customerId:String) async throws {
        //Get Recurring Service Stops
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStopByCustomerId(companyId: companyId, customerId: customerId)
        
    }
}
