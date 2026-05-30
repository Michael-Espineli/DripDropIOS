//
//  ShoppingPrepModels.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/25/26.
//
import Foundation

struct ShoppingRoutePrepContext: Hashable {
    var serviceStopIds: Set<String>
    var serviceStopInternalIds: Set<String>
    var serviceLocationIds: Set<String>
    var customerIds: Set<String>
    var jobIds: Set<String>

    init(serviceStops: [ServiceStop]) {
        self.serviceStopIds = Set(serviceStops.map { $0.id })
        self.serviceStopInternalIds = Set(serviceStops.map { $0.internalId }.filter { !$0.isEmpty })
        self.serviceLocationIds = Set(serviceStops.map { $0.serviceLocationId }.filter { !$0.isEmpty })
        self.customerIds = Set(serviceStops.map { $0.customerId }.filter { !$0.isEmpty })
        self.jobIds = Set(serviceStops.map { $0.jobId }.filter { !$0.isEmpty })
    }
}

struct ShoppingPrepSection: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var systemImage: String
    var items: [ShoppingListItem]
}
