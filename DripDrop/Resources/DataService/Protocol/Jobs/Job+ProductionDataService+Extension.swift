//
//  Job+ProductionDataService+Extension.swift
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
   
    func workOrderCollection(companyId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/workOrders")
   }
	
     func workOrderDocument(workOrderId:String,companyId:String)-> DocumentReference{
        workOrderCollection(companyId: companyId).document(workOrderId)
    }
    
    //CREATE
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws {
        try workOrderDocument(workOrderId: workOrder.id, companyId: companyId).setData(from:workOrder, merge: false)
    }
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        
        let itemRef = workOrderDocument(workOrderId: workOrder.id, companyId: companyId)
        try await itemRef.updateData([
            "purchasedItemsIds": FieldValue.arrayUnion(ids)
        ])
        
        //        let itemRef = workOrderDocument(workOrderId: workOrder.id, companyId: user.companyId)
        //
        //        var auxiliaryParts = wo.pvcParts
        //        print(auxiliaryParts)
        //        for id in ids {
        //            if wo.auxiliaryParts.contains(id) {
        //
        //            } else {
        //                auxiliaryParts.append(id)
        //            }
        //        }
        //        print(auxiliaryParts)
        //
        //        itemRef.updateData([
        //            "auxiliaryParts":auxiliaryParts
        //        ]) { err in
        //            if let err = err {
        //                print("Error updating document: \(err)")
        //            } else {
        //                print("Document successfully updated")
        //            }
        //        }
    }
    //READ
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job {
        
        return try await workOrderDocument(workOrderId: workOrderId, companyId: companyId)
            .getDocument(as: Job.self)
        
    }
    func getAllJobsOpenedCount(companyId: String) async throws -> Int {
        let status:[String] = [
            JobOperationStatus.estimatePending.rawValue,
            JobOperationStatus.unscheduled.rawValue,
            JobOperationStatus.scheduled.rawValue,
            JobOperationStatus.inProgress.rawValue
        ]
        return try await workOrderCollection(companyId: companyId)
            .whereField("operationStatus", in: status)
            .order(by: "dateCreated", descending: false)
            .count.getAggregation(source: .server).count as! Int
        
    }
    func getAllWorkOrdersSortedByPrice(companyId:String,descending: Bool) async throws -> [Job]{
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "rate", descending: descending)
            .getDocuments(as:Job.self)
        
    }
    func getAllWorkOrdersByDate(companyId:String,date: Date) async throws -> [Job]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrdersSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [Job]{
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "serviceDate", descending: descending)
            .limit(to:count)
            .getDocuments(as:Job.self)
        
    }
    func getAllWorkOrdersByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [Job]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:Job.self)
    }
    func getWorkOrdersBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[Job],lastDocument:DocumentSnapshot?) {
        
        if let lastDocument {
            return try await workOrderCollection(companyId: companyId)
            //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as: Job.self)
        }else {
            return try await workOrderCollection(companyId: companyId)
            //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .getDocumentsWithSnapshot(as: Job.self)
        }
    }
    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem{
        
        let dbItem = try await Firestore.firestore().collection("workOrders/\(workOrderId)/installationParts").document(workOrderItemId).getDocument(as: WODBItem.self)
        
        return try await getDataBaseItem(companyId: companyId, genericItemId: dbItem.genericItemId)
    }
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]{
        return try await workOrderCollection(companyId: companyId)
            .whereField("finished", isEqualTo: true)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrders(companyId: String) async throws -> [Job] {
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "dateCreated", descending: false)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrdersFinished(companyId: String,finished:Bool) async throws -> [Job] {
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "dateCreated", descending: true)
            .whereField("billingStatus", notIn: ["Invoiced","Paid"])
            .getDocuments(as:Job.self)
    }
    
    func getAllJobsByCustomer(companyId: String,customerId:String) async throws -> [Job] {
        return try await workOrderCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .order(by: "dateCreated", descending: false)
            .getDocuments(as:Job.self)
    }
    func getAllJobsByUser(companyId: String,userId:String) async throws -> [Job] {
        return try await workOrderCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: userId)
            .order(by: "dateCreated", descending: false)
            .getDocuments(as:Job.self)
    }
    func getRecentWorkOrders(companyId: String) async throws -> [Job] {
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("dateCreated", isGreaterThan: startDate)
            .whereField("dateCreated", isLessThan: endDate)
            .order(by: "dateCreated", descending: false)
            .getDocuments(as:Job.self)
    }
    
    func getRecentlyFinishedCount(companyId: String) async throws -> Int {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        return try await workOrderCollection(companyId: companyId)
            .whereField("operationStatus", isEqualTo: JobOperationStatus.finished.rawValue)
            .whereField("dateCreated", isGreaterThan: startDate)
            .whereField("dateCreated", isLessThan: endDate)
            .order(by: "dateCreated", descending: false)
            .count.getAggregation(source: .server).count as! Int
        
    }
    //UPDATE
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) async throws{
        try await workOrderCollection(companyId: companyId).document(workOrder.id).updateData([
            "installationParts": FieldValue.arrayUnion([[
                
                "id": installationPart.id,
                "name": installationPart.name,
                "quantity": installationPart.quantity,
                "cost": installationPart.cost,
                "genericItemId": installationPart.genericItemId,
                
            ] as [String : Any]])
            
        ])
    }
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) async throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        try await workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "pvcParts": [
                [
                    
                    "id": pvcPart.id,
                    "name": pvcPart.name,
                    "quantity": pvcPart.quantity,
                    "cost": pvcPart.cost,
                    "genericItemId": pvcPart.genericItemId,
                    
                ] as [String : Any]]
            
        ])
    }
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) async throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        try await workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "electricalParts": [
                [
                    
                    "id": electricalPart.id,
                    "name": electricalPart.name,
                    "quantity": electricalPart.quantity,
                    "cost": electricalPart.cost,
                    "genericItemId": electricalPart.genericItemId,
                    
                ] as [String : Any]]
            
        ])
        
    }
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) async throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        try await workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "chemicals": [
                [
                    "id": chemical.id,
                    "name": chemical.name,
                    "quantity": chemical.quantity,
                    "cost": chemical.cost,
                    "genericItemId": chemical.genericItemId,
                    
                ] as [String : Any]]
            
        ])
    }
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) async throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        try await workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "miscParts": [
                [
                    
                    "id": miscPart.id,
                    "name": miscPart.name,
                    "quantity": miscPart.quantity,
                    "cost": miscPart.cost,
                    "genericItemId": miscPart.genericItemId,
                    
                ] as [String : Any]]
            
        ])
    }
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) async throws{
        var serviceStops = workOrder.serviceStopIds
        serviceStops.append(serviceStopId)
        let ref = db.collection("workOrders").document(workOrder.id)
        
        try await ref.updateData([
            "serviceStopIds": serviceStops
        ])
        
    }
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) async throws{
        
        
        
        //        let history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
        //        var historyArray:[String] = []
        //        let pushHistoryArray:[String] = []
        //
        //
        //        let historyText = ""
        //        var dateAndTech = ""
        //        var valueChange = ""
        //check if there was a chnage in tech
        
        let ref = db.collection("companies/\(companyId)/serviceStops").document(workOrder.id)
        try await ref.updateData([
            "invoiced": billingStatus
        ])
        
    }
    //Fix later when I have more time
    
    
    func updateWorkOrder(originalJob:Job,newJob:Job) async throws{
        /*
         let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
         var user = try await UserManager.shared.getCurrentUser(userId: authDataResult.uid)
         
         var history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
         var historyArray:[String] = []
         var pushHistoryArray:[String] = []
         
         
         var historyText = ""
         var dateAndTech = ""
         var valueChange = ""
         var counter = 0
         //check if there was a chnage in tech
         if originalServiceStop.tech != newServiceStop.tech {
         counter = counter + 1
         dateAndTech = " ** " + (originalWorkOrder.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalWorkOrder.tech ?? "") + " --> " + (newServiceStop.tech ?? "") + " ** "
         historyArray.append(valueChange)
         
         let ref = db.collection("serviceStops").document(originalWorkOrder.id)
         ref.updateData([
         "tech": newServiceStop.tech
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         if originalWorkOrder.description != newServiceStop.description {
         
         counter = counter + 1
         print(counter)
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.description ?? "") + " --> " + (newServiceStop.description ?? "") + " ** "
         print(valueChange)
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "description": newServiceStop.description
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         
         if originalServiceStop.title != newServiceStop.title {
         
         counter = counter + 1
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.title ?? "") + " --> " + (newServiceStop.title ?? "") + " ** "
         print(valueChange)
         
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "title": newServiceStop.title
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         if originalServiceStop.finished != newServiceStop.finished {
         
         counter = counter + 1
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.finished!.description.capitalized ) + " --> " + (newServiceStop.finished!.description.capitalized ) + " ** "
         print(valueChange)
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "finished": newServiceStop.finished
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         history.changes = historyArray
         if counter > 0 {
         pushHistoryArray.append(dateAndTech + historyText)
         if historyArray != pushHistoryArray{
         try db.collection("serviceStops/" + originalServiceStop.id + "/history").document(history.id).setData(from:history, merge: false)
         }
         } else {
         print("no change made")
         }
         */
    }
    
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "adminId": adminId,
            "adminName": adminName,
        ])
    }
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "jobTemplateId": templateId,
            "type": templateName,
        ])
    }
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:JobOperationStatus) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "operationStatus": operationStatus.rawValue,
        ])
    }
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:JobBillingStatus) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "billingStatus": billingStatus.rawValue,
        ])
    }
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "rate": Double(rate) ?? 0,//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ])
    }
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "laborCost": Double(laborCost) ?? 0,//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ])
    }
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["description": description])
        //        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        //        ref.updateData([
        //            "description": description,//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        //        ]) { err in
        //            if let err = err {
        //                print("Error updating document: \(err)")
        //            } else {
        //                print("Updated Store Items")
        //            }
        //        }
    }
    func updateJobDateEstimateAccepted(companyId: String, jobId: String, date: Date) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["dateEstimateAccepted": date])
    }
    func updateJobEstiamteAcceptedById(companyId: String, jobId: String, id: String) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["receivedLaborContractId": id])
    }
    func updateJobEstiamteAcceptedByType(companyId: String, jobId: String, type: JobEstiamteAcceptanceType) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["estimateAcceptType": type.rawValue])
    }
    func updateJobEstimateAcceptedNotes(companyId: String, jobId: String, notes: String) async throws {
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["estimateAcceptedNotes": notes])
    }
    func updateJobInvoiceDate(companyId: String, jobId: String, date: Date) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["invoiceDate": date])
    }
    func updateJobInvoiceRef(companyId: String, jobId: String, ref: String) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["invoiceRef": ref])
    }
    func updateJobInvoiceNotes(companyId: String, jobId: String, notes: String) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["invoiceNotes": notes])
    }
    func updateJobInvoiceType(companyId: String, jobId: String, type: JobInvoiceType) async throws{
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["invoiceType": type.rawValue])
    }

    //DELETE
    func deleteJob(companyId:String,jobId:String) async throws {
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).delete()
    }
    func deletePart(companyId:String,jobId:String,part:WODBItem,category:String) async throws {
        print("Delete Part")
        let data =  [
            category: FieldValue.arrayUnion([
                [
                    "id": part.id,
                    "name": part.name,
                    "quantity": part.quantity,
                    "cost": part.cost,
                    "genericItemId": part.genericItemId
                ]
            ])
        ]
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(data)
        
    }
}
