//
//  ExternalRouteListViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/29/24.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

struct ExternalRouteStop:Identifiable, Codable, Hashable{
    var id:String = UUID().uuidString
    var companyId:String
    var companyName:String
    var customerId:String
    var customerName:String
    var recurringServicestopId:String
    var day:String
    var techId:String
    var techName:String
}
@MainActor
final class ExternalRouteListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var recurringWork:[LaborContractRecurringWork] = []
    @Published private(set) var laborContractList:[ReccuringLaborContract] = []
    @Published private(set) var externalRouteDisplayList:[ExternalRouteStop] = []
    @Published private(set) var externalRouteDisplayDayList:[String:[ExternalRouteStop]] = [:]
    @Published private(set) var days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    func onLoad(companyId:String)async throws {
        
        //Get All Open Labor Contracts for Company
        let laborContracts = try await dataService.getSentLaborContractsByStatus(companyId: companyId, status: .accepted)
        
        for contract in laborContracts {
            
            //Get all Recurring Work From Labor Contracts
            let recurringWorkList = try await dataService.getLaborContractRecurringWorkList(companyId: companyId, laborContractId: contract.id)
            for work in recurringWorkList {
                for RSSID in work.recurringServiceStopIdList {
                    let recurringServiceStop = try await dataService.getSingleRecurringServiceStop(companyId: contract.receiverId, recurringServiceStopId: RSSID.id)
                    self.externalRouteDisplayList.append(
                        ExternalRouteStop(
                            companyId: contract.receiverId,
                            companyName: contract.receiverName,
                            customerId: work.customerId,
                            customerName: work.customerName,
                            recurringServicestopId: RSSID.id,
                            day: recurringServiceStop.daysOfWeek,
                            techId: recurringServiceStop.techId,
                            techName: recurringServiceStop.tech
                        )
                    )
                }
            }
        }
        for day in self.days {
            let list = self.externalRouteDisplayList.filter({$0.day == day})
            self.externalRouteDisplayDayList[day] = list
        }
    }
}
