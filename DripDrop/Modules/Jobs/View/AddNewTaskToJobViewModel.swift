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
        lastFilled: Date()
    )
    
    @Published private(set) var equipmentList : [Equipment] = []
    @Published var selectedEquipment: Equipment = Equipment(
        id: "",
        name: "",
        category: .autoChlorinator,
        make: "",
        model: "",
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
        guard var contractedRate = Int(contractedRateString) else {
            contractedRateString = "0"

            throw AddNewTaskToJobError.noContractedRate
        }
        contractedRate = contractedRate*100
        guard let estimatedTime = Int(estimatedTimeString) else {
            estimatedTimeString = "0"

            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let quantity = Double(quantityString) else {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        switch self.selectedTaskType {
        case .basic, .clean:
            print("No Extra Details Needed")
        case .cleanFilter:
            print("Clean Filter")
            print("Select Filter")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .emptyWater:
            print("Empty Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .fillWater:
            print("Fill Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .inspection:
            print("Inspection")
        case .install:
            print("Install")
            if self.dataBaseItem.id == "" && self.selectedEquipment.id == ""{
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .remove:
            print("Remove")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .replace:
            print("Replace")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .maintenance:
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .repair:
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        }
        
        let task : JobTask = JobTask(
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
            //Add Shopping List Item For Install and Replace
            let shoppingListItem = ShoppingListItem(
                id: "comp_sli_" + UUID().uuidString,
                category: .job,
                subCategory: .dataBase,
                status: .needToPurchase,
                purchaserId: "",
                purchaserName: "",
                genericItemId: "",
                name: dataBaseItem.name,
                description: dataBaseItem.description,
                datePurchased: nil,
                quantiy: quantityString,
                jobId: jobId,
                customerId: "",
                customerName: "",
                userId: nil,
                userName: nil
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
        guard var contractedRate = Int(contractedRateString) else {
            contractedRateString = "0"

            throw AddNewTaskToJobError.noContractedRate
        }
        contractedRate = contractedRate*100
        guard let estimatedTime = Int(estimatedTimeString) else {
            estimatedTimeString = "0"

            throw AddNewTaskToJobError.noEstimatedTime
        }
        guard let quantity = Double(quantityString) else {
            throw AddNewTaskToJobError.noEstimatedTime
        }
        switch self.selectedTaskType {
        case .basic, .clean:
            print("No Extra Details Needed")
        case .cleanFilter:
            print("Clean Filter")
            print("Select Filter")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .emptyWater:
            print("Empty Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .fillWater:
            print("Fill Water")
            if self.selectedBodyOfWater.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .inspection:
            print("Inspection")
        case .install:
            print("Install")
            if self.dataBaseItem.id == "" && self.selectedEquipment.id == ""{
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .remove:
            print("Remove")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .replace:
            print("Replace")
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
            if self.dataBaseItem.id == "" {
                throw AddNewTaskToJobError.noShoppingListItem
            }
        case .maintenance:
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        case .repair:
            if self.selectedEquipment.id == "" {
                throw AddNewTaskToJobError.noBowSelected
            }
        }
        
        let task : JobTask = JobTask(
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
            //Add Shopping List Item For Install and Replace
            shoppingListItem = ShoppingListItem(
                id: "comp_sli_" + UUID().uuidString,
                category: .job,
                subCategory: .dataBase,
                status: .needToPurchase,
                purchaserId: "",
                purchaserName: "",
                genericItemId: "",
                name: dataBaseItem.name,
                description: dataBaseItem.description,
                datePurchased: nil,
                quantiy: quantityString,
                jobId: jobId,
                customerId: "",
                customerName: "",
                userId: nil,
                userName: nil
            )
        }
        
        //Reset
        selectedTaskType = .basic
        name = ""
        selectedEquipment.id = ""
        selectedBodyOfWater.id = ""
        dataBaseItemId = ""
        estimatedTimeString = "0"
        contractedRateString = "0"
        return (task,shoppingListItem)
    }

    func onChangeOfSelectedTaskType(companyId:String,customerId:String,serviceLocationId:String) async throws {
        print("On Change of selected Task \(selectedTaskType) - companyId: \(companyId) - customerId: \(customerId) - serviceLocationId: \(serviceLocationId)")
        
            print("Type: \(selectedTaskType)")
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
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first{
                self.selectedEquipment = first
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

