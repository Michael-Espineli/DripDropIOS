//
//  PaymentCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct PaymentCardView : View {
    let invoice: StripeInvoice
    var body: some View {
        VStack{
            HStack{
                Text("\(invoice.receiverId)")
            }
            HStack{
                Text("\(invoice.paymentStatus)")
                Spacer()
                Text("\(invoice.total)")
            }
        }
    }
}
#Preview {
    PaymentCardView(invoice: StripeInvoice(
        id: UUID().uuidString,
        internalIdenifier: "", 
        senderId: UUID().uuidString,
        senderName: "Michael Maziuss",
        receiverId: UUID().uuidString,
        receiverName: "Murdock Pool Service",
        dateSent: Date(),
        total: 1_000_00,
        terms: .net15,
        paymentStatus: .paid,
        paymentType: .cash,
        paymentRefrence: "534726",
        lineItems: [
            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
            StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)

        ]
    ))
}
