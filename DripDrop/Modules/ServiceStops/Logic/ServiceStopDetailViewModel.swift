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
import FirebaseFunctions

struct EquipmentMeasurements:Identifiable, Codable,Equatable,Hashable{
    var id:String
    var equipmentId:String
    var date:Date
    var status:EquipmentStatus
    var poundForcePerSquareInch:Int?
    var revolutionsPerMinute: Int?
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
    @Published var serviceLocationStopData: [StopData] = []

    @Published private(set) var bodiesOfWater: [BodyOfWater] = []

    @Published private(set) var currentHistory: [StopData] = []
    @Published private(set) var listOfEquipment: [Equipment] = []
    @Published private(set) var selectedInputIdList: [String] = []
    
    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    
    @Published var taskList: [ServiceStopTask] = []
    
    @Published var loadedImages:[DripDropStoredImage] = []
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    
    @Published var currentWeather: Weather?

    
    func onInitalLoad(companyId:String,serviceStop:ServiceStop,userId:String) async throws {
        //Get ServiceLocation Info
        print("")
        print("  [ServiceStopDtailViewModel][onInitalLoad] Start ")

        self.loadedImages = serviceStop.photoUrls ?? []
        self.location = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceStop.serviceLocationId)
        
        //get Bodies Of Water
        let bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceStop.serviceLocationId)
        self.bodiesOfWater = bodiesOfWater
        print("  [ServiceStopDtailViewModel][onInitalLoad] Received \(bodiesOfWater.count) Bodies Of Water")
        guard let firstBOW = bodiesOfWater.first else {
            print("No Bodies of Water")
            throw FireBasePublish.unableToPublish
        }
        self.selectedBOW = firstBOW
        

        //Get Readings and Dosages DEVELOPER CONSIDER HAVE THIS GOTTEN ON FIRST LOAD of app
        self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
        self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
        
        var selectedInputIdList:[String] = []
        print("  [ServiceStopDtailViewModel][onInitalLoad] - Successfuly For \(self.readingTemplates.count) Readings and \(self.dosageTemplates.count) Dosages")
        for template in self.readingTemplates {
            selectedInputIdList.append(template.readingsTemplateId)
        }
        for template in self.dosageTemplates {
            selectedInputIdList.append(template.dosageTemplateId)
        }
        self.selectedInputIdList = selectedInputIdList


        
        //get Four Most Recent StopData
        self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: selectedBOW!.id , amount: 4)
        print("  [ServiceStopDtailViewModel][onInitalLoad] Current History \(currentHistory.count)")
        
        self.listOfEquipment = []
        dataService.addListenerForEquipmentByServiceLocation(
            companyId: companyId,
            locationId: serviceStop.serviceLocationId
        ) { [weak self] route in
            self?.listOfEquipment = route
        }
        
        //Maybe just get all stop data for service stop id and filter out by body of water id
        print("  [ServiceStopDetailView][onInitialLoad] Got Current Service Stop Data: \(String(describing: stopData?.serviceStopId))")
        self.serviceLocationStopData = try await dataService.getStopDataByServiceStopIdAndLocationId(companyId: companyId, serviceStopId: serviceStop.id,locationId: serviceStop.serviceLocationId)
        
        //Get Weather
        if let location {
            self.currentWeather = try await WeatherManager.shared.fetchWeather(address: location.address)
        }
        
        //Get Tasks
        let SSTasks = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
        if serviceStop.recurringServiceStopId != "" {
            print("")
            print("[ServiceStopDtailViewModel][onInitalLoad] serviceStop recurringServiceStopId Not Empty")
            let RSSTasks = try await dataService.getRecurringServiceStopTasks(companyId: companyId, recurringServiceStopId: serviceStop.recurringServiceStopId)
            
            var finalTasks:[ServiceStopTask] = []
            for rssTask in RSSTasks {
                if SSTasks.contains(where: {$0.recurringServiceStopTaskId == rssTask.id}) {
                        //This Service Stop Already Contains this task
                    if let task = SSTasks.first(where: {$0.recurringServiceStopTaskId == rssTask.id}) {
                        finalTasks.append(task)
                    }
                } else {
                        //This Service Stop Does not contain Task. Will Update Service Stop Task List To have recurring Service Stop Id
                    let task = ServiceStopTask(
                        name : rssTask.name,
                        type : rssTask.type,
                        status : .scheduled,
                        contractedRate : rssTask.contractedRate,
                        estimatedTime : rssTask.estimatedTime,
                        customerApproval : false,
                        actualTime : 0,
                        workerId : serviceStop.techId,
                        workerType : .employee,
                        workerName : serviceStop.tech,
                        laborContractId : "",
                        serviceStopId : IdInfo(id: "", internalId: ""),
                        jobId: IdInfo(id: "", internalId: ""),
                        recurringServiceStopId : IdInfo(id: serviceStop.recurringServiceStopId, internalId: ""),
                        jobTaskId : "",
                        recurringServiceStopTaskId : rssTask.id,
                        equipmentId : "",
                        serviceLocationId : "",
                        bodyOfWaterId : "",
                        shoppingListItemId : ""
                    )
                    finalTasks.append(task)
                        //Upload Task
                    try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: serviceStop.id, task: task)
                }
            }
            self.taskList = finalTasks
        } else {
            print("")
            print("[ServiceStopDtailViewModel][onInitalLoad] serviceStop recurringServiceStopId Empty")
            self.taskList = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
        }
        print("[ServiceStopDtailViewModel][onInitalLoad] got Tasks")
            
    }
    
    func finishServiceStop(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
    }
    
    func finishServiceStop(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus,activeRoute:ActiveRoute) async throws {
        //Finish Service Stop
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        //Change Active Route Count
        if operationStatus == .finished {
            let count = activeRoute.finishedStops + 1
            dataService.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        } else {
            let count = activeRoute.finishedStops + -1
            dataService.updateActiveRouteFinishedStop(companyId: companyId, activeRouteId: activeRoute.id, finishedStops: count)
        }
    }
    
    func onChangeOfBodyOfWater(bodyOfWater:BodyOfWater)async {
    }
    
    func updateServicestopOperationStatus(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        //Update Service Stop FB
        //Just update the current Service Stop but
        //let the function check if the service stop should be from another company
        //let the function finish the other service stop on the sender side
        print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus]")
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        try await dataService.updateServiceStopEndTime(companyId: companyId, serviceStopId: stop.id, endTime: Date())
        if operationStatus == .finished {
            try? await FunctionsManager.shared.sendServiceReportOnFinish(companyId: companyId, stopId: stop.id)
            print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Sending Email")
        } else {
            print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Service Stop Not Finished")
        }
    }
    
    func createEquipmentMeasurment(companyId:String,equipmentId:String,measurment:EquipmentMeasurements) async throws {
        try await dataService.createNewEquipmentMeasurements(companyId: companyId, equipmentId: equipmentId, equipmentMeasurement: measurment)
    }
    func updateEquipmentStatus(companyId:String,serviceStop:ServiceStop,equipmentId:String,status:EquipmentStatus) throws {
        if serviceStop.otherCompany {
            if let mainCompanyId = serviceStop.mainCompanyId {
                
                try dataService.updateEquipmentStatus(companyId: mainCompanyId, equipmentId: equipmentId, status: status)
            }
        } else {
            try  dataService.updateEquipmentStatus(companyId: companyId, equipmentId: equipmentId, status: status)
        }
    }
    func updateStopData(companyId:String,serviceStop:ServiceStop,stopData:StopData)async throws {
        //Update Local Dictionary
        if let bodyOfWater = self.selectedBOW {
            self.serviceLocationStopData.removeAll(where: {$0.bodyOfWaterId == stopData.bodyOfWaterId})
            self.serviceLocationStopData.append(stopData)
        }
        
        print("")
        print("    [ServiceStopDetailViewModel][updateStopData ] Updating Stop Data ")
        
        print("    [ServiceStopDetailViewModel][updateStopData ]Body Of Water Id: \(stopData.bodyOfWaterId), Service Stop Id: \(stopData.serviceStopId)")
        
        print("    [ServiceStopDetailViewModel][updateStopData ]Readings: \(stopData.readings.count)")
        
        for reading in stopData.readings {
            print(" - \(reading)")
        }
        
        print("    [ServiceStopDetailViewModel][updateStopData ]Dosages: \(stopData.dosages.count)")
        for dosage in stopData.dosages {
            print(" - \(dosage)")
        }
        
        print("    [ServiceStopDetailViewModel][updateStopData ]Observations: \(stopData.observation.count)")
        for dosage in stopData.observation {
            print(" - \(dosage)")
        }
        try await dataService.uploadStopData(companyId: companyId, stopData: stopData)
        print("    [ServiceStopDetailViewModel][updateStopData ]Finished Uploading Service Stop Data")
        
    }
    
    func getAllEquipmentFromBodyOfWater(companyId: String,bodyOfWater:BodyOfWater) async throws {
//        self.listOfEquipment = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    
    func updatePhotoUrl(companyId:String,serviceStopId:String) {
        let photosToUpload = selectedDripDropPhotos

        guard !photosToUpload.isEmpty else { return }

        Task {
            do {
                let uploadedImages = try await dataService.uploadServiceStopImages(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    images: photosToUpload
                )

                loadedImages.append(contentsOf: uploadedImages)

                try await dataService.updateServiceStopPhotoURLs(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    photoUrls: uploadedImages
                )

                selectedDripDropPhotos = []
            } catch {
                print("Photo upload failed:", error)
            }
        }
    }
}
