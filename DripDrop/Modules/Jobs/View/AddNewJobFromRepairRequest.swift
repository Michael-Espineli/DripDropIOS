//
//  AddNewJobFromRepairRequest.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/4/24.
//

import SwiftUI

@MainActor
final class AddNewJobFromRepairRequestViewModel: ObservableObject {

    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }
    @Published var plannedServiceStops: [JobPlannedServiceStop] = []
    @Published var isAddPlannedServiceStop: Bool = false
    @Published var plannedServiceStopToDelete: JobPlannedServiceStop?
    @Published var showDeletePlannedServiceStopConfirmation: Bool = false
    
    @Published private(set) var techList: [CompanyUser] = []
    @Published private(set) var serviceLocations: [ServiceLocation] = []
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var equipmentList: [Equipment] = []

    @Published private(set) var repairRequest: RepairRequest? = nil
    @Published private(set) var repairRequestPhotos: [DripDropStoredImage] = []

    @Published var description: String = ""

    @Published var tech: CompanyUser = CompanyUser(
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

    @Published var serviceDate: Date = Date()
    @Published var includeReadings: Bool = false
    @Published var includeDosages: Bool = false
    @Published var duration: String = "0"
    @Published var rate: String = "0"
    @Published var laborCost: String = "0"

    @Published var jobId: String = ""
    @Published var jobInternalId: String = ""

    @Published var isEdit: Bool = false
    @Published var isAddTask: Bool = false
    @Published var isAddShoppingList: Bool = false

    @Published var isPresentServiceStop: Bool = false
    @Published var isPresentLaborContract: Bool = false

    @Published var chosenView: String = "Info"
    @Published private(set) var viewOptionList: [String] = [
        "Info",
        "Tasks",
        "Materials",
        "Schedule",
        "Review"
    ]

    @Published var jobTaskList: [JobTask] = []
    @Published var shoppingItemList: [ShoppingListItem] = []
    @Published var serviceStops: [ServiceStop] = []
    @Published var serviceStopTasks: [ServiceStop: [ServiceStopTask]] = [:]

    @Published var laborContracts: [LaborContract] = []

    @Published private(set) var taskTypes: [String] = []
    @Published private(set) var serviceStopIds: [String] = []
    @Published private(set) var laborContractIds: [String] = []

    @Published var showAdminSelector: Bool = false
    @Published var showCustomerSelector: Bool = false
    @Published var showLocationSelector: Bool = false
    @Published var showBodyOfWaterSelector: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    @Published var admin: CompanyUser = CompanyUser(
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

    @Published var customer: Customer = Customer(
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

    @Published var serviceLocation: ServiceLocation = ServiceLocation(
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

    @Published var bodyOfWater: BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date(),
        isActive: true
    )

    @Published var equipment: Equipment = Equipment(
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

    @Published var jobTemplate: JobTemplate = JobTemplate(companyId: "", name: "", createdByUserId: "")

    @Published var serviceStopTemplate: ServiceStopTemplate = ServiceStopTemplate(
        id: "",
        name: "",
        type: "",
        typeImage: "",
        dateCreated: Date(),
        color: ""
    )

    @Published var dateCreated: Date = Date()
    @Published var operationStatus: JobOperationStatus = .estimatePending
    @Published var billingStatus: JobBillingStatus = .draft

    @Published var installationParts: [WODBItem] = []
    @Published var installationPart: WODBItem = WODBItem(
        id: "",
        name: "",
        quantity: 0,
        cost: 0,
        genericItemId: ""
    )
    @Published var showInstallationParts: Bool = false

    @Published var pvcParts: [WODBItem] = []
    @Published var pvcPart: WODBItem = WODBItem(
        id: "",
        name: "",
        quantity: 0,
        cost: 0,
        genericItemId: ""
    )
    @Published var showPvcParts: Bool = false

    @Published var electricalParts: [WODBItem] = []
    @Published var electricalPart: WODBItem = WODBItem(
        id: "",
        name: "",
        quantity: 0,
        cost: 0,
        genericItemId: ""
    )
    @Published var showElectricalParts: Bool = false

    @Published var chemicals: [WODBItem] = []
    @Published var chemical: WODBItem = WODBItem(
        id: "",
        name: "",
        quantity: 0,
        cost: 0,
        genericItemId: ""
    )
    @Published var showChemicals: Bool = false

    @Published var miscParts: [WODBItem] = []
    @Published var miscPart: WODBItem = WODBItem(
        id: "",
        name: "",
        quantity: 0,
        cost: 0,
        genericItemId: ""
    )
    @Published var showMiscParts: Bool = false

    @Published var jobDetailType: String = "Complex"
    @Published var jobDetailTypes: [String] = ["Simple", "Complex"]

    @Published var isSubmitting: Bool = false

    func onLoad(companyId: String, repairRequest: RepairRequest) async throws {
        self.repairRequest = repairRequest

        let workOrderCount = try await dataService.getWorkOrderCount(companyId: companyId)

        self.jobId = "comp_wo_" + UUID().uuidString
        self.jobInternalId = "J" + String(workOrderCount)

        self.description = repairRequest.description
        self.repairRequestPhotos = repairRequest.photoUrls

        self.techList = try await dataService.getAllCompanyUsersByStatus(
            companyId: companyId,
            status: "Active"
        )

        self.taskTypes = [
            "Basic",
            "Clean",
            "Clean Filter",
            "Empty Water",
            "Fill Water",
            "Inspection",
            "Install",
            "Remove",
            "Replace"
        ]

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

        if !repairRequest.customerId.isEmpty {
            self.customer = try await dataService.getCustomerById(
                companyId: companyId,
                customerId: repairRequest.customerId
            )

            try await onChangeOfCustomer(companyId: companyId)
        }

        if let locationId = repairRequest.locationId, !locationId.isEmpty {
            self.serviceLocation = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: locationId
            )

            try await onChangeOfServiceLocation(companyId: companyId)
        }

        if let bodyOfWaterId = repairRequest.bodyOfWaterId, !bodyOfWaterId.isEmpty {
            self.bodyOfWater = try await dataService.getSpecificBodyOfWater(
                companyId: companyId,
                bodyOfWaterId: bodyOfWaterId
            )

            try await onChangeOfBodyOfWater(companyId: companyId)
        }

        if let equipmentId = repairRequest.equipmentId, !equipmentId.isEmpty {
            self.equipment = try await dataService.getSinglePieceOfEquipment(
                companyId: companyId,
                equipmentId: equipmentId
            )
        }
    }

    func onChangeOfCustomer(companyId: String) async throws {
        if customer.id != "" {
            self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
                companyId: companyId,
                customerId: customer.id
            )

            if serviceLocation.id == "", let firstLocation = serviceLocations.first {
                serviceLocation = firstLocation
            }
        }
    }

    func onChangeOfServiceLocation(companyId: String) async throws {
        if serviceLocation.id != "" {
            self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(
                companyId: companyId,
                serviceLocationId: serviceLocation.id
            )

            if bodyOfWater.id == "", let firstBOW = bodiesOfWater.first {
                bodyOfWater = firstBOW
            }
        }
    }

    func onChangeOfBodyOfWater(companyId: String) async throws {
        if bodyOfWater.id != "" {
            self.equipmentList = try await dataService.getEquipmentByBodyOfWater(
                companyId: companyId,
                bodyOfWater: bodyOfWater
            )

            if equipment.id == "", let firstEquipment = equipmentList.first {
                equipment = firstEquipment
            }
        }
    }

    func validateRate() {
        guard !rate.isEmpty else { return }

        if Double(rate) == nil {
            rate = String(rate.dropLast())
        }
    }

    func validateLaborCost() {
        guard !laborCost.isEmpty else { return }

        if Double(laborCost) == nil {
            laborCost = String(laborCost.dropLast())
        }
    }

    func addNewJob(companyId: String) async throws {
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

        let rateInt = Int(rateDouble * 100)

        guard let laborCostDouble = Double(laborCost) else {
            throw JobError.invalidLaborCost
        }

        let laborCostInt = Int(laborCostDouble * 100)

        let fullCustomerName = customer.firstName + " " + customer.lastName

        let job = Job(
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
            senderId: companyId,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: "",
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )

        try await dataService.uploadWorkOrder(
            companyId: companyId,
            workOrder: job
        )
        
        for plannedStop in plannedServiceStops {
            try await dataService.saveJobPlannedServiceStop(plannedStop)
        }
        
        for task in jobTaskList {
            try await dataService.uploadJobTask(
                companyId: companyId,
                jobId: jobId,
                task: task
            )
        }

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

        for stop in serviceStops {
            try await dataService.uploadServiceStop(
                companyId: companyId,
                serviceStop: stop
            )

            let tasks: [ServiceStopTask] = serviceStopTasks[stop] ?? []

            for task in tasks {
                try await dataService.uploadServiceStopTask(
                    companyId: companyId,
                    serviceStopId: stop.id,
                    task: task
                )

                try dataService.updateJobTaskWorkerId(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerId: stop.techId
                )

                try dataService.updateJobTaskWorkerName(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerName: stop.tech
                )

                try dataService.updateJobTaskWorkerType(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerType: .employee
                )

                try dataService.updateJobTaskServiceStopId(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    serviceStopId: IdInfo(
                        id: stop.id,
                        internalId: stop.internalId
                    )
                )

                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    status: .scheduled
                )
            }
        }

        try await updateRepairRequestAfterJobCreated(companyId: companyId)

        self.alertMessage = "Successfully Uploaded"
        self.showAlert = true
    }

    func updateRepairRequestAfterJobCreated(companyId: String) async throws {
        guard var repairRequest else { return }

        if !repairRequest.jobIds.contains(jobId) {
            repairRequest.jobIds.append(jobId)
        }

        repairRequest.status = .convertedToJob

        try await dataService.updateRepairRequest(
            companyId: companyId,
            repairRequest: repairRequest
        )

        self.repairRequest = repairRequest
    }

    func getTotal() -> Double {
        var total: Double = 0

        if let labor = Double(self.laborCost) {
            for part in installationParts {
                total = part.total + total
            }

            for part in pvcParts {
                total = part.total + total
            }

            for part in electricalParts {
                total = part.total + total
            }

            for part in chemicals {
                total = part.total + total
            }

            for part in miscParts {
                total = part.total + total
            }

            total = total + labor
        }

        return total
    }
    var canSubmitJob: Bool {
        guard let rateDouble = Double(rate),
              let laborCostDouble = Double(laborCost) else {
            return false
        }

        return customer.id != "" &&
        serviceLocation.id != "" &&
        admin.userId != "" &&
        admin.id != "" &&
        rateDouble >= 0 &&
        laborCostDouble >= 0
    }

    var rateCents: Int {
        guard let rateDouble = Double(rate) else { return 0 }
        return Int((rateDouble * 100.0).rounded())
    }

    var laborCostCents: Int {
        guard let laborCostDouble = Double(laborCost) else { return 0 }
        return Int((laborCostDouble * 100.0).rounded())
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

    var projectedProfitCents: Int {
        rateCents - laborCostCents - plannedMaterialCostCents
    }

    func usePlannedLaborTotal() {
        laborCost = String(Double(plannedTotalLaborCents) / 100.0)
    }
}

struct AddNewJobFromRepairRequest: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: AddNewJobFromRepairRequestViewModel

    @State var repairRequest: RepairRequest
    @Binding var returnJobId: String

    @FocusState private var focusedField: String?

    init(
        repairRequest: RepairRequest,
        dataService: any ProductionDataServiceProtocol,
        returnJobId: Binding<String>
    ) {
        _VM = StateObject(wrappedValue: AddNewJobFromRepairRequestViewModel(dataService: dataService))
        _repairRequest = State(wrappedValue: repairRequest)
        _returnJobId = returnJobId
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    viewPickerCard

                    if !VM.repairRequestPhotos.isEmpty {
                        repairRequestPhotosCard
                    }

                    switch VM.chosenView {
                    case "Customer":
                        customerView
                    case "Info":
                        info
                    case "Tasks":
                        taskView
                    case "Materials":
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

            if VM.isSubmitting {
                loadingOverlay
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
        .sheet(isPresented: $VM.showAdminSelector) {
            CompanyUserPicker(
                dataService: dataService,
                companyUser: $VM.admin
            )
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
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(
                        companyId: company.id,
                        repairRequest: repairRequest
                    )
                } else {
                    print("No Companies")
                }
            } catch {
                print("Error")
                print(error)
            }
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
                    print(error)
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
                    print(error)
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
                    print(error)
                }
            }
        }
        .onChange(of: VM.rate) { _ in
            VM.validateRate()
        }
        .onChange(of: VM.laborCost) { _ in
            VM.validateLaborCost()
        }
    }
}

