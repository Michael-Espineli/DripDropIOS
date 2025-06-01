//
//  StopDataObservationsView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/5/23.
//

import SwiftUI

struct StopDataObservationsView: View {
    var stop:ServiceStop
    @State var observationOptions:[String] = ["Dirt","No Dirt","Algea","No Algea","Cloudy","Clear","Power Out","Low Water","High Water"]
    @Binding var selectedObservations:[String]
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    @State var input:String = ""
    var body: some View {
        ZStack{
            HStack{
                if selectedObservations.count < 1 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 5)
                } else {
                    Rectangle()
                        .fill(Color.poolGreen)
                        .frame(width: 5)
                }
                VStack{
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack{
                            HStack{
                                Button(action: {
                                    selectedObservations.append(input)
                                    selectedObservations.removeDuplicates()
                                    input = ""
                                }, label: {
                                    Image(systemName: "plus")
                                    
                                })
                                TextField("Custom", text: $input)
                            }
                                .padding(5)
                                .background(Color.gray.opacity(0.5)
                                    .foregroundColor(Color.white)
                                    .cornerRadius(10))
                                                        
                            ForEach(observationOptions,id:\.self){ observation in
                                Button(action: {
                                    selectedObservations.append(observation)
                                    selectedObservations.removeDuplicates()
                                }, label: {
                                    Text("\(observation)")
                                        .foregroundColor(Color.white)
                                        .padding(5)
                                        .background(Color.blue)
                                        .cornerRadius(20)
                                })
                            }
                            
                        }
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
                    LazyVGrid(columns: columns) {
                        ForEach(selectedObservations,id:\.self){ selected in
                            
                            HStack{
                                Button(action: {
                                    selectedObservations.removeAll(where: {$0 == selected})
                                }, label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(Color.white)
                                })
                                Text("\(selected)")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(5)
                            .background(Color.poolGreen)
                            .cornerRadius(20)
                        }
                        //your view with image will come here
                    }
                    .padding(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))

                }
                .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))

            }
            .padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 0))

        }
    }
}
