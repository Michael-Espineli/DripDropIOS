//
//  PayrollExportsView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

enum PayrollExportStatementFilter: String, CaseIterable, Identifiable {
    case paid = "Paid"
    case approved = "Approved"
    case exported = "Exported"
    case all = "All"

    var id: String { rawValue }
}

@MainActor
final class PayrollExportsViewModel: ObservableObject {

    @Published var statements: [TechnicianPayStatement] = []
    @Published var lineItems: [TechnicianPayLineItem] = []

    @Published var selectedFilter: PayrollExportStatementFilter = .paid

    @Published var startDate: Date
    @Published var endDate: Date

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    @Published var exportedCSVURL: URL?
    @Published var showShareSheet: Bool = false

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

    var filteredStatements: [TechnicianPayStatement] {
        let filtered: [TechnicianPayStatement]

        switch selectedFilter {
        case .paid:
            filtered = statements.filter { $0.status == .paid }

        case .approved:
            filtered = statements.filter { $0.status == .approved }

        case .exported:
            filtered = statements.filter { $0.status == .exported }

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

    var filteredStatementIds: Set<String> {
        Set(filteredStatements.map { $0.id })
    }

    var filteredLineItems: [TechnicianPayLineItem] {
        lineItems.filter { item in
            guard let payStatementId = item.payStatementId else {
                return false
            }

            return filteredStatementIds.contains(payStatementId)
        }
    }

    var filteredTotalCents: Int {
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
            statements = try await dataService.fetchTechnicianPayStatements(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )

            lineItems = try await dataService.fetchTechnicianPayLineItems(
                companyId: companyId,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            alertMessage = "Could not load payroll exports. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func exportStatementsSummaryCSV() {
        do {
            let result = try PayrollCSVExportService.exportStatementsSummary(
                statements: filteredStatements,
                fileLabel: "payroll_statements_\(PayrollExportsDateFormatter.fileDate(startDate))_to_\(PayrollExportsDateFormatter.fileDate(endDate))"
            )

            exportedCSVURL = result.fileURL
            showShareSheet = true
        } catch {
            alertMessage = "Could not export statements CSV. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func exportLineItemsCSV() {
        do {
            let result = try exportFilteredLineItemsCSV()
            exportedCSVURL = result.fileURL
            showShareSheet = true
        } catch {
            alertMessage = "Could not export line items CSV. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func markFilteredStatementsExported() async {
        guard !filteredStatements.isEmpty else {
            alertMessage = "There are no statements to mark exported."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            for statement in filteredStatements {
                var updated = statement
                updated.status = .exported
                updated.exportedAt = Date()
                updated.exportProvider = .csv
                updated.externalReferenceId = "CSV \(PayrollExportsDateFormatter.shortDateTime(Date()))"

                try await dataService.saveTechnicianPayStatement(updated)
                upsertLocalStatement(updated)
            }

            alertMessage = "Marked \(filteredStatements.count) statement(s) exported."
            showAlert = true
        } catch {
            alertMessage = "Could not mark statements exported. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func exportFilteredLineItemsCSV() throws -> PayrollCSVExportResult {
        let fileName = "payroll_line_items_\(PayrollExportsDateFormatter.fileDate(startDate))_to_\(PayrollExportsDateFormatter.fileDate(endDate)).csv"

        var rows: [[String]] = [
            [
                "lineItemId",
                "statementId",
                "companyId",
                "technicianId",
                "technicianName",
                "workerType",
                "source",
                "serviceStopId",
                "serviceStopTaskId",
                "workTypeId",
                "workTypeName",
                "rateId",
                "rateAmountCents",
                "rateType",
                "quantity",
                "quantityUnit",
                "totalAmountCents",
                "completedDate",
                "calculatedAt",
                "status",
                "approvedAt",
                "paidAt",
                "notes",
                "adminReviewNotes"
            ]
        ]

        let sortedItems = filteredLineItems.sorted {
            if $0.completedDate == $1.completedDate {
                return $0.technicianName < $1.technicianName
            }

            return $0.completedDate < $1.completedDate
        }

        for item in sortedItems {
            rows.append([
                item.id,
                item.payStatementId ?? "",
                item.companyId,
                item.technicianId,
                item.technicianName,
                item.workerType.rawValue,
                item.source.rawValue,
                item.serviceStopId ?? "",
                item.serviceStopTaskId ?? "",
                item.workTypeId ?? "",
                item.workTypeName ?? "",
                item.rateId ?? "",
                "\(item.rateAmountCents)",
                item.rateType.rawValue,
                PayrollExportsNumberFormatter.decimalString(item.quantity),
                item.quantityUnit.rawValue,
                "\(item.totalAmountCents)",
                PayrollExportsDateFormatter.isoDate(item.completedDate),
                PayrollExportsDateFormatter.isoDateTime(item.calculatedAt),
                item.calculationStatus.rawValue,
                PayrollExportsDateFormatter.optionalDateTime(item.approvedAt),
                PayrollExportsDateFormatter.optionalDateTime(item.paidAt),
                item.notes ?? "",
                item.adminReviewNotes ?? ""
            ])
        }

        return try PayrollExportsCSVWriter.writeCSV(
            fileName: fileName,
            rows: rows
        )
    }

    private func upsertLocalStatement(_ statement: TechnicianPayStatement) {
        if let index = statements.firstIndex(where: { $0.id == statement.id }) {
            statements[index] = statement
        } else {
            statements.append(statement)
        }
    }
}

struct PayrollExportsView: View {

    @StateObject private var viewModel: PayrollExportsViewModel

    init(
        companyId: String,
        currentUserId: String,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: PayrollExportsViewModel(
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
            exportActionsSection
            statementsSection
        }
        .navigationTitle("Payroll Exports")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading exports...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Payroll Exports", isPresented: $viewModel.showAlert) {
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
            PayrollExportsSummaryRow(
                title: "Statements",
                value: "\(viewModel.filteredStatements.count)"
            )

            PayrollExportsSummaryRow(
                title: "Line Items",
                value: "\(viewModel.filteredLineItems.count)"
            )

            PayrollExportsSummaryRow(
                title: "Total",
                value: PayrollExportsMoneyFormatter.money(viewModel.filteredTotalCents)
            )
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Export", selection: $viewModel.selectedFilter) {
                ForEach(PayrollExportStatementFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var exportActionsSection: some View {
        Section {
            Button {
                viewModel.exportStatementsSummaryCSV()
            } label: {
                Label("Export Statements Summary CSV", systemImage: "doc.text")
            }
            .disabled(viewModel.filteredStatements.isEmpty)

            Button {
                viewModel.exportLineItemsCSV()
            } label: {
                Label("Export Line Items CSV", systemImage: "list.bullet.rectangle")
            }
            .disabled(viewModel.filteredLineItems.isEmpty)

            Button {
                Task {
                    await viewModel.markFilteredStatementsExported()
                }
            } label: {
                Label("Mark Filtered Statements Exported", systemImage: "checkmark.seal")
            }
            .disabled(viewModel.filteredStatements.isEmpty || viewModel.isSaving)
        } header: {
            Text("Actions")
        } footer: {
            Text("Exporting creates CSV files you can save or share. Mark exported only after you have saved or sent the file.")
        }
    }

    private var statementsSection: some View {
        Section {
            if viewModel.filteredStatements.isEmpty {
                ContentUnavailableView(
                    "No Statements",
                    systemImage: "square.and.arrow.up",
                    description: Text("No pay statements match this filter and date range.")
                )
            } else {
                ForEach(viewModel.filteredStatements) { statement in
                    PayrollExportsStatementRow(statement: statement)
                }
            }
        } header: {
            Text("Statements")
        }
    }
}

struct PayrollExportsStatementRow: View {
    var statement: TechnicianPayStatement

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(statement.technicianName)
                        .font(.headline)

                    Text("\(statement.workerType.rawValue) • \(statement.lineItemIds.count) item(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(PayrollExportsMoneyFormatter.money(statement.totalCents))
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

                Text("\(PayrollExportsDateFormatter.shortDate(statement.startDate)) - \(PayrollExportsDateFormatter.shortDate(statement.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let exportedAt = statement.exportedAt {
                Text("Exported \(PayrollExportsDateFormatter.shortDateTime(exportedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct PayrollExportsSummaryRow: View {
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

enum PayrollExportsMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: dollars)) ?? "$0.00"
    }
}

enum PayrollExportsNumberFormatter {
    static func decimalString(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

enum PayrollExportsDateFormatter {
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

    static func fileDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func isoDateTime(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    static func optionalDateTime(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoDateTime(date)
    }
}

enum PayrollExportsCSVWriter {
    static func writeCSV(
        fileName: String,
        rows: [[String]]
    ) throws -> PayrollCSVExportResult {
        let safeFileName = fileName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")

        let csvString = rows
            .map { row in
                row.map { escapeCSVField($0) }.joined(separator: ",")
            }
            .joined(separator: "\n")

        guard let data = csvString.data(using: .utf8) else {
            throw PayrollCSVExportError.couldNotCreateFile
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeFileName)

        try data.write(to: fileURL, options: [.atomic])

        return PayrollCSVExportResult(
            fileURL: fileURL,
            fileName: safeFileName
        )
    }

    private static func escapeCSVField(_ value: String) -> String {
        let shouldQuote =
            value.contains(",") ||
            value.contains("\"") ||
            value.contains("\n") ||
            value.contains("\r")

        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")

        if shouldQuote {
            return "\"\(escaped)\""
        } else {
            return escaped
        }
    }
}

#Preview {
    NavigationStack {
        PayrollExportsView(
            companyId: "com_mock_company",
            currentUserId: "mock_admin_user",
            dataService: MockDataService()
        )
    }
}
