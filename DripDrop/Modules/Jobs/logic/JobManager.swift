//
//  JobManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


struct Job:Identifiable, Codable, Hashable{
    //work Order info
    var id :String
    var internalId : String
    var type: String
    var dateCreated : Date
    var description: String
    
    //status
    var operationStatus : JobOperationStatus //Estimate Pending, Unscheduled, Scheduled, In Progress, Finished
    var billingStatus : JobBillingStatus // Draft, Estimate, Accepted, InProgress, Invoiced, Paid
    
    //refrences
    var customerId : String
    var customerName : String
    var serviceLocationId: String
    var serviceStopIds: [String]
    var laborContractIds: [String] //Labor Contract Sent out

    var adminId: String
    var adminName: String //Person In charge
    
    //Purchased Items
    var purchasedItemsIds:[String]?
    
    //Tasks
    var tasks:[ServiceStopTaskTemplate]? //MAYBE DEVELOPER MAKE REMOVE
    
    //calculations
    var rate : Int
    var laborCost : Int
    
    let otherCompany: Bool
    let receivedLaborContractId: String? //receivedLaborContractId from
    let receiverId: String? //Actually Optional
    var senderId : String?
    
    //Estiamte Info
    let dateEstimateAccepted: Date?
    let estimateAcceptedById: String?
    let estimateAcceptType: JobEstiamteAcceptanceType? //Client , Customer
    let estimateAcceptedNotes: String?
    
    //Invoice Info
    let invoiceDate:Date?
    let invoiceRef: String?
    let invoiceType: JobInvoiceType? //Manual , Auto
    let invoiceNotes: String?

    var cost: Int {
        laborCost // + installationPartsCost + auxiliaryPartsCost
    }
    var profit: Int {
        rate - cost
    }
    static func == (lhs: Job, rhs: Job) -> Bool {
        return lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.customerId == rhs.customerId &&
        lhs.serviceLocationId == rhs.serviceLocationId &&
        lhs.adminId == rhs.adminId
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
        hasher.combine(customerName)
        hasher.combine(customerId)
        hasher.combine(dateCreated)
        hasher.combine(adminName)
        
    }
}

