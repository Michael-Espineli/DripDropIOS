    //
    //  MockDataService.swift
    //  ThePoolApp
    //
    //  Created by Michael Espineli on 4/23/24.
    //

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit


@MainActor
final class MockDataService:ProductionDataServiceProtocol,ObservableObject {
    func removeListenerForSentLaborContracts() {
        
    }
    
    func removeListenerForReceivedLaborContracts() {
        
    }
    

    
    func deleteRecurringServiceStopTask(companyId: String, recurringServiceStopId: String, taskId: String) async throws {
        
    }
    
    func updateTaskGroupName(companyId: String, taskGroupId: String, name: String) async throws {
        
    }
    
    func updateTaskGroupDescription(companyId: String, taskGroupId: String, description: String) async throws {
        
    }
    
    func updateTaskGroupNumberOfTasks(companyId: String, taskGroupId: String, numberOfTasks: Int) async throws {
        
    }
    
    func getAllTaskGroupItems(companyId: String, taskGroupId: String) async throws -> [JobTaskGroupItem] {
        return []
    }
    
    func uploadNewTaskGroupItem(companyId:String,taskGroupId:String,taskGroupItem:JobTaskGroupItem) async throws {
        
    }
    //READ
    func getTaskGroupItemById(companyId:String, taskGroupId:String,taskItemId:String) async throws -> JobTaskGroupItem {
        return JobTaskGroupItem(id: "", name: "", type: .basic, description: "", contractedRate: 0, estimatedTime: 0)

    }
    func deleteTaskGroupItem(companyId:String,taskGroupId:String,taskId:String) async throws {
    }
    func deleteTaskGroup(companyId:String,taskGroupId:String) async throws {
    }
//    func getAllTaskGroups(companyId:String, taskGroupId:String) async throws ->[JobTaskGroupItem] {
//        return []
//
//    }
    
    func uploadNewTaskGroup(companyId:String,taskGroup:JobTaskGroup) async throws {
    }
    func getAllTaskGroupById(companyId:String,taskGroupId:String) async throws -> JobTaskGroup {
        return JobTaskGroup(id: "", name: "", description: "", numberOfTasks: 0)

    }
    func getAllTaskGroups(companyId:String) async throws ->[JobTaskGroup] {
        return []
    }
    func uploadRecurringServiceStopTask(companyId:String,recurringServiceStopId:String,task:RecurringServiceStopTask) async throws {
    }
    //Read
    func getRecurringServiceStopTasks(companyId:String,recurringServiceStopId:String) async throws -> [RecurringServiceStopTask] {
        return []
    }
    //Update
    func updateRecurringServiceStopTaskStatus(companyId:String,recurringServiceStopId:String,taskId:String,status:JobTaskStatus){
        
    }
    func updateRepairRequestPhotoURLs(companyId: String, repairRequest: String, photoUrls: [DripDropStoredImage]) async throws {
        
    }
    
    func uploadServiceStopImage(companyId: String, serviceStopId: String, image: DripDropImage) async throws -> (path: String, name: String) {
        return (path: "", name: "")
    }
    
    func updateServiceStopPhotoURLs(companyId: String, serviceStopId: String, photoUrls: [DripDropStoredImage]) async throws {
        
    }
    
    func getUniversalEquipmentTypes() async throws -> [UniversalEquipmentType] {
        return []
    }
    func getUniversalEquipmentBrandsByType(type:UniversalEquipmentType) async throws -> [UniversalEquipmentMake] {
        return []
    }
    func getUniversalEquipmentByTypeAndBrand(type:UniversalEquipmentType,make:UniversalEquipmentMake) async throws -> [UniversalEquipment] {
        return []
    }
    func getUniversalEquipmentPartsEquipment(equipmentId:String) async throws -> [UniversalPart] {
        return []
    }
    func deleteBodyOfWater(companyId:String,bodyOfWaterId:String) async throws {
        try await bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
            .delete()
    }
    func updateEquipmentName(companyId:String,equipmentId:String,name:String) throws {
        
    }
    func updateEquipmentCategory(companyId:String,equipmentId:String,category:EquipmentCategory) throws {
        
    }

    func updateEquipmentMake(companyId:String,equipmentId:String,make:String) throws {
        
    }
    func updateEquipmentModel(companyId:String,equipmentId:String,model:String) throws {
        
    }
    func updateEquipmentServiceFrequencyEvery(companyId:String,equipmentId:String,serviceFrequencyEvery:String) throws {
        
    }
    func updateEquipmentDateInstalled(companyId:String,equipmentId:String,dateInstalled:Date) throws {
        
    }
    func updateEquipmentStatus(companyId:String,equipmentId:String,status:EquipmentStatus) throws {
        
    }
    func updateEquipmentCleanFilterPressure(companyId:String,equipmentId:String,cleanFilterPressure:Int) throws {
        
    }
    func updateEquipmentCurrentPressure(companyId:String,equipmentId:String,currentPressure:Int) throws {
        
    }
    func updateEquipmentCleanLastServiceDate(companyId:String,equipmentId:String,lastServiceDate:Date) throws {
        
    }
    func updateEquipmentServiceFrequency(companyId:String,equipmentId:String,serviceFrequency:String) throws {
        
    }
    func updateEquipmentNextServiceDate(companyId:String,equipmentId:String,nextServiceDate:Date) throws {
        
    }
    func updateEquipmentNotes(companyId:String,equipmentId:String,notes:String) throws {
        
    }
    func updateEquipmentPhotoUrls(companyId:String,equipmentId:String,image:DripDropStoredImage) throws {
        
    }
    func updateCustomerActive(companyId:String,customerId:String,active:Bool) async throws {
    }
    func updateServiceStopTaskStatus(companyId:String,serviceStopId:String,taskId:String,status:JobTaskStatus) async throws {
    }
    func uploadServiceStopTask(companyId:String,serviceStopId:String,task:ServiceStopTask) async throws {
    }
    func updateJobTaskName(companyId:String,jobId:String,taskId:String,name:String) throws {
    }
    func updateJobTaskType(companyId:String,jobId:String,taskId:String,type:String) throws {
    }
    func updateJobTaskWorkerType(companyId:String,jobId:String,taskId:String,workerType:WorkerTypeEnum) throws {
    }
    func updateJobTaskWorkerName(companyId:String,jobId:String,taskId:String,workerName:String) throws {
    }
    func updateJobTaskWorkerId(companyId:String,jobId:String,taskId:String,workerId:String) throws {
    }
    func updateJobTaskStatus(companyId:String,jobId:String,taskId:String,status:JobTaskStatus) throws {
    }
    func updateJobTaskServiceStopId(companyId:String,jobId:String,taskId:String,serviceStopId:IdInfo) throws {
    }
    func updateJobTaskLaborContractId(companyId:String,jobId:String,taskId:String,laborContractId:String) throws {
    }
    func updateJobDateEstimateAccepted(companyId: String, jobId: String, date: Date) async throws{
    }
    func updateJobEstiamteAcceptedById(companyId: String, jobId: String, id: String) async throws{
    }
    func updateJobEstiamteAcceptedByType(companyId: String, jobId: String, type: JobEstiamteAcceptanceType) async throws {
    }    
    func updateJobInvoiceDate(companyId: String, jobId: String, date: Date) async throws {
        
    }
    func updateJobInvoiceRef(companyId: String, jobId: String, ref: String) async throws {
        
    }
    func updateJobInvoiceNotes(companyId: String, jobId: String, notes: String) async throws {
        
    }
    func updateJobInvoiceType(companyId: String, jobId: String, type: JobInvoiceType) async throws{
        
    }

    func updateLaborContractStatus(contractId:String,status:LaborContractStatus)  async throws {
    }
    func updateJobEstimateAcceptedNotes(companyId: String, jobId: String, notes: String) async throws{
    }
    func uploadWorkOrderTask(companyId:String,workOrderId:String,task:JobTask) throws {
    }
    func updateActiveRouteName(companyId:String,activeRouteId:String,name:String){
    }
    func updateActiveRouteDate(companyId:String,activeRouteId:String,date:Date){
    }
    func updateActiveRouteStartTime(companyId:String,activeRouteId:String,startTime:Date){
    }
    func updateActiveRouteEndTime(companyId:String,activeRouteId:String,endTime:Date){
    }
    func updateActiveRouteDuration(companyId:String,activeRouteId:String,duration:Int){
    }
    func updateActiveRouteDistnace(companyId:String,activeRouteId:String,distance:Double){
    }
    func updateActiveRouteStatus(companyId:String,activeRouteId:String,status:ActiveRouteStatus){
    }
    func updateActiveRouteStartMilage(companyId:String,activeRouteId:String,startMilage:Int){
    }
    func updateActiveRouteEndMilage(companyId:String,activeRouteId:String,endMilage:Int){
    }
    func updateActiveRouteFinishedStop(companyId:String,activeRouteId:String,finishedStops:Int){
    }
    func updateActiveRouteTotalStop(companyId:String,activeRouteId:String,totalStops:Int){
    }
    func updateActiveRouteVehicalId(companyId:String,activeRouteId:String,vehicalId:String){
        
    }
    func updateCustomerFirstName(companyId:String,customerId:String,firstName:String) async throws {
    }
    func updateCustomerLastName(companyId:String,customerId:String,lastName:String) async throws {
    }
    func updateCustomerEmail(companyId:String,customerId:String,email:String) async throws {
    }
    func updateCustomerAddress(companyId:String,customerId:String,billingAddress:Address) async throws {
    }
    func updateCustomerPhoneNumber(companyId:String,customerId:String,phoneNumber:String) async throws {
    }
    func updateCustomerPhoneLabel(companyId:String,customerId:String,phoneLabel:String) async throws {
    }
    func updateCustomerCompany(companyId:String,customerId:String,company:String) async throws {
    }
    func updateCustomerDisplayAsCompany(companyId:String,customerId:String,displayAsCompany:Bool) async throws {
    }
    func updateCustomerBillingNotes(companyId:String,customerId:String,billingNotes:String) async throws {
    }
    func updateCustomerTags(companyId:String,customerId:String,tags:[String]) async throws {
    }
    func updateCustomerLinkedInviteId(companyId:String,customerId:String,linkedInviteId:String) async throws {
    }
    func getServiceStopByServiceLocationId(companyId: String, serviceLocationId: String) async throws-> [ServiceStop] {
        return []
    }
    
    func getRecurringServiceStopByServiceLocationId(companyId: String, serviceLocationId: String) async throws-> [RecurringServiceStop] {
        return []
    }
    
    func updateServiceStopAddress(companyId: String, serviceStopId: String, address: Address) async throws {
    }
    func updateServiceStopIsInvoiced(companyId:String,serviceStopId:String,isInvoiced:Bool) async throws{
        
    }
    func updateRecurringServiceStopAddress(companyId: String, recurringServiceStopId: String, address: Address) async throws {
    }
    func updateHomeOwnerServiceStopFinish(companyId: String, serviceStop: ServiceStop, finished: Bool) async throws {
    }
    
    func getServiceStopByJobId(companyId: String, jobId: String) async throws -> [ServiceStop] {
            //DEVELOPER
        return []
    }
    
    func updateServicestopOperationStatus(companyId: String, serviceStop: ServiceStop, operationStatus: ServiceStopOperationStatus) async throws {
            //DEVELOPER
        
    }
    
    func updateServicestopBillingStatus(companyId: String, serviceStop: ServiceStop, billingStatus: ServiceStopBillingStatus) async throws {
            //DEVELOPER
        
    }
    func uploadJobTask(companyId:String,jobId:String,task:JobTask) async throws {
        
    }
    func getEquipmentByBodyOfWaterId(companyId:String,bodyOfWaterId:String) async throws ->[Equipment] {
        return []
    }
    func getEquipmentByServiceLocationId(companyId:String,serviceLocationId:String) async throws ->[Equipment] {
        return []
    }
    func getEquipmentByServiceLocationIdAndCategory(companyId:String,serviceLocationId:String,category:EquipmentCategory) async throws ->[Equipment] {
        return []
    }
    
    func updateVehicalMilage(companyId:String,vehicalId:String,miles:Double) async throws {
        
    }
    func updateEmailConfigurationBody(companyId:String,newBody:String) async throws {
        
    }
    func updateCustomerEmailConfig(companyId:String,customerEmailConfigId:String,emailIsOn:Bool) async throws {
        
    }
    func createCustomerEmailConfiguration(companyId:String,customerEmailConfig:CustomerEmailConfiguration) async throws {
        
    }
    func updateEmailConfigurationIsOn(companyId:String,emailIsOn:Bool) async throws {
        
    }
    func upLoadInitialEmailSettings(companyId:String) async throws {
        
    }
    func getJobTasks(companyId:String,jobId:String) async throws -> [JobTask] {
        return []
    }
    func getRecentActiveRouteForTech(companyId: String,techId:String,days:Int) async throws -> [ActiveRoute] {
    return []
    }
    func getActiveWorkLogsByUser(companyId:String,userId:String) async throws -> [WorkLog] {
        return []
    }
    func getCurrentShift(companyId:String,userId:String) async throws -> [WorkShift] {
        return []
    }
    func updateWorkLogEndTime(companyId:String,workLogId:String,endTime:Date) async throws {
        
    }
    func updateWorkLogEndLatAndLong(companyId:String,workLogId:String,lat:Double,long:Double) async throws {
        
    }
    func updateWorkLogActive(companyId:String,workLogId:String,current:Bool) async throws {
        
    }
    func uploadWorkLog(companyId:String,workLog:WorkLog) async throws {
        
    }    
    func updateWorkShiftActive(companyId:String, workShiftId:String,current:Bool) async throws {
 
    }
    func uploadWorkShift(companyId:String, workShift:WorkShift) async throws {
        
    }
    func getWorkLogByShift(companyId:String,shiftId:String,userId:String) async throws -> [WorkLog] {
        return []
    }
    func getShiftByUserIdBetweenDates(companyId:String, userId:String, start:Date, end:Date) async throws -> [WorkShift] {
        return []
    }
    func getPreviousShiftByUserId(companyId:String, userId:String, count:Int) async throws -> [WorkShift] {
        return []
    }
    func getNextShiftByUserId(companyId:String, userId:String,  count:Int) async throws -> [WorkShift] {
        return []
    }
    func getServiceStopTasks(companyId:String,serviceStopId:String) async throws -> [ServiceStopTask] {
        return []
        
    }
    func getLaborContractTasks(companyId:String,laborContractId:String) async throws -> [LaborContractTask] {
        return []
    }
    func getEmailConfigurationSettings(companyId:String) async throws -> CompanyEmailConfiguration {
        return CompanyEmailConfiguration(emailIsOn: false, emailBody: "", requirePhoto: false)
    }
    func getCustomerEmailConfigurationSettings(companyId:String) async throws -> [CustomerEmailConfiguration] {
        return []
    }
    func getCustomerEmailConfigurationSettingDocument(companyId:String,id:String) async throws -> CustomerEmailConfiguration {
        return CustomerEmailConfiguration(id: "", customerId: "", emailIsOn: false)
    }
    func updateEmailConfigurationRequirePhoto(companyId:String,requirePhoto:Bool) async throws {
        
    }
    
    func uploadReadingTemplate(readingTemplate: SavedReadingsTemplate, companyId: String) async throws {
        
    }
    
    func uploadDosageTemplate(dosageTemplate: SavedDosageTemplate, companyId: String) async throws {
        
    }
    
    func getAllReadingTemplates(companyId: String) async throws -> [SavedReadingsTemplate] {
        return []
    }
    
    func getReadingTemplate(companyId: String, readingTemplateId: String) async throws -> SavedReadingsTemplate {
        return SavedReadingsTemplate(id: "", readingsTemplateId: "", name: "", amount: [], UOM: "", chemType: "", linkedDosage: "", editable: false, order: 0, highWarning: 0, lowWarning: 0)
    }
    
    func getAllDosageTemplates(companyId: String) async throws -> [SavedDosageTemplate] {
        return []
        
    }
    func getAllUniversalReadingTemplates(companyId:String) async throws -> [ReadingsTemplate] {
        return []
    }
    func getAllUniversalDosageTemplates(companyId:String) async throws -> [DosageTemplate] {
        return []
    }
    func getDosageTemplate(companyId: String, dosageTemplateId: String) async throws -> SavedDosageTemplate {
        return SavedDosageTemplate(id: "", dosageTemplateId: "", name: "", amount: [], UOM: "", rate: "", linkedItemId: "", strength: 0, editable: false, chemType: "", order: 0)
    }
    
