//
//  JobWorkOffersView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct JobWorkOffersView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceLocation: ServiceLocation?
    let workOffers: [WorkOffer]
    let dataService: any ProductionDataServiceProtocol
    let onReload: () -> Void

    @State private var showCreateOffer = false
    @State private var canCreateOffer = false
    @State private var isCheckingCreatePermission = true
    @State private var createPermissionError: String?
    @State private var permissionCheckAttempt = 0
    @State private var showCreateUnavailable = false
    @State private var createUnavailableMessage = ""
    @State private var schedulingOffer: WorkOffer?
    @State private var showPreviousOffers = false

    private var currentOffers: [WorkOffer] {
        workOffers.filter { !$0.status.isFinal }.sorted { $0.createdAt > $1.createdAt }
    }
    private var previousOffers: [WorkOffer] {
        workOffers.filter { $0.status.isFinal }.sorted { $0.workOfferHistoryDate > $1.workOfferHistoryDate }
    }
    private var availableTaskCount: Int {
        let reserved = Set(workOffers.filter { ![WorkOfferStatus.rejected, .cancelled, .expired].contains($0.status) }.flatMap(\.jobTaskIds))
        return jobTasks.filter { !reserved.contains($0.id) }.count
    }

    private var createUnavailableReason: String? {
        var reasons: [String] = []
        if isCheckingCreatePermission {
            reasons.append("Your permission to create work offers is still being checked. Wait a moment, then try again.")
        } else if let createPermissionError {
            reasons.append("Could not check your permission to create work offers. \(createPermissionError)")
        } else if !canCreateOffer {
            reasons.append("Your company role does not allow you to create work offers. Ask a company owner or administrator to enable Create Offered Work for your role.")
        }
        if jobTasks.isEmpty {
            reasons.append("This job has no tasks to offer. Add a task to the job before creating a work offer.")
        } else if availableTaskCount == 0 {
            reasons.append("All tasks on this job are already included in work offers. Review the existing offers or add another job task. Tasks become available again when their offers are rejected, cancelled, or expired.")
        }
        return reasons.isEmpty ? nil : reasons.joined(separator: "\n\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Label("Work Offers", systemImage: "paperplane").font(.headline)
                Text("\(workOffers.count)").font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button {
                    if let reason = createUnavailableReason {
                        createUnavailableMessage = reason
                        showCreateUnavailable = true
                    } else {
                        showCreateOffer = true
                    }
                } label: {
                    Label("Create", systemImage: createUnavailableReason == nil ? "plus" : "info.circle").font(.caption.weight(.semibold))
                        .frame(minHeight: 32)
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
                .tint(.poolBlue)
                .opacity(createUnavailableReason == nil ? 1 : 0.6)
                .accessibilityLabel("Create work offer")
                .accessibilityHint(createUnavailableReason == nil ? "Create an offer for this job." : "Unavailable. Double-tap to learn why.")
            }
            if currentOffers.isEmpty {
                Text("No active offers.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(currentOffers) { offer in offerRow(offer) }
            if !previousOffers.isEmpty {
                DisclosureGroup("Previous offers (\(previousOffers.count))", isExpanded: $showPreviousOffers) {
                    VStack(spacing: 10) {
                        ForEach(previousOffers) { offer in offerRow(offer) }
                    }
                    .padding(.top, 8)
                }
                .font(.subheadline)
            }
        }
        .technicianPanel()
        .task(id: "\(companyId):\(currentUserId):\(permissionCheckAttempt)") {
            await checkCreatePermission()
        }
        .alert("Cannot Create Work Offer", isPresented: $showCreateUnavailable) {
            if createPermissionError != nil && !isCheckingCreatePermission {
                Button("Retry") { permissionCheckAttempt += 1 }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(createUnavailableMessage)
        }
        .sheet(isPresented: $showCreateOffer, onDismiss: onReload) {
            CreateJobWorkOfferView(
                companyId: companyId, currentUserId: currentUserId, currentUserName: currentUserName,
                job: job, jobTasks: jobTasks, serviceLocation: serviceLocation, workOffers: workOffers,
                dataService: dataService, onTasksChanged: {}
            )
            .presentationDetents([.large])
        }
        .sheet(item: $schedulingOffer, onDismiss: onReload) { offer in
            ScheduleAcceptedWorkOfferView(
                companyId: companyId, currentUserId: currentUserId, currentUserName: currentUserName,
                offer: offer, jobTasks: jobTasks, dataService: dataService,
                onScheduled: { schedulingOffer = nil }
            )
            .presentationDetents([.large])
        }
    }

    @MainActor
    private func checkCreatePermission() async {
        canCreateOffer = false
        isCheckingCreatePermission = true
        createPermissionError = nil
        do {
            let capabilities = try await FunctionsManager.shared.technicianWorkflow(
                "manageTechnicianWork", payload: ["companyId": companyId, "action": "capabilities"]
            )
            guard !Task.isCancelled else { return }
            if let canPost = capabilities["canPost"] as? Bool {
                canCreateOffer = canPost
            } else {
                createPermissionError = "The server did not return work-offer permissions. Please try again."
            }
        } catch {
            guard !Task.isCancelled else { return }
            createPermissionError = error.userFacingMessage
        }
        isCheckingCreatePermission = false
    }

    private func offerRow(_ offer: WorkOffer) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            NavigationLink { offerDestination(offer) } label: {
                JobWorkOfferCardView(offer: offer)
            }
            .buttonStyle(.plain)
            if canEdit(offer) || offer.isReadyToSchedule {
                HStack(spacing: 12) {
                    Spacer()
                    if canEdit(offer) {
                        NavigationLink { offerDestination(offer, startsEditing: true) } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption.weight(.semibold))
                                .frame(minHeight: 44)
                        }
                        .accessibilityLabel("Edit work offer \(offer.title)")
                    }
                    if offer.isReadyToSchedule {
                        Button { schedulingOffer = offer } label: {
                            Label("Schedule", systemImage: "calendar.badge.plus")
                                .font(.caption.weight(.semibold))
                                .frame(minHeight: 44)
                        }
                        .accessibilityLabel("Schedule work offer \(offer.title)")
                    }
                }
                .buttonStyle(.plain)
                .tint(.poolBlue)
                .padding(.horizontal, 8)
            }
        }
    }

    private func canEdit(_ offer: WorkOffer) -> Bool {
        let permissions = masterDataManager.role?.permissionIdList ?? []
        return masterDataManager.currentCompany?.ownerId == currentUserId || permissions.contains("324") ||
            (permissions.contains("322") && offer.createdByUserId == currentUserId)
    }

    private func offerDestination(_ offer: WorkOffer, startsEditing: Bool = false) -> some View {
        WorkOfferDetailView(
            companyId: companyId, currentUserId: currentUserId, currentUserName: currentUserName,
            offer: offer, jobTasks: jobTasks, dataService: dataService, onChanged: onReload,
            startsEditing: startsEditing
        )
    }
}

struct CreateCompanyWorkOfferView: View {
    @Environment(\.dismiss) private var dismiss
    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let dataService: any ProductionDataServiceProtocol
    let onCreated: () -> Void

