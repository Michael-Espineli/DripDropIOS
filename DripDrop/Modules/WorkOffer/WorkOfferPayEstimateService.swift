//
//  WorkOfferPayEstimateService.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import Foundation

struct WorkOfferPayEstimateContext {
    var settings: CompanyPaySettings
    var workTypes: [CompanyWorkType]
    var rates: [TechnicianRate]
    var workers: [PayrollWorkerSnapshot]
}

struct WorkOfferPayEstimateService {

    let context: WorkOfferPayEstimateContext

    private var workTypesById: [String: CompanyWorkType] {
        Dictionary(uniqueKeysWithValues: context.workTypes.map { ($0.id, $0) })
    }

    func estimate(
        companyId: String,
        offerType: WorkOfferType,
        selectedWorker: CompanyUser?,
        selectedServiceStopType: CompanyServiceStopType?,
        serviceStopTypeUseCase: ServiceStopTypeUseCase,
        tasks: [JobTask],
        paySource: WorkOfferPaySource,
        offeredAmountCents: Int,
        estimateDate: Date = Date()
    ) -> [WorkOfferPayEstimateLine] {

        if paySource == .offeredAmount {
            return [
                WorkOfferPayEstimateLine(
                    id: "offer_estimate_offered_amount",
                    sourceTaskId: nil,
                    source: .serviceStop,
                    workTypeId: nil,
                    workTypeName: "Offered Amount",
                    title: "Offered Amount",
                    rateAmountCents: offeredAmountCents,
                    rateType: .manual,
                    quantity: 1,
                    quantityUnit: .each,
                    totalAmountCents: offeredAmountCents,
                    calculationStatus: offeredAmountCents > 0 ? .calculated : .needsReview,
                    notes: "Fixed offered amount. Final payroll may still be generated from completed work."
                )
            ]
        }

        guard let worker = selectedWorker,
              !worker.userId.isEmpty else {
            return tasks.map { task in
                needsReviewTaskLine(
                    task: task,
                    notes: "Select a technician to estimate technician-rate pay."
                )
            }
        }

        var lines: [WorkOfferPayEstimateLine] = []

        // Stop-level estimate
        let stopWorkTypeIds = stopWorkTypeIds(
            selectedServiceStopType: selectedServiceStopType,
            serviceStopTypeUseCase: serviceStopTypeUseCase
        )

        if context.settings.routePaySource == .serviceStop ||
            context.settings.routePaySource == .serviceStopAndCompletedTasks {
            if stopWorkTypeIds.isEmpty {
                lines.append(
                    WorkOfferPayEstimateLine(
                        id: "offer_estimate_stop_needs_review",
                        sourceTaskId: nil,
                        source: .serviceStop,
                        workTypeId: nil,
                        workTypeName: nil,
                        title: "Service Stop Pay",
                        rateAmountCents: 0,
                        rateType: .manual,
                        quantity: 0,
                        quantityUnit: .each,
                        totalAmountCents: 0,
                        calculationStatus: .needsReview,
                        notes: "No service stop pay type could be resolved for this offer."
                    )
                )
            } else {
                for workTypeId in stopWorkTypeIds.prefix(1) {
                    lines.append(
                        estimateLineFromTechnicianRate(
                            companyId: companyId,
                            worker: worker,
                            source: .serviceStop,
                            sourceTaskId: nil,
                            title: workTypesById[workTypeId]?.name ?? "Service Stop Pay",
                            workTypeId: workTypeId,
                            payBasis: .serviceStop,
                            preferredRateType: workTypesById[workTypeId]?.defaultRateType,
                            estimatedMinutes: tasks.reduce(0) { $0 + $1.estimatedTime },
                            date: estimateDate
                        )
                    )
                }
            }
        }

        // Task-level estimate
        if context.settings.taskPaySource != .none {
            for task in tasks {
                if let line = estimateTaskLine(
                    companyId: companyId,
                    worker: worker,
                    task: task,
                    taskPaySource: context.settings.taskPaySource,
                    date: estimateDate
                ) {
                    lines.append(line)
                }
            }
        }

        return lines
    }

