//
//  Task.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
//

import Foundation

struct LaborContractTask: Identifiable, Codable, Hashable {
    var id : String = "lc_tas" + UUID().uuidString
    var name : String
    var description:String
    var type : String
    var workerType : WorkerTypeEnum
    var workerName : String
    var status : JobTaskStatus
    var customerApproval : Bool
    var laborContractId : String
    var serviceStopId : [String]
    var rate : Int
    var jobIsCreated : Bool
    var jobIds : [IdInfo]
    var customerId:String
    var customerName:String
    var serviceLocationId:String
    var serviceLocationName:String
    var jobTemplateId:String
    var jobTemplateName:String
}
