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

enum JobCommentFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "Open"
    case resolved = "Resolved"
    
    var id: String { rawValue }
}

@MainActor
final class JobDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var isPresentWorkOffer: Bool = false
    @Published private(set) var workOffers: [WorkOffer] = []
    
    @Published var plannedServiceStops: [JobPlannedServiceStop] = []
    @Published var isAddPlannedServiceStop: Bool = false
    @Published var plannedServiceStopToDelete: JobPlannedServiceStop?
    @Published var showDeletePlannedServiceStopConfirmation: Bool = false
    //Sheet Variables
    
    @Published var isPresentingMarkEstiamteAsAccepted: Bool = false
    @Published var isPresentingMarkJobAsInvoiced: Bool = false

    @Published var isEdit: Bool = false
    @Published var isAddTask: Bool = false
    @Published var isAddTaskGroup: Bool = false

    @Published var isAddShoppingList: Bool = false
    @Published var isPresentServiceStop: Bool = false
    @Published var scheduledServiceStopToEdit: ServiceStop?
    @Published var scheduledServiceStopToDelete: ServiceStop?
    @Published var showDeleteScheduledServiceStopConfirmation: Bool = false
    @Published var isPresentLaborContract: Bool = false
    @Published var showEstimate: Bool = false

    @Published var editShoppingItem: ShoppingListItem? = nil
    @Published var editTaskItem: JobTask? = nil

    @Published var taskGroupItems : [JobTaskGroupItem] = []
    @Published var description: String = "Tasks"

    @Published private(set) var chosenView: String = "Overview"
    @Published private(set) var viewOptionList:[String] = [
        "Overview",
        "Tasks",
        "Offers",
        "Schedule",
        "Materials",
        "Actual",
        "Billing"
    ]
    @Published private(set) var jobTaskList:[JobTask] = []
    @Published private(set) var comments: [JobComment] = []
    @Published var commentFilter: JobCommentFilter = .all
    @Published var newComment: String = ""
    @Published private(set) var commentsLoading: Bool = false
    @Published private(set) var addingComment: Bool = false
    
    @Published private(set) var taskTypes:[String] = []
    @Published private(set) var serviceStopIds:[String] = []
    
    @Published var shoppingItemList:[ShoppingListItem] = []
    @Published private(set) var purchasedItems: [PurchasedItem] = []
    @Published var isPresentPurchasedItemSelector: Bool = false
    @Published private(set) var availablePurchasedItems: [PurchasedItem] = []
    @Published private(set) var availablePurchasedItemCategories: [String: DataBaseItemCategory] = [:]
    @Published private(set) var isLoadingAvailablePurchasedItems: Bool = false
    
    @Published private(set) var serviceStops:[ServiceStop] = []
    @Published private(set) var actualPayLineItems: [TechnicianPayLineItem] = []

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
    @Published private(set) var sourceRepairRequest: RepairRequest? = nil
    
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
    @Published var alertMessage:String = ""
    @Published var showAlert:Bool = false
    
    //Functions
    var filteredComments: [JobComment] {
        switch commentFilter {
        case .all:
            return comments
        case .open:
            return comments.filter { !$0.resolved }
        case .resolved:
            return comments.filter { $0.resolved }
        }
    }
    

    
    func onLoad(companyId:String,serviceLocationId:String,job:Job) async throws {
        print("")
        self.invoiceRef = job.invoiceRef ?? ""
        self.invoiceNotes = job.invoiceNotes ?? ""
        self.invoiceDate = job.invoiceDate
        self.invoiceType = job.invoiceType
        if job.billingStatus == .invoiced {
            self.isInvoiced = true
        }
        self.plannedServiceStops = try await dataService.fetchJobPlannedServiceStops(
            companyId: companyId,
            jobId: job.id
        )
        self.description = job.description
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: job.id)
        print("jobTaskList \(jobTaskList.count)")
        
        self.shoppingItemList = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
        print("shoppingItemList \(shoppingItemList.count)")
  
        self.operationStatus = job.operationStatus
        self.billingStatus = job.billingStatus
        self.sourceRepairRequest = nil
        if let sourceRepairRequestId = job.sourceRepairRequestId,
           !sourceRepairRequestId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                self.sourceRepairRequest = try await dataService.getSpecificRepairRequest(
                    companyId: companyId,
                    repairRequestId: sourceRepairRequestId
                )
            } catch {
                print("[][load source repair request] Error \(error)")
            }
        }
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
                    if let id = item.dbItemId, let quantiyStr = item.quantity, let quantiy = Int(quantiyStr) {
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
                if let id = item.dbItemId, let quantiyStr = item.quantity, let quantiy = Int(quantiyStr) {
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
        self.taskTypes = JobTaskType.allCases.map(\.rawValue)
        
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = job.serviceStopIds
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
        try await loadServiceStopsForJob(companyId: companyId, job: job, jobTasks: jobTaskList)
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

        //
#warning(" Dont know if i Need these Developer")

//        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
//        self.serviceStopTemplates = try await SettingsManager.shared.getAllServiceStopTemplates(companyId: companyId)
        
        self.workOffers = try await dataService.fetchWorkOffers(
            companyId: companyId,
            jobId: job.id
        )
        
        self.actualPayLineItems = try await fetchActualPayLineItemsForLoadedStops(
            companyId: companyId
        )
        
        try await getPurchaseCost(
            companyId: companyId,
            purchaseIds: job.purchasedItemsIds ?? [],
            jobId: job.id
        )
        
        await loadComments(companyId: companyId, jobId: job.id)
    }
    
    func loadComments(companyId: String, jobId: String) async {
        commentsLoading = true
        defer { commentsLoading = false }
        
        do {
            comments = try await dataService.getWorkOrderComments(
                companyId: companyId,
                workOrderId: jobId
            )
        } catch {
            print("[][load job comments] Error \(error)")
            alertMessage = "Could not load comments."
            showAlert = true
        }
    }
    
    func addComment(
        companyId: String,
        jobId: String,
        userId: String,
        userName: String
    ) async {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedComment.isEmpty else {
            alertMessage = "Write a comment first."
            showAlert = true
            return
        }
        
        guard !userId.isEmpty else {
            alertMessage = "Missing signed-in user."
            showAlert = true
            return
        }
        
        addingComment = true
        defer { addingComment = false }
        
        let commentId = "comp_wo_com_" + UUID().uuidString
        let jobComment = JobComment(
            id: commentId,
            jobId: jobId,
            companyId: companyId,
            userId: userId,
            userName: userName,
            authorId: userId,
            authorName: userName,
            date: Date(),
            comment: trimmedComment,
            resolved: false
        )
        
        do {
            try await dataService.addWorkOrderComment(
                companyId: companyId,
                workOrderId: jobId,
                comment: jobComment
            )
            newComment = ""
            await loadComments(companyId: companyId, jobId: jobId)
        } catch {
            print("[][add job comment] Error \(error)")
            alertMessage = "Could not add comment."
            showAlert = true
        }
    }
    
    func setCommentResolved(
        companyId: String,
        jobId: String,
        commentId: String,
        resolved: Bool
    ) async {
        do {
            try await dataService.updateWorkOrderCommentResolved(
                companyId: companyId,
                workOrderId: jobId,
                commentId: commentId,
                resolved: resolved
            )
            await loadComments(companyId: companyId, jobId: jobId)
        } catch {
            print("[][update job comment resolved] Error \(error)")
            alertMessage = "Could not update comment."
            showAlert = true
        }
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
        self.taskTypes = JobTaskType.allCases.map(\.rawValue)
        
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
        try await loadServiceStopsForJob(companyId: companyId, job: job, jobTasks: jobTaskList)
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
        
        self.workOffers = try await dataService.fetchWorkOffers(
            companyId: companyId,
            jobId: job.id
        )

        self.actualPayLineItems = try await fetchActualPayLineItemsForLoadedStops(
            companyId: companyId
        )

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
        self.taskTypes = JobTaskType.allCases.map(\.rawValue)
        
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
        try await loadServiceStopsForJob(companyId: companyId, job: job, jobTasks: jobTaskList)
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
            self.serviceLocation = ServiceLocation(
                id: "",
                nickName: "",
                address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
                gateCode: "",
                mainContact: Contact(
                    id: "",
                    name: "",
                    phoneNumber: "",
                    email: ""
                ),
                bodiesOfWaterId: [],
                rateType: "",
                laborType: "",
                chemicalCost: "",
                laborCost: "",
                rate: "",
                customerId: "",
                customerName: "",
                preText: false,
                isActive: true
            )
        }
    }
    
    func onChangeOfServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws {
        self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: serviceLocation)

        
        if bodiesOfWater.count != 0 {
            self.bodyOfWater = bodiesOfWater.first!
        } else {
            self.bodyOfWater = BodyOfWater(
                id: "",
                name: "",
                gallons: "",
                material: "",
                customerId: "",
                serviceLocationId: "",
                lastFilled: Date(),
                isActive: true
            )
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
                type: .filter,
                typeId: "",
                make: "",
                makeId: "",
                model: "",
                modelId: "",
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
    
    func loadServiceStopsForJob(
        companyId: String,
        job: Job,
        jobTasks: [JobTask]
    ) async throws {
        var ids = job.serviceStopIds
        ids.append(contentsOf: jobTasks.map { $0.serviceStopId.id })
        ids.removeDuplicates()
        ids.remove("")

        var stopsById: [String: ServiceStop] = [:]
        print("serviceStopIds: \(ids)")

        for serviceStopId in ids {
            do {
                let stop = try await dataService.getServiceStopById(
                    serviceStopId: serviceStopId,
                    companyId: companyId
                )
                stopsById[stop.id] = stop
            } catch {
                print("[][loadServiceStopsForJob] Could not load stop \(serviceStopId): \(error)")
            }
        }

        let jobIdStops = try await dataService.getServiceStopByJobId(
            companyId: companyId,
            jobId: job.id
        )

        for stop in jobIdStops {
            stopsById[stop.id] = stop
        }

        self.serviceStops = Array(stopsById.values)
            .sorted { $0.serviceDate > $1.serviceDate }
        self.serviceStopIds = self.serviceStops.map(\.id)
    }

    func getPurchaseCost(
        companyId: String,
        purchaseIds: [String],
        jobId: String
    ) async throws {
        var total: Double = 0
        var itemsById: [String: PurchasedItem] = [:]

        for id in purchaseIds {
            let purchase = try await dataService.getSingleItem(
                itemId: id,
                companyId: companyId
            )

            itemsById[purchase.id] = purchase
        }

        let attachedPurchases = try await Firestore.firestore()
            .collection("companies/\(companyId)/purchasedItems")
            .whereField("jobId", isEqualTo: jobId)
            .getDocuments(as: PurchasedItem.self)

        for purchase in attachedPurchases {
            itemsById[purchase.id] = purchase
        }

        let items = Array(itemsById.values)
        self.purchasedItems = items.sorted { $0.date > $1.date }
        total = items.reduce(0) { $0 + $1.totalAfterTax }
        self.purchasedPartCost = total
    }

    func loadUnassignedPurchasedItems(
        companyId: String,
        startDate: Date,
        endDate: Date
    ) async throws {
        isLoadingAvailablePurchasedItems = true
        defer { isLoadingAvailablePurchasedItems = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: startDate)
        let endOfDay = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: endDate
        ) ?? endDate

        let dateRangeItems = try await Firestore.firestore()
            .collection("companies/\(companyId)/purchasedItems")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThanOrEqualTo: endOfDay)
            .order(by: "date", descending: true)
            .getDocuments(as: PurchasedItem.self)
        
        let unassignedItems = dateRangeItems.filter { !$0.isAssignedToJob }
        availablePurchasedItems = unassignedItems
        availablePurchasedItemCategories = await categoryMapForPurchasedItems(
            companyId: companyId,
            items: unassignedItems
        )
    }

    func attachPurchasedItemsToJob(
        companyId: String,
        job: Job,
        items: [PurchasedItem]
    ) async throws {
        guard !items.isEmpty else { return }

        let selectedIds = items.map(\.id)
        let selectedIdSet = Set(selectedIds)

        for item in items {
            try await dataService.updatePurchasedWorkOrderId(
                currentItem: item,
                workOrderId: job.id,
                companyId: companyId
            )
        }

        try await Firestore.firestore()
            .collection("companies/\(companyId)/workOrders")
            .document(job.id)
            .updateData([
                "purchasedItemsIds": FieldValue.arrayUnion(selectedIds)
            ])

        let attachedItems = items.map { item in
            var copy = item
            copy.jobId = job.id
            copy.workOrderId = job.id
            copy.assignedJobId = job.id
            copy.assignedToJob = true
            copy.assignmentStatus = "assignedToJob"
            copy.billingOwner = "job"
            copy.jobBillingStatus = "handledByJob"
            copy.jobBillable = item.isJobBillable
            copy.jobBillingRate = item.jobMaterialBillingRate
            return copy
        }

        purchasedItems = (attachedItems + purchasedItems.filter { !selectedIdSet.contains($0.id) })
            .sorted { $0.date > $1.date }
        purchasedPartCost = purchasedItems.reduce(0) { $0 + $1.totalAfterTax }
        availablePurchasedItems.removeAll { selectedIdSet.contains($0.id) }
        let selectedDatabaseItemIds = Set(items.map(\.itemId))
        availablePurchasedItemCategories = availablePurchasedItemCategories.filter { key, _ in
            !selectedIdSet.contains(key) && !selectedDatabaseItemIds.contains(key)
        }
    }

    private func categoryMapForPurchasedItems(
        companyId: String,
        items: [PurchasedItem]
    ) async -> [String: DataBaseItemCategory] {
        let databaseItemIds = Set(items.map(\.itemId).filter { !$0.isEmpty })
        var categoryByDatabaseItemId: [String: DataBaseItemCategory] = [:]

        for databaseItemId in databaseItemIds {
            do {
                let databaseItem = try await dataService.getDataBaseItem(
                    companyId: companyId,
                    dataBaseItemId: databaseItemId
                )
                categoryByDatabaseItemId[databaseItemId] = databaseItem.category
            } catch {
                print("[JobDetailViewModel][categoryMapForPurchasedItems] Could not load database item \(databaseItemId): \(error)")
            }
        }

        var categoryByPurchasedItemId: [String: DataBaseItemCategory] = [:]
        for item in items {
            guard let category = categoryByDatabaseItemId[item.itemId] else { continue }
            categoryByPurchasedItemId[item.id] = category
            categoryByPurchasedItemId[item.itemId] = category
        }

        return categoryByPurchasedItemId
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
        rate:Int,
        laborCost:String,
        description:String
    ) async throws{
            //Check Which Parts Need Updating
            let adminId = admin.userId.isEmpty ? admin.id : admin.userId
            if adminId != updatingJob.adminId || admin.userName != updatingJob.adminName{
                print("Change in Admin")
                let name:String = admin.userName
                try await dataService.updateJobAdmin(companyId: companyId, jobId: updatingJob.id, adminName: name, adminId: adminId)
            }
     
            if operationStatus != updatingJob.operationStatus {
                print("Change in Operation Status")
                try await dataService.updateJobOperationStatus(companyId: companyId, jobId: updatingJob.id, operationStatus: operationStatus)            }
            if billingStatus != updatingJob.billingStatus {
                print("Change in Billing Status")
                try await dataService.updateJobBillingStatus(companyId: companyId, jobId: updatingJob.id, billingStatus: billingStatus)
            }
            if updatingJob.rate != rate {
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
    
    private func addJobKeyMomentComment(
        companyId: String,
        jobId: String,
        userId: String,
        userName: String,
        comment: String
    ) async throws {
        let authorName = userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown" : userName
        let jobComment = JobComment(
            id: "comp_wo_com_" + UUID().uuidString,
            jobId: jobId,
            companyId: companyId,
            userId: userId,
            userName: authorName,
            authorId: userId,
            authorName: authorName,
            date: Date(),
            comment: comment,
            resolved: true
        )

        try await dataService.addWorkOrderComment(
            companyId: companyId,
            workOrderId: jobId,
            comment: jobComment
        )
        comments.insert(jobComment, at: 0)
    }

    func markJobAsFinished(
        companyId: String,
        job: Job,
        completedByUserId: String = "",
        completedByUserName: String = "",
        addCompletionComment: Bool = true
    ) async throws {
        //Update Data Model
        try await dataService.updateJobOperationStatus(companyId: companyId, jobId: job.id, operationStatus: .finished)
        self.operationStatus = .finished
        let completedByName = completedByUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown" : completedByUserName
        
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
                        try await updateTaskHelperFunction(companyId: senderId, task: task, jobId: contract.senderJobId.id)
                    }
                }
            }
        } else {
            for task in jobTaskList {
                //Update Task
                try dataService.updateJobTaskStatus(companyId: companyId, jobId: job.id, taskId: task.id, status: .finished)
                try await updateTaskHelperFunction(companyId: companyId, task: task, jobId: job.id)
            }
        }

        if addCompletionComment {
            try await addJobKeyMomentComment(
                companyId: companyId,
                jobId: job.id,
                userId: completedByUserId,
                userName: completedByName,
                comment: "Job finished by \(completedByName)."
            )
        }
    }

    func markJobAsFinished(
        companyId: String,
        job: Job,
        jobTasks: [JobTask],
        completedByUserId: String = "",
        completedByUserName: String = "",
        addCompletionComment: Bool = true
    ) async throws {
        self.jobTaskList = jobTasks
        try await markJobAsFinished(
            companyId: companyId,
            job: job,
            completedByUserId: completedByUserId,
            completedByUserName: completedByUserName,
            addCompletionComment: addCompletionComment
        )
    }
    func updateTaskHelperFunction(
        companyId: String,
        task: JobTask,
        jobId: String = "",
        recordEquipmentHistory: Bool = true
    ) async throws {
        
        //Developer
        switch task.type {
        case .basic, .clean:
            print("Do nothing")
        case .cleanFilter:
            if recordEquipmentHistory {
                try await EquipmentTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        case .maintenance:
            if recordEquipmentHistory {
                try await EquipmentTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        case .repair:
            if recordEquipmentHistory {
                try await EquipmentTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        case .emptyWater:
            if recordEquipmentHistory {
                try await BodyOfWaterTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        case .fillWater:
            if recordEquipmentHistory {
                try await BodyOfWaterTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        case .inspection:
            print("Something")
        case .install:
            try await completeEquipmentInstallOrReplacement(
                companyId: companyId,
                task: task,
                jobId: jobId,
                replacesExistingEquipment: false
            )
        case .remove:
            if task.equipmentId != "" {
                print("Make Equipment Inactive")
                try dataService.updateEquipmentIsActive(companyId: companyId, equipmentId: task.equipmentId, isActive: false)
                try dataService.updateEquipmentDateUninstalled(companyId: companyId, equipmentId: task.equipmentId, dateUninstalled: Date())
            }
        case .replace:
            try await completeEquipmentInstallOrReplacement(
                companyId: companyId,
                task: task,
                jobId: jobId,
                replacesExistingEquipment: true
            )
            if recordEquipmentHistory {
                try await EquipmentTaskHistoryService(dataService: dataService)
                    .recordJobTaskCompletion(companyId: companyId, task: task, jobId: jobId)
            }
        }
    }

    private struct EquipmentInstallSource {
        let dataBaseItem: DataBaseItem
        let shoppingListItem: ShoppingListItem?
        let purchasedItem: PurchasedItem?
    }

    private func completeEquipmentInstallOrReplacement(
        companyId: String,
        task: JobTask,
        jobId: String,
        replacesExistingEquipment: Bool
    ) async throws {
        guard !task.bodyOfWaterId.isEmpty,
              let source = try await resolveEquipmentInstallSource(
                companyId: companyId,
                task: task,
                jobId: jobId
              ),
              source.dataBaseItem.category == .equipment else {
            return
        }

        let bodyOfWater = try await dataService.getSpecificBodyOfWater(
            companyId: companyId,
            bodyOfWaterId: task.bodyOfWaterId
        )
        let customer = try await dataService.getCustomerById(
            companyId: companyId,
            customerId: bodyOfWater.customerId
        )
        let customerName = "\(customer.firstName) \(customer.lastName)"
        let defaults = equipmentDefaults(for: source.dataBaseItem)
        let installedAt = Date()
        let existingEquipmentId = firstNonEmpty([
            task.installedEquipmentId,
            task.replacementEquipmentId
        ])
        let equipmentId = existingEquipmentId.isEmpty ? "comp_equ_" + UUID().uuidString : existingEquipmentId

        let equipment = Equipment(
            id: equipmentId,
            name: source.dataBaseItem.name,
            type: defaults.category,
            typeId: source.dataBaseItem.equipmentTypeId ?? "",
            make: source.dataBaseItem.equipmentMake ?? "",
            makeId: source.dataBaseItem.equipmentMakeId ?? "",
            model: source.dataBaseItem.equipmentModel ?? source.dataBaseItem.name,
            modelId: source.dataBaseItem.equipmentModelId ?? source.dataBaseItem.universalEquipmentId ?? "",
            dateInstalled: installedAt,
            status: .operational,
            needsService: defaults.needsService,
            cleanFilterPressure: nil,
            currentPressure: nil,
            lastServiceDate: defaults.needsService ? installedAt : nil,
            serviceFrequency: defaults.serviceFrequency,
            serviceFrequencyEvery: defaults.serviceFrequencyEvery,
            nextServiceDate: nil,
            notes: source.purchasedItem?.notes ?? source.shoppingListItem?.description ?? "",
            customerName: customerName,
            customerId: bodyOfWater.customerId,
            serviceLocationId: bodyOfWater.serviceLocationId,
            bodyOfWaterId: bodyOfWater.id,
            photoUrls: [],
            isActive: true,
            dateUninstalled: nil
        )

        try await dataService.uploadEquipment(companyId: companyId, equipment: equipment)

        let db = Firestore.firestore()
        try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipment.id)
            .setData([
                "active": true,
                "universalEquipmentId": source.dataBaseItem.universalEquipmentId ?? source.dataBaseItem.equipmentModelId ?? "",
                "sourceDataBaseItemId": source.dataBaseItem.id,
                "sourceShoppingListItemId": source.shoppingListItem?.id ?? task.shoppingListItemId ?? "",
                "sourcePurchasedItemId": source.purchasedItem?.id ?? task.purchasedItemId ?? "",
                "installedFromJobId": jobId,
                "installedFromTaskId": task.id,
                "replacesEquipmentId": replacesExistingEquipment ? task.equipmentId : ""
            ], merge: true)

        if replacesExistingEquipment, !task.equipmentId.isEmpty {
            try dataService.updateEquipmentIsActive(
                companyId: companyId,
                equipmentId: task.equipmentId,
                isActive: false
            )
            try dataService.updateEquipmentDateUninstalled(
                companyId: companyId,
                equipmentId: task.equipmentId,
                dateUninstalled: installedAt
            )
            try dataService.updateEquipmentStatus(
                companyId: companyId,
                equipmentId: task.equipmentId,
                status: .replaced
            )
            try await db
                .collection("companies")
                .document(companyId)
                .collection("equipment")
                .document(task.equipmentId)
                .setData([
                    "active": false,
                    "replacedByEquipmentId": equipment.id,
                    "replacementJobId": jobId,
                    "replacementTaskId": task.id
                ], merge: true)
        }

        try await syncInstalledEquipmentLinks(
            companyId: companyId,
            task: task,
            jobId: jobId,
            equipmentId: equipment.id,
            source: source,
            installedAt: installedAt,
            replacesExistingEquipment: replacesExistingEquipment
        )
    }

    private func resolveEquipmentInstallSource(
        companyId: String,
        task: JobTask,
        jobId: String
    ) async throws -> EquipmentInstallSource? {
        let linkedShoppingItem = try await linkedShoppingListItem(
            companyId: companyId,
            task: task,
            jobId: jobId
        )
        let explicitDataBaseItemId = task.dataBaseItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        let shoppingDataBaseItemId = firstNonEmpty([
            linkedShoppingItem?.dbItemId,
            linkedShoppingItem?.genericItemId
        ])
        let dataBaseItemId = firstNonEmpty([explicitDataBaseItemId, shoppingDataBaseItemId])
        let purchasedItem = try await linkedPurchasedItem(
            companyId: companyId,
            task: task,
            jobId: jobId,
            dataBaseItemId: dataBaseItemId,
            shoppingListItem: linkedShoppingItem
        )
        let resolvedDataBaseItemId = firstNonEmpty([
            dataBaseItemId,
            purchasedItem?.itemId
        ])

        if !resolvedDataBaseItemId.isEmpty {
            let dataBaseItem = try await dataService.getDataBaseItem(
                companyId: companyId,
                dataBaseItemId: resolvedDataBaseItemId
            )
            return EquipmentInstallSource(
                dataBaseItem: dataBaseItem,
                shoppingListItem: linkedShoppingItem,
                purchasedItem: purchasedItem
            )
        }

        return try await singlePurchasedEquipmentSource(
            companyId: companyId,
            jobId: jobId,
            shoppingListItem: linkedShoppingItem
        )
    }

    private func linkedShoppingListItem(
        companyId: String,
        task: JobTask,
        jobId: String
    ) async throws -> ShoppingListItem? {
        if let shoppingListItemId = task.shoppingListItemId,
           !shoppingListItemId.isEmpty {
            return try? await dataService.getSpecificShoppingListItem(
                companyId: companyId,
                shoppingListItemId: shoppingListItemId
            )
        }

        if let loadedItem = shoppingItemList.first(where: { item in
            item.linkedTaskId == task.id
        }) {
            return loadedItem
        }

        let jobItems = try await dataService.getAllShoppingListItemsByUserForJob(
            companyId: companyId,
            jobId: jobId,
            category: "Job"
        )
        return jobItems.first { item in
            item.linkedTaskId == task.id
        }
    }

    private func linkedPurchasedItem(
        companyId: String,
        task: JobTask,
        jobId: String,
        dataBaseItemId: String,
        shoppingListItem: ShoppingListItem?
    ) async throws -> PurchasedItem? {
        let explicitPurchasedItemId = firstNonEmpty([
            task.purchasedItemId,
            shoppingListItem?.purchasedItem
        ])

        if !explicitPurchasedItemId.isEmpty {
            return try? await dataService.getSingleItem(
                itemId: explicitPurchasedItemId,
                companyId: companyId
            )
        }

        guard !dataBaseItemId.isEmpty else { return nil }

        let candidates = try await purchasedItemCandidates(companyId: companyId, jobId: jobId)
        return candidates.first { item in
            item.itemId == dataBaseItemId || item.universalEquipmentId == dataBaseItemId
        }
    }

    private func singlePurchasedEquipmentSource(
        companyId: String,
        jobId: String,
        shoppingListItem: ShoppingListItem?
    ) async throws -> EquipmentInstallSource? {
        let candidates = try await purchasedItemCandidates(companyId: companyId, jobId: jobId)
        var matches: [(DataBaseItem, PurchasedItem)] = []

        for item in candidates {
            guard !item.itemId.isEmpty,
                  let dataBaseItem = try? await dataService.getDataBaseItem(
                    companyId: companyId,
                    dataBaseItemId: item.itemId
                  ),
                  dataBaseItem.category == .equipment else {
                continue
            }

            matches.append((dataBaseItem, item))
        }

        guard matches.count == 1,
              let match = matches.first else {
            return nil
        }

        return EquipmentInstallSource(
            dataBaseItem: match.0,
            shoppingListItem: shoppingListItem,
            purchasedItem: match.1
        )
    }

    private func purchasedItemCandidates(
        companyId: String,
        jobId: String
    ) async throws -> [PurchasedItem] {
        if !purchasedItems.isEmpty {
            return purchasedItems
        }

        var itemsById: [String: PurchasedItem] = [:]
        let fields = ["jobId", "workOrderId", "assignedJobId"]

        for field in fields {
            let items = try await Firestore.firestore()
                .collection("companies/\(companyId)/purchasedItems")
                .whereField(field, isEqualTo: jobId)
                .getDocuments(as: PurchasedItem.self)

            for item in items {
                itemsById[item.id] = item
            }
        }

        return Array(itemsById.values)
    }

    private func syncInstalledEquipmentLinks(
        companyId: String,
        task: JobTask,
        jobId: String,
        equipmentId: String,
        source: EquipmentInstallSource,
        installedAt: Date,
        replacesExistingEquipment: Bool
    ) async throws {
        let db = Firestore.firestore()
        var taskUpdates: [String: Any] = [
            "status": JobTaskStatus.finished.rawValue,
            "installedEquipmentId": equipmentId,
            "dataBaseItemId": source.dataBaseItem.id
        ]

        if replacesExistingEquipment {
            taskUpdates["replacementEquipmentId"] = equipmentId
        }

        if let shoppingListItemId = source.shoppingListItem?.id ?? task.shoppingListItemId,
           !shoppingListItemId.isEmpty {
            taskUpdates["shoppingListItemId"] = shoppingListItemId
            try await db
                .collection("companies")
                .document(companyId)
                .collection("shoppingList")
                .document(shoppingListItemId)
                .setData([
                    "status": ShoppingListStatus.installed.rawValue,
                    "linkedTaskStatus": JobTaskStatus.finished.rawValue,
                    "installedEquipmentId": equipmentId,
                    "installedAt": installedAt
                ], merge: true)
        }

        if let purchasedItem = source.purchasedItem {
            taskUpdates["purchasedItemId"] = purchasedItem.id
            try await db
                .collection("companies")
                .document(companyId)
                .collection("purchasedItems")
                .document(purchasedItem.id)
                .setData([
                    "installedEquipmentId": equipmentId,
                    "installedAt": installedAt,
                    "installationJobId": jobId,
                    "installationTaskId": task.id,
                    "assignmentStatus": "installed",
                    "jobMaterialStatus": "Installed"
                ], merge: true)
        }

        try await db
            .collection("companies")
            .document(companyId)
            .collection("workOrders")
            .document(jobId)
            .collection("tasks")
            .document(task.id)
            .setData(taskUpdates, merge: true)

        if let index = jobTaskList.firstIndex(where: { $0.id == task.id }) {
            jobTaskList[index].installedEquipmentId = equipmentId
            jobTaskList[index].replacementEquipmentId = replacesExistingEquipment ? equipmentId : nil
            jobTaskList[index].shoppingListItemId = source.shoppingListItem?.id ?? task.shoppingListItemId
            jobTaskList[index].purchasedItemId = source.purchasedItem?.id ?? task.purchasedItemId
            jobTaskList[index].dataBaseItemId = source.dataBaseItem.id
            jobTaskList[index].status = .finished
        }
    }

    private func equipmentDefaults(
        for dataBaseItem: DataBaseItem
    ) -> (category: EquipmentCategory, needsService: Bool, serviceFrequency: Int?, serviceFrequencyEvery: EquipmentFrequency?) {
        let category: EquipmentCategory
        var needsService = false
        var serviceFrequency: Int? = nil
        var serviceFrequencyEvery: EquipmentFrequency? = nil

        if let rawType = dataBaseItem.equipmentType,
           let mappedCategory = EquipmentCategory(rawValue: rawType) {
            category = mappedCategory
        } else {
            switch dataBaseItem.subCategory {
            case .heater:
                category = .heater
            case .filter:
                category = .filter
                needsService = true
                serviceFrequency = 6
                serviceFrequencyEvery = .monthly
            case .pump:
                category = .pump
            case .cleaner:
                category = .cleaner
            case .saltCell:
                category = .saltCell
                needsService = true
                serviceFrequency = 6
                serviceFrequencyEvery = .monthly
            case .light:
                category = .light
            case .controlSystem:
                category = .controlSystem
            case .autoChlorinator:
                category = .autoChlorinator
            default:
                category = .autoChlorinator
            }
        }

        return (category, needsService, serviceFrequency, serviceFrequencyEvery)
    }

    private func firstNonEmpty(_ values: [String?]) -> String {
        values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
    }

    func markJobAsUnFinished(companyId: String, job: Job) async throws {
        //Update Data Model
        try await dataService.updateJobOperationStatus(companyId: companyId, jobId: job.id, operationStatus: .inProgress)
        self.operationStatus = .inProgress
        
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
                        try await updateTaskHelperFunction(companyId: senderId, task: task, jobId: contract.senderJobId.id, recordEquipmentHistory: false)
                    }
                }
            }
        } else {
            for task in jobTaskList {
                //Update Task
                try await updateTaskHelperFunction(companyId: companyId, task: task, jobId: job.id, recordEquipmentHistory: false)
            }
        }
    }

    func sendEstiamteToCustomer(companyId:String,job:Job) async throws {
        //DEVELOPER
        //Update Data Model
        //Call Function that Both Sends email and Sends Alert To Customer
        try await dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .estimate)
        self.billingStatus = .estimate
        try await FunctionsManager.shared.sendJobEstimate(companyId: companyId, jobId: job.id)
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
    
    func markEstimateAsAccepted(
        companyId: String,
        job: Job,
        acceptedByUserId: String = "",
        acceptedByUserName: String = ""
    ) async throws {
        let newJob = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: job.id)
        //Check if already accepted
        if let dateAccepted = newJob.dateEstimateAccepted {
            self.alertMessage = "Already Accepted \(shortDate(date:dateAccepted))"
            self.showAlert.toggle()
            throw FireBaseRead.unableToRead
        } else {
            try dataService.updateJobDateEstimateAccepted(companyId: companyId, jobId: job.id, date: estiamtedAcceptedDate)
            try dataService.updateJobEstiamteAcceptedById(companyId: companyId, jobId: job.id, id: companyId)
            try dataService.updateJobEstiamteAcceptedByType(companyId: companyId, jobId: job.id, type: .company)
            try dataService.updateJobEstimateAcceptedNotes(companyId: companyId, jobId: job.id, notes: estimateAcceptedNotes)
            try dataService.updateJobBillingStatus(companyId: companyId, jobId: job.id, billingStatus: .accepted)
            self.billingStatus = .accepted
            let acceptedByName = acceptedByUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown" : acceptedByUserName
            let trimmedNotes = estimateAcceptedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            try await addJobKeyMomentComment(
                companyId: companyId,
                jobId: job.id,
                userId: acceptedByUserId,
                userName: acceptedByName,
                comment: [
                    "Estimate accepted by \(acceptedByName).",
                    trimmedNotes.isEmpty ? "" : "Acceptance notes: \(trimmedNotes)"
                ]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n\n")
            )
        }
    }
    
    func onDismissAddTaskSheet(companyId:String,serviceLocationId:String,jobId:String) {
        Task{
            do {
                self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)
                print("[][onDismissAddTaskSheet]jobTaskList")
                print(jobTaskList)
            } catch {
                print("[][] Error \(error)")
            }
        }
    }
    
    func onDismissAddShoppingListItem(companyId:String,serviceLocationId:String,jobId:String){
        Task{
            do {
                self.shoppingItemList = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: jobId, category: "Job")
                print("[][onDismissAddShoppingListItem]shoppingItemList")
                print(shoppingItemList)
            } catch {
                print("[][] Error \(error)")
            }
        }
    }
    
    func delete(
        companyId:String,
        jobId:String,
        serviceStopIds:[String],
        laborContractIds:[String]
    ) async throws {
        //DEVELOPER BUILD GUARD STATEMENTS
        print("  [JobDetailViewModel][Delete] Start")
        try await dataService.deleteJob(companyId: companyId, jobId: jobId)
        print("  [JobDetailViewModel][Delete] Job")

        //only not finished service stops
        for stopId in serviceStopIds {
            try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stopId)
        }
        
        print("  [JobDetailViewModel][Delete] Service Stops")
        //Delete Items
        
        //Tasks get deleted with job
        
              
    }
    
    func deleteJobTaskItem(companyId:String,jobId:String,task:JobTask) {
        Task{
            do {
                try await dataService.deleteJobTaskItem(companyId: companyId, jobId: jobId, taskId: task.id)
            } catch {
                print("[][deleteJobTaskItem] Error \(error)")
            }
        }
    }

    func deleteScheduledServiceStopFromJob(
        companyId: String,
        jobId: String,
        serviceStop: ServiceStop
    ) async throws {
        guard serviceStop.operationStatus == .notFinished else {
            alertMessage = "Only not-finished scheduled stops can be deleted from the job schedule."
            showAlert = true
            return
        }

        let serviceStopTasks = try await dataService.getServiceStopTasks(
            companyId: companyId,
            serviceStopId: serviceStop.id
        )

        for serviceStopTask in serviceStopTasks {
            try await dataService.deleteServiceStopTask(
                companyId: companyId,
                serviceStopId: serviceStop.id,
                taskId: serviceStopTask.id
            )

            guard !serviceStopTask.jobTaskId.isEmpty else {
                continue
            }

            try dataService.updateJobTaskServiceStopId(
                companyId: companyId,
                jobId: jobId,
                taskId: serviceStopTask.jobTaskId,
                serviceStopId: IdInfo(id: "", internalId: "")
            )
            try dataService.updateJobTaskWorkerId(
                companyId: companyId,
                jobId: jobId,
                taskId: serviceStopTask.jobTaskId,
                workerId: ""
            )
            try dataService.updateJobTaskWorkerName(
                companyId: companyId,
                jobId: jobId,
                taskId: serviceStopTask.jobTaskId,
                workerName: ""
            )
            try dataService.updateJobTaskWorkerType(
                companyId: companyId,
                jobId: jobId,
                taskId: serviceStopTask.jobTaskId,
                workerType: .notAssigned
            )
            try dataService.updateJobTaskStatus(
                companyId: companyId,
                jobId: jobId,
                taskId: serviceStopTask.jobTaskId,
                status: .draft
            )
        }

        try await dataService.deleteServiceStopById(
            companyId: companyId,
            serviceStopId: serviceStop.id
        )
    }
    
    func deleteShoppingListItem(companyId:String, jobId:String, item:ShoppingListItem) {
        Task{
            do {
                try await dataService.deleteShoppingListItem(companyId: companyId, shoppingListItemId: item.id)
            } catch {
                print("[][deleteShoppingListItem] Error \(error)")
            }
        }
    }
}

