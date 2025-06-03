import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/michaelespineli/Desktop/DripDrop/DripDrop/Modules/Invoices/RecurringLaborContractInvoiceCardViewModel.swift", line: 1)
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
    
    func onLoad(companyId:String, contractId:String) async throws {
        self.recurringWork = [
            
            LaborContractRecurringWork(
                id: UUID().uuidString,
                customerId: UUID().uuidString,
                customerName: __designTimeString("#17717_0", fallback: "Customer Name 1"),
                serviceLocationId: UUID().uuidString,
                serviceLocationName: __designTimeString("#17717_1", fallback: "Location Name 1"),
                jobTemplateId: UUID().uuidString,
                jobTemplateName: __designTimeString("#17717_2", fallback: "Tempalte Name 1"),
                rate: __designTimeInteger("#17717_3", fallback: 1500),
                laborType: .job,
                frequency: .weekly,
                timesPerFrequency: __designTimeInteger("#17717_4", fallback: 1),
                timesPerFrequencySetUp: __designTimeInteger("#17717_5", fallback: 1),
                routeSetUp: __designTimeBoolean("#17717_6", fallback: true),
                recurringServiceStopIdList: []
            )
            ,
            LaborContractRecurringWork(
                id: UUID().uuidString,
                customerId: UUID().uuidString,
                customerName: __designTimeString("#17717_7", fallback: "Customer Name 2"),
                serviceLocationId: UUID().uuidString,
                serviceLocationName: __designTimeString("#17717_8", fallback: "Location Name 2"),
                jobTemplateId: UUID().uuidString,
                jobTemplateName: __designTimeString("#17717_9", fallback: "Tempalte Name 2"),
                rate: __designTimeInteger("#17717_10", fallback: 1500),
                laborType: .job,
                frequency: .weekly,
                timesPerFrequency: __designTimeInteger("#17717_11", fallback: 1),
                timesPerFrequencySetUp: __designTimeInteger("#17717_12", fallback: 1),
                routeSetUp: __designTimeBoolean("#17717_13", fallback: true),
                recurringServiceStopIdList: []
            )
            ,
            LaborContractRecurringWork(
                id: UUID().uuidString,
                customerId: UUID().uuidString,
                customerName: __designTimeString("#17717_14", fallback: "Customer Name 3"),
                serviceLocationId: UUID().uuidString,
                serviceLocationName: __designTimeString("#17717_15", fallback: "Location Name 3"),
                jobTemplateId: UUID().uuidString,
                jobTemplateName: __designTimeString("#17717_16", fallback: "Tempalte Name 3"),
                rate: __designTimeInteger("#17717_17", fallback: 1500),
                laborType: .job,
                frequency: .weekly,
                timesPerFrequency: __designTimeInteger("#17717_18", fallback: 1),
                timesPerFrequencySetUp: __designTimeInteger("#17717_19", fallback: 1),
                routeSetUp: __designTimeBoolean("#17717_20", fallback: true),
                recurringServiceStopIdList: []
            )
        ]
    }
}
