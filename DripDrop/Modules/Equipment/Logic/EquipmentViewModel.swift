//
//  EquipmentViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class EquipmentViewModel:ObservableObject{
    private var dataService: any ProductionDataServiceProtocol
    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var equipment: Equipment? = nil
    @Published private(set) var part: EquipmentPart? = nil
    private var lastDocument:DocumentSnapshot? = nil

    //ARRAYS
    @Published private(set) var listOfEquipment:[Equipment] = []
    @Published private(set) var partList:[EquipmentPart] = []
    @Published private(set) var equipmentCategories:[String] = ["Pump","Filter","Vacuum","Salt Cell","Heater","Light"]

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func fixEquipment(companyId:String) async throws {
        let equipmentList = try await EquipmentManager.shared.getAllEquipment(companyId: companyId)
        var count = 0
        for equipment in equipmentList {
            print("\(count) / \(equipmentList.count)")
            do {
                let customer = try await CustomerManager.shared.getCustomerById(companyId: companyId, customerId: equipment.customerId)
                let equipment = Equipment(
                    id: equipment.id,
                    name: equipment.name,
                    category: equipment.category,
                    make: equipment.make,
                    model: equipment.model,
                    dateInstalled: equipment.dateInstalled,
                    status: equipment.status,
                    needsService: equipment.needsService,
                    lastServiceDate: equipment.lastServiceDate,
                    serviceFrequency: equipment.serviceFrequency,
                    serviceFrequencyEvery: equipment.serviceFrequencyEvery,
                    nextServiceDate: equipment.nextServiceDate,
                    notes: equipment.notes,
                    customerName: customer.firstName + " " + customer.lastName,
                    customerId: equipment.customerId,
                    serviceLocationId: equipment.serviceLocationId,
                    bodyOfWaterId: equipment.bodyOfWaterId
                )
                try await EquipmentManager.shared.updateEquipmentCustomer(companyId: companyId,equipment:equipment)
            } catch {
                try await EquipmentManager.shared.deleteEquipment(companyId: companyId, equipmentId: equipment.id)
                print("Failed to Upload \(equipment.customerId)")
                print(error)
            }
            count += 1

        }
    }
    func uploadEquipment(companyId: String,customer:Customer,serviceLocation:ServiceLocation,bodyOfWater:BodyOfWater,equipment:Equipment) async throws {
        try await EquipmentManager.shared.uploadEquipment(companyId: companyId, equipment: equipment)
    }
    func addPartsToAllEquipment(companyId:String) async throws {
        let list = try await EquipmentManager.shared.getAllEquipment(companyId: companyId)
        var count = 0
        for part in list {
            count = count + 1
            print("\(String(count)) / \(String(list.count))")
            try await EquipmentManager.shared.addPartsToEquipment(companyId: companyId, equipment: part)
        }
    }
    func addEquipmentAndPartsToAllBodiesOfWater(companyId:String) async throws {
        let list = try await BodyOfWaterManager.shared.getAllBodiesOfWater(companyId: companyId)
        var count = 0
        for part in list {
            let customer = try await CustomerManager.shared.getCustomerById(
                companyId: companyId,
                customerId: part.customerId
            )
            let fullName = customer.firstName + " " + customer.lastName
            count = count + 1
            print("\(String(count)) / \(String(list.count))")
            try await EquipmentManager.shared.addNewEquipmentWithParts(
                companyId: companyId,
                equipment: Equipment(
                    id: UUID().uuidString,
                    name: "Pump 1",
                    category: .pump,
                    make: "",
                    model: "",
                    dateInstalled: Date(),
                    status: .operational,
                    needsService: false,
                    notes: "",
                    customerName: fullName,
                    customerId: part.customerId,
                    serviceLocationId: part.serviceLocationId,
                    bodyOfWaterId: part.id
                )
            )
            try await EquipmentManager.shared.addNewEquipmentWithParts(
                companyId: companyId,
                equipment: Equipment(
                    id: UUID().uuidString,
                    name: "Filter 1",
                    category: .filter,
                    make: "",
                    model: "",
                    dateInstalled: Date(),
                    status: .operational,
                    needsService: true,
                    lastServiceDate: Date(),
                    serviceFrequency: "Month",
                    serviceFrequencyEvery: "6",
                    nextServiceDate: getNextServiceDate(
                        lastServiceDate: Date(),
                        every: "6",
                        frequency: "Month"
                    ),
                    notes: "",
                    customerName: fullName,
                    customerId: part.customerId,
                    serviceLocationId: part.serviceLocationId,
                    bodyOfWaterId: part.id
                )
            )
        }
    }
    func uploadEquipmentWithValidation(
        companyId: String,
        category: EquipmentCategory,
        make: String,
        model: String,
        dateInstalled: Date,
        status: EquipmentStatus,
        notes: String,
        customerName: String,
        customerId: String,
        serviceLocationId: String,
        bodyOfWaterId:String,
        name:String,
        needsService:Bool,
        lastServiceDate: Date?,
        serviceFrequency: String?,
        serviceFrequencyEvery: String?
    ) async throws {
        let id = UUID().uuidString
        let equipment = Equipment(
            id: id,
            name: name,
            category: category,
            make: make,
            model: model,
            dateInstalled: dateInstalled,
            status: status,
            needsService: needsService,
            lastServiceDate: lastServiceDate,
            serviceFrequency: serviceFrequency,
            serviceFrequencyEvery: serviceFrequencyEvery,
            nextServiceDate: getNextServiceDate(
                lastServiceDate: lastServiceDate,
                every: serviceFrequencyEvery,
                frequency: serviceFrequency
            ),
            notes: notes,
            customerName: customerName,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: bodyOfWaterId
        )
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: equipment
        )
    }
    func uploadPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws{
        try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipmentId, part: part)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllEquipmentBy25(companyId:String) async throws{
        

        let (listOfEquipment,lastDocument) = try await dataService.getAllEquipmentCount(companyId: companyId, count: 25, lastDocument: lastDocument)
        self.listOfEquipment.append(contentsOf: listOfEquipment)
        if let lastDocument {
            self.lastDocument = lastDocument

        }
    }
    func getAllEquipment(companyId: String) async throws {
        
        self.listOfEquipment = try await EquipmentManager.shared.getAllEquipment(companyId: companyId)
    }
    func getEquipmentSnapShot(companyId: String) async throws {
        
        self.listOfEquipment = try await EquipmentManager.shared.getEquipmentSnapShot(companyId: companyId)
    }
    func getAllEquipmentFromBodyOfWater(companyId: String,bodyOfWater:BodyOfWater) async throws {
        
        self.listOfEquipment = try await EquipmentManager.shared.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    
    func getSinglePieceOfEquipment(companyId: String,customer:Customer,serviceLocation:ServiceLocation,bodyOfWater:BodyOfWater,equipmentId:String) async throws {
        self.equipment = try await EquipmentManager.shared.getSinglePieceOfEquipment(companyId: companyId, equipmentId: equipmentId)
    }
    func getSinglePieceOfEquipmentWithId(companyId: String,equipmentId:String) async throws {
        self.equipment = try await EquipmentManager.shared.getSinglePieceOfEquipment(companyId: companyId, equipmentId: equipmentId)
    }
    func getAllPartsByEquipment(companyId:String,equipmentId:String) async throws {
        self.partList = try await EquipmentManager.shared.getPartsUnderEquipment(companyId: companyId, equipmentId: equipmentId)
    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateEquipmentWithValidation(
        companyId: String,
        category: EquipmentCategory,
        equipmentId:String,
        make: String,
        model: String,
        dateInstalled: Date,
        status: EquipmentStatus,
        notes: String,
        customerName: String,

        customerId: String,
        serviceLocationId: String,
        bodyOfWaterId:String,
        name:String,
        needsService:Bool,
        lastServiceDate: Date?,
        serviceFrequency: String?,
        serviceFrequencyEvery: String?
    ) async throws {

        if needsService {
            guard let validatedLastServiceDate = lastServiceDate else {
                throw FireBasePublish.unableToPublish
            }
            guard let validatedServiceFrequency = serviceFrequency else {
                throw FireBasePublish.unableToPublish
            }
            guard let validatedServiceFrequencyEvery = serviceFrequencyEvery else {
                throw FireBasePublish.unableToPublish
            }
            guard let validedNextDate = getNextServiceDate(lastServiceDate: lastServiceDate, every: serviceFrequencyEvery, frequency: serviceFrequency) else {
                throw FireBasePublish.unableToPublish
            }
        }
        let equipment = Equipment(
            id: equipmentId,
            name: name,
            category: category,
            make: make,
            model: model,
            dateInstalled: dateInstalled,
            status: status,
            needsService: needsService,
            lastServiceDate: lastServiceDate,
            serviceFrequency: serviceFrequency,
            serviceFrequencyEvery: serviceFrequencyEvery,
            nextServiceDate: getNextServiceDate(
                lastServiceDate: lastServiceDate,
                every: serviceFrequencyEvery,
                frequency: serviceFrequency
            ),
            notes: notes,
            customerName: customerName,
            customerId: customerId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: bodyOfWaterId
        )
        try await EquipmentManager.shared.updateEquipment(
            companyId: companyId,
            equipmentId: equipmentId,
            equipment: equipment
        )
    }
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        try await EquipmentManager.shared.updatePart(companyId: companyId, equipmentId: equipmentId, part: part)
    }
    
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func removeListenerForEquipment(){
        print("Removing Equipment Listener")

        dataService.removeEquipmentListener()
    }
    func addListenerForAllEquipment(companyId:String,amount:Int){
        print("Adding Equipment Listener")
         dataService.addListenerForAllEquipment(companyId: companyId, amount: amount) { [weak self] equipment in
             self?.listOfEquipment = equipment
        }
    }

}