// MARK: - WORK OFFERS EXTENSION
extension JobDetailViewModel {
    func reloadWorkOffers(
        companyId: String,
        jobId: String
    ) async {
        do {
            self.workOffers = try await dataService.fetchWorkOffers(
                companyId: companyId,
                jobId: jobId
            )
            self.actualPayLineItems = try await fetchActualPayLineItemsForLoadedStops(
                companyId: companyId
            )
        } catch {
            print("[][reloadWorkOffers] Error \(error)")
        }
    }
}
// MARK: - ACTUAL WORK / PAYROLL EXTENSION

extension JobDetailViewModel {

    func reloadActualPayLineItems(
        companyId: String
    ) async {
        do {
            self.actualPayLineItems = try await fetchActualPayLineItemsForLoadedStops(
                companyId: companyId
            )
        } catch {
            print("[][reloadActualPayLineItems] Error \(error)")
            self.actualPayLineItems = []
        }
    }

    func fetchActualPayLineItemsForLoadedStops(
        companyId: String
    ) async throws -> [TechnicianPayLineItem] {
        let stopIds = Set(serviceStops.map { $0.id })

        guard !stopIds.isEmpty else {
            return []
        }

        let dates = serviceStops.map { $0.serviceDate }

        guard let minDate = dates.min(),
              let maxDate = dates.max() else {
            return []
        }

        let startDate = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: minDate
        ) ?? minDate

