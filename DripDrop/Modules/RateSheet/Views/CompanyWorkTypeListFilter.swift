//
//  CompanyWorkTypeListFilter.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/19/26.
//


import SwiftUI

// MARK: - Filter

enum CompanyWorkTypeListFilter: String, CaseIterable, Identifiable {
    case active = "Active"
    case inactive = "Inactive"
    case all = "All"

    var id: String { rawValue }
}

// MARK: - Default Seeds

struct CompanyWorkTypeSeed: Identifiable, Hashable {
    var id: String
    var name: String
    var category: WorkCategory
    var bucketId: String
    var iconName: String
    var defaultRateType: RateType
    var defaultStackBehavior: RateStackBehavior
}

struct CompanyPayTypeBucket: Identifiable, Hashable {
    var id: String
    var label: String
    var category: ServiceStopCategory

    static let all: [CompanyPayTypeBucket] = [
        CompanyPayTypeBucket(id: "route", label: "Routes", category: .route),
        CompanyPayTypeBucket(id: "job", label: "Jobs", category: .job),
        CompanyPayTypeBucket(id: "jobEstimate", label: "Job Estimates", category: .jobEstimate),
        CompanyPayTypeBucket(id: "serviceAgreementEstimate", label: "Service Agreement Estimates", category: .serviceAgreementEstimate),
        CompanyPayTypeBucket(id: "customerRelationship", label: "Customer Relationships", category: .customerRelationship)
    ]

    static func bucket(for id: String?) -> CompanyPayTypeBucket {
        let trimmedId = id?.trimmingCharacters(in: .whitespacesAndNewlines)

        return all.first { $0.id == trimmedId } ?? all[0]
    }

    static func defaultBucket(for category: WorkCategory) -> CompanyPayTypeBucket {
        switch category {
        case .route, .commercial:
            return bucket(for: "route")
        case .serviceCall, .repair, .installation, .cleaning, .startup, .drainAndRefill, .extra, .custom:
            return bucket(for: "job")
        }
    }
}

enum CompanyWorkTypeDefaultSeeds {

    static let poolCompanyDefaults: [CompanyWorkTypeSeed] = [
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.recurringServiceStop,
            name: "Residential",
            category: .route,
            bucketId: "route",
            iconName: "house",
            defaultRateType: .flatPerStop,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.commercialRoute,
            name: "Commercial",
            category: .commercial,
            bucketId: "route",
            iconName: "building.2",
            defaultRateType: .flatPerStop,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.jobServiceStop,
            name: "Filter Cleaning",
            category: .cleaning,
            bucketId: "job",
            iconName: "sparkles",
            defaultRateType: .flatPerTask,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.jobSaltCellCleaning,
            name: "Salt Cell Cleaning",
            category: .cleaning,
            bucketId: "job",
            iconName: "drop",
            defaultRateType: .flatPerTask,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.jobEstimateServiceStop,
            name: "Estimate",
            category: .serviceCall,
            bucketId: "jobEstimate",
            iconName: "doc.text.magnifyingglass",
            defaultRateType: .flatPerStop,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.serviceAgreementEstimateServiceStop,
            name: "Estimate",
            category: .startup,
            bucketId: "serviceAgreementEstimate",
            iconName: "list.clipboard",
            defaultRateType: .flatPerStop,
            defaultStackBehavior: .stackable
        ),
        CompanyWorkTypeSeed(
            id: PayrollSystemSourceIds.customerRelationshipServiceStop,
            name: "Service Call",
            category: .serviceCall,
            bucketId: "customerRelationship",
            iconName: "phone",
            defaultRateType: .flatPerStop,
            defaultStackBehavior: .stackable
        )
    ]
}

// MARK: - Editor Route

struct CompanyWorkTypeEditorRoute: Identifiable {
    let id = UUID()
    var workType: CompanyWorkType?
}

// MARK: - ViewModel

@MainActor
final class CompanyWorkTypesViewModel: ObservableObject {

    @Published var workTypes: [CompanyWorkType] = []
    @Published var searchText: String = ""
    @Published var selectedFilter: CompanyWorkTypeListFilter = .active

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

