//
//  EquipmentServiceActionViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/16/26.
//


//
//  EquipmentServiceActionViews.swift
//  ThePoolApp
//
//  Created by Michael Espineli.
//

import SwiftUI

// MARK: - Shared VM

@MainActor
final class EquipmentServiceActionViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var companyUsers: [CompanyUser] = []

    @Published var selectedAdmin: CompanyUser = CompanyUser(
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

    @Published var selectedTech: CompanyUser = CompanyUser(
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

    @Published var showAdminPicker: Bool = false
    @Published var showTechPicker: Bool = false

    @Published var name: String = ""
    @Published var serviceDate: Date = Date()
    @Published var description: String = ""

    @Published var performedBy: ServicePerformaceType = .company
    @Published var addedBy: ServiceRecordType = .manual

    @Published var customerPerformerName: String = ""

    @Published var currentPartName: String = ""
    @Published var partNames: [String] = []

    @Published var shouldScheduleServiceStop: Bool = true
    @Published var jobDescription: String = ""
    @Published var jobDate: Date = Date()

    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    func onLoad(companyId: String, defaultName: String, defaultDescription: String) async throws {
        self.name = defaultName
        self.description = defaultDescription
        self.jobDescription = defaultDescription

        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(
            companyId: companyId,
            status: "Active"
        )

        if selectedAdmin.id.isEmpty, let first = companyUsers.first {
            selectedAdmin = first
        }

        if selectedTech.id.isEmpty, let first = companyUsers.first {
            selectedTech = first
        }
    }

    func addPartName() {
        let cleanName = currentPartName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        partNames.append(cleanName)
        currentPartName = ""
    }

    func removePartName(_ value: String) {
        partNames.removeAll { $0 == value }
    }
    
    func calculateNextServiceDate(from date: Date, equipment: Equipment) -> Date? {
        guard let frequency = equipment.serviceFrequency,
              let every = equipment.serviceFrequencyEvery else {
            return nil
        }

        switch every {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: frequency, to: date)

        case .weekly:
            return Calendar.current.date(byAdding: .day, value: frequency * 7, to: date)

        case .monthly:
            return Calendar.current.date(byAdding: .month, value: frequency, to: date)

        case .yearly:
            return Calendar.current.date(byAdding: .year, value: frequency, to: date)
        }
    }

    func createServiceHistory(
        companyId: String,
        equipment: Equipment,
        type: EquipmentServiceType,
        partIds: [String],
        jobId: String = ""
    ) async throws {
        let performedTechId: String
        let performedTechName: String

        switch performedBy {
        case .company:
            performedTechId = selectedTech.userId
            performedTechName = selectedTech.userName

        case .customer:
            performedTechId = ""
            performedTechName = customerPerformerName

        default:
            performedTechId = selectedTech.userId
            performedTechName = selectedTech.userName
        }

        let record = EquipmentServiceHistory(
            id: "com_equ_sh_" + UUID().uuidString,
            name: name,
            type: type,
            date: serviceDate,
            description: description,
            performedBy: performedBy,
            addedBy: addedBy,
            techId: performedTechId,
            techName: performedTechName,
            jobId: jobId,
            partIds: partIds
        )

        try await dataService.uploadEquipmentServiceHistory(
            companyId: companyId,
            equipmentId: equipment.id,
            history: record
        )

        if type == .maintenance {
            let nextDate = calculateNextServiceDate(
                from: serviceDate,
                equipment: equipment
            )

            try await dataService.updateEquipmentServiceDates(
                companyId: companyId,
                equipmentId: equipment.id,
                lastServiceDate: serviceDate,
                nextServiceDate: nextDate
            )
        }
    }
    
    func createRepairParts(
        companyId: String,
        equipmentId: String
    ) async throws -> [String] {
        var ids: [String] = []

        for partName in partNames {
            let cleanName = partName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanName.isEmpty else { continue }

            let id = try await dataService.createEquipmentPartFromName(
                companyId: companyId,
                equipmentId: equipmentId,
                name: cleanName
            )

            ids.append(id)
        }

        return ids
    }
// Scheule Maintance / job Repair Work Flow
    /*
     Schedule maintenance/repair job
     → create Job
     → optionally create ServiceStop
     → create EquipmentScheduledWork
     → EquipmentDetailView shows Scheduled Work
     → work gets completed
     → create EquipmentServiceHistory
     → update EquipmentScheduledWork to Completed
     → EquipmentDetailView no longer shows it in active scheduled work
     
     try await dataService.uploadEquipmentServiceHistory(
         companyId: companyId,
         equipmentId: equipment.id,
         history: record
     )

     try await dataService.updateEquipmentScheduledWorkStatus(
         companyId: companyId,
         equipmentId: equipment.id,
         scheduledWorkId: scheduledWorkId,
         status: .completed,
         dateCompleted: Date()
     )
     */
    func createJobAndOptionalServiceStop(
        companyId: String,
        equipment: Equipment,
        jobType: EquipmentServiceType
    ) async throws {
        guard !selectedAdmin.id.isEmpty else {
            throw JobError.invalidAdmin
        }

        guard !equipment.customerId.isEmpty else {
            throw JobError.invalidCustomer
        }

        guard !equipment.serviceLocationId.isEmpty else {
            throw JobError.invalidServiceLocation
        }

        if shouldScheduleServiceStop && selectedTech.id.isEmpty {
            throw FireBasePublish.unableToPublish
        }

        let jobCount = try await dataService.getWorkOrderCount(companyId: companyId)

        let jobId = "comp_wo_" + UUID().uuidString
        let jobInternalId = "J" + String(jobCount)

        var serviceStopIds: [String] = []

        let job = Job(
            id: jobId,
            internalId: jobInternalId,
            type: jobType.rawValue,
            dateCreated: Date(),
            description: jobDescription,
            operationStatus: shouldScheduleServiceStop ? .scheduled : .estimatePending,
            billingStatus: .draft,
            customerId: equipment.customerId,
            customerName: equipment.customerName,
            serviceLocationId: equipment.serviceLocationId,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: selectedAdmin.userId,
            adminName: selectedAdmin.userName,
            rate: 0,
            laborCost: 0,
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

        if shouldScheduleServiceStop {
            let serviceStopCount = try await dataService.getServiceOrderCount(companyId: companyId)

            let location = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: equipment.serviceLocationId
            )

            let serviceStopId = "comp_ss_" + UUID().uuidString
            let serviceStopInternalId = "SS" + String(serviceStopCount)
            let serviceStopTypeFields = await dataService.resolvedServiceStopTypeFields(
                companyId: companyId,
                useCase: .serviceCall,
                context: "EquipmentServiceActionViewModel.createJobAndOptionalServiceStop"
            )

            let serviceStop = ServiceStop(
                id: serviceStopId,
                internalId: serviceStopInternalId,
                companyId: companyId,
                companyName: "",
                customerId: equipment.customerId,
                customerName: equipment.customerName,
                address: location.address,
                dateCreated: Date(),
                serviceDate: jobDate,
                duration: 0,
                estimatedDuration: 0,
                tech: selectedTech.userName,
                techId: selectedTech.userId,
                recurringServiceStopId: "",
                description: jobDescription,
                serviceLocationId: equipment.serviceLocationId,
                typeId: serviceStopTypeFields.typeId,
                type: serviceStopTypeFields.type,
                typeImage: serviceStopTypeFields.typeImage,
                jobId: jobId,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: false,
                includeDosages: false,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )

            serviceStopIds.append(serviceStopId)

            try await dataService.uploadServiceStop(
                companyId: companyId,
                serviceStop: serviceStop
            )
            let scheduledWork = EquipmentScheduledWork(
                name: "\(jobType.rawValue) Job",
                type: jobType,
                serviceDate: shouldScheduleServiceStop ? jobDate : nil,
                techId: shouldScheduleServiceStop ? selectedTech.userId : "",
                techName: shouldScheduleServiceStop ? selectedTech.userName : "",
                serviceStopId: shouldScheduleServiceStop ? serviceStopIds.first ?? "" : "",
                serviceStopInternalId: serviceStopInternalId,
                jobId: jobId,
                jobInternalId: jobInternalId,
                status: shouldScheduleServiceStop ? .scheduled : .estimatePending,
                description: jobDescription,
                dateCreated: Date(),
                dateCompleted: nil
            )

            try await dataService.uploadEquipmentScheduledWork(
                companyId: companyId,
                equipmentId: equipment.id,
                scheduledWork: scheduledWork
            )
        }

        let finalJob = Job(
            id: job.id,
            internalId: job.internalId,
            type: job.type,
            dateCreated: job.dateCreated,
            description: job.description,
            operationStatus: job.operationStatus,
            billingStatus: job.billingStatus,
            customerId: job.customerId,
            customerName: job.customerName,
            serviceLocationId: job.serviceLocationId,
            serviceStopIds: serviceStopIds,
            laborContractIds: [],
            adminId: job.adminId,
            adminName: job.adminName,
            rate: job.rate,
            laborCost: job.laborCost,
            otherCompany: job.otherCompany,
            receivedLaborContractId: job.receivedLaborContractId,
            receiverId: job.receiverId,
            senderId: job.senderId,
            dateEstimateAccepted: job.dateEstimateAccepted,
            estimateAcceptedById: job.estimateAcceptedById,
            estimateAcceptType: job.estimateAcceptType,
            estimateAcceptedNotes: job.estimateAcceptedNotes,
            invoiceDate: job.invoiceDate,
            invoiceRef: job.invoiceRef,
            invoiceType: job.invoiceType,
            invoiceNotes: job.invoiceNotes
        )

        try await dataService.uploadWorkOrder(
            companyId: companyId,
            workOrder: finalJob
        )
    }
}

