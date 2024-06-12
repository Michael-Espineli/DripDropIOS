//
//  RouteMapAllViewController.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//


import SwiftUI
import MapKit
struct RouteMapAllViewController: View {

    let serviceStopDict:[String:[ServiceStop]]
    @State var selectedServiceStop:ServiceStop? = nil
    @State var selectedRoute:String? = nil
    @State var dictKeyList:[String] = []
    var body: some View {
        VStack{
            Group{
                if let stop = selectedServiceStop {
                    RouteOverViewAllMapView(serviceStopDict: serviceStopDict,selectedStop: stop)
                }
            }
                .onAppear{
                    if serviceStopDict.isEmpty {return}
                    selectedRoute = serviceStopDict.keys.first!
                    selectedServiceStop = serviceStopDict.values.first?.first!
                }
            
                .overlay(alignment: .bottom) {
                    VStack {
                        if selectedServiceStop == nil {
                            Text("No Service Stop")
                        } else {
                            
                            VStack{
                                HStack{
                                    Button(action: {
                                        if let selectedRoute = selectedRoute {
                                
                                                if dictKeyList.first == selectedRoute {
                                                    if dictKeyList.count == 0 {
                                                        return
                                                    } else {
                                                        let newSelectedRoute = dictKeyList.last
                                                        if let newSelectedRoute = newSelectedRoute {
                                                            
                                                            self.selectedRoute = newSelectedRoute
                                                            selectedServiceStop = serviceStopDict[newSelectedRoute]?.last
                                                        }
                                                    }
                                                } else {
                                                    if let index = dictKeyList.firstIndex(of: selectedRoute) {
                                                        let newSelectedRoute = dictKeyList[index - 1]
                                                        self.selectedRoute = newSelectedRoute
                                                        selectedServiceStop = serviceStopDict[newSelectedRoute]?.first
                                                        
                                                    } else {
                                                        print("\(selectedRoute) is not in the list")
                                                    }
                                                }
                                            
                                        }
                                    }, label: {
                                        Text("Previous Route")
                                            .padding(5)
                                            .foregroundColor(Color.basicFontText)
                                            .background(Color.accentColor)
                                            .cornerRadius(5)
                                    })
                                    Spacer()
                                    if let selectedRoute = selectedRoute {
                                        
                                        Text("Selected Route: \(selectedRoute)")
                                    }
                                    Spacer()
                                    Button(action: {
                                        if let selectedRoute = selectedRoute {
                                
                                                if dictKeyList.last == selectedRoute {
                                                    if dictKeyList.count == 0 {
                                                        return
                                                    } else {
                                                        let newSelectedRoute = dictKeyList.first
                                                        if let newSelectedRoute = newSelectedRoute {
                                                            
                                                            self.selectedRoute = newSelectedRoute
                                                            
                                                            selectedServiceStop = serviceStopDict[newSelectedRoute]?.first
                                                        }
                                                    }
                                                } else {
                                                    if let index = dictKeyList.firstIndex(of: selectedRoute) {
                                                        let newSelectedRoute = dictKeyList[index + 1]

                                                        self.selectedRoute = newSelectedRoute
                                                        selectedServiceStop = serviceStopDict[newSelectedRoute]?.first

                                                        
                                                    } else {
                                                        print("\(selectedRoute) is not in the list")
                                                    }
                                                }
                                            
                                        }
                                    }, label: {
                                        Text("Next Route")
                                            .padding(5)
                                            .foregroundColor(Color.basicFontText)
                                            .background(Color.accentColor)
                                            .cornerRadius(5)
                                    })
                                }
                                HStack{
                                    Button(action: {
                                        if let selectedRoute = selectedRoute {
                                            if selectedServiceStop == nil {
                                                print("Returned")
                                                return
                                                
                                            } else {
                                                if serviceStopDict[selectedRoute]?.first == selectedServiceStop {
                                                    selectedServiceStop = serviceStopDict[selectedRoute]?.last
                                                    
                                                } else {
                                                    if let index = serviceStopDict[selectedRoute]?.firstIndex(of: selectedServiceStop!) {
                                                        print("Index of \(String(describing: selectedServiceStop)) is \(index)")
                                                        let ss:[ServiceStop] = serviceStopDict[selectedRoute] ?? []
                                                        self.selectedServiceStop = ss[index - 1]
                                                        
                                                    } else {
                                                        print("\(String(describing: selectedServiceStop?.id)) is not in the list")
                                                    }
                                                }
                                            }
                                        }
                                    }, label: {
                                        Text("Previous Stop")
                                            .padding(5)
                                            .foregroundColor(Color.basicFontText)
                                            .background(Color.accentColor)
                                            .cornerRadius(5)
                                    })
//                                    .disabled(serviceStops.first == selectedServiceStop)
                                    Spacer()
                                    if let selectedServiceStop = selectedServiceStop {
                                        
                                        Text("\(selectedServiceStop.customerName)")
                                        
                                        Spacer()
                                        Button(action: {
                                            if let selectedRoute = selectedRoute {
                                                
                                                if selectedServiceStop == nil {
                                                    print("Returned")
                                                    return
                                                    
                                                } else {
                                                    if serviceStopDict[selectedRoute]?.last == selectedServiceStop {
                                                        let ss:[ServiceStop] = serviceStopDict[selectedRoute] ?? []
                                                        if ss.count == 0 {
                                                            return
                                                        } else {
                                                            self.selectedServiceStop = ss.first
                                                        }
                                                    } else {
                                                        if let index = serviceStopDict[selectedRoute]?.firstIndex(of: selectedServiceStop) {
                                                            print("Index of \(String(describing: selectedServiceStop.id)) is \(index)")
                                                            let ss:[ServiceStop] = serviceStopDict[selectedRoute] ?? []
                                                            
                                                            self.selectedServiceStop = ss[index + 1]
                                                            
                                                        } else {
                                                            print("\(String(describing: selectedServiceStop.id)) is not in the list")
                                                        }
                                                    }
                                                }
                                            }
                                        }, label: {
                                            Text("Next Stop")
                                                .padding(5)
                                                .foregroundColor(Color.basicFontText)
                                                .background(Color.accentColor)
                                                .cornerRadius(5)
                                        })
                                    }
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
            if serviceStopDict.count != 0 {
                dictKeyList = []
                selectedServiceStop = serviceStopDict.values.first?.first!
                for dict in serviceStopDict {
                    dictKeyList.append(dict.key)
                }
            } else {
                dictKeyList = []
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
