//
//  JobPlannedServiceStop.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


import Foundation

struct JobPlannedServiceStop: Identifiable, Codable, Hashable {
    var id: String

    var companyId: String
    var jobId: String

    var name: String
    var description: String

    var serviceStopTypeId: String
    var serviceStopTypeName: String
    var serviceStopTypeImage: String

    var serviceStopTypeUseCaseRawValue: String

    var estimatedMinutes: Int
    var sortOrder: Int

    var taskIds: [String]
    
    var plannedLaborCostCents: Int?
    var plannedLaborNotes: String?

    var createdAt: Date
    var createdByUserId: String

    var payTypeId: String? = nil
    var payTypeName: String? = nil
    var payrollMode: String? = nil
    var manualPayOverrideCents: Int? = nil
    var manualPayOverrideNotes: String? = nil
    var payrollStackBehavior: String? = nil
    var payQuantity: Double? = nil
    var billingLaborPriceCents: Int? = nil
    var sourceTemplatePlannedStopId: String? = nil

    var effectivePayrollMode: String {
        payrollMode ?? (manualPayOverrideCents == nil ? "automatic" : "custom")
    }

    var scheduledPayDescription: String {
        switch effectivePayrollMode {
        case "custom":
            guard let manualPayOverrideCents else { return "Custom pay amount required" }
            return (Double(manualPayOverrideCents) / 100).formatted(.currency(code: "USD")) + " fixed"
        case "included": return "Included in another payment"
        case "unpaid": return "No separate service stop pay"
        default: return "Assigned technician’s rate"
        }
    }

    func applyPay(to stop: inout ServiceStop) throws {
        let mode = effectivePayrollMode
        if mode == "custom" && (manualPayOverrideCents ?? -1) < 0 {
            throw NSError(domain: "JobVisitPayroll", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Set the planned visit’s custom pay amount before scheduling."
            ])
        }
        stop.plannedServiceStopId = id
        stop.payWorkTypeId = payTypeId.flatMap { $0.isEmpty ? nil : $0 }
        stop.payWorkTypeName = payTypeName.flatMap { $0.isEmpty ? nil : $0 }
        stop.payrollMode = mode
        stop.manualPayOverrideCents = mode == "custom" ? manualPayOverrideCents : nil
        stop.manualPayOverrideNotes = mode == "custom" ? manualPayOverrideNotes : nil
        stop.payrollStackBehavior = payrollStackBehavior
        stop.payQuantity = payQuantity
    }

    init(
        id: String = "comp_job_plan_stop_" + UUID().uuidString,
        companyId: String,
        jobId: String,
        name: String,
        description: String = "",
        serviceStopTypeId: String,
        serviceStopTypeName: String,
        serviceStopTypeImage: String,
        serviceStopTypeUseCaseRawValue: String,
        estimatedMinutes: Int,
        sortOrder: Int,
        taskIds: [String] = [],
        plannedLaborCostCents: Int? = nil,
        plannedLaborNotes: String? = nil,
        createdAt: Date = Date(),
        createdByUserId: String,
        payTypeId: String? = nil,
        payTypeName: String? = nil,
        payrollMode: String? = nil,
        manualPayOverrideCents: Int? = nil,
        manualPayOverrideNotes: String? = nil,
        payrollStackBehavior: String? = nil,
        payQuantity: Double? = nil,
        billingLaborPriceCents: Int? = nil,
        sourceTemplatePlannedStopId: String? = nil
    ) {
        self.payTypeId = payTypeId
        self.payTypeName = payTypeName
        self.payrollMode = payrollMode
        self.manualPayOverrideCents = manualPayOverrideCents
        self.manualPayOverrideNotes = manualPayOverrideNotes
        self.payrollStackBehavior = payrollStackBehavior
        self.payQuantity = payQuantity
        self.billingLaborPriceCents = billingLaborPriceCents
        self.sourceTemplatePlannedStopId = sourceTemplatePlannedStopId
        self.id = id
        self.companyId = companyId
        self.jobId = jobId
        self.name = name
        self.description = description
        self.serviceStopTypeId = serviceStopTypeId
        self.serviceStopTypeName = serviceStopTypeName
        self.serviceStopTypeImage = serviceStopTypeImage
        self.serviceStopTypeUseCaseRawValue = serviceStopTypeUseCaseRawValue
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.taskIds = taskIds
        self.plannedLaborCostCents = plannedLaborCostCents
        self.plannedLaborNotes = plannedLaborNotes
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
    }
}
