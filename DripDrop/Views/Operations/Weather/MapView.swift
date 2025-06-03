//
//  MapView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/11/23.
//

import SwiftUI
import MapKit
struct MapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State var mapPinLocations:[MapLocation] = []
    var coordinates: CLLocationCoordinate2D
    var locations:[ServiceLocation]
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .zoom,
        annotationItems: mapPinLocations,
        annotationContent: { location in
            MapMarker(coordinate: location.coordinate,tint: Color.blue)

        })
            .onAppear(perform: {
                for location in locations {
                    region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                    mapPinLocations.append(MapLocation(customerId: UUID().uuidString, name: location.customerName, latitude: location.address.latitude, longitude:  location.address.longitude, address: location.address, color: "red"))
                }
            })
    }
}
