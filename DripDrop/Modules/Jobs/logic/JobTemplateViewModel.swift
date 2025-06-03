//
//  JobTemplateViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/14/24.
//

import Foundation
import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

@MainActor
final class JobTemplateViewModel:ObservableObject{
    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var jobTemplates:[JobTemplate] = []
    func createNewCustomerServiceLocationStartUpInfo(customerServiceLocationStartUpInfo:CustomerServiceLocationStartUpInfo) async throws{
        
    }
    func getJobTemplates(companyId:String) async throws {
        self.jobTemplates = try await dataService.getAllWorkOrderTemplates(companyId: companyId)
    }
    func convertAddressToLatLong(address:Address) async throws {
        let geoCoder = CLGeocoder()
        let fulladdress = address.streetAddress + " " + address.city + " " + address.state + " " + address.zip
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate
        }
        
    }
}
