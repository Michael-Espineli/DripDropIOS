//
//  SettingsViewModel.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/2/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class SettingsViewModel: ObservableObject {
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Variables
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    @Published private(set) var jobTemplates: [JobTemplate] = []
    @Published private(set) var serviceStopTemplates: [ServiceStopTemplate] = []

    @Published private(set) var savedReadingTemplates: [SavedReadingsTemplate] = []
    @Published private(set) var savedDosageTemplates: [SavedDosageTemplate] = []
    @Published private(set) var readingTemplates: [ReadingsTemplate] = []
    @Published private(set) var dosageTemplates: [DosageTemplate] = []
    
    @Published private(set) var readingTemplate : ReadingsTemplate? = nil
    
    @Published private(set) var workOrderTemplate: JobTemplate? = nil
    @Published private(set) var genericItems: [GenericItem] = []
    @Published private(set) var loadingText: String? = nil
    @Published private(set) var loadingTotal: Int? = nil
    @Published private(set) var loadingCurrent: Int? = nil

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                                      Uploading Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func addWorkOrderTemplates(companyId: String,workOrderTemplate:JobTemplate) async throws{
        try await SettingsManager.shared.uploadWorkOrderTemplate(companyId: companyId, workOrderTemplate: workOrderTemplate)
    }
    
    func upLoadReadingTemplates(companyId: String) async throws {
        try await SettingsManager.shared.upLoadReadingTemplates(companyId: companyId)
        print("Success")
    }
    
    func uploadDosageTemplates(companyId: String) async throws {
        try await SettingsManager.shared.uploadDosageTemplates(companyId: companyId)
        print("Success")
    }
    
    func getWorkOrderCount(companyId:String) async throws-> Int{
        try await SettingsManager.shared.getWorkOrderCount(companyId: companyId)
    }
    func getRepairRequestCount(companyId:String) async throws-> Int{
        try await SettingsManager.shared.getRepairRequestCount(companyId: companyId)
    }
    
    func addReadingTemplates(readingTemplate:ReadingsTemplate,companyId: String) async throws{
        try await SettingsManager.shared.uploadReadingTemplate(readingTemplate: readingTemplate,companyId: companyId)
    }
    
    func addDosageTemplates(dosageTemplate:DosageTemplate,companyId: String) async throws{
        try await SettingsManager.shared.uploadDosageTemplate(dosageTemplate: dosageTemplate,companyId: companyId)
    }
    
    func AddReadingAmount(companyId: String,readingTemplate:ReadingsTemplate,amount:String) async throws {
        try? await SettingsManager.shared.uploadReadingTemplateAmountArray(companyId: companyId, readingTemplateId: readingTemplate.id, amount: amount)
    }
    
    func AddDosageAmount(companyId: String,dosageTemplate:DosageTemplate,amount:String) async throws {
        try? await SettingsManager.shared.uploadDosageTemplateAmountArray(companyId: companyId, dosageTemplateId: dosageTemplate.id, amount: amount)
    }
    
    func CreateGenericHistoryForOneCustomer(companyId: String, customer: Customer) async throws {
        
//        let serviceLocationList = try await Firestore.firestore().collection("companies/\(companyId: companyId)/customers/" + customer.id + "/serviceLocations").getDocuments(as:ServiceableLocation.self)
//        for serviceLocation in serviceLocationList {
//            try? await ReadingsManager.shared.CreateGenericHistory3(companyId: companyId, customer: customer, location: serviceLocation)
//        }
//
    }
    func createBodiesOfWaterForCustomer(customer:Customer,serviceLocation:ServiceLocation,bodyOfWater:BodyOfWater,companyId: String) async throws {
        try? await BodyOfWaterManager.shared.uploadServiceLocationBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)
    }
    func CreateGenericHistory(companyId: String, customerList: [Customer], ServiceLocation: [ServiceLocation]) async throws {
//        try? await ReadingsManager.shared.CreateGenericHistory(companyId: companyId, customerList: customerList, ServiceLocation: ServiceLocation)
        print("Success")
    }
    func CreateGenericHistory2(companyId: String, customerList: [Customer], ServiceLocation: [ServiceLocation]) async throws {
//        self.loadingTotal = customerList.count
//        var customerCount = 1
//        for customer in customerList{
//            self.loadingCurrent = customerCount
//
//            try? await ReadingsManager.shared.CreateGenericHistory2(companyId: companyId, customer: customer, ServiceLocation: ServiceLocation)
//            print("Success")
//            customerCount = customerCount + 1
//            if customerCount > 1 {
//                return
//            }
//        }
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Get Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getWorkOrderTemplate(companyId:String,workOrderId:String) async throws{
        self.workOrderTemplate = try await SettingsManager.shared.getAllWorkOrderTemplate(companyId: companyId, workOrderId:workOrderId)
    }
    
    func getWorkOrderTemplates(companyId: String) async throws{
        self.jobTemplates = try await SettingsManager.shared.getAllWorkOrderTemplates(companyId: companyId)
    }
    
    func getSrerviceStopTemplates(companyId: String) async throws{
        self.serviceStopTemplates = try await SettingsManager.shared.getAllServiceStopTemplates(companyId: companyId)
    }
    
    func getWorkOrderEstimate(companyId: String) async throws{
        self.workOrderTemplate = try await SettingsManager.shared.getWorkOrderEstimate(companyId: companyId).first
    }
    
    func getReadingTemplates(companyId: String) async throws{
        self.savedReadingTemplates = try await dataService.getAllReadingTemplates(companyId: companyId)
    }
    
    func getDosageTemplates(companyId: String) async throws{
        self.savedDosageTemplates = try await dataService.getAllDosageTemplates(companyId: companyId)
    }

    func getUniversalReadingTemplates(companyId: String) async throws{
        self.readingTemplates = try await dataService.getAllUniversalReadingTemplates(companyId: companyId)
    }
    
    func getUniversalDosageTemplates(companyId: String) async throws{
        self.dosageTemplates = try await dataService.getAllUniversalDosageTemplates(companyId: companyId)
    }
    func getGenericItem(companyId: String) async throws{
        self.genericItems = try await SettingsManager.shared.getGenericItems(companyId: companyId)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Editing Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            Deleting Recordings
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func DeleteReadingAmount(companyId:String,readingTemplate:ReadingsTemplate,amount:String) async throws {
        try? await SettingsManager.shared.removingReadingTemplateAmountArray(companyId: companyId, readingTemplateId: readingTemplate.id, amount: amount)
    }

    func DeleteDosageAmount(companyId:String,dosageTemplate:DosageTemplate,amount:String) async throws {
        try? await SettingsManager.shared.removingDosageTemplateAmountArray(companyId: companyId, dosageTemplateId: dosageTemplate.id, amount: amount)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                             Functions
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func signOut() throws{
        try AuthenticationManager.shared.signOut()
    }

}
