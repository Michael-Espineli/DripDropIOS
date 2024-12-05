//
//  ServiceStopTask+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/4/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    
    func serviceStopTaskCollection(companyId:String,serviceStopId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/serviceStops/\(serviceStopId)/tasks")
   }
}
