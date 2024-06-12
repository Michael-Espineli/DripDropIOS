//
//  StoreViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//
import Foundation
@MainActor
final class StoreViewModel:ObservableObject{
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var store: Vender? = nil
    @Published private(set) var stores: [Vender] = []
    
    @Published private(set) var moneySpentAtVender: Double? = nil
    @Published private(set) var itemsPurchasedAtVender: Double? = nil
    @Published private(set) var dataBaseItemsAtVender: Double? = nil

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Uploading Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Get Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func updateStore(companyId:String,store:Vender,name:String,streetAddress:String,city:String,state:String,zip:String) async throws {
        try? await StoreManager.shared.updateStore(companyId:companyId,store:store,name:name,streetAddress:streetAddress,city:city,state:state,zip:zip)
        
    }
    func getStoreInfo(companyId: String,vender:Vender)async throws{
        let items = try await PurchasedItemsManager.shared.getAllpurchasedItemsByVender(companyId: companyId, venderId: vender.id)
        let dataBaseItemsAtVender = try await DatabaseManager.shared.getDataBaseItemByVenderItemTotal(companyId: companyId, venderId: vender.id)
        
        var moneySpentAtVender:Double = 0
        var itemsPurchasedAtVender:Double = 0

        for item in items {
            let total = (Double(item.quantityString) ?? 0) * Double(item.price)

            moneySpentAtVender = moneySpentAtVender + total
            itemsPurchasedAtVender = itemsPurchasedAtVender + (Double(item.quantityString) ?? 0)
        }
        self.moneySpentAtVender = moneySpentAtVender
        self.itemsPurchasedAtVender = itemsPurchasedAtVender
        self.dataBaseItemsAtVender = Double(dataBaseItemsAtVender)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    

    func getAllStores(companyId:String) async throws{
        self.stores = try await StoreManager.shared.getAllStores(companyId: companyId)
    }
    func addNewStore(companyId:String,store:Vender) async throws{
        
        let storeId = try await SettingsManager.shared.getStoreCount(companyId: companyId)
        let id = "ST" + String(storeId)
        let coordinates = try await convertAddressToCordinates1(address: store.address)
        
        print("Received Coordinates \(String(describing: coordinates))")
        let pushStore = Vender(id: id,
                               name: store.name,
                               email: store.email,
                               address: Address(streetAddress: store.address.streetAddress,
                                                city: store.address.city,
                                                state: store.address.state,
                                                zip: store.address.zip,
                                                latitude: coordinates.latitude,
                                                longitude: coordinates.longitude),
                               phoneNumber: store.phoneNumber)
        try await StoreManager.shared.uploadStore(companyId: companyId, store: pushStore)
    }
    
    func getSingleStore(companyId:String,storeId:String) async throws{
        
        self.store = try await StoreManager.shared.getSingleStore(companyId: companyId, storeId: storeId)
        
    }
    
}
