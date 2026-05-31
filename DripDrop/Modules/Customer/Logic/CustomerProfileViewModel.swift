//
//  CustomerProfileViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class CustomerProfileViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published var recurringServiceStops: [RecurringServiceStop] = []
    @Published var repairRequest: [RepairRequest] = []
    @Published var jobs: [Job] = []
    @Published var shoppingListItems: [ShoppingListItem] = []
    @Published var serviceStops: [ServiceStop] = []

    // For Service Stop Detail View
    @Published var serviceLocation: ServiceLocation? = nil

    private var recurringServiceStopsListener: ListenerRegistration?
    private var repairRequestsListener: ListenerRegistration?
    private var jobsListener: ListenerRegistration?

    deinit {
        recurringServiceStopsListener?.remove()
        repairRequestsListener?.remove()
        jobsListener?.remove()
        dataService.removeListenerForAllServiceStops()
    }

    // MARK: - Initial Load

    func onLoad(companyId: String, customerId: String) async throws {
        print("")
        print("[CustomerProfileViewModel][onLoad] customerId: \(customerId) companyId: \(companyId)")

        startUpcomingWorkListeners(companyId: companyId, customerId: customerId)

        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(
            companyId: companyId,
            customerId: customerId
        )

        print("")
        print("[CustomerProfileViewModel][onLoad] shoppingListItems: \(shoppingListItems.count)")
    }

    // MARK: - Live Upcoming Work Listeners

    func startUpcomingWorkListeners(companyId: String, customerId: String) {
        print("")
        print("[CustomerProfileViewModel][startUpcomingWorkListeners] customerId: \(customerId) companyId: \(companyId)")

        stopUpcomingWorkListeners()

        listenToRecurringServiceStops(companyId: companyId, customerId: customerId)
        listenToRepairRequests(companyId: companyId, customerId: customerId)
        listenToJobs(companyId: companyId, customerId: customerId)
        listenToFutureCustomerServiceStops(companyId: companyId, customerId: customerId)
    }

    func stopUpcomingWorkListeners() {
        recurringServiceStopsListener?.remove()
        recurringServiceStopsListener = nil

        repairRequestsListener?.remove()
        repairRequestsListener = nil

        jobsListener?.remove()
        jobsListener = nil

        dataService.removeListenerForAllServiceStops()
    }

    private func listenToRecurringServiceStops(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        recurringServiceStopsListener = db
            .collection("companies")
            .document(companyId)
            .collection("recurringServiceStop")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToRecurringServiceStops] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.recurringServiceStops = []
                    }
                    return
                }

                let stops: [RecurringServiceStop] = documents.compactMap { document in
                    do {
                        return try document.data(as: RecurringServiceStop.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToRecurringServiceStops] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.recurringServiceStops = stops.sorted {
                        $0.startDate < $1.startDate
                    }

                    print("")
                    print("[CustomerProfileViewModel][listenToRecurringServiceStops] recurringServiceStops: \(self.recurringServiceStops.count)")
                }
            }
    }

    private func listenToRepairRequests(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        repairRequestsListener = db
            .collection("companies")
            .document(companyId)
            .collection("repairRequests")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToRepairRequests] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.repairRequest = []
                    }
                    return
                }

                let repairs: [RepairRequest] = documents.compactMap { document in
                    do {
                        return try document.data(as: RepairRequest.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToRepairRequests] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.repairRequest = repairs

                    print("")
                    print("[CustomerProfileViewModel][listenToRepairRequests] repairRequest: \(self.repairRequest.count)")
                }
            }
    }

    private func listenToJobs(companyId: String, customerId: String) {
        let db = Firestore.firestore()

        jobsListener = db
            .collection("companies")
            .document(companyId)
            .collection("jobs")
            .whereField("customerId", isEqualTo: customerId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("[CustomerProfileViewModel][listenToJobs] Error: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.jobs = []
                    }
                    return
                }

                let jobs: [Job] = documents.compactMap { document in
                    do {
                        return try document.data(as: Job.self)
                    } catch {
                        print("[CustomerProfileViewModel][listenToJobs] Decode Error: \(error)")
                        return nil
                    }
                }

                Task { @MainActor in
                    self.jobs = jobs

                    print("")
                    print("[CustomerProfileViewModel][listenToJobs] jobs: \(self.jobs.count)")
                }
            }
    }

    private func listenToFutureCustomerServiceStops(companyId: String, customerId: String) {
        dataService.removeListenerForAllServiceStops()

        dataService.addListenerForFutureCustomerServiceStops(
            companyId: companyId,
            customerId: customerId
        ) { [weak self] stops in
            Task { @MainActor in
                self?.serviceStops = stops.sorted {
                    $0.serviceDate < $1.serviceDate
                }

                print("")
                print("[CustomerProfileViewModel][listenToFutureCustomerServiceStops] serviceStops: \(self?.serviceStops.count ?? 0)")
            }
        }
    }

    // MARK: - Service Stop Detail

    func onLoadCustomerProfileView(companyId: String?, serviceStop: ServiceStop) {
        guard let companyId else { return }

        Task {
            do {
                self.serviceLocation = try await dataService.getServiceLocationById(
                    companyId: companyId,
                    locationId: serviceStop.serviceLocationId
                )
            } catch {
                print("  [CustomerProfileViewModel][onLoadCustomerProfileView] Error \(error)")
            }
        }
    }

    // MARK: - Deletes

    func deleteRecurringServiceStop(companyId: String, RecurringServiceStopId: String) async throws {
        print("")
        print("[CustomerProfileViewModel][deleteRecurringServiceStop] Delete")
        print(RecurringServiceStopId)

        let serviceStopList = try await dataService.getAllServiceStopsByRecurringServiceStopsAfterToday(
            companyId: companyId,
            recurringServiceStopId: RecurringServiceStopId
        )

        for stop in serviceStopList {
            try await dataService.deleteServiceStop(companyId: companyId, serviceStop: stop)
        }

        try await dataService.deleteRecurringServiceStop(
            companyId: companyId,
            recurringServiceStopId: RecurringServiceStopId
        )

        print("[CustomerProfileViewModel][deleteRecurringServiceStop] Successful")
        print("")
    }

    // MARK: - Manual Reloads

    func reloadShoppingListItem(companyId: String, customerId: String) async throws {
        self.shoppingListItems = try await dataService.getAllShoppingListItemsByCompanyCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadJobs(companyId: String, customerId: String) async throws {
        self.jobs = try await dataService.getAllJobsByCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadRepairRequests(companyId: String, customerId: String) async throws {
        self.repairRequest = try await dataService.getRepairRequestsByCustomer(
            companyId: companyId,
            customerId: customerId
        )
    }

    func reloadRecurringServiceStops(companyId: String, customerId: String) async throws {
        self.recurringServiceStops = try await dataService.getAllRecurringServiceStopByCustomerId(
            companyId: companyId,
            customerId: customerId
        )
    }
}
