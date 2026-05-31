//
//  CompanyPayrollReviewQueueView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//
import SwiftUI

enum PayrollQueueFilter: String, CaseIterable, Identifiable {
    case outstanding = "Outstanding"
    case needsReview = "Needs Review"
    case approved = "Approved"
    case paid = "Paid"
    case all = "All"

    var id: String { rawValue }
}

struct PayrollReviewTechnicianGroup: Identifiable {
    var id: String { technicianId }

    var technicianId: String
    var technicianName: String
    var workerType: WorkerTypeEnum
    var lineItems: [TechnicianPayLineItem]

    var totalCents: Int {
        lineItems.reduce(0) { $0 + $1.totalAmountCents }
    }
}

@MainActor
final class CompanyPayrollReviewQueueViewModel: ObservableObject {

    @Published var lineItems: [TechnicianPayLineItem] = []
    @Published var selectedFilter: PayrollQueueFilter = .outstanding

    @Published var startDate: Date
    @Published var endDate: Date

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String

    private let currentUserId: String
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

        let today = Date()
        self.startDate = Calendar.current.date(
            byAdding: .day,
            value: -14,
            to: today
        ) ?? today
        self.endDate = today
    }

    var filteredLineItems: [TechnicianPayLineItem] {
        let filteredByStatus: [TechnicianPayLineItem]

        switch selectedFilter {
        case .outstanding:
            filteredByStatus = lineItems.filter {
                $0.calculationStatus == .pending ||
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .needsReview ||
                $0.calculationStatus == .adjusted
            }

        case .needsReview:
            filteredByStatus = lineItems.filter {
                $0.calculationStatus == .needsReview
            }

        case .approved:
            filteredByStatus = lineItems.filter {
                $0.calculationStatus == .approved
            }

        case .paid:
            filteredByStatus = lineItems.filter {
                $0.calculationStatus == .paid
            }

        case .all:
            filteredByStatus = lineItems
        }

        return filteredByStatus.sorted {
            if $0.completedDate == $1.completedDate {
                return $0.technicianName < $1.technicianName
            }

            return $0.completedDate < $1.completedDate
        }
    }

    var groups: [PayrollReviewTechnicianGroup] {
        let grouped = Dictionary(grouping: filteredLineItems) { $0.technicianId }

        return grouped.map { technicianId, items in
            let first = items.first

            return PayrollReviewTechnicianGroup(
                technicianId: technicianId,
                technicianName: first?.technicianName ?? "Unknown",
                workerType: first?.workerType ?? .notAssigned,
                lineItems: items.sorted { $0.completedDate < $1.completedDate }
            )
        }
        .sorted { $0.technicianName < $1.technicianName }
    }

    var outstandingTotalCents: Int {
        lineItems
            .filter {
                $0.calculationStatus == .pending ||
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .needsReview ||
                $0.calculationStatus == .adjusted
            }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var needsReviewCount: Int {
        lineItems.filter { $0.calculationStatus == .needsReview }.count
    }

    var approvedTotalCents: Int {
        lineItems
            .filter { $0.calculationStatus == .approved }
            .reduce(0) { $0 + $1.totalAmountCents }
    }

    var paidTotalCents: Int {
        lineItems
            .filter { $0.calculationStatus == .paid }
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
            lineItems = try await dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            alertMessage = "Could not load payroll queue. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func approve(_ lineItem: TechnicianPayLineItem) async {
        var updated = lineItem
        updated.calculationStatus = .approved
        updated.approvedAt = Date()
        updated.approvedByUserId = currentUserId

        await saveUpdatedLineItem(updated)
    }

    func markPaid(_ lineItem: TechnicianPayLineItem) async {
        var updated = lineItem

        if updated.approvedAt == nil {
            updated.approvedAt = Date()
            updated.approvedByUserId = currentUserId
        }

        updated.calculationStatus = .paid
        updated.paidAt = Date()
        updated.paidByUserId = currentUserId

        await saveUpdatedLineItem(updated)
    }

    func void(_ lineItem: TechnicianPayLineItem) async {
        var updated = lineItem
        updated.calculationStatus = .voided

        let existingNotes = updated.adminReviewNotes ?? ""
        let newNote = "Voided by admin on \(PayrollDateFormatter.shortDate(Date()))."

        updated.adminReviewNotes = existingNotes.isEmpty
            ? newNote
            : existingNotes + "\n" + newNote

        await saveUpdatedLineItem(updated)
    }

    func approveAllVisible() async {
        let visibleItems = filteredLineItems.filter {
            $0.calculationStatus != .paid &&
            $0.calculationStatus != .voided &&
            $0.calculationStatus != .approved
        }

        guard !visibleItems.isEmpty else {
            alertMessage = "There are no visible items to approve."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            for item in visibleItems {
                var updated = item
                updated.calculationStatus = .approved
                updated.approvedAt = Date()
                updated.approvedByUserId = currentUserId

                try await dataService.updateTechnicianPayLineItem(updated)
                upsertLocal(updated)
            }
        } catch {
            alertMessage = "Could not approve all visible items. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func saveUpdatedLineItem(_ lineItem: TechnicianPayLineItem) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.updateTechnicianPayLineItem(lineItem)
            upsertLocal(lineItem)
        } catch {
            alertMessage = "Could not update payroll item. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func upsertLocal(_ lineItem: TechnicianPayLineItem) {
        if let index = lineItems.firstIndex(where: { $0.id == lineItem.id }) {
            lineItems[index] = lineItem
        } else {
            lineItems.append(lineItem)
        }
    }
}

struct CompanyPayrollReviewQueueView: View {

    @StateObject private var viewModel: CompanyPayrollReviewQueueViewModel

    init(
        companyId: String,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyPayrollReviewQueueViewModel(
                companyId: companyId,
                currentUserId: currentUserId,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            dateRangeSection
            summarySection
            filterSection
            queueSection
        }
        .navigationTitle("Payroll Review")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Approve Visible") {
                    Task {
                        await viewModel.approveAllVisible()
                    }
                }
                .disabled(viewModel.isSaving)
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
                ProgressView("Loading payroll...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Payroll Review", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
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
                Label("Load Pay Period", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Pay Period")
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            PayrollSummaryRow(
                title: "Outstanding",
                value: PayrollMoneyFormatter.money(viewModel.outstandingTotalCents)
            )

            PayrollSummaryRow(
                title: "Needs Review",
                value: "\(viewModel.needsReviewCount)"
            )

            PayrollSummaryRow(
                title: "Approved",
                value: PayrollMoneyFormatter.money(viewModel.approvedTotalCents)
            )

            PayrollSummaryRow(
                title: "Paid",
                value: PayrollMoneyFormatter.money(viewModel.paidTotalCents)
            )
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Queue", selection: $viewModel.selectedFilter) {
                ForEach(PayrollQueueFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var queueSection: some View {
        if viewModel.groups.isEmpty {
            Section {
                ContentUnavailableView(
                    "No Payroll Items",
                    systemImage: "checklist",
                    description: Text("No payroll line items match this filter and date range.")
                )
            }
        } else {
            ForEach(viewModel.groups) { group in
                Section {
                    ForEach(group.lineItems) { lineItem in
                        PayrollLineItemReviewRow(
                            lineItem: lineItem,
                            approveAction: {
                                Task {
                                    await viewModel.approve(lineItem)
                                }
                            },
                            markPaidAction: {
                                Task {
                                    await viewModel.markPaid(lineItem)
                                }
                            },
                            voidAction: {
                                Task {
                                    await viewModel.void(lineItem)
                                }
                            }
                        )
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.technicianName)

                        Text("\(group.workerType.rawValue) • \(PayrollMoneyFormatter.money(group.totalCents))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct PayrollSummaryRow: View {
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

struct PayrollLineItemReviewRow: View {
    var lineItem: TechnicianPayLineItem

    var approveAction: () -> Void
    var markPaidAction: () -> Void
    var voidAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            amountRow

            if let notes = lineItem.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let adminReviewNotes = lineItem.adminReviewNotes,
               !adminReviewNotes.isEmpty {
                Text(adminReviewNotes)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            if lineItem.calculationStatus != .paid &&
                lineItem.calculationStatus != .voided {
                Button("Paid") {
                    markPaidAction()
                }
            }

            if lineItem.calculationStatus != .approved &&
                lineItem.calculationStatus != .paid &&
                lineItem.calculationStatus != .voided {
                Button("Approve") {
                    approveAction()
                }
            }

            if lineItem.calculationStatus != .paid &&
                lineItem.calculationStatus != .voided {
                Button("Void", role: .destructive) {
                    voidAction()
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lineItem.workTypeName ?? "Missing Work Type")
                    .font(.headline)

                Text(sourceSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(lineItem.calculationStatus.title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
    }

    private var amountRow: some View {
        HStack {
            Text("Rate: \(PayrollMoneyFormatter.money(lineItem.rateAmountCents))")
            Spacer()
            Text("Qty: \(quantityText)")
            Spacer()
            Text(PayrollMoneyFormatter.money(lineItem.totalAmountCents))
                .fontWeight(.semibold)
        }
        .font(.caption)
    }

    private var sourceSubtitle: String {
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

enum PayrollMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum PayrollDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        CompanyPayrollReviewQueueView(
            companyId: "com_mock_company",
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
        )
    }
}
