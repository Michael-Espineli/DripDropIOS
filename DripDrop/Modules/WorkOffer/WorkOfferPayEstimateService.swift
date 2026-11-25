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

        if paySource == .unpaid || paySource == .taskContractedRates { return [] }
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
            return []
        }

        var lines: [WorkOfferPayEstimateLine] = []

        // Stop-level estimate
        let stopWorkTypeIds = stopWorkTypeIds(
            selectedServiceStopType: selectedServiceStopType,
            serviceStopTypeUseCase: serviceStopTypeUseCase
        )

        if context.settings.routePaySource == .serviceStop ||
            context.settings.routePaySource == .serviceStopAndCompletedTasks ||
            context.settings.routePaySource == .completedTasks {
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

        return lines
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
