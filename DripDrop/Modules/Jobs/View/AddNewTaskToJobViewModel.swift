//
//  AddNewTaskToJobViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

@MainActor
final class AddNewTaskToJobViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showTaskTypePicker: Bool = false

    @Published var isEdit: Bool = false
    @Published var rate: Double = 0
    
    @Published var name: String = ""
    @Published var contractedRateString: String = "0"
    @Published var estimatedTimeString: String = "0"
    @Published var quantityString: String = "0"

    @Published var selectedTaskType: JobTaskType = .basic

    
    @Published private(set) var bodyOfWaterList : [BodyOfWater] = []
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )
    
    @Published private(set) var equipmentList : [Equipment] = []
    @Published var selectedEquipment: Equipment = Equipment(
        id: "",
        name: "",
        type: .autoChlorinator,
        typeId: "",
        make: "",
        makeId: "",
        model: "",
        modelId: "",
        dateInstalled: Date(),
        status: .needsMaintenance,
        needsService: false,
        notes: "",
        customerName: "",
        customerId: "",
        serviceLocationId: "",
        bodyOfWaterId: "",
        isActive: false
    )
    
    @Published var showItemPicker: Bool = false
    @Published var showBOWPicker: Bool = false
    @Published var showEquipmentPicker: Bool = false

    @Published private(set) var installList : [DataBaseItem] = []
    @Published var dataBaseItemId: String = ""
    @Published var dataBaseItem: DataBaseItem = DataBaseItem(
        id: "",
        name: "",
        rate: 0,
        storeName: "",
        venderId: "",
        category: .chems,
        subCategory: .bushing,
        description: "",
        dateUpdated: Date(),
        sku: "",
        billable: false,
        color: "",
        size: "",
        UOM: .ft
    )

    func onLoad(companyId:String,jobId:String,serviceLocationId:String) async throws {
        print("")
        print("On Load serviceLocationId:\(serviceLocationId) - jobId:\(jobId)")
        self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
        self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
    }
    func checkNumber(numberStr:String) -> Bool{
        return numberStr.isNumber
    }
    func addNewTaskToJob(companyId:String,jobId:String,serviceLocationId:String) async throws {
        if name == "" {
            throw AddNewTaskToJobError.noName
        }
        if contractedRateString == "" {
            throw AddNewTaskToJobError.noContractedRate
        }
        if estimatedTimeString == "" {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let contractedRateDouble = Double(contractedRateString) else {
            contractedRateString = "0"

            throw AddNewTaskToJobError.noContractedRate
        }
        let contractedRate = Int((contractedRateDouble * 100).rounded())
        guard let estimatedTime = Int(estimatedTimeString) else {
            estimatedTimeString = "0"

            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let quantity = Double(quantityString) else {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        _ = quantity
        switch self.selectedTaskType {
        case .basic, .clean, .inspection:
            print("No Extra Details Needed")
        case .cleanFilter:
            print("Clean Filter")
            print("Select Filter")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
        case .emptyWater, .fillWater:
            print("Empty Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .install:
            print("Install")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .remove, .maintenance, .repair:
            print("Remove")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
        case .replace:
            print("Replace")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        }
        
        var task : JobTask = JobTask(
            name: name,
            type: selectedTaskType,
            contractedRate: contractedRate,
            estimatedTime: estimatedTime,
            status: .unassigned,
            customerApproval: false,
            actualTime: 0,
            workerId: "",
            workerType: .notAssigned,
            workerName: "",
            laborContractId: "",
            serviceStopId: IdInfo(id: "", internalId: ""),
            equipmentId: selectedEquipment.id,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: selectedBodyOfWater.id,
            dataBaseItemId: dataBaseItem.id
        )
        if selectedTaskType == .install || selectedTaskType == .replace {
            let shoppingListItemId = "comp_sli_" + UUID().uuidString
            task.shoppingListItemId = shoppingListItemId
            //Add Shopping List Item For Install and Replace
            let shoppingListItem = ShoppingListItem(
                id: shoppingListItemId,
                category: .job,
                subCategory: .dataBase,
                status: .needToPurchase,
                purchaserId: "",
                purchaserName: "",
                genericItemId: dataBaseItem.id,
                name: dataBaseItem.name,
                description: dataBaseItem.description,
                datePurchased: nil,
                quantity: quantityString,
                jobId: jobId,
                customerId: "",
                customerName: "",
                userId: nil,
                userName: nil,
                dbItemId: dataBaseItem.id,
                purchasedItem: nil,
                invoiced: true,
                linkedTaskId: task.id,
                linkedTaskName: task.name,
                linkedTaskType: task.type.rawValue
            )
            try await dataService.addNewShoppingListItem(companyId: companyId, shoppingListItem: shoppingListItem)
        }
        print(task)
        try await dataService.uploadJobTask(companyId:companyId,jobId:jobId,task:task)
        print("Successfully Uploaded Job Task")
        
        //Reset
        selectedTaskType = .basic
        name = ""
        selectedEquipment.id = ""
        selectedBodyOfWater.id = ""
        dataBaseItem.id = ""
        dataBaseItemId = ""
        estimatedTimeString = "0"
        contractedRateString = "0"
    }
    func addNewTaskToJobTaskList(companyId:String,jobId:String,serviceLocationId:String) async throws ->(JobTask, ShoppingListItem?){
        if name == "" {
            throw AddNewTaskToJobError.noName
        }
        if contractedRateString == "" {
            throw AddNewTaskToJobError.noContractedRate
        }
        if estimatedTimeString == "" {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let contractedRateDouble = Double(contractedRateString) else {
            contractedRateString = "0"

            throw AddNewTaskToJobError.noContractedRate
        }
        let contractedRate = Int((contractedRateDouble * 100).rounded())
        guard let estimatedTime = Int(estimatedTimeString) else {
            estimatedTimeString = "0"

            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let quantity = Double(quantityString) else {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        _ = quantity
        switch self.selectedTaskType {
        case .basic, .clean, .inspection:
            print("No Extra Details Needed")
        case .cleanFilter:
            print("Clean Filter")
            print("Select Filter")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
        case .emptyWater, .fillWater:
            print("Empty Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .install:
            print("Install")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .remove, .maintenance, .repair:
            print("Remove")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
        case .replace:
            print("Replace")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noEquipmentSelected
            }
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        }
        
        var task : JobTask = JobTask(
            name: name,
            type: selectedTaskType,
            contractedRate: contractedRate,
            estimatedTime: estimatedTime,
            status: .unassigned,
            customerApproval: false,
            actualTime: 0,
            workerId: "",
            workerType: .notAssigned,
            workerName: "",
            laborContractId: "",
            serviceStopId: IdInfo(id: "", internalId: ""),
            equipmentId: selectedEquipment.id,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: selectedBodyOfWater.id,
            dataBaseItemId: dataBaseItem.id
        )
        var shoppingListItem:ShoppingListItem? = nil
        if selectedTaskType == .install || selectedTaskType == .replace {
            let shoppingListItemId = "comp_sli_" + UUID().uuidString
            task.shoppingListItemId = shoppingListItemId
            //Add Shopping List Item For Install and Replace
            shoppingListItem = ShoppingListItem(
                id: shoppingListItemId,
                category: .job,
                subCategory: .dataBase,
                status: .needToPurchase,
                purchaserId: "",
                purchaserName: "",
                genericItemId: dataBaseItem.id,
                name: dataBaseItem.name,
                description: dataBaseItem.description,
                datePurchased: nil,
                quantity: quantityString,
                jobId: jobId,
                customerId: "",
                customerName: "",
                userId: nil,
                userName: nil,
                dbItemId: dataBaseItem.id,
                purchasedItem: nil,
                invoiced: true,
                linkedTaskId: task.id,
                linkedTaskName: task.name,
                linkedTaskType: task.type.rawValue
            )
        }
        
        //Reset
        selectedTaskType = .basic
        name = ""
        selectedEquipment.id = ""
        selectedBodyOfWater.id = ""
        dataBaseItem.id = ""
        dataBaseItemId = ""
        estimatedTimeString = "0"
        contractedRateString = "0"
        return (task,shoppingListItem)
    }

    func onChangeOfSelectedTaskType(companyId:String,customerId:String,serviceLocationId:String) async throws {
        print("On Change of selected Task \(selectedTaskType) - companyId: \(companyId) - customerId: \(customerId) - serviceLocationId: \(serviceLocationId)")
        
            print("Type: \(selectedTaskType)")
        selectedEquipment.id = ""
        selectedBodyOfWater.id = ""
        dataBaseItem.id = ""
        dataBaseItemId = ""
        switch selectedTaskType {
            
        case .basic, .clean:
            print("Do Nothing \(selectedTaskType)")
        case .cleanFilter:
            self.equipmentList = try await dataService.getEquipmentByServiceLocationIdAndCategory(companyId: companyId, serviceLocationId: serviceLocationId, category: .filter)

            if let first = equipmentList.first{
                self.selectedEquipment = first
            }
        case .emptyWater:
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
 
            if let first = bodyOfWaterList.first{
                self.selectedBodyOfWater = first
            }
        case .fillWater:
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = bodyOfWaterList.first{
                self.selectedBodyOfWater = first
            }
        case .inspection:
            print("Do Nothing Inspection")
        case .install:
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = bodyOfWaterList.first{
                self.selectedBodyOfWater = first
            }
        case .remove:
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first{
                self.selectedEquipment = first
            }
        case .replace:
            //Get Equipment
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first{
                self.selectedEquipment = first
            }
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = bodyOfWaterList.first{
                self.selectedBodyOfWater = first
            }
            //Get Items
            self.installList = []
        case .maintenance:
            
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first{
                self.selectedEquipment = first
            }
        case .repair:
            
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first{
                self.selectedEquipment = first
            }
        }
    }
}
