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
    private let payrollCoordinator: ServiceStopPayrollCompletionCoordinator


    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
        self.payrollCoordinator = ServiceStopPayrollCompletionCoordinator(
            dataService: dataService
        )
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Payroll
    @Published var isFinishing: Bool = false
    @Published var generatedPayLines: [TechnicianPayLineItem] = []
    @Published var errorMessage: String?
// Normal
    
    @Published var selectedBOW: BodyOfWater? = nil
    @Published var stopData: StopData? = nil
    @Published var location: ServiceLocation? = nil
    @Published var serviceLocationStopData: [StopData] = []

    @Published private(set) var bodiesOfWater: [BodyOfWater] = []

    @Published private(set) var currentHistory: [StopData] = []
    @Published private(set) var listOfEquipment: [Equipment] = []
    @Published private(set) var selectedInputIdList: [String] = []
    @Published private(set) var companyUsers: [CompanyUser] = []
    
    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    
    @Published var taskList: [ServiceStopTask] = []
    
    @Published var loadedImages:[DripDropStoredImage] = []
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published private(set) var isUploadingPhotos: Bool = false
    
    @Published var currentWeather: Weather?

    
    func onInitalLoad(companyId:String,serviceStop:ServiceStop,userId:String) async throws {
        //Get ServiceLocation Info
        print("")
        print("  [ServiceStopDtailViewModel][onInitalLoad] Start ")

        self.loadedImages = serviceStop.photoUrls ?? []
        self.location = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceStop.serviceLocationId)
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(
            companyId: companyId,
            status: CompanyUserStatus.active.rawValue
        )
        
        //get Bodies Of Water
        let bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceStop.serviceLocationId)
        self.bodiesOfWater = bodiesOfWater
        print("  [ServiceStopDtailViewModel][onInitalLoad] Received \(bodiesOfWater.count) Bodies Of Water")
        if let firstBOW = bodiesOfWater.first {
            self.selectedBOW = firstBOW
            self.currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(
                companyId: companyId,
                bodyOfWaterId: firstBOW.id,
                amount: 4
            )
        } else {
            print("No Bodies of Water")
            self.selectedBOW = nil
            self.currentHistory = []
        }
        

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
//        if let location {
//            self.currentWeather = try await WeatherManager.shared.fetchWeather(address: location.address)
//        }
        print("  [ServiceStopDetailView][onInitialLoad] Get Tasks")
        //Get Tasks
        let SSTasks = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
        
        self.taskList = SSTasks
        print("  [ServiceStopDetailView][onInitialLoad] got \(taskList.count) tasks")
