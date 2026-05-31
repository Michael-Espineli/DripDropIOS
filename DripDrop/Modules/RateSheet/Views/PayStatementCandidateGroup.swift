//
//  PayStatementCandidateGroup.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/21/26.
//



import SwiftUI

// MARK: - Statement Candidate

struct PayStatementCandidateGroup: Identifiable {
    var id: String { technicianId }

    var technicianId: String
    var technicianName: String
    var workerType: WorkerTypeEnum
    var lineItems: [TechnicianPayLineItem]

    var subtotalCents: Int {
        lineItems.reduce(0) { $0 + $1.totalAmountCents }
    }
}

// MARK: - Statement Filter

enum PayStatementListFilter: String, CaseIterable, Identifiable {
    case candidates = "Ready"
    case draft = "Draft"
    case approved = "Approved"
    case paid = "Paid"
    case all = "All"

    var id: String { rawValue }
}

// MARK: - ViewModel

@MainActor
final class CompanyPayStatementsViewModel: ObservableObject {

    @Published var lineItems: [TechnicianPayLineItem] = []
    @Published var statements: [TechnicianPayStatement] = []

    @Published var selectedFilter: PayStatementListFilter = .candidates

    @Published var startDate: Date
    @Published var endDate: Date

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String
    
    let currentUserId: String
    let dataService: any ProductionDataServiceProtocol
    
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
        self.startDate = Calendar.current.date(byAdding: .day, value: -14, to: today) ?? today
        self.endDate = today
    }

    var candidateLineItems: [TechnicianPayLineItem] {
        lineItems.filter {
            $0.calculationStatus == .approved &&
            $0.payStatementId == nil &&
            $0.paidAt == nil
        }
    }

    var candidateGroups: [PayStatementCandidateGroup] {
        let grouped = Dictionary(grouping: candidateLineItems) { $0.technicianId }

        return grouped.map { technicianId, items in
            let first = items.first

            return PayStatementCandidateGroup(
                technicianId: technicianId,
                technicianName: first?.technicianName ?? "Unknown",
                workerType: first?.workerType ?? .notAssigned,
                lineItems: items.sorted { $0.completedDate < $1.completedDate }
            )
        }
        .sorted { $0.technicianName < $1.technicianName }
    }

    var filteredStatements: [TechnicianPayStatement] {
        let filtered: [TechnicianPayStatement]

        switch selectedFilter {
        case .candidates:
            filtered = []
        case .draft:
            filtered = statements.filter { $0.status == .draft }
        case .approved:
            filtered = statements.filter { $0.status == .approved }
        case .paid:
            filtered = statements.filter { $0.status == .paid }
        case .all:
            filtered = statements
        }

        return filtered.sorted {
            if $0.startDate == $1.startDate {
                return $0.technicianName < $1.technicianName
            }

            return $0.startDate > $1.startDate
        }
    }

    var readyTotalCents: Int {
        candidateLineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var statementTotalCents: Int {
        filteredStatements.reduce(0) { $0 + $1.totalCents }
    }

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let lineItemsTask = dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )

            async let statementsTask = dataService.fetchTechnicianPayStatements(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )

            lineItems = try await lineItemsTask
            statements = try await statementsTask
        } catch {
            alertMessage = "Could not load pay statements. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func createStatement(for group: PayStatementCandidateGroup) async {
        guard !group.lineItems.isEmpty else {
            alertMessage = "There are no approved pay items for this technician."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }
        do {
            let statementNumber = try await dataService.getNextPayStatementNumber(companyId: companyId)
            let statementReference = PayrollReferenceFormatter.statement(statementNumber)
            
            let statementId = PayrollIdFactory.technicianPayStatementId()
            let subtotal = group.subtotalCents

            let statement = TechnicianPayStatement(
                id: statementId,
                companyId: companyId,
                technicianId: group.technicianId,
                technicianName: group.technicianName,
                workerType: group.workerType,
                startDate: startDate,
                endDate: endDate,
                lineItemIds: group.lineItems.map { $0.id },
                subtotalCents: subtotal,
                adjustmentCents: 0,
                totalCents: subtotal,
                status: .draft,
                createdAt: Date(),
                createdByUserId: currentUserId,
                approvedAt: nil,
                approvedByUserId: nil,
                paidAt: nil,
                paidByUserId: nil,
                exportedAt: nil,
                exportProvider: nil,
                externalReferenceId: nil,
                notes: nil,
                statementNumber: statementNumber,
                statementReference: statementReference,
                paymentReference: nil,
                paidNotes: nil
            )

            try await dataService.saveTechnicianPayStatement(statement)

            for lineItem in group.lineItems {
                var updatedLineItem = lineItem
                updatedLineItem.payStatementId = statementId

                try await dataService.updateTechnicianPayLineItem(updatedLineItem)
                upsertLocalLineItem(updatedLineItem)
            }

            statements.append(statement)

            alertMessage = "Created pay statement for \(group.technicianName)."
            showAlert = true
        } catch {
            alertMessage = "Could not create pay statement. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func approveStatement(_ statement: TechnicianPayStatement) async {
        var updated = statement
        updated.status = .approved
        updated.approvedAt = Date()
        updated.approvedByUserId = currentUserId

        await saveStatementUpdate(updated)
    }

    func markStatementPaid(_ statement: TechnicianPayStatement) async {
        isSaving = true
        defer { isSaving = false }

        do {
            var updatedStatement = statement

            if updatedStatement.approvedAt == nil {
                updatedStatement.approvedAt = Date()
                updatedStatement.approvedByUserId = currentUserId
            }

            updatedStatement.status = .paid
            updatedStatement.paidAt = Date()
            updatedStatement.paidByUserId = currentUserId

            try await dataService.saveTechnicianPayStatement(updatedStatement)
            upsertLocalStatement(updatedStatement)

            let statementLineItems = try await dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                payStatementId: statement.id
            )

            for lineItem in statementLineItems {
                var updatedLine = lineItem
                updatedLine.calculationStatus = .paid
                updatedLine.paidAt = Date()
                updatedLine.paidByUserId = currentUserId

                try await dataService.updateTechnicianPayLineItem(updatedLine)
                upsertLocalLineItem(updatedLine)
            }

            alertMessage = "Marked statement paid."
            showAlert = true
        } catch {
            alertMessage = "Could not mark statement paid. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func voidStatement(_ statement: TechnicianPayStatement) async {
        isSaving = true
        defer { isSaving = false }

        do {
            var updatedStatement = statement
            updatedStatement.status = .voided
            updatedStatement.notes = appendNote(
                existingNote: updatedStatement.notes,
                newNote: "Voided by admin on \(PayStatementDateFormatter.shortDateTime(Date()))."
            )

            try await dataService.saveTechnicianPayStatement(updatedStatement)
            upsertLocalStatement(updatedStatement)

            let statementLineItems = try await dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                payStatementId: statement.id
            )

            for lineItem in statementLineItems {
                var updatedLine = lineItem

                // Return unpaid lines back to approved/unstatemented queue.
                if updatedLine.calculationStatus != .paid {
                    updatedLine.payStatementId = nil
                    updatedLine.adminReviewNotes = appendNote(
                        existingNote: updatedLine.adminReviewNotes,
                        newNote: "Removed from voided pay statement \(statement.id)."
                    )

                    try await dataService.updateTechnicianPayLineItem(updatedLine)
                    upsertLocalLineItem(updatedLine)
                }
            }

            alertMessage = "Voided pay statement."
            showAlert = true
        } catch {
            alertMessage = "Could not void pay statement. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func createAllCandidateStatements() async {
        guard !candidateGroups.isEmpty else {
            alertMessage = "There are no approved pay items ready for statements."
            showAlert = true
            return
        }

        for group in candidateGroups {
            await createStatement(for: group)
        }
    }

    private func saveStatementUpdate(_ statement: TechnicianPayStatement) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.saveTechnicianPayStatement(statement)
            upsertLocalStatement(statement)
        } catch {
            alertMessage = "Could not update statement. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func upsertLocalStatement(_ statement: TechnicianPayStatement) {
        if let index = statements.firstIndex(where: { $0.id == statement.id }) {
            statements[index] = statement
        } else {
            statements.append(statement)
        }
    }

    private func upsertLocalLineItem(_ lineItem: TechnicianPayLineItem) {
        if let index = lineItems.firstIndex(where: { $0.id == lineItem.id }) {
            lineItems[index] = lineItem
        } else {
            lineItems.append(lineItem)
        }
    }

    private func appendNote(
        existingNote: String?,
        newNote: String
    ) -> String {
        guard let existingNote,
              !existingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return newNote
        }

        return existingNote + "\n" + newNote
    }
}

