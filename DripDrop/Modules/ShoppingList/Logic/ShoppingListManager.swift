//
//  ShoppingListManager.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/18/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import Darwin

struct ShoppingListItem: Identifiable, Codable, Hashable {
    var id: String

    var category: ShoppingListCategory
    var subCategory: ShoppingListSubCategory
    var status: ShoppingListStatus

    var purchaserId: String
    var purchaserName: String

    var genericItemId: String
    var productId: String? = nil
    var productName: String? = nil
    var name: String
    var description: String
    var datePurchased: Date?
    var quantity: String?

    // Job
    var jobId: String?

    // Customer
    var customerId: String?
    var customerName: String?
    var customerUserId: String? = nil

    // Personal
    var userId: String?
    var userName: String?

    // Route / prep context
    var serviceStopId: String? = nil
    var serviceStopInternalId: String? = nil
    var serviceLocationId: String? = nil
    var serviceLocationName: String? = nil
    var scheduledDate: Date? = nil
    
    // Efficient query support
    var prepKeys: [String] = []
    var needsAction: Bool = true
    var shoppingListActive: Bool = true
    var actionDate: Date? = nil
    var assignedTechIds: [String] = []
    var assignedTechId: String? = nil
    var assignedTechName: String? = nil
    var assignedToUserId: String? = nil
    var assignedToUserName: String? = nil

    // DataBaseItem
    var dbItemId: String?
    var dbItemName: String? = nil
    var itemId: String? = nil
    var itemType: String? = nil
    var purchasedItem: String?
    var invoiced: Bool
    var linkedTaskId: String?
    var linkedTaskName: String?
    var linkedTaskType: String?
    var linkedTaskStatus: String?
    var installedEquipmentId: String?
    var installedAt: Date?

    // Planned material pricing snapshot
    var plannedUnitCostCents: Int?
    var plannedUnitPriceCents: Int?
    var plannedTotalCostCents: Int?
    var plannedTotalPriceCents: Int?
    
}
extension ShoppingListItem {
    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case subCategory
        case status
        case purchaserId
        case purchaserName
        case genericItemId
        case productId
        case productName
        case name
        case description
        case datePurchased
        case quantity
        case jobId
        case customerId
        case customerName
        case customerUserId
        case userId
        case userName
        case serviceStopId
        case serviceStopInternalId
        case serviceLocationId
        case serviceLocationName
        case scheduledDate
        case prepKeys
        case needsAction
        case shoppingListActive
        case actionDate
        case assignedTechIds
        case assignedTechId
        case assignedTechName
        case assignedToUserId
        case assignedToUserName
        case dbItemId
        case dbItemName
        case itemId
        case itemType
        case purchasedItem
        case invoiced
        case linkedTaskId
        case linkedTaskName
        case linkedTaskType
        case linkedTaskStatus
        case installedEquipmentId
        case installedAt
        case plannedUnitCostCents
        case plannedUnitPriceCents
        case plannedTotalCostCents
        case plannedTotalPriceCents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedStatus = (try? container.decodeIfPresent(ShoppingListStatus.self, forKey: .status)) ?? .needToPurchase

        self.id = Self.decodeString(container, forKey: .id) ?? ""
        self.category = (try? container.decodeIfPresent(ShoppingListCategory.self, forKey: .category)) ?? .personal
        self.subCategory = (try? container.decodeIfPresent(ShoppingListSubCategory.self, forKey: .subCategory)) ?? .custom
        self.status = decodedStatus

        self.purchaserId = Self.decodeString(container, forKey: .purchaserId) ?? ""
        self.purchaserName = Self.decodeString(container, forKey: .purchaserName) ?? ""

        self.productId = Self.decodeString(container, forKey: .productId)
        self.productName = Self.decodeString(container, forKey: .productName)
        self.dbItemId = Self.decodeString(container, forKey: .dbItemId)
        self.dbItemName = Self.decodeString(container, forKey: .dbItemName)
        self.itemId = Self.decodeString(container, forKey: .itemId)
        self.itemType = Self.decodeString(container, forKey: .itemType)

        let decodedGenericItemId = Self.decodeString(container, forKey: .genericItemId)
        self.genericItemId = decodedGenericItemId ?? productId ?? dbItemId ?? itemId ?? ""
        self.name = Self.decodeString(container, forKey: .name) ?? productName ?? dbItemName ?? ""
        self.description = Self.decodeString(container, forKey: .description) ?? ""
        self.datePurchased = Self.decodeDate(container, forKey: .datePurchased)
        self.quantity = Self.decodeString(container, forKey: .quantity)

        self.jobId = Self.decodeString(container, forKey: .jobId)
        self.customerId = Self.decodeString(container, forKey: .customerId)
        self.customerName = Self.decodeString(container, forKey: .customerName)
        self.customerUserId = Self.decodeString(container, forKey: .customerUserId)
        self.userId = Self.decodeString(container, forKey: .userId)
        self.userName = Self.decodeString(container, forKey: .userName)

