//
//  GeneralBackgroundMapView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/25.
//

import SwiftUI
import MapKit
struct GeneralBackgroundMapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State var mapPinLocations:[MapLocation] = []
    var coordinates: CLLocationCoordinate2D
    var body: some View {
        
        Map(
            coordinateRegion: $region,
            interactionModes: .pan,
            showsUserLocation: false,
            userTrackingMode: .constant(.none),
            annotationItems: mapPinLocations,
            annotationContent: { location in
                MapAnnotation(coordinate: location.coordinate) {
                    ZStack{
                        Circle()
                            .strokeBorder(Color.poolBlue, lineWidth: 1)
                            .frame(width: 75, height: 75)
                        Circle()
                            .fill(Color.poolBlue.opacity(0.25))
                            .frame(width: 75, height: 75)
                    }
                        
                }
            }
        )
            .onAppear(perform: {
                region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                mapPinLocations = [MapLocation(customerId: UUID().uuidString, name: "Name", latitude: coordinates.latitude, longitude: coordinates.longitude, address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), color: "red")]
            })
            .onChange(of: coordinates, perform: { coord in
                region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                mapPinLocations = [MapLocation(customerId: UUID().uuidString, name: "Name", latitude: coord.latitude, longitude: coord.longitude, address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), color: "red")]
            })
            
    }
}

