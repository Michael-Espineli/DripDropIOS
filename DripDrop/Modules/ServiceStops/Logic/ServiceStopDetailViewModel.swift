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
import UIKit

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
    private let functions = Functions.functions()
    private var serviceReportPendingPhotoUpload: (companyId: String, serviceStopId: String)?


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
    @Published var EquipmentReadings: [Equipment: EquipmentMeasurements] = [:]
    @Published private(set) var selectedInputIdList: [String] = []
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published private(set) var shoppingListItems: [ShoppingListItem] = []
    @Published private(set) var updatingDeliveredItemIds: Set<String> = []
    
    @Published private(set) var readingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [SavedDosageTemplate] = []
    
    @Published var taskList: [ServiceStopTask] = []
    @Published private(set) var isLoadingInitialDetails: Bool = false
    @Published private(set) var isLoadingTasks: Bool = false
    
    @Published var loadedImages:[DripDropStoredImage] = []
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published private(set) var isUploadingPhotos: Bool = false
    @Published private(set) var photoUploadErrorMessage: String?
    @Published private(set) var isSavingServiceNotes: Bool = false
    
    @Published var currentWeather: Weather?

    func analyzeTesterStripScan(
        companyId: String,
        serviceStopId: String,
        bodyOfWaterId: String,
        image: UIImage,
        scanId: String? = nil,
        scanImageURL: String? = nil
    ) async throws -> [Reading] {
        let stripSample = TesterStripImageSampler.sample(from: image)

        guard !stripSample.observedPads.isEmpty else {
            throw TesterStripAnalysisError.noObservedPads
        }

        var payload: [String: Any] = [
            "companyId": companyId,
            "profileId": "aquachek_7_in_1",
            "serviceStopId": serviceStopId,
            "bodyOfWaterId": bodyOfWaterId,
            "observedPads": stripSample.observedPads,
            "persist": true,
        ]

        if let scanId, !scanId.isEmpty {
            payload["scanId"] = scanId
        }

        if let scanImageURL, !scanImageURL.isEmpty {
            payload["scanImagePath"] = scanImageURL
            payload["scanImageURL"] = scanImageURL
        }

        if !stripSample.calibration.isEmpty {
            payload["calibration"] = stripSample.calibration
        }

        let result = try await functions.httpsCallable("analyzeTesterStripScan").call(payload)
        guard
            let response = result.data as? [String: Any],
            let suggestedReadings = response["suggestedReadings"] as? [[String: Any]]
        else {
            throw TesterStripAnalysisError.invalidResponse
        }

        return suggestedReadings.compactMap { readingData in
            let universalTemplateId = stringValue(for: "universalTemplateId", in: readingData)
            let amount = stringValue(for: "amount", in: readingData)

            guard !universalTemplateId.isEmpty, !amount.isEmpty else {
                return nil
            }

            return Reading(
                id: stringValue(for: "id", in: readingData, fallback: UUID().uuidString),
                templateId: stringValue(for: "templateId", in: readingData),
                universalTemplateId: universalTemplateId,
                dosageType: stringValue(for: "dosageType", in: readingData),
                name: stringValue(for: "name", in: readingData),
                amount: amount,
                UOM: stringValue(for: "UOM", in: readingData),
                bodyOfWaterId: bodyOfWaterId
            )
        }
    }

    func uploadTesterStripReviewImage(
        companyId: String,
        serviceStopId: String,
        scanId: String,
        image: UIImage
    ) async throws -> DripDropStoredImage {
        let dripDropImage = DripDropImage(name: "Tester Strip Scan")
        try FileManager().saveImage(dripDropImage.id.uuidString, image: image)

        let (path, _) = try await dataService.uploadServiceStopImage(
            companyId: companyId,
            serviceStopId: serviceStopId,
            image: dripDropImage
        )

        return DripDropStoredImage(
            id: scanId,
            description: "Tester Strip Scan",
            imageURL: path
        )
    }

    
    func onInitalLoad(companyId:String,serviceStop:ServiceStop,userId:String) async throws {
        self.isLoadingInitialDetails = true
        self.isLoadingTasks = true
        defer {
            self.isLoadingInitialDetails = false
            self.isLoadingTasks = false
        }

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
        self.shoppingListItems = try await loadShoppingListItems(
            companyId: companyId,
            serviceStop: serviceStop,
            tasks: SSTasks
        )
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

    private func loadShoppingListItems(
        companyId: String,
        serviceStop: ServiceStop,
        tasks: [ServiceStopTask]
    ) async throws -> [ShoppingListItem] {
        var keys = Set(ShoppingPrepKeyBuilder.keysForServiceStop(serviceStop))

        for task in tasks {
            if !task.jobTaskId.isEmpty {
                keys.insert("jobTask:\(task.jobTaskId)")
            }

            if !task.shoppingListItemId.isEmpty {
                let shoppingListItemId = task.shoppingListItemId
                keys.insert("shoppingListItem:\(shoppingListItemId)")
            }
        }
        let prepKeys = Array(keys)

        async let actionItems = dataService.getShoppingListItemsForPrepKeys(
            companyId: companyId,
            prepKeys: prepKeys,
            needsAction: true
        )
        async let completedItems = dataService.getShoppingListItemsForPrepKeys(
            companyId: companyId,
            prepKeys: prepKeys,
            needsAction: false
        )

        let linkedShoppingItemIds = Set(tasks.map {
            $0.shoppingListItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty })
        let linkedJobTaskIds = Set(tasks.map { $0.jobTaskId.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })

        var items = try await (actionItems + completedItems).dedupedById()
        let fetchedItemIds = Set(items.map(\.id))
        let missingLinkedItemIds = linkedShoppingItemIds.subtracting(fetchedItemIds)

        for itemId in missingLinkedItemIds {
            if let item = try? await dataService.getSpecificShoppingListItem(
                companyId: companyId,
                shoppingListItemId: itemId
            ) {
                items.append(item)
            }
        }

        return items
            .dedupedById()
            .filter { item in
                itemMatchesServiceStop(
                    item,
                    serviceStop: serviceStop,
                    linkedShoppingItemIds: linkedShoppingItemIds,
                    linkedJobTaskIds: linkedJobTaskIds
                )
            }
            .sorted { first, second in
                let firstDate = first.actionDate ?? first.datePurchased ?? Date.distantPast
                let secondDate = second.actionDate ?? second.datePurchased ?? Date.distantPast

                if first.status != second.status {
                    return shoppingStatusSortRank(first.status) < shoppingStatusSortRank(second.status)
                }

                return firstDate > secondDate
            }
    }

    private func itemMatchesServiceStop(
        _ item: ShoppingListItem,
        serviceStop: ServiceStop,
        linkedShoppingItemIds: Set<String>,
        linkedJobTaskIds: Set<String>
    ) -> Bool {
        if (item.serviceStopId ?? "") == serviceStop.id {
            return true
        }

        if linkedShoppingItemIds.contains(item.id) {
            return true
        }

        if let linkedTaskId = item.linkedTaskId,
           linkedJobTaskIds.contains(linkedTaskId) {
            return true
        }

        if let jobId = item.jobId,
           !jobId.isEmpty,
           jobId == serviceStop.jobId {
            return true
        }

        return (item.serviceLocationId ?? "") == serviceStop.serviceLocationId &&
            (item.customerId ?? "") == serviceStop.customerId
    }

    private func shoppingStatusSortRank(_ status: ShoppingListStatus) -> Int {
        switch status {
        case .needToPurchase:
            return 0
        case .purchased:
            return 1
        case .delivered:
            return 2
        case .installed:
            return 3
        case .invoiced:
            return 4
        }
    }

    func markShoppingListItemDelivered(
        companyId: String,
        item: ShoppingListItem
    ) async throws {
        guard item.status != .delivered else { return }

        updatingDeliveredItemIds.insert(item.id)
        defer { updatingDeliveredItemIds.remove(item.id) }

        try await dataService.updateShoppingListStatus(
            companyId: companyId,
            shoppingListItemId: item.id,
            status: .delivered,
            needsAction: ShoppingListStatus.delivered.needsShoppingAction
        )

        if let index = shoppingListItems.firstIndex(where: { $0.id == item.id }) {
            shoppingListItems[index].status = .delivered
            shoppingListItems[index].needsAction = ShoppingListStatus.delivered.needsShoppingAction
            shoppingListItems[index].actionDate = Date()
        }
    }
    
    func finishServiceStop(companyId:String,currentUserId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws {
        print("  [ServiceStopDetailViewModel][finishServiceStop] - Finishing Service Stop 1")
        let oldStop = stop

        var updatedStop = stop
        let finishTime = Date()
        updatedStop.operationStatus = operationStatus
        if operationStatus == .finished {
            updatedStop.endTime = finishTime
            if let duration = serviceStopDurationMinutes(startTime: stop.startTime, endTime: finishTime) {
                updatedStop.duration = duration
            }

            let completionSettings = await loadCompletionSettings(companyId: companyId, stop: stop)
            let shouldDeferServiceReport = completionSettings.sendEmailOnFinish && hasPendingServiceStopPhotoUpload
            if shouldDeferServiceReport {
                serviceReportPendingPhotoUpload = (companyId: companyId, serviceStopId: stop.id)
            }
            queuePendingPhotoUpload(companyId: companyId, serviceStopId: stop.id)

            if completionSettings.requirePhotoOnFinish && !hasAttachedOrUploadedServiceStopPhoto(stop) {
                throw NSError(
                    domain: "ServiceStopCompletion",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "A photo is required before this service stop can be finished."
                    ]
                )
            }

            try await dataService.finishServiceStopImmediately(
                companyId: companyId,
                serviceStop: stop,
                endTime: finishTime,
                duration: updatedStop.duration,
                completedByUserId: currentUserId,
                sendServiceReport: completionSettings.sendEmailOnFinish && !shouldDeferServiceReport
            )
            print("Queued service stop completion work for \(stop.id)")
            return
        }
        // 1. Update the service stop operation status in your backend.
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        if operationStatus == .finished {
            try await dataService.updateServiceStopEndTime(companyId: companyId, serviceStopId: stop.id, endTime: finishTime)
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
    
    func finishServiceStop(companyId:String,currentUserId:String,stop:ServiceStop,operationStatus:ServiceStopOperationStatus,activeRoute:ActiveRoute) async throws {
        print("  [ServiceStopDetailViewModel][finishServiceStop] - Finishing Service Stop 2")
        
        let oldStop = stop

        var updatedStop = stop
        let finishTime = Date()
        updatedStop.operationStatus = operationStatus
        if operationStatus == .finished {
            updatedStop.endTime = finishTime
            if let duration = serviceStopDurationMinutes(startTime: stop.startTime, endTime: finishTime) {
                updatedStop.duration = duration
            }

            let completionSettings = await loadCompletionSettings(companyId: companyId, stop: stop)
            let shouldDeferServiceReport = completionSettings.sendEmailOnFinish && hasPendingServiceStopPhotoUpload
            if shouldDeferServiceReport {
                serviceReportPendingPhotoUpload = (companyId: companyId, serviceStopId: stop.id)
            }
            queuePendingPhotoUpload(companyId: companyId, serviceStopId: stop.id)

            if completionSettings.requirePhotoOnFinish && !hasAttachedOrUploadedServiceStopPhoto(stop) {
                throw NSError(
                    domain: "ServiceStopCompletion",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "A photo is required before this service stop can be finished."
                    ]
                )
            }

            try await dataService.finishServiceStopImmediately(
                companyId: companyId,
                serviceStop: stop,
                endTime: finishTime,
                duration: updatedStop.duration,
                completedByUserId: currentUserId,
                sendServiceReport: completionSettings.sendEmailOnFinish && !shouldDeferServiceReport
            )
            print("Queued service stop completion work for \(stop.id)")
            return
        }
        
        // 1. Update the service stop operation status in your backend.

        //Finish Service Stop
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        if operationStatus == .finished {
            try await dataService.updateServiceStopEndTime(companyId: companyId, serviceStopId: stop.id, endTime: finishTime)
        }
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
    
    func onChangeOfBodyOfWater(companyId: String, bodyOfWater: BodyOfWater) async {
        selectedBOW = bodyOfWater

        let bodyOfWaterId = bodyOfWater.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bodyOfWaterId.isEmpty else {
            currentHistory = []
            return
        }

        do {
            currentHistory = try await dataService.getRecentServiceStopsByBodyOfWater(
                companyId: companyId,
                bodyOfWaterId: bodyOfWaterId,
                amount: 4
            )
        } catch {
            currentHistory = []
            print("[ServiceStopDetailViewModel][onChangeOfBodyOfWater] Failed loading history for \(bodyOfWaterId): \(error)")
        }
    }
    
    func updateServicestopOperationStatus(
        companyId: String,
        currentUserId: String,
        stop: ServiceStop,
        operationStatus: ServiceStopOperationStatus,
        sendServiceReport: Bool = true
    ) async throws {
        let oldStop = stop
        let completionSettings = await loadCompletionSettings(companyId: companyId, stop: stop)

        var updatedStop = stop
        updatedStop.operationStatus = operationStatus
        let finishTime = Date()
        if operationStatus == .finished {
            updatedStop.endTime = finishTime
            if let duration = serviceStopDurationMinutes(startTime: stop.startTime, endTime: finishTime) {
                updatedStop.duration = duration
            }
        }
        // 1. Update the service stop operation status in your backend.

        //Update Service Stop FB
        //Just update the current Service Stop but
        //let the function check if the service stop should be from another company
        //let the function finish the other service stop on the sender side
        if operationStatus == .finished {
            let shouldSendServiceReport = completionSettings.sendEmailOnFinish && sendServiceReport
            let shouldDeferServiceReport = shouldSendServiceReport && hasPendingServiceStopPhotoUpload
            if shouldDeferServiceReport {
                serviceReportPendingPhotoUpload = (companyId: companyId, serviceStopId: stop.id)
            }
            queuePendingPhotoUpload(companyId: companyId, serviceStopId: stop.id)

            if completionSettings.requirePhotoOnFinish && !hasAttachedOrUploadedServiceStopPhoto(stop) {
                throw NSError(
                    domain: "ServiceStopCompletion",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "A photo is required before this service stop can be finished."
                    ]
                )
            }

            try await dataService.finishServiceStopImmediately(
                companyId: companyId,
                serviceStop: stop,
                endTime: finishTime,
                duration: updatedStop.duration,
                completedByUserId: currentUserId,
                sendServiceReport: shouldSendServiceReport && !shouldDeferServiceReport
            )
            print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Queued service stop completion work")
            return
        }

        print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] - Finishing Service Stop")
        try await dataService.updateServicestopOperationStatus(companyId: companyId, serviceStopId: stop.id, operationStatus: operationStatus)
        if operationStatus == .finished {
            try await dataService.updateServiceStopEndTime(companyId: companyId, serviceStopId: stop.id, endTime: finishTime)

            if completionSettings.sendEmailOnFinish && sendServiceReport {
                _ = try? await FunctionsManager.shared.sendServiceReportOnFinish(companyId: companyId, stopId: stop.id)
                print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Sending Email")
            } else if !sendServiceReport {
                print("  [ServiceStopDetailViewModel][updateServicestopOperationStatus] Email handled by caller")
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
        queuePendingPhotoUpload(companyId: companyId, serviceStopId: serviceStopId)
    }

    func queuePendingPhotoUpload(companyId:String,serviceStopId:String) {
        guard !isUploadingPhotos else { return }

        Task {
            await uploadPendingPhotosUntilEmpty(companyId: companyId, serviceStopId: serviceStopId)
        }
    }

    func updateServiceNotes(companyId:String,serviceStopId:String,serviceNotes:String) async throws {
        isSavingServiceNotes = true
        defer { isSavingServiceNotes = false }

        try await dataService.updateServiceStopServiceNotes(
            companyId: companyId,
            serviceStopId: serviceStopId,
            serviceNotes: serviceNotes
        )
    }

    private func serviceStopDurationMinutes(startTime: Date?, endTime: Date) -> Int? {
        guard let startTime,
              endTime > startTime else {
            return nil
        }

        return max(1, Int(ceil(endTime.timeIntervalSince(startTime) / 60)))
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

    private func hasAttachedOrUploadedServiceStopPhoto(_ stop: ServiceStop) -> Bool {
        !loadedImages.isEmpty ||
        !(stop.photoUrls ?? []).isEmpty ||
        !selectedDripDropPhotos.isEmpty ||
        isUploadingPhotos
    }

    private var hasPendingServiceStopPhotoUpload: Bool {
        !selectedDripDropPhotos.isEmpty || isUploadingPhotos
    }

    private func uploadPendingPhotosUntilEmpty(companyId:String,serviceStopId:String) async {
        isUploadingPhotos = true
        photoUploadErrorMessage = nil
        defer {
            isUploadingPhotos = false
        }

        var retryDelayNanoseconds: UInt64 = 2_000_000_000

        while !selectedDripDropPhotos.isEmpty {
            let photosToUpload = selectedDripDropPhotos

            do {
                let uploadedImages = try await uploadPhotoBatchWithRetry(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    images: photosToUpload
                )

                try await attachUploadedPhotosWithRetry(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    uploadedImages: uploadedImages
                )

                loadedImages.append(contentsOf: uploadedImages)

                let uploadedImageIds = Set(photosToUpload.map(\.id))
                selectedDripDropPhotos.removeAll { uploadedImageIds.contains($0.id) }
                photoUploadErrorMessage = nil
                retryDelayNanoseconds = 2_000_000_000
            } catch {
                photoUploadErrorMessage = "Photo upload is retrying in the background."
                print("Photo upload failed:", error)

                do {
                    try await Task.sleep(nanoseconds: retryDelayNanoseconds)
                    retryDelayNanoseconds = min(retryDelayNanoseconds * 2, 30_000_000_000)
                } catch {
                    return
                }
            }
        }

        await sendDeferredServiceReportAfterPhotoUploadIfNeeded()
    }

    private func uploadPhotoBatchWithRetry(
        companyId: String,
        serviceStopId: String,
        images: [DripDropImage]
    ) async throws -> [DripDropStoredImage] {
        var lastError: Error?

        for attempt in 1...3 {
            do {
                return try await dataService.uploadServiceStopImages(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    images: images
                )
            } catch {
                lastError = error

                if attempt < 3 {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }

        throw lastError ?? URLError(.cannotConnectToHost)
    }

    private func attachUploadedPhotosWithRetry(
        companyId: String,
        serviceStopId: String,
        uploadedImages: [DripDropStoredImage]
    ) async throws {
        var lastError: Error?

        for attempt in 1...3 {
            do {
                try await dataService.updateServiceStopPhotoURLs(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    photoUrls: uploadedImages
                )
                return
            } catch {
                lastError = error

                if attempt < 3 {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }

        throw lastError ?? URLError(.cannotConnectToHost)
    }

    private func sendDeferredServiceReportAfterPhotoUploadIfNeeded() async {
        guard let pendingReport = serviceReportPendingPhotoUpload else { return }
        serviceReportPendingPhotoUpload = nil

        do {
            _ = try await FunctionsManager.shared.sendServiceReportOnFinish(
                companyId: pendingReport.companyId,
                stopId: pendingReport.serviceStopId
            )
            print("Sent deferred service report after photo upload for \(pendingReport.serviceStopId)")
        } catch {
            print("Photo upload completed, but deferred service report failed:", error)
        }
    }
}

enum TesterStripAnalysisError: LocalizedError {
    case noObservedPads
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noObservedPads:
            return "Could not read colors from the tester strip photo."
        case .invalidResponse:
            return "The tester strip analyzer returned an unexpected response."
        }
    }
}

private func stringValue(for key: String, in data: [String: Any], fallback: String = "") -> String {
    if let value = data[key] as? String {
        return value
    }

    if let value = data[key] {
        return String(describing: value)
    }

    return fallback
}