    private func estimateTaskLine(
        companyId: String,
        worker: CompanyUser,
        task: JobTask,
        taskPaySource: TaskPaySource,
        date: Date
    ) -> WorkOfferPayEstimateLine? {
        let workTypeId = task.payTypeId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !workTypeId.isEmpty else {
            return needsReviewTaskLine(
                task: task,
                notes: "No pay type selected for task \(task.name)."
            )
        }

        let workType = workTypesById[workTypeId]
        let workTypeName = task.payTypeName ?? workType?.name

        switch taskPaySource {
        case .technicianRate:
            return estimateTaskLineFromTechnicianRate(
                companyId: companyId,
                worker: worker,
                source: .serviceStopTask,
                sourceTaskId: task.id,
                title: task.name,
                workTypeId: workTypeId,
                payBasis: .serviceStopTask,
                preferredRateType: workType?.defaultRateType,
                estimatedMinutes: task.estimatedTime,
                date: date
            )

        case .taskContractedRate:
            guard task.contractedRate > 0 else {
                return nil
            }

            return flatTaskLine(
                task: task,
                workTypeId: workTypeId,
                workTypeName: workTypeName
            )

        case .technicianRateThenTaskContractedRate:
            guard let techLine = estimateTaskLineFromTechnicianRate(
                companyId: companyId,
                worker: worker,
                source: .serviceStopTask,
                sourceTaskId: task.id,
                title: task.name,
                workTypeId: workTypeId,
                payBasis: .serviceStopTask,
                preferredRateType: workType?.defaultRateType,
                estimatedMinutes: task.estimatedTime,
                date: date,
                returnNeedsReviewWhenMissing: false
            ) else {
                return nil
            }

            if techLine.calculationStatus == .calculated {
                return techLine
            }

            if task.contractedRate > 0 {
                return flatTaskLine(
                    task: task,
                    workTypeId: workTypeId,
                    workTypeName: workTypeName
                )
            }

            return techLine

        case .taskContractedRateThenTechnicianRate:
            if task.contractedRate > 0 {
                return flatTaskLine(
                    task: task,
                    workTypeId: workTypeId,
                    workTypeName: workTypeName
                )
            }

            return estimateTaskLineFromTechnicianRate(
                companyId: companyId,
                worker: worker,
                source: .serviceStopTask,
                sourceTaskId: task.id,
                title: task.name,
                workTypeId: workTypeId,
                payBasis: .serviceStopTask,
                preferredRateType: workType?.defaultRateType,
                estimatedMinutes: task.estimatedTime,
                date: date
            )

        case .hourlyEstimatedTime, .hourlyActualTime:
            return estimateHourlyTaskLine(
                companyId: companyId,
                worker: worker,
                task: task,
                workTypeId: workTypeId,
                workTypeName: workTypeName,
                date: date
            )

        case .none:
            return nil
        }
    }

    private func flatTaskLine(
        task: JobTask,
        workTypeId: String?,
        workTypeName: String?
    ) -> WorkOfferPayEstimateLine {
        let total = PayMath.calculateTotalAmountCents(
            rateAmountCents: task.contractedRate,
            rateType: .flatPerTask,
            quantity: 1,
            quantityUnit: .each
        )

        return WorkOfferPayEstimateLine(
            id: "offer_estimate_task_\(task.id)",
            sourceTaskId: task.id,
            source: .serviceStopTask,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            title: task.name,
            rateAmountCents: task.contractedRate,
            rateType: .flatPerTask,
            quantity: 1,
            quantityUnit: .each,
            totalAmountCents: total,
            calculationStatus: .calculated,
            notes: "Estimated from task contracted rate."
        )
    }

    private func estimateHourlyTaskLine(
        companyId: String,
        worker: CompanyUser,
        task: JobTask,
        workTypeId: String,
        workTypeName: String?,
        date: Date
    ) -> WorkOfferPayEstimateLine {
        estimateLineFromTechnicianRate(
            companyId: companyId,
            worker: worker,
            source: .serviceStopTask,
            sourceTaskId: task.id,
            title: task.name,
            workTypeId: workTypeId,
            payBasis: .technicianHourly,
            preferredRateType: .hourly,
            estimatedMinutes: task.estimatedTime,
            date: date
        )
    }

