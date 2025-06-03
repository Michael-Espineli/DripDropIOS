//
//  RouteOverViewMapView2.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/20/23.
//
//#if os(ios)
import SwiftUI
import UIKit
import MapKit

struct RouteOverViewMapView2: View {
    var body: some View {
       MyView()
    }
}

struct MyView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MyViewController
    
    func makeUIViewController(context: Context) -> MyViewController {
        let vc = MyViewController()
        // Do some configurations here if needed.
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MyViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

struct MapViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = MapViewController
    
    func makeUIViewController(context: Context) -> MapViewController {
        let vc = MapViewController()
        // Do some configurations here if needed.
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

class MyViewController: UIViewController {
    // 1
    private var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.text = "Hello, UIKit!"
        label.textAlignment = .center
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 2
        view.backgroundColor = .systemPink

        // 3
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }
}

class MapViewController: UIViewController {
    // 1
    var routeData : Route?
    var serviceStopList : [ServiceStop] = []
    var routeOverlay : MKOverlay?
    let mapView : MKMapView = {
        let map = MKMapView()
        map.overrideUserInterfaceStyle = .dark
        return map
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 2
        mapView.delegate = self
        setMapConstraints()
        
        serviceStops()
        
        addPins()
        
        drawRoute(serviceStops: serviceStopList)
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
        serviceStopList = [
            ServiceStop(
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
                operationStatus: .finished,
                billingStatus: .invoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            ),
            ServiceStop(
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
                operationStatus: .finished,
                billingStatus: .invoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            ),
            ServiceStop(
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
                operationStatus: .finished,
                billingStatus: .invoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            ),
        ]
    }
    
    func addPins(){
        if serviceStopList.count != 0 {
            for pin in serviceStopList {
                
                let defaultPin = MKPointAnnotation()
                defaultPin.title = "Default"
                defaultPin.coordinate = CLLocationCoordinate2D(
                    latitude: (pin.address.latitude),
                    longitude: (pin.address.longitude)
                )
                mapView.addAnnotation(defaultPin)
            }
            let startPin = MKPointAnnotation()
            startPin.title = "Start"
            startPin.coordinate = CLLocationCoordinate2D(
                latitude: (serviceStopList.first?.address.latitude)!,
                longitude: (serviceStopList.first?.address.longitude)!
            )
            mapView.addAnnotation(startPin)
            let endPin = MKPointAnnotation()
            endPin.title = "End"
            endPin.coordinate = CLLocationCoordinate2D(
                latitude: (serviceStopList.last?.address.latitude)!,
                longitude: (serviceStopList.last?.address.longitude)!
            )
            mapView.addAnnotation(endPin)
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
            print(coordiantes)
        
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


extension MapViewController : MKMapViewDelegate {
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
        case "End":
            annotationView?.image = UIImage(named: "EndPin")
        case "Start":
            annotationView?.image = UIImage(named: "StartPin")
        default:
            annotationView?.image = UIImage(named: "DefaultPin")
        }
        return annotationView
    }
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
//#endif