// MARK: - Main Layout

extension AddNewJobFromRepairRequest {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Create Job")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Create a job from this repair request and build out the scope, shopping list, and first service stop.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if VM.canSubmitJob {
                    Button {
                        submitJob()
                    } label: {
                        Text("Submit")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.accentColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(VM.isSubmitting)
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
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.chosenView = datum
                            }
                        } label: {
                            Text(datum)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(VM.chosenView == datum ? .primary : .secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(
                                    VM.chosenView == datum
                                    ? Color.accentColor.opacity(0.16)
                                    : Color.clear,
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

    var repairRequestPhotosCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Repair Request Photos", systemImage: "photo")

                Spacer()

                Text("\(VM.repairRequestPhotos.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            DripDropStoredImageRow(images: VM.repairRequestPhotos)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Creating job...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Info

extension AddNewJobFromRepairRequest {

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
}

// MARK: - Tasks

extension AddNewJobFromRepairRequest {

    var taskView: some View {
        VStack(alignment: .leading, spacing: 14) {
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
            plannedServiceStopsCard
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
                            jobId: VM.jobId,
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
}

// MARK: - Shopping List

extension AddNewJobFromRepairRequest {

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
                        subtitle: "Add parts, materials, or other required items.",
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
}

// MARK: - Schedule

extension AddNewJobFromRepairRequest {

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
                        serviceStops: $VM.serviceStops,
                        serviceStopTasks: $VM.serviceStopTasks
                    )
                    .presentationDetents([.medium, .large])
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
}

// MARK: - Customer

extension AddNewJobFromRepairRequest {

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
}

// MARK: - Review

extension AddNewJobFromRepairRequest {

    var review: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Review", systemImage: "checkmark.seal")

            VStack(alignment: .leading, spacing: 10) {
                sectionHeader("People & Location", systemImage: "person.text.rectangle")

                reviewRow(title: "Admin", value: VM.admin.userName) {
                    VM.chosenView = "Info"
                }

                reviewRow(title: "Customer", value: "\(VM.customer.firstName) \(VM.customer.lastName)") {
                    VM.chosenView = "Customer"
                }

                detailDisplayRow(
                    title: "Address",
                    value: "\(VM.serviceLocation.address.streetAddress) \(VM.serviceLocation.address.city)",
                    systemImage: "mappin.and.ellipse"
                )

                detailDisplayRow(
                    title: "Body Of Water",
                    value: VM.bodyOfWater.name,
                    systemImage: "drop"
                )

                detailDisplayRow(
                    title: "Equipment",
                    value: VM.equipment.name,
                    systemImage: "gearshape"
                )
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

                RepairRequestJobMoneyRow(
                    title: "Customer Price",
                    cents: VM.rateCents
                )

                RepairRequestJobMoneyRow(
                    title: "Saved Labor Cost",
                    cents: VM.laborCostCents
                )

                RepairRequestJobMoneyRow(
                    title: "Planned Stop Labor",
                    cents: VM.plannedStopLaborCents
                )

                RepairRequestJobMoneyRow(
                    title: "Planned Task Labor",
                    cents: VM.plannedTaskLaborCents
                )

                RepairRequestJobMoneyRow(
                    title: "Planned Materials Cost",
                    cents: VM.plannedMaterialCostCents
                )

                RepairRequestJobMoneyRow(
                    title: "Planned Materials Billable",
                    cents: VM.plannedMaterialPriceCents
                )

                Divider()
                    .opacity(0.2)

                RepairRequestJobMoneyRow(
                    title: "Projected Profit",
                    cents: VM.projectedProfitCents,
                    valueIsWarning: VM.projectedProfitCents < 0
                )

                if VM.laborCostCents == 0 && VM.plannedTotalLaborCents > 0 {
                    Button {
                        VM.usePlannedLaborTotal()
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

            if !VM.repairRequestPhotos.isEmpty {
                repairRequestPhotosCard
            }

            Button {
                submitJob()
            } label: {
                Label("Submit", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!VM.canSubmitJob || VM.isSubmitting)
            .opacity(!VM.canSubmitJob || VM.isSubmitting ? 0.55 : 1)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }}

// MARK: - Bottom Bar

extension AddNewJobFromRepairRequest {

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

                Button {
                    if VM.chosenView == "Review" {
                        submitJob()
                    } else {
                        goToNextView()
                    }
                } label: {
                    Label(
                        VM.chosenView == "Review" ? "Create Job" : "Next",
                        systemImage: VM.chosenView == "Review" ? "checkmark" : "chevron.right"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.isSubmitting || (VM.chosenView == "Review" && !VM.canSubmitJob))
                .opacity(VM.isSubmitting || (VM.chosenView == "Review" && !VM.canSubmitJob) ? 0.55 : 1)
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
    var plannedServiceStopsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
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

            if VM.plannedServiceStops.isEmpty {
                emptyState(
                    title: "No planned service stops.",
                    message: "Plan expected visits before scheduling real service stops.",
                    systemImage: "calendar.badge.plus"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.plannedServiceStops.sorted(by: { $0.sortOrder < $1.sortOrder })) { stop in
                        plannedServiceStopRow(stop)
                    }
                }
            }

            Button {
                VM.isAddPlannedServiceStop = true
            } label: {
                actionRow(
                    title: "Add Planned Stop",
                    subtitle: "Plan an expected job visit before scheduling.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $VM.isAddPlannedServiceStop) {
                AddJobPlannedServiceStopDraftSheet(
                    companyId: masterDataManager.currentCompany?.id ?? "",
                    jobId: VM.jobId,
                    jobTasks: VM.jobTaskList,
                    existingPlannedStops: VM.plannedServiceStops,
                    dataService: dataService,
                    plannedStops: $VM.plannedServiceStops
                )
                .presentationDetents([.medium, .large])
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    func plannedServiceStopRow(_ stop: JobPlannedServiceStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: stop.serviceStopTypeImage.isEmpty ? "calendar" : stop.serviceStopTypeImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(stop.name)
                    .font(.subheadline.weight(.semibold))

                Text("\(stop.serviceStopTypeName) • \(stop.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let plannedLaborCostCents = stop.plannedLaborCostCents,
                   plannedLaborCostCents > 0 {
                    Text("Planned labor: \(RepairRequestJobMoneyFormatter.money(plannedLaborCostCents))")
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

            Button {
                VM.plannedServiceStops.removeAll { $0.id == stop.id }
            } label: {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private struct RepairRequestJobMoneyRow: View {
        let title: String
        let cents: Int
        var valueIsWarning: Bool = false

        var body: some View {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(RepairRequestJobMoneyFormatter.money(cents))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(valueIsWarning ? .orange : .primary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private enum RepairRequestJobMoneyFormatter {
        static func money(_ cents: Int) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2

            return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
        }
    }
}

// MARK: - Actions

extension AddNewJobFromRepairRequest {

    func submitJob() {
        Task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.isSubmitting = true

                    try await VM.addNewJob(companyId: currentCompany.id)

                    returnJobId = VM.jobId
                    VM.isSubmitting = false

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    dismiss()
                } catch JobError.invalidRate {
                    handleSubmitError("Invalid Rate")
                } catch JobError.invalidLaborCost {
                    handleSubmitError("Invalid Labor Cost")
                } catch JobError.invalidAdmin {
                    handleSubmitError("Invalid Admin Selected")
                } catch JobError.invalidCustomer {
                    handleSubmitError("Invalid Customer Selected")
                } catch JobError.invalidJobType {
                    handleSubmitError("Invalid Job Selected")
                } catch JobError.invalidServiceLocation {
                    handleSubmitError("Invalid Service Location Selected")
                } catch {
                    handleSubmitError("Invalid Something")
                    print(error)
                }
            }
        }
    }

    func handleSubmitError(_ message: String) {
        VM.isSubmitting = false
        VM.alertMessage = message
        VM.showAlert = true

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }
}

// MARK: - Reusable UI

extension AddNewJobFromRepairRequest {

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
                isSelected: isSelected,
                chevronSystemImage: "chevron.right"
            )
        }
        .buttonStyle(.plain)
    }

    func pickerRowLabel(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        chevronSystemImage: String = "chevron.right"
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

            Image(systemName: chevronSystemImage)
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
}
