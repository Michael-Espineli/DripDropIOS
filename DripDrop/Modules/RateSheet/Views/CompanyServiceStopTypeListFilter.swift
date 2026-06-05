//
//  CompanyServiceStopTypeListFilter.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


import SwiftUI

// MARK: - List Filter

enum CompanyServiceStopTypeListFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case inactive = "Inactive"
    case all = "All"

    var id: String { rawValue }
}

// MARK: - Seed Model

struct CompanyServiceStopTypeSeed: Identifiable, Hashable {
    var id: String { name }

    var name: String
    var imageName: String
    var category: ServiceStopCategory
    var workTypeCandidateGroups: [[String]]
}

enum CompanyServiceStopTypeDefaultSeeds {

    static let poolCompanyDefaults: [CompanyServiceStopTypeSeed] = [
        CompanyServiceStopTypeSeed(
            name: "Weekly Route",
            imageName: "figure.pool.swim",
            category: .route,
            workTypeCandidateGroups: [
                ["Routes", "Route", "Weekly Route"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Route + Spa",
            imageName: "bubbles.and.sparkles",
            category: .route,
            workTypeCandidateGroups: [
                ["Routes", "Route", "Weekly Route"],
                ["Spa Add-On", "Spa", "Pool + Spa"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Extra Route",
            imageName: "plus.circle",
            category: .route,
            workTypeCandidateGroups: [
                ["Extra Route", "Extra Routes"],
                ["Routes", "Route"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Job Visit",
            imageName: "briefcase",
            category: .job,
            workTypeCandidateGroups: [
                ["Service Call", "Job Visit", "Job"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Service Call",
            imageName: "phone",
            category: .job,
            workTypeCandidateGroups: [
                ["Service Call"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Commercial Route",
            imageName: "building.2",
            category: .route,
            workTypeCandidateGroups: [
                ["Commercial Base", "Commercial", "Commercial Route"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Commercial Multi-BOW",
            imageName: "building.2.crop.circle",
            category: .route,
            workTypeCandidateGroups: [
                ["Commercial Base", "Commercial", "Commercial Route"],
                ["Commercial Additional Body of Water", "Additional Body of Water", "Additional BOW"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Startup",
            imageName: "play.circle",
            category: .serviceAgreementEstimate,
            workTypeCandidateGroups: [
                ["Startup", "Start Up"]
            ]
        ),
        CompanyServiceStopTypeSeed(
            name: "Estimate",
            imageName: "doc.text.magnifyingglass",
            category: .jobEstimate,
            workTypeCandidateGroups: []
        )
    ]
}

// MARK: - Editor Route

struct CompanyServiceStopTypeEditorRoute: Identifiable {
    let id = UUID()
    var serviceStopType: CompanyServiceStopType?
}

// MARK: - ViewModel

@MainActor
final class CompanyServiceStopTypesViewModel: ObservableObject {

    @Published var serviceStopTypes: [CompanyServiceStopType] = []
    @Published var workTypes: [CompanyWorkType] = []

    @Published var searchText: String = ""
    @Published var selectedFilter: CompanyServiceStopTypeListFilter = .active

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String
    let currentUserId: String

    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        companyId: String,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.currentUserId = currentUserId
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

    var filteredServiceStopTypes: [CompanyServiceStopType] {
        let filteredByStatus: [CompanyServiceStopType]

        switch selectedFilter {
        case .active:
            filteredByStatus = serviceStopTypes.filter { $0.isActive }
        case .inactive:
            filteredByStatus = serviceStopTypes.filter { !$0.isActive }
        case .all:
            filteredByStatus = serviceStopTypes
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let searched: [CompanyServiceStopType]

        if trimmedSearch.isEmpty {
            searched = filteredByStatus
        } else {
            searched = filteredByStatus.filter { serviceStopType in
                serviceStopType.name.localizedCaseInsensitiveContains(trimmedSearch) ||
                defaultWorkTypeNames(for: serviceStopType).localizedCaseInsensitiveContains(trimmedSearch)
            }
        }

        return searched.sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    var activeCount: Int {
        serviceStopTypes.filter { $0.isActive }.count
    }

    var inactiveCount: Int {
        serviceStopTypes.filter { !$0.isActive }.count
    }

    var missingWorkTypeReferenceCount: Int {
        serviceStopTypes.reduce(0) { total, serviceStopType in
            total + serviceStopType.defaultWorkTypeIds.filter {
                workTypesById[$0] == nil
            }.count
        }
    }

    var nextSortOrder: Int {
        (serviceStopTypes.map { $0.sortOrder }.max() ?? 0) + 10
    }

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let serviceStopTypesTask = dataService.fetchCompanyServiceStopTypes(companyId: companyId)
            async let workTypesTask = dataService.fetchCompanyWorkTypes(companyId: companyId)

            serviceStopTypes = try await serviceStopTypesTask
            workTypes = try await workTypesTask
        } catch {
            alertMessage = "Could not load service stop types. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func save(_ serviceStopType: CompanyServiceStopType) async {
        let validationResult = validate(serviceStopType)

        guard validationResult.isValid else {
            alertMessage = validationResult.message
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.saveCompanyServiceStopType(serviceStopType)
            upsertLocal(serviceStopType)
        } catch {
            alertMessage = "Could not save service stop type. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func deactivate(_ serviceStopType: CompanyServiceStopType) async {
        var updated = serviceStopType
        updated.isActive = false

        await save(updated)
    }

    func reactivate(_ serviceStopType: CompanyServiceStopType) async {
        var updated = serviceStopType
        updated.isActive = true

        await save(updated)
    }

    func seedPoolCompanyDefaults() async {
        let existingNames = Set(
            serviceStopTypes.map {
                normalizedName($0.name)
            }
        )

        var newTypes: [CompanyServiceStopType] = []
        var sortOrder = nextSortOrder

        for seed in CompanyServiceStopTypeDefaultSeeds.poolCompanyDefaults {
            guard !existingNames.contains(normalizedName(seed.name)) else {
                continue
            }

            let defaultWorkTypeIds = workTypeIdsForSeed(seed)

            let type = CompanyServiceStopType(
                id: PayrollIdFactory.companyServiceStopTypeId(),
                companyId: companyId,
                name: seed.name,
                imageName: seed.imageName,
                isActive: true,
                sortOrder: sortOrder,
                category: seed.category,
                defaultWorkTypeIds: defaultWorkTypeIds,
                createdAt: Date(),
                createdByUserId: currentUserId
            )

            newTypes.append(type)
            sortOrder += 10
        }

        guard !newTypes.isEmpty else {
            alertMessage = "Default service stop types already exist."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            for type in newTypes {
                try await dataService.saveCompanyServiceStopType(type)
            }

            serviceStopTypes.append(contentsOf: newTypes)
            sortLocal()

            let typesWithoutWorkTypes = newTypes.filter {
                $0.defaultWorkTypeIds.isEmpty
            }

            if typesWithoutWorkTypes.isEmpty {
                alertMessage = "Added \(newTypes.count) default service stop types."
            } else {
                alertMessage = "Added \(newTypes.count) default service stop types. \(typesWithoutWorkTypes.count) type(s) have no default work types yet."
            }

            showAlert = true
        } catch {
            alertMessage = "Could not add default service stop types. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func defaultWorkTypeNames(for serviceStopType: CompanyServiceStopType) -> String {
        let names = serviceStopType.defaultWorkTypeIds.map { workTypeId in
            workTypesById[workTypeId]?.name ?? "Missing Work Type"
        }

        if names.isEmpty {
            return "No default work types"
        }

        return names.joined(separator: " + ")
    }

    func hasMissingWorkTypeReference(_ serviceStopType: CompanyServiceStopType) -> Bool {
        serviceStopType.defaultWorkTypeIds.contains {
            workTypesById[$0] == nil
        }
    }

    private func validate(_ serviceStopType: CompanyServiceStopType) -> (isValid: Bool, message: String) {
        let trimmedName = serviceStopType.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return (false, "Service stop type name is required.")
        }

        let duplicate = serviceStopTypes.contains {
            $0.id != serviceStopType.id &&
            normalizedName($0.name) == normalizedName(trimmedName)
        }

        guard !duplicate else {
            return (false, "A service stop type named \(trimmedName) already exists.")
        }

        return (true, "")
    }

    private func upsertLocal(_ serviceStopType: CompanyServiceStopType) {
        if let index = serviceStopTypes.firstIndex(where: { $0.id == serviceStopType.id }) {
            serviceStopTypes[index] = serviceStopType
        } else {
            serviceStopTypes.append(serviceStopType)
        }

        sortLocal()
    }

    private func sortLocal() {
        serviceStopTypes.sort {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private func workTypeIdsForSeed(_ seed: CompanyServiceStopTypeSeed) -> [String] {
        var ids: [String] = []

        for candidateGroup in seed.workTypeCandidateGroups {
            if let workType = bestWorkType(candidateNames: candidateGroup) {
                if !ids.contains(workType.id) {
                    ids.append(workType.id)
                }
            }
        }

        return ids
    }

    private func bestWorkType(candidateNames: [String]) -> CompanyWorkType? {
        for candidateName in candidateNames {
            if let exact = activeWorkTypes.first(where: {
                normalizedName($0.name) == normalizedName(candidateName)
            }) {
                return exact
            }
        }

        for candidateName in candidateNames {
            if let contains = activeWorkTypes.first(where: {
                normalizedName($0.name).contains(normalizedName(candidateName)) ||
                normalizedName(candidateName).contains(normalizedName($0.name))
            }) {
                return contains
            }
        }

        return nil
    }

    private func normalizedName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "&", with: "and")
    }
}

// MARK: - View

struct CompanyServiceStopTypesView: View {

    @StateObject private var viewModel: CompanyServiceStopTypesViewModel
    @State private var editorRoute: CompanyServiceStopTypeEditorRoute?

    init(
        companyId: String,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyServiceStopTypesViewModel(
                companyId: companyId,
                currentUserId: currentUserId,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            filterSection
            serviceStopTypesSection
        }
        .navigationTitle("Service Stop Types")
        .searchable(text: $viewModel.searchText, prompt: "Search service stop types")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorRoute = CompanyServiceStopTypeEditorRoute(serviceStopType: nil)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading service stop types...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $editorRoute) { route in
            CompanyServiceStopTypeEditorView(
                companyId: viewModel.companyId,
                currentUserId: viewModel.currentUserId,
                originalServiceStopType: route.serviceStopType,
                workTypes: viewModel.activeWorkTypes,
                defaultSortOrder: viewModel.nextSortOrder
            ) { serviceStopType in
                Task {
                    await viewModel.save(serviceStopType)
                }
            }
        }
        .alert("Service Stop Types", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Label("Active", systemImage: "checkmark.circle")
                Spacer()
                Text("\(viewModel.activeCount)")
                    .fontWeight(.semibold)
            }

            HStack {
                Label("Inactive", systemImage: "pause.circle")
                Spacer()
                Text("\(viewModel.inactiveCount)")
                    .fontWeight(.semibold)
            }

            if viewModel.missingWorkTypeReferenceCount > 0 {
                HStack {
                    Label("Missing Work Type Links", systemImage: "exclamationmark.triangle")
                    Spacer()
                    Text("\(viewModel.missingWorkTypeReferenceCount)")
                        .fontWeight(.semibold)
                }
            }

            Button {
                Task {
                    await viewModel.seedPoolCompanyDefaults()
                }
            } label: {
                Label("Add Pool Service Stop Defaults", systemImage: "sparkles")
            }
            .disabled(viewModel.isSaving)
        } header: {
            Text("Setup")
        } footer: {
            Text("Service stop types define what a stop is. Their default work types tell payroll which work rows should be created when that kind of stop is finished.")
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(CompanyServiceStopTypeListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var serviceStopTypesSection: some View {
        Section {
            if viewModel.filteredServiceStopTypes.isEmpty {
                CompanyServiceStopTypesEmptyState(
                    selectedFilter: viewModel.selectedFilter
                )
            } else {
                ForEach(viewModel.filteredServiceStopTypes) { serviceStopType in
                    Button {
                        editorRoute = CompanyServiceStopTypeEditorRoute(serviceStopType: serviceStopType)
                    } label: {
                        CompanyServiceStopTypeRowView(
                            serviceStopType: serviceStopType,
                            defaultWorkTypeNames: viewModel.defaultWorkTypeNames(for: serviceStopType),
                            hasMissingWorkTypeReference: viewModel.hasMissingWorkTypeReference(serviceStopType)
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        if serviceStopType.isActive {
                            Button("Deactivate", role: .destructive) {
                                Task {
                                    await viewModel.deactivate(serviceStopType)
                                }
                            }
                        } else {
                            Button("Reactivate") {
                                Task {
                                    await viewModel.reactivate(serviceStopType)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Types")
        }
    }
}

// MARK: - Row

struct CompanyServiceStopTypeRowView: View {
    var serviceStopType: CompanyServiceStopType
    var defaultWorkTypeNames: String
    var hasMissingWorkTypeReference: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: serviceStopType.displayIconName)
                .font(.title3)
                .foregroundStyle(hasMissingWorkTypeReference ? .orange : .primary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(serviceStopType.name)
                        .font(.headline)

                    if !serviceStopType.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }

                    if hasMissingWorkTypeReference {
                        Text("Missing Link")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(defaultWorkTypeNames)
                    .font(.caption)
                    .foregroundStyle(hasMissingWorkTypeReference ? .orange : .secondary)
                    .lineLimit(2)

                Text("Sort: \(serviceStopType.sortOrder)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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

struct CompanyServiceStopTypesEmptyState: View {
    var selectedFilter: CompanyServiceStopTypeListFilter

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(emptyTitle)
                .font(.headline)

            Text(emptyMessage)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .active:
            return "No active service stop types"
        case .inactive:
            return "No inactive service stop types"
        case .all:
            return "No service stop types yet"
        }
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .active:
            return "Add your first type or seed the default pool company service stop types."
        case .inactive:
            return "Deactivated service stop types will show here."
        case .all:
            return "Service stop types help payroll understand what kind of stop was completed."
        }
    }
}

// MARK: - Editor

struct CompanyServiceStopTypeEditorView: View {

    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let currentUserId: String
    let originalServiceStopType: CompanyServiceStopType?
    let workTypes: [CompanyWorkType]
    let defaultSortOrder: Int
    let saveAction: (CompanyServiceStopType) -> Void

    @State private var name: String
    @State private var imageName: String
    @State private var isActive: Bool
    @State private var selectedCategory: ServiceStopCategory
    @State private var selectedWorkTypeIds: Set<String>
    @State private var sortOrderText: String

    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        originalServiceStopType != nil
    }

    init(
        companyId: String,
        currentUserId: String,
        originalServiceStopType: CompanyServiceStopType?,
        workTypes: [CompanyWorkType],
        defaultSortOrder: Int,
        saveAction: @escaping (CompanyServiceStopType) -> Void
    ) {
        self.companyId = companyId
        self.currentUserId = currentUserId
        self.originalServiceStopType = originalServiceStopType
        self.workTypes = workTypes
        self.defaultSortOrder = defaultSortOrder
        self.saveAction = saveAction

        _name = State(initialValue: originalServiceStopType?.name ?? "")
        _imageName = State(initialValue: originalServiceStopType?.imageName ?? "mappin.and.ellipse")
        _isActive = State(initialValue: originalServiceStopType?.isActive ?? true)
        _selectedCategory = State(initialValue: originalServiceStopType?.resolvedCategory() ?? .customerRelationship)
        _selectedWorkTypeIds = State(initialValue: Set(originalServiceStopType?.defaultWorkTypeIds ?? []))
        _sortOrderText = State(initialValue: "\(originalServiceStopType?.sortOrder ?? defaultSortOrder)")
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                defaultWorkTypesSection
                iconSection
                advancedSection
                helpSection
            }
            .navigationTitle(isEditing ? "Edit Stop Type" : "New Stop Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .alert("Service Stop Type", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var basicSection: some View {
        Section {
            TextField("Name", text: $name)

            Picker("Category", selection: $selectedCategory) {
                ForEach(ServiceStopCategory.allCases) { category in
                    Label(category.title, systemImage: category.systemImage)
                        .tag(category)
                }
            }

            Toggle("Active", isOn: $isActive)
        } header: {
            Text("Basic")
        } footer: {
            Text("Examples: Weekly Route, Job Visit, Job Estimate, Service Agreement Estimate, Customer Relationship.")
        }
    }

    private var defaultWorkTypesSection: some View {
        Section {
            if workTypes.isEmpty {
                Text("Create Company Work Types before assigning default work to service stop types.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(workTypes) { workType in
                    Button {
                        toggleWorkType(workType.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: workType.displayIconName)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(workType.name)
                                    .foregroundStyle(.primary)

                                Text("\(workType.category.title) • \(workType.defaultRateType.title)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedWorkTypeIds.contains(workType.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Default Payroll Work Types")
        } footer: {
            Text("When this kind of service stop is finished, payroll will try to create pay lines for these work types.")
        }
    }

    private var iconSection: some View {
        Section {
            HStack {
                Image(systemName: cleanedImageName.isEmpty ? "mappin.and.ellipse" : cleanedImageName)
                    .frame(width: 32)

                TextField("SF Symbol name", text: $imageName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(suggestedIcons, id: \.self) { icon in
                        Button {
                            imageName = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Icon")
        } footer: {
            Text("Use an SF Symbol name. This value can be copied into ServiceStop.typeImage.")
        }
    }

    private var advancedSection: some View {
        Section {
            TextField("Sort Order", text: $sortOrderText)
                .keyboardType(.numberPad)
        } header: {
            Text("Advanced")
        } footer: {
            Text("Lower sort orders show first. Use gaps like 10, 20, 30 so you can insert more later.")
        }
    }

    private var helpSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("How this connects to ServiceStop")
                    .font(.headline)

                Text("When creating or editing a service stop, set typeId to this record's id, type to this name, and typeImage to the selected icon.")
                Text("The pay engine will read defaultWorkTypeIds from this record before falling back to inferred recurring/job mappings.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var suggestedIcons: [String] {
        [
            "mappin.and.ellipse",
            "figure.pool.swim",
            "bubbles.and.sparkles",
            "plus.circle",
            "briefcase",
            "phone",
            "building.2",
            "building.2.crop.circle",
            "play.circle",
            "doc.text.magnifyingglass",
            "wrench.and.screwdriver",
            "hammer",
            "drop"
        ]
    }

    private var cleanedImageName: String {
        imageName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func toggleWorkType(_ workTypeId: String) {
        if selectedWorkTypeIds.contains(workTypeId) {
            selectedWorkTypeIds.remove(workTypeId)
        } else {
            selectedWorkTypeIds.insert(workTypeId)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Name is required."
            showValidationAlert = true
            return
        }

        let sortOrder = Int(sortOrderText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultSortOrder

        let sortedWorkTypeIds = workTypes
            .filter { selectedWorkTypeIds.contains($0.id) }
            .map { $0.id }

        let finalImageName = cleanedImageName.isEmpty ? nil : cleanedImageName

        let serviceStopType = CompanyServiceStopType(
            id: originalServiceStopType?.id ?? PayrollIdFactory.companyServiceStopTypeId(),
            companyId: companyId,
            name: trimmedName,
            imageName: finalImageName,
            isActive: isActive,
            sortOrder: sortOrder,
            category: selectedCategory,
            defaultWorkTypeIds: sortedWorkTypeIds,
            createdAt: originalServiceStopType?.createdAt ?? Date(),
            createdByUserId: originalServiceStopType?.createdByUserId ?? currentUserId
        )

        saveAction(serviceStopType)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CompanyServiceStopTypesView(
            companyId: "com_mock_company",
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
        )
    }
}
