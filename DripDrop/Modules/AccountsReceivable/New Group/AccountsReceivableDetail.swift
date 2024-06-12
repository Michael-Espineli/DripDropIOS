//
//  AccountsReceivableDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI

struct AccountsReceivableDetail: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    let invoice: StripeInvoice
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                header
                Divider()
                details
                    .padding(.horizontal,20)
            }
            VStack{
                Spacer()
                payButton
            }
        }
    }
}

#Preview {
    AccountsPayableDetail( invoice: StripeInvoice(id: "", internalIdenifier: "",  senderId: "", senderName: "", receiverId: "", receiverName: "", dateSent: Date(), total: 0, terms: .net15, paymentStatus: .paid, paymentType: .cash,paymentRefrence: "534726", lineItems: []))
}
extension AccountsReceivableDetail {
    var header: some View {
        VStack{
                Text("\(invoice.receiverId)")
                Text("\(invoice.receiverName)")
                Text("\(invoice.senderId)")
                Text("\(invoice.senderName)")
                Text("\(String(invoice.total))")
            
        }
        .padding(.horizontal,20)
        .frame(maxWidth: .infinity)
        .background(Color.poolBlue)
    }
    var details: some View {
        VStack{
                ForEach(invoice.lineItems) { item in
                    HStack{
                        Spacer()
                        Text("\(item.description) - \(String(item.total)) x \(String(item.induvidualCost/100))")
                    }
                }
            
        }
    }
    var payButton: some View {
        Button(action: {
            masterDataManager.paymentSheetType = .invoice
            masterDataManager.showPaymentSheet = true
        }, label:   {
            HStack{
                Text("Pay")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.poolBlue)
            .foregroundColor(Color.basicFontText)
            .clipShape(Capsule())
        })
        .padding(.horizontal,20)
    }
}


