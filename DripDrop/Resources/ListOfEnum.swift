//
//  ListOfEnum.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/28/24.
//

import Foundation
import SwiftUI
enum WorkLogType : String, Codable, CaseIterable {
    case working = "Working"
    case onBreak = "On Break"
    case onLunch = "On Lunch"

}

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
enum RecurringContractServiceFrequency:String,Codable,CaseIterable{
    case perMonth = "Per Month"
    case everyOtherWeek = "Every Other Week"
    case perWeek = "Per Week"
    case twicePerWeek = "Twice Per Week"
    case threeTimesPerWeek = "Three Times Per Week"
}
enum LaborContractFrequency:String,Codable, CaseIterable {
    case daily = "Daily"
    case weekDay = "Week Day"
    case weekly = "Weekly"	
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}


enum RecurringContractStatus:String, Codable, CaseIterable{
    case pending = "Pending"
    case accepted = "Accepted"
    case past = "Past"
    case rejected = "Rejected"
    case draft = "Draft"

}
enum LaborContractStatus:String, Codable, CaseIterable{
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case finished = "Finished"
}
enum RecurringLaborContractStatus:String, Codable, CaseIterable{
    case pending = "Pending"
    case accepted = "Accepted"
    case rejected = "Rejected"
    case active = "Active"
    case inactive = "In Active"
}
enum JobTaskType:String, CaseIterable, Codable,Identifiable {
    var id: String { rawValue }
    case basic = "Basic"
    case clean = "Clean"
    case cleanFilter = "Clean Filter"
    case maintenance = "Maintenance"
    case repair = "Repair"
    case emptyWater = "Empty Water"
    case fillWater = "Fill Water"
    case inspection = "Inspection"
    case install = "Install"
    case remove = "Remove"
    case replace = "Replace"
}
enum JobTaskStatus:String, CaseIterable, Codable {
    case draft = "Draft"
    case unassigned = "Unassigned"
    case offered = "Offered"
    case accepted = "Accepted"
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case rejected = "Rejected"
    case finished = "Finished"
}
enum JobOperationStatus:String, CaseIterable, Codable {
    case estimatePending = "Estimate Pending"
    case unscheduled = "Unscheduled"
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case finished = "Finished"
}
enum JobEstiamteAcceptanceType:String, CaseIterable, Codable {
    case client = "Client"
    case company = "Company"
}
enum JobInvoiceType:String, CaseIterable, Codable {
    case manual = "Manual"
    case auto = "Automatic" // Through Drip DRop
}
enum JobBillingStatus:String, CaseIterable,Codable {
    case draft = "Draft"
    case estimate = "Estimate"
    case accepted = "Accepted"
    case inProgress = "In Progress"
    case invoiced = "Invoiced"
    case paid = "Paid"
}
enum RepairRequestStatus:String,Codable, CaseIterable{
    case resolved = "Resolved"
    case unresolved = "Unresolved"
    case inprogress = "In Progress"
}
enum RateSheetStatus:String ,Codable{
    case active = "Active"
    case inactive = "Inactive"
    case past = "Past"
    case offered = "Offered"
    case rejected = "Rejected"
}

enum LaborContractType:String,Codable,CaseIterable{
    case businessToBusiness = "Business To Business"
    case businessToConsumer = "Business To Consumer"
}

enum AcountingTermsTypes:String,Codable,CaseIterable {
    case net15 = "Net 15"
    case net30 = "Net 30"
    case net45 = "Net 45"
    case net60 = "Net 60"
}
enum InvoicePaymentType:String,Codable {
    case cash = "Cash"
    case check = "Check"
    case online = "Online"
}
enum InvoiceStatusType:String,Codable {
    case unpaid = "Unpaid"
    case paid = "Paid"
}
enum EquipmentStatus:String, Codable, CaseIterable, Identifiable{
    var id: String { rawValue }
    case operational = "Operational"
    case nonoperational = "Nonoperational"
    case needsRepair = "Needs Repair"
    case needsMaintenance = "Needs Maintenance"
}

enum EquipmentCategory:String,Codable,CaseIterable {
    case pump = "Pump"
    case filter = "Filter"
    case heater = "Heater"
    case saltCell = "Salt Cell"
    case light = "Light"
    case cleaner = "Cleaner"
    case controlSystem = "Control System"
    case autoChlorinator = "Auto Chlorinator"
}

enum VehicalStatus:String, Codable,CaseIterable {
    case active = "Active"
    case retired = "Retired"
}

