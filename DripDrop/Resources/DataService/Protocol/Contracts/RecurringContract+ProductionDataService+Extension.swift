//
//  ProductionDataService+RecurringContractExtension.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/28/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit

extension ProductionDataService {
        func recurringContractCollection() -> CollectionReference{
           db.collection("recurringContract")
        }
        func recurringContractDocument(contractId:String)-> DocumentReference{
            recurringContractCollection().document(contractId)
        }
    
        //CREATE
        func uploadContact(companyId:String,contract:RecurringContract) async throws {
            
            try recurringContractCollection().document(contract.id).setData(from:contract, merge: false)
        }
    
        //READ
        func getAllContrats(companyId:String) async throws -> [RecurringContract] {
            
            return try await recurringContractCollection()
                .getDocuments(as:RecurringContract.self)
        }
        func getSpecificContract(companyId:String,contractId:String) async throws -> RecurringContract{
            
            return try await recurringContractDocument(contractId: contractId).getDocument(as: RecurringContract.self)
            //            .getDocuments(as:Equipment.self)
        }
        func getContractsByCustomer(companyId: String,customerId:String) async throws -> [RecurringContract]{
            return try await recurringContractCollection()
                .whereField(RecurringContract.CodingKeys.companyId.rawValue, isEqualTo: companyId)
                .whereField(RecurringContract.CodingKeys.internalCustomerId.rawValue, isEqualTo: customerId)
                .getDocuments(as:RecurringContract.self)
        }
    
        func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
            return try await recurringContractCollection()
                .whereField(RecurringContract.CodingKeys.internalCustomerId.rawValue, isEqualTo: customerId).count.getAggregation(source: .server).count as? Int
        }
        //UPDATE
        func updateContract(companyId:String,contract:RecurringContract) async throws {
            
            try recurringContractCollection().document(contract.id).setData(from:contract, merge: true)
        }
        func updateContractStatus(companyId:String,contractId:String,status:RecurringContractStatus) async throws {
            let contractRef = recurringContractDocument(contractId: contractId)
            
            
            try await contractRef.updateData([
                "status":status.rawValue
            ])
        }
        func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws {
            let contractRef = recurringContractDocument(contractId: contractId)
            
            
            try await contractRef.updateData([
                "startDate":startDate
            ])
        }
        func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws {
            let contractRef = recurringContractDocument(contractId: contractId)
            try await contractRef.updateData([
                "endDate":endDate
            ])
        }
    
        //DELETE
        func deleteContract(companyId:String,contractId:String) async throws{
            try await recurringContractDocument(contractId: contractId).delete()
        }
}
