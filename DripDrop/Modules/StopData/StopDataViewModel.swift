//
//  StopDataViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/13/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Darwin

@MainActor
final class StopDataViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published private(set) var readingHistory: [StopData] = []
    @Published private(set) var currentServiceStopData: [StopData] = []

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Mock Data
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var mockChemicalData:[StopData] =  [
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                 ],
                 dosages: [
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "bodyOfWater",
                customerId: "",
                serviceLocationId: "",
                 userId: ""),
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                 ],
                 dosages: [
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                 ],
                 dosages: [
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
        StopData(id: UUID().uuidString,
                 date: Calendar.current.date(byAdding: .day, value: -28, to: Date())!,
                 serviceStopId: "serviceStop",
                 readings: [
                 ],
                 dosages: [
                 ],
                 observation: [
                 ],
                 bodyOfWaterId: "bodyOfWater",
                 customerId: "",
                 serviceLocationId: "",
                 userId: ""),
        
    ]
    //Create
    func uploadStopData(companyId:String,stopData:StopData) async throws {
        try await dataService.uploadStopData(companyId: companyId, stopData: stopData)
    }
    //READ
    func getFourMostRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws{
        print("Trying to get four most recent Stop Data By Body Of Water Id \(bodyOfWaterId)")
        let customerStopData = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: bodyOfWaterId, amount: 4)
        self.readingHistory = customerStopData
        
    }
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws{
        let customerStopData = try await dataService.getStopDataByServiceStopId(companyId: companyId, serviceStopId: serviceStopId)
        print("Customer Stop Data Received >> \(customerStopData.count)")
        self.currentServiceStopData = customerStopData
    }
    func getStopDataByServiceStopIdAndBodyOfWater(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws{
        self.currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: companyId, serviceStopId: serviceStopId,bodyOfWaterId: bodyOfWaterId)
    }
    
    func getStopDataByCustomer(companyId:String,customerId: String)async throws{
        let customerStopData = try await dataService.getStopDataByCustomer(companyId: companyId, customerId: customerId)
        print("Stop Data By Customer >> \(customerId)")
        self.readingHistory = customerStopData
    }
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws{
        self.readingHistory = try await dataService.getStopDataByBodyOfWater(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
        print("Stop Data By Body Of Water >> \(bodyOfWaterId)")
    }
}
