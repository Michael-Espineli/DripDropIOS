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
                            .fill(serviceStop.operationStatus == .finished ? Color.poolGreen : Color.yellow)
                            .frame(width: 50,height:50)
                            .overlay{
                                Image(systemName: serviceStop.typeImage)
                                    .resizable()
                                    .frame(width: 30, height: 30)
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
                        }
                    }
                    HStack{
                        Spacer()
                        Text("Tech: \(serviceStop.tech)")
                            .font(.footnote)
                    }
                }
            }
            .foregroundColor(Color.basicFontText)
            .fontDesign(.monospaced)
        }
    }
}

