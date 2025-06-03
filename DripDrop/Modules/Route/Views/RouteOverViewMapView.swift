//
//  RouteOverViewMapView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//

import SwiftUI
import MapKit

struct RouteOverViewMapView: View {
    let serviceStops:[ServiceStop]
    @State var selectedServiceStop:ServiceStop? = nil
    var body: some View {
        Map(coordinateRegion: .constant(.init(center: .init(latitude: serviceStops.first!.address.latitude,
                                                            longitude: serviceStops.first!.address.longitude),
                                              latitudinalMeters: 10000,
                                              longitudinalMeters: 10000)),
            annotationItems: serviceStops) { item in
            
            MapMarker(coordinate: .init(latitude: item.address.latitude,
                                        longitude: item.address.longitude),
                      tint: item.operationStatus == .finished ? Color.red : Color.poolGreen)
        }
        
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
#if os(iOS)
            .toolbar(.hidden, for: .tabBar)
            .toolbar(.hidden, for: .navigationBar)
#endif
            .onAppear{
                if serviceStops.isEmpty {return}
                selectedServiceStop = serviceStops.first!
            }
            .overlay(alignment: .bottom) {
                VStack {
                    if selectedServiceStop == nil {
                        Text("No Service Stop")
                    } else {
                        
                        VStack{
                            HStack{
                                Button(action: {
                                    if selectedServiceStop == nil {
                                        print("Returned")
                                        return
                                        
                                    } else {
                                        if let index = serviceStops.firstIndex(of: selectedServiceStop!) {
                                            print("Index of \(String(describing: selectedServiceStop)) is \(index)")
                                            self.selectedServiceStop = serviceStops[index - 1]
                                            
                                        } else {
                                            print("\(String(describing: selectedServiceStop)) is not in the list")
                                        }
                                    }
                                }, label: {
                                    Text("Back")
                                })
                                Spacer()
                                Button(action: {
                                    if selectedServiceStop == nil {
                                        print("Returned")
                                        return
                                        
                                    } else {
                                        if let index = serviceStops.firstIndex(of: selectedServiceStop!) {
                                            print("Index of \(String(describing: selectedServiceStop)) is \(index)")
                                            self.selectedServiceStop = serviceStops[index + 1]
                                            
                                        } else {
                                            print("\(String(describing: selectedServiceStop)) is not in the list")
                                        }
                                    }
                                }, label: {
                                    Text("Next")
                                })
                            }
                            HStack{
                                Text("Client: \(selectedServiceStop?.customerName ?? "")")
                                Text("Duration: 0:42")
                            }
                            HStack{
                                Text("Status: ")
                                let status = "Traveling"//statusList.randomElement() ?? ""
                                Text("\(status)")
                                    .padding(5)
                                    .background(getColor(status: status))
                                    .cornerRadius(5)
                                Text("Duration: \(displayNumberAsMinAndHourAndSecond(seconds:69420))")
                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(Color.gray)
                        .cornerRadius(10)
                        .padding(10)
                    }
                    HStack{
                        Group {
                            Button("Back to Menu") {
                                //                            routeManager.reset()
                            }
                            
                            Button("Back to Locations") {
                                //                            routeManager.goBack()
                            }
                        }
                    }
                    .padding()
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                }
            }
    }
    func getColor(status:String)->Color{
        switch status {
        case "In Progress":
            return Color.yellow
        case "Did Not Start":
            return Color.basicFontText.opacity(0.5)
        case "Traveling":
            return Color.blue
        case "Break":
            return Color.purple
        case "Finished":
            return Color.poolGreen
        default:
            return Color.gray
        }
    }

}

