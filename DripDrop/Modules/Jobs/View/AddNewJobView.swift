//
//  AddNewJobView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI
@MainActor
final class AddNewJobViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(
        dataService: any ProductionDataServiceProtocol,
        startingTemplate: JobTemplate? = nil,
        isTechnicianCreateFlow: Bool = false,
        canScheduleServiceStopsForOthers: Bool = true
    ) {
        self.dataService = dataService
        self.startingTemplate = startingTemplate
        self.isTechnicianCreateFlow = isTechnicianCreateFlow
        self.canScheduleServiceStopsForOthers = canScheduleServiceStopsForOthers
    }
    
    @Published var startingTemplate: JobTemplate?
    @Published var isTechnicianCreateFlow: Bool = false
    @Published var canScheduleServiceStopsForOthers: Bool = true
    @Published var plannedServiceStops: [JobPlannedServiceStop] = []

    @Published var isLoadingTemplate: Bool = false
    @Published var templateApplied: Bool = false
    
    
    @Published private(set) var techList: [CompanyUser] = []
    @Published private(set) var serviceLocations: [ServiceLocation] = []
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var equipmentList:[Equipment] = []
    @Published var description:String = ""
    @Published var tech:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor,
        linkedCompanyId: "",
        linkedCompanyName: ""
    )
    @Published var serviceDate:Date = Date()

    @Published var includeReadings:Bool = false
    @Published var includeDosages:Bool = false
    @Published var duration:String = "0"
    @Published var rate:String = "0"
    @Published var laborCost:String = "0"
    @Published var issuePriority: JobIssuePriorityLevel? = nil
    

    @Published var jobId:String = ""
    @Published var jobInternalId:String = ""

    @Published var isEdit: Bool = false
    @Published var isAddTask: Bool = false
    @Published var isAddShoppingList: Bool = false

    @Published var isPresentServiceStop: Bool = false
    @Published var isPresentLaborContract: Bool = false

    @Published var chosenView: String = "Info"
    @Published private(set) var viewOptionList:[String] = ["Info","Tasks","Shopping List","Schedule","Review"]
    
    
    @Published var jobTaskList:[JobTask] = []
    @Published var shoppingItemList:[ShoppingListItem] = []
    @Published var serviceStops:[ServiceStop] = []
    @Published var serviceStopTasks:[ServiceStop:[ServiceStopTask]] = [:]

    @Published var laborContracts:[LaborContract] = []

    @Published private(set) var taskTypes:[String] = []
    @Published private(set) var serviceStopIds:[String] = []
    @Published private(set) var laborContractIds:[String] = []
    
    @Published var showAdminSelector:Bool = false
    @Published var showCustomerSelector:Bool = false
    @Published var showLocationSelector:Bool = false
    @Published var showBodyOfWaterSelector:Bool = false
    
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showBodyOfWaterSheet:Bool = false

    @Published var admin:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor,
        linkedCompanyId: "",
        linkedCompanyName: ""
    )

    @Published var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var serviceLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
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
    @Published var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )
    @Published var equipment:Equipment = Equipment(
        id : "",
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
    @Published var jobTemplate:JobTemplate = JobTemplate(companyId: "", name: "", createdByUserId: "")
    @Published var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")
    
    @Published var dateCreated:Date = Date()
    
    @Published var operationStatus:JobOperationStatus = .estimatePending
    
    @Published var billingStatus:JobBillingStatus = .draft

    @Published var showTreeSheet:Bool = false
    @Published var showBushSheet:Bool = false
    
    //Service Stop

    
    @Published var serviceStopList:[ServiceStop] = []
    
    @Published var expandJobDetails:Bool = false
    @Published var jobDetailType:String = "Complex"
    @Published var jobDetailTypes:[String] = ["Simple","Complex"]
    
    
    // MARK: Computed Values
     var canSubmitJob: Bool {
        customer.id != "" &&
        serviceLocation.id != "" &&
        admin.userId != "" &&
        admin.id != "" &&
        Double(rate) != nil &&
        Double(laborCost) != nil
    }
    var plannedStopLaborCents: Int {
        plannedServiceStops.reduce(0) { total, stop in
            total + (stop.plannedLaborCostCents ?? 0)
        }
    }

    var plannedTaskLaborCents: Int {
        jobTaskList.reduce(0) { total, task in
            total + task.contractedRate
        }
    }

    var plannedTotalLaborCents: Int {
        plannedStopLaborCents + plannedTaskLaborCents
    }

    var plannedMaterialCostCents: Int {
        shoppingItemList.reduce(0) { total, item in
            total + (item.plannedTotalCostCents ?? 0)
        }
    }

    var plannedMaterialPriceCents: Int {
        shoppingItemList.reduce(0) { total, item in
            total + (item.plannedTotalPriceCents ?? 0)
        }
    }

    var rateCents: Int {
        guard let rateDouble = Double(rate) else { return 0 }
        return Int((rateDouble * 100.0).rounded())
    }

    var laborCostCents: Int {
        guard let laborDouble = Double(laborCost) else { return 0 }
        return Int((laborDouble * 100.0).rounded())
    }

    var projectedProfitCents: Int {
        rateCents - laborCostCents - plannedMaterialCostCents
    }
    //Keyboard Info

    
    
    
    func onLoad(
        companyId: String,
        customerId: String?,
        defaultAdminId: String? = nil,
        currentUserId: String? = nil
    ) async throws {
        let workOrderCount = try await dataService.getWorkOrderCount(companyId: companyId)
        self.jobId = "comp_wo_" + UUID().uuidString
        self.jobInternalId = "J" + String(workOrderCount)
        self.techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        let normalizedDefaultAdminId = defaultAdminId?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let defaultAdmin = techList.first(where: { $0.userId == normalizedDefaultAdminId || $0.id == normalizedDefaultAdminId }) {
            self.admin = defaultAdmin
        } else if !techList.isEmpty {
            self.admin = techList.first!
        }

        let normalizedCurrentUserId = currentUserId?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let currentUser = techList.first(where: { $0.userId == normalizedCurrentUserId || $0.id == normalizedCurrentUserId }) {
            self.tech = currentUser
        } else {
            self.tech = self.admin
        }
        /*self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)*/
        //Get Task Types
        self.taskTypes = JobTaskType.allCases.map(\.rawValue)
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = []
        self.laborContractIds = []
        for task in jobTaskList {
            self.serviceStopIds.append(task.serviceStopId.internalId)
            self.laborContractIds.append(task.laborContractId)
        }
        self.serviceStopIds.removeDuplicates()
        self.laborContractIds.removeDuplicates()
        
        self.serviceStopIds.remove("")
        self.laborContractIds.remove("")
        if let customerId{
            self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        }
    }
    func applyEquipmentContext(companyId: String, equipment: Equipment) async throws {
        self.customer = try await dataService.getCustomerById(
            companyId: companyId,
            customerId: equipment.customerId
        )
        self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
            companyId: companyId,
            customerId: equipment.customerId
        )

        if let location = serviceLocations.first(where: { $0.id == equipment.serviceLocationId }) {
            self.serviceLocation = location
            self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(
                companyId: companyId,
                serviceLocationId: location.id
            )
        }

        if let bodyOfWater = bodiesOfWater.first(where: { $0.id == equipment.bodyOfWaterId }) {
            self.bodyOfWater = bodyOfWater
            self.equipmentList = try await dataService.getEquipmentByBodyOfWater(
                companyId: companyId,
                bodyOfWater: bodyOfWater
            )
        }

        self.equipment = equipmentList.first(where: { $0.id == equipment.id }) ?? equipment

        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            description = "Schedule equipment work for \(equipment.name)"
        }

        guard !jobTaskList.contains(where: { $0.equipmentId == equipment.id }) else { return }

        let taskType: JobTaskType = equipment.status == .needsRepair ? .repair : .maintenance
        jobTaskList.append(
            JobTask(
                id: "comp_job_task_" + UUID().uuidString,
                name: "\(taskType.rawValue) \(equipment.name)",
                type: taskType,
                contractedRate: 0,
                estimatedTime: 0,
                status: .draft,
                customerApproval: false,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: equipment.id,
                serviceLocationId: equipment.serviceLocationId,
                bodyOfWaterId: equipment.bodyOfWaterId,
                dataBaseItemId: ""
            )
        )
    }
    func onChangeOfCustomer(companyId:String)async throws {
        if customer.id != "" {
            self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
                companyId: companyId,
                customerId: customer.id
            )
        }
    }
    func onChangeOfServiceLocation(companyId:String)async throws {
        if serviceLocation.id != "" {
            self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocation.id)

        }
    }
    func onChangeOfBodyOfWater(companyId:String)async throws {
        if bodyOfWater.id != "" {
            self.equipmentList = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)

        }
    }
    func addNewJob(companyId:String) async throws {
        if customer.id == "" {
            throw JobError.invalidCustomer
        }
        if serviceLocation.id == "" {
            throw JobError.invalidServiceLocation
        }
        if admin.userId == "" {
            throw JobError.invalidAdmin
        }
        if admin.id == "" {
            throw JobError.invalidAdmin
        }
        guard let rateDouble = Double(rate) else {
            throw JobError.invalidRate

        }
        let rateInt = Int(rateDouble*100)
        guard let laborCostDouble = Double(laborCost) else {
            throw JobError.invalidLaborCost

        }
        let laborCostInt = Int(laborCostDouble*100)

        let fullCustomerName = customer.firstName + " " + customer.lastName
        var job = Job(
            id: jobId,
            internalId: jobInternalId,
            type: "",
            dateCreated: Date(),
            description: description,
            operationStatus: operationStatus,
            billingStatus: billingStatus,
            customerId: customer.id,
            customerName: fullCustomerName,
            serviceLocationId: serviceLocation.id,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: admin.userId,
            adminName: admin.userName,
            rate: rateInt,
            laborCost: laborCostInt,
            otherCompany: false,
            receivedLaborContractId: "",
            receiverId: "",
            senderId : companyId,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: "",
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
        if let issuePriority {
            job.setIssuePriority(issuePriority)
        }
        try await dataService.uploadWorkOrder(companyId: companyId, workOrder: job)
        //Planned Service Stops
        for plannedStop in plannedServiceStops {
            try await dataService.saveJobPlannedServiceStop(plannedStop)
        }
        //Add Tasks
        for task in jobTaskList {
            try await dataService.uploadJobTask(companyId:companyId,jobId:jobId,task:task)
        }
        //Add ShoppingList Items
        for item in shoppingItemList {
            var updatedItem = item
            updatedItem.jobId = jobId
            updatedItem.customerId = customer.id
            updatedItem.customerName = fullCustomerName

            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: updatedItem
            )
        }
        //Add Service Stops
        for stop in serviceStops {
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: stop)
            let tasks: [ServiceStopTask] = serviceStopTasks[stop] ?? []
            for task in tasks {
                try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: stop.id, task: task)
                
                //Update Receiver Job Task
                try dataService.updateJobTaskWorkerId(companyId: companyId, jobId: job.id, taskId: task.id, workerId: stop.techId)
                try dataService.updateJobTaskWorkerName(companyId: companyId, jobId: job.id, taskId: task.id, workerName: stop.tech)
                try dataService.updateJobTaskWorkerType(companyId: companyId, jobId: job.id, taskId: task.id, workerType: .employee)
                try dataService.updateJobTaskServiceStopId(companyId: companyId, jobId: job.id, taskId: task.id, serviceStopId: IdInfo(id: stop.id, internalId: stop.internalId))
                try dataService.updateJobTaskStatus(companyId: companyId, jobId: job.id, taskId: task.id, status: .scheduled)
            }
        }
        //Add Labor Contracts
        
        
        
        self.alertMessage = "Successfully Uploaded"
        self.showAlert = true
    }
    func addNewJobSimple(companyId:String) async throws {
    }
    func onDismissAddTaskShet(companyId:String,serviceLocationId:String,jobId:String) async throws {
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
//MARK: Helper Functions
    func applyStartingTemplateIfNeeded(
        companyId: String,
        createdByUserId: String
    ) async throws {
        guard let startingTemplate else { return }
        guard !templateApplied else { return }

        isLoadingTemplate = true
        defer { isLoadingTemplate = false }

        async let templateTasksTask = dataService.fetchJobTemplateTasks(
            companyId: companyId,
            templateId: startingTemplate.id
        )

        async let templatePlannedStopsTask = dataService.fetchJobTemplatePlannedServiceStops(
            companyId: companyId,
            templateId: startingTemplate.id
        )

        async let templateShoppingItemsTask = dataService.fetchJobTemplateShoppingItems(
            companyId: companyId,
            templateId: startingTemplate.id
        )

        let templateTasks = try await templateTasksTask
        let templatePlannedStops = try await templatePlannedStopsTask
        let templateShoppingItems = try await templateShoppingItemsTask

        description = startingTemplate.description
        rate = String(Double(startingTemplate.defaultRateCents) / 100.0)
        laborCost = String(Double(startingTemplate.defaultLaborCostCents) / 100.0)
        issuePriority = startingTemplate.normalizedDefaultIssuePriority

        let copiedTasks = templateTasks.map { templateTask in
            JobTask(
                id: "comp_job_task_" + UUID().uuidString,
                name: templateTask.name,
                type: templateTask.type,
                contractedRate: templateTask.contractedRate,
                estimatedTime: templateTask.estimatedTime,
                status: .draft,
                customerApproval: templateTask.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: templateTask.equipmentId ?? "",
                serviceLocationId: "",
                bodyOfWaterId: templateTask.bodyOfWaterId ?? "",
                dataBaseItemId: templateTask.dataBaseItemId ?? ""
            )
        }

        let taskIdMap = Dictionary(
            uniqueKeysWithValues: zip(templateTasks.map { $0.id }, copiedTasks.map { $0.id })
        )

        jobTaskList = copiedTasks

        plannedServiceStops = templatePlannedStops.map { templateStop in
            JobPlannedServiceStop(
                companyId: companyId,
                jobId: jobId,
                name: templateStop.name,
                description: templateStop.description,
                serviceStopTypeId: templateStop.serviceStopTypeId,
                serviceStopTypeName: templateStop.serviceStopTypeName,
                serviceStopTypeImage: templateStop.serviceStopTypeImage,
                serviceStopTypeUseCaseRawValue: templateStop.serviceStopTypeUseCaseRawValue,
                estimatedMinutes: templateStop.estimatedMinutes,
                sortOrder: templateStop.sortOrder,
                taskIds: templateStop.taskTemplateIds.compactMap { taskIdMap[$0] },
                plannedLaborCostCents: templateStop.plannedLaborCostCents,
                plannedLaborNotes: templateStop.plannedLaborNotes,
                createdByUserId: createdByUserId
            )
        }

        shoppingItemList = templateShoppingItems.map { templateItem in
            ShoppingListItem(
                id: UUID().uuidString,
                category: .job,
                subCategory: templateItem.subCategory,
                status: .needToPurchase,
                purchaserId: createdByUserId,
                purchaserName: "",
                genericItemId: templateItem.genericItemId ?? "",
                name: templateItem.name,
                description: templateItem.description,
                datePurchased: nil,
                quantity: templateItem.quantity,
                jobId: jobId,
                customerId: "",
                customerName: "",
                userId: nil,
                userName: nil,
                dbItemId: templateItem.dbItemId,
                purchasedItem: nil,
                invoiced: false,
                plannedUnitCostCents: templateItem.plannedUnitCostCents,
                plannedUnitPriceCents: templateItem.plannedUnitPriceCents,
                plannedTotalCostCents: templateItem.plannedTotalCostCents,
                plannedTotalPriceCents: templateItem.plannedTotalPriceCents
            )
        }

        templateApplied = true
    }
}
struct AddNewJobView: View {
@Environment(\.dismiss) private var dismiss

@EnvironmentObject var masterDataManager: MasterDataManager
@EnvironmentObject var dataService: ProductionDataService

@StateObject var VM: AddNewJobViewModel

