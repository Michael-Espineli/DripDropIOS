//
//  ScheduleServiceStopView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//

import MapKit
import SwiftUI

@MainActor
final class ScheduleServiceStopViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    // Route Snapshot - filler variables for now
    @Published private(set) var totalStops: Int = 7
    @Published private(set) var finishedStops: Int = 4
    @Published private(set) var routeStatus: String = "In Progress"
    @Published private(set) var estimatedTimeMin: Int = 420
    @Published private(set) var estimatedTimeMiles: Int = 69

    @Published private(set) var routeSnapshotClockedInEstimate: String = "5 Hours"
    @Published private(set) var routeSnapshotStartTime: String = "8:00 AM"
    @Published private(set) var routeSnapshotProjectedFinish: String = "3:45 PM"
    @Published private(set) var routeSnapshotNextStop: String = "Next stop placeholder"
    @Published private(set) var routeSnapshotOpenTasks: Int = 12

    @Published var description: String = ""
    @Published var estimatedTime: Int = 0

    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false

    @Published var showCompanyUserSelector: Bool = false
    @Published var showAddTask: Bool = false

    @Published var isLoading: Bool = false
    @Published var showRouteSnapShot: Bool = false
    @Published var serviceDate: Date = Date()

    @Published var selectedUser: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )

    @Published private(set) var companyUserList: [CompanyUser] = []
    @Published private(set) var jobTaskList: [JobTask] = []
    @Published var selectedJobTaskList: [JobTask] = []
    @Published private(set) var plannedServiceStops: [JobPlannedServiceStop] = []
    @Published var selectedPlannedServiceStop: JobPlannedServiceStop?
    @Published private(set) var editingServiceStop: ServiceStop?
    @Published private(set) var editingServiceStopTasks: [ServiceStopTask] = []

    @Published private(set) var taskTypes: [String] = []

    func onLoad(
        companyId: String,
        serviceLocationId: String,
        description: String,
        jobTaskList: [JobTask],
        plannedServiceStops: [JobPlannedServiceStop] = [],
        editingServiceStop: ServiceStop? = nil
    ) async throws {
        self.description = description
        self.jobTaskList = jobTaskList
        self.plannedServiceStops = plannedServiceStops
        self.editingServiceStop = editingServiceStop

        self.taskTypes = [
            "Basic",
            "Clean",
            "Clean Filter",
            "Empty Water",
            "Fill Water",
            "Inspection",
            "Install",
            "Remove",
            "Replace",
            "Maintenance",
            "Repair"
        ]

        self.companyUserList = try await dataService.getAllCompanyUsersByStatus(
            companyId: companyId,
            status: "Active"
        )

        if !companyUserList.isEmpty {
            self.selectedUser = companyUserList.first!
        }

        if let editingServiceStop {
            self.description = editingServiceStop.description
            self.serviceDate = editingServiceStop.serviceDate

            if let editingUser = companyUserList.first(where: { $0.userId == editingServiceStop.techId }) {
                self.selectedUser = editingUser
            }

            let serviceStopTasks = try await dataService.getServiceStopTasks(
                companyId: companyId,
                serviceStopId: editingServiceStop.id
            )
            self.editingServiceStopTasks = serviceStopTasks
            let editingJobTaskIds = Set(serviceStopTasks.map { $0.jobTaskId })
            self.selectedJobTaskList = jobTaskList.filter { editingJobTaskIds.contains($0.id) }
            estimateTime(tasks: selectedJobTaskList)
        }

        setPlaceholderRouteSnapshot()
    }

    func reloadJobTasks(companyId: String, jobId: String) async throws {
        let tasks = try await dataService.getJobTasks(
            companyId: companyId,
            jobId: jobId
        )

        self.jobTaskList = tasks

        self.selectedJobTaskList = selectedJobTaskList.filter { selectedTask in
            tasks.contains(where: { $0.id == selectedTask.id })
        }

        estimateTime(tasks: selectedJobTaskList)
    }

    func applyPlannedServiceStop(_ plannedStop: JobPlannedServiceStop?) {
        selectedPlannedServiceStop = plannedStop

        guard let plannedStop else {
            return
        }

        description = plannedStop.description

        let plannedTaskIds = Set(plannedStop.taskIds)
        selectedJobTaskList = jobTaskList.filter { task in
            plannedTaskIds.contains(task.id) && isTaskSelectable(task)
        }

        if selectedJobTaskList.isEmpty {
            estimatedTime = plannedStop.estimatedMinutes
        } else {
            estimateTime(tasks: selectedJobTaskList)
        }
    }

    func isTaskSelectable(_ task: JobTask) -> Bool {
        if editingServiceStopTasks.contains(where: { $0.jobTaskId == task.id }) {
            return true
        }

        switch task.status {
        case .unassigned, .rejected, .draft:
            return true
        case .accepted, .offered, .scheduled, .finished, .inProgress:
            return false
        }
    }

    func onChangeOfDayOrTech(companyId: String) async throws {
        if selectedUser.id != "" {
            setPlaceholderRouteSnapshot()
        }
    }

    func setPlaceholderRouteSnapshot() {
        // Hook these values to real route data later.
        self.finishedStops = 4
        self.totalStops = 7
        self.routeStatus = "In Progress"
        self.estimatedTimeMin = 420
        self.estimatedTimeMiles = 69
        self.routeSnapshotClockedInEstimate = "5 Hours"
        self.routeSnapshotStartTime = "8:00 AM"
        self.routeSnapshotProjectedFinish = "3:45 PM"
        self.routeSnapshotNextStop = "Next stop placeholder"
        self.routeSnapshotOpenTasks = 12
    }

    func scheduleNewServiceStop(
        companyId: String,
        jobId: String,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        estimatedDurationOverride: Int? = nil,
        serviceStopTypeFields: ServiceStopTypeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: .jobVisit
        )
    ) async throws {
        print("")
        print("---------- Create Job ------")

        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }

            self.isLoading = true

            var durationMin = 0

            for task in selectedJobTaskList {
                durationMin = durationMin + task.estimatedTime
            }
            durationMin = estimatedDurationOverride ?? durationMin

            let jobInternalId = try await dataService
                .getWorkOrderById(companyId: companyId, workOrderId: jobId)
                .internalId

            let serviceStopCount: Int = try await dataService.getServiceOrderCount(companyId: companyId)

            let serviceLocation = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: serviceLocationId
            )

            print("serviceLocation: \(serviceLocation)")

            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS" + String(serviceStopCount)
            let selectedWorkerType: WorkerTypeEnum = selectedUser.workerType == .notAssigned
            ? .employee
            : selectedUser.workerType

            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")

            let serviceStop = ServiceStop(
                id: serviceStopId,
                internalId: "SS" + String(serviceStopCount),
                companyId: companyId,
                companyName: "",
                customerId: customerId,
                customerName: customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationMin,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: serviceStopTypeFields.typeId,
                type: serviceStopTypeFields.type,
                typeImage: serviceStopTypeFields.typeImage,
                jobId: jobId,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )

            print(serviceStop)

            try await dataService.uploadServiceStop(
                companyId: companyId,
                serviceStop: serviceStop
            )

            print("----  Service Stop uploaded  -----")

            for task in selectedJobTaskList {
                let serviceStopTask = makeServiceStopTask(
                    from: task,
                    taskId: nil,
                    serviceStopId: serviceStopId,
                    serviceStopInternalId: internalId,
                    jobId: jobId,
                    jobInternalId: jobInternalId,
                    selectedWorkerType: selectedWorkerType,
                    serviceLocationId: serviceLocationId
                )

                try await dataService.uploadServiceStopTask(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    task: serviceStopTask
                )

                try dataService.updateJobTaskWorkerId(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerId: selectedUser.userId
                )

                try dataService.updateJobTaskWorkerName(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerName: selectedUser.userName
                )

                try dataService.updateJobTaskWorkerType(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerType: selectedWorkerType
                )

                try dataService.updateJobTaskServiceStopId(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    serviceStopId: IdInfo(
                        id: serviceStopId,
                        internalId: internalId
                    )
                )

                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    status: .scheduled
                )
            }

            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }

    func updateScheduledServiceStop(
        companyId: String,
        jobId: String,
        serviceStop: ServiceStop,
        serviceLocationId: String,
        estimatedDurationOverride: Int? = nil,
        serviceStopTypeFields: ServiceStopTypeFields
    ) async throws {
        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }

            self.isLoading = true
            defer { self.isLoading = false }

            var durationMin = selectedJobTaskList.reduce(0) { $0 + $1.estimatedTime }
            durationMin = estimatedDurationOverride ?? durationMin

            let selectedWorkerType: WorkerTypeEnum = selectedUser.workerType == .notAssigned
                ? .employee
                : selectedUser.workerType

            try await dataService.updateScheduledJobServiceStop(
                companyId: companyId,
                serviceStop: serviceStop,
                serviceDate: serviceDate,
                companyUser: selectedUser,
                description: description,
                estimatedDuration: durationMin,
                serviceStopTypeFields: serviceStopTypeFields
            )

            let jobInternalId = try await dataService
                .getWorkOrderById(companyId: companyId, workOrderId: jobId)
                .internalId

            let existingTasks = try await dataService.getServiceStopTasks(
                companyId: companyId,
                serviceStopId: serviceStop.id
            )
            let selectedTaskIds = Set(selectedJobTaskList.map { $0.id })

            for existingTask in existingTasks where !selectedTaskIds.contains(existingTask.jobTaskId) {
                try await dataService.deleteServiceStopTask(
                    companyId: companyId,
                    serviceStopId: serviceStop.id,
                    taskId: existingTask.id
                )

                if !existingTask.jobTaskId.isEmpty {
                    try dataService.updateJobTaskServiceStopId(
                        companyId: companyId,
                        jobId: jobId,
                        taskId: existingTask.jobTaskId,
                        serviceStopId: IdInfo(id: "", internalId: "")
                    )
                    try dataService.updateJobTaskWorkerId(
                        companyId: companyId,
                        jobId: jobId,
                        taskId: existingTask.jobTaskId,
                        workerId: ""
                    )
                    try dataService.updateJobTaskWorkerName(
                        companyId: companyId,
                        jobId: jobId,
                        taskId: existingTask.jobTaskId,
                        workerName: ""
                    )
                    try dataService.updateJobTaskWorkerType(
                        companyId: companyId,
                        jobId: jobId,
                        taskId: existingTask.jobTaskId,
                        workerType: .notAssigned
                    )
                    try dataService.updateJobTaskStatus(
                        companyId: companyId,
                        jobId: jobId,
                        taskId: existingTask.jobTaskId,
                        status: .draft
                    )
                }
            }

            for task in selectedJobTaskList {
                let existingServiceStopTaskId = existingTasks.first(where: { $0.jobTaskId == task.id })?.id
                let serviceStopTask = makeServiceStopTask(
                    from: task,
                    taskId: existingServiceStopTaskId,
                    serviceStopId: serviceStop.id,
                    serviceStopInternalId: serviceStop.internalId,
                    jobId: jobId,
                    jobInternalId: jobInternalId,
                    selectedWorkerType: selectedWorkerType,
                    serviceLocationId: serviceLocationId
                )

                try await dataService.uploadServiceStopTask(
                    companyId: companyId,
                    serviceStopId: serviceStop.id,
                    task: serviceStopTask
                )

                try dataService.updateJobTaskWorkerId(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerId: selectedUser.userId
                )
                try dataService.updateJobTaskWorkerName(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerName: selectedUser.userName
                )
                try dataService.updateJobTaskWorkerType(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    workerType: selectedWorkerType
                )
                try dataService.updateJobTaskServiceStopId(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    serviceStopId: IdInfo(id: serviceStop.id, internalId: serviceStop.internalId)
                )
                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: jobId,
                    taskId: task.id,
                    status: .scheduled
                )
            }

            self.alertMessage = "Successfully Updated"
            self.showAlert = true
        }
    }

    private func makeServiceStopTask(
        from task: JobTask,
        taskId: String?,
        serviceStopId: String,
        serviceStopInternalId: String,
        jobId: String,
        jobInternalId: String,
        selectedWorkerType: WorkerTypeEnum,
        serviceLocationId: String
    ) -> ServiceStopTask {
        ServiceStopTask(
            id: taskId ?? "comp_ss_task_" + UUID().uuidString,
            name: task.name,
            type: task.type,
            status: .scheduled,
            contractedRate: task.contractedRate,
            estimatedTime: task.estimatedTime,
            customerApproval: true,
            actualTime: 0,
            workerId: selectedUser.userId,
            workerType: selectedWorkerType,
            workerName: selectedUser.userName,
            laborContractId: "",
            serviceStopId: IdInfo(
                id: serviceStopId,
                internalId: serviceStopInternalId
            ),
            jobId: IdInfo(
                id: jobId,
                internalId: jobInternalId
            ),
            recurringServiceStopId: IdInfo(
                id: "",
                internalId: ""
            ),
            jobTaskId: task.id,
            recurringServiceStopTaskId: "",
            equipmentId: task.equipmentId,
            serviceLocationId: serviceLocationId,
            bodyOfWaterId: task.bodyOfWaterId,
            shoppingListItemId: task.dataBaseItemId
        )
    }

    func scheduleNewServiceStopNewJob(
        companyId: String,
        jobId: String,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        estimatedDurationOverride: Int? = nil,
        serviceStopTypeFields: ServiceStopTypeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: .jobVisit
        )
    ) async throws -> (ServiceStop, [ServiceStopTask]) {
        print("")
        print("---------- Create Job ------")

        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }

            self.isLoading = true

            var durationMin = 0

            for task in selectedJobTaskList {
                durationMin = durationMin + task.estimatedTime
            }
            durationMin = estimatedDurationOverride ?? durationMin

            let jobInternalId = try await dataService
                .getWorkOrderById(companyId: companyId, workOrderId: jobId)
                .internalId

            let serviceStopCount: Int = try await dataService.getServiceOrderCount(companyId: companyId)

            let serviceLocation = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: serviceLocationId
            )

            print("serviceLocation: \(serviceLocation)")

            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS" + String(serviceStopCount)
            let selectedWorkerType: WorkerTypeEnum = selectedUser.workerType == .notAssigned
            ? .employee
            : selectedUser.workerType

            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")

            var tasks: [ServiceStopTask] = []

            let serviceStop = ServiceStop(
                id: serviceStopId,
                internalId: "SS" + String(serviceStopCount),
                companyId: companyId,
                companyName: "",
                customerId: customerId,
                customerName: customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationMin,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: serviceStopTypeFields.typeId,
                type: serviceStopTypeFields.type,
                typeImage: serviceStopTypeFields.typeImage,
                jobId: jobId,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )

            print(serviceStop)
            print("----  Service Stop uploaded  -----")

            for task in selectedJobTaskList {
                let serviceStopTask = makeServiceStopTask(
                    from: task,
                    taskId: nil,
                    serviceStopId: serviceStopId,
                    serviceStopInternalId: internalId,
                    jobId: jobId,
                    jobInternalId: jobInternalId,
                    selectedWorkerType: selectedWorkerType,
                    serviceLocationId: serviceLocationId
                )

                tasks.append(serviceStopTask)
            }

            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false

            return (serviceStop, tasks)
        }

        throw FireBaseRead.unableToRead
    }

    func estimateTime(tasks: [JobTask]) {
        var durationMin = 0

        for task in selectedJobTaskList {
            durationMin = durationMin + task.estimatedTime
        }

        self.estimatedTime = durationMin
    }

    func scheduleNewServiceStopOtherCompany(
        companyId: String,
        job: Job,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        estimatedDurationOverride: Int? = nil,
        serviceStopTypeFields: ServiceStopTypeFields = ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: .jobVisit
        )
    ) async throws {
        print("")
        print("---------- Create SS Other Company ------")

        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }

            guard let senderId = job.senderId else {
                print("senderId error")
                throw FireBasePublish.unableToPublish
            }

            guard let receiverId = job.receiverId else {
                print("receiverId error")
                throw FireBasePublish.unableToPublish
            }

            guard let receivedLaborContractId = job.receivedLaborContractId else {
                print("receivedLaborContractId error")
                throw FireBasePublish.unableToPublish
            }

            self.isLoading = true

            var durationSeconds = 0

            for task in selectedJobTaskList {
                durationSeconds = durationSeconds + task.estimatedTime
            }
            durationSeconds = estimatedDurationOverride ?? durationSeconds

            let jobInternalId = try await dataService
                .getWorkOrderById(companyId: companyId, workOrderId: job.id)
                .internalId

            let serviceStopCount: Int = try await dataService.getServiceOrderCount(companyId: companyId)

            let serviceLocation = try await dataService.getServiceLocationById(
                companyId: senderId,
                locationId: serviceLocationId
            )

            let laborContract = try await dataService.getLaborContract(
                laborContractId: receivedLaborContractId
            )

            print("serviceLocation: \(serviceLocation)")

            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS" + String(serviceStopCount)
            let selectedWorkerType: WorkerTypeEnum = selectedUser.workerType == .notAssigned
                ? .employee
                : selectedUser.workerType
            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")

            let serviceStop = ServiceStop(
                id: serviceStopId,
                internalId: internalId,
                companyId: companyId,
                companyName: "",
                customerId: customerId,
                customerName: customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationSeconds,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: serviceStopTypeFields.typeId,
                type: serviceStopTypeFields.type,
                typeImage: serviceStopTypeFields.typeImage,
                jobId: job.id,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: true,
                laborContractId: receivedLaborContractId,
                contractedCompanyId: receiverId,
                mainCompanyId: senderId,
                isInvoiced: false
            )

            print(serviceStop)

            try await dataService.uploadServiceStop(
                companyId: companyId,
                serviceStop: serviceStop
            )

            print("----  Service Stop uploaded  -----")

            for task in selectedJobTaskList {
                let serviceStopTask = makeServiceStopTask(
                    from: task,
                    taskId: nil,
                    serviceStopId: serviceStopId,
                    serviceStopInternalId: internalId,
                    jobId: job.id,
                    jobInternalId: jobInternalId,
                    selectedWorkerType: selectedWorkerType,
                    serviceLocationId: serviceLocationId
                )

                try await dataService.uploadServiceStopTask(
                    companyId: companyId,
                    serviceStopId: serviceStopId,
                    task: serviceStopTask
                )

                try dataService.updateJobTaskWorkerId(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerId: selectedUser.userId
                )

                try dataService.updateJobTaskWorkerName(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerName: selectedUser.userName
                )

                try dataService.updateJobTaskWorkerType(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    workerType: selectedWorkerType
                )

                try dataService.updateJobTaskServiceStopId(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    serviceStopId: IdInfo(
                        id: serviceStopId,
                        internalId: internalId
                    )
                )

                try dataService.updateJobTaskStatus(
                    companyId: companyId,
                    jobId: job.id,
                    taskId: task.id,
                    status: .scheduled
                )
            }

            try await dataService.updateJobOperationStatus(
                companyId: companyId,
                jobId: job.id,
                operationStatus: .scheduled
            )

            try await dataService.updateJobOperationStatus(
                companyId: senderId,
                jobId: laborContract.senderJobId.id,
                operationStatus: .scheduled
            )

            let senderLaborTasks = try await dataService.getLaborContractWork(
                companyId: "Does not matter, Maybe remove",
                laborContractId: laborContract.senderJobId.id
            )

            for laborTask in senderLaborTasks {
                if selectedJobTaskList.contains(where: { $0.laborContractId == laborContract.id }) {
                    try dataService.updateJobTaskStatus(
                        companyId: senderId,
                        jobId: laborContract.senderJobId.id,
                        taskId: laborTask.senderJobTaskId,
                        status: .scheduled
                    )
                }
            }

            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }
}

