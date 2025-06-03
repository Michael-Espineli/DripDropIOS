//
//  MyCompanyViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/23/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class MyCompanyViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //LOADING
    @Published var isLoading:Bool = true
    
    //SINGLES
    @Published private(set) var totalCustomers: Int? = nil
    @Published private(set) var totalResidentalAccounts: Int? = nil
    @Published private(set) var totalComericalAccounts: Int? = nil

    @Published private(set) var itemsPurchased: Double? = nil
    @Published private(set) var itemsPurchasedBillable: Double? = nil
    @Published private(set) var itemsPurchasedAndBilled: Double? = nil
    @Published private(set) var totalSpentBillable: Double? = nil
    @Published private(set) var totalBilled: Double? = nil
    @Published private(set) var totalSpentOnBillables: Double? = nil
    @Published private(set) var totalSpent: Double? = nil
    @Published private(set) var percentage: Double? = nil
    @Published private(set) var percentageBilled: Double? = nil
    @Published private(set) var totalProfitInDollars: Double? = nil
    @Published private(set) var totalSoldInDollars: Double? = nil
    @Published private(set) var serviceStops: [ServiceStop] = []
    
    //Jobs
    @Published private(set) var recentlyFinishedJobs: Int? = nil
    @Published private(set) var openJobs: Int? = nil
    //Users
    @Published private(set) var techsByRoles: [Role:Int] = [:]
    @Published private(set) var totalUSers: Int? = nil

    //Acounts Receivable
    @Published private(set) var ARTotal: Double? = nil
    @Published private(set) var AROutstandingCount: Int? = nil
    @Published private(set) var ARInvoiceList: [StripeInvoice] = []

        //Accounts Payable
    @Published private(set) var APTotal: Double? = nil
    @Published private(set) var APOutstandingCount: Int? = nil
    
    @Published private(set) var APTotalOutstandingLate: Int? = nil
    @Published private(set) var APOutstandingLateCount: Int? = nil
    
    @Published private(set) var APTotalRecentlyPaid: Int? = nil
    @Published private(set) var APRecentlyPaidCount: Int? = nil
    //ARRAYS

    @Published private(set) var APInvoiceList: [StripeInvoice] = []
    
    @Published private(set) var customers: [Customer] = []
    @Published private(set) var businesses: [AssociatedBusiness] = []

    @Published private(set) var purchasedItems: [PurchasedItem] = []
    @Published private(set) var jobs: [Job] = []
    @Published private(set) var listOfEquipment:[Equipment] = []
    @Published private(set) var listOfRepairRequests:[RepairRequest] = []
    @Published private(set) var listOfVehicals:[Vehical] = []
    
    @Published private(set) var vehicalCount: Int? = nil
    @Published private(set) var listOfShoppingListItems:[ShoppingListItem] = []

    @Published private(set) var listOfVenders:[Vender] = []
    @Published private(set) var venderCount: Int? = nil
    
    @Published private(set) var alertCount: Int? = nil

    @Published var companyUsers: [CompanyUser] = []
    @Published var daysAndRoutes: [String:Int] = [:]
    
    @Published private(set) var laborContractList:[ReccuringLaborContract] = []
    @Published private(set) var sentLaborContractTotal: Double? = nil

    @Published private(set) var sentLaborContractCount: Int? = nil
    @Published private(set) var sentAcceptedLaborContractCount: Int? = nil
    @Published private(set) var sentPendingLaborContractCount: Int? = nil
    @Published private(set) var sentPastLaborContractCount: Int? = nil
    
    @Published private(set) var receivedLaborContractCount: Int? = nil
    @Published private(set) var receivedAcceptedLaborContractCount: Int? = nil
    @Published private(set) var receivedPendingLaborContractCount: Int? = nil
    @Published private(set) var receivedPastLaborContractCount: Int? = nil
    
    @Published private(set) var contractList:[RecurringContract] = []
    @Published private(set) var contractCount: Int? = nil
    @Published private(set) var pendingContractCount: Int? = nil
    @Published private(set) var contractTotal: Double? = nil

    //Chart Variables
    @Published private(set) var buildActivities: [BuildActivity] = []

    //DICTIONARY
    @Published private(set) var typesAndAmount: [String:Int] = ["Sunday":0,"Monday":0,"Tuesday":0,"Wednesday":0,"Thursday":0,"Friday":0,"Saturday":0]

    
    
    func onLoad(companyId:String,userId:String,category:String) async throws {
        self.isLoading = true
        //Returns Items Mainly For Company Overview SnapShot
        //Chart Snap Shot

//        for i in 0...3 {
//
//            var date:Date = Date()
//            if i != 0 {
//                date = Calendar.current.date(byAdding: .month, value: -i, to: Date())!
//            }
//            print("Month - \(i) - \(date)")
//            if category == "Operations" {
//                self.buildActivities.append(BuildActivity(date: date, name: "Jobs", numberOfUnits: Int.random(in: 1..<50)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Repair Requests", numberOfUnits: Int.random(in: 1..<50)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Items Purchased", numberOfUnits: Int.random(in: 1..<50)))
//            } else if category == "Finance"{
//                self.buildActivities.append(BuildActivity(date: date, name: "Jobs", numberOfUnits: Int.random(in: 10..<5000)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Items Purchased", numberOfUnits: Int.random(in: -500..<10)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Monthly Service", numberOfUnits: Int.random(in: 1..<500)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Labor", numberOfUnits: Int.random(in: -500..<10)))
//            } else if category == "Management"{
//                self.buildActivities.append(BuildActivity(date: date, name: "Customers", numberOfUnits: Int.random(in: 1..<500)))
//                self.buildActivities.append(BuildActivity(date: date, name: "Technicians", numberOfUnits: Int.random(in: 10..<50)))
//            } else {
//                print("No Snap Shot")
//            }
//        }

        //Alerts
        self.alertCount = try await dataService.getDripDropAlertsCount(companyId: companyId)
        //Routes
        let days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

        for day in days {
            let count = try await dataService.getRecurringRouteByDayCount(companyId: companyId, day: day)
            if count != 0 {
                daysAndRoutes[day] = count
            }
        }
        //Users
        let roles = try await dataService.getAllCompanyRoles(companyId: companyId)
        let users = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        self.totalUSers = users.count
        for role in roles {
            let count = users.filter({$0.roleId == role.id}).count
            self.techsByRoles[role] = count
        }
        //Labor Contracts
        self.laborContractList = try await dataService.getLaborContractsSnapShot(companyId: companyId)
        
        self.sentAcceptedLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.accepted)
        
        self.sentPendingLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.pending)

        self.sentPastLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.finished)
        
        self.sentLaborContractCount = (sentAcceptedLaborContractCount ?? 0) + (sentPendingLaborContractCount ?? 0) + (sentPastLaborContractCount ?? 0)
        
        self.receivedAcceptedLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.accepted)
        
        self.receivedPendingLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.pending)

        self.receivedPastLaborContractCount = try await dataService.getLaborContractsSentCountByStatus(companyId: companyId, status: LaborContractStatus.finished)
        
        self.receivedLaborContractCount = (sentLaborContractCount ?? 0) + (receivedPendingLaborContractCount ?? 0) + (receivedPastLaborContractCount ?? 0)

        //Contracts
        
        
        
        //Total Active Customers
        self.totalCustomers = try await dataService.checkCustomerCount(companyId: companyId)
        //Total Residential - DEVELOPER >> ADD TAGS To Customer Accounts so that I can tag them as Comerical or Residental
        self.totalResidentalAccounts = 178
        
        //Total Comerical
        self.totalComericalAccounts = 15
        
        //10 Most Recent Customers.
        self.customers = try await dataService.getMostRecentCustomers(companyId: companyId, number: 10)
        
        //Get 10 Most Recent Purchases
        self.purchasedItems = try await PurchasedItemsManager.shared.getMostRecentPurchases(companyId: companyId, number: 10)
        
        //Details
        let result = try await PurchasedItemsManager.shared.getNumberOfItemsPurchasedIn30Days(companyId: companyId)
        self.itemsPurchased = result.total
        self.itemsPurchasedBillable = result.totalBillable

        self.itemsPurchasedAndBilled = result.Invoiced
        self.totalSpentOnBillables = result.TotalSpentBillable
        self.totalSpent = result.TotalSpent

        self.totalBilled = result.TotalBilled
        self.percentageBilled = (result.TotalBilled / result.TotalSpentBillable)*100
        self.purchasedItems = result.NonBillableList
        self.percentage = (result.Invoiced/result.totalBillable)*100
        self.totalSoldInDollars = result.totalSoldInDollars
        self.totalProfitInDollars = result.totalSoldInDollars - result.TotalSpentBillable
        
        //Fleet
        self.listOfVehicals = try await dataService.getCompanyFleetSnapShot(companyId: companyId)
        self.vehicalCount = try await dataService.getAllVehicalsCount(companyId: companyId)
        

        // Jobs
        self.jobs = try await dataService.getRecentWorkOrders(companyId: companyId)
        self.recentlyFinishedJobs = try await dataService.getRecentlyFinishedCount(companyId: companyId)
        self.openJobs = try await dataService.getAllJobsOpenedCount(companyId: companyId)
        
        //Shopping List Item
        
        self.listOfShoppingListItems = try await dataService.getAllShoppingListItemsSnapShotByCompany(companyId: companyId)
        
        // Equipment
        self.listOfEquipment = try await EquipmentManager.shared.getEquipmentSnapShot(companyId: companyId)

        //DEVELOPER
        
        self.listOfRepairRequests = try await dataService.getAllRepairRequests(companyId: companyId)
