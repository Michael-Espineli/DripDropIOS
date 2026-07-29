//
//  PayEngine.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation

// MARK: - Pay Math

enum PayMath {
    static func calculateTotalAmountCents(
        rateAmountCents: Int,
        rateType: RateType,
        quantity: Double,
        quantityUnit: PayQuantityUnit
    ) -> Int {
        switch rateType {
        case .flatPerStop, .flatPerTask, .manual:
            return Int((Double(rateAmountCents) * quantity).rounded())

        case .hourly:
            switch quantityUnit {
            case .minutes:
                return Int(((Double(rateAmountCents) / 60.0) * quantity).rounded())
            case .hours:
                return Int((Double(rateAmountCents) * quantity).rounded())
            default:
                return 0
            }

        case .perBodyOfWater, .perServiceLocation:
            return Int((Double(rateAmountCents) * quantity).rounded())

        case .percentage:
            return 0
        }
    }
}

struct PayrollWorkerSnapshot: Identifiable, Codable, Hashable {
    var id: String { userId }

    var userId: String
    var userName: String
    var workerType: WorkerTypeEnum
}

extension PayrollWorkerSnapshot {
    init(companyUser: CompanyUser) {
        self.userId = companyUser.userId
        self.userName = companyUser.userName
        self.workerType = companyUser.workerType
    }
}

// MARK: - Pay Engine
import Foundation

// MARK: - Pay Engine

struct PayEngine {
    let settings: CompanyPaySettings
    let serviceStopTypes: [CompanyServiceStopType]
    let workTypes: [CompanyWorkType]
    let mappings: [WorkTypeMapping]
    let rates: [TechnicianRate]
    let workers: [PayrollWorkerSnapshot]

    private var workTypesById: [String: CompanyWorkType] {
        Dictionary(uniqueKeysWithValues: workTypes.map { ($0.id, $0) })
    }

    private var serviceStopTypesById: [String: CompanyServiceStopType] {
        Dictionary(uniqueKeysWithValues: serviceStopTypes.map { ($0.id, $0) })
    }

    private var workersByUserId: [String: PayrollWorkerSnapshot] {
        var result: [String: PayrollWorkerSnapshot] = [:]

        for worker in workers {
            result[worker.userId] = worker
        }

        return result
    }

    func generateLineItems(
        companyId: String,
        serviceStop: ServiceStop,
        tasks: [ServiceStopTask],
        now: Date = Date()
    ) -> [TechnicianPayLineItem] {

        guard serviceStop.isFinishedForPay else {
            return []
        }

        if let manualPayOverrideCents = serviceStop.manualPayOverrideCents {
            return [
                manualPayOverrideLine(
                    serviceStop: serviceStop,
                    amountCents: max(0, manualPayOverrideCents),
                    now: now
                )
            ]
        }

        // Hourly-only companies should generate pay from ActiveRoute / ActiveRouteLog,
        // not from individual service stops.
        if settings.payMode == .hourlyOnly {
            return []
        }

        var lineItems: [TechnicianPayLineItem] = []

        // MARK: Stop-Level Production Pay

        switch settings.routePaySource {
        case .serviceStop, .serviceStopAndCompletedTasks:
            let stopWorkTypeIds = serviceStopWorkTypeIds(for: serviceStop)

            if stopWorkTypeIds.isEmpty {
                lineItems.append(
                    needsReviewLine(
                        serviceStop: serviceStop,
                        serviceStopTask: nil,
                        worker: serviceStopWorker(serviceStop),
                        source: .serviceStop,
                        workTypeId: nil,
                        workTypeName: nil,
                        completedDate: serviceStop.serviceDate,
                        now: now,
                        notes: "No service stop work type could be resolved. typeId: \(serviceStop.typeId), inferredSourceId: \(serviceStop.inferredPayrollServiceStopSourceId)"
                    )
                )
            } else if !settings.allowMultipleWorkTypesPerStop && stopWorkTypeIds.count > 1 {
                lineItems.append(
                    needsReviewLine(
                        serviceStop: serviceStop,
                        serviceStopTask: nil,
                        worker: serviceStopWorker(serviceStop),
                        source: .serviceStop,
                        workTypeId: nil,
                        workTypeName: nil,
                        completedDate: serviceStop.serviceDate,
                        now: now,
                        notes: "Multiple work types matched this service stop, but company settings do not allow multiple work types per stop."
                    )
                )
            } else {
                for workTypeId in stopWorkTypeIds {
                    lineItems.append(
                        makeServiceStopProductionLine(
                            companyId: companyId,
                            serviceStop: serviceStop,
                            workTypeId: workTypeId,
                            now: now
                        )
                    )
                }
            }

        case .hourlyServiceStopDuration:
            lineItems.append(
                makeServiceStopHourlyLine(
                    companyId: companyId,
                    serviceStop: serviceStop,
                    now: now
                )
            )

        case .completedTasks, .hourlyTaskActualTime, .none:
            break
        }

        // MARK: Task-Level Pay

        let finishedTasks = tasks.filter { $0.isFinishedForPay }

        let effectiveTaskPaySource: TaskPaySource = {
            if settings.routePaySource == .hourlyTaskActualTime {
                return .hourlyActualTime
            } else {
                return settings.taskPaySource
            }
        }()

        guard effectiveTaskPaySource != .none else {
            return lineItems
        }

        for task in finishedTasks {
            if let line = makeTaskLine(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                taskPaySource: effectiveTaskPaySource,
                now: now
            ) {
                lineItems.append(line)
            }
        }

        return lineItems
    }
}

