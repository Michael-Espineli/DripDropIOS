//
//  PayrollGenerationService.swift
//  DripDrop
//

import Foundation

struct CompanyPayContext {
    var settings: CompanyPaySettings
    var workTypes: [CompanyWorkType]
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

        // The server uses the same rules as the web preview and reconciles obsolete
        // unapproved lines atomically. Never calculate and overwrite earned pay here.
        try await dataService.refreshServiceStopPayroll(companyId: serviceStop.companyId, serviceStopId: serviceStop.id)
        return try await dataService.fetchTechnicianPayLineItems(companyId: serviceStop.companyId, serviceStopId: serviceStop.id)
            .filter { $0.calculationStatus != .voided }
    }
}
