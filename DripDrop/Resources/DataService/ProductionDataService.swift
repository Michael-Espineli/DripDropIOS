    //
    //  ProductionDataService.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 4/22/24.
    //

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage

@MainActor
final class ProductionDataService:ProductionDataServiceProtocol,ObservableObject {


    var storage = Storage.storage().reference()
    let id = UUID().uuidString

    func getFeatureFlags() async throws -> [FeatureFlag] {
        let snapshot = try await db
            .collection("featureFlags")
            .order(by: "index")
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: FeatureFlag.self)
        }
    }

    func getFeatureFlag(flagId: String) async throws -> FeatureFlag? {
        let snapshot = try await db
            .collection("featureFlags")
            .document(flagId)
            .getDocument()

        guard snapshot.exists else { return nil }

        return try snapshot.data(as: FeatureFlag.self)
    }

    func isFeatureFlagEnabled(_ flagId: String) async throws -> Bool {
        try await getFeatureFlag(flagId: flagId)?.enabled ?? false
    }

    private func getCustomerSalesDocuments<T: Decodable>(
        collectionName: String,
        companyId: String,
        customerId: String,
        as type: T.Type
    ) async throws -> [T] {
        guard !companyId.isEmpty, !customerId.isEmpty else { return [] }

        let snapshot = try await db
            .collection(collectionName)
            .whereField("companyId", isEqualTo: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: T.self)
        }
    }

    func getSalesAgreements(companyId: String, customerId: String) async throws -> [SalesAgreement] {
        try await getCustomerSalesDocuments(
            collectionName: "salesAgreements",
            companyId: companyId,
            customerId: customerId,
            as: SalesAgreement.self
        )
    }

    func getSalesBillingSubscriptions(companyId: String, customerId: String) async throws -> [SalesBillingSubscription] {
        try await getCustomerSalesDocuments(
            collectionName: "salesBillingSubscriptions",
            companyId: companyId,
            customerId: customerId,
            as: SalesBillingSubscription.self
        )
    }

    func getSalesInvoices(companyId: String, customerId: String) async throws -> [SalesInvoice] {
        try await getCustomerSalesDocuments(
            collectionName: "salesInvoices",
            companyId: companyId,
            customerId: customerId,
            as: SalesInvoice.self
        )
    }

    func getSalesPayments(companyId: String, customerId: String) async throws -> [SalesPayment] {
        try await getCustomerSalesDocuments(
            collectionName: "salesPayments",
            companyId: companyId,
            customerId: customerId,
            as: SalesPayment.self
        )
    }

    func getNextPayStatementNumber(companyId: String) async throws -> Int {
        return try await getNextCompanyIncrement(
            companyId: companyId,
            category: "payStatements"
        )
    }

    func getNextPayLineItemNumber(companyId: String) async throws -> Int {
        return try await getNextCompanyIncrement(
            companyId: companyId,
            category: "payLineItems"
        )
    }
    func getNextCompanyIncrement(
        companyId: String,
        category: String
    ) async throws -> Int {
        let db = Firestore.firestore()

        let ref = db
            .collection("companies")
            .document(companyId)
            .collection("settings")
            .document(category)

        return try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(ref)

                let currentIncrement: Int

                if snapshot.exists {
                    let increment = try snapshot.data(as: Increment.self)
                    currentIncrement = increment.increment
                } else {
                    currentIncrement = 0
                }

                let nextIncrement = currentIncrement + 1

                let updated = Increment(
                    category: category,
                    increment: nextIncrement
                )

                try transaction.setData(from: updated, forDocument: ref, merge: false)

                return nextIncrement
            } catch {
                errorPointer?.pointee = error as NSError
                return 0
            }
        } as? Int ?? 0
    }
    func updateShoppingListStatus(
        companyId: String,
        shoppingListItemId: String,
        status: ShoppingListStatus,
        needsAction: Bool
    ) async throws {
        try await db
            .collection("companies")
            .document(companyId)
            .collection("shoppingList")
            .document(shoppingListItemId)
            .updateData([
                "status": status.rawValue,
                "needsAction": needsAction
            ])
    }
    
    // MARK: - ShoppingList
    func getOutstandingShoppingListItemsPage(
        companyId: String,
        limit: Int = 100
    ) async throws -> [ShoppingListItem] {
        let snapshot = try await db
            .collection("companies")
            .document(companyId)
            .collection("shoppingList")
            .whereField("needsAction", isEqualTo: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            try? document.data(as: ShoppingListItem.self)
        }
    }
    func getShoppingListItemsForPrepKeys(
        companyId: String,
        prepKeys: [String],
        needsAction: Bool = true
    ) async throws -> [ShoppingListItem] {

        guard !prepKeys.isEmpty else { return [] }

        var results: [ShoppingListItem] = []
        let chunks = prepKeys.chunked(into: 10)

        for chunk in chunks {
            let snapshot = try await db
                .collection("companies")
                .document(companyId)
                .collection("shoppingList")
                .whereField("needsAction", isEqualTo: needsAction)
                .whereField("prepKeys", arrayContainsAny: chunk)
                .getDocuments()

            let items = snapshot.documents.compactMap { document in
                try? document.data(as: ShoppingListItem.self)
            }

            results.append(contentsOf: items)
        }

        return results.dedupedById()
    }
    // MARK: - Job Templates

    func fetchJobTemplates(
        companyId: String
    ) async throws -> [JobTemplate] {
        let snapshot = try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: JobTemplate.self)
        }
        .sorted { $0.name < $1.name }
    }

    func fetchJobTemplate(
        companyId: String,
        templateId: String
    ) async throws -> JobTemplate {
        try await WorkOrderDocument(workOrderTemplateId: templateId, companyId: companyId)
        .getDocument(as: JobTemplate.self)
    }

    func saveJobTemplate(
        _ template: JobTemplate
    ) async throws {
        try WorkOrderDocument(workOrderTemplateId: template.id, companyId: template.companyId)
        .setData(from: template, merge: true)
    }

    func saveJobTemplatePlannedServiceStops(
        _ plannedStops: [JobTemplatePlannedServiceStop]
    ) async throws {
        for plannedStop in plannedStops {
            try jobTemplatePlannedServiceStopDoc(
                companyId: plannedStop.companyId,
                templateId: plannedStop.templateId,
                plannedStopId: plannedStop.id
            )
            .setData(from: plannedStop, merge: true)
        }
    }

    func saveJobTemplateTasks(
        _ tasks: [JobTemplateTask]
    ) async throws {
        for task in tasks {
            try jobTemplateTaskDoc(
                companyId: task.companyId,
                templateId: task.templateId,
                templateTaskId: task.id
            )
            .setData(from: task, merge: true)
        }
    }

    func saveJobTemplateShoppingItems(
        _ items: [JobTemplateShoppingItem]
    ) async throws {
        for item in items {
            try jobTemplateShoppingItemDoc(
                companyId: item.companyId,
                templateId: item.templateId,
                templateShoppingItemId: item.id
            )
            .setData(from: item, merge: true)
        }
    }

    func fetchJobTemplatePlannedServiceStops(
        companyId: String,
        templateId: String
    ) async throws -> [JobTemplatePlannedServiceStop] {
        let snapshot = try await jobTemplatePlannedServiceStopsCollection(
            companyId: companyId,
            templateId: templateId
        )
        .order(by: "sortOrder", descending: false)
        .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: JobTemplatePlannedServiceStop.self)
        }
    }

    func fetchJobTemplateTasks(
        companyId: String,
        templateId: String
    ) async throws -> [JobTemplateTask] {
        let snapshot = try await jobTemplateTasksCollection(
            companyId: companyId,
            templateId: templateId
        )
        .order(by: "sortOrder", descending: false)
        .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: JobTemplateTask.self)
        }
    }

    func fetchJobTemplateShoppingItems(
        companyId: String,
        templateId: String
    ) async throws -> [JobTemplateShoppingItem] {
        let snapshot = try await jobTemplateShoppingItemsCollection(
            companyId: companyId,
            templateId: templateId
        )
        .order(by: "sortOrder", descending: false)
        .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: JobTemplateShoppingItem.self)
        }
    }
    // MARK: - Job Copy Helpers

    func saveJobPlannedServiceStops(
        _ plannedStops: [JobPlannedServiceStop]
    ) async throws {
        for plannedStop in plannedStops {
            try jobPlannedServiceStopDoc(
                companyId: plannedStop.companyId,
                jobId: plannedStop.jobId,
                plannedServiceStopId: plannedStop.id
            )
            .setData(from: plannedStop, merge: true)
        }
    }

    func saveJobTasks(
        companyId: String,
        jobId: String,
        tasks: [JobTask]
    ) async throws {
        for task in tasks {
            try workOrderTaskDocument(companyId: companyId, workOrderId: jobId, taskId: task.id)
            .setData(from: task, merge: true)
        }
    }

    func saveShoppingListItems(
        companyId: String,
        items: [ShoppingListItem]
    ) async throws {
        for item in items {
            try shoppingListDoc(
                companyId: companyId,
                shoppingListItemId: item.id
            )
            .setData(from: item, merge: true)
        }
    }
    
    // MARK: - Planned Service stops
    func fetchJobPlannedServiceStops(
        companyId: String,
        jobId: String
    ) async throws -> [JobPlannedServiceStop] {
        let snapshot = try await jobPlannedServiceStopsCollection(
            companyId: companyId,
            jobId: jobId
        )
        .order(by: "sortOrder", descending: false)
        .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: JobPlannedServiceStop.self)
        }
    }

    func saveJobPlannedServiceStop(
        _ plannedStop: JobPlannedServiceStop
    ) async throws {
        try jobPlannedServiceStopDoc(
            companyId: plannedStop.companyId,
            jobId: plannedStop.jobId,
            plannedServiceStopId: plannedStop.id
        )
        .setData(from: plannedStop, merge: true)
    }

    func deleteJobPlannedServiceStop(
        companyId: String,
        jobId: String,
        plannedServiceStopId: String
    ) async throws {
        try await jobPlannedServiceStopDoc(
            companyId: companyId,
            jobId: jobId,
            plannedServiceStopId: plannedServiceStopId
        )
        .delete()
    }
    // MARK: - Work Offers
    func fetchCompanyServiceStopType(
        companyId: String,
        serviceStopTypeId: String
    ) async throws -> CompanyServiceStopType {
        try await companyServiceStopTypeDoc(
            companyId: companyId,
            serviceStopTypeId: serviceStopTypeId
        )
        .getDocument(as: CompanyServiceStopType.self)
    }
    func fetchServiceStopsForTechnician(
        companyId: String,
        technicianId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [ServiceStop] {
        let snapshot = try await serviceStopsCollection(companyId: companyId)
            .whereField("techId", isEqualTo: technicianId)
            .whereField("serviceDate", isGreaterThanOrEqualTo: startDate)
            .whereField("serviceDate", isLessThanOrEqualTo: endDate)
            .order(by: "serviceDate", descending: false)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: ServiceStop.self)
        }
    }
    func fetchAcceptedWorkOffersForUser(
        companyId: String,
        userId: String
    ) async throws -> [WorkOffer] {
        let snapshot = try await workOffersCollection(companyId: companyId)
            .whereField("acceptedByUserId", isEqualTo: userId)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: WorkOffer.self)
        }
    }
    func fetchWorkOffers(
        companyId: String,
        jobId: String
    ) async throws -> [WorkOffer] {
        let snapshot = try await workOffersCollection(companyId: companyId)
            .whereField("jobId", isEqualTo: jobId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: WorkOffer.self)
        }
    }

    func fetchWorkOffersForUser(
        companyId: String,
        userId: String
    ) async throws -> [WorkOffer] {
        let snapshot = try await workOffersCollection(companyId: companyId)
            .whereField("offeredToUserId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: WorkOffer.self)
        }
    }

    func fetchOpenBoardWorkOffers(
        companyId: String,
        workerType: WorkerTypeEnum
    ) async throws -> [WorkOffer] {
        let snapshot = try await workOffersCollection(companyId: companyId)
            .whereField("postedToBoard", isEqualTo: true)
            .whereField("status", in: [
                WorkOfferStatus.posted.rawValue,
                WorkOfferStatus.viewed.rawValue
            ])
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let offers = try snapshot.documents.compactMap { document in
            try document.data(as: WorkOffer.self)
        }

        return offers.filter { offer in
            switch offer.boardVisibility {
            case .employeesOnly:
                return workerType == .employee
            case .contractorsOnly:
                return workerType == .contractor
            case .employeesAndContractors:
                return workerType == .employee || workerType == .contractor
            case .adminsOnly:
                return false
            }
        }
    }

    func saveWorkOffer(
        _ workOffer: WorkOffer
    ) async throws {
        try workOfferDoc(
            companyId: workOffer.companyId,
            workOfferId: workOffer.id
        )
        .setData(from: workOffer, merge: true)

        // Optional reference under the job for quick future UI loading.
        let refData: [String: Any] = [
            "id": workOffer.id,
            "jobId": workOffer.jobId,
            "status": workOffer.status.rawValue,
            "offerType": workOffer.offerType.rawValue,
            "title": workOffer.title,
            "createdAt": workOffer.createdAt
        ]

        try await jobWorkOfferRefDoc(
            companyId: workOffer.companyId,
            jobId: workOffer.jobId,
            workOfferId: workOffer.id
        )
        .setData(refData, merge: true)
    }

    func updateWorkOfferStatus(
        companyId: String,
        workOfferId: String,
        status: WorkOfferStatus
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue
        ]

        switch status {
        case .sent:
            data["sentAt"] = Date()
        case .posted:
            data["postedAt"] = Date()
        case .viewed:
            data["viewedAt"] = Date()
        case .accepted:
            data["acceptedAt"] = Date()
        case .rejected:
            data["rejectedAt"] = Date()
        case .cancelled:
            data["cancelledAt"] = Date()
        case .completed:
            data["completedAt"] = Date()
        case .draft, .expired, .scheduled, .inProgress:
            break
        }

        try await workOfferDoc(
            companyId: companyId,
            workOfferId: workOfferId
        )
        .updateData(data)
    }

    func acceptWorkOffer(
        companyId: String,
        workOfferId: String,
        acceptedByUserId: String,
        acceptedByUserName: String
    ) async throws {
        try await workOfferDoc(
            companyId: companyId,
            workOfferId: workOfferId
        )
        .updateData([
            "status": WorkOfferStatus.accepted.rawValue,
            "acceptedAt": Date(),
            "acceptedByUserId": acceptedByUserId,
            "acceptedByUserName": acceptedByUserName
        ])
    }

    func rejectWorkOffer(
        companyId: String,
        workOfferId: String,
        rejectedByUserId: String,
        rejectedByUserName: String,
        reason: String
    ) async throws {
        try await workOfferDoc(
            companyId: companyId,
            workOfferId: workOfferId
        )
        .updateData([
            "status": WorkOfferStatus.rejected.rawValue,
            "rejectedAt": Date(),
            "acceptedByUserId": rejectedByUserId,
            "acceptedByUserName": rejectedByUserName,
            "rejectionReason": reason
        ])
    }

    func cancelWorkOffer(
        companyId: String,
        workOfferId: String,
        reason: String
    ) async throws {
        try await workOfferDoc(
            companyId: companyId,
            workOfferId: workOfferId
        )
        .updateData([
            "status": WorkOfferStatus.cancelled.rawValue,
            "cancelledAt": Date(),
            "adminNotes": reason,
            "rejectionReason": reason
        ])
    }
    func updateWorkOfferScheduledServiceStop(
        companyId: String,
        workOfferId: String,
        serviceStopId: String,
        serviceStopInternalId: String
    ) async throws {
        try await workOfferDoc(
            companyId: companyId,
            workOfferId: workOfferId
        )
        .updateData([
            "serviceStopId": serviceStopId,
            "serviceStopInternalId": serviceStopInternalId,
            "status": WorkOfferStatus.scheduled.rawValue
        ])
    }
    func appendServiceStopIdToJob(
        companyId: String,
        jobId: String,
        serviceStopId: String
    ) async throws {
        try await workOrderDocument(workOrderId: jobId, companyId: companyId)
            .updateData([
            "serviceStopIds": FieldValue.arrayUnion([serviceStopId])
        ])
    }
    // MARK: - Billing Info
    func ensureCompanyPaySettings(
        companyId: String
    ) async throws -> CompanyPaySettings {
        if var settings = try await fetchCompanyPaySettings(companyId: companyId) {
            if settings.companyId.isBlank {
                settings.companyId = companyId
                try await saveCompanyPaySettings(companyId: companyId, settings)
            }

            return settings
        }

        let defaultSettings = CompanyPaySettings.defaultSettings(companyId: companyId)
        try await saveCompanyPaySettings(companyId: companyId, defaultSettings)

        return defaultSettings
    }
    // MARK: - Company Users

    func fetchCompanyUsers(
        companyId: String
    ) async throws -> [CompanyUser] {
        let snapshot = try await companyUsersCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: CompanyUser.self) }
            .sorted { $0.userName < $1.userName }
    }

    // MARK: - Service Stop Tasks

    func fetchServiceStopTasks(
        companyId: String,
        serviceStopId: String
    ) async throws -> [ServiceStopTask] {
        let snapshot = try await serviceStopTasksCollection(
            companyId: companyId,
            serviceStopId: serviceStopId
        )
        .getDocuments()

        return try snapshot.documents.map { document in
            do {
                return try document.data(as: ServiceStopTask.self)
            } catch {
                print("[Payroll Debug][fetchServiceStopTasks][decodeError] companyId=\(companyId) serviceStopId=\(serviceStopId) taskDocId=\(document.documentID) data=\(document.data()) error=\(error)")
                throw error
            }
        }
    }

    // MARK: - Pay Settings

    func fetchCompanyPaySettings(
        companyId: String
    ) async throws -> CompanyPaySettings? {
        let snapshot = try await companyPaySettingsDoc(companyId: companyId)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try snapshot.data(as: CompanyPaySettings.self)
    }

    func saveCompanyPaySettings(
        companyId:String,
        _ settings: CompanyPaySettings
    ) async throws {
        try await companyPaySettingsDoc(companyId: companyId)
            .setData(from: settings, merge: true)
    }

    // MARK: - Service Stop Types

    func fetchCompanyServiceStopTypes(
        companyId: String
    ) async throws -> [CompanyServiceStopType] {
        let snapshot = try await companyServiceStopTypesCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: CompanyServiceStopType.self) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func saveCompanyServiceStopType(
        _ serviceStopType: CompanyServiceStopType
    ) async throws {
        try await companyServiceStopTypeDoc(
            companyId: serviceStopType.companyId,
            serviceStopTypeId: serviceStopType.id
        )
        .setData(from: serviceStopType, merge: true)
    }

    // MARK: - Work Types

    func fetchCompanyWorkTypes(
        companyId: String
    ) async throws -> [CompanyWorkType] {
        let snapshot = try await companyWorkTypesCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: CompanyWorkType.self) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func saveCompanyWorkType(
        _ workType: CompanyWorkType
    ) async throws {
        try await companyWorkTypeDoc(
            companyId: workType.companyId,
            workTypeId: workType.id
        )
        .setData(from: workType, merge: true)
    }

    // MARK: - Work Type Mappings

    func fetchWorkTypeMappings(
        companyId: String
    ) async throws -> [WorkTypeMapping] {
        let snapshot = try await workTypeMappingsCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: WorkTypeMapping.self) }
    }

    func saveWorkTypeMapping(
        _ mapping: WorkTypeMapping
    ) async throws {
        try await workTypeMappingDoc(
            companyId: mapping.companyId,
            mappingId: mapping.id
        )
        .setData(from: mapping, merge: true)
    }
    func deleteWorkTypeMapping(
        companyId: String,
        mappingId: String
    ) async throws {
        try await workTypeMappingDoc(
            companyId: companyId,
            mappingId: mappingId
        )
        .delete()
    }

    // MARK: - Company Rate Plans

    func fetchCompanyRatePlans(
        companyId: String
    ) async throws -> [CompanyRatePlan] {
        let snapshot = try await companyRatePlansCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: CompanyRatePlan.self) }
            .sorted { $0.effectiveStartDate > $1.effectiveStartDate }
    }

    func saveCompanyRatePlan(
        _ ratePlan: CompanyRatePlan
    ) async throws {
        try await companyRatePlanDoc(
            companyId: ratePlan.companyId,
            ratePlanId: ratePlan.id
        )
        .setData(from: ratePlan, merge: true)
    }

    // MARK: - Technician Rates

    func fetchTechnicianRates(
        companyId: String
    ) async throws -> [TechnicianRate] {
        let snapshot = try await technicianRatesCollection(companyId: companyId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianRate.self) }
            .sorted { $0.effectiveStartDate > $1.effectiveStartDate }
    }

    func fetchTechnicianRates(
        companyId: String,
        technicianId: String
    ) async throws -> [TechnicianRate] {
        let snapshot = try await technicianRatesCollection(companyId: companyId)
            .whereField("technicianId", isEqualTo: technicianId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianRate.self) }
            .sorted { $0.effectiveStartDate > $1.effectiveStartDate }
    }

    func saveTechnicianRate(
        _ rate: TechnicianRate
    ) async throws {
        try await technicianRateDoc(
            companyId: rate.companyId,
            technicianRateId: rate.id
        )
        .setData(from: rate, merge: true)
    }

    func saveTechnicianRateIncrease(
        expiredOldRate: TechnicianRate,
        newRate: TechnicianRate
    ) async throws {
        let batch = db.batch()
        let encoder = Firestore.Encoder()

        let oldData = try encoder.encode(expiredOldRate)
        let newData = try encoder.encode(newRate)

        batch.setData(
            oldData,
            forDocument: technicianRateDoc(
                companyId: expiredOldRate.companyId,
                technicianRateId: expiredOldRate.id
            ),
            merge: true
        )

        batch.setData(
            newData,
            forDocument: technicianRateDoc(
                companyId: newRate.companyId,
                technicianRateId: newRate.id
            ),
            merge: true
        )

        try await batch.commit()
    }

    // MARK: - Technician Pay Line Items

    func fetchTechnicianPayLineItems(
        companyId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [TechnicianPayLineItem] {
        let snapshot = try await technicianPayLineItemsCollection(companyId: companyId)
            .whereField("completedDate", isGreaterThanOrEqualTo: startDate)
            .whereField("completedDate", isLessThanOrEqualTo: endDate)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianPayLineItem.self) }
            .sorted {
                if $0.completedDate == $1.completedDate {
                    return $0.technicianName < $1.technicianName
                }

                return $0.completedDate < $1.completedDate
            }
    }
    func fetchTechnicianPayLineItems(
        companyId: String,
        serviceStopId: String
    ) async throws -> [TechnicianPayLineItem] {
        let snapshot = try await technicianPayLineItemsCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianPayLineItem.self) }
            .sorted {
                if $0.completedDate == $1.completedDate {
                    return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
                }

                return $0.completedDate < $1.completedDate
            }
    }

    func saveTechnicianPayLineItems(
        _ lineItems: [TechnicianPayLineItem]
    ) async throws {
        guard !lineItems.isEmpty else {
            return
        }

        let batch = db.batch()
        let encoder = Firestore.Encoder()

        for lineItem in lineItems {
            let data = try encoder.encode(lineItem)

            batch.setData(
                data,
                forDocument: technicianPayLineItemDoc(
                    companyId: lineItem.companyId,
                    payLineItemId: lineItem.id
                ),
                merge: true
            )
        }

        try await batch.commit()
    }

    func updateTechnicianPayLineItem(
        _ lineItem: TechnicianPayLineItem
    ) async throws {
        try await technicianPayLineItemDoc(
            companyId: lineItem.companyId,
            payLineItemId: lineItem.id
        )
        .setData(from: lineItem, merge: true)
    }

    // MARK: - Technician Pay Statements

    func fetchTechnicianPayStatements(
        companyId: String,
        startDate: Date,
        endDate: Date
    ) async throws -> [TechnicianPayStatement] {
        let snapshot = try await technicianPayStatementsCollection(companyId: companyId)
            .whereField("startDate", isLessThanOrEqualTo: endDate)
            .whereField("endDate", isGreaterThanOrEqualTo: startDate)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianPayStatement.self) }
            .sorted { $0.startDate > $1.startDate }
    }
    func fetchTechnicianPayLineItems(
        companyId: String,
        payStatementId: String
    ) async throws -> [TechnicianPayLineItem] {
        let snapshot = try await technicianPayLineItemsCollection(companyId: companyId)
            .whereField("payStatementId", isEqualTo: payStatementId)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: TechnicianPayLineItem.self) }
            .sorted {
                if $0.completedDate == $1.completedDate {
                    return ($0.workTypeName ?? "") < ($1.workTypeName ?? "")
                }

                return $0.completedDate < $1.completedDate
            }
    }
    
    func saveTechnicianPayStatement(
        _ statement: TechnicianPayStatement
    ) async throws {
        try await technicianPayStatementDoc(
            companyId: statement.companyId,
            payStatementId: statement.id
        )
        .setData(from: statement, merge: true)
    }
    
    // MARK: - Billing Info

    nonisolated static func == (lhs: ProductionDataService, rhs: ProductionDataService) -> Bool {
        return lhs.id == rhs.id
    }
    
    let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    let db = Firestore.firestore()
    func getEquipmentServiceHistory(
        companyId: String,
        equipmentId: String
    ) async throws -> [EquipmentServiceHistory] {
        let snapshot = try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("serviceHistory")
            .order(by: "date", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: EquipmentServiceHistory.self)
        }
    }
    func getEquipmentScheduledWork(
        companyId: String,
        equipmentId: String
    ) async throws -> [EquipmentScheduledWork] {
        let snapshot = try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("scheduledWork")
            .whereField("status", in: [
                EquipmentScheduledWorkStatus.draft.rawValue,
                EquipmentScheduledWorkStatus.estimatePending.rawValue,
                EquipmentScheduledWorkStatus.scheduled.rawValue,
                EquipmentScheduledWorkStatus.inProgress.rawValue
            ])
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: EquipmentScheduledWork.self)
        }
    }

    func uploadEquipmentScheduledWork(
        companyId: String,
        equipmentId: String,
        scheduledWork: EquipmentScheduledWork
    ) async throws {
        try db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("scheduledWork")
            .document(scheduledWork.id)
            .setData(from: scheduledWork, merge: true)
    }

    func updateEquipmentScheduledWorkStatus(
        companyId: String,
        equipmentId: String,
        scheduledWorkId: String,
        status: EquipmentScheduledWorkStatus,
        dateCompleted: Date? = nil
    ) async throws {
        var data: [String: Any] = [
            "status": status.rawValue
        ]

        if let dateCompleted {
            data["dateCompleted"] = dateCompleted
        }

        try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("scheduledWork")
            .document(scheduledWorkId)
            .setData(data, merge: true)
    }
