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
        VStack {
            Spacer()

            HStack{
                Spacer()

                NavigationLink(destination: {
                    RedeemInviteCode(dataService:dataService)//DEVELOPER ADD PAY WALL
                }, label: {
                    Text("Join Company with invite Code")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
                Spacer()

                NavigationLink(destination: {
                    TechSignUpView(dataService: dataService)
                }, label: {
                    Text("Create New Account")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.green)
                        .cornerRadius(10)
                })
                Spacer()

            }
            Spacer()
        }

        
    }
}
