//
//  Task.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
//

import Foundation

protocol TaskItem {
    var name : String { get set } //{ get } //read able
    var type : JobTaskType { get set } //{ get set } //Read and write able
    var contractedRate : Int { get set } // Cents
    var estimatedTime : Int { get set } // Min
    var status : JobTaskStatus { get set }

}
struct JobTaskGroupItem:Identifiable, Codable, Equatable{
    var id:String
    var name:String
    var type:JobTaskType
    var description:String
    var contractedRate:Int // Cents
    var estimatedTime:Int // Min
    
    static func == (lhs: JobTaskGroupItem, rhs: JobTaskGroupItem) -> Bool {
        return lhs.id == rhs.id
    }
}
struct JobTask: Identifiable, Codable, Hashable, TaskItem {
    var id : String = "comp_job_task_" + UUID().uuidString
    
    var name : String
    var type : JobTaskType
    var contractedRate : Int //Cents
    var estimatedTime : Int //Minutes
    var status : JobTaskStatus
    
    var customerApproval : Bool
    var actualTime : Int //Minutes
    
    var workerId : String
    var workerType : WorkerTypeEnum
    var workerName : String
    
    var laborContractId : String
    var serviceStopId : IdInfo //Sender
    
    var equipmentId : String
    var serviceLocationId : String
    var bodyOfWaterId : String
    var dataBaseItemId : String
    var shoppingListItemId: String? = nil
    var purchasedItemId: String? = nil
    var installedEquipmentId: String? = nil
    var replacementEquipmentId: String? = nil
}

struct LaborContractTask: Identifiable, Codable, Hashable, TaskItem {
    var id : String = "lc_task" + UUID().uuidString
    
    var name : String
    var type : JobTaskType
    var contractedRate : Int //Cents
    var estimatedTime : Int //Minutes
    var status : JobTaskStatus

    var customerApproval : Bool
    
    var laborContractId : String
    var serviceStopId : IdInfo //Receiver Service Stop Id
    
    var jobIsCreated : Bool
    var receiverJobId : [IdInfo]
    var senderJobTaskId : String
    
    var equipmentId : String
    var serviceLocationId : String
    var bodyOfWaterId : String
    var shoppingListItemId : String
}

struct ServiceStopTask: Identifiable, Codable, Hashable, TaskItem {
    
    var id : String = "comp_ss_task_" + UUID().uuidString
    
    var name : String
    var type : JobTaskType
    var status : JobTaskStatus
    var contractedRate : Int //Cents
    var estimatedTime : Int //Minutes
    
    var customerApproval : Bool
    var actualTime : Int //Minutes
    
    var workerId : String
    var workerType : WorkerTypeEnum
    var workerName : String
    
    var laborContractId : String
    var serviceStopId : IdInfo
    var jobId : IdInfo
    var recurringServiceStopId : IdInfo
    
    var jobTaskId : String
    var recurringServiceStopTaskId : String
    
    var equipmentId : String
    var serviceLocationId : String
    var bodyOfWaterId : String
    var shoppingListItemId : String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case status
        case contractedRate
        case estimatedTime
        case customerApproval
        case actualTime
        case workerId
        case workerType
        case workerName
        case laborContractId
        case serviceStopId
        case jobId
        case recurringServiceStopId
        case jobTaskId
        case recurringServiceStopTaskId
        case equipmentId
        case serviceLocationId
        case bodyOfWaterId
        case shoppingListItemId
    }

    init(
        id: String = "comp_ss_task_" + UUID().uuidString,
        name: String,
        type: JobTaskType,
        status: JobTaskStatus,
        contractedRate: Int,
        estimatedTime: Int,
        customerApproval: Bool,
        actualTime: Int,
        workerId: String,
        workerType: WorkerTypeEnum,
        workerName: String,
        laborContractId: String,
        serviceStopId: IdInfo,
        jobId: IdInfo,
        recurringServiceStopId: IdInfo,
        jobTaskId: String,
        recurringServiceStopTaskId: String,
        equipmentId: String,
        serviceLocationId: String,
        bodyOfWaterId: String,
        shoppingListItemId: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.contractedRate = contractedRate
        self.estimatedTime = estimatedTime
        self.customerApproval = customerApproval
        self.actualTime = actualTime
        self.workerId = workerId
        self.workerType = workerType
        self.workerName = workerName
        self.laborContractId = laborContractId
        self.serviceStopId = serviceStopId
        self.jobId = jobId
        self.recurringServiceStopId = recurringServiceStopId
        self.jobTaskId = jobTaskId
        self.recurringServiceStopTaskId = recurringServiceStopTaskId
        self.equipmentId = equipmentId
        self.serviceLocationId = serviceLocationId
        self.bodyOfWaterId = bodyOfWaterId
        self.shoppingListItemId = shoppingListItemId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "comp_ss_task_" + UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try container.decodeIfPresent(JobTaskType.self, forKey: .type) ?? .basic
        status = try container.decodeIfPresent(JobTaskStatus.self, forKey: .status) ?? .scheduled
        contractedRate = try container.decodeIfPresent(Int.self, forKey: .contractedRate) ?? 0
        estimatedTime = try container.decodeIfPresent(Int.self, forKey: .estimatedTime) ?? 0
        customerApproval = try container.decodeIfPresent(Bool.self, forKey: .customerApproval) ?? false
        actualTime = try container.decodeIfPresent(Int.self, forKey: .actualTime) ?? 0
        workerId = try container.decodeIfPresent(String.self, forKey: .workerId) ?? ""
        workerType = try container.decodeIfPresent(WorkerTypeEnum.self, forKey: .workerType) ?? .notAssigned
        workerName = try container.decodeIfPresent(String.self, forKey: .workerName) ?? ""
        laborContractId = try container.decodeIfPresent(String.self, forKey: .laborContractId) ?? ""
        serviceStopId = ServiceStopTask.decodeIdInfo(container, forKey: .serviceStopId)
        jobId = ServiceStopTask.decodeIdInfo(container, forKey: .jobId)
        recurringServiceStopId = ServiceStopTask.decodeIdInfo(container, forKey: .recurringServiceStopId)
        jobTaskId = try container.decodeIfPresent(String.self, forKey: .jobTaskId) ?? ""
        recurringServiceStopTaskId = try container.decodeIfPresent(String.self, forKey: .recurringServiceStopTaskId) ?? ""
        equipmentId = try container.decodeIfPresent(String.self, forKey: .equipmentId) ?? ""
        serviceLocationId = try container.decodeIfPresent(String.self, forKey: .serviceLocationId) ?? ""
        bodyOfWaterId = try container.decodeIfPresent(String.self, forKey: .bodyOfWaterId) ?? ""
        shoppingListItemId = try container.decodeIfPresent(String.self, forKey: .shoppingListItemId) ?? ""
    }

    private static func decodeIdInfo(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> IdInfo {
        if let value = try? container.decode(IdInfo.self, forKey: key) {
            return value
        }

        if let value = try? container.decode(String.self, forKey: key) {
            return IdInfo(id: value, internalId: "")
        }

        return IdInfo(id: "", internalId: "")
    }
}

struct RecurringServiceStopTask: Identifiable, Codable, Hashable, TaskItem {
    var id : String = "comp_rss_task_" + UUID().uuidString
    
    var name : String
    var description : String
    var type : JobTaskType
    var contractedRate : Int // Cents
    var estimatedTime : Int // Min
    var status : JobTaskStatus
    var isTaskGroup : Bool
    var taskGroupId : String
    var taskGroupTaskId : String

}
