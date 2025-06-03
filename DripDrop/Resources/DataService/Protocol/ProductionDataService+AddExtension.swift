//
//  ProductionDataService+AddExtension.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage
extension ProductionDataService {
 
 
    
    //----------------------------------------------------
    //                    Create Functions
    //----------------------------------------------------

    func upLoadInitialEmailSettings(companyId:String) async throws {
        //Developer make this better
        let initalEmailSettings: CompanyEmailConfiguration = CompanyEmailConfiguration( emailIsOn: false , emailBody: "Thank you for choosing us. We hope to continue to service your pool well.", requirePhoto: false)
         try CompanyEmailConfigurationDocument(companyId: companyId)
            .setData(from:initalEmailSettings, merge: false)
    }
    func createCustomerEmailConfiguration(companyId:String,customerEmailConfig:CustomerEmailConfiguration) async throws {
        try await CustomerEmailConfigurationDocument(companyId: companyId, id: customerEmailConfig.id)
            .setData(from:customerEmailConfig, merge: false)
    }

    //Person Alerts
    func addPersonalAlert(userId:String,dripDropAlert:DripDropAlert) async throws {
        try personalAlertDocument(userId: userId, alertId: dripDropAlert.id)
            .setData(from:dripDropAlert, merge: false)
    }
    //Company Alerts
    func addDripDropAlert(companyId:String,dripDropAlert:DripDropAlert) async throws {
        try alertDocument(companyId: companyId, alertId: dripDropAlert.id)
            .setData(from:dripDropAlert, merge: false)
    }
 
    func addTermsTemplate(companyId:String,termsTemplate:TermsTemplate) async throws{
        try termsTemplateDocument(companyId: companyId, templateId: termsTemplate.id)
            .setData(from:termsTemplate, merge: false)
    }
    func addTermsToTermsTemplate(companyId:String,termsTemplateId:String,terms:ContractTerms) async throws {
        try termsDocument(companyId: companyId, termsTempalteId: termsTemplateId, termsId: terms.id)
            .setData(from:terms, merge: false)
    }


    func addNewToDo(companyId:String, todo:ToDo) async throws {
        try ToDoDocument(toDoId: todo.id, companyId: companyId)
            .setData(from:todo, merge: false)
    }
    
    func loadCurrentUser() async throws -> DBUser{
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        return try await UserManager.shared.getCurrentUser(userId: authDataResult.uid)
        
    }
    func createNewUser(user:DBUser) async throws{
        _ = try await DBUserManager.shared.loadCurrentUser()//DEVELOPER DELETE
        try userDocument(userId: user.id).setData(from: user,merge: false,encoder: encoder)
    }
    func createFirstCompanyUser(user:DBUser) async throws{
        try userDocument(userId: user.id ).setData(from: user,merge: false)
    }
    func createNewRecentActivity(userId:String,recentActivity:RecentActivityModel) async throws{
        try userActivityDocument(userId: userId,recentActivityId: recentActivity.id).setData(from: recentActivity,merge: false)
    }
    
    
    nonisolated func updateCompanyUser(user:DBUser,updatingUser:DBUser) throws {
        //        let ref = userDocument(userId: updatingUser.id, companyId: user.companyId)
        //
        //         ref.updateData([
        //            "email": updatingUser.email,
        //            "photoUrl": updatingUser.photoUrl as Any,
        //            "dateCreated": updatingUser.dateCreated as Any,
        //            "firstName": updatingUser.firstName as Any,
        //            "lastName": updatingUser.lastName as Any,
        //            "company": updatingUser.company as Any,
        //            "companyId": updatingUser.companyId,
        //            "position": updatingUser.position,
        //            "hireDate": updatingUser.hireDate as Any,
        //            "fireDate": updatingUser.fireDate as Any,
        //            "favorites": updatingUser.favorites as Any,
        //        ]) { err in
        //            if let err = err {
        //                print("Error updating document: \(err)")
        //            } else {
        //                print("Updated Company User Successfully")
        //            }
        //        }
    }
    func updateCompanyUserRole(companyId:String,companyUserId:String,roleId:String,roleName:String) async throws{
        let ref = companyUserDoc(companyId: companyId, companyUserId: companyUserId)
        try await ref.updateData([
            "roleId": roleId,
            "roleName": roleName
        ])
    }
    func updateCompanyUserWorkerType(companyId:String,companyUserId:String,workerType:WorkerTypeEnum) async throws {
        let ref = companyUserDoc(companyId: companyId, companyUserId: companyUserId)
        try await ref.updateData([
            "workerType": workerType.rawValue
        ])
    }
    //DEVELOPER MAKE SURE THIS IS NOT NEEDED
    //    func createNewUser(user:DBUser) async throws{
    //        try userDocument(userId: user.id).setData(from: user,merge: false)
    //        //        try userDocument(userId: user.id).setData(from: user,merge: false)
    //
    //        print("New User Created")
    //    }
    
