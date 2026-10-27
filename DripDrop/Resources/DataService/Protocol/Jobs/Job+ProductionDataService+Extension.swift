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
import FirebaseAuth
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

    func workOrderCommentsCollection(companyId: String, workOrderId: String) -> CollectionReference {
        workOrderDocument(workOrderId: workOrderId, companyId: companyId)
            .collection("comments")
    }
    
    //CREATE
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws {
        let actor = try await jobCreationActor()
        let ref = workOrderDocument(workOrderId: workOrder.id, companyId: companyId)
        let encoded = try Firestore.Encoder().encode(workOrder)
        let now = Date()
        let initialEvent = actor.creationEvent(companyId: companyId, jobId: workOrder.id, internalId: workOrder.internalId, at: now)
        let history = try Firestore.Encoder().encode(initialEvent)
        _ = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let existing = try transaction.getDocument(ref)
                var record = encoded
                if existing.exists {
                    // Updating a job cannot relabel its original creator or creation time.
                    let original = existing.data() ?? [:]
                    for key in ["createdByUserId", "createdByUserName", "createdByCompanyUserId", "createdAt", "createdAtMillis", "dateCreated"] {
                        if let value = original[key] { record[key] = value }
                        else { record.removeValue(forKey: key) }
                    }
                } else {
                    record["createdByUserId"] = actor.userId
                    record["createdByUserName"] = actor.userName
                    record["createdByCompanyUserId"] = actor.companyUserId
                    record["createdAt"] = FieldValue.serverTimestamp()
                    record["createdAtMillis"] = initialEvent.createdAtMillis
                    record["lastHistoryEventId"] = "created"
                    record["lastHistoryEventTitle"] = "Job created"
                    record["lastHistoryEventType"] = "Created"
                    var event = history
                    event["createdAt"] = FieldValue.serverTimestamp()
                    transaction.setData(event, forDocument: ref.collection("history").document("created"))
                }
                transaction.setData(record, forDocument: ref)
                return true
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func jobCreationActor() async throws -> JobCreationActor {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "JobCreation", code: 4, userInfo: [NSLocalizedDescriptionKey: "Sign in before creating a job so its creator can be recorded."])
        }
        let profile = try? await getCurrentUser(userId: user.uid)
        let fullName = [profile?.firstName, profile?.lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let name = [fullName, user.displayName ?? "", profile?.email ?? user.email ?? "", user.uid].first {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.lowercased() != "unknown"
        } ?? user.uid
        return JobCreationActor(userId: user.uid, userName: name)
    }

    func fetchJobHistory(companyId: String, jobId: String) async throws -> [JobHistoryEvent] {
        let snapshot = try await workOrderDocument(workOrderId: jobId, companyId: companyId).collection("history").getDocuments()
        return try snapshot.documents.map { document in
            var data = document.data()
            data["id"] = document.documentID
            return try Firestore.Decoder().decode(JobHistoryEvent.self, from: data)
        }.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }

    func addWorkOrderComment(
        companyId: String,
        workOrderId: String,
        comment: JobComment
    ) async throws {
        try workOrderCommentsCollection(companyId: companyId, workOrderId: workOrderId)
            .document(comment.id)
            .setData(from: comment, merge: false)
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
    
    func getWorkOrderComments(companyId: String, workOrderId: String) async throws -> [JobComment] {
        try await workOrderCommentsCollection(companyId: companyId, workOrderId: workOrderId)
            .order(by: "date", descending: true)
            .getDocuments(as: JobComment.self)
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
            .order(by: "dateCreated", descending: true)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrdersFinished(companyId: String,finished:Bool) async throws -> [Job] {
        if finished {
            return try await workOrderCollection(companyId: companyId)
                .order(by: "dateCreated", descending: true)
                .whereField("operationStatus", in: ["Finished"])
                    .whereField("billingStatus", in: ["Invoiced","Paid","Comped","Expired"])
                .getDocuments(as:Job.self)
            
        } else {
            return try await workOrderCollection(companyId: companyId)
                .order(by: "dateCreated", descending: true)
                .whereField("operationStatus", in: ["Estimate Pending","Unscheduled","Scheduled","In Progress","Waiting for Parts"])
                    .whereField("billingStatus", in: ["Draft","Estimate","Accepted","In Progress"])
                .getDocuments(as:Job.self)
            
        }
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
    func updateTermsTemplateName(companyId:String,templateId:String,templateName:String) async throws{
        let ref = termsTemplateDocument(companyId: companyId, templateId: templateId)
        try await ref.updateData([
            "name": templateName,
        ])
    }
    
    func updateTermsTemplateDescription(companyId:String,templateId:String,templateDescription:String) async throws{
        let ref = termsTemplateDocument(companyId: companyId, templateId: templateId)
        try await ref.updateData([
            "description": templateDescription,
        ])
    }
    
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:JobOperationStatus) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "operationStatus": operationStatus.rawValue,
        ])
    }
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:JobBillingStatus)  throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try ref.updateData([
            "billingStatus": billingStatus.rawValue,
        ])
    }
    func updateJobRate(companyId:String,jobId:String,rate:Int) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await ref.updateData([
            "rate": rate,
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
    
    func updateWorkOrderCommentResolved(
        companyId: String,
        workOrderId: String,
        commentId: String,
        resolved: Bool
    ) async throws {
        try await workOrderCommentsCollection(companyId: companyId, workOrderId: workOrderId)
            .document(commentId)
            .updateData(["resolved": resolved])
    }
    
    func updateJobDateEstimateAccepted(companyId: String, jobId: String, date: Date) throws{
        workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["dateEstimateAccepted": date])
    }
    func updateJobEstiamteAcceptedById(companyId: String, jobId: String, id: String) throws{
         workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["estimateAcceptedById": id])
    }
    func updateJobEstiamteAcceptedByType(companyId: String, jobId: String, type: JobEstiamteAcceptanceType) throws{
        try  workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["estimateAcceptType": type.rawValue])
    }
    func updateJobEstimateAcceptedNotes(companyId: String, jobId: String, notes: String) throws {
        try workOrderDocument(workOrderId: jobId, companyId: companyId).updateData(["estimateAcceptedNotes": notes])
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
        let jobRef = workOrderDocument(workOrderId: jobId, companyId: companyId)
        let jobSnapshot = try await jobRef.getDocument()

        if jobSnapshot.exists {
            let job = try jobSnapshot.data(as: Job.self)
            if job.operationStatus == .finished {
                throw DeleteProtectionError.finishedJob
            }

            for serviceStopId in job.serviceStopIds {
                let serviceStopSnapshot = try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).getDocument()
                guard serviceStopSnapshot.exists else { continue }

                let serviceStop = try serviceStopSnapshot.data(as: ServiceStop.self)
                if serviceStop.operationStatus == .finished || serviceStop.endTime != nil {
                    throw DeleteProtectionError.jobHasFinishedServiceStop
                }
            }
        }

        try await jobRef.delete()
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

