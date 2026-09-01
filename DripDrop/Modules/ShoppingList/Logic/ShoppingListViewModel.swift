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
    @Published private(set) var routePrepItems: [ShoppingListItem] = []
    @Published private(set) var outstandingItems: [ShoppingListItem] = []
    @Published private(set) var myItems: [ShoppingListItem] = []
    @Published private(set) var jobItems: [ShoppingListItem] = []
    @Published private(set) var customerItems: [ShoppingListItem] = []
    
    //Singles
    @Published private(set) var shoppingListItem: ShoppingListItem? = nil
    @Published private(set) var shoppingListItemCount: Int? = nil

    //Arrays
    @Published private(set) var allShoppingItems:[ShoppingListItem] = []
    @Published private(set) var personalShoppingItems:[ShoppingListItem] = []
    @Published private(set) var customerShoppingItems:[ShoppingListItem] = []
    @Published private(set) var jobShoppingItems:[Job:[ShoppingListItem]] = [:]
    
    @Published private(set) var companyUsers:[CompanyUser] = []
    
    @Published private(set) var routeCustomerItems: [ShoppingListItem] = []
    @Published private(set) var routeJobItems: [ShoppingListItem] = []
    @Published private(set) var purchasedButNotInstalledItems: [ShoppingListItem] = []
    @Published private(set) var recentlyPurchasedItems: [ShoppingListItem] = []
    
    //Create
    func addNewShoppingListItemWithValidation(
    companyId: String,
    datePurchased: Date?,
    category: ShoppingListCategory,
    subCategory: ShoppingListSubCategory,
    purchaserId: String,
    itemId: String?,
    quantiy: String?,
    description: String,
    jobId: String?,
    customerId: String?,
    customerName: String?,
    userId: String?,
    userName: String?,
    serviceLocationId: String?,
    serviceLocationName: String?,
    purchaserName: String?,
    name: String,
    shoppingListActive: Bool = true
) async throws {

    let id = "comp_shop_" + UUID().uuidString
    let status: ShoppingListStatus = .needToPurchase
    let cleanItemId = itemId ?? ""
    let productId = subCategory == .product ? cleanItemId : ""
    let vendorItemId = subCategory == .dataBase ? cleanItemId : ""

    let prepKeys = buildPrepKeys(
        category: category,
        jobId: jobId,
        customerId: customerId,
        userId: userId,
        serviceLocationId: serviceLocationId
    )

    let shoppingListItem = ShoppingListItem(
        id: id,
        category: category,
        subCategory: subCategory,
        status: status,
        purchaserId: purchaserId,
        purchaserName: purchaserName ?? "",
        genericItemId: productId,
        productId: productId.isEmpty ? nil : productId,
        productName: productId.isEmpty ? nil : name,
        name: name,
        description: description,
        datePurchased: datePurchased,
        quantity: quantiy,

        jobId: jobId,

        customerId: customerId ?? "",
        customerName: customerName ?? "",

        userId: userId,
        userName: userName,

        serviceStopId: nil,
        serviceStopInternalId: nil,
        serviceLocationId: serviceLocationId,
        serviceLocationName: serviceLocationName,
        scheduledDate: nil,

        prepKeys: prepKeys,
        needsAction: shoppingListActive && status.needsShoppingAction,
        shoppingListActive: shoppingListActive,
        actionDate: shoppingListActive ? Date() : nil,
        assignedTechIds: userId == nil ? [] : [userId!],

        dbItemId: vendorItemId.isEmpty ? nil : vendorItemId,
        dbItemName: vendorItemId.isEmpty ? nil : name,
        itemId: cleanItemId.isEmpty ? nil : cleanItemId,
        itemType: subCategory.rawValue,
        purchasedItem: nil,
        invoiced: false,

        plannedUnitCostCents: nil,
        plannedUnitPriceCents: nil,
        plannedTotalCostCents: nil,
        plannedTotalPriceCents: nil
    )

    try await dataService.addNewShoppingListItem(
        companyId: companyId,
        shoppingListItem: shoppingListItem
    )
}
    //Read
    func loadRoutePrepShoppingItems(
        companyId: String,
        userId: String,
        serviceStops: [ServiceStop],
        timeScope: ShoppingCenterTimeScope = .thisWeek,
        referenceDate: Date = Date()
    ) async throws {
        let prepKeys = ShoppingPrepKeyBuilder.keysForRoute(
            serviceStops: serviceStops,
            userId: userId
        )
        let prepContext = ShoppingRoutePrepContext(serviceStops: serviceStops)

        let prepKeyItems = try await dataService.getShoppingListItemsForPrepKeys(
            companyId: companyId,
            prepKeys: prepKeys,
            needsAction: true
        )
        let userScopeItems = try await dataService.getShoppingListItemsForUserScope(
            companyId: companyId,
            userId: userId,
            limit: 150
        )
        let legacyUserItems = try await dataService.getAllShoppingListItemsByUser(
            companyId: companyId,
            userId: userId
        )
        let items = uniqueShoppingItems(prepKeyItems + userScopeItems + legacyUserItems)
            .filter { item in
                item.isOutstandingShoppingAction &&
                item.isNeeded(
                    in: timeScope,
                    referenceDate: referenceDate,
                    routeContext: prepContext
                )
            }
            .sortedForShoppingPrep()

        self.routePrepItems = items

        self.myItems = items.filter { item in
            item.isAssociatedWithShoppingUser(userId)
        }

        self.jobItems = items.filter { item in
            item.category == .job
        }

        self.customerItems = items.filter { item in
            item.category == .customer
        }

        self.outstandingItems = items

        self.purchasedButNotInstalledItems = purchasedItemsSortedByRecency(from: items)
        self.recentlyPurchasedItems = purchasedItemsSortedByRecency(from: items)
    }
    
    
    func loadOutstandingShoppingItems(
        companyId: String,
        limit: Int = 100,
        timeScope: ShoppingCenterTimeScope = .all,
        referenceDate: Date = Date()
    ) async throws {
        let items = try await dataService.getOutstandingShoppingListItemsPage(
            companyId: companyId,
            limit: limit
        )
        .filter { item in
            item.isNeeded(in: timeScope, referenceDate: referenceDate)
        }
        .sortedForShoppingPrep()

        self.outstandingItems = items

        self.purchasedButNotInstalledItems = purchasedItemsSortedByRecency(from: items)
        self.recentlyPurchasedItems = purchasedItemsSortedByRecency(from: items)
    }

    func loadRecentlyPurchasedShoppingItems(
        companyId: String,
        limit: Int = 100
    ) async throws {
        let items = try await dataService.getOutstandingShoppingListItemsPage(
            companyId: companyId,
            limit: limit
        )

        self.recentlyPurchasedItems = purchasedItemsSortedByRecency(from: items)
    }
    
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws {
        self.shoppingListItem = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: shoppingListItemId)
    }
    func getAllShoppingListItemsByCompany(companyId:String) async throws {
        self.allShoppingItems = try await dataService.getAllShoppingListItemsByCompany(companyId: companyId)

    }
    func getAllShoppingListItemsByCompanyForJobs(companyId:String) async throws {
        print("")
        print("ShoppingListViewModel getAllShoppingListItemsByCompanyForJobs")
        let jobList = try await dataService.getAllWorkOrdersFinished(companyId: companyId, finished: false)
        print("Got \(jobList.count) Jobs")
        var jobShoppingListDict : [Job:[ShoppingListItem]] = [:]
        for job in jobList {
            let shoppingListItems = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
            if !shoppingListItems.isEmpty {
                jobShoppingListDict[job] = shoppingListItems
            }
            print("For \(job.id) Got \(shoppingListItems.count) Items")
            self.jobShoppingItems = jobShoppingListDict
        }
        self.jobShoppingItems = jobShoppingListDict
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
            let shoppingListItems = try await dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: job.id, category: "Job")
            if !shoppingListItems.isEmpty {
                jobShoppingListDict[job] = shoppingListItems
            }
        }
        self.jobShoppingItems = jobShoppingListDict
    }
    func getCompanyUsers(companyId:String) async throws {
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: CompanyUserStatus.active.rawValue)
    }
    //Update
    func updateShoppingListItem(companyId:String) async throws {
        
    }
    func updateShoppingListDescription(companyId:String,shoppingListItemId:String,newDescription:String) async throws {
        try await dataService.updateShoppingListDescription(companyId: companyId, shoppingListItemId: shoppingListItemId, newDescription: newDescription)
    }
    //Delete
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await dataService.deleteShoppingListItem(companyId: companyId, shoppingListItemId: shoppingListItemId)
    }
    //Setters for private Functions
    func setOutstandingItemsForCurrentContext(_ items: [ShoppingListItem]) {
        self.outstandingItems = items
            .filter { $0.isOutstandingShoppingAction }
            .sortedForShoppingPrep()
    }

    func setRecentlyPurchasedItemsForCurrentContext(_ items: [ShoppingListItem]) {
        self.recentlyPurchasedItems = purchasedItemsSortedByRecency(from: items)
    }

    private func purchasedItemsSortedByRecency(from items: [ShoppingListItem]) -> [ShoppingListItem] {
        items
            .filter { item in
                item.status == .purchased
            }
            .sorted { lhs, rhs in
                purchaseRecencyDate(lhs) > purchaseRecencyDate(rhs)
            }
    }

    private func purchaseRecencyDate(_ item: ShoppingListItem) -> Date {
        item.datePurchased ?? item.actionDate ?? .distantPast
    }

    private func buildPrepKeys(
        category: ShoppingListCategory,
        jobId: String?,
        customerId: String?,
        userId: String?,
        serviceLocationId: String?
    ) -> [String] {
        var keys: [String] = []

        switch category {
        case .personal:
            if let userId, !userId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.user(userId))
            }

        case .customer:
            if let customerId, !customerId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.customer(customerId))
            }

            if let serviceLocationId, !serviceLocationId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.serviceLocation(serviceLocationId))
            }

        case .job:
            if let jobId, !jobId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.job(jobId))
            }

            if let customerId, !customerId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.customer(customerId))
            }

            if let serviceLocationId, !serviceLocationId.isEmpty {
                keys.append(ShoppingPrepKeyBuilder.serviceLocation(serviceLocationId))
            }
        }

        return Array(Set(keys))
    }
    func updateShoppingListStatus(
        companyId: String,
        shoppingListItemId: String,
        status: ShoppingListStatus
    ) async throws {
        try await dataService.updateShoppingListStatus(
            companyId: companyId,
            shoppingListItemId: shoppingListItemId,
            status: status,
            needsAction: status.needsShoppingAction
        )
    }
}

