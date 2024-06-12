//
//  BackGroundMapView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
import MapKit
struct BackGroundMapView: View {
    
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    @State var mapPinLocations:[MapLocation] = []
    var coordinates: CLLocationCoordinate2D
    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .zoom,
        annotationItems: mapPinLocations,
        annotationContent: { location in
            MapMarker(coordinate: location.coordinate,tint: Color.blue)

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
extension CLLocationCoordinate2D:Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude &&
        lhs.longitude == rhs.longitude
    }
}
