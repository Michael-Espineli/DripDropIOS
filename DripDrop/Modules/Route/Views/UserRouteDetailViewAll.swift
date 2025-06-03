//
//  UserRouteDetailViewAll.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI
import MapKit
struct UserRouteDetailViewAll: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

init(dataService:any ProductionDataServiceProtocol,activeRoute:[ActiveRoute]){
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService : dataService))
        _activeRoutes = State(wrappedValue: activeRoute)
    }
    @StateObject var serviceStopVM : ServiceStopsViewModel
    //received Variables
    @State var activeRoutes : [ActiveRoute]
    
    @State var serviceStopDict:[String:[ServiceStop]] = [:]
    @State var selectedServiceStop:ServiceStop? = nil
    @State var selected:String = "Map"
    @State var isLoading:Bool = true
    var body: some View {
        VStack{
            if isLoading {
                ProgressView()
            }
            
              else {
                if serviceStopDict.isEmpty {
                    VStack{
                        Text("No Stops")
                    }
                } else {
                    Picker("Type", selection: $selected) {
                        Text("List").tag("List")
                        Text("Map").tag("Map")
                    }
                    .pickerStyle(.segmented)
                    if isLoading {
                        ProgressView()
                    } else {
                        switch selected {
         
                        case "Map":
                            RouteMapAllViewController(serviceStopDict: serviceStopDict)
                            //                    RouteOverViewMapView(serviceStops: serviceStops)
                        default:
                            RouteMapAllViewController(serviceStopDict: serviceStopDict)
                        }
                    }
                }
            }
              
        }
        .navigationTitle("Over View")
        .task{
            if let company = masterDataManager.currentCompany {
                isLoading = true
                do{
                    try await serviceStopVM.getServiceStopByListFromActiveRoutes(companyId: company.id, activeRoutes: activeRoutes)
                    serviceStopDict = serviceStopVM.serviceStopDictionary
                    isLoading = false
                    
                } catch {
                    print("error")
                    isLoading = false
                    
                }
            }
        }
        .onChange(of:masterDataManager.selectedActiveRoute, perform: { route in
            Task{
                if let company = masterDataManager.currentCompany {
                    
                    isLoading = true
                    do{
                        guard let activeRoute = route else { return }
                        try await serviceStopVM.getServiceStopByListFromActiveRoutes(companyId: company.id, activeRoutes: activeRoutes)
                        serviceStopDict = serviceStopVM.serviceStopDictionary
                        masterDataManager.selectedServiceStopList = serviceStopVM.serviceStops
                        isLoading = false
                        
                    } catch {
                        print("error")
                        isLoading = false
                        
                    }
                }
            }
        })
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