//    func getScheduledWorkForEquipment(
//        companyId: String,
//        equipmentId: String
//    ) async throws -> [EquipmentScheduledWork] {
//        let db = self.db
//
//        let taskSnapshot = try await db
//            .collectionGroup("tasks")
//            .whereField("equipmentId", isEqualTo: equipmentId)
//            .getDocuments()
//
//        var scheduledWork: [EquipmentScheduledWork] = []
//
//        for taskDoc in taskSnapshot.documents {
//            let task = try taskDoc.data(as: ServiceStopTask.self)
//
//            guard task.status == .scheduled || task.status == .inProgress else {
//                continue
//            }
//
//            guard let serviceStopRef = taskDoc.reference.parent.parent else {
//                continue
//            }
//
//            let serviceStopSnapshot = try await serviceStopRef.getDocument()
//            let serviceStop = try serviceStopSnapshot.data(as: ServiceStop.self)
//
//            guard serviceStop.companyId == companyId else {
//                continue
//            }
//
//            guard serviceStop.serviceDate >= Calendar.current.startOfDay(for: Date()) else {
//                continue
//            }
//
//            var jobInternalId = task.jobId.internalId
//
//            if !serviceStop.jobId.isEmpty {
//                do {
//                    let job = try await getWorkOrderById(
//                        companyId: companyId,
//                        workOrderId: serviceStop.jobId
//                    )
//                    jobInternalId = job.internalId
//                } catch {
//                    print("Unable to fetch job for scheduled equipment work: \(error)")
//                }
//            }
//
//            let item = EquipmentScheduledWork(
//                id: task.id,
//                taskName: task.name,
//                taskType: task.type,
//                serviceDate: serviceStop.serviceDate,
//                techName: serviceStop.tech,
//                serviceStopId: serviceStop.id,
//                serviceStopInternalId: serviceStop.internalId,
//                jobId: serviceStop.jobId,
//                jobInternalId: jobInternalId,
//                status: task.status
//            )
//
//            scheduledWork.append(item)
//        }
//
//        return scheduledWork.sorted { $0.serviceDate < $1.serviceDate }
//    }
    func uploadEquipmentServiceHistory(
        companyId: String,
        equipmentId: String,
        history: EquipmentServiceHistory
    ) async throws {
        try db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("serviceHistory")
            .document(history.id)
            .setData(from: history, merge: true)
    }

    func updateEquipmentServiceDates(
        companyId: String,
        equipmentId: String,
        lastServiceDate: Date,
        nextServiceDate: Date?
    ) async throws {
        var data: [String: Any] = [
            "lastServiceDate": lastServiceDate
        ]

        if let nextServiceDate {
            data["nextServiceDate"] = nextServiceDate
        } else {
            data["nextServiceDate"] = FieldValue.delete()
        }

        try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .setData(data, merge: true)
    }

    func createEquipmentPartFromName(
        companyId: String,
        equipmentId: String,
        name: String
    ) async throws -> String {
        let partId = "com_equ_par_" + UUID().uuidString

        try await db
            .collection("companies")
            .document(companyId)
            .collection("equipment")
            .document(equipmentId)
            .collection("parts")
            .document(partId)
            .setData([
                "id": partId,
                "name": name,
                "date": Date(),
                "createdAt": Date()
            ], merge: true)

        return partId
    }
        //----------------------------------------------------
        //                   Universal Collections
        //----------------------------------------------------
    func universalReadingsTemplateCollection() -> CollectionReference{
        db.collection("universal/settings/readingTemplates")
    }
    func universalDossagesTemplateCollection() -> CollectionReference{
        db.collection("universal/settings/dosageTemplates")
    }
    func generalReadingDocument(readingTemplateId:String)-> DocumentReference{
        universalReadingsTemplateCollection().document(readingTemplateId)
    }
    func generalDossageDocument(dosageTemplateId:String)-> DocumentReference{
        universalDossagesTemplateCollection().document(dosageTemplateId)
    }
        // MARK: - Job Planned Service Stops

    func jobPlannedServiceStopsCollection(
        companyId: String,
        jobId: String
    ) -> CollectionReference {
        workOrderDocument(workOrderId: jobId, companyId: companyId)
            .collection("plannedServiceStops")
    }

    func jobPlannedServiceStopDoc(
        companyId: String,
        jobId: String,
        plannedServiceStopId: String
    ) -> DocumentReference {
        jobPlannedServiceStopsCollection(
            companyId: companyId,
            jobId: jobId
        )
        .document(plannedServiceStopId)
    }
    //MARK: - Billing Collections and docuemnts
    /*
     
     "comp_pay_set_main"
     "comp_ss_type_" + UUID().uuidString
     "comp_work_type_" + UUID().uuidString
     "comp_work_map_" + UUID().uuidString
     "comp_rate_plan_" + UUID().uuidString
     "comp_tech_rate_" + UUID().uuidString
     "comp_pay_line_" + UUID().uuidString
     "comp_pay_stmt_" + UUID().uuidString
     
     */

    // MARK: - Companies