    var filteredWorkTypes: [CompanyWorkType] {
        let filteredByStatus: [CompanyWorkType]

        switch selectedFilter {
        case .active:
            filteredByStatus = workTypes.filter { $0.isActive }
        case .inactive:
            filteredByStatus = workTypes.filter { !$0.isActive }
        case .all:
            filteredByStatus = workTypes
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let searched: [CompanyWorkType]

        if trimmedSearch.isEmpty {
            searched = filteredByStatus
        } else {
            searched = filteredByStatus.filter {
                $0.name.localizedCaseInsensitiveContains(trimmedSearch) ||
                $0.category.title.localizedCaseInsensitiveContains(trimmedSearch) ||
                $0.defaultRateType.title.localizedCaseInsensitiveContains(trimmedSearch)
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
        workTypes.filter { $0.isActive }.count
    }

    var inactiveCount: Int {
        workTypes.filter { !$0.isActive }.count
    }

    var nextSortOrder: Int {
        (workTypes.map { $0.sortOrder }.max() ?? 0) + 10
    }

    func load(companyId: String,forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            workTypes = try await dataService.fetchCompanyWorkTypes(companyId: companyId)
        } catch {
            alertMessage = "Could not load company pay types. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func save(_ workType: CompanyWorkType) async {
        let validationResult = validate(workType)

        guard validationResult.isValid else {
            alertMessage = validationResult.message
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.saveCompanyWorkType(workType)
            upsertLocal(workType)
        } catch {
            alertMessage = "Could not save pay type. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func deactivate(_ workType: CompanyWorkType) async {
        var updated = workType
        updated.isActive = false

        await save(updated)
    }

    func reactivate(_ workType: CompanyWorkType) async {
        var updated = workType
        updated.isActive = true

        await save(updated)
    }

    func seedPoolCompanyDefaults(companyId: String) async {
        var existingKeys = Set(
            workTypes.map { duplicateKey(name: $0.name, bucketId: $0.bucketId) }
        )

        var newWorkTypes: [CompanyWorkType] = []
        let appendingToExistingPayTypes = !workTypes.isEmpty
        var sortOrder = appendingToExistingPayTypes ? nextSortOrder : 0
        let sortOrderStep = appendingToExistingPayTypes ? 10 : 1

        for seed in CompanyWorkTypeDefaultSeeds.poolCompanyDefaults {
            let bucket = CompanyPayTypeBucket.bucket(for: seed.bucketId)
            let seedDuplicateKey = duplicateKey(name: seed.name, bucketId: bucket.id)

            guard !existingKeys.contains(seedDuplicateKey) else {
                continue
            }

            let workType = CompanyWorkType(
                id: seed.id,
                companyId: companyId,
                name: seed.name,
                category: seed.category,
                bucketId: bucket.id,
                bucketLabel: bucket.label,
                serviceStopCategory: bucket.category,
                iconName: seed.iconName,
                isActive: true,
                defaultRateType: seed.defaultRateType,
                defaultStackBehavior: seed.defaultStackBehavior,
                sortOrder: sortOrder
            )

            newWorkTypes.append(workType)
            existingKeys.insert(seedDuplicateKey)
            sortOrder += sortOrderStep
        }

        guard !newWorkTypes.isEmpty else {
            alertMessage = "Default pay types already exist."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            for workType in newWorkTypes {
                try await dataService.saveCompanyWorkType(workType)
            }

            workTypes.append(contentsOf: newWorkTypes)
            workTypes.sort {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }

            alertMessage = "Added \(newWorkTypes.count) default pay types."
            showAlert = true
        } catch {
            alertMessage = "Could not add default pay types. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func validate(_ workType: CompanyWorkType) -> (isValid: Bool, message: String) {
        let trimmedName = workType.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return (false, "Work type name is required.")
        }

        let duplicate = workTypes.contains {
            $0.id != workType.id &&
            duplicateKey(name: $0.name, bucketId: $0.bucketId) == duplicateKey(name: trimmedName, bucketId: workType.bucketId)
        }

        guard !duplicate else {
            return (false, "A pay type named \(trimmedName) already exists.")
        }

        return (true, "")
    }

    private func upsertLocal(_ workType: CompanyWorkType) {
        if let index = workTypes.firstIndex(where: { $0.id == workType.id }) {
            workTypes[index] = workType
        } else {
            workTypes.append(workType)
        }

        workTypes.sort {
            if $0.sortOrder == $1.sortOrder {
                return $0.name < $1.name
            }

            return $0.sortOrder < $1.sortOrder
        }
    }

    private func normalizedName(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func duplicateKey(name: String, bucketId: String?) -> String {
        "\(normalizedName(name))|\(CompanyPayTypeBucket.bucket(for: bucketId).id)"
    }
}

// MARK: - View

struct CompanyWorkTypesView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject private var viewModel: CompanyWorkTypesViewModel
    @State private var editorRoute: CompanyWorkTypeEditorRoute?

    init(
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyWorkTypesViewModel(
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            filterSection
            workTypesSection
        }
        .navigationTitle("Pay Types")
        .searchable(text: $viewModel.searchText, prompt: "Search pay types")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorRoute = CompanyWorkTypeEditorRoute(workType: nil)
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
                ProgressView("Loading pay types...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $editorRoute) { route in
            CompanyWorkTypeEditorView(
                originalWorkType: route.workType,
                defaultSortOrder: viewModel.nextSortOrder
            ) { workType in
                Task {
                    await viewModel.save(workType)
                }
            }
        }
        .alert("Company Pay Types", isPresented: $viewModel.showAlert) {
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

            Button {
                editorRoute = CompanyWorkTypeEditorRoute(workType: nil)
            } label: {
                Label("New Pay Type", systemImage: "plus.circle")
            }

            Button {
                Task {
                    
                    if let currentCompany = masterDataManager.currentCompany {
                        await viewModel.seedPoolCompanyDefaults(companyId: currentCompany.id)
                    }
                }
            } label: {
                Label("Add Pool Company Defaults", systemImage: "sparkles")
            }
            .disabled(viewModel.isSaving)
        } header: {
            Text("Setup")
        } footer: {
            Text("Pay types are the payroll rows used for technician rates and pay line items. Deactivate old pay types instead of deleting them.")
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(CompanyWorkTypeListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var workTypesSection: some View {
        Section {
            if viewModel.filteredWorkTypes.isEmpty {
                CompanyWorkTypesEmptyState(
                    selectedFilter: viewModel.selectedFilter
                )
            } else {
                ForEach(viewModel.filteredWorkTypes) { workType in
                    Button {
                        editorRoute = CompanyWorkTypeEditorRoute(workType: workType)
                    } label: {
                        CompanyWorkTypeRowView(workType: workType)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        if workType.isActive {
                            Button("Deactivate", role: .destructive) {
                                Task {
                                    await viewModel.deactivate(workType)
                                }
                            }
                        } else {
                            Button("Reactivate") {
                                Task {
                                    await viewModel.reactivate(workType)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Pay Types")
        }
    }
}

// MARK: - Row

struct CompanyWorkTypeRowView: View {
    var workType: CompanyWorkType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workType.displayIconName)
                .font(.title3)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(workType.name)
                        .font(.headline)

                    if !workType.isActive {
                        Text("Inactive")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }
                }

                Text("\(workType.category.title) • \(CompanyPayTypeBucket.bucket(for: workType.bucketId).label) • \(workType.defaultRateType.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Stacking: \(workType.defaultStackBehavior.title) • Sort: \(workType.sortOrder)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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

struct CompanyWorkTypesEmptyState: View {
    var selectedFilter: CompanyWorkTypeListFilter

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
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
            return "No active pay types"
        case .inactive:
            return "No inactive pay types"
        case .all:
            return "No pay types yet"
        }
    }

    private var emptyMessage: String {
        switch selectedFilter {
        case .active:
            return "Add your first pay type or seed the default pool company pay types."
        case .inactive:
            return "Deactivated pay types will show here."
        case .all:
            return "Pay types are used as payroll rows for technician rates."
        }
    }
}

// MARK: - Editor

struct CompanyWorkTypeEditorView: View {

    @Environment(\.dismiss) private var dismiss

    let originalWorkType: CompanyWorkType?
    let defaultSortOrder: Int
    let saveAction: (CompanyWorkType) -> Void

    @State private var name: String
    @State private var category: WorkCategory
    @State private var selectedBucketId: String
    @State private var iconName: String
    @State private var isActive: Bool
    @State private var defaultRateType: RateType
    @State private var defaultStackBehavior: RateStackBehavior
    @State private var sortOrderText: String

    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    private var isEditing: Bool {
        originalWorkType != nil
    }

    init(
        originalWorkType: CompanyWorkType?,
        defaultSortOrder: Int,
        saveAction: @escaping (CompanyWorkType) -> Void
    ) {
        self.originalWorkType = originalWorkType
        self.defaultSortOrder = defaultSortOrder
        self.saveAction = saveAction

        let startingCategory = originalWorkType?.category ?? .custom
        let startingBucket = CompanyPayTypeBucket.bucket(for: originalWorkType?.bucketId)

        _name = State(initialValue: originalWorkType?.name ?? "")
        _category = State(initialValue: startingCategory)
        _selectedBucketId = State(initialValue: startingBucket.id)
        _iconName = State(initialValue: originalWorkType?.iconName ?? startingCategory.defaultIconName)
        _isActive = State(initialValue: originalWorkType?.isActive ?? true)
        _defaultRateType = State(initialValue: originalWorkType?.defaultRateType ?? startingCategory.suggestedDefaultRateType)
        _defaultStackBehavior = State(initialValue: originalWorkType?.defaultStackBehavior ?? startingCategory.suggestedStackBehavior)
        _sortOrderText = State(initialValue: "\(originalWorkType?.sortOrder ?? defaultSortOrder)")
    }

    var body: some View {
        NavigationStack {
            Form {
                basicSection
                payDefaultsSection
                iconSection
                advancedSection
            }
            .navigationTitle(isEditing ? "Edit Pay Type" : "New Pay Type")
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
                            save(companyId: currentCompany.id)
                        }
                    }
                }
            }
            .onChange(of: category) { _, newCategory in
                guard !isEditing else { return }

                selectedBucketId = CompanyPayTypeBucket.defaultBucket(for: newCategory).id
                iconName = newCategory.defaultIconName
                defaultRateType = newCategory.suggestedDefaultRateType
                defaultStackBehavior = newCategory.suggestedStackBehavior
            }
            .alert("Pay Type", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var basicSection: some View {
        Section {
            TextField("Name", text: $name)

            Picker("Category", selection: $category) {
                ForEach(WorkCategory.selectableCases, id: \.self) { category in
                    Text(category.title).tag(category)
                }
            }

            Picker("Bucket", selection: $selectedBucketId) {
                ForEach(CompanyPayTypeBucket.all) { bucket in
                    Text(bucket.label).tag(bucket.id)
                }
            }

            Toggle("Active", isOn: $isActive)
        } header: {
            Text("Basic")
        } footer: {
            Text("Examples: Residential, Commercial, Filter Cleaning, Salt Cell Cleaning, Estimate, Service Call.")
        }
    }

    private var payDefaultsSection: some View {
        Section {
            Picker("Default Rate Type", selection: $defaultRateType) {
                ForEach(RateType.allCases, id: \.self) { rateType in
                    Text(rateType.title).tag(rateType)
                }
            }

            Picker("Default Stacking", selection: $defaultStackBehavior) {
                ForEach(RateStackBehavior.selectableCases, id: \.self) { behavior in
                    Text(behavior.title).tag(behavior)
                }
            }

            Text(defaultStackBehavior.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Payroll Defaults")
        } footer: {
            Text("These defaults help the rate matrix and pay engine know how this type of work should usually be paid.")
        }
    }

    private var iconSection: some View {
        Section {
            HStack {
                Image(systemName: iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? category.defaultIconName : iconName)
                    .frame(width: 32)

                TextField("SF Symbol name", text: $iconName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(suggestedIcons, id: \.self) { icon in
                        Button {
                            iconName = icon
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
            Text("Use an SF Symbol name. This is optional; the category icon will be used if left blank.")
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

    private var suggestedIcons: [String] {
        [
            category.defaultIconName,
            "figure.pool.swim",
            "sparkles",
            "line.3.horizontal.decrease.circle",
            "bolt.circle",
            "phone",
            "wrench.and.screwdriver",
            "hammer",
            "building.2",
            "drop",
            "drop.triangle",
            "plus.circle",
            "tag"
        ]
    }

    private func save(companyId:String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Name is required."
            showValidationAlert = true
            return
        }

        let sortOrder = Int(sortOrderText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? defaultSortOrder
        let bucket = CompanyPayTypeBucket.bucket(for: selectedBucketId)

        let trimmedIconName = iconName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalIconName = trimmedIconName.isEmpty ? nil : trimmedIconName

        let workType = CompanyWorkType(
            id: originalWorkType?.id ?? PayrollIdFactory.companyWorkTypeId(),
            companyId: companyId,
            name: trimmedName,
            category: category,
            bucketId: bucket.id,
            bucketLabel: bucket.label,
            serviceStopCategory: bucket.category,
            iconName: finalIconName,
            isActive: isActive,
            defaultRateType: defaultRateType,
            defaultStackBehavior: defaultStackBehavior,
            sortOrder: sortOrder
        )

        saveAction(workType)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CompanyWorkTypesView(
            dataService: MockDataService()
        )
    }
}