struct ScheduleServiceStopView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject var VM: ScheduleServiceStopViewModel

    @State var job: Job
    @State var customerId: String
    @State var customerName: String

    @State var serviceLocationId: String
    @State var description: String
    @State var jobTaskList: [JobTask]
    @State var plannedServiceStops: [JobPlannedServiceStop]
    @State var editingServiceStop: ServiceStop?

    let companyId: String
    let serviceStopTypeUseCase: ServiceStopTypeUseCase

    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?

    init(
        dataService: any ProductionDataServiceProtocol,
        companyId: String = "",
        job: Job,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        description: String,
        jobTaskList: [JobTask],
        plannedServiceStops: [JobPlannedServiceStop] = [],
        editingServiceStop: ServiceStop? = nil,
        serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit
    ) {
        _VM = StateObject(wrappedValue: ScheduleServiceStopViewModel(dataService: dataService))
        _job = State(wrappedValue: job)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _description = State(wrappedValue: description)
        _jobTaskList = State(wrappedValue: jobTaskList)
        _plannedServiceStops = State(wrappedValue: plannedServiceStops)
        _editingServiceStop = State(wrappedValue: editingServiceStop)

        self.companyId = companyId
        self.serviceStopTypeUseCase = serviceStopTypeUseCase
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard
                    plannedSourceCard
                    detailsCard
                    serviceStopTypeCard
                    routeSnapshotCard
                    tasksCard
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .scrollDismissesKeyboard(.interactively)

            if VM.isLoading {
                loadingOverlay
            }
        }
        .safeAreaInset(edge: .bottom) {
            scheduleButtonBar
        }
        .sheet(isPresented: $VM.showCompanyUserSelector) {
            CompanyUserPicker(
                dataService: dataService,
                companyUser: $VM.selectedUser
            )
        }
        .sheet(isPresented: $VM.showAddTask, onDismiss: {
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.reloadJobTasks(
                            companyId: currentCompany.id,
                            jobId: job.id
                        )
                    } catch {
                        print(error)
                    }
                }
            }
        }) {
            AddNewTaskToJob(
                dataService: dataService,
                jobId: job.id,
                taskTypes: VM.taskTypes,
                customerId: customerId,
                serviceLocationId: serviceLocationId
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $VM.showRouteSnapShot) {
            routeSnapshotSheet
                .presentationDetents([.fraction(0.5), .medium, .large])
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.description = description

                    try await VM.onLoad(
                        companyId: currentCompany.id,
                        serviceLocationId: serviceLocationId,
                        description: description,
                        jobTaskList: jobTaskList,
                        plannedServiceStops: plannedServiceStops,
                        editingServiceStop: editingServiceStop
                    )
                } catch {
                    print(error)
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.serviceDate) { _ in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedUser) { _ in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: VM.selectedJobTaskList) { tasks in
            VM.estimateTime(tasks: tasks)
        }
        .onChange(of: VM.selectedPlannedServiceStop) { _ in
            selectedCompanyServiceStopType = nil
        }
    }
}

