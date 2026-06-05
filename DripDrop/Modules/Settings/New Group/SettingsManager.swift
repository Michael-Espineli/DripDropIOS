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

struct JobTemplate: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var name: String
    var description: String

    var jobType: String
    var jobTypeImage: String?

    var defaultRateCents: Int
    var defaultLaborCostCents: Int

    var color: String?
    var isActive: Bool
    var locked: Bool

    var createdAt: Date
    var createdByUserId: String
    var updatedAt: Date?

    init(
        id: String = "comp_job_template_" + UUID().uuidString,
        companyId: String,
        name: String,
        description: String = "",
        jobType: String = "",
        jobTypeImage: String? = nil,
        defaultRateCents: Int = 0,
        defaultLaborCostCents: Int = 0,
        color: String? = nil,
        isActive: Bool = true,
        locked: Bool = false,
        createdAt: Date = Date(),
        createdByUserId: String,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.name = name
        self.description = description
        self.jobType = jobType
        self.jobTypeImage = jobTypeImage
        self.defaultRateCents = defaultRateCents
        self.defaultLaborCostCents = defaultLaborCostCents
        self.color = color
        self.isActive = isActive
        self.locked = locked
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
        self.updatedAt = updatedAt
    }
}

struct JobTemplatePlannedServiceStop: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var name: String
    var description: String

    var serviceStopTypeId: String
    var serviceStopTypeName: String
    var serviceStopTypeImage: String
    var serviceStopTypeUseCaseRawValue: String

    var estimatedMinutes: Int
    var sortOrder: Int

    var taskTemplateIds: [String]

    var plannedLaborCostCents: Int?
    var plannedLaborNotes: String?

    init(
        id: String = "comp_job_template_plan_stop_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        name: String,
        description: String = "",
        serviceStopTypeId: String,
        serviceStopTypeName: String,
        serviceStopTypeImage: String,
        serviceStopTypeUseCaseRawValue: String,
        estimatedMinutes: Int,
        sortOrder: Int,
        taskTemplateIds: [String] = [],
        plannedLaborCostCents: Int? = nil,
        plannedLaborNotes: String? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.name = name
        self.description = description
        self.serviceStopTypeId = serviceStopTypeId
        self.serviceStopTypeName = serviceStopTypeName
        self.serviceStopTypeImage = serviceStopTypeImage
        self.serviceStopTypeUseCaseRawValue = serviceStopTypeUseCaseRawValue
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.taskTemplateIds = taskTemplateIds
        self.plannedLaborCostCents = plannedLaborCostCents
        self.plannedLaborNotes = plannedLaborNotes
    }
}

struct JobTemplateTask: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var name: String
    var type: JobTaskType
    var description: String

    var contractedRate: Int
    var estimatedTime: Int
    var customerApproval: Bool

    var equipmentId: String?
    var serviceLocationId: String?
    var bodyOfWaterId: String?
    var dataBaseItemId: String?

    var sortOrder: Int

    init(
        id: String = "comp_job_template_task_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        name: String,
        type: JobTaskType,
        description: String = "",
        contractedRate: Int,
        estimatedTime: Int,
        customerApproval: Bool = false,
        equipmentId: String? = nil,
        serviceLocationId: String? = nil,
        bodyOfWaterId: String? = nil,
        dataBaseItemId: String? = nil,
        sortOrder: Int
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.name = name
        self.type = type
        self.description = description
        self.contractedRate = contractedRate
        self.estimatedTime = estimatedTime
        self.customerApproval = customerApproval
        self.equipmentId = equipmentId
        self.serviceLocationId = serviceLocationId
        self.bodyOfWaterId = bodyOfWaterId
        self.dataBaseItemId = dataBaseItemId
        self.sortOrder = sortOrder
    }
}

