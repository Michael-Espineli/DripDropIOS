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
                    NavigationLink(destination: {
                        TechSignUpView(dataService: dataService)
                    }, label: {
                        VStack{
                            Spacer()
                            Text("Create New Account")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(BlueButtonModifier())
                    })
                    NavigationLink(destination: {
                        RedeemInviteCode(dataService:dataService)//DEVELOPER ADD PAY WALL
                    }, label: {
                        VStack{
                            Spacer()
                            Text("Join Company with invite Code")
                            Spacer()
                            
                        }
                        .frame(maxWidth: .infinity)
                        .modifier(SubmitButtonModifier())
                    })
                        
                    
                }
            }
            .padding()
        }
        .fontDesign(.monospaced)
    }
}
