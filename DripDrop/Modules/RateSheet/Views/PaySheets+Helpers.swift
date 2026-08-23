//
//  PaySheets+Helpers.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation

// MARK: - System Mapping Source IDs

enum PayrollSystemSourceIds {
static let recurringServiceStop = "system_recurring_service_stop"
static let commercialRoute = "system_recurring_commercial_pay_type"
static let jobServiceStop = "system_job_service_stop"
static let jobSaltCellCleaning = "system_job_salt_cell_cleaning_pay_type"
static let jobEstimateServiceStop = "system_job_estimate_service_stop"
static let serviceAgreementEstimateServiceStop = "system_service_agreement_estimate_service_stop"
static let customerRelationshipServiceStop = "system_customer_relationship_service_stop"
static let unknownServiceStop = "system_unknown_service_stop"
}

// MARK: - Defaults

extension CompanyPaySettings {

static func defaultSettings() -> CompanyPaySettings {
    defaultSettings(companyId: "")
}

static func defaultSettings(companyId: String) -> CompanyPaySettings {
    dripDropProductionDefault(companyId: companyId)
}

static func dripDropProductionDefault() -> CompanyPaySettings {
    dripDropProductionDefault(companyId: "")
}

static func dripDropProductionDefault(companyId: String) -> CompanyPaySettings {
    CompanyPaySettings(
        companyId: companyId,
        payMode: .productionOnly,
        routePaySource: .serviceStopAndCompletedTasks,
        taskPaySource: .technicianRateThenTaskContractedRate,
        hourlyPaySource: .none,
        allowMultipleWorkTypesPerStop: false,
        defaultStackBehavior: .stackable,
        allowTechnicianRateOverrides: true,
        allowManualPayAdjustments: false,
        payCommercialAsSeparateWorkType: false,
        paySpaAsSeparateWorkType: false,
        payPerBodyOfWater: false,
        commercialMultiBodyPayStyle: .singleCommercialRate,
        lockPayAfterApproval: true,
        recalculateUnapprovedPayWhenRatesChange: true
    )
}

static func hourlyDefault(companyId: String) -> CompanyPaySettings {
    CompanyPaySettings(
        companyId: companyId,
        payMode: .hourlyOnly,
        routePaySource: .none,
        taskPaySource: .none,
        hourlyPaySource: .activeRouteDuration,
        allowMultipleWorkTypesPerStop: false,
        defaultStackBehavior: .stackable,
        allowTechnicianRateOverrides: true,
        allowManualPayAdjustments: false,
        payCommercialAsSeparateWorkType: false,
        paySpaAsSeparateWorkType: false,
        payPerBodyOfWater: false,
        commercialMultiBodyPayStyle: .singleCommercialRate,
        lockPayAfterApproval: true,
        recalculateUnapprovedPayWhenRatesChange: true
    )
}

static func hybridDefault(companyId: String) -> CompanyPaySettings {
    CompanyPaySettings(
        companyId: companyId,
        payMode: .hybrid,
        routePaySource: .serviceStopAndCompletedTasks,
        taskPaySource: .technicianRateThenTaskContractedRate,
        hourlyPaySource: .activeRouteDuration,
        allowMultipleWorkTypesPerStop: false,
        defaultStackBehavior: .stackable,
        allowTechnicianRateOverrides: true,
        allowManualPayAdjustments: false,
        payCommercialAsSeparateWorkType: false,
        paySpaAsSeparateWorkType: false,
        payPerBodyOfWater: false,
        commercialMultiBodyPayStyle: .singleCommercialRate,
        lockPayAfterApproval: true,
        recalculateUnapprovedPayWhenRatesChange: true
    )
}
}

// MARK: - Payroll Completion Helpers

extension ServiceStop {
var isFinishedForPay: Bool {
    operationStatus == .finished
}

var inferredPayrollServiceStopSourceId: String {
    switch resolvedCategory {
    case .route:
        return PayrollSystemSourceIds.recurringServiceStop
    case .job:
        return PayrollSystemSourceIds.jobServiceStop
    case .jobEstimate:
        return PayrollSystemSourceIds.jobEstimateServiceStop
    case .serviceAgreementEstimate:
        return PayrollSystemSourceIds.serviceAgreementEstimateServiceStop
    case .customerRelationship:
        return PayrollSystemSourceIds.customerRelationshipServiceStop
    }
}
}

