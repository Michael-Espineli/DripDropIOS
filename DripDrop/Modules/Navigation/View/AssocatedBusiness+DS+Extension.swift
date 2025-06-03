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

//Associated Business
extension ProductionDataService {
    //Refrences
    func businessesCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/business")
    }
    func businessesDocument(companyId:String,businessId:String)-> DocumentReference{
        businessesCollection(companyId: companyId).document(businessId)
    }

    //Create
    func saveAssociatedBusinessToCompany(companyId:String,business:AssociatedBusiness) async throws {
        try businessesDocument(companyId: companyId, businessId: business.id)
            .setData(from:business, merge: false)
    }
    //Read
    func getAssociatedBusinesses(companyId:String) async throws -> [AssociatedBusiness] {
        return try await businessesCollection(companyId: companyId)
            .getDocuments(as:AssociatedBusiness.self)
    }
    func getAssociatedBusiness(companyId:String,businessId:String) async throws -> AssociatedBusiness {
        return try await businessesDocument(companyId: companyId, businessId: businessId)
            .getDocument(as: AssociatedBusiness.self)
    }
    func getAssociatedBusinessByCompanyId(companyId:String,businessCompanyId:String) async throws -> AssociatedBusiness {
        let businessList = try await businessesCollection(companyId: companyId)
            .whereField("companyId", isEqualTo: businessCompanyId)
            .limit(to: 1)
            .getDocuments(as:AssociatedBusiness.self)
        if let first = businessList.first {
            return first
        }
        throw FireBaseRead.unableToRead
    }
    //Update
    //Delete
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws {
        try await businessesDocument(companyId: companyId, businessId: businessId)
            .delete()
    }
}
//Associated Business Sub Collections

//Payment History?
