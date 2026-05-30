//
//  JobTemplateChildren.swift
//  DripDrop
//

import Foundation

struct JobTemplatePlannedServiceStop: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var name: String
    var description: String

    var serviceStopTypeId: String
    var serviceStopTypeName: String
    var serviceStopTypeImage: String
    var serviceStopTypeUseCaseRawValue: String

    var estimatedMinutes: Int
    var sortOrder: Int

    var taskTemplateIds: [String]

    var plannedLaborCostCents: Int?
    var plannedLaborNotes: String?

    init(
        id: String = "comp_job_template_plan_stop_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        name: String,
        description: String = "",
        serviceStopTypeId: String,
        serviceStopTypeName: String,
        serviceStopTypeImage: String,
        serviceStopTypeUseCaseRawValue: String,
        estimatedMinutes: Int,
        sortOrder: Int,
        taskTemplateIds: [String] = [],
        plannedLaborCostCents: Int? = nil,
        plannedLaborNotes: String? = nil
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.name = name
        self.description = description
        self.serviceStopTypeId = serviceStopTypeId
        self.serviceStopTypeName = serviceStopTypeName
        self.serviceStopTypeImage = serviceStopTypeImage
        self.serviceStopTypeUseCaseRawValue = serviceStopTypeUseCaseRawValue
        self.estimatedMinutes = estimatedMinutes
        self.sortOrder = sortOrder
        self.taskTemplateIds = taskTemplateIds
        self.plannedLaborCostCents = plannedLaborCostCents
        self.plannedLaborNotes = plannedLaborNotes
    }
}

struct JobTemplateTask: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var name: String
    var type: JobTaskType
    var description: String

    var contractedRate: Int
    var estimatedTime: Int
    var customerApproval: Bool

    var equipmentId: String?
    var serviceLocationId: String?
    var bodyOfWaterId: String?
    var dataBaseItemId: String?

    var sortOrder: Int

    init(
        id: String = "comp_job_template_task_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        name: String,
        type: JobTaskType,
        description: String = "",
        contractedRate: Int,
        estimatedTime: Int,
        customerApproval: Bool = false,
        equipmentId: String? = nil,
        serviceLocationId: String? = nil,
        bodyOfWaterId: String? = nil,
        dataBaseItemId: String? = nil,
        sortOrder: Int
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.name = name
        self.type = type
        self.description = description
        self.contractedRate = contractedRate
        self.estimatedTime = estimatedTime
        self.customerApproval = customerApproval
        self.equipmentId = equipmentId
        self.serviceLocationId = serviceLocationId
        self.bodyOfWaterId = bodyOfWaterId
        self.dataBaseItemId = dataBaseItemId
        self.sortOrder = sortOrder
    }
}

struct JobTemplateShoppingItem: Identifiable, Codable, Hashable {
    var id: String
    var companyId: String
    var templateId: String

    var subCategory: ShoppingListSubCategory

    var name: String
    var description: String
    var quantity: String

    var dbItemId: String?
    var genericItemId: String?

    var plannedUnitCostCents: Int?
    var plannedUnitPriceCents: Int?
    var plannedTotalCostCents: Int?
    var plannedTotalPriceCents: Int?

    var billable: Bool
    var sortOrder: Int

    init(
        id: String = "comp_job_template_shop_item_" + UUID().uuidString,
        companyId: String,
        templateId: String,
        subCategory: ShoppingListSubCategory,
        name: String,
        description: String = "",
        quantity: String,
        dbItemId: String? = nil,
        genericItemId: String? = nil,
        plannedUnitCostCents: Int? = nil,
        plannedUnitPriceCents: Int? = nil,
        plannedTotalCostCents: Int? = nil,
        plannedTotalPriceCents: Int? = nil,
        billable: Bool,
        sortOrder: Int
    ) {
        self.id = id
        self.companyId = companyId
        self.templateId = templateId
        self.subCategory = subCategory
        self.name = name
        self.description = description
        self.quantity = quantity
        self.dbItemId = dbItemId
        self.genericItemId = genericItemId
        self.plannedUnitCostCents = plannedUnitCostCents
        self.plannedUnitPriceCents = plannedUnitPriceCents
        self.plannedTotalCostCents = plannedTotalCostCents
        self.plannedTotalPriceCents = plannedTotalPriceCents
        self.billable = billable
        self.sortOrder = sortOrder
    }
}