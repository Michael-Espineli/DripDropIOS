import SwiftUI

@MainActor
final class EditTaskViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol
    let originalTask: JobTask
    let jobId: String

    init(dataService: any ProductionDataServiceProtocol, task: JobTask, jobId: String) {
        self.dataService = dataService
        self.originalTask = task
        self.jobId = jobId
        // Prefill editable fields from the original task
        self.name = task.name
        self.selectedTaskType = task.type
        self.contractedRateString = String(Double(task.contractedRate) / 100)
        self.estimatedTimeString = String(task.estimatedTime)
        self.quantityString = "0"
        self.selectedEquipment = Equipment(
            id: task.equipmentId,
            name: "",
            type: .filter,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: "",
            customerId: "",
            serviceLocationId: task.serviceLocationId,
            bodyOfWaterId: "",
            isActive: true
        )
        self.selectedBodyOfWater = BodyOfWater(
            id: task.bodyOfWaterId,
            name: "",
            gallons: "",
            material: "",
            customerId: "",
            serviceLocationId: task.serviceLocationId,
            lastFilled: Date(),
            isActive: true
        )
        self.dataBaseItem = DataBaseItem(
            id: task.dataBaseItemId,
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
    }

    // UI State
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var showTaskTypePicker: Bool = false
    @Published var showItemPicker: Bool = false
    @Published var showBOWPicker: Bool = false
    @Published var showEquipmentPicker: Bool = false

    // Editable fields
    @Published var name: String = ""
    @Published var contractedRateString: String = "0"
    @Published var estimatedTimeString: String = "0"
    @Published var quantityString: String = "0"

    @Published var selectedTaskType: JobTaskType = .basic

    @Published private(set) var bodyOfWaterList: [BodyOfWater] = []
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

    @Published private(set) var equipmentList: [Equipment] = []
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

    @Published private(set) var installList: [DataBaseItem] = []
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

    func onLoad(companyId: String) async throws {
        // Preload pick lists for the task's service location
        let serviceLocationId = originalTask.serviceLocationId
        self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
        self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
    }

    func onChangeOfSelectedTaskType(companyId: String, customerId: String) async throws {
        let serviceLocationId = originalTask.serviceLocationId
        switch selectedTaskType {
        case .basic, .clean:
            break
        case .cleanFilter:
            self.equipmentList = try await dataService.getEquipmentByServiceLocationIdAndCategory(companyId: companyId, serviceLocationId: serviceLocationId, category: .filter)
            if let first = equipmentList.first { self.selectedEquipment = first }
        case .emptyWater, .fillWater:
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = bodyOfWaterList.first { self.selectedBodyOfWater = first }
        case .inspection:
            break
        case .install, .remove, .replace, .maintenance, .repair:
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocationId)
            if let first = equipmentList.first { self.selectedEquipment = first }
        }
    }

    func checkNumber(numberStr: String) -> Bool { numberStr.isNumber }

    func updateExistingTask(companyId: String) async throws {
        if name.isEmpty { throw AddNewTaskToJobError.noName }
        if contractedRateString.isEmpty { throw AddNewTaskToJobError.noContractedRate }
        if estimatedTimeString.isEmpty { throw AddNewTaskToJobError.noEstimatedTime }

        guard let contractedRateDouble = Double(contractedRateString) else { throw AddNewTaskToJobError.noContractedRate }
        let contractedRate = Int(contractedRateDouble * 100)
        guard let estimatedTime = Int(estimatedTimeString) else { throw AddNewTaskToJobError.noEstimatedTime }
        _ = Double(quantityString) // quantity may be unused for some types

        switch selectedTaskType {
        case .basic, .clean, .inspection:
            break
        case .cleanFilter, .remove, .maintenance, .repair:
            if selectedEquipment.id.isEmpty { throw AddNewTaskToJobError.noBowSelected }
        case .emptyWater, .fillWater:
            if selectedBodyOfWater.id.isEmpty { throw AddNewTaskToJobError.noBowSelected }
        case .install, .replace:
            if selectedEquipment.id.isEmpty || dataBaseItem.id.isEmpty { throw AddNewTaskToJobError.noShoppingListItem }
        }

        // Apply updates via service functions already used elsewhere in project
        try dataService.updateJobTaskName(companyId: companyId, jobId: jobId, taskId: originalTask.id, name: name)
        try dataService.updateJobTaskType(companyId: companyId, jobId: jobId, taskId: originalTask.id, type: selectedTaskType.rawValue)
//        try dataService.updateJobTaskContractedRate(companyId: companyId, jobId: jobId, taskId: originalTask.id, contractedRate: contractedRate)
//        try dataService.updateJobTaskEstimatedTime(companyId: companyId, jobId: jobId, taskId: originalTask.id, estimatedTime: estimatedTime)
//        try dataService.updateJobTaskEquipmentId(companyId: companyId, jobId: jobId, taskId: originalTask.id, equipmentId: selectedEquipment.id)
//        try dataService.updateJobTaskBodyOfWaterId(companyId: companyId, jobId: jobId, taskId: originalTask.id, bodyOfWaterId: selectedBodyOfWater.id)
//        try dataService.updateJobTaskDBItemId(companyId: companyId, jobId: jobId, taskId: originalTask.id, dataBaseItemId: dataBaseItem.id)
    }
}

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EditTaskViewModel

    init(dataService: any ProductionDataServiceProtocol, task: JobTask) {
        // We need jobId to update; derive from task.serviceStopId.internalId if not carried separately.
        // For this app, JobDetailView passes job.id into EditTaskView; keep jobId as the task.serviceStopId.internalId fallback.
        _VM = StateObject(wrappedValue: EditTaskViewModel(dataService: dataService, task: task, jobId: task.serviceStopId.internalId))
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()
            ScrollView { formView }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) { Button("OK", role: .cancel) { } }
        .task {
            do {
                if let currentCompany = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: currentCompany.id)
                }
            } catch { print(error) }
        }
        .onChange(of: VM.selectedTaskType) { _ in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do { try await VM.onChangeOfSelectedTaskType(companyId: currentCompany.id, customerId: "") } catch { print(error) }
                }
            }
        }
        .onChange(of: VM.contractedRateString) { str in
            let isNumber = VM.checkNumber(numberStr: str)
            if str != "" && !isNumber { VM.contractedRateString = String(str.dropLast()) }
        }
        .onChange(of: VM.estimatedTimeString) { str in
            let isNumber = VM.checkNumber(numberStr: str)
            if str != "" && !isNumber { VM.estimatedTimeString = String(str.dropLast()) }
        }
    }
}

