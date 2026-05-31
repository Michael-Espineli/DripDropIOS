//
//  TechnicianPayStatementDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

// MARK: - ViewModel

@MainActor
final class TechnicianPayStatementDetailViewModel: ObservableObject {

    @Published var statement: TechnicianPayStatement
    @Published var lineItems: [TechnicianPayLineItem] = []

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    @Published var exportedCSVURL: URL?
    @Published var showShareSheet: Bool = false
    
    let companyId: String

    private let currentUserId: String
    private let dataService: any ProductionDataServiceProtocol
    private var hasLoaded = false

    init(
        statement: TechnicianPayStatement,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.statement = statement
        self.companyId = statement.companyId
        self.currentUserId = currentUserId
        self.dataService = dataService
    }

    var subtotalCents: Int {
        lineItems.reduce(0) { $0 + $1.totalAmountCents }
    }

    var adjustmentCents: Int {
        statement.adjustmentCents
    }

    var totalCents: Int {
        subtotalCents + adjustmentCents
    }

    var canApprove: Bool {
        statement.status == .draft
    }

    var canMarkPaid: Bool {
        statement.status != .paid &&
        statement.status != .voided
    }

    var canVoid: Bool {
        statement.status != .paid &&
        statement.status != .voided
    }

    var paidLineItemCount: Int {
        lineItems.filter { $0.calculationStatus == .paid }.count
    }

    var needsReviewLineItemCount: Int {
        lineItems.filter { $0.calculationStatus == .needsReview }.count
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
                payStatementId: statement.id
            )

