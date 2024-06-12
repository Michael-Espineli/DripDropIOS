//
//  ContractManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/22/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin

struct Contract:Identifiable, Codable, Hashable{
    var id:String
    var customerName:String
    var customerId:String
    var dateSent:Date
    var dateToAccept:Date
    var status:String //Pending, Accepted, Past
    var dateAccepted:Date?
    var locations:Double
    var rate:Double
    var rateType:String //per Month, per Stop
    var laborType:String //per Stop, Weekly, Monthly
    var chemType:String //All inclusive, Without Chems, Includes specific Chems, Excludes Specific Chems
    var terms:String
    var notes:String
    var startDate:Date?
    var endDate: Date?
//    var fireDate : Date?
//    var fireCategory : String?
//    var fireReason : String?
    
}
protocol ContractManagerProtocol {

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadContact(companyId:String,contract:Contract) async throws
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllContrats(companyId:String) async throws -> [Contract]
    func getSpecificContract(companyId:String,contractId:String) async throws ->Contract
    func getContractsByCustomer(companyId: String,customerId:String) async throws ->[Contract]
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateContract(companyId:String,contract:Contract) async throws
    func updateContractStatus(companyId:String,contractId:String,status:String) async throws
    func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws
    func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteContract(companyId:String,contractId:String) async throws
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}

    final class MockContractManager:ContractManagerProtocol {

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
        
        let mockContracts:[Contract] = [
            /*
            Contract(id: "1", customerName: "Aphrodite", customerId: "1", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "2", customerName: "Athena", customerId: "2", dateSent: Date(), dateToAccept: Date(), accepted: false, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "3", customerName: "Artemis", customerId: "3", dateSent: Date(), dateToAccept: Date(), accepted: false, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "4", customerName: "Aries", customerId: "4", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "5", customerName: "Apollo", customerId: "5", dateSent: Date(), dateToAccept: Date(), accepted: false, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "6", customerName: "Demeter", customerId: "6", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "7", customerName: "Dionysus", customerId: "7", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "8", customerName: "Hades", customerId: "8", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "9", customerName: "Hera", customerId: "9", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "10", customerName: "Poseidon", customerId: "10", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
            
            Contract(id: "11", customerName: "Zeus", customerId: "11", dateSent: Date(), dateToAccept: Date(), accepted: true, dateAccepted: Date(), locations: 1, rate: 160, rateType: "Per Month", laborType: "Per Stop", chemType: "Including Chems", terms: "", notes: ""),
             */
        ]

    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadContact(companyId:String,contract:Contract) async throws {
        
      print("Successfully upLoaded Contract")
    }
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllContrats(companyId:String) async throws -> [Contract] {
        
        return mockContracts
    }
    func getSpecificContract(companyId:String,contractId:String) async throws ->Contract{
        
        guard let contract = mockContracts.first(where: {$0.id == contractId}) else {
            throw FireBaseRead.unableToRead
        }
        return contract
//            .getDocuments(as:Equipment.self)
    }
    func getContractsByCustomer(companyId: String,customerId:String) async throws ->[Contract]{
        return mockContracts

    }
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        var count: Int = 0
        for contract in mockContracts {
            if contract.customerId == customerId {
                count += count
            }
        }
        return count
    }

    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateContract(companyId:String,contract:Contract) async throws {
        print("Successfully Uploaded")
    }
        func updateContractStatus(companyId:String,contractId:String,status:String) async throws {
            
        }
        func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws {
            
        }
        func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws {
            
        }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteContract(companyId:String,contractId:String) async throws{
        print("Successfully Deleted")
    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}

final class ContractManager:ContractManagerProtocol {
    
    static let shared = ContractManager()
    init(){}
    private let db = Firestore.firestore()

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func contractCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/contracts")
    }


    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func contractDocument(companyId:String,contractId:String)-> DocumentReference{
        contractCollection(companyId: companyId).document(contractId)
    }
    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadContact(companyId:String,contract:Contract) async throws {
        
        try contractCollection(companyId: companyId).document(contract.id).setData(from:contract, merge: false)
    }
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllContrats(companyId:String) async throws -> [Contract] {
        
        return try await contractCollection(companyId: companyId)
            .getDocuments(as:Contract.self)
    }
    func getSpecificContract(companyId:String,contractId:String) async throws ->Contract{
        
        return try await contractDocument(companyId: companyId,contractId: contractId).getDocument(as: Contract.self)
//            .getDocuments(as:Equipment.self)
    }
    func getContractsByCustomer(companyId: String,customerId:String) async throws ->[Contract]{
        return try await contractCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:Contract.self)
    }
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        let count = try await contractCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId).count.getAggregation(source: .server).count
        
        return count as! Int
    }

    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateContract(companyId:String,contract:Contract) async throws {
        
        try contractCollection(companyId: companyId).document(contract.id).setData(from:contract, merge: true)
    }
        func updateContractStatus(companyId:String,contractId:String,status:String) async throws {
            let contractRef = contractDocument(companyId: companyId, contractId: contractId)

            
            contractRef.updateData([
                "status":status
            ]) { err in
                if let err = err {
                    print("Error updating Contract Status: \(err)")
                } else {
                    print("Document successfully updated Contract Status")
                }
            }
        }
        func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws {
            let contractRef = contractDocument(companyId: companyId, contractId: contractId)

            
            contractRef.updateData([
                "startDate":startDate
            ]) { err in
                if let err = err {
                    print("Error updating Contract Start Date: \(err)")
                } else {
                    print("Document successfully updated Contract Start Date")
                }
            }
        }
        func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws {
            let contractRef = contractDocument(companyId: companyId, contractId: contractId)

            
            contractRef.updateData([
                "endDate":endDate
            ]) { err in
                if let err = err {
                    print("Error updating Contract End Date: \(err)")
                } else {
                    print("Document successfully updated Contract End Date")
                }
            }
        }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteContract(companyId:String,contractId:String) async throws{
        try await contractDocument(companyId: companyId,contractId: contractId).delete()
    }
    //----------------------------------------------------
    //------------------  FUNCTIONS  ---------------------
    //----------------------------------------------------
    
}
