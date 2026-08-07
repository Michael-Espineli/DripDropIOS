    //
    //  CustomerUpcomingWork.swift
    //  ThePoolApp
    //
    //  Aesthetic-only refresh:
    //  - dashboard background
    //  - “page header” feel
    //  - compact section cards
    //  - consistent header controls (icon buttons)
    //  - better spacing + typography
    //

    import SwiftUI

    enum CustomerUpcomingWorkMode {
        case operations
        case notes
    }

    struct CustomerUpcomingWork: View {
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService

        @EnvironmentObject var VM: CustomerProfileViewModel
        @EnvironmentObject var customerListVM: CustomerListViewModel

        private var customer: Customer? {
            customerListVM.customers.first { $0.id == customerId }
        }

        @State var customerId: String
        let mode: CustomerUpcomingWorkMode

        init(
            dataService: any ProductionDataServiceProtocol,
            customerId: String,
            mode: CustomerUpcomingWorkMode = .operations
        ) {
            _customerId = State(wrappedValue: customerId)
            self.mode = mode
        }

        @State var editRSS: Bool = false
        @State var addRSS: Bool = false
        @State var addRepairRequest: Bool = false
        @State var addJob: Bool = false
        @State var addItem: Bool = false
        @State var addServiceStop: Bool = false

        @State var alertMessage: String = ""
        @State var showAlert: Bool = false
        @State var showDeleteConfirmation: Bool = false
        @State var rssID: String = ""
        @State var selectedJob: Job? = nil
        @State private var customerNoteText: String = ""
        @State private var selectedNoteBodyOfWaterId: String = ""
        @State private var isSavingCustomerNote: Bool = false

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        pageHeader

                        if mode == .notes {
                            customerNotes
                        } else {
                            recurringServiceStops
                            serviceStops
                            outstandingWork
                            repairRequests
                            jobs
                        }
                    }
                    .padding(.horizontal, 0)
                    .padding(.top, 2)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
            .task {
                startLiveUpcomingWork()
            }
            .onAppear {
                startLiveUpcomingWork()

                Task {
                    await refreshUpcomingWorkBackup()
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Alert"),
                    message: Text("\(alertMessage)"),
                    primaryButton: .destructive(Text("Delete")) {
                        if rssID != "" {
                            Task {
                                if let company = masterDataManager.currentCompany {
                                    do {
                                        try await VM.deleteRecurringServiceStop(
                                            companyId: company.id,
                                            RecurringServiceStopId: rssID
                                        )

                                        rssID = ""

                                        try await VM.reloadRecurringServiceStops(
                                            companyId: company.id,
                                            customerId: customerId
                                        )
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }

        private func startLiveUpcomingWork() {
            guard let company = masterDataManager.currentCompany else { return }

            VM.startUpcomingWorkListeners(
                companyId: company.id,
                customerId: customerId
            )
        }

        private func refreshUpcomingWorkBackup() async {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                try await VM.reloadRecurringServiceStops(
                    companyId: company.id,
                    customerId: customerId
                )

                try await VM.reloadRepairRequests(
                    companyId: company.id,
                    customerId: customerId
                )

                try await VM.reloadJobs(
                    companyId: company.id,
                    customerId: customerId
                )

                try await VM.reloadCustomerBodiesOfWater(
                    companyId: company.id,
                    customerId: customerId
                )
            } catch {
                print("[CustomerUpcomingWork][refreshUpcomingWorkBackup] Error: \(error)")
            }
        }
    }

    // MARK: - Header

    extension CustomerUpcomingWork {
        private var pageHeader: some View {
            HStack(spacing: 10) {
                Image(systemName: mode == .notes ? "text.bubble.fill" : "wrench.and.screwdriver.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 34, height: 34)
                    .background(Color.poolBlue.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode == .notes ? "Customer Notes" : "Upcoming Work")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(mode == .notes ? "Open notes, office notes, and customer context." : "Recurring stops, scheduled service, repairs, and jobs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    // MARK: - Sections

    extension CustomerUpcomingWork {

        private var currentUserDisplayName: String {
            let firstName = masterDataManager.user?.firstName ?? ""
            let lastName = masterDataManager.user?.lastName ?? ""
            let fullName = [firstName, lastName]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            if !fullName.isEmpty {
                return fullName
            }

            return masterDataManager.user?.email ?? "Admin"
        }

        private var selectedNoteBodyOfWater: BodyOfWater? {
            VM.customerBodiesOfWater.first { $0.id == selectedNoteBodyOfWaterId }
        }

        private var outstandingWorkItems: [CustomerOutstandingWorkDisplayItem] {
            var jobsById: [String: Job] = [:]
            VM.jobs.forEach { jobsById[$0.id] = $0 }

            var repairsById: [String: RepairRequest] = [:]
            VM.repairRequest.forEach { repairsById[$0.id] = $0 }

            var usedSourceKeys = Set<String>()
            var items: [CustomerOutstandingWorkDisplayItem] = []

            for record in VM.customerOutstandingWork {
                let recordJobId = record.jobId ?? record.sourceId
                let linkedJob = recordJobId.flatMap { jobsById[$0] }
                let linkedRepair = record.sourceType?.lowercased().contains("repair") == true
                    ? record.sourceId.flatMap { repairsById[$0] }
                    : nil

                if let linkedJob {
                    usedSourceKeys.insert("job-\(linkedJob.id)")
                }

                if let linkedRepair {
                    usedSourceKeys.insert("repair-\(linkedRepair.id)")
                }

                items.append(
                    CustomerOutstandingWorkDisplayItem(
                        record: record,
                        job: linkedJob,
                        repairRequest: linkedRepair
                    )
                )
            }

            for job in VM.jobs where isOutstanding(job) {
                let key = "job-\(job.id)"
                guard !usedSourceKeys.contains(key) else { continue }
                usedSourceKeys.insert(key)
                items.append(CustomerOutstandingWorkDisplayItem(job: job))
            }

            for repair in VM.repairRequest where isOpenRepairRequest(repair) {
                let key = "repair-\(repair.id)"
                guard !usedSourceKeys.contains(key) else { continue }
                usedSourceKeys.insert(key)
                items.append(CustomerOutstandingWorkDisplayItem(repairRequest: repair))
            }

            return items.sorted { $0.date > $1.date }
        }

        private func isOutstanding(_ job: Job) -> Bool {
            let closedBillingStatuses: Set<JobBillingStatus> = [.invoiced, .paid, .comped]
            return job.operationStatus != .finished && !closedBillingStatuses.contains(job.billingStatus)
        }

        private func isOpenRepairRequest(_ repair: RepairRequest) -> Bool {
            ![RepairRequestStatus.resolved, .convertedToJob, .cancelled].contains(repair.status)
        }

        private func saveCustomerNote() async {
            let trimmedNote = customerNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedNote.isEmpty else { return }

            guard let company = masterDataManager.currentCompany, let customer else {
                alertMessage = "Select a customer before adding a note."
                showAlert = true
                return
            }

            let userId = masterDataManager.user?.id ?? ""
            guard !userId.isEmpty else {
                alertMessage = "Sign in before adding a note."
                showAlert = true
                return
            }

            isSavingCustomerNote = true
            defer { isSavingCustomerNote = false }

            do {
                try await VM.addCustomerNote(
                    companyId: company.id,
                    customer: customer,
                    bodyOfWater: selectedNoteBodyOfWater,
                    note: trimmedNote,
                    authorId: userId,
                    authorName: currentUserDisplayName
                )

                customerNoteText = ""
            } catch {
                alertMessage = "Unable to save customer note."
                showAlert = true
                print("[CustomerUpcomingWork][saveCustomerNote] Error: \(error)")
            }
        }

        private func toggleCustomerNoteResolved(_ note: CustomerNote) async {
            guard let company = masterDataManager.currentCompany else { return }

            let userId = masterDataManager.user?.id ?? ""
            guard !userId.isEmpty else {
                alertMessage = "Sign in before updating a note."
                showAlert = true
                return
            }

            do {
                try await VM.setCustomerNoteResolved(
                    companyId: company.id,
                    customerId: customerId,
                    noteId: note.id,
                    resolved: !(note.resolved ?? false),
                    authorId: userId,
                    authorName: currentUserDisplayName
                )
            } catch {
                alertMessage = "Unable to update customer note."
                showAlert = true
                print("[CustomerUpcomingWork][toggleCustomerNoteResolved] Error: \(error)")
            }
        }

        var outstandingWork: some View {
            SectionCard(title: "Outstanding Work") {
                VStack(spacing: 12) {
                    if outstandingWorkItems.isEmpty {
                        Text("No outstanding work found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(outstandingWorkItems) { item in
                            if let job = item.job {
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                        CustomerOutstandingWorkRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedCategory = .jobs
                                        masterDataManager.selectedJob = job
                                    } label: {
                                        CustomerOutstandingWorkRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else if let repairRequest = item.repairRequest {
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.repairRequest(repairRequest: repairRequest, dataService: dataService)) {
                                        CustomerOutstandingWorkRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedCategory = .jobs
                                        masterDataManager.selectedRepairRequest = repairRequest
                                    } label: {
                                        CustomerOutstandingWorkRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                CustomerOutstandingWorkRow(item: item)
                            }
                        }
                    }
                }
            }
        }

        var customerNotes: some View {
            SectionCard(title: "Customer Notes") {
                VStack(alignment: .leading, spacing: 12) {
                    if !VM.customerBodiesOfWater.isEmpty {
                        Picker("Pool", selection: $selectedNoteBodyOfWaterId) {
                            Text("All pools").tag("")
                            ForEach(VM.customerBodiesOfWater) { bodyOfWater in
                                Text(bodyOfWater.name).tag(bodyOfWater.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    TextEditor(text: $customerNoteText)
                        .frame(minHeight: 84)
                        .padding(8)
                        .background(Color.primary.opacity(0.035))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )

                    HStack {
                        Spacer()
                        Button {
                            Task {
                                await saveCustomerNote()
                            }
                        } label: {
                            Label(isSavingCustomerNote ? "Saving" : "Save Note", systemImage: "paperplane.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSavingCustomerNote || customerNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Divider()

                    if VM.customerNotes.isEmpty {
                        Text("No customer notes yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(Array(VM.customerNotes.prefix(8))) { note in
                            CustomerNoteRow(note: note) {
                                Task {
                                    await toggleCustomerNoteResolved(note)
                                }
                            }
                        }
                    }
                }
            }
        }

        var recurringServiceStops: some View {
            SectionCard(
                title: "Recurring Service Stops",
                leadingButton: SectionIconButton(systemName: "square.and.pencil") {
                    self.editRSS.toggle()
                },
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addRSS.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.recurringServiceStops.isEmpty {
                        Text("No recurring service stops found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.recurringServiceStops) { RSS in
                            NavigationLink(
                                value: Route.recurringServiceStopDetail(
                                    dataService: dataService,
                                    recurringServiceStop: RSS
                                )
                            ) {
                                RecurringServiceStopSmallCardView(recurringServiceStop: RSS)
                                    .id(rssCardRefreshId(RSS))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .sheet(isPresented: $addRSS, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                NewSingleRecurringServiceStop(dataService: dataService, customerId: customerId)
            }
        }

        var repairRequests: some View {
            SectionCard(
                title: "Repair Requests",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addRepairRequest.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.repairRequest.isEmpty {
                        Text("No repair requests found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.repairRequest) { repair in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.repairRequest(repairRequest: repair, dataService: dataService)) {
                                    RepairRequestCardView(repairRequest: repair)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .jobs
                                    masterDataManager.selectedRepairRequest = repair
                                }) {
                                    RepairRequestCardView(repairRequest: repair)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $addRepairRequest, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                AddNewRepairRequest(
                    dataService: dataService,
                    isPresented: $addRepairRequest,
                    customer: customer
                )
            }
        }

        var jobs: some View {
            SectionCard(
                title: "Jobs",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addJob.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.jobs.isEmpty {
                        Text("No jobs found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.jobs) { job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .jobs
                                    masterDataManager.selectedJob = job
                                }) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $addJob, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                AddNewJobView(dataService: dataService, customerId: customerId)
            }
        }

        var serviceStops: some View {
            SectionCard(
                title: "Service Stops",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addServiceStop.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.serviceStops.isEmpty {
                        Text("No service stops found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(Array(VM.serviceStops.prefix(4))) { ss in
                            NavigationLink(value: Route.serviceStop(serviceStop: ss, dataService: dataService)) {
                                ServiceStopCardViewLarge(serviceStop: ss)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .sheet(isPresented: $addServiceStop, onDismiss: {
                Task {
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await VM.reloadShoppingListItem(
                                companyId: company.id,
                                customerId: customerId
                            )
                        } catch {
                            print(error)
                        }
                    }
                }
            }) {
                AddNewServiceStop(dataService: dataService)
            }
        }

        func rssCardRefreshId(_ rss: RecurringServiceStop) -> String {
            [
                rss.id,
                rss.tech,
                rss.techId,
                rss.day.rawValue,
                rss.frequency.rawValue,
                rss.description,
                String(rss.noEndDate),
                String(rss.endDate?.timeIntervalSince1970 ?? 0)
            ].joined(separator: "_")
        }
    }

    // MARK: - Reusable UI

    private struct SectionCard<Content: View>: View {
        let title: String
        var leadingButton: AnyView? = nil
        var trailingButton: AnyView? = nil
        let content: Content

        init(
            title: String,
            leadingButton: AnyView? = nil,
            trailingButton: AnyView? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.leadingButton = leadingButton
            self.trailingButton = trailingButton
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                header
                content
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
        }

        private var header: some View {
            HStack(spacing: 10) {
                if let leadingButton {
                    leadingButton
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if let trailingButton {
                    trailingButton
                }
            }
            .padding(.bottom, 2)
        }
    }

    private func SectionIconButton(systemName: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        )
    }

    private enum CustomerOutstandingWorkKind {
        case persisted
        case job
        case repairRequest
    }

    private struct CustomerOutstandingWorkDisplayItem: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let detail: String
        let status: String
        let date: Date
        let kind: CustomerOutstandingWorkKind
        let job: Job?
        let repairRequest: RepairRequest?

        init(record: CustomerOutstandingWork, job: Job?, repairRequest: RepairRequest?) {
            let status = record.displayStatus
            let detail = [record.displayDetail, record.reason ?? ""]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            let subtitle = [
                record.bodyOfWaterName,
                record.serviceLocationName,
                record.adminName
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " • ")

            self.id = "outstanding-record-\(record.id)"
            self.title = record.displayTitle
            self.subtitle = subtitle
            self.detail = detail
            self.status = status
            self.date = record.displayDate
            self.kind = .persisted
            self.job = job
            self.repairRequest = repairRequest
        }

        init(job: Job) {
            self.id = "outstanding-job-\(job.id)"
            self.title = job.type.isEmpty ? "Work order" : job.type
            self.subtitle = [job.adminName, job.operationStatus.rawValue]
                .filter { !$0.isEmpty }
                .joined(separator: " • ")
            self.detail = job.description
            self.status = job.billingStatus.rawValue
            self.date = job.dateCreated
            self.kind = .job
            self.job = job
            self.repairRequest = nil
        }

        init(repairRequest: RepairRequest) {
            self.id = "outstanding-repair-\(repairRequest.id)"
            self.title = "Repair request"
            self.subtitle = [repairRequest.requesterName, repairRequest.status.rawValue]
                .filter { !$0.isEmpty }
                .joined(separator: " • ")
            self.detail = repairRequest.description
            self.status = repairRequest.status.rawValue
            self.date = repairRequest.date
            self.kind = .repairRequest
            self.job = nil
            self.repairRequest = repairRequest
        }

        var accentColor: Color {
            let normalizedStatus = status.lowercased()
            if normalizedStatus.contains("reject") {
                return .red
            }

            if normalizedStatus.contains("expired") {
                return .orange
            }

            switch kind {
            case .persisted:
                return .orange
            case .job:
                return .purple
            case .repairRequest:
                return .blue
            }
        }

        var systemImage: String {
            switch kind {
            case .persisted:
                return "exclamationmark.circle"
            case .job:
                return "briefcase"
            case .repairRequest:
                return "wrench.and.screwdriver"
            }
        }
    }

    private struct CustomerOutstandingWorkRow: View {
        let item: CustomerOutstandingWorkDisplayItem

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.accentColor.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.accentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(item.status)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(item.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(item.accentColor.opacity(0.12))
                            )
                    }

                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
        }
    }

    private struct CustomerNoteRow: View {
        let note: CustomerNote
        let toggleResolved: () -> Void

        private var isResolved: Bool {
            note.resolved ?? false
        }

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Button(action: toggleResolved) {
                    Image(systemName: isResolved ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isResolved ? Color.green : Color.secondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(note.displayAuthor)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)

                        Spacer(minLength: 8)

                        Text(isResolved ? "Resolved" : "Open")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isResolved ? Color.green : Color.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill((isResolved ? Color.green : Color.orange).opacity(0.12))
                            )
                    }

                    Label(note.displayAudience.title, systemImage: note.displayAudience.systemImage)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let bodyOfWaterName = note.bodyOfWaterName, !bodyOfWaterName.isEmpty {
                        Label(bodyOfWaterName, systemImage: "drop.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(note.displayDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(note.displayText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(4)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
        }
    }
