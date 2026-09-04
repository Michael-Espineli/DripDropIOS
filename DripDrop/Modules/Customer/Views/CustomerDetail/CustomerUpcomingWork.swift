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
    import FirebaseFirestore
    import FirebaseFirestoreSwift

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
        @State private var selectedNoteAudience: CustomerNoteAudience = .office
        @State private var selectedNoteFilter: CustomerNoteAudienceFilter = .all
        @State private var isSavingCustomerNote: Bool = false
        @State private var showAllCustomerNotes: Bool = false
        @FocusState private var isCustomerNoteTextFocused: Bool

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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        isCustomerNoteTextFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .accessibilityLabel("Dismiss keyboard")
                }
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

        private var unresolvedCustomerNotesCount: Int {
            VM.customerNotes.filter { !($0.resolved ?? false) }.count
        }

        private var filteredCustomerNotes: [CustomerNote] {
            VM.customerNotes.filter { selectedNoteFilter.matches($0) }
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
                    audience: selectedNoteAudience,
                    authorId: userId,
                    authorName: currentUserDisplayName
                )

                customerNoteText = ""
                selectedNoteAudience = .office
                isCustomerNoteTextFocused = false
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
                VStack(spacing: 8) {
                    if outstandingWorkItems.isEmpty {
                        CompactEmptyState(
                            title: "No outstanding work found.",
                            systemImage: "checkmark.circle"
                        )
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
            SectionCard(
                title: "Customer Notes",
                badgeCount: unresolvedCustomerNotesCount
            ) {
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

                    Picker("Audience", selection: $selectedNoteAudience) {
                        ForEach(CustomerNoteAudience.allCases) { audience in
                            Label(audience.title, systemImage: audience.systemImage)
                                .tag(audience)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextEditor(text: $customerNoteText)
                        .frame(minHeight: 84)
                        .padding(8)
                        .focused($isCustomerNoteTextFocused)
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
                        CompactEmptyState(
                            title: "No customer notes yet.",
                            systemImage: "text.bubble"
                        )
                    } else {
                        Picker("Filter", selection: $selectedNoteFilter) {
                            ForEach(CustomerNoteAudienceFilter.allCases) { filter in
                                Label(filter.title, systemImage: filter.systemImage)
                                    .tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)

                        if filteredCustomerNotes.isEmpty {
                            CompactEmptyState(
                                title: "No notes for this filter.",
                                systemImage: selectedNoteFilter.systemImage
                            )
                        } else {
                            ForEach(Array(filteredCustomerNotes.prefix(3))) { note in
                                CustomerNoteRow(note: note) {
                                    Task {
                                        await toggleCustomerNoteResolved(note)
                                    }
                                }
                            }
                        }

                        Button {
                            showAllCustomerNotes = true
                        } label: {
                            HStack {
                                Text("View All Notes")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(Color.poolBlue)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .sheet(isPresented: $showAllCustomerNotes) {
                if let companyId = masterDataManager.currentCompany?.id {
                    CustomerNotesPagedSheet(
                        dataService: dataService,
                        companyId: companyId,
                        customerId: customerId,
                        unresolvedCount: unresolvedCustomerNotesCount,
                        initialFilter: selectedNoteFilter,
                        currentUserId: masterDataManager.user?.id ?? "",
                        currentUserName: currentUserDisplayName
                    )
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
                VStack(spacing: 8) {
                    if VM.recurringServiceStops.isEmpty {
                        CompactEmptyState(
                            title: "No recurring service stops found.",
                            systemImage: "repeat"
                        )
                    } else {
                        ForEach(VM.recurringServiceStops) { RSS in
                            NavigationLink(
                                value: Route.recurringServiceStopDetail(
                                    dataService: dataService,
                                    recurringServiceStop: RSS
                                )
                            ) {
                                CustomerRecurringServiceStopRow(recurringServiceStop: RSS)
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
                VStack(spacing: 8) {
                    if VM.repairRequest.isEmpty {
                        CompactEmptyState(
                            title: "No repair requests found.",
                            systemImage: "wrench.and.screwdriver"
                        )
                    } else {
                        ForEach(VM.repairRequest) { repair in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.repairRequest(repairRequest: repair, dataService: dataService)) {
                                    CustomerRepairRequestRow(repairRequest: repair)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .jobs
                                    masterDataManager.selectedRepairRequest = repair
                                }) {
                                    CustomerRepairRequestRow(repairRequest: repair)
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
                VStack(spacing: 8) {
                    if VM.jobs.isEmpty {
                        CompactEmptyState(
                            title: "No jobs found.",
                            systemImage: "briefcase"
                        )
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
                VStack(spacing: 8) {
                    if VM.serviceStops.isEmpty {
                        CompactEmptyState(
                            title: "No service stops found.",
                            systemImage: "checklist"
                        )
                    } else {
                        ForEach(Array(VM.serviceStops.prefix(4))) { ss in
                            NavigationLink(value: Route.serviceStop(serviceStop: ss, dataService: dataService)) {
                                CustomerServiceStopRow(serviceStop: ss)
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

    private enum CustomerNoteAudienceFilter: String, CaseIterable, Identifiable {
        case all
        case office
        case field

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all:
                return "All"
            case .office:
                return "Office"
            case .field:
                return "Field"
            }
        }

        var systemImage: String {
            switch self {
            case .all:
                return "text.bubble"
            case .office:
                return CustomerNoteAudience.office.systemImage
            case .field:
                return CustomerNoteAudience.field.systemImage
            }
        }

        func matches(_ note: CustomerNote) -> Bool {
            switch self {
            case .all:
                return true
            case .office:
                return note.displayAudience == .office || note.displayAudience == .all
            case .field:
                return note.displayAudience == .field || note.displayAudience == .all
            }
        }
    }

    private struct SectionCard<Content: View>: View {
        let title: String
        var badgeCount: Int? = nil
        var leadingButton: AnyView? = nil
        var trailingButton: AnyView? = nil
        let content: Content

        init(
            title: String,
            badgeCount: Int? = nil,
            leadingButton: AnyView? = nil,
            trailingButton: AnyView? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.badgeCount = badgeCount
            self.leadingButton = leadingButton
            self.trailingButton = trailingButton
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                header
                content
            }
            .padding(12)
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

                if let badgeCount, badgeCount > 0 {
                    Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.poolRed, in: Capsule())
                }

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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        )
    }

    private struct CompactEmptyState: View {
        let title: String
        let systemImage: String

        var body: some View {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private struct CustomerRecurringServiceStopRow: View {
        let recurringServiceStop: RecurringServiceStop

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "repeat")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 26, height: 26)
                    .background(Color.poolBlue.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(recurringServiceStop.tech.isEmpty ? "No Technician" : recurringServiceStop.tech)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text("#\(recurringServiceStop.internalId)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 0)
                    }

                    Text("\(shortDate(date: recurringServiceStop.startDate)) to \(endDateText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("\(recurringServiceStop.frequency.rawValue) • \(recurringServiceStop.day.rawValue)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if !recurringServiceStop.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(recurringServiceStop.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 5)
            }
            .padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
        }

        var endDateText: String {
            if recurringServiceStop.noEndDate {
                return "No end date"
            }

            if let endDate = recurringServiceStop.endDate {
                return shortDate(date: endDate)
            }

            return "No end date"
        }
    }

    private struct CustomerServiceStopRow: View {
        let serviceStop: ServiceStop

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: serviceStop.typeImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 26, height: 26)
                    .background(Color.poolBlue.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(serviceStop.type.isEmpty ? "Service Stop" : serviceStop.type)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(fullDateAndDay(date: serviceStop.serviceDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if !serviceStop.tech.isEmpty {
                        Text("Tech: \(serviceStop.tech)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 5)
            }
            .padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
        }
    }

    private struct CustomerRepairRequestRow: View {
        let repairRequest: RepairRequest

        var body: some View {
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(statusColor)
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 26, height: 26)
                    .background(statusColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(repairRequest.description.isEmpty ? "Repair Request" : repairRequest.description)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Text(repairRequest.status.displayName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.12), in: Capsule())
                    }

                    HStack(spacing: 6) {
                        if !repairRequest.requesterName.isEmpty {
                            Text(repairRequest.requesterName)
                        }

                        if !repairRequest.requesterName.isEmpty {
                            Text("•")
                        }

                        Text(fullDate(date: repairRequest.date))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
        }

        private var statusColor: Color {
            switch repairRequest.status {
            case .resolved:
                return Color.poolGreen
            case .unresolved, .cancelled, .legacyPending, .legacyPendingCapitalized:
                return Color.poolRed
            case .convertedToJob:
                return Color.gray
            case .inprogress:
                return Color.yellow
            }
        }
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
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(item.accentColor.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: item.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
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
            .padding(10)
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

    @MainActor
    private final class CustomerNotesPagedViewModel: ObservableObject {
        @Published private(set) var notes: [CustomerNote] = []
        @Published private(set) var loadedNotesCount = 0
        @Published private(set) var isLoadingPage = false
        @Published private(set) var hasMoreNotes = true
        @Published var alertMessage = ""
        @Published var showAlert = false

        private let dataService: any ProductionDataServiceProtocol
        private let companyId: String
        private let customerId: String
        private let pageSize = 5
        private var lastDocument: DocumentSnapshot? = nil
        private var loadedNotes: [CustomerNote] = []
        private var activeFilter: CustomerNoteAudienceFilter = .all

        init(
            dataService: any ProductionDataServiceProtocol,
            companyId: String,
            customerId: String
        ) {
            self.dataService = dataService
            self.companyId = companyId
            self.customerId = customerId
        }

        func loadFirstPage(matching filter: CustomerNoteAudienceFilter) async {
            applyFilter(filter)

            if loadedNotes.isEmpty {
                await loadNextVisiblePage(matching: filter)
            }
        }

        func loadNextVisiblePage(matching filter: CustomerNoteAudienceFilter) async {
            let targetCount = notes.count + pageSize

            repeat {
                await loadNextPage(matching: filter)
            } while hasMoreNotes && !isLoadingPage && notes.count < targetCount
        }

        func applyFilter(_ filter: CustomerNoteAudienceFilter) {
            activeFilter = filter
            notes = loadedNotes.filter { filter.matches($0) }
            loadedNotesCount = loadedNotes.count
        }

        private func loadNextPage(matching filter: CustomerNoteAudienceFilter) async {
            guard !isLoadingPage, hasMoreNotes else { return }

            isLoadingPage = true
            defer { isLoadingPage = false }

            do {
                let page = try await dataService.getCustomerNotesPage(
                    companyId: companyId,
                    customerId: customerId,
                    limit: pageSize,
                    lastDocument: lastDocument
                )

                let loadedIds = Set(loadedNotes.map(\.id))
                loadedNotes.append(contentsOf: page.notes.filter { !loadedIds.contains($0.id) })
                lastDocument = page.lastDocument
                hasMoreNotes = page.lastDocument != nil && page.notes.count == pageSize
                applyFilter(filter)
            } catch {
                alertMessage = "Unable to load more customer notes."
                showAlert = true
                hasMoreNotes = false
                print("[CustomerNotesPagedViewModel][loadNextPage] Error: \(error)")
            }
        }

        func toggleResolved(note: CustomerNote, authorId: String, authorName: String) async {
            guard !authorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                alertMessage = "Sign in before updating a note."
                showAlert = true
                return
            }

            let newResolvedValue = !(note.resolved ?? false)

            do {
                try await dataService.updateCustomerNoteResolved(
                    companyId: companyId,
                    customerId: customerId,
                    noteId: note.id,
                    resolved: newResolvedValue,
                    authorId: authorId,
                    authorName: authorName
                )

                if let index = loadedNotes.firstIndex(where: { $0.id == note.id }) {
                    loadedNotes[index].resolved = newResolvedValue
                    loadedNotes[index].updatedAt = Date()
                    loadedNotes[index].updatedAtMillis = Date().timeIntervalSince1970 * 1000
                    applyFilter(activeFilter)
                }
            } catch {
                alertMessage = "Unable to update customer note."
                showAlert = true
                print("[CustomerNotesPagedViewModel][toggleResolved] Error: \(error)")
            }
        }
    }

    private struct CustomerNotesPagedSheet: View {
        @Environment(\.dismiss) private var dismiss
        @StateObject private var VM: CustomerNotesPagedViewModel
        @State private var selectedFilter: CustomerNoteAudienceFilter

        let unresolvedCount: Int
        let currentUserId: String
        let currentUserName: String

        init(
            dataService: any ProductionDataServiceProtocol,
            companyId: String,
            customerId: String,
            unresolvedCount: Int,
            initialFilter: CustomerNoteAudienceFilter,
            currentUserId: String,
            currentUserName: String
        ) {
            _VM = StateObject(
                wrappedValue: CustomerNotesPagedViewModel(
                    dataService: dataService,
                    companyId: companyId,
                    customerId: customerId
                )
            )
            _selectedFilter = State(initialValue: initialFilter)
            self.unresolvedCount = unresolvedCount
            self.currentUserId = currentUserId
            self.currentUserName = currentUserName
        }

        var body: some View {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        header

                        if VM.notes.isEmpty && !VM.isLoadingPage {
                            VStack(alignment: .leading, spacing: 10) {
                                CompactEmptyState(
                                    title: selectedFilter == .all ? "No customer notes yet." : "No notes for this filter.",
                                    systemImage: selectedFilter.systemImage
                                )
                            }
                            .padding(12)
                            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(VM.notes) { note in
                                    CustomerNoteRow(note: note) {
                                        Task {
                                            await VM.toggleResolved(
                                                note: note,
                                                authorId: currentUserId,
                                                authorName: currentUserName
                                            )
                                        }
                                    }
                                    .onAppear {
                                        if VM.notes.last?.id == note.id {
                                            Task {
                                                await VM.loadNextVisiblePage(matching: selectedFilter)
                                            }
                                        }
                                    }
                                }

                                if VM.isLoadingPage {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .presentationDetents([.medium, .large])
            .task {
                await VM.loadFirstPage(matching: selectedFilter)
            }
            .onChange(of: selectedFilter) { _, newFilter in
                VM.applyFilter(newFilter)
                Task {
                    await VM.loadNextVisiblePage(matching: newFilter)
                }
            }
            .alert(VM.alertMessage, isPresented: $VM.showAlert) {
                Button("OK", role: .cancel) { }
            }
        }

        private var header: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.poolBlue)
                        .frame(width: 34, height: 34)
                        .background(Color.poolBlue.opacity(0.13), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text("Customer Notes")
                                .font(.headline.weight(.semibold))

                            if unresolvedCount > 0 {
                                Text(unresolvedCount > 99 ? "99+" : "\(unresolvedCount)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Color.poolRed, in: Capsule())
                            }
                        }

                        Text(VM.notes.count == 1 ? "1 note" : "\(VM.notes.count) notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(CustomerNoteAudienceFilter.allCases) { filter in
                        Label(filter.title, systemImage: filter.systemImage)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
