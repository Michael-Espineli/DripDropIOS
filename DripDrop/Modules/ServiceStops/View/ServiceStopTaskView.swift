//
//  ServiceStopTaskView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/18/24.
//

import SwiftUI

@MainActor
final class ServiceStopTaskViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    @Published var showAddCurrentStopTask: Bool = false
    @Published var showAddNextRecurringStopTask: Bool = false
    @Published var showAddRepairRequest: Bool = false

    @Published var pendingCurrentStopTasks: [JobTaskGroupItem] = []
    @Published var pendingNextRecurringStopTasks: [JobTaskGroupItem] = []

    @Published var isSavingNewTask: Bool = false
    @Published var showAttachJobTasks: Bool = false
    @Published var attachableJobTasks: [JobTask] = []
    @Published var selectedAttachJobTaskIds: Set<String> = []

    func finishServiceStopTask(
        companyId: String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        status: JobTaskStatus
    ) async throws {
        try await dataService.updateServiceStopTaskStatus(
            companyId: companyId,
            serviceStopId: serviceStop.id,
            taskId: task.id,
            status: status
        )

        let historyCompanyId: String

        if serviceStop.otherCompany {
            if let mainCompanyId = serviceStop.mainCompanyId {
                historyCompanyId = mainCompanyId
                if serviceStop.jobId != "" {
                    try dataService.updateJobTaskStatus(
                        companyId: mainCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: task.jobTaskId,
                        status: .finished
                    )
                } else {
                    // Update Sender RSS
                }
            } else {
                historyCompanyId = companyId
            }
        } else {
            historyCompanyId = companyId
            if serviceStop.jobId != "" {
                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: serviceStop.jobId,
                    taskId: task.jobTaskId,
                    status: .finished
                )
            } else {
                // Update Sender RSS
            }
        }

        if status == .finished {
            try await EquipmentTaskHistoryService(dataService: dataService)
                .recordServiceStopTaskCompletion(
                    companyId: historyCompanyId,
                    serviceStop: serviceStop,
                    task: task
                )

            try await BodyOfWaterTaskHistoryService(dataService: dataService)
                .recordServiceStopTaskCompletion(
                    companyId: historyCompanyId,
                    serviceStop: serviceStop,
                    task: task
                )
        }
    }

    func unfinishServiceStopTask(
        companyId: String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        status: JobTaskStatus
    ) async throws {
        try await dataService.updateServiceStopTaskStatus(
            companyId: companyId,
            serviceStopId: serviceStop.id,
            taskId: task.id,
            status: status
        )

        if serviceStop.otherCompany {
            if let mainCompanyId = serviceStop.mainCompanyId {
                if serviceStop.jobId != "" {
                    try dataService.updateJobTaskStatus(
                        companyId: mainCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: task.jobTaskId,
                        status: .scheduled
                    )
                }
            }
        } else {
            if serviceStop.jobId != "" {
                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: serviceStop.jobId,
                    taskId: task.jobTaskId,
                    status: .scheduled
                )
            }
        }
    }

    private func jobTaskCompanyId(companyId: String, serviceStop: ServiceStop) -> String {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return companyId
    }

    func loadAttachableJobTasks(
        companyId: String,
        serviceStop: ServiceStop,
        currentTasks: [ServiceStopTask]
    ) async throws {
        guard !serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            attachableJobTasks = []
            selectedAttachJobTaskIds = []
            return
        }

        let jobCompanyId = jobTaskCompanyId(companyId: companyId, serviceStop: serviceStop)
        let jobTasks = try await dataService.getJobTasks(
            companyId: jobCompanyId,
            jobId: serviceStop.jobId
        )
        let currentJobTaskIds = Set(currentTasks.compactMap { task in
            task.jobTaskId.isEmpty ? nil : task.jobTaskId
        })

        attachableJobTasks = jobTasks.filter { task in
            guard !currentJobTaskIds.contains(task.id) else { return false }
            guard task.status != .finished else { return false }

            let assignedStopId = task.serviceStopId.id.trimmingCharacters(in: .whitespacesAndNewlines)
            return assignedStopId.isEmpty || assignedStopId == serviceStop.id
        }
        selectedAttachJobTaskIds = []
    }

    func attachSelectedJobTasksToCurrentStop(
        companyId: String,
        serviceStop: ServiceStop,
        taskList: Binding<[ServiceStopTask]>
    ) {
        guard !selectedAttachJobTaskIds.isEmpty else { return }

        Task {
            do {
                isSavingNewTask = true

                let jobCompanyId = jobTaskCompanyId(companyId: companyId, serviceStop: serviceStop)
                let job = try await dataService.getWorkOrderById(
                    companyId: jobCompanyId,
                    workOrderId: serviceStop.jobId
                )
                let selectedTasks = attachableJobTasks.filter { selectedAttachJobTaskIds.contains($0.id) }
                var newStopTasks: [ServiceStopTask] = []

                for jobTask in selectedTasks {
                    let stopTask = makeServiceStopTask(
                        from: jobTask,
                        serviceStop: serviceStop,
                        jobInternalId: job.internalId
                    )

                    try await dataService.uploadServiceStopTask(
                        companyId: companyId,
                        serviceStopId: serviceStop.id,
                        task: stopTask
                    )

                    try dataService.updateJobTaskWorkerId(
                        companyId: jobCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: jobTask.id,
                        workerId: serviceStop.techId
                    )
                    try dataService.updateJobTaskWorkerName(
                        companyId: jobCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: jobTask.id,
                        workerName: serviceStop.tech
                    )
                    try dataService.updateJobTaskWorkerType(
                        companyId: jobCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: jobTask.id,
                        workerType: .employee
                    )
                    try dataService.updateJobTaskServiceStopId(
                        companyId: jobCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: jobTask.id,
                        serviceStopId: IdInfo(id: serviceStop.id, internalId: serviceStop.internalId)
                    )
                    try dataService.updateJobTaskStatus(
                        companyId: jobCompanyId,
                        jobId: serviceStop.jobId,
                        taskId: jobTask.id,
                        status: .scheduled
                    )

                    newStopTasks.append(stopTask)
                }

                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    taskList.wrappedValue.append(contentsOf: newStopTasks)
                }

                attachableJobTasks.removeAll { selectedAttachJobTaskIds.contains($0.id) }
                selectedAttachJobTaskIds = []
                showAttachJobTasks = false
                isSavingNewTask = false

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            } catch {
                isSavingNewTask = false
                alertMessage = error.localizedDescription
                showAlert = true
                print(error)

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
            }
        }
    }
    func addPendingTasksToCurrentServiceStop(
        companyId: String,
        serviceStop: ServiceStop,
        taskList: Binding<[ServiceStopTask]>,
        workerId: String = "",
        workerType: WorkerTypeEnum = .employee,
        workerName: String = ""
    ) {
        guard !pendingCurrentStopTasks.isEmpty else { return }

        Task {
            do {
                isSavingNewTask = true

                var newlyCreatedTasks: [ServiceStopTask] = []

                for item in pendingCurrentStopTasks {
                    let serviceStopTask = makeServiceStopTask(
                        from: item,
                        companyId: companyId,
                        serviceStop: serviceStop,
                        workerId: workerId,
                        workerType: workerType,
                        workerName: workerName
                    )

                    try await dataService.uploadServiceStopTask(
                        companyId: companyId,
                        serviceStopId: serviceStop.id,
                        task: serviceStopTask
                    )

                    newlyCreatedTasks.append(serviceStopTask)
                }

                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    taskList.wrappedValue.append(contentsOf: newlyCreatedTasks)
                }

                pendingCurrentStopTasks = []
                isSavingNewTask = false

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            } catch {
                isSavingNewTask = false
                alertMessage = error.localizedDescription
                showAlert = true
                print(error)

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
            }
        }
    }
    func addPendingTasksToNextRecurringStop(
        companyId: String,
        serviceStop: ServiceStop
    ) {
        guard !pendingNextRecurringStopTasks.isEmpty else { return }
        guard !serviceStop.recurringServiceStopId.isEmpty else { return }

        Task {
            do {
                isSavingNewTask = true

                for item in pendingNextRecurringStopTasks {
                    let recurringTask = RecurringServiceStopTask(
                        name: item.name,
                        description: item.description,
                        type: item.type,
                        contractedRate: item.contractedRate,
                        estimatedTime: item.estimatedTime,
                        status: .unassigned,
                        isTaskGroup: false,
                        taskGroupId: "",
                        taskGroupTaskId: ""
                    )

                    try await dataService.uploadRecurringServiceStopTask(
                        companyId: companyId,
                        recurringServiceStopId: serviceStop.recurringServiceStopId,
                        task: recurringTask
                    )
                }

                pendingNextRecurringStopTasks = []
                isSavingNewTask = false

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            } catch {
                isSavingNewTask = false
                alertMessage = error.localizedDescription
                showAlert = true
                print(error)

                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
            }
        }
    }

    func makeServiceStopTask(
        from item: JobTaskGroupItem,
        companyId: String,
        serviceStop: ServiceStop,
        workerId: String = "",
        workerType: WorkerTypeEnum = .employee,
        workerName: String = ""
    ) -> ServiceStopTask {
        ServiceStopTask(
            id: "comp_ss_task_" + UUID().uuidString,
            name: item.name,
            type: item.type,
            status: .scheduled,
            contractedRate: item.contractedRate,
            estimatedTime: item.estimatedTime,
            customerApproval: false,
            actualTime: 0,
            workerId: workerId,
            workerType: workerType,
            workerName: workerName,
            laborContractId: serviceStop.laborContractId,
            serviceStopId: IdInfo(
                id: serviceStop.id,
                internalId: serviceStop.internalId,
            ),
            jobId: IdInfo(
                id: serviceStop.jobId,
                internalId: "",
            ),
            recurringServiceStopId: IdInfo(
                id: serviceStop.recurringServiceStopId,
                internalId: "",
            ),
            jobTaskId: "",
            recurringServiceStopTaskId: "",
            equipmentId: "",
            serviceLocationId: serviceStop.serviceLocationId,
            bodyOfWaterId: "",
            shoppingListItemId: ""
        )
    }

    func makeServiceStopTask(
        from jobTask: JobTask,
        serviceStop: ServiceStop,
        jobInternalId: String
    ) -> ServiceStopTask {
        ServiceStopTask(
            id: "comp_ss_task_" + UUID().uuidString,
            name: jobTask.name,
            type: jobTask.type,
            status: .scheduled,
            contractedRate: jobTask.contractedRate,
            estimatedTime: jobTask.estimatedTime,
            customerApproval: jobTask.customerApproval,
            actualTime: jobTask.actualTime,
            workerId: serviceStop.techId,
            workerType: .employee,
            workerName: serviceStop.tech,
            laborContractId: serviceStop.laborContractId,
            serviceStopId: IdInfo(
                id: serviceStop.id,
                internalId: serviceStop.internalId
            ),
            jobId: IdInfo(
                id: serviceStop.jobId,
                internalId: jobInternalId
            ),
            recurringServiceStopId: IdInfo(
                id: serviceStop.recurringServiceStopId,
                internalId: ""
            ),
            jobTaskId: jobTask.id,
            recurringServiceStopTaskId: "",
            equipmentId: jobTask.equipmentId,
            serviceLocationId: serviceStop.serviceLocationId,
            bodyOfWaterId: jobTask.bodyOfWaterId,
            shoppingListItemId: jobTask.dataBaseItemId
        )
    }
}

