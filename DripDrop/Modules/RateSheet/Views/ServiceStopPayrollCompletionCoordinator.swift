//
//  ServiceStopPayrollCompletionCoordinator.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/26.
//
//  ServiceStopPayrollCompletionCoordinator.swift
//  DripDrop
//

import Foundation

struct ServiceStopPayrollStatusChangeResult {
    var generatedLineItems: [TechnicianPayLineItem] = []
    var voidedLineItems: [TechnicianPayLineItem] = []
    var lockedLineItems: [TechnicianPayLineItem] = []

    var didGeneratePay: Bool {
        !generatedLineItems.isEmpty
    }

    var didVoidPay: Bool {
        !voidedLineItems.isEmpty
    }

    var hasLockedItems: Bool {
        !lockedLineItems.isEmpty
    }
}

final class ServiceStopPayrollCompletionCoordinator {

    private let dataService: any ProductionDataServiceProtocol
    private let payrollGenerationService: PayrollGenerationService

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
        self.payrollGenerationService = PayrollGenerationService(
            dataService: dataService
        )
    }

    func handleServiceStopStatusChange(
        oldStop: ServiceStop,
        newStop: ServiceStop,
        changedByUserId: String
    ) async throws -> ServiceStopPayrollStatusChangeResult {

        let wasFinished = oldStop.operationStatus == .finished
        let isFinished = newStop.operationStatus == .finished

        // Nothing payroll-related changed.
        guard wasFinished != isFinished else {
            return ServiceStopPayrollStatusChangeResult()
        }

        // Work became finished.
        if isFinished {
            let generated = try await payrollGenerationService
                .generatePayForCompletedStop(serviceStop: newStop)

            return ServiceStopPayrollStatusChangeResult(
                generatedLineItems: generated,
                voidedLineItems: [],
                lockedLineItems: []
            )
        }

        // Work was reopened, skipped, or otherwise no longer finished.
        let voidReason: PayLineItemVoidReason = {
            if newStop.operationStatus == .skipped {
                return .serviceStopSkipped
            } else {
                return .serviceStopReopened
            }
        }()

        let result = try await voidUnapprovedPayLineItemsForServiceStop(
            serviceStop: newStop,
            changedByUserId: changedByUserId,
            voidReason: voidReason
        )

        return result
    }

    private func voidUnapprovedPayLineItemsForServiceStop(
        serviceStop: ServiceStop,
        changedByUserId: String,
        voidReason: PayLineItemVoidReason
    ) async throws -> ServiceStopPayrollStatusChangeResult {

        let existingLineItems = try await dataService.fetchTechnicianPayLineItems(
            companyId: serviceStop.companyId,
            serviceStopId: serviceStop.id
        )

        var voidedItems: [TechnicianPayLineItem] = []
        var lockedItems: [TechnicianPayLineItem] = []

        for lineItem in existingLineItems {
            switch lineItem.calculationStatus {
            case .pending, .calculated, .needsReview, .adjusted:
                var updated = lineItem
                updated.calculationStatus = .voided
                updated.voidedAt = Date()
                updated.voidedByUserId = changedByUserId
                updated.voidReason = voidReason
                updated.adminReviewNotes = appendAdminNote(
                    existingNote: updated.adminReviewNotes,
                    newNote: "Automatically voided because service stop changed from Finished to \(serviceStop.operationStatus.rawValue)."
                )

                try await dataService.updateTechnicianPayLineItem(updated)
                voidedItems.append(updated)

            case .approved, .paid:
                // Do not silently change approved or paid payroll.
                // These should be reviewed by an admin.
                lockedItems.append(lineItem)

            case .voided:
                break
            }
        }

        return ServiceStopPayrollStatusChangeResult(
            generatedLineItems: [],
            voidedLineItems: voidedItems,
            lockedLineItems: lockedItems
        )
    }

    private func appendAdminNote(
        existingNote: String?,
        newNote: String
    ) -> String {
        let timestamp = PayrollCoordinatorDateFormatter.shortDateTime(Date())
        let formattedNewNote = "[\(timestamp)] \(newNote)"

        guard let existingNote,
              !existingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return formattedNewNote
        }

        return existingNote + "\n" + formattedNewNote
    }
}

enum PayrollCoordinatorDateFormatter {
    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
