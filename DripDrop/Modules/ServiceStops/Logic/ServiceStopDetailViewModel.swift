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
    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []

    @Published private(set) var currentHistory: [StopData] = []
    @Published private(set) var listOfEquipment: [Equipment] = []
    @Published private(set) var selectedInputIdList: [String] = []

    @Published private(set) var currentStopData: [BodyOfWater:StopData] = [:]

    @Published private(set) var BOWHistoryDict: [BodyOfWater:[StopData]] = [:]
    @Published private(set) var BOWEquipmentDick: [BodyOfWater:[Equipment]] = [:]
    @Published var EquipmentReadings: [Equipment:EquipmentMeasurements] = [:]
    
    @Published var taskList: [ServiceStopTask] = []
    
    @Published var loadedImages:[DripDropStoredImage] = []
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    
    @Published var currentWeather: Weather?

    
    func onInitalLoad(companyId:String,serviceStop:ServiceStop,userId:String) async throws {
        //Get ServiceLocation Info
        print("")
        print("onInitalLoad - [ServiceStopDtailViewModel]")

        self.loadedImages = serviceStop.photoUrls ?? []
        print(" - Getting Service Location Info and Bodies Of Water")

        if serviceStop.otherCompany {
            print(" - Other Company True")
            if let mainCompanyId = serviceStop.mainCompanyId {
                print(" - Using Main Company Id")
                self.location = try? await dataService.getServiceLocationById(companyId: mainCompanyId, locationId: serviceStop.serviceLocationId)
                //get Bodies Of Water
                print("Location 1")
                let bodiesOfWater = try? await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: mainCompanyId, serviceLocationId: serviceStop.serviceLocationId)
                
                print("BOW 1")
                self.bodiesOfWater = bodiesOfWater ?? []
                guard let bodiesOfWater, let firstBOW = bodiesOfWater.first else {
                    print("No Bodies of Water")
                    throw FireBasePublish.unableToPublish
                }
                self.selectedBOW = firstBOW
                
                print(" - Got Service Location  and bodies of waterInfo - Successful")
                //Get Readings and Dosages DEVELOPER CONSIDER HAVE THIS GOTTEN ON FIRST LOAD of app
                self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: mainCompanyId)
                self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: mainCompanyId)
                
                var selectedInputIdList:[String] = []
                print(" - Successfuly For \(self.readingTemplates.count) Readings and \(self.dosageTemplates.count) Dosages")
                for template in self.readingTemplates {
                    selectedInputIdList.append(template.readingsTemplateId)
                }
                for template in self.dosageTemplates {
                    selectedInputIdList.append(template.dosageTemplateId)
                }
                self.selectedInputIdList = selectedInputIdList
                
                //get Four Most Recent StopData
                self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: mainCompanyId, bodyOfWaterId: selectedBOW!.id , amount: 4)
                print("---  Current History  --- \(currentHistory.count)")
                for history in currentHistory {
                    print("--- Readings ---")

                    print(history.readings)
                    
                    print("---Dosages ---")

                    print(history.dosages)
                }
                var BOWHistoryDict: [BodyOfWater:[StopData]] = [:]
                var BOWHEquipmentDict: [BodyOfWater:[Equipment]] = [:]
                print("-")
                for body in bodiesOfWater {
                    print(" - Body Of Water: \(body)")
                    let customerStopData = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: mainCompanyId, bodyOfWaterId: body.id , amount: 4)
                    let listOfEquipment = try? await dataService.getEquipmentByBodyOfWater(companyId: mainCompanyId, bodyOfWater: body)
                    print(" - List Of Equipment: \(listOfEquipment?.count)")
                    BOWHEquipmentDict[body] = listOfEquipment
                    BOWHistoryDict[body] = customerStopData
                }
                
                print("-")
                print("BOWHEquipmentDict: \(BOWHEquipmentDict)")
                self.BOWEquipmentDick = BOWHEquipmentDict
                self.BOWHistoryDict = BOWHistoryDict
                
                print("-")
                self.listOfEquipment = BOWHEquipmentDict[firstBOW] ?? []
                print("List Of Equipment: \(listOfEquipment)")
                print("-")
                //Initiliaze Stop Data
                var stopData:StopData? = nil
                let currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: mainCompanyId, serviceStopId: serviceStop.id,bodyOfWaterId: firstBOW.id)
                if let currentServiceStopData = currentServiceStopData.first {
                    stopData = currentServiceStopData
                } else {
                    stopData = StopData(
                        id: UUID().uuidString,
                        date: serviceStop.serviceDate,
                        serviceStopId: serviceStop.id,
                        readings: [],
                        dosages: [],
                        observation: [],
                        bodyOfWaterId: selectedBOW!.id,
                        customerId: serviceStop.customerId,
                        serviceLocationId: serviceStop.serviceLocationId,
                        userId: userId
                    )
                }
                print("Got Current Service Stop Data: \(String(describing: stopData?.serviceStopId))")

                self.stopData = stopData
                var currentStopDataDict: [BodyOfWater:StopData] = [:]
                for body in bodiesOfWater {
                    var currentStopData1:StopData? = nil

                    let currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: mainCompanyId, serviceStopId:  serviceStop.id,bodyOfWaterId: body.id)
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
                            observation: [],
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
        } else {
            print("Not Other Company")
            self.location = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceStop.serviceLocationId)
            //get Bodies Of Water
            print("Location 2")

            let bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceStop.serviceLocationId)
            print("BOW 2")
            self.bodiesOfWater = bodiesOfWater
            guard let firstBOW = bodiesOfWater.first else {
                print("No Bodies of Water")
                throw FireBasePublish.unableToPublish
            }
            self.selectedBOW = firstBOW
            
            print(" - Got Service Location  and bodies of waterInfo - Successful")
            //Get Readings and Dosages DEVELOPER CONSIDER HAVE THIS GOTTEN ON FIRST LOAD of app
            self.readingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
            self.dosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
            
            var selectedInputIdList:[String] = []
            print(" - Successfuly For \(self.readingTemplates.count) Readings and \(self.dosageTemplates.count) Dosages")
            for template in self.readingTemplates {
                selectedInputIdList.append(template.readingsTemplateId)
            }
            for template in self.dosageTemplates {
                selectedInputIdList.append(template.dosageTemplateId)
            }
            self.selectedInputIdList = selectedInputIdList


            
            //get Four Most Recent StopData
            self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(companyId: companyId, bodyOfWaterId: selectedBOW!.id , amount: 4)
            print("--- Current History  --- \(currentHistory.count)")
            for history in currentHistory {
                print("--- Readings ---")

                print(history.readings)
                
                print("--- Dosages ---")

                print(history.dosages)
            }
            print("-------")
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
            
            self.listOfEquipment = BOWHEquipmentDict[selectedBOW!] ?? []
            
            //Initiliaze Stop Data
            var stopData:StopData? = nil
            let currentServiceStopData = try await dataService.getStopDataByServiceStopIdAndBodyOfWaterId(companyId: companyId, serviceStopId: serviceStop.id,bodyOfWaterId: selectedBOW!.id)
            if let currentServiceStopData = currentServiceStopData.first {
                stopData = currentServiceStopData
            } else {
                stopData = StopData(
                    id: UUID().uuidString,
                    date: serviceStop.serviceDate ?? Date(),
                    serviceStopId: serviceStop.id,
                    readings: [],
                    dosages: [],
                    observation: [],
                    bodyOfWaterId: selectedBOW!.id,
                    customerId: serviceStop.customerId,
                    serviceLocationId: serviceStop.serviceLocationId,
                    userId: userId
                )
            }
            print("Got Current Service Stop Data: \(String(describing: stopData?.serviceStopId))")

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
                        observation: [],
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
        //Get Weather
        if let location {
            self.currentWeather = try await WeatherManager.shared.fetchWeather(address: location.address)
        }
            //Get Tasks
            let SSTasks = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
            if serviceStop.recurringServiceStopId != "" {
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
                self.taskList = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
            }
            print(" - got Tasks - ")
            

    }
    
    func finishServiceStop(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: stop, operationStatus: operationStatus)
    }
    
    func finishServiceStop(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus,activeRoute:ActiveRoute) async throws {
        //Finish Service Stop
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: stop, operationStatus: operationStatus)
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
        stopData = currentStopData[bodyOfWater]
        print(" - Body Of Water Stop Data on Change \(stopData)")
        currentHistory = BOWHistoryDict[bodyOfWater] ?? []
        print(" - Body Of Water History on Change \(currentHistory)")
        listOfEquipment = BOWEquipmentDick[bodyOfWater] ?? []
        print(" - Body Of Water History on Change \(BOWEquipmentDick)")

    }
    
    func updateServicestopOperationStatus(companyId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        //Update Service Stop FB
        //Just update the current Service Stop but
        //let the function check if the service stop should be from another company
        //let the function finish the other service stop on the sender side
        print("updateServicestopOperationStatus - [ServiceStopDetailViewModel]")
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStop: stop, operationStatus: operationStatus)

        if operationStatus == .finished {
 
            print("Sending Email")
            let data = [
                "companyId":companyId,
                "serviceStopId":stop.id,
            ]
            let result = try await Functions.functions().httpsCallable("sendServiceReportOnFinish").call(data)
            guard let json = result.data as? [String: Any] else {
                print("json")
                throw FireBaseRead.unableToRead
            }
            print(json)
            
        } else {
            print("Service Stop Not Finished")
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
        if serviceStop.otherCompany {
            print(" - Other Company True")
            // Gets Stop Data Based on the sender company and not by the local company
            if let mainCompanyId = serviceStop.mainCompanyId {
                if let bodyOfWater = self.selectedBOW {
                    self.currentStopData[bodyOfWater] = stopData
                }
                
                print("")
                print("Updating Stop Data - [ServiceStopDetailViewModel]")
                
                print("Body Of Water Id: \(stopData.bodyOfWaterId), Service Stop Id: \(stopData.serviceStopId)")
                
                print("Readings: \(stopData.readings.count)")
                
                for reading in stopData.readings {
                    print(" - \(reading)")
                }
                
                print("Dosages: \(stopData.dosages.count)")
                for dosage in stopData.dosages {
                    print(" - \(dosage)")
                }
                
                print("Observations: \(stopData.observation.count)")
                for dosage in stopData.observation {
                    print(" - \(dosage)")
                }
                try await dataService.uploadStopData(companyId: companyId, stopData: stopData)
                print("Finished Uploading Service Stop Data")
                print("----------------------------------")
            }
        } else {
            if let bodyOfWater = self.selectedBOW {
                self.currentStopData[bodyOfWater] = stopData
            }
            
            print("")
            print("Updating Stop Data - [ServiceStopDetailViewModel]")
            
            print("Body Of Water Id: \(stopData.bodyOfWaterId), Service Stop Id: \(stopData.serviceStopId)")
            
            print("Readings: \(stopData.readings.count)")
            
            for reading in stopData.readings {
                print(" - \(reading)")
            }
            
            print("Dosages: \(stopData.dosages.count)")
            for dosage in stopData.dosages {
                print(" - \(dosage)")
            }
            
            print("Observations: \(stopData.observation.count)")
            for dosage in stopData.observation {
                print(" - \(dosage)")
            }
            try await dataService.uploadStopData(companyId: companyId, stopData: stopData)
            print("Finished Uploading Service Stop Data")
            print("----------------------------------")
        }
    }
    
    func getAllEquipmentFromBodyOfWater(companyId: String,bodyOfWater:BodyOfWater) async throws {
        self.listOfEquipment = BOWEquipmentDick[bodyOfWater] ?? []
//        self.listOfEquipment = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    
    func updatePhotoUrl(companyId:String,serviceStopId:String) {
        Task{
            do {
                var uploadedImages : [DripDropStoredImage] = []
                for photo in selectedDripDropPhotos {
                    let (path,name) = try await dataService.uploadServiceStopImage(companyId: companyId, serviceStopId: serviceStopId, image: photo)
                    let storedImage = DripDropStoredImage(
                        id: UUID().uuidString,
                        description: name,
                        imageURL: path
                    )
                    uploadedImages.append(storedImage)
                    self.loadedImages.append(storedImage)
                    
                }
                try await dataService.updateServiceStopPhotoURLs(companyId: companyId, serviceStopId: serviceStopId, photoUrls: uploadedImages)
                self.selectedDripDropPhotos = []
            } catch {
                print(error)
            }
        }
    }
}