    @State private var jobs: [Job] = []
    @State private var selectedJob: Job?
    @State private var serviceLocation: ServiceLocation?
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var isSelecting = false
    @State private var errorMessage = ""

    private var visibleJobs: [Job] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return jobs.filter {
            term.isEmpty || [$0.internalId, $0.customerName, $0.type, $0.description].contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    var body: some View {
        Group {
            if let selectedJob {
                CreateJobWorkOfferView(
                    companyId: companyId, currentUserId: currentUserId, currentUserName: currentUserName,
                    job: selectedJob, jobTasks: [], serviceLocation: serviceLocation, workOffers: [],
                    dataService: dataService, onTasksChanged: {}, onCreated: onCreated
                )
            } else {
                NavigationStack {
                    List {
                        Section {
                            Text("Choose the job whose tasks you want to offer to a technician or work board.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        if isLoading {
                            ProgressView("Loading jobs…")
                        } else if visibleJobs.isEmpty {
                            ContentUnavailableView("No matching jobs", systemImage: "briefcase", description: Text("Create a job or change your search to choose work for this offer."))
                        } else {
                            Section("Jobs") {
                                ForEach(visibleJobs) { job in
                                    Button { Task { await select(job) } } label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("\(job.internalId) · \(job.customerName)")
                                                .font(.headline).foregroundStyle(.primary)
                                            Text(job.type.isEmpty ? job.description : job.type)
                                                .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .disabled(isSelecting)
                                }
                            }
                        }
                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.subheadline).foregroundStyle(Color.poolRed)
                            Button("Retry loading jobs") { Task { await load() } }
                        }
                    }
                    .navigationTitle("Create Work Offer")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $searchText, prompt: "Job, customer, or work")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }.disabled(isSelecting)
                        }
                    }
                    .overlay { if isSelecting { ProgressView("Loading job…").padding().technicianPanel().padding(24) } }
                }
            }
        }
        .task(id: companyId) { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        do {
            jobs = try await dataService.getAllWorkOrders(companyId: companyId)
                .filter { $0.operationStatus != .finished }
                .sorted { $0.dateCreated > $1.dateCreated }
        } catch {
            errorMessage = "Could not load jobs. \(error.userFacingMessage)"
        }
    }

    private func select(_ job: Job) async {
        guard !isSelecting else { return }
        isSelecting = true
        errorMessage = ""
        defer { isSelecting = false }
        do {
            serviceLocation = job.serviceLocationId.isEmpty ? nil : try await dataService.getServiceLocationById(companyId: companyId, locationId: job.serviceLocationId)
            selectedJob = job
        } catch {
            errorMessage = "Could not load the job’s location. \(error.userFacingMessage)"
        }
    }
}

