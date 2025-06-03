//
//  recurringServiceStopViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/24/23.
//

import Foundation
@MainActor
final class RecurringStopViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var recurringServiceStops: [RecurringServiceStop] = []
    @Published private(set) var recurringServiceStop: RecurringServiceStop? = nil
    @Published private(set) var selectedRecurringServiceStop: RecurringServiceStop? = nil

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getReucrringServiceStopById(companyId: String,recurringServiceStopId:String) async throws{
        self.recurringServiceStop = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
    }
    func getAllRecurringServiceStops(companyId: String) async throws{
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStop(companyId: companyId)
    }
    func getAllRecurringServiceStopsByDay(companyId:String,days:[String]) async throws{
        var recurringServiceStopsList:[RecurringServiceStop] = []
        for day in days {
            let stops = try await dataService.getRecurringServiceStopsByDays(companyId: companyId, day: day)
            for stop in stops {
                recurringServiceStopsList.append(stop)
            }
        }
        self.recurringServiceStops = recurringServiceStopsList
    }
    func getAllRecurringServiceStopsByDayAndTech(companyId:String,techId:String,days:[String]) async throws{
        var recurringServiceStopsList:[RecurringServiceStop] = []
        for day in days {
            let stops = try await dataService.getRecurringServiceStopsByDayAndTech(companyId: companyId,techId: techId, day: day)
            for stop in stops {
                recurringServiceStopsList.append(stop)
            }
        }
        self.recurringServiceStops = recurringServiceStopsList
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                           UPDATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    func deleteRecurringServiceStop(recurringServiceStopId : String,companyId: String) async throws {
        print("Delete Recurring Service Stop - DEV")
        //DEVELOPER CHECK
//        try await dataService.deleteRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
//        let serviceStopList = try await ServiceStopManager.shared.getAllServiceStopsSortedByRecurringServiceStops(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
//        for ss in serviceStopList {
//            try await ServiceStopManager.shared.deleteServiceStop(companyId: companyId, serviceStopId: ss.id)
//
//        }
    }
}
