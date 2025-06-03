//
//  CustomerCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/1/23.
//

import SwiftUI
struct CustomerCardViewSmall: View{
    @EnvironmentObject var naviagionManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager


    let customer:Customer
    func checkPercentageFilledOut(customer:Customer) ->(filledOut:Bool,percentage:Double){
        //DEVELOPER Please Change this Name
        //Variables To Return
        var filledOut:Bool = false
        var percentage:Double = 0.5
        //Working Variables
        var sum:Double = 0
        var total:Double = 0
        if customer.firstName != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.lastName != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.email != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.phoneNumber != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.city != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.state != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.streetAddress != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if customer.billingAddress.zip != "" {
            sum = sum + 1
            total = total + 1
        } else {
            total = total + 1
        }
        if sum == total {
            filledOut = true
        }
        return (filledOut:filledOut,percentage:percentage)
    }
    var body: some View{
        ZStack{
            switch masterDataManager.mainScreenDisplayType {
            case .compactList:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 25, height: 25)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                        }
                        Spacer()
                    }
                }
            case .preview:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                        }
                        Spacer()
                    }
                    if !checkPercentageFilledOut(customer: customer).filledOut {
                        ProgressView(value: checkPercentageFilledOut(customer: customer).percentage)
                            .tint(Color.red)
                    }
                }
            case .fullPreview:
                VStack{
                    HStack{
                        VStack{
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        VStack{
                            if customer.displayAsCompany {
                                HStack{
                                    Text(customer.company ?? "No Company Name" )
                                }
                            } else {
                                HStack{
                                    Text(customer.firstName )
                                    Text(customer.lastName )
                                }
                            }
                            HStack{
                                Text(customer.billingAddress.streetAddress)
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                    }
                    if !checkPercentageFilledOut(customer: customer).filledOut {
                        ProgressView(value: checkPercentageFilledOut(customer: customer).percentage)
                            .tint(Color.red)
                    }
                }
            }
            
        }
        .modifier(ListButtonModifier())
    }
}
