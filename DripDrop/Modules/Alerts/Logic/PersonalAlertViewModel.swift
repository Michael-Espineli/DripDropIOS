//
//  PersonalAlertViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/29/24.
//

import Foundation
@MainActor
final class PersonalAlertViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var alerts : [DripDropAlert] = []
    func onLoad(_ userId:String) async throws {
        self.alerts = try await dataService.getPersonalAlerts(userId: userId)
    }
}
