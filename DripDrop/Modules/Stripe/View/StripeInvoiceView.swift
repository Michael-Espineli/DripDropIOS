//
//  StripeInvoiceView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

import SwiftUI
import StripePaymentSheet
import StripePaymentsUI
struct StripeInvoiceView: View {
    @ObservedObject var model = StripeViewModel()
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager

    @State private var showingCustomerSheet = false
    let invoice : StripeInvoice
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                Text("Payment Sheet")
                HStack{
                    Spacer()
                    Button(action: {
                        masterDataManager.showPaymentSheet = false
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .padding(.horizontal,20)
                if let paymentSheet = model.paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: model.onPaymentCompletion
                    ) {
                        Text("Buy")
                    }
                } else {
                    HStack{
                        Text("Loading…")
                        ProgressView()
                    }
                }
                if let result = model.paymentResult {
                    switch result {
                    case .completed:
                        Text("Payment complete")
                    case .failed(let error):
                        Text("Payment failed: \(error.localizedDescription)")
                    case .canceled:
                        Text("Payment canceled.")
                    }
                }
            }
        }
        .task{
            if let user = masterDataManager.user, let stripeId = user.stripeId {
                do {
//                    try await model.preparePaymentSheet(stripeId: stripeId, total: invoice.total)
                    try await model.setUpPaymentIntent(stripeId: stripeId)
                }  catch {
                    print(error)
                }
            }
        }
    }
}

#Preview {
    StripeInvoiceView(invoice: StripeInvoice(id: "", internalIdenifier: "", senderId: "", senderName: "", receiverId: "", receiverName: "", dateSent: Date(), total: 0, terms: .net15, paymentStatus: .paid,     paymentType: .cash,
                                             paymentRefrence: "534726", lineItems: []))
}