//        self.companyUsers = try await CompanyUserManager.shared.getAllCompanyUsers(companyId: companyId)
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        self.isLoading = false
        self.listOfVenders = try await dataService.getAllStores(companyId: companyId)
        self.venderCount = try await dataService.getAllVenderCount(companyId: companyId)

        //Companies
//        let companyAccess = try await dataService.getAllUserAvailableCompanies(userId: userId)
//        var companies:[Company] = []
//        for access in companyAccess {
//            if companyId != access.companyId {
//                let company = try await dataService.getCompany(companyId: access.companyId)
//                companies.append(company)
//            }
//        }
        self.businesses = try await dataService.getAssociatedBusinesses(companyId: companyId)
        
        //SERVICE STOPS
        var typesAndAmount: [String:Int] = [:]
        let stops = try await dataService.getAllServiceStopsBetweenDate(companyId: companyId, startDate: Date().startOfDay(), endDate: Date().endOfDay())
        self.serviceStops = Array(stops.prefix(10))
        for stop in stops {
            
            if typesAndAmount[stop.type] == nil {
                //Does Not have type Yet
                print("Type Not In Dict")
                typesAndAmount[stop.type] = 1
            } else {
                //Un wraps amount
                if let amount = typesAndAmount[stop.type] {
                    typesAndAmount[stop.type] = amount + 1
                } else {
                    typesAndAmount[stop.type] = 1
                }
            }
        }
        print(typesAndAmount)
        self.typesAndAmount = typesAndAmount
        
        //AR
        self.ARInvoiceList = try await dataService.getAccountsReceivableInvoice(companyId: companyId)
        var WorkingARTotal: Int = 0
        var ARCount:Int = 0
        let ARList = try await dataService.getAccountsReceivableInvoice(companyId: companyId)
        for ar in ARList {
            if ar.paymentStatus == .unpaid {
                WorkingARTotal += ar.total
                ARCount += 1
            }
        }
        self.ARTotal = Double(WorkingARTotal)/100
        self.AROutstandingCount = ARCount
        
        //AP
        self.APInvoiceList = try await dataService.getAccountsPayableInvoice(companyId: companyId)
        var WorkingAPTotal: Int = 0
        var APCount:Int = 0
        let APList = try await dataService.getAccountsPayableInvoice(companyId: companyId)
        for ap in APList {
            if ap.paymentStatus == .unpaid {
                
                WorkingAPTotal += ap.total
                APCount += 1
            }
        }
        self.APTotal = Double(WorkingAPTotal)/100
        self.APOutstandingCount = APCount
        let r = try await dataService.getAPOutstandingLateInvoiceCount(companyId: companyId)
        self.APTotalOutstandingLate = r.total
        self.APOutstandingLateCount = r.count
        let s = try await dataService.getAPRecentlyPaidInvoiceCount(companyId: companyId)
        self.APTotalRecentlyPaid = s.total
        self.APRecentlyPaidCount = s.count
    }
}
