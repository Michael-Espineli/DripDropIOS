//
//  JobPlannedServiceStop.swift
//  DripDrop
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

    var createdAt: Date
    var createdByUserId: String

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
        createdAt: Date = Date(),
        createdByUserId: String
    ) {
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
        self.createdAt = createdAt
        self.createdByUserId = createdByUserId
    }
}