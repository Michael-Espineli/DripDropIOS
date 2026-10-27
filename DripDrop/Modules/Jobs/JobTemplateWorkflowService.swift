//
//  JobTemplateWorkflowService.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import Foundation

final class JobTemplateWorkflowService {

    private let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Save Job As Template

    func saveJobAsTemplate(
        companyId: String,
        sourceJob: Job,
        plannedServiceStops: [JobPlannedServiceStop],
        jobTasks: [JobTask],
        shoppingItems: [ShoppingListItem],
        templateName: String,
        createdByUserId: String
    ) async throws -> JobTemplate {
        var template = JobTemplate(
            companyId: companyId,
            name: templateName,
            description: sourceJob.description,
            jobType: sourceJob.type,
            jobTypeImage: nil,
            defaultRateCents: sourceJob.rate,
            defaultLaborCostCents: sourceJob.laborCost,
            color: nil,
            isActive: true,
            locked: false,
            createdByUserId: createdByUserId
        )
        template.setDefaultIssuePriority(
            sourceJob.normalizedIssuePriority ?? .defaultLevel
        )

        let taskIdMap = Dictionary(
            uniqueKeysWithValues: jobTasks.map { originalTask in
                (originalTask.id, "comp_job_template_task_" + UUID().uuidString)
            }
        )

        let templateTasks = jobTasks.enumerated().map { index, task in
            JobTemplateTask(
                id: taskIdMap[task.id] ?? "comp_job_template_task_" + UUID().uuidString,
                companyId: companyId,
                templateId: template.id,
                name: task.name,
                type: task.type,
                description: "",
                contractedRate: task.contractedRate,
                estimatedTime: task.estimatedTime,
                customerApproval: task.customerApproval,
                equipmentId: nil,
                serviceLocationId: nil,
                bodyOfWaterId: nil,
                dataBaseItemId: task.dataBaseItemId.isEmpty ? nil : task.dataBaseItemId,
                sortOrder: index,
                billingLaborPriceCents: task.billingLaborPriceCents,
                taxable: task.taxable,
                payTypeId: task.payTypeId,
                payTypeName: task.payTypeName,
                payrollMode: task.payrollMode,
                manualPayOverrideCents: task.manualPayOverrideCents,
                manualPayOverrideNotes: task.manualPayOverrideNotes,
                payrollStackBehavior: task.payrollStackBehavior,
                payQuantity: task.payQuantity
            )
        }

        let templatePlannedStops = plannedServiceStops.map { plannedStop in
            JobTemplatePlannedServiceStop(
                companyId: companyId,
                templateId: template.id,
                name: plannedStop.name,
                description: plannedStop.description,
                serviceStopTypeId: plannedStop.serviceStopTypeId,
                serviceStopTypeName: plannedStop.serviceStopTypeName,
                serviceStopTypeImage: plannedStop.serviceStopTypeImage,
                serviceStopTypeUseCaseRawValue: plannedStop.serviceStopTypeUseCaseRawValue,
                estimatedMinutes: plannedStop.estimatedMinutes,
                sortOrder: plannedStop.sortOrder,
                taskTemplateIds: plannedStop.taskIds.compactMap { taskIdMap[$0] },
                plannedLaborCostCents: plannedStop.plannedLaborCostCents,
                plannedLaborNotes: plannedStop.plannedLaborNotes,
                payTypeId: plannedStop.payTypeId,
                payTypeName: plannedStop.payTypeName,
                payrollMode: plannedStop.payrollMode,
                manualPayOverrideCents: plannedStop.manualPayOverrideCents,
                manualPayOverrideNotes: plannedStop.manualPayOverrideNotes,
                payrollStackBehavior: plannedStop.payrollStackBehavior,
                payQuantity: plannedStop.payQuantity,
                billingLaborPriceCents: plannedStop.billingLaborPriceCents
            )
        }

        let templateShoppingItems = shoppingItems.enumerated().map { index, item in
            JobTemplateShoppingItem(
                companyId: companyId,
                templateId: template.id,
                subCategory: item.subCategory,
                name: item.name,
                description: item.description,
                quantity: item.quantity ?? "1",
                dbItemId: item.dbItemId,
                genericItemId: item.genericItemId.isEmpty ? nil : item.genericItemId,
                plannedUnitCostCents: item.plannedUnitCostCents,
                plannedUnitPriceCents: item.plannedUnitPriceCents,
                plannedTotalCostCents: item.plannedTotalCostCents,
                plannedTotalPriceCents: item.plannedTotalPriceCents,
                billable: item.plannedUnitPriceCents != nil || item.plannedTotalPriceCents != nil,
                sortOrder: index,
                linkedTaskId: item.linkedTaskId.flatMap { taskIdMap[$0] },
                taxable: item.taxable
            )
        }
        let stopIdMap = Dictionary(uniqueKeysWithValues: zip(plannedServiceStops.map(\.id), templatePlannedStops.map(\.id)))
        let sourceLines = try await dataService.fetchJobLaborLineItems(companyId: companyId, jobId: sourceJob.id)
        if !sourceLines.isEmpty {
            let priced = NewJobScope(tasks: jobTasks, plannedStops: plannedServiceStops, laborLineItems: sourceLines).completeLaborLines
            let materialPrice = shoppingItems.reduce(0) { $0 + ($1.plannedTotalPriceCents ?? Int((Double($1.quantity ?? "1") ?? 1) * Double($1.plannedUnitPriceCents ?? 0))) }
            template.defaultRateCents = priced.reduce(0) { $0 + $1.priceCents } + materialPrice
            template.defaultLaborCostCents = priced.reduce(0) { $0 + ($1.internalCostCents ?? 0) }
        }
        let templateLines = sourceLines.map { $0.remapped(companyId: companyId, taskIds: taskIdMap, stopIds: stopIdMap, templateId: template.id) }
        try await dataService.saveJobTemplateBundle(template: template, tasks: templateTasks, stops: templatePlannedStops, items: templateShoppingItems, laborLines: templateLines)

        return template
    }

