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
        billingLaborPriceCents: Int? = nil
    ) {
        self.payTypeId = payTypeId
        self.payTypeName = payTypeName
        self.payrollMode = payrollMode
        self.manualPayOverrideCents = manualPayOverrideCents
        self.manualPayOverrideNotes = manualPayOverrideNotes
        self.payrollStackBehavior = payrollStackBehavior
        self.payQuantity = payQuantity
        self.billingLaborPriceCents = billingLaborPriceCents
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