//    func companyCollection() -> CollectionReference {
//        db.collection("companies")
//    }

    func companyDoc(companyId: String) -> DocumentReference {
        companyCollection().document(companyId)
    }

    // MARK: - Company Users
    // companies/{companyId}/companyUsers/{companyUserId}

//    func companyUsersCollection(companyId: String) -> CollectionReference {
//        companyDoc(companyId: companyId).collection("companyUsers")
//    }

//    func companyUserDoc(
//        companyId: String,
//        companyUserId: String
//    ) -> DocumentReference {
//        companyUsersCollection(companyId: companyId)
//            .document(companyUserId)
//    }

    func companyUserByUserIdQuery(
        companyId: String,
        userId: String
    ) -> Query {
        companyUsersCollection(companyId: companyId)
            .whereField("userId", isEqualTo: userId)
    }

    // MARK: - Service Stops
    // companies/{companyId}/serviceStops/{serviceStopId}

    func serviceStopsCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("serviceStops")
    }

    func serviceStopDoc(
        companyId: String,
        serviceStopId: String
    ) -> DocumentReference {
        serviceStopsCollection(companyId: companyId)
            .document(serviceStopId)
    }

    // MARK: - Service Stop Tasks
    // companies/{companyId}/serviceStops/{serviceStopId}/tasks/{taskId}

    func serviceStopTasksCollection(
        companyId: String,
        serviceStopId: String
    ) -> CollectionReference {
        serviceStopDoc(
            companyId: companyId,
            serviceStopId: serviceStopId
        )
        .collection("tasks")
    }

    func serviceStopTaskDoc(
        companyId: String,
        serviceStopId: String,
        taskId: String
    ) -> DocumentReference {
        serviceStopTasksCollection(
            companyId: companyId,
            serviceStopId: serviceStopId
        )
        .document(taskId)
    }

    // MARK: - Company Pay Settings
    // companies/{companyId}/paySettings/main

    func companyPaySettingsCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("paySettings")
    }

    func companyPaySettingsDoc(companyId: String) -> DocumentReference {
        companyPaySettingsCollection(companyId: companyId)
            .document("main")
    }

    // MARK: - Company Service Stop Types
    // companies/{companyId}/companyServiceStopTypes/{serviceStopTypeId}

    func companyServiceStopTypesCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("companyServiceStopTypes")
    }

    func companyServiceStopTypeDoc(
        companyId: String,
        serviceStopTypeId: String
    ) -> DocumentReference {
        companyServiceStopTypesCollection(companyId: companyId)
            .document(serviceStopTypeId)
    }

    // MARK: - Company Work Types
    // companies/{companyId}/companyWorkTypes/{workTypeId}

    func companyWorkTypesCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("companyWorkTypes")
    }

    func companyWorkTypeDoc(
        companyId: String,
        workTypeId: String
    ) -> DocumentReference {
        companyWorkTypesCollection(companyId: companyId)
            .document(workTypeId)
    }

    // MARK: - Work Type Mappings
    // companies/{companyId}/workTypeMappings/{mappingId}

    func workTypeMappingsCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("workTypeMappings")
    }

    func workTypeMappingDoc(
        companyId: String,
        mappingId: String
    ) -> DocumentReference {
        workTypeMappingsCollection(companyId: companyId)
            .document(mappingId)
    }

    // MARK: - Company Rate Plans
    // companies/{companyId}/companyRatePlans/{ratePlanId}

    func companyRatePlansCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("companyRatePlans")
    }

    func companyRatePlanDoc(
        companyId: String,
        ratePlanId: String
    ) -> DocumentReference {
        companyRatePlansCollection(companyId: companyId)
            .document(ratePlanId)
    }

    // MARK: - Technician Rates
    // companies/{companyId}/technicianRates/{technicianRateId}

    func technicianRatesCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("technicianRates")
    }

    func technicianRateDoc(
        companyId: String,
        technicianRateId: String
    ) -> DocumentReference {
        technicianRatesCollection(companyId: companyId)
            .document(technicianRateId)
    }

    // MARK: - Technician Pay Line Items
    // companies/{companyId}/technicianPayLineItems/{payLineItemId}

    func technicianPayLineItemsCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("technicianPayLineItems")
    }

    func technicianPayLineItemDoc(
        companyId: String,
        payLineItemId: String
    ) -> DocumentReference {
        technicianPayLineItemsCollection(companyId: companyId)
            .document(payLineItemId)
    }

    // MARK: - Technician Pay Statements
    // companies/{companyId}/technicianPayStatements/{payStatementId}

    func technicianPayStatementsCollection(companyId: String) -> CollectionReference {
        companyDoc(companyId: companyId).collection("technicianPayStatements")
    }

    func technicianPayStatementDoc(
        companyId: String,
        payStatementId: String
    ) -> DocumentReference {
        technicianPayStatementsCollection(companyId: companyId)
            .document(payStatementId)
    }
        // MARK: - Work Offers

    func workOffersCollection(
        companyId: String
    ) -> CollectionReference {
        companyDoc(companyId: companyId)
            .collection("workOffers")
    }

    func workOfferDoc(
        companyId: String,
        workOfferId: String
    ) -> DocumentReference {
        workOffersCollection(companyId: companyId)
            .document(workOfferId)
    }

    // Optional lightweight job reference collection.
    // Useful later if you want a job subcollection for quick navigation,
    // but the source of truth should remain companies/{companyId}/workOffers.
    func jobWorkOfferRefsCollection(
        companyId: String,
        jobId: String
    ) -> CollectionReference {
        workOrderDocument(workOrderId: jobId, companyId: companyId)
            .collection("workOfferRefs")
    }

    func jobWorkOfferRefDoc(
        companyId: String,
        jobId: String,
        workOfferId: String
    ) -> DocumentReference {
        jobWorkOfferRefsCollection(companyId: companyId, jobId: jobId)
            .document(workOfferId)
    }
    //----------------------------------------------------
    //                    Invites Collections
    //----------------------------------------------------
    func inviteCollection() -> CollectionReference{
        db.collection("invites")
    }
    func stripeInvoiceCollection() -> CollectionReference{
        db.collection("invoices")
    }
    func homeownerServiceStopCollection() -> CollectionReference{
        db.collection("homeownerServiceStop")
    }
    func companyCollection() -> CollectionReference{
        db.collection("companies")
    }
    func homeOwnerStopDataCollection() -> CollectionReference{
        db.collection("homeownerStopData")
    }
    func SettingsCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings")
    }
    func BillingTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/billing/billing")
    }
    
    func CompanyEmailConfigurationCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/emailConfiguration/customerConfiguration")
    }
    func DosageCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/dosages/dosages")
    }
    func DataBaseCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/dataBase/dataBase")
    }
    func GenericItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/genericItems/genericItems")
    }
    func ReadingsCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/readings/readings")
    }
    func StoreCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/venders/vender")
    }
    func ServiceStopTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/serviceStops/serviceStops")
    }
    func TrainingTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/trainingTemplates/trainingTemplates")
    }
    func WorkOrderTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/jobTemplates")
    }
    func jobTemplatePlannedServiceStopsCollection(
        companyId: String,
        templateId: String
    ) -> CollectionReference {
        WorkOrderDocument(
            workOrderTemplateId: templateId,
            companyId: companyId
        )
        .collection("plannedServiceStops")
    }

    func jobTemplatePlannedServiceStopDoc(
        companyId: String,
        templateId: String,
        plannedStopId: String
    ) -> DocumentReference {
        jobTemplatePlannedServiceStopsCollection(
            companyId: companyId,
            templateId: templateId
        )
        .document(plannedStopId)
    }

    func jobTemplateTasksCollection(
        companyId: String,
        templateId: String
    ) -> CollectionReference {
        WorkOrderDocument(
            workOrderTemplateId: templateId,
            companyId: companyId
        )
        .collection("tasks")
    }

    func jobTemplateTaskDoc(
        companyId: String,
        templateId: String,
        templateTaskId: String
    ) -> DocumentReference {
        jobTemplateTasksCollection(
            companyId: companyId,
            templateId: templateId
        )
        .document(templateTaskId)
    }

    func jobTemplateShoppingItemsCollection(
        companyId: String,
        templateId: String
    ) -> CollectionReference {
        WorkOrderDocument(
            workOrderTemplateId: templateId,
            companyId: companyId
        )
        .collection("shoppingItems")
    }

    func jobTemplateShoppingItemDoc(
        companyId: String,
        templateId: String,
        templateShoppingItemId: String
    ) -> DocumentReference {
        jobTemplateShoppingItemsCollection(
            companyId: companyId,
            templateId: templateId
        )
        .document(templateShoppingItemId)
    }
        //                    toDos Collections
    
    func ToDoCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/toDos")
    }
        //                    receipts Collections
    
    func ReceiptItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/receipts")
    }
    
    func workOrderInstallationPartsCollection(companyId:String,workOrderId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/workOrders/\(workOrderId)/installationParts")
    }
        //                    stopData Collections

        //                    invoices Collections
    func InvoiceCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/invoices")
    }

        
    func roleCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/roles")
    }
        
    func shoppingListCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/shoppingList")
    }
        
    func vehicalCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/vehicals")
    }

        //                    purchasedItems Collections
    func PurchaseItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/purchasedItems")
    }
        //                    companyUsers Collections
    

        //                    bodiesOfWater Collections

    func termsTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/termsTemplates")
    }
    func termsCollection(companyId:String,termsTempalteId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/termsTemplates/\(termsTempalteId)/terms")
    }
    func alertCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/alerts")
    }
    
    //----------------------------------------------------
    //                    Documents
    //----------------------------------------------------
        func CompanyEmailConfigurationDocument(companyId:String) -> DocumentReference{
        db.collection("companies/\(companyId)/settings").document("emailConfiguration")
    }
    func CustomerEmailConfigurationDocument(companyId:String,id:String) -> DocumentReference{
        db.collection("companies/\(companyId)/settings/emailConfiguration/customerConfiguration").document(id)
    }
        //----------------------------------------------------
        //                   Universal Documents
        //----------------------------------------------------
    
