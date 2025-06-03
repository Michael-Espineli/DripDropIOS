//
//  ServiceStopCardViewLarge.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//


import SwiftUI
struct ServiceStopCardViewLarge: View{
    @State var serviceStop: ServiceStop
    
    var body: some View{
        ZStack{
            HStack{
                VStack(spacing: 0){
                    HStack{
                            Image(systemName: serviceStop.typeImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                        VStack{
                            HStack{
                                Text(serviceStop.customerName )
                            }
                            HStack{
                                Text(fullDateAndDay(date:serviceStop.serviceDate))
                                    .font(.footnote)
                                
                            }
                        }
                            Spacer()
                            Image(systemName: "chevron.compact.right")
                        
                    }
                    
                    HStack{
                        Spacer()
                        Text("Tech: \(serviceStop.tech ?? "0")")
                            .font(.footnote)
                        
                    }
                }
            }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            .background(Color.gray.opacity(0.5))
            .cornerRadius(10)
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
        }
    }
}