struct EquipmentTaskHistoryService {
    let dataService: any ProductionDataServiceProtocol

    func recordJobTaskCompletion(
        companyId: String,
        task: JobTask,
        jobId: String,
        completedAt: Date = Date()
    ) async throws {
        guard let type = serviceHistoryType(for: task.type),
              !task.equipmentId.isEmpty else {
            return
        }

        let equipment = try await dataService.getSinglePieceOfEquipment(
            companyId: companyId,
            equipmentId: task.equipmentId
        )

        let history = EquipmentServiceHistory(
            id: historyId(for: task.id),
            name: historyName(taskName: task.name, taskType: task.type),
            type: type,
            date: completedAt,
            description: "Auto-created from finished \(task.type.rawValue) task.",
            performedBy: performedBy(for: task.workerType),
            addedBy: .auto,
            techId: task.workerId,
            techName: task.workerName,
            jobId: jobId,
            partIds: []
        )

        try await save(history, for: equipment, companyId: companyId)
    }

    func recordServiceStopTaskCompletion(
        companyId: String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        completedAt: Date = Date()
    ) async throws {
        guard let type = serviceHistoryType(for: task.type),
              !task.equipmentId.isEmpty else {
            return
        }

        let equipment = try await dataService.getSinglePieceOfEquipment(
            companyId: companyId,
            equipmentId: task.equipmentId
        )

        let sourceId = task.jobTaskId.isEmpty ? task.id : task.jobTaskId
        let techId = task.workerId.isEmpty ? serviceStop.techId : task.workerId
        let techName = task.workerName.isEmpty ? serviceStop.tech : task.workerName
        let jobId = task.jobId.id.isEmpty ? serviceStop.jobId : task.jobId.id

        let history = EquipmentServiceHistory(
            id: historyId(for: sourceId),
            name: historyName(taskName: task.name, taskType: task.type),
            type: type,
            date: completedAt,
            description: "Auto-created from finished \(task.type.rawValue) service stop task.",
            performedBy: performedBy(for: task.workerType),
            addedBy: .auto,
            techId: techId,
            techName: techName,
            jobId: jobId,
            partIds: []
        )

        try await save(history, for: equipment, companyId: companyId)
    }

