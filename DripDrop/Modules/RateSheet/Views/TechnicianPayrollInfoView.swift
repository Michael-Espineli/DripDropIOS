//
//  TechnicianPayrollInfoView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

enum TechnicianPayrollInfoFilter: String, CaseIterable, Identifiable {
    case outstanding = "Outstanding"
    case approved = "Approved"
    case paid = "Paid"
    case all = "All"

    var id: String { rawValue }
}

@MainActor
final class TechnicianPayrollInfoViewModel: ObservableObject {

    @Published var lineItems: [TechnicianPayLineItem] = []
    @Published var statements: [TechnicianPayStatement] = []
    @Published var rates: [TechnicianRate] = []
    @Published var workTypes: [CompanyWorkType] = []

    @Published var selectedFilter: TechnicianPayrollInfoFilter = .outstanding

    @Published var startDate: Date
    @Published var endDate: Date

    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String
    let companyUser: CompanyUser
    let dataService: any ProductionDataServiceProtocol

    private var hasLoaded = false

    init(
        companyId: String,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.companyUser = companyUser
        self.dataService = dataService

        let today = Date()
        self.startDate = Calendar.current.date(byAdding: .day, value: -30, to: today) ?? today
        self.endDate = today
    }

    var technicianId: String {
        companyUser.userId
    }

    var filteredLineItems: [TechnicianPayLineItem] {
        let userItems = lineItems.filter {
            $0.technicianId == technicianId
        }

        let filtered: [TechnicianPayLineItem]

        switch selectedFilter {
        case .outstanding:
            filtered = userItems.filter {
                $0.calculationStatus == .pending ||
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .needsReview ||
                $0.calculationStatus == .adjusted
            }

        case .approved:
            filtered = userItems.filter {
                $0.calculationStatus == .approved
            }

        case .paid:
            filtered = userItems.filter {
                $0.calculationStatus == .paid
            }

        case .all:
            filtered = userItems
        }

        return filtered.sorted {
            if $0.completedDate == $1.completedDate {
                return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
            }

            return $0.completedDate > $1.completedDate
        }
    }

    var userStatements: [TechnicianPayStatement] {
        statements
            .filter { $0.technicianId == technicianId }
            .sorted {
                if $0.startDate == $1.startDate {
                    return $0.createdAt > $1.createdAt
                }

                return $0.startDate > $1.startDate
            }
    }

    var currentRates: [TechnicianRate] {
        let now = Date()

        return rates
            .filter {
                $0.technicianId == technicianId &&
                $0.status == .active &&
                $0.effectiveStartDate <= now &&
                ($0.effectiveEndDate == nil || $0.effectiveEndDate! >= now)
            }
            .sorted {
                workTypeName(for: $0) < workTypeName(for: $1)
            }
    }

    var recentRateHistory: [TechnicianRate] {
        rates
            .filter { $0.technicianId == technicianId }
            .sorted { $0.effectiveStartDate > $1.effectiveStartDate }
    }

