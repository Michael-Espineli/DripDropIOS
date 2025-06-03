//
//  ProductionDataService+DeleteExtension.swift
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
    //                    Delete Functions
    //----------------------------------------------------


    func deleteTermsTemplate(companyId:String,termsTemplateId:String) async throws{
        try await termsTemplateDocument(companyId: companyId, templateId: termsTemplateId)
            .delete()
    }
    func deleteTerms(companyId:String,termsTemplateId:String,termsId:String) async throws{
        try await termsDocument(companyId: companyId, termsTempalteId: termsTemplateId, termsId: termsId)
            .delete()
    }


    

    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).delete()
        
    }


    
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws{
        
        let summaryList = try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .getDocuments(as:CustomerMonthlySummary.self)
        
        for summary in summaryList {
            print("Deleted \(summary)")
            try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(summary.id)
                .delete()
        }
    }
    
    
    func deleteCustomerContact(companyId:String,customerId:String,contactId:String)async throws {
        try await customerContactDocument(companyId: companyId, customerId: customerId, contactId: contactId)
            .delete()
        
    }
    func deleteToDo(companyId:String,toDoId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId).delete()
    }
}
