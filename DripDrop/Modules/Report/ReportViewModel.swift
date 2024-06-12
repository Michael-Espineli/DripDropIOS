//
//  ReportViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
struct purchaseItemReportLineItem:Codable,Identifiable,Hashable {
    let id:String
    var price: Double
    var dataBaseItemId:String
    var dataBaseItemName:String
}
struct WasteReportItem:Identifiable,Codable,Hashable {
    let id:String
    var dosageTemplateName:String
    var dosageTemplateId:String
    var amountUsed:Double
    var amountPurchased:Double
    var price:Double
    var UOM:String
}
@MainActor
final class ReportViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //Waste Report Variables
    @Published var wasteReportItemDict: [CompanyUser:[WasteReportItem]] = [:]
    @Published var wasteReportLoading:Bool = false
    @Published var wasteReportLoadingValue:Int = 0
    @Published var wasteReportLoadingTotal:Int = 0
    @Published var wasteReportLoadingLabel:String = ""

    //Chemical Report Variables
    @Published var listOfStopData:[StopData] = []
    @Published var listOfDosageTemplates:[DosageTemplate] = []
    @Published var listOfReadingTemplates:[ReadingsTemplate] = []
    @Published var customerDict:[Customer:[StopData]] = [:]
    @Published var customerSummaryDosageDict:[Customer:[DosageTemplate:Double]] = [:]
    
    //Chemical Report Variables
    @Published var userReportDetailDictionary:[CompanyUser:[StopData]] = [:]
    @Published var userReportSummaryDictionary:[CompanyUser:[DosageTemplate:Double]] = [:]
    
    //PNL Report Variables
    @Published var pnlSummaryReport:[Customer:[Contract:Double]] = [:] //Create PNL Struct
    
    //Purchase Report Variables
        //Summary
    @Published var purchaseSummaryReport:[CompanyUser:Double] = [:]
    @Published var companyPurchaseSummary:Double? = nil

        //Detail
    @Published var purchaseDetailReport:[CompanyUser:[purchaseItemReportLineItem:Double]] = [:]
    @Published var companyPurchaseDetail:[purchaseItemReportLineItem:Double] = [:]

    func getChemicalReport(
        companyId:String,
        type:oneReportType,
        order:induvidualReportDisplay,
        startDate:Date,
        endDate:Date
    ) async throws{

 
        //Here
        let start = startDate.startOfDay()
        let end = endDate.endOfDay()
        var customerDict:[Customer:[StopData]] = [:]
        var customerSummaryDosageDict:[Customer:[DosageTemplate:Double]] = [:]
        let readingTemplateList = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        let dosageTemplateList = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        self.listOfDosageTemplates = dosageTemplateList
        self.listOfReadingTemplates = readingTemplateList
        var userReportDetailDictionary:[CompanyUser:[StopData]] = [:]
        var userReportSummaryDict:[CompanyUser:[DosageTemplate:Double]] = [:]
        
        let stopDataList = try await StopDataManager.shared.getStopDataByDateRange(companyId: companyId, startDate: start, endDate: end)
        print("Stops \(stopDataList.count)")
        switch type {
        case .detail:
            let stopDataList = try await StopDataManager.shared.getStopDataByDateRange(companyId: companyId, startDate: start, endDate: end)
            print("Generating Detail Chemical Report")
            switch order {
            case .customer:
                print("Customer")
                for stop in stopDataList {
                    var customer:Customer? = nil
                    if customerDict.keys.contains(where: {$0.id == stop.customerId}) {
                        let workingCustomerDic = customerDict.first(where: { $0.key.id == stop.customerId})
                        var customerValue = workingCustomerDic?.value
                        var customerKey:Customer = workingCustomerDic!.key // DEVELOPER PROPERLY HAndle
                        customerValue?.append(stop)
                        customerDict[customerKey] = customerValue
                    } else {
                        if stop.customerId == "" {
                            print("Throw Error For CustomerId == Nil")
                        } else {
                            
                            customer = try await CustomerManager.shared.getCustomerById(companyId: companyId, customerId: stop.customerId)
                            if let customer = customer {
                                customerDict[customer] = [stop]
                            } else {
                                print("No customer Found")
                            }
                        }
                    }
                }
                self.customerDict = customerDict
            case .user:
                print("User")
                for stop in stopDataList {
                    var user:CompanyUser? = nil
                    //If User Report Detail Dictionary Already Has that User
                    
                    if userReportDetailDictionary.keys.contains(where: {$0.userId == stop.userId}) {
                        //User Report Detail Dictionary Already Has that User
                        print("User Report Detail Dictionary Already Has that User")
                        
                        let workingUserReportDetailDictionary = userReportDetailDictionary.first(where: { $0.key.userId == stop.userId})
                        var userDictValue = workingUserReportDetailDictionary?.value
                        let userDictKey:CompanyUser = workingUserReportDetailDictionary!.key // DEVELOPER PROPERLY HANDLE ERROR
                        userDictValue?.append(stop)
                        userReportDetailDictionary[userDictKey] = userDictValue
                    } else {
                        //User Report Detail Dictionary Does Not Have User
                        print("User Report Detail Dictionary Does Not Have User")
                        if stop.id == "" {
                            print("Throw Error")
                        } else {
                            print("Stop Id Exists")
                            user = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: companyId, userId:stop.userId)
                            if let user = user {
                                userReportDetailDictionary[user] = [stop]
                            } else {
                                print("No User Found")
                            }
                        }
                    }
                    
                }
                self.userReportDetailDictionary = userReportDetailDictionary
            case .company:
                print("Company")
            }
            
        case .summary:
            print("Generating Summary Chemical Report")
            let stopDataList = try await StopDataManager.shared.getStopDataByDateRange(companyId: companyId, startDate: start, endDate: end)
            
            switch order {
            case .customer:
                print("Customer")
                for stop in stopDataList {
                    print("stop Data For \(stop.serviceStopId)")
                    var customer:Customer? = nil
                    //Check to See if Customer Is inside of Dictionary
                    if customerSummaryDosageDict.keys.contains(where: {$0.id == stop.customerId}) {
                        print("Customer is already in Dictionary")
                        let workingCustomerSummaryDosageDict = customerSummaryDosageDict.first(where: { $0.key.id == stop.customerId})
                        var summaryDosageValue = workingCustomerSummaryDosageDict?.value
                        var customerKey:Customer = workingCustomerSummaryDosageDict!.key // DEVELOPER PROPERLY Handle
                        
                        for template in dosageTemplateList {
                            print("Template Name \(template.name)")
                            if let summaryDosageValueDict = summaryDosageValue {
                                //Check if DosageTempalte is already inside of DosageDict
                                if summaryDosageValueDict.keys.contains(where: {$0.id == template.id}) {
                                    print("Dosage Template is in array in already")
                                    
                                    //Dosage Template is already inside of DosageDictionary
                                    let workingDosageDic = summaryDosageValueDict.first(where: {$0.key.id == template.id})
                                    if let workingDosageDic {
                                        var dosageValue = workingDosageDic.value
                                        var dosageKey:DosageTemplate = workingDosageDic.key
                                        if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                            if let incomingInt = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                                var dosageAmountIncrement:Double = dosageValue + incomingInt
                                                //make copy of customer Dosage Summary Dictionary
                                                var workingSummaryDosageValueDict = summaryDosageValueDict
                                                
                                                workingSummaryDosageValueDict[dosageKey] = dosageAmountIncrement
                                                
                                                customerSummaryDosageDict[customerKey] = workingSummaryDosageValueDict
                                                //update original to be new customer Dosage Summary Dictionary
                                                
                                                summaryDosageValue = workingSummaryDosageValueDict
                                                
                                            } else {
                                                print("Throw Error Unable to Convert incoming number to Int")
                                            }
                                        } else {
                                            print("Throw Error 5")
                                            
                                        }
                                        
                                    } else {
                                        print("Throw Invalid Working Dosage Dictionary")
                                        
                                    }
                                } else {
                                    print("Dosage Template not Already in array")
                                    //Dosage Template is not already inside of DosageDictionary
                                    var dosageKey:DosageTemplate = template
                                    if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                        if let dosageValue = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                            //make copy of customer Dosage Summary Dictionary
                                            var workingSummaryDosageValueDict = summaryDosageValueDict
                                            
                                            workingSummaryDosageValueDict[dosageKey] = dosageValue
                                            
                                            customerSummaryDosageDict[customerKey] = workingSummaryDosageValueDict
                                            //update original to be new customer Dosage Summary Dictionary
                                            
                                            summaryDosageValue = workingSummaryDosageValueDict
                                        } else {
                                            print("Throw Error 4")
                                        }
                                    } else {
                                        print("Throw Error 3")
                                        
                                    }
                                }
                            } else {
                                print("Invalid Customer value")
                            }
                        }
                    } else {
                        print("Customer is not in Dictionary")
                        if stop.id == "" {
                            print("Throw Error")
                        } else {
                            if stop.customerId != "" {
                                customer = try await CustomerManager.shared.getCustomerById(companyId: companyId, customerId: stop.customerId)
                                if let customerKey = customer {
                                    for template in dosageTemplateList {
                                        //No need to check if dosage template is there if customer is not
                                        var workingDosageDic:[DosageTemplate:Double] = [:]
                                        var dosageKey:DosageTemplate = template
                                        let dosageValue = stop.dosages.first(where: {$0.templateId == template.id})?.amount
                                        if dosageValue == "" || dosageValue == "0" {
                                            print(" - Chemical: \(template.name) - 0 (skipped)")
                                            
                                        } else {
                                            let validatedDosage = Double(dosageValue?.replacingOccurrences(of: " ", with: "") ?? "0")
                                            workingDosageDic[dosageKey] = validatedDosage
                                            customerSummaryDosageDict[customerKey] = workingDosageDic
                                            print(" - Chemical: \(template.name) - \(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0")")
                                        }
                                    }
                                } else {
                                    print("No customer Found")
                                }
                            } else {
                                print("Customer Id is empty")
                            }
                        }
                    }
                }
                self.customerSummaryDosageDict = customerSummaryDosageDict
            case .user:
                print("User")
                for stop in stopDataList {
                    print("** Stop Data \(stop.serviceStopId) **")
                    var user:CompanyUser? = nil
                    //Check to See if Customer Is inside of Dictionary
                    if userReportSummaryDict.keys.contains(where: {$0.userId == stop.userId}) {
                        print("User is Found in Dictionary User Report Summary Dict")
                        let workingUserReportSummaryDict = userReportSummaryDict.first(where: { $0.key.userId == stop.userId})
                        var userDosageValue = workingUserReportSummaryDict?.value
                        var userKey:CompanyUser = workingUserReportSummaryDict!.key // DEVELOPER PROPERLY Handle
                        
                        for template in dosageTemplateList {
                            print(" - Template Name \(template.name)")
                            if let summaryDosageValueDict = userDosageValue {
                                //Check if DosageTempalte is already inside of DosageDict
                                if summaryDosageValueDict.keys.contains(where: {$0.id == template.id}) {
                                    print("Dosage Template is in array in already")
                                    
                                    //Dosage Template is already inside of DosageDictionary
                                    let workingDosageDic = summaryDosageValueDict.first(where: {$0.key.id == template.id})
                                    if let workingDosageDic {
                                        var dosageValue = workingDosageDic.value
                                        var dosageKey:DosageTemplate = workingDosageDic.key
                                        if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                            if let incomingInt = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                                var dosageAmountIncrement:Double = dosageValue + incomingInt
                                                //make copy of customer Dosage Summary Dictionary
                                                var workingSummaryDosageValueDict = summaryDosageValueDict
                                                
                                                workingSummaryDosageValueDict[dosageKey] = dosageAmountIncrement
                                                
                                                userReportSummaryDict[userKey] = workingSummaryDosageValueDict
                                                //update original to be new customer Dosage Summary Dictionary
                                                
                                            } else {
                                                print("Throw Error Unable to Convert incoming number to Int")
                                            }
                                        } else {
                                            print("Throw Error 5")
                                            
                                        }
                                        
                                    } else {
                                        print("Throw Invalid Working Dosage Dictionary")
                                        
                                    }
                                } else {
                                    print("Dosage Template not Already in array")
                                    //Dosage Template is not already inside of DosageDictionary
                                    var dosageKey:DosageTemplate = template
                                    if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                        if let dosageValue = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                            //make copy of customer Dosage Summary Dictionary
                                            var workingSummaryDosageValueDict = summaryDosageValueDict
                                            
                                            workingSummaryDosageValueDict[dosageKey] = dosageValue
                                            
                                            userReportSummaryDict[userKey] = workingSummaryDosageValueDict
                                            //update original to be new customer Dosage Summary Dictionary
                                            
                                            userDosageValue = workingSummaryDosageValueDict
                                        } else {
                                            print("Throw Error 4")
                                        }
                                    } else {
                                        print("Throw Error 3")
                                        
                                    }
                                }
                            } else {
                                print("Invalid Customer value")
                            }
                        }
                    } else {
                        print("User is not in Dictionary")
                        if stop.id == "" {
                            print("Throw Error")
                        } else {
                            if stop.userId != "" {
                                user = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: companyId, userId: stop.userId)
                                if let userKey = user {
                                    print("User \(userKey.userName) Found")
                                    for template in dosageTemplateList {
                                        //No need to check if dosage template is there if customer is not
                                        var workingDosageDic:[DosageTemplate:Double] = [:]
                                        let dosageKey:DosageTemplate = template
                                        let dosageValue = stop.dosages.first(where: {$0.templateId == template.id})?.amount
                                        let validatedDosage = Double(dosageValue?.replacingOccurrences(of: " ", with: "") ?? "0")
                                        workingDosageDic[dosageKey] = validatedDosage
                                        userReportSummaryDict[userKey] = workingDosageDic
                                        print(" - Temaplate Name: \(template.name) - Amount: \(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0")")
                                    }
                                } else {
                                    print("No User Found")
                                }
                            } else {
                                print("User Id is empty")
                            }
                        }
                    }
                }
                self.userReportSummaryDictionary = userReportSummaryDict
            case .company:
                print("Company")
            default:
                print("Invalid Order Selected")
                print("Generating Detail Chemical Report")
            }
        default:
            print("Incorrect Chemical Report Type")
        }
    }
    //Waste Report Functions
    
    func getWasteReport(
        companyId:String,
        type:oneReportType,
        wasteType:induvidualReportDisplay,
        startDate:Date,
        endDate:Date
    ) async throws{
        self.wasteReportLoading = true
        
        let start = startDate.startOfDay()
        let end = endDate.endOfDay()
        var userReportDetailDictionary:[CompanyUser:[StopData]] = [:]
        var userReportSummaryDict:[CompanyUser:[DosageTemplate:Double]] = [:]
        
        let stopDataList = try await StopDataManager.shared.getStopDataByDateRange(companyId: companyId, startDate: start, endDate: end)
        print("Stops \(stopDataList.count)")
        let readingTemplateList = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        let dosageTemplateList = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        self.listOfDosageTemplates = dosageTemplateList
        self.listOfReadingTemplates = readingTemplateList
        switch type {
        case .detail:
            print("Generating Detail Chemical Report")
            
            print("Stop Data Found \(stopDataList.count)")
            switch wasteType {
            case .user:
                print("User")
                self.wasteReportLoadingTotal = stopDataList.count
                self.wasteReportLoadingValue = 0

                for stop in stopDataList {
                    self.wasteReportLoadingValue = 1 + wasteReportLoadingValue
                    print("** Stop Data \(stop.serviceStopId) **")
                    var user:CompanyUser? = nil
                    //Check to See if Customer Is inside of Dictionary
                    if userReportSummaryDict.keys.contains(where: {$0.userId == stop.userId}) {
                        print("User is Found in Dictionary User Report Summary Dict")
                        let workingUserReportSummaryDict = userReportSummaryDict.first(where: { $0.key.userId == stop.userId})
                        var userDosageValue = workingUserReportSummaryDict?.value
                        var userKey:CompanyUser = workingUserReportSummaryDict!.key // DEVELOPER PROPERLY Handle
                        self.wasteReportLoadingLabel = userKey.userName

                        for template in dosageTemplateList {
                            print(" - Template Name \(template.name)")
                            if let summaryDosageValueDict = userDosageValue {
                                //Check if DosageTempalte is already inside of DosageDict
                                if summaryDosageValueDict.keys.contains(where: {$0.id == template.id}) {
                                    print("Dosage Template is in array in already")
                                    
                                    //Dosage Template is already inside of DosageDictionary
                                    let workingDosageDic = summaryDosageValueDict.first(where: {$0.key.id == template.id})
                                    if let workingDosageDic {
                                        var dosageValue = workingDosageDic.value
                                        var dosageKey:DosageTemplate = workingDosageDic.key
                                        if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                            if let incomingInt = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                                var dosageAmountIncrement:Double = dosageValue + incomingInt
                                                //make copy of customer Dosage Summary Dictionary
                                                var workingSummaryDosageValueDict = summaryDosageValueDict
                                                
                                                workingSummaryDosageValueDict[dosageKey] = dosageAmountIncrement
                                                
                                                userReportSummaryDict[userKey] = workingSummaryDosageValueDict
                                                //update original to be new customer Dosage Summary Dictionary
                                                
                                            } else {
                                                print("Throw Error Unable to Convert incoming number to Int")
                                            }
                                        } else {
                                            print("Throw Error 5")
                                            
                                        }
                                        
                                    } else {
                                        print("Throw Invalid Working Dosage Dictionary")
                                        
                                    }
                                } else {
                                    print("Dosage Template not Already in array")
                                    //Dosage Template is not already inside of DosageDictionary
                                    var dosageKey:DosageTemplate = template
                                    if stop.dosages.contains(where: {$0.templateId == template.id}) {
                                        if let dosageValue = Double(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0") {
                                            //make copy of customer Dosage Summary Dictionary
                                            var workingSummaryDosageValueDict = summaryDosageValueDict
                                            
                                            workingSummaryDosageValueDict[dosageKey] = dosageValue
                                            
                                            userReportSummaryDict[userKey] = workingSummaryDosageValueDict
                                            //update original to be new customer Dosage Summary Dictionary
                                            
                                            userDosageValue = workingSummaryDosageValueDict
                                        } else {
                                            print("Throw Error 4")
                                        }
                                    } else {
                                        print("Throw Error 3")
                                        
                                    }
                                }
                            } else {
                                print("Invalid Customer value")
                            }
                        }
                    } else {
                        print("User is not in Dictionary")
                        if stop.id == "" {
                            print("Throw Error")
                        } else {
                            if stop.userId != "" {
                                user = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: companyId, userId: stop.userId)
                                if let userKey = user {
                                    print("User \(userKey.userName) Found")
                                    for template in dosageTemplateList {
                                        //No need to check if dosage template is there if customer is not
                                        var workingDosageDic:[DosageTemplate:Double] = [:]
                                        let dosageKey:DosageTemplate = template
                                        let dosageValue = stop.dosages.first(where: {$0.templateId == template.id})?.amount
                                        let validatedDosage = Double(dosageValue?.replacingOccurrences(of: " ", with: "") ?? "0")
                                        workingDosageDic[dosageKey] = validatedDosage
                                        userReportSummaryDict[userKey] = workingDosageDic
                                        print(" - Temaplate Name: \(template.name) - Amount: \(stop.dosages.first(where: {$0.templateId == template.id})?.amount ?? "0")")
                                    }
                                } else {
                                    print("No User Found")
                                }
                            } else {
                                print("User Id is empty")
                            }
                        }
                    }
                }
                self.userReportSummaryDictionary = userReportSummaryDict
            case .company:
                print("Company")
            default:
                print("Invalid Order Selected")
                print("Generating Detail Chemical Report")
                
            }
            
        case .summary:
            print("Generating Detail Chemical Report")
            let purchaseItems = try await dataService.getAllpurchasedItemsByDate(companyId: companyId, startDate: startDate, endDate: endDate)
            switch wasteType {
            case .user:
                print("User")
                var dataBaseItems:[DataBaseItem] = []
                var wasteReportItemDict: [CompanyUser:[WasteReportItem]] = [:]
                
                let companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                self.wasteReportLoadingTotal = companyUsers.count
                self.wasteReportLoadingValue = 0
                for user in companyUsers {
                    self.wasteReportLoadingLabel = user.userName
                    self.wasteReportLoadingValue = 1 + wasteReportLoadingValue
                    var wasteReportList:[WasteReportItem] = []
                    
                    print("Getting Waste Report For \(user.userName)")
                    
                    for stop in stopDataList {
                        
                        if stop.userId == user.userId {
                            
                            print("Got Stop")
                            
                            for dosage in stop.dosages {
                                
                                let dosageTemplate = listOfDosageTemplates.first(where: {$0.id == dosage.templateId})
                                
                                if let dosageTemplate {
                                    
                                    if let wasteReport =  wasteReportList.first(where: {$0.dosageTemplateId == dosage.templateId}) {
                                        print("Waste Report List Does Contains Dosage \(dosage.name)")
                                        
                                        if let dosageAmount = dosage.amount, let amount = Double(dosageAmount){
                                            
                                            var workWorkingWasteReport = wasteReport
                                            
                                            workWorkingWasteReport.amountUsed = amount + wasteReport.amountUsed
                                            print(workWorkingWasteReport)
                                            wasteReportList.removeAll(where: {$0.id == wasteReport.id})
                                            
                                            wasteReportList.append(workWorkingWasteReport)
                                            
                                        }
                                        
                                    } else {
                                        print("Waste Report List Does Not Contain Dosage \(dosage.name)")
                                        
                                        if let dosageAmount = dosage.amount, let amount = Double(dosageAmount), let dosageRate = dosage.rate, let rate = Double(dosageRate) {
                                            
                                            let waste = WasteReportItem(
                                                id: UUID().uuidString,
                                                dosageTemplateName: dosageTemplate.name ?? "",
                                                dosageTemplateId: dosageTemplate.id,
                                                amountUsed: amount,
                                                amountPurchased: 0,
                                                price: rate,
                                                UOM:dosage.UOM ?? ""
                                            )
                                            
                                            wasteReportList.append(waste)
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                    for item in purchaseItems {
                        if item.techId == user.userId {
                            //Maybe Get Data Base Items
                            print("Got Purchase Item")
                            
                            if let dataBaseItem = dataBaseItems.first(where: {$0.id == item.itemId}) {
                                print("Data Base Item List Containts Data Base Items")
                                if let trackingId = dataBaseItem.tracking , let wasteReport =  wasteReportList.first(where: {$0.dosageTemplateId == trackingId}) {
                                    //Check
                                    var workWorkingWasteReport = wasteReport
                                    
                                    workWorkingWasteReport.amountPurchased = Double(item.quantity) + wasteReport.amountPurchased
                                    
                                    wasteReportList.removeAll(where: {$0.id == wasteReport.id})
                                    
                                    wasteReportList.append(workWorkingWasteReport)
                                    
                                }
                                
                            } else {
                                print("Getting New Data Base Item ID > \(item.itemId) Name > \(item.name)")
                                //I am doing this to save Items
                                let dataBaseItem = try? await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: item.itemId)
                                if let dataBaseItem {
                                    print("Successfully got Data Base Item \(dataBaseItem.name)")
                                    dataBaseItems.append(dataBaseItem)
                                    if let trackingId = dataBaseItem.tracking , let wasteReport =  wasteReportList.first(where: {$0.dosageTemplateId == trackingId}) {
                                        //Check
                                        var workWorkingWasteReport = wasteReport
                                        
                                        workWorkingWasteReport.amountPurchased = Double(item.quantity) + wasteReport.amountPurchased
                                        
                                        wasteReportList.removeAll(where: {$0.id == wasteReport.id})
                                        
                                        wasteReportList.append(workWorkingWasteReport)
                                        
                                    }
                                } else {
                                    print("Failed")
                                }
                            }
                        }
                    }
                    wasteReportItemDict[user] = wasteReportList
                }

                self.wasteReportItemDict = wasteReportItemDict
            case .company:
                print("Company")
            case .customer:
                print("Customer")
            }
        }
        self.wasteReportLoading = false

    }
    
    func getPNLReport(companyId:String,type:oneReportType,PNLType:induvidualReportDisplay,startDate:Date,endDate:Date) async throws{
        print("Add Something to do With Something")
        let start = startDate.startOfDay()
        let end = endDate.endOfDay()
        var pnlSummaryReport:[Customer:[Contract:Double]] = [:] //Create PNL Struct
        
        let stopDataList = try await StopDataManager.shared.getStopDataByDateRange(companyId: companyId, startDate: start, endDate: end)
        print("Stops \(stopDataList.count)")
        let readingTemplateList = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
        let dosageTemplateList = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
        self.listOfDosageTemplates = dosageTemplateList
        self.listOfReadingTemplates = readingTemplateList
        let contracts = try await ContractManager.shared.getAllContrats(companyId: companyId)
        print("PNL Report")
        
        switch type {
        case .detail:
            print(" - Generate Detail Report")
            
            print("Stop Data Found \(stopDataList.count)")
            switch PNLType {
            case .user:
                print("User")
                
            case .company:
                print("Company")
            case .customer:
                print("Customer")

            }
            
        case .summary:
            print(" - Summary Report")
            switch PNLType {
            case .user:
                print("User")
                for contract in contracts {
                    var workingContractLossDict:[Contract:Double] = [:]
                    let customer = try await CustomerManager.shared.getCustomerById(companyId: companyId, customerId: contract.customerId)
                    var totalChemCost:Double = 0
                    var totalCost:Double = 0
                    var totalLaborCost:Double = 0
                    
                    for stop in stopDataList {
                        if stop.customerId == customer.id {
                            for dosage in stop.dosages {
                                if let chemRate = Double(listOfDosageTemplates.first(where: {$0.id == dosage.templateId})?.rate ?? "1"), let amount = Double(dosage.amount ?? "1") {
                                    totalChemCost = totalChemCost + (amount * chemRate)
                                } else {
                                    print(" \(dosage.name)- \(Double(listOfDosageTemplates.first(where: {$0.id == dosage.templateId})?.rate ?? "1"))- \(Double(dosage.amount ?? "1"))")
                                }
                            }
                            totalLaborCost = totalLaborCost + 15
                        }
                    }
                    
                    let profit = contract.rate - totalChemCost - totalLaborCost
                    workingContractLossDict[contract] = profit
                    pnlSummaryReport[customer] = workingContractLossDict
                    print("Customer \(contract.customerName)")
                    print(" - Chem Cost: \(totalCost)")
                    print(" - Labor Cost: \(totalLaborCost)")
                    
                    print(" - Final Profit: \(profit)")
                }
            case .company:
                print("Company")
            case .customer:
                print("Customer")
            }
        default:
            print("Incorrect Chemical Report Type")
        }
        self.pnlSummaryReport = pnlSummaryReport
    }
    
    func getUserReport(companyId:String,type:oneReportType,orderString:induvidualReportDisplay,startDate:Date,endDate:Date) async throws {
        
    }
    //Purchasse
    func getPurchaseReport(companyId:String,type:oneReportType,orderString:induvidualReportDisplay,startDate:Date,endDate:Date) async throws {
        print("")
        var purchaseSummaryReport:[CompanyUser:[purchaseItemReportLineItem:Double]] = [:]
        switch type {
        case .summary:
            print("Summary")
            switch orderString {
            case .company:
                print("Company")
                
                var companyPurchaseSummary:Double = 0
                let purchaseList = try await dataService.getAllpurchasedItemsByDate(companyId: companyId, startDate: startDate, endDate: endDate)
                for purchase in purchaseList {
                    companyPurchaseSummary += purchase.totalAfterTax
                }
                self.companyPurchaseSummary = companyPurchaseSummary
            case .customer:
                print("Customer")

            case .user:
                print("User")
                var purchaseSummaryReport:[CompanyUser:Double] = [:]
                let companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                for companyUser in companyUsers {
                    print("Getting Summary for \(companyUser.userName)")
                    var purchseAmount:Double = 0
                    let purchaseList = try await dataService.getAllpurchasedItemsByTechAndDate(companyId: companyId, techId: companyUser.userId, startDate: startDate, endDate: endDate)
                    
                    print("Got \(purchaseList.count) Purchases")
                    
                    for purchase in purchaseList {
                        purchseAmount += purchase.totalAfterTax
                    }
                    purchaseSummaryReport[companyUser] = purchseAmount
                }
                self.purchaseSummaryReport = purchaseSummaryReport
            }


        case .detail:
            print("Detail")
            switch orderString {
            case .company:
                print("Company")
                var companyPurchaseDetail:[purchaseItemReportLineItem:Double] = [:]

                let purchaseList = try await dataService.getAllpurchasedItemsByDate(companyId: companyId, startDate: startDate, endDate: endDate)
                for purchase in purchaseList {
                    
                    let workingPurchaseDic = companyPurchaseDetail.first(where: {$0.key.dataBaseItemId == purchase.name})
                    if let workingPurchaseDic {
                        var count = workingPurchaseDic.value + purchase.quantity
                        print("\(purchase.name) \(count)")
                        companyPurchaseDetail[workingPurchaseDic.key] = count
                        
                    } else {
                        print("\(purchase.name) \(purchase.quantity)")
                        companyPurchaseDetail[purchaseItemReportLineItem(id: UUID().uuidString, price: purchase.price, dataBaseItemId: purchase.name, dataBaseItemName: purchase.name)] = purchase.quantity
                    }
                }
                self.companyPurchaseDetail = companyPurchaseDetail
            case .customer:
                print("Customer")

            case .user:
                print("User")
                let companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                for companyUser in companyUsers {
                    print("Getting Detailed Report for \(companyUser.userName)")
                    
                    var purchaseCount:[purchaseItemReportLineItem:Double] = [:]
                    
                    let purchaseList = try await dataService.getAllpurchasedItemsByTechAndDate(companyId: companyId, techId: companyUser.userId, startDate: startDate, endDate: endDate)
                    
                    print("Got \(purchaseList.count) Purchases")
                    
                    for purchase in purchaseList {
                        
                        let workingPurchaseDic = purchaseCount.first(where: {$0.key.dataBaseItemId == purchase.name})
                        if let workingPurchaseDic {
                            var count = workingPurchaseDic.value + purchase.quantity
                            print("\(purchase.name) \(count)")
                            purchaseCount[workingPurchaseDic.key] = count
                            
                        } else {
                            print("\(purchase.name) \(purchase.quantity)")
                            purchaseCount[purchaseItemReportLineItem(id: UUID().uuidString, price: purchase.price, dataBaseItemId: purchase.name, dataBaseItemName: purchase.name)] = purchase.quantity
                            
                        }
                    }
                    purchaseSummaryReport[companyUser] = purchaseCount
                }
                self.purchaseDetailReport = purchaseSummaryReport
            }
        }
        print("")
    }
    
    func getPurchase(array:[purchaseItemReportLineItem:Double]) -> Double{
        var total:Double = 0
        for item in Array(array.keys) {
            if let amount = array[item] {
                total += amount * item.price
            }
        }
        return total
    }
}
