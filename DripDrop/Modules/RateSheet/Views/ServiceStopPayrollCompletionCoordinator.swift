//
//  ServiceStopPayrollCompletionCoordinator.swift
//  DripDrop
//

import Foundation

final class ServiceStopPayrollCompletionCoordinator {

    private let payrollGenerationService: PayrollGenerationService

    init(dataService: any ProductionDataServiceProtocol) {
        self.payrollGenerationService = PayrollGenerationService(
            dataService: dataService
        )
    }

    func generatePayrollIfNeeded(
        for serviceStop: ServiceStop
    ) async throws -> [TechnicianPayLineItem] {

        guard serviceStop.operationStatus == .finished else {
            return []
        }

        return try await payrollGenerationService
            .generatePayForCompletedStop(serviceStop: serviceStop)
    }
}