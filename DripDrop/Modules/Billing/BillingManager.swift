//
//  BillingManager.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/6/23.
//


import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


final class BillingManager {
    
    static let shared = BillingManager()
    private init(){}
    
    //Collections

    private func BillingTemplateCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/billing/billing")
    }
    //Documents
    
    private func BillingTemplateDocument(billingTemplateId:String,companyId:String)-> DocumentReference{
        BillingTemplateCollection(companyId: companyId).document(billingTemplateId)
    }
    
    //generic Functions
    func uploadBillingTemplate(billingTempalte : BillingTemplate,companyId:String) async throws {

        try BillingTemplateDocument(billingTemplateId: billingTempalte.id, companyId: companyId)
            .setData(from:billingTempalte, merge: false)
    }
    
    func getAllBillingTemplates(companyId:String) async throws -> [BillingTemplate]{

        return try await BillingTemplateCollection(companyId: companyId)
            .getDocuments(as:BillingTemplate.self)
    }
    func getDefaultBillingTempalte(companyId:String) async throws -> BillingTemplate{

        let templates = try await BillingTemplateCollection(companyId: companyId)
            .whereField("defaultSelected", isEqualTo: true)
            .getDocuments(as:BillingTemplate.self)
        return templates.first!
    }
    //start up functions

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
    
}