            syncStatementTotalsFromLineItems()
        } catch {
            alertMessage = "Could not load statement details. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func approveStatement() async {
        guard canApprove else { return }

        var updated = statement
        updated.status = .approved
        updated.approvedAt = Date()
        updated.approvedByUserId = currentUserId

        await saveStatement(updated, successMessage: "Statement approved.")
    }

    func markStatementPaid() async {
        guard canMarkPaid else { return }

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
            updatedStatement.subtotalCents = subtotalCents
            updatedStatement.totalCents = totalCents

            try await dataService.saveTechnicianPayStatement(updatedStatement)
            statement = updatedStatement

            for lineItem in lineItems {
                var updatedLine = lineItem
                updatedLine.calculationStatus = .paid
                updatedLine.paidAt = Date()
                updatedLine.paidByUserId = currentUserId
                updatedLine.payStatementId = statement.id

                try await dataService.updateTechnicianPayLineItem(updatedLine)
                upsertLocalLineItem(updatedLine)
            }

            alertMessage = "Statement marked paid."
            showAlert = true
        } catch {
            alertMessage = "Could not mark statement paid. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func voidStatement() async {
        guard canVoid else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            var updatedStatement = statement
            updatedStatement.status = .voided
            updatedStatement.notes = appendNote(
                existingNote: updatedStatement.notes,
                newNote: "Voided by admin on \(TechnicianPayStatementDetailDateFormatter.shortDateTime(Date()))."
            )

            try await dataService.saveTechnicianPayStatement(updatedStatement)
            statement = updatedStatement

            for lineItem in lineItems {
                var updatedLine = lineItem

                // Paid line items should not be automatically detached or changed.
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

            alertMessage = "Statement voided. Unpaid line items were released back to payroll review."
            showAlert = true
        } catch {
            alertMessage = "Could not void statement. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func refreshTotalsAndSave() async {
        var updated = statement
        updated.subtotalCents = subtotalCents
        updated.totalCents = totalCents

        await saveStatement(updated, successMessage: "Statement totals updated.")
    }

    private func saveStatement(
        _ updatedStatement: TechnicianPayStatement,
        successMessage: String
    ) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.saveTechnicianPayStatement(updatedStatement)
            statement = updatedStatement
            alertMessage = successMessage
            showAlert = true
        } catch {
            alertMessage = "Could not update statement. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func syncStatementTotalsFromLineItems() {
        let currentSubtotal = subtotalCents
        let currentTotal = totalCents

        guard statement.subtotalCents != currentSubtotal ||
                statement.totalCents != currentTotal else {
            return
        }

        statement.subtotalCents = currentSubtotal
        statement.totalCents = currentTotal
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
    func exportCombinedCSV() {
        do {
            let result = try PayrollCSVExportService.exportCombinedStatementCSV(
                statement: statement,
                lineItems: lineItems
            )

            exportedCSVURL = result.fileURL
            showShareSheet = true
        } catch {
            alertMessage = "Could not export CSV. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func exportSummaryCSV() {
        do {
            let result = try PayrollCSVExportService.exportStatementSummary(
                statement: statement
            )

            exportedCSVURL = result.fileURL
            showShareSheet = true
        } catch {
            alertMessage = "Could not export summary CSV. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func exportLineItemsCSV() {
        do {
            let result = try PayrollCSVExportService.exportStatementLineItems(
                statement: statement,
                lineItems: lineItems
            )

            exportedCSVURL = result.fileURL
            showShareSheet = true
        } catch {
            alertMessage = "Could not export line items CSV. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - View

struct TechnicianPayStatementDetailView: View {

    @StateObject private var viewModel: TechnicianPayStatementDetailViewModel

    init(
        statement: TechnicianPayStatement,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TechnicianPayStatementDetailViewModel(
                statement: statement,
                currentUserId: currentUserId,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            totalsSection
            warningSection
            lineItemsSection
            exportSection
            notesSection
            actionsSection
        }
        .navigationTitle("Pay Statement")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading statement...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Pay Statement", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
        #if os(iOS)
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.exportedCSVURL {
                ShareSheet(activityItems: [url])
            } else {
                Text("No export file available.")
                    .presentationDetents([.medium])
            }
        }
        #endif
    }

    private var summarySection: some View {
        Section("Statement") {
            DetailFieldRow(
                title: "Technician",
                value: viewModel.statement.technicianName
            )

            DetailFieldRow(
                title: "Worker Type",
                value: viewModel.statement.workerType.rawValue
            )

            DetailFieldRow(
                title: "Status",
                value: viewModel.statement.status.title
            )

            DetailFieldRow(
                title: "Pay Period",
                value: "\(TechnicianPayStatementDetailDateFormatter.shortDate(viewModel.statement.startDate)) - \(TechnicianPayStatementDetailDateFormatter.shortDate(viewModel.statement.endDate))"
            )

            DetailFieldRow(
                title: "Line Items",
                value: "\(viewModel.lineItems.count)"
            )

            DetailFieldRow(
                title: "Statement ID",
                value: viewModel.statement.id
            )
        }
    }

    private var totalsSection: some View {
        Section("Totals") {
            DetailFieldRow(
                title: "Subtotal",
                value: TechnicianPayStatementDetailMoneyFormatter.money(viewModel.subtotalCents)
            )

            DetailFieldRow(
                title: "Adjustments",
                value: TechnicianPayStatementDetailMoneyFormatter.money(viewModel.adjustmentCents)
            )

            HStack {
                Text("Total")
                    .fontWeight(.semibold)

                Spacer()

                Text(TechnicianPayStatementDetailMoneyFormatter.money(viewModel.totalCents))
                    .fontWeight(.bold)
            }

            if viewModel.statement.subtotalCents != viewModel.subtotalCents ||
                viewModel.statement.totalCents != viewModel.totalCents {
                Button {
                    Task {
                        await viewModel.refreshTotalsAndSave()
                    }
                } label: {
                    Label("Update Saved Totals", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    @ViewBuilder
    private var warningSection: some View {
        if viewModel.needsReviewLineItemCount > 0 || viewModel.paidLineItemCount > 0 {
            Section("Warnings") {
                if viewModel.needsReviewLineItemCount > 0 {
                    Label(
                        "\(viewModel.needsReviewLineItemCount) line item(s) still need review.",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)
                }

                if viewModel.paidLineItemCount > 0 {
                    Label(
                        "\(viewModel.paidLineItemCount) line item(s) are already marked paid.",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundStyle(.green)
                }
            }
        }
    }

    private var lineItemsSection: some View {
        Section {
            if viewModel.lineItems.isEmpty {
                ContentUnavailableView(
                    "No Line Items",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("No pay line items are attached to this statement.")
                )
            } else {
                ForEach(viewModel.lineItems.sorted { $0.completedDate < $1.completedDate }) { lineItem in
                    TechnicianPayStatementLineItemRow(lineItem: lineItem)
                }
            }
        } header: {
            Text("Included Pay")
        } footer: {
            Text("These are the payroll line items attached to this statement.")
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if let notes = viewModel.statement.notes,
           !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Section("Notes") {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionsSection: some View {
        Section {
            if viewModel.canApprove {
                Button {
                    Task {
                        await viewModel.approveStatement()
                    }
                } label: {
                    Label("Approve Statement", systemImage: "checkmark.circle")
                }
                .disabled(viewModel.isSaving)
            }

            if viewModel.canMarkPaid {
                Button {
                    Task {
                        await viewModel.markStatementPaid()
                    }
                } label: {
                    Label("Mark Statement Paid", systemImage: "dollarsign.circle")
                }
                .disabled(viewModel.isSaving)
            }

            if viewModel.canVoid {
                Button(role: .destructive) {
                    Task {
                        await viewModel.voidStatement()
                    }
                } label: {
                    Label("Void Statement", systemImage: "xmark.circle")
                }
                .disabled(viewModel.isSaving)
            }
        } header: {
            Text("Actions")
        } footer: {
            Text("Marking a statement paid also marks its attached line items as paid. Voiding releases unpaid line items back to payroll review.")
        }
    }
    private var exportSection: some View {
        Section {
            Button {
                viewModel.exportCombinedCSV()
            } label: {
                Label("Export Statement CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.lineItems.isEmpty)

            Button {
                viewModel.exportSummaryCSV()
            } label: {
                Label("Export Summary CSV", systemImage: "doc.text")
            }

            Button {
                viewModel.exportLineItemsCSV()
            } label: {
                Label("Export Line Items CSV", systemImage: "list.bullet.rectangle")
            }
            .disabled(viewModel.lineItems.isEmpty)
        } header: {
            Text("Export")
        } footer: {
            Text("CSV exports can be used for payroll records, contractor statements, bank transfer notes, QuickBooks imports, or manual bookkeeping.")
        }
    }
}

// MARK: - Line Item Row

struct TechnicianPayStatementLineItemRow: View {
    var lineItem: TechnicianPayLineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lineItem.displayTitle ?? lineItem.customerName ?? lineItem.workTypeName ?? "Payroll Line")
                        .font(.headline)

                    Text(lineItem.displaySubtitle ?? sourceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(TechnicianPayStatementDetailMoneyFormatter.money(lineItem.totalAmountCents))
                    .fontWeight(.semibold)
            }

            HStack {
                Text("Rate: \(TechnicianPayStatementDetailMoneyFormatter.money(lineItem.rateAmountCents))")
                Spacer()
                Text("Qty: \(quantityText)")
                Spacer()
                Text(lineItem.calculationStatus.title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(TechnicianPayStatementDetailDateFormatter.shortDate(lineItem.completedDate))
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if let lineReference = lineItem.lineReference,
               !lineReference.isEmpty {
                Text(lineReference)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            if let paymentReference = lineItem.paymentReference,
               !paymentReference.isEmpty {
                Text("Payment Ref: \(paymentReference)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
            }
            if let notes = lineItem.notes,
               !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let adminReviewNotes = lineItem.adminReviewNotes,
               !adminReviewNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(adminReviewNotes)
                    .font(.caption)
                    .foregroundStyle(.orange)
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

// MARK: - Shared Row

struct DetailFieldRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Formatters

enum TechnicianPayStatementDetailMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum TechnicianPayStatementDetailDateFormatter {
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
        TechnicianPayStatementDetailView(
            statement: TechnicianPayStatement(
                id: "comp_pay_stmt_mock_001",
                companyId: "com_mock_company",
                technicianId: "usr_marco",
                technicianName: "Marco",
                workerType: .employee,
                startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                endDate: Date(),
                lineItemIds: [
                    "comp_pay_line_mock_001",
                    "comp_pay_line_mock_002"
                ],
                subtotalCents: 9600,
                adjustmentCents: 0,
                totalCents: 9600,
                status: .draft,
                createdAt: Date(),
                createdByUserId: "mock_admin_user",
                approvedAt: nil,
                approvedByUserId: nil,
                paidAt: nil,
                paidByUserId: nil,
                exportedAt: nil,
                exportProvider: nil,
                externalReferenceId: nil,
                notes: nil,
                statementNumber: 1,
                statementReference: "REF_001"
            ),
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
            
        )
    }
    
}
