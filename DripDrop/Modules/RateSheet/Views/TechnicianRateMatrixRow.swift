//
//  TechnicianRateMatrixRow.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//


import SwiftUI

// MARK: - Matrix Row

struct TechnicianRateMatrixRow: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var iconName: String

    var workTypeId: String?
    var defaultRateType: RateType
    var defaultPayBasis: PayBasis

    var isHourlyRow: Bool

    init(workType: CompanyWorkType) {
        self.id = workType.id
        self.title = workType.name
        self.subtitle = "\(workType.category.title) • \(workType.defaultRateType.title)"
        self.iconName = workType.displayIconName
        self.workTypeId = workType.id
        self.defaultRateType = workType.defaultRateType
        self.defaultPayBasis = workType.suggestedPayBasis
        self.isHourlyRow = false
    }

    static func hourlyRow() -> TechnicianRateMatrixRow {
        TechnicianRateMatrixRow(
            id: "matrix_hourly_rate_row",
            title: "Hourly Rate",
            subtitle: "General technician hourly rate",
            iconName: "clock",
            workTypeId: nil,
            defaultRateType: .hourly,
            defaultPayBasis: .technicianHourly,
            isHourlyRow: true
        )
    }

    private init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        workTypeId: String?,
        defaultRateType: RateType,
        defaultPayBasis: PayBasis,
        isHourlyRow: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.workTypeId = workTypeId
        self.defaultRateType = defaultRateType
        self.defaultPayBasis = defaultPayBasis
        self.isHourlyRow = isHourlyRow
    }
}

// MARK: - Editor Route

struct TechnicianRateEditorRoute: Identifiable {
    let id = UUID()

    var row: TechnicianRateMatrixRow
    var technician: CompanyUser
    var currentRate: TechnicianRate?
}

// MARK: - ViewModel

@MainActor
final class TechnicianRateMatrixViewModel: ObservableObject {
    
    @Published var workTypes: [CompanyWorkType] = []
    @Published var technicians: [CompanyUser] = []
    @Published var rates: [TechnicianRate] = []
    @Published var ratePlans: [CompanyRatePlan] = []

    @Published var showHourlyRow: Bool = true
    @Published var showInactiveWorkers: Bool = false
    @Published var searchText: String = ""

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""


