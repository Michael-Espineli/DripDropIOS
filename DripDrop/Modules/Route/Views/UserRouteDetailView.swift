//
//  UserRouteDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/19/23.
//
import SwiftUI
import MapKit
struct UserRouteDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

init(dataService:any ProductionDataServiceProtocol,activeRoute:ActiveRoute){
        _serviceStopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService : dataService))
        _activeRoute = State(wrappedValue: activeRoute)
    }
    @StateObject var serviceStopVM : ServiceStopsViewModel
    //received Variables
    @State var activeRoute : ActiveRoute
    
    @State var serviceStops:[ServiceStop] = []
    @State var selectedServiceStop:ServiceStop? = nil
    @State var selected:String = "List"
    @State var isLoading:Bool = true
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if isLoading {
                    ProgressView()
                }
                
                else {
                    if serviceStops.isEmpty {
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
                            case "List":
                                RouteOverViewListView(serviceStops: serviceStops)
                                
                            case "Map":
                                RouteMapViewController(serviceStops: serviceStops)
                                //                    RouteOverViewMapView(serviceStops: serviceStops)
                            default:
                                RouteOverViewListView(serviceStops: serviceStops)
                            }
                        }
                    }
                }
                Spacer()
            }
        }
        .navigationTitle("\(activeRoute.techName)")
        .task{
            isLoading = true
            do{
                try await serviceStopVM.getServiceStopByList(companyId: masterDataManager.currentCompany!.id, serviceStopIds: activeRoute.serviceStopsIds)
                serviceStops = serviceStopVM.serviceStops
                masterDataManager.selectedServiceStopList = serviceStopVM.serviceStops

            } catch {
                print("UserRouteDetailView Error >> \(error)")
            }
            isLoading = false

        }
        .onChange(of:masterDataManager.selectedActiveRoute, perform: { route in
            Task{
                if let company = masterDataManager.currentCompany {
                    isLoading = true
                    do{
                        guard let activeRoute = route else { return }
                        try await serviceStopVM.getServiceStopByList(companyId: company.id, serviceStopIds: activeRoute.serviceStopsIds)
                        serviceStops = serviceStopVM.serviceStops
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
            return Color.poolGreen
        default:
            return Color.gray
        }
    }
}
