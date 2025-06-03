//
//  RouteString.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/8/24.
//

import Foundation
enum RouteString:String,Codable {
    
    case operation = "operation"
    case finace = "finace"
    case managment = "managment"
    case dashBoard = "dashBoard"
    case customers = "customers"
    case toDoDetail  = "toDoDetail"
    case repairRequestList  = "repairRequestList"
    case toDoList  = "toDoList"
    case pendingJobs  = "pendingJobs"
    case shoppingList  = "shoppingList"
    case purchasedItemsList  = "purchasedItemsList"
    case map  = "map"
    case dailyDisplay  = "dailyDisplay"
    case calendar  = "calendar"
    case profile  = "profile"
    case routeBuilder = "routeBuilder"
    case pnl  = "pnl"
    case companyRouteOverView = "companyRouteOverView"
    case routeOverview = "routeOverview"
    case allTechRouteOverview = "allTechRouteOverview"
    case dailyDisplayStop = "dailyDisplayStop"
    case reports  = "reports"
    case fleet  = "fleet"
    case mainDailyDisplayView = "mainDailyDisplayView"
    case serviceStops  = "serviceStops"
    case jobs  = "jobs"
    case contracts  = "contracts"
    case purchases  = "purchases"
    case receipts  = "receipts"
    case databaseItems  = "databaseItems"
    case genericItems  = "genericItems"
    case venders  = "venders"
    case users  = "users"
    case userRoles  = "userRoles"
    case readingsAndDosages  = "readingsAndDosages"
    case marketPlace  = "marketPlace"
    case jobPosing  = "jobPosing"
    case feed  = "feed"
    case chats = "chats"
    case equipmentList  = "equipmentList"
    case routes  = "routes"
    case settings  = "settings"
    case userSettings  = "userSettings"
    case companySettings = "companySettings"
    case jobTemplates  = "jobTemplates"
    case accountsPayableList  = "accountsPayableList"
    case accountsReceivableList  = "accountsReceivableList"
    case businesses  = "businesses"
    case alerts = "alerts"
    case cart = "cart"
    case shoppingListDetail = "shoppingListDetail"
    case purchase = "purchase"
    case job = "job"
    case editUser = "editUser"
    case rateSheet = "rateSheet"
    case companyUserRateSheet = "companyUserRateSheet"
    case chat = "chat"
    case repairRequest = "repairRequest"
    case customer = "customer"
    case serviceStop = "serviceStop"
    case business = "business"
    case vender = "vender"
    case dataBaseItem = "dataBaseItem"
    case contract = "contract"
    case genericItem = "genericItem"
    case readingTemplate = "readingTemplate"
    case dosageTemplate = "dosageTemplate"
    case recentActivity = "recentActivity"
    case receipt = "receipt"
    case companyProfile = "companyProfile"
    case compileInvoice = "compileInvoice"
    case createNewJob = "createNewJob"
    case createRepairRequest = "createRepairRequest"
    case createCustomer = "createCustomer"
    case equipmentDetailView = "equipmentDetailView"
    case vehicalDetailView = "vehicalDetailView"
    case accountsPayableDetail = "accountsPayableDetail"
    case accountsReceivableDetail = "accountsReceivableDetail"
    case companyUserDetailView = "companyUserDetailView"
    case laborContractDetailView = "recurringLaborContractDetailView"
    case jobTemplate = "jobTemplate"
    case laborContracts = "laborContracts"
    case companyAlerts = "companyAlerts"
    case externalRouteOverView = "externalRouteOverView"
    case banks = "banks"
    case transactions = "transactions"
    case bankDetailView = "bankDetailView"
    case transactionDetailView = "transactionDetailView"
    case activeRouteOverView = "activeRouteOverView"
    case emailConfiguration = "emailConfiguration"
    case managementTables = "managementTables"
    case employeeMainDailyDisplayView = "employeeMainDailyDisplayView"

    
}

extension RouteString {
    func hasItem() ->Bool{
        switch self {
        case .operation:
            return false
        case .finace:
            return false
        case .managment:
            return false
        case .dashBoard:
            return false
        case .customers:
            return false
        case .toDoDetail:
            return false
        case .repairRequestList:
            return false
        case .toDoList:
            return false
        case .pendingJobs:
            return false
        case .shoppingList:
            return false
        case .purchasedItemsList:
            return false
        case .map:
            return false
        case .dailyDisplay:
            return false
        case .calendar:
            return false
        case .profile:
            return false
        case .routeBuilder:
            return false
        case .pnl:
            return false
        case .companyRouteOverView:
            return false
        case .routeOverview:
            return false
        case .allTechRouteOverview:
            return false
        case .dailyDisplayStop:
            return false
        case .reports:
            return false
        case .fleet:
            return false
        case .mainDailyDisplayView:
            return false
        case .serviceStops:
            return false
        case .jobs:
            return false
        case .contracts:
            return false
        case .purchases:
            return false
        case .receipts:
            return false
        case .databaseItems:
            return false
        case .genericItems:
            return false
        case .venders:
            return false
        case .users:
            return false
        case .userRoles:
            return false
        case .readingsAndDosages:
            return false
        case .marketPlace:
            return false
        case .jobPosing:
            return false
        case .feed:
            return false
        case .chats:
            return false
        case .equipmentList:
            return false
        case .routes:
            return false
        case .settings:
            return false
        case .userSettings:
            return false
        case .companySettings:
            return false
        case .jobTemplates:
            return false
        case .accountsPayableList:
            return false
        case .accountsReceivableList:
            return false
        case .businesses:
            return false
        case .alerts:
            return false
        case .cart:
            return false
        case .recentActivity:
            return false
            
        case .shoppingListDetail:
            return true
        case .purchase:
            return true
        case .job:
            return true
        case .editUser:
            return true
        case .rateSheet:
            return true
        case .companyUserRateSheet:
            return true
        case .chat:
            return true
        case .repairRequest:
            return true
        case .customer:
            return true
        case .serviceStop:
            return true
        case .business:
            return true
        case .vender:
            return true
        case .dataBaseItem:
            return true
        case .contract:
            return true
        case .genericItem:
            return true
        case .readingTemplate:
            return true
        case .dosageTemplate:
            return true
       
        case .receipt:
            return true
        case .companyProfile:
            return true
        case .compileInvoice:
            return true
        case .createNewJob:
            return true
        case .createRepairRequest:
            return true
        case .createCustomer:
            return true
        case .equipmentDetailView:
            return true
        case .vehicalDetailView:
            return true
        case .accountsPayableDetail:
            return true
        case .accountsReceivableDetail:
            return true
        case .companyUserDetailView:
            return true
        case .laborContractDetailView:
            return true
        case .jobTemplate:
            return true
        case .laborContracts:
            return false
        case .companyAlerts:
            return false
        case .externalRouteOverView:
            return false
        case .banks:
            return false
        case .transactions:
            return false
        case .bankDetailView:
            return true
        case .transactionDetailView:
            return true
        case .activeRouteOverView:
            return false
        case .emailConfiguration:
            return false
        case .managementTables:
            return false
        case .employeeMainDailyDisplayView:
            return false
        }
    }
}