struct ServiceStopTaskView: View {
    init(
        dataService: any ProductionDataServiceProtocol,
        taskList: Binding<[ServiceStopTask]>,
        serviceStopId: String
    ) {
        _VM = StateObject(wrappedValue: ServiceStopTaskViewModel(dataService: dataService))
        self._taskList = taskList
        _serviceStopId = State(wrappedValue: serviceStopId)
    }

    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataService: MasterDataManager
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel

    @StateObject var VM: ServiceStopTaskViewModel

    @State var serviceStopId: String
    @Binding var taskList: [ServiceStopTask]

    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }

    private var finishedTaskCount: Int {
        taskList.filter { $0.status == .finished }.count
    }

    private var canWorkTasks: Bool {
        guard let serviceStop else { return false }
        return vm.activeRoute?.status == .inProgress && serviceStop.startTime != nil
    }

    private var disabledMessage: String? {
        guard let serviceStop else { return nil }

        if let activeRoute = vm.activeRoute {
            if activeRoute.status == .didNotStart ||
                activeRoute.status == .onBreak ||
                activeRoute.status == .traveling ||
                activeRoute.status == .finished {
                return "Start route to continue"
            }
        }

        if serviceStop.startTime == nil {
            return "Start service stop to continue"
        }

        return nil
    }

    private var hasRecurringServiceStop: Bool {
        guard let serviceStop else { return false }
        return !serviceStop.recurringServiceStopId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if let serviceStop {
                List {
                    headerListRow(serviceStop: serviceStop)

                    taskSection(serviceStop: serviceStop)

                    addWorkSection(serviceStop: serviceStop)

                    if disabledMessage != nil {
                        Color.clear
                            .frame(height: 72)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.listColor)
                .disabled(false)

                if let disabledMessage {
                    VStack {
                        Spacer()
                        actionNeededBar(message: disabledMessage, serviceStop: serviceStop)
                    }
                }
            } else {
                missingServiceStopState
            }
        }
        .sheet(isPresented: $VM.showAddCurrentStopTask, onDismiss: {
            if let currentCompany = masterDataService.currentCompany,
               let serviceStop {
                VM.addPendingTasksToCurrentServiceStop(
                    companyId: currentCompany.id,
                    serviceStop: serviceStop,
                    taskList: $taskList,
                    workerId: masterDataService.user?.id ?? "",
                    workerType: .employee,
                    workerName: "\(masterDataService.user?.firstName ?? "") \(masterDataService.user?.lastName ?? "")"
                )
            }
        }) {
            AddRecurringServiceStopTask(
                dataService: dataService,
                tasks: $VM.pendingCurrentStopTasks
            )
        }
        .sheet(isPresented: $VM.showAttachJobTasks) {
            if let currentCompany = masterDataService.currentCompany,
               let serviceStop {
                attachJobTasksSheet(
                    companyId: currentCompany.id,
                    serviceStop: serviceStop
                )
            }
        }
        .sheet(isPresented: $VM.showAddNextRecurringStopTask, onDismiss: {
            if let currentCompany = masterDataService.currentCompany,
               let serviceStop {
                VM.addPendingTasksToNextRecurringStop(
                    companyId: currentCompany.id,
                    serviceStop: serviceStop
                )
            }
        }) {
            AddRecurringServiceStopTask(
                dataService: dataService,
                tasks: $VM.pendingNextRecurringStopTasks
            )
        }
        .sheet(isPresented: $VM.showAddRepairRequest) {
            AddNewRepairRequest(
                dataService: dataService,
                isPresented: $VM.showAddRepairRequest,
                customer: nil
            )
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }}

