//
//  SubscriptionPickerViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/8/25.
//

import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class SubscriptionPickerViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var subscriptions:[StripeSubscription] = []
    @Published var selectedSubscription:StripeSubscription? = nil
    @Published var paymentSheet: PaymentSheet? = nil
    @Published var paymentResult: PaymentSheetResult?
    @Published var customerSheet: CustomerSheet?
    @Published var isPaymentSheetPresented: Bool = false
    @Published var subscriptionId: String? = nil
    
    @Published var detailedSub:StripeSubscription? = nil
    
    @Published var showAlert: Bool = false
    @Published var alertMessage: String?
    func onLoad() async throws {
        // Get subscriptions
        self.subscriptions = try await dataService.getActiveSubscriptions(active: true)
        self.subscriptions = subscriptions.sorted { $0.price < $1.price }
        // Get Information On Subscriptions
    }
    
    func deselectSubscription(){
        self.selectedSubscription = nil
        self.paymentSheet = nil
    }
    func preparePaymentSheet(stripeId:String,subscription:StripeSubscription) async throws{
        if subscription.name != .free{
            print("--preparePaymentSheet--")
            let data:[String:Any] = [
                "customerId": stripeId,
                "stripeVersion": "2023-10-16",
                "priceId": subscription.stripePriceId
            ]
            print(data)
            let result = try await Functions.functions().httpsCallable("createSubscriptionPaymentIntent").call(data)
            print(result)
            guard let json = result.data as? [String: Any],
                  let subscriptionId = json["subscriptionId"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let clientSecret = json["clientSecret"] as? String else {
                    // Handle error
                print("Failed to Parse JSON")
                return
            }
            
            print("Successfully Parsed JSON")
            STPAPIClient.shared.publishableKey = publishableKey
            
            var configuration = PaymentSheet.Configuration()
            configuration.allowsDelayedPaymentMethods = false
                //        configuration.primaryButtonLabel = "Subscribe"
            configuration.primaryButtonLabel = "Subscribe \(Double(subscription.price)/100) /Month"
            
            configuration.merchantDisplayName = "Espineli, L.L.C."
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
            self.subscriptionId = subscriptionId
            print("Payment Sheet Finished Setting Up")
        } else {
            print("do not prepare payment sheet")
        }
    }
    
    func onPaymentCompletion(
        result: PaymentSheetResult
    ) {
        Task{
            self.paymentResult = result
            switch result {
            case .completed:
                self.alertMessage = "Payment Completed"
                self.showAlert = true
            case .failed(let error):
                self.alertMessage = "Payment failed: \(error.localizedDescription)"
                self.showAlert = true
            case .canceled:
                self.alertMessage = "Payment Canceled"
                self.showAlert = true
            }
        }
        
    }
    
    
    func createCompanySubscription(
        subscription:StripeSubscription,
        user:DBUser,
        company:Company
    ){
        
        Task{
            do {
                print("Creating Company Subscription")
                if let subscriptionId {
                    let companySub = CompanySubscription(
                        id: UUID().uuidString,
                        description: subscription.description,
                        dripDropSubscriptionId: subscription.id,
                        name: subscription.name,
                        price: subscription.price,
                        started: Date(),
                        status: "Active",
                        stripeCustomerId: "",
                        stripePriceId: subscription.stripePriceId,
                        stripeProductId: subscription.stripeProductId,
                        stripeSubscriptionId: subscriptionId,
                        userId: user.id
                    )
                    print("companySub")
                    print(companySub)
                    try await dataService.createCompanySubscription(subscription: companySub, company: company)
                } else {
                    if subscription.name == .free {
                        let companySub = CompanySubscription(
                            id: UUID().uuidString,
                            description: subscription.description,
                            dripDropSubscriptionId: subscription.id,
                            name: subscription.name,
                            price: subscription.price,
                            started: Date(),
                            status: "Active",
                            stripeCustomerId: "",
                            stripePriceId: "",
                            stripeProductId: "",
                            stripeSubscriptionId: "",
                            userId: user.id
                        )
                        print("user Company Sub Free")
                        print(companySub)
                        try await dataService.createCompanySubscription(subscription: companySub, company: company)
                    } else {
                        print("Should Not Happen: SubscriptionPickerViewModel")
                    }
                }
            } catch {
                print("Error creating subscription")
                print(error)
            }
        }
    }
}
