//
//  JobDetailViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/22/24.
//

import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

@MainActor
final class JobDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //Sheet Variables
    @Published var isPresentingMarkEstiamteAsAccepted: Bool = false
    @Published var isPresentingMarkJobAsInvoiced: Bool = false

    @Published var isEdit: Bool = false
    @Published var isAddTask: Bool = false
    @Published var isAddTaskGroup: Bool = false

    @Published var isAddShoppingList: Bool = false
    @Published var isPresentServiceStop: Bool = false
    @Published var isPresentLaborContract: Bool = false
    @Published var showEstimate: Bool = false

    @Published var taskGroupItems : [JobTaskGroupItem] = []
    @Published var description: String = "Tasks"

    @Published private(set) var chosenView: String = "Tasks"
    @Published private(set) var viewOptionList:[String] = ["Tasks","Shopping","Schedule","Info"]
    @Published private(set) var jobTaskList:[JobTask] = []
    @Published var shoppingItemList:[ShoppingListItem] = []
    @Published private(set) var taskTypes:[String] = []
    @Published private(set) var serviceStopIds:[String] = []
    @Published private(set) var serviceStops:[ServiceStop] = []
    @Published private(set) var laborContracts:[LaborContract] = []

    @Published private(set) var jobTemplates:[JobTemplate] = []
    @Published private(set) var serviceStopTemplates:[ServiceStopTemplate] = []
    @Published private(set) var techList:[CompanyUser] = []
    
    @Published private(set) var serviceLocations:[ServiceLocation] = []
    @Published private(set) var serviceLocation:ServiceLocation? = nil
    
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var bodyOfWater:BodyOfWater? = nil
    
    @Published private(set) var equipmentList: [Equipment] = []
    @Published private(set) var equipment:Equipment? = nil

    @Published private(set) var purchasedPartCost: Double? = nil
    @Published private(set) var shoppingListCost: Double? = nil
    @Published private(set) var shoppingListPrice: Double? = nil
    
    @Published private(set) var updatedLaborCost: Double? = nil
    @Published private(set) var employeeLaborCost: Double? = nil
    @Published private(set) var employeeHours: Double = 0
    @Published private(set) var employeeHourlyRate: Double = 2000

    @Published var showLaborCostBreakDown: Bool = false
    @Published var showMaterialCostBreakDown: Bool = false

    @Published private(set) var laborContractIds:[String] = []
    @Published private(set) var senderCompany:Company? = nil
    
    @Published private(set) var laborContract:LaborContract? = nil
    
    @Published private(set) var operationStatus:JobOperationStatus? = nil
    @Published private(set) var billingStatus:JobBillingStatus? = nil

    //On Manual Accept Estimate
    @Published var estimateAcceptedNotes: String = ""
    @Published var estiamtedAcceptedDate: Date = Date()
    
    //On Manual Invoice 
    @Published var invoiceRef: String = ""
    @Published var invoiceNotes: String = ""
    @Published var isInvoiced: Bool = false
    @Published var invoiceDate: Date? = nil
    @Published var invoiceType: JobInvoiceType? = nil

    //Alert Info
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    //Functions
    
    func onLoad(companyId:String,serviceLocationId:String,job:Job) async throws {
        print("")
        self.invoiceRef = job.invoiceRef ?? ""
        self.invoiceNotes = job.invoiceNotes ?? ""
        self.invoiceDate = job.invoiceDate
        self.invoiceType = job.invoiceType
        if job.billingStatus == .invoiced {
            self.isInvoiced = true
        }
        
        self.description = job.description
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: job.id)
        print("jobTaskList \(jobTaskList.count)")
        
        self.shoppingItemList = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
        print("shoppingItemList \(shoppingItemList.count)")
  
        self.operationStatus = job.operationStatus
        self.billingStatus = job.billingStatus
        var updatedLaborCost = 0
        var employeeMin = 0
            //Other Company Stuff
        if job.otherCompany {
            if let senderId = job.senderId {
                    //Service Locations
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: senderId, locationId: serviceLocationId)
                self.senderCompany = try await dataService.getCompany(companyId: senderId)
                
                //Items From other company
                var total = 0
                var price = 0
                for item in shoppingItemList {
                    if let id = item.dbItemId, let quantiyStr = item.quantiy, let quantiy = Int(quantiyStr) {
                        let dbItem = try await dataService.getDataBaseItem(companyId: senderId, dataBaseItemId: id)
                        let subtotal = Int(dbItem.rate) * quantiy
                        total = total + subtotal
                        if let sellPrice = dbItem.sellPrice {
                            let subPrice = Int(sellPrice) * quantiy
                            price = price + subPrice
                        }
                    }
                }
                self.shoppingListCost = Double(total)
                self.shoppingListPrice = Double(price)
            }
            if let receivedLaborContractId = job.receivedLaborContractId {
                self.laborContract = try await dataService.getLaborContract(laborContractId: receivedLaborContractId)
            }
        } else {
            self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceLocationId)
            
            var total = 0
            var price = 0
            for item in shoppingItemList {
                if let id = item.dbItemId, let quantiyStr = item.quantiy, let quantiy = Int(quantiyStr) {
                    let dbItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: id)
                    let subtotal = Int(dbItem.rate) * quantiy
                    total = total + subtotal
                    if let sellPrice = dbItem.sellPrice {
                        let subPrice = Int(sellPrice) * quantiy
                        price = price + subPrice
                    }
                }
            }
            self.shoppingListCost = Double(total)
            self.shoppingListPrice = Double(price)
        }
        
        //Get Task Types
        self.taskTypes = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
        
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = []
        self.laborContractIds = []
        self.serviceStops = []
        self.laborContracts = []
        
        print("Received \(jobTaskList.count) Tasks")
        for task in jobTaskList {
            print("Task: \(task)")
            self.serviceStopIds.append(task.serviceStopId.id)
            self.laborContractIds.append(task.laborContractId)
            updatedLaborCost = updatedLaborCost + task.contractedRate
            employeeMin = employeeMin + task.estimatedTime
        }
        
        self.employeeHours = Double(employeeMin)/60
        self.employeeLaborCost = Double(employeeHours) * employeeHourlyRate
        self.updatedLaborCost = Double(updatedLaborCost)
        if job.laborCost != updatedLaborCost {
            //Update Labor Cost
            if job.otherCompany {
                if let senderId = job.senderId {
                    try await dataService.updateJobLaborCost(companyId: senderId, jobId: job.id, laborCost: String(updatedLaborCost))
                }
            } else {
                try await dataService.updateJobLaborCost(companyId: companyId, jobId: job.id, laborCost: String(updatedLaborCost))
            }
        }
        
        print("")
        self.serviceStopIds.removeDuplicates()
        self.serviceStopIds.remove("")
        var serviceStopList:[ServiceStop] = []
        print("serviceStopIds: \(serviceStopIds)")
        for serviceStopId in serviceStopIds {
            serviceStopList.append(try await dataService.getServiceStopById(serviceStopId: serviceStopId, companyId: companyId))
        }
        self.serviceStops = serviceStopList
        print("got Service Stops")
        
        
        self.laborContractIds.removeDuplicates()
        self.laborContractIds.remove("")
        var laborContractList:[LaborContract] = []
        print("laborContractIds: \(laborContractIds)")
        for id in laborContractIds {
            laborContractList.append(try await dataService.getLaborContract(laborContractId: id))
        }
        self.laborContracts = laborContractList
        print("got Labor Contracts")
        
        self.techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")

        //D ont know if i Need these Developer
