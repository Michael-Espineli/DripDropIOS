//
//  ServiceLocation+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/7/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    func serviceLocationCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/serviceLocations")
    }
    func serviceLocationDoc(companyId:String,serviceLocationId:String)-> DocumentReference{
        serviceLocationCollection(companyId: companyId).document(serviceLocationId)
    }
}
