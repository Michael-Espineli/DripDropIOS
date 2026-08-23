//
//  SubscriptionPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/8/25.
//
// Pay Wall
import SwiftUI
import StripePaymentSheet
import StripePaymentsUI

struct SubscriptionPicker: View {
    init( dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: SubscriptionPickerViewModel(dataService: dataService))
    }
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject private var VM : SubscriptionPickerViewModel
 
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                Text("Subscriptions")
                
                if let paymentSheet = VM.paymentSheet, let subscription = VM.selectedSubscription{
                    HStack{
                        Button(action: {
                            VM.deselectSubscription()
                        }, label: {
                            Text("Cancel")
                                .modifier(DismissButtonModifier())
                        })
                        Spacer()
                    }
                    Button {
                        VM.isPaymentSheetPresented = true
                    } label: {
                        Text("Subscribe to \(subscription.name.rawValue)")
                            .frame(maxWidth: .infinity)
                            .modifier(AddButtonModifier())
                            .padding(.horizontal,16)
                    }.paymentSheet(isPresented: $VM.isPaymentSheetPresented, paymentSheet: paymentSheet) { result in
                        switch result {
                        case .completed:
                            if let subscription = VM.selectedSubscription,let user = masterDataManager.user, let company = masterDataManager.currentCompany{
                                VM.alertMessage = "Completed"
                                VM.showAlert = true
                                VM.createCompanySubscription(
                                    subscription: subscription,
                                    user: user,
                                    company: company
                                )
                                masterDataManager.checkForSubscriptionStatus()
                            }
                            
                            break
                            // Handle completion
                        case .canceled:
                            VM.alertMessage = "Canceled"
                            VM.showAlert = true
                            break
                        case .failed(let error):
                            print("Failed to pay: \(error.localizedDescription)")
                            VM.alertMessage = error.localizedDescription
                            VM.showAlert = true
                            break
                            // Handle error
                        }
                    }
                    VStack{
                        Text("Additional Details")
                        Divider()
                        ForEach(subscription.featureSet, id:\.self){ feature in
                            Text(feature)
                        }
                    }
                    
                } else {
                    if let sub = VM.selectedSubscription,let user = masterDataManager.user, let company = masterDataManager.currentCompany {
                        if sub.name == .free {
                            VStack{
                                HStack{
                                    Button(action: {
                                        VM.deselectSubscription()
                                    }, label: {
                                        Text("Cancel")
                                            .modifier(DismissButtonModifier())
                                    })
                                    Spacer()
                                }
                                
                                Button(action: {
                                    VM.createCompanySubscription(subscription: sub, user: user, company: company)
                                    masterDataManager.checkForSubscriptionStatus()
                                }, label: {
                                    HStack{
                                        Text("Subscribe to \(sub.name.rawValue)")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .modifier(AddButtonModifier())
                                    .padding(.horizontal,16)
                                })
                                
                                VStack{
                                    Text("Additional Details")
                                    Divider()
                                    ForEach(sub.featureSet, id:\.self){ feature in
                                        Text(feature)
                                    }
                                }
                            }
                            
                        } else {
                            VStack{
                                HStack{
                                    Button(action: {
                                        VM.deselectSubscription() 
                                    }, label: {
                                        Text("Cancel")
                                            .modifier(DismissButtonModifier())
                                    })
                                    Spacer()
                                }
                                HStack{
                                    Text("Loading \(sub.name.rawValue) Details...")
                                    ProgressView()
                                }
                                .frame(maxWidth: .infinity)
                                .modifier(AddButtonModifier())
                                .padding(.horizontal,16)
                                
                                VStack{
                                    Text("Additional Details")
                                    Divider()
                                    ForEach(sub.featureSet, id:\.self){ feature in
                                        Text(feature)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(VM.subscriptions){ subscription in
                            VStack{
                                HStack{
                                    Text(subscription.name.rawValue)
                                        .bold()
                                        Spacer()
                                    Text("\(Double(subscription.price)/100, format: .currency(code: "usd").precision(.fractionLength(2)))")
                                }
                                Text(subscription.description)
                                    .font(.caption)
                                    .padding(.vertical,8)
                                HStack{
//                                    Button(action: {
//                                        VM.detailedSub = subscription
//                                    }, label: {
//                                        Text("More Details")
//                                    })
                                    Spacer()
                                    Button(action: {
                                            Task{
                                                do {
                                                    print("Get Subscription Payment Intent 1 ")
                                                    VM.selectedSubscription = subscription
                                                    if let company = masterDataManager.currentCompany, let stripeId = company.stripeId, let subscription = VM.selectedSubscription {
                                                        try await VM.preparePaymentSheet(stripeId: stripeId, companyId: company.id, subscription: subscription)
                                                    }
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                    }, label: {
                                        Text("Sign up")
                                            .modifier(GreenCardModifier())
                                    })
                                }
                            }
                            .modifier(BasicCardModifier())
                        }
                    }
                }
            }
            .padding(8)
        }
        .task{
            do {
                try await VM.onLoad()
            } catch {
                print(error)
            }
        }
        .fontDesign(.monospaced)
        .toolbar{
            ToolbarItem{
                Button(action: {
                    
                }, label: {
                    Text("Next")
                        .modifier(AddButtonModifier())
                })
                .disabled(VM.selectedSubscription == nil)
                .opacity(VM.selectedSubscription == nil ? 0.5 : 1.0)
            }
        }
        .alert(VM.alertMessage ?? "", isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    SubscriptionPicker(dataService: ProductionDataService())
}