extension ProductionDataService {
    func fetchJobLaborLineItems(companyId: String, jobId: String) async throws -> [JobLaborLineItem] {
        let job = workOrderDocument(workOrderId: jobId, companyId: companyId)
        let record = try await job.getDocument(as: Job.self)
        if let lines = record.laborLineItems ?? record.estimateLaborLineItems { return lines }
        let snapshot = try await job.collection("laborLineItems").getDocuments()
        return try snapshot.documents.map { try $0.data(as: JobLaborLineItem.self) }
    }

    func fetchJobTemplateLaborLineItems(companyId: String, templateId: String) async throws -> [JobLaborLineItem] {
        let ref = db.collection("companies/\(companyId)/jobTemplates").document(templateId)
        let snapshot = try await ref.collection("laborLineItems").getDocuments()
        if !snapshot.isEmpty { return try snapshot.documents.map { try $0.data(as: JobLaborLineItem.self) } }
        let root = try await ref.getDocument().data() ?? [:]
        if let embedded = root["laborLineItems"] as? [[String: Any]], !embedded.isEmpty {
            return try embedded.map { try Firestore.Decoder().decode(JobLaborLineItem.self, from: $0) }
        }
        if (root["laborLineItemCount"] as? Int ?? root["laborLineCount"] as? Int ?? 0) > 0 {
            throw NSError(domain: "JobTemplate", code: 3, userInfo: [NSLocalizedDescriptionKey: "The template's service billing lines could not be loaded. Reload the template before creating a job."])
        }
        return []
    }

