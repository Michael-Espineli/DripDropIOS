//
//  CompanyUser+DS+Extension.swift
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
    func companyUsersCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/companyUsers")
    }
    func companyUsersRateSheetCollection(companyId:String,companyUserId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/companyUsers/\(companyUserId)/rateSheet")
    }
    func TrainingCollection(companyId:String,techId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/users/\(techId)/trainings")
    }
}
