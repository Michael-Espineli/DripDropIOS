//
//  MiniMapView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import SwiftUI
import MapKit
struct MiniMapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State var mapPinLocations:[MapLocation] = []
    @State var coordinates: CLLocationCoordinate2D
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .zoom,
        annotationItems: mapPinLocations,
        annotationContent: { location in
            MapMarker(coordinate: location.coordinate,tint: Color.poolBlue)

        })
            .onAppear(perform: {
                region = MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                mapPinLocations = [MapLocation(customerId: UUID().uuidString, name: "Name", latitude: coordinates.latitude, longitude: coordinates.longitude, address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), color: "red")]
            })
            .onChange(of: coordinates, perform: { coord in
                region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))
                mapPinLocations = [MapLocation(customerId: UUID().uuidString, name: "Name", latitude: coord.latitude, longitude: coord.longitude, address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), color: "red")]
            })
            
    }
}
