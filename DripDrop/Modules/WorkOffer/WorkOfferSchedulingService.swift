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

        guard offer.status == .accepted else {
            throw WorkOfferSchedulingError.offerNotAccepted
        }

        guard offer.serviceStopId.isEmpty else {
            throw WorkOfferSchedulingError.alreadyScheduled
        }

        let acceptedWorkerId = resolvedWorkerId(for: offer)
        let acceptedWorkerName = resolvedWorkerName(for: offer)
        let acceptedWorkerType = resolvedWorkerType(for: offer)

        guard !acceptedWorkerId.isEmpty else {
            throw WorkOfferSchedulingError.missingWorker
        }

        let selectedTasks = allJobTasks.filter {
            offer.jobTaskIds.contains($0.id)
        }

        guard !selectedTasks.isEmpty else {
            throw WorkOfferSchedulingError.noSelectedTasks
        }

        let serviceStopId = "comp_ss_" + UUID().uuidString
        let internalId = "S" + shortInternalSuffix()

        let address = serviceLocation?.address ?? offer.address ?? Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        )

        let estimatedDuration = selectedTasks.reduce(0) { $0 + $1.estimatedTime }
        let manualPayOverrideCents = manualPayOverrideCents(for: offer)
        let manualPayOverrideNotes = manualPayOverrideNotes(for: offer)

        let serviceStop = ServiceStop(
            id: serviceStopId,
            internalId: internalId,
            companyId: companyId,
            companyName: companyName,
            customerId: job.customerId,
            customerName: job.customerName,
            address: address,
            dateCreated: Date(),
            serviceDate: serviceDate,
            startTime: nil,
            endTime: nil,
            duration: estimatedDuration,
            estimatedDuration: estimatedDuration,
            tech: acceptedWorkerName,
            techId: acceptedWorkerId,
            recurringServiceStopId: "",
            description: offer.description.isEmpty ? job.description : offer.description,
            serviceLocationId: job.serviceLocationId,
            typeId: serviceStopTypeFields.typeId,
            type: serviceStopTypeFields.type,
            typeImage: serviceStopTypeFields.typeImage,
            jobId: job.id,
            jobName: job.type,
            operationStatus: .notFinished,
            billingStatus: .notInvoiced,
            includeReadings: false,
            includeDosages: false,
            otherCompany: false,
            laborContractId: "",
            contractedCompanyId: "",
            photoUrls: [],
            mainCompanyId: nil,
            isInvoiced: false,
            estimatedPayCents: offer.estimatedPayTotalCents ?? offer.offeredAmountCents,
            manualPayOverrideCents: manualPayOverrideCents,
            manualPayOverrideNotes: manualPayOverrideNotes
        )

        try await dataService.uploadServiceStop(
            companyId: companyId,
            serviceStop: serviceStop
        )

        try await dataService.appendServiceStopIdToJob(
            companyId: companyId,
            jobId: job.id,
            serviceStopId: serviceStop.id
        )

        var copiedTasks: [ServiceStopTask] = []

        for jobTask in selectedTasks {
            let serviceStopTask = ServiceStopTask(
                id: "comp_ss_task_" + UUID().uuidString,
                name: jobTask.name,
                type: jobTask.type,
                status: .scheduled,
                contractedRate: jobTask.contractedRate,
                estimatedTime: jobTask.estimatedTime,
                customerApproval: jobTask.customerApproval,
                actualTime: 0,
                workerId: acceptedWorkerId,
                workerType: acceptedWorkerType,
                workerName: acceptedWorkerName,
                laborContractId: "",
                serviceStopId: IdInfo(
                    id: serviceStop.id,
                    internalId: serviceStop.internalId
                ),
                jobId: IdInfo(
                    id: job.id,
                    internalId: job.internalId
                ),
                recurringServiceStopId: IdInfo(
                    id: "",
                    internalId: ""
                ),
                jobTaskId: jobTask.id,
                recurringServiceStopTaskId: "",
                equipmentId: jobTask.equipmentId,
                serviceLocationId: jobTask.serviceLocationId.isEmpty ? job.serviceLocationId : jobTask.serviceLocationId,
                bodyOfWaterId: jobTask.bodyOfWaterId,
                shoppingListItemId: jobTask.shoppingListItemId ?? "",
                payTypeId: jobTask.payTypeId,
                payTypeName: jobTask.payTypeName
//                dataBaseItemId: jobTask.dataBaseItemId

            )

#warning("Work Offers do not have a dataBaseItemId")
            try await dataService.uploadServiceStopTask(
                companyId: companyId,
                serviceStopId: serviceStop.id,
                task: serviceStopTask
            )
            try await dataService.updateJobTaskServiceStopId(
                companyId: companyId,
                jobId: job.id,
                taskId: jobTask.id,
                serviceStopId: IdInfo(
                    id: serviceStop.id,
                    internalId: serviceStop.internalId
                )
            )
            try await dataService.updateJobTaskWorkerId(
                companyId: companyId,
                jobId: job.id,
                taskId: jobTask.id,
                workerId: acceptedWorkerId
            )
            try await dataService.updateJobTaskWorkerName(
                companyId: companyId,
                jobId: job.id,
                taskId: jobTask.id,
                workerName: acceptedWorkerName
            )
            try await dataService.updateJobTaskWorkerType(
                companyId: companyId,
                jobId: job.id,
                taskId: jobTask.id,
                workerType: acceptedWorkerType
            )
            copiedTasks.append(serviceStopTask)
        }

        let shoppingItemIds = selectedTasks.compactMap { task in
            task.shoppingListItemId?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }

        try await dataService.syncShoppingListItemsForScheduledJobTasks(
            companyId: companyId,
            jobId: job.id,
            customerId: job.customerId,
            serviceLocationId: job.serviceLocationId,
            serviceStopId: serviceStop.id,
            serviceStopInternalId: serviceStop.internalId,
            serviceDate: serviceDate,
            assignedTechId: acceptedWorkerId,
            assignedTechName: acceptedWorkerName,
            taskIds: selectedTasks.map { $0.id },
            shoppingListItemIds: shoppingItemIds,
            plannedServiceStopId: nil
        )

        try await dataService.updateWorkOfferScheduledServiceStop(
            companyId: companyId,
            workOfferId: offer.id,
            serviceStopId: serviceStop.id,
            serviceStopInternalId: serviceStop.internalId
        )

        return WorkOfferSchedulingResult(
            serviceStop: serviceStop,
            serviceStopTasks: copiedTasks
        )
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
