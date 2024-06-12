//
//  StripeViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/10/24.
//

import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class StripeViewModel:ObservableObject{
    @Published var paymentSheet: PaymentSheet? = nil
    @Published var paymentResult: PaymentSheetResult?
    @Published var customerSheet: CustomerSheet?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String?

    @Published var customerSheetResult: CustomerSheet.CustomerSheetResult?
    func prepareCustomerSheet(stripeId:String) async throws {
        var configuration = CustomerSheet.Configuration()

        // Configure settings for the CustomerSheet here. For example:
        configuration.headerTextForSelectionScreen = "Manage your payment method"
        
        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            let data = [
                "customerId":stripeId,
                "stripeVersion":"2023-10-16",
            ]
            let result = try await Functions.functions().httpsCallable("createEphemeralKey").call(data)
            guard let json = result.data as? [String: Any],
                  let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String else {
              // Handle error
                print("Failed to Parse JSON")
                throw FireBaseRead.unableToRead
            }
            return CustomerEphemeralKey(customerId: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        }, setupIntentClientSecretProvider: {
            let data = [
                "customerId":stripeId,
                "stripeVersion":"2023-10-16",
            ]
            let result = try await Functions.functions().httpsCallable("setUpPaymentIntent").call(data)
            guard let json = result.data as? [String: Any],
                  let paymentIntentClientSecret = json["paymentIntent"] as? String else {
              // Handle error
                print("Failed to Parse JSON")
                throw FireBaseRead.unableToRead
                
            }
            return paymentIntentClientSecret
        })
        self.customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)

    }
    func onCompletion(result: CustomerSheet.CustomerSheetResult) {
      self.customerSheetResult = result
    }
    func preparePaymentSheet(stripeId:String,total:Int) async throws{
        let data:[String:Any] = [
            "customerId":stripeId,
            "stripeVersion":"2023-10-16",
            "total":total
        ]
        print(data)
        let result = try await Functions.functions().httpsCallable("createPaymentIntent").call(data)
        
        guard let json = result.data as? [String: Any],
              let customerId = json["customer"] as? String,
              let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
              let paymentIntentClientSecret = json["paymentIntent"] as? String,
              let publishableKey = json["publishableKey"] as? String else {
          // Handle error
            print("Failed to Parse JSON")
          return
        }
        print("Successfully Parsed JSON")
        STPAPIClient.shared.publishableKey = publishableKey
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Espineli, L.L.C."
        configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment methods
        // that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = false
        print("PaymentSheet")

        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
    }
    func setUpPaymentIntent(stripeId:String) async throws{
        let data:[String:Any] = [
            "customerId":stripeId,
            "stripeVersion":"2023-10-16",
            "total":1000
        ]
        print(data)
        let result = try await Functions.functions().httpsCallable("setUpPaymentIntent").call(data)
        
        guard let json = result.data as? [String: Any],
              let customerId = json["customer"] as? String,
              let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
              let paymentIntentClientSecret = json["setupIntent"] as? String,
              let publishableKey = json["publishableKey"] as? String else {
          // Handle error
            print("Failed to Parse JSON")
          return
        }
        STPAPIClient.shared.publishableKey = publishableKey
        // MARK: Create a PaymentSheet instance
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Espineli, L.L.C."
        configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
        // Set `allowsDelayedPaymentMethods` to true if your business can handle payment methods
        // that complete payment after a delay, like SEPA Debit and Sofort.
        configuration.allowsDelayedPaymentMethods = true
        self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
    }
    func onPaymentCompletion(result: PaymentSheetResult) {
      self.paymentResult = result
            switch result {
            case .completed:
                self.alertMessage = "Payment Completed"
                self.showAlert = true
                print(alertMessage)
            case .failed(let error):
                self.alertMessage = "Payment failed: \(error.localizedDescription)"
                self.showAlert = true
                print(alertMessage)
            case .canceled:
                self.alertMessage = "Payment Canceled"
                self.showAlert = true
                print(alertMessage)
            }
        
    }
}
