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
    @Published var serviceStops:[ServiceStop] = []

    //For Service Stop Detail View
    @Published var serviceLocation:ServiceLocation? = nil

    func onLoad(companyId:String,customerId:String) async throws {
        print("")
        print("[CustomerProfileViewModel][onLoad] customerId: \(customerId) companyId: \(companyId)")
        //Get Recurring Service Stops
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStopByCustomerId(companyId: companyId, customerId: customerId)
        print("")
        print("[CustomerProfileViewModel][onLoad] recurringServiceStops: \(recurringServiceStops.count)")
        
        //Get Repair Requests
        self.repairRequest = try await dataService.getRepairRequestsByCustomer(companyId: companyId, customerId: customerId)
        print("")
        print("[CustomerProfileViewModel][onLoad] repairRequest: \(repairRequest.count)")
        
        //Get Jobs
        self.jobs = try await dataService.getAllJobsByCustomer(companyId: companyId, customerId: customerId)
        print("")
        print("[CustomerProfileViewModel][onLoad] jobs: \(jobs.count)")
        
        //Get Recent Service Stops
        dataService.removeListenerForAllServiceStops()
            dataService.addListenerForFutureCustomerServiceStops(
                companyId: companyId,
                customerId: customerId,
            ) { [weak self] stops in
                self?.serviceStops = stops
            }
                //Get Shopping List Items
        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(companyId: companyId ,customerId: customerId)
        print("")
        print("[CustomerProfileViewModel][onLoad] shoppingListItems: \(shoppingListItems.count)")
    }
    func onLoadCustomerProfileView(companyId:String?, serviceStop: ServiceStop) {
        guard let companyId else {return}
        Task {
            do {
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceStop.serviceLocationId)
            } catch {
                print("  [CustomerProfileViewModel][onLoadCustomerProfileView]Error \(error)")
            }
        }
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
