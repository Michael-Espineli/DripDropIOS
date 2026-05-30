//
//  PayrollGenerationService.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation

struct CompanyPayContext {
    var settings: CompanyPaySettings
    var workTypes: [CompanyWorkType]
    var mappings: [WorkTypeMapping]
    var rates: [TechnicianRate]
}

protocol PayrollDataRepository {
    func fetchPayContext(companyId: String) async throws -> CompanyPayContext
    func fetchTasks(serviceStopId: String) async throws -> [ServiceStopTask]
    func savePayLineItems(_ lineItems: [TechnicianPayLineItem]) async throws
}

final class PayrollGenerationService {
    private let repository: PayrollDataRepository

    init(repository: PayrollDataRepository) {
        self.repository = repository
    }

    @discardableResult
    func generatePayForCompletedStop(
        serviceStop: ServiceStop
    ) async throws -> [TechnicianPayLineItem] {
        let context = try await repository.fetchPayContext(
            companyId: serviceStop.companyId
        )

        let tasks = try await repository.fetchTasks(
            serviceStopId: serviceStop.id
        )

        let engine = PayEngine(
            settings: context.settings,
            workTypes: context.workTypes,
            mappings: context.mappings,
            rates: context.rates
        )

        let lineItems = engine.generateLineItems(
            serviceStop: serviceStop,
            tasks: tasks,
            isServiceStopCompleted: { stop in
                // Best first pass if your enum case is literally "completed".
                // Replace with: stop.operationStatus == .completed
                String(describing: stop.operationStatus).lowercased() == "completed"
            },
            isTaskCompleted: { task in
                // Replace with: task.status == .completed
                String(describing: task.status).lowercased() == "completed"
            },
            taskTypeSourceId: { task in
                // If JobTaskType is RawRepresentable, use task.type.rawValue instead.
                // This must match WorkTypeMapping.sourceId.
                String(describing: task.type)
            }
        )

        try await repository.savePayLineItems(lineItems)

        return lineItems
    }
}
