//
//  RouteBoardViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/7/26.
//

import Foundation
@MainActor
final class RouteBoardViewModel: ObservableObject {

    @Published var companyUsers: [CompanyUser] = []
    @Published var recurringRoutes: [RecurringRoute] = []
    @Published var recurringStops: [RecurringServiceStop] = []

    private var listeners: [ListenerRegistration] = []

    let dataService: ProductionDataServiceProtocol

    init(dataService: ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    func start(companyId: String) {
        listenCompanyUsers(companyId: companyId)
        listenRecurringRoutes(companyId: companyId)
        listenRecurringStops(companyId: companyId)
    }

    func stop() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}