// MARK: - View

struct CompanyPayStatementsView: View {

    @StateObject private var viewModel: CompanyPayStatementsViewModel
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager: MasterDataManager

    init(
        companyId: String,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: CompanyPayStatementsViewModel(
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

            if viewModel.selectedFilter == .candidates {
                candidateSection
            } else {
                statementsSection
            }
        }
        .navigationTitle("Pay Statements")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.selectedFilter == .candidates {
                    Button("Create All") {
                        Task {
                            await viewModel.createAllCandidateStatements()
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.candidateGroups.isEmpty)
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
                ProgressView("Loading statements...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Pay Statements", isPresented: $viewModel.showAlert) {
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
            PayStatementSummaryRow(
                title: "Ready for Statements",
                value: PayStatementMoneyFormatter.money(viewModel.readyTotalCents)
            )

            PayStatementSummaryRow(
                title: "Ready Technicians",
                value: "\(viewModel.candidateGroups.count)"
            )

            if viewModel.selectedFilter != .candidates {
                PayStatementSummaryRow(
                    title: "Filtered Statements",
                    value: "\(viewModel.filteredStatements.count)"
                )

                PayStatementSummaryRow(
                    title: "Filtered Total",
                    value: PayStatementMoneyFormatter.money(viewModel.statementTotalCents)
                )
            }
        }
    }

    private var filterSection: some View {
        Section {
            Picker("View", selection: $viewModel.selectedFilter) {
                ForEach(PayStatementListFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var candidateSection: some View {
        Section {
            if viewModel.candidateGroups.isEmpty {
                ContentUnavailableView(
                    "No Approved Pay Ready",
                    systemImage: "doc.text",
                    description: Text("Approve pay line items in the Payroll Review Queue before creating pay statements.")
                )
            } else {
                ForEach(viewModel.candidateGroups) { group in
                    PayStatementCandidateRow(
                        group: group,
                        createAction: {
                            Task {
                                await viewModel.createStatement(for: group)
                            }
                        }
                    )
                }
            }
        } header: {
            Text("Ready to Create")
        } footer: {
            Text("Only approved, unpaid line items that are not already attached to a statement appear here.")
        }
    }

    private var statementsSection: some View {
        Section {
            if viewModel.filteredStatements.isEmpty {
                ContentUnavailableView(
                    "No Statements",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("No pay statements match this filter and date range.")
                )
            } else {
                if let user = masterDataManager.user {
                    ForEach(viewModel.filteredStatements) { statement in
                        NavigationLink {
                            TechnicianPayStatementDetailView(
                                statement: statement,
                                currentUserId: user.id,
                                dataService: dataService
                            )
                        } label: {
                            PayStatementRow(
                                statement: statement,
                                approveAction: {
                                    Task {
                                        await viewModel.approveStatement(statement)
                                    }
                                },
                                markPaidAction: {
                                    Task {
                                        await viewModel.markStatementPaid(statement)
                                    }
                                },
                                voidAction: {
                                    Task {
                                        await viewModel.voidStatement(statement)
                                    }
                                }
                            )
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Statements")
        }
    }
}

// MARK: - Rows

struct PayStatementCandidateRow: View {
    var group: PayStatementCandidateGroup
    var createAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.technicianName)
                        .font(.headline)

                    Text("\(group.workerType.rawValue) • \(group.lineItems.count) item(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(PayStatementMoneyFormatter.money(group.subtotalCents))
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(group.lineItems.prefix(3)) { item in
                    Text("• \(item.workTypeName ?? "Missing Work Type") — \(PayStatementMoneyFormatter.money(item.totalAmountCents))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if group.lineItems.count > 3 {
                    Text("+ \(group.lineItems.count - 3) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                createAction()
            } label: {
                Label("Create Statement", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }
}

struct PayStatementRow: View {
    var statement: TechnicianPayStatement

    var approveAction: () -> Void
    var markPaidAction: () -> Void
    var voidAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(statement.technicianName)
                        .font(.headline)

                    Text("\(statement.workerType.rawValue) • \(statement.lineItemIds.count) item(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(PayStatementMoneyFormatter.money(statement.totalCents))
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

                Text("\(PayStatementDateFormatter.shortDate(statement.startDate)) - \(PayStatementDateFormatter.shortDate(statement.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let notes = statement.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .swipeActions(edge: .trailing) {
            if statement.status != .paid && statement.status != .voided {
                Button("Paid") {
                    markPaidAction()
                }
            }

            if statement.status == .draft {
                Button("Approve") {
                    approveAction()
                }
            }

            if statement.status != .paid && statement.status != .voided {
                Button("Void", role: .destructive) {
                    voidAction()
                }
            }
        }
    }
}

struct PayStatementSummaryRow: View {
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

// MARK: - Formatters

enum PayStatementMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum PayStatementDateFormatter {
    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CompanyPayStatementsView(
            companyId: "com_mock_company",
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
        )
    }
}