extension ServiceStopTask {
var isFinishedForPay: Bool {
    status == .finished
}

var payrollTaskSourceId: String {
    type.rawValue
}
}

extension String {
var isBlank: Bool {
    trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}
}

// MARK: - Display Helpers

extension CompanyPayMode {
var title: String {
    switch self {
    case .productionOnly: return "Production Pay"
    case .hourlyOnly: return "Hourly Pay"
    case .hybrid: return "Hybrid Pay"
    }
}

var helpText: String {
    switch self {
    case .productionOnly:
        return "Technicians are paid based on completed stops, tasks, and pay types."
    case .hourlyOnly:
        return "Technicians are paid based on time worked, usually from an active route or time log."
    case .hybrid:
        return "Some work is paid by production rate, and some work is paid hourly."
    }
}
}

extension RoutePaySource {
var title: String {
    switch self {
    case .serviceStop:
        return "Completed stop only"
    case .completedTasks:
        return "Completed tasks only"
    case .serviceStopAndCompletedTasks:
        return "Stop plus completed tasks"
    case .hourlyServiceStopDuration:
        return "Hourly from stop duration"
    case .hourlyTaskActualTime:
        return "Hourly from task time"
    case .none:
        return "No automatic stop pay"
    }
}

var helpText: String {
    switch self {
    case .serviceStop:
        return "A completed service stop creates one pay item."
    case .completedTasks:
        return "The stop itself does not create pay. Only completed tasks do."
    case .serviceStopAndCompletedTasks:
        return "The completed stop creates pay, and completed payable tasks can add more pay."
    case .hourlyServiceStopDuration:
        return "Pay is based on the service stop duration."
    case .hourlyTaskActualTime:
        return "Pay is based on actual time entered on completed tasks."
    case .none:
        return "No automatic stop pay will be generated."
    }
}
}

extension TaskPaySource {
var title: String {
    switch self {
    case .technicianRate:
        return "Technician rate"
    case .taskContractedRate:
        return "Task contracted rate"
    case .technicianRateThenTaskContractedRate:
        return "Technician rate, then task fallback"
    case .taskContractedRateThenTechnicianRate:
        return "Task rate, then technician fallback"
    case .hourlyActualTime:
        return "Hourly actual time"
    case .hourlyEstimatedTime:
        return "Hourly estimated time"
    case .none:
        return "No automatic task pay"
    }
}

var helpText: String {
    switch self {
    case .technicianRate:
        return "Use the technician's active rate for the task's pay type."
    case .taskContractedRate:
        return "Use ServiceStopTask.contractedRate."
    case .technicianRateThenTaskContractedRate:
        return "Prefer technician-specific rate. If missing, use task contracted rate."
    case .taskContractedRateThenTechnicianRate:
        return "Prefer task contracted rate. If missing, use technician-specific rate."
    case .hourlyActualTime:
        return "Use actualTime and the technician's hourly rate."
    case .hourlyEstimatedTime:
        return "Use estimatedTime and the technician's hourly rate."
    case .none:
        return "Completed tasks will not automatically create pay."
    }
}
}

extension HourlyPaySource {
var title: String {
    switch self {
    case .activeRouteDuration:
        return "Active route duration"
    case .activeRouteLogs:
        return "Active route logs"
    case .serviceStopDuration:
        return "Service stop duration"
    case .taskActualTime:
        return "Task actual time"
    case .none:
        return "No hourly pay"
    }
}

var helpText: String {
    switch self {
    case .activeRouteDuration:
        return "Generate hourly pay from the total ActiveRoute start and end time."
    case .activeRouteLogs:
        return "Generate hourly pay from individual ActiveRouteLog records."
    case .serviceStopDuration:
        return "Generate hourly pay from each service stop duration."
    case .taskActualTime:
        return "Generate hourly pay from completed task actualTime."
    case .none:
        return "No hourly pay line items are generated."
    }
}
}

