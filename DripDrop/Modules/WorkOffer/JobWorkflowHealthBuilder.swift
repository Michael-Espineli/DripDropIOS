//
//  JobWorkflowHealthBuilder.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


//
//  JobWorkflowHealthBuilder.swift
//  DripDrop
//

import Foundation

enum JobWorkflowHealthBuilder {

    static func buildReport(
        job: Job,
        jobTasks: [JobTask],
        serviceStops: [ServiceStop],
        workOffers: [WorkOffer],
        payLineItems: [TechnicianPayLineItem],
        shoppingItems: [ShoppingListItem],
        purchasedItems: [PurchasedItem],
        plannedLaborCents: Int,
        actualPayrollCents: Int,
        plannedMaterialCostCents: Int,
        actualMaterialCostCents: Int
    ) -> JobWorkflowHealthReport {
        var issues: [JobWorkflowHealthIssue] = []

        addPlanningChecks(
            issues: &issues,
            job: job,
            jobTasks: jobTasks,
            plannedLaborCents: plannedLaborCents
        )

        addOfferChecks(
            issues: &issues,
            workOffers: workOffers
        )

        addScheduleChecks(
            issues: &issues,
            jobTasks: jobTasks,
            serviceStops: serviceStops,
            workOffers: workOffers
        )

        addActualWorkChecks(
            issues: &issues,
            serviceStops: serviceStops
        )

        addPayrollChecks(
            issues: &issues,
            serviceStops: serviceStops,
            payLineItems: payLineItems,
            plannedLaborCents: plannedLaborCents,
            actualPayrollCents: actualPayrollCents
        )

        addMaterialChecks(
            issues: &issues,
            shoppingItems: shoppingItems,
            purchasedItems: purchasedItems,
            plannedMaterialCostCents: plannedMaterialCostCents,
            actualMaterialCostCents: actualMaterialCostCents
        )

        addBillingChecks(
            issues: &issues,
            job: job,
            serviceStops: serviceStops,
            payLineItems: payLineItems,
            purchasedItems: purchasedItems
        )

        if issues.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "job_healthy",
                    severity: .success,
                    category: .planning,
                    title: "Job workflow looks healthy",
                    message: "No major workflow issues were found.",
                    actionTitle: nil,
                    destinationTab: nil
                )
            )
        }

        return JobWorkflowHealthReport(issues: issues)
    }

    // MARK: - Planning

    private static func addPlanningChecks(
        issues: inout [JobWorkflowHealthIssue],
        job: Job,
        jobTasks: [JobTask],
        plannedLaborCents: Int
    ) {
        if jobTasks.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "planning_no_tasks",
                    severity: .critical,
                    category: .planning,
                    title: "No planned tasks",
                    message: "This job does not have planned tasks yet. Add tasks before offering, scheduling, or estimating work.",
                    actionTitle: "Go To Tasks",
                    destinationTab: "Tasks"
                )
            )
        }

        if !jobTasks.isEmpty && plannedLaborCents <= 0 {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "planning_zero_labor",
                    severity: .warning,
                    category: .planning,
                    title: "Planned labor is $0",
                    message: "The job has tasks, but the planned labor total is zero. This may make estimates and profit projections inaccurate.",
                    actionTitle: "Review Tasks",
                    destinationTab: "Tasks"
                )
            )
        }

        if job.rate <= 0 {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "planning_zero_rate",
                    severity: .warning,
                    category: .billing,
                    title: "Customer price is $0",
                    message: "The job rate is zero. Add a customer-facing estimate or price before billing.",
                    actionTitle: "Go To Billing",
                    destinationTab: "Billing"
                )
            )
        }
    }

    // MARK: - Offers

    private static func addOfferChecks(
        issues: inout [JobWorkflowHealthIssue],
        workOffers: [WorkOffer]
    ) {
        let openOffers = workOffers.filter { $0.status.isOpen }

        if !openOffers.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "offers_open",
                    severity: .info,
                    category: .offers,
                    title: "\(openOffers.count) open work offer(s)",
                    message: "Some work offers are still waiting for a contractor or worker response.",
                    actionTitle: "Review Offers",
                    destinationTab: "Offers"
                )
            )
        }

        let acceptedReadyToSchedule = workOffers.filter {
            $0.status == .accepted &&
            $0.serviceStopId.isEmpty
        }

        if !acceptedReadyToSchedule.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "offers_accepted_ready_to_schedule",
                    severity: .warning,
                    category: .offers,
                    title: "\(acceptedReadyToSchedule.count) accepted offer(s) ready to schedule",
                    message: "Accepted work offers need to become scheduled service stops before the work can be completed.",
                    actionTitle: "Go To Schedule",
                    destinationTab: "Schedule"
                )
            )
        }
    }

    // MARK: - Schedule

    private static func addScheduleChecks(
        issues: inout [JobWorkflowHealthIssue],
        jobTasks: [JobTask],
        serviceStops: [ServiceStop],
        workOffers: [WorkOffer]
    ) {
        if !jobTasks.isEmpty && serviceStops.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "schedule_no_service_stops",
                    severity: .warning,
                    category: .schedule,
                    title: "No service stops scheduled",
                    message: "This job has planned work but no scheduled service stops.",
                    actionTitle: "Go To Schedule",
                    destinationTab: "Schedule"
                )
            )
        }

        let unfinishedStops = serviceStops.filter { $0.operationStatus != .finished }

        if !unfinishedStops.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "schedule_unfinished_stops",
                    severity: .info,
                    category: .schedule,
                    title: "\(unfinishedStops.count) unfinished service stop(s)",
                    message: "Some scheduled work has not been finished yet.",
                    actionTitle: "Review Schedule",
                    destinationTab: "Schedule"
                )
            )
        }

        let scheduledOffersWithoutStop = workOffers.filter {
            $0.status == .scheduled &&
            $0.serviceStopId.isEmpty
        }

        if !scheduledOffersWithoutStop.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "schedule_offer_marked_scheduled_missing_stop",
                    severity: .critical,
                    category: .schedule,
                    title: "Scheduled offer missing service stop",
                    message: "One or more offers are marked scheduled but are not linked to a service stop.",
                    actionTitle: "Review Offers",
                    destinationTab: "Offers"
                )
            )
        }
    }

    // MARK: - Actual Work

    private static func addActualWorkChecks(
        issues: inout [JobWorkflowHealthIssue],
        serviceStops: [ServiceStop]
    ) {
        let finishedStops = serviceStops.filter { $0.operationStatus == .finished }

        if !finishedStops.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "actual_finished_stops",
                    severity: .success,
                    category: .actualWork,
                    title: "\(finishedStops.count) finished service stop(s)",
                    message: "Completed service stops are available for actual work and payroll review.",
                    actionTitle: "Review Actual",
                    destinationTab: "Actual"
                )
            )
        }
    }

    // MARK: - Payroll

    private static func addPayrollChecks(
        issues: inout [JobWorkflowHealthIssue],
        serviceStops: [ServiceStop],
        payLineItems: [TechnicianPayLineItem],
        plannedLaborCents: Int,
        actualPayrollCents: Int
    ) {
        let finishedStops = serviceStops.filter { $0.operationStatus == .finished }

        if !finishedStops.isEmpty && payLineItems.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "payroll_finished_stops_no_pay",
                    severity: .critical,
                    category: .payroll,
                    title: "Finished work has no payroll lines",
                    message: "At least one service stop is finished, but no technician pay line items were found for this job.",
                    actionTitle: "Review Actual",
                    destinationTab: "Actual"
                )
            )
        }

        let needsReview = payLineItems.filter { $0.calculationStatus == .needsReview }

        if !needsReview.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "payroll_needs_review",
                    severity: .warning,
                    category: .payroll,
                    title: "\(needsReview.count) payroll line(s) need review",
                    message: "Some pay lines need rate, mapping, or admin review before payroll can be approved.",
                    actionTitle: "Review Actual",
                    destinationTab: "Actual"
                )
            )
        }

        if plannedLaborCents > 0 && actualPayrollCents > plannedLaborCents {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "payroll_over_planned",
                    severity: .warning,
                    category: .payroll,
                    title: "Actual payroll is above planned labor",
                    message: "Actual payroll is higher than the planned labor budget for this job.",
                    actionTitle: "Review Actual",
                    destinationTab: "Actual"
                )
            )
        }
    }

    // MARK: - Materials

    private static func addMaterialChecks(
        issues: inout [JobWorkflowHealthIssue],
        shoppingItems: [ShoppingListItem],
        purchasedItems: [PurchasedItem],
        plannedMaterialCostCents: Int,
        actualMaterialCostCents: Int
    ) {
        let needPurchaseItems = shoppingItems.filter {
            $0.status.rawValue.localizedCaseInsensitiveContains("Need")
        }

        if !needPurchaseItems.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "materials_need_purchase",
                    severity: .info,
                    category: .materials,
                    title: "\(needPurchaseItems.count) material item(s) need purchase",
                    message: "Some planned materials still need to be purchased.",
                    actionTitle: "Review Materials",
                    destinationTab: "Materials"
                )
            )
        }

        let billableMissingRate = purchasedItems.filter {
            $0.billable &&
            $0.billingRate == nil
        }

        if !billableMissingRate.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "materials_billable_missing_rate",
                    severity: .warning,
                    category: .materials,
                    title: "\(billableMissingRate.count) billable item(s) missing billing rate",
                    message: "Some purchased items are billable but do not have a billing rate set.",
                    actionTitle: "Review Materials",
                    destinationTab: "Materials"
                )
            )
        }

        let billableNotInvoiced = purchasedItems.filter {
            $0.billable && !$0.invoiced
        }

        if !billableNotInvoiced.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "materials_billable_not_invoiced",
                    severity: .warning,
                    category: .materials,
                    title: "\(billableNotInvoiced.count) billable material item(s) not invoiced",
                    message: "Billable purchased items are linked to this job but have not been invoiced.",
                    actionTitle: "Review Materials",
                    destinationTab: "Materials"
                )
            )
        }

        if plannedMaterialCostCents > 0 && actualMaterialCostCents > plannedMaterialCostCents {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "materials_over_planned",
                    severity: .warning,
                    category: .materials,
                    title: "Actual material cost is above planned",
                    message: "Purchased material cost is higher than the planned material cost.",
                    actionTitle: "Review Materials",
                    destinationTab: "Materials"
                )
            )
        }
    }

    // MARK: - Billing

    private static func addBillingChecks(
        issues: inout [JobWorkflowHealthIssue],
        job: Job,
        serviceStops: [ServiceStop],
        payLineItems: [TechnicianPayLineItem],
        purchasedItems: [PurchasedItem]
    ) {
        let finishedStops = serviceStops.filter { $0.operationStatus == .finished }

        if job.operationStatus == .finished && job.billingStatus != .invoiced && job.billingStatus != .paid {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "billing_job_finished_not_invoiced",
                    severity: .warning,
                    category: .billing,
                    title: "Job finished but not invoiced",
                    message: "This job is marked finished but has not been invoiced or paid.",
                    actionTitle: "Go To Billing",
                    destinationTab: "Billing"
                )
            )
        }

        if job.billingStatus == .invoiced {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "billing_invoiced_not_paid",
                    severity: .info,
                    category: .billing,
                    title: "Job invoiced but not paid",
                    message: "This job has been invoiced and is waiting for payment.",
                    actionTitle: "Go To Billing",
                    destinationTab: "Billing"
                )
            )
        }

        if job.billingStatus == .accepted && serviceStops.isEmpty {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "billing_accepted_no_schedule",
                    severity: .warning,
                    category: .billing,
                    title: "Estimate accepted but no work scheduled",
                    message: "The estimate is accepted, but no service stops are scheduled.",
                    actionTitle: "Go To Schedule",
                    destinationTab: "Schedule"
                )
            )
        }

        let billableNotInvoiced = purchasedItems.filter {
            $0.billable && !$0.invoiced
        }

        if !finishedStops.isEmpty &&
            !payLineItems.isEmpty &&
            billableNotInvoiced.isEmpty &&
            job.billingStatus == .inProgress {
            issues.append(
                JobWorkflowHealthIssue(
                    id: "billing_ready_to_invoice",
                    severity: .success,
                    category: .billing,
                    title: "Job may be ready to invoice",
                    message: "Finished work, payroll, and materials look ready for billing review.",
                    actionTitle: "Go To Billing",
                    destinationTab: "Billing"
                )
            )
        }
    }
}