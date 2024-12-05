//
//  JobTasks+ProductionDataService+Extension.swift
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
    func workOrderTaskCollection(companyId:String,workOrderId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/workOrders/\(workOrderId)/tasks")
   }
    //CREATE
    //READ
    func getJobTasks(companyId:String,jobId:String) async throws -> [JobTask] {
        return try await workOrderTaskCollection(companyId: companyId, workOrderId: jobId)
            .getDocuments(as:JobTask.self)
    }
    //UPDATE
    //DELETE
}
