//
//  FleetViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/20/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class FleetViewModel:ObservableObject{
    @Published private(set) var listOfVehicals:[Vehical] = []
    @Published private(set) var vehical:Vehical? = nil

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //CREATE
    func createGenericItemWithValidation(companyId:String,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{
    }
    
    func addNewVehical(companyId:String,vehical:Vehical) async throws {
        try await dataService.addNewVehical(companyId: companyId, vehical: vehical)
    }
    //READ
    func getFleetSnapShot(companyId:String) async throws {
        //DEVELOPER
        self.listOfVehicals = try await dataService.getFleet(companyId: companyId)
    }
    func getFleetList(companyId:String) async throws {
        //DEVLOPER
        self.listOfVehicals = try await dataService.getFleet(companyId: companyId)
    }
    func getVehical(companyId:String,vehicalId:String) async throws {
        //DEVLOPER
        self.vehical = try await dataService.getVehical(companyId: companyId, vehicalId: vehicalId)
    }
    //UPDATE
    func updateGenericItem(companyId:String,genericItem:GenericItem,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{

    }
    //DELETE
    func deleteVehical(companyId:String,genericId:String) async throws {
        
    }
}
