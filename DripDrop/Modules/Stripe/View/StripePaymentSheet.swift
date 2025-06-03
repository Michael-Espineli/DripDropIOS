//
//  StripePaymentSheet.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/25/24.
//

enum PaymentSheetType {
    case invoice
    case manageCards
    case paymentSettings
}
import SwiftUI
import StripePaymentSheet
import SwiftUI
import StripePaymentSheet
struct StripePaymentSheet: View {
    @ObservedObject var model = StripeViewModel()
    @EnvironmentObject var masterDataManager: MasterDataManager

    @State private var showingCustomerSheet = false
    let sheetType: PaymentSheetType
    
    var body: some View {
        ZStack{
            switch sheetType {
            case .invoice:
                if let invoice = masterDataManager.selectedAccountsPayableInvoice {
                    StripeInvoiceView(invoice: invoice)
                }
            case .manageCards:
                PaymentSettings()
            case .paymentSettings:
                PaymentSettings()
            }
        }
    }
}

#Preview {
    StripePaymentSheet( sheetType: .invoice)
}


/*
 //
 //  StripePaymentSheet.swift
 //  ThePoolApp
 //
 //  Created by Michael Espineli on 4/25/24.
 //

 enum PaymentSheetType {
     case invoice
     case manageCards
     case paymentSettings
 }
 struct StripePaymentSheet: View {
     @ObservedObject var model = StripeViewModel()
     @EnvironmentObject var navigationManager: NavigationStateManager
     @State private var showingCustomerSheet = false
     let sheetType: PaymentSheetType
     var body: some View {
         VStack{
             VStack {
                 Text("Payment Sheet")
                 HStack{
                     Spacer()
                     Button(action: {
                         navigationManager.showPaymentSheet = false
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
             if let user = navigationManager.user, let stripeId = user.stripeId {
                 do {
                     try await model.preparePaymentSheet(stripeId: stripeId, total: 1000)
                     
                 }  catch {
                     print(error)
                 }
             }
         }
       }
 }

 #Preview {
     StripePaymentSheet( sheetType: .invoice)
 }
 */
