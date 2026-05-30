//
//  PayrollCSVExportService.swift
//  DripDrop
//

import Foundation

enum PayrollCSVExportError: Error {
    case couldNotCreateFile
}

struct PayrollCSVExportResult {
    var fileURL: URL
    var fileName: String
}

enum PayrollCSVExportService {

    // MARK: - Single Statement Summary Export

    static func exportStatementSummary(
        statement: TechnicianPayStatement
    ) throws -> PayrollCSVExportResult {
        let fileName = safeFileName(
            "pay_statement_summary_\(statement.technicianName)_\(statement.id).csv"
        )

        let rows: [[String]] = [
            [
                "statementId",
                "companyId",
                "technicianId",
                "technicianName",
                "workerType",
                "startDate",
                "endDate",
                "lineItemCount",
                "subtotalCents",
                "adjustmentCents",
                "totalCents",
                "status",
                "createdAt",
                "approvedAt",
                "paidAt",
                "exportedAt",
                "exportProvider",
                "externalReferenceId",
                "notes"
            ],
            [
                statement.id,
                statement.companyId,
                statement.technicianId,
                statement.technicianName,
                statement.workerType.rawValue,
                isoDate(statement.startDate),
                isoDate(statement.endDate),
                "\(statement.lineItemIds.count)",
                "\(statement.subtotalCents)",
                "\(statement.adjustmentCents)",
                "\(statement.totalCents)",
                statement.status.rawValue,
                isoDateTime(statement.createdAt),
                optionalDateTime(statement.approvedAt),
                optionalDateTime(statement.paidAt),
                optionalDateTime(statement.exportedAt),
                statement.exportProvider ?? "",
                statement.externalReferenceId ?? "",
                statement.notes ?? ""
            ]
        ]

        return try writeCSV(
            fileName: fileName,
            rows: rows
        )
    }

    // MARK: - Single Statement Line Items Export