    private func estimateLineFromTechnicianRate(
        companyId: String,
        worker: CompanyUser,
        source: PayLineItemSource,
        sourceTaskId: String?,
        title: String,
        workTypeId: String,
        payBasis: PayBasis,
        preferredRateType: RateType?,
        estimatedMinutes: Int,
        date: Date,
        returnNeedsReviewWhenMissing: Bool = true
    ) -> WorkOfferPayEstimateLine {
        let workType = workTypesById[workTypeId]

        guard let rate = activeRate(
            companyId: companyId,
            technicianId: worker.userId,
            workTypeId: workTypeId,
            payBasis: payBasis,
            preferredRateType: preferredRateType,
            date: date
        ) else {
            return WorkOfferPayEstimateLine(
                id: "offer_estimate_missing_rate_\(source.rawValue)_\(sourceTaskId ?? workTypeId)",
                sourceTaskId: sourceTaskId,
                source: source,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                title: title,
                rateAmountCents: 0,
                rateType: .manual,
                quantity: 0,
                quantityUnit: .each,
                totalAmountCents: 0,
                calculationStatus: returnNeedsReviewWhenMissing ? .needsReview : .needsReview,
                notes: "No active technician rate found for \(worker.userName) and \(workType?.name ?? workTypeId)."
            )
        }

        let quantity: Double
        let unit: PayQuantityUnit

        switch rate.rateType {
        case .hourly:
            quantity = Double(estimatedMinutes)
            unit = .minutes
        case .flatPerStop, .flatPerTask, .manual:
            quantity = 1
            unit = .each
        case .perBodyOfWater:
            quantity = 1
            unit = .bodyOfWater
        case .perServiceLocation:
            quantity = 1
            unit = .serviceLocation
        case .percentage:
            quantity = 1
            unit = .percent
        }

        let total = PayMath.calculateTotalAmountCents(
            rateAmountCents: rate.amountCents,
            rateType: rate.rateType,
            quantity: quantity,
            quantityUnit: unit
        )

        return WorkOfferPayEstimateLine(
            id: "offer_estimate_rate_\(rate.id)_\(sourceTaskId ?? "stop")",
            sourceTaskId: sourceTaskId,
            source: source,
            workTypeId: workTypeId,
            workTypeName: workType?.name,
            title: title,
            rateAmountCents: rate.amountCents,
            rateType: rate.rateType,
            quantity: quantity,
            quantityUnit: unit,
            totalAmountCents: total,
            calculationStatus: rate.rateType == .percentage ? .needsReview : .calculated,
            notes: "Estimated from technician rate."
        )
    }

    private func estimateTaskLineFromTechnicianRate(
        companyId: String,
        worker: CompanyUser,
        source: PayLineItemSource,
        sourceTaskId: String?,
        title: String,
        workTypeId: String,
        payBasis: PayBasis,
        preferredRateType: RateType?,
        estimatedMinutes: Int,
        date: Date,
        returnNeedsReviewWhenMissing: Bool = true
    ) -> WorkOfferPayEstimateLine? {
        let line = estimateLineFromTechnicianRate(
            companyId: companyId,
            worker: worker,
            source: source,
            sourceTaskId: sourceTaskId,
            title: title,
            workTypeId: workTypeId,
            payBasis: payBasis,
            preferredRateType: preferredRateType,
            estimatedMinutes: estimatedMinutes,
            date: date,
            returnNeedsReviewWhenMissing: returnNeedsReviewWhenMissing
        )

        if source == .serviceStopTask,
           line.calculationStatus == .calculated,
           line.rateAmountCents <= 0 {
            return nil
        }

        return line
    }

    private func needsReviewTaskLine(
        task: JobTask,
        notes: String
    ) -> WorkOfferPayEstimateLine {
        WorkOfferPayEstimateLine(
            id: "offer_estimate_task_needs_review_\(task.id)",
            sourceTaskId: task.id,
            source: .serviceStopTask,
            workTypeId: nil,
            workTypeName: nil,
            title: task.name,
            rateAmountCents: 0,
            rateType: .manual,
            quantity: 0,
            quantityUnit: .each,
            totalAmountCents: 0,
            calculationStatus: .needsReview,
            notes: notes
        )
    }

    private func stopWorkTypeIds(
        selectedServiceStopType: CompanyServiceStopType?,
        serviceStopTypeUseCase: ServiceStopTypeUseCase
    ) -> [String] {
        if let selectedServiceStopType {
            return [selectedServiceStopType.id]
        }

        return [serviceStopTypeUseCase.fallbackTypeId].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func activeRate(
        companyId: String,
        technicianId: String,
        workTypeId: String?,
        payBasis: PayBasis,
        preferredRateType: RateType?,
        date: Date
    ) -> TechnicianRate? {
        let candidates = context.rates.filter { rate in
            guard rate.companyId == companyId else { return false }
            guard rate.technicianId == technicianId else { return false }
            guard rate.status != .draft else { return false }
            guard rate.status != .archived else { return false }
            guard rate.effectiveStartDate <= date else { return false }

            if let endDate = rate.effectiveEndDate, date > endDate {
                return false
            }

            guard rate.payBasis == payBasis else { return false }

            return rate.workTypeId == workTypeId
        }

        if let preferredRateType,
           let preferred = candidates
            .filter({ $0.rateType == preferredRateType })
            .sorted(by: { $0.effectiveStartDate > $1.effectiveStartDate })
            .first {
            return preferred
        }

        return candidates
            .sorted(by: { $0.effectiveStartDate > $1.effectiveStartDate })
            .first
    }

    private func uniqueIds(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for id in ids where !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if !seen.contains(id) {
                result.append(id)
                seen.insert(id)
            }
        }

        return result
    }
}
