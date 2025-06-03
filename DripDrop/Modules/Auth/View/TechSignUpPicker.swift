//
//  TechSignUpPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct TechSignUpPicker: View {
    @State var signUpType:String = "Company"
    @EnvironmentObject var dataService : ProductionDataService

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack {
                if UIDevice.isIPhone {
                    Spacer()
                    
                    HStack{
                        Spacer()
                        
                        NavigationLink(destination: {
                            RedeemInviteCode(dataService:dataService)//DEVELOPER ADD PAY WALL
                        }, label: {
                            VStack{
                                
                                Text("Join Company with invite Code")
                                
                            }
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                            .padding(8)
                        })
                        Spacer()
                        
                        NavigationLink(destination: {
                            TechSignUpView(dataService: dataService)
                        }, label: {
                            VStack{
                                Text("Create New Account")
                            }
                            .foregroundColor(Color.white)
                            .padding(8)
                            .background(Color.poolGreen)
                            .cornerRadius(8)
                            .padding(8)
                        })
                        Spacer()
                        
                    }
                    Spacer()
                } else {
                    Spacer()
                    
                    HStack{
                        Spacer()
                        
                        NavigationLink(destination: {
                            RedeemInviteCode(dataService:dataService)//DEVELOPER ADD PAY WALL
                        }, label: {
                            VStack{
                                Spacer()
                                
                                Text("Join Company with invite Code")
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
                        
                        NavigationLink(destination: {
                            TechSignUpView(dataService: dataService)
                        }, label: {
                            VStack{
                                Spacer()
                                
                                Text("Create New Account")
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
                        
                    }
                    Spacer()
                }
            }
        }
        .fontDesign(.monospaced)
    }
}