        self.serviceStopId = Self.decodeString(container, forKey: .serviceStopId)
        self.serviceStopInternalId = Self.decodeString(container, forKey: .serviceStopInternalId)
        self.serviceLocationId = Self.decodeString(container, forKey: .serviceLocationId)
        self.serviceLocationName = Self.decodeString(container, forKey: .serviceLocationName)
        self.scheduledDate = Self.decodeDate(container, forKey: .scheduledDate)

        self.prepKeys = (try? container.decodeIfPresent([String].self, forKey: .prepKeys)) ?? []
        self.needsAction = (try? container.decodeIfPresent(Bool.self, forKey: .needsAction)) ?? decodedStatus.needsShoppingAction
        self.shoppingListActive = (try? container.decodeIfPresent(Bool.self, forKey: .shoppingListActive)) ?? true
        self.actionDate = Self.decodeDate(container, forKey: .actionDate)
        self.assignedTechIds = (try? container.decodeIfPresent([String].self, forKey: .assignedTechIds)) ?? []
        self.assignedTechId = Self.decodeString(container, forKey: .assignedTechId)
        self.assignedTechName = Self.decodeString(container, forKey: .assignedTechName)
        self.assignedToUserId = Self.decodeString(container, forKey: .assignedToUserId)
        self.assignedToUserName = Self.decodeString(container, forKey: .assignedToUserName)

        self.purchasedItem = Self.decodeString(container, forKey: .purchasedItem)
        self.invoiced = (try? container.decodeIfPresent(Bool.self, forKey: .invoiced)) ?? false
        self.linkedTaskId = Self.decodeString(container, forKey: .linkedTaskId)
        self.linkedTaskName = Self.decodeString(container, forKey: .linkedTaskName)
        self.linkedTaskType = Self.decodeString(container, forKey: .linkedTaskType)
        self.linkedTaskStatus = Self.decodeString(container, forKey: .linkedTaskStatus)
        self.installedEquipmentId = Self.decodeString(container, forKey: .installedEquipmentId)
        self.installedAt = Self.decodeDate(container, forKey: .installedAt)

        self.plannedUnitCostCents = Self.decodeInt(container, forKey: .plannedUnitCostCents)
        self.plannedUnitPriceCents = Self.decodeInt(container, forKey: .plannedUnitPriceCents)
        self.plannedTotalCostCents = Self.decodeInt(container, forKey: .plannedTotalCostCents)
        self.plannedTotalPriceCents = Self.decodeInt(container, forKey: .plannedTotalPriceCents)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
        try container.encode(subCategory, forKey: .subCategory)
        try container.encode(status, forKey: .status)
        try container.encode(purchaserId, forKey: .purchaserId)
        try container.encode(purchaserName, forKey: .purchaserName)
        try container.encode(genericItemId, forKey: .genericItemId)
        try container.encodeIfPresent(productId, forKey: .productId)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(datePurchased, forKey: .datePurchased)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(jobId, forKey: .jobId)
        try container.encodeIfPresent(customerId, forKey: .customerId)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(customerUserId, forKey: .customerUserId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(serviceStopId, forKey: .serviceStopId)
        try container.encodeIfPresent(serviceStopInternalId, forKey: .serviceStopInternalId)
        try container.encodeIfPresent(serviceLocationId, forKey: .serviceLocationId)
        try container.encodeIfPresent(serviceLocationName, forKey: .serviceLocationName)
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encode(prepKeys, forKey: .prepKeys)
        try container.encode(needsAction, forKey: .needsAction)
        try container.encode(shoppingListActive, forKey: .shoppingListActive)
        try container.encodeIfPresent(actionDate, forKey: .actionDate)
        try container.encode(assignedTechIds, forKey: .assignedTechIds)
        try container.encodeIfPresent(assignedTechId, forKey: .assignedTechId)
        try container.encodeIfPresent(assignedTechName, forKey: .assignedTechName)
        try container.encodeIfPresent(assignedToUserId, forKey: .assignedToUserId)
        try container.encodeIfPresent(assignedToUserName, forKey: .assignedToUserName)
        try container.encodeIfPresent(dbItemId, forKey: .dbItemId)
        try container.encodeIfPresent(dbItemName, forKey: .dbItemName)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encodeIfPresent(itemType, forKey: .itemType)
        try container.encodeIfPresent(purchasedItem, forKey: .purchasedItem)
        try container.encode(invoiced, forKey: .invoiced)
        try container.encodeIfPresent(linkedTaskId, forKey: .linkedTaskId)
        try container.encodeIfPresent(linkedTaskName, forKey: .linkedTaskName)
        try container.encodeIfPresent(linkedTaskType, forKey: .linkedTaskType)
        try container.encodeIfPresent(linkedTaskStatus, forKey: .linkedTaskStatus)
        try container.encodeIfPresent(installedEquipmentId, forKey: .installedEquipmentId)
        try container.encodeIfPresent(installedAt, forKey: .installedAt)
        try container.encodeIfPresent(plannedUnitCostCents, forKey: .plannedUnitCostCents)
        try container.encodeIfPresent(plannedUnitPriceCents, forKey: .plannedUnitPriceCents)
        try container.encodeIfPresent(plannedTotalCostCents, forKey: .plannedTotalCostCents)
        try container.encodeIfPresent(plannedTotalPriceCents, forKey: .plannedTotalPriceCents)
    }

