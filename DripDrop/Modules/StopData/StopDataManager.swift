//
//  StopDataManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/13/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


struct StopData:Identifiable, Codable,Equatable{
    var id: String
    var date: Date
    var serviceStopId: String
    var readings: [Reading]
    var dosages: [Dosage]
    var observation: [String]
    var bodyOfWaterId: String
    var customerId: String
    var serviceLocationId: String
    var userId: String
    var equipmentMeasurements: [EquipmentMeasurements]
}

protocol StopDataManagerProtocol {
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadStopData(companyId:String,stopData:StopData) throws
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws->[StopData]
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]
}

final class MockStopDataManager:StopDataManagerProtocol {
    
    let mockStopData:[StopData] = [
        StopData(id: "1", date: Date(), serviceStopId: "1",
                 readings: [
                    Reading(id: "1", templateId: "1",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "1")
                 ],
                 dosages: [
                    Dosage(id: "1", templateId: "1",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "1", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "1")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "2", date: Date(), serviceStopId: "2",
                 readings: [
                    Reading(id: "2", templateId: "2",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "2")
                 ],
                 dosages: [
                    Dosage(id: "2", templateId: "2",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "2", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "2")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "3", date: Date(), serviceStopId: "3",
                 readings: [
                    Reading(id: "3", templateId: "3",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "3")
                 ],
                 dosages: [
                    Dosage(id: "3", templateId: "3",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "3", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "3")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(
            id: "4",
            date: Date(),
            serviceStopId: "4",
             readings: [
                Reading(id: "4", templateId: "4",
                        universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "4")
             ],
             dosages: [
                Dosage(id: "4", templateId: "4",
                       universalTemplateId: "dev_id_in_need_of_a_real_one", name: "4", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "4")
             ],
             observation: [
             ],
             bodyOfWaterId: "1",
             customerId: "1",
             serviceLocationId:"1",
             userId: "",
             equipmentMeasurements: []
             
            ),
        StopData(
            id: "5",
            date: Date(),
            serviceStopId: "5",
                 readings: [
                    Reading(id: "5", templateId: "5",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "5")
                 ],
                 dosages: [
                    Dosage(id: "5", templateId: "5",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "5", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "5")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
            equipmentMeasurements: []
                 
                ),
        StopData(id: "6", date: Date(), serviceStopId: "6",
                 readings: [
                    Reading(id: "6", templateId: "6",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "6")
                 ],
                 dosages: [
                    Dosage(id: "6", templateId: "6",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "6", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "6")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "7", date: Date(), serviceStopId: "7",
                 readings: [
                    Reading(id: "7", templateId: "7",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "7")
                 ],
                 dosages: [
                    Dosage(id: "7", templateId: "7",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "7", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "7")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "8", date: Date(), serviceStopId: "8",
                 readings: [
                    Reading(id: "8", templateId: "8",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "8")
                 ],
                 dosages: [
                    Dosage(id: "8", templateId: "8",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "8", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "8")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "9", date: Date(), serviceStopId: "9",
                 readings: [
                    Reading(id: "9", templateId: "9",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "9")
                 ],
                 dosages: [
                    Dosage(id: "9", templateId: "9",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "9", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "9")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "10", date: Date(), serviceStopId: "10",
                 readings: [
                    Reading(id: "10", templateId: "10",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "10")
                 ],
                 dosages: [
                    Dosage(id: "10", templateId: "10",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "10", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "10")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "11", date: Date(), serviceStopId: "11",
                 readings: [
                    Reading(id: "11", templateId: "11",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "11")
                 ],
                 dosages: [
                    Dosage(id: "11", templateId: "11",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "11", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "11")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "12", date: Date(), serviceStopId: "12",
                 readings: [
                    Reading(id: "12", templateId: "12",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "12")
                 ],
                 dosages: [
                    Dosage(id: "12", templateId: "12",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "12", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "12")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                 
                ),
        StopData(id: "13", date: Date(), serviceStopId: "13",
                 readings: [
                    Reading(id: "13", templateId: "13",
                            universalTemplateId: "dev_id_in_need_of_a_real_one", dosageType: "", name: "", amount: "", UOM: "", bodyOfWaterId: "13")
                 ],
                 dosages: [
                    Dosage(id: "13", templateId: "13",
                           universalTemplateId: "dev_id_in_need_of_a_real_one", name: "13", amount: "", UOM: "", rate: "", linkedItem: "", bodyOfWaterId: "13")
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "1",
                 customerId: "1",
                 serviceLocationId:"1",
                 userId: "",
                 equipmentMeasurements: []
                )
        
    ]
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadStopData(companyId:String,stopData:StopData) throws {
        print("Successfully Uploaded")
    }
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]{
        return []
    }
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]{
        return []
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]{
        var stopDataList:[StopData] = []
        for stopData in mockStopData {
            if stopData.bodyOfWaterId == bodyOfWaterId {
                stopDataList.append(stopData)
            }
        }
        return stopDataList
    }
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws->[StopData]{
        var stopDataList:[StopData] = []
        for stopData in mockStopData {
            if stopData.serviceStopId == serviceStopId {
                stopDataList.append(stopData)
            }
        }
        return stopDataList
    }
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]{
        print("Getting Stop Data for \(serviceStopId)")
        return []
    }
}

final class StopDataManager:StopDataManagerProtocol {
    
    static let shared = StopDataManager()
    init(){}
    private let db = Firestore.firestore()
    private func stopDataCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/stopData")
    }
    
    private func stopDataDocument(companyId:String,stopDataId:String)-> DocumentReference{
        
        stopDataCollection(companyId: companyId).document(stopDataId)
        
    }
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadStopData(companyId:String,stopData:StopData) throws {
        try stopDataDocument(companyId: companyId,stopDataId: stopData.id)
            .setData(from:stopData, merge: true)
        
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]{
        print("Getting All Stop Data")
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .whereField("date", isLessThan: Date())
            .order(by: "date", descending: true)
            .limit(to: amount)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws->[StopData]{
        print("Getting Stop Data for \(serviceStopId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
        
            .order(by: "date", descending: true)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]{
        print("Getting Stop Data for >> \(serviceStopId) and Body Of Water >> \(bodyOfWaterId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByDateRange(companyId:String,startDate: Date,endDate:Date)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
}