    private func save(
        _ history: EquipmentServiceHistory,
        for equipment: Equipment,
        companyId: String
    ) async throws {
        try await dataService.uploadEquipmentServiceHistory(
            companyId: companyId,
            equipmentId: equipment.id,
            history: history
        )

        guard history.type == .maintenance else { return }

        try await dataService.updateEquipmentServiceDates(
            companyId: companyId,
            equipmentId: equipment.id,
            lastServiceDate: history.date,
            nextServiceDate: nextServiceDate(from: history.date, equipment: equipment)
        )
    }

    private func serviceHistoryType(for taskType: JobTaskType) -> EquipmentServiceType? {
        switch taskType {
        case .cleanFilter, .maintenance:
            return .maintenance
        case .repair, .replace:
            return .repair
        case .basic, .clean, .emptyWater, .fillWater, .inspection, .install, .remove:
            return nil
        }
    }

    private func performedBy(for workerType: WorkerTypeEnum) -> ServicePerformaceType {
        switch workerType {
        case .contractor:
            return .contractor
        case .employee:
            return .company
        case .notAssigned:
            return .unknown
        }
    }

    private func historyName(taskName: String, taskType: JobTaskType) -> String {
        let trimmedName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? taskType.rawValue : trimmedName
    }

    private func historyId(for sourceId: String) -> String {
        let cleanedId = sourceId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        return "auto_equ_sh_\(cleanedId)"
    }

