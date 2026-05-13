//
//  EditSubscriptionView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/1/25.
//

import SwiftUI

struct EditSubscriptionView: View {
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: EditSubscriptionViewModel(dataService: dataService))
    }
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : EditSubscriptionViewModel
 
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                currentSubscriptionDetails
                Rectangle()
                    .frame(height: 1)
                subOptions
            }
        }
        .navigationTitle("Subscription Management")
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(company: currentCompany)
            }
        }
    }
}

#Preview {
    EditSubscriptionView(dataService: MockDataService())
}
extension EditSubscriptionView {
    var currentSubscriptionDetails: some View {
        VStack{
            if let subscription = VM.currentSubscription{
                VStack{
                    HStack{
                        Text("Name: \(subscription.name.rawValue)")
                        Spacer()
                        Text("\(subscription.status)")
                    }
                    Text("\(Double(subscription.price)/100, format: .currency(code: "usd").precision(.fractionLength(2)))")
                    Text("\(subscription.description)")
                }
                VStack{
                    Text("Started: \(fullDate(date: subscription.started))")
                    Text("Last Paid: \(fullDate(date: subscription.lastPaid))")
                }
            }
        }
    }
    var subOptions: some View {
        VStack{
            
            Button(action: {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.cancelSubscription(company: currentCompany)
                    masterDataManager.checkForSubscriptionStatus()
                }
            }, label: {
                Text("Change Subscription")
                    .modifier(SubmitButtonModifier())
            })
            Button(action: {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.cancelSubscription(company: currentCompany)
                    masterDataManager.checkForSubscriptionStatus()
                }
            }, label: {
                Text("Cancel Subscription")
                    .modifier(DeleteButtonModifier())
            })
        }
    }
}
