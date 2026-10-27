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

        // Reopening can leave completed tasks payable. Let the server reconcile
        // individual work components and preserve approved/paid/statement lines.
        try await dataService.refreshServiceStopPayroll(companyId: newStop.companyId, serviceStopId: newStop.id)
        let lines = try await dataService.fetchTechnicianPayLineItems(companyId: newStop.companyId, serviceStopId: newStop.id)
        return ServiceStopPayrollStatusChangeResult(
            generatedLineItems: [],
            voidedLineItems: lines.filter { $0.calculationStatus == .voided },
            lockedLineItems: lines.filter { $0.calculationStatus == .approved || $0.calculationStatus == .paid || $0.calculationStatus == .adjusted || $0.payStatementId != nil || $0.exportBatchId != nil }
        )
    }
}
