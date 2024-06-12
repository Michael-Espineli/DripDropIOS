//
//  TrainingManager.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 9/3/23.
//


import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
struct TrainingTemplate:Identifiable, Codable,Hashable{
    var id :String
    var name: String
    var description: String
    var workOrderIds: [String]

}

struct Training:Identifiable, Codable,Hashable{
    var id :String
    var templateId: String
    var name: String
    var dateReceived: Date
    var status: String //Finished, In Progress, Not Started
    var proficiency : String //In Training, Beginer, Intermediate, Advanced, Trainer
    var description: String
    var workOrderIds: [String]

}

final class TrainingManager {
    
    static let shared = TrainingManager()
    private init(){}
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Collections and Documents
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Training
    private func TrainingCollection(companyId:String,techId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/users/\(techId)/trainings")
    }
    private func TrainingDocument(trainingId:String,companyId:String,techId:String)-> DocumentReference{
        TrainingCollection(companyId: companyId,techId: techId).document(trainingId)
        
    }
    //Training Templates
    private func TrainingTemplateCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/settings/trainingTemplates/trainingTemplates")
    }
    private func TrainingTemplateDocument(trainingTemplateId:String,companyId:String)-> DocumentReference{
        TrainingTemplateCollection(companyId: companyId).document(trainingTemplateId)
        
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Uploading Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Getting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func getAllTrainings(companyId: String,techId:String) async throws -> [Training]{
        let trainings = try await TrainingCollection(companyId: companyId, techId: techId)
            .getDocuments(as:Training.self)
        print("got all trainings for \(techId)")
        print(trainings)
        return trainings
    }
    func getSingleTraining(companyId: String,trainingId:String,techId:String) async throws -> Training{
        return try await TrainingDocument(trainingId: trainingId, companyId: companyId, techId: techId)
            .getDocument(as: Training.self)
    }
    func getAllTrainingTemplates(companyId: String) async throws -> [TrainingTemplate]{
        return try await TrainingTemplateCollection(companyId: companyId)
            .getDocuments(as:TrainingTemplate.self)
    }
    func getSingleTrainingTemplate(companyId: String,trainingTemplateId:String) async throws -> TrainingTemplate{
        return try await TrainingTemplateDocument(trainingTemplateId: trainingTemplateId, companyId: companyId)
            .getDocument(as: TrainingTemplate.self)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

}