// MARK: - Main UI

extension ScheduleServiceStopView {
    private var isEditingScheduledStop: Bool {
        editingServiceStop != nil
    }

    private var resolvedServiceStopTypeFields: ServiceStopTypeFields {
        if let plannedStop = VM.selectedPlannedServiceStop {
            return ServiceStopTypeFields(
                typeId: plannedStop.serviceStopTypeId,
                type: plannedStop.serviceStopTypeName,
                typeImage: plannedStop.serviceStopTypeImage
            )
        }

        if let selectedCompanyServiceStopType {
            return ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase
            )
        }

        if let editingServiceStop {
            return ServiceStopTypeFields(
                typeId: editingServiceStop.typeId,
                type: editingServiceStop.type,
                typeImage: editingServiceStop.typeImage
            )
        }

        return ServiceStopTypeResolver.serviceStopTypeFields(
            selectedType: nil,
            useCase: serviceStopTypeUseCase
        )
    }

    var plannedSourceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Planned Stop Source", systemImage: "calendar.badge.clock")

                Spacer()

                if let selected = VM.selectedPlannedServiceStop {
                    Text(selected.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if plannedServiceStops.isEmpty {
                emptyState(
                    title: "No planned stops on this job.",
                    message: "You can still schedule a blank service stop.",
                    systemImage: "calendar"
                )
            } else {
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            VM.applyPlannedServiceStop(nil)
                        }
                    } label: {
                        plannedStopSourceRow(
                            title: "Blank service stop",
                            subtitle: "Start without a planned stop template.",
                            systemImage: "plus.circle",
                            isSelected: VM.selectedPlannedServiceStop == nil
                        )
                    }
                    .buttonStyle(.plain)

                    ForEach(plannedServiceStops.sorted(by: { $0.sortOrder < $1.sortOrder })) { plannedStop in
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                VM.applyPlannedServiceStop(plannedStop)
                            }
                        } label: {
                            plannedStopSourceRow(
                                title: plannedStop.name,
                                subtitle: "\(plannedStop.serviceStopTypeName) • \(plannedStop.estimatedMinutes) min • \(plannedStop.taskIds.count) task(s)",
                                systemImage: plannedStop.serviceStopTypeImage.isEmpty ? "calendar" : plannedStop.serviceStopTypeImage,
                                isSelected: VM.selectedPlannedServiceStop?.id == plannedStop.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var serviceStopTypeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Stop Type", systemImage: "mappin.and.ellipse")

            if resolvedCompanyId.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Missing company", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)

                    Text("Company ID is required to load service stop types. This stop will use the fallback job service stop type if scheduled.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                CompanyServiceStopTypePickerView(
                    companyId: resolvedCompanyId,
                    dataService: VM.dataService,
                    selectedType: $selectedCompanyServiceStopType,
                    useCase: serviceStopTypeUseCase,
                    title: "Service Stop Type",
                    subtitle: VM.selectedPlannedServiceStop == nil
                    ? "Payroll uses this type to decide which work type rates apply when this stop is finished."
                    : "Using the service stop type from the selected planned stop.",
                    preferredTypeId: VM.selectedPlannedServiceStop?.serviceStopTypeId
                )
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var resolvedCompanyId: String {
        let trimmedCompanyId = companyId.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedCompanyId.isEmpty {
            return trimmedCompanyId
        }

        return masterDataManager.currentCompany?.id ?? ""
    }
    
    
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(isEditingScheduledStop ? "Edit Service Stop" : "Schedule Service Stop")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
                VStack{
                    Label(fullDate(date: VM.serviceDate), systemImage: "calendar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                    
                        if VM.selectedUser.id != "" {
                            Label(VM.selectedUser.userName, systemImage: "person.crop.circle")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.thinMaterial, in: Capsule())
                        }
                }
                VStack{
                    Label("\(VM.selectedJobTaskList.count) Selected", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
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

    var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Details", systemImage: "calendar.badge.plus")

            pickerButtonRow(
                title: "Technician",
                value: VM.selectedUser.id == "" ? "Select Technician" : "\(VM.selectedUser.userName) \(VM.selectedUser.roleName)",
                systemImage: "person.crop.circle",
                isSelected: VM.selectedUser.id != ""
            ) {
                VM.showCompanyUserSelector.toggle()
            }

            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                DatePicker(
                    "Service Date",
                    selection: $VM.serviceDate,
                    in: (isEditingScheduledStop ? Date.distantPast : Date())...,
                    displayedComponents: .date
                )
                .font(.subheadline.weight(.semibold))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            descriptionInputCard

            detailDisplayRow(
                title: "Selected Task Time",
                value: displayMinAsMinAndHour(min: VM.estimatedTime),
                systemImage: "timer"
            )
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var routeSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Route Snapshot", systemImage: "map")

                Spacer()

                Button {
                    VM.showRouteSnapShot.toggle()
                } label: {
                    Label("View", systemImage: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
            }

//                VStack(spacing: 8) {
//                    routeMetricRow(
//                        title: "Stops",
//                        value: "\(VM.finishedStops)/\(VM.totalStops)",
//                        systemImage: "checklist"
//                    )
//
//                    routeMetricRow(
//                        title: "Status",
//                        value: VM.routeStatus,
//                        systemImage: "circle.dashed"
//                    )
//
//                    routeMetricRow(
//                        title: "Estimated Time",
//                        value: displayMinAsMinAndHour(min: VM.estimatedTimeMin),
//                        systemImage: "clock"
//                    )
//
//                    routeMetricRow(
//                        title: "Estimated Mileage",
//                        value: "\(VM.estimatedTimeMiles) mi",
//                        systemImage: "car"
//                    )
//                }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var tasksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Select Tasks", systemImage: "checklist")

                Spacer()

                Text("\(VM.selectedJobTaskList.count)/\(VM.jobTaskList.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if VM.jobTaskList.isEmpty {
                emptyState(
                    title: "No tasks available.",
                    message: "There are no unscheduled tasks to add to this service stop.",
                    systemImage: "checklist.unchecked"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.jobTaskList) { task in
                        taskSelectionRow(task)
                    }
                }
            }

            Button {
                VM.showAddTask.toggle()
            } label: {
                actionRow(
                    title: "Add New Task",
                    subtitle: "Create another task for this job, then select it for this service stop.",
                    systemImage: "plus.circle"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Bottom Bar

extension ScheduleServiceStopView {

    var scheduleButtonBar: some View {
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
                    scheduleServiceStop()
                } label: {
                    Label(isEditingScheduledStop ? "Update" : "Schedule", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(VM.isLoading)
                .opacity(VM.isLoading ? 0.55 : 1)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.regularMaterial)
        }
    }
    
    func scheduleServiceStop() {
        Task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    let resolvedFields = resolvedServiceStopTypeFields
                    let typeFields: ServiceStopTypeFields
                    if resolvedFields.isSystemFallback,
                       editingServiceStop == nil,
                       VM.selectedPlannedServiceStop == nil,
                       selectedCompanyServiceStopType == nil {
                        typeFields = await dataService.resolvedServiceStopTypeFields(
                            companyId: currentCompany.id,
                            useCase: serviceStopTypeUseCase,
                            context: "ScheduleServiceStopView.scheduleServiceStop"
                        )
                    } else {
                        typeFields = resolvedFields
                    }
                    let plannedEstimate = VM.selectedPlannedServiceStop?.estimatedMinutes

                    if let editingServiceStop {
                        try await VM.updateScheduledServiceStop(
                            companyId: currentCompany.id,
                            jobId: job.id,
                            serviceStop: editingServiceStop,
                            serviceLocationId: serviceLocationId,
                            estimatedDurationOverride: plannedEstimate,
                            serviceStopTypeFields: typeFields
                        )
                    } else if job.otherCompany {

                        try await VM.scheduleNewServiceStopOtherCompany(
                            companyId: currentCompany.id,
                            job: job,
                            customerId: customerId,
                            customerName: customerName,
                            serviceLocationId: serviceLocationId,
                            estimatedDurationOverride: plannedEstimate,
                            serviceStopTypeFields: typeFields
                        )
                    } else {
                        try await VM.scheduleNewServiceStop(
                            companyId: currentCompany.id,
                            jobId: job.id,
                            customerId: customerId,
                            customerName: customerName,
                            serviceLocationId: serviceLocationId,
                            estimatedDurationOverride: plannedEstimate,
                            serviceStopTypeFields: typeFields
                        )
                    }

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    #endif

                    dismiss()
                } catch {
                    print(error)

                    VM.alertMessage = "Could not schedule service stop. \(error.localizedDescription)"
                    VM.showAlert = true

                    #if os(iOS)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                }
            }
        }
    }
}

// MARK: - Rows

extension ScheduleServiceStopView {

    func taskSelectionRow(_ task: JobTask) -> some View {
        let isSelectable = VM.isTaskSelectable(task)

        if !isSelectable {
            return AnyView(
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("\(task.type) • \(task.status.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .opacity(0.55)
            )

        } else {
            let isSelected = VM.selectedJobTaskList.contains(where: { $0.id == task.id })

            return AnyView(
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        if isSelected {
                            VM.selectedJobTaskList.removeAll(where: { $0.id == task.id })
                        } else {
                            VM.selectedJobTaskList.append(task)
                        }
                    }

                    #if os(iOS)
                    UISelectionFeedbackGenerator().selectionChanged()
                    #endif
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Text("\(task.type) • \(task.status.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        isSelected ? Color.poolGreen.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            )
        }
    }

    func plannedStopSourceRow(
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(isSelected ? Color.poolGreen : .secondary)
                .frame(width: 30, height: 30)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(
            isSelected ? Color.poolGreen.opacity(0.12) : Color.primary.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    func routeMetricRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .buttonStyle(.plain)
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
}

// MARK: - Helpers

extension ScheduleServiceStopView {

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
                .lineLimit(4, reservesSpace: true)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var routeSnapshotSheet: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Route Snapshot")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Placeholder route data for selected technician and date.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            VM.showRouteSnapShot = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 34, height: 34)
                                .background(.thinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Today", systemImage: "calendar")

                        VStack(spacing: 8) {
                            routeMetricRow(
                                title: "Stops",
                                value: "\(VM.finishedStops)/\(VM.totalStops)",
                                systemImage: "checklist"
                            )

                            routeMetricRow(
                                title: "Status",
                                value: VM.routeStatus,
                                systemImage: "circle.dashed"
                            )

                            routeMetricRow(
                                title: "Open Tasks",
                                value: "\(VM.routeSnapshotOpenTasks)",
                                systemImage: "checklist.unchecked"
                            )

                            routeMetricRow(
                                title: "Next Stop",
                                value: VM.routeSnapshotNextStop,
                                systemImage: "mappin.and.ellipse"
                            )
                        }
                    }
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        sectionHeader("Time & Distance", systemImage: "clock")

                        VStack(spacing: 8) {
                            routeMetricRow(
                                title: "If Clocked In",
                                value: VM.routeSnapshotClockedInEstimate,
                                systemImage: "clock.badge.checkmark"
                            )

                            routeMetricRow(
                                title: "Start Time",
                                value: VM.routeSnapshotStartTime,
                                systemImage: "play.circle"
                            )

                            routeMetricRow(
                                title: "Projected Finish",
                                value: VM.routeSnapshotProjectedFinish,
                                systemImage: "flag.checkered"
                            )

                            routeMetricRow(
                                title: "Estimated Route Time",
                                value: displayMinAsMinAndHour(min: VM.estimatedTimeMin),
                                systemImage: "clock"
                            )

                            routeMetricRow(
                                title: "Estimated Mileage",
                                value: "\(VM.estimatedTimeMiles) mi",
                                systemImage: "car"
                            )
                        }
                    }
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .padding(14)
            }
        }
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
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
    
}
