//
////
////  CustomerMonthlySummaryViewModel.swift
////  BuisnessSide
////
////  Created by Michael Espineli on 12/2/23.
////
//
//import Foundation
//import SwiftUI
//import FirebaseFirestore
//import MapKit
//
//@MainActor
//final class CustomerMonthlySummaryViewModel:ObservableObject{
//    //-------------------------------------------------------
//    //                             Variables
//    //-------------------------------------------------------
//    //SINGLES
//    @Published private(set) var notProfitableMonths: [Date] = []
//    @Published private(set) var summaryOfLast12Months: CustomerMonthlySummary? = nil
//
//    //ARRAYS
//    @Published private(set) var customerMonthlySummary: [CustomerMonthlySummary] = []
//    @Published private(set) var currentMonth: [CustomerMonthlySummary] = []
//    @Published private(set) var previousMonth: [CustomerMonthlySummary] = []
//    @Published private(set) var lastYear: [CustomerMonthlySummary] = []
//    @Published private(set) var allCompanyCurrentProfitablility: [CustomerMonthlySummary] = []
//    @Published private(set) var allCompanyCurrentProfitablilitySearched: [CustomerMonthlySummary] = []
//    //-------------------------------------------------------
//    //                             CREATE
//    //-------------------------------------------------------
//    //-------------------------------------------------------
//    //                             READ
//    //-------------------------------------------------------
//    func filterCustomerPNLSummaryList(filterTerm:String,customersPNL:[CustomerMonthlySummary]) {
//        //very facncy Search Bar
//        
//        var filteredListOfCustomers:[CustomerMonthlySummary] = []
//        for customer in customersPNL {
//            
//            if customer.customerDisplayName.lowercased().contains(filterTerm.lowercased()) {
//                filteredListOfCustomers.append(customer)
//            }
//        }
//        self.allCompanyCurrentProfitablilitySearched = filteredListOfCustomers
//    }
//    func getSummaryOfLastYear(customer: Customer, companyId: String,month:Date) async throws {
//        
//        let last12Months = try await CustomerManager.shared.getSummaryOfLastYear(companyId: companyId, customer: customer,month: month)
//        
//        var monthlyRate = 0
//        var chemicalCost = 0
//        var laborCost = 0
//        var serviceStops = 0
//        var monthCount = 0
//        var serviceStopLocationID = ""
//        var listOfMonths:[Date] = []
//        
//        for month in last12Months {
//            monthlyRate = monthlyRate + Int(month.monthlyRate)
//            chemicalCost = chemicalCost + Int(month.chemicalCost)
//            laborCost = laborCost + Int(month.laborCost)
//            serviceStops = serviceStops + Int(month.serviceStops)
//            monthCount = monthCount + 1
//            serviceStopLocationID = month.serviceLocationId
//            let monthlyLoss = Int(month.chemicalCost) + Int(month.laborCost)
//            if  monthlyLoss > Int(month.monthlyRate) {
//                listOfMonths.append(month.date)
//            }
//        }
//        
//        var monthlyRateSummary = 0
//        var monthlyChemicalCostSummary = 0
//        var monthlyLaborCostSummary = 0
//        var monthlyServiceStopsSummary = 0
//        if monthCount == 0 {
//            monthlyRateSummary = monthlyRate
//            monthlyChemicalCostSummary = chemicalCost
//            monthlyLaborCostSummary = laborCost
//            monthlyServiceStopsSummary = serviceStops
//        } else {
//            monthlyRateSummary = monthlyRate/monthCount// error
//            monthlyChemicalCostSummary = chemicalCost/monthCount
//            monthlyLaborCostSummary = laborCost/monthCount
//            monthlyServiceStopsSummary = serviceStops/monthCount
//        }
//        
//        
//        self.notProfitableMonths = listOfMonths
//        let fullName = (customer.firstName ) + " " + (customer.lastName )
//        self.summaryOfLast12Months = CustomerMonthlySummary(id: UUID().uuidString, date: Date(), customerId: customer.id, customerDisplayName: fullName, serviceLocationId: serviceStopLocationID, monthlyRate: Double(monthlyRateSummary), chemicalCost: Double(monthlyChemicalCostSummary), laborCost: Double(monthlyLaborCostSummary), serviceStops: Double(monthlyServiceStopsSummary))
//    }
//    func getAllCompanyPNL(customers: [Customer], companyId: String,date:Date) async throws {
//        var summaryList:[CustomerMonthlySummary] = []
//        for customer in customers {
//            let specificSummary = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonth(companyId: companyId, customer: customer,month: date)
//            if specificSummary.count > 0 {
//                summaryList.append(specificSummary.first!)
//            }
//        }
//        self.allCompanyCurrentProfitablility = summaryList
//    }
//
//    //-------------------------------------------------------
//    //                             UPDATE
//    //-------------------------------------------------------
//    //-------------------------------------------------------
//    //                             FUNCTIONS
//    //-------------------------------------------------------
//    func getAllCustomerCustomerMonthlySummary(customer: Customer, companyId: String) async throws {
//        
//        self.customerMonthlySummary = try await CustomerManager.shared.getAllCustomerCustomerMonthlySummary(companyId: companyId, customer: customer)
//    }
//    func getMonthlySummaryByCustomerAndCurrentMonth(customer: Customer, companyId: String,month:Date) async throws {
//        
//        self.currentMonth = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonth(companyId: companyId, customer: customer,month: month)
//    }
//    
//    func getMonthlySummaryByCustomerAndPreviousMonth(customer: Customer, companyId: String,month:Date) async throws {
//        
//        self.previousMonth = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonth(companyId: companyId, customer: customer,month: month)
//    }
//    func getMonthlySummaryByCustomerAndLastYear(customer: Customer, companyId: String,month:Date) async throws {
//        
//        self.lastYear = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonth(companyId: companyId, customer: customer,month: month)
//    }
//}