//    func generalReadingDocument(readingTemplateId:String)-> DocumentReference{
//        universalReadingsTemplateCollection().document(readingTemplateId)
//    }
//    func generalDossageDocument(dosageTemplateId:String)-> DocumentReference{
//        universalDossagesTemplateCollection().document(dosageTemplateId)
//    }
    
    
        //Home Owner Stuff
    func homeownerServiceStopDocument(serviceStopId:String)-> DocumentReference{
        homeownerServiceStopCollection().document(serviceStopId)
    }
    
    func alertDocument(companyId:String,alertId:String)-> DocumentReference{
        alertCollection(companyId:companyId).document(alertId)
    }
    

    func termsTemplateDocument(companyId:String,templateId:String)-> DocumentReference{
        termsTemplateCollection(companyId:companyId).document(templateId)
    }
    func termsDocument(companyId:String,termsTempalteId:String,termsId:String)-> DocumentReference{
        termsCollection(companyId:companyId,termsTempalteId:termsTempalteId).document(termsId)
    }
    func stripeInvoiceDocument(invoiceId:String)-> DocumentReference{
        stripeInvoiceCollection().document(invoiceId)
    }

    func ReadingsTemplateDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        ReadingsCollection(companyId: companyId).document(readingTemplateId)
    }
    func DosageTemplateDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        DosageCollection(companyId: companyId).document(dosageTemplateId)
    }
    func GenericItemDocument(genericItemId:String,companyId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
    }
 

    func StoreDocument(storeId:String,companyId:String)-> DocumentReference{
        StoreCollection(companyId: companyId).document(storeId)
        
    }
    func DataBaseDocument(dataBaseId:String,companyId:String)-> DocumentReference{
        DataBaseCollection(companyId: companyId).document(dataBaseId)
        
    }
    

    func ToDoDocument(toDoId:String,companyId:String)-> DocumentReference{
        ToDoCollection(companyId: companyId).document(toDoId)
    }
 
    func ReceiptItemDocument(receiptItemId:String,companyId:String)-> DocumentReference{
        ReceiptItemCollection(companyId: companyId).document(receiptItemId)
    }
    
    func WorkOrderDocument(workOrderTemplateId:String,companyId:String)-> DocumentReference{
        WorkOrderTemplateCollection(companyId: companyId).document(workOrderTemplateId)
    }
    
    func ServiceStopDocument(serviceStopTemplateId:String,companyId:String)-> DocumentReference{
        ServiceStopTemplateCollection(companyId: companyId).document(serviceStopTemplateId)
    }
    func ReadingsDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        ReadingsCollection(companyId: companyId).document(readingTemplateId)
    }
    func DosageDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        DosageCollection(companyId: companyId).document(dosageTemplateId)
    }

    func BillingTemplateDocument(billingTemplateId:String,companyId:String)-> DocumentReference{
        BillingTemplateCollection(companyId: companyId).document(billingTemplateId)
    }
    func TrainingDocument(trainingId:String,companyId:String,techId:String)-> DocumentReference{
        TrainingCollection(companyId: companyId,techId: techId).document(trainingId)
    }
    func TrainingTemplateDocument(trainingTemplateId:String,companyId:String)-> DocumentReference{
        TrainingTemplateCollection(companyId: companyId).document(trainingTemplateId)
    }
    func inviteDoc(inviteId:String)-> DocumentReference{
        inviteCollection().document(inviteId)
    }
    
    func readingDocumentToServiceStop(serviceStopId:String,stopDataId:String,companyId:String)-> DocumentReference{
        readingCollectionForServiceStop(serviceStopId: serviceStopId, companyId: companyId).document(stopDataId)
    }
    
