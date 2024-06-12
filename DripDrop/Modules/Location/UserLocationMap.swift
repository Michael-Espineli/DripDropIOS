//
//  UserLocationMap.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/9/24.
//

import MapKit
import SwiftUI

struct UserLocationMap: View {
    
    let locationManager = CLLocationManager()
    var region: MKCoordinateRegion
    @State var region2 = MKCoordinateRegion(
        center: .init(latitude: 37.334_900,longitude: -122.009_020),
        span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    var body: some View {
        Map(
          coordinateRegion: $region2,
          showsUserLocation: true,
          userTrackingMode: .constant(.follow)
        )
          .edgesIgnoringSafeArea(.all)
          .onAppear {
              region2 = region
              locationManager.requestWhenInUseAuthorization()
          }
    }
}
