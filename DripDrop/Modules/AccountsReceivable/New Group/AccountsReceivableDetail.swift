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
                details
                    .padding(8)
                Text("d")
                    .foregroundColor(.clear)
                    .padding(8)
            }
            VStack{
                Spacer()
                payButton
            }
        }
    }
    func sendReminder() async throws {
        print("Developer Please Send Reminder, Either Call Function ")
      }
}

#Preview {
    AccountsPayableDetail(
        invoice: StripeInvoice(
            id: "",
            internalIdenifier: "",
            senderId: "",
            senderName: "",
            receiverId: "",
            receiverName: "",
            dateSent: Date(),
            total: 0,
            terms: .net15,
            paymentStatus: .paid,
            paymentType: .cash,
            paymentRefrence: "534726",
            paymentDate: nil,
            lineItems: []
        )
    )
}
extension AccountsReceivableDetail {
    var header: some View {
        VStack{
            HStack{
                Text("To:")
                    .bold()
                Text("\(invoice.receiverName)")
                Spacer()
            }
            HStack{
                Text("Rate:")
                    .bold()
                Text("\(Double(invoice.total)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                Spacer()
            }
            HStack{
                Text("Sent:")
                    .bold()
                Text(shortDate(date: invoice.dateSent))
                Spacer()
            }
            HStack{
                if invoice.paymentStatus == .unpaid {
                    
                    Text("Due:")
                        .bold()
                    switch invoice.terms {
                    case .net15:
                        Text("\(shortDate(date: Calendar.current.date(byAdding: .day, value: +15, to: invoice.dateSent)!))")
                    case .net30:
                        Text("\(shortDate(date: Calendar.current.date(byAdding: .day, value: +30, to: invoice.dateSent)!))")
                    case .net45:
                        Text("\(shortDate(date: Calendar.current.date(byAdding: .day, value: +45, to: invoice.dateSent)!))")
                    case .net60:
                        Text("\(shortDate(date: Calendar.current.date(byAdding: .day, value: +60, to: invoice.dateSent)!))")
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
                } else {
                    if let paymentType = invoice.paymentType {
                        Text("Payment Info: \(invoice.paymentStatus.rawValue) on \(shortDate(date: invoice.paymentDate)) with \(paymentType.rawValue)")
                    }
                }
            }
        }
        .padding(8)
        .padding(.horizontal,8)
        .frame(maxWidth: .infinity)
        .background(Color.poolBlue.opacity(0.75))
    }
    var details: some View {
        VStack{
            Text("Line Items")
                .font(.headline)
            Rectangle()
                .frame(height: 1)
            ForEach(invoice.lineItems) { item in
                VStack(alignment:.leading){
                    HStack{
                        Text("\(item.description)")
                        Spacer()
                    }
                    .lineLimit(1)
                    Text("\(String(item.total/item.induvidualCost)) x \(Double(item.induvidualCost)/100, format: .currency(code: "USD").precision(.fractionLength(2))) = \(Double(item.total)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")

                }
                Divider()
            }
            
        }
    }
    var payButton: some View {
        Button(action: {
            Task{
                do {
                    try await sendReminder()
                } catch {
                    print(error)
                }
            }
        }, label:   {
            HStack{
                Text("Send Reminder")
            }
            .frame(maxWidth: .infinity)
            .modifier(AddButtonModifier())
        })
        .padding(.horizontal,16)
    }
}


