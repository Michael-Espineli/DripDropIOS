//
//  SettingsManager.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/18/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import Darwin

struct JobTemplate:Identifiable, Codable,Hashable{
    
    var id :String
    var name: String
    var type: String?
    var typeImage: String?

    var dateCreated : Date?
    var rate : String?
    var color: String?
    var locked: Bool?

}
struct ServiceStopTemplate:Identifiable, Codable,Hashable{
    
    var id :String
    var name: String
    var type: String?
    var typeImage: String?

    var dateCreated : Date?
    var color: String?
}
final class SettingsManager {
    
    static let shared = SettingsManager()
    private init(){}
    
//Collections
    private func InvoiceCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/invoices")
    }
    private func SettingsCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings")
    }
    private func WorkOrderTemplateCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/workOrders/workOrders")
    }
    private func ServiceStopTemplateCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/serviceStops/serviceStops")
    }
    private func ReadingsCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/readings/readings/")
    }
    private func DosageCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/dosages/dosages/")
    }
    private func GenericItemCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/genericItems/genericItems/")
    }
    private func recurringServiceStopSettingsCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings")
    }

    //Documents
    
    private func WorkOrderDocument(workOrderTemplateId:String,companyId:String)-> DocumentReference{
        WorkOrderTemplateCollection(companyId: companyId).document(workOrderTemplateId)
    }
    private func ServiceStopDocument(serviceStopTemplateId:String,companyId:String)-> DocumentReference{
        ServiceStopTemplateCollection(companyId: companyId).document(serviceStopTemplateId)
    }
    private func ReadingsDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        ReadingsCollection(companyId: companyId).document(readingTemplateId)
    }
    private func ReadingsTemplateDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/readings/readings/").document(readingTemplateId)
        
    }
    private func DosageDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        DosageCollection(companyId: companyId).document(dosageTemplateId)
    }
    private func DosageTemplateDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/dosages/dosages/").document(dosageTemplateId)
        
    }
    private func GenericItemDocument(genericItemId:String,companyId:String)-> DocumentReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/genericItems/genericItems/").document(genericItemId)
        
    }
    //Functions
    
    //Generic Items
    func uploadGenericItem(companyId:String,workOrderTemplate : GenericItem) async throws {
        try GenericItemDocument(genericItemId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func getGenericItem(companyId:String,genericItemId:String) async throws -> GenericItem{
        return try await GenericItemDocument(genericItemId: genericItemId,companyId: companyId).getDocument(as: GenericItem.self)

   

    }
    func getGenericItems(companyId:String) async throws -> [GenericItem]{

        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)

    }
    
    //WorkOrders
    func getWorkOrderCount(companyId:String) async throws-> Int{

        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("workOrders").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
         SettingsCollection(companyId: companyId).document("workOrders")
           .updateData([
               "increment": updatedWorkOrderCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print("Work Order Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount

    }
    //Repair Request
    func getRepairRequestCount(companyId:String) async throws-> Int{

        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("repairRequests").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
         SettingsCollection(companyId: companyId).document("repairRequests")
           .updateData([
               "increment": updatedWorkOrderCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print("Repair Request Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount

    }
    func getServiceOrderCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        SettingsCollection(companyId: companyId).document("serviceStops")
           .updateData([
               "increment": updatedServiceStopCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
//        return 1

    }
    //recurringServiceStop Settings
    func getRecurringServiceStopCount(companyId:String) async throws-> Int{

        var recurringServiceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("recurringServiceStops").getDocument(as: Increment.self)
        recurringServiceStopCount = doc.increment
        sleep(1)
        let updatedRecurringServiceStopCount = recurringServiceStopCount + 1
        
         SettingsCollection(companyId: companyId).document("recurringServiceStops")
           .updateData([
               "increment": updatedRecurringServiceStopCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print(" - Recurring Service Stop Count " + String(updatedRecurringServiceStopCount))
        return updatedRecurringServiceStopCount
//        return 2

    }
    func uploadWorkOrderTemplate(companyId:String,workOrderTemplate : JobTemplate) async throws {

        try WorkOrderDocument(workOrderTemplateId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func uploadServiceStopTemplate(companyId:String,template : ServiceStopTemplate) async throws {

        try ServiceStopDocument(serviceStopTemplateId: template.id, companyId: companyId)
            .setData(from:template, merge: false)
    }
    func getAllWorkOrderTemplate(companyId:String,workOrderId:String) async throws -> JobTemplate{

        return try await WorkOrderDocument(workOrderTemplateId: workOrderId,companyId: companyId).getDocument(as: JobTemplate.self)

   

    }
    func getAllWorkOrderTemplates(companyId:String) async throws -> [JobTemplate]{

        return try await WorkOrderTemplateCollection(companyId: companyId)
            .getDocuments(as:JobTemplate.self)

    }
    func getWorkOrderEstimate(companyId:String) async throws -> [JobTemplate]{

        return try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: "Estimate" )
            .getDocuments(as:JobTemplate.self)

    }
    
    //Readings settings
    

    func uploadReadingTemplate(readingTemplate : ReadingsTemplate,companyId:String) async throws {
        
        try ReadingsDocument(readingTemplateId: readingTemplate.id,companyId: companyId).setData(from:readingTemplate, merge: false)
    }
    
    func getAllReadingTemplates(companyId:String) async throws -> [ReadingsTemplate]{

        return try await ReadingsCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:ReadingsTemplate.self)
    }

    func uploadReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {

        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId,companyId: companyId).updateData(["amount":FieldValue.arrayUnion([amount])
                                                                                             ])
    }
    func removingReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {

        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId, companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
                                                                                             ])
    }

    
    //Dosages settings
    
 
    func uploadDosageTemplate(dosageTemplate : DosageTemplate,companyId:String) async throws {

        try DosageDocument(dosageTemplateId: dosageTemplate.id,companyId: companyId).setData(from:dosageTemplate, merge: false)
    }
    func getAllDosageTemplates(companyId:String) async throws -> [DosageTemplate]{

        return try await DosageCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:DosageTemplate.self)
    }
    func getAllServiceStopTemplates(companyId:String) async throws -> [ServiceStopTemplate]{

        return try await ServiceStopTemplateCollection(companyId: companyId)
            .getDocuments(as:ServiceStopTemplate.self)
    }
    func uploadDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {

        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData(
            ["amount":FieldValue.arrayUnion([amount])
                                                                                             ])
    }
    func removingDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {

        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
                                                                                             ])
    }
    //recurringServiceStop Settings
    func upLoadStartingCompanySettings(companyId:String) async throws{
        
        let WOIncrement = Increment(category: "workOrders", increment: 0)
        let SSIncrement = Increment(category: "serviceStops", increment: 0)
        let RIncrement = Increment(category: "receipts", increment: 0)
        let RountIncrement = Increment(category: "recurringServiceStops", increment: 0)
        let StoreIncrement = Increment(category: "venders", increment: 0)
        let ToDoIncrement = Increment(category: "toDos", increment: 0)

        try Firestore.firestore().collection("companies/\(companyId)/settings").document("workOrders").setData(from:WOIncrement , merge:false)
        try Firestore.firestore().collection("companies/\(companyId)/settings").document("serviceStops").setData(from:SSIncrement , merge:false)
        try Firestore.firestore().collection("companies/\(companyId)/settings").document("receipts").setData(from:RIncrement , merge:false)
        try Firestore.firestore().collection("companies/\(companyId)/settings").document("recurringServiceStops").setData(from:RountIncrement , merge:false)
        try Firestore.firestore().collection("companies/\(companyId)/settings").document("venders").setData(from:StoreIncrement , merge:false)
        try Firestore.firestore().collection("companies/\(companyId)/settings").document("workOrders").setData(from:ToDoIncrement , merge:false)

    }
    
    func upLoadInitialGenericRoles(companyId:String) async throws {
        let roles:[Role] = [
            Role(id: "1", name: "Owner", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "All Permissions Enabled"),

            Role(id: UUID().uuidString, name: "Tech", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Techs"),
            Role(id: UUID().uuidString, name: "Manager", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Manager"),
            Role(id: UUID().uuidString, name: "Admin", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Admin"),
            Role(id: UUID().uuidString, name: "Office", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Office Personal")
            ]
        print("Adding Work Order Templates")
        for role in roles {
            try await RoleManager.shared.uploadRole(companyId: companyId, role: role)
        }
    }
    func upLoadIntialWorkOrdersAndReadingsAndDosages(companyId:String) async throws->[TrainingTemplate]{
        let weeklyCleaningId = "1"
        let saltCellId = UUID().uuidString
        let filterCleaningId = UUID().uuidString
        let esitmateId = UUID().uuidString
        let serviceCallId = UUID().uuidString
        let DrainandfillID = UUID().uuidString
        let isntallId = UUID().uuidString
        let repairID = UUID().uuidString

        let serviceStopEstiamteId = UUID().uuidString
        let serviceStopFollowUpId = UUID().uuidString
        let serviceStopLaborId = UUID().uuidString

        let startUpEstimateId = "2"

        let InitialTemplates:[JobTemplate] = [
  
            JobTemplate(id: weeklyCleaningId, name: "Weekly Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "red",locked: true),
            JobTemplate(id: filterCleaningId, name: "Filter Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "120", color: "orange"),
            JobTemplate(id: saltCellId, name: "Salt Cell Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "85", color: "yellow"),
            JobTemplate(id: esitmateId, name: "Weekly Cleaning Estimate", type: "Estimate", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "green"),
            JobTemplate(id: serviceCallId, name: "Service Call", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "blue"),
            JobTemplate(id: DrainandfillID, name: "Drain and Fill", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: isntallId, name: "Installation", type: "Installation", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "pink"),
            
            JobTemplate(id: repairID, name: "Repair", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "white"),
            JobTemplate(id: startUpEstimateId, name: "Start Up Estimate", type: "Estimate", typeImage: "list.clipboard", dateCreated: Date(), rate: "0", color: "black",locked: true)
        ]
        let InitialServiceStopTemplates:[ServiceStopTemplate] = [
  
            ServiceStopTemplate(id: serviceStopEstiamteId, name: "Estimate", type: "Estimate" , typeImage: "list.clipboard", dateCreated: Date(), color: "red"),
            ServiceStopTemplate(id: serviceStopLaborId, name: "Labor", type: "Labor" , typeImage: "wrench", dateCreated: Date(), color: "blue"),
            ServiceStopTemplate(id: serviceStopFollowUpId, name: "Follow Up", type: "Follow Up" , typeImage: "wrench", dateCreated: Date(), color: "green"),

        ]
        let genericTemplateList:[TrainingTemplate] = [
            TrainingTemplate(id: UUID().uuidString, name: "Pool Cleaning", description: "", workOrderIds: [weeklyCleaningId]),
            TrainingTemplate(id: UUID().uuidString, name: "Filter Cleaning", description: "", workOrderIds: [filterCleaningId]),
            TrainingTemplate(id: UUID().uuidString, name: "General Repair", description: "", workOrderIds: [repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Drain and Fill", description: "", workOrderIds: [DrainandfillID]),
            TrainingTemplate(id: UUID().uuidString, name: "Managment Training", description: "", workOrderIds: [serviceCallId,esitmateId]),
            TrainingTemplate(id: UUID().uuidString, name: "Filter Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Pump Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Heater Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
        ]
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString

        let InitialDosageTemplates:[DosageTemplate] = [
            DosageTemplate(id: chlorineDosageID, name: "Liquid Chlorine", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil, strength: 0.13, editable: false,chemType: "Liquid Chlorine",order: 1),
            
            DosageTemplate(id: tabsID, name: "Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "3 in Tabs", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Tabs",order: 2),

            DosageTemplate(id: acidID, name: "Muratic Acid", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil,strength: 0.14, editable: false,chemType: "Muratic Acid",order: 3),

                  
            DosageTemplate(id: sodaAsh, name: "Soda Ash", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "1.00",
                           linkedItemId: nil, strength: 1, editable: false,chemType: "Soda Ash",order: 4),

            DosageTemplate(id: sodiumBromideId, name: "Sodium Bromide", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Sodium Bromide",order: 5),

            DosageTemplate(id: bromideTabs, name: "Bromide Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "Tab", rate: "2.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Bromide Tabs",order: 6),

            
            DosageTemplate(id: saltId, name: "Salt", amount: ["0","40","80","120","160","200","240","280"], UOM: "Lbs", rate: "0.10", linkedItemId: nil, strength: 1, editable: false,chemType: "Salt",order: 7)

        ]
        
        let InitialReadingsTemplates:[ReadingsTemplate] = [
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Disolved Solids", amount: ["100","150","200","250","300","350","400","450"], UOM: "ppm", chemType: "Total Disolved Solids", linkedDosage: "0", editable: false,order: 1,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Free Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Free Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 3 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Total Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 2 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "pH", amount: ["6.8","7.0","7.2","7.4","7.6","7.8","8.0","8.2"], UOM: "pH", chemType: "pH", linkedDosage: acidID, editable: false,order: 4 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Alkalinity", amount: ["40","80","120","180","200","220"], UOM: "ppm", chemType: "Alkalinity", linkedDosage: "0", editable: false,order: 5 ,highWarning: 0, lowWarning: 0),

            ReadingsTemplate(id: UUID().uuidString, name: "Cyanuric Acid", amount: ["10","20","30","50","80","120","150","300"], UOM: "ppm",
 chemType: "Cyanuric Acid", linkedDosage: "0", editable: false,order: 6 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Salt", amount: ["500","1000","1500","2000","2500","3000","3500","4000","4500"],
                             UOM: "ppm", chemType: "Salt", linkedDosage: saltId, editable: false,order: 7 ,highWarning: 0, lowWarning: 0),


        ]
        print("Adding Work Order Templates")
        for template in InitialTemplates {
            try await SettingsManager.shared.uploadWorkOrderTemplate(companyId: companyId, workOrderTemplate: template)
        }
        print("Adding Service Stop Templates")
        for template in InitialServiceStopTemplates {
            try await SettingsManager.shared.uploadServiceStopTemplate(companyId: companyId, template: template)
        }
        print("Adding Dosage Templates")

        for template in InitialDosageTemplates {
            try DosageTemplateDocument(dosageTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
        }
        print("Adding Reading Templates")

        for template in InitialReadingsTemplates {
            try ReadingsTemplateDocument(readingTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)

        }
return genericTemplateList
    }
    func upLoadReadingTemplates(companyId:String) async throws{
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString

        let InitialReadingsTemplates:[ReadingsTemplate] = [
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Disolved Solids", amount: ["100","150","200","250","300","350","400","450"], UOM: "ppm", chemType: "Total Disolved Solids", linkedDosage: "0", editable: false,order: 1,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Free Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Free Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 3 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Total Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 2 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "pH", amount: ["6.8","7.0","7.2","7.4","7.6","7.8","8.0","8.2"], UOM: "pH", chemType: "pH", linkedDosage: acidID, editable: false,order: 4 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Alkalinity", amount: ["40","80","120","180","200","220"], UOM: "ppm", chemType: "Alkalinity", linkedDosage: "0", editable: false,order: 5 ,highWarning: 0, lowWarning: 0),

            ReadingsTemplate(id: UUID().uuidString, name: "Cyanuric Acid", amount: ["10","20","30","50","80","120","150","300"], UOM: "ppm",
 chemType: "Cyanuric Acid", linkedDosage: "0", editable: false,order: 6 ,highWarning: 0, lowWarning: 0),

            
            ReadingsTemplate(id: UUID().uuidString, name: "Salt", amount: ["500","1000","1500","2000","2500","3000","3500","4000","4500"],
                             UOM: "ppm", chemType: "Salt", linkedDosage: saltId, editable: false,order: 7 ,highWarning: 0, lowWarning: 0),


        ]

        print("Adding Reading Templates")

        for template in InitialReadingsTemplates {
            try ReadingsTemplateDocument(readingTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)

        }
    }
    func uploadDosageTemplates(companyId:String) async throws{
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString

        let InitialDosageTemplates:[DosageTemplate] = [
            DosageTemplate(id: chlorineDosageID, name: "Liquid Chlorine", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil, strength: 0.13, editable: false,chemType: "Liquid Chlorine",order: 1),
            
            DosageTemplate(id: tabsID, name: "Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "3 in Tabs", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Tabs",order: 2),

            DosageTemplate(id: acidID, name: "Muratic Acid", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil,strength: 0.14, editable: false,chemType: "Muratic Acid",order: 3),

                  
            DosageTemplate(id: sodaAsh, name: "Soda Ash", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "1.00",
                           linkedItemId: nil, strength: 1, editable: false,chemType: "Soda Ash",order: 4),

            DosageTemplate(id: sodiumBromideId, name: "Sodium Bromide", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Sodium Bromide",order: 5),

            DosageTemplate(id: bromideTabs, name: "Bromide Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "Tab", rate: "2.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Bromide Tabs",order: 6),

            
            DosageTemplate(id: saltId, name: "Salt", amount: ["0","40","80","120","160","200","240","280"], UOM: "Lbs", rate: "0.10", linkedItemId: nil, strength: 1, editable: false,chemType: "Salt",order: 7)

        ]

        print("Adding Reading Templates")

        for template in InitialDosageTemplates {
            try DosageTemplateDocument(dosageTemplateId: template.id, companyId: companyId).setData(from:template, merge: false)

        }
    }
    func getStoreCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        SettingsCollection(companyId: companyId).document("serviceStops")
           .updateData([
               "increment": updatedServiceStopCount
       ]) { err in
           if let err = err {
               print("Error updating document: \(err)")
           } else {
               print("Document successfully updated")
           }
       }
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
//        return 1

    }
}