    static func exportStatementLineItems(
        statement: TechnicianPayStatement,
        lineItems: [TechnicianPayLineItem]
    ) throws -> PayrollCSVExportResult {
        let fileName = safeFileName(
            "pay_statement_line_items_\(statement.technicianName)_\(statement.id).csv"
        )

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
                "activeRouteId",
                "activeRouteLogId",
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
                "exportBatchId",
                "notes",
                "adminReviewNotes"
            ]
        ]

        let sortedLineItems = lineItems.sorted {
            if $0.completedDate == $1.completedDate {
                return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
            }

            return $0.completedDate < $1.completedDate
        }

        for item in sortedLineItems {
            rows.append([
                item.id,
                item.payStatementId ?? statement.id,
                item.companyId,
                item.technicianId,
                item.technicianName,
                item.workerType.rawValue,
                item.source.rawValue,
                item.serviceStopId ?? "",
                item.serviceStopTaskId ?? "",
                item.activeRouteId ?? "",
                item.activeRouteLogId ?? "",
                item.workTypeId ?? "",
                item.workTypeName ?? "",
                item.rateId ?? "",
                "\(item.rateAmountCents)",
                item.rateType.rawValue,
                decimalString(item.quantity),
                item.quantityUnit.rawValue,
                "\(item.totalAmountCents)",
                isoDate(item.completedDate),
                isoDateTime(item.calculatedAt),
                item.calculationStatus.rawValue,
                optionalDateTime(item.approvedAt),
                optionalDateTime(item.paidAt),
                item.exportBatchId ?? "",
                item.notes ?? "",
                item.adminReviewNotes ?? ""
            ])
        }

        return try writeCSV(
            fileName: fileName,
            rows: rows
        )
    }

    // MARK: - Combined Statement Export

    static func exportCombinedStatementCSV(
        statement: TechnicianPayStatement,
        lineItems: [TechnicianPayLineItem]
    ) throws -> PayrollCSVExportResult {
        let fileName = safeFileName(
            "pay_statement_\(statement.technicianName)_\(statement.id).csv"
        )

        var rows: [[String]] = []

        rows.append(["PAY STATEMENT SUMMARY"])
        rows.append([
            "statementId",
            "technicianName",
            "workerType",
            "startDate",
            "endDate",
            "subtotalCents",
            "adjustmentCents",
            "totalCents",
            "status"
        ])
        rows.append([
            statement.id,
            statement.technicianName,
            statement.workerType.rawValue,
            isoDate(statement.startDate),
            isoDate(statement.endDate),
            "\(statement.subtotalCents)",
            "\(statement.adjustmentCents)",
            "\(statement.totalCents)",
            statement.status.rawValue
        ])

        rows.append([])
        rows.append(["LINE ITEMS"])
        rows.append([
            "lineItemId",
            "source",
            "serviceStopId",
            "serviceStopTaskId",
            "workTypeName",
            "rateAmountCents",
            "rateType",
            "quantity",
            "quantityUnit",
            "totalAmountCents",
            "completedDate",
            "status"
        ])

        let sortedLineItems = lineItems.sorted {
            if $0.completedDate == $1.completedDate {
                return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
            }

            return $0.completedDate < $1.completedDate
        }

        for item in sortedLineItems {
            rows.append([
                item.id,
                item.source.rawValue,
                item.serviceStopId ?? "",
                item.serviceStopTaskId ?? "",
                item.workTypeName ?? "",
                "\(item.rateAmountCents)",
                item.rateType.rawValue,
                decimalString(item.quantity),
                item.quantityUnit.rawValue,
                "\(item.totalAmountCents)",
                isoDate(item.completedDate),
                item.calculationStatus.rawValue
            ])
        }

        return try writeCSV(
            fileName: fileName,
            rows: rows
        )
    }

    // MARK: - Multi Statement Summary Export

    static func exportStatementsSummary(
        statements: [TechnicianPayStatement],
        fileLabel: String = "pay_statements_summary"
    ) throws -> PayrollCSVExportResult {
        let fileName = safeFileName("\(fileLabel).csv")

        var rows: [[String]] = [
            [
                "statementId",
                "companyId",
                "technicianId",
                "technicianName",
                "workerType",
                "startDate",
                "endDate",
                "lineItemCount",
                "subtotalCents",
                "adjustmentCents",
                "totalCents",
                "status",
                "createdAt",
                "approvedAt",
                "paidAt",
                "exportedAt",
                "exportProvider",
                "externalReferenceId",
                "notes"
            ]
        ]

        for statement in statements.sorted(by: { $0.technicianName < $1.technicianName }) {
            rows.append([
                statement.id,
                statement.companyId,
                statement.technicianId,
                statement.technicianName,
                statement.workerType.rawValue,
                isoDate(statement.startDate),
                isoDate(statement.endDate),
                "\(statement.lineItemIds.count)",
                "\(statement.subtotalCents)",
                "\(statement.adjustmentCents)",
                "\(statement.totalCents)",
                statement.status.rawValue,
                isoDateTime(statement.createdAt),
                optionalDateTime(statement.approvedAt),
                optionalDateTime(statement.paidAt),
                optionalDateTime(statement.exportedAt),
                statement.exportProvider ?? "",
                statement.externalReferenceId ?? "",
                statement.notes ?? ""
            ])
        }

        return try writeCSV(
            fileName: fileName,
            rows: rows
        )
    }

    // MARK: - Private CSV Helpers

    private static func writeCSV(
        fileName: String,
        rows: [[String]]
    ) throws -> PayrollCSVExportResult {
        let csvString = rows
            .map { row in
                row.map { escapeCSVField($0) }.joined(separator: ",")
            }
            .joined(separator: "\n")

        guard let data = csvString.data(using: .utf8) else {
            throw PayrollCSVExportError.couldNotCreateFile
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)

        try data.write(to: fileURL, options: [.atomic])

        return PayrollCSVExportResult(
            fileURL: fileURL,
            fileName: fileName
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

    private static func safeFileName(_ value: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")

        return value
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .replacingOccurrences(of: " ", with: "_")
    }

    private static func isoDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func isoDateTime(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    private static func optionalDateTime(_ date: Date?) -> String {
        guard let date else { return "" }
        return isoDateTime(date)
    }

    private static func decimalString(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
