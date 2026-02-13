//
//  Settings+DataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/31/26.
//

import Foundation
extension ProductionDataService {
    private func ReadingsTemplateDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/readings/readings/").document(readingTemplateId)
        
    }
    func TaskGroupCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/taskGroup/taskGroup")
    }
    func updateSavedReadingAmount(companyId:String, readingTemplateId:String,newArray:[String]) {
        
    }
    func updateSavedDosageAmount(companyId:String, dosageTemplateId:String,newArray:[String]) {
        
    }
}