    private let currentUserId: String
    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.currentUserId = currentUserId
        self.dataService = dataService
    }

    var matrixRows: [TechnicianRateMatrixRow] {
        var rows: [TechnicianRateMatrixRow] = []

        if showHourlyRow {
            rows.append(.hourlyRow())
        }

        let activeWorkTypes = workTypes
            .filter { $0.isActive }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.name < $1.name
                }

                return $0.sortOrder < $1.sortOrder
            }

        rows.append(contentsOf: activeWorkTypes.map { TechnicianRateMatrixRow(workType: $0) })

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return rows
        }

        return rows.filter {
            $0.title.localizedCaseInsensitiveContains(trimmedSearch) ||
            $0.subtitle.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var visibleTechnicians: [CompanyUser] {
        let filtered = technicians.filter { user in
            if showInactiveWorkers {
                return user.workerType != .notAssigned
            } else {
                return user.isPayrollWorker
            }
        }

        return filtered.sorted {
            $0.payrollDisplayName < $1.payrollDisplayName
        }
    }

    var activeRateCount: Int {
        rates.filter { rateIsCurrent($0, on: Date()) }.count
    }

    func missingRateCellCount(companyId:String) -> Int {
        var missing = 0

        for row in matrixRows {
            for technician in visibleTechnicians {
                if currentRate(
                    companyId:companyId,
                    technicianId: technician.userId,
                    row: row
                ) == nil {
                    missing += 1
                }
            }
        }

        return missing
    }

    func load(companyId:String,forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let workTypesTask = dataService.fetchCompanyWorkTypes(companyId: companyId)
            async let usersTask = dataService.fetchCompanyUsers(companyId: companyId)
            async let ratesTask = dataService.fetchTechnicianRates(companyId: companyId)
            async let plansTask = dataService.fetchCompanyRatePlans(companyId: companyId)

            workTypes = try await workTypesTask
            technicians = try await usersTask
            rates = try await ratesTask
            ratePlans = try await plansTask
        } catch {
            alertMessage = "Could not load technician rate matrix. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func currentRate(
        companyId:String,
        technicianId: String,
        row: TechnicianRateMatrixRow,
        date: Date = Date()
    ) -> TechnicianRate? {
        let candidates = rates.filter { rate in
            guard rate.companyId == companyId else { return false }
            guard rate.technicianId == technicianId else { return false }
            guard rate.workTypeId == row.workTypeId else { return false }
            guard rateIsCurrent(rate, on: date) else { return false }

            if row.isHourlyRow {
                return rate.payBasis == .technicianHourly && rate.rateType == .hourly
            }

            return true
        }

        return candidates.sorted {
            $0.effectiveStartDate > $1.effectiveStartDate
        }
        .first
    }

    func saveRate(
        companyId:String,
        technician: CompanyUser,
        row: TechnicianRateMatrixRow,
        existingRate: TechnicianRate?,
        amountCents: Int,
        rateType: RateType,
        payBasis: PayBasis,
        effectiveStartDate: Date,
        reason: String?
    ) async {
        guard amountCents >= 0 else {
            alertMessage = "Rate amount cannot be negative."
            showAlert = true
            return
        }
        
        isSaving = true
        defer { isSaving = false }

        do {
            let ratePlan = try await activeOrCreateRatePlan(companyId: companyId)

            let newStatus: RateStatus = effectiveStartDate > Date()
            ? .scheduled
            : .active

            let newRate = TechnicianRate(
                id: PayrollIdFactory.technicianRateId(),
                ratePlanId: existingRate?.ratePlanId ?? ratePlan.id,
                companyId: companyId,
                technicianId: technician.userId,
                payBasis: payBasis,
                workTypeId: row.workTypeId,
                amountCents: amountCents,
                rateType: rateType,
                effectiveStartDate: effectiveStartDate,
                effectiveEndDate: nil,
                status: newStatus,
                createdAt: Date(),
                createdByUserId: currentUserId,
                reason: reason,
                previousRateId: existingRate?.id
            )

            if let existingRate {
                var expiredOldRate = existingRate
                expiredOldRate.status = .expired
                expiredOldRate.effectiveEndDate = effectiveStartDate.addingTimeInterval(-1)

                try await dataService.saveTechnicianRateIncrease(
                    expiredOldRate: expiredOldRate,
                    newRate: newRate
                )

                replaceLocalRate(expiredOldRate)
                upsertLocalRate(newRate)
            } else {
                try await dataService.saveTechnicianRate(newRate)
                upsertLocalRate(newRate)
            }

        } catch {
            alertMessage = "Could not save technician rate. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func rateHistory(
        technicianId: String,
        row: TechnicianRateMatrixRow
    ) -> [TechnicianRate] {
        
        rates
            .filter {
//                $0.companyId == companyId &&
                $0.technicianId == technicianId &&
                $0.workTypeId == row.workTypeId
            }
            .sorted {
                $0.effectiveStartDate > $1.effectiveStartDate
            }
    }

    private func activeOrCreateRatePlan(companyId:String) async throws -> CompanyRatePlan {
        if let activePlan = ratePlans
            .filter({ $0.status == .active })
            .sorted(by: { $0.effectiveStartDate > $1.effectiveStartDate })
            .first {
            return activePlan
        }
    
        
        let newPlan = CompanyRatePlan(
            id: PayrollIdFactory.companyRatePlanId(),
            companyId: companyId,
            name: "Default Rate Plan",
            status: .active,
            effectiveStartDate: Date(),
            effectiveEndDate: nil,
            createdAt: Date(),
            createdByUserId: currentUserId
        )

        try await dataService.saveCompanyRatePlan(newPlan)
        ratePlans.append(newPlan)

        return newPlan
    }

    private func rateIsCurrent(
        _ rate: TechnicianRate,
        on date: Date
    ) -> Bool {
        guard rate.status != .draft else { return false }
        guard rate.status != .archived else { return false }
        guard rate.effectiveStartDate <= date else { return false }

        if let endDate = rate.effectiveEndDate, date > endDate {
            return false
        }

        return true
    }

    private func replaceLocalRate(_ rate: TechnicianRate) {
        if let index = rates.firstIndex(where: { $0.id == rate.id }) {
            rates[index] = rate
        } else {
            rates.append(rate)
        }
    }

    private func upsertLocalRate(_ rate: TechnicianRate) {
        if let index = rates.firstIndex(where: { $0.id == rate.id }) {
            rates[index] = rate
        } else {
            rates.append(rate)
        }
    }
}

// MARK: - View

// MARK: - Mobile Technician Rate Setup View

struct TechnicianRateMatrixView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager

    @StateObject private var viewModel: TechnicianRateMatrixViewModel
    @State private var editorRoute: TechnicianRateEditorRoute?
    @State private var selectedTechnicianId: String?

    init(
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TechnicianRateMatrixViewModel(
                currentUserId: currentUserId,
                dataService: dataService
            )
        )
    }

    private var selectedTechnician: CompanyUser? {
        if let selectedTechnicianId,
           let technician = viewModel.visibleTechnicians.first(where: { $0.userId == selectedTechnicianId }) {
            return technician
        }

        return viewModel.visibleTechnicians.first
    }

    private var selectedTechnicianRates: [TechnicianRate] {
        guard let selectedTechnician else { return [] }

        return viewModel.rates
            .filter { $0.technicianId == selectedTechnician.userId }
            .sorted { $0.effectiveStartDate > $1.effectiveStartDate }
    }

    private var selectedCurrentRateCount: Int {
        guard let currentCompany = masterDataManager.currentCompany,
              let selectedTechnician else { return 0 }

        return viewModel.matrixRows.filter { row in
            viewModel.currentRate(
                companyId: currentCompany.id,
                technicianId: selectedTechnician.userId,
                row: row
            ) != nil
        }
        .count
    }

    private var selectedMissingRateCount: Int {
        guard let currentCompany = masterDataManager.currentCompany,
              let selectedTechnician else { return 0 }

        return viewModel.matrixRows.filter { row in
            viewModel.currentRate(
                companyId: currentCompany.id,
                technicianId: selectedTechnician.userId,
                row: row
            ) == nil
        }
        .count
    }

    var body: some View {
        List {
            overviewSection
            technicianPickerSection

            if let selectedTechnician {
                selectedTechnicianSummarySection(selectedTechnician)
                rateRowsSection(selectedTechnician)
            } else {
                emptyWorkersSection
            }
        }
        .navigationTitle("Technician Rates")
        .searchable(text: $viewModel.searchText, prompt: "Search work types")
        .task {
            guard let currentCompany = masterDataManager.currentCompany else { return }
            await viewModel.load(companyId: currentCompany.id)

            if selectedTechnicianId == nil {
                selectedTechnicianId = viewModel.visibleTechnicians.first?.userId
            }
        }
        .refreshable {
            guard let currentCompany = masterDataManager.currentCompany else { return }
            await viewModel.load(companyId: currentCompany.id, forceRefresh: true)

            if selectedTechnicianId == nil {
                selectedTechnicianId = viewModel.visibleTechnicians.first?.userId
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading rates...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(item: $editorRoute) { route in
            TechnicianRateEditorView(
                technician: route.technician,
                row: route.row,
                currentRate: route.currentRate,
                history: viewModel.rateHistory(
                    technicianId: route.technician.userId,
                    row: route.row
                )
            ) { amountCents, rateType, payBasis, effectiveStartDate, reason in
                Task {
                    guard let currentCompany = masterDataManager.currentCompany else { return }

                    await viewModel.saveRate(
                        companyId: currentCompany.id,
                        technician: route.technician,
                        row: route.row,
                        existingRate: route.currentRate,
                        amountCents: amountCents,
                        rateType: rateType,
                        payBasis: payBasis,
                        effectiveStartDate: effectiveStartDate,
                        reason: reason
                    )
                }
            }
        }
        .alert("Technician Rates", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var overviewSection: some View {
        Section {
            HStack(spacing: 10) {
                TechnicianRateSetupSummaryChip(
                    title: "Workers",
                    value: "\(viewModel.visibleTechnicians.count)",
                    systemImage: "person.2"
                )

                TechnicianRateSetupSummaryChip(
                    title: "Rates",
                    value: "\(viewModel.activeRateCount)",
                    systemImage: "dollarsign.circle"
                )

                if let currentCompany = masterDataManager.currentCompany {
                    TechnicianRateSetupSummaryChip(
                        title: "Missing",
                        value: "\(viewModel.missingRateCellCount(companyId: currentCompany.id))",
                        systemImage: "exclamationmark.triangle"
                    )
                }
            }

            Toggle("Show hourly rate row", isOn: $viewModel.showHourlyRow)
            Toggle("Show inactive workers", isOn: $viewModel.showInactiveWorkers)
        } header: {
            Text("Setup")
        } footer: {
            Text("Pick one technician at a time and set their rates by work type. This is easier to use on iPhone than a spreadsheet-style grid.")
        }
    }

    private var technicianPickerSection: some View {
        Section {
            if viewModel.visibleTechnicians.isEmpty {
                ContentUnavailableView(
                    "No Payroll Workers",
                    systemImage: "person.2.slash",
                    description: Text("Add active company users marked as Employee or Independent Contractor before creating technician rates.")
                )
            } else {
                Picker("Technician", selection: selectedTechnicianBinding) {
                    ForEach(viewModel.visibleTechnicians) { technician in
                        Text(technician.payrollDisplayName)
                            .tag(Optional(technician.userId))
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.visibleTechnicians) { technician in
                            Button {
                                selectedTechnicianId = technician.userId
                            } label: {
                                TechnicianRateWorkerPill(
                                    technician: technician,
                                    isSelected: selectedTechnicianId == technician.userId ||
                                    (selectedTechnicianId == nil && technician.userId == viewModel.visibleTechnicians.first?.userId)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("Technician")
        }
    }

    private func selectedTechnicianSummarySection(_ technician: CompanyUser) -> some View {
        Section {
            HStack(spacing: 10) {
                TechnicianRateSetupSummaryChip(
                    title: "Current",
                    value: "\(selectedCurrentRateCount)",
                    systemImage: "checkmark.circle"
                )

                TechnicianRateSetupSummaryChip(
                    title: "Missing",
                    value: "\(selectedMissingRateCount)",
                    systemImage: "plus.circle"
                )

                TechnicianRateSetupSummaryChip(
                    title: "History",
                    value: "\(selectedTechnicianRates.count)",
                    systemImage: "clock.arrow.circlepath"
                )
            }

            HStack {
                Label(technician.workerType.rawValue, systemImage: "person.crop.circle.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(technician.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(technician.status == .active ? .green : .orange)
            }
        } header: {
            Text(technician.payrollDisplayName)
        }
    }

    private func rateRowsSection(_ technician: CompanyUser) -> some View {
        Section {
            if viewModel.matrixRows.isEmpty {
                ContentUnavailableView(
                    "No Work Types",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Create Company Work Types before setting technician rates.")
                )
            } else if let currentCompany = masterDataManager.currentCompany {
                ForEach(viewModel.matrixRows) { row in
                    let rate = viewModel.currentRate(
                        companyId: currentCompany.id,
                        technicianId: technician.userId,
                        row: row
                    )

                    Button {
                        editorRoute = TechnicianRateEditorRoute(
                            row: row,
                            technician: technician,
                            currentRate: rate
                        )
                    } label: {
                        TechnicianRateSetupRow(
                            row: row,
                            rate: rate
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Rates")
        } footer: {
            Text("Tap any work type to add a starting rate or create a rate increase. Existing rates are expired instead of overwritten.")
        }
    }

    private var emptyWorkersSection: some View {
        Section {
            ContentUnavailableView(
                "No Technician Selected",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text("Select a technician to edit their rates.")
            )
        }
    }

    private var selectedTechnicianBinding: Binding<String?> {
        Binding(
            get: {
                selectedTechnician?.userId
            },
            set: { newValue in
                selectedTechnicianId = newValue
            }
        )
    }
}
// MARK: - Mobile Rate Setup Components

struct TechnicianRateSetupSummaryChip: View {
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

struct TechnicianRateWorkerPill: View {
    var technician: CompanyUser
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: technician.workerType == .contractor ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                .font(.caption)

            VStack(alignment: .leading, spacing: 2) {
                Text(technician.payrollDisplayName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                Text(technician.workerType.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            isSelected
            ? Color.accentColor.opacity(0.18)
            : Color.primary.opacity(0.05),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08),
                    lineWidth: 1
                )
        }
    }
}

struct TechnicianRateSetupRow: View {
    var row: TechnicianRateMatrixRow
    var rate: TechnicianRate?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.iconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(rate == nil ? .secondary : .primary)
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    if let rate {
                        Text(RateMatrixMoneyFormatter.money(rate.amountCents))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Set")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                }

                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let rate {
                    HStack(spacing: 6) {
                        Text(rate.payBasis.title)
                        Text("•")
                        Text(rate.rateType.title)
                        Text("•")
                        Text(rate.status.title)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    Text("Effective \(RateMatrixDateFormatter.shortDate(rate.effectiveStartDate))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let reason = rate.reason,
                       !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(row.defaultPayBasis.title)
                        Text("•")
                        Text(row.defaultRateType.title)
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
// MARK: - Matrix Cells

struct MatrixSummaryChip: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Editor

struct TechnicianRateEditorView: View {

    @Environment(\.dismiss) private var dismiss

    var technician: CompanyUser
    var row: TechnicianRateMatrixRow
    var currentRate: TechnicianRate?
    var history: [TechnicianRate]

    var saveAction: (
        _ amountCents: Int,
        _ rateType: RateType,
        _ payBasis: PayBasis,
        _ effectiveStartDate: Date,
        _ reason: String?
    ) -> Void

    @State private var amountText: String
    @State private var rateType: RateType
    @State private var payBasis: PayBasis
    @State private var effectiveStartDate: Date
    @State private var reason: String

    @State private var showValidationAlert: Bool = false
    @State private var validationMessage: String = ""

    init(
        technician: CompanyUser,
        row: TechnicianRateMatrixRow,
        currentRate: TechnicianRate?,
        history: [TechnicianRate],
        saveAction: @escaping (
            _ amountCents: Int,
            _ rateType: RateType,
            _ payBasis: PayBasis,
            _ effectiveStartDate: Date,
            _ reason: String?
        ) -> Void
    ) {
        self.technician = technician
        self.row = row
        self.currentRate = currentRate
        self.history = history
        self.saveAction = saveAction

        _amountText = State(
            initialValue: currentRate.map {
                RateMatrixMoneyFormatter.decimalString($0.amountCents)
            } ?? ""
        )

        _rateType = State(initialValue: currentRate?.rateType ?? row.defaultRateType)
        _payBasis = State(initialValue: currentRate?.payBasis ?? row.defaultPayBasis)
        _effectiveStartDate = State(initialValue: Date())
        _reason = State(initialValue: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                summarySection
                rateSection
                historySection
            }
            .navigationTitle(currentRate == nil ? "New Rate" : "Rate Increase")
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
            .alert("Technician Rate", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                Text("Technician")
                Spacer()
                Text(technician.payrollDisplayName)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Worker Type")
                Spacer()
                Text(technician.workerType.rawValue)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Work Type")
                Spacer()
                Text(row.title)
                    .foregroundStyle(.secondary)
            }

            if let currentRate {
                HStack {
                    Text("Current Rate")
                    Spacer()
                    Text(RateMatrixMoneyFormatter.money(currentRate.amountCents))
                        .fontWeight(.semibold)
                }
            }
        } header: {
            Text("Summary")
        }
    }

    private var rateSection: some View {
        Section {
            TextField("Amount", text: $amountText)
                .keyboardType(.decimalPad)

            Picker("Rate Type", selection: $rateType) {
                ForEach(RateType.allCases, id: \.self) { type in
                    Text(type.title).tag(type)
                }
            }

            Picker("Pay Basis", selection: $payBasis) {
                ForEach(PayBasis.allCases, id: \.self) { basis in
                    Text(basis.title).tag(basis)
                }
            }

            Text(payBasis.helpText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            DatePicker(
                "Effective Date",
                selection: $effectiveStartDate,
                displayedComponents: .date
            )

            TextField("Reason / Notes", text: $reason, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Rate")
        } footer: {
            Text("Saving creates a new TechnicianRate. If a current rate exists, the old rate is expired so rate history is preserved.")
        }
    }

    private var historySection: some View {
        Section {
            if history.isEmpty {
                Text("No rate history yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history) { rate in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(RateMatrixMoneyFormatter.money(rate.amountCents))
                                .font(.headline)

                            Spacer()

                            Text(rate.status.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(rate.rateType.title) • \(rate.payBasis.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(dateRangeText(rate))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        if let reason = rate.reason, !reason.isEmpty {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text("History")
        }
    }

    private func save() {
        guard let amountCents = RateMatrixMoneyFormatter.cents(from: amountText) else {
            validationMessage = "Enter a valid rate amount."
            showValidationAlert = true
            return
        }

        if rateType == .hourly && payBasis != .technicianHourly {
            validationMessage = "Hourly rates should usually use Technician Hourly as the pay basis."
            showValidationAlert = true
            return
        }

        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)

        saveAction(
            amountCents,
            rateType,
            payBasis,
            effectiveStartDate,
            trimmedReason.isEmpty ? nil : trimmedReason
        )

        dismiss()
    }

    private func dateRangeText(_ rate: TechnicianRate) -> String {
        let start = RateMatrixDateFormatter.shortDate(rate.effectiveStartDate)

        if let endDate = rate.effectiveEndDate {
            return "\(start) - \(RateMatrixDateFormatter.shortDate(endDate))"
        }

        return "\(start) - Present"
    }
}

// MARK: - Formatters

enum RateMatrixMoneyFormatter {

    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }

    static func decimalString(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "0.00"
    }

    static func cents(from text: String) -> Int? {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let value = Double(cleaned) else {
            return nil
        }

        return Int((value * 100).rounded())
    }
}

enum RateMatrixDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TechnicianRateMatrixView(
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
        )
    }
}
