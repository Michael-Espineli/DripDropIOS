//
//  PayrollGenerationService.swift
//  DripDrop
//

import Foundation

struct CompanyPayContext {
    var settings: CompanyPaySettings
    var serviceStopTypes: [CompanyServiceStopType]
    var workTypes: [CompanyWorkType]
    var mappings: [WorkTypeMapping]
    var rates: [TechnicianRate]
    var workers: [PayrollWorkerSnapshot]
}

final class PayrollGenerationService {

    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @discardableResult
    func generatePayForCompletedStop(
        
        serviceStop: ServiceStop
    ) async throws -> [TechnicianPayLineItem] {

        guard serviceStop.operationStatus == .finished else {
            return []
        }

        let context = try await fetchPayContext(
            companyId: serviceStop.companyId
        )

        let tasks = try await dataService.fetchServiceStopTasks(
            companyId: serviceStop.companyId,
            serviceStopId: serviceStop.id
        )

        let engine = PayEngine(
            settings: context.settings,
            serviceStopTypes: context.serviceStopTypes,
            workTypes: context.workTypes,
            mappings: context.mappings,
            rates: context.rates,
            workers: context.workers
        )

        let generatedLineItems = engine.generateLineItems(
            companyId: serviceStop.companyId,
            serviceStop: serviceStop,
            tasks: tasks
        )

        let existingLineItems = try await dataService.fetchTechnicianPayLineItems(
            companyId: serviceStop.companyId,
            serviceStopId: serviceStop.id
        )

        let lineItemsToSave = mergeGeneratedLineItems(
            generatedLineItems: generatedLineItems,
            existingLineItems: existingLineItems,
            settings: context.settings
        )

        try await dataService.saveTechnicianPayLineItems(lineItemsToSave)

        return lineItemsToSave
    }

    private func fetchPayContext(
        companyId: String
    ) async throws -> CompanyPayContext {

        async let settingsTask = dataService.fetchCompanyPaySettings(companyId: companyId)
        async let serviceStopTypesTask = dataService.fetchCompanyServiceStopTypes(companyId: companyId)
        async let workTypesTask = dataService.fetchCompanyWorkTypes(companyId: companyId)
        async let mappingsTask = dataService.fetchWorkTypeMappings(companyId: companyId)
        async let ratesTask = dataService.fetchTechnicianRates(companyId: companyId)
        async let companyUsersTask = dataService.fetchCompanyUsers(companyId: companyId)

        let settings = try await settingsTask
            ?? CompanyPaySettings.defaultSettings()

        let serviceStopTypes = try await serviceStopTypesTask
        let workTypes = try await workTypesTask
        let mappings = try await mappingsTask
        let rates = try await ratesTask
        let companyUsers = try await companyUsersTask

        let workers = companyUsers
            .filter { $0.status == .active }
            .map { PayrollWorkerSnapshot(companyUser: $0) }

        return CompanyPayContext(
            settings: settings,
            serviceStopTypes: serviceStopTypes,
            workTypes: workTypes,
            mappings: mappings,
            rates: rates,
            workers: workers
        )
    }

    private func mergeGeneratedLineItems(
        generatedLineItems: [TechnicianPayLineItem],
        existingLineItems: [TechnicianPayLineItem],
        settings: CompanyPaySettings
    ) -> [TechnicianPayLineItem] {

        let existingById = Dictionary(
            uniqueKeysWithValues: existingLineItems.map { ($0.id, $0) }
        )

        return generatedLineItems.map { generated in
            guard let existing = existingById[generated.id] else {
                return generated
            }

            if shouldKeepExistingLineItem(existing, settings: settings) {
                return existing
            }

            var updated = generated

            updated.adminReviewNotes = appendAdminNote(
                existingNote: existing.adminReviewNotes,
                newNote: existing.calculationStatus == .voided
                    ? "Regenerated because the service stop was finished again."
                    : "Regenerated from current payroll rules."
            )

            return updated
        }
    }

    private func shouldKeepExistingLineItem(
        _ existing: TechnicianPayLineItem,
        settings: CompanyPaySettings
    ) -> Bool {

        // Paid records should never be overwritten by automatic regeneration.
        if existing.calculationStatus == .paid {
            return true
        }

        // Admin-voided or duplicate-voided records should not come back automatically.
        if existing.calculationStatus == .voided {
            switch existing.voidReason {
            case .serviceStopReopened, .serviceStopSkipped, .taskReopened:
                // These can be regenerated if the work becomes finished again.
                return false

            case .adminVoided, .duplicate:
                return true

            case .none:
                // If we do not know why it was voided, keep it safe.
                return true
            }
        }

        // If the company locks approved pay, do not overwrite approved line items.
        if settings.lockPayAfterApproval &&
            existing.calculationStatus == .approved {
            return true
        }

        // If the company does not want recalculation, preserve unapproved existing lines too.
        if !settings.recalculateUnapprovedPayWhenRatesChange {
            switch existing.calculationStatus {
            case .pending, .calculated, .needsReview, .adjusted:
                return true

            case .approved, .paid, .voided:
                return false
            }
        }

        return false
    }
    private func appendAdminNote(
        existingNote: String?,
        newNote: String
    ) -> String {
        let timestamp = PayrollGenerationDateFormatter.shortDateTime(Date())
        let formattedNewNote = "[\(timestamp)] \(newNote)"

        guard let existingNote,
              !existingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return formattedNewNote
        }

        return existingNote + "\n" + formattedNewNote
    }
    enum PayrollGenerationDateFormatter {
        static func shortDateTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}