    init(
        dataService: any ProductionDataServiceProtocol,
        customerId: String?,
        startingTemplate: JobTemplate? = nil,
        equipment: Equipment? = nil,
        isTechnicianCreateFlow: Bool = false,
        canScheduleServiceStopsForOthers: Bool = true
    ) {
        _VM = StateObject(
            wrappedValue: AddNewJobViewModel(
                dataService: dataService,
                startingTemplate: startingTemplate,
                isTechnicianCreateFlow: isTechnicianCreateFlow,
                canScheduleServiceStopsForOthers: canScheduleServiceStopsForOthers
            )
        )
        _customerId = State(wrappedValue: customerId)
        self.initialEquipment = equipment
    }

@State var customerId: String?
private let initialEquipment: Equipment?
@FocusState private var focusedField: String?

var body: some View {
    ZStack {
        Color.listColor.ignoresSafeArea()

        if VM.isTechnicianCreateFlow {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    technicianCreateInfo
                    technicianSchedule
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        } else if VM.jobDetailType == "Complex" {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    viewPickerCard

                    switch VM.chosenView {
                    case "Customer":
                        customerView
                    case "Info":
                        info
                    case "Tasks":
                        taskView
                    case "Shopping List":
                        shoppingListView
                    case "Schedule":
                        schedule
                    case "Review":
                        review
                    default:
                        info
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    simpleJobView
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    .safeAreaInset(edge: .bottom) {
        bottomActionBar
    }
    .navigationTitle("ID : \(VM.jobInternalId)")
    .navigationBarTitleDisplayMode(.inline)
    .alert(VM.alertMessage, isPresented: $VM.showAlert) {
        Button("OK", role: .cancel) { }
    }
    .task {
        do {
            guard let company = masterDataManager.currentCompany else {
                print("No Companies")
                return
            }

            try await VM.onLoad(
                companyId: company.id,
                customerId: customerId,
                defaultAdminId: company.defaultAdminId,
                currentUserId: masterDataManager.user?.id
            )

            let userId = masterDataManager.user?.id ?? ""

            try await VM.applyStartingTemplateIfNeeded(
                companyId: company.id,
                createdByUserId: userId
            )

            if let initialEquipment {
                try await VM.applyEquipmentContext(
                    companyId: company.id,
                    equipment: initialEquipment
                )
            }
        } catch {
            VM.alertMessage = "Could not load job. \(error.localizedDescription)"
            VM.showAlert = true
            print(error)
        }
    }
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            if VM.canSubmitJob {
                Button {
                    submitCurrentJob()
                } label: {
                    Text("Submit")
                        .font(.caption.weight(.semibold))
                }
            } else if !UIDevice.isIPhone && !VM.isTechnicianCreateFlow {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        VM.jobDetailType = VM.jobDetailType == "Simple" ? "Complex" : "Simple"
                    }
                } label: {
                    Text(VM.jobDetailType == "Simple" ? "Expand" : "Simplify")
                        .font(.caption.weight(.semibold))
                }
            }
        }
    }
    .sheet(isPresented: $VM.showAdminSelector) {
        CompanyUserPicker(dataService: dataService, companyUser: $VM.admin)
    }
    .sheet(isPresented: $VM.showCustomerSelector) {
        CustomerAndLocationPicker(
            dataService: dataService,
            customer: $VM.customer,
            location: $VM.serviceLocation
        )
    }
    .sheet(isPresented: $VM.showLocationSelector) {
        ServiceLocationPicker(
            dataService: dataService,
            customerId: VM.customer.id,
            location: $VM.serviceLocation
        )
    }
    .sheet(isPresented: $VM.showBodyOfWaterSelector) {
        BodyOfWaterPicker(
            dataService: dataService,
            serviceLocationId: VM.serviceLocation.id,
            bodyOfWater: $VM.bodyOfWater
        )
    }