    private static func decodeString(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let string = try? container.decodeIfPresent(String.self, forKey: key) {
            return string
        }

        if let int = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(int)
        }

        if let double = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(double)
        }

        return nil
    }

    private static func decodeDate(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Date? {
        try? container.decodeIfPresent(Date.self, forKey: key)
    }

    private static func decodeInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let int = try? container.decodeIfPresent(Int.self, forKey: key) {
            return int
        }

        if let double = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Int(double)
        }

        if let string = decodeString(container, forKey: key) {
            return Int(string)
        }

        return nil
    }
}
extension ShoppingListItem {
    var computedNeedsAction: Bool {
        status.needsShoppingAction
    }

    var isOutstandingShoppingAction: Bool {
        shoppingListActive && needsAction && status.needsShoppingAction
    }

    var shoppingNeedDate: Date? {
        scheduledDate ?? actionDate ?? datePurchased
    }

    func isAssociatedWithShoppingUser(_ userId: String) -> Bool {
        let cleanUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUserId.isEmpty else { return false }

        return purchaserId == cleanUserId ||
        self.userId == cleanUserId ||
        assignedTechIds.contains(cleanUserId) ||
        assignedTechId == cleanUserId ||
        assignedToUserId == cleanUserId ||
        prepKeys.contains(ShoppingPrepKeyBuilder.user(cleanUserId))
    }

    func isNeeded(
        in scope: ShoppingCenterTimeScope,
        referenceDate: Date = Date()
    ) -> Bool {
        switch scope {
        case .all:
            return true

        case .today:
            guard let needDate = shoppingNeedDate else { return true }
            let startOfTomorrow = Calendar.current.date(
                byAdding: .day,
                value: 1,
                to: Calendar.current.startOfDay(for: referenceDate)
            ) ?? referenceDate

            return needDate < startOfTomorrow

        case .thisWeek:
            guard let needDate = shoppingNeedDate else { return true }
            let weekStart = Calendar.current.dateInterval(
                of: .weekOfYear,
                for: referenceDate
            )?.start ?? Calendar.current.startOfDay(for: referenceDate)
            let startOfNextWeek = Calendar.current.date(
                byAdding: .day,
                value: 7,
                to: weekStart
            ) ?? referenceDate

            return needDate < startOfNextWeek
        }
    }
}
extension ShoppingListStatus {
    var needsShoppingAction: Bool {
        switch self {
        case .delivered, .installed, .invoiced:
            return false
        case .needToPurchase, .purchased:
            return true
        }
    }
}
protocol ShoppingListManagerProtocol {
    func addNewShoppingListItem(companyId:String,shoppingListItem:ShoppingListItem) async throws
    
    func getSpecificShoppingListItem(companyId:String,shoppingListItemId:String) async throws -> ShoppingListItem
    func getAllShoppingListItemsByCompany(companyId:String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUser(companyId:String,userId:String) async throws  -> [ShoppingListItem]
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws
}

final class MockShoppingListtManager:ShoppingListManagerProtocol {
  
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        
    }
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        print("Successfully addNewShoppingListItemWithValidation")

    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return ShoppingListItem(
            id: "",
            category: .customer,
            subCategory: .chemical,
            status: .needToPurchase,
            purchaserId: "",
            purchaserName: "",
            genericItemId: "",
            name: "",
            description:"",
            invoiced: true
        )
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByCompany")
        return []
    }
    
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByUser")
        return []

    }
    
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        print("Successfully getAllShoppingListItemsByUserForCategory")
        return []
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        return 8
    }
}

final class ShoppingListManager:ShoppingListManagerProtocol {


    static let shared = ShoppingListManager()
    init(){}
    private let db = Firestore.firestore()
    private var chatListener: ListenerRegistration? = nil
    private var messageListener: ListenerRegistration? = nil

    //----------------------------------------------------
    //                    COLLECTIONS
    //----------------------------------------------------
    private func shoppingListCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/shoppingList")
    }
    //----------------------------------------------------
    //                    DOCUMENTS
    //----------------------------------------------------
    private func shoppingListDoc(companyId:String,shoppingListItemId:String)-> DocumentReference{
        shoppingListCollection(companyId: companyId).document(shoppingListItemId)
    }
    //CRUD
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        try shoppingListCollection(companyId: companyId).document(shoppingListItem.id).setData(from:shoppingListItem, merge: false)

    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).getDocument(as: ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .getDocuments(as:ShoppingListItem.self)
    }
    
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .getDocuments(as:ShoppingListItem.self)
            .filter { $0.shoppingListActive }
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        let items = try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .getDocuments(as:ShoppingListItem.self)

        return items.filter { $0.isOutstandingShoppingAction }.count
    }
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
            .filter { $0.shoppingListActive }
    }

    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).delete()

    }
    
}
