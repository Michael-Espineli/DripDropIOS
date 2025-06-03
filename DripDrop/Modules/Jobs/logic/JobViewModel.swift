//
//  JobViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//


import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class JobViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    @Published private(set) var workOrder: Job? = nil

    @Published private(set) var workOrders: [Job] = []

    @Published private(set) var filteredWorkOrders: [Job] = []

    @Published private(set) var unscheduledWorkOrders: [Job] = []

    @Published private(set) var dailyDisplayTechs: [DBUser] = []
    @Published private(set) var readingHistory: [StopData] = []
    @Published private(set) var changeHistory: [History] = []

    @Published var searchTerm: String = ""

//    @Published private(set) var billableServiceStops: [ServiceStop] = []
    @Published private(set) var purchasedPartCost: Double? = nil


    @Published var selectedFilter: FilterOption? = nil
    @Published var selectedDate: Date? = nil
    private var lastDocument: DocumentSnapshot? = nil
    
    

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Get Jobs
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getAllJobSnapShot(companyId: String) async throws{
        self.workOrders = try await dataService.getAllWorkOrders(companyId: companyId)
    }
    func getAllWorkOrders(companyId: String) async throws{
        self.workOrders = try await dataService.getAllWorkOrders(companyId: companyId)
    }
    func getAllUnbilledJobs(companyId: String) async throws{
        self.workOrders = try await dataService.getAllWorkOrdersFinished(companyId: companyId, finished: false)
    }
    func getSingleWorkOrder(companyId: String,WorkOrderId:String) async throws{
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: WorkOrderId)
    }

    func getAllUnscheduledWorkOrders(companyId: String) async throws{
        self.unscheduledWorkOrders = try await dataService.getAllUnscheduledWorkOrders(companyId: companyId)

    }
    func getFiveServiceStops(companyId: String) async throws{
        self.workOrders = try await dataService.getAllWorkOrdersSortedByTime(companyId: companyId, descending: true, count: 5)
    }
    
    enum FilterOption:String, CaseIterable{
        case noFilter
        case priceHigh
        case priceLow
    }
    func filterSelected(companyId: String,option: FilterOption) async throws{
        switch option{
        case .priceHigh:
            self.workOrders = try await dataService.getAllWorkOrdersSortedByPrice(companyId: companyId, descending: true)
            break
        case .priceLow:
            self.workOrders = try await dataService.getAllWorkOrdersSortedByPrice(companyId: companyId, descending: false)
            break
        case .noFilter:
            self.workOrders = try await dataService.getAllWorkOrders(companyId: companyId)
            break
        }
        self.selectedFilter = option
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //Filter Service Locations
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func filterWorkOrderList() {
        var filteredWorkOrderList:[Job] = []
        
        for wo in workOrders {
            if wo.adminName.lowercased().contains(searchTerm) || wo.type.lowercased().contains(searchTerm) || wo.description.lowercased().contains(searchTerm) || wo.customerName.lowercased().contains(searchTerm) || wo.internalId.lowercased().contains(searchTerm) {
                
                filteredWorkOrderList.append(wo)
            }
        }
        self.filteredWorkOrders = filteredWorkOrderList
    }
    
    func DateSelected(companyId: String,date: Date) async throws{
        self.workOrders = try await dataService.getAllWorkOrdersByDate(companyId: companyId, date: date)

    }
    //takes all the service stops and finds all unique techs in all of the service stops. only use on daily.
    func FindTechsArray(stops:[ServiceStop],companyId:String) async throws{
//        self.currentTechs = try await DBUserManager.shared.FindTechs(stops: stops,companyId: companyId).techs
        
    }
    func TechAndDate(companyId: String,date: Date,techId:String) async throws{
        self.workOrders = try await dataService.getAllWorkOrdersByDayAndTech(companyId: companyId, date: date,techId:techId)
        print(workOrders)
    }
    func getServiceStopBySomething(companyId: String){
        Task{
            let (newWorkOrders,lastDocument) = try await dataService.getWorkOrdersBySomething(companyId: companyId, count: 5, lastDocument: lastDocument)
            self.workOrders.append(contentsOf: newWorkOrders)
        }
    }
    func addNewWorkOrder(companyId:String,workOrder:Job,workOrderTemplateType:JobTemplate) async throws{
        print("Arrived")

        let workOrderCount = try await SettingsManager.shared.getWorkOrderCount(companyId: companyId)
        print("WO COUNT : ")
        print(workOrderCount)

        try await dataService.uploadWorkOrder(
            companyId: companyId,
            workOrder: Job(
                id: "comp_wo_" + UUID().uuidString,
                internalId: "J" + String(workOrderCount),
                type: workOrderTemplateType.type ?? "..Loading",
                dateCreated: workOrder.dateCreated,
                description: workOrder.description,
                operationStatus: workOrder.operationStatus,
                billingStatus: workOrder.billingStatus,
                customerId: workOrder.customerId,
                customerName: workOrder.customerName,
                serviceLocationId: workOrder.serviceLocationId,
                serviceStopIds: workOrder.serviceStopIds,
                laborContractIds: workOrder.laborContractIds,
                adminId: workOrder.adminId,
                adminName: workOrder.adminName,
                rate: workOrder.rate,
                laborCost: workOrder.laborCost,
                otherCompany: false,
                receivedLaborContractId: "",
                receiverId: "",
                senderId : companyId,
                dateEstimateAccepted: nil,
                estimateAcceptedById: nil,
                estimateAcceptType: nil,
                estimateAcceptedNotes: nil,
                invoiceDate: nil,
                invoiceRef: nil,
                invoiceType: nil,
                invoiceNotes: nil
            )
        )
            print("Uploaded")
   
    }
    func addNewJobWithValidation(companyId:String, jobId:String, jobTemplate:JobTemplate, dateCreated:Date, description:String, operationStatus:JobOperationStatus, billingStatus:JobBillingStatus, customerId:String, customerName:String, serviceLocationId:String, serviceStopIds:[String], adminId:String, adminName:String, installationParts:[WODBItem], pvcParts:[WODBItem], electricalParts:[WODBItem], chemicals:[WODBItem], miscParts:[WODBItem], rate:String, laborCost:String, bodyOfWater:BodyOfWater, equipment:Equipment) async throws {
        print("Arrived")
        var bodyOfWaterInside : BodyOfWater? = nil
        var equipmentInside : Equipment? = nil

        guard let laborCost = Int(laborCost) else {
            throw JobError.invalidLaborCost
        }
        guard let rate = Int(rate) else {
            throw JobError.invalidRate
        }
        if customerId == "" {
            throw JobError.invalidCustomer
        }
        if adminId == "" {
            throw JobError.invalidAdmin
        }
        if jobTemplate.id == "" {
            throw JobError.invalidJobType
        }
        if bodyOfWater.id == "" {
            bodyOfWaterInside = nil
        } else {
            bodyOfWaterInside = bodyOfWater
        }
        if equipment.id == "" {
            equipmentInside = nil
        } else {
            equipmentInside = equipment
        }
        try await dataService.uploadWorkOrder(companyId: companyId,
                                              workOrder: Job(id: jobId, 
                                                             internalId: "J",
                                                             type: jobTemplate.type ?? "..Loading",
                                                             dateCreated: dateCreated,
                                                             description: description,
                                                             operationStatus: operationStatus,
                                                             billingStatus: billingStatus,
                                                             customerId: customerId,
                                                             customerName: customerName,
                                                             serviceLocationId: serviceLocationId,
                                                             serviceStopIds: serviceStopIds,
                                                             //Developer Check Out
                                                             laborContractIds: [],
                                                             adminId: adminId,
                                                             adminName: adminName,
                                                             rate: rate,
                                                             laborCost: laborCost,
                                                             otherCompany: false,
                                                             receivedLaborContractId: "",
                                                             receiverId: "",
                                                             senderId : companyId,
                                                             dateEstimateAccepted: nil,
                                                             estimateAcceptedById: nil,
                                                             estimateAcceptType: nil,
                                                             estimateAcceptedNotes: nil,
                                                             invoiceDate: nil,
                                                             invoiceRef: nil,
                                                             invoiceType: nil,
                                                             invoiceNotes: nil
                                                            )
        )
        
            print("Uploaded")
   
    }
    func addServiceIdToJob(companyId:String,jobId:String,serviceStopId:String) async throws{
        try await JobManager.shared.addServiceIdToJob(companyId:companyId,jobId:jobId,serviceStopId:serviceStopId)
    }

    func addServiceStopToCustomerHistory(serviceStop:Job,stopData:StopData) async throws{
//        try await dataService.uploadReadingToCustomerHistory(serviceStop: serviceStop, stopData: stopData)

    }

    
    func addInstallationItemsToWorkOrder(companyId: String,workOrder:Job,installPart:WODBItem) async throws{
        //Adds the Service Stop id to the workOrder you added it too.
        try await dataService.updateInstallationPartsListOfWorkOrder(companyId: companyId, workOrder: workOrder, installationPart: installPart)
    }
    
    func addPVCItemsToWorkOrder(companyId: String,workOrder:Job,pvcItem:WODBItem) async throws{
        //Adds the Service Stop id to the workOrder you added it too.
        try await dataService.updatePVCPartsListOfWorkOrder(companyId: companyId, workOrderId: workOrder.id, pvcPart: pvcItem)
    }
    func addElectricalItemsToWorkOrder(companyId: String,workOrder:Job,electricalItem:WODBItem) async throws{
        //Adds the Service Stop id to the workOrder you added it too.
        try await dataService.updateElectricalPartsListOfWorkOrder(companyId: companyId, workOrderId: workOrder.id, electricalPart: electricalItem)
    }
    func addChemicalItemsToWorkOrder(companyId: String,workOrder:Job,chemicalItem:WODBItem) async throws{
        //Adds the Service Stop id to the workOrder you added it too.
        try await dataService.updateChemicalListOfWorkOrder(companyId: companyId, workOrderId: workOrder.id, chemical: chemicalItem)
    }
    func addMiscItemsToWorkOrder(companyId: String,workOrder:Job,miscItem:WODBItem) async throws{
        //Adds the Service Stop id to the workOrder you added it too.
        try await dataService.updateMiscPartsListOfWorkOrder(companyId: companyId, workOrderId: workOrder.id, miscPart: miscItem)
    }
    func getAllHistoryByCustomer(customer: Customer,companyId: String)async throws{
        self.readingHistory = try await dataService.readAllHistory(companyId: companyId, customer: customer)

    }
    func getAllPastJobsBasedOnCustomer(companyId: String,customer: Customer)async throws{
        try await dataService.getAllPastJobsBasedOnCustomer(companyId: companyId, customer: customer)
    }
    func getAllFutureJobsBasedOnCustomer(companyId: String,customer: Customer)async throws{
        try await dataService.getAllFutureJobsBasedOnCustomer(companyId: companyId, customer: customer)

    }
    func getFourMostRecentHistoryByCustomer(companyId: String,customer: Customer)async throws{
        self.readingHistory = try await dataService.readFourMostRecentStops(companyId: companyId, customer: customer)

    }
    func getFourMostRecentHistoryByCustomerId(companyId: String,customerId: String)async throws{
        self.readingHistory = try await dataService.readFourMostRecentStopsById(companyId: companyId, customerId: customerId)

    }
    func updateServiceStop(originalWorkOrder:Job,updatedWorkOrder:Job) async throws {

//        try await dataService.updateWorkOrder(originalWorkOrder: originalWorkOrder, newWorkOrder: updatedWorkOrder)
    }
    func getChangeHistoryByWorkOrder(workOrder:Job)async throws{
        self.changeHistory = try await dataService.getHistoryByWorkOrder(workOrder: workOrder)
        
    }
    func getBillableServiceStopsByDate(companyId: String,startDate:Date,endDate:Date)async throws{
        self.workOrders = try await dataService.getBillableWorkOrdersByDate(companyId: companyId, startDate: startDate,endDate: endDate)
        
    }
    func changeBillingStatusOfWorkOrder(workOrder:Job,billingStatus:Bool)async throws{


    }
    func filterWorkOrderList(companyId: String,id:String)async throws {
        self.workOrder = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: id)

    }
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        try await dataService.addPurchaseItemsToWorkOrder(workOrder: workOrder, companyId: companyId, ids: ids)

    }
    func addPurchaseItemsToWorkOrderToInstall(workOrder:Job,companyId: String,ids:[String])async throws {
        try await dataService.addPurchaseItemsToInstallationWorkOrder(workOrder: workOrder, companyId: companyId, ids: ids)

    }
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    func deleteJob(companyId:String,jobId:String) async throws {
        try await dataService.deleteJob(companyId: companyId, jobId: jobId)
    }
    func deletePart(companyId:String,jobId:String,part:WODBItem,category:String) async throws {
        //Delete From Job
        try await dataService.deletePart(companyId: companyId, jobId: jobId, part: part,category: category)
        //Delete From shopping List
        let items = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: jobId, category: category)//This is a really bad way to do this. Just put the shopping List id into the WODBItem for the JOB
        for item in items {
            if item.genericItemId == part.genericItemId && item.name == part.name && item.quantiy == String(part.quantity) {
                try await dataService.deleteShoppingListItem(companyId: companyId, shoppingListItemId: item.id)
            }
        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    func addListenerForAllJobsOperations(companyId: String, status: [JobOperationStatus], requesterIds: [String], startDate: Date, endDate: Date){
        print("")
        print("Adding Operations Job Listener")
        print("Company Id: \(companyId)")
        dataService.addListenerForAllJobsOperations(companyId: companyId, status: status, requesterIds: requesterIds, startDate: startDate, endDate: endDate){ [weak self] jobs in
            print("Jobs: \(jobs.count)")
           self?.workOrders = jobs
       }
        
    }
    func addListenerForAllJobsBillings(companyId: String, status: [JobBillingStatus], requesterIds: [String], startDate: Date, endDate: Date){
        print("")
        print("Adding Billing Job Listener")
        
        print("Company Id: \(companyId)")
         dataService.addListenerForAllJobsBilling(companyId: companyId, status: status, requesterIds: requesterIds, startDate: startDate, endDate: endDate){ [weak self] jobs in
             print("Jobs: \(jobs.count)")
            self?.workOrders = jobs
        }
    }
    func removeListenerForJob(){
        print("Removing Job Listener")

        dataService.removeListenerForJobs()
    }
    func getPurchaseCost(companyId:String,purchaseIds:[String]) async throws {
        var total:Double = 0
        for id in purchaseIds {
            let purchase = try await dataService.getSingleItem(itemId: id, companyId: companyId)
            total += purchase.totalAfterTax
        }
        self.purchasedPartCost = total
    }
        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        //                             Uploading Jobs
        //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        func updateJobInfo(companyId:String,updatingJob:Job,admin:DBUser,jobTemplate:JobTemplate,operationStatus:JobOperationStatus,billingStatus:JobBillingStatus,rate:String,laborCost:String,description:String) async throws{
            //Check Which Parts Need Updating
            if admin.id != updatingJob.adminId || admin.firstName != updatingJob.adminName{
                print("Change in Admin")
                let name:String = admin.firstName ?? ""  //DEVELOPER THINK ABOUT CHANGING THIS TO BOTH THE FIRST AND THE LAST NAME
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
        func updateJobCustomer() async throws{
            
        }
        
        func updateInstallationJobParts(companyId:String,jobId:String,installationPart:WODBItem) async throws{
            try await dataService.updateInstallationJobParts(companyId: companyId, jobId: jobId, installationPart: installationPart)
        }
        
        func updatePVCobParts(companyId:String,jobId:String,pvc:WODBItem) async throws{
            //Add to job
            try await dataService.updatePVCobParts(companyId: companyId, jobId: jobId, pvc: pvc)
            
            //Add to Shopping List
            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: ShoppingListItem(
                    id: UUID().uuidString,
                    category: .job,
                    subCategory: .part,
                    status: .needToPurchase,
                    purchaserId: "",
                    purchaserName: "",
                    genericItemId: pvc.genericItemId,
                    name: pvc.name,
                    description: "",
                    datePurchased: nil,
                    quantiy: String(pvc.quantity),
                    jobId: jobId,
                    customerId: nil,
                    customerName: nil,
                    userId: nil,
                    userName: nil
                )
            )
        }
        
        func updateElectricalJobParts(companyId:String,jobId:String,electical:WODBItem) async throws{
            //Add to job
            try await dataService.updateElectricalJobParts(companyId: companyId, jobId: jobId, electical: electical)
            
            //Add to Shopping List
            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: ShoppingListItem(
                    id: UUID().uuidString,
                    category: .job,
                    subCategory: .part,
                    status: .needToPurchase,
                    purchaserId: "",
                    purchaserName: "",
                    genericItemId: electical.genericItemId,
                    name: electical.name,
                    description: "",
                    datePurchased: nil,
                    quantiy: String(electical.quantity),
                    jobId: jobId,
                    customerId: nil,
                    customerName: nil,
                    userId: nil,
                    userName: nil
                )
            )

        }
        
        func updateChemicalsJobParts(companyId:String,jobId:String,chemical:WODBItem) async throws{
            //Add to job
            try await dataService.updateChemicalsJobParts(companyId: companyId, jobId: jobId, chemical: chemical)
            
            //Add to Shopping List
            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: ShoppingListItem(
                    id: UUID().uuidString,
                    category: .job,
                    subCategory: .chemical,
                    status: .needToPurchase,
                    purchaserId: "",
                    purchaserName: "",
                    genericItemId: chemical.genericItemId,
                    name: chemical.name,
                    description: "",
                    datePurchased: nil,
                    quantiy: String(chemical.quantity),
                    jobId: jobId,
                    customerId: nil,
                    customerName: nil,
                    userId: nil,
                    userName: nil
                )
            )

        }
        
        func updateMiscJobParts(companyId:String,jobId:String,misc:WODBItem) async throws{
            //Add to job
            try await dataService.updateMiscJobParts(companyId: companyId, jobId: jobId, misc: misc)
            
            //Add to Shopping List
            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: ShoppingListItem(
                    id: UUID().uuidString,
                    category: .job,
                    subCategory: .part,
                    status: .needToPurchase,
                    purchaserId: "",
                    purchaserName: "",
                    genericItemId: misc.genericItemId,
                    name: misc.name,
                    description: "",
                    datePurchased: nil,
                    quantiy: String(misc.quantity),
                    jobId: jobId,
                    customerId: nil,
                    customerName: nil,
                    userId: nil,
                    userName: nil
                )
            )

        }
        
        func updateJobSchedule() async throws{
            
        }
}