    .onChange(of: VM.admin) { admin in
        VM.tech = admin
    }
    .onChange(of: VM.customer) { _ in
        Task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onChangeOfCustomer(companyId: company.id)
                }
            } catch {
                print("Error")
            }
        }
    }
    .onChange(of: VM.serviceLocation) { _ in
        Task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onChangeOfServiceLocation(companyId: company.id)
                }
            } catch {
                print("Error")
            }
        }
    }
    .onChange(of: VM.bodyOfWater) { _ in
        Task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onChangeOfBodyOfWater(companyId: company.id)
                }
            } catch {
                print("Error")
            }
        }
    }
    .onChange(of: VM.rate) { datum in
        if datum != "" {
            if Double(datum) == nil {
                VM.rate = String(datum.dropLast())
            }
        }
    }
    .onChange(of: VM.laborCost) { datum in
        if datum != "" {
            if Double(datum) == nil {
                VM.laborCost = String(datum.dropLast())
            }
        }
    }
}
}

extension AddNewJobView {

var headerCard: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Create Job")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                if let template = VM.startingTemplate {
                    Text("Started from template: \(template.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Build the job scope, shopping list, schedule, and review before submitting.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let template = VM.startingTemplate {
                Label(template.name, systemImage: "square.stack.3d.up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }
            Spacer()

            if VM.canSubmitJob {
                Button {
                    submitCurrentJob()
                } label: {
                    Text("Submit")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }

        HStack(spacing: 8) {
            Label(VM.jobInternalId.isEmpty ? "New Job" : VM.jobInternalId, systemImage: "number")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())

            if VM.customer.id != "" {
                Label("\(VM.customer.firstName) \(VM.customer.lastName)", systemImage: "person.crop.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }

            Label("\(VM.jobTaskList.count) Tasks", systemImage: "checklist")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())

            if let issuePriority = VM.issuePriority {
                Label("Priority \(issuePriority.displayName)", systemImage: "flag")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }

            Spacer()
        }
    }
    .padding(16)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var viewPickerCard: some View {
    VStack(alignment: .leading, spacing: 12) {
        sectionHeader("Job Setup", systemImage: "slider.horizontal.3")

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(VM.viewOptionList, id: \.self) { datum in
                    let index = VM.viewOptionList.firstIndex(where: { $0 == datum }) ?? 0
                    let selectedIndex = VM.viewOptionList.firstIndex(where: { $0 == VM.chosenView }) ?? 0
                    let isSelected = VM.chosenView == datum
                    let isCompleted = index < selectedIndex

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            VM.chosenView = datum
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                            }

                            Text(datum)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            isSelected ? Color.accentColor.opacity(0.16) :
                                isCompleted ? Color.poolGreen.opacity(0.12) :
                                Color.clear,
                            in: Capsule()
                        )
                        .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var info: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Info", systemImage: "briefcase")

        pickerButtonRow(
            title: "Admin",
            value: VM.admin.id == "" ? "Select Admin" : VM.admin.userName,
            systemImage: "person.crop.circle",
            isSelected: VM.admin.id != ""
        ) {
            VM.showAdminSelector.toggle()
        }

        pickerButtonRow(
            title: "Customer",
            value: VM.customer.id == "" ? "Select Customer" : "\(VM.customer.firstName) \(VM.customer.lastName)",
            systemImage: "person.text.rectangle",
            isSelected: VM.customer.id != ""
        ) {
            VM.showCustomerSelector.toggle()
        }

        pickerButtonRow(
            title: "Service Location",
            value: VM.serviceLocation.id == "" ? "Select Location" : VM.serviceLocation.address.streetAddress,
            systemImage: "mappin.and.ellipse",
            isSelected: VM.serviceLocation.id != ""
        ) {
            VM.showLocationSelector.toggle()
        }
        .disabled(VM.customer.id == "")
        .opacity(VM.customer.id == "" ? 0.55 : 1)

        HStack(spacing: 12) {
            detailDisplayRow(
                title: "Operation",
                value: VM.operationStatus.rawValue,
                systemImage: "checkmark.circle"
            )

            detailDisplayRow(
                title: "Billing",
                value: VM.billingStatus.rawValue,
                systemImage: "creditcard"
            )
        }

        HStack(spacing: 12) {
            textInputRow(
                title: "Rate",
                systemImage: "dollarsign.circle",
                placeholder: "Rate",
                text: $VM.rate,
                keyboardType: .decimalPad
            )

            textInputRow(
                title: "Labor Cost",
                systemImage: "hammer",
                placeholder: "Labor Cost",
                text: $VM.laborCost,
                keyboardType: .decimalPad
            )
        }

        descriptionInputCard

        nextButton("Next", systemImage: "chevron.right") {
            VM.chosenView = "Tasks"
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var technicianCreateInfo: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Job Details", systemImage: "briefcase")

        if let template = VM.startingTemplate {
            detailDisplayRow(
                title: "Template",
                value: template.name,
                systemImage: "square.stack.3d.up"
            )
        }

        pickerButtonRow(
            title: "Admin",
            value: VM.admin.id == "" ? "Select Admin" : VM.admin.userName,
            systemImage: "person.crop.circle",
            isSelected: VM.admin.id != ""
        ) {
            VM.showAdminSelector.toggle()
        }

        pickerButtonRow(
            title: "Customer",
            value: VM.customer.id == "" ? "Select Customer" : "\(VM.customer.firstName) \(VM.customer.lastName)",
            systemImage: "person.text.rectangle",
            isSelected: VM.customer.id != ""
        ) {
            VM.showCustomerSelector.toggle()
        }

        pickerButtonRow(
            title: "Service Location",
            value: VM.serviceLocation.id == "" ? "Select Location" : VM.serviceLocation.address.streetAddress,
            systemImage: "mappin.and.ellipse",
            isSelected: VM.serviceLocation.id != ""
        ) {
            VM.showLocationSelector.toggle()
        }
        .disabled(VM.customer.id == "")
        .opacity(VM.customer.id == "" ? 0.55 : 1)

        if let template = VM.startingTemplate {
            HStack(spacing: 12) {
                detailDisplayRow(
                    title: "Default Price",
                    value: AddNewJobMoneyFormatter.money(template.defaultRateCents),
                    systemImage: "dollarsign.circle"
                )

                detailDisplayRow(
                    title: "Labor",
                    value: AddNewJobMoneyFormatter.money(template.defaultLaborCostCents),
                    systemImage: "hammer"
                )
            }
        }

        descriptionInputCard
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var technicianSchedule: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            sectionHeader("Service Stops", systemImage: "calendar.badge.plus")

            Spacer()

            Text("\(VM.serviceStops.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        if !VM.plannedServiceStops.isEmpty {
            plannedServiceStopsPreviewCard
        }

        if VM.serviceStops.isEmpty {
            emptyState(
                title: "No service stops scheduled.",
                message: "Schedule the service stop for this job.",
                systemImage: "calendar.badge.exclamationmark"
            )
        } else {
            VStack(spacing: 8) {
                ForEach(VM.serviceStops) { serviceStop in
                    serviceStopScheduleRow(serviceStop)
                }
            }
        }

        if VM.customer.id != "" && VM.serviceLocation.id != "" {
            Button {
                VM.isPresentServiceStop.toggle()
            } label: {
                actionRow(
                    title: "Schedule Service Stop",
                    subtitle: VM.canScheduleServiceStopsForOthers ? "Choose any technician allowed for this work." : "This stop will be assigned to you.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.isPresentServiceStop) {
                AddNewScheduleServiceStopToNewJobView(
                    dataService: dataService,
                    jobId: VM.jobId,
                    customerId: VM.customer.id,
                    customerName: VM.customer.firstName + " " + VM.customer.lastName,
                    serviceLocationId: VM.serviceLocation.id,
                    description: VM.description,
                    jobTaskList: VM.jobTaskList,
                    plannedServiceStops: VM.plannedServiceStops,
                    canScheduleForOthers: VM.canScheduleServiceStopsForOthers,
                    preferredTechnicianUserId: masterDataManager.user?.id,
                    serviceStops: $VM.serviceStops,
                    serviceStopTasks: $VM.serviceStopTasks
                )
                .presentationDetents([.medium])
            }
        } else {
            Button {
                VM.showCustomerSelector.toggle()
            } label: {
                actionRow(
                    title: "Add Customer Info",
                    subtitle: "Select a customer and service location before scheduling.",
                    systemImage: "person.text.rectangle"
                )
            }
            .buttonStyle(.plain)
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var taskView: some View {
    VStack(alignment: .leading, spacing: 14) {
        if !VM.plannedServiceStops.isEmpty {
            plannedServiceStopsPreviewCard
        }
        HStack {
            sectionHeader("Task List", systemImage: "checklist")

            Spacer()

            Text("\(VM.jobTaskList.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        if VM.jobTaskList.isEmpty {
            emptyState(
                title: "No tasks added yet.",
                message: "Add a task to build the job scope.",
                systemImage: "checklist.unchecked"
            )
        } else {
            VStack(spacing: 8) {
                ForEach(VM.jobTaskList) { task in
                    JobTaskCardView(
                        dataService: dataService,
                        jobId: "",
                        jobTask: task
                    )
                }
            }
        }

        if VM.customer.id != "" && VM.serviceLocation.id != "" {
            Button {
                VM.isAddTask.toggle()
            } label: {
                actionRow(
                    title: "Add New Task",
                    subtitle: "Add a single custom task to this job.",
                    systemImage: "plus.circle"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.isAddTask) {
                AddNewTaskToNewJob(
                    dataService: dataService,
                    jobId: VM.jobId,
                    taskTypes: VM.taskTypes,
                    customerId: VM.customer.id,
                    serviceLocationId: VM.serviceLocation.id,
                    tasks: $VM.jobTaskList,
                    shoppingList: $VM.shoppingItemList
                )
                .presentationDetents([.large, .medium])
            }
        } else {
            Button {
                VM.chosenView = "Info"
            } label: {
                actionRow(
                    title: "Add Customer Info",
                    subtitle: "Select a customer and service location first.",
                    systemImage: "person.text.rectangle"
                )
            }
            .buttonStyle(.plain)
        }

        nextButton("Next", systemImage: "chevron.right") {
            VM.chosenView = "Shopping List"
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var shoppingListView: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            sectionHeader("Shopping List", systemImage: "cart")

            Spacer()

            Text("\(VM.shoppingItemList.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        if VM.shoppingItemList.isEmpty {
            emptyState(
                title: "No shopping items.",
                message: "Add any parts or items needed for this job.",
                systemImage: "cart"
            )
        } else {
            VStack(spacing: 8) {
                ForEach(VM.shoppingItemList) { item in
                    ShoppingListItemCardView(
                        dataService: dataService,
                        shoppingListItem: item
                    )
                }
            }
        }

        if VM.customer.id != "" {
            Button {
                VM.isAddShoppingList.toggle()
            } label: {
                actionRow(
                    title: "Add Shopping List Item",
                    subtitle: "Add parts, materials, or required items.",
                    systemImage: "plus.circle"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.isAddShoppingList) {
                AddNewShoppingListItemToNewJob(
                    dataService: dataService,
                    jobId: VM.jobId,
                    customerId: VM.customer.id,
                    customerName: VM.customer.firstName + " " + VM.customer.lastName,
                    serviceLocationId: VM.serviceLocation.id,
                    serviceLocationName: VM.serviceLocation.nickName,
                    shoppingList: $VM.shoppingItemList
                )
                .presentationDetents([.medium, .large])
            }
        } else {
            Button {
                VM.chosenView = "Info"
            } label: {
                actionRow(
                    title: "Add Customer Info",
                    subtitle: "Select a customer before adding shopping list items.",
                    systemImage: "person.text.rectangle"
                )
            }
            .buttonStyle(.plain)
        }

        nextButton("Next", systemImage: "chevron.right") {
            VM.chosenView = "Schedule"
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var schedule: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            sectionHeader("Service Stops", systemImage: "calendar.badge.plus")

            Spacer()

            Text("\(VM.serviceStops.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        if VM.serviceStops.isEmpty {
            emptyState(
                title: "No service stops scheduled.",
                message: "Schedule the first service stop for this job.",
                systemImage: "calendar.badge.exclamationmark"
            )
        } else {
            VStack(spacing: 8) {
                ForEach(VM.serviceStops) { serviceStop in
                    serviceStopScheduleRow(serviceStop)
                }
            }
        }

        if VM.customer.id != "" && VM.serviceLocation.id != "" {
            Button {
                VM.isPresentServiceStop.toggle()
            } label: {
                actionRow(
                    title: "Schedule Service Stop",
                    subtitle: "Create the first scheduled service stop for this job.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.isPresentServiceStop) {
                AddNewScheduleServiceStopToNewJobView(
                    dataService: dataService,
                    jobId: VM.jobId,
                    customerId: VM.customer.id,
                    customerName: VM.customer.firstName + " " + VM.customer.lastName,
                    serviceLocationId: VM.serviceLocation.id,
                    description: VM.description,
                    jobTaskList: VM.jobTaskList,
                    plannedServiceStops: VM.plannedServiceStops,
                    canScheduleForOthers: VM.canScheduleServiceStopsForOthers,
                    preferredTechnicianUserId: masterDataManager.user?.id,
                    serviceStops: $VM.serviceStops,
                    serviceStopTasks: $VM.serviceStopTasks
                )
                .presentationDetents([.medium])
            }
        } else {
            Button {
                VM.chosenView = "Info"
            } label: {
                actionRow(
                    title: "Add Customer Info",
                    subtitle: "Select a customer and service location before scheduling.",
                    systemImage: "person.text.rectangle"
                )
            }
            .buttonStyle(.plain)
        }

        Divider()
            .opacity(0.35)

        HStack {
            sectionHeader("Labor Contracts", systemImage: "doc.text")

            Spacer()

            Text("\(VM.laborContractIds.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }

        if VM.laborContractIds.isEmpty {
            Text("No labor contracts attached.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 8) {
                ForEach(VM.laborContractIds, id: \.self) { id in
                    detailDisplayRow(
                        title: "Labor Contract",
                        value: id,
                        systemImage: "doc.text"
                    )
                }
            }
        }

        Button {
            VM.isPresentLaborContract.toggle()
        } label: {
            actionRow(
                title: "Offer New Labor Contract",
                subtitle: "Available after creating the job.",
                systemImage: "plus.circle"
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $VM.isPresentLaborContract) {
            Text("Add After Creating Job")
                .presentationDetents([.medium, .large])
        }

        nextButton("Next", systemImage: "chevron.right") {
            VM.chosenView = "Review"
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

var customerView: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Customer", systemImage: "person.text.rectangle")

        pickerButtonRow(
            title: "Customer",
            value: VM.customer.id == "" ? "Select Customer" : "\(VM.customer.firstName) \(VM.customer.lastName)",
            systemImage: "person.crop.circle",
            isSelected: VM.customer.id != ""
        ) {
            VM.showCustomerSelector.toggle()
        }

        pickerButtonRow(
            title: "Service Location",
            value: VM.serviceLocation.id == "" ? "Select Location" : "\(VM.serviceLocation.nickName): \(VM.serviceLocation.address.streetAddress)",
            systemImage: "mappin.and.ellipse",
            isSelected: VM.serviceLocation.id != ""
        ) {
            VM.showLocationSelector.toggle()
        }
        .disabled(VM.customer.id == "")
        .opacity(VM.customer.id == "" ? 0.55 : 1)

        pickerButtonRow(
            title: "Body Of Water",
            value: VM.bodyOfWater.id == "" ? "Select Body Of Water" : VM.bodyOfWater.name,
            systemImage: "drop",
            isSelected: VM.bodyOfWater.id != ""
        ) {
            VM.showBodyOfWaterSelector.toggle()
        }
        .disabled(VM.serviceLocation.id == "")
        .opacity(VM.serviceLocation.id == "" ? 0.55 : 1)

        nextButton("Next", systemImage: "chevron.right") {
            VM.chosenView = "Tasks"
        }
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}

    var review: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Review", systemImage: "checkmark.seal")

            if let template = VM.startingTemplate {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Started From Template", systemImage: "square.stack.3d.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(template.name)
                        .font(.subheadline.weight(.semibold))

                    if !template.description.isEmpty {
                        Text(template.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("People & Location", systemImage: "person.text.rectangle")

                reviewRow(title: "Admin", value: VM.admin.userName) {
                    VM.chosenView = "Info"
                }

                reviewRow(title: "Customer", value: "\(VM.customer.firstName) \(VM.customer.lastName)") {
                    VM.chosenView = "Info"
                }

                detailDisplayRow(
                    title: "Service Location",
                    value: "\(VM.serviceLocation.address.streetAddress) \(VM.serviceLocation.address.city)",
                    systemImage: "mappin.and.ellipse"
                )

                if VM.bodyOfWater.id != "" {
                    detailDisplayRow(
                        title: "Body Of Water",
                        value: VM.bodyOfWater.name,
                        systemImage: "drop"
                    )
                }

                if VM.equipment.id != "" {
                    detailDisplayRow(
                        title: "Equipment",
                        value: VM.equipment.name,
                        systemImage: "gearshape"
                    )
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Planned Work", systemImage: "calendar.badge.clock")

                detailDisplayRow(
                    title: "Planned Stops",
                    value: "\(VM.plannedServiceStops.count)",
                    systemImage: "calendar"
                )

                detailDisplayRow(
                    title: "Tasks",
                    value: "\(VM.jobTaskList.count)",
                    systemImage: "checklist"
                )

                detailDisplayRow(
                    title: "Materials",
                    value: "\(VM.shoppingItemList.count)",
                    systemImage: "cart"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("Financial Review", systemImage: "dollarsign.circle")

                AddNewJobReviewMoneyRow(
                    title: "Customer Price",
                    cents: VM.rateCents
                )

                AddNewJobReviewMoneyRow(
                    title: "Saved Labor Cost",
                    cents: VM.laborCostCents
                )

                AddNewJobReviewMoneyRow(
                    title: "Planned Stop Labor",
                    cents: VM.plannedStopLaborCents
                )

                AddNewJobReviewMoneyRow(
                    title: "Planned Task Labor",
                    cents: VM.plannedTaskLaborCents
                )

                AddNewJobReviewMoneyRow(
                    title: "Planned Materials Cost",
                    cents: VM.plannedMaterialCostCents
                )

                AddNewJobReviewMoneyRow(
                    title: "Planned Materials Billable",
                    cents: VM.plannedMaterialPriceCents
                )

                Divider()
                    .opacity(0.2)

                AddNewJobReviewMoneyRow(
                    title: "Projected Profit",
                    cents: VM.projectedProfitCents,
                    valueIsWarning: VM.projectedProfitCents < 0
                )

                if VM.laborCostCents == 0 && VM.plannedTotalLaborCents > 0 {
                    Button {
                        VM.laborCost = String(Double(VM.plannedTotalLaborCents) / 100.0)
                    } label: {
                        Label("Use Planned Labor Total", systemImage: "arrow.down.circle")
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            submitButton
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
var simpleJobView: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader("Simple Job", systemImage: "briefcase")

        pickerButtonRow(
            title: "Customer",
            value: VM.customer.id == "" ? "Select Customer" : "\(VM.customer.firstName) \(VM.customer.lastName)",
            systemImage: "person.crop.circle",
            isSelected: VM.customer.id != ""
        ) {
            VM.showCustomerSelector.toggle()
        }

        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            Picker("Tech", selection: $VM.tech) {
                Text("Pick Tech").tag(CompanyUser(
                    id: "",
                    userId: "",
                    userName: "",
                    roleId: "",
                    roleName: "",
                    dateCreated: Date(),
                    status: .active,
                    workerType: .contractor,
                    linkedCompanyId: "",
                    linkedCompanyName: ""
                ))

                ForEach(VM.techList) { user in
                    Text(user.userName).tag(user)
                }
            }
            .pickerStyle(.menu)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            DatePicker("Service Date", selection: $VM.serviceDate, displayedComponents: .date)
                .font(.subheadline)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        descriptionInputCard

        submitButtonSimple
    }
    .padding(16)
    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
}
}
extension AddNewJobView {

var bottomActionBar: some View {
    VStack(spacing: 0) {
        Divider()
            .opacity(0.35)

        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Label("Cancel", systemImage: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            let isSubmitAction = VM.isTechnicianCreateFlow || VM.chosenView == "Review"

            Button {
                if isSubmitAction {
                    submitCurrentJob()
                } else {
                    goToNextView()
                }
            } label: {
                Label(
                    isSubmitAction ? "Submit" : "Next",
                    systemImage: isSubmitAction ? "checkmark" : "chevron.right"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.regularMaterial)
    }
}

func goToNextView() {
    switch VM.chosenView {
    case "Info":
        VM.chosenView = "Tasks"
    case "Tasks":
        VM.chosenView = "Shopping List"
    case "Shopping List":
        VM.chosenView = "Schedule"
    case "Schedule":
        VM.chosenView = "Review"
    default:
        VM.chosenView = "Review"
    }
}

func submitCurrentJob() {
    Task {
        if let currentCompany = masterDataManager.currentCompany {
            do {
                try await VM.addNewJob(companyId: currentCompany.id)

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif

                dismiss()
            } catch {
                VM.alertMessage = "Invalid Something"
                VM.showAlert = true
                print(error)

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
            }
        }
    }
}

var submitButton: some View {
    Button {
        submitCurrentJob()
    } label: {
        Label("Submit", systemImage: "checkmark")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
}

var submitButtonSimple: some View {
    HStack(spacing: 12) {
        Button {
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.addNewJobSimple(companyId: currentCompany.id)
                    } catch {
                        VM.alertMessage = "Invalid Something"
                        VM.showAlert = true
                        print(error)
                    }
                }
            }
        } label: {
            Label("Save", systemImage: "tray.and.arrow.down")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)

        Button {
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.addNewJobSimple(companyId: currentCompany.id)
                    } catch {
                        VM.alertMessage = "Invalid Something"
                        VM.showAlert = true
                        print(error)
                    }
                }
            }
        } label: {
            Label("Save And Send", systemImage: "paperplane")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

func sectionHeader(_ title: String, systemImage: String) -> some View {
    Label(title, systemImage: systemImage)
        .font(.headline.weight(.semibold))
        .foregroundStyle(.primary)
}

func pickerButtonRow(
    title: String,
    value: String,
    systemImage: String,
    isSelected: Bool,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        pickerRowLabel(
            title: title,
            value: value,
            systemImage: systemImage,
            isSelected: isSelected
        )
    }
    .buttonStyle(.plain)
}

func pickerRowLabel(
    title: String,
    value: String,
    systemImage: String,
    isSelected: Bool
) -> some View {
    HStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(.thinMaterial, in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

func textInputRow(
    title: String,
    systemImage: String,
    placeholder: String,
    text: Binding<String>,
    keyboardType: UIKeyboardType = .default
) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

        TextField(placeholder, text: text)
            .font(.subheadline)
            .keyboardType(keyboardType)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

var descriptionInputCard: some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Label("Description", systemImage: "text.alignleft")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                VM.description = ""
            } label: {
                Text("Clear")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }

        TextField("Description", text: $VM.description, axis: .vertical)
            .font(.subheadline)
            .lineLimit(5, reservesSpace: true)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .focused($focusedField, equals: "Description")
            .submitLabel(.return)
    }
}

func detailDisplayRow(title: String, value: String, systemImage: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
            .background(.thinMaterial, in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value.isEmpty ? "-" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }

        Spacer()
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

func actionRow(title: String, subtitle: String, systemImage: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 30, height: 30)
            .background(.thinMaterial, in: Circle())

        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
    }
    .padding(12)
    .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

func emptyState(title: String, message: String, systemImage: String) -> some View {
    VStack(spacing: 8) {
        Image(systemName: systemImage)
            .font(.title2)
            .foregroundStyle(.secondary)

        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)

        Text(message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
}

func nextButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
    HStack {
        Spacer()

        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentColor.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

func reviewRow(title: String, value: String, action: @escaping () -> Void) -> some View {
    HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value.isEmpty ? "-" : value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }

        Spacer()

        Button(action: action) {
            Image(systemName: "pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
    .padding(12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
}

    func serviceStopScheduleRow(_ serviceStop: ServiceStop) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(serviceStop.customerName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            HStack {
                Label(fullDateAndDay(date: serviceStop.serviceDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tech: \(serviceStop.tech)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Text(serviceStop.operationStatus.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    var plannedServiceStopsPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Planned Service Stops", systemImage: "calendar.badge.clock")

                Spacer()

                Text("\(VM.plannedServiceStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            VStack(spacing: 8) {
                ForEach(VM.plannedServiceStops.sorted(by: { $0.sortOrder < $1.sortOrder })) { stop in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: stop.serviceStopTypeImage.isEmpty ? "calendar" : stop.serviceStopTypeImage)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stop.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("\(stop.serviceStopTypeName) • \(stop.estimatedMinutes) min")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let plannedLaborCostCents = stop.plannedLaborCostCents,
                               plannedLaborCostCents > 0 {
                                Text("Planned labor: \(AddNewJobMoneyFormatter.money(plannedLaborCostCents))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            if !stop.taskIds.isEmpty {
                                Label("\(stop.taskIds.count) linked task(s)", systemImage: "checklist")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
    
 

}
private struct AddNewJobReviewMoneyRow: View {
    let title: String
    let cents: Int
    var valueIsWarning: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(AddNewJobMoneyFormatter.money(cents))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(valueIsWarning ? .orange : .primary)
                .multilineTextAlignment(.trailing)
        }
    }
}
private enum AddNewJobMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}