// MARK: - Service Stop Lines

private extension PayEngine {

    func makeServiceStopProductionLine(
        companyId: String,
        serviceStop: ServiceStop,
        workTypeId: String,
        now: Date
    ) -> TechnicianPayLineItem {
        let worker = serviceStopWorker(serviceStop)
        let workType = workTypesById[workTypeId]
        let primaryPayBasis = serviceStopProductionPayBasis(for: workType)
        let fallbackPayBasis: PayBasis = primaryPayBasis == .serviceStop
            ? .serviceStopTask
            : .serviceStop

        let primaryRate = activeRate(
            companyId: companyId,
            technicianId: worker.userId,
            workTypeId: workTypeId,
            payBasis: primaryPayBasis,
            preferredRateType: workType?.defaultRateType,
            date: serviceStop.serviceDate,
            allowGeneralHourlyFallback: false
        )

        let fallbackRate: TechnicianRate? = {
            guard primaryRate == nil else { return nil }

            payrollDebug(
                "[serviceStopRate] No \(primaryPayBasis.rawValue) rate for stop work type \(workType?.name ?? workTypeId). Trying \(fallbackPayBasis.rawValue)."
            )

            return activeRate(
                companyId: companyId,
                technicianId: worker.userId,
                workTypeId: workTypeId,
                payBasis: fallbackPayBasis,
                preferredRateType: workType?.defaultRateType,
                date: serviceStop.serviceDate,
                allowGeneralHourlyFallback: false
            )
        }()

        guard let rate = primaryRate ?? fallbackRate else {
            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: nil,
                worker: worker,
                source: .serviceStop,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                completedDate: serviceStop.serviceDate,
                now: now,
                notes: "No active production rate found for \(worker.userName) and work type \(workType?.name ?? workTypeId). Checked \(primaryPayBasis.rawValue) and \(fallbackPayBasis.rawValue)."
            )
        }

        let quantityInfo = quantityAndUnit(
            for: rate.rateType,
            serviceStop: serviceStop,
            task: nil,
            minutesOverride: nil
        )

        return lineFromRate(
            serviceStop: serviceStop,
            serviceStopTask: nil,
            worker: worker,
            source: .serviceStop,
            workTypeId: workTypeId,
            workTypeName: workType?.name,
            rate: rate,
            quantity: quantityInfo.quantity,
            quantityUnit: quantityInfo.unit,
            completedDate: serviceStop.serviceDate,
            now: now,
            notes: rate.payBasis == primaryPayBasis
                ? nil
                : "Used \(rate.payBasis.title) rate for stop-level payroll because the service stop work type is configured with \(primaryPayBasis.title) as its preferred pay basis."
        )
    }

    func makeServiceStopHourlyLine(
        companyId: String,
        serviceStop: ServiceStop,
        now: Date
    ) -> TechnicianPayLineItem {
        let worker = serviceStopWorker(serviceStop)

        let workTypeId = serviceStopWorkTypeIds(for: serviceStop).first
        let workType = workTypeId.flatMap { workTypesById[$0] }

        guard let rate = activeRate(
            companyId: companyId,
            technicianId: worker.userId,
            workTypeId: workTypeId,
            payBasis: .technicianHourly,
            preferredRateType: .hourly,
            date: serviceStop.serviceDate,
            allowGeneralHourlyFallback: true
        ) else {
            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: nil,
                worker: worker,
                source: .serviceStop,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                completedDate: serviceStop.serviceDate,
                now: now,
                notes: "No active hourly rate found for \(worker.userName)."
            )
        }

        return lineFromRate(
            serviceStop: serviceStop,
            serviceStopTask: nil,
            worker: worker,
            source: .serviceStop,
            workTypeId: workTypeId,
            workTypeName: workType?.name ?? "Hourly Service Stop Time",
            rate: rate,
            quantity: Double(serviceStop.duration),
            quantityUnit: .minutes,
            completedDate: serviceStop.serviceDate,
            now: now,
            notes: "Hourly pay from service stop duration. For hourly-only companies, prefer ActiveRoute pay generation instead."
        )
    }
}

