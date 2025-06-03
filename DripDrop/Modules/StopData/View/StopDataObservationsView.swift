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
    
    @Binding var stopData:StopData
    
    let columns = [
        GridItem(.adaptive(minimum: 100))
    ]
    @State var input:String = ""
    var body: some View {
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
                HStack{
                    TextField("Custom", text: $input)
                        .modifier(TextFieldModifier())
                    Button(action: {
                        if input != "" {
                            stopData.observation.append(input)
                            stopData.observation.removeDuplicates()
                            input = ""
                        }
                    }, label: {
                        Image(systemName: "plus")
                        
                    })
                }
                .modifier(ListButtonModifier())
                .modifier(OutLineButtonModifier())
                
                LazyVGrid(columns: columns) {
                    ForEach(observationOptions,id:\.self){ observation in
                        Button(action: {
                            if stopData.observation.contains(observation) {
                                stopData.observation.removeAll(where: {$0 == observation})
                            } else {
                                stopData.observation.append(observation)
                                stopData.observation.removeDuplicates()
                            }
                        }, label: {
                            
                            if stopData.observation.contains(observation) {
                                Text("\(observation)")
                                    .modifier(SubmitButtonModifier())
                            } else {
                                Text("\(observation)")
                                    .modifier(ListButtonModifier())
                            }
                        })
                    }
                    ForEach(stopData.observation, id:\.self){ observation in
                        if !observationOptions.contains(where: {$0 == observation}) {
                            Button(action: {
                                if stopData.observation.contains(observation) {
                                    stopData.observation.removeAll(where: {$0 == observation})
                                }
                            }, label: {
                                Text("\(observation)")
                                    .modifier(SubmitButtonModifier())
                            })
                        }
                    }
                }
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 0))
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16))
        }
    }
}
