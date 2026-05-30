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

    let companyId: String

    init(companyId: String) {
        self.companyId = companyId
        loadMockData()
    }

    var filteredLineItems: [TechnicianPayLineItem] {
        switch selectedFilter {
        case .outstanding:
            return lineItems.filter {
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .needsReview ||
                $0.calculationStatus == .adjusted ||
                $0.calculationStatus == .pending
            }

        case .needsReview:
            return lineItems.filter { $0.calculationStatus == .needsReview }

        case .approved:
            return lineItems.filter { $0.calculationStatus == .approved }

        case .paid:
            return lineItems.filter { $0.calculationStatus == .paid }

        case .all:
            return lineItems
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
                $0.calculationStatus == .calculated ||
                $0.calculationStatus == .needsReview ||
                $0.calculationStatus == .adjusted ||
                $0.calculationStatus == .pending
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

    func approve(_ lineItem: TechnicianPayLineItem) {
        update(lineItem) { item in
            item.calculationStatus = .approved
            item.approvedAt = Date()
            item.approvedByUserId = "mock_admin_user"
        }
    }

    func markPaid(_ lineItem: TechnicianPayLineItem) {
        update(lineItem) { item in
            item.calculationStatus = .paid
            item.paidAt = Date()
            item.paidByUserId = "mock_admin_user"
        }
    }

    func void(_ lineItem: TechnicianPayLineItem) {
        update(lineItem) { item in
            item.calculationStatus = .voided
            item.adminReviewNotes = "Voided from mock payroll queue."
        }
    }

    func approveAllVisible() {
        let visibleIds = Set(filteredLineItems.map { $0.id })

        for index in lineItems.indices {
            if visibleIds.contains(lineItems[index].id),
               lineItems[index].calculationStatus != .paid,
               lineItems[index].calculationStatus != .voided {
                lineItems[index].calculationStatus = .approved
                lineItems[index].approvedAt = Date()
                lineItems[index].approvedByUserId = "mock_admin_user"
            }
        }
    }

    private func update(
        _ lineItem: TechnicianPayLineItem,
        mutation: (inout TechnicianPayLineItem) -> Void
    ) {
        guard let index = lineItems.firstIndex(where: { $0.id == lineItem.id }) else {
            return
        }

        mutation(&lineItems[index])
    }

    private func loadMockData() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now

        lineItems = [
            TechnicianPayLineItem(
                id: "comp_pay_line_mock_001",
                companyId: companyId,
                technicianId: "usr_marco",
                technicianName: "Marco",
                workerType: .employee,
                source: .serviceStop,
                serviceStopId: "comp_ss_mock_001",
                serviceStopTaskId: nil,
                activeRouteId: nil,
                activeRouteLogId: nil,
                workTypeId: "comp_work_type_routes",
                workTypeName: "Routes",
                rateId: "comp_tech_rate_mock_001",
                rateAmountCents: 1600,
                rateType: .flatPerStop,
                quantity: 1,
                quantityUnit: .each,
                totalAmountCents: 1600,
                completedDate: twoDaysAgo,
                calculatedAt: now,
                calculationStatus: .calculated,
                approvedAt: nil,
                approvedByUserId: nil,
                paidAt: nil,
                paidByUserId: nil,
                payStatementId: nil,
                exportBatchId: nil,
                notes: "Generated from finished recurring service stop.",
                adminReviewNotes: nil
            ),
            TechnicianPayLineItem(
                id: "comp_pay_line_mock_002",
                companyId: companyId,
                technicianId: "usr_marco",
                technicianName: "Marco",
                workerType: .employee,
                source: .serviceStopTask,
                serviceStopId: "comp_ss_mock_001",
                serviceStopTaskId: "comp_ss_task_mock_001",
                activeRouteId: nil,
                activeRouteLogId: nil,
                workTypeId: "comp_work_type_filter",
                workTypeName: "Clean Filter",
                rateId: "comp_tech_rate_mock_002",
                rateAmountCents: 8000,
                rateType: .flatPerTask,
                quantity: 1,
                quantityUnit: .each,
                totalAmountCents: 8000,
                completedDate: twoDaysAgo,
                calculatedAt: now,
                calculationStatus: .calculated,
                approvedAt: nil,
                approvedByUserId: nil,
                paidAt: nil,
                paidByUserId: nil,
                payStatementId: nil,
                exportBatchId: nil,
                notes: "Route plus filter cleaning.",
                adminReviewNotes: nil
            ),
            TechnicianPayLineItem(
                id: "comp_pay_line_mock_003",
                companyId: companyId,
                technicianId: "usr_anna",
                technicianName: "Anna",
                workerType: .contractor,
                source: .serviceStopTask,
                serviceStopId: "comp_ss_mock_002",
                serviceStopTaskId: "comp_ss_task_mock_002",
                activeRouteId: nil,
                activeRouteLogId: nil,
                workTypeId: nil,
                workTypeName: nil,
                rateId: nil,
                rateAmountCents: 0,
                rateType: .manual,
                quantity: 0,
                quantityUnit: .each,
                totalAmountCents: 0,
                completedDate: yesterday,
                calculatedAt: now,
                calculationStatus: .needsReview,
                approvedAt: nil,
                approvedByUserId: nil,
                paidAt: nil,
                paidByUserId: nil,
                payStatementId: nil,
                exportBatchId: nil,
                notes: "No WorkTypeMapping found for task type: Repair.",
                adminReviewNotes: nil
            ),
            TechnicianPayLineItem(
                id: "comp_pay_line_mock_004",
                companyId: companyId,
                technicianId: "usr_caleb",
                technicianName: "Caleb",
                workerType: .contractor,
                source: .serviceStop,
                serviceStopId: "comp_ss_mock_003",
                serviceStopTaskId: nil,
                activeRouteId: nil,
                activeRouteLogId: nil,
                workTypeId: "comp_work_type_service_call",
                workTypeName: "Service Call",
                rateId: "comp_tech_rate_mock_004",
                rateAmountCents: 5000,
                rateType: .flatPerStop,
                quantity: 1,
                quantityUnit: .each,
                totalAmountCents: 5000,
                completedDate: yesterday,
                calculatedAt: now,
                calculationStatus: .approved,
                approvedAt: now,
                approvedByUserId: "mock_admin_user",
                paidAt: nil,
                paidByUserId: nil,
                payStatementId: nil,
                exportBatchId: nil,
                notes: "Approved contractor service call.",
                adminReviewNotes: nil
            ),
            TechnicianPayLineItem(
                id: "comp_pay_line_mock_005",
                companyId: companyId,
                technicianId: "usr_jose",
                technicianName: "Jose",
                workerType: .employee,
                source: .activeRoute,
                serviceStopId: nil,
                serviceStopTaskId: nil,
                activeRouteId: "comp_active_route_mock_001",
                activeRouteLogId: nil,
                workTypeId: nil,
                workTypeName: "Hourly Route Time",
                rateId: "comp_tech_rate_mock_005",
                rateAmountCents: 2500,
                rateType: .hourly,
                quantity: 480,
                quantityUnit: .minutes,
                totalAmountCents: 20000,
                completedDate: yesterday,
                calculatedAt: now,
                calculationStatus: .paid,
                approvedAt: yesterday,
                approvedByUserId: "mock_admin_user",
                paidAt: now,
                paidByUserId: "mock_admin_user",
                payStatementId: "comp_pay_stmt_mock_001",
                exportBatchId: nil,
                notes: "Generated from ActiveRoute duration.",
                adminReviewNotes: nil
            )
        ]
    }
}