struct JobTemplateShoppingItem: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var subCategory: ShoppingListSubCategory

    var name: String
    var description: String
    var quantity: String

    var dbItemId: String?
    var genericItemId: String?

    var plannedUnitCostCents: Int?
    var plannedUnitPriceCents: Int?
    var plannedTotalCostCents: Int?
    var plannedTotalPriceCents: Int?

    var billable: Bool
    var sortOrder: Int

    init(
        id: String = "comp_job_template_shop_item_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        subCategory: ShoppingListSubCategory,
        name: String,
        description: String = "",
        quantity: String,
        dbItemId: String? = nil,
        genericItemId: String? = nil,
        plannedUnitCostCents: Int? = nil,
        plannedUnitPriceCents: Int? = nil,
        plannedTotalCostCents: Int? = nil,
        plannedTotalPriceCents: Int? = nil,
        billable: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.subCategory = subCategory
        self.name = name
        self.description = description
        self.quantity = quantity
        self.dbItemId = dbItemId
        self.genericItemId = genericItemId
        self.plannedUnitCostCents = plannedUnitCostCents
        self.plannedUnitPriceCents = plannedUnitPriceCents
        self.plannedTotalCostCents = plannedTotalCostCents
        self.plannedTotalPriceCents = plannedTotalPriceCents
        self.billable = billable
        self.sortOrder = sortOrder
    }
}
// I dont think I use this anywhere
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
        print("[SettingsManager][getRecurringServiceStopCount] recurringServiceStopCount:\(recurringServiceStopCount)")
        let updatedRecurringServiceStopCount = recurringServiceStopCount + 1
        print("[SettingsManager][getRecurringServiceStopCount] updatedRecurringServiceStopCount:\(updatedRecurringServiceStopCount)")
        
         try await SettingsCollection(companyId: companyId).document("recurringServiceStops")
           .updateData([
               "increment": updatedRecurringServiceStopCount
           ])
        print("[SettingsManager][getRecurringServiceStopCount]  Recurring Service Stop Count " + String(updatedRecurringServiceStopCount))
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
        let allPermissionIds = [
            "0","10","12","14","16","20","22","24","26","30","32","34","36",
            "40","42","44","46","50","52","54","56","60","62","64","66",
            "200","210","220","230","232","234","236","240","242","244","246",
            "250","252","254","256","260","262","264","266","280","282","284","286",
            "290","292","294","296",
            "400","410","412","414","416",
            "600","610","612","614","616","620","622","624","626",
            "800","810","812","814","816","820","822","824","826","830","832","834","836",
            "840","842","844","846","850","852","854","856","860","862","864","866",
            "870","872","874","876","880","882","884","886",
            "890","892","894","896"
        ]
        let managerPermissionIds = [
            "0","10","12","14","16","20","22","24","26","30","32","34","36",
            "200","210","220","230","232","234","236","240","242","244","246",
            "250","252","254","256","260","262","264","266","280","282","284","286",
            "290","292","294","296",
            "400",
            "600","610","612","614","616","620","622","624","626",
            "800","810","812","814","816","820","822","824","826","830","832","834","836",
            "840","842","844","846","850","852","854","856","860","862","864","866",
            "870","872","874","876","880","882","884","886"
        ]
        let roles:[Role] = [
            Role(id: "1", name: "Owner", permissionIdList: allPermissionIds, listOfUserIdsToManage: [], color: "red", description: "All Permissions Enabled"),

            Role(id: UUID().uuidString, name: "Tech", permissionIdList: allPermissionIds, listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Techs"),
            Role(id: UUID().uuidString, name: "Manager", permissionIdList: managerPermissionIds, listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Manager"),
            Role(id: UUID().uuidString, name: "Admin", permissionIdList: allPermissionIds, listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Admin"),
            Role(id: UUID().uuidString, name: "Office", permissionIdList: allPermissionIds, listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Office Personal")
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

        let InitialTemplates:[JobTemplate] = []
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
            DosageTemplate(
                id: chlorineDosageID,
                name: "Liquid Chlorine",
                amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"],
                UOM: "gallon",
                rate: "5.00",
                linkedItemId: nil,
                strength: 0.13,
                editable: false,
                chemType: "Liquid Chlorine",
                order: 1
            ),
            
            DosageTemplate(id: tabsID, name: "Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "3 in Tabs", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Tabs",order: 2),

            DosageTemplate(id: acidID, name: "Muratic Acid", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil,strength: 0.14, editable: false,chemType: "Muratic Acid",order: 3),

                  
            DosageTemplate(id: sodaAsh, name: "Soda Ash", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "1.00",
                           linkedItemId: nil, strength: 1, editable: false,chemType: "Soda Ash",order: 4),

            DosageTemplate(id: sodiumBromideId, name: "Sodium Bromide", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Sodium Bromide",order: 5),

            DosageTemplate(id: bromideTabs, name: "Bromide Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "Tab", rate: "2.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Bromide Tabs",order: 6),

            
            DosageTemplate(id: saltId, name: "Salt", amount: ["0","40","80","120","160","200","240","280"], UOM: "Lbs", rate: "0.10", linkedItemId: nil, strength: 1, editable: false,chemType: "Salt",order: 7)

        ]
        
        let InitialReadingsTemplates:[ReadingsTemplate] = [
            
            ReadingsTemplate(
                id: UUID().uuidString,
                name: "Total Disolved Solids",
                amount: ["100","150","200","250","300","350","400","450"],
                UOM: "ppm",
                chemType: "Total Disolved Solids",
                linkedDosage: "0",
                editable: false,
                order: 1,
                highWarning: 0,
                lowWarning: 0
            ),
            
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