//        if serviceStop.recurringServiceStopId != "" {
//            print("")
//            print("[ServiceStopDtailViewModel][onInitalLoad] serviceStop recurringServiceStopId Not Empty")
//            let RSSTasks = try await dataService.getRecurringServiceStopTasks(companyId: companyId, recurringServiceStopId: serviceStop.recurringServiceStopId)
//            
//            var finalTasks:[ServiceStopTask] = []
//            for rssTask in RSSTasks {
//                if SSTasks.contains(where: {$0.recurringServiceStopTaskId == rssTask.id}) {
//                        //This Service Stop Already Contains this task
//                    if let task = SSTasks.first(where: {$0.recurringServiceStopTaskId == rssTask.id}) {
//                        finalTasks.append(task)
//                    }
//                } else {
//                        //This Service Stop Does not contain Task. Will Update Service Stop Task List To have recurring Service Stop Id
//                    let task = ServiceStopTask(
//                        name : rssTask.name,
//                        type : rssTask.type,
//                        status : .scheduled,
//                        contractedRate : rssTask.contractedRate,
//                        estimatedTime : rssTask.estimatedTime,
//                        customerApproval : false,
//                        actualTime : 0,
//                        workerId : serviceStop.techId,
//                        workerType : .employee,
//                        workerName : serviceStop.tech,
//                        laborContractId : "",
//                        serviceStopId : IdInfo(id: "", internalId: ""),
//                        jobId: IdInfo(id: "", internalId: ""),
//                        recurringServiceStopId : IdInfo(id: serviceStop.recurringServiceStopId, internalId: ""),
//                        jobTaskId : "",
//                        recurringServiceStopTaskId : rssTask.id,
//                        equipmentId : "",
//                        serviceLocationId : "",
//                        bodyOfWaterId : "",
//                        shoppingListItemId : ""
//                    )
//                    finalTasks.append(task)
//                        //Upload Task
//                    try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: serviceStop.id, task: task)
//                }
//            }
//            self.taskList = finalTasks
//        } else {
//            print("")
//            print("[ServiceStopDtailViewModel][onInitalLoad] serviceStop recurringServiceStopId Empty")
//            self.taskList = try await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: serviceStop.id)
//        }
        print("[ServiceStopDtailViewModel][onInitalLoad] got Tasks")
            
    }
    
    func finishServiceStop(companyId:String,currentUserId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        print("  [ServiceStopDetailViewModel][finishServiceStop] - Finishing Service Stop 1")
        let oldStop = stop

        var updatedStop = stop
        updatedStop.operationStatus = .finished
        // 1. Update the service stop operation status in your backend.
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)

        // 2. Then update payroll based on the transition.
        let payrollCoordinator = ServiceStopPayrollCompletionCoordinator(
            dataService: dataService
        )

        let payrollResult = try await payrollCoordinator.handleServiceStopStatusChange(
            oldStop: oldStop,
            newStop: updatedStop,
            changedByUserId: currentUserId
        )

        if payrollResult.didGeneratePay {
            print("Generated \(payrollResult.generatedLineItems.count) payroll line item(s).")
        }

        if payrollResult.didVoidPay {
            print("Voided \(payrollResult.voidedLineItems.count) payroll line item(s).")
        }

        if payrollResult.hasLockedItems {
            print("\(payrollResult.lockedLineItems.count) approved/paid payroll item(s) need admin review.")
        }
    }
    
    func finishServiceStop(companyId:String,currentUserId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus,activeRoute:ActiveRoute) async throws {
        print("  [ServiceStopDetailViewModel][finishServiceStop] - Finishing Service Stop 2")
        
        let oldStop = stop

        var updatedStop = stop
        updatedStop.operationStatus = .finished
        
        // 1. Update the service stop operation status in your backend.

        //Finish Service Stop
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        _ = try? await dataService.syncActiveRouteForServiceStops(
            companyId: companyId,
            date: stop.serviceDate,
            techId: stop.techId,
            techName: stop.tech
        )

        // 2. Then update payroll based on the transition.
        let payrollCoordinator = ServiceStopPayrollCompletionCoordinator(
            dataService: dataService
        )

        let payrollResult = try await payrollCoordinator.handleServiceStopStatusChange(
            oldStop: oldStop,
            newStop: updatedStop,
            changedByUserId: currentUserId
        )

        if payrollResult.didGeneratePay {
            print("Generated \(payrollResult.generatedLineItems.count) payroll line item(s).")
        }

        if payrollResult.didVoidPay {
            print("Voided \(payrollResult.voidedLineItems.count) payroll line item(s).")
        }

        if payrollResult.hasLockedItems {
            print("\(payrollResult.lockedLineItems.count) approved/paid payroll item(s) need admin review.")
        }
    }
    
    func onChangeOfBodyOfWater(bodyOfWater:BodyOfWater)async {
    }
    
    func updateServicestopOperationStatus(companyId:String,currentUserId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        let oldStop = stop
        let completionSettings = await loadCompletionSettings(companyId: companyId, stop: stop)

        var updatedStop = stop
        updatedStop.operationStatus = operationStatus
        // 1. Update the service stop operation status in your backend.

        //Update Service Stop FB
        //Just update the current Service Stop but
        //let the function check if the service stop should be from another company
        //let the function finish the other service stop on the sender side
        if operationStatus == .finished {
            try await uploadPendingPhotosIfNeeded(companyId: companyId, serviceStopId: stop.id)

            let hasUploadedPhoto = !loadedImages.isEmpty || !(stop.photoUrls ?? []).isEmpty
            if completionSettings.requirePhotoOnFinish && !hasUploadedPhoto {
                throw NSError(
                    domain: "ServiceStopCompletion",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "A photo is required before this service stop can be finished."
                    ]
                )
            }
        }

        print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] - Finishing Service Stop")
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        try await dataService.updateServiceStopEndTime(companyId: companyId, serviceStopId: stop.id, endTime: Date())
        if operationStatus == .finished {
            if completionSettings.sendEmailOnFinish {
                try? await FunctionsManager.shared.sendServiceReportOnFinish(companyId: companyId, stopId: stop.id)
                print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Sending Email")
            } else {
                print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Email off for category \(stop.resolvedCategory.rawValue)")
            }
        } else {
            print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Service Stop Not Finished")
        }
        // 2. Then update payroll based on the transition.
        let payrollCoordinator = ServiceStopPayrollCompletionCoordinator(
            dataService: dataService
        )

        let payrollResult = try await payrollCoordinator.handleServiceStopStatusChange(
            oldStop: oldStop,
            newStop: updatedStop,
            changedByUserId: currentUserId
        )

        if payrollResult.didGeneratePay {
            print("Generated \(payrollResult.generatedLineItems.count) payroll line item(s).")
        }

        if payrollResult.didVoidPay {
            print("Voided \(payrollResult.voidedLineItems.count) payroll line item(s).")
        }

        if payrollResult.hasLockedItems {
            print("\(payrollResult.lockedLineItems.count) approved/paid payroll item(s) need admin review.")
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
        Task {
            do {
                try await uploadPendingPhotosIfNeeded(companyId: companyId, serviceStopId: serviceStopId)
            } catch {
                print("Photo upload failed:", error)
            }
        }
    }

    private func loadCompletionSettings(
        companyId: String,
        stop: ServiceStop
    ) async -> ServiceStopCategoryCompletionSettings {
        do {
            let emailConfiguration = try await dataService.getEmailConfigurationSettings(companyId: companyId)
            return emailConfiguration.completionSettings(for: stop.resolvedCategory)
        } catch {
            print("Unable to load completion settings. Using defaults.", error)
            return ServiceStopCategoryCompletionSettings.defaultSettings(for: stop.resolvedCategory)
        }
    }

    private func uploadPendingPhotosIfNeeded(companyId:String,serviceStopId:String) async throws {
        while isUploadingPhotos {
            try await Task.sleep(nanoseconds: 200_000_000)
        }

        let photosToUpload = selectedDripDropPhotos
        guard !photosToUpload.isEmpty else { return }

        isUploadingPhotos = true
        defer { isUploadingPhotos = false }

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
    }
}