    private func nextServiceDate(from date: Date, equipment: Equipment) -> Date? {
        guard let frequency = equipment.serviceFrequency,
              let every = equipment.serviceFrequencyEvery else {
            return nil
        }

        switch every {
        case .daily:
            return Calendar.current.date(byAdding: .day, value: frequency, to: date)
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: frequency * 7, to: date)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: frequency, to: date)
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: frequency, to: date)
        }
    }
}

// MARK: - 1. Record Maintenance

struct RecordEquipmentMaintenanceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EquipmentServiceActionViewModel
    @State var equipment: Equipment

    var onSaved: (() -> Void)? = nil

    init(
        dataService: any ProductionDataServiceProtocol,
        equipment: Equipment,
        onSaved: (() -> Void)? = nil
    ) {
        _VM = StateObject(wrappedValue: EquipmentServiceActionViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
        self.onSaved = onSaved
    }

    var body: some View {
        EquipmentServiceRecordShell(
            title: "Record Maintenance",
            subtitle: equipment.name,
            systemImage: "wrench.and.screwdriver",
            VM: VM,
            equipment: equipment,
            showParts: false,
            submitTitle: "Save Maintenance"
        ) {
            save()
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(
                        companyId: company.id,
                        defaultName: "Maintenance",
                        defaultDescription: "Maintenance performed on \(equipment.name)."
                    )
                } catch {
                    print(error)
                }
            }
        }
        .sheet(isPresented: $VM.showTechPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedTech)
        }
    }

    func save() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                VM.isSaving = true

                try await VM.createServiceHistory(
                    companyId: company.id,
                    equipment: equipment,
                    type: .maintenance,
                    partIds: []
                )

                VM.isSaving = false
                onSaved?()
                dismiss()
            } catch {
                VM.isSaving = false
                VM.alertMessage = error.localizedDescription
                VM.showAlert = true
            }
        }
    }
}

// MARK: - 2. Record Repair

struct RecordEquipmentRepairView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EquipmentServiceActionViewModel
    @State var equipment: Equipment

    var onSaved: (() -> Void)? = nil

    init(
        dataService: any ProductionDataServiceProtocol,
        equipment: Equipment,
        onSaved: (() -> Void)? = nil
    ) {
        _VM = StateObject(wrappedValue: EquipmentServiceActionViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
        self.onSaved = onSaved
    }

    var body: some View {
        EquipmentServiceRecordShell(
            title: "Record Repair",
            subtitle: equipment.name,
            systemImage: "cross.case",
            VM: VM,
            equipment: equipment,
            showParts: true,
            submitTitle: "Save Repair"
        ) {
            save()
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(
                        companyId: company.id,
                        defaultName: "Repair",
                        defaultDescription: "Repair performed on \(equipment.name)."
                    )
                } catch {
                    print(error)
                }
            }
        }
        .sheet(isPresented: $VM.showTechPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedTech)
        }
    }

    func save() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                VM.isSaving = true

                let partIds = try await VM.createRepairParts(
                    companyId: company.id,
                    equipmentId: equipment.id
                )

                try await VM.createServiceHistory(
                    companyId: company.id,
                    equipment: equipment,
                    type: .repair,
                    partIds: partIds
                )

                VM.isSaving = false
                onSaved?()
                dismiss()
            } catch {
                VM.isSaving = false
                VM.alertMessage = error.localizedDescription
                VM.showAlert = true
            }
        }
    }
}

