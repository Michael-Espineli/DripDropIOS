//
//  ServiceStop+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/2/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    func updateHomeOwnerServiceStopFinish(companyId: String, serviceStop: ServiceStop, finished: Bool) async throws {
        
    }
    
    func getServiceStopByJobId(companyId: String, jobId: String) async throws -> [ServiceStop] {
        //DEVELOPER
        return []
    }
    
    func updateServicestopOperationStatus(companyId: String, serviceStop: ServiceStop, operationStatus: ServiceStopOperationStatus) async throws {
            //DEVELOPER
        
    }
    
    func updateServicestopBillingStatus(companyId: String, serviceStop: ServiceStop, billingStatus: ServiceStopBillingStatus) async throws {
            //DEVELOPER
        
    }
}