//        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
//        self.serviceStopTemplates = try await SettingsManager.shared.getAllServiceStopTemplates(companyId: companyId)

    }
    
    func onDismissOfScheduleServiceStop(companyId:String,serviceLocationId:String,job:Job) async throws {
        print("")
        print("On Dismiss of schedule service stop")
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: job.id)
        print("jobTaskList")
        print(jobTaskList)
        
        self.shoppingItemList = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
        print("shoppingItemList")
        print(shoppingItemList)
        
        //Service Locations
        if job.otherCompany {
            if let senderId = job.senderId {
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: senderId, locationId: serviceLocationId)
            }
        } else {
            self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceLocationId)
        }
        
        //Get Task Types
        self.taskTypes = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
        
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = []
        self.laborContractIds = []
        self.serviceStops = []
        self.laborContracts = []
        
        print("Received \(jobTaskList.count) Tasks")
        for task in jobTaskList {
            print("Task: \(task)")
            self.serviceStopIds.append(task.serviceStopId.id)
            self.laborContractIds.append(task.laborContractId)
        }
        
        print("")
        self.serviceStopIds.removeDuplicates()
        self.serviceStopIds.remove("")
        var serviceStopList:[ServiceStop] = []
        print("serviceStopIds: \(serviceStopIds)")
        for serviceStopId in serviceStopIds {
            serviceStopList.append(try await dataService.getServiceStopById(serviceStopId: serviceStopId, companyId: companyId))
        }
        self.serviceStops = serviceStopList
        print("got Service Stops")
        
        
        self.laborContractIds.removeDuplicates()
        self.laborContractIds.remove("")
        var laborContractList:[LaborContract] = []
        print("laborContractIds: \(laborContractIds)")
        for id in laborContractIds {
            laborContractList.append(try await dataService.getLaborContract(laborContractId: id))
        }
        self.laborContracts = laborContractList
        print("got Labor Contracts")
        
        self.techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")

    }
    
    func onDismissOfOfferLaborContract(companyId:String,serviceLocationId:String,job:Job) async throws {
        print("")
        print("On Dismiss of offer labor contract")
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: job.id)
        print("jobTaskList")
        print(jobTaskList)
        
        self.shoppingItemList = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
        print("shoppingItemList")
        print(shoppingItemList)
        
        //Service Locations
        if job.otherCompany {
            if let senderId = job.senderId {
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: senderId, locationId: serviceLocationId)
            }
        } else {
            self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceLocationId)
        }
        
        //Get Task Types
        self.taskTypes = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
        
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = []
        self.laborContractIds = []
        self.serviceStops = []
        self.laborContracts = []
        
        print("Received \(jobTaskList.count) Tasks")
        for task in jobTaskList {
            print("Task: \(task)")
            self.serviceStopIds.append(task.serviceStopId.id)
            self.laborContractIds.append(task.laborContractId)
        }
        
        print("")
        self.serviceStopIds.removeDuplicates()
        self.serviceStopIds.remove("")
        var serviceStopList:[ServiceStop] = []
        print("serviceStopIds: \(serviceStopIds)")
        for serviceStopId in serviceStopIds {
            serviceStopList.append(try await dataService.getServiceStopById(serviceStopId: serviceStopId, companyId: companyId))
        }
        self.serviceStops = serviceStopList
        print("got Service Stops")
        
        
        self.laborContractIds.removeDuplicates()
        self.laborContractIds.remove("")
        var laborContractList:[LaborContract] = []
        print("laborContractIds: \(laborContractIds)")
        for id in laborContractIds {
            laborContractList.append(try await dataService.getLaborContract(laborContractId: id))
        }
        self.laborContracts = laborContractList
        print("got Labor Contracts")
        
        self.techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")

    }

    func onChangeOfCustomer (companyId:String,customerId:String) async throws {
        self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customerId
        )
        
        if serviceLocations.count != 0 {
            self.serviceLocation = serviceLocations.first!
        } else {
            self.serviceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "", preText: false)
        }
    }
    
    func onChangeOfServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws {
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: serviceLocation)

        
        if bodiesOfWater.count != 0 {
            self.bodyOfWater = bodiesOfWater.first!
        } else {
            self.bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date())
        }
    }
    
    func onChangeOfBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws {
        self.equipmentList = try await EquipmentManager.shared.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)

        
        if equipmentList.count != 0 {
            equipment = equipmentList.first!
        } else {
            equipment = Equipment(
                id: "",
                name: "",
                category: .filter,
                make: "",
                model: "",
                dateInstalled: Date(),
                status: .operational,
                needsService: true,
                notes: "",
                customerName: "",
                customerId: "",
                serviceLocationId: "",
                bodyOfWaterId: "", 
                isActive: true
            )
        }
    }
    func updateDescription(companyId: String, jobId: String) async throws {
        try await dataService.updateJobDescription(companyId: companyId, jobId: jobId, description: description)
    }
    func getPurchaseCost(companyId:String,purchaseIds:[String]) async throws {
        var total:Double = 0
        for id in purchaseIds {
            let purchase = try await dataService.getSingleItem(itemId: id, companyId: companyId)
            total += purchase.totalAfterTax
        }
        self.purchasedPartCost = total
    }
    func getShoppingListTotal() {
        
    }
    func getTotalParts(installation:[WODBItem], pvc:[WODBItem], electrical:[WODBItem], chems:[WODBItem], misc:[WODBItem])->Double {
        var total:Double = 0
        for part in installation {
            total = part.total + total
        }
        for part in pvc {
            total = part.total + total
        }
        for part in electrical {
            total = part.total + total
        }
        for part in chems {
            total = part.total + total
        }
        for part in misc {
            total = part.total + total
        }
        
        return total
    }
    
    func getTotal(installation:[WODBItem], pvc:[WODBItem], electrical:[WODBItem], chems:[WODBItem], misc:[WODBItem], labor:String)->Double {
        var total:Double = 0
        if let labor = Double(labor) {
            for part in installation {
                total = part.total + total
            }
            for part in pvc {
                total = part.total + total
            }
            for part in electrical {
                total = part.total + total
            }
            for part in chems {
                total = part.total + total
            }
            for part in misc {
                total = part.total + total
            }
            total = total + labor
        }
        return total
    }
    
    func addNewTasks(companyId:String,jobId:String) {
        //DEVELOPER WHAT DOES THIS DO
        Task{
            do {
                for task in taskGroupItems {
                    let jobTask = JobTask(
                        name: task.name,
                        type: task.type,
                        contractedRate: task.contractedRate,
                        estimatedTime: task.estimatedTime,
                        status: .draft,
                        customerApproval: false,
                        actualTime: 0,
                        workerId: "",
                        workerType: .notAssigned,
                        workerName: "",
                        laborContractId: "",
                        serviceStopId: IdInfo(id: "", internalId: ""),
                        equipmentId: "",
                        serviceLocationId: "",
                        bodyOfWaterId: "",
                        dataBaseItemId: ""
                    )
                    self.jobTaskList.append(jobTask)
                    try await dataService.uploadJobTask(companyId: companyId, jobId: jobId, task: jobTask)
                }
                self.taskGroupItems = []
            } catch {
                print(error)
            }
        }
    }
    
    func updateJobInfo(
        companyId:String,
        updatingJob:Job,
        admin:CompanyUser,
        jobTemplate:JobTemplate,
        operationStatus:JobOperationStatus,
        billingStatus:JobBillingStatus,
        rate:String,
        laborCost:String,
        description:String
    ) async throws{
            //Check Which Parts Need Updating
            if admin.id != updatingJob.adminId || admin.userName != updatingJob.adminName{
                print("Change in Admin")
                let name:String = admin.userName
                try await dataService.updateJobAdmin(companyId: companyId, jobId: updatingJob.id, adminName: name, adminId: admin.id)
            }
     
            if operationStatus != updatingJob.operationStatus {
                print("Change in Operation Status")
                try await dataService.updateJobOperationStatus(companyId: companyId, jobId: updatingJob.id, operationStatus: operationStatus)
            }
            if billingStatus != updatingJob.billingStatus {
                print("Change in Billing Status")
                try await dataService.updateJobBillingStatus(companyId: companyId, jobId: updatingJob.id, billingStatus: billingStatus)
            }
            if String(updatingJob.rate) != rate {
                print("Change in Rate")
                try await dataService.updateJobRate(companyId: companyId, jobId: updatingJob.id, rate: rate)
            }
            if laborCost != String(updatingJob.laborCost) {
                print("Change in Labor Cost")
                try await dataService.updateJobLaborCost(companyId: companyId, jobId: updatingJob.id, laborCost: laborCost)
            }
            if description != updatingJob.description{
                print("Change in Description")
                try await dataService.updateJobDescription(companyId: companyId, jobId: updatingJob.id, description: description)
            }
        }
    
    func markJobAsFinished(companyId: String, job: Job) async throws {
        //Update Data Model
        try await dataService.updateJobOperationStatus(companyId: companyId, jobId: job.id, operationStatus: .finished)
        self.operationStatus = .finished
        
        //See if is other company
        if job.otherCompany {
            if job.receiverId == companyId {
                if let senderId = job.senderId, let contractId = job.receivedLaborContractId {
                    //Update Labor Contract
                    try await dataService.updateLaborContractStatus(contractId: contractId, status: .finished)
                    //Get Labor Contract
                    let contract = try await dataService.getLaborContract(laborContractId: contractId)
                    //Update Job Info
                    for task in jobTaskList {
                        try dataService.updateJobTaskStatus(companyId: senderId, jobId: contract.senderJobId.id, taskId: task.id, status: .finished)
                        try await updateTaskHelperFunction(companyId: senderId, task: task)
                    }
                }
            }
        } else {
            for task in jobTaskList {
                //Update Task
                try await updateTaskHelperFunction(companyId: companyId, task: task)
            }
        }
    }
    func updateTaskHelperFunction(companyId:String,task:JobTask) async throws {
        
        //Developer
        switch task.type {
        case .basic, .clean:
            print("Do nothing")
        case .cleanFilter:
            print("Update Filter")
        case .maintenance:
            print("Maintence")
        case .repair:
            print("Add to Equipment History")
        case .emptyWater:
            print("Update Body Of Water")
        case .fillWater:
            if task.bodyOfWaterId != "" {
                try await dataService.updateBodyOfWaterLastFilledDate(companyId: companyId, bodyOfWaterId: task.bodyOfWaterId, lastFilled: Date())
            }
        case .inspection:
            print("Something")
        case .install:
            print("Add New Equipment")
            if task.dataBaseItemId != "" && task.bodyOfWaterId != ""{
                let DBItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: task.dataBaseItemId)
                let BOW = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: task.bodyOfWaterId)
                let customer = try await dataService.getCustomerById(companyId: companyId, customerId: BOW.customerId)
                let customerName = customer.firstName + " " + customer.lastName
                var equipmentType:EquipmentCategory = .autoChlorinator
                var equipmentNeedsService:Bool = false
                var serviceFrequency:String = ""
                var serviceFrequencyInternval:String = ""
                if DBItem.category == .equipment {
                    switch DBItem.subCategory {
                    case .pipe, .glue, .primer, .pipeExtender, .fittingExtender, .insideCoupler, .sweep, .street, .valve, .bushing, .tee, .elbow, .elbow45, .coupler, .union, .maleAdaptor, .nipple, .wire, .misc, .na:
                        print("Developer I dont Think I do anything")
                    case .heater:
                        equipmentType = .heater
                    case .filter:
                        equipmentType = .filter
                        equipmentNeedsService = true
                        serviceFrequency = "6"
                        serviceFrequencyInternval = "Month"
                    case .pump:
                        equipmentType = .pump
                    case .cleaner:
                        equipmentType = .cleaner
                    case .saltCell:
                        equipmentType = .saltCell
                        equipmentNeedsService = true
                        serviceFrequency = "6"
                        serviceFrequencyInternval = "Month"
                    case .light:
                        equipmentType = .light
                    case .controlSystem:
                        equipmentType = .controlSystem
                    case .autoChlorinator:
                        equipmentType = .autoChlorinator
                    }
                }
                let equipment = Equipment(
                    id: "comp_equ_" + UUID().uuidString,
                    name: DBItem.name,
                    category: equipmentType,
                    make: "", //DEVELOPER AFter Updating PA-97
                    model: "", //DEVELOPER AFter Updating PA-97
                    dateInstalled: Date(),
                    status: .operational,
                    needsService: equipmentNeedsService,
                    cleanFilterPressure: nil,
                    currentPressure: nil,
                    lastServiceDate: Date(),
                    serviceFrequency: serviceFrequency,
                    serviceFrequencyEvery: serviceFrequencyInternval,
                    nextServiceDate: nil,
                    notes: "",
                    customerName: customerName,
                    customerId: BOW.customerId,
                    serviceLocationId: BOW.serviceLocationId,
                    bodyOfWaterId: BOW.id,
                    photoUrls: [],
                    isActive: true,
                    dateUninstalled: nil
                )
                try await dataService.uploadEquipment(companyId: companyId, equipment: equipment)
            }
        case .remove:
            if task.equipmentId != "" {
                print("Make Equipment Inactive")
                try dataService.updateEquipmentIsActive(companyId: companyId, equipmentId: task.equipmentId, isActive: false)
                try dataService.updateEquipmentDateUninstalled(companyId: companyId, equipmentId: task.equipmentId, dateUninstalled: Date())
            }
        case .replace:
            if task.equipmentId != "" {
                
                print("Make Equipment Inactive")
                try dataService.updateEquipmentIsActive(companyId: companyId, equipmentId: task.equipmentId, isActive: false)
                try dataService.updateEquipmentDateUninstalled(companyId: companyId, equipmentId: task.equipmentId, dateUninstalled: Date())
            }
            print("Add New Equipment")
            if task.dataBaseItemId != "" && task.bodyOfWaterId != ""{
                let DBItem = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: task.dataBaseItemId)
                let BOW = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: task.bodyOfWaterId)
                let customer = try await dataService.getCustomerById(companyId: companyId, customerId: BOW.customerId)
                let customerName = customer.firstName + " " + customer.lastName
                var equipmentType:EquipmentCategory = .autoChlorinator
                var equipmentNeedsService:Bool = false
                var serviceFrequency:String = ""
                var serviceFrequencyInternval:String = ""
                if DBItem.category == .equipment {
                    switch DBItem.subCategory {
                    case .pipe, .glue, .primer, .pipeExtender, .fittingExtender, .insideCoupler, .sweep, .street, .valve, .bushing, .tee, .elbow, .elbow45, .coupler, .union, .maleAdaptor, .nipple, .wire, .misc, .na:
                        print("Developer I dont Think I do anything")
                    case .heater:
                        equipmentType = .heater
                    case .filter:
                        equipmentType = .filter
                        equipmentNeedsService = true
                        serviceFrequency = "6"
                        serviceFrequencyInternval = "Month"
                    case .pump:
                        equipmentType = .pump
                    case .cleaner:
                        equipmentType = .cleaner
                    case .saltCell:
                        equipmentType = .saltCell
                        equipmentNeedsService = true
                        serviceFrequency = "6"
                        serviceFrequencyInternval = "Month"
                    case .light:
                        equipmentType = .light
                    case .controlSystem:
                        equipmentType = .controlSystem
                    case .autoChlorinator:
                        equipmentType = .autoChlorinator
                    }
                }
                let equipment = Equipment(
                    id: "comp_equ_" + UUID().uuidString,
                    name: DBItem.name,
                    category: equipmentType,
                    make: "", //DEVELOPER AFter Updating PA-97
                    model: "", //DEVELOPER AFter Updating PA-97
                    dateInstalled: Date(),
                    status: .operational,
                    needsService: equipmentNeedsService,
                    cleanFilterPressure: nil,
                    currentPressure: nil,
                    lastServiceDate: Date(),
                    serviceFrequency: serviceFrequency,
                    serviceFrequencyEvery: serviceFrequencyInternval,
                    nextServiceDate: nil,
                    notes: "",
                    customerName: customerName,
                    customerId: BOW.customerId,
                    serviceLocationId: BOW.serviceLocationId,
                    bodyOfWaterId: BOW.id,
                    photoUrls: [],
                    isActive: true,
                    dateUninstalled: nil
                )
                try await dataService.uploadEquipment(companyId: companyId, equipment: equipment)
            }
        }
    }
    func markJobAsUnFinished(companyId: String, job: Job) async throws {
        //Update Data Model
        try await dataService.updateJobOperationStatus(companyId: companyId, jobId: job.id, operationStatus: .finished)
        self.operationStatus = .finished
        
        //See if is other company
        if job.otherCompany {
            if job.receiverId == companyId {
                if let senderId = job.senderId, let contractId = job.receivedLaborContractId {
                    //Update Labor Contract
                    try await dataService.updateLaborContractStatus(contractId: contractId, status: .finished)
                    //Get Labor Contract
                    let contract = try await dataService.getLaborContract(laborContractId: contractId)
                    //Update Job Info
                    for task in jobTaskList {
                        try dataService.updateJobTaskStatus(companyId: senderId, jobId: contract.senderJobId.id, taskId: task.id, status: .finished)
                        try await updateTaskHelperFunction(companyId: senderId, task: task)
                    }
                }
            }
        } else {
            for task in jobTaskList {
                //Update Task
                try await updateTaskHelperFunction(companyId: companyId, task: task)
            }
        }
    }

    func sendEstiamteToCustomer(companyId:String,job:Job) async throws {
        //DEVELOPER
        //Update Data Model
        //Call Function that Both Sends email and Sends Alert To Customer
        try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .estimate)
    }
    
    func sendInvoiceToCustomer(companyId:String,job:Job) async throws {
        //DEVELOPER
        //Update Data Model
        //Generate Invoice
        //Call Function that Both Sends email and Sends Alert To Customer
        try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .invoiced)
    }
    func markJobAsInvoiced(companyId:String,job:Job) async throws {
        let newJob = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: job.id)
        //Check To make sure if is sender company
        if job.otherCompany {
            if job.senderId == companyId {
                
                //Check if already accepted
//                if let invoiceDate = newJob.invoiceDate {
//                    self.alertMessage = "Already Invoiced \(shortDate(date: invoiceDate))"
//                    self.showAlert.toggle()
//                    throw FireBaseRead.unableToRead
//                } else {
                    print("Updated Job: \(job.internalId)")
                    print("Date: \(job.internalId)")
                    print("Company Id: \(companyId)")
                    print("Type: \(job.internalId)")
                    print("Notes: \(job.invoiceNotes)")
                    try await dataService.updateJobInvoiceDate(companyId: companyId, jobId: job.id, date: Date())
                    try await dataService.updateJobInvoiceRef(companyId: companyId, jobId: job.id, ref: companyId)
                    try await dataService.updateJobInvoiceType(companyId: companyId, jobId: job.id, type: .manual)
                    try await dataService.updateJobInvoiceNotes(companyId: companyId, jobId: job.id, notes: invoiceNotes)
                    try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .invoiced)
                
                    self.invoiceDate = Date()
                    self.invoiceType = .manual
                    self.isInvoiced = true
                    self.billingStatus = .invoiced
//                }
            }
        } else {
            print("Updated Job: \(job.internalId)")
            print("Date: \(job.internalId)")
            print("Company Id: \(companyId)")
            print("Type: \(job.internalId)")
            print("Notes: \(job.invoiceNotes)")
            try await dataService.updateJobInvoiceDate(companyId: companyId, jobId: job.id, date: Date())
            try await dataService.updateJobInvoiceRef(companyId: companyId, jobId: job.id, ref: companyId)
            try await dataService.updateJobInvoiceType(companyId: companyId, jobId: job.id, type: .manual)
            try await dataService.updateJobInvoiceNotes(companyId: companyId, jobId: job.id, notes: invoiceNotes)
            try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .invoiced)
    
            self.invoiceDate = Date()
            self.invoiceType = .manual
            self.isInvoiced = true
            self.billingStatus = .invoiced
        }
    }
    
    func markJobAsNotInvoiced(companyId:String,job:Job) async throws {
        let newJob = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: job.id)
        //Check To make sure if is sender company
        if job.otherCompany {
            if job.senderId == companyId {
                
                //Check if already accepted
                if let dateAccepted = newJob.dateEstimateAccepted {
                    //Reset Invoice Info
//                    try await dataService.updateJobDateEstimateAccepted(companyId: companyId, jobId: job.id, date: estiamtedAcceptedDate)
//                    try await dataService.updateJobEstiamteAcceptedById(companyId: companyId, jobId: job.id, id: companyId)
//                    try await dataService.updateJobEstiamteAcceptedByType(companyId: companyId, jobId: job.id, type: .company)
//                    try await dataService.updateJobEstimateAcceptedNotes(companyId: companyId, jobId: job.id, notes: estimateAcceptedNotes)
                    
                    try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .inProgress)
                    
                    self.billingStatus = .inProgress
                } else {
                    
                        self.alertMessage = "Not Invoiced "
                        self.showAlert.toggle()
                        throw FireBaseRead.unableToRead
                }
            }
        }
    }
    func markEstimateAsAccepted(companyId:String,job:Job) async throws {
        let newJob = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: job.id)
        //Check To make sure if is sender company
        if job.otherCompany {
            if job.senderId == companyId {
                
                //Check if already accepted
                if let dateAccepted = newJob.dateEstimateAccepted {
                    self.alertMessage = "Already Accepted \(shortDate(date:dateAccepted))"
                    self.showAlert.toggle()
                    throw FireBaseRead.unableToRead
                } else {
                    try await dataService.updateJobDateEstimateAccepted(companyId: companyId, jobId: job.id, date: estiamtedAcceptedDate)
                    try await dataService.updateJobEstiamteAcceptedById(companyId: companyId, jobId: job.id, id: companyId)
                    try await dataService.updateJobEstiamteAcceptedByType(companyId: companyId, jobId: job.id, type: .company)
                    try await dataService.updateJobEstimateAcceptedNotes(companyId: companyId, jobId: job.id, notes: estimateAcceptedNotes)
                    try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .accepted)
                }
            }
        }
    }
    
    func onDismissAddTaskSheet(companyId:String,serviceLocationId:String,jobId:String) async throws {
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)
        print("jobTaskList")
        print(jobTaskList)
    }
    
    func delete(
        companyId:String,
        jobId:String,
        serviceStopIds:[String],
        laborContractIds:[String]
    ) async throws {
        //DEVELOPER BUILD GUARD STATEMENTS
        for stopId in serviceStopIds {
            try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stopId)
        }
        for id in laborContractIds{
//            try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stopId)
        }
        try await dataService.deleteJob(companyId: companyId, jobId: jobId)

        
    }
    func deleteJobTaskItem(companyId:String,jobId:String,task:JobTask) async throws {
        
    }
}