// MARK: - Task Lines

private extension PayEngine {

    func makeTaskLine(
        companyId: String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        taskPaySource: TaskPaySource,
        now: Date
    ) -> TechnicianPayLineItem? {
        print("")
        print("serviceStop")
        print(serviceStop)
        print("task")
        print(task)
        print("taskPaySource")
        print(taskPaySource)
        print("")
        print(task)
        let worker = taskWorker(serviceStop: serviceStop, task: task)
        let sourceId = task.payrollTaskSourceId

        guard let workTypeId = mappedWorkTypeIds(
            sourceType: .jobTaskType,
            sourceId: sourceId
        ).first else {
            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: task,
                worker: worker,
                source: .serviceStopTask,
                workTypeId: nil,
                workTypeName: nil,
                completedDate: serviceStop.serviceDate,
                now: now,
                notes: "No WorkTypeMapping found for task type: \(sourceId)"
            )
        }

        let workType = workTypesById[workTypeId]

        switch taskPaySource {
        case .technicianRate:
            return taskLineFromTechnicianRate(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                preferredRateType: workType?.defaultRateType,
                now: now
            )

        case .taskContractedRate:
            return taskLineFromContractedRate(
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                now: now
            )

        case .technicianRateThenTaskContractedRate:
            if let line = taskLineFromTechnicianRate(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                preferredRateType: workType?.defaultRateType,
                now: now,
                returnNilWhenMissingRate: true
            ) {
                return line
            }

            return taskLineFromContractedRate(
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                now: now
            )

        case .taskContractedRateThenTechnicianRate:
            if task.contractedRate > 0 {
                return taskLineFromContractedRate(
                    serviceStop: serviceStop,
                    task: task,
                    worker: worker,
                    workTypeId: workTypeId,
                    workTypeName: workType?.name,
                    now: now
                )
            }

            return taskLineFromTechnicianRate(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                preferredRateType: workType?.defaultRateType,
                now: now
            )

        case .hourlyActualTime:
            return taskLineFromHourlyRate(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                minutes: task.actualTime,
                now: now,
                notes: "Hourly pay from task actualTime."
            )

        case .hourlyEstimatedTime:
            return taskLineFromHourlyRate(
                companyId: companyId,
                serviceStop: serviceStop,
                task: task,
                worker: worker,
                workTypeId: workTypeId,
                workTypeName: workType?.name,
                minutes: task.estimatedTime,
                now: now,
                notes: "Hourly pay from task estimatedTime."
            )

        case .none:
            return nil
        }
    }

    func taskLineFromTechnicianRate(
        companyId:String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        worker: PayrollWorkerSnapshot,
        workTypeId: String,
        workTypeName: String?,
        preferredRateType: RateType?,
        now: Date,
        returnNilWhenMissingRate: Bool = false
    ) -> TechnicianPayLineItem? {
        guard let rate = activeRate(
            companyId: companyId,
            technicianId: worker.userId,
            workTypeId: workTypeId,
            payBasis: .serviceStopTask,
            preferredRateType: preferredRateType,
            date: serviceStop.serviceDate,
            allowGeneralHourlyFallback: false
        ) else {
            if returnNilWhenMissingRate {
                return nil
            }

            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: task,
                worker: worker,
                source: .serviceStopTask,
                workTypeId: workTypeId,
                workTypeName: workTypeName,
                completedDate: serviceStop.serviceDate,
                now: now,
                notes: "No active technician task rate found for \(worker.userName) and work type \(workTypeName ?? workTypeId)."
            )
        }

        let quantityInfo = quantityAndUnit(
            for: rate.rateType,
            serviceStop: serviceStop,
            task: task,
            minutesOverride: nil
        )

        return lineFromRate(
            serviceStop: serviceStop,
            serviceStopTask: task,
            worker: worker,
            source: .serviceStopTask,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            rate: rate,
            quantity: quantityInfo.quantity,
            quantityUnit: quantityInfo.unit,
            completedDate: serviceStop.serviceDate,
            now: now,
            notes: nil
        )
    }

    func taskLineFromContractedRate(
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        worker: PayrollWorkerSnapshot,
        workTypeId: String,
        workTypeName: String?,
        now: Date
    ) -> TechnicianPayLineItem? {
        guard task.contractedRate > 0 else {
            payrollDebug(
                "Skipping task pay line because contractedRate is 0. taskId: \(task.id), taskName: \(task.name), workType: \(workTypeName ?? workTypeId)"
            )
            return nil
        }

        let total = PayMath.calculateTotalAmountCents(
            rateAmountCents: task.contractedRate,
            rateType: .flatPerTask,
            quantity: 1,
            quantityUnit: .each
        )

        return TechnicianPayLineItem(
            id: makeLineId(
                source: .serviceStopTask,
                serviceStopId: serviceStop.id,
                serviceStopTaskId: task.id,
                activeRouteId: nil,
                activeRouteLogId: nil,
                technicianId: worker.userId,
                workTypeId: workTypeId
            ),
            companyId: serviceStop.companyId,
            technicianId: worker.userId,
            technicianName: worker.userName,
            workerType: worker.workerType,
            source: .serviceStopTask,
            serviceStopId: serviceStop.id,
            serviceStopTaskId: task.id,
            activeRouteId: nil,
            activeRouteLogId: nil,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            rateId: nil,
            rateAmountCents: task.contractedRate,
            rateType: .flatPerTask,
            payBasis: .serviceStopTask,
            quantity: 1,
            quantityUnit: .each,
            totalAmountCents: total,
            completedDate: serviceStop.serviceDate,
            calculatedAt: now,
            calculationStatus: .calculated,
            approvedAt: nil,
            approvedByUserId: nil,
            paidAt: nil,
            paidByUserId: nil,
            voidedAt: nil,
            voidedByUserId: nil,
            voidReason: nil,
            payStatementId: nil,
            exportBatchId: nil,
            notes: "Used ServiceStopTask.contractedRate.",
            adminReviewNotes: nil,
            lineNumber: nil,
            lineReference: nil,
            paymentReference: nil,
            displayTitle: payrollDisplayTitle(
                serviceStop: serviceStop,
                serviceStopTask: task,
                workTypeName: workTypeName
            ),
            displaySubtitle: payrollDisplaySubtitle(
                serviceStop: serviceStop,
                serviceStopTask: task,
                workTypeName: workTypeName
            ),
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationAddress: serviceStop.address.streetAddress,
            jobId: serviceStop.jobId.isEmpty ? nil : serviceStop.jobId,
            jobInternalId: nil,
            taskName: task.name,
            serviceStopTypeName: serviceStop.type,
            serviceStopCategory: serviceStop.resolvedCategory
        )
    }
    func taskLineFromHourlyRate(
        companyId: String,
        serviceStop: ServiceStop,
        task: ServiceStopTask,
        worker: PayrollWorkerSnapshot,
        workTypeId: String,
        workTypeName: String?,
        minutes: Int,
        now: Date,
        notes: String
    ) -> TechnicianPayLineItem {
        guard let rate = activeRate(
            companyId: companyId,
            technicianId: worker.userId,
            workTypeId: workTypeId,
            payBasis: .technicianHourly,
            preferredRateType: .hourly,
            date: serviceStop.serviceDate,
            allowGeneralHourlyFallback: true
        ) else {
            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: task,
                worker: worker,
                source: .serviceStopTask,
                workTypeId: workTypeId,
                workTypeName: workTypeName,
                completedDate: serviceStop.serviceDate,
                now: now,
                notes: "No active hourly rate found for \(worker.userName)."
            )
        }

        return lineFromRate(
            serviceStop: serviceStop,
            serviceStopTask: task,
            worker: worker,
            source: .serviceStopTask,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            rate: rate,
            quantity: Double(minutes),
            quantityUnit: .minutes,
            completedDate: serviceStop.serviceDate,
            now: now,
            notes: notes
        )
    }
}

