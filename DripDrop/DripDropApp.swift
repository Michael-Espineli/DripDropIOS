//
//  DripDropApp.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI
import Firebase
import StripeCore
import BackgroundTasks

@main
struct DripDropApp: App {
  
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase

    @StateObject private var navigationManager = NavigationStateManager()
    @StateObject private var masterDataManager = MasterDataManager(dataService: ProductionDataService())
    @StateObject private var dataService = ProductionDataService()
    @StateObject private var masterRoleManager = MasterRoleManager(dataService: ProductionDataService())
//    @StateObject private var dataService = MockDataService()

    static let fleetDataService = FleetManager()
    
    func background() {
       print("App Entering Background")
    }
    func foreground() {
       print("App Entering Foreground")
    }
    var body: some Scene {
        WindowGroup {
            RootView(dataService: dataService)
                .onOpenURL { incomingURL in
                    handleIncomingURL(incomingURL)
                }
            //                .onOpenURL { incomingURL in
            //                    let stripeHandled = StripeAPI.handleURLCallback(with: incomingURL)
            //                    if (!stripeHandled) {
            //                        let routeFinder = RouteFinder()
            //                         if let route = routeFinder.find2(from: incomingURL) {
            //                             navigationManager.selectedCategory = route.category
            //                             navigationManager.selectedID = route.id
            //                         }
            //                    }
            //                  }
                .environmentObject(masterDataManager)
                .environmentObject(navigationManager)
                .environmentObject(dataService)
                .environmentObject(masterRoleManager)
                .onChange(of: phase) { newPhase in
                        switch newPhase {
                        case .background: background()
                        case .active: foreground()
                        default: break
                        }
                    }
           
        }
    }

    private func handleIncomingURL(_ incomingURL: URL) {
        if StripeAPI.handleURLCallback(with: incomingURL) {
            return
        }

        let routeFinder = RouteFinder()
        if let sharedReference = routeFinder.findSharedRecordReference(from: incomingURL) {
            Task { @MainActor in
                await openSharedRecord(sharedReference)
            }
            return
        }

        if let route = routeFinder.find2(from: incomingURL) {
            Task { @MainActor in
                masterDataManager.selectedCategory = route.category
                masterDataManager.selectedID = route.id
            }
        }
    }

    @MainActor
    private func openSharedRecord(_ reference: SharedRecordReference) async {
        masterDataManager.selectedCategory = reference.category
        masterDataManager.selectedID = reference.recordId

        guard let route = await routeForSharedRecord(reference) else {
            if let fallback = fallbackRoute(for: reference.category) {
                navigationManager.replace(stack: [fallback])
            }
            return
        }

        navigationManager.replace(stack: [route])
    }

    @MainActor
    private func routeForSharedRecord(_ reference: SharedRecordReference) async -> Route? {
        let companyId = reference.companyId ?? masterDataManager.currentCompany?.id ?? ""
        let recordId = reference.chatId ?? reference.recordId

        do {
            switch reference.routeString {
            case .chat:
                let item = try await dataService.getSpecificChat(chatId: recordId)
                masterDataManager.selectedChat = item
                return Route.chat(chat: item, dataService: dataService)
            case .customer where !companyId.isEmpty:
                let item = try await dataService.getCustomerById(companyId: companyId, customerId: reference.recordId)
                masterDataManager.selectedCustomer = item
                return Route.customer(customer: item, dataService: dataService)
            case .equipmentDetailView where !companyId.isEmpty:
                let item = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: reference.recordId)
                masterDataManager.selectedEquipment = item
                return Route.equipmentDetailView(equipment: item, dataService: dataService)
            case .repairRequest where !companyId.isEmpty:
                let item = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: reference.recordId)
                masterDataManager.selectedRepairRequest = item
                return Route.repairRequest(repairRequest: item, dataService: dataService)
            case .serviceStop where !companyId.isEmpty:
                let item = try await dataService.getServiceStopById(serviceStopId: reference.recordId, companyId: companyId)
                masterDataManager.selectedServiceStops = item
                return Route.serviceStop(serviceStop: item, dataService: dataService)
            case .job where !companyId.isEmpty:
                let item = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: reference.recordId)
                masterDataManager.selectedJob = item
                return Route.job(job: item, dataService: dataService)
            case .purchase where !companyId.isEmpty:
                let item = try await dataService.getSingleItem(itemId: reference.recordId, companyId: companyId)
                masterDataManager.selectedPurchases = item
                return Route.purchase(purchasedItem: item, dataService: dataService)
            case .shoppingListDetail where !companyId.isEmpty:
                let item = try await dataService.getSpecificShoppingListItem(companyId: companyId, shoppingListItemId: reference.recordId)
                masterDataManager.selectedShoppingListItem = item
                return Route.shoppingListDetail(item: item, dataService: dataService)
            case .dataBaseItem where !companyId.isEmpty:
                let item = try await dataService.getDataBaseItem(companyId: companyId, dataBaseItemId: reference.recordId)
                masterDataManager.selectedDataBaseItem = item
                return Route.dataBaseItem(dataBaseItem: item, dataService: dataService)
            case .receipt where !companyId.isEmpty:
                let item = try await dataService.getReceipt(companyId: companyId, receiptId: reference.recordId)
                masterDataManager.selectedReceipt = item
                return Route.receipt(receipt: item, dataService: dataService)
            case .vender where !companyId.isEmpty:
                let item = try await dataService.getSingleStore(companyId: companyId, storeId: reference.recordId)
                masterDataManager.selectedVender = item
                return Route.vender(vender: item, dataService: dataService)
            case .accountsReceivableDetail where !companyId.isEmpty:
                let item = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: reference.recordId)
                masterDataManager.selectedAccountsReceivableInvoice = item
                return Route.accountsReceivableDetail(invoice: item, dataService: dataService)
            case .companyUserDetailView where !companyId.isEmpty:
                let item = try await dataService.getCompanyUserById(companyId: companyId, companyUserId: reference.recordId)
                masterDataManager.selectedCompanyUser = item
                return Route.companyUserDetailView(user: item, dataService: dataService)
            default:
                return fallbackRoute(for: reference.category)
            }
        } catch {
            print("[DripDropApp][openSharedRecord] \(error)")
            return fallbackRoute(for: reference.category)
        }
    }

    private func fallbackRoute(for category: MacCategories) -> Route? {
        switch category {
        case .customers:
            return Route.customers(dataService: dataService)
        case .equipment:
            return Route.equipmentList(dataService: dataService)
        case .repairRequest:
            return Route.repairRequestList(dataService: dataService)
        case .serviceStops:
            return Route.serviceStops(dataService: dataService)
        case .jobs:
            return Route.jobs(dataService: dataService)
        case .purchases:
            return Route.purchases(dataService: dataService)
        case .shoppingList:
            return Route.shoppingList(dataService: dataService)
        case .databaseItems:
            return Route.databaseItems(dataService: dataService)
        case .receipts:
            return Route.receipts(dataService: dataService)
        case .vender:
            return Route.venders(dataService: dataService)
        case .companyUser, .users:
            return Route.users(dataService: dataService)
        case .accountsReceivable:
            return Route.accountsReceivableList(dataService: dataService)
        case .chat:
            return Route.chats(dataService: dataService)
        case .alerts:
            return Route.alerts(dataService: dataService)
        default:
            return nil
        }
    }
}

