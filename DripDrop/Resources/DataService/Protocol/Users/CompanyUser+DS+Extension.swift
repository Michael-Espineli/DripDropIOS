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
    func companyUserPerformanceReviewsCollection(companyId:String,companyUserId:String) -> CollectionReference{
        db.collection("companyUserPerformanceReviews")
            .document(companyId)
            .collection("companyUsers")
            .document(companyUserId)
            .collection("reviews")
    }
    func TrainingCollection(companyId:String,techId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/users/\(techId)/trainings")
    }

    func createNewPerformanceReview(companyId:String,companyUser:CompanyUser,performaceHistory:PerformaceHistory) async throws {
        let documentId = performaceHistory.id.isEmpty ? companyUserPerformanceReviewsCollection(companyId: companyId, companyUserId: companyUser.id).document().documentID : performaceHistory.id

        try await companyUserPerformanceReviewsCollection(companyId: companyId, companyUserId: companyUser.id)
            .document(documentId)
            .setData(performaceHistory.firestorePayload(companyId: companyId, companyUser: companyUser), merge: false)
    }

    func getPerformaceReivewByUserId(companyId:String,companyUserId:String) async throws -> [PerformaceHistory] {
        let snapshot = try await companyUserPerformanceReviewsCollection(companyId: companyId, companyUserId: companyUserId)
            .order(by: "date", descending: true)
            .getDocuments()

        return snapshot.documents.map { document in
            PerformaceHistory(id: document.documentID, data: document.data())
        }
    }
}
