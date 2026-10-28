import SwiftUI

struct JobListView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @StateObject private var listVM: JobListViewModel
    @State private var showFilters = false
    @State private var showCreateJobOptions = false
    @State private var showCreateBlankJob = false
    @State private var showCreateFromTemplate = false

    init(dataService: any ProductionDataServiceProtocol, initialMode: JobListMode = .operations) {
        _listVM = StateObject(wrappedValue: JobListViewModel(mode: initialMode))
    }

    private var regionalAccessEnabled: Bool {
        // The web's customer-area filtering flag is also feature_flag_014.
        masterDataManager.featureFlagsLoaded && masterDataManager.isFeatureEnabled(.iosReimaginedMain)
    }

    private var displayedJobs: [Job] { listVM.displayedJobs(regionalAccessEnabled: regionalAccessEnabled) }

    private var requiredData: [String] {
        regionalAccessEnabled ? ["jobs", "customers", "access", "role"] : ["jobs"]
    }

    private var loadError: String? {
        requiredData.compactMap { listVM.errors[$0] }.first
    }

    var body: some View {
        VStack(spacing: 0) {
            listHeader
            if masterDataManager.currentCompany == nil {
                ContentUnavailableView("Select a company", systemImage: "building.2")
            } else if let error = loadError {
                ContentUnavailableView {
                    Label("Jobs unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again", action: reloadJobs)
                }
            } else if !masterDataManager.featureFlagsLoaded || !requiredData.allSatisfy({ listVM.loaded.contains($0) }) {
                ProgressView("Loading jobs…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if displayedJobs.isEmpty {
                            ContentUnavailableView("No matching jobs", systemImage: "briefcase", description: Text("Try changing your filters or search."))
                        }
                        ForEach(displayedJobs) { job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button { masterDataManager.selectedJob = job } label: {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(14)
                }
                .refreshable { reloadJobs() }
            }
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle(listVM.filters.mode == .billing ? "Billable Jobs" : "Job List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showFilters = true } label: {
                    Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
                }
                NavigationLink(value: Route.jobTemplates(dataService: dataService)) {
                    Label("Job Templates", systemImage: "square.stack.3d.up")
                }
                if masterDataManager.role?.canCreateAnyJob == true {
                    Button { showCreateJobOptions = true } label: {
                        Label("Create Job", systemImage: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) { jobFilterSheet }
        .sheet(isPresented: $showCreateJobOptions) {
            createJobOptionsSheet.presentationDetents([.medium])
        }
        .sheet(isPresented: $showCreateBlankJob, onDismiss: reloadJobs) {
            AddNewJobView(dataService: dataService, customerId: nil,
                          canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true)
        }
        .sheet(isPresented: $showCreateFromTemplate, onDismiss: reloadJobs) {
            if let company = masterDataManager.currentCompany {
                JobTemplatePickerCreateJobSheet(companyId: company.id, dataService: dataService,
                    canScheduleServiceStopsForOthers: masterDataManager.role?.canScheduleServiceStopsForOthers == true)
                    .presentationDetents([.large])
            }
        }
        .task(id: "\(masterDataManager.currentCompany?.id ?? "")|\(masterDataManager.user?.id ?? "")") {
            if !masterDataManager.featureFlagsLoaded { await masterDataManager.loadFeatureFlags() }
            guard !Task.isCancelled else { return }
            reloadJobs()
        }
        .onDisappear { listVM.stop() }
        .onChange(of: listVM.selectedRegionTag) { _ in listVM.saveRegionTag() }
        .onChange(of: masterDataManager.selectedID) { id in
            guard let id, let companyId = masterDataManager.currentCompany?.id else { return }
            Task {
                if let job = try? await dataService.getWorkOrderById(companyId: companyId, workOrderId: id) {
                    masterDataManager.selectedJob = job
                }
            }
        }
    }

    private var listHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Job list", selection: Binding(get: { listVM.filters.mode }, set: { listVM.filters.selectMode($0) })) {
                ForEach(JobListMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            .pickerStyle(.segmented)

            if !listVM.filters.usesDefaultStatusesAndPriorities {
                Button("Use default filters") { listVM.filters.selectMode(listVM.filters.mode) }
                    .font(.caption.weight(.semibold))
            }

            HStack {
                Button("Assigned to me") {
                    listVM.filters.adminFilterActive = true
                    listVM.filters.adminIds = listVM.currentAdminIds
                }
                .tint(assignedToMe ? .poolBlue : .secondary)
                Button("Company wide") {
                    listVM.filters.adminFilterActive = false
                    listVM.filters.adminIds = []
                }
                .tint(listVM.filters.adminFilterActive ? .secondary : .poolBlue)
                Spacer()
            }
            .buttonStyle(.bordered)
            .font(.caption.weight(.semibold))

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search jobs", text: $listVM.filters.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !listVM.filters.search.isEmpty {
                    Button { listVM.filters.search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Clear search")
                }
            }
            .padding(10)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))

            Text("\(displayedJobs.count) jobs • \(listVM.filters.mode == .billing ? "Finished not invoiced" : "Operations") • \(adminScope) • \(listVM.filters.usesDefaultStatusesAndPriorities ? "Default filters" : "Custom filters")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial)
    }

    private var assignedToMe: Bool {
        listVM.filters.adminFilterActive && !listVM.currentAdminIds.isEmpty && listVM.filters.adminIds == listVM.currentAdminIds
    }

    private var adminScope: String {
        if !listVM.filters.adminFilterActive { return "Company wide" }
        if assignedToMe { return "Assigned to me" }
        if listVM.filters.adminIds.isEmpty { return "No admins selected" }
        return "\(listVM.filters.adminIds.count) admins selected"
    }

    private var jobFilterSheet: some View {
        DripDropFilterSheet(title: "Filter & Sort", isPresented: $showFilters, isResetDisabled: false, onReset: resetFilters) {
            DripDropFilterSummaryCard(title: "\(displayedJobs.count) jobs showing", subtitle: adminScope,
                                      systemImage: "briefcase.fill", tint: .poolBlue)
            sortSection
            prioritySection
            operationSection
            billingSection
            adminSection
            if regionalAccessEnabled { regionSection }
        }
        .presentationDetents([.large])
    }

    private var sortSection: some View {
        DripDropFilterSection(title: "Sort", systemImage: "arrow.up.arrow.down", tint: .poolBlue) {
            Picker("Sort by", selection: $listVM.filters.sortField) {
                ForEach(JobListSortField.allCases) { field in Text(field.rawValue).tag(field) }
            }
            .onChange(of: listVM.filters.sortField) { field in listVM.filters.ascending = field.defaultsAscending }
            Toggle("Ascending", isOn: $listVM.filters.ascending)
        }
    }

    private var prioritySection: some View {
        DripDropFilterSection(title: "Priority", systemImage: "exclamationmark.circle", tint: .orange) {
            selectionActions(selectAll: { listVM.filters.priorities = Set(JobIssuePriorityLevel.allCases.map(\.rawValue)) }, clear: { listVM.filters.priorities = [] })
            ForEach(JobIssuePriorityLevel.allCases) { priority in
                Toggle(priority.label, isOn: selectionBinding($listVM.filters.priorities, value: priority.rawValue))
            }
        }
    }

    private var operationSection: some View {
        DripDropFilterSection(title: "Operation Status", systemImage: "checklist", tint: .poolBlue) {
            Text("No statuses selected includes any operation status.").font(.caption).foregroundStyle(.secondary)
            selectionActions(selectAll: { listVM.filters.operationStatuses = Set(JobOperationStatus.allCases) }, clear: { listVM.filters.operationStatuses = [] })
            ForEach(JobOperationStatus.allCases, id: \.self) { status in
                Toggle(status.rawValue, isOn: selectionBinding($listVM.filters.operationStatuses, value: status))
            }
        }
    }

    private var billingSection: some View {
        DripDropFilterSection(title: "Billing Status", systemImage: "creditcard", tint: .poolGreen) {
            Text("No statuses selected includes any billing status.").font(.caption).foregroundStyle(.secondary)
            selectionActions(selectAll: { listVM.filters.billingStatuses = Set(JobBillingStatus.allCases) }, clear: { listVM.filters.billingStatuses = [] })
            ForEach(JobBillingStatus.allCases, id: \.self) { status in
                Toggle(status.rawValue, isOn: selectionBinding($listVM.filters.billingStatuses, value: status))
            }
        }
    }

    private var adminSection: some View {
        DripDropFilterSection(title: "Admins", systemImage: "person.2", tint: .poolGreen) {
            selectionActions(selectAll: {
                listVM.filters.adminFilterActive = false
                listVM.filters.adminIds = []
            }, clear: {
                listVM.filters.adminFilterActive = true
                listVM.filters.adminIds = []
            })
            Text(adminScope).font(.caption).foregroundStyle(.secondary)
            if let error = listVM.errors["admins"] {
                Text(error).foregroundStyle(.secondary)
                Button("Try again", action: reloadJobs)
            } else if !listVM.loaded.contains("admins") {
                ProgressView("Loading admins…")
            }
            ForEach(listVM.admins) { admin in
                Toggle(admin.name, isOn: Binding(get: {
                    !listVM.filters.adminFilterActive || listVM.filters.adminIds.contains(admin.id)
                }, set: { selected in
                    var ids = listVM.filters.adminFilterActive ? listVM.filters.adminIds : Set(listVM.admins.map(\.id))
                    if selected { ids.insert(admin.id) } else { ids.remove(admin.id) }
                    listVM.filters.adminIds = ids
                    listVM.filters.adminFilterActive = ids != Set(listVM.admins.map(\.id))
                }))
            }
        }
    }

    private var regionSection: some View {
        DripDropFilterSection(title: "Customer Area", systemImage: "tag", tint: .poolBlue) {
            Picker("Area", selection: $listVM.selectedRegionTag) {
                Text("All allowed areas").tag("")
                ForEach(listVM.availableRegionTags, id: \.self) { tag in Text(tag).tag(tag) }
                if !listVM.selectedRegionTag.isEmpty && !listVM.availableRegionTags.contains(listVM.selectedRegionTag) {
                    Text(listVM.selectedRegionTag).tag(listVM.selectedRegionTag)
                }
            }
        }
    }

    private func selectionActions(selectAll: @escaping () -> Void, clear: @escaping () -> Void) -> some View {
        HStack {
            Button("Select all", action: selectAll)
            Spacer()
            Button("Clear", action: clear)
        }
        .font(.caption.weight(.semibold))
    }

    private func selectionBinding<Value: Hashable>(_ selection: Binding<Set<Value>>, value: Value) -> Binding<Bool> {
        Binding(get: { selection.wrappedValue.contains(value) }, set: { selected in
            if selected { selection.wrappedValue.insert(value) } else { selection.wrappedValue.remove(value) }
        })
    }

    private func resetFilters() {
        let mode = listVM.filters.mode
        listVM.filters = JobListFilters()
        listVM.filters.selectMode(mode)
        listVM.selectedRegionTag = ""
    }

    private func reloadJobs() {
        listVM.start(companyId: masterDataManager.currentCompany?.id ?? "", userId: masterDataManager.user?.id ?? "")
    }

    // MARK: createJobOptionsSheet
    var createJobOptionsSheet: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Create Job")
                                    .font(.title3.weight(.semibold))

                                Text(masterDataManager.role?.canCreateBlankJob == true ? "Start blank or use a reusable template." : "Use a reusable job template.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial, in: Circle())
                        }
                    }
                    .jobCreateOptionCard()

                    if masterDataManager.role?.canCreateBlankJob == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateBlankJob = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "Blank Job",
                                subtitle: "Build a job manually from scratch.",
                                systemImage: "doc.badge.plus"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if masterDataManager.role?.canCreateJobFromTemplate == true {
                        Button {
                            showCreateJobOptions = false

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showCreateFromTemplate = true
                            }
                        } label: {
                            jobCreateOptionRow(
                                title: "From Template",
                                subtitle: "Create a job using planned stops, tasks, materials, and pricing.",
                                systemImage: "square.stack.3d.up"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(14)
            }
            .navigationTitle("New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCreateJobOptions = false
                    }
                }
            }
        }
    }
        // MARK: jobCreateOptionRow

    func jobCreateOptionRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
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
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

}

//MARK: Extension View
private extension View {
    func jobCreateOptionCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            )
    }
}
