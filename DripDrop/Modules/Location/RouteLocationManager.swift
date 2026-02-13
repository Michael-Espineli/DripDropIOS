import Foundation
import CoreLocation

final class RouteLocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    // Simple callback-based emission. You can replace this with Combine if preferred.
    var onAuthorizationChanged: ((CLAuthorizationStatus) -> Void)?
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onError: ((Error) -> Void)?

    // Current state
    private(set) var isTracking: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // meters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        // For iOS 14+: manager.activityType = .automotiveNavigation or .otherNavigation as needed
    }

    // MARK: - Permissions
    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        // Must call whenInUse first (system requirement), then Always
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - Tracking control
    func startTracking() {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            isTracking = true
        case .notDetermined:
            // Request when-in-use first; client can later call requestAlwaysAuthorization if needed
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Surface UI to guide user to Settings if needed
            break
        @unknown default:
            break
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
    }

    // Optionally support significant-change for battery savings
    func startSignificantChangeTracking() {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            manager.startMonitoringSignificantLocationChanges()
            isTracking = true
        }
    }

    func stopSignificantChangeTracking() {
        manager.stopMonitoringSignificantLocationChanges()
        isTracking = false
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChanged?(manager.authorizationStatus)
        // If permission was granted while we intended to be tracking, resume
        if isTracking && (manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse) {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        onLocationUpdate?(latest)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onError?(error)
    }
}