// MARK: - Main UI
    // MARK: - Main UI

    extension ServiceStopTaskView {

        func headerListRow(serviceStop: ServiceStop) -> some View {
            headerCard(serviceStop: serviceStop)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }

        func headerCard(serviceStop: ServiceStop) -> some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task List")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(serviceStop.customerName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    taskProgressBadge
                }

                progressSection
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var taskProgressBadge: some View {
            Text("\(finishedTaskCount)/\(taskList.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.thinMaterial, in: Capsule())
        }

        var progressSection: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Progress", systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(progressPercentText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)
            }
        }

        var progressValue: Double {
            guard !taskList.isEmpty else { return 0 }
            return Double(finishedTaskCount) / Double(taskList.count)
        }

        var progressPercentText: String {
            guard !taskList.isEmpty else { return "0%" }
            return "\(Int((progressValue * 100).rounded()))%"
        }

        func taskSection(serviceStop: ServiceStop) -> some View {
            Section {
                if taskList.isEmpty {
                    emptyTaskState
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach($taskList) { $task in
                        ServiceStopTaskCardView(
                            dataService: dataService,
                            task: $task,
                            serviceStop: serviceStop
                        )
                        .disabled(!canWorkTasks)
                        .opacity(canWorkTasks ? 1 : 0.55)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                finishTask(serviceStop: serviceStop, task: $task)
                            } label: {
                                Label("Finish", systemImage: "checkmark.circle.fill")
                            }
                            .tint(.poolGreen)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                unfinishTask(serviceStop: serviceStop, task: $task)
                            } label: {
                                Label("Unfinish", systemImage: "xmark")
                            }
                            .tint(.poolRed)
                        }
                    }
                }
            } header: {
                HStack {
                    sectionHeader("Tasks", systemImage: "checklist")

                    Spacer()

                    Text("\(taskList.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .textCase(nil)
            }
        }

        func addWorkSection(serviceStop: ServiceStop) -> some View {
            Section {
                if !serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        Task {
                            if let currentCompany = masterDataService.currentCompany {
                                do {
                                    try await VM.loadAttachableJobTasks(
                                        companyId: currentCompany.id,
                                        serviceStop: serviceStop,
                                        currentTasks: taskList
                                    )
                                    VM.showAttachJobTasks = true
                                } catch {
                                    VM.alertMessage = error.localizedDescription
                                    VM.showAlert = true
                                    print(error)
                                }
                            }
                        }
                    } label: {
                        addWorkButtonLabel(
                            title: "Attach Job Tasks",
                            subtitle: "Pull unscheduled tasks from the linked job into this stop.",
                            systemImage: "link.badge.plus"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Button {
                    VM.showAddCurrentStopTask.toggle()
                } label: {
                    addWorkButtonLabel(
                        title: "Add Task To Current Stop",
                        subtitle: "Adds a one-off task to this service stop.",
                        systemImage: "checkmark.circle"
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if hasRecurringServiceStop {
                    Button {
                        VM.showAddNextRecurringStopTask.toggle()
                    } label: {
                        addWorkButtonLabel(
                            title: "Add Task To Next Recurring Stop",
                            subtitle: "Adds this task to the recurring template.",
                            systemImage: "repeat"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                Button {
                    VM.showAddRepairRequest.toggle()
                } label: {
                    addWorkButtonLabel(
                        title: "Add Repair Request",
                        subtitle: "Use this when something needs repair.",
                        systemImage: "wrench.and.screwdriver"
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if VM.isSavingNewTask {
                    HStack(spacing: 8) {
                        ProgressView()

                        Text("Saving task...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } header: {
                sectionHeader("Add Work", systemImage: "plus.circle")
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    .textCase(nil)
            }
        }

        func attachJobTasksSheet(
            companyId: String,
            serviceStop: ServiceStop
        ) -> some View {
            NavigationStack {
                Group {
                    if VM.attachableJobTasks.isEmpty {
                        ContentUnavailableView(
                            "No Job Tasks",
                            systemImage: "checklist.unchecked",
                            description: Text("Every available job task is already on this stop, finished, or assigned to another stop.")
                        )
                    } else {
                        List {
                            ForEach(VM.attachableJobTasks) { task in
                                Button {
                                    if VM.selectedAttachJobTaskIds.contains(task.id) {
                                        VM.selectedAttachJobTaskIds.remove(task.id)
                                    } else {
                                        VM.selectedAttachJobTaskIds.insert(task.id)
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: VM.selectedAttachJobTaskIds.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(VM.selectedAttachJobTaskIds.contains(task.id) ? Color.poolGreen : .secondary)
                                            .frame(width: 28, height: 28)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(task.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)

                                            Text("\(task.type.rawValue) • \(task.status.rawValue)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Text("\(task.estimatedTime) min")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .navigationTitle("Attach Job Tasks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            VM.showAttachJobTasks = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Attach") {
                            VM.attachSelectedJobTasksToCurrentStop(
                                companyId: companyId,
                                serviceStop: serviceStop,
                                taskList: $taskList
                            )
                        }
                        .disabled(VM.selectedAttachJobTaskIds.isEmpty || VM.isSavingNewTask)
                    }
                }
            }
        }

        func addWorkButtonLabel(
            title: String,
            subtitle: String,
            systemImage: String
        ) -> some View {
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        var emptyTaskState: some View {
            VStack(spacing: 8) {
                Image(systemName: "checklist.unchecked")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("No tasks added yet.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Tasks for this service stop will show up here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }

        var missingServiceStopState: some View {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Service stop not found.")
                    .font(.headline)

                Text("The task list could not be loaded for this service stop.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
    }
// MARK: - Action Bar

extension ServiceStopTaskView {

    func actionNeededBar(message: String, serviceStop: ServiceStop) -> some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            Button {
                handleBlockedAction(serviceStop: serviceStop)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .font(.caption.weight(.bold))

                    Text(message)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }

    func handleBlockedAction(serviceStop: ServiceStop) {
        if let activeRoute = vm.activeRoute {
            if activeRoute.status == .didNotStart ||
                activeRoute.status == .onBreak ||
                activeRoute.status == .traveling ||
                activeRoute.status == .finished {
                vm.startActiveRoute(
                    companyId: masterDataService.currentCompany?.id,
                    companyName: masterDataService.currentCompany?.name,
                    user: masterDataService.user
                )
                return
            }
        }

        if serviceStop.startTime == nil {
            vm.startServiceStop(
                companyId: masterDataService.currentCompany?.id,
                serviceStopId: serviceStop.id
            )
        }
    }
}

// MARK: - Actions

extension ServiceStopTaskView {

    func finishTask(serviceStop: ServiceStop, task: Binding<ServiceStopTask>) {
        Task {
            if let currentCompany = masterDataService.currentCompany {
                do {
                    try await VM.finishServiceStopTask(
                        companyId: currentCompany.id,
                        serviceStop: serviceStop,
                        task: task.wrappedValue,
                        status: .finished
                    )

                    task.wrappedValue.status = .finished

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                } catch {
                    VM.alertMessage = error.localizedDescription
                    VM.showAlert = true
                    print("Error")
                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }

    func unfinishTask(serviceStop: ServiceStop, task: Binding<ServiceStopTask>) {
        Task {
            if let currentCompany = masterDataService.currentCompany {
                do {
                    try await VM.unfinishServiceStopTask(
                        companyId: currentCompany.id,
                        serviceStop: serviceStop,
                        task: task.wrappedValue,
                        status: .scheduled
                    )

                    task.wrappedValue.status = .scheduled

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif
                } catch {
                    VM.alertMessage = error.localizedDescription
                    VM.showAlert = true
                    print("Error")
                    print(error)

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }
}

// MARK: - Helpers

extension ServiceStopTaskView {

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
}
