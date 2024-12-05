//
//  ListOfEnum.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/28/24.
//

import Foundation

enum RecurringContractChemType:String,Codable,CaseIterable{
    case withChems = "With Chemicals"
    case withOutChems = "With Out Chemicals"
    case withSpecificChems = "With Specific Chems"
    case allInclusive = "All Inclusive"
}
enum RecurringContractCleaningPlan:String,Codable,CaseIterable{
    case basic = "Basic"
    case custom = "Custom"
    case chemsOnly = "Chems Only"
}
enum BillingType:String,Codable,CaseIterable{
    case billedSeparately = "Billed Separately"
    case included = "Included"
}
enum RecurringContractLaborType:String,Codable,CaseIterable{
    case perWeek = "Per Week"
    case perMonth = "Per Month"
    case perStop = "Per Stop"
}
enum RecurringContractRateType:String,Codable,CaseIterable{
    case perYear = "Per Year"
    case perMonth = "Per Month"
    case perWeek = "Per Week"
    case perStop = "Per Stop"
    case perDay = "Per Day"
}
enum RecurringContractStatus:String,Codable,CaseIterable{
    case pending = "Pending"
    case accepted = "Accepted"
    case past = "Past"
    case rejected = "Rejected"
}
enum RecurringContractServiceFrequency:String,Codable,CaseIterable{
    case perMonth = "Per Month"
    case everyOtherWeek = "Every Other Week"
    case perWeek = "Per Week"
    case twicePerWeek = "Twice Per Week"
    case threeTimesPerWeek = "Three Times Per Week"

}
enum LaborContractStatus:String,Codable,CaseIterable{
    case pending = "Pending"
    case accepted = "Accepted"
    case past = "Past"
    case rejected = "Rejected"

}
