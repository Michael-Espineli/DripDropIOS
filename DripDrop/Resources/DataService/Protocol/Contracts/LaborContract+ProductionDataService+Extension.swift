//
//  LaborContract+ProductionDataService+Extension.swift
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
        //Refrences
    func LaborContractCollection() -> CollectionReference{
        db.collection("laborContracts")
    }
    func LaborContractDocument(laborContractId:String)-> DocumentReference{
        LaborContractCollection().document(laborContractId)
    }
    //Create
    func uploadLaborContract(laborContractId:String,laborContract:LaborContract) async throws {
        try LaborContractDocument(laborContractId: laborContractId)
            .setData(from:laborContract, merge: false)
    }
    //Read
    func getLaborContract(laborContractId: String) async throws -> LaborContract {
        return try await LaborContractDocument(laborContractId: laborContractId)
            .getDocument(as: LaborContract.self)
    }
    
    func getLaborContractsBySenderId(senderId: String) async throws -> [LaborContract] {
        return try await LaborContractCollection()
            .whereField("senderId", isEqualTo: senderId)
            .getDocuments(as: LaborContract.self)
    }
    
    func getLaborContractsByReceiverId(receiverId: String) async throws -> [LaborContract] {
        return try await LaborContractCollection()
            .whereField("receiverId", isEqualTo: receiverId)
            .getDocuments(as: LaborContract.self)
    }
    
    func getLaborContractsBySenderReceiverIsInvoiced(senderId: String,receiverId: String,isInvoiced: Bool) async throws -> [LaborContract] {
        return try await LaborContractCollection()
            .whereField("receiverId", isEqualTo: receiverId)
            .whereField("senderId", isEqualTo: senderId)
            .whereField("isInvoiced", isEqualTo: isInvoiced)
            .getDocuments(as: LaborContract.self)
    }
    
    func getLaborContractsBySenderReceiverIsInvoicedStatus(senderId: String,receiverId: String,isInvoiced: Bool, status:LaborContractStatus) async throws -> [LaborContract] {
        return try await LaborContractCollection()
            .whereField("receiverId", isEqualTo: receiverId)
            .whereField("senderId", isEqualTo: senderId)
            .whereField("isInvoiced", isEqualTo: isInvoiced)
            .whereField("status", isEqualTo: status.rawValue)
            .getDocuments(as: LaborContract.self)
    }
    
    //Update
    func updateOneTimeLaborContractAsAcceptedByReceiver(contractId:String,accepted:Bool)  async throws {
        let ref = LaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "status":LaborContractStatus.accepted.rawValue,
                "receiverAcceptance": accepted
            ])
    }
    func updateOneTimeLaborContractAsAcceptedBySender(contractId:String,accepted:Bool)  async throws {
        let ref = LaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "status":LaborContractStatus.accepted.rawValue,
                "senderAcceptance": accepted
            ])
    }
    
    func updateLaborContractStatus(contractId:String,status:LaborContractStatus)  async throws {
        let ref = LaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "status":status.rawValue,
            ])
    }
    
    func updateLaborContractIsInvoiced(companyId:String, contractId:String, isInvoiced:Bool)  async throws {
        let ref = LaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "isInvoiced": isInvoiced
            ])
    }
    func updateLaborContractInvoiceRef(companyId:String, contractId:String, invoiceInfo:IdInfo)  async throws {
        let ref = LaborContractDocument(laborContractId: contractId)
        try await ref
            .updateData([
                "invoiceRef":[
                    "id": invoiceInfo.id,
                    "internalId": invoiceInfo.internalId
                ]
            ])
    }
    //Delete
    
    func deleteLaborContract( contractId:String) async throws {
        try await LaborContractDocument(laborContractId: contractId)
            .delete()
    }

}
struct IdInfo: Identifiable, Codable, Hashable {
    var id:String//var uniqueId:String
    var internalId:String
}


//tasks Sub collection of Labor Contracts

extension ProductionDataService {
        //Refrences
    func LaborContractTaskCollection(laborContractId:String) -> CollectionReference{
        db.collection("laborContracts/\(laborContractId)/tasks")
    }
    func LaborContractTaskDocument(laborContractId:String,taskId:String)-> DocumentReference{
        LaborContractTaskCollection(laborContractId: laborContractId).document(taskId)
    }
        //Create

    func uploadTaskToLaborContract(laborContractId:String,task:LaborContractTask) async throws {
        try LaborContractTaskDocument(laborContractId: laborContractId, taskId: task.id)
            .setData(from:task, merge: false)
    }
    //Read
    func getLaborContractTask(laborContractId: String, taskId: String) async throws -> LaborContractTask {
        return try await LaborContractTaskDocument(laborContractId: laborContractId, taskId: taskId)
            .getDocument(as: LaborContractTask.self)
    }
    
    func getLaborContractWork(companyId: String, laborContractId: String) async throws -> [LaborContractTask] {
        return try await LaborContractTaskCollection(laborContractId: laborContractId)
            .getDocuments(as: LaborContractTask.self)
    }
    func getLaborContractTasks(companyId:String,laborContractId:String) async throws -> [LaborContractTask] {
        return []
    }
    //Update
    func updateLaborContractTaskStatus(laborContractId:String, laborContractTaskId:String, status:JobTaskStatus) async throws {
        let ref = LaborContractTaskDocument(laborContractId: laborContractId, taskId: laborContractTaskId)
        try await ref
            .updateData([
                "status":status.rawValue,
            ])
    }
    func updateLaborContractTaskJobIsCreated(laborContractId:String, laborContractTaskId:String, jobIsCreated:Bool) async throws {
        let ref = LaborContractTaskDocument(laborContractId: laborContractId, taskId: laborContractTaskId)
        try await ref
            .updateData([
                "jobIsCreated":jobIsCreated
            ])
    }
    func updateLaborContractTaskReceiverJobId(laborContractId:String, laborContractTaskId:String, jobIdInfo:IdInfo) async throws {
        let ref = LaborContractTaskDocument(laborContractId: laborContractId, taskId: laborContractTaskId)
        try await  ref.updateData(
            ["receiverJobId":FieldValue.arrayUnion([[
                "id" : jobIdInfo.id,
                "internalId" : jobIdInfo.internalId
            ] as [String : Any]])
        ])
    }

}
