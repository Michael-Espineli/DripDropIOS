//
//  RecurringWorkRecurringServicestopCardViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/21/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class RecurringWorkRecurringServicestopCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var recurringServiceStop:RecurringServiceStop? = nil
    func onLoad(recurringServiceStopId:String,laborContract:ReccuringLaborContract) async throws{
        //I dont Need a company Id, because I am using the Receiver Id of the Labor Contrat, because this view model is specific for getting the recurring Service Stop info from a view
        self.recurringServiceStop = try await dataService.getSingleRecurringServiceStop(
            companyId: laborContract.receiverId,
            recurringServiceStopId: recurringServiceStopId
        )
    }
}
