//
//  SignUpTypePicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/12/23.
//

import SwiftUI

struct SignUpTypePicker: View {
    @State var signUpType:String = "Company"
    var body: some View {
        VStack {
            Spacer()

            HStack{
                Spacer()

                NavigationLink(destination: {
                    IndustryTypePicker()//DEVELOPER ADD PAY WALL
                    
                }, label: {
                    Text("New Company")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.green)
                        .cornerRadius(10)
                })
                Spacer()

                NavigationLink(destination: {
                    TechSignUpPicker()
                }, label: {
                    Text("Induvidual")
                        .foregroundColor(Color.white)
                        .padding(10)
                        .background(Color.blue)
                        .cornerRadius(10)
                })
                Spacer()

            }
            Spacer()
        }
        
    }
}

