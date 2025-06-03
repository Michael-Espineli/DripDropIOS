//
//  AccountingViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI
import StripePaymentSheet
import FirebaseFunctions


struct StripeInvoiceLineItems: Identifiable, Codable{
    let id : String
    let itemId : String
    //let name: String
    let description: String
    let induvidualCost:Int //Cents
    let total: Int //Amount - Cents

}
struct StripeInvoice:Identifiable, Codable{
    let id :String
    let internalIdenifier:String
    let senderId: String
    let senderName : String
    let receiverId: String
    let receiverName : String
    let dateSent : Date
    let total:Int //In cents
    let terms : AcountingTermsTypes
    let paymentStatus: InvoiceStatusType
    let paymentType: InvoicePaymentType?
    let paymentRefrence:String
    let paymentDate:Date?
    var lineItems:[StripeInvoiceLineItems]
    // Stripe Id?
}

@MainActor
final class AccountingViewModel:ObservableObject{

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var accountsReceivableInvoices:[StripeInvoice] = []
    @Published private(set) var accountsPayableInvoices:[StripeInvoice] = []

    func uploadNewInvoice(invoice:StripeInvoice) async throws {
        //Create Master Invoice
        
    }
    func getAccountsReceivableInvoices(companyId:String) async throws {
        self.accountsReceivableInvoices = try await dataService.getAccountsReceivableInvoice(companyId: companyId)
    }
    func getAccountsPaymentInvoices(companyId:String) async throws {
        self.accountsPayableInvoices = try await dataService.getAccountsPayableInvoice(companyId: companyId)
    }
}
