//
//  IndustryTypePickerViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//

import Foundation
import CoreLocation
import MapKit
import Contacts
@MainActor
final class IndustryTypePickerViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var industryTypes:[String] = ["Pool Cleaning","Green To Blue","Filter Cleaning","Salt Cell Cleaning","Leak Detection","Pool Building","Commercial","Residential"]
    @Published var selectedIndustryTypes:[String] = []
    @Published var selectedIndustry:String? = nil //Developer I dont think I used it
    @Published var selectedZipCodes:[String] = []
    @Published var commonZipCodes:[String] = []

    @Published var zipCode:String = ""
    @Published private(set) var coordinates: CLLocationCoordinate2D? = nil
    @Published private(set) var placemark: CLPlacemark? = nil

    func getCityFromZip() async throws {
        let geoCoder = CLGeocoder()
        if zipCode != "" && zipCode.count == 5 {
            let placemarkList = try await geoCoder.geocodeAddressString(zipCode)
            if !placemarkList.isEmpty {
                self.placemark = placemarkList.first!
            }
        }
    }
    func addZipToList() async throws {
        //Validate
        if zipCode.count == 5 {
            selectedZipCodes.append(zipCode)
            commonZipCodes.append(zipCode)
            commonZipCodes.removeDuplicates()
            self.zipCode = ""
        }
    }
}
