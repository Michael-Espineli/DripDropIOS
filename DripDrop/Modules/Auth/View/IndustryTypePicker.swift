//
//  IndustryTypePicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct IndustryTypePicker: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var dataService : ProductionDataService

    @State var signUpType:String = "Company"
    var body: some View {
        ZStack{
            ScrollView{
                VStack {
                    HStack{
                        Spacer()
                        NavigationLink(destination: {
                            SignUpView(dataService:dataService)//DEVELOPER ADD PAY WALL
                            
                        }, label: {
                            Text("Next")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.accentColor)
                                .cornerRadius(5)
                        })
                    }
                    .padding(10)
                    Button(action: {
                        
                    }, label: {
                        Text("Pool Cleaning")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .foregroundColor(Color.white)
                    })
                    Button(action: {
                        
                    }, label: {
                        Text("Equipment Repairs")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .foregroundColor(Color.white)
                    })
                    Button(action: {
                        
                    }, label: {
                        Text("Leak Detection")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .foregroundColor(Color.white)
                    })
                    Button(action: {
                        
                    }, label: {
                        Text("Pool Building")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .foregroundColor(Color.white)
                    })
                    Spacer()
                    
                    Spacer()
                }
            }
        }
        
    }
}
