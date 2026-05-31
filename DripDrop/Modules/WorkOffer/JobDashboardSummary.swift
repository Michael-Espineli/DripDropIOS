//
//  JobDashboardSummary.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


import Foundation

struct JobDashboardSummary: Hashable {
    var jobRateCents: Int

    var plannedTaskLaborCents: Int
    var plannedServiceStopLaborCents: Int
    
    var actualPayrollCents: Int

    var plannedMaterialCostCents: Int
    var plannedMaterialPriceCents: Int

    var actualMaterialCostCents: Int
    var actualMaterialBillableCents: Int

    var serviceStopCount: Int
    var finishedServiceStopCount: Int

    var openOfferCount: Int
    var acceptedOfferCount: Int
    var acceptedOffersReadyToScheduleCount: Int

    var payrollNeedsReviewCount: Int
    
    var plannedLaborCents: Int {
        plannedTaskLaborCents + plannedServiceStopLaborCents
    }
    
    var plannedTotalCostCents: Int {
        plannedLaborCents + plannedMaterialCostCents
    }

    var actualTotalCostCents: Int {
        actualPayrollCents + actualMaterialCostCents
    }

    var plannedRevenueCents: Int {
        if jobRateCents > 0 {
            return jobRateCents
        }

        return plannedLaborCents + plannedMaterialPriceCents
    }

    var plannedProfitCents: Int {
        plannedRevenueCents - plannedTotalCostCents
    }

    var actualProfitCents: Int {
        plannedRevenueCents - actualTotalCostCents
    }

    var laborDifferenceCents: Int {
        actualPayrollCents - plannedLaborCents
    }

    var materialDifferenceCents: Int {
        actualMaterialCostCents - plannedMaterialCostCents
    }
}
