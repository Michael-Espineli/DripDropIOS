//
//  AssocatedBusiness+DS+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/30/25.
//

import Foundation
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
    //Refrences
    func businessesCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/business")
    }
    //Create
    //Read
    //Update
    //Delete
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws {
        try await businessesDocument(companyId: companyId, businessId: businessId)
            .delete()
    }
}