enum VehicalType:String, Codable,CaseIterable {
    case car = "Car"
    case truck = "Truck"
    case van = "Van"
}

enum WorkerTypeEnum:String, CaseIterable, Codable {
    case contractor = "Independent Contractor"
    case employee = "Employee"
    case notAssigned = ""
}

enum ActiveRouteStatus:String,Codable,CaseIterable {
    case inProgress = "In Progress"
    case didNotStart = "Did Not Start"
    case traveling = "Traveling"
    case onBreak = "Break"
    case finished = "Finished"
}

enum CompanyUserStatus:String, Codable {
    case active = "Active"
    case pending = "Pending"
    case past = "Past"
}
enum RateSheetLaborType:String, Codable,CaseIterable {
    case hour = "Hour"
    case job = "Job"
}

enum WorkTimeType:String{
    case workTime = "Work Time"
    case breakTime = "Break Time"
    case lunchTime = "Lunch Time"
}

enum UnitOfMeasurment: String, Codable, CaseIterable {
    case gallon = "Gallon"
    case lbs = "Pounds"
    case oz = "Ounce"
    case ft = "Feet"
    case sqft = "Square Feet"
    case liter = "Liter"
    case inch = "Inch"
    case quart = "Quart"
    case tab = "Tab"
    case unit = "Unit"
    
    case na = ""

}

enum DataBaseItemCategory: String, CaseIterable, Codable {
    case pvc = "PVC"
    case galvanized = "Galvanized"
    case chems = "Chemicals"
    case useables = "Useables"
    case equipment = "Equipment"
    case parts = "Parts"
    case electrical = "Electrical"
    case tools = "Tools"

    case misc = "Misc"
    
    case na = ""

}

enum DataBaseItemSubCategory: String, CaseIterable, Codable {
    //PVC
    case pipe = "Pipe"
    case glue = "Glue"
    case primer = "Primer"

    case pipeExtender = "Pipe Extender"
    case fittingExtender = "Fitting Extender"

    case insideCoupler = "Inside Coupler"
    case sweep = "Sweep"
    case street = "Street"

    case valve = "Valve"
    case bushing = "Bushing"
    case tee = "Tee"
    case elbow = "Elbow"
    case elbow45 = "45"
    case coupler = "Coupler"
    case union = "Union"
    case maleAdaptor  = "Male Adaptor"

    
    //Galvanized
    case nipple = "Nipple"
    
    //Equipment
    case pump = "Pump"
    case heater = "Heater"
    case filter = "Filter"
    case saltCell = "Salt Cell"
    case light = "Light"
    case cleaner = "Cleaner"
    case controlSystem = "Control System"
    case autoChlorinator = "Auto Chlorinator"
    
    //Electrical
    case wire = "Wire"

    
    case misc = "Misc"
    
    case na = ""

}

enum DataBaseItemSubCategoryPVC: String, CaseIterable, Codable {
    
    case glue = "Glue"
    case primer = "Primer"

    case pipeExtender = "Pipe Extender"
    case fittingExtender = "Fitting Extender"

    case insideCoupler = "Inside Coupler"
    case sweep = "Sweep"
    case street = "Street"

    case valve = "Valve"
    case bushing = "Bushing"
    case tee = "Tee"
    case elbow = "Elbow"
    case elbow45 = "45"
    case coupler = "Coupler"
    case union = "Union"
    case maleAdaptor  = "Male Adaptor"
    case misc = "Misc"
}
enum DaysOfWeek: String, Hashable, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    var id: String {
        return self.rawValue
    }
}

enum DaylyDisplayAlert: String, Hashable, CaseIterable, Identifiable {
    case parts
    case emergency
    case messages
    case chems
    case alets
    var id: String {
        return self.rawValue
    }
    
    func alertInfo() -> (title:String,imageName:String,color:Color) {
        switch self {
        case .parts:
            return (title:"Parts To Install",imageName:"wrench.adjustable.fill",color:Color.purple)
        case .emergency:
            return (title:"Emergency",imageName:"exclamationmark.triangle.fill",color:Color.red)
        case .messages:
            return (title:"Messages",imageName:"exclamationmark.bubble.fill",color:Color.poolGreen)
        case .chems:
            return (title:"Chems Out Of Balance",imageName:"testtube.2",color:Color.blue)
        case .alets:
            return (title:"Alerts",imageName:"exclamationmark.circle.fill",color:Color.yellow)


        }
    }
}
