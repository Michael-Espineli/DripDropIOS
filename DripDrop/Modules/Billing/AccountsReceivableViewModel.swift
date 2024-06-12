//
//  AccountsReceivableViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/8/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class AccountsReceivableViewModel:ObservableObject{
    @Published private(set) var listOfInvoices:[Invoice] = []
    
    //CREATE
    func createGenericItemWithValidation(companyId:String,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{
    }
    func createStardingGenericItems(companyId:String,genericItem:GenericItem) async throws {

    }
    //READ
    func readFleetList(companyId:String) async throws {
    }
    //UPDATE
    func updateGenericItem(companyId:String,genericItem:GenericItem,commonName:String,specificName:String,category:String,description:String, dateUpdated:Date, sku:String, rate:Double,UOM:String,storeItems:[String],storItemIds:[String]) async throws{

    }
    //DELETE
    func deleteGenericItem(companyId:String,genericId:String) async throws {
        
    }
}
