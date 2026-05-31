//
//  WorkTypeMappingSourceOption.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


import SwiftUI

// MARK: - Source Option

struct WorkTypeMappingSourceOption: Identifiable, Hashable {
    var id: String {
        sourceType.rawValue + "|" + sourceId
    }

    var sourceType: WorkTypeSource
    var sourceId: String
    var title: String
    var subtitle: String
    var systemImage: String
}

// MARK: - List Filter

enum WorkTypeMappingListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case serviceStops = "Stops"
    case tasks = "Tasks"
    case other = "Other"

    var id: String { rawValue }
}

// MARK: - Editor Route

struct WorkTypeMappingEditorRoute: Identifiable {
    let id = UUID()
    var mapping: WorkTypeMapping?
}

// MARK: - ViewModel

@MainActor
final class WorkTypeMappingsViewModel: ObservableObject {

    @Published var mappings: [WorkTypeMapping] = []
    @Published var workTypes: [CompanyWorkType] = []
    @Published var serviceStopTypes: [CompanyServiceStopType] = []

    @Published var selectedFilter: WorkTypeMappingListFilter = .all
    @Published var searchText: String = ""

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""


    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        dataService: any ProductionDataServiceProtocol
    ) {
        self.dataService = dataService
    }

    var activeWorkTypes: [CompanyWorkType] {
        workTypes
            .filter { $0.isActive }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    var workTypesById: [String: CompanyWorkType] {
        Dictionary(uniqueKeysWithValues: workTypes.map { ($0.id, $0) })
    }

    var serviceStopTypesById: [String: CompanyServiceStopType] {
        Dictionary(uniqueKeysWithValues: serviceStopTypes.map { ($0.id, $0) })
    }

    var serviceStopSourceOptions: [WorkTypeMappingSourceOption] {
        var options: [WorkTypeMappingSourceOption] = [
            WorkTypeMappingSourceOption(
                sourceType: .serviceStopType,
                sourceId: PayrollSystemSourceIds.recurringServiceStop,
                title: "Recurring Service Stop",
                subtitle: "Fallback for current recurring route stops",
                systemImage: "repeat"
            ),
            WorkTypeMappingSourceOption(
                sourceType: .serviceStopType,
                sourceId: PayrollSystemSourceIds.jobServiceStop,
                title: "Job Service Stop",
                subtitle: "Fallback for current job-based stops",
                systemImage: "briefcase"
            ),
            WorkTypeMappingSourceOption(
                sourceType: .serviceStopType,
                sourceId: PayrollSystemSourceIds.unknownServiceStop,
                title: "Unknown Service Stop",
                subtitle: "Fallback when stop type cannot be inferred",
                systemImage: "questionmark.circle"
            )
        ]

        let realServiceStopTypeOptions = serviceStopTypes
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }
            .map { type in
                WorkTypeMappingSourceOption(
                    sourceType: .serviceStopType,
                    sourceId: type.id,
                    title: type.name,
                    subtitle: "Company service stop type",
                    systemImage: type.imageName ?? "mappin.and.ellipse"
                )
            }

        options.append(contentsOf: realServiceStopTypeOptions)

        return options
    }

    var jobTaskSourceOptions: [WorkTypeMappingSourceOption] {
        JobTaskType.allCases.map { taskType in
            WorkTypeMappingSourceOption(
                sourceType: .jobTaskType,
                sourceId: taskType.rawValue,
                title: taskType.rawValue,
                subtitle: "ServiceStopTask.type",
                systemImage: "checklist"
            )
        }
    }

    var filteredMappings: [WorkTypeMapping] {
        let filteredByType: [WorkTypeMapping]

        switch selectedFilter {
        case .all:
            filteredByType = mappings
        case .serviceStops:
            filteredByType = mappings.filter { $0.sourceType == .serviceStopType }
        case .tasks:
            filteredByType = mappings.filter { $0.sourceType == .jobTaskType || $0.sourceType == .recurringServiceStopTaskType }
        case .other:
            filteredByType = mappings.filter {
                $0.sourceType == .bodyOfWaterType ||
                $0.sourceType == .serviceLocationType ||
                $0.sourceType == .manualTag
            }
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let searched: [WorkTypeMapping]

        if trimmedSearch.isEmpty {
            searched = filteredByType
        } else {
            searched = filteredByType.filter { mapping in
                let sourceTitle = sourceTitle(for: mapping)
                let workTypeName = workTypesById[mapping.workTypeId]?.name ?? ""

                return sourceTitle.localizedCaseInsensitiveContains(trimmedSearch) ||
                mapping.sourceId.localizedCaseInsensitiveContains(trimmedSearch) ||
                mapping.sourceType.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                workTypeName.localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        return searched.sorted { left, right in
            if left.sourceType.title == right.sourceType.title {
                return sourceTitle(for: left) < sourceTitle(for: right)
            }

            return left.sourceType.title < right.sourceType.title
        }
    }

    var serviceStopMappingCount: Int {
        mappings.filter { $0.sourceType == .serviceStopType }.count
    }

    var taskMappingCount: Int {
        mappings.filter { $0.sourceType == .jobTaskType || $0.sourceType == .recurringServiceStopTaskType }.count
    }

    var missingWorkTypeCount: Int {
        mappings.filter { workTypesById[$0.workTypeId] == nil }.count
    }

    func load(companyId:String,forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let mappingsTask = dataService.fetchWorkTypeMappings(companyId: companyId)
            async let workTypesTask = dataService.fetchCompanyWorkTypes(companyId: companyId)
            async let serviceStopTypesTask = dataService.fetchCompanyServiceStopTypes(companyId: companyId)

            mappings = try await mappingsTask
            workTypes = try await workTypesTask
            serviceStopTypes = try await serviceStopTypesTask
        } catch {
            alertMessage = "Could not load work type mappings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func save(companyId:String,_ mapping: WorkTypeMapping) async {
        let validation = validate(companyId:companyId,mapping)

        guard validation.isValid else {
            alertMessage = validation.message
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.saveWorkTypeMapping(mapping)
            upsertLocal(mapping)
        } catch {
            alertMessage = "Could not save mapping. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func delete(_ mapping: WorkTypeMapping) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.deleteWorkTypeMapping(
                companyId: mapping.companyId,
                mappingId: mapping.id
            )

            mappings.removeAll { $0.id == mapping.id }
        } catch {
            alertMessage = "Could not delete mapping. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func seedSuggestedDefaults(companyId:String) async {
        guard !activeWorkTypes.isEmpty else {
            alertMessage = "Create company work types before seeding mappings."
            showAlert = true
            return
        }

        var newMappings: [WorkTypeMapping] = []

        func appendMappingIfPossible(
            sourceType: WorkTypeSource,
            sourceId: String,
            candidateNames: [String],
            category: WorkCategory?
        ) {
            guard let workType = bestWorkType(
                candidateNames: candidateNames,
                category: category
            ) else {
                return
            }

            let mapping = WorkTypeMapping(
                id: PayrollIdFactory.workTypeMappingId(),
                companyId: companyId,
                sourceType: sourceType,
                sourceId: sourceId,
                workTypeId: workType.id
            )

            if canAddSeedMapping(mapping) {
                newMappings.append(mapping)
            }
        }

        // Current service stop fallbacks.
        appendMappingIfPossible(
            sourceType: .serviceStopType,
            sourceId: PayrollSystemSourceIds.recurringServiceStop,
            candidateNames: ["Routes", "Route", "Weekly Route"],
            category: .route
        )

        appendMappingIfPossible(
            sourceType: .serviceStopType,
            sourceId: PayrollSystemSourceIds.jobServiceStop,
            candidateNames: ["Service Call", "Job", "Job Visit", "Repair"],
            category: .serviceCall
        )

        // Payable task types.
        appendMappingIfPossible(
            sourceType: .jobTaskType,
            sourceId: JobTaskType.cleanFilter.rawValue,
            candidateNames: ["Clean Filter", "Filter Cleaning", "Filter Clean"],
            category: .cleaning
        )

        appendMappingIfPossible(
            sourceType: .jobTaskType,
            sourceId: JobTaskType.repair.rawValue,
            candidateNames: ["Repair", "Repairs"],
            category: .repair
        )

        appendMappingIfPossible(
            sourceType: .jobTaskType,
            sourceId: JobTaskType.install.rawValue,
            candidateNames: ["Installation", "Install"],
            category: .installation
        )

        appendMappingIfPossible(
            sourceType: .jobTaskType,
            sourceId: JobTaskType.replace.rawValue,
            candidateNames: ["Repair", "Replacement", "Replace"],
            category: .repair
        )

        appendMappingIfPossible(
            sourceType: .jobTaskType,
            sourceId: JobTaskType.emptyWater.rawValue,
            candidateNames: ["Drain / Refill", "Drain Refill", "Pool Refill and Drain"],
            category: .drainAndRefill
        )

        guard !newMappings.isEmpty else {
            alertMessage = "No new suggested mappings were found. You may already have them, or the matching work types do not exist yet."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            for mapping in newMappings {
                try await dataService.saveWorkTypeMapping(mapping)
            }

            mappings.append(contentsOf: newMappings)

            alertMessage = "Added \(newMappings.count) suggested mappings."
            showAlert = true
        } catch {
            alertMessage = "Could not add suggested mappings. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func sourceTitle(for mapping: WorkTypeMapping) -> String {
        switch mapping.sourceType {
        case .serviceStopType:
            if mapping.sourceId == PayrollSystemSourceIds.recurringServiceStop {
                return "Recurring Service Stop"
            }

            if mapping.sourceId == PayrollSystemSourceIds.jobServiceStop {
                return "Job Service Stop"
            }

            if mapping.sourceId == PayrollSystemSourceIds.unknownServiceStop {
                return "Unknown Service Stop"
            }

            return serviceStopTypesById[mapping.sourceId]?.name ?? mapping.sourceId

        case .jobTaskType:
            return mapping.sourceId

        case .recurringServiceStopTaskType:
            return mapping.sourceId

        case .bodyOfWaterType:
            return mapping.sourceId

        case .serviceLocationType:
            return mapping.sourceId

        case .manualTag:
            return mapping.sourceId
        }
    }

    func workTypeTitle(for mapping: WorkTypeMapping) -> String {
        workTypesById[mapping.workTypeId]?.name ?? "Missing Work Type"
    }

    func workTypeIconName(for mapping: WorkTypeMapping) -> String {
        guard let workType = workTypesById[mapping.workTypeId] else {
            return "exclamationmark.triangle"
        }

        if let iconName = workType.iconName,
           !iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return iconName
        }

        return workType.category.defaultIconName
    }

    private func validate(companyId:String,_ mapping: WorkTypeMapping) -> (isValid: Bool, message: String) {
        guard mapping.companyId == companyId else {
            return (false, "Mapping company ID does not match the current company.")
        }

        guard !mapping.sourceId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "Source ID is required.")
        }

        guard workTypesById[mapping.workTypeId] != nil else {
            return (false, "Select a valid company work type.")
        }

        let exactDuplicate = mappings.contains {
            $0.id != mapping.id &&
            $0.sourceType == mapping.sourceType &&
            $0.sourceId == mapping.sourceId &&
            $0.workTypeId == mapping.workTypeId
        }

        guard !exactDuplicate else {
            return (false, "This exact mapping already exists.")
        }

        if !mapping.sourceType.allowsMultipleMappingsPerSource {
            let existingSameSource = mappings.first {
                $0.id != mapping.id &&
                $0.sourceType == mapping.sourceType &&
                $0.sourceId == mapping.sourceId
            }

            if let existingSameSource {
                let existingWorkTypeName = workTypesById[existingSameSource.workTypeId]?.name ?? "another work type"
                return (
                    false,
                    "\(mapping.sourceType.title) '\(mapping.sourceId)' is already mapped to \(existingWorkTypeName). Edit the existing mapping instead."
                )
            }
        }

        return (true, "")
    }

    private func upsertLocal(_ mapping: WorkTypeMapping) {
        if let index = mappings.firstIndex(where: { $0.id == mapping.id }) {
            mappings[index] = mapping
        } else {
            mappings.append(mapping)
        }
    }

    private func canAddSeedMapping(_ mapping: WorkTypeMapping) -> Bool {
        let exactExists = mappings.contains {
            $0.sourceType == mapping.sourceType &&
            $0.sourceId == mapping.sourceId &&
            $0.workTypeId == mapping.workTypeId
        }

        if exactExists {
            return false
        }

        if !mapping.sourceType.allowsMultipleMappingsPerSource {
            let sourceAlreadyMapped = mappings.contains {
                $0.sourceType == mapping.sourceType &&
                $0.sourceId == mapping.sourceId
            }

            if sourceAlreadyMapped {
                return false
            }
        }

        return true
    }

    private func bestWorkType(
        candidateNames: [String],
        category: WorkCategory?
    ) -> CompanyWorkType? {
        for candidateName in candidateNames {
            if let exact = activeWorkTypes.first(where: {
                normalized($0.name) == normalized(candidateName)
            }) {
                return exact
            }
        }

        for candidateName in candidateNames {
            if let contains = activeWorkTypes.first(where: {
                normalized($0.name).contains(normalized(candidateName)) ||
                normalized(candidateName).contains(normalized($0.name))
            }) {
                return contains
            }
        }

        if let category {
            return activeWorkTypes.first { $0.category == category }
        }

        return nil
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "&", with: "and")
    }
}