// MARK: - Shared Line Builders

private extension PayEngine {
    func manualPayOverrideLine(
        serviceStop: ServiceStop,
        amountCents: Int,
        now: Date
    ) -> TechnicianPayLineItem {
        let worker = serviceStopWorker(serviceStop)

        return TechnicianPayLineItem(
            id: makeLineId(
                source: .manualAdjustment,
                serviceStopId: serviceStop.id,
                serviceStopTaskId: nil,
                activeRouteId: nil,
                activeRouteLogId: nil,
                technicianId: worker.userId,
                workTypeId: nil
            ),
            companyId: serviceStop.companyId,
            technicianId: worker.userId,
            technicianName: worker.userName,
            workerType: worker.workerType,
            source: .manualAdjustment,
            serviceStopId: serviceStop.id,
            serviceStopTaskId: nil,
            activeRouteId: nil,
            activeRouteLogId: nil,
            workTypeId: serviceStop.payWorkTypeId ?? serviceStop.workTypeId,
            workTypeName: serviceStop.payWorkTypeName ?? serviceStop.workTypeName,
            rateId: nil,
            rateAmountCents: amountCents,
            rateType: .manual,
            payBasis: .manualAdjustment,
            quantity: 1,
            quantityUnit: .each,
            totalAmountCents: amountCents,
            completedDate: serviceStop.serviceDate,
            calculatedAt: now,
            calculationStatus: .calculated,
            approvedAt: nil,
            approvedByUserId: nil,
            paidAt: nil,
            paidByUserId: nil,
            voidedAt: nil,
            voidedByUserId: nil,
            voidReason: nil,
            payStatementId: nil,
            exportBatchId: nil,
            notes: serviceStop.manualPayOverrideNotes ?? "Manual payroll amount set while scheduling this service stop.",
            adminReviewNotes: nil,
            lineNumber: nil,
            lineReference: nil,
            paymentReference: nil,
            displayTitle: payrollDisplayTitle(
                serviceStop: serviceStop,
                serviceStopTask: nil,
                workTypeName: serviceStop.payWorkTypeName ?? serviceStop.workTypeName
            ),
            displaySubtitle: payrollDisplaySubtitle(
                serviceStop: serviceStop,
                serviceStopTask: nil,
                workTypeName: serviceStop.payWorkTypeName ?? serviceStop.workTypeName
            ),
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationAddress: serviceStop.address.streetAddress,
            jobId: serviceStop.jobId.isEmpty ? nil : serviceStop.jobId,
            jobInternalId: nil,
            taskName: nil,
            serviceStopTypeName: serviceStop.type,
            serviceStopCategory: serviceStop.resolvedCategory
        )
    }

