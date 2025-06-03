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
}




struct RecurringServiceStopTask: Identifiable, Codable, Hashable, TaskItem {
    var id : String = "comp_rss_task_" + UUID().uuidString
    
    var name : String
    var type : JobTaskType
    var contractedRate : Int // Cents
    var estimatedTime : Int // Min
    var status : JobTaskStatus

}