        let endDate = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: maxDate
        ) ?? maxDate

        let items = try await dataService.fetchTechnicianPayLineItems(
            companyId: companyId,
            startDate: startDate,
            endDate: endDate
        )

        return items
            .filter { item in
                guard let serviceStopId = item.serviceStopId else {
                    return false
                }

                return stopIds.contains(serviceStopId)
            }
            .sorted {
                if $0.completedDate == $1.completedDate {
                    return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
                }

                return $0.completedDate > $1.completedDate
            }
    }

    var actualPayrollTotalCents: Int {
        actualPayLineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var scheduledServiceStopLaborEstimateCents: Int {
        let stopIdsWithPayroll = Set(actualPayLineItems.compactMap { $0.serviceStopId })

        return serviceStops.reduce(0) { total, stop in
            if stopIdsWithPayroll.contains(stop.id) {
                return total
            }

            if let estimatedPayCents = stop.estimatedPayCents,
               estimatedPayCents > 0 {
                print("[JobDetailViewModel][scheduledStopLaborEstimate] using saved service stop estimate stopId=\(stop.id) estimatedPayCents=\(estimatedPayCents) typeId=\(stop.typeId) payWorkTypeId=\(stop.payWorkTypeId ?? "nil") workTypeId=\(stop.workTypeId ?? "nil")")
                return total + estimatedPayCents
            }

            let minutes = stop.duration > 0 ? stop.duration : stop.estimatedDuration
            let estimatedCents = (Double(minutes) / 60.0) * employeeHourlyRate
            let fallbackCents = Int(estimatedCents.rounded())
            print("[JobDetailViewModel][scheduledStopLaborFallback] stopId=\(stop.id) jobId=\(stop.jobId) typeId=\(stop.typeId) type=\(stop.type) inferredSourceId=\(stop.inferredPayrollServiceStopSourceId) techId=\(stop.techId) estimatedPayCents=\(String(describing: stop.estimatedPayCents)) payWorkTypeId=\(stop.payWorkTypeId ?? "nil") payWorkTypeName=\(stop.payWorkTypeName ?? "nil") workTypeId=\(stop.workTypeId ?? "nil") workTypeName=\(stop.workTypeName ?? "nil") defaultWorkTypeIds=\(stop.defaultWorkTypeIds ?? []) duration=\(stop.duration) estimatedDuration=\(stop.estimatedDuration) fallbackHourlyRateCents=\(Int(employeeHourlyRate.rounded())) fallbackCents=\(fallbackCents)")
            return total + fallbackCents
        }
    }

    var actualLaborTotalCents: Int {
        actualPayrollTotalCents + scheduledServiceStopLaborEstimateCents
    }

    var actualPayrollCalculatedCents: Int {
        actualPayLineItems
            .filter {
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .approved ||
                $0.calculationStatus == .paid
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var actualPayrollNeedsReviewCount: Int {
        actualPayLineItems
            .filter { $0.calculationStatus == .needsReview }
            .count
    }

    var finishedServiceStops: [ServiceStop] {
        serviceStops
            .filter { $0.operationStatus == .finished }
            .sorted { $0.serviceDate > $1.serviceDate }
    }

    var unfinishedServiceStops: [ServiceStop] {
        serviceStops
            .filter { $0.operationStatus != .finished }
            .sorted { $0.serviceDate > $1.serviceDate }
    }

    var plannedLaborTotalCents: Int {
        jobTaskList.reduce(0) { $0 + $1.contractedRate }
    }
    
    var plannedTaskLaborCents: Int {
        plannedLaborTotalCents
    }
    
    var plannedServiceStopLaborCents: Int {
        plannedServiceStops.reduce(0) { total, plannedStop in
            total + (plannedStop.plannedLaborCostCents ?? 0)
        }
    }

    var plannedTotalLaborCents: Int {
        plannedTaskLaborCents + plannedServiceStopLaborCents
    }

    func estimatedPlannedStopCostCents(_ stop: JobPlannedServiceStop) -> Int {
        // V1 fallback:
        // Until you plug in full TechnicianRate / WorkTypeMapping estimating,
        // use 0 here or add a manual planned cost field later.
        0
    }
    var plannedLaborMinutes: Int {
        jobTaskList.reduce(0) { $0 + $1.estimatedTime }
    }

    var actualServiceStopMinutes: Int {
        serviceStops.reduce(0) { $0 + $1.duration }
    }
    
    var plannedServiceStopMinutes: Int {
        plannedServiceStops.reduce(0) { $0 + $1.estimatedMinutes }
    }
}
// MARK: - MATERIALS EXTENSION

extension JobDetailViewModel {

    var plannedMaterialCostCents: Int {
        shoppingItemList.reduce(0) { partial, item in
            partial + (item.plannedTotalCostCents ?? 0)
        }
    }

    var plannedMaterialPriceCents: Int {
        shoppingItemList.reduce(0) { partial, item in
            partial + (item.plannedTotalPriceCents ?? 0)
        }
    }

    var actualPurchasedMaterialCostCents: Int {
        Int(purchasedItems.reduce(0.0) { $0 + $1.totalAfterTax }.rounded())
    }

    var purchasedItemsNotInvoiced: [PurchasedItem] {
        purchasedItems
    }

    var billablePurchasedItems: [PurchasedItem] {
        purchasedItems.filter { $0.isJobBillable }
    }

    var billablePurchasedMaterialPriceCents: Int {
        Int(billablePurchasedItems.reduce(0.0) { partial, item in
            let rate = item.jobMaterialBillingRate
            return partial + (rate * item.quantity)
        }.rounded())
    }

    var shoppingItemsNeedPurchase: [ShoppingListItem] {
        shoppingItemList.filter { $0.status == .needToPurchase }
    }

    var shoppingItemsPurchased: [ShoppingListItem] {
        shoppingItemList.filter { $0.status == .purchased }
    }

    var shoppingItemsInstalled: [ShoppingListItem] {
        shoppingItemList.filter { $0.status == .installed }
    }
}
// MARK: - JOB DASHBOARD EXTENSION

extension JobDetailViewModel {

    func dashboardSummary(for job: Job) -> JobDashboardSummary {
        JobDashboardSummary(
            jobRateCents: job.rate,
            plannedTaskLaborCents: plannedTaskLaborCents,
            plannedServiceStopLaborCents: plannedServiceStopLaborCents,
            actualPayrollCents: actualLaborTotalCents,
            plannedMaterialCostCents: plannedMaterialCostCents,
            plannedMaterialPriceCents: plannedMaterialPriceCents,
            actualMaterialCostCents: actualPurchasedMaterialCostCents,
            actualMaterialBillableCents: billablePurchasedMaterialPriceCents,
            serviceStopCount: serviceStops.count,
            finishedServiceStopCount: finishedServiceStops.count,
            openOfferCount: workOffers.filter { $0.status.isOpen }.count,
            acceptedOfferCount: workOffers.filter { $0.status == .accepted }.count,
            acceptedOffersReadyToScheduleCount: workOffers.acceptedReadyToScheduleCount,
            payrollNeedsReviewCount: actualPayrollNeedsReviewCount
        )
    }

    var openServiceStopCount: Int {
        serviceStops.filter { $0.operationStatus != .finished }.count
    }

    var scheduledServiceStopCount: Int {
        serviceStops.count
    }

    var openWorkOffers: [WorkOffer] {
        workOffers.filter { $0.status.isOpen }
    }

    var acceptedWorkOffers: [WorkOffer] {
        workOffers.filter { $0.status == .accepted }
    }

    var scheduledWorkOffers: [WorkOffer] {
        workOffers.filter {
            $0.status == .scheduled ||
            $0.status == .inProgress ||
            $0.status == .completed ||
            !$0.serviceStopId.isEmpty
        }
    }
    var acceptedOffersReadyToSchedule: [WorkOffer] {
        workOffers
            .filter {
                $0.status == .accepted &&
                $0.serviceStopId.isEmpty
            }
            .sorted {
                ($0.acceptedAt ?? $0.createdAt) > ($1.acceptedAt ?? $1.createdAt)
            }
    }

    var acceptedOffersReadyToScheduleCount: Int {
        acceptedOffersReadyToSchedule.count
    }

    var adminWorkOfferAttentionCount: Int {
        workOffers.acceptedReadyToScheduleCount
    }
    
    //Health Checks
    func workflowHealthReport(for job: Job) -> JobWorkflowHealthReport {
        JobWorkflowHealthBuilder.buildReport(
            job: job,
            jobTasks: jobTaskList,
            serviceStops: serviceStops,
            workOffers: workOffers,
            payLineItems: actualPayLineItems,
            shoppingItems: shoppingItemList,
            purchasedItems: purchasedItems,
            plannedLaborCents: plannedTotalLaborCents,
            actualPayrollCents: actualLaborTotalCents,
            plannedMaterialCostCents: plannedMaterialCostCents,
            actualMaterialCostCents: actualPurchasedMaterialCostCents
        )
    }
    
}
// MARK: Planned Service Stops
extension JobDetailViewModel {
    func reloadPlannedServiceStops(
        companyId: String,
        jobId: String
    ) async throws {
        plannedServiceStops = try await dataService.fetchJobPlannedServiceStops(
            companyId: companyId,
            jobId: jobId
        )
    }

    func deletePlannedServiceStop(
        companyId: String,
        plannedStop: JobPlannedServiceStop
    ) async throws {
        try await dataService.deleteJobPlannedServiceStop(
            companyId: companyId,
            jobId: plannedStop.jobId,
            plannedServiceStopId: plannedStop.id
        )

        plannedServiceStops.removeAll { $0.id == plannedStop.id }
    }
}
