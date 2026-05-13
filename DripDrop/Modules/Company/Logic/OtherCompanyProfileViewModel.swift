//
//  OtherCompanyProfileViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit
import CoreLocation

struct Review: Identifiable {
    var id: String
    var rating: Double
    var description: String
    var reviewerName: String
    var verified: Bool
    var createdAt: Date
}

@MainActor
final class OtherCompanyProfileViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    let company: Company
    init(dataService:any ProductionDataServiceProtocol,company: Company){
        self.dataService = dataService
        self.company = company

    }
    @Published private(set) var savedBuisnessList : [AssociatedBusiness] = []
    @Published private(set) var isLoadingReviews : Bool = false
    @Published private(set) var buisnessList : [AssociatedBusiness] = []
    
    @Published private(set) var reviews : [Review] = []
    @Published private(set) var mapLocations: [MapLocation2] = []
    @Published var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35), span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20))
    @Published private(set) var geocodeError: String?
    
    //Misc
    func loadReviewsIfNeeded() async {
        guard !isLoadingReviews else { return }
        self.isLoadingReviews = true
        defer { self.isLoadingReviews = false }
        // TODO: Hook up VM or service to fetch reviews for company.id

    }
    
    func geocodeServiceZipCodes() async {
        let zips = company.serviceZipCodes
        guard !zips.isEmpty else { return }
        let geocoder = CLGeocoder()
        var coords: [MapLocation2] = []

        for zip in zips {
            do {
                let placemarks = try await geocoder.geocodeAddressString(zip)
                if let first = placemarks.first, let location = first.location {
                    coords.append(MapLocation2(name: "Company Location", coordinate: location.coordinate))
                }
            } catch {
                print("Geocoding failed for \(zip): \(error)")
                geocodeError = "Error during geocoding. Please check your network connection."
            }
        }

        mapLocations = coords
        if let first = coords.first {
            mapRegion.center = first.coordinate
            mapRegion.span = MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
        }
    }

    //Create
    func saveAssociatedBusinessToUser(userId:String,business:AssociatedBusiness) async throws {
        try await dataService.saveAssociatedBusinessToUser(userId: userId, business: business)
    }
    func saveAssociatedBusinessToCompany(companyId:String,business:AssociatedBusiness) async throws {
        try await dataService.saveAssociatedBusinessToCompany(companyId: companyId, business: business)
    }
    //Read
    func getSavedCompanies(userId:String) async throws {
        self.savedBuisnessList = try await dataService.getUserSavedBusinessList(userId: userId)
            //        getUserSavedBusiness
    }
    func getAssociatedBuisnesses(companyId:String) async throws {
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
    }
    //Update
    //Delete
    func deleteAssociatedBusinessToCompany(userId:String,businessId:String) async throws {
        try await dataService.deleteSavedCompany(userId: userId, businessId: businessId)
    }
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws {
        try await dataService.deleteAssociatedBusinessToCompany(companyId: companyId, businessId: businessId)
    }
}