// MARK: - 3. Schedule Maintenance

struct ScheduleEquipmentMaintenanceJobView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EquipmentServiceActionViewModel
    @State var equipment: Equipment

    var onSaved: (() -> Void)? = nil

    init(
        dataService: any ProductionDataServiceProtocol,
        equipment: Equipment,
        onSaved: (() -> Void)? = nil
    ) {
        _VM = StateObject(wrappedValue: EquipmentServiceActionViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
        self.onSaved = onSaved
    }

    var body: some View {
        EquipmentScheduleJobShell(
            title: "Schedule Maintenance Job",
            subtitle: equipment.name,
            systemImage: "calendar.badge.plus",
            VM: VM,
            equipment: equipment,
            submitTitle: "Create Maintenance Job"
        ) {
            save()
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(
                        companyId: company.id,
                        defaultName: "Maintenance Job",
                        defaultDescription: "Maintenance needed for \(equipment.name)."
                    )
                } catch {
                    print(error)
                }
            }
        }
        .sheet(isPresented: $VM.showAdminPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedAdmin)
        }
        .sheet(isPresented: $VM.showTechPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedTech)
        }
    }

    func save() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                VM.isSaving = true

                try await VM.createJobAndOptionalServiceStop(
                    companyId: company.id,
                    equipment: equipment,
                    jobType: .maintenance
                )

                VM.isSaving = false
                onSaved?()
                dismiss()
            } catch {
                VM.isSaving = false
                VM.alertMessage = error.localizedDescription
                VM.showAlert = true
            }
        }
    }
}

// MARK: - 4. Schedule Repair

struct ScheduleEquipmentRepairJobView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: EquipmentServiceActionViewModel
    @State var equipment: Equipment

    var onSaved: (() -> Void)? = nil

    init(
        dataService: any ProductionDataServiceProtocol,
        equipment: Equipment,
        onSaved: (() -> Void)? = nil
    ) {
        _VM = StateObject(wrappedValue: EquipmentServiceActionViewModel(dataService: dataService))
        _equipment = State(wrappedValue: equipment)
        self.onSaved = onSaved
    }

    var body: some View {
        EquipmentScheduleJobShell(
            title: "Schedule Repair Job",
            subtitle: equipment.name,
            systemImage: "calendar.badge.clock",
            VM: VM,
            equipment: equipment,
            submitTitle: "Create Repair Job"
        ) {
            save()
        }
        .task {
            if let company = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(
                        companyId: company.id,
                        defaultName: "Repair Job",
                        defaultDescription: "Repair needed for \(equipment.name)."
                    )
                } catch {
                    print(error)
                }
            }
        }
        .sheet(isPresented: $VM.showAdminPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedAdmin)
        }
        .sheet(isPresented: $VM.showTechPicker) {
            CompanyUserPicker(dataService: dataService, companyUser: $VM.selectedTech)
        }
    }

    func save() {
        Task {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                VM.isSaving = true

                try await VM.createJobAndOptionalServiceStop(
                    companyId: company.id,
                    equipment: equipment,
                    jobType: .repair
                )

                VM.isSaving = false
                onSaved?()
                dismiss()
            } catch {
                VM.isSaving = false
                VM.alertMessage = error.localizedDescription
                VM.showAlert = true
            }
        }
    }
}

// MARK: - Shared Record UI

