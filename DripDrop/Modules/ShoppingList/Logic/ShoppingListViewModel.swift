//
//  ShoppingListViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ShoppingListViewModel:ObservableObject{
    //Variables
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //Singles
    @Published private(set) var shoppingListItem: ShoppingListItem? = nil
    @Published private(set) var shoppingListItemCount: Int? = nil

    //Arrays
    @Published private(set) var allShoppingItems:[ShoppingListItem] = []
    
    @Published private(set) var personalShoppingItems:[ShoppingListItem] = []
    @Published private(set) var customerShoppingItems:[ShoppingListItem] = []
    @Published private(set) var jobShoppingItems:[Job:[ShoppingListItem]] = [:]

    //Create
    func addNewShoppingListItemWithValidation(companyId:String,datePurchased:Date?,category:ShoppingListCategory,subCategory:ShoppingListSubCategory,purchaserId:String,itemId:String?,quantiy:String?,description:String,jobId:String?,customerId:String?,customerName:String?,purchaserName:String?,name:String) async throws{

        let id = UUID().uuidString
        //, Purchased, Installed
        let shoppingListItem = ShoppingListItem(id: id, category: category, subCategory: subCategory, status: .needToPurchase, purchaserId: purchaserId, purchaserName: purchaserName ?? "", genericItemId: "", name: name, description: description, datePurchased: datePurchased, quantiy: quantiy, jobId: jobId,customerId: customerId ?? "",customerName: customerName ?? "")
        try await dataService.addNewShoppingListItem(companyId: companyId, shoppingListItem: shoppingListItem)
    }
    //Read
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws {
        self.shoppingListItem = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: shoppingListItemId)
    }
    func getAllShoppingListItemsByCompany(companyId:String) async throws {
        self.allShoppingItems = try await dataService.getAllShoppingListItemsByCompany(companyId: companyId)

    }
    func getAllShoppingListItemsByUser(companyId:String,userId:String) async throws {
        self.allShoppingItems = try await dataService.getAllShoppingListItemsByUser(companyId: companyId, userId: userId)

    }
    func getAllShoppingListItemsByUserCount(companyId:String,userId:String) async throws {
        self.shoppingListItemCount = try await dataService.getAllShoppingListItemsByUserCount(companyId: companyId, userId: userId)

    }
    func getAllShoppingListItemsByUserForPersonal(companyId:String,userId:String) async throws {
        self.personalShoppingItems = try await dataService.getAllShoppingListItemsByUserForCategory(companyId: companyId, userId: userId, category: "Personal")
    }
    func getAllShoppingListItemsByUserForCustomers(companyId:String,userId:String) async throws {
        self.customerShoppingItems = try await dataService.getAllShoppingListItemsByUserForCategory(companyId: companyId, userId: userId, category: "Customer")
    }
    func getAllShoppingListItemsByUserForJobs(companyId:String,userId:String) async throws {
        //Get All Jobs Under This Tech?
        let jobList = try await dataService.getAllJobsByUser(companyId: companyId, userId: userId)
        var jobShoppingListDict : [Job:[ShoppingListItem]] = [:]
        for job in jobList {
            let shoppingListItems = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: userId, category: "Job")
            if !shoppingListItems.isEmpty {
                jobShoppingListDict[job] = shoppingListItems
            }
        }
        self.jobShoppingItems = jobShoppingListDict
    }
    //Update
    func updateShoppingListItem(companyId:String) async throws {
        
    }
    //Delete
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await dataService.deleteShoppingListItem(companyId: companyId, shoppingListItemId: shoppingListItemId)
    }
}