struct CreateJobWorkOfferView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceLocation: ServiceLocation?
    let workOffers: [WorkOffer]
    let dataService: any ProductionDataServiceProtocol
    let onTasksChanged: () -> Void
    var onCreated: (() -> Void)? = nil
    
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit
    
    @State private var showAddTask: Bool = false
    @State private var workingJobTasks: [JobTask] = []
    @State private var workingWorkOffers: [WorkOffer] = []
    
    @State private var showCompanyUserSelector: Bool = false
    @State private var offerType: WorkOfferType = .directUser
    @State private var selectedWorker: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )
    @State private var allowsTechnicianSelfScheduling: Bool = false
    @State private var companyUsers: [CompanyUser] = []
    @State private var selectedTaskIds: Set<String> = []

    @State private var boardVisibility: WorkOfferBoardVisibility = .contractorsOnly
    @State private var paySource: WorkOfferPaySource = .technicianRate
    @State private var offeredAmountCents: Int = 0
    @State private var serverPayLines: [WorkOfferPayEstimateLine] = []
    @State private var isQuotingPay = false
    @State private var payQuoteMessage = ""
    @State private var diagnosticMinutes = 60

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var proposedStartDate: Date = Date()
    @State private var includeDate: Bool = true
    @State private var includeDeadline = true
    @State private var completionDeadlineAt: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) ?? Date()
    @State private var timelineNotes: String = ""

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var selectedTasks: [JobTask] {
        workingJobTasks.filter {
            selectedTaskIds.contains($0.id) &&
            !offeredTaskIds.contains($0.id)
        }
    }

    private var estimatedMinutes: Int {
        serviceStopTypeUseCase == .jobEstimate ? diagnosticMinutes : selectedTasks.reduce(0) { $0 + $1.estimatedTime }
    }
    private var payQuoteKey: String {
        [selectedWorker.userId, paySource.rawValue, String(offeredAmountCents), availableSelectedTaskIds.sorted().joined(separator: ","), selectedCompanyServiceStopType?.id ?? "", serviceStopTypeUseCase.rawValue, String(estimatedMinutes)].joined(separator: "|")
    }
    @MainActor private func refreshPayQuote() async {
        isQuotingPay = true; defer { isQuotingPay = false }
        do {
            let result = try await FunctionsManager.shared.technicianWorkflow("manageTechnicianWork", payload: ["companyId":companyId,"action":"quote","technicianId":selectedWorker.userId,"offer":["jobId":job.id,"jobTaskIds":Array(availableSelectedTaskIds),"workPurpose":serviceStopTypeUseCase == .jobEstimate ? "diagnostic" : "execution","serviceStopTypeId":selectedCompanyServiceStopType?.id ?? serviceStopTypeUseCase.fallbackTypeId,"estimatedMinutes":estimatedMinutes,"paySource":paySource.rawValue,"offeredAmountCents":offeredAmountCents]])
            let data = try JSONSerialization.data(withJSONObject: result["lines"] as? [[String:Any]] ?? [])
            serverPayLines = try JSONDecoder().decode([WorkOfferPayEstimateLine].self, from: data)
            payQuoteMessage = result["personal"] as? Bool == false ? "The recipient reviews their personal rate before accepting." : ""
        } catch { serverPayLines = []; payQuoteMessage = error.userFacingMessage }
    }

    private var estimatedLaborCents: Int {
        selectedTasks.reduce(0) { $0 + $1.contractedRate }
    }

    private var defaultTitle: String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(job.internalId) - \(job.customerName)"
        }

        return title
    }

    private var canSave: Bool {
        guard serviceStopTypeUseCase == .jobEstimate || !availableSelectedTaskIds.isEmpty else { return false }
        guard unavailableSelectedTaskCount == 0 else { return false }
        guard WorkOfferTiming.isValid(availableFrom: includeDate ? proposedStartDate : nil, deadline: includeDeadline ? completionDeadlineAt : nil) else { return false }

        switch offerType {
        case .directUser:
            return !selectedWorker.userId.isEmpty
        case .internalBoard:
            return true
        case .externalCompany:
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                offerTypeSection
                notesSection
                workerSection
                scheduleSection
                taskScopeSection
                serviceStopTypeSection
                paySection
                saveSection
            }
            .task(id: payQuoteKey) { await refreshPayQuote() }
            .navigationTitle("Create Work Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await load()
            }
            .alert("Work Offer", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showCompanyUserSelector) {
                CompanyUserPicker(
                    dataService: dataService,
                    companyUser: $selectedWorker
                )
            }
            .sheet(isPresented: $showAddTask, onDismiss: {
                Task {
                    await reloadLocalOfferData()
                    onTasksChanged()
                }
            }) {
                AddNewTaskToJob(
                    dataService: dataService,
                    jobId: job.id,
                    taskTypes: [
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
                    ],
                    customerId: job.customerId,
                    serviceLocationId: job.serviceLocationId
                )
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var offerTypeSection: some View {
        Section {
            Picker("Offer Type", selection: $offerType) {
                Text("Direct User").tag(WorkOfferType.directUser)
                Text("Internal Board").tag(WorkOfferType.internalBoard)
            }
            .pickerStyle(.segmented)

            Text(offerTypeHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Offer Type")
        }
    }

    @ViewBuilder
    private var workerSection: some View {
        if offerType == .directUser {
            Section {
                if companyUsers.isEmpty {
                    ContentUnavailableView(
                        "No Contractors",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("No active contractors were found.")
                    )
                } else {
                    pickerButtonRow(
                        title: "Technician",
                        value: selectedWorker.id == "" ? "Select Technician" : "\(selectedWorker.userName) \(selectedWorker.roleName)",
                        systemImage: "person.crop.circle",
                        isSelected: selectedWorker.id != ""
                    ) {
                        showCompanyUserSelector.toggle()
                    }
                }
            } header: {
                Text("Send To")
            }
        }

        if offerType == .internalBoard {
            Section {
                Picker("Visibility", selection: $boardVisibility) {
                    ForEach(WorkOfferBoardVisibility.allCases) { visibility in
                        Text(visibility.title).tag(visibility)
                    }
                }
            } header: {
                Text("Board")
            } footer: {
                Text("The work will be posted so eligible company users can claim or request it later.")
            }
        }
    }
    private func workOfferTaskSelectionRow(_ task: JobTask) -> some View {
        let isSelected = selectedTaskIds.contains(task.id)

        return Button {
            toggleTask(task)
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

                    Text("\(task.type.rawValue) • \(task.estimatedTime) min • \(money(task.contractedRate)) planned labor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(12)
            .background(
                isSelected ? Color.poolGreen.opacity(0.12) : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func workOfferLockedTaskRow(_ task: JobTask) -> some View {
        let offer = activeOfferForTask(task)

        return HStack(spacing: 12) {
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

                if let offer {
                    Text("\(task.type.rawValue) • Already in \(offer.status.title) offer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\(task.type.rawValue) • Already offered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(0.6)
    }

    private func activeOfferForTask(_ task: JobTask) -> WorkOffer? {
        activeWorkOffers.first { offer in
            offer.jobTaskIds.contains(task.id)
        }
    }
    private func reloadLocalOfferData() async {
        do {
            async let tasksTask = dataService.getJobTasks(
                companyId: companyId,
                jobId: job.id
            )

            async let offersTask = dataService.fetchWorkOffers(
                companyId: companyId,
                jobId: job.id
            )

            let loadedTasks = try await tasksTask
            let loadedOffers = try await offersTask

            workingJobTasks = loadedTasks
            workingWorkOffers = loadedOffers

            selectedTaskIds = selectedTaskIds.filter { taskId in
                loadedTasks.contains(where: { $0.id == taskId }) &&
                !Set(loadedOffers.flatMap { $0.jobTaskIds }).contains(taskId)
            }

            if selectedTaskIds.isEmpty {
                let activeOffers = loadedOffers.filter { offer in
                    switch offer.status {
                    case .rejected, .cancelled, .expired:
                        return false
                    case .pendingApproval, .acceptancePendingApproval, .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress, .completed:
                        return true
                    }
                }

                let lockedTaskIds = Set(activeOffers.flatMap { $0.jobTaskIds })
                selectedTaskIds = Set(
                    loadedTasks
                        .filter { !lockedTaskIds.contains($0.id) }
                        .map { $0.id }
                )
            }
        } catch {
            alertMessage = "Could not reload tasks or offers. \(error.userFacingMessage)"
            showAlert = true
        }
    }
    private var taskScopeSection: some View {
        Section {
            if workingJobTasks.isEmpty {
                ContentUnavailableView(
                    "No Job Tasks",
                    systemImage: "checklist",
                    description: Text("Add planned work tasks before creating a work offer.")
                )

                Button {
                    showAddTask = true
                } label: {
                    Label("Add New Task", systemImage: "plus.circle")
                }
            } else {
                HStack {
                    Button {
                        if availableSelectedTaskIds.count == availableTasks.count {
                            selectedTaskIds.removeAll()
                        } else {
                            selectedTaskIds = Set(availableTasks.map { $0.id })
                        }
                    } label: {
                        Text(availableSelectedTaskIds.count == availableTasks.count ? "Deselect Available" : "Select Available")
                    }

                    Spacer()

                    Text("\(availableSelectedTaskIds.count)/\(availableTasks.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if !availableTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Available Tasks")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(availableTasks) { task in
                            workOfferTaskSelectionRow(task)
                        }
                    }
                }

                if !alreadyOfferedTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Already Offered")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(alreadyOfferedTasks) { task in
                            workOfferLockedTaskRow(task)
                        }
                    }
                }

                Button {
                    showAddTask = true
                } label: {
                    Label("Add New Task", systemImage: "plus.circle")
                }
            }
        } header: {
            Text("Work Scope")
        } footer: {
            if !payQuoteMessage.isEmpty { Text(payQuoteMessage).font(.caption) }
            Text("Tasks that already belong to an active offer are locked so they are not accidentally offered twice.")
        }
    }
    
    private var serviceStopTypeSection: some View {
        Section {
            if serviceStopTypeUseCase == .jobEstimate { Stepper("Estimated visit: \(diagnosticMinutes) minutes", value: $diagnosticMinutes, in: 15...480, step: 15) }
            Picker("Work Purpose", selection: $serviceStopTypeUseCase) {
                Text("Perform planned work").tag(ServiceStopTypeUseCase.jobVisit)
                Text("Diagnostic / estimate visit").tag(ServiceStopTypeUseCase.jobEstimate)
            }.onChange(of: serviceStopTypeUseCase) { _, purpose in selectedCompanyServiceStopType = nil; if purpose == .jobEstimate { selectedTaskIds = [] } }
            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase,
                title: "Pay Type",
                subtitle: "This is the default pay type used when this offer becomes a scheduled service stop."
            )
        } header: {
            Text("Pay Type")
        } footer: {
            Text("The accepted offer preserves this purpose and pay type when it is scheduled.")
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
    private var paySection: some View {
        Section {
            Picker("Pay Source", selection: $paySource) {
                ForEach(WorkOfferPaySource.allCases) { source in
                    Text(source.title).tag(source)
                }
            }

            if paySource == .offeredAmount {
                MoneyTextField(cents: $offeredAmountCents)
            }

            WorkOfferSummaryRow(title: "Estimated Minutes", value: "\(estimatedMinutes)")
            WorkOfferSummaryRow(title: "Planned Labor", value: money(estimatedLaborCents))

            if paySource == .offeredAmount {
                WorkOfferSummaryRow(title: "Offered Amount", value: money(offeredAmountCents))
            }
        } header: {
            Text("Pay")
        } footer: {
            Text("The accepted rate or fixed offer is preserved. Fixed pay and incentives are earned when the agreed work is complete. Hourly totals use recorded time.")
        }
    }

    private var scheduleSection: some View {
        Section {
            WorkOfferTimingFields(
                includeAvailableFrom: $includeDate, availableFrom: $proposedStartDate,
                includeDeadline: $includeDeadline, deadline: $completionDeadlineAt
            )

            TextField("Timeline notes", text: $timelineNotes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)

            Toggle("Allow technician self-scheduling", isOn: $allowsTechnicianSelfScheduling)
        } header: {
            Text("Deadline & Scheduling")
        } footer: {
            Text("Technicians see the completion deadline before accepting. If self-scheduling is allowed, the accepted technician can schedule immediately after accepting or later from Current.")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Offer title", text: $title)

            TextField("Notes for worker", text: $notes, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
        } header: {
            Text("Details")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await save()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Create Offer", systemImage: "paperplane")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(isSaving)
        } footer: {
            if !canSave {
                Text(createOfferValidationMessage)
                    .foregroundStyle(.orange)
            }
        }
    }
    
    private var createOfferValidationMessage: String {
        if serviceStopTypeUseCase != .jobEstimate && availableSelectedTaskIds.isEmpty {
            return "Select at least one available task."
        }

        if unavailableSelectedTaskCount > 0 {
            return "One or more selected tasks are already included in an active offer."
        }

        if offerType == .directUser && selectedWorker.userId.isEmpty {
            return "Select a technician before creating a direct offer."
        }

        if offerType == .externalCompany {
            return "External company offers are not supported yet."
        }

        if includeDeadline && includeDate && completionDeadlineAt < proposedStartDate {
            return "The completion deadline must be after the available-from time."
        }

        return ""
    }

    private var offerTypeHelpText: String {
        switch offerType {
        case .directUser:
            return "Send this work directly to one contractor."
        case .internalBoard:
            return "Post this work so eligible company users can claim or request it."
        case .externalCompany:
            return "External company offers can be added later."
        }
    }

    private var emptyCompanyUser: CompanyUser {
        CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .notAssigned
        )
    }

    private func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            companyUsers = try await dataService.getAllCompanyUsersByStatus(
                companyId: companyId,
                status: "Active"
            )

            workingJobTasks = jobTasks
            workingWorkOffers = workOffers

            await reloadLocalOfferData()
        } catch {
            alertMessage = "Could not load company users. \(error.userFacingMessage)"
            showAlert = true
        }
    }

    private func toggleTask(_ task: JobTask) {
        guard !offeredTaskIds.contains(task.id) else {
            alertMessage = "This task is already included in an active work offer."
            showAlert = true
            return
        }

        if selectedTaskIds.contains(task.id) {
            selectedTaskIds.remove(task.id)
        } else {
            selectedTaskIds.insert(task.id)
        }
    }

    private func save() async {
        guard canSave else {
            alertMessage = createOfferValidationMessage
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let status: WorkOfferStatus = offerType == .internalBoard ? .posted : .sent
            let finalTaskIds = Array(availableSelectedTaskIds)
            
            let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase
            )

            let payLines = estimatedPayLines
            let payTotal = payLines.reduce(0) { $0 + $1.totalAmountCents }
            
            var offer = WorkOffer(
                companyId: companyId,
                jobId: job.id,
                jobInternalId: job.internalId,
                jobName: job.type,
                offerType: offerType,
                status: status,
                title: defaultTitle,
                description: notes.isEmpty ? job.description : notes,
                offeredToUserId: offerType == .directUser ? selectedWorker.userId : "",
                offeredToUserName: offerType == .directUser ? selectedWorker.userName : "",
                offeredToWorkerType: offerType == .directUser ? selectedWorker.workerType : .notAssigned,
                postedToBoard: offerType == .internalBoard,
                boardVisibility: offerType == .internalBoard ? boardVisibility : .contractorsOnly,
                boardPostId: offerType == .internalBoard ? WorkOfferIdFactory.boardPostId() : "",
                jobTaskIds: finalTaskIds,
                customerId: job.customerId,
                customerName: job.customerName,
                serviceLocationId: job.serviceLocationId,
                serviceLocationName: serviceLocation?.nickName ?? "",
                address: serviceLocation?.address,
                proposedStartDate: includeDate ? proposedStartDate : nil,
                proposedEndDate: includeDeadline ? completionDeadlineAt : nil,
                completionDeadlineAt: includeDeadline ? completionDeadlineAt : nil,
                timelineNotes: timelineNotes,
                estimatedMinutes: estimatedMinutes,
                allowsTechnicianSelfScheduling: allowsTechnicianSelfScheduling,
                paySource: paySource,
                offeredAmountCents: paySource == .offeredAmount ? offeredAmountCents : 0,
                estimatedLaborCents: estimatedLaborCents,
                createdByUserId: currentUserId,
                createdByUserName: currentUserName,
                sentAt: offerType == .directUser ? Date() : nil,
                postedAt: offerType == .internalBoard ? Date() : nil,
                adminNotes: notes,
                serviceStopTypeId: typeFields.typeId,
                serviceStopTypeName: typeFields.type,
                serviceStopTypeImage: typeFields.typeImage,
                serviceStopTypeUseCaseRawValue: serviceStopTypeUseCase.rawValue,
                estimatedPayLines: payLines,
                estimatedPayTotalCents: payTotal,
                estimatedPayNotes: "Estimate only. Final payroll is generated from completed service stop work."
            )

            offer.workPurpose = serviceStopTypeUseCase == .jobEstimate ? "diagnostic" : "execution"
            try await dataService.saveWorkOffer(offer)
            onTasksChanged()
            onCreated?()
            dismiss()
        } catch {
            alertMessage = "Could not create work offer. \(error.userFacingMessage)"
            showAlert = true
        }
    }
    private var estimatedPayLines: [WorkOfferPayEstimateLine] { serverPayLines }
    private var legacyEstimatedPayLines: [WorkOfferPayEstimateLine] {
        switch paySource {
        case .unpaid:
            return [
                WorkOfferPayEstimateLine(
                    id: "offer_estimate_unpaid",
                    sourceTaskId: nil,
                    source: .manualAdjustment,
                    workTypeId: nil,
                    workTypeName: nil,
                    title: "Unpaid Work",
                    rateAmountCents: 0,
                    rateType: .manual,
                    quantity: 0,
                    quantityUnit: .each,
                    totalAmountCents: 0,
                    calculationStatus: .calculated,
                    notes: "This offer is marked unpaid."
                )
            ]

        case .offeredAmount:
            return [
                WorkOfferPayEstimateLine(
                    id: "offer_estimate_offered_amount",
                    sourceTaskId: nil,
                    source: .manualAdjustment,
                    workTypeId: nil,
                    workTypeName: nil,
                    title: "Offered Amount",
                    rateAmountCents: offeredAmountCents,
                    rateType: .manual,
                    quantity: 1,
                    quantityUnit: .each,
                    totalAmountCents: offeredAmountCents,
                    calculationStatus: offeredAmountCents > 0 ? .calculated : .needsReview,
                    notes: "Fixed amount offered for this work."
                )
            ]

        case .taskContractedRates:
            return selectedTasks
                .filter { $0.contractedRate > 0 }
                .map { task in
                    WorkOfferPayEstimateLine(
                        id: "offer_estimate_task_\(task.id)",
                        sourceTaskId: task.id,
                        source: .serviceStopTask,
                        workTypeId: nil,
                        workTypeName: task.type.rawValue,
                        title: task.name,
                        rateAmountCents: task.contractedRate,
                        rateType: .flatPerTask,
                        quantity: 1,
                        quantityUnit: .each,
                        totalAmountCents: task.contractedRate,
                        calculationStatus: .calculated,
                        notes: "\(task.type.rawValue) • \(task.estimatedTime) min • Task contracted rate"
                    )
                }

        case .technicianRate:
            return selectedTasks.map { task in
                WorkOfferPayEstimateLine(
                    id: "offer_estimate_task_preview_\(task.id)",
                    sourceTaskId: task.id,
                    source: .serviceStopTask,
                    workTypeId: nil,
                    workTypeName: task.type.rawValue,
                    title: task.name,
                    rateAmountCents: task.contractedRate,
                    rateType: .flatPerTask,
                    quantity: 1,
                    quantityUnit: .each,
                    totalAmountCents: task.contractedRate,
                    calculationStatus: task.contractedRate > 0 ? .calculated : .needsReview,
                    notes: "Temporary estimate from task contracted rate. Final pay should use technician rate preview when pay context is loaded."
                )
            }
        }
    }
    private func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
    private var activeWorkOffers: [WorkOffer] {
        workingWorkOffers.filter { offer in
            switch offer.status {
            case .rejected, .cancelled, .expired:
                return false
            case .pendingApproval, .acceptancePendingApproval, .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress, .completed:
                return true
            }
        }
    }

    private var offeredTaskIds: Set<String> {
        Set(activeWorkOffers.flatMap { $0.jobTaskIds })
    }

    private var availableTasks: [JobTask] {
        workingJobTasks.filter { !offeredTaskIds.contains($0.id) }
    }

    private var alreadyOfferedTasks: [JobTask] {
        workingJobTasks.filter { offeredTaskIds.contains($0.id) }
    }

    private var availableSelectedTaskIds: Set<String> {
        selectedTaskIds.filter { taskId in
            !offeredTaskIds.contains(taskId)
        }
    }

    private var unavailableSelectedTaskCount: Int {
        selectedTaskIds.filter { offeredTaskIds.contains($0) }.count
    }
}

// MARK: - Rows / Cards

struct JobWorkOfferCardView: View {
    var offer: WorkOffer

    private var statusTint: Color {
        switch offer.status {
        case .draft: return .secondary
        case .sent, .posted, .viewed: return .orange
        case .pendingApproval, .acceptancePendingApproval: return .orange
        case .accepted: return .poolGreen
        case .scheduled, .inProgress: return .poolBlue
        case .completed: return .secondary
        case .rejected, .cancelled, .expired: return .poolRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Text(offer.title.isEmpty ? "Work Offer" : offer.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 4)
                Text(offer.status.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(statusTint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusTint.opacity(0.12), in: Capsule())
            }
            Text("\(recipient) · \(offer.estimatedMinutes) min")
                .font(.caption).foregroundStyle(.secondary)
            if let deadline = offer.completionDeadlineAt ?? offer.proposedEndDate {
                Label(WorkOfferDetailDateFormatter.shortDateTime(deadline), systemImage: "flag.checkered")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if offer.offeredAmountCents > 0 {
                Text(WorkOfferDetailMoneyFormatter.money(offer.offeredAmountCents))
                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }

    private var recipient: String {
        switch offer.offerType {
        case .directUser:
            return offer.offeredToUserName.isEmpty ? "Direct offer" : offer.offeredToUserName
        case .internalBoard:
            return offer.boardName.flatMap { $0.isEmpty ? nil : $0 } ?? "Work board"
        case .externalCompany:
            return offer.externalCompanyName.isEmpty ? "External company" : offer.externalCompanyName
        }
    }
}

struct JobWorkOfferActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
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
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct WorkOfferSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

private extension View {
    func jobWorkOfferCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct JobCloseoutSheet: View {
    let companyId: String
    let job: Job
    let dataService: any ProductionDataServiceProtocol
    var onComplete: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @State private var tasks: [JobTask] = []
    @State private var products: [ShoppingListItem] = []
    @State private var selectedTasks = Set<String>()
    @State private var selectedProducts = Set<String>()
    @State private var selectedServices = Set<String>()
    @State private var finishJob = true
    @State private var cancelRemainingVisits = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error = ""
    @State private var requestId = UUID().uuidString
    private var services: [JobLaborLineItem] { job.laborLineItems ?? [] }
    private var remainingTasks: [JobTask] { tasks.filter { $0.status != .finished } }
    private var remainingProducts: [ShoppingListItem] { products.filter { $0.status != .installed } }
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    summaryCard
                    if isLoading {
                        ProgressView("Loading remaining work…")
                            .frame(maxWidth: .infinity, minHeight: 80)
                            .technicianPanel()
                    } else {
                        optionsSection
                        servicesSection
                        tasksSection
                        productsSection
                    }
                }
                .padding(14)
                .disabled(isSaving)
            }
            .background(Color.listColor.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) { completionBar }
            .navigationTitle("Job Closeout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task { await load() }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
                    .frame(width: 42, height: 42)
                    .background(Color.poolGreen.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text([job.internalId, job.type].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.headline)
                    if !job.customerName.isEmpty {
                        Text(job.customerName).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text("Review the completed work and choose how to close out this job.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            if !isLoading {
                HStack(spacing: 10) {
                    summaryCount("Services", count: services.count)
                    summaryCount("Tasks", count: remainingTasks.count)
                    summaryCount("Products", count: remainingProducts.count)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .workOfferSurface(tint: .poolGreen)
    }

    private func summaryCount(_ title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)").font(.headline)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.poolGreen.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    private var optionsSection: some View {
        TechnicianWorkPanel(title: "Closeout options", systemImage: "checkmark.seal") {
            Toggle(isOn: $finishJob) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Finish the entire job").font(.subheadline.weight(.semibold))
                    Text("Turn off to save completed work and keep the job open.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if finishJob {
                Toggle(isOn: $cancelRemainingVisits) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cancel unused visits").font(.subheadline.weight(.semibold))
                        Text("Also cancels unaccepted work offers.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel("Cancel unused visits and unaccepted offers")
            }
            Divider()
            Button {
                selectedTasks = Set(remainingTasks.map(\.id))
                selectedProducts = Set(remainingProducts.map(\.id))
                selectedServices = Set(services.map(\.id))
            } label: {
                Label("Select all remaining work", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .slate))
            .tint(.poolBlue)
        }
        .tint(.poolGreen)
    }

    private var servicesSection: some View {
        TechnicianWorkPanel(title: "Service items", systemImage: "wrench.and.screwdriver") {
            if services.isEmpty {
                emptySection("No service items to review.")
            } else {
                ForEach(services) { service in
                    selectionRow(
                        service.name ?? "Service",
                        subtitle: service.description,
                        isSelected: Binding(get: { selectedServices.contains(service.id) }, set: { value in
                            if value { selectedServices.insert(service.id); selectedTasks.formUnion(service.linkedTaskIds) }
                            else { selectedServices.remove(service.id) }
                        })
                    )
                }
            }
        }
    }

    private var tasksSection: some View {
        TechnicianWorkPanel(title: "Remaining tasks", systemImage: "checklist") {
            if remainingTasks.isEmpty {
                emptySection("No remaining tasks to finish.")
            } else {
                ForEach(remainingTasks) { task in
                    selectionRow(
                        task.name,
                        subtitle: task.workerName,
                        isSelected: Binding(get: { selectedTasks.contains(task.id) }, set: { value in
                            if value { selectedTasks.insert(task.id) } else { selectedTasks.remove(task.id) }
                        })
                    )
                }
            }
        }
    }

    private var productsSection: some View {
        TechnicianWorkPanel(title: "Products to install", systemImage: "shippingbox") {
            if remainingProducts.isEmpty {
                emptySection("No products left to mark installed.")
            } else {
                ForEach(remainingProducts) { item in
                    selectionRow(
                        item.name,
                        subtitle: "Quantity: " + (item.quantity ?? "1"),
                        isSelected: Binding(get: { selectedProducts.contains(item.id) }, set: { value in
                            if value { selectedProducts.insert(item.id); if let taskId = item.linkedTaskId { selectedTasks.insert(taskId) } }
                            else { selectedProducts.remove(item.id) }
                        })
                    )
                }
            }
        }
    }

    private func emptySection(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
    }

    private func selectionRow(_ title: String, subtitle: String? = nil, isSelected: Binding<Bool>) -> some View {
        Button { isSelected.wrappedValue.toggle() } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected.wrappedValue ? Color.poolGreen : Color.secondary)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isSelected.wrappedValue ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected.wrappedValue ? .isSelected : [])
    }

    private var completionBar: some View {
        VStack(spacing: 8) {
            if !error.isEmpty {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.poolRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !isLoading {
                Text("\(selectedServices.count) services · \(remainingTasks.filter { selectedTasks.contains($0.id) }.count) tasks · \(selectedProducts.count) products selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button { Task { await complete() } } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().tint(.white) }
                    Label(isSaving ? "Completing…" : finishJob ? "Finish Job" : "Save Completed Work", systemImage: finishJob ? "checkmark.seal" : "checkmark.circle")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
            .buttonBorderShape(.capsule)
            .tint(.poolGreen)
            .disabled(isLoading || isSaving)
            Text(finishJob ? "Completes the selected work and closes this job." : "Saves the selected work and keeps this job open.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color(.systemBackground))
    }

    @MainActor private func load() async {
        do {
            tasks = try await dataService.getJobTasks(companyId: companyId, jobId: job.id)
            products = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: ShoppingListCategory.job.rawValue)
        } catch { self.error = error.userFacingMessage }
        isLoading = false
    }
    @MainActor private func complete() async {
        isSaving = true; error = ""; defer { isSaving = false }
        do {
            if finishJob && (remainingTasks.contains { !selectedTasks.contains($0.id) } || remainingProducts.contains { !selectedProducts.contains($0.id) }) {
                error = "Select all remaining work to finish the job, or turn off Finish the entire job."; return
            }
            let helper = JobDetailViewModel(dataService: dataService)
            for task in remainingTasks where selectedTasks.contains(task.id) {
                try await helper.updateTaskHelperFunction(companyId: companyId, task: task, jobId: job.id)
            }
            _ = try await FunctionsManager.shared.technicianWorkflow("finalizeTechnicianJob", payload: [
                "companyId":companyId,"jobId":job.id,"requestId":requestId,"finishJob":finishJob,
                "cancelRemainingVisits":cancelRemainingVisits,"taskIds":Array(selectedTasks),
                "productIds":Array(selectedProducts),"serviceIds":Array(selectedServices)
            ])
            onComplete(); dismiss()
        } catch { self.error = error.userFacingMessage }
    }
}

// Keep selection tied to the dated route, including when stops change before posting.
enum RouteCoverageSelection {
    static func eligibleStops(in stops: [ServiceStop], route: ActiveRoute) -> [ServiceStop] {
        let byId = Dictionary(stops.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var seen = Set<String>()
        return route.serviceStopsIds.compactMap { id in
            guard seen.insert(id).inserted,
                  let stop = byId[id],
                  stop.operationStatus == .notFinished,
                  stop.startTime == nil, stop.endTime == nil,
                  stop.techId == route.techId,
                  Calendar.current.isDate(stop.serviceDate, inSameDayAs: route.date) else { return nil }
            return stop
        }
    }

    static func selectedStopIds(in stops: [ServiceStop], route: ActiveRoute, selected: Set<String>) -> [String] {
        eligibleStops(in: stops, route: route).map(\.id).filter { selected.contains($0) }
    }

    static func isWholeRoute(_ ids: [String], route: ActiveRoute) -> Bool {
        !ids.isEmpty && Set(ids) == Set(route.serviceStopsIds)
    }

    static func coverageSelection(available: Set<String>, requested: Set<String>?) -> Set<String> {
        (requested ?? available).intersection(available)
    }

    static func cents(from text: String) -> Int? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return 0 }
        guard value.range(of: #"^\d+(?:[.,]\d{1,2})?$"#, options: .regularExpression) != nil,
              let amount = Double(value.replacingOccurrences(of: ",", with: ".")),
              amount.isFinite, amount < Double(Int.max) / 100 else { return nil }
        return Int((amount * 100).rounded())
    }
}

struct RouteCoverageOfferSheet: View {
    let companyId: String
    let route: ActiveRoute
    let dataService: any ProductionDataServiceProtocol
    let initialSelectedStopIds: Set<String>?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @State private var includeDeadline = true
    @State private var completionDeadlineAt: Date
    @State private var reason = "Scheduling conflict"
    @State private var throughDate: Date
    @State private var loadedThroughDate: Date
    @State private var routes: [ActiveRoute] = []
    @State private var postedRouteIds = Set<String>()
    @State private var stops: [ServiceStop] = []
    @State private var users: [CompanyUser] = []
    @State private var selected = Set<String>()
    @State private var allowSplit = false
    @State private var fixedPay = ""
    @State private var incentivePay = ""
    @State private var directWorkerId = ""
    @State private var canPost = false
    @State private var canPostForOthers = false
    @State private var canSplit = false
    @State private var canSetPay = false
    @State private var canIncentivize = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var message = ""
    @State private var offerId = WorkOfferIdFactory.workOfferId()
    @State private var hasLoadedSelection = false

    init(companyId: String, route: ActiveRoute, dataService: any ProductionDataServiceProtocol, initialSelectedStopIds: Set<String>? = nil, initialReason: String = "Scheduling conflict") {
        self.companyId = companyId
        self.route = route
        self.dataService = dataService
        self.initialSelectedStopIds = initialSelectedStopIds
        _completionDeadlineAt = State(initialValue: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: route.date) ?? route.date)
        _reason = State(initialValue: initialReason)
        _throughDate = State(initialValue: route.date)
        _loadedThroughDate = State(initialValue: route.date)
    }

    private var routeName: String { route.name.isEmpty ? "Daily Route" : route.name }
    private var unpostedRoutes: [ActiveRoute] { routes.filter { !postedRouteIds.contains($0.id) } }
    private var eligibleStops: [ServiceStop] {
        unpostedRoutes.flatMap { RouteCoverageSelection.eligibleStops(in: stops, route: $0) }
    }
    private var selectedIds: [String] {
        unpostedRoutes.flatMap { RouteCoverageSelection.selectedStopIds(in: stops, route: $0, selected: selected) }
    }
    private var hasUnloadedDates: Bool { !Calendar.current.isDate(throughDate, inSameDayAs: loadedThroughDate) }
    private var estimatedMinutes: Int {
        eligibleStops.filter { selected.contains($0.id) }.reduce(0) { $0 + $1.estimatedDuration }
    }
    private var canOfferRoute: Bool {
        canPost && (route.techId == masterDataManager.user?.id || canPostForOthers)
    }
    private var validDeadline: Bool {
        unpostedRoutes.allSatisfy {
            WorkOfferTiming.isValid(availableFrom: Calendar.current.startOfDay(for: $0.date), deadline: deadline(for: $0))
        }
    }
    private func deadline(for datedRoute: ActiveRoute) -> Date? {
        guard includeDeadline else { return nil }
        if Calendar.current.isDate(throughDate, inSameDayAs: route.date) { return completionDeadlineAt }
        return WorkOfferTiming.deadline(on: datedRoute.date, at: completionDeadlineAt)
    }

    private var validPay: Bool {
        (!canSetPay || RouteCoverageSelection.cents(from: fixedPay) != nil) &&
        (!canIncentivize || RouteCoverageSelection.cents(from: incentivePay) != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    routeSummary
                    if isLoading {
                        ProgressView("Loading route stops…")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if canOfferRoute {
                        stopSelection
                        deadlineSection
                        offerOptions
                    } else {
                        Text("Your company has not enabled coverage offers for this route.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .jobWorkOfferCard()
                    }
                    if !message.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label(message, systemImage: "exclamationmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Button("Reload Route") { Task { await load() } }
                        }
                        .jobWorkOfferCard()
                    }
                }
                .padding(14)
                .disabled(isSaving || isLoading)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Offer Route Coverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) { postButton }
            .interactiveDismissDisabled(isSaving)
            .task { await load() }
        }
    }

    private var routeSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(routeName).font(.headline)
                    Text(route.date.formatted(date: .complete, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !route.techName.isEmpty {
                        Text(route.techName).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Text("Choose the stops you need covered. Your recurring route assignment stays the same.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if canOfferRoute {
                Divider()
                DatePicker(
                    "Coverage through", selection: $throughDate,
                    in: route.date...(Calendar.current.date(byAdding: .day, value: 30, to: route.date) ?? route.date),
                    displayedComponents: .date
                )
                .font(.subheadline)
                .disabled(!postedRouteIds.isEmpty)
                if hasUnloadedDates {
                    Button("Load Coverage Dates") { Task { await load() } }
                        .font(.subheadline.weight(.semibold))
                }
                Text("Extend the dates for time away. Existing dated routes are shown, with a separate offer for each day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var stopSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Stops to Cover", systemImage: "checklist").font(.headline)
                Spacer()
                Text("\(selectedIds.count) of \(eligibleStops.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if eligibleStops.isEmpty {
                Text("There are no remaining stops to offer on this route.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 12) {
                    Button("Select All Remaining") { selected = Set(eligibleStops.map(\.id)) }
                    Spacer()
                    Button("Clear") { selected.removeAll() }
                }
                .font(.caption.weight(.semibold))
                .tint(.poolBlue)

                ForEach(unpostedRoutes) { datedRoute in
                    let remaining = RouteCoverageSelection.eligibleStops(in: stops, route: datedRoute)
                    if !remaining.isEmpty {
                        if routes.count > 1 {
                            Text(datedRoute.date.formatted(date: .complete, time: .omitted))
                                .font(.subheadline.weight(.semibold))
                        }
                        ForEach(remaining) { stop in stopSelectionRow(stop) }
                    }
                }
            }
            Text("Completed and skipped stops are excluded. Deselect any stops you will keep.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .jobWorkOfferCard()
        .disabled(hasUnloadedDates)
    }

    private func stopSelectionRow(_ stop: ServiceStop) -> some View {
        Button {
            if selected.contains(stop.id) { selected.remove(stop.id) }
            else { selected.insert(stop.id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected.contains(stop.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected.contains(stop.id) ? Color.poolBlue : Color.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.customerName).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text(stop.type).font(.caption).foregroundStyle(.secondary)
                    if !stop.address.streetAddress.isEmpty {
                        Text(stop.address.streetAddress).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Text("\(stop.estimatedDuration) min").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(12)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected.contains(stop.id) ? .isSelected : [])
    }

    private var deadlineSection: some View {
        TechnicianWorkPanel(title: "Completion deadline", systemImage: "flag.checkered") {
            Toggle("Set completion deadline", isOn: $includeDeadline)
            if includeDeadline {
                DatePicker(
                    Calendar.current.isDate(throughDate, inSameDayAs: route.date) ? "Complete by" : "Complete each day by",
                    selection: $completionDeadlineAt,
                    displayedComponents: Calendar.current.isDate(throughDate, inSameDayAs: route.date) ? [.date, .hourAndMinute] : [.hourAndMinute]
                )
                Text("For multiple coverage days, each offer uses its own route date and this deadline time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !validDeadline {
                Text("The completion deadline must follow the route’s available date.")
                    .font(.caption)
                    .foregroundStyle(Color.poolRed)
            }
        }
        .tint(.poolBlue)
        .disabled(hasUnloadedDates)
    }

    private var offerOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Coverage Details", systemImage: "paperplane").font(.headline)
            Picker("Reason", selection: $reason) {
                Text("Scheduling conflict").tag("Scheduling conflict")
                Text("Sick day").tag("Sick day")
                Text("Vacation").tag("Vacation")
            }
            Picker("Send to", selection: $directWorkerId) {
                Text("Company Work Board").tag("")
                ForEach(users.filter { $0.userId != route.techId }) { user in
                    Text(user.userName).tag(user.userId)
                }
            }
            if canSplit {
                Toggle("Allow multiple technicians", isOn: $allowSplit)
                Text("When enabled, technicians can pick up individual stops. Otherwise one technician takes all selected stops.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("One technician takes all selected stops.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if canSetPay || canIncentivize {
                Divider()
                if canSetPay {
                    TextField("Fixed pay per daily offer (optional)", text: $fixedPay)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                if canIncentivize {
                    TextField("Incentive per daily offer (optional)", text: $incentivePay)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                Text("Each day creates a separate offer. Leave pay blank to use the accepting technician’s rate.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !validPay {
                    Text("Enter an amount of zero or more with up to two decimal places.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .tint(.poolBlue)
        .jobWorkOfferCard()
    }

    private var postButton: some View {
        VStack(spacing: 10) {
            if !selectedIds.isEmpty {
                Text("\(selectedIds.count) stop\(selectedIds.count == 1 ? "" : "s") selected · \(estimatedMinutes) min")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Button { Task { await post() } } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isSaving ? "Posting Coverage…" : "Post Coverage Offer")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
            .tint(.poolBlue)
            .disabled(!canOfferRoute || isSaving || isLoading || hasUnloadedDates || selectedIds.isEmpty || !validPay || !validDeadline)
        }
        .padding(14)
        .background(.regularMaterial)
    }

    @MainActor private func fetchStops() async throws -> [ServiceStop] {
        var loaded: [ServiceStop] = []
        var seen = Set<String>()
        for datedRoute in unpostedRoutes {
            for stopId in datedRoute.serviceStopsIds where seen.insert(stopId).inserted {
                loaded.append(try await dataService.getServiceStopById(serviceStopId: stopId, companyId: companyId))
            }
        }
        return loaded
    }

    @MainActor private func load() async {
        guard !isSaving else { return }
        isLoading = true
        message = ""
        defer { isLoading = false }
        do {
            let capabilities = try await FunctionsManager.shared.technicianWorkflow(
                "manageTechnicianWork", payload: ["companyId": companyId, "action": "capabilities"]
            )
            canPost = capabilities["canPost"] as? Bool ?? false
            canPostForOthers = capabilities["canPostForOthers"] as? Bool ?? false
            canSplit = capabilities["canSplit"] as? Bool ?? false
            canSetPay = capabilities["canSetPay"] as? Bool ?? false
            canIncentivize = capabilities["canIncentivize"] as? Bool ?? false
            guard canOfferRoute else { return }
            users = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
            if Calendar.current.isDate(throughDate, inSameDayAs: route.date) {
                routes = [route]
            } else {
                let start = Calendar.current.startOfDay(for: route.date)
                let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: throughDate)) ?? throughDate
                let snapshot = try await Firestore.firestore().collection("companies").document(companyId)
                    .collection("activeRoutes").whereField("techId", isEqualTo: route.techId)
                    .whereField("date", isGreaterThanOrEqualTo: start).whereField("date", isLessThan: end).getDocuments()
                routes = try snapshot.documents.map { document in
                    var datedRoute = try document.data(as: ActiveRoute.self)
                    datedRoute.id = document.documentID
                    if datedRoute.serviceStopsIds.isEmpty {
                        datedRoute.serviceStopsIds = document.data()["serviceStopIds"] as? [String] ?? []
                    }
                    return datedRoute
                }
                if !routes.contains(where: { $0.id == route.id }) { routes.append(route) }
                routes.sort { $0.date < $1.date }
            }
            stops = try await fetchStops()
            let available = Set(eligibleStops.map(\.id))
            selected = RouteCoverageSelection.coverageSelection(available: available, requested: hasLoadedSelection ? selected : initialSelectedStopIds)
            hasLoadedSelection = true
            loadedThroughDate = throughDate
        } catch {
            stops = []
            message = error.userFacingMessage
        }
    }

    @MainActor private func post() async {
        guard canOfferRoute, !isLoading, !isSaving, !hasUnloadedDates, validPay, validDeadline, !selectedIds.isEmpty else { return }
        isSaving = true
        message = ""
        defer { isSaving = false }
        do {
            let previousIds = selectedIds
            stops = try await fetchStops()
            guard selectedIds == previousIds else {
                selected = Set(selectedIds)
                message = "Some stops have changed or are no longer available. Review the selection before posting."
                return
            }
            let fixedCents = canSetPay ? (RouteCoverageSelection.cents(from: fixedPay) ?? 0) : 0
            let bonusCents = canIncentivize ? (RouteCoverageSelection.cents(from: incentivePay) ?? 0) : 0
            let worker = users.first { $0.userId == directWorkerId }
            for datedRoute in unpostedRoutes {
                let ids = RouteCoverageSelection.selectedStopIds(in: stops, route: datedRoute, selected: selected)
                guard !ids.isEmpty else { continue }
                let name = datedRoute.name.isEmpty ? "Daily Route" : datedRoute.name
                let start = Calendar.current.startOfDay(for: datedRoute.date)
                let completionDeadline = deadline(for: datedRoute)
                let minutes = stops.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.estimatedDuration }
                var offer = WorkOffer(
                    id: offerId + "_" + datedRoute.id, companyId: companyId, jobId: "", jobInternalId: "", jobName: "",
                    offerType: directWorkerId.isEmpty ? .internalBoard : .directUser,
                    title: name + " coverage",
                    description: reason + " coverage: complete the selected route stops and their required service tasks.",
                    offeredToUserId: directWorkerId, offeredToUserName: worker?.userName ?? "",
                    postedToBoard: directWorkerId.isEmpty, boardVisibility: .employeesAndContractors,
                    jobTaskIds: [], customerId: "", customerName: "", serviceLocationId: "",
                    proposedStartDate: start, proposedEndDate: completionDeadline, completionDeadlineAt: completionDeadline, estimatedMinutes: minutes,
                    paySource: fixedCents > 0 ? .offeredAmount : .technicianRate,
                    offeredAmountCents: fixedCents, estimatedLaborCents: 0,
                    createdByUserId: masterDataManager.user?.id ?? "", createdByUserName: ""
                )
                offer.routeId = datedRoute.id
                offer.routeSource = "activeRoutes"
                offer.routeName = name
                offer.routeDate = datedRoute.date
                offer.routeTechId = datedRoute.techId
                offer.originalTechnicianId = datedRoute.techId
                offer.routeServiceStopIds = ids
                let wholeRoute = RouteCoverageSelection.isWholeRoute(ids, route: datedRoute)
                offer.routeOfferMode = wholeRoute ? "whole" : "partial"
                offer.routeSplitAllowed = canSplit && allowSplit
                offer.workOfferCategory = wholeRoute ? "fullRoute" : "partialRoute"
                offer.coverageReason = reason
                if bonusCents > 0 {
                    offer.incentive = WorkOfferIncentive(type: "flat", amountCents: bonusCents, percentage: 0, notes: "Coverage incentive")
                }
                try await dataService.saveWorkOffer(offer)
                postedRouteIds.insert(datedRoute.id)
                selected.subtract(ids)
            }
            dismiss()
        } catch {
            let posted = postedRouteIds.count
            message = (posted > 0 ? "\(posted) daily offer(s) already posted. Retry to post the remaining selection. " : "") + error.userFacingMessage
        }
    }
}
