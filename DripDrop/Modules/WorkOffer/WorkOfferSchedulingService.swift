//
//  WorkOfferSchedulingService.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import Foundation

enum WorkOfferSchedulingError: LocalizedError {
    case offerNotAccepted
    case missingWorker
    case noSelectedTasks
    case alreadyScheduled

    var errorDescription: String? {
        switch self {
        case .offerNotAccepted:
            return "This work offer must be accepted before it can be scheduled."
        case .missingWorker:
            return "This offer does not have an accepted worker."
        case .noSelectedTasks:
            return "This offer does not include any job tasks."
        case .alreadyScheduled:
            return "This work offer is already linked to a service stop."
        }
    }
}

struct WorkOfferSchedulingResult {
    var serviceStop: ServiceStop
    var serviceStopTasks: [ServiceStopTask]
}

final class WorkOfferSchedulingService {

    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @discardableResult
    func createServiceStopFromAcceptedOffer(
        companyId: String,
        companyName: String,
        job: Job,
        offer: WorkOffer,
        allJobTasks: [JobTask],
        serviceLocation: ServiceLocation?,
        serviceStopTypeFields: ServiceStopTypeFields,
        serviceDate: Date
    ) async throws -> WorkOfferSchedulingResult {
        let result = try await FunctionsManager.shared.technicianWorkflow("scheduleTechnicianWork", payload: [
            "companyId":companyId, "offerId":offer.id, "serviceDateMillis":serviceDate.timeIntervalSince1970 * 1000
        ])
        guard let stopId = result["serviceStopId"] as? String else { throw WorkOfferSchedulingError.alreadyScheduled }
        let stop = try await dataService.getServiceStopById(serviceStopId:stopId, companyId:companyId)
        let tasks = try await dataService.getServiceStopTasks(companyId:companyId, serviceStopId:stopId)
        return WorkOfferSchedulingResult(serviceStop:stop, serviceStopTasks:tasks)
    }

    private func resolvedWorkerId(for offer: WorkOffer) -> String {
        if !offer.acceptedByUserId.isEmpty {
            return offer.acceptedByUserId
        }

        return offer.offeredToUserId
    }

    private func resolvedWorkerName(for offer: WorkOffer) -> String {
        if !offer.acceptedByUserName.isEmpty {
            return offer.acceptedByUserName
        }

        return offer.offeredToUserName
    }

    private func resolvedWorkerType(for offer: WorkOffer) -> WorkerTypeEnum {
        if offer.offeredToWorkerType != .notAssigned {
            return offer.offeredToWorkerType
        }

        return .contractor
    }

    private func manualPayOverrideCents(for offer: WorkOffer) -> Int? {
        switch offer.paySource {
        case .offeredAmount:
            return max(0, offer.offeredAmountCents)
        case .unpaid:
            return 0
        case .technicianRate, .taskContractedRates:
            return nil
        }
    }

    private func manualPayOverrideNotes(for offer: WorkOffer) -> String? {
        switch offer.paySource {
        case .offeredAmount:
            return "Manual payroll amount from accepted work offer \(offer.id)."
        case .unpaid:
            return "Accepted work offer marked unpaid."
        case .technicianRate, .taskContractedRates:
            return nil
        }
    }

    private func shortInternalSuffix() -> String {
        String(UUID().uuidString.prefix(6)).uppercased()
    }
}