struct EquipmentServiceRecordShell: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedInput: Bool

    let title: String
    let subtitle: String
    let systemImage: String

    @ObservedObject var VM: EquipmentServiceActionViewModel
    let equipment: Equipment

    let showParts: Bool
    let submitTitle: String
    let onSubmit: () -> Void

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    detailsCard

                    if showParts {
                        partsCard
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            if VM.isSaving {
                loadingOverlay
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDismissButton {
                    focusedInput = false
                }
            }
        }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(title, systemImage: systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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

            HStack(spacing: 8) {
                Label(equipment.customerName, systemImage: "person.crop.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Label(equipment.typeDisplayName, systemImage: "gearshape")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Details", systemImage: "doc.text")

            textInputRow(
                title: "Name",
                systemImage: "tag",
                text: $VM.name
            )

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                DatePicker("Date", selection: $VM.serviceDate, displayedComponents: .date)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Picker("Performed By", selection: $VM.performedBy) {
                Text("Company").tag(ServicePerformaceType.company)
                Text("Customer").tag(ServicePerformaceType.customer)
            }
            .pickerStyle(.segmented)

            if VM.performedBy == .company {
                pickerButtonRow(
                    title: "Technician",
                    value: VM.selectedTech.id.isEmpty ? "Select Technician" : VM.selectedTech.userName,
                    systemImage: "person.crop.circle",
                    isSelected: !VM.selectedTech.id.isEmpty
                ) {
                    VM.showTechPicker.toggle()
                }
            } else {
                textInputRow(
                    title: "Customer Name",
                    systemImage: "person",
                    text: $VM.customerPerformerName
                )
            }

            descriptionInputCard
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var partsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Parts Replaced", systemImage: "gearshape.2")

            HStack(spacing: 10) {
                TextField("Part name", text: $VM.currentPartName)
                    .font(.subheadline)
                    .focused($focusedInput)
                    .submitLabel(.done)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    VM.addPartName()
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 42, height: 42)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            if VM.partNames.isEmpty {
                Text("No parts added.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.partNames, id: \.self) { part in
                        HStack {
                            Text(part)
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            Button {
                                VM.removePartName(part)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 28)
                                    .background(.thinMaterial, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var descriptionInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Description", systemImage: "text.alignleft")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Description", text: $VM.description, axis: .vertical)
                .font(.subheadline)
                .focused($focusedInput)
                .submitLabel(.done)
                .lineLimit(4, reservesSpace: true)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.35)

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
                    onSubmit()
                } label: {
                    Label(submitTitle, systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.isSaving)
                .opacity(VM.isSaving ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func textInputRow(title: String, systemImage: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(title, text: text)
                .font(.subheadline)
                .focused($focusedInput)
                .submitLabel(.done)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    func pickerButtonRow(
        title: String,
        value: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
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
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text("Saving...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Shared Schedule UI

struct EquipmentScheduleJobShell: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedInput: Bool

    let title: String
    let subtitle: String
    let systemImage: String

    @ObservedObject var VM: EquipmentServiceActionViewModel
    let equipment: Equipment

    let submitTitle: String
    let onSubmit: () -> Void

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    jobCard

                    if VM.shouldScheduleServiceStop {
                        scheduleCard
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }

            if VM.isSaving {
                loadingOverlay
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDismissButton {
                    focusedInput = false
                }
            }
        }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Label(title, systemImage: systemImage)
                        .font(.title3.weight(.semibold))

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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

            HStack(spacing: 8) {
                Label(equipment.customerName, systemImage: "person.crop.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Label(VM.shouldScheduleServiceStop ? "Job + Stop" : "Job Only", systemImage: "briefcase")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var jobCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Job", systemImage: "briefcase")

            pickerButtonRow(
                title: "Admin In Charge",
                value: VM.selectedAdmin.id.isEmpty ? "Select Admin" : VM.selectedAdmin.userName,
                systemImage: "person.crop.circle",
                isSelected: !VM.selectedAdmin.id.isEmpty
            ) {
                VM.showAdminPicker.toggle()
            }

            Toggle("Schedule a service stop now", isOn: $VM.shouldScheduleServiceStop)
                .font(.subheadline.weight(.semibold))
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Description", text: $VM.jobDescription, axis: .vertical)
                    .font(.subheadline)
                    .focused($focusedInput)
                    .submitLabel(.done)
                    .lineLimit(4, reservesSpace: true)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Schedule", systemImage: "calendar.badge.plus")

            pickerButtonRow(
                title: "Technician",
                value: VM.selectedTech.id.isEmpty ? "Select Technician" : VM.selectedTech.userName,
                systemImage: "person.crop.circle",
                isSelected: !VM.selectedTech.id.isEmpty
            ) {
                VM.showTechPicker.toggle()
            }

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                DatePicker("Service Date", selection: $VM.jobDate, displayedComponents: .date)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.35)

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
                    onSubmit()
                } label: {
                    Label(submitTitle, systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.isSaving)
                .opacity(VM.isSaving ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
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
            HStack(spacing: 12) {
                Image(systemName: systemImage)
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
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text("Saving...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
