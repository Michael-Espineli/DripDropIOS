//
//  PayrollRateHistoryView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

enum PayrollRateHistoryFilter: String, CaseIterable, Identifiable {
    case current = "Current"
    case expired = "Expired"
    case scheduled = "Scheduled"
    case all = "All"

    var id: String { rawValue }
}

struct PayrollRateHistoryGroup: Identifiable {
    var id: String { technicianId }

    var technicianId: String
    var technicianName: String
    var rates: [TechnicianRate]
}

@MainActor
final class PayrollRateHistoryViewModel: ObservableObject {

    @Published var rates: [TechnicianRate] = []
    @Published var workTypes: [CompanyWorkType] = []
    @Published var workers: [CompanyUser] = []

    @Published var selectedFilter: PayrollRateHistoryFilter = .current
    @Published var searchText: String = ""

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String
    let dataService: any ProductionDataServiceProtocol

    private var hasLoaded = false

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.dataService = dataService
    }

    var workTypesById: [String: CompanyWorkType] {
        Dictionary(uniqueKeysWithValues: workTypes.map { ($0.id, $0) })
    }

    var workersByUserId: [String: CompanyUser] {
        Dictionary(uniqueKeysWithValues: workers.map { ($0.userId, $0) })
    }

    var filteredRates: [TechnicianRate] {
        let now = Date()

        let statusFiltered: [TechnicianRate]

        switch selectedFilter {
        case .current:
            statusFiltered = rates.filter { isCurrent($0, now: now) }

        case .expired:
            statusFiltered = rates.filter { $0.status == .expired }

        case .scheduled:
            statusFiltered = rates.filter {
                $0.status == .scheduled || $0.effectiveStartDate > now
            }

        case .all:
            statusFiltered = rates
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return statusFiltered
        }

        return statusFiltered.filter { rate in
            technicianName(for: rate)
                .localizedCaseInsensitiveContains(trimmedSearch) ||
            workTypeName(for: rate)
                .localizedCaseInsensitiveContains(trimmedSearch) ||
            rate.payBasis.title
                .localizedCaseInsensitiveContains(trimmedSearch) ||
            rate.rateType.title
                .localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var groups: [PayrollRateHistoryGroup] {
        let grouped = Dictionary(grouping: filteredRates) { $0.technicianId }

        return grouped.map { technicianId, rates in
            PayrollRateHistoryGroup(
                technicianId: technicianId,
                technicianName: workersByUserId[technicianId]?.payrollDisplayName ?? technicianId,
                rates: rates.sorted {
                    if $0.effectiveStartDate == $1.effectiveStartDate {
                        return workTypeName(for: $0) < workTypeName(for: $1)
                    }

                    return $0.effectiveStartDate > $1.effectiveStartDate
                }
            )
        }
        .sorted { $0.technicianName < $1.technicianName }
    }

    var currentRateCount: Int {
        let now = Date()
        return rates.filter { isCurrent($0, now: now) }.count
    }

    var expiredRateCount: Int {
        rates.filter { $0.status == .expired }.count
    }

    var scheduledRateCount: Int {
        let now = Date()
        return rates.filter {
            $0.status == .scheduled || $0.effectiveStartDate > now
        }.count
    }

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let ratesTask = dataService.fetchTechnicianRates(companyId: companyId)
            async let workTypesTask = dataService.fetchCompanyWorkTypes(companyId: companyId)
            async let workersTask = dataService.fetchCompanyUsers(companyId: companyId)

            rates = try await ratesTask
            workTypes = try await workTypesTask
            workers = try await workersTask
        } catch {
            alertMessage = "Could not load rate history. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func technicianName(for rate: TechnicianRate) -> String {
        workersByUserId[rate.technicianId]?.payrollDisplayName ?? rate.technicianId
    }

    func workTypeName(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "Hourly Rate"
        }

        guard let workTypeId = rate.workTypeId else {
            return "No Work Type"
        }

        return workTypesById[workTypeId]?.name ?? "Missing Work Type"
    }

    func workTypeIcon(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "clock"
        }

        guard let workTypeId = rate.workTypeId,
              let workType = workTypesById[workTypeId] else {
            return "exclamationmark.triangle"
        }

        return workType.displayIconName
    }

    func previousRate(for rate: TechnicianRate) -> TechnicianRate? {
        guard let previousRateId = rate.previousRateId else {
            return nil
        }

        return rates.first { $0.id == previousRateId }
    }

    private func isCurrent(
        _ rate: TechnicianRate,
        now: Date
    ) -> Bool {
        guard rate.status == .active else { return false }
        guard rate.effectiveStartDate <= now else { return false }

        if let endDate = rate.effectiveEndDate, now > endDate {
            return false
        }

        return true
    }
}

struct PayrollRateHistoryView: View {

    @StateObject private var viewModel: PayrollRateHistoryViewModel

    init(
        companyId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: PayrollRateHistoryViewModel(
                companyId: companyId,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            filterSection
            rateGroupsSection
        }
        .navigationTitle("Rate History")
        .searchable(text: $viewModel.searchText, prompt: "Search technician, work type, or basis")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading rate history...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Rate History", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            PayrollRateHistorySummaryRow(
                title: "Current Rates",
                value: "\(viewModel.currentRateCount)"
            )

            PayrollRateHistorySummaryRow(
                title: "Scheduled Rates",
                value: "\(viewModel.scheduledRateCount)"
            )

            PayrollRateHistorySummaryRow(
                title: "Expired Rates",
                value: "\(viewModel.expiredRateCount)"
            )
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(PayrollRateHistoryFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var rateGroupsSection: some View {
        Group {
            if viewModel.groups.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Rates Found",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("No technician rates match this filter.")
                    )
                }
            } else {
                ForEach(viewModel.groups) { group in
                    Section {
                        ForEach(group.rates) { rate in
                            PayrollRateHistoryRow(
                                rate: rate,
                                technicianName: viewModel.technicianName(for: rate),
                                workTypeName: viewModel.workTypeName(for: rate),
                                workTypeIcon: viewModel.workTypeIcon(for: rate),
                                previousRate: viewModel.previousRate(for: rate)
                            )
                        }
                    } header: {
                        Text(group.technicianName)
                    }
                }
            }
        }
    }
}

struct PayrollRateHistoryRow: View {
    var rate: TechnicianRate
    var technicianName: String
    var workTypeName: String
    var workTypeIcon: String
    var previousRate: TechnicianRate?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: workTypeIcon)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(workTypeName)
                        .font(.headline)

                    Text("\(rate.payBasis.title) • \(rate.rateType.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(PayrollRateHistoryMoneyFormatter.money(rate.amountCents))
                    .font(.headline)
            }

            HStack {
                Text(rate.status.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())

                Spacer()

                Text(dateRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let previousRate {
                Text("Previous: \(PayrollRateHistoryMoneyFormatter.money(previousRate.amountCents))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let reason = rate.reason,
               !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var dateRangeText: String {
        let start = PayrollRateHistoryDateFormatter.shortDate(rate.effectiveStartDate)

        if let endDate = rate.effectiveEndDate {
            return "\(start) - \(PayrollRateHistoryDateFormatter.shortDate(endDate))"
        }

        return "\(start) - Present"
    }
}

struct PayrollRateHistorySummaryRow: View {
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

enum PayrollRateHistoryMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum PayrollRateHistoryDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PayrollRateHistoryView(
            companyId: "com_mock_company",
            dataService: MockDataService()
        )
    }
}