extension EditTaskView {
    var formView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Name").bold(true)
                TextField("Name", text: $VM.name)
                    .modifier(TextFieldModifier())
            }
            HStack {
                Text("Contracted Rate").bold(true)
                TextField("Contracted Rate", text: $VM.contractedRateString)
                    .keyboardType(.decimalPad)
                    .modifier(TextFieldModifier())
            }
            HStack {
                Text("Estimated Time").bold(true)
                TextField("Estimated Time", text: $VM.estimatedTimeString)
                    .keyboardType(.decimalPad)
                    .modifier(TextFieldModifier())
            }
            HStack {
                Button(action: { VM.showTaskTypePicker.toggle() }) {
                    Text(VM.selectedTaskType.rawValue)
                        .modifier(BlueButtonModifier())
                }
                .sheet(isPresented: $VM.showTaskTypePicker) {
                    JobTaskTypePicker(taskType: $VM.selectedTaskType)
                        .presentationDetents([.large, .medium])
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                switch VM.selectedTaskType {
                case .basic, .clean:
                    Text("No Extra Details Needed")
                case .cleanFilter:
                    Button(action: { VM.showEquipmentPicker.toggle() }) {
                        Text(VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name)
                    }
                    .sheet(isPresented: $VM.showEquipmentPicker) {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, equipment: $VM.selectedEquipment)
                    }
                case .emptyWater:
                    Button(action: { VM.showBOWPicker.toggle() }) {
                        Text(VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name)
                    }
                    .sheet(isPresented: $VM.showBOWPicker) {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    }
                case .fillWater:
                    Button(action: { VM.showBOWPicker.toggle() }) {
                        Text(VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name)
                    }
                    .sheet(isPresented: $VM.showBOWPicker) {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    }
                case .inspection:
                    Text("Inspection")
                case .install:
                    Button(action: { VM.showBOWPicker.toggle() }) {
                        Text(VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name)
                    }
                    .sheet(isPresented: $VM.showBOWPicker) {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    }
                    Button(action: { VM.showItemPicker.toggle() }) {
                        Text(VM.dataBaseItem.id.isEmpty ? "Select Item" : VM.dataBaseItem.name)
                            .modifier(BlueButtonModifier())
                    }
                    .sheet(isPresented: $VM.showItemPicker) {
                        DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                    }
                    HStack {
                        Text("Quantity").bold(true)
                        TextField("Quantity", text: $VM.quantityString)
                            .modifier(TextFieldModifier())
                    }
                case .remove:
                    Button(action: { VM.showEquipmentPicker.toggle() }) {
                        Text(VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name)
                    }
                    .sheet(isPresented: $VM.showEquipmentPicker) {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, equipment: $VM.selectedEquipment)
                    }
                case .replace:
                    Button(action: { VM.showEquipmentPicker.toggle() }) {
                        Text(VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name)
                    }
                    .sheet(isPresented: $VM.showEquipmentPicker) {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, equipment: $VM.selectedEquipment)
                    }
                    Button(action: { VM.showBOWPicker.toggle() }) {
                        Text(VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name)
                    }
                    .sheet(isPresented: $VM.showBOWPicker) {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    }
                    Divider()
                    Text("Install")
                    Button(action: { VM.showItemPicker.toggle() }) {
                        Text(VM.dataBaseItem.id.isEmpty ? "Select Item" : VM.dataBaseItem.name)
                            .modifier(BlueButtonModifier())
                    }
                    .sheet(isPresented: $VM.showItemPicker) {
                        DataBaseItemPicker(dataService: dataService, DBItem: $VM.dataBaseItem, category: .equipment)
                    }
                    HStack {
                        Text("Quantity").bold(true)
                        TextField("Quantity", text: $VM.quantityString)
                            .modifier(TextFieldModifier())
                    }
                case .maintenance:
                    Button(action: { VM.showEquipmentPicker.toggle() }) {
                        Text(VM.selectedEquipment.id.isEmpty ? "Select Equipment" : VM.selectedEquipment.name)
                    }
                    .sheet(isPresented: $VM.showEquipmentPicker) {
                        EquipmentPickerByServiceLocationId(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, equipment: $VM.selectedEquipment)
                    }
                case .repair:
                    Button(action: { VM.showBOWPicker.toggle() }) {
                        Text(VM.selectedBodyOfWater.id.isEmpty ? "Select Body Of Water" : VM.selectedBodyOfWater.name)
                    }
                    .sheet(isPresented: $VM.showBOWPicker) {
                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.originalTask.serviceLocationId, bodyOfWater: $VM.selectedBodyOfWater)
                    }
                }
            }

            Button(action: {
                Task {
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await VM.updateExistingTask(companyId: company.id)
                            dismiss()
                        } catch {
                            if let myError = error as? AddNewTaskToJobError {
                                VM.alertMessage = myError.errorDescription
                                VM.showAlert.toggle()
                            } else { VM.alertMessage = error.localizedDescription; VM.showAlert.toggle() }
                        }
                    }
                }
            }) {
                HStack { Spacer(); Text("Save Changes"); Spacer() }
                    .modifier(SubmitButtonModifier())
            }
        }
        .padding(8)
    }
}