extension CommercialMultiBodyPayStyle {
var title: String {
    switch self {
    case .singleCommercialRate:
        return "Single commercial rate"
    case .sameRatePerBodyOfWater:
        return "Same rate per body of water"
    case .basePlusAdditionalBodyRate:
        return "Base plus additional body rate"
    }
}

var helpText: String {
    switch self {
    case .singleCommercialRate:
        return "Commercial stops pay one flat commercial rate."
    case .sameRatePerBodyOfWater:
        return "Each body of water pays the same rate."
    case .basePlusAdditionalBodyRate:
        return "The first body of water pays a base rate, and additional bodies pay a separate rate."
    }
}
}

extension RateStackBehavior {
static var selectableCases: [RateStackBehavior] {
    [.stackable, .exclusive, .replacesBase, .modifier]
}

var title: String {
    switch self {
    case .stackable:
        return "Stackable"
    case .exclusive:
        return "Exclusive"
    case .replacesBase:
        return "Replaces base"
    case .modifier:
        return "Modifier"
    }
}

    var helpText: String {
        switch self {
        case .stackable:
            return "This pay type can pay alongside completed task pay."
        case .exclusive:
            return "Only one matching rate should win."
    case .replacesBase:
        return "This pay type replaces the normal base pay."
    case .modifier:
        return "This pay type modifies another rate."
    }
}
}

extension PayCalculationStatus {
var title: String {
    switch self {
    case .pending: return "Pending"
    case .calculated: return "Calculated"
    case .needsReview: return "Needs Review"
    case .approved: return "Approved"
    case .paid: return "Paid"
    case .voided: return "Voided"
    case .adjusted: return "Adjusted"
    }
}
}

// MARK: - Work Category Helpers

extension WorkCategory {

    static var selectableCases: [WorkCategory] {
        [
            .route,
            .maintenance,
            .serviceCall,
            .repair,
            .installation,
            .cleaning,
            .commercial,
            .startup,
            .drainAndRefill,
            .estimate,
            .extra,
            .custom
        ]
    }

    var title: String {
        switch self {
        case .route:
            return "Route"
        case .maintenance:
            return "Maintenance"
        case .serviceCall:
            return "Service Call"
        case .repair:
            return "Repair"
        case .installation:
            return "Installation"
        case .cleaning:
            return "Cleaning"
        case .commercial:
            return "Commercial"
        case .startup:
            return "Startup"
        case .drainAndRefill:
            return "Drain / Refill"
        case .estimate:
            return "Estimate"
        case .extra:
            return "Extra"
        case .custom:
            return "Custom"
        }
    }

    var defaultIconName: String {
        switch self {
        case .route:
            return "house"
        case .maintenance:
            return "figure.pool.swim"
        case .serviceCall:
            return "phone"
        case .repair:
            return "wrench.and.screwdriver"
        case .installation:
            return "hammer"
        case .cleaning:
            return "sparkles"
        case .commercial:
            return "building.2"
        case .startup:
            return "play.circle"
        case .drainAndRefill:
            return "drop"
        case .estimate:
            return "doc.text.magnifyingglass"
        case .extra:
            return "plus.circle"
        case .custom:
            return "tag"
        }
    }

    var suggestedDefaultRateType: RateType {
        switch self {
        case .route:
            return .flatPerStop
        case .maintenance:
            return .flatPerStop
        case .serviceCall:
            return .flatPerStop
        case .repair:
            return .flatPerTask
        case .installation:
            return .flatPerTask
        case .cleaning:
            return .flatPerTask
        case .commercial:
            return .flatPerStop
        case .startup:
            return .flatPerStop
        case .drainAndRefill:
            return .flatPerTask
        case .estimate:
            return .flatPerStop
        case .extra:
            return .manual
        case .custom:
            return .flatPerTask
        }
    }

    var suggestedStackBehavior: RateStackBehavior {
        switch self {
        case .route:
            return .stackable
        case .maintenance:
            return .stackable
        case .serviceCall:
            return .stackable
        case .repair:
            return .stackable
        case .installation:
            return .stackable
        case .cleaning:
            return .stackable
        case .commercial:
            return .stackable
        case .startup:
            return .stackable
        case .drainAndRefill:
            return .stackable
        case .estimate:
            return .stackable
        case .extra:
            return .stackable
        case .custom:
            return .stackable
        }
    }
}

extension CompanyWorkType {
    var displayIconName: String {
        if let iconName, !iconName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return iconName
        }

        return category.defaultIconName
    }

    var statusTitle: String {
        isActive ? "Active" : "Inactive"
    }
}
// MARK: - Work Type Source Helpers

