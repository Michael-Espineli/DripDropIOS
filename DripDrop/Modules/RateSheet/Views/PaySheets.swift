//
//  PaySheets.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/18/26.
//

import Foundation
struct CompanyWorkType: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var name: String
    var category: WorkCategory
    var iconName: String?
    var isActive: Bool

    var defaultRateType: RateType
    var defaultStackBehavior: RateStackBehavior

    var sortOrder: Int
}
enum RateType: String, Codable, Hashable, CaseIterable {
    case flatPerStop
    case flatPerTask
    case hourly
    case perBodyOfWater
    case perServiceLocation
    case percentage
    case manual
}

extension RateType {
    var title: String {
        switch self {
        case .flatPerStop: return "Flat Per Stop"
        case .flatPerTask: return "Flat Per Task"
        case .hourly: return "Hourly"
        case .perBodyOfWater: return "Per Body of Water"
        case .perServiceLocation: return "Per Service Location"
        case .percentage: return "Percentage"
        case .manual: return "Manual"
        }
    }
}

enum WorkCategory: String, Codable, Hashable {
    case route
    case serviceCall
    case repair
    case installation
    case cleaning
    case commercial
    case startup
    case drainAndRefill
    case extra
    case custom
}

struct TechnicianRate: Identifiable, Codable, Hashable {
    var id: String
    var ratePlanId: String
    var companyId: String

    // This should be CompanyUser.userId.
    var technicianId: String

    var payBasis: PayBasis
    var workTypeId: String?

    var amountCents: Int
    var rateType: RateType

    var effectiveStartDate: Date
    var effectiveEndDate: Date?

    var status: RateStatus

    var createdAt: Date
    var createdByUserId: String

    var reason: String?
    var previousRateId: String?
}

/*
 Example Example route rate:
 
 TechnicianRate(
     id: "comp_tech_rate_" + UUID().uuidString,
     ratePlanId: "comp_rate_plan_2026",
     companyId: companyId,
     technicianId: techId,
     payBasis: .serviceStop,
     workTypeId: "comp_work_type_routes",
     amountCents: 1600,
     rateType: .flatPerStop,
     effectiveStartDate: Date(),
     effectiveEndDate: nil,
     status: .active,
     createdAt: Date(),
     createdByUserId: currentUserId,
     reason: "Starting route rate",
     previousRateId: nil
 )
 Example hourly rate:
 TechnicianRate(
     id: "comp_tech_rate_" + UUID().uuidString,
     ratePlanId: "comp_rate_plan_2026",
     companyId: companyId,
     technicianId: techId,
     payBasis: .technicianHourly,
     workTypeId: nil,
     amountCents: 2500,
     rateType: .hourly,
     effectiveStartDate: Date(),
     effectiveEndDate: nil,
     status: .active,
     createdAt: Date(),
     createdByUserId: currentUserId,
     reason: "$25/hour starting rate",
     previousRateId: nil
 )
 */
struct CompanyServiceStopType: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var name: String
    var imageName: String?
    var isActive: Bool
    var sortOrder: Int

    // Example:
    // Weekly Route -> [Routes]
    // Route + Spa -> [Routes, Spa Add-On]
    // Commercial Multi BOW -> [Commercial Base, Commercial Additional BOW]
    var defaultWorkTypeIds: [String]

    var createdAt: Date
    var createdByUserId: String
}

/*
 Examples
 
 CompanyServiceStopType(
     id: "comp_ss_type_" + UUID().uuidString,
     companyId: companyId,
     name: "Weekly Route",
     imageName: "figure.pool.swim",
     isActive: true,
     sortOrder: 1,
     defaultWorkTypeIds: ["comp_work_type_routes"],
     createdAt: Date(),
     createdByUserId: currentUserId
 )
 
 */

/*
 
 payBasis = .serviceStop
 workTypeId = routeWorkTypeId
 rateType = .flatPerStop
 amountCents = 1600
 payBasis = .serviceStopTask
 workTypeId = filterCleaningWorkTypeId
 rateType = .flatPerTask
 amountCents = 8000
 payBasis = .technicianHourly
 workTypeId = nil
 rateType = .hourly
 amountCents = 2500
 
 */
/*
 The important change is:

 var workTypeId: String?

 For production pay:

 workTypeId = routeWorkTypeId
 rateType = .flatPerStop
 amountCents = 1600

 For hourly pay:

 workTypeId = nil
 rateType = .hourly
 amountCents = 2500

 That means $25.00/hour.

 You could also allow different hourly rates for different work types:

 workTypeId = commercialWorkTypeId
 rateType = .hourly
 amountCents = 3000

 That means $30/hour for commercial work.
 
 
 */

struct CompanyPaySettings: Codable, Hashable {
    var companyId: String

    var payMode: CompanyPayMode

