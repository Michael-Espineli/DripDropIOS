//
//  EditSubscriptionViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/1/25.
//

import Foundation
import SwiftUI
import StripePaymentSheet
import FirebaseFunctions

@MainActor
final class EditSubscriptionViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var activeSubscriptions:[StripeSubscription] = []
    @Published var newSubscription:StripeSubscription? = nil

    @Published var currentSubscription: CompanySubscription? = nil
    func onLoad(company:Company){
        Task{
            do {
                    //Get Current Subscription
                self.currentSubscription = try await dataService.getCompanySubscription(companyId: company.id)
                self.activeSubscriptions = try await dataService.getActiveSubscriptions(active: true)
            } catch {
                print(error)
            }
        }
    }
    func cancelSubscription(company:Company){
        Task{
            do {
                    //Cancel Subscription
                let data:[String:Any] = [
                    "subscriptionId": "stripeId",
                    "stripeVersion": "2023-10-16",
                ]
                let result = try await Functions.functions().httpsCallable("cancelStripeSubscription").call(data)
                guard let _ = result.data as? [String: Any] else {
                        // Handle error
                    print("Failed to Parse JSON")
                    return
                }
                
            } catch {
                print(error)
            }
        }
    }
    func changeSubscription(company:Company){
        Task{
            do {
                if newSubscription != nil {
                    
                        //Update Subscription
                    let data:[String:Any] = [
                        "subscriptionId": "stripeId",
                        "stripeVersion": "2023-10-16",
                    ]
                    let result = try await Functions.functions().httpsCallable("updateStripeSubscription").call(data)
                    guard let _ = result.data as? [String: Any] else {
                            // Handle error
                        print("Failed to Parse JSON")
                        return
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
