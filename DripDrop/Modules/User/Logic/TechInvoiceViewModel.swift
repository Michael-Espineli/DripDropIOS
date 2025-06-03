//
//  TechInvoiceViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/2/24.
//

import Foundation

@MainActor
final class TechInvoiceViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var serviceStops:[ServiceStop] = []
    @Published private(set) var jobTemplates:[JobTemplate] = []
    @Published var companyUser : CompanyUser? = nil
    @Published var rateSheetList: [RateSheet] = []
    @Published private(set) var invoiceTotal: Double? = nil
    @Published private(set) var purchaseTotal: Double? = nil
    @Published var stripeLineItems: [StripeInvoiceLineItems] = []

    func onInitialLoad(companyId:String,userId:String,startDate:Date,endDate:Date) async throws{
        self.serviceStops = try await dataService.getAllServiceStopsBetweenDateByUserId(companyId: companyId, startDate: startDate, endDate: endDate, userId: userId)
        print("- Got Service Stops")
        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
        print("- Got Job Templates")

        let companyUser = try await CompanyUserManager.shared.getCompanyUserByDBUserId(companyId: companyId, userId: userId)
        self.companyUser = companyUser
        print("- Got Company User")

       let rateSheetList = try await CompanyUserManager.shared.getAllRateSheetByCompanyUserId(companyId: companyId, companyUserId: companyUser.id)
        self.rateSheetList = rateSheetList
        print("- Rate Sheet List")

        //Summary
        
        var invoiceDick:[String:StripeInvoiceLineItems] = [:]
            var purchaseTotal:Double = 0
            var invoiceTotal:Double = 0
            for stop in serviceStops {
                //DEVELOPER MAKE SURE TO GET ACTIVE AMOUNT
                print("- Service Stop >> \(stop.id)")
                
                if let rateSheet = rateSheetList.first(where: {$0.templateId == stop.typeId}) {
                    if invoiceDick[stop.typeId] == nil {
                        //Add New
                        invoiceTotal += rateSheet.rate
                        let invoice = StripeInvoiceLineItems(
                            id: UUID().uuidString,
                            itemId: stop.typeId,
                            description: stop.type,
                            induvidualCost: Int(rateSheet.rate),
                            total: 1
                        )
                        invoiceDick[stop.typeId] = invoice
                    } else {
                        //Update
                        invoiceTotal += rateSheet.rate
                        var invoice = invoiceDick[stop.typeId]!
                        let newInvoice = StripeInvoiceLineItems(
                            id: UUID().uuidString,
                            itemId: stop.typeId,
                            description: stop.type,
                            induvidualCost: Int(rateSheet.rate),
                            total: invoice.total + 1
                        )
                        invoiceDick[stop.typeId] = newInvoice
                    }
                  
                } else {
                    print("No Rate Sheet For Service Stop")
                }
                
            }
            var stripeInvoices:[StripeInvoiceLineItems] = []
            for invoice in invoiceDick {
                stripeInvoices.append(invoice.value)
            }
            self.stripeLineItems = stripeInvoices
            self.purchaseTotal = purchaseTotal
            self.invoiceTotal = invoiceTotal
        
    }
    func sendInvoice(companyId:String,invoice:StripeInvoice) async throws {
        print("Figure Out Invoice Logic")
    }
    
}
