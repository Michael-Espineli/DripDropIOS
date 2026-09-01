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
                equipmentId: task.equipmentId.isEmpty ? nil : task.equipmentId,
                serviceLocationId: nil,
                bodyOfWaterId: nil,
                dataBaseItemId: task.dataBaseItemId.isEmpty ? nil : task.dataBaseItemId,
                sortOrder: index
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
                plannedLaborNotes: plannedStop.plannedLaborNotes
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
                sortOrder: index
            )
        }
        print("      [JobTemplateWorkFlowService][saveJobAsTemplate] Start Saving")
        try await dataService.saveJobTemplate(template)
        print("      [JobTemplateWorkFlowService][saveJobAsTemplate] Template saved")
        try await dataService.saveJobTemplateTasks(templateTasks)
        print("      [JobTemplateWorkFlowService][saveJobAsTemplate] Template Tasks")
        try await dataService.saveJobTemplatePlannedServiceStops(templatePlannedStops)
        print("      [JobTemplateWorkFlowService][saveJobAsTemplate] Template Planned Stops")
        try await dataService.saveJobTemplateShoppingItems(templateShoppingItems)
        print("      [JobTemplateWorkFlowService][saveJobAsTemplate] Shopping items")

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
        customerId: String,
        customerName: String,
        serviceLocationId: String,
        admin: CompanyUser,
        createdByUserId: String
    ) async throws -> Job {
        let newJobId = "comp_job_" + UUID().uuidString

        var newJob = Job(
            id: newJobId,
            internalId: newInternalId,
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
                createdByUserId: createdByUserId
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

        try await dataService.uploadWorkOrder(companyId: companyId, workOrder: newJob)
        try await dataService.saveJobTasks(
            companyId: companyId,
            jobId: newJobId,
            tasks: copiedTasks
        )

        try await dataService.saveJobPlannedServiceStops(copiedPlannedStops)

        try await dataService.saveShoppingListItems(
            companyId: companyId,
            items: copiedShoppingItems
        )

        return newJob
    }

    // MARK: - Create Job From Template

    func createJobFromTemplate(
        companyId: String,
        templateId: String,
        newInternalId: String,
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

        let newJobId = "comp_job_" + UUID().uuidString

        var newJob = Job(
            id: newJobId,
            internalId: newInternalId,
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
                status: .draft,
                customerApproval: templateTask.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: templateTask.equipmentId ?? "",
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: templateTask.bodyOfWaterId ?? "",
                dataBaseItemId: templateTask.dataBaseItemId ?? ""
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
                createdByUserId: createdByUserId
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

        try await dataService.uploadWorkOrder(companyId: companyId, workOrder: newJob)
        
        try await dataService.saveJobTasks(
            companyId: companyId,
            jobId: newJobId,
            tasks: copiedTasks
        )

        try await dataService.saveJobPlannedServiceStops(copiedPlannedStops)

        try await dataService.saveShoppingListItems(
            companyId: companyId,
            items: copiedShoppingItems
        )

        return newJob
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
                status: .draft,
                customerApproval: task.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: task.equipmentId,
                serviceLocationId: serviceLocationId,
                bodyOfWaterId: task.bodyOfWaterId,
                dataBaseItemId: task.dataBaseItemId
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
