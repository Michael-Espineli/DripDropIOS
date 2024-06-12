//
//  ServiceStopCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//



import SwiftUI
struct ServiceStopCardViewSmall: View{
    @State var serviceStop: ServiceStop
    
    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            HStack{
                VStack(spacing: 0){
                    HStack{
                        Circle()
                            .fill(serviceStop.finished ? Color.poolGreen : Color.yellow)
                            .frame(width: 50,height:50)
                            .overlay{
                                Image(systemName: serviceStop.typeImage)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                            }
                        Spacer()
                        VStack{
                            HStack{
                                Text(serviceStop.customerName )
                            }
                            HStack{
                                Text(fullDateAndDay(date:serviceStop.serviceDate))
                                    .font(.footnote)
                                
                            }
                            
                            Text("$ " + String(serviceStop.rate ?? 0))
                                .font(.footnote)
                        }
                    }
                    HStack{
                        Spacer()
                        Text("Tech: \(serviceStop.tech ?? "0")")
                            .font(.footnote)
                    }
                }
            }
            .foregroundColor(Color.basicFontText)
            .fontDesign(.monospaced)
        }
    }
}

