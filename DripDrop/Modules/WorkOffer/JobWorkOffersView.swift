//
//  JobWorkOffersView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

struct JobWorkOffersView: View {
    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceLocation: ServiceLocation?
    let workOffers: [WorkOffer]
    let dataService: any ProductionDataServiceProtocol
    let onReload: () -> Void

    @State private var showCreateOffer: Bool = false
    @State private var showAddTask: Bool = false

    private var activeWorkOffers: [WorkOffer] {
        workOffers.filter { offer in
            switch offer.status {
            case .rejected, .cancelled, .expired:
                return false
            case .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress, .completed:
                return true
            }
        }
    }

    private var offeredTaskIds: Set<String> {
        Set(activeWorkOffers.flatMap { $0.jobTaskIds })
    }

    private var availableTaskCount: Int {
        jobTasks.filter { !offeredTaskIds.contains($0.id) }.count
    }

    private var alreadyOfferedTaskCount: Int {
        jobTasks.filter { offeredTaskIds.contains($0.id) }.count
    }

    private var acceptedReadyToScheduleCount: Int {
        workOffers.filter {
            $0.status == .accepted &&
            $0.serviceStopId.isEmpty
        }.count
    }

    private var openOfferCount: Int {
        workOffers.filter { $0.status.isOpen }.count
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                headerCard
                offerActionsCard
                taskCoverageCard
                offersListCard

                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
        .sheet(isPresented: $showCreateOffer, onDismiss: {
            onReload()
        }) {
            CreateJobWorkOfferView(
                companyId: companyId,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                job: job,
                jobTasks: jobTasks,
                serviceLocation: serviceLocation,
                workOffers: workOffers,
                dataService: dataService,
                onTasksChanged: {
                    onReload()
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddTask, onDismiss: {
            onReload()
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

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Work Offers")
                        .font(.title3.weight(.semibold))

                    Text("\(job.internalId) • \(job.customerName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(workOffers.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }

            Text("Offer planned job tasks to a contractor, post them to the internal board, or add more tasks before creating an offer.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                JobWorkOfferSummaryChip(
                    title: "Open",
                    value: "\(openOfferCount)",
                    systemImage: "paperplane"
                )

                JobWorkOfferSummaryChip(
                    title: "Ready",
                    value: "\(acceptedReadyToScheduleCount)",
                    systemImage: "calendar.badge.plus"
                )

                JobWorkOfferSummaryChip(
                    title: "Available",
                    value: "\(availableTaskCount)",
                    systemImage: "checklist"
                )
            }
        }
        .jobWorkOfferCard()
    }

    private var offerActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Actions", systemImage: "plus.circle")

            Button {
                showCreateOffer = true
            } label: {
                JobWorkOfferActionRow(
                    title: "Create Work Offer",
                    subtitle: "Send available tasks to a contractor or post to the board.",
                    systemImage: "person.crop.circle.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .disabled(availableTaskCount == 0)
            .opacity(availableTaskCount == 0 ? 0.55 : 1)

            Button {
                showAddTask = true
            } label: {
                JobWorkOfferActionRow(
                    title: "Add New Task",
                    subtitle: "Create another task for this job, then offer it.",
                    systemImage: "selection.reminders.checklist.badge.plus"
                )
            }
            .buttonStyle(.plain)
        }
        .jobWorkOfferCard()
    }

    private var taskCoverageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Task Offer Coverage", systemImage: "checklist")

                Spacer()

                Text("\(alreadyOfferedTaskCount)/\(jobTasks.count) offered")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if jobTasks.isEmpty {
                JobWorkOfferEmptyMiniState(
                    title: "No tasks yet.",
                    message: "Add tasks before creating a work offer.",
                    systemImage: "checklist.unchecked"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(jobTasks) { task in
                        JobWorkOfferTaskCoverageRow(
                            task: task,
                            offer: activeOfferForTask(task)
                        )
                    }
                }
            }
        }
        .jobWorkOfferCard()
    }

    private var offersListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader("Offers", systemImage: "tray.full")

                Spacer()

                Text("\(openOfferCount) open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if workOffers.isEmpty {
                JobWorkOfferEmptyMiniState(
                    title: "No Work Offers",
                    message: "Create an offer when you want a contractor to accept work or when you want to post this job to the internal board.",
                    systemImage: "tray"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(workOffers.sorted(by: { $0.createdAt > $1.createdAt })) { offer in
                        NavigationLink {
                            WorkOfferDetailView(
                                companyId: companyId,
                                currentUserId: currentUserId,
                                currentUserName: currentUserName,
                                offer: offer,
                                jobTasks: jobTasks,
                                dataService: dataService,
                                onChanged: onReload
                            )
                        } label: {
                            JobWorkOfferCardView(offer: offer)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .jobWorkOfferCard()
    }

    private func activeOfferForTask(_ task: JobTask) -> WorkOffer? {
        activeWorkOffers.first { offer in
            offer.jobTaskIds.contains(task.id)
        }
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }
    struct JobWorkOfferSummaryChip: View {
        var title: String
        var value: String
        var systemImage: String

        var body: some View {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    struct JobWorkOfferTaskCoverageRow: View {
        var task: JobTask
        var offer: WorkOffer?

        private var isOffered: Bool {
            offer != nil
        }

        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: isOffered ? "lock.fill" : "circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isOffered ? .secondary : .tertiary)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(isOffered ? "Offered" : "Available")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }
            .padding(12)
            .background(
                isOffered ? Color.primary.opacity(0.035) : Color.accentColor.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(isOffered ? 0.7 : 1)
        }

        private var subtitle: String {
            if let offer {
                return "\(task.type.rawValue) • \(offer.status.title) offer"
            }

            return "\(task.type.rawValue) • \(task.estimatedTime) min"
        }
    }

    struct JobWorkOfferEmptyMiniState: View {
        var title: String
        var message: String
        var systemImage: String

        var body: some View {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
// MARK: - Create Offer View

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

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var proposedStartDate: Date = Date()
    @State private var includeDate: Bool = false

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
        selectedTasks.reduce(0) { $0 + $1.estimatedTime }
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
        guard !availableSelectedTaskIds.isEmpty else { return false }
        guard unavailableSelectedTaskCount == 0 else { return false }

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
                taskScopeSection
                serviceStopTypeSection
                paySection
                scheduleSection
                saveSection
            }
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
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    case .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress, .completed:
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
            alertMessage = "Could not reload tasks or offers. \(error.localizedDescription)"
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
            Text("Tasks that already belong to an active offer are locked so they are not accidentally offered twice.")
        }
    }
    
    private var serviceStopTypeSection: some View {
        Section {
            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase,
                title: "Service Stop Type",
                subtitle: "This is the default type used when this offer becomes a scheduled service stop."
            )
        } header: {
            Text("Service Stop Type")
        } footer: {
            Text("You can still change this later when scheduling, but choosing it now makes the offer and pay estimate more accurate.")
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
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            Text("This is a work-offer snapshot. The payroll engine still calculates final pay from completed work unless you later choose to support offered-amount overrides.")
        }
    }

    private var scheduleSection: some View {
        Section {
            Toggle("Include proposed date", isOn: $includeDate)

            if includeDate {
                DatePicker(
                    "Proposed Date",
                    selection: $proposedStartDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Toggle("Allow technician self-scheduling", isOn: $allowsTechnicianSelfScheduling)
        } header: {
            Text("Proposed Schedule")
        } footer: {
            Text("If self-scheduling is allowed, the accepted technician can create the scheduled service stop from their work center.")
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
        if availableSelectedTaskIds.isEmpty {
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
            alertMessage = "Could not load company users. \(error.localizedDescription)"
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
            
            let offer = WorkOffer(
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
                proposedEndDate: nil,
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

            try await dataService.saveWorkOffer(offer)
            onTasksChanged()
            dismiss()
        } catch {
            alertMessage = "Could not create work offer. \(error.localizedDescription)"
            showAlert = true
        }
    }
    private var estimatedPayLines: [WorkOfferPayEstimateLine] {
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
            case .draft, .sent, .posted, .viewed, .accepted, .scheduled, .inProgress, .completed:
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

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Image(systemName: offer.offerType.systemImage)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(offer.title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            HStack {
                Label("\(offer.jobTaskIds.count) task(s)", systemImage: "checklist")
                Spacer()
                Label("\(offer.estimatedMinutes) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if offer.offeredAmountCents > 0 {
                Text("Offered: \(money(offer.offeredAmountCents))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var subtitle: String {
        switch offer.offerType {
        case .directUser:
            return offer.offeredToUserName.isEmpty ? "Direct offer" : "Offered to \(offer.offeredToUserName)"
        case .internalBoard:
            return "Posted to board • \(offer.boardVisibility.title)"
        case .externalCompany:
            return offer.externalCompanyName.isEmpty ? "External company offer" : offer.externalCompanyName
        }
    }

    private func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
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
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
