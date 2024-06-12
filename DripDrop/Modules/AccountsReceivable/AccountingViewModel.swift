//
//  AccountingViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

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
struct StripeInvoiceLineItems: Identifiable, Codable{
    let id : String
    let itemId : String
    let description: String
    let induvidualCost:Int //Cents
    let total: Int //Amount

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
    let paymentType: InvoicePaymentType
    let paymentRefrence:String
    let lineItems:[StripeInvoiceLineItems]
}
@MainActor
final class AccountingViewModel:ObservableObject{
    @Published private(set) var accountsReceivableInvoices:[StripeInvoice] = []
    @Published private(set) var accountsPaymentInvoices:[StripeInvoice] = []

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func uploadNewInvoice(invoice:StripeInvoice) async throws {
        //Create Master Invoice
        
    }
    func getAccountsReceivableInvoices(companyId:String) async throws {
        self.accountsReceivableInvoices = try await dataService.getAccountsReceivableInvoice(companyId: companyId)
    }
    func getAccountsPaymentInvoices(companyId:String) async throws {
        self.accountsPaymentInvoices = try await dataService.getAccountsPayableInvoice(companyId: companyId)
    }
}