    private func payrollDisplayTitle(
        serviceStop: ServiceStop,
        serviceStopTask: ServiceStopTask?,
        workTypeName: String?
    ) -> String {
        if let taskName = serviceStopTask?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !taskName.isEmpty {
            return taskName
        }

        if let workTypeName = workTypeName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !workTypeName.isEmpty {
            return workTypeName
        }

        let stopType = serviceStop.type.trimmingCharacters(in: .whitespacesAndNewlines)

        if !stopType.isEmpty {
            return stopType
        }

        return "Payroll Line Item"
    }

    private func payrollDisplaySubtitle(
        serviceStop: ServiceStop,
        serviceStopTask: ServiceStopTask?,
        workTypeName: String?
    ) -> String {
        var parts: [String] = []

        if let taskName = serviceStopTask?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !taskName.isEmpty {
            parts.append(taskName)
        } else if let workTypeName = workTypeName?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !workTypeName.isEmpty {
            parts.append(workTypeName)
        } else {
            let stopType = serviceStop.type.trimmingCharacters(in: .whitespacesAndNewlines)

            if !stopType.isEmpty {
                parts.append(stopType)
            }
        }

        let streetAddress = serviceStop.address.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)

        if !streetAddress.isEmpty {
            parts.append(streetAddress)
        }

        if let jobName = serviceStop.jobName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !jobName.isEmpty {
            parts.append(jobName)
        } else {
            let jobId = serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines)

