//
//  RouteOverViewMapView2.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//

import SwiftUI
import UIKit
import MapKit


struct MapViewControllerRepresentable3: UIViewControllerRepresentable {

    typealias UIViewControllerType = Map3ViewController
//    init(serviceStopList:[ServiceStop]){
//        self.serviceStopList = serviceStopList
//    }
    var serviceStopList : [ServiceStop]
    var selectedStop : ServiceStop

    func makeUIViewController(context: Context) -> Map3ViewController {
        let vc = Map3ViewController()
        // Do some configurations here if needed.
        vc.serviceStopList = serviceStopList
        vc.selectedStop = selectedStop
        return vc
    }
    
    func updateUIViewController(_ uiViewController: Map3ViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
        print(" updateUIViewController Service Stop List \(serviceStopList.count)")
        uiViewController.serviceStopList = serviceStopList
        uiViewController.selectedStop = selectedStop
        uiViewController.showSpecificPin(serviceStop: selectedStop)
        
    }
}


class Map3ViewController: UIViewController {
    // 1
  
    
    var routeData : Route?
    var serviceStopList : [ServiceStop] = []
    var selectedStop : ServiceStop = ServiceStop(
        id: "",
        internalId: "",
        companyId: "",
        companyName: "",
        customerId: "",
        customerName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        dateCreated: Date(),
        serviceDate: Date(),
        startTime: Date(),
        endTime: Date(),
        duration: 0,
        estimatedDuration: 0,
        tech: "",
        techId: "",
        recurringServiceStopId: "",
        description: "",
        serviceLocationId: "",
        typeId: "",
        type: "",
        typeImage: "",
        jobId: "",
        jobName: "",
        operationStatus: .notFinished,
        billingStatus: .notInvoiced,
        includeReadings: true,
        includeDosages: true,
        otherCompany: false,
        laborContractId: "",
        contractedCompanyId: "",
        isInvoiced: false
    )
    var routeOverlay : MKOverlay?
    var routeOverlay2 : MKOverlay?
    var zoomRange : MKMapView.CameraZoomRange?
    var cameraBoundry : MKMapView.CameraBoundary?

