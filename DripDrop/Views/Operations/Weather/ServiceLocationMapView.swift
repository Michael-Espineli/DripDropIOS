//
//  ServiceLocationMapView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/11/23.
//

import SwiftUI
import MapKit
struct ServiceLocationMapView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager

    @StateObject var locationVM : ServiceLocationViewModel

    init(companyId:String,serviceLocationDataService:any ProductionDataServiceProtocol){
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: serviceLocationDataService))
        self.companyId = companyId
    }

    var companyId:String? = nil
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.161087), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State var mapPinLocations:[MapLocation] = []
    @State var isLoading:Bool = true
    var body: some View {
        ZStack{
            if isLoading {
                ProgressView()
            } else {
                Map(coordinateRegion: $region,
                    annotationItems: mapPinLocations,
                    annotationContent: { location in

                    MapAnnotation(coordinate: location.coordinate, content: {
                                            Button(action: {
                                                print(location.name)
//                                                navigationManager.selectedMapLocation = location
                                            }, label: {
                                                Image(systemName: "house")
                                            })
                    })

//                        MapMarker(coordinate: location.coordinate,tint: Color.blue)
                })
            }
        }
        .task {
            if let companyId = companyId {
                isLoading = true
                var sumOfLat:Double = 0
                var numberOfCoord:Double = 0
                var sumOfLon:Double = 0
                try? await locationVM.getAllCustomerServiceLocations(companyId: companyId)
                region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 32.7157, longitude: -117.161087), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                for location in locationVM.serviceLocations {
                    numberOfCoord = numberOfCoord + 1
                    sumOfLat = sumOfLat + location.address.latitude
                    sumOfLon = sumOfLon + location.address.longitude
                    print("numberOfCoord")
                    print(numberOfCoord)
                    print("sumOfLat")
                    print(sumOfLat)
                    print("sumOfLon")
                    print(sumOfLon)
                    
                    mapPinLocations.append(MapLocation(customerId: UUID().uuidString, name: location.customerName, latitude: location.address.latitude, longitude:  location.address.longitude, address: location.address, color: "red"))
                }
                print("sumOfLat/numberOfCoord")
                print(sumOfLat/numberOfCoord)
                print("sumOfLon/numberOfCoord")
                print(sumOfLon/numberOfCoord)
                region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: sumOfLat/numberOfCoord, longitude: sumOfLon/numberOfCoord), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                isLoading = false
            }
        }
    }
}