            if !jobId.isEmpty {
                parts.append("Job \(jobId)")
            }
        }

        return parts.joined(separator: " • ")
    }
    
    
    func lineFromRate(
        serviceStop: ServiceStop,
        serviceStopTask: ServiceStopTask?,
        worker: PayrollWorkerSnapshot,
        source: PayLineItemSource,
        workTypeId: String?,
        workTypeName: String?,
        rate: TechnicianRate,
        quantity: Double,
        quantityUnit: PayQuantityUnit,
        completedDate: Date,
        now: Date,
        notes: String?
    ) -> TechnicianPayLineItem {
        guard rate.amountCents > 0 else {
            payrollDebug(
                "Skipping line because technician rate amount is 0. rateId: \(rate.id), worker: \(worker.userName), workType: \(workTypeName ?? workTypeId ?? "nil")"
            )

            return needsReviewLine(
                serviceStop: serviceStop,
                serviceStopTask: serviceStopTask,
                worker: worker,
                source: source,
                workTypeId: workTypeId,
                workTypeName: workTypeName,
                completedDate: completedDate,
                now: now,
                notes: "Technician rate exists but amount is 0."
            )
        }

        let total = PayMath.calculateTotalAmountCents(
            rateAmountCents: rate.amountCents,
            rateType: rate.rateType,
            quantity: quantity,
            quantityUnit: quantityUnit
        )

        let status: PayCalculationStatus = rate.rateType == .percentage
            ? .needsReview
            : .calculated

        let finalNotes: String? = rate.rateType == .percentage
            ? "Percentage pay needs an invoice or base amount before it can be calculated."
            : notes

        return TechnicianPayLineItem(
            id: makeLineId(
                source: source,
                serviceStopId: serviceStop.id,
                serviceStopTaskId: serviceStopTask?.id,
                activeRouteId: nil,
                activeRouteLogId: nil,
                technicianId: worker.userId,
                workTypeId: workTypeId
            ),
            companyId: serviceStop.companyId,
            technicianId: worker.userId,
            technicianName: worker.userName,
            workerType: worker.workerType,
            source: source,
            serviceStopId: serviceStop.id,
            serviceStopTaskId: serviceStopTask?.id,
            activeRouteId: nil,
            activeRouteLogId: nil,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            rateId: rate.id,
            rateAmountCents: rate.amountCents,
            rateType: rate.rateType,
            payBasis: rate.payBasis,
            quantity: quantity,
            quantityUnit: quantityUnit,
            totalAmountCents: total,
            completedDate: completedDate,
            calculatedAt: now,
            calculationStatus: status,
            approvedAt: nil,
            approvedByUserId: nil,
            paidAt: nil,
            paidByUserId: nil,
            voidedAt: nil,
            voidedByUserId: nil,
            voidReason: nil,
            payStatementId: nil,
            exportBatchId: nil,
            notes: finalNotes,
            adminReviewNotes: nil,
            lineNumber: nil,
            lineReference: nil,
            paymentReference: nil,
            displayTitle: payrollDisplayTitle(
                serviceStop: serviceStop,
                serviceStopTask: serviceStopTask,
                workTypeName: workTypeName
            ),
            displaySubtitle: payrollDisplaySubtitle(
                serviceStop: serviceStop,
                serviceStopTask: serviceStopTask,
                workTypeName: workTypeName
            ),
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationAddress: serviceStop.address.streetAddress,
            jobId: serviceStop.jobId.isEmpty ? nil : serviceStop.jobId,
            jobInternalId: nil,
            taskName: serviceStopTask?.name,
            serviceStopTypeName: serviceStop.type,
            serviceStopCategory: serviceStop.resolvedCategory
        )
    }
    func needsReviewLine(
        serviceStop: ServiceStop,
        serviceStopTask: ServiceStopTask?,
        worker: PayrollWorkerSnapshot,
        source: PayLineItemSource,
        workTypeId: String?,
        workTypeName: String?,
        completedDate: Date,
        now: Date,
        notes: String
    ) -> TechnicianPayLineItem {
        TechnicianPayLineItem(
            id: makeLineId(
                source: source,
                serviceStopId: serviceStop.id,
                serviceStopTaskId: serviceStopTask?.id,
                activeRouteId: nil,
                activeRouteLogId: nil,
                technicianId: worker.userId,
                workTypeId: workTypeId
            ),
            companyId: serviceStop.companyId,
            technicianId: worker.userId,
            technicianName: worker.userName,
            workerType: worker.workerType,
            source: source,
            serviceStopId: serviceStop.id,
            serviceStopTaskId: serviceStopTask?.id,
            activeRouteId: nil,
            activeRouteLogId: nil,
            workTypeId: workTypeId,
            workTypeName: workTypeName,
            rateId: nil,
            rateAmountCents: 0,
            rateType: .manual,
            payBasis: nil,
            quantity: 0,
            quantityUnit: .each,
            totalAmountCents: 0,
            completedDate: completedDate,
            calculatedAt: now,
            calculationStatus: .needsReview,
            approvedAt: nil,
            approvedByUserId: nil,
            paidAt: nil,
            paidByUserId: nil,
            voidedAt: nil,
            voidedByUserId: nil,
            voidReason: nil,
            payStatementId: nil,
            exportBatchId: nil,
            notes: notes,
            adminReviewNotes: nil,
            lineNumber: nil,
            lineReference: nil,
            paymentReference: nil,
            displayTitle: payrollDisplayTitle(
                serviceStop: serviceStop,
                serviceStopTask: serviceStopTask,
                workTypeName: workTypeName
            ),
            displaySubtitle: payrollDisplaySubtitle(
                serviceStop: serviceStop,
                serviceStopTask: serviceStopTask,
                workTypeName: workTypeName
            ),
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationAddress: serviceStop.address.streetAddress,
            jobId: serviceStop.jobId.isEmpty ? nil : serviceStop.jobId,
            jobInternalId: nil,
            taskName: serviceStopTask?.name,
            serviceStopTypeName: serviceStop.type,
            serviceStopCategory: serviceStop.resolvedCategory
        )
    }
}

// MARK: - Lookup Helpers

private extension PayEngine {