extension WorkTypeSource {

    static var selectableCases: [WorkTypeSource] {
        [
            .serviceStopType,
            .jobTaskType,
            .recurringServiceStopTaskType,
            .bodyOfWaterType,
            .serviceLocationType,
            .manualTag
        ]
    }

    var title: String {
        switch self {
        case .serviceStopType:
            return "Fallback Stop Source"
        case .jobTaskType:
            return "Job Task Type"
        case .recurringServiceStopTaskType:
            return "Recurring Task Type"
        case .bodyOfWaterType:
            return "Body of Water Type"
        case .serviceLocationType:
            return "Service Location Type"
        case .manualTag:
            return "Manual Tag"
        }
    }

    var helpText: String {
        switch self {
        case .serviceStopType:
            return "Maps fallback service stop source IDs to pay types."
        case .jobTaskType:
            return "Maps ServiceStopTask.type values like Clean Filter, Repair, or Install."
        case .recurringServiceStopTaskType:
            return "Maps recurring-service task templates to pay types."
        case .bodyOfWaterType:
            return "Maps a body-of-water type to pay types."
        case .serviceLocationType:
            return "Maps a service location type to pay types."
        case .manualTag:
            return "Maps a custom manual tag to pay types."
        }
    }

    var allowsMultipleMappingsPerSource: Bool {
        switch self {
        case .serviceStopType:
            return true
        case .manualTag:
            return true
        case .jobTaskType,
             .recurringServiceStopTaskType,
             .bodyOfWaterType,
             .serviceLocationType:
            return false
        }
    }
}

// MARK: - Pay Basis Helpers

extension PayBasis {
    var title: String {
        switch self {
        case .serviceStop:
            return "Service Stop"
        case .serviceStopTask:
            return "Service Stop Task"
        case .technicianHourly:
            return "Technician Hourly"
        case .manualAdjustment:
            return "Manual Adjustment"
        }
    }

    var helpText: String {
        switch self {
        case .serviceStop:
            return "Used for pay generated from a completed service stop."
        case .serviceStopTask:
            return "Used for pay generated from a completed service stop task."
        case .technicianHourly:
            return "Used for hourly pay, usually from ActiveRoute or time logs."
        case .manualAdjustment:
            return "Used for manually created pay adjustments."
        }
    }
}

// MARK: - Rate Status Helpers

extension RateStatus {
    var title: String {
        switch self {
        case .draft:
            return "Draft"
        case .active:
            return "Active"
        case .scheduled:
            return "Scheduled"
        case .expired:
            return "Expired"
        case .archived:
            return "Archived"
        }
    }
}

// MARK: - Company User Payroll Helpers

extension CompanyUser {
    var isPayrollWorker: Bool {
        status == .active && workerType != .notAssigned
    }

    var payrollDisplayName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? userId
        : userName
    }
}

// MARK: - Work Type Pay Basis Suggestion

extension CompanyWorkType {
    var suggestedPayBasis: PayBasis {
        if defaultRateType == .hourly {
            return .technicianHourly
        }

        switch category {
        case .route, .maintenance, .serviceCall, .commercial, .startup, .estimate:
            return .serviceStop

        case .repair, .installation, .cleaning, .drainAndRefill, .extra, .custom:
            return .serviceStopTask
        }
    }
}

// MARK: - Company Service Stop Type Helpers

extension CompanyServiceStopType {
    var displayIconName: String {
        if let imageName,
           !imageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return imageName
        }

        return "mappin.and.ellipse"
    }

    var statusTitle: String {
        isActive ? "Active" : "Inactive"
    }
}

extension ServiceStop {
    mutating func applyCompanyServiceStopType(_ serviceStopType: CompanyServiceStopType) {
        self.typeId = serviceStopType.id
        self.type = serviceStopType.name
        self.typeImage = serviceStopType.imageName ?? ""
    }
}
// MARK: - Pay Statement Status Helpers

extension PayStatementStatus {
    var title: String {
        switch self {
        case .draft:
            return "Draft"
        case .approved:
            return "Approved"
        case .paid:
            return "Paid"
        case .exported:
            return "Exported"
        case .voided:
            return "Voided"
        case .readyForReview:
            return "Ready For Review"
        }
    }
}
