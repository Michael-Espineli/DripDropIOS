//
//  RouteOverViewListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//

import SwiftUI

struct RouteOverViewListView: View {
    @EnvironmentObject var dataService: ProductionDataService

    let serviceStops:[ServiceStop]
    @State var selectedStopList:[ServiceStop] = []

    @State var enableMove:Bool = false
    @State var confirmMove:Bool = false

    var body: some View {
        ScrollView(showsIndicators: false){
            ForEach(serviceStops) { stop in
                if enableMove {
                    
                    Button(action: {
                        if selectedStopList.contains(stop) {
                            selectedStopList.removeAll(where: {$0.id == stop.id})
                        } else {
                            selectedStopList.append(stop)
                        }
                        
                    }, label: {
                        HStack {
                            if enableMove {
                                if selectedStopList.contains(stop) {
                                    Image(systemName: "checkmark.square")
                                    
                                } else {
                                    Image(systemName: "square")
                                }
                            }
                            ServiceStopCardViewSmall(serviceStop: stop)
                        }
                    })
                    .padding(.horizontal,16)
                    
                    
                } else {
                    NavigationLink(value: Route.serviceStop(serviceStop: stop, dataService: dataService), label: {
                        HStack {
                            if enableMove {
                                if selectedStopList.contains(stop) {
                                    Image(systemName: "checkmark.square")
                                    
                                } else {
                                    Image(systemName: "square")
                                }
                            }
                            ServiceStopCardViewSmall(serviceStop: stop)
                        }
                    })
                    .padding(.horizontal,16)
                }
            }
        }
        .sheet(isPresented: $confirmMove,
               onDismiss: {
            enableMove = false
            selectedStopList = []
        },
               content: {
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        confirmMove = false
                    }, label: {
                        Image(systemName:"xmark")
                    })
                }
                MoveServiceStopsConfirmation(
                    dataService:dataService,
                    selectedServiceStopList: selectedStopList
                )
            }
        })
        .toolbar{
            if enableMove {
                
                Button(action: {
                    enableMove.toggle()
                }, label: {
                    Text("Cancel")
                })
            }
            Button(action: {
                 confirmMove = true
            }, label: {
                Text("Confirm")
            })
        }
    }
}