protocol JobManagerProtocol {
    
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws
    func getAllWorkOrders(companyId: String) async throws -> [Job]
    func getAllWorkOrdersSortedByPrice(companyId:String,descending: Bool) async throws -> [Job]
    func getAllWorkOrdersByDate(companyId:String,date: Date) async throws -> [Job]
    
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]
    func getAllWorkOrdersSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [Job]
    func getAllWorkOrdersByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [Job]
    func getWorkOrdersBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[Job],lastDocument:DocumentSnapshot?)
    func getAllPastJobsBasedOnCustomer(companyId: String,customer: Customer)async throws -> [Job]
    
    
    func getAllFutureJobsBasedOnCustomer(companyId: String,customer: Customer)async throws -> [Job]
    
    
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job
    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws
    
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) throws
    
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) throws
    
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) throws
    
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) throws
    
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) throws
    
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) throws
    
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) throws
    
    // DEVELOPER Fix later when I have more time
    
    func updateWorkOrder(originalJob:Job,newJob:Job) async throws
    
    
    
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]
    func deleteJob(companyId:String,jobId:String) async throws
    
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:String) async throws
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:String) async throws
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws
    
    
}
final class MockJobManager:JobManagerProtocol {
    func getAllPastJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
    }
    
    func getAllFutureJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
        
    }
    
    
    static let shared = MockJobManager()
    init(){}
    private let db = Firestore.firestore()
    
    
    private func workOrderCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/workOrders")
    }
    private func workOrderInstallationPartsCollection(companyId:String,workOrderId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/workOrders/\(workOrderId)/installationParts")
    }
    private func workOrderDocument(workOrderId:String,companyId:String)-> DocumentReference{
        workOrderCollection(companyId: companyId).document(workOrderId)
        
    }
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws {
        try workOrderDocument(workOrderId: workOrder.id, companyId: companyId).setData(from:workOrder, merge: false)
    }
    
    func getAllWorkOrders(companyId: String) async throws -> [Job] {
        
        let snapshot = try await workOrderCollection(companyId: companyId).getDocuments()
        
        var workOrders: [Job] = []
        
        for document in snapshot.documents{
            let workOrder = try document.data(as: Job.self)
            workOrders.append(workOrder)
        }
        return workOrders
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
    
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]{
        let workOrders = try await getAllWorkOrders(companyId: companyId)
        var workOrderList:[Job] = []
        for WO in workOrders {
            if WO.serviceStopIds.count == 0 {
                workOrderList.append(WO)
            }
        }
        return workOrderList
        
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
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job {
        
        return try await workOrderDocument(workOrderId: workOrderId, companyId: companyId).getDocument(as: Job.self)
        
    }
    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        //DEVELOPER REMOVE THIS FUNCTION
    }
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        
        let wo = try await workOrderDocument(workOrderId: workOrder.id, companyId: companyId).getDocument(as: Job.self)
        //
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
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) throws{
        workOrderCollection(companyId: companyId).document(workOrder.id).updateData([
            "installationParts": FieldValue.arrayUnion([[
                
                "id": installationPart.id,
                "name": installationPart.name,
                "quantity": installationPart.quantity,
                "cost": installationPart.cost,
                "genericItemId": installationPart.genericItemId,
                
            ] as [String : Any]])
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "pvcParts": [
                [
                    
                    "id": pvcPart.id,
                    "name": pvcPart.name,
                    "quantity": pvcPart.quantity,
                    "cost": pvcPart.cost,
                    "genericItemId": pvcPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "electricalParts": [
                [
                    
                    "id": electricalPart.id,
                    "name": electricalPart.name,
                    "quantity": electricalPart.quantity,
                    "cost": electricalPart.cost,
                    "genericItemId": electricalPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "chemicals": [
                [
                    "id": chemical.id,
                    "name": chemical.name,
                    "quantity": chemical.quantity,
                    "cost": chemical.cost,
                    "genericItemId": chemical.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "miscParts": [
                [
                    
                    "id": miscPart.id,
                    "name": miscPart.name,
                    "quantity": miscPart.quantity,
                    "cost": miscPart.cost,
                    "genericItemId": miscPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) throws{
        var serviceStops = workOrder.serviceStopIds
        serviceStops.append(serviceStopId)
        let ref = db.collection("workOrders").document(workOrder.id)
        
        ref.updateData([
            "serviceStopIds": serviceStops
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) throws{
        
        
        
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
        ref.updateData([
            "invoiced": billingStatus
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Billing Status Successfully")
            }
        }
        
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
    
    
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]{
        //        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await db.collection("workOrders/" + workOrder.id + "/history")
            .getDocuments(as:History.self)
    }
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]{
        
        //        let calendar = Calendar.current
        //        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
        //        let start = calendar.date(from: components)!
        //        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("finished", isEqualTo: true)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:Job.self)
    }
    func deleteJob(companyId:String,jobId:String) async throws {
        
    }
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws{
        
    }
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws{
        
    }
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:String) async throws{
        
    }
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:String) async throws{
        
    }
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws{
        
    }
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws{
        
    }
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws{
        
    }
    
}
final class JobManager:JobManagerProtocol {
    
    static let shared = JobManager()
    init(){}
    private let db = Firestore.firestore()
    
    
    private func workOrderCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/workOrders")
    }
    private func workOrderInstallationPartsCollection(companyId:String,workOrderId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/workOrders/\(workOrderId)/installationParts")
    }
    private func workOrderDocument(workOrderId:String,companyId:String)-> DocumentReference{
        workOrderCollection(companyId: companyId).document(workOrderId)
        
    }
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws {
        try workOrderDocument(workOrderId: workOrder.id, companyId: companyId).setData(from:workOrder, merge: false)
    }
    func addServiceIdToJob(companyId:String,jobId:String,serviceStopId:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        try await  ref.updateData(
            ["serviceStopIds":FieldValue.arrayUnion([serviceStopId])
            ])
    }
    
    func getAllWorkOrders(companyId: String) async throws -> [Job] {
        
        let snapshot = try await workOrderCollection(companyId: companyId).getDocuments()
        
        var workOrders: [Job] = []
        
        for document in snapshot.documents{
            let workOrder = try document.data(as: Job.self)
            workOrders.append(workOrder)
        }
        return workOrders
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
    
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]{
        let workOrders = try await getAllWorkOrders(companyId: companyId)
        var workOrderList:[Job] = []
        for WO in workOrders {
            if WO.serviceStopIds.count == 0 {
                workOrderList.append(WO)
            }
        }
        return workOrderList
        
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
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job {
        
        return try await workOrderDocument(workOrderId: workOrderId, companyId: companyId).getDocument(as: Job.self)
        
    }
    func getAllPastJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
    }
    
    func getAllFutureJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
        
    }
    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        //Something To Delete
    }
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        
        let wo = try await workOrderDocument(workOrderId: workOrder.id, companyId: companyId).getDocument(as: Job.self)
        //
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
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) throws{
        workOrderCollection(companyId: companyId).document(workOrder.id).updateData([
            "installationParts": FieldValue.arrayUnion([[
                
                "id": installationPart.id,
                "name": installationPart.name,
                "quantity": installationPart.quantity,
                "cost": installationPart.cost,
                "genericItemId": installationPart.genericItemId,
                
            ] as [String : Any]])
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "pvcParts": [
                [
                    
                    "id": pvcPart.id,
                    "name": pvcPart.name,
                    "quantity": pvcPart.quantity,
                    "cost": pvcPart.cost,
                    "genericItemId": pvcPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "electricalParts": [
                [
                    
                    "id": electricalPart.id,
                    "name": electricalPart.name,
                    "quantity": electricalPart.quantity,
                    "cost": electricalPart.cost,
                    "genericItemId": electricalPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "chemicals": [
                [
                    "id": chemical.id,
                    "name": chemical.name,
                    "quantity": chemical.quantity,
                    "cost": chemical.cost,
                    "genericItemId": chemical.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) throws{
        //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "miscParts": [
                [
                    
                    "id": miscPart.id,
                    "name": miscPart.name,
                    "quantity": miscPart.quantity,
                    "cost": miscPart.cost,
                    "genericItemId": miscPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) throws{
        var serviceStops = workOrder.serviceStopIds
        serviceStops.append(serviceStopId)
        let ref = db.collection("workOrders").document(workOrder.id)
        
        ref.updateData([
            "serviceStopIds": serviceStops
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) throws{
        
        
        
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
        ref.updateData([
            "invoiced": billingStatus
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Billing Status Successfully")
            }
        }
        
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
    
    
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]{
        //        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await db.collection("workOrders/" + workOrder.id + "/history")
            .getDocuments(as:History.self)
    }
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]{
        
        //        let calendar = Calendar.current
        //        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
        //        let start = calendar.date(from: components)!
        //        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("finished", isEqualTo: true)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:Job.self)
    }
    //UPDATE
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "adminId": adminId,
            "adminName": adminName,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "jobTemplateId": templateId,
            "type": templateName,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "operationStatus": operationStatus,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "billingStatus": billingStatus,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "rate": Double(rate),//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "laborCost": Double(laborCost),//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "description": description,//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    //DELETE
    func deleteJob(companyId:String,jobId:String) async throws {
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).delete()
    }
}