    func saveJobTemplateBundle(template: JobTemplate, tasks: [JobTemplateTask], stops: [JobTemplatePlannedServiceStop], items: [JobTemplateShoppingItem], laborLines: [JobLaborLineItem]) async throws {
        guard 1 + tasks.count + stops.count + items.count + laborLines.count <= 500 else {
            throw NSError(domain: "JobTemplate", code: 2, userInfo: [NSLocalizedDescriptionKey: "This template contains too many records to save together."])
        }
        let ref = db.collection("companies/\(template.companyId)/jobTemplates").document(template.id)
        let batch = db.batch()
        var root = try Firestore.Encoder().encode(template)
        root["laborLineItemCount"] = laborLines.count
        root["laborLineItems"] = try laborLines.map { try Firestore.Encoder().encode($0) }
        batch.setData(root, forDocument: ref)
        for task in tasks { try batch.setData(from: task, forDocument: ref.collection("tasks").document(task.id)) }
        for stop in stops { try batch.setData(from: stop, forDocument: ref.collection("plannedServiceStops").document(stop.id)) }
        for item in items { try batch.setData(from: item, forDocument: ref.collection("shoppingItems").document(item.id)) }
        for line in laborLines { try batch.setData(from: line, forDocument: ref.collection("laborLineItems").document(line.id)) }
        try await batch.commit()
    }

