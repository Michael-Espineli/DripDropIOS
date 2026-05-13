//
//  Settings+DataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/31/26.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Firebase
import Darwin
extension ProductionDataService {
//    func ReadingsTemplateDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
//        ReadingsCollection(companyId: companyId).document(readingTemplateId)
//    }
//    func DosageTemplateDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
//        DosageCollection(companyId: companyId).document(dosageTemplateId)
//    }
    func updateSavedReadingAmount(companyId:String, readingTemplateId:String,newArray:[String]) async throws {
        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId,companyId: companyId)
            .updateData([
                "amount":newArray
                        ])
    }
    func updateSavedDosageAmount(companyId:String, dosageTemplateId:String,newArray:[String]) async throws {
        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId)
            .updateData([
                "amount":newArray
                        ])
    }
}