    var outstandingTotalCents: Int {
        lineItems
            .filter {
                $0.technicianId == technicianId &&
                (
                    $0.calculationStatus == .pending ||
                    $0.calculationStatus == .calculated ||
                    $0.calculationStatus == .needsReview ||
                    $0.calculationStatus == .adjusted
                )
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var approvedTotalCents: Int {
        lineItems
            .filter {
                $0.technicianId == technicianId &&
                $0.calculationStatus == .approved
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var paidTotalCents: Int {
        lineItems
            .filter {
                $0.technicianId == technicianId &&
                $0.calculationStatus == .paid
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var yearToDatePaidCents: Int {
        let yearStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year], from: Date())
        ) ?? Date()

        return lineItems
            .filter {
                $0.technicianId == technicianId &&
                $0.calculationStatus == .paid &&
                $0.completedDate >= yearStart
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let ytdStart = Calendar.current.date(
                from: Calendar.current.dateComponents([.year], from: Date())
            ) ?? startDate

            let lineItemStartDate = min(startDate, ytdStart)

            async let lineItemsTask = dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                startDate: lineItemStartDate,
                endDate: endDate
            )

            async let statementsTask = dataService.fetchTechnicianPayStatements(
                companyId: companyId,
                startDate: lineItemStartDate,
                endDate: endDate
            )

            async let ratesTask = dataService.fetchTechnicianRates(
                companyId: companyId,
                technicianId: technicianId
            )

            async let workTypesTask = dataService.fetchCompanyWorkTypes(
                companyId: companyId
            )

            lineItems = try await lineItemsTask
            statements = try await statementsTask
            rates = try await ratesTask
            workTypes = try await workTypesTask

        } catch {
            alertMessage = "Could not load technician payroll info. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func workTypeName(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "Hourly Rate"
        }

        guard let workTypeId = rate.workTypeId else {
            return "No Work Type"
        }

        return workTypes.first(where: { $0.id == workTypeId })?.name ?? "Missing Work Type"
    }

    func workTypeIcon(for rate: TechnicianRate) -> String {
        if rate.payBasis == .technicianHourly {
            return "clock"
        }

        guard let workTypeId = rate.workTypeId,
              let workType = workTypes.first(where: { $0.id == workTypeId }) else {
            return "exclamationmark.triangle"
        }

        return workType.displayIconName
    }
}

struct TechnicianPayrollInfoView: View {

    @StateObject private var viewModel: TechnicianPayrollInfoViewModel

    init(
        companyId: String,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TechnicianPayrollInfoViewModel(
                companyId: companyId,
                companyUser: companyUser,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            technicianSection
            dateRangeSection
            summarySection
            filterSection
            lineItemsSection
            statementsSection
            currentRatesSection
            rateHistorySection
        }
        .navigationTitle("Payroll Info")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading payroll...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Payroll Info", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var technicianSection: some View {
        Section("Technician") {
            TechnicianPayrollDetailRow(
                title: "Name",
                value: viewModel.companyUser.payrollDisplayName
            )

            TechnicianPayrollDetailRow(
                title: "Worker Type",
                value: viewModel.companyUser.workerType.rawValue
            )

            TechnicianPayrollDetailRow(
                title: "Status",
                value: viewModel.companyUser.status.rawValue
            )

            TechnicianPayrollDetailRow(
                title: "User ID",
                value: viewModel.companyUser.userId
            )
        }
    }

    private var dateRangeSection: some View {
        Section {
            DatePicker(
                "Start",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )

            DatePicker(
                "End",
                selection: $viewModel.endDate,
                displayedComponents: .date
            )

            Button {
                Task {
                    await viewModel.load(forceRefresh: true)
                }
            } label: {
                Label("Load Date Range", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Date Range")
        } footer: {
            Text("Line items and statements are shown for this date range. Year-to-date uses the current calendar year.")
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            TechnicianPayrollSummaryRow(
                title: "Outstanding",
                value: TechnicianPayrollMoneyFormatter.money(viewModel.outstandingTotalCents),
                systemImage: "clock.badge.exclamationmark"
            )

            TechnicianPayrollSummaryRow(
                title: "Approved",
                value: TechnicianPayrollMoneyFormatter.money(viewModel.approvedTotalCents),
                systemImage: "checkmark.circle"
            )

            TechnicianPayrollSummaryRow(
                title: "Paid",
                value: TechnicianPayrollMoneyFormatter.money(viewModel.paidTotalCents),
                systemImage: "dollarsign.circle"
            )

            TechnicianPayrollSummaryRow(
                title: "Year To Date Paid",
                value: TechnicianPayrollMoneyFormatter.money(viewModel.yearToDatePaidCents),
                systemImage: "chart.line.uptrend.xyaxis"
            )
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Pay Lines", selection: $viewModel.selectedFilter) {
                ForEach(TechnicianPayrollInfoFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var lineItemsSection: some View {
        Section {
            if viewModel.filteredLineItems.isEmpty {
                ContentUnavailableView(
                    "No Pay Lines",
                    systemImage: "list.bullet.rectangle",
                    description: Text("No pay line items match this filter.")
                )
            } else {
                ForEach(viewModel.filteredLineItems) { item in
                    TechnicianPayrollLineItemRow(lineItem: item)
                }
            }
        } header: {
            Text("Pay Line Items")
        }
    }

    private var statementsSection: some View {
        Section {
            if viewModel.userStatements.isEmpty {
                ContentUnavailableView(
                    "No Statements",
                    systemImage: "doc.text",
                    description: Text("No pay statements found for this technician.")
                )
            } else {
                ForEach(viewModel.userStatements.prefix(5)) { statement in
                    NavigationLink {
                        TechnicianPayStatementDetailView(
                            statement: statement,
                            currentUserId: viewModel.companyUser.userId,
                            dataService: viewModel.dataService
                        )
                    } label: {
                        TechnicianPayrollStatementRow(statement: statement)
                    }
                }
            }
        } header: {
            Text("Pay Statements")
        } footer: {
            Text("Shows recent statements for this technician.")
        }
    }

    private var currentRatesSection: some View {
        Section {
            if viewModel.currentRates.isEmpty {
                ContentUnavailableView(
                    "No Current Rates",
                    systemImage: "tablecells",
                    description: Text("This technician does not have active rates.")
                )
            } else {
                ForEach(viewModel.currentRates) { rate in
                    TechnicianPayrollRateRow(
                        rate: rate,
                        workTypeName: viewModel.workTypeName(for: rate),
                        workTypeIcon: viewModel.workTypeIcon(for: rate)
                    )
                }
            }
        } header: {
            Text("Current Rates")
        }
    }

    private var rateHistorySection: some View {
        Section {
            if viewModel.recentRateHistory.isEmpty {
                ContentUnavailableView(
                    "No Rate History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Rate changes will appear here.")
                )
            } else {
                ForEach(viewModel.recentRateHistory.prefix(8)) { rate in
                    TechnicianPayrollRateRow(
                        rate: rate,
                        workTypeName: viewModel.workTypeName(for: rate),
                        workTypeIcon: viewModel.workTypeIcon(for: rate)
                    )
                }
            }
        } header: {
            Text("Recent Rate History")
        }
    }
}

// MARK: - Rows

struct TechnicianPayrollSummaryRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 28)

            Text(title)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct TechnicianPayrollDetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TechnicianPayrollLineItemRow: View {
    var lineItem: TechnicianPayLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(lineItem.workTypeName ?? "Missing Work Type")
                        .font(.headline)

                    Text(sourceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(TechnicianPayrollMoneyFormatter.money(lineItem.totalAmountCents))
                    .font(.headline)
            }

            HStack {
                Text(lineItem.calculationStatus.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())

                Spacer()

                Text(TechnicianPayrollDateFormatter.shortDate(lineItem.completedDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Rate: \(TechnicianPayrollMoneyFormatter.money(lineItem.rateAmountCents))")
                Spacer()
                Text("Qty: \(quantityText)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let notes = lineItem.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private var sourceText: String {
        var parts: [String] = []

        parts.append(lineItem.source.rawValue)

        if let serviceStopId = lineItem.serviceStopId {
            parts.append(serviceStopId)
        }

        if let taskId = lineItem.serviceStopTaskId {
            parts.append(taskId)
        }

        return parts.joined(separator: " • ")
    }

    private var quantityText: String {
        switch lineItem.quantityUnit {
        case .minutes:
            return "\(Int(lineItem.quantity)) min"
        case .hours:
            return "\(lineItem.quantity) hr"
        case .each:
            return "\(Int(lineItem.quantity))"
        case .bodyOfWater:
            return "\(Int(lineItem.quantity)) BOW"
        case .serviceLocation:
            return "\(Int(lineItem.quantity)) loc"
        case .percent:
            return "\(lineItem.quantity)%"
        }
    }
}

struct TechnicianPayrollStatementRow: View {
    var statement: TechnicianPayStatement

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(TechnicianPayrollDateFormatter.shortDate(statement.startDate)) - \(TechnicianPayrollDateFormatter.shortDate(statement.endDate))")
                    .font(.headline)

                Spacer()

                Text(TechnicianPayrollMoneyFormatter.money(statement.totalCents))
                    .font(.headline)
            }

            HStack {
                Text(statement.status.title)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())

                Spacer()

                Text("\(statement.lineItemIds.count) item(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct TechnicianPayrollRateRow: View {
    var rate: TechnicianRate
    var workTypeName: String
    var workTypeIcon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: workTypeIcon)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(workTypeName)
                        .font(.headline)

                    Text("\(rate.payBasis.title) • \(rate.rateType.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(TechnicianPayrollMoneyFormatter.money(rate.amountCents))
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

                Text(rateDateRangeText)
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

    private var rateDateRangeText: String {
        let start = TechnicianPayrollDateFormatter.shortDate(rate.effectiveStartDate)

        if let end = rate.effectiveEndDate {
            return "\(start) - \(TechnicianPayrollDateFormatter.shortDate(end))"
        }

        return "\(start) - Present"
    }
}

// MARK: - Formatters

enum TechnicianPayrollMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum TechnicianPayrollDateFormatter {
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
        TechnicianPayrollInfoView(
            companyId: "com_mock_company",
            companyUser: CompanyUser(
                id: "comp_user_mock",
                userId: "usr_marco",
                userName: "Marco",
                roleId: "role_tech",
                roleName: "Technician",
                dateCreated: Date(),
                status: .active,
                workerType: .employee,
                linkedCompanyId: nil,
                linkedCompanyName: nil
            ),
            dataService: MockDataService()
        )
    }
}
