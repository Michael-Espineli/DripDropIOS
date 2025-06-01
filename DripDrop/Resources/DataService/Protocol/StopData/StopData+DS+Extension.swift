//
//  StopData+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/12/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    func stopDataCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/stopData")
    }
}
