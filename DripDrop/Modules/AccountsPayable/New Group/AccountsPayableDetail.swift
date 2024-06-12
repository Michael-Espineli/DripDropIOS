//
//  AccountsPayableDetail.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//


import SwiftUI
import StripePaymentSheet
import StripePaymentsUI
struct AccountsPayableDetail: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @ObservedObject var stripeVM = StripeViewModel()

    let invoice: StripeInvoice
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
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
                if let paymentSheet = stripeVM.paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: stripeVM.onPaymentCompletion
                    ) {
                        HStack{
                            Text("Pay")
                            Text("$ \(String(format: "%.2f", Double(invoice.total)/100))")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.poolBlue)
                        .foregroundColor(Color.basicFontText)
                        .clipShape(Capsule())
                        .padding(.horizontal,20)
                    }
                } else {
                    HStack{
                        Text("Loading…")
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .foregroundColor(Color.white)
                    .clipShape(Capsule())
                    .padding(.horizontal,20)
                }
  
                
            }
        }
        .alert(stripeVM.alertMessage ?? "", isPresented: $stripeVM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            if let user = masterDataManager.user, let stripeId = user.stripeId {
                do {
//                    try await model.preparePaymentSheet(stripeId: stripeId, total: invoice.total)
                    try await stripeVM.preparePaymentSheet(stripeId: stripeId, total: invoice.total)
                }  catch {
                    print(error)
                }
            }
        }

    }
}

#Preview {
    AccountsPayableDetail( invoice: StripeInvoice(id: "", internalIdenifier: "",  senderId: "", senderName: "", receiverId: "", receiverName: "", dateSent: Date(), total: 0, terms: .net15, paymentStatus: .paid,     paymentType: .cash,
                                                  paymentRefrence: "534726", lineItems: []))
}

extension AccountsPayableDetail {
    var header: some View {
        VStack{
                Text("\(invoice.receiverId)")
                Text("\(invoice.receiverName)")
                Text("\(invoice.senderId)")
                Text("\(invoice.senderName)")
            Text("$ \(String(format: "%.2f", Double(invoice.total)/100))")

        }
        .padding(.horizontal,20)
        .frame(maxWidth: .infinity)
        .background(Color.poolBlue)
    }
    var details: some View {
        VStack{
                ForEach(invoice.lineItems) { item in
                    HStack{
                        Text("\(item.description)")
                        Spacer()
                        Text("- \(String(item.total)) x $ \(String(item.induvidualCost/100))")
                    }
                }
            
        }
    }
}