// MARK: - View

struct WorkTypeMappingsView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var viewModel: WorkTypeMappingsViewModel
    @State private var editorRoute: WorkTypeMappingEditorRoute?

    init(
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: WorkTypeMappingsViewModel(
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            filterSection
            mappingsSection
        }
        .navigationTitle("Work Type Mappings")
        .searchable(text: $viewModel.searchText, prompt: "Search mappings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorRoute = WorkTypeMappingEditorRoute(mapping: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                
                await viewModel.load(companyId: currentCompany.id)
            }
        }
        .refreshable {
            if let currentCompany = masterDataManager.currentCompany {
                await viewModel.load(companyId:currentCompany.id,forceRefresh: true)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading mappings...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $editorRoute) { route in
            WorkTypeMappingEditorView(
                originalMapping: route.mapping,
                workTypes: viewModel.activeWorkTypes,
                serviceStopSourceOptions: viewModel.serviceStopSourceOptions,
                jobTaskSourceOptions: viewModel.jobTaskSourceOptions
            ) { mapping in
                Task {
                    if let currentCompany = masterDataManager.currentCompany {
                        await viewModel.save(companyId:currentCompany.id,mapping)
                    }
                }
            }
        }
        .alert("Work Type Mappings", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Label("Service Stop Mappings", systemImage: "mappin.and.ellipse")
                Spacer()
                Text("\(viewModel.serviceStopMappingCount)")
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Task Mappings", systemImage: "checklist")
                Spacer()
                Text("\(viewModel.taskMappingCount)")
                    .fontWeight(.semibold)
            }

            if viewModel.missingWorkTypeCount > 0 {
                HStack {
                    Label("Missing Work Types", systemImage: "exclamationmark.triangle")
                    Spacer()
                    Text("\(viewModel.missingWorkTypeCount)")
                        .fontWeight(.semibold)
                }
            }

            Button {
                Task {
                    if let currentCompany = masterDataManager.currentCompany {
                        await viewModel.seedSuggestedDefaults(companyId:currentCompany.id)
                    }
                }
            } label: {
                Label("Add Suggested Pool Mappings", systemImage: "sparkles")
            }
            .disabled(viewModel.isSaving || viewModel.activeWorkTypes.isEmpty)
        } header: {
            Text("Setup")
        } footer: {
            Text("Mappings tell payroll which Company Work Type should be used for a service stop source or task type. Do not map normal checklist tasks unless they should create extra pay.")
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(WorkTypeMappingListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var mappingsSection: some View {
        Section {
            if viewModel.filteredMappings.isEmpty {
                WorkTypeMappingsEmptyState()
            } else {
                ForEach(viewModel.filteredMappings) { mapping in
                    Button {
                        editorRoute = WorkTypeMappingEditorRoute(mapping: mapping)
                    } label: {
                        WorkTypeMappingRowView(
                            mapping: mapping,
                            sourceTitle: viewModel.sourceTitle(for: mapping),
                            workTypeTitle: viewModel.workTypeTitle(for: mapping),
                            workTypeIconName: viewModel.workTypeIconName(for: mapping),
                            workTypeMissing: viewModel.workTypesById[mapping.workTypeId] == nil
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.delete(mapping)
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Mappings")
        }
    }
}

// MARK: - Row

struct WorkTypeMappingRowView: View {
    var mapping: WorkTypeMapping
    var sourceTitle: String
    var workTypeTitle: String
    var workTypeIconName: String
    var workTypeMissing: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workTypeIconName)
                .foregroundStyle(workTypeMissing ? .red : .primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(sourceTitle)
                        .font(.headline)

                    if workTypeMissing {
                        Text("Missing")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 6) {
                    Text(mapping.sourceType.title)
                    Text("→")
                    Text(workTypeTitle)
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundStyle(workTypeMissing ? .red : .secondary)

                Text(mapping.sourceId)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct WorkTypeMappingsEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No mappings yet")
                .font(.headline)

            Text("Add suggested mappings or create a mapping manually. Payroll needs mappings before completed stops and tasks can become real pay line items.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Editor

struct WorkTypeMappingEditorView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @Environment(\.dismiss) private var dismiss

    let originalMapping: WorkTypeMapping?
    let workTypes: [CompanyWorkType]
    let serviceStopSourceOptions: [WorkTypeMappingSourceOption]
    let jobTaskSourceOptions: [WorkTypeMappingSourceOption]
    let saveAction: (WorkTypeMapping) -> Void

    @State private var sourceType: WorkTypeSource
    @State private var selectedServiceStopSourceId: String
    @State private var selectedJobTaskSourceId: String
    @State private var customSourceId: String
    @State private var selectedWorkTypeId: String

    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        originalMapping != nil
    }

    init(
        originalMapping: WorkTypeMapping?,
        workTypes: [CompanyWorkType],
        serviceStopSourceOptions: [WorkTypeMappingSourceOption],
        jobTaskSourceOptions: [WorkTypeMappingSourceOption],
        saveAction: @escaping (WorkTypeMapping) -> Void
    ) {
        self.originalMapping = originalMapping
        self.workTypes = workTypes
        self.serviceStopSourceOptions = serviceStopSourceOptions
        self.jobTaskSourceOptions = jobTaskSourceOptions
        self.saveAction = saveAction

        let startingSourceType = originalMapping?.sourceType ?? .jobTaskType

        let firstServiceStopSourceId = serviceStopSourceOptions.first?.sourceId
            ?? PayrollSystemSourceIds.recurringServiceStop

        let firstJobTaskSourceId = jobTaskSourceOptions.first?.sourceId
            ?? JobTaskType.cleanFilter.rawValue

        _sourceType = State(initialValue: startingSourceType)
        _selectedServiceStopSourceId = State(
            initialValue: startingSourceType == .serviceStopType
            ? originalMapping?.sourceId ?? firstServiceStopSourceId
            : firstServiceStopSourceId
        )
        _selectedJobTaskSourceId = State(
            initialValue: startingSourceType == .jobTaskType
            ? originalMapping?.sourceId ?? firstJobTaskSourceId
            : firstJobTaskSourceId
        )
        _customSourceId = State(
            initialValue: startingSourceType == .serviceStopType || startingSourceType == .jobTaskType
            ? ""
            : originalMapping?.sourceId ?? ""
        )
        _selectedWorkTypeId = State(initialValue: originalMapping?.workTypeId ?? workTypes.first?.id ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                sourceSection
                workTypeSection
                helpSection
            }
            .navigationTitle(isEditing ? "Edit Mapping" : "New Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let currentCompany = masterDataManager.currentCompany {
                            save(companyId:currentCompany.id)
                        }
                    }
                }
            }
            .onChange(of: sourceType) { newValue in
                if newValue == .serviceStopType {
                    selectedServiceStopSourceId = serviceStopSourceOptions.first?.sourceId
                    ?? PayrollSystemSourceIds.recurringServiceStop
                } else if newValue == .jobTaskType {
                    selectedJobTaskSourceId = jobTaskSourceOptions.first?.sourceId
                    ?? JobTaskType.cleanFilter.rawValue
                }
            }
            .alert("Work Type Mapping", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var sourceSection: some View {
        Section {
            Picker("Source Type", selection: $sourceType) {
                ForEach(WorkTypeSource.selectableCases, id: \.self) { sourceType in
                    Text(sourceType.title).tag(sourceType)
                }
            }

            sourceIdInput

            Text(sourceType.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Source")
        } footer: {
            Text("The source is the existing app value payroll should listen for.")
        }
    }

    @ViewBuilder
    private var sourceIdInput: some View {
        switch sourceType {
        case .serviceStopType:
            Picker("Service Stop Source", selection: $selectedServiceStopSourceId) {
                ForEach(serviceStopSourceOptionsWithCurrentSelection) { option in
                    Text(option.title).tag(option.sourceId)
                }
            }

            if let selected = serviceStopSourceOptionsWithCurrentSelection.first(where: { $0.sourceId == selectedServiceStopSourceId }) {
                Label(selected.subtitle, systemImage: selected.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .jobTaskType:
            Picker("Task Type", selection: $selectedJobTaskSourceId) {
                ForEach(jobTaskSourceOptionsWithCurrentSelection) { option in
                    Text(option.title).tag(option.sourceId)
                }
            }

            if let selected = jobTaskSourceOptionsWithCurrentSelection.first(where: { $0.sourceId == selectedJobTaskSourceId }) {
                Label(selected.subtitle, systemImage: selected.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .recurringServiceStopTaskType,
             .bodyOfWaterType,
             .serviceLocationType,
             .manualTag:
            TextField("Source ID", text: $customSourceId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Text("For custom sources, this ID must exactly match the value your app will send into payroll.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var workTypeSection: some View {
        Section {
            if workTypes.isEmpty {
                Text("Create at least one Company Work Type before adding mappings.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Maps To", selection: $selectedWorkTypeId) {
                    ForEach(workTypes) { workType in
                        Text(workType.name).tag(workType.id)
                    }
                }

                if let selectedWorkType = workTypes.first(where: { $0.id == selectedWorkTypeId }) {
                    HStack {
                        Image(systemName: selectedWorkType.iconName ?? selectedWorkType.category.defaultIconName)
                        VStack(alignment: .leading) {
                            Text(selectedWorkType.name)
                            Text("\(selectedWorkType.category.title) • \(selectedWorkType.defaultRateType.title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        } header: {
            Text("Company Work Type")
        } footer: {
            Text("This is the payroll work type that will be used to find technician rates.")
        }
    }

    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples")
                    .font(.headline)

                Text("system_recurring_service_stop → Routes")
                Text("system_job_service_stop → Service Call")
                Text("Clean Filter → Clean Filter")
                Text("Repair → Repair")
                Text("Install → Installation")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var serviceStopSourceOptionsWithCurrentSelection: [WorkTypeMappingSourceOption] {
        guard sourceType == .serviceStopType else {
            return serviceStopSourceOptions
        }

        let exists = serviceStopSourceOptions.contains {
            $0.sourceId == selectedServiceStopSourceId
        }

        if exists {
            return serviceStopSourceOptions
        }

        return [
            WorkTypeMappingSourceOption(
                sourceType: .serviceStopType,
                sourceId: selectedServiceStopSourceId,
                title: selectedServiceStopSourceId,
                subtitle: "Current saved source",
                systemImage: "questionmark.circle"
            )
        ] + serviceStopSourceOptions
    }

    private var jobTaskSourceOptionsWithCurrentSelection: [WorkTypeMappingSourceOption] {
        guard sourceType == .jobTaskType else {
            return jobTaskSourceOptions
        }

        let exists = jobTaskSourceOptions.contains {
            $0.sourceId == selectedJobTaskSourceId
        }

        if exists {
            return jobTaskSourceOptions
        }

        return [
            WorkTypeMappingSourceOption(
                sourceType: .jobTaskType,
                sourceId: selectedJobTaskSourceId,
                title: selectedJobTaskSourceId,
                subtitle: "Current saved source",
                systemImage: "questionmark.circle"
            )
        ] + jobTaskSourceOptions
    }

    private func save(companyId:String) {
        guard !selectedWorkTypeId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Select a company work type."
            showValidationAlert = true
            return
        }

        let finalSourceId = resolvedSourceId()

        guard !finalSourceId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Source ID is required."
            showValidationAlert = true
            return
        }

        let mapping = WorkTypeMapping(
            id: originalMapping?.id ?? PayrollIdFactory.workTypeMappingId(),
            companyId: companyId,
            sourceType: sourceType,
            sourceId: finalSourceId,
            workTypeId: selectedWorkTypeId
        )

        saveAction(mapping)
        dismiss()
    }

    private func resolvedSourceId() -> String {
        switch sourceType {
        case .serviceStopType:
            return selectedServiceStopSourceId

        case .jobTaskType:
            return selectedJobTaskSourceId

        case .recurringServiceStopTaskType,
             .bodyOfWaterType,
             .serviceLocationType,
             .manualTag:
            return customSourceId.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WorkTypeMappingsView(
            dataService: MockDataService()
        )
    }
}