struct CompanyPayrollReviewQueueView: View {
    @StateObject private var viewModel: CompanyPayrollReviewQueueViewModel

    init(companyId: String) {
        _viewModel = StateObject(
            wrappedValue: CompanyPayrollReviewQueueViewModel(companyId: companyId)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                summarySection
                filterSection
                queueSection
            }
            .navigationTitle("Payroll Review")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Approve Visible") {
                        viewModel.approveAllVisible()
                    }
                }
            }
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            PayrollSummaryRow(
                title: "Outstanding",
                value: money(viewModel.outstandingTotalCents)
            )

            PayrollSummaryRow(
                title: "Needs Review",
                value: "\(viewModel.needsReviewCount)"
            )

            PayrollSummaryRow(
                title: "Approved",
                value: money(viewModel.approvedTotalCents)
            )

            PayrollSummaryRow(
                title: "Paid",
                value: money(viewModel.paidTotalCents)
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

    private var queueSection: some View {
        ForEach(viewModel.groups) { group in
            Section {
                ForEach(group.lineItems) { lineItem in
                    PayrollLineItemReviewRow(
                        lineItem: lineItem,
                        approveAction: {
                            viewModel.approve(lineItem)
                        },
                        markPaidAction: {
                            viewModel.markPaid(lineItem)
                        },
                        voidAction: {
                            viewModel.void(lineItem)
                        }
                    )
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.technicianName)
                    Text("\(group.workerType.rawValue) • \(money(group.totalCents))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func money(_ cents: Int) -> String {
        MoneyFormatter.money(cents)
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
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lineItem.workTypeName ?? "Missing Work Type")
                        .font(.headline)

                    Text(lineItem.source.rawValue)
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

            HStack {
                Text("Rate: \(MoneyFormatter.money(lineItem.rateAmountCents))")
                Spacer()
                Text("Qty: \(quantityText)")
                Spacer()
                Text(MoneyFormatter.money(lineItem.totalAmountCents))
                    .fontWeight(.semibold)
            }
            .font(.caption)

            if let notes = lineItem.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            Button("Paid") {
                markPaidAction()
            }

            Button("Approve") {
                approveAction()
            }

            Button("Void", role: .destructive) {
                voidAction()
            }
        }
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

enum MoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

#Preview {
    CompanyPayrollReviewQueueView(
        companyId: "com_mock_company"
    )
}
