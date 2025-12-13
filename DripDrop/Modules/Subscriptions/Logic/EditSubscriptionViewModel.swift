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

    @Published var currentSubscription: CompanySubscription? = nil
    func onLoad(company:Company){
        Task{
            do {
                    //Get Current Subscription
                self.currentSubscription = try await dataService.getCompanySubscription(company: company)
                self.subscriptions = try await dataService.getActiveSubscriptions(active: true)
            } catch {
                print(error)
            }
        }
    }
}