    let mapView : MKMapView = {
        let map = MKMapView()
        map.overrideUserInterfaceStyle = .dark
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 2
        mapView.delegate = self
        //create two dummy locations
        print(" Inside Map3ViewController \(serviceStopList.count)")

//        serviceStops()
        
        setMapConstraints()
        //find route
        addPins()
        showMultipleRoutesOnMap(serviceStops: serviceStopList)
//        showSpecificPin(serviceStop:selectedStop)
    }
    func showSpecificPin(serviceStop:ServiceStop) {
        print("Showing Coordiante >> \(CLLocationCoordinate2D(latitude: serviceStop.address.latitude, longitude: serviceStop.address.longitude))")
        DispatchQueue.main.async {
//            self.routeOverlay2 = MKPolygon(coordinates: [CLLocationCoordinate2D(latitude: serviceStop.address.latitude, longitude: serviceStop.address.longitude)], count: 1)
//            self.mapView.addOverlay(self.routeOverlay2!, level: .aboveRoads)
//            let customEdgePadding : UIEdgeInsets = UIEdgeInsets(
//                top: 10000,
//                left: 10000,
//                bottom: 10000,
//                right: 10000
//            )
            //            self.mapView.setVisibleMapRect(self.routeOverlay2!.boundingMapRect, edgePadding: customEdgePadding,animated: true)

            
//            self.zoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 1000, maxCenterCoordinateDistance: 1000)
//            self.mapView.setCameraZoomRange(self.zoomRange, animated: true)

            self.cameraBoundry = MKMapView.CameraBoundary(mapRect: MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: serviceStop.address.latitude, longitude: serviceStop.address.longitude)), size: MKMapSize(width: 0.01, height: 0.01)))
            self.mapView.setCameraBoundary(self.cameraBoundry, animated: true)
            self.mapView.isScrollEnabled = true
            self.mapView.isZoomEnabled = true
        }
    }
    func showMultipleRoutesOnMap(serviceStops:[ServiceStop]) {
        if serviceStops.count == 0 || serviceStops.count == 1 {
            return
        }
        var firstStop:ServiceStop? = nil
        var secondStop:ServiceStop? = nil
        let totalCount = serviceStops.count - 1
        var currentCount = 0
        while currentCount < totalCount {
//        for stop in serviceStops {
//            if totalCount == currentCount {
//                return // break
//            }
            print("totalCount \(totalCount)")

            print("currentCount \(currentCount)")
            firstStop = serviceStops[currentCount]
            secondStop = serviceStops[currentCount + 1]
            currentCount = currentCount + 1
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (firstStop?.address.latitude)!, longitude: (firstStop?.address.longitude)!), addressDictionary: nil))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: (secondStop?.address.latitude)!, longitude: (secondStop?.address.longitude)!), addressDictionary: nil))
            request.requestsAlternateRoutes = true
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            
            directions.calculate { [unowned self] response, error in
                guard let unwrappedResponse = response else { return }
                
                //for getting just one route
                if let route = unwrappedResponse.routes.first {
                    //show on map
                    self.mapView.addOverlay(route.polyline)
                    //set the map area to show the route
                    self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
                }
                //if you want to show multiple routes then you can get all routes in a loop in the following statement
                //for route in unwrappedResponse.routes {}
                
            }
        }
    }
    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            //for getting just one route
            if let route = unwrappedResponse.routes.first {
                //show on map
                self.mapView.addOverlay(route.polyline)
                //set the map area to show the route
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
            }
            //if you want to show multiple routes then you can get all routes in a loop in the following statement
            //for route in unwrappedResponse.routes {}
        }
    }
    func setMapConstraints() {
        view.addSubview(mapView)
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
    }
    func serviceStops(){
        
        serviceStopList = []
    }
    
    func addPins(){
        if serviceStopList.count != 0 {
            for pin in serviceStopList {
                
                let defaultPin = MKPointAnnotation()
                defaultPin.title = pin.operationStatus.rawValue
                defaultPin.coordinate = CLLocationCoordinate2D(
                    latitude: (pin.address.latitude),
                    longitude: (pin.address.longitude)
                )
                mapView.addAnnotation(defaultPin)
            }
        }
    }
    func drawRoute(serviceStops:[ServiceStop]){
        if serviceStops.count == 0 {
            print("No Coordinates")
            return
        }
        var coordiantes:[CLLocationCoordinate2D] = []
        for stop in serviceStops {
            coordiantes.append(CLLocationCoordinate2D(latitude: stop.address.latitude, longitude: stop.address.longitude))
        }
        print("Coordinate Count \(coordiantes.count)")
        
        DispatchQueue.main.async {
            self.routeOverlay = MKPolygon(coordinates: coordiantes, count: coordiantes.count)
            self.mapView.addOverlay(self.routeOverlay!, level: .aboveRoads)
            let customEdgePadding : UIEdgeInsets = UIEdgeInsets(
                top: 50,
                left: 50,
                bottom: 50,
                right: 50
            )
            
            self.mapView.setVisibleMapRect(self.routeOverlay!.boundingMapRect, edgePadding: customEdgePadding,animated: true)
        }
        
    }
}


extension Map3ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Custom")
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Custom")
        } else {
            annotationView?.annotation = annotation
        }
        
        switch annotation.title {
        case "Not Finished":
            annotationView?.image = UIImage(named: "EndPin")
        case "Finished":
            annotationView?.image = UIImage(named: "StartPin")
        default:
            annotationView?.image = UIImage(named: "DefaultPin")
        }
        return annotationView
    }
    //this delegate function is for displaying the route overlay and styling it
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKGradientPolylineRenderer(overlay: overlay)
        renderer.setColors([
            UIColor(red: 0.02, green: 0.91, blue: 0.05, alpha: 1.0),
            UIColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1.0),
            UIColor(red: 1.0, green: 0.91, blue: 0.0, alpha: 1.0)
                
        ], locations: [])
        renderer.lineCap = .round
        renderer.lineWidth = 3.0
        return renderer
    }
}