    func commitNewJob(companyId: String, job: Job, scope: NewJobScope) async throws -> Job {
        let actor = try await jobCreationActor()
        let createdAt = Date()
        let company = db.collection("companies").document(companyId)
        let ref = company.collection("workOrders").document(job.id)
        let counter = company.collection("settings").document("workOrders")
        let stopCounter = company.collection("settings").document("recurringServiceStops")
        let planId = "comp_job_plan_" + job.id
        var preparedJob = job
        preparedJob.createdByUserId = actor.userId
        preparedJob.createdByUserName = actor.userName
        preparedJob.createdByCompanyUserId = actor.companyUserId
        preparedJob.createdAt = createdAt
        preparedJob.createdAtMillis = Int(createdAt.timeIntervalSince1970 * 1000)
        var tasks = scope.tasks
        var materials = scope.shoppingItems
        for index in tasks.indices { tasks[index].serviceLocationId = job.serviceLocationId }
        for index in materials.indices {
            materials[index].jobId = job.id
            materials[index].customerId = job.customerId
            materials[index].customerName = job.customerName
            materials[index].serviceLocationId = job.serviceLocationId
        }
        var lines = scope.completeLaborLines.map { original -> JobLaborLineItem in
            var line = original
            line.companyId = companyId
            line.jobId = job.id
            line.templateId = nil
            line.sourcePlanId = planId
            line.sourceSolutionId = planId
            return line
        }
        preparedJob.activePlanId = planId
        preparedJob.activeSolutionId = planId
        let materialPrice = materials.reduce(0) { $0 + ($1.plannedTotalPriceCents ?? Int((Double($1.quantity ?? "1") ?? 1) * Double($1.plannedUnitPriceCents ?? 0))) }
        let materialCost = materials.reduce(0) { $0 + ($1.plannedTotalCostCents ?? Int((Double($1.quantity ?? "1") ?? 1) * Double($1.plannedUnitCostCents ?? 0))) }
        if scope.laborLineItems.isEmpty && job.rate != 0 {
            var legacy = JobLaborLineItem(id: "comp_job_labor_line_" + job.id)
            legacy.name = job.sourceTemplateName ?? "Labor"
            legacy.companyId = companyId
            legacy.jobId = job.id
            legacy.quantity = 1
            legacy.totalPriceCents = max(0, job.rate - materialPrice)
            legacy.unitPriceCents = legacy.totalPriceCents
            legacy.internalCostCents = job.laborCost
            legacy.taxable = false
            legacy.taskIds = tasks.map(\.id)
            legacy.plannedServiceStopIds = scope.plannedStops.map(\.id)
            legacy.sourcePlanId = planId
            legacy.sourceSolutionId = planId
            lines = [legacy]
        }
        preparedJob.laborLineItems = lines
        preparedJob.estimateLaborLineItems = lines
        if !lines.isEmpty || materialPrice != 0 {
            preparedJob.rate = lines.reduce(0) { $0 + $1.priceCents } + materialPrice
            preparedJob.laborCost = lines.reduce(0) { $0 + ($1.internalCostCents ?? 0) }
        }
        preparedJob.serviceStopIds = scope.scheduledStops.map(\.id)
        let encoder = Firestore.Encoder()
        let taskRows = try tasks.map { try encoder.encode($0) }
        let stopRows = try scope.plannedStops.map { try encoder.encode($0) }
        let materialRows = try materials.map { try encoder.encode($0) }
        let lineRows = try lines.map { try encoder.encode($0) }
        let scheduledRows = try scope.scheduledStops.map { try encoder.encode($0) }
        let scheduledTasks = try scope.scheduledTasks.mapValues { try $0.map { try encoder.encode($0) } }
        let writeCount = 4 + tasks.count + stopRows.count + materials.count + lines.count + scheduledRows.count + scheduledTasks.values.reduce(0) { $0 + $1.count } + (scheduledRows.isEmpty ? 0 : 1)
        guard writeCount <= 500 else {
            throw NSError(domain: "JobCreation", code: 2, userInfo: [NSLocalizedDescriptionKey: "This job contains too many records to save together. Reduce its scope before creating it."])
        }
        let rootData = try encoder.encode(preparedJob)
        var invoiceLines = lineRows.map { row -> [String: Any] in
            var result = row
            let price = row["totalPriceCents"] as? Int ?? 0
            result["totalAmountCents"] = price
            result["unitAmountCents"] = row["unitPriceCents"] ?? price
            result["amount"] = price
            result["type"] = "Service"
            result["taxable"] = row["taxable"] ?? false
            return result
        }
        invoiceLines += materials.map { item in
            let price = item.plannedTotalPriceCents ?? Int((Double(item.quantity ?? "1") ?? 1) * Double(item.plannedUnitPriceCents ?? 0))
            return ["id": item.id, "name": item.name, "description": item.description, "quantity": Double(item.quantity ?? "1") ?? 1,
                    "unitAmountCents": item.plannedUnitPriceCents ?? price, "totalAmountCents": price, "amount": price,
                    "type": "Material", "taxable": item.taxable ?? false, "genericItemId": item.genericItemId]
        }
        if invoiceLines.isEmpty && preparedJob.rate != 0 {
            invoiceLines = [["id": "job_labor_" + job.id, "name": "Labor", "type": "Labor", "quantity": 1, "unitAmountCents": preparedJob.rate, "totalAmountCents": preparedJob.rate, "taxable": false]]
        }
        let planLines = invoiceLines
        let totalCost = preparedJob.laborCost + materialCost
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let existing = try transaction.getDocument(ref)
                if existing.exists { return try existing.data(as: Job.self) }
                let snapshot = try transaction.getDocument(counter)
                let next = (snapshot.data()?["increment"] as? Int ?? 0) + 1
                var nextStop = 0
                if !scheduledRows.isEmpty {
                    nextStop = (try transaction.getDocument(stopCounter).data()?["increment"] as? Int ?? 0)
                }
                var saved = preparedJob
                saved.internalId = "J\(next)"
                var root = rootData
                root["internalId"] = saved.internalId
                root["companyId"] = companyId
                root["createdAt"] = FieldValue.serverTimestamp()
                root["lastHistoryEventId"] = "created"
                root["lastHistoryEventTitle"] = "Job created"
                root["lastHistoryEventType"] = "Created"
                root["solutionSelectionStatus"] = "Draft"
                root["activePlanTier"] = 2
                root["activeSolutionTier"] = 2
                let stopNumbers = Dictionary(uniqueKeysWithValues: scope.scheduledStops.enumerated().map { ($0.element.id, "SS\(nextStop + $0.offset)") })
                if let first = scope.scheduledStops.first {
                    root["scheduledServiceStopId"] = first.id
                    root["scheduledServiceStopInternalId"] = stopNumbers[first.id]
                }
                transaction.setData(["increment": next], forDocument: counter, merge: true)
                if !scheduledRows.isEmpty { transaction.setData(["increment": nextStop + scheduledRows.count], forDocument: stopCounter, merge: true) }
                transaction.setData(root, forDocument: ref)
                var plan: [String: Any] = [
                    "id": planId, "planId": planId, "solutionId": planId, "companyId": companyId, "jobId": job.id,
                    "jobInternalId": saved.internalId, "customerId": job.customerId, "customerName": job.customerName,
                    "serviceLocationId": job.serviceLocationId, "name": job.sourceTemplateName ?? "Starter Plan",
                    "description": job.description, "planTier": 2, "solutionTier": 2, "status": "Draft", "isActivePlan": true, "isAccepted": false,
                    "tasks": taskRows, "plannedServiceStops": stopRows, "shoppingItems": materialRows,
                    "laborLineItems": lineRows, "estimateLaborLineItems": lineRows, "lineItems": planLines, "contractLineItemsSnapshot": planLines,
                    "subtotalAmountCents": saved.rate, "totalAmountCents": saved.rate, "rate": saved.rate,
                    "laborCost": saved.laborCost, "laborCostCents": saved.laborCost, "internalCostCents": totalCost,
                    "createdAt": Timestamp(date: job.dateCreated), "updatedAt": Timestamp(date: job.dateCreated),
                    "sourceTemplateId": job.sourceTemplateId ?? "", "sourceTemplateName": job.sourceTemplateName ?? ""
                ]
                var savedTasks = taskRows
                for index in savedTasks.indices {
                    let linkedIds = materials.filter { $0.linkedTaskId == tasks[index].id }.map(\.id)
                    savedTasks[index]["shoppingListItemId"] = linkedIds.first ?? ""
                    savedTasks[index]["shoppingListItemIds"] = linkedIds
                }
                for index in savedTasks.indices {
                    for stop in scope.scheduledStops {
                        let source = (scope.scheduledTasks[stop.id] ?? []).first { $0.jobTaskId == tasks[index].id || ($0.jobTaskId.isEmpty && $0.id == tasks[index].id) }
                        if source != nil {
                            savedTasks[index]["status"] = "Scheduled"
                            savedTasks[index]["workerId"] = stop.techId
                            savedTasks[index]["workerName"] = stop.tech
                            savedTasks[index]["workerType"] = "Employee"
                            savedTasks[index]["serviceStopId"] = ["id": stop.id, "internalId": stopNumbers[stop.id] ?? ""]
                        }
                    }
                    savedTasks[index]["sourcePlanId"] = planId
                    savedTasks[index]["sourceSolutionId"] = planId
                    transaction.setData(savedTasks[index], forDocument: ref.collection("tasks").document(tasks[index].id))
                }
                var savedStops = stopRows
                for index in savedStops.indices {
                    savedStops[index]["companyId"] = companyId
                    savedStops[index]["jobId"] = job.id
                    savedStops[index]["sourcePlanId"] = planId
                    transaction.setData(savedStops[index], forDocument: ref.collection("plannedServiceStops").document(scope.plannedStops[index].id))
                }
                for index in materialRows.indices {
                    var item = materialRows[index]
                    item["sourcePlanId"] = planId
                    item["sourceSolutionId"] = planId
                    item["planWorkspaceOnly"] = !job.activatesShoppingListMaterials
                    transaction.setData(item, forDocument: company.collection("shoppingList").document(materials[index].id))
                }
                for index in lineRows.indices { transaction.setData(lineRows[index], forDocument: ref.collection("laborLineItems").document(lines[index].id)) }
                for index in scheduledRows.indices {
                    let stop = scope.scheduledStops[index]
                    var row = scheduledRows[index]
                    row["internalId"] = stopNumbers[stop.id]
                    row["jobId"] = job.id
                    row["jobName"] = saved.internalId
                    let stopRef = company.collection("serviceStops").document(stop.id)
                    transaction.setData(row, forDocument: stopRef)
                    for original in scheduledTasks[stop.id] ?? [] {
                        var task = original
                        task["jobId"] = ["id": job.id, "internalId": saved.internalId]
                        task["serviceStopId"] = ["id": stop.id, "internalId": stopNumbers[stop.id] ?? ""]
                        let linkedId = task["jobTaskId"] as? String ?? ""
                        if linkedId.isEmpty, let id = task["id"] as? String, tasks.contains(where: { $0.id == id }) { task["jobTaskId"] = id }
                        task["workOrderTaskId"] = task["jobTaskId"]
                        transaction.setData(task, forDocument: stopRef.collection("tasks").document(task["id"] as? String ?? UUID().uuidString))
                    }
                }
                let planTitle = job.sourceTemplateName ?? "Starter Plan"
                plan["title"] = planTitle
                plan["planName"] = planTitle
                plan["sourceType"] = job.sourceTemplateId == nil ? "initialJobPlan" : "template"
                plan["planTierLabel"] = "Standard Fix"
                plan["solutionTierLabel"] = "Standard Fix"
                plan["recommendationRank"] = 2
                plan["recommendationRankLabel"] = "Standard Fix"
                plan["rateAmountCents"] = saved.rate
                plan["plannedLaborCostCents"] = saved.laborCost
                plan["plannedLaborPriceCents"] = lines.reduce(0) { $0 + $1.priceCents }
                plan["materialCostCents"] = materialCost
                plan["materialPriceCents"] = materialPrice
                plan["projectedProfitCents"] = saved.rate - totalCost
                plan["createdAtMillis"] = Int(job.dateCreated.timeIntervalSince1970 * 1000)
                plan["updatedAtMillis"] = Int(job.dateCreated.timeIntervalSince1970 * 1000)
                plan["costSummary"] = ["plannedLaborCostCents": saved.laborCost, "plannedLaborPriceCents": lines.reduce(0) { $0 + $1.priceCents }, "plannedMaterialCostCents": materialCost, "plannedMaterialPriceCents": materialPrice, "internalCostCents": totalCost]
                plan["scopeOfWork"] = ["title": planTitle, "customerDescription": job.description, "issueDescription": job.description, "taskSummaries": savedTasks, "plannedStopSummaries": savedStops, "laborLineSummaries": lineRows, "materialSummaries": materialRows]
                plan["tasks"] = savedTasks
                plan["plannedServiceStops"] = savedStops
                transaction.setData(plan, forDocument: ref.collection("plans").document(planId))
                var history = try Firestore.Encoder().encode(actor.creationEvent(companyId: companyId, jobId: job.id, internalId: saved.internalId, at: createdAt))
                history["createdAt"] = FieldValue.serverTimestamp()
                transaction.setData(history, forDocument: ref.collection("history").document("created"))
                return saved
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let saved = result as? Job else { throw NSError(domain: "JobCreation", code: 3) }
        return saved
    }
}