    func serviceStopWorkTypeIds(for serviceStop: ServiceStop) -> [String] {
        
        payrollDebug("Resolving service stop work types")
        payrollDebug("serviceStop.id: \(serviceStop.id)")
        payrollDebug("serviceStop.typeId: \(serviceStop.typeId)")
        payrollDebug("serviceStop.type: \(serviceStop.type)")
        payrollDebug("recurringServiceStopId: \(serviceStop.recurringServiceStopId)")
        payrollDebug("jobId: \(serviceStop.jobId)")
        payrollDebug("inferred sourceId: \(serviceStop.inferredPayrollServiceStopSourceId)")
        payrollDebug("serviceStopTypes count: \(serviceStopTypes.count)")
        payrollDebug("mappings count: \(mappings.count)")
        payrollDebug("workTypes count: \(workTypes.count)")
        
        // 1. Preferred path:
        // ServiceStop.typeId points to a real CompanyServiceStopType.
        if let serviceStopType = serviceStopTypesById[serviceStop.typeId],
           !serviceStopType.defaultWorkTypeIds.isEmpty {
            return uniqueIds(serviceStopType.defaultWorkTypeIds)
        }
        payrollDebug("No CompanyServiceStopType match for typeId: \(serviceStop.typeId)")

        // 2. Explicit fallback mapping path:
        // Map whatever serviceStop.typeId currently is.
        let explicitTypeIds = mappedWorkTypeIds(
            sourceType: .serviceStopType,
            sourceId: serviceStop.typeId
        )
        
        payrollDebug("Explicit mapping workTypeIds for \(serviceStop.typeId): \(explicitTypeIds)")

        if !explicitTypeIds.isEmpty {
            return explicitTypeIds
        }

        // 3. System fallback path:
        // Since typeId is not hooked up, infer recurring vs job.
        let inferredTypeIds = mappedWorkTypeIds(
            sourceType: .serviceStopType,
            sourceId: serviceStop.inferredPayrollServiceStopSourceId
        )
        
        payrollDebug("Inferred mapping workTypeIds for \(serviceStop.inferredPayrollServiceStopSourceId): \(inferredTypeIds)")

        return inferredTypeIds
    }

    func mappedWorkTypeIds(
        sourceType: WorkTypeSource,
        sourceId: String
    ) -> [String] {
        guard !sourceId.isBlank else {
            payrollDebug("Mapping skipped because sourceId is blank for sourceType \(sourceType.rawValue)")
            return []
        }

        payrollDebug("Looking for mapping sourceType: \(sourceType.rawValue), sourceId: \(sourceId)")
        payrollDebug("Looking for mapping  companyId: \(settings.companyId)")

        let matchingMappings = mappings.filter {
//            $0.companyId == settings.companyId &&
            $0.sourceType == sourceType &&
            $0.sourceId == sourceId
        }

        payrollDebug("Matching mappings found: \(matchingMappings.count)")
        if matchingMappings.isEmpty {
            for mapping in mappings {
                
                payrollDebug("Looking for Mapping: \(mapping)")
                print("")
                payrollDebug("Looking for settings: \(settings.companyId), sourceId: \(mapping.companyId)")
                payrollDebug("Looking for sourceType: \(sourceType), sourceId: \(mapping.sourceType)")
                payrollDebug("Looking for sourceId: \(sourceId), sourceId: \(mapping.sourceId)")

            }
        }
        for mapping in matchingMappings {
            payrollDebug("Mapping: \(mapping.sourceType.rawValue) \(mapping.sourceId) -> \(mapping.workTypeId)")
        }

        let ids = matchingMappings.map { $0.workTypeId }
        
        return uniqueIds(ids)
    }

    func activeRate(
        companyId:String,
        technicianId: String,
        workTypeId: String?,
        payBasis: PayBasis,
        preferredRateType: RateType?,
        date: Date,
        allowGeneralHourlyFallback: Bool
    ) -> TechnicianRate? {
        payrollDebug("[activeRate] lookup companyId=\(companyId) technicianId=\(technicianId) workTypeId=\(workTypeId ?? "nil") payBasis=\(payBasis.rawValue) preferredRateType=\(preferredRateType?.rawValue ?? "nil") date=\(date) allowGeneralHourlyFallback=\(allowGeneralHourlyFallback) totalRates=\(rates.count)")

        var rejectionCounts: [String: Int] = [:]

        func reject(_ reason: String) -> Bool {
            rejectionCounts[reason, default: 0] += 1
            return false
        }

        let candidates = rates.filter { rate in
            guard rate.companyId == companyId else {
                return reject("companyId")
            }
            guard rate.technicianId == technicianId else {
                return reject("technicianId")
            }
            guard rateIsUsable(rate, on: date) else {
                return reject("usableDateOrStatus")
            }

            let exactPayBasisMatch = rate.payBasis == payBasis

            let hourlyFallback =
                allowGeneralHourlyFallback &&
                rate.payBasis == .technicianHourly &&
                rate.rateType == .hourly

            guard exactPayBasisMatch || hourlyFallback else {
                return reject("payBasis")
            }

            let exactWorkTypeMatch = rate.workTypeId == workTypeId

            let generalHourlyFallback =
                allowGeneralHourlyFallback &&
                rate.workTypeId == nil &&
                rate.rateType == .hourly

            guard exactWorkTypeMatch || generalHourlyFallback else {
                return reject("workTypeId")
            }

            return true
        }

        if candidates.isEmpty {
            payrollDebug("[activeRate] no candidates. rejectionCounts=\(rejectionCounts)")
            let nearbyRates = rates.filter { rate in
                rate.companyId == companyId &&
                (rate.technicianId == technicianId || rate.workTypeId == workTypeId)
            }

            for rate in nearbyRates.prefix(12) {
                payrollDebug("[activeRate] nearby rate id=\(rate.id) technicianId=\(rate.technicianId) workTypeId=\(rate.workTypeId ?? "nil") payBasis=\(rate.payBasis.rawValue) rateType=\(rate.rateType.rawValue) amountCents=\(rate.amountCents) status=\(rate.status.rawValue) start=\(rate.effectiveStartDate) end=\(String(describing: rate.effectiveEndDate))")
            }
        } else {
            payrollDebug("[activeRate] candidates=\(candidates.map { $0.id })")
        }

        if let preferredRateType {
            let preferred = candidates
                .filter { $0.rateType == preferredRateType }
                .sorted(by: sortRates)
                .first

            if let preferred {
                return preferred
            }
        }

        return candidates
            .sorted(by: sortRates)
            .first
    }