    func getAllpurchasedItemsByPrice(companyId: String, start: Date, end: Date,descending: Bool,techIds:[String]) async throws -> [PurchasedItem]{
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
    func modifyRecurringServiceStopToNew(
        companyId:String,
        recurringServiceStop:RecurringServiceStop,
        customFrequencyType:String,
        CustomFrequency:String,
        daysOfWeek:[String],
        oldRss:RecurringServiceStop,
        old:[ServiceStop]
    ) async throws ->(String?){
        return ""
    }
    func addNewRecurringServiceStop(companyId: String, recurringServiceStop: RecurringServiceStop) async throws -> (String?) {
        return ""
    }
    
    
    func addLaborContractRecurringWork(companyId: String, laborContractId: String, laborContractRecurringWork: LaborContractRecurringWork) async throws {
        
    }
    func updateLaborContractIsActive(contractId:String,isActive:Bool)  async throws {

    }
    func getLaborContractRecurringWork(companyId: String, laborContractId: String, recurringWorkId: String) async throws -> LaborContractRecurringWork {
        return MockDataService.mockLaborContractRecurringWork.first!
    }
    
    func getLaborContractRecurringWorkList(companyId: String, laborContractId: String) async throws -> [LaborContractRecurringWork] {
        return MockDataService.mockLaborContractRecurringWork
        
    }
    
    func updateLaborContractRecurringWorkRate(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, rate: Double) async throws {
        
    }
    func updateLaborContractRecurringWorkLastBilled(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, lastBilled: Date) async throws {

    }
    func updateLaborContractRecurringWorkIsActive(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, isActive: Bool) async throws {

    }
    func updateLaborContractRecurringWorkRateRateSheetLaborType(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, laborType: RateSheetLaborType) async throws {
        
    }
    
    func updateLaborContractRecurringWorkRateLaborContractFrequency(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, frequency: LaborContractFrequency) async throws {
        
    }
    func uploadTaskToLaborContract(laborContractId:String,task:LaborContractTask) async throws {

    }
    //Create
    func uploadLaborContract(laborContractId:String,laborContract:LaborContract) async throws {

    }
    //Read
    func getLaborContract(laborContractId: String) async throws -> LaborContract {
        return MockDataService.mockLaborContract
    }
    
    func getLaborContractsBySenderId(senderId: String) async throws -> [LaborContract] {
        return []
    }
    
    func getLaborContractsByReceiverId(receiverId: String) async throws -> [LaborContract] {
        return []
    }
    
    
    func getLaborContractsBySenderReceiverIsInvoiced(senderId: String,receiverId: String,isInvoiced: Bool) async throws -> [LaborContract] {
        return []
    }
    func getLaborContractsBySenderReceiverIsInvoicedStatus(senderId: String,receiverId: String,isInvoiced: Bool, status:LaborContractStatus) async throws -> [LaborContract] {
        return MockDataService.mockLaborContracts
    }
    //Read
    func updateOneTimeLaborContractAsAcceptedByReceiver(contractId:String,accepted:Bool)  async throws {

    }
    func updateOneTimeLaborContractAsAcceptedBySender(contractId:String,accepted:Bool)  async throws {
  
    }
    func deleteLaborContract(contractId:String) async throws {
        
    }

    func getLaborContractTask(laborContractId: String, taskId: String) async throws -> LaborContractTask {
        return LaborContractTask(
            name: "",
            type: .basic,
            contractedRate: 0,
            estimatedTime: 0,
            status: .accepted,
            customerApproval: false,
            laborContractId: "",
            serviceStopId: IdInfo(
                id: "",
                internalId: ""
            ),
            jobIsCreated: false,
            receiverJobId: [],
            senderJobTaskId: "",
            
            equipmentId: "",
            serviceLocationId: "",
            bodyOfWaterId: "",
            shoppingListItemId: ""
        )
    }
    
    func getLaborContractWork(companyId: String, laborContractId: String) async throws -> [LaborContractTask] {
        return []
    }
    func updateLaborContractTaskStatus(laborContractId:String,laborContractTaskId:String,status:JobTaskStatus) async throws {
        
    }
    func updateLaborContractTaskJobIsCreated(laborContractId:String,laborContractTaskId:String,jobIsCreated:Bool) async throws {
        
    }
    func updateLaborContractTaskReceiverJobId(laborContractId:String,laborContractTaskId:String,jobIdInfo:IdInfo) async throws {
        
    }
    func updateLaborContractRecurringWorkSetUpRoute(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, setUpRoute: Bool) async throws {
        
    }
    
    func getLaborContractsSnapShot(companyId: String) async throws -> [ReccuringLaborContract] {
        return []
    }
    
    func getLaborContractsSentCountByStatus(companyId: String,status:LaborContractStatus) async throws -> Int {
        return 8
    }
    
    func getLaborContractsReceivedCountByStatus(companyId: String,status:LaborContractStatus) async throws -> Int {
        return 8
    }
    
    func getLaborContractsTotal(companyId: String) async throws -> Double {
        return 8
    }
    
    
    func updateLaborContractAsAcceptedByReceiver(companyId:String,contractId:String,accepted:Bool)  async throws {
        
    }
    func updateLaborContractIsInvoiced(companyId:String, contractId:String, isInvoiced:Bool)  async throws {
        
    }
    func updateLaborContractInvoiceRef(companyId:String, contractId:String, invoiceInfo:IdInfo)  async throws{
        
    }
    func deleteRecurringLaborContract(companyId:String,contractId:String) async throws {
        
    }
    func updateLaborContractAsAcceptedBySender(companyId:String,contractId:String,accepted:Bool)  async throws {
        
    }
    func getPersonalAlertsCount(userId:String) async throws -> Int {
        return 1
    }
    func getPersonalAlerts(userId:String) async throws -> [DripDropAlert] {
        return []
        
    }
    func getDripDropAlertsCount(companyId:String) async throws -> Int {
        return 1
    }
    func getLaborContract(companyId: String, laborContractId: String) async throws -> ReccuringLaborContract {
        return MockDataService.mockRecurringLaborContracts.first!
    }
    
    func getActiveRoute(companyId: String, activeRouteId: String) async throws -> ActiveRoute {
        return ActiveRoute(
            id: "",
            name: "",
            date: Date(),
            serviceStopsIds: [],
            order: [],
            startTime: Date(),
            endTime: Date(),
            startMilage: 0,
            endMilage: 0,
            techId: "",
            techName: "",
            traineeId: "",
            traineeName: "",
            durationMin: 0,
            distanceMiles: 0,
            status: .didNotStart,
            totalStops: 0,
            finishedStops: 0,
            vehicalId: ""
        )
    }
    
    func getReceipt(companyId: String, receiptId: String) async throws -> Receipt {
        return Receipt(
            id: "",
            numberOfItems: 0,
            cost: 0,
            costAfterTax: 0
        )
    }
    
    func getJobTemplate(companyId: String, templateId: String) async throws -> JobTemplate {
        return JobTemplate(
            id: "",
            name: "",
            type: "",
            typeImage: "",
            dateCreated: Date(),
            rate: "",
            color: "",
            locked: false
        )
    }
    
    func getReadingTemplate(companyId: String, readingTemplateId: String) async throws -> ReadingsTemplate {
        return ReadingsTemplate(
            id: "",
            name: "",
            amount: [],
            UOM: "",
            chemType: "",
            linkedDosage: "",
            editable: true,
            order: 0,
            highWarning: 0,
            lowWarning: 0
        )
    }
    
    func getDosageTemplate(companyId: String, dosageTemplateId: String) async throws -> DosageTemplate {
        return DosageTemplate(
            id: "",
            name: "",
            amount: [],
            UOM: "",
            rate: "",
            linkedItemId: "",
            strength: 0,
            editable: true,
            chemType: "",
            order: 0
        )
    }
    
    func getAccountsReceivableInvoice(companyId: String, invoiceId: String) async throws -> StripeInvoice {
        return StripeInvoice(
            id: "",
            internalIdenifier: "",
            senderId: "",
            senderName: "",
            receiverId: "",
            receiverName: "",
            dateSent: Date(),
            total: 9,
            terms: .net15,
            paymentStatus: .paid,
            paymentType: .cash,
            paymentRefrence: "",
            paymentDate: nil,
            lineItems: []
        )
        
    }
    
    func getAccountsPayableInvoice(companyId: String, invoiceId: String) async throws -> StripeInvoice {
        return StripeInvoice(
            id: "",
            internalIdenifier: "",
            senderId: "",
            senderName: "",
            receiverId: "",
            receiverName: "",
            dateSent: Date(),
            total: 9,
            terms: .net15,
            paymentStatus: .paid,
            paymentType: .cash,
            paymentRefrence: "",
            paymentDate: nil,
            lineItems: []
        )
    }
    func addPersonalAlert(userId:String,dripDropAlert:DripDropAlert) async throws {
        
    }
    func addDripDropAlert(companyId:String,dripDropAlert:DripDropAlert) async throws {
        
    }
    func createNewJobPost(jobPost:JobPost) async throws{
        
    }
    func getDripDropAlerts(companyId:String) async throws -> [DripDropAlert] {
        return []
    }
    func getLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return []
    }
    func getReceivedLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return []

    }
    func getJobPostsByBoard(boardId:String) async throws -> [JobPost] {
        return []
    }
    func getSentLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] {
        return []

    }
    func getPublicJobBoards() async throws -> [JobBoard] {
        return []
    }
    
    func getJobPostsByUserId(userId:String) async throws -> [JobPost] {
        return []
    }
    func getSavedJobBoards(userId:String) async throws -> [JobBoard] {
        return []
    }
    func addNewRecurringServiceStopFromLaborContract(companyId:String,recurringServiceStop:RecurringServiceStop,laborContract:ReccuringLaborContract) async throws ->(String?){
        return nil
    }
    func getSentLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract] {
        return []
    }
    func getLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract] {
        return []
        
    }
    func searchForUsers(searchTerm:String) async throws -> [DBUser] {
        return []
    }
    func updateBodyOfWaterPhotoURLs(companyId: String, bodyOfWaterId: String, photoUrls: [DripDropStoredImage]) async throws {
    }
    func updateBodyOfWaterLastFilledDate(companyId: String, bodyOfWaterId: String, lastFilled: Date) async throws {
 
    }
    func updateServiceLocationPhotoURLs(companyId: String, serviceLocationId: String, photoUrls: [DripDropStoredImage]) async throws {
    }
    func getLaborContractsByAssociatedBusiness(companyId:String,associatedBusinessCompanyId:String) async throws -> [ReccuringLaborContract] {
        return MockDataService.mockRecurringLaborContracts
    }
    func getLaborContractsByAssociatedBusinessIsActive(companyId:String,associatedBusinessCompanyId:String,isActive:Bool) async throws -> [ReccuringLaborContract] {
        return MockDataService.mockRecurringLaborContracts

    }
    func addLaborContract(companyId:String,laborContract:ReccuringLaborContract) async throws {
        
    }
    func addTermsTemplate(companyId:String,termsTemplate:TermsTemplate) async throws{
        
    }
    func addTermsToTermsTemplate(companyId:String,termsTemplateId:String,terms:ContractTerms) async throws {
        
    }
    
    func getTermsTemplate(companyId:String,termsTemplateId:String) async throws -> TermsTemplate{
        return TermsTemplate(name: "")
    }
    func getTermsTemplateList(companyId:String) async throws -> [TermsTemplate]{
        return []
    }
    func getTermsTemplateListByCategory(companyId:String,category:String) async throws -> [TermsTemplate]{
        return []
        
    }
    func getTermsByTermsTemplate(companyId:String,termsTemplateId:String) async throws-> [ContractTerms] {
        return []
    }
    
    func editTermsTemplateName(companyId:String,termsTemplateId:String,termsTemplateName:String) async throws{
        
    }
    
    func deleteTermsTemplate(companyId:String,termsTemplateId:String) async throws{
        
    }
    func deleteTerms(companyId:String,termsTemplateId:String,termsId:String) async throws{
        
    }
    
    func getCompanysBySearchTerm(searchTerm: String) async throws -> [Company]{
        return []
    }
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws {
        
    }
    
    func saveAssociatedBusinessToCompany(companyId:String,business:AssociatedBusiness) async throws {
        
    }
    func getVehical(companyId: String,vehicalId:String) async throws -> Vehical {
        return MockDataService.mockVehical
    }
    func addNewVehical(companyId:String,vehical:Vehical) async throws {
        
    }
    func getAssociatedBusinesses(companyId:String) async throws -> [AssociatedBusiness] {
        return []
    }
    func getAssociatedBusiness(companyId:String,businessId:String) async throws -> AssociatedBusiness {
        return AssociatedBusiness(id: "", companyId: "", companyName: "")
    }
    func getAssociatedBusinessByCompanyId(companyId:String,businessCompanyId:String) async throws -> AssociatedBusiness {
        return AssociatedBusiness(id: "", companyId: "", companyName: "")
    }
    func getFleet(companyId: String) async throws -> [Vehical] {
        return MockDataService.mockFleet
    }
    
    func getActiveVehicalFleet(companyId: String) async throws -> [Vehical] {
        return MockDataService.mockFleet
    }
    func getCompanyFleetSnapShot(companyId: String) async throws -> [Vehical] {
        return []
    }
    func updateShoppingListDescription(companyId: String, shoppingListItemId: String, newDescription: String) async throws {
        
    }
    func updateShoppingListItemStatus(companyId: String, shoppingListItemId: String, status: ShoppingListStatus) async throws {
  
    }
    func uploadBodyOfWaterImage(companyId: String,bodyOfWaterId:String, image: DripDropImage) async throws ->(path:String, name:String){
        print("uploadBodyOfWaterImage")
        return (path:"",name:"")
    }
    
    func uploadEquipmentImage(companyId: String,equipmentId:String, image: DripDropImage) async throws ->(path:String, name:String){
        print("uploadEquipmentImage")
        return (path:"",name:"")
    }
    func uploadServiceLocationImage(companyId: String,serviceLocationId:String, image: DripDropImage) async throws ->(path:String, name:String){
        return (path:"",name:"")

    }
    func updateDataBaseItem(dataBaseItem: DataBaseItem, companyId: String, name: String, rate: Double, category: DataBaseItemCategory, description: String, sku: String, billable: Bool, color: String, size: String, sellPrice: Double, UOM: String, subCategory: DataBaseItemSubCategory) async throws {
        
    }
    
    func getRecentWorkOrders(companyId: String) async throws -> [Job] {
        return []
    }
    
    func getRecentlyFinishedCount(companyId: String) async throws -> Int {
        return 0
    }
    
    func getAllJobsInProgressCount(companyId: String) async throws -> Int {
        return 4
    }
    
    func getAllJobsOpenedCount(companyId: String) async throws -> Int {
        return 2
    }
    
    func updateInstallationJobParts(companyId: String, jobId: String, installationPart: WODBItem) async throws {
        print("updateInstallationJobParts")
    }
    
    func updatePVCobParts(companyId: String, jobId: String, pvc: WODBItem) async throws {
        print("updatePVCobParts")
        
    }
    
    func updateElectricalJobParts(companyId: String, jobId: String, electical: WODBItem) async throws {
        print("updateElectricalJobParts")
        
    }
    
    func updateChemicalsJobParts(companyId: String, jobId: String, chemical: WODBItem) async throws {
        print("updateChemicalsJobParts")
        
    }
    
    func updateMiscJobParts(companyId: String, jobId: String, misc: WODBItem) async throws {
        print("updateMiscJobParts")
        
    }
    
    func getAllVehicals(companyId:String) async throws -> [Vehical] {
        return MockDataService.mockFleet
    }
    
    func getAllVehicalsCount(companyId:String) async throws -> Int {
        return 6
    }
    func getAllVenderCount(companyId:String) async throws -> Int {
        return 420
    }
    func createNewEquipmentMeasurements(companyId:String,equipmentId:String,equipmentMeasurement:EquipmentMeasurements) async throws {
        
    }
    func getRecentEquipmentMeasurments(companyId:String,equipmentId:String,amount:Int) async throws -> [EquipmentMeasurements] {
        return []
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
    func createInvoice(stripeInvoice: StripeInvoice) async throws {
        print("createInvoice")
    }
    
    func updateInvoiceAsPaid(stripeInvoiceId: String, paymentType: InvoicePaymentType) async throws {
        print("updateInvoiceAsPaid")
        
    }
    
    func deleteInvoice(stripeInvoiceId: String) async throws {
        print("deleteInvoice")
        
    }
    
    func updateEquipmentIsActive(companyId:String,equipmentId:String,isActive:Bool) throws {
    }
    func updateEquipmentDateUninstalled(companyId:String,equipmentId:String,dateUninstalled:Date) throws {
    }
    func uploadRoute(companyId: String, activeRoute: ActiveRoute) async throws {
        print("Upload Route")
    }
    
    func getAllActiveRoutesBasedOnDate(companyId: String, date: Date, tech: DBUser) async throws -> [ActiveRoute] {
        return []
    }
    
    func getAllActiveRoutesBasedOnVehical(companyId: String, vehicalId:String, count: Int) async throws -> [ActiveRoute] {
        return []
    }
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ActiveRoute] {
        return []
    }
    
    static func == (lhs: MockDataService, rhs: MockDataService) -> Bool {
        return lhs.id == rhs.id
    }
    let id = UUID().uuidString
    
    func getAccountsPayableInvoice(companyId: String) async throws -> [StripeInvoice] {
        return [
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                senderId: UUID().uuidString,
                senderName: "Michael Maziuss",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net15,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Caleb Short",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net30,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Michael Espineli",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net45,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Kaden Brownsberg",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net60,
                paymentStatus: .unpaid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Keller Short",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net15,
                paymentStatus: .unpaid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            )
        ]
    }
    
    func getAccountsReceivableInvoice(companyId: String) async throws -> [StripeInvoice] {
        return [
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Michael Maziuss",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net15,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Caleb Short",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net30,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Michael Espineli",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net45,
                paymentStatus: .paid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Kaden Brownsberg",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net60,
                paymentStatus: .unpaid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                ]
            ),
            StripeInvoice(
                id: UUID().uuidString,
                internalIdenifier: "",
                
                senderId: UUID().uuidString,
                senderName: "Keller Short",
                receiverId: UUID().uuidString,
                receiverName: "Murdock Pool Service",
                dateSent: Date(),
                total: 1_000_00,
                terms: .net15,
                paymentStatus: .unpaid,
                paymentType: .cash,
                paymentRefrence: "",
                paymentDate: nil,
                lineItems: [
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: "Residential Pool Cleaning", induvidualCost: 15_00, total: 40),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "2", description: "Commercial Pool Cleaning", induvidualCost: 25_00, total: 15),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "3", description: "Filter Cleaning", induvidualCost: 60_00, total: 4),
                    StripeInvoiceLineItems(id: UUID().uuidString, itemId: "4", description: "Salt Cell Cleaning", induvidualCost: 40_00, total: 7)
                    
                ]
            )
        ]
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    private let db = Firestore.firestore()
    
    
        //        ********     ********         **           **             ***********    ********      ********     ********    ********    **      **
        //        ****         **    **         **           **             **             ****             **           **       **    **    ****    **
        //        **           **    **         **           **             **             **               **           **       **    **    ** **   **
        //        **           **    **         **           **             *********      **               **           **       **    **    **  **  **
        //        **           **    **         **           **             *********      **               **           **       **    **    **   ** **
        //        **           **    **         **           **             **             **               **           **       **    **    **    ****
        //        ****         **    **         **           **             **             ****             **           **       **    **    **     ***
        //        ********     ********         *********    *********      ***********    ********         **        ********    ********    **      **
    
    
        //----------------------------------------------------
        //                    High Level Collections
        //----------------------------------------------------
    
    private func chatCollection() -> CollectionReference{
        db.collection("chats")
    }
        //----------------------------------------------------
        //                    Messages Collections
        //----------------------------------------------------
    private func messageCollection() -> CollectionReference{
        db.collection("messages")
    }
        //----------------------------------------------------
        //                    Invites Collections
        //----------------------------------------------------
    private func inviteCollection() -> CollectionReference{
        db.collection("invites")
    }
        //----------------------------------------------------
        //                    Users Collections
        //----------------------------------------------------
    private func userCollection() -> CollectionReference{
        db.collection("users")
    }
    private func userRecentActivityCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/recentActivity")
    }
    private func userAccessCollection(userId:String) -> CollectionReference{
        db.collection("users/\(userId)/userAccess")
    }
        //----------------------------------------------------
        //                    Companies Collections
        //----------------------------------------------------
    private func companyCollection() -> CollectionReference{
        db.collection("companies")
    }
        //                    Settings Collections
    
    private func SettingsCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings")
    }
    private func BillingTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/billing/billing")
    }
    private func DosageCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/dosages/dosages")
    }
    private func DataBaseCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/dataBase/dataBase")
    }
    private func GenericItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/genericItems/genericItems")
    }
    private func ReadingsCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/readings/readings")
    }
    private func StoreCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/venders/vender")
    }
    private func ServiceStopTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/serviceStops/serviceStops")
    }
    private func TrainingTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/trainingTemplates/trainingTemplates")
    }
    private func WorkOrderTemplateCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/settings/workOrders/workOrders")
    }
        //                    repairRequests Collections
    private func repairRequestCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/repairRequests")
    }
        //                    toDos Collections
    
    private func ToDoCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/toDos")
    }
        //                    receipts Collections
    
    private func ReceiptItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/receipts")
    }
        //                    recurringRoutes Collections
    
    private func recurringRouteCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/recurringRoutes")
    }
        //                    recurringRoutes Collections
    private func contractCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/contracts")
    }
        //                    workOrders Collections
    private func workOrderCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/workOrders")
    }
    private func workOrderInstallationPartsCollection(companyId:String,workOrderId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/workOrders/\(workOrderId)/installationParts")
    }
        //                    stopData Collections
    private func stopDataCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/stopData")
    }
        //                    invoices Collections
    private func InvoiceCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/invoices")
    }
        //                    recurringServiceStop Collections
    private func recurringServiceStopCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/recurringServiceStop")
    }
        //                    trainings Collections
    private func TrainingCollection(companyId:String,techId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/users/\(techId)/trainings")
    }
        //                    serviceLocations Collections
    private func serviceLocationCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/serviceLocations")
    }
        //                    serviceStops Collections
    private func serviceStopCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/serviceStops")
    }
    private func readingCollectionForServiceStop(serviceStopId:String,companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/serviceStops/\(serviceStopId)/stores")
    }
        //                    stopData Collections
    
    private func readingCollectionForCustomerHistory(customerId:String,companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/stopData")
    }
        //                    roles Collections
    private func roleCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/roles")
    }
        //                    shoppingList Collections
    private func shoppingListCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/shoppingList")
    }
        //                    equipment Collections
    
    private func equipmentCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment")
    }
    private func equipmentPartCollection(companyId:String,equipmentId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/equipment/\(equipmentId)/parts")
    }
        //                    customers Collections
    private func customerCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/customers")
    }
        //                    purchasedItems Collections
    private func PurchaseItemCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/purchasedItems")
    }
        //                    companyUsers Collections
    
    private func companyUsersCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/companyUsers")
    }
    private func companyUsersRateSheetCollection(companyId:String,companyUserId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/companyUsers/\(companyUserId)/rateSheet")
    }
        //                    bodiesOfWater Collections
    private func bodyOfWaterCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/bodiesOfWater")
    }
        //        *******       ********      *********      ********       **       **     ******     ******     ********     **      **   ********
        //        **    **      **    **      **     **      **             **       **     **  ***   **   **     **           ****    **      **
        //        **      **    **    **      **     **      **             **       **     **   **  **    **     **           ** **   **      **
        //        **       **   **    **      **     **      **             **       **     **    ****     **     ****         **  **  **      **
        //        **       **   **    **      **     **      **             **       **     **             **     ****         **   ** **      **
        //        **      **    **    **      **     **      **             **       **     **             **     **           **    ****      **
        //        **    **      **    **      **     **      **             **       **     **             **     **           **     ***      **
        //        *******       ********      *********      *********      ***********     **             **     ********     **      **      **
    
    private func ReadingsTemplateDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        ReadingsCollection(companyId: companyId).document(readingTemplateId)
    }
    private func DosageTemplateDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        DosageCollection(companyId: companyId).document(dosageTemplateId)
    }
    private func GenericItemDocument(genericItemId:String,companyId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
    }
    private func bodyOfWaterDoc(companyId:String,bodyOfWaterId:String)-> DocumentReference{
        bodyOfWaterCollection(companyId: companyId).document(bodyOfWaterId)
    }
    private func chatDocument(chatId:String)-> DocumentReference{
        chatCollection().document(chatId)
    }
    private func messageDocument(messageId:String)-> DocumentReference{
        messageCollection().document(messageId)
    }
    private func StoreDocument(storeId:String,companyId:String)-> DocumentReference{
        StoreCollection(companyId: companyId).document(storeId)
        
    }
    private func DataBaseDocument(dataBaseId:String,companyId:String)-> DocumentReference{
        DataBaseCollection(companyId: companyId).document(dataBaseId)
        
    }
    private func ToDoDocument(toDoId:String,companyId:String)-> DocumentReference{
        ToDoCollection(companyId: companyId).document(toDoId)
    }
    private func repairRequestDocument(companyId:String,repairRequestId:String)-> DocumentReference{
        repairRequestCollection(companyId: companyId).document(repairRequestId)
    }
    private func ReceiptItemDocument(receiptItemId:String,companyId:String)-> DocumentReference{
        ReceiptItemCollection(companyId: companyId).document(receiptItemId)
    }
    private func contractDocument(companyId:String,contractId:String)-> DocumentReference{
        contractCollection(companyId: companyId).document(contractId)
    }
    private func reccuringRouteDoc(companyId:String,recurringRouteId:String)-> DocumentReference{
        recurringRouteCollection(companyId: companyId).document(recurringRouteId)
    }
    private func workOrderDocument(workOrderId:String,companyId:String)-> DocumentReference{
        workOrderCollection(companyId: companyId).document(workOrderId)
    }
    private func stopDataDocument(companyId:String,stopDataId:String)-> DocumentReference{
        stopDataCollection(companyId: companyId).document(stopDataId)
    }
    private func WorkOrderDocument(workOrderTemplateId:String,companyId:String)-> DocumentReference{
        WorkOrderTemplateCollection(companyId: companyId).document(workOrderTemplateId)
    }
    private func ServiceStopDocument(serviceStopTemplateId:String,companyId:String)-> DocumentReference{
        ServiceStopTemplateCollection(companyId: companyId).document(serviceStopTemplateId)
    }
    private func ReadingsDocument(readingTemplateId:String,companyId:String)-> DocumentReference{
        ReadingsCollection(companyId: companyId).document(readingTemplateId)
    }
    private func DosageDocument(dosageTemplateId:String,companyId:String)-> DocumentReference{
        DosageCollection(companyId: companyId).document(dosageTemplateId)
    }
    private func recurringServiceStopDocument(recurringServiceStopId:String,companyId:String)-> DocumentReference{
        recurringServiceStopCollection(companyId: companyId).document(recurringServiceStopId)
    }
    private func BillingTemplateDocument(billingTemplateId:String,companyId:String)-> DocumentReference{
        BillingTemplateCollection(companyId: companyId).document(billingTemplateId)
    }
    private func TrainingDocument(trainingId:String,companyId:String,techId:String)-> DocumentReference{
        TrainingCollection(companyId: companyId,techId: techId).document(trainingId)
    }
    private func TrainingTemplateDocument(trainingTemplateId:String,companyId:String)-> DocumentReference{
        TrainingTemplateCollection(companyId: companyId).document(trainingTemplateId)
    }
    private func inviteDoc(inviteId:String)-> DocumentReference{
        inviteCollection().document(inviteId)
    }
    private func serviceLocationDoc(companyId:String,serviceLocationId:String)-> DocumentReference{
        serviceLocationCollection(companyId: companyId).document(serviceLocationId)
    }
    private func readingDocumentToServiceStop(serviceStopId:String,stopDataId:String,companyId:String)-> DocumentReference{
        readingCollectionForServiceStop(serviceStopId: serviceStopId, companyId: companyId).document(stopDataId)
    }
    private func readingDocumentToCustomerHistory(customerId:String,stopDataId:String,companyId:String)-> DocumentReference{
        readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId).document(stopDataId)
    }
    private func userDocument(userId:String) -> DocumentReference{
        userCollection().document(userId)
    }
        //    private func userCompanyDocument(userId:String,companyId:String) -> DocumentReference{
        //        companyUserCollection().document(userId)
        //    }
    private func GenericItemDocument(companyId:String,genericItemId:String)-> DocumentReference{
        GenericItemCollection(companyId: companyId).document(genericItemId)
    }
    private func CompanyDocument(companyId:String)-> DocumentReference{
        companyCollection().document(companyId)
    }
    private func roleDoc(companyId:String,roleId:String)-> DocumentReference{
        roleCollection(companyId: companyId).document(roleId)
    }
    private func serviceStopDocument(serviceStopId:String,companyId:String)-> DocumentReference{
        serviceStopCollection(companyId: companyId).document(serviceStopId)
    }
    private func shoppingListDoc(companyId:String,shoppingListItemId:String)-> DocumentReference{
        shoppingListCollection(companyId: companyId).document(shoppingListItemId)
    }
    private func customerDocument(customerId:String,companyId:String)-> DocumentReference{
        customerCollection(companyId: companyId).document(customerId)
    }
    private func PurchaseItemDocument(purchaseItemId:String,companyId:String)-> DocumentReference{
        PurchaseItemCollection(companyId: companyId).document(purchaseItemId)
        
    }
    private func companyUserDoc(companyId:String,companyUserId:String) -> DocumentReference{
        companyUsersCollection(companyId: companyId).document(companyUserId)
    }
    private func companyUserRateSheetDoc(companyId:String,companyUserId:String,rateSheetId:String) -> DocumentReference{
        companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId).document(rateSheetId)
    }
    private func userActivityDocument(userId:String,recentActivityId:String) -> DocumentReference{
        userRecentActivityCollection(userId: userId).document(recentActivityId)
    }
    private func userDocument(userId:String,accessId:String) -> DocumentReference{
        userAccessCollection(userId: userId).document(accessId)
    }
    private func equipmentDoc(companyId:String,equipmentId:String)-> DocumentReference{
        equipmentCollection(companyId: companyId).document(equipmentId)
    }
    private func equipmentPartDoc(companyId:String,equipmentId:String,partId:String)-> DocumentReference{
        equipmentPartCollection(companyId: companyId, equipmentId: equipmentId).document(partId)
    }
        //----------------------------------------------------
        //                    Listeners
        //----------------------------------------------------
    private var serviceStopListener: ListenerRegistration? = nil
    private var chatListener: ListenerRegistration? = nil
    private var messageListener: ListenerRegistration? = nil
    private var equipmentListener: ListenerRegistration? = nil
    private var customerListener: ListenerRegistration? = nil
    private var dataBaseListener: ListenerRegistration? = nil
    private var requestListener: ListenerRegistration? = nil
    private var jobListener: ListenerRegistration? = nil
    
        //----------------------------------------------------
        //                    Coordinates
        //----------------------------------------------------
    
    @Published private(set) var Coordinates: CLLocationCoordinate2D? = nil
    
    let geoCoder = CLGeocoder()
        //------------------------------------------------------------------------------------------------------------------------------------------------------------
        //
        //                    BASIC CRUD FUNCTIONS
        //
        //---------------------------------------------------------------------------------------------------------------------------------------------------------
    
    
    
    
    
    
    
        //----------------------------------------------------
        //                    Create Functions
        //----------------------------------------------------
    func addNewToDo(companyId:String, todo:ToDo) async throws {
        try ToDoDocument(toDoId: todo.id, companyId: companyId)
            .setData(from:todo, merge: false)
    }
    
    func loadCurrentUser() async throws -> DBUser{
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        return try await UserManager.shared.getCurrentUser(userId: authDataResult.uid)
        
    }
    func createNewUser(user:DBUser) async throws{
        let DBUser = try await DBUserManager.shared.loadCurrentUser()//DEVELOPER DELETE
        try userDocument(userId: user.id).setData(from: user,merge: false,encoder: encoder)
    }
    func createFirstCompanyUser(user:DBUser) async throws{
        try userDocument(userId: user.id ).setData(from: user,merge: false)
    }
    func createNewRecentActivity(userId:String,recentActivity:RecentActivityModel) async throws{
        try userActivityDocument(userId: userId,recentActivityId: recentActivity.id).setData(from: recentActivity,merge: false)
    }
    
    
    func updateCompanyUser(user:DBUser,updatingUser:DBUser) throws {
            //        let ref = userDocument(userId: updatingUser.id, companyId: user.companyId)
            //
            //         ref.updateData([
            //            "email": updatingUser.email,
            //            "photoUrl": updatingUser.photoUrl as Any,
            //            "dateCreated": updatingUser.dateCreated as Any,
            //            "firstName": updatingUser.firstName as Any,
            //            "lastName": updatingUser.lastName as Any,
            //            "company": updatingUser.company as Any,
            //            "companyId": updatingUser.companyId,
            //            "position": updatingUser.position,
            //            "hireDate": updatingUser.hireDate as Any,
            //            "fireDate": updatingUser.fireDate as Any,
            //            "favorites": updatingUser.favorites as Any,
            //        ]) { err in
            //            if let err = err {
            //                print("Error updating document: \(err)")
            //            } else {
            //                print("Updated Company User Successfully")
            //            }
            //        }
    }
    func updateCompanyUserRole(companyId:String,companyUserId:String,roleId:String,roleName:String) async throws{
    }
    func updateCompanyUserWorkerType(companyId:String,companyUserId:String,workerType:WorkerTypeEnum) async throws {
    }
        //DEVELOPER MAKE SURE THIS IS NOT NEEDED
        //    func createNewUser(user:DBUser) async throws{
        //        try userDocument(userId: user.id).setData(from: user,merge: false)
        //        //        try userDocument(userId: user.id).setData(from: user,merge: false)
        //
        //        print("New User Created")
        //    }
    
        //DEVELOPER MAKE SURE THIS IS NOT NEEDED
        //    func loadCurrentUser() async throws -> DBUser{
        //
        //        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        //
        //        return try await DBUserManager.shared.getCurrentUser(userId: authDataResult.uid)
        //
        //    }
    func uploadUserAccess(userId : String,companyId:String,userAccess:UserAccess) async throws {
        print("Attempting to Up Load \(userId) Have access to \(userAccess.companyName) to Firestore")
        
        try userDocument(userId: userId, accessId: companyId).setData(from:userAccess, merge: false)
    }
    func addCompanyUser(companyId:String,companyUser:CompanyUser) async throws{
        try companyUserDoc(companyId: companyId, companyUserId: companyUser.id).setData(from:companyUser, merge: false)
        
    }
    func addNewRateSheet(companyId:String,companyUserId:String,rateSheet:RateSheet) async throws {
        try companyUserRateSheetDoc(companyId: companyId, companyUserId: companyUserId, rateSheetId: rateSheet.id).setData(from:rateSheet, merge: false)
    }
    func uploadPurchaseItem(companyId: String,purchaseItem : PurchasedItem) async throws {
        
        try PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData(from:purchaseItem, merge: false)
    }
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws{
        print("UploadingCustomerMonthlySummary")
        print(companyId)
        
        try db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(customerMonthlySummary.id)
            .setData(from:customerMonthlySummary, merge: false)
    }
    func uploadCSVCustomerToFireStore(companyId:String,customer: CSVCustomer) async throws{
        
        print("Begin to UpLoad \(customer.firstName) \(customer.lastName) to Firestore 1")
        let identification:String = UUID().uuidString
        var DBAddress = Address(streetAddress: customer.streetAddress, city: customer.city, state: customer.state, zip: customer.zip,latitude: 0.0,longitude: 0.0)
        
        let fulladdress = DBAddress.streetAddress + " " + DBAddress.city + " " + DBAddress.state + " " + DBAddress.zip
        let fullName = customer.firstName + " " + customer.lastName
        let geoCoder = CLGeocoder()
        
        geoCoder.geocodeAddressString(fulladdress) {
            placemarks, error in
            let placemark = placemarks?.first
            self.Coordinates = placemark?.location?.coordinate
        }
            //add back in before production or if I am adding more than 50 customers
        let hireDateString = customer.hireDate
        
            // Create Date Formatter
        let dateFormatter = DateFormatter()
        
            // Convert String to Date
        let hireDate:Date = dateFormatter.date(from: hireDateString) ?? Date()
        
        usleep(1201000)
        
        let pushCoordinates = self.Coordinates
        DBAddress.latitude = pushCoordinates?.latitude ?? 32.8
        DBAddress.longitude = pushCoordinates?.longitude ?? -117.8
        print("Received Coordinates from geoCoder : \(String(describing: pushCoordinates))")
        
        let DBCustomer:Customer = Customer(
            id: identification,
            firstName: customer.firstName ,
            lastName:customer.lastName,
            email:customer.email,
            billingAddress:DBAddress ,
            phoneNumber: customer.phone,
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: hireDate,
            billingNotes: "NA" ,
            linkedInviteId: UUID().uuidString
        )
        
        print("Uploading Customer - \(customer.firstName) - \(customer.lastName)")
            //        try await dataService.uploadCustomer(companyId: companyId, customer: DBCustomer)
        let serviceLocationId:String = UUID().uuidString
        let bodyOfWaterId:String = UUID().uuidString
        
        
        
        
        sleep(1)
            //Uploading Customer Billing Type
        let billingTempalte = try await BillingManager.shared.getDefaultBillingTempalte(companyId: companyId)
        
            //Uploading Customer Service Locations
        
        let serviceLocation:ServiceLocation = ServiceLocation(id: serviceLocationId,
                                                              nickName: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                              address: DBCustomer.billingAddress,
                                                              gateCode: "",
                                                              mainContact: Contact(id: UUID().uuidString,
                                                                                   name: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                                                   phoneNumber: DBCustomer.phoneNumber ?? "",
                                                                                   email: DBCustomer.email,
                                                                                   notes: ""),
                                                              bodiesOfWaterId: [bodyOfWaterId],
                                                              rateType: billingTempalte.title,
                                                              laborType: billingTempalte.laborType,
                                                              chemicalCost: billingTempalte.chemType,
                                                              laborCost: "15",
                                                              rate: customer.rate,
                                                              customerId: DBCustomer.id,
                                                              customerName: ((DBCustomer.firstName) + " " + (DBCustomer.lastName)),
                                                              preText: false)
        
        try await ServiceLocationManager.shared.uploadCustomerServiceLocations(
            companyId: companyId,
            customer: DBCustomer,
            serviceLocation: serviceLocation
        )
        print(
            " - Service Location - Check"
        )
        
            //Uploading Body of water
        
        let bodyOfwater = BodyOfWater(
            id: bodyOfWaterId,
            name: "Main",
            gallons: "16000",
            material: "Plaster",
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id, 
            lastFilled: Date()
        )
        try await BodyOfWaterManager.shared.uploadBodyOfWaterByServiceLocation(
            companyId:companyId,
            bodyOfWater: bodyOfwater
        )
        print(
            " - Body Of Water - Check"
        )
        let pump = Equipment(
            id: UUID().uuidString,
            name:"Pump 1",
            category: .pump,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id,
            isActive: true
        )
        let filter = Equipment(
            id: UUID().uuidString,
            name:"Filter 1",
            category: .filter,
            make: "",
            model: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: true,
            lastServiceDate: Date(),
            serviceFrequency: "Month",
            serviceFrequencyEvery: "6",
            notes: "",
            customerName: fullName,
            customerId: DBCustomer.id,
            serviceLocationId: serviceLocation.id,
            bodyOfWaterId: bodyOfwater.id,
            isActive: true
        )
        
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: pump
        )
        try await EquipmentManager.shared.addNewEquipmentWithParts(
            companyId: companyId,
            equipment: filter
        )
        print(" - Equipment - Check")
        
        
        print("Finished Uploaded \(customer.firstName) \(customer.lastName) to Firestore")
        
    }
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws{
        print("Uploading Service Location >>\(serviceLocation.id) For customer >> \(customer.firstName)")
        let coordinates = try await convertAddressToCordinates1(address: serviceLocation.address)
        print("Received Coordinates \(String(describing: coordinates))")
        var pushLocation = serviceLocation
        pushLocation.address.latitude = coordinates.latitude
        pushLocation.address.longitude = coordinates.longitude
        
        try serviceLocationCollection(companyId: companyId).document(serviceLocation.id).setData(from:serviceLocation, merge: false)
    }
    func uploadServiceLocationBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        print(companyId)
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }
    func uploadBodyOfWaterByServiceLocation(companyId:String,bodyOfWater:BodyOfWater) async throws{
        print("using upload Service Locations Body of Water function")
        try bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id).setData(from:bodyOfWater, merge: false)
    }
    func uploadEquipment(companyId:String,equipment:Equipment) async throws {
        
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: false)
        
    }
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws {
        try await EquipmentManager.shared.uploadEquipment(companyId: companyId, equipment: equipment)
        print("\(equipment.category)")
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in filterPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            for part in pumpPartList {
                print(part.name)
                
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Returned")
            return
        }
    }
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws {
        switch equipment.category {
        case .filter:
            let filterPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Pressure Gauge",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Spring Nut Assembly",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Manifold",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Short Grid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 1",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 2",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 3",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 4",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 5",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 6",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .filter,
                    name: "Grid 7",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Filter")
            
            for part in filterPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
            
        case .pump:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Basket",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Lid",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "O-Ring",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .pump,
                    name: "Motor",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .cleaner:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Tires/Wheel",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Gear Box",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Turbine",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .cleaner,
                    name: "Hose",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                
            ]
            print("Vacuum")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .saltCell:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .saltCell,
                    name: "Salt Cell",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
            ]
            print("Salt Cell")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .heater:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .heater,
                    name: "Heater",
                    date: equipment.dateInstalled,
                    notes: ""
                ),
                //DEVELOPER HERE
                
            ]
            print("Heater")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        case .light:
            
            let pumpPartList:[EquipmentPart] = [
                EquipmentPart(
                    id: UUID().uuidString,
                    equipmentType: .light,
                    name: "Light",
                    date: Date(),
                    notes: ""
                ),
                
            ]
            print("Pump")
            
            for part in pumpPartList {
                print(part.name)
                try await EquipmentManager.shared.uploadEquipmentPart(companyId: companyId, equipmentId: equipment.id, part: part)
            }
        default:
            print("Return")
            return
        }
    }
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
        try equipmentPartDoc(companyId: companyId,equipmentId: equipmentId,partId: part.id)
            .setData(from:part, merge: false)
    }
    
    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws {
        try serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).setData(from:serviceStop, merge: false)
    }
    func uploadRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }
    func uploadCompany(company : Company) async throws {
        try CompanyDocument(companyId: company.id).setData(from:company, merge: false)
    }
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) throws {
        
        var DBArray: [String] = []
        print("Throw error Here")
        DBArray = genericItem.storeItems
        DBArray.append(storeItem.id)
        print(genericItem.id)
        let ref = GenericItemCollection(companyId: companyId).document(genericItem.id)
        ref.updateData([
            "storeItems": DBArray
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
        
    }
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws {
        try shoppingListCollection(companyId: companyId).document(shoppingListItem.id).setData(from:shoppingListItem, merge: false)
        
    }
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws {
        
        try GenericItemDocument(companyId: companyId, genericItemId: genericItem.id).setData(from:genericItem, merge: false)
    }
    func createIntialGenericDataBaseItems(companyId:String) async throws{
        let genericItems:[GenericItem] = [
            //Chemicals
            GenericItem(id: "Chlorine", commonName: "Chlorine", specificName: "Bleach", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Acid", commonName: "Acid", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Gallon", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodiumBromide", commonName: "Sodium Bromide", specificName: "Muriatic Acid 15%", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Tabs", commonName: "Tabs", specificName: "3in Chlorine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "BromineTabs", commonName: "Bromine Tabs", specificName: "Bromine Tabs", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Tab", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Salt", commonName: "Salt", specificName: "Salt", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Lbs", storeItems: [], storeItemsIds: []),
            GenericItem(id: "SodaAsh", commonName: "Soda Ash", specificName: "Soda Ash", category: "Chemical", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "Oz", storeItems: [], storeItemsIds: []),
            //PVC
            GenericItem(id: "Pipe", commonName: "Pipe", specificName: "Pipe", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Coupler", commonName: "Coupler", specificName: "Coupler", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "Elbow", commonName: "Elbow", specificName: "Elbow", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: []),
            GenericItem(id: "45", commonName: "45", specificName: "45", category: "PVC", description: "", dateUpdated: Date(), sku: "",rate:0.00,sellPrice:0 ,UOM: "part", storeItems: [], storeItemsIds: [])
        ]
        
        for item in genericItems {
            try GenericItemDocument(companyId: companyId, genericItemId: item.id).setData(from:item, merge:false)
            
        }
        
    }
    
    func uploadStore(companyId:String,store : Vender) async throws {
        
        return try StoreDocument(storeId: store.id, companyId: companyId).setData(from:store, merge: false)
    }
    func uploadChat(userId:String,chat:Chat) async throws {
        try chatDocument(chatId: chat.id)
            .setData(from:chat, merge: false)
    }
    func sendMessage(userId: String, message: Message) async throws {
        try messageDocument(messageId: message.id)
            .setData(from:message, merge: false)
    }
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: false)
    }
    func uploadGenericItem(companyId:String,workOrderTemplate : GenericItem) async throws {
        try GenericItemDocument(genericItemId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func uploadWorkOrderTemplate(companyId:String,workOrderTemplate : JobTemplate) async throws {
        
        try WorkOrderDocument(workOrderTemplateId: workOrderTemplate.id, companyId: companyId).setData(from:workOrderTemplate, merge: false)
    }
    func uploadServiceStopTemplate(companyId:String,template : ServiceStopTemplate) async throws {
        
        try ServiceStopDocument(serviceStopTemplateId: template.id, companyId: companyId)
            .setData(from:template, merge: false)
    }
    
        //Readings settings
    
    
    func uploadReadingTemplate(readingTemplate : ReadingsTemplate,companyId:String) async throws {
        
        try ReadingsDocument(readingTemplateId: readingTemplate.id,companyId: companyId).setData(from:readingTemplate, merge: false)
    }
    
    
    
    
    
    
        //Dosages settings
    
    
    func uploadDosageTemplate(dosageTemplate : DosageTemplate,companyId:String) async throws {
        
        try DosageDocument(dosageTemplateId: dosageTemplate.id,companyId: companyId).setData(from:dosageTemplate, merge: false)
    }
    
    
        //recurringServiceStop Settings
    func upLoadStartingCompanySettings(companyId:String) async throws{
        
        let WOIncrement = Increment(category: "workOrders", increment: 0)
        let SSIncrement = Increment(category: "serviceStops", increment: 0)
        let RIncrement = Increment(category: "receipts", increment: 0)
        let RountIncrement = Increment(category: "recurringServiceStops", increment: 0)
        let StoreIncrement = Increment(category: "venders", increment: 0)
        let ToDoIncrement = Increment(category: "toDos", increment: 0)
        
        try db.collection("companies/\(companyId)/settings").document("workOrders").setData(from:WOIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("serviceStops").setData(from:SSIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("receipts").setData(from:RIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("recurringServiceStops").setData(from:RountIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("venders").setData(from:StoreIncrement , merge:false)
        try db.collection("companies/\(companyId)/settings").document("workOrders").setData(from:ToDoIncrement , merge:false)
        
    }
    
    func upLoadInitialGenericRoles(companyId:String) async throws {
        let roles:[Role] = [
            Role(id: "1", name: "Owner", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "All Permissions Enabled"),
            
            Role(id: UUID().uuidString, name: "Tech", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Techs"),
            Role(id: UUID().uuidString, name: "Manager", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Manager"),
            Role(id: UUID().uuidString, name: "Admin", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Admin"),
            Role(id: UUID().uuidString, name: "Office", permissionIdList: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21"], listOfUserIdsToManage: [], color: "red", description: "Basic Permissions For Office Personal")
        ]
        print("Adding Work Order Templates")
        for role in roles {
            try await RoleManager.shared.uploadRole(companyId: companyId, role: role)
        }
    }
    func upLoadIntialWorkOrdersAndReadingsAndDosages(companyId:String) async throws->[TrainingTemplate]{
        let weeklyCleaningId = "2"
        let saltCellId = UUID().uuidString
        let filterCleaningId = UUID().uuidString
        let esitmateId = UUID().uuidString
        let serviceCallId = UUID().uuidString
        let DrainandfillID = UUID().uuidString
        let isntallId = UUID().uuidString
        let repairID = UUID().uuidString
        let startUpEstimateId = "2"
        
        let serviceStopEstiamteId = UUID().uuidString
        let serviceStopFollowUpId = UUID().uuidString
        let serviceStopLaborId = UUID().uuidString
        
        let InitialTemplates:[JobTemplate] = [
            
            JobTemplate(id: weeklyCleaningId, name: "Weekly Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "red"),
            JobTemplate(id: filterCleaningId, name: "Filter Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "120", color: "orange"),
            JobTemplate(id: saltCellId, name: "Salt Cell Cleaning", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "85", color: "yellow"),
            JobTemplate(id: esitmateId, name: "Weekly Cleaning Estimate", type: "Estimate", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "green"),
            JobTemplate(id: serviceCallId, name: "Service Call", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "blue"),
            JobTemplate(id: DrainandfillID, name: "Drain and Fill", type: "Maintenance", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: isntallId, name: "Installation", type: "Installation", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: repairID, name: "Repair", type: "Repair", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "purple"),
            JobTemplate(id: startUpEstimateId, name: "Start Up Estimate", type: "Estimate", typeImage: "wrench", dateCreated: Date(), rate: "0", color: "black",locked: true)
            
        ]
        let InitialServiceStopTemplates:[ServiceStopTemplate] = [
            
            ServiceStopTemplate(id: serviceStopEstiamteId, name: "Estimate", type: "Estimate" , typeImage: "list.clipboard", dateCreated: Date(), color: "red"),
            ServiceStopTemplate(id: serviceStopLaborId, name: "Labor", type: "Labor" , typeImage: "wrench", dateCreated: Date(), color: "blue"),
            ServiceStopTemplate(id: serviceStopFollowUpId, name: "Follow Up", type: "Follow Up" , typeImage: "wrench", dateCreated: Date(), color: "green"),
            
        ]
        let genericTemplateList:[TrainingTemplate] = [
            TrainingTemplate(id: UUID().uuidString, name: "Pool Cleaning", description: "", workOrderIds: [weeklyCleaningId]),
            TrainingTemplate(id: UUID().uuidString, name: "Filter Cleaning", description: "", workOrderIds: [filterCleaningId]),
            TrainingTemplate(id: UUID().uuidString, name: "General Repair", description: "", workOrderIds: [repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Drain and Fill", description: "", workOrderIds: [DrainandfillID]),
            TrainingTemplate(id: UUID().uuidString, name: "Managment Training", description: "", workOrderIds: [serviceCallId,esitmateId,startUpEstimateId]),
            TrainingTemplate(id: UUID().uuidString, name: "Filter Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Pump Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
            TrainingTemplate(id: UUID().uuidString, name: "Heater Repair / Install", description: "", workOrderIds: [isntallId,repairID]),
        ]
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString
        
        let InitialDosageTemplates:[DosageTemplate] = [
            DosageTemplate(id: chlorineDosageID, name: "Liquid Chlorine", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil, strength: 0.13, editable: false,chemType: "Liquid Chlorine",order: 1),
            
            DosageTemplate(id: tabsID, name: "Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "3 in Tabs", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Tabs",order: 2),
            
            DosageTemplate(id: acidID, name: "Muratic Acid", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil,strength: 0.14, editable: false,chemType: "Muratic Acid",order: 3),
            
            
            DosageTemplate(id: sodaAsh, name: "Soda Ash", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "1.00",
                           linkedItemId: nil, strength: 1, editable: false,chemType: "Soda Ash",order: 4),
            
            DosageTemplate(id: sodiumBromideId, name: "Sodium Bromide", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Sodium Bromide",order: 5),
            
            DosageTemplate(id: bromideTabs, name: "Bromide Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "Tab", rate: "2.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Bromide Tabs",order: 6),
            
            
            DosageTemplate(id: saltId, name: "Salt", amount: ["0","40","80","120","160","200","240","280"], UOM: "Lbs", rate: "0.10", linkedItemId: nil, strength: 1, editable: false,chemType: "Salt",order: 7)
            
        ]
        
        let InitialReadingsTemplates:[ReadingsTemplate] = [
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Disolved Solids", amount: ["100","150","200","250","300","350","400","450"], UOM: "ppm", chemType: "Total Disolved Solids", linkedDosage: "0", editable: false,order: 1,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Free Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Free Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 3 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Total Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 2 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "pH", amount: ["6.8","7.0","7.2","7.4","7.6","7.8","8.0","8.2"], UOM: "pH", chemType: "pH", linkedDosage: acidID, editable: false,order: 4 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Alkalinity", amount: ["40","80","120","180","200","220"], UOM: "ppm", chemType: "Alkalinity", linkedDosage: "0", editable: false,order: 5 ,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Cyanuric Acid", amount: ["10","20","30","50","80","120","150","300"], UOM: "ppm",
                             chemType: "Cyanuric Acid", linkedDosage: "0", editable: false,order: 6 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Salt", amount: ["500","1000","1500","2000","2500","3000","3500","4000","4500"],
                             UOM: "ppm", chemType: "Salt", linkedDosage: saltId, editable: false,order: 7 ,highWarning: 0, lowWarning: 0),
            
            
        ]
        print("Adding Work Order Templates")
        for template in InitialTemplates {
            try await SettingsManager.shared.uploadWorkOrderTemplate(companyId: companyId, workOrderTemplate: template)
        }
        print("Adding Service Stop Templates")
        for template in InitialServiceStopTemplates {
            try await SettingsManager.shared.uploadServiceStopTemplate(companyId: companyId, template: template)
        }
        print("Adding Dosage Templates")
        
        for template in InitialDosageTemplates {
            try DosageTemplateDocument(dosageTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
        }
        print("Adding Reading Templates")
        
        for template in InitialReadingsTemplates {
            try ReadingsTemplateDocument(readingTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
            
        }
        return genericTemplateList
    }
    func upLoadReadingTemplates(companyId:String) async throws{
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString
        
        let InitialReadingsTemplates:[ReadingsTemplate] = [
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Disolved Solids", amount: ["100","150","200","250","300","350","400","450"], UOM: "ppm", chemType: "Total Disolved Solids", linkedDosage: "0", editable: false,order: 1,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Free Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Free Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 3 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Total Chlorine", amount: ["0","1","2","3","4","5","6","7"], UOM: "ppm", chemType: "Total Chlorine", linkedDosage: chlorineDosageID, editable: false,order: 2 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "pH", amount: ["6.8","7.0","7.2","7.4","7.6","7.8","8.0","8.2"], UOM: "pH", chemType: "pH", linkedDosage: acidID, editable: false,order: 4 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Alkalinity", amount: ["40","80","120","180","200","220"], UOM: "ppm", chemType: "Alkalinity", linkedDosage: "0", editable: false,order: 5 ,highWarning: 0, lowWarning: 0),
            
            ReadingsTemplate(id: UUID().uuidString, name: "Cyanuric Acid", amount: ["10","20","30","50","80","120","150","300"], UOM: "ppm",
                             chemType: "Cyanuric Acid", linkedDosage: "0", editable: false,order: 6 ,highWarning: 0, lowWarning: 0),
            
            
            ReadingsTemplate(id: UUID().uuidString, name: "Salt", amount: ["500","1000","1500","2000","2500","3000","3500","4000","4500"],
                             UOM: "ppm", chemType: "Salt", linkedDosage: saltId, editable: false,order: 7 ,highWarning: 0, lowWarning: 0),
            
            
        ]
        
        print("Adding Reading Templates")
        
        for template in InitialReadingsTemplates {
            try ReadingsTemplateDocument(readingTemplateId: template.id,companyId: companyId).setData(from:template, merge: false)
            
        }
    }
    func uploadDosageTemplates(companyId:String) async throws{
        let chlorineDosageID = UUID().uuidString
        let tabsID = UUID().uuidString
        let acidID = UUID().uuidString
        let sodaAsh = UUID().uuidString
        let sodiumBromideId = UUID().uuidString
        let bromideTabs = UUID().uuidString
        let saltId = UUID().uuidString
        
        let InitialDosageTemplates:[DosageTemplate] = [
            DosageTemplate(id: chlorineDosageID, name: "Liquid Chlorine", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil, strength: 0.13, editable: false,chemType: "Liquid Chlorine",order: 1),
            
            DosageTemplate(id: tabsID, name: "Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "3 in Tabs", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Tabs",order: 2),
            
            DosageTemplate(id: acidID, name: "Muratic Acid", amount: ["0","0.25","0.50","0.75","1.00","1.25","1.50","1.75","2.00","2.25","2.50","2.75","3.00","4.00","5.00","6.00","7.00","8.00","9.00","10.00","11.00","12.00","16.00"], UOM: "gallon", rate: "5.00", linkedItemId: nil,strength: 0.14, editable: false,chemType: "Muratic Acid",order: 3),
            
            
            DosageTemplate(id: sodaAsh, name: "Soda Ash", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "1.00",
                           linkedItemId: nil, strength: 1, editable: false,chemType: "Soda Ash",order: 4),
            
            DosageTemplate(id: sodiumBromideId, name: "Sodium Bromide", amount: ["0","1","2","3","4","5","6","7"], UOM: "oz", rate: "5.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Sodium Bromide",order: 5),
            
            DosageTemplate(id: bromideTabs, name: "Bromide Tabs", amount: ["0","1","2","3","4","5","6","7"], UOM: "Tab", rate: "2.00", linkedItemId: nil, strength: 1, editable: false,chemType: "Bromide Tabs",order: 6),
            
            
            DosageTemplate(id: saltId, name: "Salt", amount: ["0","40","80","120","160","200","240","280"], UOM: "Lbs", rate: "0.10", linkedItemId: nil, strength: 1, editable: false,chemType: "Salt",order: 7)
            
        ]
        
        print("Adding Reading Templates")
        
        for template in InitialDosageTemplates {
            try DosageTemplateDocument(dosageTemplateId: template.id, companyId: companyId).setData(from:template, merge: false)
            
        }
    }
    func uploadBillingTemplate(billingTempalte : BillingTemplate,companyId:String) async throws {
        
        try BillingTemplateDocument(billingTemplateId: billingTempalte.id, companyId: companyId)
            .setData(from:billingTempalte, merge: false)
    }
    func uploadGenericBillingTempaltes(companyId:String) async throws {
            //        var laborType:String //per Stop, Weekly, Monthly
            //        var chemType:String //All inclusive, Without Chems, Includes specific Chems, Excludes Specific Chems
            //
        
        let tempalteArray:[BillingTemplate] = [
            BillingTemplate(id: UUID().uuidString, title: "No Worry Service", defaultSelected: false, laborType: "per Stop", chemType: "All inclusive", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Cheap Service", defaultSelected: false, laborType: "per Stop", chemType: "Without Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Normal Service", defaultSelected: true, laborType: "per Stop", chemType: "Includes specific Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "A La Carte", defaultSelected: false, laborType: "per Stop", chemType: "Excludes Specific Chems", notes: ""),
            
            BillingTemplate(id: UUID().uuidString, title: "Type 1", defaultSelected: false, laborType: "per month", chemType: "All inclusive", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 2", defaultSelected: false, laborType: "per month", chemType: "Without Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 3", defaultSelected: false, laborType: "per month", chemType: "Includes specific Chems", notes: ""),
            BillingTemplate(id: UUID().uuidString, title: "Type 4", defaultSelected: false, laborType: "per month", chemType: "Excludes Specific Chems", notes: "")
            
        ]
        var tempalteCount = 0
        for template in tempalteArray {
            print("uploading Template \(tempalteCount)")
            try await uploadBillingTemplate(billingTempalte: template, companyId: companyId)
            tempalteCount = tempalteCount + 1
        }
        print("Finished upLoading Generic Billing Templates")
    }
    func uploadSingleTraining(training : Training,companyId: String,techId:String) async throws {
        
        try TrainingDocument(trainingId: training.id, companyId: companyId, techId: techId).setData(from:training, merge: false)
    }
    func uploadSingleTrainingTemplate(trainingTemplate : TrainingTemplate,companyId: String) async throws {
        
        try TrainingTemplateDocument(trainingTemplateId: trainingTemplate.id, companyId: companyId).setData(from:trainingTemplate, merge: false)
    }
    func uploadGenericTraingTempaltes(companyId: String,templateList:[TrainingTemplate]) async throws{
            //        let genericTemplateList:[TrainingTemplate] = [
            //            TrainingTemplate(id: UUID().uuidString, name: "Pool Cleaning", description: "", workOrderIds: ["FUCK"]),
            //            TrainingTemplate(id: UUID().uuidString, name: "Filter Cleaning", description: "", workOrderIds: ["FUCK"]),
            //            TrainingTemplate(id: UUID().uuidString, name: "Filter Repair / Install", description: "", workOrderIds: ["FUCK"]),
            //            TrainingTemplate(id: UUID().uuidString, name: "Pump Repair / Install", description: "", workOrderIds: ["FUCK"]),
            //            TrainingTemplate(id: UUID().uuidString, name: "Heater Repair / Install", description: "", workOrderIds: ["FUCK"]),
            //
            //        ]
        for tempalte in templateList {
            try TrainingTemplateDocument(trainingTemplateId: tempalte.id, companyId: companyId).setData(from:tempalte, merge: false)
        }
        print("Successfully uploaded Generic Templates")
        
    }
    func uploadInvite(invite : Invite) async throws {
        try inviteDoc(inviteId: invite.id)
            .setData(from:invite, merge: true)
    }
    func uploadReadingToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    func uploadDosagesToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToServiceStop(serviceStopId: serviceStop.id, stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
    }
    
    func uploadReadingAndDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) throws {
        print("Attempting to Upload Reading and Dosages List")
        let itemRef = readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId)
        itemRef.setData([
            "id": stopData.id,
            "date": stopData.date,
            "serviceStopId": stopData.serviceStopId,
            "bodyOfWaterId": stopData.bodyOfWaterId,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Uploaded Reading and Dosages List Info Successfully")
            }
        }
        var readingData:[String:Any] = [:]
        var dosageData:[String:Any] = [:]
            //Attempting to append each reading to the reading array in firestore .In side of Stop Data in the specific Customer Document
        if stopData.readings.isEmpty {
            readingData = [
                "readings": [[
                    "id": "",
                    "templateId": "",
                    "dosageType": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "bodyOfWaterId": "",
                    
                ]]
                
            ]
            itemRef.updateData(readingData) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Uploaded Empty Reading List Successfully")
                }
            }
        }else {
            for reading in stopData.readings {
                print("Attempt To Upload Reading for \(reading.id)")
                
                readingData = [
                    "readings": FieldValue.arrayUnion([
                        [
                            "id": reading.id,
                            "templateId": reading.templateId,
                            "dosageType": reading.dosageType,
                            "name": reading.name,
                            "amount": reading.amount,
                            "UOM": reading.UOM,
                            "bodyOfWaterId": reading.bodyOfWaterId,
                        ]])
                ]
                itemRef.updateData(readingData) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Uploaded Reading \(String(describing: reading.name)) to List Successfully")
                    }
                }
            }
        }
            //Attempting to append each reading to the reading array in firestore. In side of Stop Data in the specific Customer Document
        
        if stopData.dosages.isEmpty {
            dosageData = [
                "dosages": [[
                    "id": "",
                    "templateId": "",
                    "name": "",
                    "amount": "",
                    "UOM": "",
                    "rate": "",
                    "linkedItem": "",
                    "bodyOfWaterId": "",
                ]]
                
            ]
            itemRef.updateData(dosageData) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Uploaded Empty Dosage List Successfully")
                }
            }
        } else {
            for dosage in stopData.dosages {
                print("Attempt To Upload Dosage for \(dosage.id)")
                
                dosageData = [
                    "dosages": FieldValue.arrayUnion([[
                        "id": dosage.id,
                        "templateId": dosage.templateId,
                        "name": dosage.name,
                        "amount": dosage.amount,
                        "UOM": dosage.UOM,
                        "rate": dosage.rate,
                        "linkedItem": dosage.linkedItem,
                        
                        "bodyOfWaterId": dosage.bodyOfWaterId,
                    ]])
                ]
                
                itemRef.updateData(dosageData) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Uploaded Dosage \(String(describing: dosage.name)) to List Successfully")
                    }
                }
            }
        }
        
    }
    func uploadReadingToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
        print("Uploaded Reading List")
        
    }
    func uploadDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws {
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: true)
        print("Uploaded Dosage List")
    }
    func addStopHistory(serviceStop:ServiceStop,stopData:StopData,companyId:String) async throws{
        print("breaks here")
        try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
        
    }
    func uploadRecurringServiceStop(companyId:String,recurringServiceStop : RecurringServiceStop) async throws {
        
        try recurringServiceStopDocument(recurringServiceStopId: recurringServiceStop.id,companyId: companyId).setData(from:recurringServiceStop, merge: true)
    }
    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop,
                                    standardFrequencyNumber:Int,
                                    customFrequencyType:String,
                                    CustomFrequency:String,
                                    daysOfWeek:[String]) async throws{
        
    }
    
    func uploadDataBaseItem(companyId:String,dataBaseItem : DataBaseItem) async throws {
        
        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
    }
    func uploadDataBaseItemWithUser(dataBaseItem : DataBaseItem,companyId:String) async throws {
        
        try DataBaseDocument(dataBaseId: dataBaseItem.id,companyId: companyId).setData(from:dataBaseItem, merge: false)
    }
    func uploadCSVDataBaseItemToFireStore(companyId:String,CSVItem: CSVDataBaseItem,storeId:String,storeName:String) async throws{
        let identification:String = UUID().uuidString
        var boolToken:Bool = true
        if CSVItem.billable == "NB" {
            boolToken = false
        } else if CSVItem.billable == "B" {
            boolToken = true
        } else {
            boolToken = true
        }
        
            //DEVELOPER FIX
            //        let DBItem:DataBaseItem = DataBaseItem(id: identification, name: CSVItem.name, rate: Double(CSVItem.rate) ?? 12.34, storeName: storeName, venderId:storeId, category: CSVItem.category, description: CSVItem.description, dateUpdated: Date(), sku: CSVItem.sku, billable: boolToken,color: CSVItem.color,size: CSVItem.size)
            //        print(DBItem)
            //        try await DatabaseManager.shared.uploadDataBaseItemWithUser(dataBaseItem: DBItem,companyId: companyId)
        
    }
    func uploadReceipt(companyId: String,receiptItem : Receipt) async throws {
        return try ReceiptItemDocument(receiptItemId: receiptItem.id, companyId: companyId).setData(from:receiptItem, merge: false)
    }
    
    func uploadRoute(companyId:String,recurringRoute:RecurringRoute) async throws {
        print("Upload Route >> \(recurringRoute.id)")
        try recurringRouteCollection(companyId: companyId).document(recurringRoute.id).setData(from:recurringRoute, merge: false)
    }
    
    
    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop,
                                    customFrequencyType:String,
                                    CustomFrequency:String,
                                    daysOfWeek:[String]) async throws ->(String?){
        return ""
        
    }
    
    func helpCreateDailyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                       noEndDate:Bool,startDate:Date,endDate:Date) async throws{}
        //WeekDay
    func helpCreateWeekDayRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async throws{}
        //Weeekly
    func helpCreateWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        noEndDate:Bool,startDate:Date,endDate:Date) async throws{}
        //Bi Weekly
    
    func helpCreateBiWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                          noEndDate:Bool,startDate:Date,endDate:Date) async  throws{}
        //Monthly
    
    func helpCreateMonthlyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async  throws{}
    
        //Custom
    func helpCreateCustomRecurringRoute(companyId: String, recurringServiceStop: RecurringServiceStop, standardFrequencyNumber: Int, customFrequencyType: String, CustomFrequency: String, daysOfWeek: [String]) {
        
    }
    
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws {
        try workOrderDocument(workOrderId: workOrder.id, companyId: companyId).setData(from:workOrder, merge: false)
    }
    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
            //DEVELOPER REMOVE THIS FUNCTION
    }
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws {
        
        let wo = try await workOrderDocument(workOrderId: workOrder.id, companyId: companyId).getDocument(as: Job.self)
            //
            //        let itemRef = workOrderDocument(workOrderId: workOrder.id, companyId: user.companyId)
            //
            //        var auxiliaryParts = wo.pvcParts
            //        print(auxiliaryParts)
            //        for id in ids {
            //            if wo.auxiliaryParts.contains(id) {
            //
            //            } else {
            //                auxiliaryParts.append(id)
            //            }
            //        }
            //        print(auxiliaryParts)
            //
            //        itemRef.updateData([
            //            "auxiliaryParts":auxiliaryParts
            //        ]) { err in
            //            if let err = err {
            //                print("Error updating document: \(err)")
            //            } else {
            //                print("Document successfully updated")
            //            }
            //        }
    }
    func uploadStopData(companyId:String,stopData:StopData) throws {
        try stopDataDocument(companyId: companyId,stopDataId: stopData.id)
            .setData(from:stopData, merge: true)
        
    }
    func uploadContact(companyId:String,contract:RecurringContract) async throws {
        
        try contractCollection(companyId: companyId).document(contract.id).setData(from:contract, merge: false)
    }
    
    
    
    
    
    
        //----------------------------------------------------
        //                    Read Functions
        //----------------------------------------------------
    
    func getAllCompanyToDoItems(companyId:String) -> [ToDo]{
        return [
            ToDo(id: "1", title: "Check Harold Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "2", title: "Check hey Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "3", title: "Check yum Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: ""),
            ToDo(id: "4", title: "Check the Dude Rice", status: .toDo, description: "Do some stuff", dateCreated: Date(), dateFinished: Date(), assignedTechId: "", creatorId: "")
        ]
        
    }
    func getAllCompanyToDoItemsCount(companyId: String) -> Int {
        return 8
    }
    
    func getAllTechnicanToDoItemsCount(companyId: String, techId: String) async throws -> Int {
        
        let query = ToDoCollection(companyId: companyId).whereField("assignedTechId", isEqualTo: techId).whereField("status", isNotEqualTo: "Finished")
        let countQuery = query.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return snapshot.count as! Int
        } catch {
            print(error)
            return 0
        }
    }
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]{
        return try await ToDoCollection(companyId: companyId)
            .whereField("assignedTechId", isEqualTo: techId)
            .getDocuments(as:ToDo.self)
        
    }
    func getCurrentUser(userId:String) async throws -> DBUser{
            //        let DBUser = try await DBUserManager.shared.loadCurrentUser()
        
        return try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    
    func getRecentActivityByUser(userId:String) async throws -> [RecentActivityModel]{
        return try await userRecentActivityCollection(userId: userId)
            .order(by: "date", descending: true)
            .limit(to: 8)
            .getDocuments(as:RecentActivityModel.self)
        
    }
    func getOneUser(userId:String) async throws -> DBUser{
        try await userDocument(userId: userId).getDocument(as: DBUser.self,decoder: decoder)
            //        try await userDocument(userId: userId).getDocument(as: DBUser.self)
        
    }
        //for some reason this does not work
    func getAllTechs() async throws ->[DBUser]{
        print("Get all techs")
        
        let techList = try await userCollection()
            .getDocuments(as:DBUser.self)
        print(techList)
        return techList
    }
    func getAllCompayTechs(companyId:String) async throws ->[DBUser]{
        return try await userCollection()
            .getDocuments(as:DBUser.self)
    }
    func getCurrentTechs(id:String) async throws ->[DBUser]{
        
        return try await userCollection()
            .whereField("position", isEqualTo: "Owner")
            .whereField("id", isEqualTo: id)
            .getDocuments(as:DBUser.self)
    }
    func checkUserAccessBy(userId:String,companyId:String) async throws{
        
    }
    
    func getAllUserAvailableCompanies(userId:String) async throws ->[UserAccess]{
        print("Attempting to get User Access \(userId) - Page: UserAccessManager - Func: getAllUserAvailableCompanies")
        return try await userAccessCollection(userId: userId)
            .getDocuments(as:UserAccess.self) // DEVELOPER FIX LATER, BUT FOR NOW I WANNA TEST WHAT IT LOOKS LIKE WITH OUT HAVING A COMPANY
                                              //        return []
    }
    func getUserAccessCompanies(userId:String,companyId:String) async throws ->UserAccess{
        return try await userDocument(userId: userId, accessId: companyId).getDocument(as: UserAccess.self)
    }
    func getCompanyUserById(companyId:String,companyUserId:String) async throws -> CompanyUser{
        return try await companyUserDoc(companyId: companyId, companyUserId: companyUserId)
            .getDocument(as:CompanyUser.self)
    }
    
    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws -> CompanyUser{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments(as:CompanyUser.self).first! // DEVELOPER PROPPERLY UNWRAP
        
    }
    func getAllRateSheetByCompanyUserId(companyId: String, companyUserId: String) async throws -> [RateSheet]{
        return try await companyUsersRateSheetCollection(companyId: companyId,companyUserId: companyUserId)
            .getDocuments(as:RateSheet.self)
    }
    func getAllCompanyUsers(companyId:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .getDocuments(as:CompanyUser.self)
    }
    func getAllCompanyUsersByStatus(companyId:String,status:String) async throws -> [CompanyUser]{
        return try await companyUsersCollection(companyId: companyId)
            .whereField("status", isEqualTo: status)
            .getDocuments(as:CompanyUser.self)
    }
    func getNumberOfItemsPurchasedIn30Days(companyId: String) async throws->(total:Double,totalBillable:Double,Invoiced:Double,TotalSpent:Double,totalSoldInDollars:Double,TotalSpentBillable:Double,TotalBilled:Double,NonBillableList:[PurchasedItem]){
        
        let calendar = Calendar(identifier: .gregorian)
        let endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        
        let nonBillableList = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: false)
            .getDocuments(as:PurchasedItem.self)
        let list = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: true)
            .getDocuments(as:PurchasedItem.self)
        var countOfInvoiced:Double = 0
        var countOfTotalBillable:Double = 0
        var costOfTotal:Double = 0
        var counterOfTotalBilled:Double = 0
        var totalProfitDolalrsOfBillable:Double = 0
        
        
        for item in list {
            if item.invoiced{
                countOfInvoiced = countOfInvoiced + 1
                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
            }
            totalProfitDolalrsOfBillable = (item.billingRate ?? 0) + totalProfitDolalrsOfBillable
            countOfTotalBillable = item.totalAfterTax + countOfTotalBillable
        }
        
        for item in nonBillableList {
            if item.invoiced{
                countOfInvoiced = countOfInvoiced + 1
                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
            }
            costOfTotal = item.totalAfterTax + costOfTotal
        }
        let twoLists = list.count + nonBillableList.count
        let totalBillabledAndNonBillable = countOfTotalBillable + costOfTotal
        let twoItemList = nonBillableList + list
        var total:Double = 0
        var i = 30
        while i > 1 {
            var billableCount:Double = 0
            var nonbillableCount:Double = 0
            let adding = i * -1
            let initalDate = Calendar.current.date(byAdding: .day, value: adding, to: Date())!
            let startDate = initalDate.startOfDay()
            let endDate = initalDate.endOfDay()
            for item in twoItemList {
                if item.billable == false {
                    
                    if item.date > startDate && item.date < endDate {
                        nonbillableCount = nonbillableCount + item.totalAfterTax
                    }
                }
                if item.billable == true {
                    if item.date > startDate && item.date < endDate {
                        billableCount = billableCount + item.totalAfterTax
                    }
                }
            }
            let both = billableCount + nonbillableCount
            total = total + both
            
            i = i - 1
        }
        
        return (total:Double(twoLists),
                totalBillable:Double(list.count),
                Invoiced:countOfInvoiced,
                TotalSpent:totalBillabledAndNonBillable,
                totalSoldInDollars:totalProfitDolalrsOfBillable,
                TotalSpentBillable:countOfTotalBillable,
                TotalBilled:counterOfTotalBilled,
                NonBillableList:nonBillableList)
    }
    
    
        //    func getNumberOfItemsPurchasedIn30DaysPrior(companyId: String) async throws->(total:Double,totalBillable:Double,Invoiced:Double,TotalSpent:Double,totalSoldInDollars:Double,TotalSpentBillable:Double,TotalBilled:Double,NonBillableList:[PurchasedItem],purchasedItemsChart:[customerChartSeriesData]){
        //
        //        let calendar = Calendar(identifier: .gregorian)
        //        var purchasedItemsChart:[customerChartSeriesData] = []
        //        var endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        //        endDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        //
        //        let startDate = calendar.date(byAdding: .month, value: -2, to: endDate)!
        //        let nonBillableList = try await ReceiptItemCollection(companyId: user.companyId)
        //            .whereField("date", isGreaterThan: startDate)
        //            .whereField("date", isLessThan: endDate)
        //            .whereField("billable", isEqualTo: false)
        //            .getDocuments(as:PurchasedItem.self)
        //
        //        let list = try await ReceiptItemCollection(companyId: user.companyId)
        //            .whereField("date", isGreaterThan: startDate)
        //            .whereField("date", isLessThan: endDate)
        //            .whereField("billable", isEqualTo: true)
        //            .getDocuments(as:PurchasedItem.self)
        //        var countOfInvoiced:Double = 0
        //        var countOfTotalBillable:Double = 0
        //        var costOfTotal:Double = 0
        //        var counterOfTotalBilled:Double = 0
        //        var totalProfitDolalrsOfBillable:Double = 0
        //
        //
        //        for item in list {
        //            if item.invoiced{
        //                countOfInvoiced = countOfInvoiced + 1
        //                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
        //            }
        //            totalProfitDolalrsOfBillable = (item.billingRate ?? 0) + totalProfitDolalrsOfBillable
        //            countOfTotalBillable = item.totalAfterTax + countOfTotalBillable
        //        }
        //
        //        for item in nonBillableList {
        //            if item.invoiced{
        //                countOfInvoiced = countOfInvoiced + 1
        //                counterOfTotalBilled = counterOfTotalBilled + item.totalAfterTax
        //            }
        //            costOfTotal = item.totalAfterTax + costOfTotal
        //        }
        //        let twoLists = list.count + nonBillableList.count
        //        let totalBillabledAndNonBillable = countOfTotalBillable + costOfTotal
        //        let twoItemList = nonBillableList + list
        //
        //        var billableChartList:[customerDateSummary] = []
        //        var nonBillableChartList:[customerDateSummary] = []
        //        var totalChartList:[customerDateSummary] = []
        //        var bothChartList:[customerDateSummary] = []
        //
        //        var total:Double = 0
        //        var i = 30
        //        while i > 1 {
        //            var billableCount:Double = 0
        //            var nonbillableCount:Double = 0
        //            let adding = i * -1
        //            let initalDate = Calendar.current.date(byAdding: .day, value: adding, to:endDate)!
        //            let startDate = initalDate.startOfDay()
        //            let endDate = initalDate.endOfDay()
        //            for item in twoItemList {
        //                if item.billable == false {
        //
        //                    if item.date > startDate && item.date < endDate {
        //                        nonbillableCount = nonbillableCount + item.totalAfterTax
        //                    }
        //                }
        //                if item.billable == true {
        //                    if item.date > startDate && item.date < endDate {
        //                        billableCount = billableCount + item.totalAfterTax
        //                    }
        //                }
        //            }
        //            let both = billableCount + nonbillableCount
        //            total = total + both
        //            billableChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: billableCount))
        //            nonBillableChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: nonbillableCount))
        //            totalChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: total))
        //            bothChartList.append(customerDateSummary(id: UUID().uuidString, date: initalDate, amount: both))
        //
        //            i = i - 1
        //        }
        //        purchasedItemsChart = [
        //            customerChartSeriesData(id:UUID().uuidString,type: "Both", data: bothChartList),
        //            customerChartSeriesData(id:UUID().uuidString,type: "Billable", data: billableChartList),
        //            customerChartSeriesData(id:UUID().uuidString,type: "Non Billable", data: nonBillableChartList),
        //            customerChartSeriesData(id:UUID().uuidString,type: "Total", data: totalChartList)
        //        ]
        //        return (total:Double(twoLists),
        //                totalBillable:Double(list.count),
        //                Invoiced:countOfInvoiced,
        //                TotalSpent:totalBillabledAndNonBillable,
        //                totalSoldInDollars:totalProfitDolalrsOfBillable,
        //                TotalSpentBillable:countOfTotalBillable,
        //                TotalBilled:counterOfTotalBilled,
        //                NonBillableList:nonBillableList,
        //                purchasedItemsChart:purchasedItemsChart)
        //    }
    func getNumberOfItemsPurchasedAndBilledIn30Days(companyId: String) async throws -> Double{
        let calendar = Calendar(identifier: .gregorian)
        
        let endDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        
        let query = PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: true)
            .whereField("invoiced", isEqualTo: true)
        
        let countQuery = query.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return Double(truncating: snapshot.count)
            
        } catch {
            print(error)
            return 0
        }
    }
    func getPurchasesCountForTechId(companyId:String,userId:String) async throws ->Int {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        
        let count = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("techId", isEqualTo: userId)
            .whereField("billable", isEqualTo: true)
            .whereField("invoiced", isEqualTo: false)
            .whereField("customerId", isEqualTo: "")
            .count.getAggregation(source: .server).count
        return count as! Int
        
    }
    func GetPurchasesByDateSortByDate(companyId: String,start:Date,end:Date,dateHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .order(by: "date",descending: dateHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByDateSortByPrice(companyId: String,start:Date,end:Date,priceHigh:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: start)
            .whereField("date", isLessThan: end)
            .order(by: "price",descending: priceHigh)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillable(companyId: String,billable:Bool) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .limit(to: 100)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoiced(companyId: String,billable:Bool,invoiced:Bool) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .limit(to: 100)
        
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool, price:Bool, techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "price",descending: price)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool,invoiced:Bool,price:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .order(by: "date",descending: true)
            .order(by: "price",descending: price)
            .whereField("techId", in: techIds)
        
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndSortByDate(companyId: String, start: Date, end: Date,billable:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: String, start:Date, end:Date, billable:Bool,invoiced:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: billable)
            .whereField("invoiced", isEqualTo: invoiced)
            .order(by: "date",descending: date)
            .whereField("techId", in: techIds)
            .getDocuments(as:PurchasedItem.self)
    }
    func getSingleItem(itemId:String,companyId: String) async throws -> PurchasedItem{
        return try await PurchaseItemDocument(purchaseItemId: itemId, companyId: companyId).getDocument(as: PurchasedItem.self)
    }
    
    func getItemsBasedOnDBItem(companyId: String,DataBaseItemSku:String) async throws -> [PurchasedItem] {
        let calendar = Calendar.current
        let previousMonth = calendar.date(byAdding: .month, value: -30, to: Date())!
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: previousMonth)
            .whereField("date", isLessThan: Date())
            .whereField("sku", isEqualTo: DataBaseItemSku)
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getallReceiptsLast30Days(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date", descending: true)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            //            .limit(to: 30)
            //            .order(by: "invoiceNum")
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getallReceiptsLast30DaysBillable(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date", descending: true)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: viewBillable)
            //            .limit(to: 30)
            //            .order(by: "invoiceNum")
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllBillableReceipts(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem] {
        let snapshot = try await PurchaseItemCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .whereField("billable", isEqualTo: viewBillable)
            .getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllReceiptItems(companyId: String) async throws -> [PurchasedItem] {
        
        let snapshot = try await PurchaseItemCollection(companyId: companyId).getDocuments()
        
        var receiptItems: [PurchasedItem] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: PurchasedItem.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    
    func getAllpurchasedItemsByTech(companyId: String,techId: String) async throws -> [PurchasedItem]{
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllpurchasedItemsByVender(companyId: String,venderId:String) async throws -> [PurchasedItem]{
        
        return try await PurchaseItemCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllpurchasedItemsByTechAndDate(companyId: String,techId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem]{
        
        return []
        
    }
    func getAllpurchasedItemsByDate(companyId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem] {
        return []
    }
    func getMostRecentPurchases(companyId:String,number:Int) async throws ->[PurchasedItem] {
        return try await PurchaseItemCollection(companyId: companyId)
            .order(by: "date",descending: true)
            .limit(to:number)
            .getDocuments(as:PurchasedItem.self)
    }
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws -> [CustomerMonthlySummary] {
        
        return  try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .limit(to: 25)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("date", isGreaterThan: month.previousMonth().endOfMonth())
            .whereField("serviceLocationId", isEqualTo: serviceLocationId)
            .limit(to: 1)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
    }
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary] {
        
        return try await Firestore.firestore().collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .whereField("date", isGreaterThan: month.previousYear().previousMonth().endOfMonth())
            .limit(to: 12)
            .whereField("date", isLessThan: month.endOfMonth())
            .getDocuments(as:CustomerMonthlySummary.self)
        
        
    }
    func checkCustomerCount(companyId:String) async throws -> Int{
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: true)
            .count.getAggregation(source: .server).count as! Int
    }
    func GetCustomersByHireDate(companyId:String,DurationHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: DurationHigh)
            .getDocuments(as:Customer.self)
    }
    
    func GetCustomersByLastName(companyId:String,LastNameHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.lastName.rawValue,descending: LastNameHigh)
            .getDocuments(as:Customer.self)
    }
    
    func GetCustomersByFirstName(companyId:String,FirstNameHigh:Bool) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.firstName.rawValue,descending: FirstNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActive(companyId:String,active : Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: false)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndHireDate(companyId:String,active : Bool,hireDateHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: hireDateHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndFirstName(companyId:String,active : Bool,firstNameHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.firstName.rawValue,descending: firstNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomersActiveAndLastName(companyId:String,active : Bool,lastNameHigh:Bool) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: active)
            .order(by: Customer.CodingKeys.lastName.rawValue,descending: lastNameHigh)
            .getDocuments(as:Customer.self)
    }
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer {
        return try await customerDocument(customerId: customerId,companyId: companyId)
            .getDocument(as: Customer.self)
    }
    func getAllCustomers(companyId:String) async throws -> [Customer] {
        
        let snapshot = try await customerCollection(companyId: companyId).getDocuments()
        
        var customers: [Customer] = []
        
        for document in snapshot.documents{
            let customer = try document.data(as: Customer.self)
            customers.append(customer)
        }
        return customers
    }
    func getAllActiveCustomers(companyId:String) async throws -> [Customer] {
        return try await customerCollection(companyId: companyId)
            .whereField(Customer.CodingKeys.active.rawValue, isEqualTo: true)
            .getDocuments(as:Customer.self)
    }
    func searchForCustomers(companyId:String,searchTerm:String) async throws -> [Customer]{
        var customerList:[Customer] = []
        
        
        let customerListFirstName =  try await customerCollection(companyId: companyId)
            .limit(to:5)
            .whereField(Customer.CodingKeys.firstName.rawValue, isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:Customer.self)
        
        let customerListByLastName =  try await customerCollection(companyId: companyId)
            .limit(to:5)
            .whereField(Customer.CodingKeys.lastName.rawValue, isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:Customer.self)
        customerList = customerListFirstName + customerListByLastName
        let uniqueList = Array(Set(customerList))
        
        print(uniqueList)
        return uniqueList
        
        
    }
    
    
    
    func getAllCustomersFilteredByRate(companyId:String,descending: Bool) async throws -> [Customer]{
        let user = try await DBUserManager.shared.loadCurrentUser()
        
        return try await customerCollection(companyId: companyId)
            .order(by: "rate", descending: descending).getDocuments(as:Customer.self)
        
    }
    func get25Customers(companyId:String) async throws -> [Customer]{
        
        return try await customerCollection(companyId: companyId)
            .limit(to:25)
            .getDocuments(as:Customer.self)
        
    }
    func getNext25Customers(companyId:String,lastDocument:DocumentSnapshot?) async throws -> (customers: [Customer],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            return try await customerCollection(companyId: companyId)
                .order(by: Customer.CodingKeys.lastName.rawValue,descending: false)
                .limit(to:25)
                .start(afterDocument: lastDocument)
                .getCustomerDocumentsWithSnapshot(as:Customer.self)
        } else {
            return try await customerCollection(companyId: companyId)
                .order(by: Customer.CodingKeys.lastName.rawValue,descending: false)
                .limit(to:25)
                .getCustomerDocumentsWithSnapshot(as:Customer.self)
        }
        
    }
    func getMostRecentCustomers(companyId:String,number:Int) async throws ->[Customer] {
        return try await customerCollection(companyId: companyId)
            .order(by: Customer.CodingKeys.hireDate.rawValue,descending: true)
            .limit(to:number)
            .getDocuments(as:Customer.self)
    }
    func getAllCompanyServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return try await serviceLocationCollection(companyId:companyId)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func getAllCustomerServiceLocations(companyId:String) async throws -> [ServiceLocation] {
        
        return try await serviceLocationCollection(companyId:companyId)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func get4CustomerServiceLocations(companyId:String,customer:Customer) async throws -> [ServiceLocation] {
        
        return  try await serviceLocationCollection(companyId:companyId)
            .limit(to: 4)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func getAllCustomerServiceLocationsId(companyId:String,customerId:String) async throws -> [ServiceLocation] {
        
        return  try await serviceLocationCollection(companyId: companyId)
            .whereField(ServiceLocation.CodingKeys.customerId.rawValue, isEqualTo: customerId)
            .getDocuments(as:ServiceLocation.self)
        
    }
    func getServiceLocationById(companyId:String,locationId:String) async throws -> ServiceLocation {
        return  try await serviceLocationDoc(companyId: companyId, serviceLocationId: locationId)
            .getDocument(as:ServiceLocation.self)
        
    }
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId:String,customerId:String,companyId:String) async throws -> [BodyOfWater] {
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print("collection")
        print(collection)
        return collection
    }
    func getAllBodiesOfWater(companyId:String) async throws -> [BodyOfWater] {
        
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws -> [BodyOfWater] {
        
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocation.id)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws -> [BodyOfWater] {
        print(serviceLocationId)
        let collection = try await bodyOfWaterCollection(companyId: companyId)
            .whereField(BodyOfWater.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments(as:BodyOfWater.self)
        print(collection)
        return collection
    }
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId:String) async throws -> Int {
        let collection =  bodyOfWaterCollection(companyId: companyId)
        let countQuery = collection.count
        do {
            let snapshot = try await countQuery.getAggregation(source: .server)
            print(snapshot.count)
            return Int(truncating: snapshot.count)
        } catch {
            print(error)
            return 0
        }
    }
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater{
        return try await bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId).getDocument(as:BodyOfWater.self)
    }
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            print(" - - - Has Old Doc")
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
            
        } else {
            print(" - - - Does Not have First Doc")
            
            let snap = try await equipmentCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:Equipment.self)
            return (equipmentList:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment] {
        return try await equipmentCollection(companyId: companyId)
            .limit(to: 10)
            .getDocuments(as:Equipment.self)
    }
    func getAllEquipment(companyId:String) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .getDocuments(as:Equipment.self)
    }
    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment] {
        
        return try await equipmentCollection(companyId: companyId)
            .whereField(Equipment.CodingKeys.bodyOfWaterId.rawValue, isEqualTo: bodyOfWater.id)
            .getDocuments(as:Equipment.self)
    }
    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment{
        
        return try await equipmentDoc(companyId: companyId,equipmentId: equipmentId).getDocument(as: Equipment.self)
            //            .getDocuments(as:Equipment.self)
    }
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]{
        
        return try await equipmentPartCollection(companyId: companyId, equipmentId: equipmentId)
            .getDocuments(as:EquipmentPart.self)
            //            .getDocuments(as:Equipment.self)
    }
    func getHistoryServiceStopsBy(companyId:String,serviceStop: ServiceStop) async throws -> [History]{
        
        return try await db.collection("companies/\(companyId)/serviceStops/\(serviceStop.id)/history")
            .getDocuments(as:History.self)
    }
    func getBillableServiceStopsByDate(startDate: Date,endDate:Date,companyId:String) async throws -> [ServiceStop]{
        let user = try await UserManager.shared.loadCurrentUser()
        
            //        let calendar = Calendar.current
            //        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
            //        let start = calendar.date(from: components)!
            //        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("finished", isEqualTo: true)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:ServiceStop.self)
    }
    
    func getServiceStopById(serviceStopId:String,companyId:String) async throws -> ServiceStop{
        try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).getDocument(as: ServiceStop.self)
        
    }
    func getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: String,recurringServiceStopId:String,date:Date) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.recurringServiceStopId.rawValue, isEqualTo: recurringServiceStopId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStops(companyId:String) async throws -> [ServiceStop] {
        let snapshot = try await serviceStopCollection(companyId: companyId).getDocuments()
        
        var serviceStops: [ServiceStop] = []
        
        for document in snapshot.documents{
            let serviceStop = try document.data(as: ServiceStop.self)
            serviceStops.append(serviceStop)
        }
        return serviceStops
    }
    func getAllServiceStopsByCustoer(companyId: String,customerId:String,startDate:Date,endDate:Date) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:ServiceStop.self)
    }
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:DBUser) async throws -> [ServiceStop]{
            //DEVELOPER WHY DOES THIS FUNCTION RUN TWICE
        print("Getting All Service Stops By Tech For \(tech.firstName ?? "") \(tech.lastName ?? "") and Day by \(fullDate(date: date))")
        let stops = try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .getDocuments(as:ServiceStop.self)
        print("Got \(stops.count) Stops Between \(dateAndTime(date: date.startOfDay())) and \(dateAndTime(date: date.endOfDay())) for \(tech.firstName) - \(tech.id)")
        return stops
    }
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ServiceStop] {
        return []
    }
    
    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .getDocuments(as:ServiceStop.self).count
        
    }
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .whereField(ServiceStop.CodingKeys.operationStatus.rawValue, isEqualTo: ServiceStopOperationStatus.finished.rawValue)
            .getDocuments(as:ServiceStop.self).count
        
    }
    func getAllServiceStopsSortedByRecurringServiceStops(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: recurringServiceStopId )
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsByRecurringServiceStopsAfterToday(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: recurringServiceStopId )
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsSortedByPrice(companyId:String,descending: Bool) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .order(by: "rate", descending: descending).getDocuments(as:ServiceStop.self)
        
    }
        //    func getAllServiceStopsByDateAndTech(date: Date,user:DBUser,companyUser:CompanyUser) async throws -> [ServiceStop]{
        //
        //        let calendar = Calendar.current
        //        let components = calendar.dateComponents([.year, .month, .day], from: date)
        //        let start = calendar.date(from: components)!
        //        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        //        let stops = try await serviceStopCollection(companyId: user.companyId)
        //            .whereField("serviceDate", isGreaterThan: start)
        //            .whereField("techId", isEqualTo: companyUser.id)
        //            .whereField("serviceDate", isLessThan: end)
        //            .getDocuments(as:ServiceStop.self)
        //
        //        return stops
        //    }
    func getAllServiceStopsByDate(companyId:String,date: Date) async throws -> [ServiceStop]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        print(start)
        print(end)
        let stops = try await serviceStopCollection(companyId:companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .getDocuments(as:ServiceStop.self)
        print("stops")
        print(stops)
        return stops
    }
    func getAllServiceStopsSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .order(by: "serviceDate", descending: descending)
            .limit(to:count)
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsBetweenDate(companyId:String,startDate: Date,endDate:Date) async throws -> [ServiceStop]{
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        
        let pushStartDate = makeDate(year: startComponents.year!, month: startComponents.month!, day: startComponents.day!, hr: 0, min: 0, sec: 0)
        let pushEndDate = makeDate(year: endComponents.year!, month: endComponents.month!, day: endComponents.day!, hr: 0, min: 0, sec: 0)
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: pushStartDate)
            .whereField("serviceDate", isLessThan: pushEndDate)
            .getDocuments(as:ServiceStop.self)
    }
    func getAllServiceStopsBetweenDateByUserId(companyId:String,startDate: Date,endDate:Date,userId:String) async throws -> [ServiceStop]{
        let calendar = Calendar.current
        
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: startDate.startOfDay())
            .whereField("serviceDate", isLessThan: endDate.endOfDay())
            .whereField("techId", isEqualTo: userId)
            .getDocuments(as:ServiceStop.self)
    }
    func getServiceStopsByRecurringsServiceStop(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]{
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: Date())
            .whereField("recurringServiceStopId", isEqualTo: recurringsServicestop.id)
            .getDocuments(as:ServiceStop.self)
    }
    func getServiceStopsByRecurringsServiceStopBetweenDates(companyId:String,recurringsServicestopId:String,startDate: Date, endDate: Date) async throws -> [ServiceStop]{

        return []
    }
    func getServiceStopsByRecurringsServiceStopNotFinished(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]{
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: Date())
            .whereField("recurringServiceStopId", isEqualTo: recurringsServicestop.id)
            .whereField("finished", isEqualTo: false)
        
            .getDocuments(as:ServiceStop.self)
    }
    func getUnfinishedServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]{
        
        return try await serviceStopCollection(companyId:companyId)
            .whereField("customerId", isEqualTo: customer.id)
            .whereField("finished", isEqualTo: false)
            .getDocuments(as:ServiceStop.self)
        
    }
    func getUnfinished4ServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]{
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customer.id)
            .whereField("finished", isEqualTo: false)
            .limit(to: 4)
            .getDocuments(as:ServiceStop.self)
        
    }
    
    func getServiceStopsBetweenDatesAndByCustomer(companyId:String,startDate: Date,endDate:Date,customer:Customer) async throws -> [ServiceStop]{
        let pushStartDate = startDate.previousMonth()
        let pushEndDate = endDate.endOfMonth()
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: pushStartDate)
            .whereField("customerId", isEqualTo: customer.id)
            .limit(to: 25)
            .whereField("serviceDate", isLessThan: pushEndDate)
            .getDocuments(as:ServiceStop.self)
        
    }
    
    func getServiceStopsBetweenDatesAndByType(companyId:String,startDate: Date,endDate:Date,workOrderType:String) async throws -> [ServiceStop]{
        let calendar = Calendar.current
        
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        
        let pushStartDate = makeDate(year: startComponents.year!, month: startComponents.month!, day: startComponents.day!, hr: 0, min: 0, sec: 0)
        
        let endDay = makeDate(year: endComponents.year!, month: endComponents.month!, day: endComponents.day!, hr: 0, min: 0, sec: 0)
        let pushEndDate = calendar.date(byAdding: .day, value: 1, to: endDay)!
        if workOrderType == "All" {
            return try await serviceStopCollection(companyId: companyId)
                .whereField("serviceDate", isGreaterThan: pushStartDate)
                .whereField("serviceDate", isLessThan: pushEndDate)
                .getDocuments(as:ServiceStop.self)
        } else {
            return try await serviceStopCollection(companyId: companyId)
                .whereField("serviceDate", isGreaterThan: pushStartDate)
                .whereField("serviceDate", isLessThan: pushEndDate)
                .whereField("type", isEqualTo: workOrderType)
                .getDocuments(as:ServiceStop.self)
        }
    }
    
    func getAllUnfinishedServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]{
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .whereField("finished", isEqualTo: true)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:ServiceStop.self)
    }
    func getAllServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:ServiceStop.self)
    }
    func getServiceStopBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[ServiceStop],lastDocument:DocumentSnapshot?) {
        
        if let lastDocument {
            return try await serviceStopCollection(companyId: companyId)
                //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as: ServiceStop.self)
        }else {
            return try await serviceStopCollection(companyId: companyId)
                //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .getDocumentsWithSnapshot(as: ServiceStop.self)
        }
    }
    func getAllCompanyRoles(companyId : String) async throws ->[Role] {
        return try await roleCollection(companyId: companyId)
            //            .whereField(Role.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            //            .whereField(Role.CodingKeys.status.rawValue, isEqualTo: "Pending")
            .getDocuments(as:Role.self)
    }
    
    func getSpecificRole(companyId:String,roleId : String) async throws ->Role {
        return try await roleDoc(companyId: companyId,roleId: roleId)
            .getDocument(as: Role.self)
        
    }
    func getAllCompanies() async throws -> [Company]{
        try await companyCollection()
            .getDocuments(as:Company.self)
    }
    
    func getCompany(companyId:String) async throws -> Company{
        try await CompanyDocument(companyId: companyId).getDocument(as: Company.self)
    }
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem {
        return try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).getDocument(as: ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsSnapShotByCompany(companyId:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByCompanyCustomer(companyId: String,customerId: String) async throws -> [ShoppingListItem]{
        return []
    }
    
    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int {
        return Int(try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .count.getAggregation(source: .server).count)
    }
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem] {
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: userId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
    }
    func getAllShoppingListItemsByUserForJob(companyId: String, jobId: String,category:String) async throws -> [ShoppingListItem]{
        return try await shoppingListCollection(companyId: companyId)
            .whereField("purchaserId", isEqualTo: jobId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:ShoppingListItem.self)
    }
    
    func getAllGenericDataBaseItems(companyId:String) async throws -> [GenericItem]{
        
        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)
        
    }
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [GenericItem]{
        return try await GenericItemCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .getDocuments(as:GenericItem.self)
        
    }
    func getDataBaseItem(companyId:String,genericItemId:String) async throws -> GenericItem{
        
        return try await GenericItemDocument(companyId: companyId, genericItemId: genericItemId).getDocument(as: GenericItem.self)
    }
    
    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem{
        
        let dbItem = try await Firestore.firestore().collection("workOrders/\(workOrderId)/installationParts").document(workOrderItemId).getDocument(as: WODBItem.self)
        
        return try await getDataBaseItem(companyId: companyId, genericItemId: dbItem.genericItemId)
    }
    func getAllStores(companyId:String) async throws -> [Vender]{
        return try await StoreCollection(companyId: companyId)
            .getDocuments(as:Vender.self)
        
    }
    func getSingleStore(companyId:String,storeId:String) async throws -> Vender{
        
        return try await StoreDocument(storeId: storeId, companyId: companyId).getDocument(as: Vender.self)
        
    }
    func getAllChatsByUser(userId:String) async throws -> [Chat] {
        return try await chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: true)
        
            .getDocuments(as:Chat.self)
    }
    func getSpecificChat(chatId:String) async throws ->Chat{
        
        return try await chatDocument(chatId: chatId)
            .getDocument(as: Chat.self)
            //            .getDocuments(as:Equipment.self)
    }
    func deleteCustomerContact(companyId:String,customerId:String,contactId:String)async throws {
        
    }
    func uploadCustomerContact(companyId:String,customerId:String,contact:Contact) async throws {
        
    }
    func getCustomerContactById(companyId:String,customerId : String,contactId:String) async throws -> Contact {
        return Contact(id: "", name: "", phoneNumber: "", email: "", notes: "")
    }
    func getAllContactsByCustomer(companyId:String,customerId:String) async throws -> [Contact] {
        return []
    }
    func getChatBySenderAndReceiver(companyId:String,senderId:String,receiverId:String) async throws ->Chat? {
        return try await chatDocument(chatId: receiverId)
            .getDocument(as: Chat.self)
    }
    func getChatsByCompany(companyId: String) async throws ->[Chat]{
        return try await chatCollection()
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments(as:Chat.self)
    }
    func getAllMessagesByChat(chatId: String) async throws ->[Message]{
        return try await messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: false)
            .limit(to: 10)
            .getDocuments(as:Message.self)
    }
    func getNewestMessage(chatId: String) async throws ->Message? {
        return try await messageCollection()
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "dateSent", descending: false)
            .limit(to: 1)
            .getDocuments(as:Message.self).first
    }
    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest] {
        
        return try await repairRequestCollection(companyId: companyId)
            .getDocuments(as:RepairRequest.self)
    }
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest{
        
        return try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId).getDocument(as: RepairRequest.self)
            //            .getDocuments(as:Equipment.self)
    }
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]{
        return try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RepairRequest.self)
    }
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        let count = try await repairRequestCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId).count.getAggregation(source: .server).count
        
        return count as! Int
    }
    func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?{
        let count = try await repairRequestCollection(companyId: companyId)
            .whereField("requesterId", isEqualTo: userId)
            .count.getAggregation(source: .server).count
        
        return count as! Int
    }
    func getAllContrats(companyId:String) async throws -> [RecurringContract] {
        
        return try await contractCollection(companyId: companyId)
            .getDocuments(as:RecurringContract.self)
    }
    func getSpecificContract(companyId:String,contractId:String) async throws ->RecurringContract{
        
        return try await contractDocument(companyId: companyId,contractId: contractId).getDocument(as: RecurringContract.self)
            //            .getDocuments(as:Equipment.self)
    }
    func getContractsByCustomer(companyId: String,customerId:String) async throws ->[RecurringContract]{
        return try await contractCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RecurringContract.self)
    }
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?{
        let count = try await contractCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId).count.getAggregation(source: .server).count
        
        return count as! Int
    }
    
    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]{
        print("Getting All Stop Data")
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .whereField("date", isLessThan: Date())
            .order(by: "date", descending: true)
            .limit(to: amount)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String)async throws->[StopData]{
        print("Getting Stop Data for \(serviceStopId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
        
            .order(by: "date", descending: true)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]{
        print("Getting Stop Data for >> \(serviceStopId) and Body Of Water >> \(bodyOfWaterId)")
        return try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getStopDataByDateRange(companyId:String,startDate: Date,endDate:Date)async throws->[StopData]{
        return try await stopDataCollection(companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: false)
            .getDocuments(as:StopData.self)
    }
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]{
            //        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await db.collection("workOrders/" + workOrder.id + "/history")
            .getDocuments(as:History.self)
    }
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]{
        
            //        let calendar = Calendar.current
            //        let components = calendar.dateComponents([.year, .month, .day], from: startDate)
            //        let start = calendar.date(from: components)!
            //        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("finished", isEqualTo: true)
            .whereField("serviceDate", isGreaterThan: startDate)
            .whereField("serviceDate", isLessThan: endDate)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrdersFinished(companyId: String,finished:Bool) async throws -> [Job] {
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "dateCreated", descending: true)
            .whereField("finished", isEqualTo: finished)
            .getDocuments(as:Job.self)
    }
    func getAllWorkOrders(companyId: String) async throws -> [Job] {
        
        let snapshot = try await workOrderCollection(companyId: companyId).getDocuments()
        
        var workOrders: [Job] = []
        
        for document in snapshot.documents{
            let workOrder = try document.data(as: Job.self)
            workOrders.append(workOrder)
        }
        return workOrders
    }
    func getAllJobsByCustomer(companyId: String,customerId:String) async throws -> [Job] {
        return []
    }
    func getAllJobsByUser(companyId: String,userId:String) async throws -> [Job] {
        return []
    }
    
    func getAllWorkOrdersSortedByPrice(companyId:String,descending: Bool) async throws -> [Job]{
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "rate", descending: descending)
            .getDocuments(as:Job.self)
        
    }
    func getAllWorkOrdersByDate(companyId:String,date: Date) async throws -> [Job]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .getDocuments(as:Job.self)
    }
    
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]{
        let workOrders = try await getAllWorkOrders(companyId: companyId)
        var workOrderList:[Job] = []
        for WO in workOrders {
            if WO.serviceStopIds.count == 0 {
                workOrderList.append(WO)
            }
        }
        return workOrderList
        
    }
    func getAllWorkOrdersSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [Job]{
        
        return try await workOrderCollection(companyId: companyId)
            .order(by: "serviceDate", descending: descending)
            .limit(to:count)
            .getDocuments(as:Job.self)
        
    }
    func getAllWorkOrdersByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [Job]{
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        return try await workOrderCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: start)
            .whereField("serviceDate", isLessThan: end)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as:Job.self)
    }
    func getWorkOrdersBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[Job],lastDocument:DocumentSnapshot?) {
        
        if let lastDocument {
            return try await workOrderCollection(companyId: companyId)
                //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as: Job.self)
        }else {
            return try await workOrderCollection(companyId: companyId)
                //                .order(by: ServiceStop.CodingKeys.rate.rawValue, descending: true)
                .limit(to: count)
                .getDocumentsWithSnapshot(as: Job.self)
        }
    }
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job {
        
        return try await workOrderDocument(workOrderId: workOrderId, companyId: companyId).getDocument(as: Job.self)
        
    }
    func getAllPastJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
    }
    
    func getAllFutureJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job] {
        return []
        
    }
    
    
    func getSingleRoute(companyId:String,recurringRouteId:String) async throws -> RecurringRoute {
        print("* getSingleRoute in RecurringRouteManager *")
        
        return try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId)
            .getDocument(as: RecurringRoute.self)
    }
    func getSingleRouteFromTechIdAndDay(companyId: String, techId: String, day: String) async throws -> RecurringRoute? {
        return try await reccuringRouteDoc(companyId: companyId, recurringRouteId: "1")
            .getDocument(as: RecurringRoute.self)
    }
    func getAllActiveRoutes(companyId:String,param:String) async throws -> [RecurringRoute] {
        
        return try await  recurringRouteCollection(companyId: companyId)
            .getDocuments(as: RecurringRoute.self)
            //            .getDocuments(as:Equipment.self)
    }
    
    func getAllActiveRoutesBasedOnDate(companyId:String,day:String,techId:String) async throws -> [RecurringRoute] {
        
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .whereField("techId", isEqualTo: techId)
            .getDocuments(as: RecurringRoute.self)
    }
    func getRecurringRouteByDayAndTech(companyId:String,day:String,techId:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("techId", isEqualTo: techId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
        
            //            .whereField(recurringRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
            //            .whereField(recurringRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            //            .whereField(recurringRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
    }
    func getRecurringRouteByDay(companyId:String,day:String) async throws ->[RecurringRoute] {
        return try await  recurringRouteCollection(companyId: companyId)
            .whereField("day", isEqualTo: day)
            .getDocuments(as: RecurringRoute.self)
        
            //            .whereField(recurringRoute.CodingKeys.date.rawValue, isGreaterThan: date.startOfDay())
            //            .whereField(recurringRoute.CodingKeys.date.rawValue, isLessThan: date.endOfDay())
            //            .whereField(recurringRoute.CodingKeys.techId.rawValue, isEqualTo: tech.id)
    }
    func getRecurringRouteByDayCount(companyId:String,day:String) async throws ->Int {
        return 9
    }
    
    func getAllReceipts(companyId: String) async throws -> [Receipt] {
        
        let snapshot = try await ReceiptItemCollection(companyId: companyId).getDocuments()
        
        var receiptItems: [Receipt] = []
        
        for document in snapshot.documents{
            let receiptItem = try document.data(as: Receipt.self)
            receiptItems.append(receiptItem)
        }
        return receiptItems
    }
    func getAllpurchasedItemsByPrice(companyId:String,descending: Bool) async throws -> [Receipt]{
        
        return try await ReceiptItemCollection(companyId: companyId)
            //            .order(by: "price", descending: descending)
            .getDocuments(as:Receipt.self)
        
    }
    
    func getAllDataBaseItemsByCategory(companyId:String,category:String) async throws -> [DataBaseItem]{
        
        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func get25DataBaseItems(companyId:String) async throws -> [DataBaseItem]{
        
        return try await DataBaseCollection(companyId: companyId)
            .limit(to:25)
            .getDocuments(as:DataBaseItem.self)
        
    }
    
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [DataBaseItem]{
        return try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func getItemsFromDataBaseBySearchTermAndStoreId(companyId:String,storeId:String,searchTerm:String) async throws -> [DataBaseItem]{
        var DatabaseItemList:[DataBaseItem] = []
        
        let DatabaseItemListByName =  try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .whereField("name", isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:DataBaseItem.self)
        print(DatabaseItemListByName)
        let DatabaseItemListBySKU =  try await DataBaseCollection(companyId: companyId)
            .limit(to:5)
            .whereField("storeId", isEqualTo: storeId)
            .whereField("sku", isGreaterThanOrEqualTo: searchTerm)
            .getDocuments(as:DataBaseItem.self)
        print(DatabaseItemListBySKU)
        
        DatabaseItemList = DatabaseItemListBySKU + DatabaseItemListByName
        let uniqueList = Array(Set(DatabaseItemList))
        
        print(uniqueList)
        return uniqueList
        
    }
    func getDataBaseItem(companyId:String,dataBaseItemId:String) async throws -> DataBaseItem{
        return try await DataBaseDocument(dataBaseId: dataBaseItemId, companyId: companyId).getDocument(as: DataBaseItem.self)
    }
    func getDataBaseItemsFromArrayOfIds(companyId:String,dataBaseIds:[String]) async throws -> [DataBaseItem]{
        var dataBaseItemList: [DataBaseItem] = []
        for id in dataBaseIds {
            try await dataBaseItemList.append(getDataBaseItem(companyId: companyId, dataBaseItemId: id))
        }
        return dataBaseItemList
    }
    func getallNonBillableTemplates(companyId:String) async throws -> [DataBaseItem]{
        
        return try await DataBaseCollection(companyId: companyId)
            .whereField("billable", isEqualTo: false)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func getDataBaseItemByCategory(companyId: String,category:String) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func getDataBaseItemByVender(companyId: String,venderId:String) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:DataBaseItem.self)
    }
    func getDataBaseItemByVenderItemTotal(companyId: String,venderId:String) async throws -> Int {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("venderId", isEqualTo: venderId)
            .getDocuments(as:DataBaseItem.self).count
    }
    func getDataBaseItemByCategoryAndSubCategory(companyId: String,category:String,subCategory:DataBaseSubCategories) async throws -> [DataBaseItem] {
        return try await DataBaseCollection(companyId: companyId)
            .whereField("category", isEqualTo: category)
            .whereField("subCategory", isEqualTo:subCategory.name)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func getAllDataBaseItems(companyId:String) async throws -> [DataBaseItem]{
        
        return try await DataBaseCollection(companyId: companyId)
            .getDocuments(as:DataBaseItem.self)
        
    }
    func getAllDataBaseItemsByName(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (dataBase:[DataBaseItem],lastDocument:DocumentSnapshot?){
        if let lastDocument {
            let snap = try await DataBaseCollection(companyId: companyId)
                .limit(to: count)
                .start(afterDocument: lastDocument)
                .getDocumentsWithSnapshot(as:DataBaseItem.self)
            return (dataBase:snap.serviceStops,lastDocument:snap.lastDocument)
            
        } else {
            let snap = try await DataBaseCollection(companyId: companyId)
                .limit(to: count)
                .getDocumentsWithSnapshot(as:DataBaseItem.self)
            return (dataBase:snap.serviceStops,lastDocument:snap.lastDocument)
        }
    }
    func getSingleRecurringServiceStop(companyId:String,recurringServiceStopId:String) async throws -> RecurringServiceStop {
        return try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId).getDocument(as:RecurringServiceStop.self)
    }
    func getAllRecurringServiceStop(companyId:String) async throws -> [RecurringServiceStop] {
        return try await recurringServiceStopCollection(companyId: companyId)
            .getDocuments(as:RecurringServiceStop.self)
    }
        //    func getRecurringServiceStopsByTechAndDay(user:DBUser,tech:CompanyUser,day:String) async throws -> [RecurringServiceStop] {
        //
        //        return try await recurringServiceStopCollection(companyId: user.companyId)
        //            .whereField("techId", isEqualTo: tech.id)
        //            .whereField("daysOfWeek", arrayContains: day)
        //            .getDocuments(as:RecurringServiceStop.self)
        //
        //    }
    func getReucrringServiceStopsWithOutEndDate(companyId:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField("noEndDate", isEqualTo: true)
            .getDocuments(as:RecurringServiceStop.self)
        
    }
    func getRecurringServiceStopsByDays(companyId:String,day:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.daysOfWeek.rawValue, arrayContains: day)
            .getDocuments(as:RecurringServiceStop.self)
    }
    
    func getRecurringServiceStopsByDayAndTech(companyId:String,techId:String,day:String) async throws -> [RecurringServiceStop] {
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .whereField(RecurringServiceStop.CodingKeys.daysOfWeek.rawValue, arrayContains: day)
            .whereField(RecurringServiceStop.CodingKeys.techId.rawValue, isEqualTo: techId)
        
            .getDocuments(as:RecurringServiceStop.self)
    }
    
    func getAllRecurringServiceStopByCustomerId(companyId:String,customerId:String) async throws -> [RecurringServiceStop]{
        
        return try await recurringServiceStopCollection(companyId: companyId)
            .limit(to:5)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments(as:RecurringServiceStop.self)
        
    }
    func readFourMostRecentStops(companyId:String,customer : Customer) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsById(companyId:String,customerId : String) async throws -> [StopData]{
        let user = try await UserManager.shared.loadCurrentUser()
        
        return try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func readFourMostRecentStopsByCustomerIdServiceLocationIdAndBodyOfWaterId(companyId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .order(by: "date", descending: true)
            .limit(to:4)
            .getDocuments(as:StopData.self)
        
    }
    func getStopDataFromServiceStop(companyId:String,serviceStopId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> StopData{
        print("Getting Stop Data From Service Stop")
        print("serviceStopId --> \(serviceStopId)")
        print("bodyOfWaterId --> \(bodyOfWaterId)")
        let stopData = try await readingCollectionForCustomerHistory(customerId: customerId, companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .whereField("bodyOfWaterId", isEqualTo: bodyOfWaterId)
            .getDocuments(as:StopData.self)
            //        return stopData.first!
        print(stopData.first!)
        return stopData.first ?? StopData(
            id: "",
            date: Date(),
            serviceStopId: "",
            readings: [],
            dosages: [],
            observation: [],
            bodyOfWaterId: "",
            customerId: "",
            serviceLocationId: "",
            userId: ""
        )
    }
    func readAllHistory(companyId:String,customer : Customer) async throws -> [StopData]{
        print("Trying to get data")
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .order(by: "date", descending: true)
            //            .limit(to: 5)
            .getDocuments(as:StopData.self)
        
    }
    
    func getHistoryByCustomerByDateRange(companyId:String,customer : Customer,startDate:Date,endDate:Date) async throws -> [StopData]{
        
        return try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
            .whereField("date", isGreaterThan: startDate)
            .whereField("date", isLessThan: endDate)
            .getDocuments(as:StopData.self)
        
    }
    func getAllCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, isEqualTo: "Pending")
            .getDocuments(as:Invite.self)
    }
    func getAllAcceptedCompanyInvites(comapnyId : String) async throws ->[Invite] {
        return try await inviteCollection()
            .whereField(Invite.CodingKeys.companyId.rawValue, isEqualTo: comapnyId)
            .whereField(Invite.CodingKeys.status.rawValue, isEqualTo: "Accepted")
            .getDocuments(as:Invite.self)
    }
    func getSpecificInvite(inviteId : String) async throws ->Invite {
        return try await inviteDoc(inviteId: inviteId)
            .getDocument(as: Invite.self)
        
    }
    func getAllTrainings(companyId: String,techId:String) async throws -> [Training]{
        let trainings = try await TrainingCollection(companyId: companyId, techId: techId)
            .getDocuments(as:Training.self)
        print("got all trainings for \(techId)")
        print(trainings)
        return trainings
    }
    func getSingleTraining(companyId: String,trainingId:String,techId:String) async throws -> Training{
        return try await TrainingDocument(trainingId: trainingId, companyId: companyId, techId: techId)
            .getDocument(as: Training.self)
    }
    func getAllTrainingTemplates(companyId: String) async throws -> [TrainingTemplate]{
        return try await TrainingTemplateCollection(companyId: companyId)
            .getDocuments(as:TrainingTemplate.self)
    }
    func getSingleTrainingTemplate(companyId: String,trainingTemplateId:String) async throws -> TrainingTemplate{
        return try await TrainingTemplateDocument(trainingTemplateId: trainingTemplateId, companyId: companyId)
            .getDocument(as: TrainingTemplate.self)
    }
    func getAllBillingTemplates(companyId:String) async throws -> [BillingTemplate]{
        
        return try await BillingTemplateCollection(companyId: companyId)
            .getDocuments(as:BillingTemplate.self)
    }
    func getDefaultBillingTempalte(companyId:String) async throws -> BillingTemplate{
        
        let templates = try await BillingTemplateCollection(companyId: companyId)
            .whereField("defaultSelected", isEqualTo: true)
            .getDocuments(as:BillingTemplate.self)
        return templates.first!
    }
        //start up functions
    
    func getStoreCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        SettingsCollection(companyId: companyId).document("serviceStops")
            .updateData([
                "increment": updatedServiceStopCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
            //        return 1
        
    }
    func getGenericItem(companyId:String,genericItemId:String) async throws -> GenericItem{
        return try await GenericItemDocument(genericItemId: genericItemId,companyId: companyId).getDocument(as: GenericItem.self)
    }
    func getGenericItems(companyId:String) async throws -> [GenericItem]{
        
        return try await GenericItemCollection(companyId: companyId)
            .getDocuments(as:GenericItem.self)
    }
    func getInvoiceCount(companyId:String) async throws-> Int {
        return 0
    }

    func getWorkOrderCount(companyId:String) async throws-> Int{
        
        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("workOrders").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
        SettingsCollection(companyId: companyId).document("workOrders")
            .updateData([
                "increment": updatedWorkOrderCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("Work Order Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount
        
    }
    func getRepairRequestCount(companyId:String) async throws-> Int{
        
        var workOrderCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("repairRequests").getDocument(as: Increment.self)
        workOrderCount = doc.increment
        let updatedWorkOrderCount = workOrderCount + 1
        SettingsCollection(companyId: companyId).document("repairRequests")
            .updateData([
                "increment": updatedWorkOrderCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("Repair Request Count " + String(updatedWorkOrderCount))
        return updatedWorkOrderCount
        
    }
    func getServiceOrderCount(companyId:String) async throws-> Int{
        var serviceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("serviceStops").getDocument(as: Increment.self)
        serviceStopCount = doc.increment
        let updatedServiceStopCount = serviceStopCount + 1
        SettingsCollection(companyId: companyId).document("serviceStops")
            .updateData([
                "increment": updatedServiceStopCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("Service Stop Count " + String(serviceStopCount))
        return updatedServiceStopCount
            //        return 1
        
    }
        //recurringServiceStop Settings
    func getRecurringServiceStopCount(companyId:String) async throws-> Int{
        
        var recurringServiceStopCount = 0
        let doc = try await SettingsCollection(companyId: companyId).document("recurringServiceStops").getDocument(as: Increment.self)
        recurringServiceStopCount = doc.increment
        sleep(1)
        let updatedRecurringServiceStopCount = recurringServiceStopCount + 1
        
        SettingsCollection(companyId: companyId).document("recurringServiceStops")
            .updateData([
                "increment": updatedRecurringServiceStopCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("recurringServiceStop Count " + String(updatedRecurringServiceStopCount))
        return updatedRecurringServiceStopCount
            //        return 2
        
    }
    func getAllWorkOrderTemplate(companyId:String,workOrderId:String) async throws -> JobTemplate{
        
        return try await WorkOrderDocument(workOrderTemplateId: workOrderId,companyId: companyId).getDocument(as: JobTemplate.self)
        
        
        
    }
    func getAllWorkOrderTemplates(companyId:String) async throws -> [JobTemplate]{
        
        return try await WorkOrderTemplateCollection(companyId: companyId)
            .getDocuments(as:JobTemplate.self)
        
    }
    func getWorkOrderEstimate(companyId:String) async throws -> [JobTemplate]{
        
        return try await WorkOrderTemplateCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: "Estimate" )
            .getDocuments(as:JobTemplate.self)
        
    }
    func getAllReadingTemplates(companyId:String) async throws -> [ReadingsTemplate]{
        
        return try await ReadingsCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:ReadingsTemplate.self)
    }
    func getAllDosageTemplates(companyId:String) async throws -> [DosageTemplate]{
        
        return try await DosageCollection(companyId: companyId)
            .order(by: "order", descending: false)
            .getDocuments(as:DosageTemplate.self)
    }
    func getAllServiceStopTemplates(companyId:String) async throws -> [ServiceStopTemplate]{
        
        return try await ServiceStopTemplateCollection(companyId: companyId)
            .getDocuments(as:ServiceStopTemplate.self)
    }
    
        //----------------------------------------------------
        //                    Update Functions
        //----------------------------------------------------
    func removingReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {
        
        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId, companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
        ])
    }
    func removingDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {
        
        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData([
            "amount":FieldValue.arrayRemove([amount])
        ])
    }
    func uploadDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws {
        
        try await  DosageTemplateDocument(dosageTemplateId: dosageTemplateId,companyId: companyId).updateData(
            ["amount":FieldValue.arrayUnion([amount])
            ])
    }
    func uploadReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws {
        
        try await  ReadingsTemplateDocument(readingTemplateId: readingTemplateId,companyId: companyId).updateData(["amount":FieldValue.arrayUnion([amount])
                                                                                                                  ])
    }
    func markInviteAsAccepted(invite:Invite) async throws {
        let itemRef = inviteDoc(inviteId: invite.id)
        
            // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            Invite.CodingKeys.status.rawValue:"Accepted"
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }    }
    func endRecurringServiceStop(companyId:String,recurringServiceStopId:String,endDate:Date) async throws {
            //DEVELOPER ADD LOGIC
        print("End Recurring Service Stop Logic")
        try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId)
            .updateData([
                "noEndDate": false,
                "endDate":endDate
            ])
    }
    func editDataBaseItem(companyId:String,dataBaseItemId:String,name:String,rate:Double,storeName:String,storeId:String,category:DataBaseItemCategory,subCategory:DataBaseItemSubCategory,description:String,sku:String,billable:Bool,color:String,size:String,UOM:UnitOfMeasurment) async throws {
        let dataBaseItem = DataBaseItem(
            id: dataBaseItemId,
            name: name,
            rate: rate,
            storeName: storeName,
            venderId: storeId,
            category: category,
            subCategory: subCategory,
            description: description,
            dateUpdated: Date(),
            sku: sku,
            billable: billable,
            color: color,
            size: size,
            UOM:UOM
        )
        try DataBaseDocument(dataBaseId: dataBaseItemId,companyId: companyId).setData(from:dataBaseItem, merge: true)
    }
    func updateDataBaseItem(
        dataBaseItem:DataBaseItem,
        companyId: String,
        name:String,
        rate:Double,
        category:DataBaseItemCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        sellPrice:Double,
        UOM:UnitOfMeasurment,
        subCategory:DataBaseItemSubCategory
    ) async throws {
        let itemRef = DataBaseDocument(dataBaseId: dataBaseItem.id, companyId: companyId)
        
            // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            "name":name,
            "rate":rate,
            "category":category.rawValue,
            "description":description,
            "dateUpdated":Date(),
            "sku":sku,
            "billable":billable,
            "color":color,
            "size":size,
            "sellPrice":sellPrice,
            "UOM":UOM.rawValue,
            "subCategory":subCategory.rawValue,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateReceiptPDFPath(companyId: String,receiptItemId:String,path:String) async throws {
        
        let ref = ReceiptItemDocument(receiptItemId: receiptItemId, companyId: companyId)
        
        ref.updateData([
            Receipt.CodingKeys.pdfUrlList.rawValue: FieldValue.arrayUnion([path])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }
    func updateRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws {
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: activeRoute.id)
            .updateData([
                ActiveRoute.CodingKeys.serviceStopsIds.rawValue:FieldValue.arrayUnion([serviceStopId])
            ])
        
    }
    func removeRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws{
        
    }
    
    func endRecurringRoute(companyId:String,recurringRouteId:String,endDate:Date) async throws {
            //DEVELOPER ADD LOGIC
        print("End Recurring Route Logic")
        try await reccuringRouteDoc(companyId: companyId, recurringRouteId: recurringRouteId).delete()
        
            //Delete Recurring Route
    }
    func updateActiveRouteOrderList(companyId:String,activeRouteId:String,serviceStopOrderList:[ServiceStopOrder]) async throws {
        
    }
    
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) async throws{
        workOrderCollection(companyId: companyId).document(workOrder.id).updateData([
            "installationParts": FieldValue.arrayUnion([[
                
                "id": installationPart.id,
                "name": installationPart.name,
                "quantity": installationPart.quantity,
                "cost": installationPart.cost,
                "genericItemId": installationPart.genericItemId,
                
            ] as [String : Any]])
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) async throws{
            //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "pvcParts": [
                [
                    
                    "id": pvcPart.id,
                    "name": pvcPart.name,
                    "quantity": pvcPart.quantity,
                    "cost": pvcPart.cost,
                    "genericItemId": pvcPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) async throws{
            //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "electricalParts": [
                [
                    
                    "id": electricalPart.id,
                    "name": electricalPart.name,
                    "quantity": electricalPart.quantity,
                    "cost": electricalPart.cost,
                    "genericItemId": electricalPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) async throws{
            //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "chemicals": [
                [
                    "id": chemical.id,
                    "name": chemical.name,
                    "quantity": chemical.quantity,
                    "cost": chemical.cost,
                    "genericItemId": chemical.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) async throws{
            //        let workOrder =  try await workOrderDocument(workOrderId: workOrderId, companyId: user.companyId).getDocument(as: WorkOrder.self)
        workOrderCollection(companyId: companyId).document(workOrderId).updateData([
            "miscParts": [
                [
                    
                    "id": miscPart.id,
                    "name": miscPart.name,
                    "quantity": miscPart.quantity,
                    "cost": miscPart.cost,
                    "genericItemId": miscPart.genericItemId,
                    
                ] as [String : Any]]
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) async throws{
        var serviceStops = workOrder.serviceStopIds
        serviceStops.append(serviceStopId)
        let ref = db.collection("workOrders").document(workOrder.id)
        
        ref.updateData([
            "serviceStopIds": serviceStops
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) async throws{
        
        
        
            //        let history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
            //        var historyArray:[String] = []
            //        let pushHistoryArray:[String] = []
            //
            //
            //        let historyText = ""
            //        var dateAndTech = ""
            //        var valueChange = ""
            //check if there was a chnage in tech
        
        let ref = db.collection("companies/\(companyId)/serviceStops").document(workOrder.id)
        ref.updateData([
            "invoiced": billingStatus
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Billing Status Successfully")
            }
        }
        
    }
        //Fix later when I have more time
    
    
    func updateWorkOrder(originalJob:Job,newJob:Job) async throws{
        /*
         let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
         var user = try await UserManager.shared.getCurrentUser(userId: authDataResult.uid)
         
         var history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
         var historyArray:[String] = []
         var pushHistoryArray:[String] = []
         
         
         var historyText = ""
         var dateAndTech = ""
         var valueChange = ""
         var counter = 0
         //check if there was a chnage in tech
         if originalServiceStop.tech != newServiceStop.tech {
         counter = counter + 1
         dateAndTech = " ** " + (originalWorkOrder.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalWorkOrder.tech ?? "") + " --> " + (newServiceStop.tech ?? "") + " ** "
         historyArray.append(valueChange)
         
         let ref = db.collection("serviceStops").document(originalWorkOrder.id)
         ref.updateData([
         "tech": newServiceStop.tech
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         if originalWorkOrder.description != newServiceStop.description {
         
         counter = counter + 1
         print(counter)
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.description ?? "") + " --> " + (newServiceStop.description ?? "") + " ** "
         print(valueChange)
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "description": newServiceStop.description
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         
         if originalServiceStop.title != newServiceStop.title {
         
         counter = counter + 1
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.title ?? "") + " --> " + (newServiceStop.title ?? "") + " ** "
         print(valueChange)
         
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "title": newServiceStop.title
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         if originalServiceStop.finished != newServiceStop.finished {
         
         counter = counter + 1
         dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
         valueChange = " ** " + (originalServiceStop.finished!.description.capitalized ) + " --> " + (newServiceStop.finished!.description.capitalized ) + " ** "
         print(valueChange)
         historyArray.append(valueChange)
         let ref = db.collection("serviceStops").document(originalServiceStop.id)
         ref.updateData([
         "finished": newServiceStop.finished
         ]) { err in
         if let err = err {
         print("Error updating document: \(err)")
         } else {
         print("Document successfully updated")
         }
         }
         }
         history.changes = historyArray
         if counter > 0 {
         pushHistoryArray.append(dateAndTech + historyText)
         if historyArray != pushHistoryArray{
         try db.collection("serviceStops/" + originalServiceStop.id + "/history").document(history.id).setData(from:history, merge: false)
         }
         } else {
         print("no change made")
         }
         */
    }
    
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "adminId": adminId,
            "adminName": adminName,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "jobTemplateId": templateId,
            "type": templateName,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:JobOperationStatus) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "operationStatus": operationStatus.rawValue,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:JobBillingStatus) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "billingStatus": billingStatus.rawValue,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "rate": Double(rate),//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "laborCost": Double(laborCost),//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws{
        let ref = workOrderDocument(workOrderId: jobId, companyId: companyId)
        ref.updateData([
            "description": description,//DEVELOPER MOVE THIS HIGHER UP THE CHAIN, SO WE CAN VALIDATE BETTER
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Store Items")
            }
        }
    }
    
    func updateContract(companyId:String,contract:RecurringContract) async throws {
        
        try contractCollection(companyId: companyId).document(contract.id).setData(from:contract, merge: true)
    }
    func updateContractStatus(companyId:String,contractId:String,status:RecurringContractStatus) async throws {
        let contractRef = contractDocument(companyId: companyId, contractId: contractId)
        
        
        contractRef.updateData([
            "status":status
        ]) { err in
            if let err = err {
                print("Error updating Contract Status: \(err)")
            } else {
                print("Document successfully updated Contract Status")
            }
        }
    }
    func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws {
        let contractRef = contractDocument(companyId: companyId, contractId: contractId)
        
        
        contractRef.updateData([
            "startDate":startDate
        ]) { err in
            if let err = err {
                print("Error updating Contract Start Date: \(err)")
            } else {
                print("Document successfully updated Contract Start Date")
            }
        }
    }
    func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws {
        let contractRef = contractDocument(companyId: companyId, contractId: contractId)
        
        
        contractRef.updateData([
            "endDate":endDate
        ]) { err in
            if let err = err {
                print("Error updating Contract End Date: \(err)")
            } else {
                print("Document successfully updated Contract End Date")
            }
        }
    }
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        
        try repairRequestCollection(companyId: companyId).document(repairRequest.id).setData(from:repairRequest, merge: true)
    }
    func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:RepairRequestStatus) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        ref.updateData([
            "status": status
        ]) { err in
            if let err = err {
                print("Error updating Repair Request Doc: \(err)")
            } else {
                print("Updated Repair Request Status Successfully")
            }
        }
    }
    func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        ref.updateData([
            "jobIds": FieldValue.arrayUnion([jobId])
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws {
        let ref = repairRequestDocument(companyId: companyId, repairRequestId: repairRequestId)
        ref.updateData([
            "photoUrls": FieldValue.arrayUnion([photoUrl])
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully Updated photoURl String")
            }
        }
    }
    func uploadRepairRequestImage(companyId: String, requestId: String, image: DripDropImage) async throws -> (path: String, name: String) {
        return ("","")
    }
    func markChatAsRead(userId:String, chat: Chat) async throws {
        
        var array:[String] = chat.participantIds
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        
        chatRef.updateData([
            "userWhoHaveNotRead": FieldValue.arrayRemove([userId])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func markChatAsUnread(userId:String,chat:Chat) async throws {
        print("Trying to mark the chat as unread")
        var array:[String] = chat.participantIds
        
        array.removeAll(where: {$0 == userId})
        let chatRef = chatDocument(chatId: chat.id)
        chatRef.updateData([
            "userWhoHaveNotRead" : FieldValue.arrayUnion(array)
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateStore(companyId:String,store:Vender,name:String,streetAddress:String,city:String,state:String,zip:String) async throws {
        
        let ref = StoreCollection(companyId: companyId).document(store.id)
        ref.updateData([
            "address": [
                "StreetAddress": streetAddress,
                "City": city,
                "State": state,
                "Zip": zip
            ],
            "name":name
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Billing Status Successfully")
            }
        }
    }
    func updateCompanyImagePath(user:DBUser,companyId:String,path:String) async throws {
        let ref = CompanyDocument(companyId: companyId)
        
        ref.updateData([
            Company.CodingKeys.photoUrl.rawValue: path,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }
    func updateRole(companyId:String,role : Role) async throws {
        try roleDoc(companyId: companyId, roleId: role.id)
            .setData(from:role, merge: true)
    }
    func updateServiceStopLocations(newServiceStop:ServiceStop,serviceLocation:ServiceLocation,companyId:String) async throws{
    }
    
    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) async throws{
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        ref.updateData([
            ServiceStop.CodingKeys.serviceDate.rawValue: serviceDate,
            ServiceStop.CodingKeys.techId.rawValue: companyUser.userId,
            ServiceStop.CodingKeys.tech.rawValue: companyUser.userName,
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Service Date Successfully")
            }
        }
        
    }
    func updateServiceStop(
        companyId:String,
        user:DBUser,
        originalServiceStop:ServiceStop,
        newServiceStop:ServiceStop
    ) async throws{
        
    }
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws {
        
    }
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws {
        let equipmentRef = equipmentDoc(companyId: companyId, equipmentId: equipmentId)
        equipmentRef.updateData([
            Equipment.CodingKeys.name.stringValue:equipment.name,
            Equipment.CodingKeys.category.stringValue:equipment.category,
            Equipment.CodingKeys.make.stringValue:equipment.make,
            Equipment.CodingKeys.model.stringValue:equipment.model,
            Equipment.CodingKeys.dateInstalled.stringValue:equipment.dateInstalled,
            Equipment.CodingKeys.status.stringValue:equipment.status,
            Equipment.CodingKeys.needsService.stringValue:equipment.needsService,
            Equipment.CodingKeys.customerId.stringValue:equipment.customerId,
            Equipment.CodingKeys.serviceLocationId.stringValue:equipment.serviceLocationId,
            Equipment.CodingKeys.bodyOfWaterId.stringValue:equipment.bodyOfWaterId,
        ]) { err in
            if let err = err {
                print("Error updating Equipment: \(err)")
            } else {
                print("Equipment successfully updated")
            }
        }
        if equipment.needsService {
            equipmentRef.updateData([
                Equipment.CodingKeys.lastServiceDate.stringValue:equipment.lastServiceDate,
                Equipment.CodingKeys.serviceFrequency.stringValue:equipment.serviceFrequency,
                Equipment.CodingKeys.serviceFrequencyEvery.stringValue:equipment.serviceFrequencyEvery,
                Equipment.CodingKeys.nextServiceDate.stringValue:equipment.nextServiceDate,
            ]) { err in
                if let err = err {
                    print("Error updating equipment: \(err)")
                } else {
                    print("Equipment successfully updated")
                }
            }
        }
    }
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws {
        try equipmentCollection(companyId: companyId).document(equipment.id).setData(from:equipment, merge: true)
        
    }
    
    
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "name":name
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Name: \(err)")
            } else {
                print("Document successfully updated Body Of Water Name")
            }
        }
    }
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "gallons":gallons
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Gallons: \(err)")
            } else {
                print("Document successfully updated Body Of Water Gallons")
            }
        }
    }
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "material":material
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Material: \(err)")
            } else {
                print("Document successfully updated Material")
            }
        }
    }
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "notes":notes
        ]) { err in
            if let err = err {
                print("Error updating Body Of Water Notes: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Notes")
            }
        }
    }
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "shape":shape
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Shape: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Shape")
            }
        }
    }
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "length":length
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Length: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Length")
            }
        }
    }
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "depth":depth
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Depth: \(err)")
            } else {
                print("Document successfully updated  Body Of Water Depth")
            }
        }
    }
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "width":width
        ]) { err in
            if let err = err {
                print("Error updating  Body Of Water Width: \(err)")
            } else {
                print("Document successfully updated Body Of Water Width")
            }
        }
    }
    
    func editBodyOfWater(companyId:String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) async throws{
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWater.id)
        
        
        bodyOfWaterRef.updateData([
            "gallons":updatedBodyOfWater.gallons,
            "material":updatedBodyOfWater.material,
            "name":updatedBodyOfWater.name
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) async throws {
        let customerRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId)
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            
            "address": [
                "City": address.city,
                "State": address.state,
                "StreetAddress": address.streetAddress,
                "Zip": address.zip,
                "latitude":address.latitude ,
                "longitude":address.longitude ,
            ] as [String : Any],
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceLocationNickName(companyId: String, serviceLocationId: String, nickName: String) async throws {
        
    }
    
    func updateServiceLocationGateCode(companyId: String, serviceLocationId: String, gateCode: String) async throws {
        
    }
    
    func updateServiceLocationDogName(companyId:String,serviceLocationId:String,dogNames:[String])async throws{
        
    }
    
    func updateServiceLocationEstimatedTime(companyId: String, serviceLocationId: String, estimatedTime: Int) async throws {
        
    }
    
    func updateServiceLocationNotes(companyId: String, serviceLocationId: String, notes: String) async throws {
        
    }
    
    func updateServiceLocationContact(companyId: String, serviceLocationId: String, contact: Contact) async throws {
        
    }
    func updateServiceLocation(companyId:String,currentCustomerId:String,serviceLocation:ServiceLocation) async throws {
        
        let customerRef = serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocation.id)
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            "nickName": serviceLocation.nickName,
            "gateCode": serviceLocation.gateCode,
            "dogName": serviceLocation.dogName as Any,
            "estimatedTime": serviceLocation.estimatedTime as Any,
            "mainContact": [
                "Name": serviceLocation.mainContact.name,
                "phoneNumber": serviceLocation.mainContact.phoneNumber,
                "email": serviceLocation.mainContact.email,
                "notes": serviceLocation.mainContact.notes,
            ],
            "notes": serviceLocation.notes as Any,
            "rateType": serviceLocation.rateType,
            "laborType": serviceLocation.laborType,
            "chemicalCost": serviceLocation.chemicalCost,
            "laborCost": serviceLocation.laborCost,
            "rate": serviceLocation.rate,
            "customerName": serviceLocation.customerName,
            "address": [
                "City": serviceLocation.address.city,
                "State": serviceLocation.address.state,
                "StreetAddress": serviceLocation.address.streetAddress,
                "Zip": serviceLocation.address.zip,
                "latitude":serviceLocation.address.latitude ,
                "longitude":serviceLocation.address.longitude,
            ] as [String : Any],
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) async throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        var pushLat = customerWithUpdates.billingAddress.latitude
        var pushLong = customerWithUpdates.billingAddress.longitude
        
        if currentCustomer.billingAddress.streetAddress != customerWithUpdates.billingAddress.streetAddress || currentCustomer.billingAddress.city != customerWithUpdates.billingAddress.city || currentCustomer.billingAddress.state != customerWithUpdates.billingAddress.state || currentCustomer.billingAddress.zip != customerWithUpdates.billingAddress.zip {
            let fulladdress = customerWithUpdates.billingAddress.streetAddress + " " + customerWithUpdates.billingAddress.city + " " + customerWithUpdates.billingAddress.state + " " + customerWithUpdates.billingAddress.zip
            geoCoder.geocodeAddressString(fulladdress) {
                placemarks, error in
                let placemark = placemarks?.first
                self.Coordinates = placemark?.location?.coordinate
                
                pushLat = self.Coordinates?.latitude ?? 0
                pushLong = self.Coordinates?.longitude ?? 0
            }
            
        }
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            "firstName":customerWithUpdates.firstName,
            "lastName":customerWithUpdates.lastName,
            "email":customerWithUpdates.email,
            "billingAddress": [
                "City": customerWithUpdates.billingAddress.city,
                "State": customerWithUpdates.billingAddress.state,
                "StreetAddress": customerWithUpdates.billingAddress.streetAddress,
                "Zip": customerWithUpdates.billingAddress.zip,
            ],
            "phoneNumber":customerWithUpdates.phoneNumber ?? "",
            "phoneLabel":customerWithUpdates.phoneLabel ?? "",
            "company":customerWithUpdates.company ?? "",
            "displayAsCompany":customerWithUpdates.displayAsCompany,
            "hireDate":customerWithUpdates.hireDate,
            "latitude":pushLat,
            "longitidue":pushLong
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) async throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            "firstName":currentCustomer.firstName,
            "lastName":currentCustomer.lastName,
            "email":currentCustomer.email,
            //            "billingAddress": [
            //                "City": customerWithUpdates.billingAddress.city,
            //                "State": customerWithUpdates.billingAddress.state,
            //                "StreetAddress": customerWithUpdates.billingAddress.streetAddress,
            //                "Zip": customerWithUpdates.billingAddress.zip,
            //            ],
            "phoneNumber":currentCustomer.phoneNumber ?? "",
            //            "phoneLabel":customerWithUpdates.phoneLabel ?? "",
            "company":currentCustomer.company ?? "",
            "displayAsCompany":currentCustomer.displayAsCompany,
            //            "hireDate":customerWithUpdates.hireDate,
            //            "latitude":pushLat,
            //            "longitidue":pushLong
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCustomerInfoWithValidation(
        currentCustomer:Customer,
        companyId: String,
        firstName:String,
        lastName:String,
        email:String,
        phoneNumber:String,
        company:String,
        displayAsCompany:Bool,
        billingAddress:Address,
        active:Bool
    ) async throws {
        let customerRef = customerDocument(customerId: currentCustomer.id, companyId: companyId)
        print("Customer id \(currentCustomer.id)")
        customerRef.updateData([
            Customer.CodingKeys.firstName.stringValue:firstName,
            Customer.CodingKeys.lastName.stringValue:lastName,
            Customer.CodingKeys.email.stringValue:email,
            Customer.CodingKeys.phoneNumber.stringValue:phoneNumber,
            Customer.CodingKeys.company.stringValue:company,
            Customer.CodingKeys.displayAsCompany.stringValue:displayAsCompany,
            Customer.CodingKeys.billingAddress.stringValue: [
                Address.CodingKeys.city.stringValue: billingAddress.city,
                Address.CodingKeys.state.stringValue: billingAddress.state,
                Address.CodingKeys.streetAddress.stringValue: billingAddress.streetAddress,
                Address.CodingKeys.zip.stringValue: billingAddress.zip,
                Address.CodingKeys.latitude.stringValue:billingAddress.latitude ,
                Address.CodingKeys.longitude.stringValue:billingAddress.longitude ,
            ]
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) async throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            
            "billingAddress": [
                "city": address.city,
                "state": address.state,
                "streetAddress": address.streetAddress,
                "zip": address.zip,
                "latitude":address.latitude ,
                "longitude":address.longitude ,
            ] as [String : Any],
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    
    
    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) async throws {
        let customerRef = customerDocument(customerId: currentCustomerId, companyId: companyId)
        
            // Set the "capital" field of the city 'DC'
        customerRef.updateData([
            
            "active":false,
            "fireDate":fireDate,
            "fireCategory":fireCategory,
            "fireReason":fireReason,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updatePurchaseItem(purchaseItem:PurchasedItem,companyId: String) async throws {
        
            // Add a new document in collection "cities"
        PurchaseItemDocument(purchaseItemId: purchaseItem.id, companyId: companyId).setData([
            "workOrderId": "0"
        ]) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    func updateNotes(currentItem:PurchasedItem,notes:String,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "notes":notes
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateBilling(currentItem:PurchasedItem,billingRate:Double,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "billingRate":billingRate
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedItemBillingStatus(currentItem:PurchasedItem,newBillingStatus:Bool,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
            // Set the "capital" field of the city 'DC'
        itemRef.updateData([
            "invoiced":newBillingStatus
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedCustomer(currentItem:PurchasedItem,newCustomer:Customer,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        let fullName = newCustomer.firstName + " " + newCustomer.lastName
        print(fullName)
        itemRef.updateData([
            "customerId":newCustomer.id,
            "customerName":fullName
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updatePurchasedWorkOrderId(currentItem:PurchasedItem,workOrderId:String,companyId: String) async throws {
        let itemRef = PurchaseItemDocument(purchaseItemId: currentItem.id, companyId: companyId)
        
        itemRef.updateData([
            "workOrderId":workOrderId
            
            
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateCompanyUserFavorites(user:DBUser,updatingUser:DBUser,favorites:[String]) async throws {
            //        let ref = userDocument(userId: updatingUser.id)
            //        //Change to Array Append
            //         ref.updateData([
            //            DBUser.CodingKeys.favorites.rawValue: favorites,
            //        ]) { err in
            //            if let err = err {
            //                print("Error updating document: \(err)")
            //            } else {
            //                print("Updated Tech Favorite List Successfully")
            //            }
            //        }
    }
    func updateUserImagePath(updatingUser:DBUser,path:String) async throws {
        let ref = userDocument(userId: updatingUser.id)
        
        ref.updateData([
            DBUser.CodingKeys.photoUrl.rawValue: path,
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Updated Tech Image List Successfully")
            }
        }
    }
    
    func updateUserRecentlySelectedCompany(user:DBUser,recentlySelectedCompanyId:String) async throws {
        
    }
    func updateToDoTitle(companyId:String,toDoId:String,newTitle:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "title": newTitle
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoStatus(companyId:String,toDoId:String,newStatus:toDoStatus) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "status": newStatus
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoDescription(companyId:String,toDoId:String,newDescription:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "description": newDescription
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoDateFinished(companyId:String,toDoId:String,newDateFinished:Date?) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "dateFinished": newDateFinished
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoCustomerId(companyId:String,toDoId:String,newCustomerId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "customerId": newCustomerId
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoJobId(companyId:String,toDoId:String,newJobId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "jobId": newJobId
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func updateToDoTechId(companyId:String,toDoId:String,newTechId:String) async throws {
        ToDoDocument(toDoId: toDoId, companyId: companyId)
            .updateData([
                "newTechId": newTechId
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
    }
    func getToDoCount(companyId:String) async throws -> Int {
        var toDoCount = 0
        let doc = try await Firestore.firestore().collection("companies/\(companyId)/settings").document("todos").getDocument(as: Increment.self)
        toDoCount = doc.increment
        let updatedServiceStopCount = toDoCount + 1
        Firestore.firestore().collection("companies/\(companyId)/settings").document("todos")
            .updateData([
                "increment": updatedServiceStopCount
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        print("Service Stop Count " + String(toDoCount))
        return updatedServiceStopCount
    }
    
    
    
    
    
    
    
    
    
        //----------------------------------------------------
        //                    Delete Functions
        //----------------------------------------------------
    func deleteRecurringServiceStop(companyId:String,recurringServiceStopId : String) async throws {
        try await recurringServiceStopDocument(recurringServiceStopId: recurringServiceStopId, companyId: companyId).delete()
        
    }
    func deleteRecurringRoute(companyId:String,recurringRouteId : String) async throws{
        
    }
    
    
    /*
     func CreateGenericHistory(companyId:String,customerList:[Customer],ServiceLocation:[ServiceableLocation]) async throws {
     let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
     let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
     let calendar = Calendar.current
     
     let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: user.companyId)
     .whereField("type", isEqualTo: "Weekly Cleaning")
     .getDocuments(as:WorkOrderTemplate.self)
     let weeklyCleaningTemplate = workOrderTempaltes.first
     
     var customerCount = 0
     var locationsCount = 0
     
     var serviceStopCount = 0
     
     for customer in customerList{
     var customerFullName = (customer.firstName ?? "") + " " + (customer.lastName ?? "")
     
     print("Customer \(customerFullName)")
     var counter = 0
     
     let serviceLocations = try await CustomerManager.shared.getAllCustomerServiceLocations(customer: customer)
     
     for location in serviceLocations {
     
     for _ in 1...56 {
     var date = Date()
     
     var readingList:[String:String] = [:]
     var dosageList:[String:String] = [:]
     for readings in readingTemplates {
     if readings.amount?.count != 0 {
     let randomReading = readings.amount?.randomElement()
     readingList[readings.name ?? ""] = randomReading
     }
     }
     for dosage in dosageTemplates {
     if dosage.amount?.count != 0 {
     let randomDosage = dosage.amount?.randomElement()
     dosageList[dosage.name ?? ""] = randomDosage
     }
     }
     date = calendar.date(byAdding: .day, value: counter, to: date)!
     let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount()
     let id = "S" + String(dataBaseServiceStopCount)
     
     var serviceStop = ServiceStop(id: id, typeId: weeklyCleaningTemplate?.id ?? "1", finished: true, customerName: customerFullName, customerId: customer.id, address: customer.billingAddress, dateCreated: date, serviceDate: date, duration: 15, rate: 15, tech: user.displayName, techId: user.id, invoiced: false, description: "NA", serviceLocationId: location.id, type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning")//It might get fuckie without a real serviceLocationId
     
     try await ServiceStopManager.shared.uploadServiceStop(serviceStop: serviceStop)
     
     print("Created servcice stop on \(fullDate(date: date))")
     
     var stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList)
     
     try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: user.companyId).setData(from:stopData, merge: false)
     
     print("Added Stop Data")
     counter = counter - 7
     serviceStopCount = serviceStopCount + 1
     print("Service Stop Count \(serviceStopCount)")
     
     }
     locationsCount = locationsCount + 1
     print("Service Location Count \(locationsCount)")
     
     for months in 1...13 {
     let multiplier = (months * -1) + 1
     let calendar = Calendar.current
     let components = calendar.dateComponents([.year, .month, .day], from: Date())
     let dateComponents = calendar.date(from: components)!
     let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
     
     var pushEndDate = changingDate.endOfMonth()
     var pushStartDate = changingDate.startOfMonth()
     
     
     //working spot
     print(pushStartDate)
     print(pushEndDate)
     
     let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: user.companyId)
     .whereField("date", isGreaterThan: pushStartDate)
     .whereField("date", isLessThan: pushEndDate)
     .getDocuments(as:StopData.self)
     
     //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
     
     print("stopHistory")
     print(stopHistory)
     
     var totalData:[PNLDataPointArray] = []
     var dataPoints:[PNLChem] = []
     var dataPointsByDay:[PNLChem] = []
     var dateList:[Date] = []
     for stop in stopHistory {
     print("stop")
     print(stop)
     if stop.date > pushStartDate && stop.date < pushEndDate {
     for template in dosageTemplates {
     let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
     dataPoints.append(PNLDataPoint)
     }
     
     }
     }
     for uniqueDay in dataPoints{
     if !dateList.contains(uniqueDay.date) {
     dateList.append(uniqueDay.date)
     for day in dataPoints {
     if uniqueDay.date == day.date {
     dataPointsByDay.append(day)
     }
     }
     let serviceStop = try! await ServiceStopManager.shared.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: user.companyId)
     
     totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
     dataPointsByDay = []
     }
     }
     var chemicalCost: Double = 0.00
     var laborCost: Double = 0.00
     
     for data in dataPoints {
     chemicalCost = data.totalCost + chemicalCost
     }
     for data in totalData {
     laborCost = data.laborCost + laborCost
     }
     let totalCost = laborCost + chemicalCost
     print("chemicalCost")
     print(chemicalCost)
     print("laborCost")
     print(laborCost)
     print("totalCost")
     print(totalCost)
     let fullName = (customer.firstName ) + " " + (customer.lastName )
     
     try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
     }
     
     }
     
     customerCount = customerCount + 1
     print("Customer Count \(customerCount)")
     //remove before Production
     
     if customerCount > 10{
     return
     }
     
     }
     }
     func CreateGenericHistory2(companyId:String,customer:Customer,ServiceLocation:[ServiceableLocation]) async throws {
     let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
     let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
     let calendar = Calendar.current
     
     let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: companyId)
     .whereField("type", isEqualTo: "Weekly Cleaning")
     .getDocuments(as:JobTemplate.self)
     let weeklyCleaningTemplate = workOrderTempaltes.first
     
     var customerCount = 0
     var locationsCount = 0
     
     var serviceStopCount = 0
     
     let customerFullName = (customer.firstName ) + " " + (customer.lastName )
     
     print("Customer \(customerFullName)")
     var counter = 0
     
     let serviceLocations = try await ServiceLocationManager.shared.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
     
     for location in serviceLocations {
     
     for _ in 1...56 {
     print("Service Location Id")
     print(location.id)
     let bodiesOfWater = try await BodyOfWaterManager.shared.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: location)
     
     //creates service Stop
     var date = Date()
     
     
     date = calendar.date(byAdding: .day, value: counter, to: date)!
     let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount(companyId: company.id)
     let id = "S" + String(dataBaseServiceStopCount)
     
     let serviceStop = ServiceStop(id: id,
     typeId: weeklyCleaningTemplate?.id ?? "1",
     customerName: customerFullName,
     customerId: customer.id,
     address: customer.billingAddress,
     dateCreated: date,
     serviceDate: date,
     duration: 15,
     rate: 15,
     techId: user.id,
     recurringServiceStopId: "NA",
     description: "",
     serviceLocationId: location.id,
     type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning",
     typeImage: weeklyCleaningTemplate?.typeImage ?? "bubbles.and.sparkles.fill",
     workOrderId: "",
     finished: true,
     skipped: false,
     invoiced: true,checkList: []
     ,includeReadings: true,includeDosages: true)
     
     
     try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
     
     print("Created servcice stop on \(fullDate(date: date))")
     
     
     for bodyOfWater in bodiesOfWater {
     
     var readingList:[Reading] = []
     var dosageList:[Dosage] = []
     for readings in readingTemplates {
     if readings.amount.count != 0 {
     let randomReading = readings.amount.randomElement()
     readingList.append(Reading(id: UUID().uuidString, templateId: readings.id, dosageType: readings.chemType, name: readings.name, amount: randomReading, UOM: readings.UOM, bodyOfWaterId: bodyOfWater.id))
     }
     }
     for dosage in dosageTemplates {
     if dosage.amount?.count != 0 {
     let randomDosage = dosage.amount?.randomElement()
     dosageList.append(Dosage(id: UUID().uuidString, templateId: dosage.id, name: dosage.name,amount:randomDosage, UOM: dosage.UOM, rate: dosage.rate, linkedItem:dosage.linkedItemId ?? "1" , bodyOfWaterId: bodyOfWater.id))
     }
     }
     let stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList, bodyOfWaterId: bodyOfWater.id)
     
     try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
     
     print("Added Stop Data")
     counter = counter - 7
     serviceStopCount = serviceStopCount + 1
     print("Service Stop Count \(serviceStopCount)")
     }
     
     }
     locationsCount = locationsCount + 1
     print("Service Location Count \(locationsCount)")
     
     for months in 1...13 {
     let multiplier = (months * -1) + 1
     let calendar = Calendar.current
     let components = calendar.dateComponents([.year, .month, .day], from: Date())
     let dateComponents = calendar.date(from: components)!
     let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
     
     let pushEndDate = changingDate.endOfMonth()
     let pushStartDate = changingDate.startOfMonth()
     
     
     //working spot
     print(pushStartDate)
     print(pushEndDate)
     
     let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
     .whereField("date", isGreaterThan: pushStartDate)
     .whereField("date", isLessThan: pushEndDate)
     .getDocuments(as:StopData.self)
     
     //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
     
     print("stopHistory")
     print(stopHistory)
     
     var totalData:[PNLDataPointArray] = []
     var dataPoints:[PNLChem] = []
     var dataPointsByDay:[PNLChem] = []
     var dateList:[Date] = []
     for stop in stopHistory {
     print("stop")
     print(stop)
     if stop.date > pushStartDate && stop.date < pushEndDate {
     for template in dosageTemplates {
     let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(stop.dosages[template.name ?? ""] as! String) ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
     dataPoints.append(PNLDataPoint)
     }
     
     }
     }
     for uniqueDay in dataPoints{
     if !dateList.contains(uniqueDay.date) {
     dateList.append(uniqueDay.date)
     for day in dataPoints {
     if uniqueDay.date == day.date {
     dataPointsByDay.append(day)
     }
     }
     let serviceStop = try! await ServiceStopManager.shared.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
     
     totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
     dataPointsByDay = []
     }
     }
     var chemicalCost: Double = 0.00
     var laborCost: Double = 0.00
     
     for data in dataPoints {
     chemicalCost = data.totalCost + chemicalCost
     }
     for data in totalData {
     laborCost = data.laborCost + laborCost
     }
     let totalCost = laborCost + chemicalCost
     print("chemicalCost")
     print(chemicalCost)
     print("laborCost")
     print(laborCost)
     print("totalCost")
     print(totalCost)
     let fullName = (customer.firstName ) + " " + (customer.lastName )
     
     try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
     }
     
     }
     
     customerCount = customerCount + 1
     print("Customer Count \(customerCount)")
     //remove before Production
     
     //            if customerCount > 0{
     //                return
     //            }
     
     
     }
     func CreateGenericHistory3(companyId:String,customer:Customer,location:ServiceableLocation) async throws {
     let readingTemplates = try await SettingsManager.shared.getAllReadingTemplates(companyId: companyId)
     let dosageTemplates = try await SettingsManager.shared.getAllDosageTemplates(companyId: companyId)
     let calendar = Calendar.current
     
     let workOrderTempaltes =  try await WorkOrderTemplateCollection(companyId: companyId)
     .whereField("type", isEqualTo: "Weekly Cleaning")
     .getDocuments(as:JobTemplate.self)
     let weeklyCleaningTemplate = workOrderTempaltes.first
     
     var customerCount = 0
     var locationsCount = 0
     
     var serviceStopCount = 0
     
     let customerFullName = (customer.firstName ) + " " + (customer.lastName )
     
     print("Customer \(customerFullName)")
     var counter = 0
     
     //        let serviceLocations = try await CustomerManager.shared.getAllCustomerServiceLocations(customer: customer)
     
     
     for _ in 1...56 {
     print("Service Location Id")
     print(location.id)
     let bodiesOfWater = try await BodyOfWaterManager.shared.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: location)
     
     //creates service Stop
     var date = Date()
     
     
     date = calendar.date(byAdding: .day, value: counter, to: date)!
     let dataBaseServiceStopCount = try await SettingsManager.shared.getServiceOrderCount()
     let id = "S" + String(dataBaseServiceStopCount)
     
     let serviceStop = ServiceStop(id: id,
     typeId: weeklyCleaningTemplate?.id ?? "1",
     customerName: customerFullName,
     customerId: customer.id,
     address: customer.billingAddress,
     dateCreated: date,
     serviceDate: date,
     duration: 15,
     rate: 15,
     techId: user.id,
     recurringServiceStopId: "NA",
     description: "",
     serviceLocationId: location.id,
     type: weeklyCleaningTemplate?.type ?? "Weekly Cleaning",
     typeImage: weeklyCleaningTemplate?.typeImage ?? "bubbles.and.sparkles.fill",
     workOrderId: "",
     finished: true,
     skipped: false,
     invoiced: true,checkList: []
     ,includeReadings: true,includeDosages: true)
     
     try await ServiceStopManager.shared.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
     
     print("Created servcice stop on \(fullDate(date: date))")
     
     
     for bodyOfWater in bodiesOfWater {
     
     var readingList:[Reading] = []
     var dosageList:[Dosage] = []
     for readings in readingTemplates {
     if readings.amount.count != 0 {
     let randomReading = readings.amount.randomElement()
     //                        print(randomReading)
     readingList.append(Reading(id: UUID().uuidString, templateId: readings.id, dosageType: readings.chemType, name: readings.name, amount: randomReading, UOM: readings.UOM, bodyOfWaterId: bodyOfWater.id))
     }
     }
     for dosage in dosageTemplates {
     if dosage.amount?.count != 0 {
     var amount = "0"
     if dosage.name == "Liquid Chlorine"{
     amount = "1.00"
     
     }
     dosageList.append(Dosage(id: UUID().uuidString, templateId: dosage.id, name: dosage.name,amount:amount, UOM: dosage.UOM, rate: dosage.rate, linkedItem:dosage.linkedItemId ?? "1" , bodyOfWaterId: bodyOfWater.id))
     
     }
     }
     let stopData = StopData(id: UUID().uuidString, date: date, serviceStopId: id, readings: readingList, dosages: dosageList, bodyOfWaterId: bodyOfWater.id)
     
     try readingDocumentToCustomerHistory(customerId: serviceStop.customerId , stopDataId: stopData.id, companyId: companyId).setData(from:stopData, merge: false)
     
     print("Added Stop Data")
     counter = counter - 7
     serviceStopCount = serviceStopCount + 1
     print("Service Stop Count \(serviceStopCount)")
     }
     
     }
     locationsCount = locationsCount + 1
     print("Service Location Count \(locationsCount)")
     
     for months in 1...13 {
     let multiplier = (months * -1) + 1
     let calendar = Calendar.current
     let components = calendar.dateComponents([.year, .month, .day], from: Date())
     let dateComponents = calendar.date(from: components)!
     let changingDate = calendar.date(byAdding: .month, value: multiplier, to: dateComponents)!
     
     let pushEndDate = changingDate.endOfMonth()
     let pushStartDate = changingDate.startOfMonth()
     
     
     //working spot
     print(pushStartDate)
     print(pushEndDate)
     
     let stopHistory = try await readingCollectionForCustomerHistory(customerId: customer.id, companyId: companyId)
     .whereField("date", isGreaterThan: pushStartDate)
     .whereField("date", isLessThan: pushEndDate)
     .getDocuments(as:StopData.self)
     
     //                let stopHistory = try await ReadingsManager.shared.readAllHistory(customer: customer)
     
     print("stopHistory")
     print(stopHistory)
     
     var totalData:[PNLDataPointArray] = []
     var dataPoints:[PNLChem] = []
     var dataPointsByDay:[PNLChem] = []
     var dateList:[Date] = []
     for stop in stopHistory {
     print("stop")
     print(stop)
     if stop.date > pushStartDate && stop.date < pushEndDate {
     for template in dosageTemplates {
     for dosage in stop.dosages {
     if dosage.templateId == template.id {
     let PNLDataPoint = PNLChem(id: UUID().uuidString, chemName: template.name ?? "NA", date: stop.date, amount: Double(dosage.amount ?? "0.00") ?? 0.00, rate: Double(template.rate ?? "0.00") ?? 0.00, serviceStopId: stop.serviceStopId)
     dataPoints.append(PNLDataPoint)
     }
     }
     }
     
     }
     }
     for uniqueDay in dataPoints{
     if !dateList.contains(uniqueDay.date) {
     dateList.append(uniqueDay.date)
     for day in dataPoints {
     if uniqueDay.date == day.date {
     dataPointsByDay.append(day)
     }
     }
     let serviceStop = try! await ServiceStopManager.shared.getServiceStopById(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
     
     totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
     dataPointsByDay = []
     }
     }
     var chemicalCost: Double = 0.00
     var laborCost: Double = 0.00
     
     for data in dataPoints {
     chemicalCost = data.totalCost + chemicalCost
     }
     for data in totalData {
     laborCost = data.laborCost + laborCost
     }
     let totalCost = laborCost + chemicalCost
     print("chemicalCost")
     print(chemicalCost)
     print("laborCost")
     print(laborCost)
     print("totalCost")
     print(totalCost)
     let fullName = (customer.firstName ) + " " + (customer.lastName )
     
     try await CustomerManager.shared.uploadingCustomerMonthlySummary(customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)), companyId: companyId)
     }
     
     
     
     customerCount = customerCount + 1
     print("Customer Count \(customerCount)")
     //remove before Production
     
     //            if customerCount > 0{
     //                return
     //            }
     
     
     }
     */
    
    func deleteJob(companyId:String,jobId:String) async throws {
        try await workOrderDocument(workOrderId: jobId, companyId: companyId).delete()
    }
    func deletePart(companyId:String,jobId:String,part:WODBItem,category:String) async throws {
        
    }
    func deleteContract(companyId:String,contractId:String) async throws{
        try await contractDocument(companyId: companyId,contractId: contractId).delete()
    }
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws{
        try await repairRequestDocument(companyId: companyId,repairRequestId: repairRequestId).delete()
    }
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws {
        try await shoppingListDoc(companyId: companyId, shoppingListItemId: shoppingListItemId).delete()
        
    }
    func deleteServiceStop(companyId:String,serviceStop:ServiceStop)async throws {
        try await serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).delete()
        
    }
    func deleteServiceStopById(companyId:String,serviceStopId:String)async throws {
        try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).delete()
        
    }
    func deleteEquipment(companyId:String,equipmentId:String) async throws {
        try await equipmentDoc(companyId: companyId, equipmentId: equipmentId).delete()
    }
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws {
        try await serviceLocationDoc(companyId: companyId, serviceLocationId: serviceLocationId).delete()
        
    }
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws{
        
        let summaryList = try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries")
            .getDocuments(as:CustomerMonthlySummary.self)
        
        for summary in summaryList {
            print("Deleted \(summary)")
            try await db.collection("companies/\(companyId)/customers/" + customer.id + "/monthlySummaries").document(summary.id)
                .delete()
        }
    }
    func deleteCustomer(companyId:String,customer:Customer) throws {
        print("Attempting to Delete \(customer.firstName) \(customer.lastName)")
        customerCollection(companyId: companyId)
            .document(customer.id).delete() { err in
                if let err = err {
                    print("Error removing document: \(err)")
                } else {
                    print("Customer successfully Deleted \(customer.firstName) \(customer.lastName)!")
                }
            }
    }
    func deleteCustomer(companyId:String,customer:Customer)async throws {
        try? await customerDocument(customerId: customer.id,companyId: companyId)
            .delete()
        
    }
    func deleteToDo(companyId:String,toDoId:String) async throws {
        try await ToDoDocument(toDoId: toDoId, companyId: companyId).delete()
    }
        //----------------------------------------------------
        //                    WORKING Functions
        //----------------------------------------------------
    
    
    func RegenerateCustomerSummaries(companyId:String,customers:[Customer],dosageTemplates:[DosageTemplate]) async throws {
            //        for customer in customers {
            //            //Delete all current monthlySummaries
            //            try await CustomerManager.shared.deleteAllCustomerSummaries(companyId: companyId, customer: customer)
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
            //                    let specificSummary = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId: companyId, customer: customer,month: pushStartDate,serviceLocationId: location.id).first
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
            //                            //DEVELOPER Investigate
            ////                            totalData.append(PNLDataPointArray(id: UUID().uuidString, date: uniqueDay.date,techId:serviceStop.techId!,tech:serviceStop.tech!, laborCost: Double(serviceStop.rate ?? Int(0.00)), PNLDataPoint: dataPointsByDay))
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
            //                    try await CustomerManager.shared.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: specificSummary?.id ?? "1",date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
            //                }
            //            }
            //            
            //        }
            //        
            //        
    }
    func RegenerateSingleCustomer(companyId:String,customer:Customer,dosageTemplates:[DosageTemplate]) async throws {
            //        //Delete all current monthlySummaries
            //        try await CustomerManager.shared.deleteAllCustomerSummaries(companyId:companyId,customer: customer)
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
            //                //                let specificSummary = try await CustomerManager.shared.getMonthlySummaryByCustomerAndMonthAndServiceLocation(customer: customer, companyId: companyId,month: pushStartDate,serviceLocationId: location.id).first
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
            //                        let serviceStop = try? await serviceStopDocument(serviceStopId: uniqueDay.serviceStopId, companyId: companyId)
            //                        //Developer INvestigate
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
            //                try await CustomerManager.shared.uploadingCustomerMonthlySummary(companyId: companyId, customer: customer, customerMonthlySummary: CustomerMonthlySummary(id: UUID().uuidString,date: pushStartDate, customerId: customer.id, customerDisplayName: fullName, serviceLocationId:location.id, monthlyRate: Double(location.rate) ?? 200.00, chemicalCost: chemicalCost, laborCost: laborCost, serviceStops: Double(dateList.count)))
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
    func addListenerForAllCustomers(companyId:String,storeId:String,completion:@escaping (_ serviceStops:[DataBaseItem]) -> Void){
        
        let listener = DataBaseCollection(companyId: companyId)
            .whereField("storeId", isEqualTo: storeId)
            .order(by: "name",descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let serviceStops: [DataBaseItem] = documents.compactMap({try? $0.data(as: DataBaseItem.self)})
                completion(serviceStops)
            }
        self.dataBaseListener = listener
    }
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        print("add Listener For UnreadChats \(userId)")
        let listener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .whereField("userWhoHaveNotRead", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
                completion(chats)
            }
        self.chatListener = listener
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
        
        print("All Filters ")
        
        listener = repairRequestCollection(companyId: companyId)
            .whereField("status", in: status)
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
        
        self.requestListener = listener
    }
    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void){
        
        let listener = chatCollection()
            .whereField("participantIds", arrayContains: userId)
            .order(by: "mostRecentChat", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("There are no documents in the Customer Collection")
                    return
                }
                let chats: [Chat] = documents.compactMap({try? $0.data(as: Chat.self)})
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
    func addListenerForSentLaborContracts(companyId:String,status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void){
    }
    func addListenerForReceivedLaborContracts(companyId:String,status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void){
    }
    func addListenerForReceivedLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void){
        
    }
    func addListenerForAllJobsBilling(companyId:String,status:[JobBillingStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void){
        
    }
    func addListenerForSentLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void){
    }
    
    func addListenerForAllJobsOperations(companyId:String,status:[JobOperationStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void){
        
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
    }
    func removeListenerForRequests(){
        self.requestListener?.remove()
    }
    
    func removeListenerForAllServiceStops(){
        self.serviceStopListener?.remove()
    }
    func removeEquipmentListener() {
        self.equipmentListener?.remove()
    }
        //----------------------------------------------------
        //                    All Mock Data
        //----------------------------------------------------
    
        // Service Locations
    
    static let mockCustomer:Customer = Customer(
        id: UUID().uuidString,
        firstName: "Jane",
        lastName: "Doe",
        email: "JD2000@gmail.com",
        billingAddress: Address(
            streetAddress: "One Apple Park Way",
            city: "Cupertino",
            state: "CA",
            zip: "95014",
            latitude: 37.332279,
            longitude: -122.010979
        ),
        phoneNumber: "",
        phoneLabel: "",
        active: true,
        company: "",
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        tags: [] ,
        linkedInviteId: UUID().uuidString
    )
    static let mockCustomerList:[Customer] =  [
        
        Customer(
            id: "1",
            firstName: "Aphrodite",
            lastName: "Love, Sex and Beauty",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "2",
            firstName: "Athena",
            lastName: "Reason, Wisdom and War",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "3",
            firstName: "Artemis",
            lastName: "Hunt",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "4",
            firstName: "Aries",
            lastName: "Bloodlust and War",
            email: "HotSex@hotmail.com",
            billingAddress: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            phoneNumber: "Aphrodite",
            phoneLabel: "619-555-6969",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "5",
            firstName: "Apollo",
            lastName: "Son of Zeus",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "6",
            firstName: "Demeter",
            lastName: "Agriculture",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "7",
            firstName: "Dionysus",
            lastName: "Drunken Wine",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "8",
            firstName: "Hades",
            lastName: "Ruler of the Underworld",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "9",
            firstName: "Hera",
            lastName: "Hearth",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "10",
            firstName: "Poseidon",
            lastName: "Ocean, Horses and Earthquakes",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        ),
        
        Customer(
            id: "11",
            firstName: "Zeus",
            lastName: "King of the Gods",
            email: "Genius@gmail.com",
            billingAddress: Address(
                streetAddress: "Temple of Athena Nike",
                city: "Dionysiou Areopagitou",
                state: "Athina 105 58",
                zip: "Greece",
                latitude: 37.9716,
                longitude: 23.7249
            ),
            phoneNumber: "Athena",
            phoneLabel: "619-555-0180",
            active: true,
            company: "",
            displayAsCompany: false,
            hireDate: Date(),
            billingNotes: "",
            linkedInviteId: UUID().uuidString
        )
    ]
    
    static let mockServiceLocation:ServiceLocation = ServiceLocation(
        id: "1",
        nickName: "Main",
        address: Address(
            streetAddress: "Akti Sachtouri 10",
            city: "Rhodes",
            state: "Greece",
            zip: "851 31",
            latitude: 36.44591,
            longitude: 28.22736
        ),
        gateCode: "",
        dogName: nil,
        estimatedTime: 15,
        mainContact: Contact(
            id: "1",
            name: "Aphrodite",
            phoneNumber: "619-555-6969",
            email: "HotSex@hotmail.com"
        ),
        notes: "",
        bodiesOfWaterId: ["1"],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "1",
        customerName: "Aphrodite",
        backYardTree: [],
        backYardBushes: [],
        backYardOther: [],
        preText: false
    )
    static let mockServiceLocations:[ServiceLocation] = [
        ServiceLocation(
            id: "1",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Aphrodite",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "1",
            customerName: "Aphrodite",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "2",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Athena",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "2",
            customerName: "Athena",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "3",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Artemis",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "3",
            customerName: "Artemis",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "4",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Aries",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "4",
            customerName: "Aries",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "5",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Apollo",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "5",
            customerName: "Apollo",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "6",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Demeter",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "6",
            customerName: "Demeter",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "7",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Dionysus",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "7",
            customerName: "Dionysus",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "8",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Hades",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "8",
            customerName: "Hades",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "9",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Hera",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "9",
            customerName: "Hera",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "10",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Poseidon",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "10",
            customerName: "Poseidon",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        ),
        
        ServiceLocation(
            id: "11",
            nickName: "Main",
            address: Address(
                streetAddress: "Akti Sachtouri 10",
                city: "Rhodes",
                state: "Greece",
                zip: "851 31",
                latitude: 36.44591,
                longitude: 28.22736
            ),
            gateCode: "",
            dogName: nil,
            estimatedTime: 15,
            mainContact: Contact(
                id: "1",
                name: "Zeus",
                phoneNumber: "619-555-6969",
                email: "HotSex@hotmail.com"
            ),
            notes: "",
            bodiesOfWaterId: ["1"],
            rateType: "",
            laborType: "",
            chemicalCost: "",
            laborCost: "",
            rate: "",
            customerId: "11",
            customerName: "Zeus",
            backYardTree: [],
            backYardBushes: [],
            backYardOther: [],
            preText: false
        )
    ]
    let mockServiceStops:[ServiceStop] = []
    
    static let mockRecurringServiceStop:RecurringServiceStop = RecurringServiceStop(
        id: "",
        internalId: "",
        type: "",
        typeId: "",
        typeImage: "",
        customerName: "",
        customerId: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        tech: "",
        techId: "",
        dateCreated: Date(),
        startDate: Date(),
        endDate: Date(),
        noEndDate: false,
        frequency: .biWeekly,
        daysOfWeek: "",
        description: "",
        lastCreated: Date(),
        serviceLocationId: "",
        estimatedTime: "",
        otherCompany: false
    )
    static let mockCompany:Company = Company(
        id: UUID().uuidString,
        ownerId: UUID().uuidString,
        ownerName: "Michael Angelo",
        name: "Angelo Arts",
        photoUrl: "",
        dateCreated: Date(),
        email: "DaVinciSucks@gmail.com",
        phoneNumber: "6195556969",
        verified: false,
        serviceZipCodes: [],
        services: []
    )
    static let mockAssociatedBusiness : AssociatedBusiness = AssociatedBusiness(
        id: UUID().uuidString,
        companyId: UUID().uuidString,
        companyName: "Mock Company Name"
    )
    static let mockServicestop: ServiceStop = ServiceStop(
        id: "",
        internalId: "",
        companyId: "",
        companyName: "",
        customerId: "",
        customerName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        dateCreated: Date(),
        serviceDate: Date(),
        startTime: Date(),
        endTime: Date(),
        duration: 0,
        estimatedDuration: 0,
        tech: "",
        techId: "",
        recurringServiceStopId: "",
        description: "",
        serviceLocationId: "",
        typeId: "",
        type: "",
        typeImage: "",
        jobId: "",
        jobName: "",
        operationStatus: .finished,
        billingStatus: .notInvoiced,
        includeReadings: true,
        includeDosages: true,
        otherCompany: false,
        laborContractId: "",
        contractedCompanyId: "",
        isInvoiced: false
    )
    static let mockVehical : Vehical = Vehical(
        id: UUID().uuidString,
        nickName: "Betsy",
        vehicalType: .truck,
        year: "2019",
        make: "Toyota",
        model: "Tundra",
        color: "White",
        plate: "7FKHNUD",
        datePurchased: Date(),
        miles: 2234654,
        status: .active
    )
    
    static let mockFleet : [Vehical] = [
        Vehical(
            id: UUID().uuidString,
            nickName: "Betsy",
            vehicalType: .truck,
            year: "2019",
            make: "Toyota",
            model: "Tundra",
            color: "White",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 2234654,
            status: .active
        ),
        Vehical(
            id: UUID().uuidString,
            nickName: "jordan",
            vehicalType: .truck,
            year: "1994",
            make: "Toyota",
            model: "Pick Up",
            color: "Red",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 245654,
            status: .active
        ),
        Vehical(
            id: UUID().uuidString,
            nickName: "Green",
            vehicalType: .truck,
            year: "2013",
            make: "Nissan",
            model: "Datsun",
            color: "Green",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 34566,
            status: .active
        ),
        Vehical(
            id: UUID().uuidString,
            nickName: "Blue",
            vehicalType: .truck,
            year: "2000",
            make: "Nissan",
            model: "Frontier",
            color: "Blue",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 35463456,
            status: .active
        ),
        Vehical(
            id: UUID().uuidString,
            nickName: "White",
            vehicalType: .truck,
            year: "2020",
            make: "Toyota",
            model: "Tacoma",
            color: "White",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 356346,
            status: .active
        ),
        Vehical(
            id: UUID().uuidString,
            nickName: "Black",
            vehicalType: .van,
            year: "2004",
            make: "Ford",
            model: "Ranger",
            color: "Black",
            plate: "7FKHNUD",
            datePurchased: Date(),
            miles: 3456456,
            status: .active
        )
    ]
    static let mockLaborContract: LaborContract =
    LaborContract(
        id: UUID().uuidString,
        senderName: "Sender Name",
        senderId: UUID().uuidString,
        senderAcceptance: false,
        receiverName: "Receiver Name",
        receiverId: UUID().uuidString,
        receiverAcceptance: false,
        type: .businessToBusiness,
        dateSent: Date(),
        lastDateToAccept: Date(),
        dateAccepted: Date(),
        status: .accepted,
        terms: [
            
        ],
        notes: "Notes",
        rate: 0,
        senderJobId: IdInfo(
            id: UUID().uuidString,
            internalId: "J123"
        ),
        customerId: UUID().uuidString,
        customerName: "Customer Name",
        serviceLocationId: UUID().uuidString,
        serviceLocationName: "Location Name",
        jobTemplateId: UUID().uuidString,
        jobTemplateName: "Job Template Name",
        isInvoiced: true
    )

    static let mockLaborContracts: [LaborContract] = [
        LaborContract(
            id: UUID().uuidString,
            senderName: "Sender Name",
            senderId: UUID().uuidString,
            senderAcceptance: false,
            receiverName: "Receiver Name",
            receiverId: UUID().uuidString,
            receiverAcceptance: false,
            type: .businessToBusiness,
            dateSent: Date(),
            lastDateToAccept: Date(),
            dateAccepted: Date(),
            status: .accepted,
            terms: [
                
            ],
            notes: "Notes",
            rate: 0,
            senderJobId: IdInfo(
                id: UUID().uuidString,
                internalId: "J123"
            ),
            customerId: UUID().uuidString,
            customerName: "Customer Name",
            serviceLocationId: UUID().uuidString,
            serviceLocationName: "Location Name",
            jobTemplateId: UUID().uuidString,
            jobTemplateName: "Job Template Name",
            isInvoiced: true
        ),
        
        LaborContract(
            id: UUID().uuidString,
            senderName: "Sender Name",
            senderId: UUID().uuidString,
            senderAcceptance: false,
            receiverName: "Receiver Name",
            receiverId: UUID().uuidString,
            receiverAcceptance: false,
            type: .businessToBusiness,
            dateSent: Date(),
            lastDateToAccept: Date(),
            dateAccepted: Date(),
            status: .accepted,
            terms: [
                
            ],
            notes: "Notes",
            rate: 0,
            senderJobId: IdInfo(
                id: UUID().uuidString,
                internalId: "J123"
            ),
            customerId: UUID().uuidString,
            customerName: "Customer Name",
            serviceLocationId: UUID().uuidString,
            serviceLocationName: "Location Name",
            jobTemplateId: UUID().uuidString,
            jobTemplateName: "Job Template Name",
            isInvoiced: true
        )
    ]
    
    static let mockRecurringLaborContracts : [ReccuringLaborContract] = [
        ReccuringLaborContract(
            id: UUID().uuidString,
            senderName: "Murdock Pool Service",
            senderId: UUID().uuidString,
            senderAcceptance: true,
            receiverName: "Michael Espineli",
            receiverId: UUID().uuidString,
            receiverAcceptance: false,
            dateSent: Date(), 
            lastDateToAccept: Date(),
            startDate: Date(),
            endDate: Date(),
            status: .accepted,
            isActive: true,
            terms:[],
            notes: "Notes",
            atWill:false
        )
        ,
        
        ReccuringLaborContract(
            id: UUID().uuidString,
            senderName: "Murdock Pool Service",
            senderId: UUID().uuidString,
            senderAcceptance: true,
            receiverName: "Michael Espineli",
            receiverId: UUID().uuidString,
            receiverAcceptance: false,
            dateSent: Date(),
            lastDateToAccept: Date(),
            startDate: Date(),
            endDate: Date(),
            status: .accepted,
            isActive: true,
            terms:[],
            notes: "Notes",
            atWill:false
        )
        ,
        
        ReccuringLaborContract(
            id: UUID().uuidString,
            senderName: "Murdock Pool Service",
            senderId: UUID().uuidString,
            senderAcceptance: true,
            receiverName: "Michael Espineli",
            receiverId: UUID().uuidString,
            receiverAcceptance: false,
            dateSent: Date(),
            lastDateToAccept: Date(),
            startDate: Date(),
            endDate: Date(),
            status: .accepted,
            isActive: true,
            terms:[],
            notes: "Notes",
            atWill:false
        )
    ]
    static let mockPerformaceHistory : [PerformaceHistory] = [
        PerformaceHistory(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            userName: "John Doe",
            date: Date(),
            description: "Description",
            photoUrls: [],
            performaceHistoryType: .kudo
        ),
        PerformaceHistory(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            userName: "John Doe",
            date: Date(),
            description: "Description",
            photoUrls: [],
            performaceHistoryType: .kudo
        ),
        PerformaceHistory(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            userName: "John Doe",
            date: Date(),
            description: "Description",
            photoUrls: [],
            performaceHistoryType: .complaint
        ),
        PerformaceHistory(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            userName: "John Doe",
            date: Date(),
            description: "Description",
            photoUrls: [],
            performaceHistoryType: .complaint
        )
    ]
    static let mockShoppingListItem : ShoppingListItem = ShoppingListItem(
        id: UUID().uuidString,
        category: .customer,
        subCategory: .chemical,
        status: .installed,
        purchaserId: "",
        purchaserName: "",
        genericItemId: "",
        name: "",
        description: "",
        datePurchased: Date(),
        quantiy: "",
        jobId: "",
        customerId: "",
        customerName: "",
        userId: "",
        userName: ""
    )
    static let mockLaborContractRecurringWork : [LaborContractRecurringWork] = [
        LaborContractRecurringWork(
            id: UUID().uuidString,
            customerId: UUID().uuidString,
            customerName: "Customer Name 1",
            serviceLocationId: UUID().uuidString,
            serviceLocationName: "Location Name 1",
            jobTemplateId: UUID().uuidString,
            jobTemplateName: "Tempalte Name 1",
            rate: 1500,
            laborType: .job,
            frequency: .weekly,
            timesPerFrequency: 1,
            timesPerFrequencySetUp: 1,
            routeSetUp: true,
            recurringServiceStopIdList: [],
            isActive: true,
            lastBilled: Date()
        )
        ,
        LaborContractRecurringWork(
            id: UUID().uuidString,
            customerId: UUID().uuidString,
            customerName: "Customer Name 2",
            serviceLocationId: UUID().uuidString,
            serviceLocationName: "Location Name 2",
            jobTemplateId: UUID().uuidString,
            jobTemplateName: "Tempalte Name 2",
            rate: 1500,
            laborType: .job,
            frequency: .weekly,
            timesPerFrequency: 1,
            timesPerFrequencySetUp: 1,
            routeSetUp: true,
            recurringServiceStopIdList: [],
            isActive: true,
            lastBilled: Date()
        )
        ,
        LaborContractRecurringWork(
            id: UUID().uuidString,
            customerId: UUID().uuidString,
            customerName: "Customer Name 3",
            serviceLocationId: UUID().uuidString,
            serviceLocationName: "Location Name 3",
            jobTemplateId: UUID().uuidString,
            jobTemplateName: "Tempalte Name 3",
            rate: 1500,
            laborType: .job,
            frequency: .weekly,
            timesPerFrequency: 1,
            timesPerFrequencySetUp: 1,
            routeSetUp: true,
            recurringServiceStopIdList: [],
            isActive: true,
            lastBilled: Date()
        )
        
    ]
}
