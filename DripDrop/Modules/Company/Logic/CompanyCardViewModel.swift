//
//  CompanyCardViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/19/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class CompanyCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var company:Company? = nil
    func onLoad(companyId:String) async throws {
        self.company = try await dataService.getCompany(companyId: companyId)
    }
}

@MainActor
final class RecurringServiceStopCompanyNameCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var recurringServiceStop:RecurringServiceStop? = nil
    func onLoad(companyId:String,recurringServiceStopId:String) async throws {
        self.recurringServiceStop = try await dataService.getSingleRecurringServiceStop(companyId: companyId, recurringServiceStopId: recurringServiceStopId)
    }
}