    // MARK: - Duplicate Job

    func duplicateJob(
        companyId: String,
        sourceJob: Job,
        plannedServiceStops: [JobPlannedServiceStop],
        jobTasks: [JobTask],
        shoppingItems: [ShoppingListItem],
        newInternalId: String,
        creationId: String = "comp_wo_" + UUID().uuidString,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        admin: CompanyUser,
        createdByUserId: String
    ) async throws -> Job {
        let newJobId = creationId

        var newJob = Job(
            id: newJobId,
            internalId: "",
            type: sourceJob.type,
            dateCreated: Date(),
            description: sourceJob.description,
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: customerId,
            customerName: customerName,
            serviceLocationId: serviceLocationId,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: admin.userId,
            adminName: admin.userName,
            purchasedItemsIds: nil,
            tasks: nil,
            rate: sourceJob.rate,
            laborCost: sourceJob.laborCost,
            otherCompany: false,
            receivedLaborContractId: nil,
            receiverId: nil,
            senderId: nil,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: nil,
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
        if let issuePriority = sourceJob.normalizedIssuePriority {
            newJob.setIssuePriority(issuePriority)
        }

        let copiedTasks = copyJobTasks(
            companyId: companyId,
            jobId: newJobId,
            sourceTasks: jobTasks,
            customerId: customerId,
            serviceLocationId: serviceLocationId
        )

        let taskIdMap = Dictionary(
            uniqueKeysWithValues: zip(jobTasks.map { $0.id }, copiedTasks.map { $0.id })
        )

        let copiedPlannedStops = plannedServiceStops.map { plannedStop in
            JobPlannedServiceStop(
                companyId: companyId,
                jobId: newJobId,
                name: plannedStop.name,
                description: plannedStop.description,
                serviceStopTypeId: plannedStop.serviceStopTypeId,
                serviceStopTypeName: plannedStop.serviceStopTypeName,
                serviceStopTypeImage: plannedStop.serviceStopTypeImage,
                serviceStopTypeUseCaseRawValue: plannedStop.serviceStopTypeUseCaseRawValue,
                estimatedMinutes: plannedStop.estimatedMinutes,
                sortOrder: plannedStop.sortOrder,
                taskIds: plannedStop.taskIds.compactMap { taskIdMap[$0] },
                plannedLaborCostCents: plannedStop.plannedLaborCostCents,
                plannedLaborNotes: plannedStop.plannedLaborNotes,
                createdByUserId: createdByUserId,
                payTypeId: plannedStop.payTypeId,
                payTypeName: plannedStop.payTypeName,
                payrollMode: plannedStop.payrollMode,
                manualPayOverrideCents: plannedStop.manualPayOverrideCents,
                manualPayOverrideNotes: plannedStop.manualPayOverrideNotes,
                payrollStackBehavior: plannedStop.payrollStackBehavior,
                payQuantity: plannedStop.payQuantity,
                billingLaborPriceCents: plannedStop.billingLaborPriceCents
            )
        }

        let copiedShoppingItems = copyShoppingItems(
            sourceItems: shoppingItems,
            jobId: newJobId,
            customerId: customerId,
            customerName: customerName,
            serviceLocationId: serviceLocationId,
            purchaserId: createdByUserId,
            purchaserName: admin.userName
        )

        let sourceLines = try await dataService.fetchJobLaborLineItems(companyId: companyId, jobId: sourceJob.id)
        let stopIdMap = Dictionary(uniqueKeysWithValues: zip(plannedServiceStops.map(\.id), copiedPlannedStops.map(\.id)))
        let copiedLines = sourceLines.map { $0.remapped(companyId: companyId, taskIds: taskIdMap, stopIds: stopIdMap, jobId: newJobId) }
        let linkedMaterials = zip(shoppingItems, copiedShoppingItems).map { source, copy -> ShoppingListItem in
            var item = copy
            item.linkedTaskId = source.linkedTaskId.flatMap { taskIdMap[$0] }
            item.taxable = source.taxable
            return item
        }
        newJob.referenceLabel = newInternalId.isEmpty ? nil : newInternalId
        return try await dataService.commitNewJob(companyId: companyId, job: newJob, scope: NewJobScope(tasks: copiedTasks, plannedStops: copiedPlannedStops, shoppingItems: linkedMaterials, laborLineItems: copiedLines))
    }

    // MARK: - Create Job From Template

    func createJobFromTemplate(
        companyId: String,
        templateId: String,
        newInternalId: String,
        creationId: String = "comp_wo_" + UUID().uuidString,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        admin: CompanyUser,
        createdByUserId: String
    ) async throws -> Job {
        let template = try await dataService.fetchJobTemplate(
            companyId: companyId,
            templateId: templateId
        )

        async let templateTasksTask = dataService.fetchJobTemplateTasks(
            companyId: companyId,
            templateId: templateId
        )

        async let templatePlannedStopsTask = dataService.fetchJobTemplatePlannedServiceStops(
            companyId: companyId,
            templateId: templateId
        )

        async let templateShoppingItemsTask = dataService.fetchJobTemplateShoppingItems(
            companyId: companyId,
            templateId: templateId
        )

        let templateTasks = try await templateTasksTask
        let templatePlannedStops = try await templatePlannedStopsTask
        let templateShoppingItems = try await templateShoppingItemsTask
        let templateLines = try await dataService.fetchJobTemplateLaborLineItems(companyId: companyId, templateId: templateId)

        let newJobId = creationId

        var newJob = Job(
            id: newJobId,
            internalId: "",
            type: template.jobType.isEmpty ? template.name : template.jobType,
            dateCreated: Date(),
            description: template.description,
            operationStatus: .estimatePending,
            billingStatus: .draft,
            customerId: customerId,
            customerName: customerName,
            serviceLocationId: serviceLocationId,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: admin.userId,
            adminName: admin.userName,
            purchasedItemsIds: nil,
            tasks: nil,
            rate: template.defaultRateCents,
            laborCost: template.defaultLaborCostCents,
            otherCompany: false,
            receivedLaborContractId: nil,
            receiverId: nil,
            senderId: nil,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: nil,
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
        newJob.setIssuePriority(template.normalizedDefaultIssuePriority)

        let copiedTasks = templateTasks.map { templateTask in
            JobTask(
                id: "comp_job_task_" + UUID().uuidString,
                name: templateTask.name,
                type: templateTask.type,
                contractedRate: templateTask.contractedRate,
                estimatedTime: templateTask.estimatedTime,
                payTypeId: templateTask.payTypeId,
                payTypeName: templateTask.payTypeName,
                status: .draft,
                customerApproval: templateTask.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: "",
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: "",
                dataBaseItemId: templateTask.dataBaseItemId ?? "",
                billingLaborPriceCents: templateTask.billingLaborPriceCents,
                taxable: templateTask.taxable,
                payrollMode: templateTask.payrollMode,
                manualPayOverrideCents: templateTask.manualPayOverrideCents,
                manualPayOverrideNotes: templateTask.manualPayOverrideNotes,
                payrollStackBehavior: templateTask.payrollStackBehavior,
                payQuantity: templateTask.payQuantity
            )
        }

        let taskIdMap = Dictionary(
            uniqueKeysWithValues: zip(templateTasks.map { $0.id }, copiedTasks.map { $0.id })
        )

        let copiedPlannedStops = templatePlannedStops.map { templateStop in
            JobPlannedServiceStop(
                companyId: companyId,
                jobId: newJobId,
                name: templateStop.name,
                description: templateStop.description,
                serviceStopTypeId: templateStop.serviceStopTypeId,
                serviceStopTypeName: templateStop.serviceStopTypeName,
                serviceStopTypeImage: templateStop.serviceStopTypeImage,
                serviceStopTypeUseCaseRawValue: templateStop.serviceStopTypeUseCaseRawValue,
                estimatedMinutes: templateStop.estimatedMinutes,
                sortOrder: templateStop.sortOrder,
                taskIds: templateStop.taskTemplateIds.compactMap { taskIdMap[$0] },
                plannedLaborCostCents: templateStop.plannedLaborCostCents,
                plannedLaborNotes: templateStop.plannedLaborNotes,
                createdByUserId: createdByUserId,
                payTypeId: templateStop.payTypeId,
                payTypeName: templateStop.payTypeName,
                payrollMode: templateStop.payrollMode,
                manualPayOverrideCents: templateStop.manualPayOverrideCents,
                manualPayOverrideNotes: templateStop.manualPayOverrideNotes,
                payrollStackBehavior: templateStop.payrollStackBehavior,
                payQuantity: templateStop.payQuantity,
                billingLaborPriceCents: templateStop.billingLaborPriceCents
            )
        }

        let copiedShoppingItems = templateShoppingItems.map { templateItem in
            ShoppingListItem(
                id: UUID().uuidString,
                category: .job,
                subCategory: templateItem.subCategory,
                status: .needToPurchase,
                purchaserId: createdByUserId,
                purchaserName: admin.userName,
                genericItemId: templateItem.genericItemId ?? "",
                name: templateItem.name,
                description: templateItem.description,
                datePurchased: nil,
                quantity: templateItem.quantity,
                jobId: newJobId,
                customerId: customerId,
                customerName: customerName,
                userId: nil,
                userName: nil,
                serviceLocationId: serviceLocationId,
                prepKeys: ShoppingPrepKeyBuilder.keysForJobMaterial(
                    jobId: newJobId,
                    customerId: customerId,
                    serviceLocationId: serviceLocationId
                ),
                needsAction: false,
                shoppingListActive: false,
                actionDate: nil,
                dbItemId: templateItem.dbItemId,
                purchasedItem: nil,
                invoiced: false,
                plannedUnitCostCents: templateItem.plannedUnitCostCents,
                plannedUnitPriceCents: templateItem.plannedUnitPriceCents,
                plannedTotalCostCents: templateItem.plannedTotalCostCents,
                plannedTotalPriceCents: templateItem.plannedTotalPriceCents
            )
        }

        let stopIdMap = Dictionary(uniqueKeysWithValues: zip(templatePlannedStops.map(\.id), copiedPlannedStops.map(\.id)))
        let copiedLines = templateLines.map { $0.remapped(companyId: companyId, taskIds: taskIdMap, stopIds: stopIdMap, jobId: newJobId) }
        let linkedMaterials = zip(templateShoppingItems, copiedShoppingItems).map { source, copy -> ShoppingListItem in
            var item = copy
            item.linkedTaskId = source.linkedTaskId.flatMap { taskIdMap[$0] }
            item.taxable = source.taxable
            return item
        }
        newJob.sourceTemplateId = template.id
        newJob.sourceTemplateName = template.name
        newJob.referenceLabel = newInternalId.isEmpty ? nil : newInternalId
        return try await dataService.commitNewJob(companyId: companyId, job: newJob, scope: NewJobScope(tasks: copiedTasks, plannedStops: copiedPlannedStops, shoppingItems: linkedMaterials, laborLineItems: copiedLines))
    }

    // MARK: - Private Helpers

    private func copyJobTasks(
        companyId: String,
        jobId: String,
        sourceTasks: [JobTask],
        customerId: String,
        serviceLocationId: String
    ) -> [JobTask] {
        sourceTasks.map { task in
            JobTask(
                id: "comp_job_task_" + UUID().uuidString,
                name: task.name,
                type: task.type,
                contractedRate: task.contractedRate,
                estimatedTime: task.estimatedTime,
                payTypeId: task.payTypeId,
                payTypeName: task.payTypeName,
                status: .draft,
                customerApproval: task.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: "",
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: "",
                dataBaseItemId: task.dataBaseItemId,
                billingLaborPriceCents: task.billingLaborPriceCents,
                taxable: task.taxable,
                payrollMode: task.payrollMode,
                manualPayOverrideCents: task.manualPayOverrideCents,
                manualPayOverrideNotes: task.manualPayOverrideNotes,
                payrollStackBehavior: task.payrollStackBehavior,
                payQuantity: task.payQuantity
            )
        }
    }

    private func copyShoppingItems(
        sourceItems: [ShoppingListItem],
        jobId: String,
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        purchaserId: String,
        purchaserName: String
    ) -> [ShoppingListItem] {
        sourceItems.map { item in
            ShoppingListItem(
                id: UUID().uuidString,
                category: .job,
                subCategory: item.subCategory,
                status: .needToPurchase,
                purchaserId: purchaserId,
                purchaserName: purchaserName,
                genericItemId: item.genericItemId,
                name: item.name,
                description: item.description,
                datePurchased: nil,
                quantity: item.quantity,
                jobId: jobId,
                customerId: customerId,
                customerName: customerName,
                userId: nil,
                userName: nil,
                serviceLocationId: serviceLocationId,
                prepKeys: ShoppingPrepKeyBuilder.keysForJobMaterial(
                    jobId: jobId,
                    customerId: customerId,
                    serviceLocationId: serviceLocationId
                ),
                needsAction: false,
                shoppingListActive: false,
                actionDate: nil,
                dbItemId: item.dbItemId,
                purchasedItem: nil,
                invoiced: false,
                plannedUnitCostCents: item.plannedUnitCostCents,
                plannedUnitPriceCents: item.plannedUnitPriceCents,
                plannedTotalCostCents: item.plannedTotalCostCents,
                plannedTotalPriceCents: item.plannedTotalPriceCents
            )
        }
    }
}

// Shared web/iOS billing snapshot. Optional fields keep older templates readable.
struct JobLaborLineItem: Identifiable, Codable, Hashable {
    var completionStatus: String? = nil
    var id: String
    var laborLineId: String? = nil
    var companyId: String? = nil
    var jobId: String? = nil
    var templateId: String? = nil
    var name: String? = nil
    var description: String? = nil
    var quantity: Double? = nil
    var unitPriceCents: Int? = nil
    var totalPriceCents: Int? = nil
    var internalCostCents: Int? = nil
    var internalCostMode: String? = nil
    var taxable: Bool? = nil
    var taskIds: [String]? = nil
    var taskTemplateIds: [String]? = nil
    var laborLineTaskIds: [String]? = nil
    var plannedServiceStopIds: [String]? = nil
    var plannedServiceStopTemplateIds: [String]? = nil
    var laborLinePlannedServiceStopIds: [String]? = nil
    var salesItemType: String? = nil
    var billingBehavior: String? = nil
    var sourceType: String? = nil
    var sourceId: String? = nil
    var catalogItemId: String? = nil
    var salesCatalogItemId: String? = nil
    var catalogItemName: String? = nil
    var stripeConnectedAccountId: String? = nil
    var stripeProductId: String? = nil
    var stripePriceId: String? = nil
    var sourceTemplateId: String? = nil
    var sourceTemplateLaborLineId: String? = nil
    var sourcePlanId: String? = nil
    var sourceSolutionId: String? = nil
    var generatedFromTaskId: String? = nil
    var generatedFromPlannedStopId: String? = nil
    var sortOrder: Int? = nil

    var linkedTaskIds: [String] {
        if let taskIds, !taskIds.isEmpty { return taskIds }
        if let laborLineTaskIds, !laborLineTaskIds.isEmpty { return laborLineTaskIds }
        return taskTemplateIds ?? []
    }
    var linkedStopIds: [String] {
        if let plannedServiceStopIds, !plannedServiceStopIds.isEmpty { return plannedServiceStopIds }
        if let laborLinePlannedServiceStopIds, !laborLinePlannedServiceStopIds.isEmpty { return laborLinePlannedServiceStopIds }
        return plannedServiceStopTemplateIds ?? []
    }

    var priceCents: Int { totalPriceCents ?? Int((Double(unitPriceCents ?? 0) * (quantity ?? 1)).rounded()) }

    func remapped(companyId: String, taskIds: [String: String], stopIds: [String: String], jobId: String? = nil, templateId: String? = nil) -> JobLaborLineItem {
        var copy = self
        copy.id = "comp_job_labor_line_" + UUID().uuidString
        copy.laborLineId = copy.id
        copy.companyId = companyId
        copy.jobId = jobId
        copy.templateId = templateId
        copy.taskIds = self.linkedTaskIds.compactMap { taskIds[$0] }
        copy.laborLineTaskIds = copy.taskIds
        copy.taskTemplateIds = templateId == nil ? nil : copy.taskIds
        copy.plannedServiceStopIds = self.linkedStopIds.compactMap { stopIds[$0] }
        copy.laborLinePlannedServiceStopIds = copy.plannedServiceStopIds
        copy.plannedServiceStopTemplateIds = templateId == nil ? nil : copy.plannedServiceStopIds
        copy.generatedFromTaskId = generatedFromTaskId.flatMap { taskIds[$0] }
        copy.generatedFromPlannedStopId = generatedFromPlannedStopId.flatMap { stopIds[$0] }
        copy.sourceTemplateId = jobId == nil ? nil : self.templateId
        copy.sourceTemplateLaborLineId = jobId == nil ? nil : self.id
        copy.sourcePlanId = nil
        copy.sourceSolutionId = nil
        copy.completionStatus = nil
        return copy
    }
}

struct NewJobScope {
    var tasks: [JobTask] = []
    var plannedStops: [JobPlannedServiceStop] = []
    var shoppingItems: [ShoppingListItem] = []
    var laborLineItems: [JobLaborLineItem] = []
    var scheduledStops: [ServiceStop] = []
    var scheduledTasks: [String: [ServiceStopTask]] = [:]

    var completeLaborLines: [JobLaborLineItem] {
        let explicit = laborLineItems.filter { $0.generatedFromTaskId == nil && $0.generatedFromPlannedStopId == nil }
        let coveredStops = Set(explicit.flatMap { $0.linkedStopIds })
        var coveredTasks = Set(explicit.flatMap { $0.linkedTaskIds })
        for stop in plannedStops where coveredStops.contains(stop.id) { coveredTasks.formUnion(stop.taskIds) }
        var lines = explicit
        for task in tasks where !coveredTasks.contains(task.id) {
            var line = JobLaborLineItem(id: "scope_task_" + task.id)
            line.name = task.name
            line.quantity = 1
            line.totalPriceCents = task.billingLaborPriceCents ?? task.contractedRate
            line.unitPriceCents = line.totalPriceCents
            line.internalCostCents = task.contractedRate
            line.taskIds = [task.id]
            line.generatedFromTaskId = task.id
            line.taxable = task.taxable ?? false
            if line.priceCents != 0 || task.contractedRate != 0 { lines.append(line) }
        }
        for stop in plannedStops where !coveredStops.contains(stop.id) {
            var line = JobLaborLineItem(id: "scope_visit_" + stop.id)
            line.name = stop.name
            line.quantity = 1
            line.totalPriceCents = stop.billingLaborPriceCents ?? stop.plannedLaborCostCents ?? 0
            line.unitPriceCents = line.totalPriceCents
            line.internalCostCents = stop.plannedLaborCostCents ?? 0
            line.plannedServiceStopIds = [stop.id]
            line.generatedFromPlannedStopId = stop.id
            line.taxable = false
            if line.priceCents != 0 { lines.append(line) }
        }
        return lines
    }
}

extension ProductionDataServiceProtocol {
    func fetchJobHistory(companyId: String, jobId: String) async throws -> [JobHistoryEvent] { [] }
    func fetchJobLaborLineItems(companyId: String, jobId: String) async throws -> [JobLaborLineItem] { [] }
    func fetchJobTemplateLaborLineItems(companyId: String, templateId: String) async throws -> [JobLaborLineItem] { [] }
    func commitNewJob(companyId: String, job: Job, scope: NewJobScope) async throws -> Job {
        throw NSError(domain: "JobCreation", code: 1, userInfo: [NSLocalizedDescriptionKey: "Atomic job creation is unavailable for this data service."])
    }
    func saveJobTemplateBundle(template: JobTemplate, tasks: [JobTemplateTask], stops: [JobTemplatePlannedServiceStop], items: [JobTemplateShoppingItem], laborLines: [JobLaborLineItem]) async throws {
        throw NSError(domain: "JobTemplate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Atomic template saving is unavailable for this data service."])
    }
}

// The same audit fields are written by web and iOS creation flows.
struct JobHistoryEvent: Codable, Identifiable, Hashable {
    var id: String
    var companyId: String? = nil
    var jobId: String? = nil
    var jobInternalId: String? = nil
    var eventType: String? = nil
    var title: String? = nil
    var description: String? = nil
    var actorUserId: String? = nil
    var actorUserName: String? = nil
    var actorCompanyUserId: String? = nil
    var createdAt: Date? = nil
    var createdAtMillis: Int? = nil
    var date: Date? = nil
    var tech: String? = nil

    var actorDisplayName: String {
        if let name = actorUserName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty, name.lowercased() != "unknown" { return name }
        if let actorUserId, !actorUserId.isEmpty { return actorUserId }
        return tech ?? "Creator not recorded"
    }
    var timestamp: Date? {
        createdAt ?? createdAtMillis.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? date
    }
}

struct JobCreationActor {
    var userId: String
    var userName: String
    var companyUserId: String = ""

    func creationEvent(companyId: String, jobId: String, internalId: String, at date: Date) -> JobHistoryEvent {
        var event = JobHistoryEvent(id: "created")
        event.companyId = companyId
        event.jobId = jobId
        event.jobInternalId = internalId
        event.eventType = "Created"
        event.title = "Job created"
        event.description = "Job initially created from iOS."
        event.actorUserId = userId
        event.actorUserName = userName.isEmpty ? userId : userName
        event.actorCompanyUserId = companyUserId
        event.createdAt = date
        event.createdAtMillis = Int(date.timeIntervalSince1970 * 1000)
        return event
    }
}
