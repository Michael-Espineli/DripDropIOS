//
//  ProductionDataService+UpdateExtension.swift
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
    //                    Update Functions
    //----------------------------------------------------
    func updateCustomerEmailConfig(companyId:String,customerEmailConfigId:String,emailIsOn:Bool) async throws {
        try await CustomerEmailConfigurationDocument(companyId: companyId, id: customerEmailConfigId)
            .updateData([
                "emailIsOn": emailIsOn
            ])
    }
    
    func updateEmailConfigurationRequirePhoto(companyId:String,requirePhoto:Bool) async throws {
        try await CompanyEmailConfigurationDocument(companyId: companyId)
            .updateData([
                "requirePhoto": requirePhoto
            ])
    }

    func updateEmailConfigurationBody(companyId:String,newBody:String) async throws {
        try await CompanyEmailConfigurationDocument(companyId: companyId)
            .updateData([
                "emailBody": newBody
            ])
    }
    
    func updateEmailConfigurationIsOn(companyId:String,emailIsOn:Bool) async throws {
        try await CompanyEmailConfigurationDocument(companyId: companyId)
            .updateData([
                "emailIsOn": emailIsOn
            ])
    }

    func editTermsTemplateName(companyId:String,termsTemplateId:String,termsTemplateName:String) async throws{
        let ref = termsTemplateDocument(companyId: companyId, templateId: termsTemplateId)
        try await ref
            .updateData([
                "names": termsTemplateName
            ])
    }

    func updateShoppingListDescription(companyId: String, shoppingListItemId: String, newDescription: String) async throws {
        let ref = shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId)
        try await ref
            .updateData([
                "description": newDescription
            ])
    }
    func updateShoppingListItemStatus(companyId: String, shoppingListItemId: String, status: ShoppingListStatus) async throws {
        let ref = shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId)
        try await ref
            .updateData([
                "status": status.rawValue
            ])
    }
    func removingReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {
        
        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId, companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
        ])
    }
    
    func removingDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {
        
        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
        ])
    }
    func uploadDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {
        
        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData(
            ["amount":FieldValue.arrayUnion([amount])
            ])
    }
    func updateInstallationJobParts(companyId: String, jobId: String, installationPart: WODBItem) async throws {
        print("updateInstallationJobParts")
        try await  workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
                "installationParts":FieldValue.arrayUnion([
                    [
                        "id":installationPart.id,
                        "name":installationPart.name,
                        "quantity":installationPart.quantity,
                        "cost":installationPart.cost,
                        "genericItemId":installationPart.genericItemId,
                    ] as [String : Any]])
            ])
    }
    func updatePVCobParts(companyId: String, jobId: String, pvc: WODBItem) async throws {
        print("updatePVCobParts")
        try await  workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
                "pvcParts":FieldValue.arrayUnion([
                    [
                        "id":pvc.id,
                        "name":pvc.name,
                        "quantity":pvc.quantity,
                        "cost":pvc.cost,
                        "genericItemId":pvc.genericItemId,
                    ] as [String : Any]])
            ])
    }
    
    func updateElectricalJobParts(companyId: String, jobId: String, electical: WODBItem) async throws {
        print("updateElectricalJobParts")
        try await  workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
                "electricalParts":FieldValue.arrayUnion([
                    [
                        "id":electical.id,
                        "name":electical.name,
                        "quantity":electical.quantity,
                        "cost":electical.cost,
                        "genericItemId":electical.genericItemId,
                    ] as [String : Any]])
            ])
    }
    
    func updateChemicalsJobParts(companyId: String, jobId: String, chemical: WODBItem) async throws {
        print("updateChemicalsJobParts")
        try await  workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
                "chemicals":FieldValue.arrayUnion([
                    [
                        "id":chemical.id,
                        "name":chemical.name,
                        "quantity":chemical.quantity,
                        "cost":chemical.cost,
                        "genericItemId":chemical.genericItemId,
                    ] as [String : Any]])
            ])
    }
    
    func updateMiscJobParts(companyId: String, jobId: String, misc: WODBItem) async throws {
        print("updateMiscJobParts")
        try await  workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
                "miscParts":FieldValue.arrayUnion([
                    [
                        "id":misc.id,
                        "name":misc.name,
                        "quantity":misc.quantity,
                        "cost":misc.cost,
                        "genericItemId":misc.genericItemId,
                    ] as [String : Any]])
            ])
    }
    func uploadReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {
        
        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId,companyId: companyId).updateData(["amount":FieldValue.arrayUnion([amount])
                                                                                                                  ])
    }
    func markInviteAsAccepted(invite:Invite) async throws {
        let itemRef = inviteDoc(inviteId: invite.id)
        
        // Set the "capital" field of the city 'DC'
        try await itemRef.updateData([
            Invite.CodingKeys.status.rawValue:"Accepted"
            
        ])
    }

    func editDataBaseItem(
        companyId:String,
        dataBaseItemId:String,
        name:String,
        rate:Double,
        storeName:String,
        storeId:String,
        category:DataBaseItemCategory,
        subCategory:DataBaseItemSubCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        UOM:UnitOfMeasurment
    ) async throws {
        
        let dataBaseItem = DataBaseItem(
            id: dataBaseItemId,
            name: name,
            rate: rate,
            storeName: storeName,
            venderId: storeId,
            category: category,
            subCategory: subCategory,
            description: description,
            dateUpdated: Date(),
            sku: sku,
            billable: billable,
            color: color,
            size: size,
            UOM:UOM
        )
        try DataBaseDocument(dataBaseId: dataBaseItemId,companyId: companyId).setData(from:dataBaseItem, merge: true)
    }
    
    
    func updateDataBaseItem(
        dataBaseItem:DataBaseItem,
        companyId: String,
        name:String,
        rate:Double,
        category:DataBaseItemCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        sellPrice:Double,
        UOM:UnitOfMeasurment,
        subCategory:DataBaseItemSubCategory
    ) async throws {
        let itemRef = DataBaseDocument(dataBaseId: dataBaseItem.id, companyId: companyId)
        
        // Set the "capital" field of the city 'DC'
        try await itemRef.updateData([
            "name":name,
            "rate":rate,
            "category":category.rawValue,
            "description":description,
            "dateUpdated":Date(),
            "sku":sku,
            "billable":billable,
            "color":color,
            "size":size,
            "sellPrice":sellPrice,
            "UOM":UOM.rawValue,
            "subCategory":subCategory.rawValue,
        ])
    }
    func updateReceiptPDFPath(companyId: String,receiptItemId:String,path:String) async throws {
        
        let ref = ReceiptItemDocument(receiptItemId: receiptItemId, companyId: companyId)
        
        try await ref.updateData([
            Receipt.CodingKeys.pdfUrlList.rawValue: FieldValue.arrayUnion([path])
        ])
    }
    
    func markChatAsRead(userId:String, chat: Chat) async throws {
        
        var array:[String] = chat.participantIds
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        
        try await chatRef.updateData([
            "userWhoHaveNotRead": FieldValue.arrayRemove([userId])
        ])
    }
    func markChatAsUnread(userId:String,chat:Chat) async throws {
        print("Trying to mark the chat as unread")
        var array:[String] = chat.participantIds
        
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        try await chatRef.updateData([
            "userWhoHaveNotRead" : FieldValue.arrayUnion(array)
        ])
    }
    func updateStore(companyId:String,store:Vender,name:String,streetAddress:String,city:String,state:String,zip:String) async throws {
        
        let ref = StoreCollection(companyId: companyId).document(store.id)
        try await ref.updateData([
            "address": [
                "streetAddress": streetAddress,
                "city": city,
                "state": state,
                "zip": zip
            ],
            "name":name
            
        ])
    }
    func updateCompanyImagePath(user:DBUser,companyId:String,path:String) async throws {
        let ref = CompanyDocument(companyId: companyId)
        
        try await ref.updateData([
            Company.CodingKeys.photoUrl.rawValue: path,
        ])
    }
    func updateRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }

    func updateServiceStop(companyId:String,user:DBUser,originalServiceStop:ServiceStop,newServiceStop:ServiceStop) async throws{
        
        //        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        
        var history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
        var historyArray:[String] = []
        var pushHistoryArray:[String] = []
        
        
        let historyText = ""
        var dateAndTech = ""
        var valueChange = ""
        var counter = 0
        //check if there was a chnage in tech
        if originalServiceStop.tech != newServiceStop.tech {
            counter = counter + 1
            dateAndTech = " ** " + (originalServiceStop.tech) + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.tech) + " --> " + (newServiceStop.tech ?? "") + " ** "
            historyArray.append(valueChange)
            
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            try await ref.updateData([
                "tech": newServiceStop.tech
            ])
        }
        if originalServiceStop.description != newServiceStop.description {
            
            counter = counter + 1
            print(counter)
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.description ) + " --> " + (newServiceStop.description ) + " ** "
            print(valueChange)
            historyArray.append(valueChange)
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            try await ref.updateData([
                "description": newServiceStop.description
            ])
        }
        
        if originalServiceStop.typeId != newServiceStop.typeId {
            
            counter = counter + 1
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.typeId ) + " --> " + (newServiceStop.typeId ) + " ** "
            print(valueChange)
            
            historyArray.append(valueChange)
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            try await ref.updateData([
                "typeId": newServiceStop.typeId
            ])
        }
        if originalServiceStop.operationStatus != newServiceStop.operationStatus {
            
            counter = counter + 1
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            print(valueChange)
            historyArray.append(valueChange)
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            try await ref.updateData([
                ServiceStop.CodingKeys.operationStatus.rawValue: newServiceStop.operationStatus
            ])
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
    }
 
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
    }

  
    
    
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        try await bodyOfWaterRef.updateData([
            "name":name
        ])
    }
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        try await bodyOfWaterRef.updateData([
            "gallons":gallons
        ])
    }
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "material":material
        ])
    }
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "notes":notes
        ])
    }
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "shape":shape
        ])
    }
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "length":length
        ])
    }
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "depth":depth
        ])
    }
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "width":width
        ])
    }
    
    func editBodyOfWater(companyId:String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        try await bodyOfWaterRef.updateData([
            "gallons":updatedBodyOfWater.gallons,
            "material":updatedBodyOfWater.material,
            "name":updatedBodyOfWater.name
        ])
    }
    
 
 
    
    
    func updatePurchaseItem(purchaseItem:PurchasedItem,companyId: String) async throws {
        
        // Add a new document in collection "cities"
        try await PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData([
            "workOrderId": "0"
        ])
    }
    func updateNotes(currentItem:PurchasedItem,notes:String,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        try await itemRef.updateData([
            "notes":notes
        ])
    }
    func updateBilling(currentItem:PurchasedItem,billingRate:Double,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        try await  itemRef.updateData([
            "billingRate":billingRate
        ])
    }
    func updatePurchasedItemBillingStatus(currentItem:PurchasedItem,newBillingStatus:Bool,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        // Set the "capital" field of the city 'DC'
        try await itemRef.updateData([
            "invoiced":newBillingStatus
            
        ])
    }
    func updatePurchasedCustomer(currentItem:PurchasedItem,newCustomer:Customer,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        let fullName = newCustomer.firstName + " " + newCustomer.lastName
        print(fullName)
        try await itemRef.updateData([
            "customerId":newCustomer.id,
            "customerName":fullName
            
        ])
    }
    func updatePurchasedWorkOrderId(currentItem:PurchasedItem,workOrderId:String,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        try await itemRef.updateData([
            "workOrderId":workOrderId
        ])
    }
    func updateCompanyUserFavorites(user:DBUser,updatingUser:DBUser,favorites:[String]) throws {
        //        let ref = userDocument(userId: updatingUser.id)
        //        //Change to Array Append
        //         ref.updateData([
        //            DBUser.CodingKeys.favorites.rawValue: favorites,
        //        ]) { err in
        //            if let err = err {
        //                print("Error updating document: \(err)")
        //            } else {
        //                print("Updated Tech Favorite List Successfully")
        //            }
        //        }
    }
    func updateUserImagePath(updatingUser:DBUser,path:String) async throws {
        let ref = userDocument(userId: updatingUser.id)
        
        try await ref.updateData([
            DBUser.CodingKeys.photoUrl.rawValue: path,
        ])
    }
    func updateUserRecentlySelectedCompany(user:DBUser,recentlySelectedCompanyId:String) async throws {
        let ref = userDocument(userId: user.id)
        
        try await ref.updateData([
            DBUser.CodingKeys.recentlySelectedCompany.rawValue: recentlySelectedCompanyId,
        ])
    }
    func updateToDoTitle(companyId:String,toDoId:String,newTitle:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "title": newTitle
            ])
    }
    func updateToDoStatus(companyId:String,toDoId:String,newStatus:toDoStatus) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "status": newStatus
            ])
    }
    func updateToDoDescription(companyId:String,toDoId:String,newDescription:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "description": newDescription
            ])
    }
    func updateToDoDateFinished(companyId:String,toDoId:String,newDateFinished:Date?) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "dateFinished": newDateFinished
            ])
    }
    func updateToDoCustomerId(companyId:String,toDoId:String,newCustomerId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "customerId": newCustomerId
            ])
    }
    func updateToDoJobId(companyId:String,toDoId:String,newJobId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "jobId": newJobId
            ])
    }
    func updateToDoTechId(companyId:String,toDoId:String,newTechId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "newTechId": newTechId
            ])
    }
}