//MARK: Helper Functions
extension ShoppingListViewModel {
    /*
    func loadShoppingCenter(
        companyId: String,
        userId: String,
        routeServiceStops: [ServiceStop],
        includeAllOutstanding: Bool = false
    ) async throws {
        let allItems = try await dataService.getAllShoppingListItemsByCompany(companyId: companyId)

        self.allShoppingItems = allItems

        let prepContext = ShoppingRoutePrepContext(serviceStops: routeServiceStops)

        self.myItems = allItems.filter { item in
            item.category == .personal &&
            item.userId == userId &&
            item.isOutstandingShoppingAction
        }

        self.routeCustomerItems = allItems.filter { item in
            item.category == .customer &&
            item.isOutstandingShoppingAction &&
            item.matchesRoutePrepContext(prepContext)
        }

        self.routeJobItems = allItems.filter { item in
            item.category == .job &&
            item.isOutstandingShoppingAction &&
            item.matchesRoutePrepContext(prepContext)
        }

        self.routePrepItems = uniqueShoppingItems(
            myItems + routeCustomerItems + routeJobItems
        )

        self.outstandingItems = allItems.filter { item in
            item.isOutstandingShoppingAction &&
            (
                includeAllOutstanding ||
                item.purchaserId == userId ||
                item.userId == userId ||
                item.matchesRoutePrepContext(prepContext)
            )
        }

        self.purchasedButNotInstalledItems = allItems.filter { item in
            item.status.rawValue.localizedCaseInsensitiveContains("Purchased")
        }
    }
     */
}
private extension ShoppingListItem {
    func matchesRoutePrepContext(_ context: ShoppingRoutePrepContext) -> Bool {
        if let serviceStopId,
           !serviceStopId.isEmpty,
           context.serviceStopIds.contains(serviceStopId) {
            return true
        }

        if let serviceStopInternalId,
           !serviceStopInternalId.isEmpty,
           context.serviceStopInternalIds.contains(serviceStopInternalId) {
            return true
        }

        if let serviceLocationId,
           !serviceLocationId.isEmpty,
           context.serviceLocationIds.contains(serviceLocationId) {
            return true
        }

        if let customerId,
           !customerId.isEmpty,
           context.customerIds.contains(customerId) {
            return true
        }

        if let jobId,
           !jobId.isEmpty,
           context.jobIds.contains(jobId) {
            return true
        }

        return false
    }

    func isNeeded(
        in scope: ShoppingCenterTimeScope,
        referenceDate: Date,
        routeContext: ShoppingRoutePrepContext
    ) -> Bool {
        if scope == .today && matchesRoutePrepContext(routeContext) {
            return true
        }

        return isNeeded(in: scope, referenceDate: referenceDate)
    }
}
private func uniqueShoppingItems(_ items: [ShoppingListItem]) -> [ShoppingListItem] {
    var seen: Set<String> = []
    var result: [ShoppingListItem] = []

    for item in items {
        if !seen.contains(item.id) {
            seen.insert(item.id)
            result.append(item)
        }
    }

    return result
}
