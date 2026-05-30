//
//  PaySheets+Helpers.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation

extension CompanyPaySettings {
    static func productionDefault(companyId: String) -> CompanyPaySettings {
        CompanyPaySettings(
            companyId: companyId,
            payMode: .productionOnly,
            routePaySource: .serviceStopAndCompletedTasks,
            taskPaySource: .technicianRateThenTaskContractedRate,
            allowMultipleWorkTypesPerStop: true,
            defaultStackBehavior: .stackable,
            allowTechnicianRateOverrides: true,
            allowManualPayAdjustments: true,
            payCommercialAsSeparateWorkType: true,
            paySpaAsSeparateWorkType: true,
            payPerBodyOfWater: true,
            lockPayAfterApproval: true,
            recalculateUnapprovedPayWhenRatesChange: false
        )
    }

    static func hourlyDefault(companyId: String) -> CompanyPaySettings {
        CompanyPaySettings(
            companyId: companyId,
            payMode: .hourlyOnly,
            routePaySource: .hourlyServiceStopDuration,
            taskPaySource: .hourlyActualTime,
            allowMultipleWorkTypesPerStop: false,
            defaultStackBehavior: .stackable,
            allowTechnicianRateOverrides: true,
            allowManualPayAdjustments: true,
            payCommercialAsSeparateWorkType: false,
            paySpaAsSeparateWorkType: false,
            payPerBodyOfWater: false,
            lockPayAfterApproval: true,
            recalculateUnapprovedPayWhenRatesChange: false
        )
    }
}
