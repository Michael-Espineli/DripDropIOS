//
//  RouteMapViewController.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//

import SwiftUI
import MapKit
struct RouteMapViewController: View {

    let serviceStops:[ServiceStop]
    @State var selectedServiceStop:ServiceStop? = nil
    var body: some View {
        VStack{
            Group{
                if let stop = selectedServiceStop {
                    MapViewControllerRepresentable3(serviceStopList: serviceStops,selectedStop: stop)
                }
            }
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
                                            if serviceStops.first == selectedServiceStop {
                                                selectedServiceStop = serviceStops.last

                                            } else {
                                                if let index = serviceStops.firstIndex(of: selectedServiceStop!) {
                                                    print("Index of \(String(describing: selectedServiceStop)) is \(index)")
                                                    self.selectedServiceStop = serviceStops[index - 1]
                                                    
                                                } else {
                                                    print("\(String(describing: selectedServiceStop?.id)) is not in the list")
                                                }
                                            }
                                        }
                                    }, label: {
                                        Text("Back")
                                            .padding(5)
                                            .foregroundColor(Color.basicFontText)
                                            .background(Color.accentColor)
                                            .cornerRadius(5)
                                    })
//                                    .disabled(serviceStops.first == selectedServiceStop)
                                    Spacer()
                                    Text("\(String((serviceStops.firstIndex(of: selectedServiceStop!) ?? 0) + 1))")
                                    Spacer()
                                    Button(action: {
                                        if selectedServiceStop == nil {
                                            print("Returned")
                                            return
                                            
                                        } else {
                                            if serviceStops.last == selectedServiceStop {
                                                selectedServiceStop = serviceStops.first
                                            } else {
                                                if let index = serviceStops.firstIndex(of: selectedServiceStop!) {
                                                    print("Index of \(String(describing: selectedServiceStop?.id)) is \(index)")
                                                    self.selectedServiceStop = serviceStops[index + 1]
                                                    
                                                } else {
                                                    print("\(String(describing: selectedServiceStop?.id)) is not in the list")
                                                }
                                            }
                                        }
                                    }, label: {
                                        Text("Next")
                                            .padding(5)
                                            .foregroundColor(Color.basicFontText)
                                            .background(Color.accentColor)
                                            .cornerRadius(5)
                                    })
//                                    .disabled(serviceStops.last == selectedServiceStop)
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
                    }
                }

        }
        .task{
            if serviceStops.count != 0 {
                selectedServiceStop = serviceStops.first
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
            return Color.green
        default:
            return Color.gray
        }
    }
}