    func serviceStopProductionPayBasis(for workType: CompanyWorkType?) -> PayBasis {
        guard let workType else {
            return .serviceStop
        }

        let suggestedBasis = workType.suggestedPayBasis

        switch suggestedBasis {
        case .serviceStop, .serviceStopTask:
            return suggestedBasis
        case .technicianHourly, .manualAdjustment:
            return .serviceStop
        }
    }

    func rateIsUsable(_ rate: TechnicianRate, on date: Date) -> Bool {
        guard rate.status != .draft else { return false }
        guard rate.status != .archived else { return false }
        guard rate.effectiveStartDate <= date else { return false }

        if let endDate = rate.effectiveEndDate, date > endDate {
            return false
        }

        return true
    }

    func sortRates(_ lhs: TechnicianRate, _ rhs: TechnicianRate) -> Bool {
        // Prefer work-type-specific rates over general hourly rates.
        if lhs.workTypeId != nil && rhs.workTypeId == nil {
            return true
        }

        if lhs.workTypeId == nil && rhs.workTypeId != nil {
            return false
        }

        // Prefer most recent rate.
        return lhs.effectiveStartDate > rhs.effectiveStartDate
    }

    func serviceStopWorker(_ serviceStop: ServiceStop) -> PayrollWorkerSnapshot {
        if let worker = workersByUserId[serviceStop.techId] {
            return worker
        }

        return PayrollWorkerSnapshot(
            userId: serviceStop.techId,
            userName: serviceStop.tech,
            workerType: .notAssigned
        )
    }

    func taskWorker(
        serviceStop: ServiceStop,
        task: ServiceStopTask
    ) -> PayrollWorkerSnapshot {
        let workerId = task.workerId.isBlank ? serviceStop.techId : task.workerId

        let knownWorker = workersByUserId[workerId]

        let workerName: String = {
            if !task.workerName.isBlank {
                return task.workerName
            }

            if let knownWorker {
                return knownWorker.userName
            }

            return serviceStop.tech
        }()

        let workerType: WorkerTypeEnum = {
            if task.workerType != .notAssigned {
                return task.workerType
            }

            if let knownWorker {
                return knownWorker.workerType
            }

            return .notAssigned
        }()

        return PayrollWorkerSnapshot(
            userId: workerId,
            userName: workerName,
            workerType: workerType
        )
    }

    func quantityAndUnit(
        for rateType: RateType,
        serviceStop: ServiceStop,
        task: ServiceStopTask?,
        minutesOverride: Int?
    ) -> (quantity: Double, unit: PayQuantityUnit) {
        switch rateType {
        case .flatPerStop, .flatPerTask, .manual:
            return (1, .each)

        case .hourly:
            let minutes = minutesOverride ?? task?.actualTime ?? serviceStop.duration
            return (Double(minutes), .minutes)

        case .perBodyOfWater:
            // First version.
            // Later this should receive a serviceLocation/bodyOfWater count.
            return (1, .bodyOfWater)

        case .perServiceLocation:
            return (1, .serviceLocation)

        case .percentage:
            return (1, .percent)
        }
    }

    func makeLineId(
        source: PayLineItemSource,
        serviceStopId: String?,
        serviceStopTaskId: String?,
        activeRouteId: String?,
        activeRouteLogId: String?,
        technicianId: String,
        workTypeId: String?
    ) -> String {
        [
            "comp_pay_line",
            source.rawValue,
            serviceStopId ?? "no_stop",
            serviceStopTaskId ?? "no_task",
            activeRouteId ?? "no_route",
            activeRouteLogId ?? "no_route_log",
            technicianId,
            workTypeId ?? "no_work_type"
        ].joined(separator: "_")
    }

    func uniqueIds(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for id in ids where !id.isBlank {
            if !seen.contains(id) {
                result.append(id)
                seen.insert(id)
            }
        }

        return result
    }
    private func payrollDebug(_ message: String) {
        #if DEBUG
        print("🧾 [Payroll Debug] \(message)")
        #endif
    }
}
