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

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //CREATE
    func createGenericItemWithValidation(companyId:String,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{
    }
    func createStardingGenericItems(companyId:String,genericItem:GenericItem) async throws {

    }
    //READ
    func getFleetSnapShot(companyId:String) async throws {
        //DEVELOPER
//        self.listOfVehicals = try await dataService.readFleetList(companyId: companyId)
    }
    func readFleetList(companyId:String) async throws {
        //DEVLOPER
//        self.listOfVehicals = try await dataService.readFleetList(companyId: companyId)
    }
    //UPDATE
    func updateGenericItem(companyId:String,genericItem:GenericItem,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{

    }
    //DELETE
    func deleteGenericItem(companyId:String,genericId:String) async throws {
        
    }
}
