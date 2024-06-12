//
//  GenericItemViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/27/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class GenericItemViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var genericItems: [GenericItem] = []
    //CREATE
    func createGenericItemWithValidation(companyId:String,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{
    }
    func createStardingGenericItems(companyId:String,genericItem:GenericItem) async throws {
        try await dataService.createDataBaseItem(companyId: companyId, genericItem: genericItem)
    }
    //READ
    func getAllGenericItems(companyId:String) async throws {
        self.genericItems = try await dataService.getAllDataBaseItems(companyId: companyId)
    }
    //UPDATE
    func updateGenericItem(companyId:String,genericItem:GenericItem,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{

    }
    //DELETE
    func deleteGenericItem(companyId:String,genericId:String) async throws {
        
    }
}
