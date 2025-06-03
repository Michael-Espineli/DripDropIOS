//
//  SignUpTypePicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI

struct SignUpTypePicker: View {
    @EnvironmentObject var dataService : ProductionDataService

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
        VStack {
            if UIDevice.isIPhone{
                VStack{
                    Spacer()
                    NavigationLink(destination: {
                        IndustryTypePicker(dataService: dataService)//DEVELOPER ADD PAY WALL
                    }, label: {
                        VStack{
                            Spacer()
                            VStack{
                                Text("New Company")
                                Image(systemName: "building.2.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.largeTitle)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.white)
                        .padding(8)
                        .background(Color.poolGreen)
                        .cornerRadius(8)
                        .padding(8)
                    })
                    Spacer()
                    NavigationLink(destination: {
                        TechSignUpPicker()
                    }, label: {
                        VStack{
                            Spacer()
                            VStack{
                                Text("Induvidual")
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.largeTitle)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.white)
                        .padding(8)
                        .background(Color.poolBlue)
                        .cornerRadius(8)
                        .padding(8)
                    })
                    Spacer()
                }
                .padding(8)
            } else {
                HStack{
                    Spacer()
                    NavigationLink(destination: {
                        IndustryTypePicker(dataService: dataService)//DEVELOPER ADD PAY WALL
                    }, label: {
                        VStack{
                            Spacer()
                            VStack{
                                Text("New Company")
                                Image(systemName: "building.2.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.largeTitle)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.white)
                        .padding(8)
                        .background(Color.poolGreen)
                        .cornerRadius(8)
                        .padding(8)
                    })
                    Spacer()
                    NavigationLink(destination: {
                        TechSignUpPicker()
                    }, label: {
                        VStack{
                            Spacer()
                            VStack{
                                Text("Induvidual")
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity)
                            }
                            .font(.largeTitle)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.white)
                        .padding(8)
                        .background(Color.poolBlue)
                        .cornerRadius(8)
                        .padding(8)
                    })
                    Spacer()
                }
            }
            NavigationLink(destination: {
                RedeemInviteCode(dataService:dataService)//DEVELOPER ADD PAY WALL
            }, label: {
                VStack{
                    Text("Redeem Invite Code")
                }
                .foregroundColor(Color.white)
                .padding(8)
                .background(Color.orange)
                .cornerRadius(8)
                .padding(8)
            })
        }
    }
        .fontDesign(.monospaced)
    }
}

