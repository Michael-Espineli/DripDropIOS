//
//  PaymentCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct PaymentCardView : View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    let invoice: StripeInvoice
    var body: some View {
        VStack{
            if let currentCompany = masterDataManager.currentCompany {
                if invoice.receiverId == currentCompany.id {
                    HStack{
                        Text("\(invoice.senderName)")
                    }
                } else if invoice.senderId == currentCompany.id {
                    HStack{
                        Text("\(invoice.receiverName)")
                    }
                }
            }
            HStack{
                Text("\(invoice.paymentStatus.rawValue)")
                    .modifier(YellowButtonModifier())
                Spacer()
                Text("\(invoice.total/100, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            HStack{
                Text("Sent: \(shortDate(date: invoice.dateSent))")
                Spacer()
                Text("\(invoice.terms.rawValue)")

            }
            
            HStack{
                switch invoice.terms {
                case .net15:
                    Text("Due: \(shortDate(date: Calendar.current.date(byAdding: .day, value: +15, to: invoice.dateSent)!))")
                case .net30:
                    Text("Due: \(shortDate(date: Calendar.current.date(byAdding: .day, value: +30, to: invoice.dateSent)!))")
                case .net45:
                        Text("Due: \(shortDate(date: Calendar.current.date(byAdding: .day, value: +45, to: invoice.dateSent)!))")
                case .net60:
                        Text("Due: \(shortDate(date: Calendar.current.date(byAdding: .day, value: +60, to: invoice.dateSent)!))")
                }
                Spacer()
                switch invoice.terms {
                case .net15:
                    if Calendar.current.date(byAdding: .day, value: +15, to: invoice.dateSent)! > Date() {
                        HStack{
                            Text("Due")
                            
                            Text("(\(String(daysBetween(start: Date(), end: Calendar.current.date(byAdding: .day, value: +15, to: invoice.dateSent)!))) Days )")
                        }
                        .modifier(YellowButtonModifier())
                    }  else {
                        Text("Over Due")
                            .modifier(DismissButtonModifier())
                        Text("(\(String(daysBetween(start: Calendar.current.date(byAdding: .day, value: +15, to: invoice.dateSent)!, end: Date()))))")
                            .font(.footnote)
                    }
                case .net30:
                    if Calendar.current.date(byAdding: .day, value: +30, to: invoice.dateSent)! > Date() {
                        HStack{
                            Text("Due")
                            Text("(\(String(daysBetween(start: Date(), end: Calendar.current.date(byAdding: .day, value: +30, to: invoice.dateSent)!))) Days )")
                        }
                        .modifier(YellowButtonModifier())
                    }  else {
                        Text("Over Due")
                            .modifier(DismissButtonModifier())
                        Text("(\(String(daysBetween(start: Calendar.current.date(byAdding: .day, value: +30, to: invoice.dateSent)!, end: Date()))))")
                            .font(.footnote)
                    }
                case .net45:
                    if Calendar.current.date(byAdding: .day, value: +45, to: invoice.dateSent)! > Date() {
                        HStack{
                            Text("Due")
                            Text("(\(String(daysBetween(start: Date(), end: Calendar.current.date(byAdding: .day, value: +45, to: invoice.dateSent)!))) Days )")
                        }
                        .modifier(YellowButtonModifier())
                    }  else {
                        Text("Over Due")
                            .modifier(DismissButtonModifier())
                        Text("(\(String(daysBetween(start: Calendar.current.date(byAdding: .day, value: +45, to: invoice.dateSent)!, end: Date()))))")
                            .font(.footnote)
                    }
                case .net60:
                    if Calendar.current.date(byAdding: .day, value: +60, to: invoice.dateSent)! > Date() {
                        HStack{
                            Text("Due")
                            Text("(\(String(daysBetween(start: Date(), end: Calendar.current.date(byAdding: .day, value: +60, to: invoice.dateSent)!))) Days )")
                        }
                        .modifier(YellowButtonModifier())
                    }  else {
                        Text("Over Due")
                            .modifier(DismissButtonModifier())
                        Text("(\(String(daysBetween(start: Calendar.current.date(byAdding: .day, value: +60, to: invoice.dateSent)!, end: Date()))))")
                            .font(.footnote)
                    }
                }
            }
        }
        .modifier(ListButtonModifier())
        .padding(8)
    }
}
//#Preview {
//    PaymentCardView(invoice: StripeInvoice(
//        id: UUID().uuidString,
//        internalIdenifier: "", 
//        senderId: UUID().uuidString,
//        senderName: "Michael Maziuss",
//        receiverId: UUID().uuidString,
//        receiverName: "Murdock Pool Service",
//        dateSent: Date(),
//        total: 1_000_00,
//        terms: .net15,
//        paymentStatus: .paid,
//        paymentType: .cash,
//        paymentRefrence: "534726",
//        lineItems: [
//            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
//            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
//            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
//            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
//
//        ]
//    ))
//}
