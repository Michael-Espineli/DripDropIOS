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
        db.collection("companies/\(companyId)/settings/workOrders/workOrders")
    }
        //repairRequests Collections

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
        db.collection("companies/\(companyId)/termsTemplate")
    }
    func termsCollection(companyId:String,termsTempalteId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/termsTemplate/\(termsTempalteId)/terms")
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
    private var serviceStopListener: ListenerRegistration? = nil
    private var chatListener: ListenerRegistration? = nil
    private var unreadChatListener: ListenerRegistration? = nil
    private var customerListener: ListenerRegistration? = nil
    
    private var messageListener: ListenerRegistration? = nil
    private var equipmentListener: ListenerRegistration? = nil
    private var dataBaseListener: ListenerRegistration? = nil
    private var requestListener: ListenerRegistration? = nil
    private var jobListener: ListenerRegistration? = nil
    
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
        //
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
                    print("- There are no documents in the Read Chat Collection")
                    return
                }
                
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                print("- Received Read Chats \(chats.count)")
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
                .order(by: "dateCreated", descending: false)
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
    
    func removeListenerForJobs(){
        self.jobListener?.remove()
        
    }
    
    func removeListenerForAllCustomers(){
        self.dataBaseListener?.remove()
    }
    
    func removeListenerForMessages() {
        self.messageListener?.remove()
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
    
}