    var routePaySource: RoutePaySource
    var taskPaySource: TaskPaySource
    var hourlyPaySource: HourlyPaySource

    var allowMultipleWorkTypesPerStop: Bool
    var defaultStackBehavior: RateStackBehavior

    var allowTechnicianRateOverrides: Bool
    var allowManualPayAdjustments: Bool

    var payCommercialAsSeparateWorkType: Bool
    var paySpaAsSeparateWorkType: Bool
    var payPerBodyOfWater: Bool
    var commercialMultiBodyPayStyle: CommercialMultiBodyPayStyle

    var lockPayAfterApproval: Bool
    var recalculateUnapprovedPayWhenRatesChange: Bool
}


/*
 For hourly companies, I would use:

 hourlyPaySource = .activeRouteDuration
 routePaySource = .none
 taskPaySource = .none

 That means:

 Do not generate hourly pay from each service stop.
 Generate one hourly line from the whole route.
 */
enum RateStackBehavior: String, Codable, Hashable {
    case stackable       // route + filter + salt cell
    case exclusive       // only one matching rate wins
    case replacesBase    // route plus spa replaces normal route
    case modifier        // commercial adds or changes the base
}
struct WorkTypeMapping: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var sourceType: WorkTypeSource
    var sourceId: String

    var workTypeId: String
}
enum WorkTypeSource: String, Codable, Hashable {
    case serviceStopType
    case jobTaskType
    case recurringServiceStopTaskType
    case bodyOfWaterType
    case serviceLocationType
    case manualTag
}
struct PayableWorkItem: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var technicianId: String
    var technicianName: String

    var serviceStopId: String
    var serviceStopTaskId: String?

    var jobId: String?
    var recurringServiceStopId: String?
    var customerId: String
    var serviceLocationId: String
    var bodyOfWaterId: String?

    var workTypeId: String
    var workTypeName: String

    var completedDate: Date
    var quantity: Double

    var source: PayableWorkSource
}
enum PayableWorkSource: String, Codable, Hashable {
    case serviceStop
    case serviceStopTask
    case manualAdjustment
}
struct TechnicianRateHistorySummary: Codable, Hashable {
    var technicianId: String
    var workTypeId: String

    var currentRateCents: Int
    var previousRateCents: Int?
    var lastIncreaseDate: Date?
    var daysSinceLastIncrease: Int?
    var totalIncreasesLast12Months: Int
}
struct RateSheet:Codable,Identifiable,Hashable{
    var id :String
    var templateName : String
    var templateId : String
    var rate : Double
    var dateImplemented : Date
    var status : RateSheetStatus
    var laborType:RateSheetLaborType
}
struct CompanyRatePlan: Codable, Identifiable, Hashable {
    var id: String
    var companyId: String

    var name: String
    var status: RatePlanStatus

    var effectiveStartDate: Date
    var effectiveEndDate: Date?

    var createdAt: Date
    var createdByUserId: String
}

struct TechnicianPayStatement: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    var technicianId: String
    var technicianName: String
    var workerType: WorkerTypeEnum

    var startDate: Date
    var endDate: Date

    var lineItemIds: [String]
    var subtotalCents: Int
    var adjustmentCents: Int
    var totalCents: Int

    var status: PayStatementStatus

    var createdAt: Date
    var createdByUserId: String

    var approvedAt: Date?
    var approvedByUserId: String?

    var paidAt: Date?
    var paidByUserId: String?

    var exportedAt: Date?
    var exportProvider: PayrollExportProvider?
    var externalReferenceId: String?

    var notes: String?
}

func makePayLineId(
    serviceStopId: String?,
    serviceStopTaskId: String?,
    activeRouteId: String?,
    technicianId: String,
    workTypeId: String?
) -> String {
    [
        "comp_pay_line",
        serviceStopId ?? "no_stop",
        serviceStopTaskId ?? "no_task",
        activeRouteId ?? "no_route",
        technicianId,
        workTypeId ?? "no_work_type"
    ].joined(separator: "_")
}

struct TechnicianPayLineItem: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String

    // This should be CompanyUser.userId.
    var technicianId: String
    var technicianName: String
    var workerType: WorkerTypeEnum

    var source: PayLineItemSource

    var serviceStopId: String?
    var serviceStopTaskId: String?
    var activeRouteId: String?
    var activeRouteLogId: String?

    var workTypeId: String?
    var workTypeName: String?

    var rateId: String?
    var rateAmountCents: Int

    var rateType: RateType
    var quantity: Double
    var quantityUnit: PayQuantityUnit

    var totalAmountCents: Int

    var completedDate: Date
    var calculatedAt: Date

    var calculationStatus: PayCalculationStatus

    var approvedAt: Date?
    var approvedByUserId: String?

    var paidAt: Date?
    var paidByUserId: String?

    var payStatementId: String?
    var exportBatchId: String?

    var notes: String?
    var adminReviewNotes: String?
}

