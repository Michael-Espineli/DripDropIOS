//
//  LocationManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/9/24.
//

import CoreLocation
import CoreLocationUI
import SwiftUI
import MapKit

final class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var region = MKCoordinateRegion(
        center: .init(latitude: 37.334_900, longitude: -122.009_020),
        span: .init(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.setup()
    }
    
    func setup() {
        switch locationManager.authorizationStatus {
        //If we are authorized then we request location just once, to center the map
        case .authorizedWhenInUse:
            locationManager.requestLocation()
        //If we don´t, we request authorization
        case .notDetermined:
            locationManager.startUpdatingLocation()
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard .authorizedWhenInUse == manager.authorizationStatus else { return }
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Something went wrong: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        locations.last.map {
            region = MKCoordinateRegion(
                center: $0.coordinate,
                span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
}
struct ContentView: View {
    @StateObject var manager = LocationManager()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var count:Int = 0
    var body: some View {
        Map(coordinateRegion: $manager.region, showsUserLocation: true)
            .edgesIgnoringSafeArea(.all)
            .onReceive(timer) { time in
                if count == 0 || count == 60 {
                    print(time)
                    if count == 60 {
                        count = 0
                        print("Location Lat: \(manager.region.center.latitude) and Long: \(manager.region.center.longitude)")
                    } else {
                        count += 1
                    }
                }
            }
    }
}