    //DEVELOPER MAKE SURE THIS IS NOT NEEDED
    //    func loadCurrentUser() async throws -> DBUser{
    //
    //        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
    //
    //        return try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)
    //
    //    }
    func uploadUserAccess(userId : String,companyId:String,userAccess:UserAccess) async throws {
        print("Attempting to Up Load \(userId) Have access to \(userAccess.companyName) to Firestore")
        
        try userDocument(userId: userId, accessId: companyId).setData(from:userAccess, merge: false)
    }
    func addCompanyUser(companyId:String,companyUser:CompanyUser) async throws{
        try companyUserDoc(companyId: companyId, companyUserId: companyUser.id)
            .setData(from:companyUser, merge: false)
        
    }
    func addNewRateSheet(companyId:String,companyUserId:String,rateSheet:RateSheet) async throws {
        try companyUserRateSheetDoc(companyId: companyId, companyUserId: companyUserId, rateSheetId: rateSheet.id).setData(from:rateSheet, merge: false)
    }
    func uploadPurchaseItem(companyId: String,purchaseItem : PurchasedItem) async throws {
        
        try PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData(from:purchaseItem, merge: false)
    }
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws{
        print("UploadingCustomerMonthlySummary")
        print(companyId)
        
        try db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(customerMonthlySummary.id)
            .setData(from:customerMonthlySummary, merge: false)
    }
    
    
    func uploadServiceLocationBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        print(companyId)
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }
    func uploadBodyOfWaterByServiceLocation(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }
 
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws {
        try await EquipmentManager.shared.uploadEquipment(companyId: companyId, equipment: equipment)
        print("\(equipment.category)")
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in filterPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in pumpPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Returned")
            return
        }
    }
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws {
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Filter")
            
            for part in filterPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
            
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .cleaner:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Tires/Wheel",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Gear Box",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Turbine",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Hose",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Vacuum")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .saltCell:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .saltCell,
                    name: "Salt Cell",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            ]
            print("Salt Cell")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .heater:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .heater,
                    name: "Heater",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                //DEVELOPER HERE
                
            ]
            print("Heater")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .light:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .light,
                    name: "Light",
                    date: Date(),
                    notes: ""
                ),
                
            ]
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Return")
            return
        }
    }
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
        try equipmentPartDoc(companyId: companyId,equipmentId: equipmentId,partId: part.id)
            .setData(from:part, merge: false)
    }
    
    func uploadRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }
    func uploadCompany(company : Company) async throws {
        try CompanyDocument(companyId: company.id).setData(from:company, merge: false)
    }
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) async throws {
        
        var DBArray: [String] = []
        print("Throw error Here")
        DBArray = genericItem.storeItems
        DBArray.append(storeItem.id)
        print(genericItem.id)
        try await GenericItemCollection(companyId: companyId).document(genericItem.id)
            .updateData([
                "storeItems": DBArray
            ])
        
    }
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        try shoppingListCollection(companyId: companyId).document(shoppingListItem.id).setData(from:shoppingListItem, merge: false)
        
    }
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws {
        
        try GenericItemDocument(companyId: companyId, genericItemId: genericItem.id).setData(from:genericItem, merge: false)
    }
    func createIntialGenericDataBaseItems(companyId:String) async throws{
        let genericItems:[GenericItem] = [
            //Chemicals
            GenericItem(id: "Chlorine", commonName: "Chlorine", specificName: "Bleach", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Acid", commonName: "Acid", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodiumBromide", commonName: "Sodium Bromide", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Tabs", commonName: "Tabs", specificName: "3in Chlorine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "BromineTabs", commonName: "Bromine Tabs", specificName: "Bromine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Salt", commonName: "Salt", specificName: "Salt", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodaAsh", commonName: "Soda Ash", specificName: "Soda Ash", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Oz", storeItems: [], storeItemsIds: []),
            //PVC
            GenericItem(id: "Pipe", commonName: "Pipe", specificName: "Pipe", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Coupler", commonName: "Coupler", specificName: "Coupler", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Elbow", commonName: "Elbow", specificName: "Elbow", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "45", commonName: "45", specificName: "45", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: [])
        ]
        
        for item in genericItems {
            try GenericItemDocument(companyId: companyId, genericItemId: item.id).setData(from:item, merge:false)
            
        }
        
    }
    
    func uploadStore(companyId:String,store : Vender) async throws {
        
        return try StoreDocument(storeId: store.id, companyId: companyId).setData(from:store, merge: false)
    }
    func uploadChat(userId:String,chat:Chat) async throws {
        try chatDocument(chatId: chat.id)
            .setData(from:chat, merge: false)
    }
    func sendMessage(userId: String, message: Message) async throws {
        try messageDocument(messageId: message.id)
            .setData(from:message, merge: false)
    }

    func uploadGenericItem(companyId:String,workOrderTemplate : GenericItem) async throws {
        try GenericItemDocument(genericItemId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func uploadWorkOrderTemplate(companyId:String,workOrderTemplate : JobTemplate) async throws {
        
        try WorkOrderDocument(workOrderTemplateId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func uploadServiceStopTemplate(companyId:String,template : ServiceStopTemplate) async throws {
        
        try ServiceStopDocument(serviceStopTemplateId: template.id, companyId: companyId)
            .setData(from:template, merge: false)
    }
    func uploadCustomerContact(companyId:String,customerId:String,contact:Contact) async throws {
        
        try customerContactDocument(companyId: companyId, customerId: customerId, contactId: contact.id)
            .setData(from:contact, merge: false)
    }

    //Readings settings
    
    func uploadReadingTemplate(readingTemplate: SavedReadingsTemplate, companyId: String) async throws {
        try ReadingsDocument(readingTemplateId: readingTemplate.id,companyId: companyId).setData(from:readingTemplate, merge: false)

    }
  
 

    //Dosages settings
    
    func uploadDosageTemplate(dosageTemplate: SavedDosageTemplate, companyId: String) async throws {
        try DosageDocument(dosageTemplateId: dosageTemplate.id,companyId: companyId).setData(from:dosageTemplate, merge: false)
    }
    
    //recurringServiceStop Settings
    func upLoadStartingCompanySettings(companyId:String) async throws{
        
        let WOIncrement = Increment(category: "workOrders", increment: 0)
        let SSIncrement = Increment(category: "serviceStops", increment: 0)
        let RIncrement = Increment(category: "receipts", increment: 0)
        let RountIncrement = Increment(category: "recurringServiceStops", increment: 0)
        let StoreIncrement = Increment(category: "venders", increment: 0)
        let ToDoIncrement = Increment(category: "toDos", increment: 0)
        
        try db.collection("companies/\(companyId)/settings").document("workOrders").setData(from:WOIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("serviceStops").setData(from:SSIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("receipts").setData(from:RIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("recurringServiceStops").setData(from:RountIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("venders").setData(from:StoreIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("workOrders").setData(from:ToDoIncrement , merge:false)
        
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
        //Developer Change to Copying the Universal Readings and Dosages Rather Than Createing New Readings and Dosages Templates
        let weeklyCleaningId = UUID().uuidString
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
        
        let InitialTemplates:[JobTemplate] = [
            
            JobTemplate(id: weeklyCleaningId, name: "Weekly Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "red"),
            JobTemplate(id: filterCleaningId, name: "Filter Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "120", color: "orange"),
            JobTemplate(id: saltCellId, name: "Salt Cell Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "85", color: "yellow"),
            JobTemplate(id: esitmateId, name: "Weekly Cleaning Estimate", type: "Estimate", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "green"),
            JobTemplate(id: serviceCallId, name: "Service Call", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "blue"),
            JobTemplate(id: DrainandfillID, name: "Drain and Fill", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: isntallId, name: "Installation", type: "Installation", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            
            JobTemplate(id: repairID, name: "Repair", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: "2", name: "Start Up Estimate", type: "Estimate", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "black",locked: true)
            
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
        
            // Get Universal Dosage Templates
         let universalDosageTemplates = try await universalDossagesTemplateCollection()
            .getDocuments(as: DosageTemplate.self)
        print("Got Universal Dosage Templates")
        
            // Get Universal Readings Templates
        let universalReadingTemplates = try await universalReadingsTemplateCollection()
           .getDocuments(as: DosageTemplate.self)
        print("Got Universal Reading Templates")

        print("Adding Work Order Templates")
        for template in InitialTemplates {
            try await SettingsManager.shared.uploadWorkOrderTemplate(companyId: companyId, workOrderTemplate: template)
        }
        print("Adding Service Stop Templates")
        for template in InitialServiceStopTemplates {
            try await uploadServiceStopTemplate(companyId: companyId, template: template)
        }
        
        print("Adding Dosage Templates")
        for template in universalDosageTemplates {
            try DosageTemplateDocument(dosageTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
        }
        
        print("Adding Reading Templates")
        for template in universalReadingTemplates {
            try ReadingsTemplateDocument(readingTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
            
        }
        return genericTemplateList
        /*
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
        */

    }
    func upLoadReadingTemplates(companyId:String) async throws{
        let chlorineDosageID = UUID().uuidString
        //        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        //        let sodaAsh = UUID().uuidString
        //        let sodiumBromideId = UUID().uuidString
        //        let bromideTabs = UUID().uuidString
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
    func uploadBillingTemplate(billingTempalte : BillingTemplate,companyId:String) async throws {
        
        try BillingTemplateDocument(billingTemplateId: billingTempalte.id, companyId: companyId)
            .setData(from:billingTempalte, merge: false)
    }
    func uploadGenericBillingTempaltes(companyId:String) async throws {
        //        var laborType:String //per Stop, Weekly, Monthly
        //        var chemType:String //All inclusive, Without Chems, Includes specific Chems, Excludes Specific Chems
        //
        
        let tempalteArray:[BillingTemplate] = [
            BillingTemplate(id: UUID().uuidString, title: "No Worry Service", defaultSelected: false, laborType: "per Stop", chemType: "All inclusive", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Cheap Service", defaultSelected: false, laborType: "per Stop", chemType: "Without Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Normal Service", defaultSelected: true, laborType: "per Stop", chemType: "Includes specific Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "A La Carte", defaultSelected: false, laborType: "per Stop", chemType: "Excludes Specific Chems", notes: ""),
            
            BillingTemplate(id: UUID().uuidString, title: "Type 1", defaultSelected: false, laborType: "per month", chemType: "All inclusive", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 2", defaultSelected: false, laborType: "per month", chemType: "Without Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 3", defaultSelected: false, laborType: "per month", chemType: "Includes specific Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 4", defaultSelected: false, laborType: "per month", chemType: "Excludes Specific Chems", notes: "")
            
        ]
        var tempalteCount = 0
        for template in tempalteArray {
            print("uploading Template \(tempalteCount)")
            try await uploadBillingTemplate(billingTempalte: template, companyId: companyId)
            tempalteCount = tempalteCount + 1
        }
        print("Finished upLoading Generic Billing Templates")
    }
    func uploadSingleTraining(training : Training,companyId: String,techId:String) async throws {
        
        try TrainingDocument(trainingId: training.id, companyId: companyId, techId: techId).setData(from:training, merge: false)
    }
    func uploadSingleTrainingTemplate(trainingTemplate : TrainingTemplate,companyId: String) async throws {
        
        try TrainingTemplateDocument(trainingTemplateId: trainingTemplate.id, companyId: companyId).setData(from:trainingTemplate, merge: false)
    }
    func uploadGenericTraingTempaltes(companyId: String,templateList:[TrainingTemplate]) async throws{
        //        let genericTemplateList:[TrainingTemplate] = [
        //            TrainingTemplate(id: UUID().uuidString, name: "Pool Cleaning", description: "", workOrderIds: ["FUCK"]),
        //            TrainingTemplate(id: UUID().uuidString, name: "Filter Cleaning", description: "", workOrderIds: ["FUCK"]),
        //            TrainingTemplate(id: UUID().uuidString, name: "Filter Repair / Install", description: "", workOrderIds: ["FUCK"]),
        //            TrainingTemplate(id: UUID().uuidString, name: "Pump Repair / Install", description: "", workOrderIds: ["FUCK"]),
        //            TrainingTemplate(id: UUID().uuidString, name: "Heater Repair / Install", description: "", workOrderIds: ["FUCK"]),
        //
        //        ]
        for tempalte in templateList {
            try TrainingTemplateDocument(trainingTemplateId: tempalte.id, companyId: companyId).setData(from:tempalte, merge: false)
        }
        print("Successfully uploaded Generic Templates")
        
    }
    func uploadInvite(invite : Invite) async throws {
        try inviteDoc(inviteId: invite.id)
            .setData(from:invite, merge: true)
    }
    func uploadReadingToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    func uploadDosagesToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    
    func uploadReadingAndDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        print("Attempting to Upload Reading and Dosages List")
        let itemRef = stopDataDocument(companyId: companyId, stopDataId: stopData.id)
        let homeOwnerItemRef = homeOwnerStopDataDocument(stopDataId: stopData.id)
        try await itemRef.setData([
            "id": stopData.id,
            "date": stopData.date,
            "serviceStopId": stopData.serviceStopId,
            "bodyOfWaterId": stopData.bodyOfWaterId,
        ])
        try await homeOwnerItemRef.setData([
            "id": stopData.id,
            "date": stopData.date,
            "serviceStopId": stopData.serviceStopId,
            "bodyOfWaterId": stopData.bodyOfWaterId,
        ])
        var readingData:[String:Any] = [:]
        var dosageData:[String:Any] = [:]
        //Attempting to append each reading to the reading array in firestore .In side of Stop Data in the specific Customer Document
        if stopData.readings.isEmpty {
            readingData = [
                "readings": [[
                    "id": "",
                    "templateId": "",
                    "dosageType": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "bodyOfWaterId": "",
                    
                ]]
                
            ]
            try await itemRef.updateData(readingData)
            try await homeOwnerItemRef.updateData(readingData)

        }else {
            for reading in stopData.readings {
                print("Attempt To Upload Reading for \(reading.id)")
                
                readingData = [
                    "readings": FieldValue.arrayUnion([
                        [
                            "id": reading.id,
                            "templateId": reading.templateId,
                            "dosageType": reading.dosageType,
                            "name": reading.name,
                            "amount": reading.amount,
                            "UOM": reading.UOM,
                            "bodyOfWaterId": reading.bodyOfWaterId,
                        ]
                    ])
                ]
                //Internal Company
                try await itemRef.updateData(readingData)
                //External Public
                try await homeOwnerItemRef.updateData(readingData)
            }
        }
        //Attempting to append each reading to the reading array in firestore. In side of Stop Data in the specific Customer Document
        
        if stopData.dosages.isEmpty {
            dosageData = [
                "dosages": [[
                    "id": "",
                    "templateId": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "rate": "",
                    "linkedItem": "",
                    "bodyOfWaterId": "",
                ]]
                
            ]
            try await itemRef.updateData(dosageData)
            try await homeOwnerItemRef.updateData(dosageData)
        } else {
            for dosage in stopData.dosages {
                print("Attempt To Upload Dosage for \(dosage.id)")
                
                dosageData = [
                    "dosages": FieldValue.arrayUnion([[
                        "id": dosage.id,
                        "templateId": dosage.templateId,
                        "name": dosage.name,
                        "amount": dosage.amount,
                        "UOM": dosage.UOM,
                        "rate": dosage.rate,
                        "linkedItem": dosage.linkedItem,
                        
                        "bodyOfWaterId": dosage.bodyOfWaterId,
                    ]])
                ]
                
                try await itemRef.updateData(dosageData)
                try await homeOwnerItemRef.updateData(dosageData)
            }
        }
    }
    
    func uploadReadingToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try stopDataDocument(companyId: companyId, stopDataId: stopData.id).setData(from:stopData, merge: true)
        try homeOwnerStopDataDocument(stopDataId: stopData.id).setData(from:stopData,merge: true)
        print("Uploaded Reading List")
        
    }
    func uploadDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try stopDataDocument(companyId: companyId, stopDataId: stopData.id).setData(from:stopData, merge: true)
        try homeOwnerStopDataDocument(stopDataId: stopData.id).setData(from:stopData,merge: true)

        print("Uploaded Dosage List")
    }
    func addStopHistory(serviceStop:ServiceStop,stopData:StopData,companyId:String) async throws{
        print("breaks here")
        try stopDataDocument(companyId: companyId, stopDataId: stopData.id).setData(from:stopData, merge: false)
        try homeOwnerStopDataDocument(stopDataId: stopData.id).setData(from:stopData,merge: true)

        
    }

    func uploadDataBaseItem(companyId:String,dataBaseItem : DataBaseItem) async throws {
        
        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
    }
    func uploadDataBaseItemWithUser(dataBaseItem : DataBaseItem,companyId:String) async throws {
        
        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
    }
    func uploadCSVDataBaseItemToFireStore(companyId:String,CSVItem: CSVDataBaseItem,storeId:String,storeName:String) async throws{
        let identification:String = UUID().uuidString
        var boolToken:Bool = true
        if CSVItem.billable == "NB" {
            boolToken = false
        } else if CSVItem.billable == "B" {
            boolToken = true
        } else {
            boolToken = true
            
        }
        //DEVELOPER FIX
        //        let DBItem:DataBaseItem = DataBaseItem(id: identification, name: CSVItem.name, rate: Double(CSVItem.rate) ?? 12.34, storeName: storeName, venderId:storeId, category: CSVItem.category, description: CSVItem.description, dateUpdated: Date(), sku: CSVItem.sku, billable: boolToken,color: CSVItem.color,size: CSVItem.size)
        //        print(DBItem)
        //        try await DatabaseManager.shared.uploadDataBaseItemWithUser(dataBaseItem: DBItem,companyId: companyId)
        
    }
    func uploadReceipt(companyId: String,receiptItem : Receipt) async throws {
        return try ReceiptItemDocument(receiptItemId: receiptItem.id, companyId: companyId).setData(from:receiptItem, merge: false)
    }
    
    func uploadRoute(companyId:String,recurringRoute:RecurringRoute) async throws {
        print("Upload Route >> \(recurringRoute.id)")
        try recurringRouteCollection(companyId: companyId).document(recurringRoute.id).setData(from:recurringRoute, merge: false)
    }
    
    

    
   
    

    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
            //DEVELOPER REMOVE THIS FUNCTION
    }
 
    func uploadStopData(companyId:String,stopData:StopData) async throws {
        //Internal
        try stopDataDocument(companyId: companyId,stopDataId: stopData.id)
            .setData(from:stopData, merge: true)
        
        //External
        try homeOwnerStopDataDocument(stopDataId: stopData.id)
            .setData(from:stopData, merge: true)
    }
}