enum PayQuantityUnit: String, Codable, Hashable, CaseIterable {
    case each
    case minutes
    case hours
    case bodyOfWater
    case serviceLocation
    case percent
}

enum RateStatus: String, Codable, Hashable, CaseIterable {
    case draft      // Created but not used yet
    case active     // Currently valid and used for calculations
    case scheduled  // Starts in the future
    case expired    // Replaced by a newer rate
    case archived   // Hidden/retired, mostly for cleanup
}
enum RatePlanStatus: String, Codable, Hashable, CaseIterable {
    case draft      // Company is still building the pay plan
    case active     // This is the current pay plan
    case scheduled  // Starts on a future date
    case inactive   // No longer used, but kept for history
    case archived   // Hidden from normal views
}
enum RoutePaySource: String, Codable, Hashable, CaseIterable {
    case serviceStop
    // Pay one route rate when the service stop is completed.

    case completedTasks
    // Do not pay a route rate. Only pay completed tasks.

    case serviceStopAndCompletedTasks
    // Pay the route rate plus any completed payable tasks.

    case hourlyServiceStopDuration
    // Pay using the service stop's actual duration.

    case hourlyTaskActualTime
    // Pay using completed task actual times.

    case none
    // No automatic route pay.
}

enum TaskPaySource: String, Codable, Hashable, CaseIterable {
    case technicianRate
    // Use the technician's active rate for the task's mapped work type.

    case taskContractedRate
    // Use ServiceStopTask.contractedRate.

    case technicianRateThenTaskContractedRate
    // Prefer technician-specific rate. Fall back to task contracted rate.

    case taskContractedRateThenTechnicianRate
    // Prefer task contracted rate. Fall back to technician-specific rate.

    case hourlyActualTime
    // Use actualTime and the technician's hourly rate.

    case hourlyEstimatedTime
    // Use estimatedTime and the technician's hourly rate.

    case none
    // Completed tasks do not create automatic pay.
}

enum PayCalculationStatus: String, Codable, Hashable, CaseIterable {
    case pending
    // Work is completed but pay has not been calculated yet.

    case calculated
    // Pay was calculated successfully.

    case needsReview
    // Missing rate, conflict, or unusual calculation.

    case approved
    // Manager approved this pay item.

    case paid
    // Included in payroll/export/check.

    case voided
    // Removed from payroll, but kept for audit history.

    case adjusted
    // Manually changed after initial calculation.
}

enum CompanyPayMode: String, Codable, Hashable, CaseIterable {
    case productionOnly
    // Pay based on completed work items: stops, tasks, work types.

    case hourlyOnly
    // Pay based on time worked.

    case hybrid
    // Some work is production pay, some work is hourly.
}

/*
 
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
 
 
 */
enum PayBasis: String, Codable, Hashable, CaseIterable {
    case serviceStop
    case serviceStopTask
    case technicianHourly
    case manualAdjustment
}

//MARK: - Pay Calculation Helper
/*
 func calculateTotalAmountCents(
     rateAmountCents: Int,
     rateType: RateType,
     quantity: Double,
     quantityUnit: PayQuantityUnit
 ) -> Int {
     switch rateType {
     case .flatPerStop, .flatPerTask, .manual:
         return Int(Double(rateAmountCents) * quantity)

     case .hourly:
         switch quantityUnit {
         case .minutes:
             return Int((Double(rateAmountCents) / 60.0) * quantity)
         case .hours:
             return Int(Double(rateAmountCents) * quantity)
         default:
             return 0
         }

     case .perBodyOfWater, .perServiceLocation:
         return Int(Double(rateAmountCents) * quantity)

     case .percentage:
         return 0
     }
 }
 */


/*
 
 Rate sheet = company pay plan
 Rows = company work types
 Columns = technicians
 Cells = technician-specific rate records
 History = versioned TechnicianRate records
 Calculation = generated from completed work
 
 */

enum HourlyPaySource: String, Codable, Hashable, CaseIterable {
    case activeRouteDuration
    case activeRouteLogs
    case serviceStopDuration
    case taskActualTime
    case none
}

enum CommercialMultiBodyPayStyle: String, Codable, Hashable, CaseIterable {
    case singleCommercialRate
    case sameRatePerBodyOfWater
    case basePlusAdditionalBodyRate
}

enum PayLineItemSource: String, Codable, Hashable, CaseIterable {
    case serviceStop
    case serviceStopTask
    case activeRoute
    case activeRouteLog
    case manualAdjustment
}

enum PayStatementStatus: String, Codable, Hashable, CaseIterable {
    case draft
    case readyForReview
    case approved
    case paid
    case exported
    case voided
}
enum PayrollExportProvider: String, Codable, Hashable, CaseIterable {
    case csv
    case quickBooks
    case gusto
    case adp
    case manual
}
