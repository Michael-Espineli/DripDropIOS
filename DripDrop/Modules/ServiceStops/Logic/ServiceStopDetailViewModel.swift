//
//  ServiceStopDetailViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/28/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Darwin
struct EquipmentMeasurements:Identifiable, Codable,Equatable,Hashable{
    var id:String
    var date:Date
    var status:EquipmentStatus
    var psi:Int?
}

@MainActor
final class ServiceStopDetailViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published var selectedBOW: BodyOfWater? = nil
    @Published var stopData: StopData? = nil
    @Published var location: ServiceLocation? = nil

    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var readingTemplates: [ReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [DosageTemplate] = []

    @Published private(set) var currentHistory: [StopData] = []
    @Published private(set) var listOfEquipment: [Equipment] = []
    @Published private(set) var selectedInputIdList: [String] = []

    @Published private(set) var currentStopData: [BodyOfWater:StopData] = [:]

    @Published private(set) var BOWHistoryDict: [BodyOfWater:[StopData]] = [:]
    @Published private(set) var BOWEquipmentDick: [BodyOfWater:[Equipment]] = [:]
    @Published var EquipmentReadings: [Equipment:EquipmentMeasurements] = [:]

    func onInitalLoad(companyId:String,serviceStop:ServiceStop,userId:String) async throws {
        //Get ServiceLocation Info
        self.location = try await dataService.getServiceLocationsCustomerAndLocationId(companyId: companyId, customerId: serviceStop.customerId, locationId: serviceStop.serviceLocationId)
        
        
        //Get Readings and Dosages DEVELOPER CONSIDER HAVE THIS GOTTEN ON FIRST LOAD
        self.readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        self.dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        var selectedInputIdList:[String] = []
        print("Successfuly For \(self.readingTemplates.count) Readings and \(self.dosageTemplates.count) Dosages")
        for template in self.readingTemplates {
            selectedInputIdList.append(template.id)
        }
        for template in self.dosageTemplates {
            selectedInputIdList.append(template.id)
        }
        self.selectedInputIdList = selectedInputIdList
        //get Bodies Of Water
        let bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceStop.serviceLocationId)
        self.bodiesOfWater = bodiesOfWater
        guard let firstBOW = bodiesOfWater.first else {
            print("No Bodies of Water")

            throw FireBasePublish.unableToPublish
        }
        print("Succesfully got bodies of water")

        self.selectedBOW = firstBOW

        //get Four Most Recent StopData
        self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: firstBOW.id , amount: 4)
       
         var BOWHistoryDict: [BodyOfWater:[StopData]] = [:]
        var BOWHEquipmentDict: [BodyOfWater:[Equipment]] = [:]

        for body in bodiesOfWater {
            let customerStopData = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: body.id , amount: 4)
            let listOfEquipment = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: body)
            BOWHEquipmentDict[body] = listOfEquipment
            BOWHistoryDict[body] = customerStopData
        }
        self.BOWEquipmentDick = BOWHEquipmentDict
        self.BOWHistoryDict = BOWHistoryDict
        
        self.listOfEquipment = BOWHEquipmentDict[firstBOW] ?? []
        //Initiliaze Stop Data
        var stopData:StopData? = nil
        let currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: companyId, serviceStopId: serviceStop.id,bodyOfWaterId: firstBOW.id)
        if let currentServiceStopData = currentServiceStopData.first {
            stopData = currentServiceStopData
        } else {
            stopData = StopData(
                id: UUID().uuidString,
                date: serviceStop.serviceDate ?? Date(),
                serviceStopId: serviceStop.id,
                readings: [],
                dosages: [],
                bodyOfWaterId: firstBOW.id,
                customerId: serviceStop.customerId,
                serviceLocationId: serviceStop.serviceLocationId,
                userId: userId
            )
        }
        print("got Current Service Stop Data >>\(stopData?.serviceStopId)")

        self.stopData = stopData
        var currentStopDataDict: [BodyOfWater:StopData] = [:]
        for body in bodiesOfWater {
            var currentStopData1:StopData? = nil

            let currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: companyId, serviceStopId:  serviceStop.id,bodyOfWaterId: body.id)
            print("Got \(currentServiceStopData.count) stop Data for BOW Id : \(body.id) ")
            if let currentServiceStopData1 = currentServiceStopData.first {
                currentStopData1 = currentServiceStopData1
            } else {
                currentStopData1 = StopData(
                    id: UUID().uuidString,
                    date: serviceStop.serviceDate ?? Date(),
                    serviceStopId: serviceStop.id,
                    readings: [],
                    dosages: [],
                    bodyOfWaterId: body.id,
                    customerId: serviceStop.customerId,
                    serviceLocationId: serviceStop.serviceLocationId,
                    userId: userId
                )
                //Maybe Post Stop Data
            }
            currentStopDataDict[body] = currentStopData1
        }
        self.currentStopData = currentStopDataDict

    }
    func finishServiceStop(companyId:String,stop:ServiceStop,finish:Bool) async throws {
        //Finish Service Stop
        try await dataService.updateServiceStopFinish(companyId: companyId, serviceStop: stop, finished: finish)

    }
    func finishServiceStop(companyId:String,stop:ServiceStop,finish:Bool,activeRoute:ActiveRoute) async throws {
        //Finish Service Stop
        try await dataService.updateServiceStopFinish(companyId: companyId, serviceStop: stop, finished: finish)
        //Change Active Route Count
        if finish {
            let count = activeRoute.finishedStops + 1
            RouteManager.shared.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        } else {
            let count = activeRoute.finishedStops + -1
            RouteManager.shared.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        }
    }
    func onChangeOfBodyOfWater(bodyOfWater:BodyOfWater)async {
        stopData = currentStopData[bodyOfWater]
        print(" - Body Of Water Stop Data on Change \(stopData)")
        currentHistory = BOWHistoryDict[bodyOfWater] ?? []
        print(" - Body Of Water History on Change \(currentHistory)")
        listOfEquipment = BOWEquipmentDick[bodyOfWater] ?? []
        print(" - Body Of Water History on Change \(BOWEquipmentDick)")

    }
    
    func skipServiceStop(companyId:String,stop:ServiceStop,skip:Bool) async throws {
        try ServiceStopManager.shared.updateServiceStopSkipped(companyId: companyId, serviceStop: stop, skipped: skip)
    }
    func createEquipmentMeasurment(companyId:String,equipmentId:String,measurment:EquipmentMeasurements) async throws {
        try await dataService.createNewEquipmentMeasurements(companyId: companyId, equipmentId: equipmentId, equipmentMeasurement: measurment)
    }
    func updateStopData(companyId:String,stopData:StopData)async throws {
        //Update Local Dictionary
        if let bodyOfWater = self.selectedBOW {
            self.currentStopData[bodyOfWater] = stopData
        }
        //Publish
//        if stopData.readings.count == 0 || stopData.dosages.count == 0 {
//            throw FireBasePublish.unableToPublish
//        }
        print("")
        print("Updating Stop Data")
        
        print("bodyOfWaterId >> \(stopData.bodyOfWaterId) serviceStopId >> \(stopData.serviceStopId)")
        
        print("Readings")
        
        for reading in stopData.readings {
            print(" - \(reading)")
        }
        
        print("Dosages")
        for dosage in stopData.dosages {
            print(" - \(dosage)")
        }
        
        print("")

        try await dataService.uploadStopData(companyId: companyId, stopData: stopData)
    }
    func getAllEquipmentFromBodyOfWater(companyId: String,bodyOfWater:BodyOfWater) async throws {
        
        self.listOfEquipment = try await EquipmentManager.shared.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
    }
}