//    func readingDocumentToCustomerHistory(customerId:String,stopDataId:String,companyId:String)-> DocumentReference{
//        readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId).document(stopDataId)
//    }
    func homeOwnerStopDataDocument(stopDataId:String)-> DocumentReference{
        homeOwnerStopDataCollection().document(stopDataId)
    }
    

    func GenericItemDocument(companyId:String,genericItemId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
    }
    func CompanyDocument(companyId:String)-> DocumentReference{
        companyCollection().document(companyId)
    }
    func roleDoc(companyId:String,roleId:String)-> DocumentReference{
        roleCollection(companyId: companyId).document(roleId)
    }
    
    func shoppingListDoc(companyId:String,shoppingListItemId:String)-> DocumentReference{
        shoppingListCollection(companyId: companyId).document(shoppingListItemId)
    }
    
    func vehicalDocument(companyId:String,vehicalId:String)-> DocumentReference{
        vehicalCollection(companyId: companyId).document(vehicalId)
    }
    func customerContactDocument(companyId:String,customerId:String,contactId:String)-> DocumentReference{
        customerContactCollection(companyId: companyId, customerId: customerId)
            .document(contactId)
    }
    func PurchaseItemDocument(purchaseItemId:String,companyId:String)-> DocumentReference{
        PurchaseItemCollection(companyId: companyId).document(purchaseItemId)
        
    }
    func companyUserDoc(companyId:String,companyUserId:String) -> DocumentReference{
        companyUsersCollection(companyId: companyId).document(companyUserId)
    }
    func companyUserRateSheetDoc(companyId:String,companyUserId:String,rateSheetId:String) -> DocumentReference{
        companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId).document(rateSheetId)
    }


    
    func equipmentPartDoc(companyId:String,equipmentId:String,partId:String)-> DocumentReference{
        equipmentPartCollection(companyId: companyId, equipmentId: equipmentId).document(partId)
    }
    func equipmentMeasurmentDoc(companyId:String,equipmentId:String,measurmentId:String)-> DocumentReference{
        equipmentMeasurmentsCollection(companyId: companyId, equipmentId: measurmentId)
            .document(measurmentId)
    }
    func getAllpurchasedItemsByPrice(companyId: String,start:Date,end:Date, descending: Bool,techIds:[String]) async throws -> [PurchasedItem]{
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        if techIds.isEmpty {
            return try await PurchaseItemCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate)
                .whereField("date", isLessThan: endDate)
                .order(by: "date", descending: descending)
                .getDocuments(as:PurchasedItem.self)
        } else {
            return try await PurchaseItemCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate)
                .whereField("date", isLessThan: endDate)
                .order(by: "date", descending: descending)
                .whereField("techId", in: techIds)
                .getDocuments(as:PurchasedItem.self)
        }
    }
 
    func getLaborContract(companyId: String, laborContractId: String) async throws -> ReccuringLaborContract {
        return try await RecurringLaborContractDocument(laborContractId: laborContractId)
            .getDocument(as: ReccuringLaborContract.self)
    }
    
    
    func getReceipt(companyId: String, receiptId: String) async throws -> Receipt {
        return try await ReceiptItemDocument(receiptItemId: receiptId, companyId: companyId)
            .getDocument(as: Receipt.self)
    }
    
    func getJobTemplate(companyId: String, templateId: String) async throws -> JobTemplate {
        return try await workOrderDocument(workOrderId: templateId, companyId: companyId)
            .getDocument(as: JobTemplate.self)
    }
    
    func getReadingTemplate(companyId: String, readingTemplateId: String) async throws -> SavedReadingsTemplate {
        return try await ReadingsDocument(readingTemplateId: readingTemplateId, companyId: companyId)
            .getDocument(as: SavedReadingsTemplate.self)
    }
    
    func getDosageTemplate(companyId: String, dosageTemplateId: String) async throws -> SavedDosageTemplate {
        return try await DosageTemplateDocument(dosageTemplateId: dosageTemplateId, companyId: companyId)
            .getDocument(as: SavedDosageTemplate.self)
    }
    
    func getAllUniversalReadingTemplates(companyId:String) async throws -> [ReadingsTemplate] {
        try await universalReadingsTemplateCollection()
            .getDocuments(as: ReadingsTemplate.self)
    }
    func getAllUniversalDosageTemplates(companyId:String) async throws -> [DosageTemplate]{
        return try await universalDossagesTemplateCollection()
            .getDocuments(as: DosageTemplate.self)
    }
    
    func getAccountsReceivableInvoice(companyId: String, invoiceId: String) async throws -> StripeInvoice {
        return try await stripeInvoiceDocument(invoiceId: invoiceId)
            .getDocument(as: StripeInvoice.self)
        
    }
    
    func getAccountsPayableInvoice(companyId: String, invoiceId: String) async throws -> StripeInvoice {
        return try await stripeInvoiceDocument(invoiceId: invoiceId)
            .getDocument(as: StripeInvoice.self)
    }
        //----------------------------------------------------
        //                    Listeners
        //----------------------------------------------------
    private var chatListener: ListenerRegistration? = nil
    private var unreadChatListener: ListenerRegistration? = nil
    private var customerListener: ListenerRegistration? = nil
    
    private var messageListener: ListenerRegistration? = nil
    private var equipmentListener: ListenerRegistration? = nil
    private var dataBaseListener: ListenerRegistration? = nil
    private var requestListener: ListenerRegistration? = nil
    private var jobListener: ListenerRegistration? = nil
    private var savedBusinessListener: ListenerRegistration? = nil
    
    private var termsTemplateListener: ListenerRegistration? = nil
    private var vehicalListener: ListenerRegistration? = nil
    private var companyUserListener: ListenerRegistration? = nil
    private var inviteListener: ListenerRegistration? = nil
    
    private var recurringRouteListListener: ListenerRegistration? = nil
    private var recurringServiceStopListener: ListenerRegistration? = nil
    
    private var currentCompanyUserListener: ListenerRegistration? = nil
    private var currentRoleListener: ListenerRegistration? = nil
    private var userAccessListener: ListenerRegistration? = nil
    
    //MainDashboard Listeners
    private var serviceStopListener: ListenerRegistration? = nil
    private var activeRouteListener: ListenerRegistration? = nil
    private var recurringRouteListener: ListenerRegistration? = nil
    
    private var sentLaborContractListeners: ListenerRegistration? = nil
    private var receivedLaborContractListener: ListenerRegistration? = nil
        //----------------------------------------------------
        //                    Coordinates
        //----------------------------------------------------
    
    @Published var Coordinates: CLLocationCoordinate2D? = nil
    
    let geoCoder = CLGeocoder()
        //-----------------------------------------------------------------------------------------------------------------------------------------------------
        //
        //                    BASIC CRUD FUNCTIONS
        //
        //-----------------------------------------------------------------------------------------------------------------------------------------------------
    
        //----------------------------------------------------
        //                    WORKING Functions
        //----------------------------------------------------
    func getCompanysBySearchTerm(searchTerm: String) async throws -> [Company]{
            //DEVELOPER Maybe break this up so that the search goes faster
        var companyList:[Company] = []
        let idCompanyList = try await companyCollection()
            .whereField("id", isEqualTo: searchTerm)
            .getDocuments(as:Company.self)
        for company in idCompanyList {
            companyList.append(company)
        }
        let nameCompanyList = try await companyCollection()
            .whereField("name", isEqualTo: searchTerm)
            .limit(to: 5)
            .getDocuments(as:Company.self)
        for company in nameCompanyList {
            companyList.append(company)
        }
        companyList.removeDuplicates()
        if companyList.isEmpty {
            let idCGreaterompanyList = try await companyCollection()
                .whereField("id", isGreaterThan: searchTerm)
                .limit(to: 5)
                .getDocuments(as:Company.self)
            for company in idCGreaterompanyList {
                companyList.append(company)
            }
            companyList.removeDuplicates()
            let idLessCompanyList = try await companyCollection()
                .whereField("id", isLessThan: searchTerm)
                .limit(to: 5)
            
                .getDocuments(as:Company.self)
            for company in idLessCompanyList {
                companyList.append(company)
            }
            companyList.removeDuplicates()
            let nameGreaterCompanyList = try await companyCollection()
                .whereField("name", isGreaterThan: searchTerm)
                .limit(to: 5)
            
                .getDocuments(as:Company.self)
            for company in nameGreaterCompanyList {
                companyList.append(company)
            }
            companyList.removeDuplicates()
            let nameLessCompanyList = try await companyCollection()
                .whereField("name", isLessThan: searchTerm)
                .limit(to: 5)
                .getDocuments(as:Company.self)
            for company in nameLessCompanyList {
                companyList.append(company)
            }
            companyList.removeDuplicates()
        }
        return companyList
    }
    
    func RegenerateCustomerSummaries(companyId:String,customers:[Customer],dosageTemplates:[DosageTemplate]) async throws {
            //        for customer in customers {
            //            //Delete all current monthlySummaries
            //            try await dataService.deleteAllCustomerSummaries(companyId: companyId, customer: customer)
            //            let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
            //
            //            for location in serviceLocations {
            //                for months in 1...13 {
            //                    let multiplier = (months * -1) + 1
            //                    let calendar = Calendar.current
            //                    let components = calendar.dateComponents([.year, .month, .day], from: Date())
            //                    let dateComponents = calendar.date(from: components)!
            //                    let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
            //
            //                    let pushEndDate = changingDate.endOfMonth()
            //                    let pushStartDate = changingDate.startOfMonth()
            //                    //working spot
            //                    print(pushStartDate)
            //                    print(pushEndDate)
            //
            //                    let specificSummary = try await dataService.getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId: companyId, customer: customer,month: pushStartDate,serviceLocationId: location.id).first
            //
            //
            //                    let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            //                        .whereField("date", isGreaterThan: pushStartDate)
            //                        .whereField("date", isLessThan: pushEndDate)
            //                        .getDocuments(as:StopData.self)
            //
            //                    //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
            //
            //                    print("stopHistory")
            //                    print(stopHistory)
            //
            //                    var totalData:[PNLDataPointArray] = []
            //                    var dataPoints:[PNLChem] = []
            //                    var dataPointsByDay:[PNLChem] = []
            //                    var dateList:[Date] = []
            //                    for stop in stopHistory {
            //                        print("stop")
            //                        print(stop)
            //                        if stop.date > pushStartDate && stop.date < pushEndDate {
            //                            for template in dosageTemplates {
            //                                let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
            //                                dataPoints.append(PNLDataPoint)
            //                            }
            //
            //                        }
            //                    }
            //                    for uniqueDay in dataPoints{
            //                        if !dateList.contains(uniqueDay.date) {
            //                            dateList.append(uniqueDay.date)
            //                            for day in dataPoints {
            //                                if uniqueDay.date == day.date {
            //                                    dataPointsByDay.append(day)
            //                                }
            //                            }
            //                            let serviceStop = try await serviceStopDocument(serviceStopId: uniqueDay.serviceStopId, companyId: companyId).getDocument(as: ServiceStop.self)
            //                            //DEVELOPER CHECK OUT AND FIX
            ////                            totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId,tech:serviceStop.tech, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
            //                            dataPointsByDay = []
            //                        }
            //                    }
            //                    var chemicalCost: Double = 0.00
            //                    var laborCost: Double = 0.00
            //
            //                    for data in dataPoints {
            //                        chemicalCost = data.totalCost + chemicalCost
            //                    }
            //                    for data in totalData {
            //                        laborCost = data.laborCost + laborCost
            //                    }
            //                    let totalCost = laborCost + chemicalCost
            //                    print("chemicalCost")
            //                    print(chemicalCost)
            //                    print("laborCost")
            //                    print(laborCost)
            //                    print("totalCost")
            //                    print(totalCost)
            //                    let fullName = (customer.firstName ) + " " + (customer.lastName )
            //
            //                    try await dataService.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: specificSummary?.id ?? "1",date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
            //                }
            //            }
            //
            //        }
        
    }
    func RegenerateSingleCustomer(companyId:String,customer:Customer,dosageTemplates:[DosageTemplate]) async throws {
            //Delete all current monthlySummaries
            //        try await dataService.deleteAllCustomerSummaries(companyId:companyId,customer: customer)
            //        let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
            //
            //        for location in serviceLocations {
            //            for months in 1...13 {
            //                let multiplier = (months * -1) + 1
            //                let calendar = Calendar.current
            //                let components = calendar.dateComponents([.year, .month, .day], from: Date())
            //                let dateComponents = calendar.date(from: components)!
            //                let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
            //
            //                let pushEndDate = changingDate.endOfMonth()
            //                let pushStartDate = changingDate.startOfMonth()
            //                //working spot
            //                print(pushStartDate)
            //                print(pushEndDate)
            //
            //                //                let specificSummary = try await dataService.getMonthlySummaryByCustomerAndMonthAndServiceLocation(customer: customer, companyId: companyId,month: pushStartDate,serviceLocationId: location.id).first
            //
            //
            //                let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            //                    .whereField("date", isGreaterThan: pushStartDate)
            //                    .whereField("date", isLessThan: pushEndDate)
            //                    .getDocuments(as:StopData.self)
            //
            //                //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
            //
            //                print("stopHistory")
            //                print(stopHistory)
            //
            //                var totalData:[PNLDataPointArray] = []
            //                var dataPoints:[PNLChem] = []
            //                var dataPointsByDay:[PNLChem] = []
            //                var dateList:[Date] = []
            //                for stop in stopHistory {
            //                    print("stop")
            //                    print(stop)
            //                    if stop.date > pushStartDate && stop.date < pushEndDate {
            //                        for template in dosageTemplates {
            //                            for dosage in stop.dosages{
            //                                if dosage.templateId == template.id {
            //                                    let amount:String = dosage.amount ?? "0.00"
            //
            //                                    let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(amount) ?? 0, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
            //                                    dataPoints.append(PNLDataPoint)
            //                                }
            //                            }
            //                        }
            //
            //                    }
            //                }
            //                for uniqueDay in dataPoints{
            //                    if !dateList.contains(uniqueDay.date) {
            //                        dateList.append(uniqueDay.date)
            //                        for day in dataPoints {
            //                            if uniqueDay.date == day.date {
            //                                dataPointsByDay.append(day)
            //                            }
            //                        }
            //                        let serviceStop = try await serviceStopDocument(serviceStopId: uniqueDay.serviceStopId, companyId: companyId).getDocument(as:ServiceStop.self)
            //                        //DEVELOPER INVESTIFATRE
            ////                        totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop?.techId! ?? "1",tech:serviceStop?.tech! ?? "1", laborCost: Double(serviceStop?.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
            //
            //                        dataPointsByDay = []
            //                    }
            //                }
            //                var chemicalCost: Double = 0.00
            //                var laborCost: Double = 0.00
            //
            //                for data in dataPoints {
            //                    chemicalCost = data.totalCost + chemicalCost
            //                }
            //                for data in totalData {
            //                    laborCost = data.laborCost + laborCost
            //                }
            //                let totalCost = laborCost + chemicalCost
            //                print("chemicalCost")
            //                print(chemicalCost)
            //                print("laborCost")
            //                print(laborCost)
            //                print("totalCost")
            //                print(totalCost)
            //                let fullName = (customer.firstName ) + " " + (customer.lastName )
            //
            //                try await dataService.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
            //            }
            //
            //
            //        }
            //
            //
    }
    func convertDatabaseItemToCSVStruct(contents: String) async throws -> [CSVDataBaseItem]{
        var csvToStruct = [CSVDataBaseItem]()
        
        var rows = contents.components(separatedBy: "\n")
        rows.removeFirst()
        
        for row in rows {
            let CSVColumns = row.components(separatedBy: ",")
            let customerStruct = CSVDataBaseItem.init(raw: CSVColumns)
            print(customerStruct)
            csvToStruct.append(customerStruct)
        }
        
        
        print("Successfully Converted Database List")
        
        return csvToStruct
        
    }
    func changeDBServiceStopsToServiceStops(DBServiceStops:[ServiceStop]) async throws ->[ServiceStop] {
        let liveServiceStopsList: [ServiceStop] = []
        return liveServiceStopsList
    }
    func searchForCustomersLocations(searchTerm:String,serviceLocation:[ServiceLocation])->[ServiceLocation]{
        var locationList:[ServiceLocation] = []
        let term = searchTerm.replacingOccurrences(of: " ", with: "")
        for location in serviceLocation {
            if location.address.streetAddress.lowercased().contains(term) || location.address.city.lowercased().contains(term) || location.address.state.lowercased().contains(term) || location.address.zip.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.customerName.lowercased().contains(term) || location.nickName.lowercased().contains(term) || location.mainContact.name.contains(term) {
                locationList.append(location)
            }
        }
        
        return locationList
    }
    func convertCustomerCSVToStruct(contents: String) async throws -> [CSVCustomer]{
        var csvToStruct = [CSVCustomer]()
        
        
        var rows = contents.components(separatedBy: "\n")
        rows.removeFirst()
        for row in rows {
            let CSVColumns = row.components(separatedBy: ",")
            var customerStruct = CSVCustomer.init(raw: CSVColumns)
            print("Converted \(customerStruct.firstName) \(customerStruct.lastName)")
            
            csvToStruct.append(customerStruct)
                //            if customerStruct.firstName == "Sue" && customerStruct.lastName == "Thomas" {
                //
                //                return csvToStruct
                //                print("Cut Out Early")
                //
                //            }
        }
        print("Successfully Converted Customer List")
        return csvToStruct
    }
        //----------------------------------------------------
        //                    Listeners
        //----------------------------------------------------
    func uploadCustomer(companyId:String,customer : Customer) async throws {
        print("Attempting to Up Load \(customer.firstName) \(customer.lastName) to Firestore")
        
        let coordinates = try await convertAddressToCordinates1(address: customer.billingAddress)
        print("Received Coordinates \(String(describing: coordinates))")
        var pushCustomer = customer
        pushCustomer.billingAddress.latitude = coordinates.latitude
        pushCustomer.billingAddress.longitude = coordinates.longitude
        
        pushCustomer.id = customer.id
        pushCustomer.firstName = customer.firstName
        pushCustomer.lastName = customer.lastName
        
        pushCustomer.email = customer.email
        pushCustomer.company = customer.company
        pushCustomer.displayAsCompany = customer.displayAsCompany
        
        try customerDocument(customerId: pushCustomer.id,companyId: companyId).setData(from:pushCustomer, merge: false)
    }
    
    func getAllJobsInProgressCount(companyId: String) async throws -> Int {
        return 0
    }
    func getAllVehicals(companyId:String) async throws -> [Vehical] {
        return try await vehicalCollection(companyId: companyId)
            .getDocuments(as:Vehical.self)
    }
    func getVehical(companyId: String,vehicalId:String) async throws -> Vehical {
        return try await vehicalDocument(companyId: companyId, vehicalId: vehicalId)
            .getDocument(as:Vehical.self)
    }
    
    func getFleet(companyId: String) async throws -> [Vehical] {
        return try await vehicalCollection(companyId: companyId)
            .getDocuments(as:Vehical.self)
    }
    func getCompanyFleetSnapShot(companyId: String) async throws -> [Vehical] {
        return try await vehicalCollection(companyId: companyId)
            .getDocuments(as:Vehical.self)
    }
    func getActiveVehicalFleet(companyId: String) async throws -> [Vehical] {
        return try await vehicalCollection(companyId: companyId)
            .getDocuments(as:Vehical.self)
    }
    func getAllVehicalsCount(companyId:String) async throws -> Int {
        return try await vehicalCollection(companyId: companyId)
            .count.getAggregation(source: .server).count as! Int
    }
    
    func getAllVenderCount(companyId:String) async throws -> Int {
        return try await StoreCollection(companyId: companyId)
            .count.getAggregation(source: .server).count as! Int
    }
    func addNewVehical(companyId:String,vehical:Vehical) async throws {
        try await vehicalDocument(companyId: companyId, vehicalId: vehical.id)
            .setData(from:vehical, merge: false)
    }
    
    func updateVehicalMilage(companyId:String,vehicalId:String,miles:Double) async throws {
        try await vehicalDocument(companyId: companyId, vehicalId: vehicalId)
            .updateData([
                "miles": miles,
            ])
    }
    func createNewEquipmentMeasurements(companyId:String,equipmentId:String,equipmentMeasurement:EquipmentMeasurements) async throws {
        try await equipmentMeasurmentDoc(companyId: companyId, equipmentId: equipmentId, measurmentId: equipmentMeasurement.id)
            .setData(from:equipmentMeasurement, merge: false)
        
    }
    func getRecentEquipmentMeasurments(companyId:String,equipmentId:String,amount:Int) async throws -> [EquipmentMeasurements] {
        return try await equipmentMeasurmentsCollection(companyId: companyId, equipmentId: equipmentId)
            .limit(to: amount)
            .order(by: "date", descending: true)
            .getDocuments(as:EquipmentMeasurements.self)
    }
    func getAccountsReceivableInvoiceSnapShot(companyId: String) async throws -> [StripeInvoice] {
        return []
    }
    
    func getAccountsPayableInvoiceSnapShot(companyId: String) async throws -> [StripeInvoice] {
        return []
    }
    
    func getAPOutstandingInvoiceCount(companyId: String) async throws -> (count: Int, total: Int) {
        return (count: 1, total: 1)
    }
    
    func getAPOutstandingLateInvoiceCount(companyId: String) async throws -> (count: Int, total: Int) {
        return (count: 2, total: 2)
    }
    
    func getAPRecentlyPaidInvoiceCount(companyId: String) async throws -> (count: Int, total: Int) {
        return (count: 3, total: 3)
    }
    func createInvoice(stripeInvoice:StripeInvoice) async throws {
        try stripeInvoiceDocument(invoiceId: stripeInvoice.id)
            .setData(from:stripeInvoice, merge: false)
    }
    func updateInvoiceAsPaid(stripeInvoiceId:String,paymentType:InvoicePaymentType) async throws {
        try await stripeInvoiceDocument(invoiceId: stripeInvoiceId)
            .updateData([
                "paymentType": paymentType,
                "status": InvoiceStatusType.paid
            ])
    }
    func deleteInvoice(stripeInvoiceId:String) async throws {
        try await stripeInvoiceDocument(invoiceId: stripeInvoiceId)
            .delete()
    }
    func deleteDBUser(userId:String) async throws{
        try await userDocument(userId: userId).delete()
    }
    
    func getAccountsPayableInvoice(companyId: String) async throws -> [StripeInvoice] {
        return try await stripeInvoiceCollection()
            .whereField("receiverId", isEqualTo: companyId)
            .whereField("paymentStatus", isEqualTo: InvoiceStatusType.unpaid.rawValue)
            .getDocuments(as: StripeInvoice.self)
    }
    
    func getAccountsReceivableInvoice(companyId: String) async throws -> [StripeInvoice] {
        return try await stripeInvoiceCollection()
            .whereField("senderId", isEqualTo: companyId)
            .whereField("paymentStatus", isEqualTo: InvoiceStatusType.unpaid.rawValue)
            .order(by: "dateSent", descending: true)
            .getDocuments(as: StripeInvoice.self)
    }

    func listenServiceStops(
         companyId: String,
         date: Date,
         techId: String,
         onChange: @escaping ([ServiceStop]) -> Void
    ) {
        serviceStopListener?.remove()

        serviceStopListener = serviceStopCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let stops = docs.compactMap {
                    try? $0.data(as: ServiceStop.self)
                }
                onChange(stops)
            }
        
    }
    func addListenerForEquipmentByServiceLocation(companyId: String,locationId:String, completion: @escaping ([Equipment]) -> Void){
        equipmentListener?.remove()
        equipmentListener = equipmentCollection(companyId: companyId)
            .whereField("serviceLocationId", isEqualTo: locationId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                let equipment = docs.compactMap {
                    try? $0.data(as: Equipment.self)
                }
                completion(equipment)
            }
    }

    func listenActiveRoute(
          companyId: String,
          date: Date,
          techId: String,
          onChange: @escaping (ActiveRoute?) -> Void
    ) {
        activeRouteListener?.remove()
        activeRouteListener = ActiveRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ActiveRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    onChange(nil)
                    return
                }
                let routes = docs.compactMap { try? $0.data(as: ActiveRoute.self) }
                    .filter { route in
                        route.totalStops > 0 || route.startTime != nil || route.endTime != nil
                    }
                    .sorted { lhs, rhs in
                        let lhsHasWork = lhs.startTime != nil || lhs.endTime != nil || lhs.status != .didNotStart
                        let rhsHasWork = rhs.startTime != nil || rhs.endTime != nil || rhs.status != .didNotStart

                        if lhsHasWork != rhsHasWork {
                            return lhsHasWork
                        }

                        if lhs.serviceStopsIds.count != rhs.serviceStopsIds.count {
                            return lhs.serviceStopsIds.count > rhs.serviceStopsIds.count
                        }

                        return lhs.id < rhs.id
                    }

                onChange(routes.first)
            }
    }
    private func UserAccessDocument(userId:String,accessId:String) -> DocumentReference{
        userAccessCollection(userId: userId).document(accessId)
    }
    func addCurrentUserAccessListener(companyId: String, userId:String, onChange: @escaping ([UserAccess]) -> Void) {
        currentCompanyUserListener?.remove()
        currentCompanyUserListener = userAccessCollection(userId: userId)
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let stops = docs.compactMap {
                    try? $0.data(as: UserAccess.self)
                }
                onChange(stops)
            }
    }
    private func CompanyUserCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/companyUsers")
    }
    private func CompanyUserDocument(companyId:String,companyUserId:String) -> DocumentReference{
        CompanyUserCollection(companyId: companyId).document(companyUserId)
    }
    func addCurrentCompanyUserListener(companyId: String, userId:String, onChange: @escaping ([CompanyUser]) -> Void) {
//      currentCompanyUserListener currentRoleListener userAccessListener
        currentCompanyUserListener?.remove()
        currentCompanyUserListener = CompanyUserCollection(companyId: companyId)
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let stops = docs.compactMap {
                    try? $0.data(as: CompanyUser.self)
                }
                onChange(stops)
            }
    }
    
    private func RoleCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/roles")
    }
    private func RoleDocument(companyId:String,roleId:String) -> DocumentReference{
        RoleCollection(companyId: companyId).document(roleId)
    }
    func addRoleListener(companyId: String, roleId:String, onChange: @escaping (Role?) -> Void) {
        let docRef = RoleDocument(companyId: companyId,roleId: roleId)
        currentRoleListener?.remove()
        currentRoleListener = docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("CompanyUser listener error:", error)
                onChange(nil)
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                onChange(nil)
                return
            }
            let companyUser = try? snapshot.data(as: Role.self)
            onChange(companyUser)
        }
    }

    func listenRecurringRoute(
        companyId: String,
        techId: String,
        day: String,
        onChange: @escaping (RecurringRoute?) -> Void
    ) {
        recurringRouteListener?.remove()
        recurringRouteListener = recurringRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("day", isEqualTo: day)
            .limit(to: 1)
        
            .addSnapshotListener { snapshot, error in
                guard let doc = snapshot?.documents.first else {
                    onChange(nil)
                    return
                }

                let route = try? doc.data(as: RecurringRoute.self)
                onChange(route)
            }
    }
    func addlistenerVehicals(companyId: String, status:String, onChange: @escaping ([Vehical]) -> Void) {
        
        vehicalListener?.remove()
        vehicalListener = vehicalCollection(companyId: companyId)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: Vehical.self)
            }
            onChange(stops)
        }
    }
    
    func addListenerForRecurringRoute(companyId: String, onChange: @escaping ([RecurringRoute]) -> Void) {
        recurringRouteListListener?.remove()
        recurringRouteListListener = recurringRouteCollection(companyId: companyId)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: RecurringRoute.self)
            }
            onChange(stops)
        }
    }
    
    func addListenerForRecurringServiceStop(companyId: String, onChange: @escaping ([RecurringServiceStop]) -> Void){
        recurringServiceStopListener?.remove()
        recurringServiceStopListener = recurringServiceStopCollection(companyId: companyId)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: RecurringServiceStop.self)
            }
            onChange(stops)
        }
    }

    func addCompanyUserListener(companyId: String, status:String, onChange: @escaping ([CompanyUser]) -> Void) {
        companyUserListener?.remove()
        companyUserListener = companyUsersCollection(companyId: companyId)
            .whereField("status", isEqualTo: status)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: CompanyUser.self)
            }
            onChange(stops)
        }
    }
    func addInviteListener(companyId: String, status:String, onChange: @escaping ([Invite]) -> Void) {
        inviteListener?.remove()
        inviteListener = inviteCollection()
            .whereField("companyId", isEqualTo: companyId)
            .whereField("status", isEqualTo: status)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: Invite.self)
            }
            onChange(stops)
        }
    }
    func addListenerForFutureCustomerServiceStops(companyId:String,customerId:String,completion:@escaping (_ serviceStops:[ServiceStop]) -> Void){
        
            serviceStopListener?.remove()
            serviceStopListener = serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.customerId.rawValue, isEqualTo: customerId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: Date().startOfDay())
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }
                let stops = docs.compactMap {
                    try? $0.data(as: ServiceStop.self)
                }
                completion(stops)
            }
    }

    func listenTermsTemplate(
        companyId: String,
        onChange: @escaping ([TermsTemplate]) -> Void
    ) {
        termsTemplateListener?.remove()
        termsTemplateListener = termsTemplateCollection(companyId: companyId)
        .addSnapshotListener { snapshot, error in
            guard let docs = snapshot?.documents else {
                onChange([])
                return
            }
            let stops = docs.compactMap {
                try? $0.data(as: TermsTemplate.self)
            }
            onChange(stops)
        }
        
    }
    func stopServiceStopActiveRouteRecurringRouteListenrs() {
         serviceStopListener?.remove()
         activeRouteListener?.remove()
         recurringRouteListener?.remove()
        companyUserListener?.remove()
     }
    func addListenerForSentLaborContracts(companyId:String, status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void){
        let stringStatus = status.map {$0.rawValue}
        if stringStatus.isEmpty {
            let listener = LaborContractCollection()
                .whereField("senderId", isEqualTo: companyId)
                .whereField("isInvoiced", isEqualTo: isInvoiced)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.sentLaborContractListeners = listener
        } else {
            let listener = LaborContractCollection()
                .whereField("senderId", isEqualTo: companyId)
                .whereField("isInvoiced", isEqualTo: isInvoiced)
                .whereField("status", in: stringStatus)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.sentLaborContractListeners = listener
        }
    }
    
    func addListenerForReceivedLaborContracts(companyId:String, status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void){
        
        let stringStatus = status.map {$0.rawValue}
        if stringStatus.isEmpty {
            let listener = LaborContractCollection()
                .whereField("receiverId", isEqualTo: companyId)
                .whereField("isInvoiced", isEqualTo: isInvoiced)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.receivedLaborContractListener = listener
        } else {
            let listener = LaborContractCollection()
                .whereField("receiverId", isEqualTo: companyId)
                .whereField("isInvoiced", isEqualTo: isInvoiced)
                .whereField("status", in: stringStatus)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.receivedLaborContractListener = listener
        }
    }

    func addListenerForSentLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void){
        let stringStatus = status.map {$0.rawValue}
        if stringStatus.isEmpty {
            let listener = LaborContractCollection()
                .whereField("senderId", isEqualTo: companyId)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.sentLaborContractListeners = listener
        } else {
            let listener = LaborContractCollection()
                .whereField("senderId", isEqualTo: companyId)
                .whereField("status", in: stringStatus)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.sentLaborContractListeners = listener
        }
    }
    
    func addListenerForReceivedLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void){
        
        let stringStatus = status.map {$0.rawValue}
        if stringStatus.isEmpty {
            let listener = LaborContractCollection()
                .whereField("receiverId", isEqualTo: companyId)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.receivedLaborContractListener = listener
        } else {
            let listener = LaborContractCollection()
                .whereField("receiverId", isEqualTo: companyId)
                .whereField("status", in: stringStatus)
                .order(by: "dateSent",descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Data Base Collection")
                        return
                    }
                    let serviceStops: [LaborContract] = documents.compactMap({try? $0.data(as: LaborContract.self)})
                    completion(serviceStops)
                }
            self.receivedLaborContractListener = listener
        }
    }
    //Listeners
    func removeListenerForSentLaborContracts() {
        self.sentLaborContractListeners?.remove()
    }
    func removeListenerForReceivedLaborContracts() {
        self.receivedLaborContractListener?.remove()
    }
    func removeVehicalListener() {
        self.vehicalListener?.remove()
    }
    
    func removeRecurringRouteListener() {
        self.recurringRouteListListener?.remove()
    }
    func removeRecurringServiceStopListener() {
        self.recurringRouteListener?.remove()
        
    }
    func addListenerForAllCustomers(companyId:String,storeId:String,completion:@escaping (_ serviceStops:[DataBaseItem]) -> Void){
        
        let listener = DataBaseCollection(companyId: companyId)
            .whereField("storeId", isEqualTo: storeId)
            .order(by: "name",descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Data Base Collection")
                    return
                }
                let serviceStops: [DataBaseItem] = documents.compactMap({try? $0.data(as: DataBaseItem.self)})
                completion(serviceStops)
            }
        self.dataBaseListener = listener
        
    }
    func addListenerForAllCustomers(companyId:String,sort:CustomerSortOptions,filter:CustomerFilterOptions,completion:@escaping (_ customers:[Customer]) -> Void){
        var listener: ListenerRegistration? = nil
        print("Sort: \(sort)")
        print("Filter: \(filter)")
        switch sort {
        case .durationLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .durationHigh:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.hireDate.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .lastNameHigh:
            print("Last Name High")
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .lastNameLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.lastName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .firstNameHigh:
            switch filter {
            case .active:
                print("Active")
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: false)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        case .firstNameLow:
            switch filter {
            case .active:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: true )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .deActivate:
                listener = customerCollection(companyId: companyId)
                    .whereField(Customer.CodingKeys.active.stringValue, isEqualTo: false )
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            case .all:
                listener = customerCollection(companyId: companyId)
                    .order(by: Customer.CodingKeys.firstName.stringValue, descending: true)
                    .addSnapshotListener { querySnapshot, error in
                        guard let documents = querySnapshot?.documents else {
                            print("There are no documents in the Customer Collection")
                            return
                        }
                        let chats: [Customer] = documents.compactMap({try? $0.data(as: Customer.self)})
                        completion(chats)
                    }
            }
        }
        self.customerListener = listener
    }
    
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("Add Listener For Unread Chats: \(userId)")
        let listener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .whereField("userWhoHaveNotRead", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("- There are no documents in the Unread Chat Collection")
                    return
                }
                
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                print("- Received Unread Chats \(chats.count)")
                completion(chats)
            }
        self.unreadChatListener = listener
    }
    func addListenerForAllMessages(chatId: String,amount:Int, completion: @escaping ([Message]) -> Void) {
        print("For Chat - \(chatId)")
        let listener = messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: true)
            .limit(to: amount)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Chat Collection")
                    return
                }
                let messages: [Message] = documents.compactMap({try? $0.data(as: Message.self)})
                print("Successfully Received \(messages.count) Messages")
                completion(messages)
            }
        self.messageListener = listener
    }
    func addListenerForAllRepairRequests(companyId:String,status:[RepairRequestStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[RepairRequest]) -> Void){
        
        var listener:ListenerRegistration? = nil
        let stringStatus = status.map {$0.rawValue}
        print(stringStatus)
        print(requesterIds)
        if stringStatus.isEmpty && requesterIds.isEmpty{
            print("Both Status and Tech Ids are empty")
            listener = repairRequestCollection(companyId: companyId)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else if stringStatus.isEmpty {
            print("Status is Empty")
            listener = repairRequestCollection(companyId: companyId)
                .whereField("requesterId", in: requesterIds)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else if requesterIds.isEmpty {
            print("Tech Ids Empty")
            listener = repairRequestCollection(companyId: companyId)
                .whereField("status", in: stringStatus)
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        } else {
            print("Full Query")
            
            listener = repairRequestCollection(companyId: companyId)
                .whereField("status", in: stringStatus)
                .whereField("requesterId", in: requesterIds)
                //                .whereField("status", isEqualTo: "Unresolved")
                //                .whereField("requesterId", isEqualTo: "YOlmTUaH9YUKXdHnccSOCJPQosC2")
                .whereField("date", isGreaterThan: startDate.startOfDay())
                .whereField("date", isLessThan: endDate.endOfDay())
                .order(by: "date", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let chats: [RepairRequest] = documents.compactMap({try? $0.data(as: RepairRequest.self)})
                    completion(chats)
                }
        }
        
        self.requestListener = listener
    }
    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("Add Listener For Read Chats: \(userId)")
        let listener = chatCollection()
            .order(by: "mostRecentChat", descending: true)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("[ProductionDataService] [addListenerForAllChats] - There are no documents in the Read Chat Collection")
                    return
                }
                
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                print("[ProductionDataService] [addListenerForAllChats] - Received Read Chats \(chats.count)")
                completion(chats)
            }
        self.chatListener = listener
    }
    func addListenerForAllServiceStops(companyId:String,completion:@escaping (_ serviceStops:[ServiceStop]) -> Void){
        
        let listener = serviceStopCollection(companyId: companyId)
            .limit(to: 25)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Service Stop Collection")
                    return
                }
                let serviceStops: [ServiceStop] = documents.compactMap({try? $0.data(as: ServiceStop.self)})
                completion(serviceStops)
            }
        self.serviceStopListener = listener
    }
    func addListenerForAllEquipment(companyId: String,amount:Int, completion: @escaping ([Equipment]) -> Void) {
        let listener = equipmentCollection(companyId: companyId)
            .limit(to: amount)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Chat Collection")
                    return
                }
                let equipmentList: [Equipment] = documents.compactMap({try? $0.data(as: Equipment.self)})
                print("Successfully Received \(equipmentList.count) Equipments")
                completion(equipmentList)
            }
        self.equipmentListener = listener
    }
    
    
    func addListenerForAllJobsBilling(companyId:String,status:[JobBillingStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void){
        
        var listener:ListenerRegistration? = nil
        let stringStatus = status.map {$0.rawValue}
        print("String Status : ")
        print(stringStatus)
        
        print("Requester Ids : ")
        print(requesterIds)
        
        print("Start Date : ")
        print(startDate)
        
        print("End Date : ")
        print(endDate)
        
        if stringStatus.isEmpty && requesterIds.isEmpty{
            print("Both Status and Tech Ids are empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("operationStatus", isEqualTo: JobOperationStatus.finished.rawValue)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    print("Received: \(jobs.count) Jobs")
                    completion(jobs)
                }
        } else if stringStatus.isEmpty {
            print("Status is Empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("adminId", in: requesterIds)
                .whereField("operationStatus", isEqualTo: JobOperationStatus.finished.rawValue)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    print("Received: \(jobs.count) Jobs")
                    completion(jobs)
                }
        } else if requesterIds.isEmpty {
            print("Tech Ids Empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("billingStatus", in: stringStatus)
                .whereField("operationStatus", isEqualTo: JobOperationStatus.finished.rawValue)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    print("Received: \(jobs.count) Jobs")
                    completion(jobs)
                }
        } else {
            print("Full Query")
            
            listener = workOrderCollection(companyId: companyId)
                .whereField("billingStatus", in: stringStatus)
                //                .whereField("adminId", in: requesterIds)
                .whereField("operationStatus", isEqualTo: JobOperationStatus.finished.rawValue)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: false)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Repair Request Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    print("Received: \(jobs.count) Jobs")
                    completion(jobs)
                }
        }
        
        self.jobListener = listener
    }
    
    func addListenerForAllJobsOperations(companyId:String,status:[JobOperationStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void){
        
        var listener:ListenerRegistration? = nil
        let stringStatus = status.map {$0.rawValue}
        print("String Status : ")
        print(stringStatus)
        
        print("Requester Ids : ")
        print(requesterIds)
        
        print("Start Date : ")
        print(startDate)
        
        print("End Date : ")
        print(endDate)
        
        if stringStatus.isEmpty && requesterIds.isEmpty{
            print("Both Status and Tech Ids are empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    completion(jobs)
                }
        } else if stringStatus.isEmpty {
            print("Status is Empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("adminId", in: requesterIds)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    completion(jobs)
                }
        } else if requesterIds.isEmpty {
            print("Tech Ids Empty")
            listener = workOrderCollection(companyId: companyId)
                .whereField("operationStatus", in: stringStatus)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    completion(jobs)
                }
        } else {
            print("Full Query")
            
            listener = workOrderCollection(companyId: companyId)
                .whereField("operationStatus", in: stringStatus)
//                .whereField("adminId", in: requesterIds)
                .whereField("dateCreated", isGreaterThan: startDate.startOfDay())
                .whereField("dateCreated", isLessThan: endDate.endOfDay())
                .order(by: "dateCreated", descending: true)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("There are no documents in the Job Collection")
                        return
                    }
                    let jobs: [Job] = documents.compactMap({try? $0.data(as: Job.self)})
                    completion(jobs)
                }
        }
        
        self.jobListener = listener
        print("")

    }
    func addSavedCompanyListener(userId:String,completion:@escaping (_ savedCompanies:[AssociatedBusiness]) -> Void) {
        
        let listener = savedCompaniesCollection(userId: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [AssociatedBusiness] = documents.compactMap({try? $0.data(as: AssociatedBusiness.self)})
                completion(chats)
            }
        self.savedBusinessListener = listener
    }

    func removeListenerForJobs(){
        self.jobListener?.remove()
        
    }
    
    func removeListenerForAllCustomers(){
        self.dataBaseListener?.remove()
    }
    
    func removeListenerForMessages() {
        self.messageListener?.remove()
    }
    func removeCurrentRoleListener() {
        self.currentRoleListener?.remove()
    }
    func removeRoleListener() {
        self.currentRoleListener?.remove()
    }
    func removeUserAccessListener() {
        self.userAccessListener?.remove()
        
    }

    func removeListenerForChats(){
        self.chatListener?.remove()
        self.unreadChatListener?.remove()
    }
    
    func removeListenerForAllServiceStops(){
        self.serviceStopListener?.remove()
    }
    
    func removeListenerForRequests(){
        self.requestListener?.remove()
    }
    
    func removeEquipmentListener() {
        self.equipmentListener?.remove()
    }
    func removeSavedCompanyListener() {
        self.savedBusinessListener?.remove()
    }
    func removeTermsTemplateListern() {
        self.termsTemplateListener?.remove()
    }
    func removeCompanyUserListener() {
        self.companyUserListener?.remove()
    }
    func removeInviteListener() {
        self.inviteListener?.remove()
    }
    func dateOnlyTimestamp(_ date: Date) -> Timestamp {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return Timestamp(date: startOfDay)
    }
}
