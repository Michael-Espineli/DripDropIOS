//
//  RecurringLaborContractInvoiceCardViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/1/25.
//

import Foundation

@MainActor
final class RecurringLaborContractInvoiceCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var recurringWork: [LaborContractRecurringWork] = []
    @Published private(set) var total: Int = 0
    @Published private(set) var weeklyTotal: Int = 0
    @Published private(set) var weeksBetween: Int = 0

    @Published private(set) var lastBilled: Date = Date()
    func onLoad(companyId:String, contractId:String) async throws {
        var total: Int = 0
        var recurringWork = try await dataService.getLaborContractRecurringWorkList(companyId: companyId, laborContractId: contractId)
        print("recurringWork \(recurringWork.count) for \(companyId) -  \(contractId)")
        for work in recurringWork {
            //Get Service Stops Since Last Billed
            if work.isActive {
                //Developer Maybe a better Way to do this
                self.lastBilled = work.lastBilled
                for rssIds in work.recurringServiceStopIdList {
                    let serviceStops = try await dataService.getServiceStopsByRecurringsServiceStopBetweenDates(
                        companyId: companyId,
                        recurringsServicestopId: rssIds.id,
                        startDate: work.lastBilled,
                        endDate: Date()
                    )
                    print("received serviceStops for \(rssIds.id) - \(serviceStops.count)")
                    for stop in serviceStops {
                        if !stop.isInvoiced {
                            // if stop.operationStatus == .finished {}//DEVELOPER MAYBE ADD COMPANY SETTING REQUIRE FINISH
                            total += Int(work.rate)
                            //Update Service Stop once Sent
                        }
                    }
                }
                //Update work once sent to billed as Date()
            } else {
                print("Work is Inactive")
            }
        }
        //This is Estimate
        let weeksBetween = numberOfWeeksBetween(lastBilled, Date())
        self.total = total
    }
}
