//
//  ProductionDataServiceProtocol.swift
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

protocol ProductionDataServiceProtocol: Equatable {
    var id:String { get }

    func updateRepairRequestPhotoURLs(companyId: String, repairRequest: String, photoUrls: [DripDropStoredImage]) async throws

    func uploadServiceStopImage(companyId: String,serviceStopId:String, image: DripDropImage) async throws ->(path:String, name:String)
    func updateServiceStopPhotoURLs(companyId: String, serviceStopId: String, photoUrls: [DripDropStoredImage]) async throws

    func modifyRecurringServiceStopToNew(
        companyId:String,
        recurringServiceStop:RecurringServiceStop,
        customFrequencyType:String,
        CustomFrequency:String,
        daysOfWeek:[String],
        oldRss:RecurringServiceStop,
        old:[ServiceStop]
    ) async throws ->(String?)
    func updateBodyOfWaterPhotoURLs(companyId: String, bodyOfWaterId: String, photoUrls: [DripDropStoredImage]) async throws
    func updateBodyOfWaterLastFilledDate(companyId: String, bodyOfWaterId: String, lastFilled: Date) async throws
    func updateServiceLocationPhotoURLs(companyId: String, serviceLocationId: String, photoUrls: [DripDropStoredImage]) async throws
    func addPersonalAlert(userId:String,dripDropAlert:DripDropAlert) async throws
    func getPersonalAlertsCount(userId:String) async throws -> Int
    func getPersonalAlerts(userId:String) async throws -> [DripDropAlert]
    
    func addDripDropAlert(companyId:String,dripDropAlert:DripDropAlert) async throws
    func getDripDropAlerts(companyId:String) async throws -> [DripDropAlert]
    func getDripDropAlertsCount(companyId:String) async throws -> Int
    func uploadServiceLocationImage(companyId: String,serviceLocationId:String, image: DripDropImage) async throws ->(path:String, name:String)

    
    func addTermsTemplate(companyId:String,termsTemplate:TermsTemplate) async throws
    func addTermsToTermsTemplate(companyId:String,termsTemplateId:String,terms:ContractTerms) async throws
    
    func createNewJobPost(jobPost:JobPost) async throws

    func addLaborContract(companyId:String,laborContract:ReccuringLaborContract) async throws
    func getLaborContracts(companyId:String) async throws -> [ReccuringLaborContract]
    func getReceivedLaborContracts(companyId:String) async throws -> [ReccuringLaborContract] 
    func getSentLaborContracts(companyId:String) async throws -> [ReccuringLaborContract]
    func getSentLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract] 
    func getLaborContractsByStatus(companyId:String,status:LaborContractStatus) async throws -> [ReccuringLaborContract]
    func getUniversalEquipmentTypes() async throws -> [UniversalEquipmentType]
    func getUniversalEquipmentBrandsByType(type:UniversalEquipmentType) async throws -> [UniversalEquipmentMake]
    func getUniversalEquipmentByTypeAndBrand(type:UniversalEquipmentType,make:UniversalEquipmentMake) async throws -> [UniversalEquipment]
    func getUniversalEquipmentPartsEquipment(equipmentId:String) async throws -> [UniversalPart] 
    func getLaborContractsSnapShot(companyId:String) async throws -> [ReccuringLaborContract]
    func getLaborContractsByAssociatedBusinessIsActive(companyId:String,associatedBusinessCompanyId:String,isActive:Bool) async throws -> [ReccuringLaborContract]
    func getLaborContractsByAssociatedBusiness(companyId:String,associatedBusinessCompanyId:String) async throws -> [ReccuringLaborContract]
    func getLaborContract(companyId:String,laborContractId:String) async throws -> ReccuringLaborContract
    
    func getLaborContractsSentCountByStatus(companyId:String,status:LaborContractStatus) async throws -> Int
    func getLaborContractsReceivedCountByStatus(companyId:String,status:LaborContractStatus) async throws -> Int
    func getLaborContractsTotal(companyId:String) async throws -> Double
    func updateLaborContractIsActive(contractId:String,isActive:Bool)  async throws
    func addLaborContractRecurringWork(companyId:String,laborContractId:String,laborContractRecurringWork:LaborContractRecurringWork) async throws
    func getLaborContractRecurringWork(companyId:String,laborContractId:String,recurringWorkId:String) async throws -> LaborContractRecurringWork
    func getLaborContractRecurringWorkList(companyId:String,laborContractId:String) async throws -> [LaborContractRecurringWork]
    
    func updateLaborContractRecurringWorkLastBilled(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, lastBilled: Date) async throws
    func updateLaborContractRecurringWorkIsActive(companyId: String, laborContractId: String, laborContractRecurringWorkId: String, isActive: Bool) async throws
    func updateLaborContractRecurringWorkRate(companyId:String,laborContractId:String,laborContractRecurringWorkId:String,rate:Double) async throws
    func updateLaborContractRecurringWorkRateRateSheetLaborType(companyId:String,laborContractId:String,laborContractRecurringWorkId:String,laborType:RateSheetLaborType) async throws
    func updateLaborContractRecurringWorkRateLaborContractFrequency(companyId:String,laborContractId:String,laborContractRecurringWorkId:String,frequency:LaborContractFrequency) async throws
    func updateLaborContractRecurringWorkSetUpRoute(companyId:String,laborContractId:String,laborContractRecurringWorkId:String,setUpRoute:Bool) async throws

    func getTermsTemplate(companyId:String,termsTemplateId:String) async throws -> TermsTemplate
    func getTermsTemplateList(companyId:String) async throws -> [TermsTemplate]
    func getTermsTemplateListByCategory(companyId:String,category:String) async throws -> [TermsTemplate]
    func getTermsByTermsTemplate(companyId:String,termsTemplateId:String)  async throws -> [ContractTerms]
    func updateLaborContractAsAcceptedByReceiver(companyId:String,contractId:String,accepted:Bool)  async throws
    func updateLaborContractIsInvoiced(companyId:String, contractId:String, isInvoiced:Bool)  async throws
    func updateLaborContractInvoiceRef(companyId:String, contractId:String, invoiceInfo:IdInfo)  async throws
    func deleteRecurringLaborContract(companyId:String,contractId:String) async throws
    func deleteLaborContract(contractId:String) async throws

    func updateLaborContractAsAcceptedBySender(companyId:String,contractId:String,accepted:Bool)  async throws

    func editTermsTemplateName(companyId:String,termsTemplateId:String,termsTemplateName:String) async throws
    
    func deleteTermsTemplate(companyId:String,termsTemplateId:String) async throws
    func deleteTerms(companyId:String,termsTemplateId:String,termsId:String) async throws
    
    
    func updateOneTimeLaborContractAsAcceptedByReceiver(contractId:String,accepted:Bool)  async throws
    func updateOneTimeLaborContractAsAcceptedBySender(contractId:String,accepted:Bool)  async throws
    func updateInstallationJobParts(companyId:String,jobId:String,installationPart:WODBItem) async throws
    
    func updatePVCobParts(companyId:String,jobId:String,pvc:WODBItem) async throws
    func updateElectricalJobParts(companyId:String,jobId:String,electical:WODBItem) async throws
    
    func updateChemicalsJobParts(companyId:String,jobId:String,chemical:WODBItem) async throws
    
    func updateMiscJobParts(companyId:String,jobId:String,misc:WODBItem) async throws
    func createNewEquipmentMeasurements(companyId:String,equipmentId:String,equipmentMeasurement:EquipmentMeasurements) async throws
    func getRecentEquipmentMeasurments(companyId:String,equipmentId:String,amount:Int) async throws -> [EquipmentMeasurements]
    
    
    func deleteCustomerContact(companyId:String,customerId:String,contactId:String)async throws
    func uploadCustomerContact(companyId:String,customerId:String,contact:Contact) async throws
    func getCustomerContactById(companyId:String,customerId : String,contactId:String) async throws -> Contact
    func getAllContactsByCustomer(companyId:String,customerId:String) async throws -> [Contact]
    //----------------------------------------------------
    //                    CREATE Functions
    //----------------------------------------------------
    func createInvoice(stripeInvoice:StripeInvoice) async throws
    func addNewToDo(companyId:String, todo:ToDo) async throws
    func loadCurrentUser() async throws -> DBUser
    func createNewUser(user:DBUser) async throws
    func createFirstCompanyUser(user:DBUser) async throws
    func createNewRecentActivity(userId:String,recentActivity:RecentActivityModel) async throws
    func updateCompanyUser(user:DBUser,updatingUser:DBUser) throws
    func updateCompanyUserRole(companyId:String,companyUserId:String,roleId:String,roleName:String) async throws
    func updateCompanyUserWorkerType(companyId:String,companyUserId:String,workerType:WorkerTypeEnum) async throws
    func addNewVehical(companyId:String,vehical:Vehical) async throws

    func uploadUserAccess(userId : String,companyId:String,userAccess:UserAccess) async throws
    func addCompanyUser(companyId:String,companyUser:CompanyUser) async throws
    func addNewRateSheet(companyId:String,companyUserId:String,rateSheet:RateSheet) async throws
    func uploadPurchaseItem(companyId: String,purchaseItem : PurchasedItem) async throws
    func uploadingCustomerMonthlySummary(companyId:String,customer:Customer,customerMonthlySummary:CustomerMonthlySummary) async throws
    func uploadCSVCustomerToFireStore(companyId:String,customer: CSVCustomer) async throws
    func uploadCustomerServiceLocations(companyId:String,customer:Customer,serviceLocation:ServiceLocation) async throws
    func uploadServiceLocationBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws
    func uploadBodyOfWaterByServiceLocation(companyId:String,bodyOfWater:BodyOfWater) async throws
    func uploadEquipment(companyId:String,equipment:Equipment) async throws
    func addNewEquipmentWithParts(companyId: String,equipment:Equipment) async throws
    func addPartsToEquipment(companyId: String,equipment:Equipment) async throws
    func uploadEquipmentPart(companyId:String,equipmentId:String,part:EquipmentPart) async throws
    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws
    func uploadRole(companyId:String,role : Role) async throws
    func uploadCompany(company : Company) async throws
    func addStoreItemsToGeneriItem(companyId: String,genericItem:GenericItem,storeItem:DataBaseItem) async throws
    func addNewShoppingListItem(companyId: String, shoppingListItem: ShoppingListItem) async throws
    func createDataBaseItem(companyId:String,genericItem : GenericItem) async throws
    func createIntialGenericDataBaseItems(companyId:String) async throws
    func uploadStore(companyId:String,store : Vender) async throws
    func uploadChat(userId:String,chat:Chat) async throws
    func sendMessage(userId: String, message: Message) async throws
    func uploadRepairRequest(companyId:String,repairRequest:RepairRequest) async throws
    func uploadGenericItem(companyId:String,workOrderTemplate : GenericItem) async throws
    func uploadWorkOrderTemplate(companyId:String,workOrderTemplate : JobTemplate) async throws
    func uploadServiceStopTemplate(companyId:String,template : ServiceStopTemplate) async throws
    
        //Developer  I Need to change to Saving New Saved Readings Template
    func uploadReadingTemplate(readingTemplate : SavedReadingsTemplate,companyId:String) async throws
        //Developer  I Need to change to Saving New Saved Dosage Template

    func uploadDosageTemplate(dosageTemplate : SavedDosageTemplate,companyId:String) async throws
    
    func upLoadStartingCompanySettings(companyId:String) async throws
    func upLoadInitialGenericRoles(companyId:String) async throws
    func upLoadIntialWorkOrdersAndReadingsAndDosages(companyId:String) async throws->[TrainingTemplate]
    func upLoadReadingTemplates(companyId:String) async throws
    func uploadDosageTemplates(companyId:String) async throws
    func uploadBillingTemplate(billingTempalte : BillingTemplate,companyId:String) async throws
    func uploadGenericBillingTempaltes(companyId:String) async throws
    func uploadSingleTraining(training : Training,companyId: String,techId:String) async throws
    func uploadSingleTrainingTemplate(trainingTemplate : TrainingTemplate,companyId: String) async throws
    func uploadGenericTraingTempaltes(companyId: String,templateList:[TrainingTemplate]) async throws
    func uploadInvite(invite : Invite) async throws
    func uploadReadingToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws
    func uploadDosagesToServiceStop(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws
    func uploadReadingAndDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws
    func uploadReadingToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws
    func uploadDosagesToCustomerHistory(companyId:String,serviceStop : ServiceStop,stopData:StopData) async throws
    func addStopHistory(serviceStop:ServiceStop,stopData:StopData,companyId:String) async throws
    
    func uploadDataBaseItem(companyId:String,dataBaseItem : DataBaseItem) async throws
    func uploadDataBaseItemWithUser(dataBaseItem : DataBaseItem,companyId:String) async throws
    func uploadCSVDataBaseItemToFireStore(companyId:String,CSVItem: CSVDataBaseItem,storeId:String,storeName:String) async throws
    func uploadReceipt(companyId: String,receiptItem : Receipt) async throws
    
    func uploadRecurringServiceStop(companyId:String,recurringServiceStop : RecurringServiceStop) async throws
    func uploadRoute(companyId:String,recurringRoute:RecurringRoute) async throws
    func addNewRecurringServiceStop(companyId:String,recurringServiceStop:RecurringServiceStop) async throws ->(String?)
    func addNewRecurringServiceStopFromLaborContract(companyId:String,recurringServiceStop:RecurringServiceStop,laborContract:ReccuringLaborContract) async throws ->(String?)

    func helpCreateDailyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                       noEndDate:Bool,startDate:Date,endDate:Date) async throws
    //WeekDay
    func helpCreateWeekDayRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async throws
    //Weeekly
    func helpCreateWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        noEndDate:Bool,startDate:Date,endDate:Date) async throws
    //Bi Weekly
    func helpCreateBiWeeklyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                          noEndDate:Bool,startDate:Date,endDate:Date) async throws
    //Monthly
    func helpCreateMonthlyRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                         noEndDate:Bool,startDate:Date,endDate:Date) async throws
    //Custom
    func helpCreateCustomRecurringRoute(companyId:String,recurringServiceStop:RecurringServiceStop,
                                        standardFrequencyNumber:Int,
                                        customFrequencyType:String,
                                        CustomFrequency:String,
                                        daysOfWeek:[String])
    func uploadWorkOrder(companyId:String,workOrder : Job) async throws
    func addPurchaseItemsToInstallationWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws
    func addPurchaseItemsToWorkOrder(workOrder:Job,companyId: String,ids:[String])async throws
    func uploadStopData(companyId:String,stopData:StopData) async throws
    func uploadContact(companyId:String,contract:RecurringContract) async throws
    func uploadRoute(companyId: String,activeRoute:ActiveRoute) async throws 
    
    func uploadBodyOfWaterImage(companyId:String,bodyOfWaterId:String,image:DripDropImage) async throws ->(path:String, name:String)
    func uploadEquipmentImage(companyId:String,equipmentId:String,image:DripDropImage) async throws ->(path:String, name:String)
    func saveAssociatedBusinessToCompany(companyId:String,business:AssociatedBusiness) async throws
    func upLoadInitialEmailSettings(companyId:String) async throws
    func createCustomerEmailConfiguration(companyId:String,customerEmailConfig:CustomerEmailConfiguration) async throws
    func uploadJobTask(companyId:String,jobId:String,task:JobTask) async throws
    func uploadServiceStopTask(companyId:String,serviceStopId:String,task:ServiceStopTask) async throws 
    //----------------------------------------------------
    //                    Read Functions
    //----------------------------------------------------
    
    func getJobTasks(companyId:String,jobId:String) async throws -> [JobTask]
    func getServiceStopTasks(companyId:String,serviceStopId:String) async throws -> [ServiceStopTask]
    func getLaborContractTasks(companyId:String,laborContractId:String) async throws -> [LaborContractTask]

    
    
    
    func searchForUsers(searchTerm:String) async throws -> [DBUser]
    func getAllCompanyToDoItems(companyId:String) -> [ToDo]
    func getAllCompanyToDoItemsCount(companyId: String) -> Int
    func getAllTechnicanToDoItemsCount(companyId: String, techId: String) async throws -> Int
    func getAllTechnicanToDoItems(companyId:String,techId:String) async throws -> [ToDo]
    func getCurrentUser(userId:String) async throws -> DBUser
    func getRecentActivityByUser(userId:String) async throws -> [RecentActivityModel]
        func getOneUser(userId:String) async throws -> DBUser

    //for some reason this does not work
    func getAllTechs() async throws ->[DBUser]
    func getAllCompayTechs(companyId:String) async throws ->[DBUser]
    func getCurrentTechs(id:String) async throws ->[DBUser]
    func checkUserAccessBy(userId:String,companyId:String) async throws
    func getAllUserAvailableCompanies(userId:String) async throws ->[UserAccess]
    func getUserAccessCompanies(userId:String,companyId:String) async throws ->UserAccess
    func getCompanyUserById(companyId:String,companyUserId:String) async throws -> CompanyUser
    func getCompanyUserByDBUserId(companyId:String,userId:String) async throws -> CompanyUser
    func getAllRateSheetByCompanyUserId(companyId: String, companyUserId: String) async throws -> [RateSheet]
    func getAllCompanyUsers(companyId:String) async throws -> [CompanyUser]
    func getAllCompanyUsersByStatus(companyId:String,status:String) async throws -> [CompanyUser]
    func getNumberOfItemsPurchasedIn30Days(companyId: String) async throws->(total:Double,totalBillable:Double,Invoiced:Double,TotalSpent:Double,totalSoldInDollars:Double,TotalSpentBillable:Double,TotalBilled:Double,NonBillableList:[PurchasedItem])
    func getNumberOfItemsPurchasedAndBilledIn30Days(companyId: String) async throws -> Double
    func getPurchasesCountForTechId(companyId:String,userId:String) async throws ->Int
    func GetPurchasesByDateSortByDate(companyId: String,start:Date,end:Date,dateHigh:Bool,techIds:[String]) async throws -> [PurchasedItem]
    func GetPurchasesByDateSortByPrice(companyId: String,start:Date,end:Date,priceHigh:Bool,techIds:[String]) async throws -> [PurchasedItem]
    func GetPurchasesByBillable(companyId: String,billable:Bool) async throws -> [PurchasedItem]
    func GetPurchasesByBillableAndInvoiced(companyId: String,billable:Bool,invoiced:Bool) async throws -> [PurchasedItem]
    func GetPurchasesByBillableAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool, price:Bool,techIds:[String]) async throws -> [PurchasedItem]
    
 
    func GetPurchasesByBillableAndInvoicedAndSortByPrice(companyId: String, start:Date, end:Date, billable:Bool, invoiced:Bool, price:Bool, techIds:[String]) async throws -> [PurchasedItem]
    func GetPurchasesByBillableAndSortByDate(companyId: String, start:Date, end:Date, billable:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem]
    func GetPurchasesByBillableAndInvoicedAndSortByDate(companyId: String, start:Date, end:Date, billable:Bool,invoiced:Bool,date:Bool,techIds:[String]) async throws -> [PurchasedItem]
    func getSingleItem(itemId:String,companyId: String) async throws -> PurchasedItem
    func getItemsBasedOnDBItem(companyId: String,DataBaseItemSku:String) async throws -> [PurchasedItem]
    func getallReceiptsLast30Days(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem]
    func getallReceiptsLast30DaysBillable(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem]
    func getAllBillableReceipts(companyId: String,startDate:Date,endDate:Date,viewBillable:Bool) async throws -> [PurchasedItem]
    func getAllReceiptItems(companyId: String) async throws -> [PurchasedItem]
    func getAllpurchasedItemsByPrice(companyId: String,start:Date,end:Date, descending: Bool,techIds:[String]) async throws -> [PurchasedItem]
    func getAllpurchasedItemsByTech(companyId: String,techId: String) async throws -> [PurchasedItem]
    func getAllpurchasedItemsByVender(companyId: String,venderId:String) async throws -> [PurchasedItem]
    func getAllpurchasedItemsByTechAndDate(companyId: String,techId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem]
    func getAllpurchasedItemsByDate(companyId: String,startDate:Date,endDate:Date) async throws -> [PurchasedItem]

    func getMostRecentPurchases(companyId:String,number:Int) async throws ->[PurchasedItem]
    func getAllCustomerCustomerMonthlySummary(companyId:String,customer:Customer) async throws -> [CustomerMonthlySummary]
    func getMonthlySummaryByCustomerAndMonth(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary]
    func getMonthlySummaryByCustomerAndMonthAndServiceLocation(companyId:String,customer:Customer,month:Date,serviceLocationId:String) async throws -> [CustomerMonthlySummary]
    func getSummaryOfLastYear(companyId:String,customer:Customer,month:Date) async throws -> [CustomerMonthlySummary]
    func checkCustomerCount(companyId:String) async throws -> Int
    func GetCustomersByHireDate(companyId:String,DurationHigh:Bool) async throws -> [Customer]
    func GetCustomersByLastName(companyId:String,LastNameHigh:Bool) async throws -> [Customer]
    func GetCustomersByFirstName(companyId:String,FirstNameHigh:Bool) async throws -> [Customer]
    func getCustomersActive(companyId:String,active : Bool) async throws ->[Customer]
    func getCustomersActiveAndHireDate(companyId:String,active : Bool,hireDateHigh:Bool) async throws ->[Customer]
    func getCustomersActiveAndFirstName(companyId:String,active : Bool,firstNameHigh:Bool) async throws ->[Customer]
    func getCustomersActiveAndLastName(companyId:String,active : Bool,lastNameHigh:Bool) async throws ->[Customer]
    func getCustomerById(companyId:String,customerId : String) async throws ->Customer
    func getAllCustomers(companyId:String) async throws -> [Customer]
    func getAllActiveCustomers(companyId:String) async throws -> [Customer]
    func searchForCustomers(companyId:String,searchTerm:String) async throws -> [Customer]
    func getAllCustomersFilteredByRate(companyId:String,descending: Bool) async throws -> [Customer]
    func get25Customers(companyId:String) async throws -> [Customer]
    func getNext25Customers(companyId:String,lastDocument:DocumentSnapshot?) async throws -> (customers: [Customer],lastDocument:DocumentSnapshot?)
    func getMostRecentCustomers(companyId:String,number:Int) async throws ->[Customer]
    func getAllCompanyServiceLocations(companyId:String) async throws -> [ServiceLocation]
    func getAllCustomerServiceLocations(companyId:String) async throws -> [ServiceLocation]
    func get4CustomerServiceLocations(companyId:String,customer:Customer) async throws -> [ServiceLocation]
    func getAllCustomerServiceLocationsId(companyId:String,customerId:String) async throws -> [ServiceLocation]
    func getServiceLocationById(companyId:String,locationId:String) async throws -> ServiceLocation
    func getAllBodiesOfWaterByServiceLocationIdAndCustomerId(serviceLocationId:String,customerId:String,companyId:String) async throws -> [BodyOfWater]
    func getAllBodiesOfWater(companyId:String) async throws -> [BodyOfWater]
    func getAllBodiesOfWaterByServiceLocation(companyId:String,serviceLocation:ServiceLocation) async throws -> [BodyOfWater]
    func getAllBodiesOfWaterByServiceLocationId(companyId:String,serviceLocationId:String) async throws -> [BodyOfWater]
    func getBodiesOfWaterCount(serviceLocationId:String,customerId:String,companyId:String) async throws -> Int
    func getSpecificBodyOfWater(companyId: String,bodyOfWaterId:String) async throws -> BodyOfWater
    func getAllEquipmentCount(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (equipmentList:[Equipment],lastDocument:DocumentSnapshot?)
    func getEquipmentSnapShot(companyId:String) async throws -> [Equipment]
    func getAllEquipment(companyId:String) async throws -> [Equipment]
    func getEquipmentByBodyOfWater(companyId:String,bodyOfWater:BodyOfWater) async throws -> [Equipment]
    
    func getSinglePieceOfEquipment(companyId:String,equipmentId:String) async throws ->Equipment
    
    func getEquipmentByBodyOfWaterId(companyId:String,bodyOfWaterId:String) async throws ->[Equipment]
    func getEquipmentByServiceLocationId(companyId:String,serviceLocationId:String) async throws ->[Equipment]
    func getEquipmentByServiceLocationIdAndCategory(companyId:String,serviceLocationId:String,category:EquipmentCategory) async throws ->[Equipment]

    
    func getPartsUnderEquipment(companyId:String,equipmentId:String) async throws ->[EquipmentPart]
    func getHistoryServiceStopsBy(companyId:String,serviceStop: ServiceStop) async throws -> [History]
    func getBillableServiceStopsByDate(startDate: Date,endDate:Date,companyId:String) async throws -> [ServiceStop]
    func getServiceStopById(serviceStopId:String,companyId:String) async throws -> ServiceStop
    func getAllServiceStops(companyId:String) async throws -> [ServiceStop]
    func getAllServiceStopsByCustoer(companyId: String,customerId:String,startDate:Date,endDate:Date) async throws -> [ServiceStop]
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:DBUser) async throws -> [ServiceStop]
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ServiceStop]

    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int
    
    //Get Service Stop
    func getServiceStopByServiceLocationId(companyId:String, serviceLocationId:String) async throws -> [ServiceStop]
    func getServiceStopByJobId(companyId:String,jobId:String) async throws -> [ServiceStop]
    func getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: String,recurringServiceStopId:String,date:Date) async throws -> [ServiceStop]
    func getAllServiceStopsSortedByRecurringServiceStops(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]
    func getAllServiceStopsByRecurringServiceStopsAfterToday(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]
    func getAllServiceStopsSortedByPrice(companyId:String,descending: Bool) async throws -> [ServiceStop]
    func getAllServiceStopsByDate(companyId:String,date: Date) async throws -> [ServiceStop]
    func getAllServiceStopsSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [ServiceStop]
    func getAllServiceStopsBetweenDate(companyId:String,startDate: Date,endDate:Date) async throws -> [ServiceStop]
    func getAllServiceStopsBetweenDateByUserId(companyId:String,startDate: Date,endDate:Date,userId:String) async throws -> [ServiceStop]
    func getServiceStopsByRecurringsServiceStop(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]
    func getServiceStopsByRecurringsServiceStopNotFinished(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]
    func getUnfinishedServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]
    func getUnfinished4ServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]
    func getServiceStopsBetweenDatesAndByCustomer(companyId:String,startDate: Date,endDate:Date,customer:Customer) async throws -> [ServiceStop]
    func getServiceStopsBetweenDatesAndByType(companyId:String,startDate: Date,endDate:Date,workOrderType:String) async throws -> [ServiceStop]
    func getAllUnfinishedServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]
    func getAllServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]
    func getServiceStopBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[ServiceStop],lastDocument:DocumentSnapshot?)
    func getServiceStopsByRecurringsServiceStopBetweenDates(companyId:String,recurringsServicestopId:String,startDate: Date, endDate: Date) async throws -> [ServiceStop]
    func getAllCompanyRoles(companyId : String) async throws ->[Role]
    func getSpecificRole(companyId:String,roleId : String) async throws ->Role
    func getAllCompanies() async throws -> [Company]
    func getCompany(companyId:String) async throws -> Company
    func getSpecificShoppingListItem(companyId: String, shoppingListItemId: String) async throws -> ShoppingListItem
    func getAllShoppingListItemsByCompany(companyId: String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsSnapShotByCompany(companyId: String) async throws -> [ShoppingListItem]

    func getAllShoppingListItemsByCompanyCustomer(companyId: String,customerId: String) async throws -> [ShoppingListItem]

    func getAllShoppingListItemsByUser(companyId: String, userId: String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUserCount(companyId: String, userId: String) async throws -> Int
    func getAllShoppingListItemsByUserForCategory(companyId: String, userId: String,category:String) async throws -> [ShoppingListItem]
    func getAllShoppingListItemsByUserForJob(companyId: String, jobId: String,category:String) async throws -> [ShoppingListItem]

    func getAllGenericDataBaseItems(companyId:String) async throws -> [GenericItem]
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [GenericItem]
    func getDataBaseItem(companyId:String,genericItemId:String) async throws -> GenericItem
    func getGenericItemByIdFromWorkOrderCollection(companyId:String,workOrderItemId:String,workOrderId:String) async throws -> GenericItem
    func getAllStores(companyId:String) async throws -> [Vender]
    func getAllVehicals(companyId:String) async throws -> [Vehical]
    func getAllVehicalsCount(companyId:String) async throws -> Int
    func getAllVenderCount(companyId:String) async throws -> Int
    
    func uploadTaskToLaborContract(laborContractId:String,task:LaborContractTask) async throws
    func getLaborContractTask(laborContractId: String, taskId: String) async throws -> LaborContractTask
    func getLaborContractWork(companyId: String, laborContractId: String) async throws -> [LaborContractTask]
    func uploadLaborContract(laborContractId:String,laborContract:LaborContract) async throws
    
    func updateLaborContractTaskStatus(laborContractId:String,laborContractTaskId:String,status:JobTaskStatus) async throws
    func updateLaborContractTaskJobIsCreated(laborContractId:String,laborContractTaskId:String,jobIsCreated:Bool) async throws
    func updateLaborContractTaskReceiverJobId(laborContractId:String,laborContractTaskId:String,jobIdInfo:IdInfo) async throws
    
    
    func getLaborContract(laborContractId: String) async throws -> LaborContract
    func getLaborContractsBySenderId(senderId: String) async throws -> [LaborContract]
    func getLaborContractsByReceiverId(receiverId: String) async throws -> [LaborContract]
    
    
    func getLaborContractsBySenderReceiverIsInvoiced(senderId: String,receiverId: String,isInvoiced: Bool) async throws -> [LaborContract]
    func getLaborContractsBySenderReceiverIsInvoicedStatus(senderId: String,receiverId: String,isInvoiced: Bool, status:LaborContractStatus) async throws -> [LaborContract]
    
    func getSingleStore(companyId:String,storeId:String) async throws -> Vender
    func getAllChatsByUser(userId:String) async throws -> [Chat]
    func getSpecificChat(chatId:String) async throws ->Chat
    func getChatBySenderAndReceiver(companyId:String,senderId:String,receiverId:String) async throws ->Chat?

    func getChatsByCompany(companyId: String) async throws ->[Chat]
    func getAllMessagesByChat(chatId: String) async throws ->[Message]
    func getNewestMessage(chatId: String) async throws ->Message?

    func getAllRepairRequests(companyId:String) async throws -> [RepairRequest]
    func getSpecificRepairRequest(companyId:String,repairRequestId:String) async throws ->RepairRequest
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws ->[RepairRequest]
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws ->Int?
    func getRepairRequestsByUserCount(companyId: String,userId:String) async throws ->Int?
    func getAllContrats(companyId:String) async throws -> [RecurringContract]
    func getSpecificContract(companyId:String,contractId:String) async throws ->RecurringContract
    func getContractsByCustomer(companyId: String,customerId:String) async throws ->[RecurringContract]
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws ->Int?
    func getRecentServiceStopsByBodyOfWater(companyId:String,bodyOfWaterId: String,amount:Int)async throws->[StopData]
    func getStopDataByServiceStopId(companyId:String,serviceStopId: String) async throws ->[StopData]
    func getStopDataByServiceStopIdAndBodyOfWaterId(companyId:String,serviceStopId: String,bodyOfWaterId:String)async throws->[StopData]
    func getStopDataByCustomer(companyId:String,customerId: String)async throws->[StopData]
    func getStopDataByBodyOfWater(companyId:String,bodyOfWaterId: String)async throws->[StopData]
    func getStopDataByDateRange(companyId:String,startDate: Date,endDate:Date)async throws->[StopData]
    func getHistoryByWorkOrder(workOrder: Job) async throws -> [History]
    
    //Job
    func getBillableWorkOrdersByDate(companyId:String,startDate: Date,endDate:Date) async throws -> [Job]
    func getAllWorkOrders(companyId: String) async throws -> [Job]
    func getAllWorkOrdersFinished(companyId: String,finished:Bool) async throws -> [Job]
    func getAllJobsByCustomer(companyId: String,customerId:String) async throws -> [Job]
    func getAllJobsByUser(companyId: String,userId:String) async throws -> [Job]

    func getRecentWorkOrders(companyId: String) async throws -> [Job]
    
    func getRecentlyFinishedCount(companyId: String) async throws -> Int
    func getAllJobsInProgressCount(companyId: String) async throws -> Int
    func getAllJobsOpenedCount(companyId: String) async throws -> Int

    func getAllWorkOrdersSortedByPrice(companyId:String,descending: Bool) async throws -> [Job]
    func getAllWorkOrdersByDate(companyId:String,date: Date) async throws -> [Job]
    func getAllUnscheduledWorkOrders(companyId: String) async throws -> [Job]
    func getAllWorkOrdersSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [Job]
    func getAllWorkOrdersByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [Job]
    func getWorkOrdersBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[Job],lastDocument:DocumentSnapshot?)
    func getWorkOrderById(companyId: String,workOrderId:String) async throws -> Job
    func getAllPastJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job]
    func getAllFutureJobsBasedOnCustomer(companyId: String, customer: Customer) async throws -> [Job]
    func getSingleRoute(companyId:String,recurringRouteId:String) async throws -> RecurringRoute
    func getSingleRouteFromTechIdAndDay(companyId:String,techId:String,day:String) async throws -> RecurringRoute?
    func getAllActiveRoutes(companyId:String,param:String) async throws -> [RecurringRoute]
    
    func updateEquipmentIsActive(companyId:String,equipmentId:String,isActive:Bool) throws
    func updateEquipmentDateUninstalled(companyId:String,equipmentId:String,dateUninstalled:Date) throws
    func getAllActiveRoutesBasedOnVehical(companyId: String, vehicalId:String, count: Int) async throws -> [ActiveRoute]

    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:DBUser) async throws -> [ActiveRoute]
    func getAllActiveRoutesBasedOnDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ActiveRoute]

    func getActiveRoute(companyId: String,activeRouteId:String) async throws -> ActiveRoute

    func getAllActiveRoutesBasedOnDate(companyId:String,day:String,techId:String) async throws -> [RecurringRoute]
    func getRecurringRouteByDayAndTech(companyId:String,day:String,techId:String) async throws ->[RecurringRoute]
    func getRecurringRouteByDay(companyId:String,day:String) async throws ->[RecurringRoute]
    func getRecurringRouteByDayCount(companyId:String,day:String) async throws ->Int

    func getAllReceipts(companyId: String) async throws -> [Receipt]
    func getReceipt(companyId: String,receiptId:String) async throws -> Receipt

    func getAllpurchasedItemsByPrice(companyId:String,descending: Bool) async throws -> [Receipt]
    func getAllDataBaseItemsByCategory(companyId:String,category:String) async throws -> [DataBaseItem]
    func get25DataBaseItems(companyId:String) async throws -> [DataBaseItem]
    func getAllDataBaseItemsByCompany(companyId:String,storeId:String) async throws -> [DataBaseItem]
    func getItemsFromDataBaseBySearchTermAndStoreId(companyId:String,storeId:String,searchTerm:String) async throws -> [DataBaseItem]
    func getDataBaseItem(companyId:String,dataBaseItemId:String) async throws -> DataBaseItem
    func getDataBaseItemsFromArrayOfIds(companyId:String,dataBaseIds:[String]) async throws -> [DataBaseItem]
    func getallNonBillableTemplates(companyId:String) async throws -> [DataBaseItem]
    func getDataBaseItemByCategory(companyId: String,category:String) async throws -> [DataBaseItem]
    func getDataBaseItemByVender(companyId: String,venderId:String) async throws -> [DataBaseItem]
    func getDataBaseItemByVenderItemTotal(companyId: String,venderId:String) async throws -> Int
    func getDataBaseItemByCategoryAndSubCategory(companyId: String,category:String,subCategory:DataBaseSubCategories) async throws -> [DataBaseItem]
    func getAllDataBaseItems(companyId:String) async throws -> [DataBaseItem]
    func getAllDataBaseItemsByName(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (dataBase:[DataBaseItem],lastDocument:DocumentSnapshot?)
    
    //Recurring SErvice Stops
    func getSingleRecurringServiceStop(companyId:String,recurringServiceStopId:String) async throws -> RecurringServiceStop
    func getAllRecurringServiceStop(companyId:String) async throws -> [RecurringServiceStop]
    func getReucrringServiceStopsWithOutEndDate(companyId:String) async throws -> [RecurringServiceStop]
    func getRecurringServiceStopsByDays(companyId:String,day:String) async throws -> [RecurringServiceStop]
    func getRecurringServiceStopsByDayAndTech(companyId:String,techId:String,day:String) async throws -> [RecurringServiceStop]
    func getAllRecurringServiceStopByCustomerId(companyId:String,customerId:String) async throws -> [RecurringServiceStop]
    func getRecurringServiceStopByServiceLocationId(companyId:String, serviceLocationId:String) async throws  -> [RecurringServiceStop]

    func readFourMostRecentStops(companyId:String,customer : Customer) async throws -> [StopData]
    func readFourMostRecentStopsById(companyId:String,customerId : String) async throws -> [StopData]
    func readFourMostRecentStopsByCustomerIdServiceLocationIdAndBodyOfWaterId(companyId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> [StopData]
    func getStopDataFromServiceStop(companyId:String,serviceStopId:String,customerId : String,serviceLocationId:String,bodyOfWaterId:String) async throws -> StopData
    func readAllHistory(companyId:String,customer : Customer) async throws -> [StopData]
    func getHistoryByCustomerByDateRange(companyId:String,customer : Customer,startDate:Date,endDate:Date) async throws -> [StopData]
    func getAllCompanyInvites(comapnyId : String) async throws ->[Invite]
    func getAllAcceptedCompanyInvites(comapnyId : String) async throws ->[Invite]
    func getSpecificInvite(inviteId : String) async throws ->Invite
    func getAllTrainings(companyId: String,techId:String) async throws -> [Training]
    func getSingleTraining(companyId: String,trainingId:String,techId:String) async throws -> Training
    func getAllTrainingTemplates(companyId: String) async throws -> [TrainingTemplate]
    func getSingleTrainingTemplate(companyId: String,trainingTemplateId:String) async throws -> TrainingTemplate
    func getAllBillingTemplates(companyId:String) async throws -> [BillingTemplate]
    func getDefaultBillingTempalte(companyId:String) async throws -> BillingTemplate
    
    //start up functions
    func getStoreCount(companyId:String) async throws-> Int
    func getGenericItem(companyId:String,genericItemId:String) async throws -> GenericItem
    func getGenericItems(companyId:String) async throws -> [GenericItem]
    func getWorkOrderCount(companyId:String) async throws-> Int
    func getRepairRequestCount(companyId:String) async throws-> Int
    func getServiceOrderCount(companyId:String) async throws-> Int
    func getInvoiceCount(companyId:String) async throws-> Int

    //recurringServiceStop Settings
    func getRecurringServiceStopCount(companyId:String) async throws-> Int
    func getAllWorkOrderTemplate(companyId:String,workOrderId:String) async throws -> JobTemplate
    func getAllWorkOrderTemplates(companyId:String) async throws -> [JobTemplate]
    func getJobTemplate(companyId:String,templateId:String) async throws -> JobTemplate

    func getWorkOrderEstimate(companyId:String) async throws -> [JobTemplate]
    func getAllReadingTemplates(companyId:String) async throws -> [SavedReadingsTemplate]
    func getReadingTemplate(companyId:String,readingTemplateId:String) async throws -> SavedReadingsTemplate
    func getAllDosageTemplates(companyId:String) async throws -> [SavedDosageTemplate]
    func getDosageTemplate(companyId:String,dosageTemplateId:String) async throws -> SavedDosageTemplate
    
    func getAllUniversalReadingTemplates(companyId:String) async throws -> [ReadingsTemplate]
    func getAllUniversalDosageTemplates(companyId:String) async throws -> [DosageTemplate]

    func getAllServiceStopTemplates(companyId:String) async throws -> [ServiceStopTemplate]
    //Job Posting
    
    func getJobPostsByBoard(boardId:String) async throws -> [JobPost]
    func getJobPostsByUserId(userId:String) async throws -> [JobPost]

    func getPublicJobBoards() async throws -> [JobBoard]
    func getSavedJobBoards(userId:String) async throws -> [JobBoard]
    //AR
    func getAccountsReceivableInvoice(companyId:String) async throws ->[StripeInvoice]
    func getAccountsReceivableInvoiceSnapShot(companyId:String) async throws ->[StripeInvoice] //10
    func getAccountsReceivableInvoice(companyId:String,invoiceId:String) async throws ->StripeInvoice

    //AP
    func getAccountsPayableInvoiceSnapShot(companyId:String) async throws ->[StripeInvoice] //10
    func getAccountsPayableInvoice(companyId:String) async throws ->[StripeInvoice]
    
    func getAccountsPayableInvoice(companyId:String,invoiceId:String) async throws ->StripeInvoice

    func getAPOutstandingInvoiceCount(companyId:String) async throws -> (count:Int,total:Int)
    func getAPOutstandingLateInvoiceCount(companyId:String) async throws -> (count:Int,total:Int)
    func getAPRecentlyPaidInvoiceCount(companyId:String) async throws -> (count:Int,total:Int)

    //Fleet
    func getVehical(companyId: String,vehicalId:String) async throws -> Vehical
    func getFleet(companyId:String) async throws -> [Vehical]
    func getActiveVehicalFleet(companyId:String) async throws -> [Vehical]
    func getCompanyFleetSnapShot(companyId: String) async throws -> [Vehical]
    
    //Associated Buisnesses
    func getAssociatedBusinesses(companyId:String) async throws -> [AssociatedBusiness]
    func getAssociatedBusiness(companyId:String,businessId:String) async throws -> AssociatedBusiness
    func getAssociatedBusinessByCompanyId(companyId:String,businessCompanyId:String) async throws -> AssociatedBusiness

    func getEmailConfigurationSettings(companyId:String) async throws -> CompanyEmailConfiguration
    
    func getCustomerEmailConfigurationSettings(companyId:String) async throws -> [CustomerEmailConfiguration]
    func getCustomerEmailConfigurationSettingDocument(companyId:String,id:String) async throws -> CustomerEmailConfiguration
    func getToDoCount(companyId:String) async throws -> Int

    //----------------------------------------------------
    //                    Update Functions
    //----------------------------------------------------
    func updateEquipmentName(companyId:String,equipmentId:String,name:String) throws
    func updateEquipmentCategory(companyId:String,equipmentId:String,category:EquipmentCategory) throws

    func updateEquipmentMake(companyId:String,equipmentId:String,make:String) throws
    func updateEquipmentModel(companyId:String,equipmentId:String,model:String) throws
    func updateEquipmentDateInstalled(companyId:String,equipmentId:String,dateInstalled:Date) throws
    func updateEquipmentStatus(companyId:String,equipmentId:String,status:EquipmentStatus) throws
    func updateEquipmentCleanFilterPressure(companyId:String,equipmentId:String,cleanFilterPressure:Int) throws
    func updateEquipmentCurrentPressure(companyId:String,equipmentId:String,currentPressure:Int) throws
    func updateEquipmentCleanLastServiceDate(companyId:String,equipmentId:String,lastServiceDate:Date) throws
    func updateEquipmentServiceFrequency(companyId:String,equipmentId:String,serviceFrequency:String) throws
    func updateEquipmentServiceFrequencyEvery(companyId:String,equipmentId:String,serviceFrequencyEvery:String) throws
    func updateEquipmentNextServiceDate(companyId:String,equipmentId:String,nextServiceDate:Date) throws
    func updateEquipmentNotes(companyId:String,equipmentId:String,notes:String) throws
    func updateEquipmentPhotoUrls(companyId:String,equipmentId:String,image:DripDropStoredImage) throws
    
    
    func updateServiceStopTaskStatus(companyId:String,serviceStopId:String,taskId:String,status:JobTaskStatus) async throws
    func updateServiceStopIsInvoiced(companyId:String,serviceStopId:String,isInvoiced:Bool) async throws

    func updateJobTaskName(companyId:String,jobId:String,taskId:String,name:String) throws
    func updateJobTaskType(companyId:String,jobId:String,taskId:String,type:String) throws
    func updateJobTaskWorkerType(companyId:String,jobId:String,taskId:String,workerType:WorkerTypeEnum) throws
    func updateJobTaskWorkerName(companyId:String,jobId:String,taskId:String,workerName:String) throws
    func updateJobTaskWorkerId(companyId:String,jobId:String,taskId:String,workerId:String) throws
    func updateJobTaskStatus(companyId:String,jobId:String,taskId:String,status:JobTaskStatus) throws
    func updateJobTaskServiceStopId(companyId:String,jobId:String,taskId:String,serviceStopId:IdInfo) throws
    func updateJobTaskLaborContractId(companyId:String,jobId:String,taskId:String,laborContractId:String) throws
    
    func updateJobDateEstimateAccepted(companyId: String, jobId: String, date: Date) async throws
    func updateJobEstiamteAcceptedById(companyId: String, jobId: String, id: String) async throws
    func updateJobEstiamteAcceptedByType(companyId: String, jobId: String, type: JobEstiamteAcceptanceType) async throws
    func updateJobEstimateAcceptedNotes(companyId: String, jobId: String, notes: String) async throws
    
    func updateJobInvoiceDate(companyId: String, jobId: String, date: Date) async throws
    func updateJobInvoiceRef(companyId: String, jobId: String, ref: String) async throws
    func updateJobInvoiceNotes(companyId: String, jobId: String, notes: String) async throws
    func updateJobInvoiceType(companyId: String, jobId: String, type: JobInvoiceType) async throws

    func updateLaborContractStatus(contractId:String,status:LaborContractStatus)  async throws
    func updateActiveRouteName(companyId:String,activeRouteId:String,name:String)
    func updateVehicalMilage(companyId:String,vehicalId:String,miles:Double) async throws

    func updateActiveRouteDate(companyId:String,activeRouteId:String,date:Date)
    func updateActiveRouteStartTime(companyId:String,activeRouteId:String,startTime:Date)
    func updateActiveRouteEndTime(companyId:String,activeRouteId:String,endTime:Date)
    func updateActiveRouteDuration(companyId:String,activeRouteId:String,duration:Int)
    func updateActiveRouteDistnace(companyId:String,activeRouteId:String,distance:Double)
    func updateActiveRouteStatus(companyId:String,activeRouteId:String,status:ActiveRouteStatus)
    func updateActiveRouteStartMilage(companyId:String,activeRouteId:String,startMilage:Int)
    func updateActiveRouteEndMilage(companyId:String,activeRouteId:String,endMilage:Int)
    func updateActiveRouteFinishedStop(companyId:String,activeRouteId:String,finishedStops:Int)
    func updateActiveRouteTotalStop(companyId:String,activeRouteId:String,totalStops:Int)
    func updateActiveRouteVehicalId(companyId:String,activeRouteId:String,vehicalId:String)
    func updateCustomerFirstName(companyId:String,customerId:String,firstName:String) async throws
    func updateCustomerLastName(companyId:String,customerId:String,lastName:String) async throws
    func updateCustomerEmail(companyId:String,customerId:String,email:String) async throws
    func updateCustomerAddress(companyId:String,customerId:String,billingAddress:Address) async throws
    func updateCustomerPhoneNumber(companyId:String,customerId:String,phoneNumber:String) async throws
    func updateCustomerPhoneLabel(companyId:String,customerId:String,phoneLabel:String) async throws
    func updateCustomerCompany(companyId:String,customerId:String,company:String) async throws
    func updateCustomerDisplayAsCompany(companyId:String,customerId:String,displayAsCompany:Bool) async throws
    func updateCustomerBillingNotes(companyId:String,customerId:String,billingNotes:String) async throws
    func updateCustomerTags(companyId:String,customerId:String,tags:[String]) async throws
    func updateCustomerLinkedInviteId(companyId:String,customerId:String,linkedInviteId:String) async throws
    func updateInvoiceAsPaid(stripeInvoiceId:String,paymentType:InvoicePaymentType) async throws
    func removingReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws
    func removingDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws
    func uploadDosageTemplateAmountArray(companyId:String,dosageTemplateId : String,amount:String) async throws
    func uploadReadingTemplateAmountArray(companyId:String,readingTemplateId : String,amount:String) async throws
    func markInviteAsAccepted(invite:Invite) async throws
    func endRecurringServiceStop(companyId:String,recurringServiceStopId:String,endDate:Date) async throws
    func editDataBaseItem(companyId:String,
        dataBaseItemId:String,
        name:String,
        rate:Double,
        storeName:String,
        storeId:String,
        category:DataBaseItemCategory,
        subCategory:DataBaseItemSubCategory,
        description:String,
        sku:String,
        billable:Bool,
        color:String,
        size:String,
        UOM:UnitOfMeasurment
    ) async throws 
    func updateDataBaseItem(dataBaseItem:DataBaseItem,companyId: String,name:String,rate:Double,category:DataBaseItemCategory,description:String,sku:String,billable:Bool,color:String,size:String,sellPrice:Double,UOM:UnitOfMeasurment,subCategory:DataBaseItemSubCategory) async throws
    func updateReceiptPDFPath(companyId: String,receiptItemId:String,path:String) async throws
    func updateRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws
    func removeRouteServiceStopId(companyId:String,activeRoute:ActiveRoute,serviceStopId:String) async throws

    func endRecurringRoute(companyId:String,recurringRouteId:String,endDate:Date) async throws
    func updateInstallationPartsListOfWorkOrder(companyId: String,workOrder:Job,installationPart:WODBItem) async throws
    func updatePVCPartsListOfWorkOrder(companyId: String,workOrderId:String,pvcPart:WODBItem) async throws
    func updateElectricalPartsListOfWorkOrder(companyId: String,workOrderId:String,electricalPart:WODBItem) async throws
    func updateChemicalListOfWorkOrder(companyId: String,workOrderId:String,chemical:WODBItem) async throws
    func updateMiscPartsListOfWorkOrder(companyId: String,workOrderId:String,miscPart:WODBItem) async throws
    func updateServiceStopListOfWorkOrder(companyId: String,workOrder:Job,serviceStopId:String) async throws
    func updateBillingStatusOfworkOrder(companyId: String,workOrder:Job,billingStatus:Bool) async throws
    
    //Fix later when I have more time
    func updateWorkOrder(originalJob:Job,newJob:Job) async throws
    func updateJobAdmin(companyId:String,jobId:String,adminName:String,adminId:String) async throws
    func updateJobTemplate(companyId:String,jobId:String,templateId:String,templateName:String) async throws
    func updateJobOperationStatus(companyId:String,jobId:String,operationStatus:JobOperationStatus) async throws
    func updateJobBillingStatus(companyId:String,jobId:String,billingStatus:JobBillingStatus) async throws
    func updateJobRate(companyId:String,jobId:String,rate:String) async throws
    func updateJobLaborCost(companyId:String,jobId:String,laborCost:String) async throws
    func updateJobDescription(companyId:String,jobId:String,description:String) async throws
    
    func updateContract(companyId:String,contract:RecurringContract) async throws
    func updateContractStatus(companyId:String,contractId:String,status:RecurringContractStatus) async throws
    func updateContractStartDate(companyId:String,contractId:String,startDate:Date) async throws
    func updateContractEndDate(companyId:String,contractId:String,endDate:Date) async throws
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws
    func updateRepairRequestStatus(companyId:String,repairRequestId:String,status:RepairRequestStatus) async throws
    func updateRepairRequestJobList(companyId:String,repairRequestId:String,jobId:String) async throws
    func updateRepairRequestPhotoUrl(companyId:String,repairRequestId:String,photoUrl:String) async throws
    func uploadRepairRequestImage(companyId: String,requestId:String, image: DripDropImage) async throws ->(path:String, name:String)
    func updateShoppingListDescription(companyId:String,shoppingListItemId:String,newDescription:String) async throws
    func updateShoppingListItemStatus(companyId: String, shoppingListItemId: String, status: ShoppingListStatus) async throws
    func updateStore(companyId:String,store:Vender,name:String,streetAddress:String,city:String,state:String,zip:String) async throws
    func updateCompanyImagePath(user:DBUser,companyId:String,path:String) async throws
    func updateRole(companyId:String,role : Role) async throws
    
    func updateHomeOwnerServiceStopFinish(companyId: String, serviceStop: ServiceStop, finished: Bool) async throws
    func updateRecurringServiceStopAddress(companyId:String,recurringServiceStopId:String,address:Address) async throws
    func uploadRecurringServiceStopTask(companyId:String,recurringServiceStopId:String,task:RecurringServiceStopTask) async throws
    func getRecurringServiceStopTasks(companyId:String,recurringServiceStopId:String) async throws -> [RecurringServiceStopTask]
    func updateRecurringServiceStopTaskStatus(companyId:String,recurringServiceStopId:String,taskId:String,status:JobTaskStatus)
    func getAllTaskGroupById(companyId:String,taskGroupId:String) async throws -> JobTaskGroup 
    func getAllTaskGroups(companyId:String) async throws ->[JobTaskGroup]
    func uploadNewTaskGroup(companyId:String,taskGroup:JobTaskGroup) async throws 
    func uploadNewTaskGroupItem(companyId:String,taskGroupId:String,taskGroupItem:JobTaskGroupItem) async throws 
    //READ
    func getTaskGroupItemById(companyId:String, taskGroupId:String,taskItemId:String) async throws -> JobTaskGroupItem
    func getAllTaskGroupItems(companyId:String, taskGroupId:String) async throws ->[JobTaskGroupItem]
        //Service Stops

    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) async throws
    func updateServiceStop(companyId:String,user:DBUser,originalServiceStop:ServiceStop,newServiceStop:ServiceStop) async throws // Developer Break Out into Induvidual and Delete
    func updateServiceStopAddress(companyId:String,serviceStopId:String,address:Address) async throws
    func updateServicestopOperationStatus(companyId:String,serviceStop:ServiceStop,operationStatus:ServiceStopOperationStatus) async throws
    func updateServicestopBillingStatus(companyId:String,serviceStop:ServiceStop,billingStatus:ServiceStopBillingStatus) async throws
    
    func updatePart(companyId:String,equipmentId:String,part:EquipmentPart) async throws
    func updateEquipment(companyId:String,equipmentId:String,equipment:Equipment) async throws
    func updateEquipmentCustomer(companyId:String,equipment:Equipment) async throws
    
    func editBodyOfWaterName(companyId:String,bodyOfWater:BodyOfWater,name:String) async throws
    func editBodyOfWaterGallons(companyId:String,bodyOfWater:BodyOfWater,gallons:String) async throws
    func editBodyOfWaterMaterial(companyId:String,bodyOfWater:BodyOfWater,material:String) async throws
    func editBodyOfWaterNotes(companyId:String,bodyOfWater:BodyOfWater,notes:String) async throws
    func editBodyOfWaterShape(companyId:String,bodyOfWater:BodyOfWater,shape:String) async throws
    func editBodyOfWaterLength(companyId:String,bodyOfWater:BodyOfWater,length:[String]) async throws
    func editBodyOfWaterDepth(companyId:String,bodyOfWater:BodyOfWater,depth:[String]) async throws
    func editBodyOfWaterWidth(companyId:String,bodyOfWater:BodyOfWater,width:[String]) async throws
    func editBodyOfWater(companyId:String,bodyOfWater:BodyOfWater,updatedBodyOfWater:BodyOfWater) async throws
    
    func updateServiceLocationAddress(companyId:String,currentCustomerId:String,serviceLocationId:String,address:Address) async throws
    
    func updateActiveRouteOrderList(companyId:String,activeRouteId:String,serviceStopOrderList:[ServiceStopOrder]) async throws
    func updateServiceLocationNickName(companyId:String,serviceLocationId:String,nickName:String)async throws
    func updateServiceLocationGateCode(companyId:String,serviceLocationId:String,gateCode:String)async throws
    func updateServiceLocationDogName(companyId:String,serviceLocationId:String,dogNames:[String])async throws
    func updateServiceLocationEstimatedTime(companyId:String,serviceLocationId:String,estimatedTime:Int)async throws
    func updateServiceLocationNotes(companyId:String,serviceLocationId:String,notes:String)async throws
    func updateServiceLocationContact(companyId:String,serviceLocationId:String,contact:Contact)async throws

    
    func updateCustomer(companyId:String,currentCustomer:Customer,customerWithUpdates:Customer) async throws
    func updateCurrentCustomer(companyId:String,currentCustomer:Customer) async throws
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
    ) async throws
    func updateCustomerAddress(companyId:String,currentCustomerId:String,address:Address) async throws
    func makeCustomerInactive(companyId:String,currentCustomerId:String,fireDate:Date,fireReason:String,fireCategory:String) async throws
    func updateCustomerActive(companyId:String,customerId:String,active:Bool) async throws
    func updatePurchaseItem(purchaseItem:PurchasedItem,companyId: String) async throws
    func updateNotes(currentItem:PurchasedItem,notes:String,companyId: String) async throws
    func updateBilling(currentItem:PurchasedItem,billingRate:Double,companyId: String) async throws
    func updatePurchasedItemBillingStatus(currentItem:PurchasedItem,newBillingStatus:Bool,companyId: String) async throws
    func updatePurchasedCustomer(currentItem:PurchasedItem,newCustomer:Customer,companyId: String) async throws
    func updatePurchasedWorkOrderId(currentItem:PurchasedItem,workOrderId:String,companyId: String) async throws
    func updateCompanyUserFavorites(user:DBUser,updatingUser:DBUser,favorites:[String]) async throws
    func updateUserImagePath(updatingUser:DBUser,path:String) async throws
    func updateUserRecentlySelectedCompany(user:DBUser,recentlySelectedCompanyId:String) async throws

    func updateToDoTitle(companyId:String,toDoId:String,newTitle:String) async throws
    func updateToDoStatus(companyId:String,toDoId:String,newStatus:toDoStatus) async throws
    func updateToDoDescription(companyId:String,toDoId:String,newDescription:String) async throws
    func updateToDoDateFinished(companyId:String,toDoId:String,newDateFinished:Date?) async throws
    func updateToDoCustomerId(companyId:String,toDoId:String,newCustomerId:String) async throws
    func updateToDoJobId(companyId:String,toDoId:String,newJobId:String) async throws
    func updateToDoTechId(companyId:String,toDoId:String,newTechId:String) async throws
    func updateEmailConfigurationBody(companyId:String,newBody:String) async throws
    func updateEmailConfigurationIsOn(companyId:String,emailIsOn:Bool) async throws
    func updateEmailConfigurationRequirePhoto(companyId:String,requirePhoto:Bool) async throws
    func updateCustomerEmailConfig(companyId:String,customerEmailConfigId:String,emailIsOn:Bool) async throws
    
    func markChatAsRead(userId:String, chat: Chat) async throws
    func markChatAsUnread(userId:String,chat:Chat) async throws
    
    //----------------------------------------------------
    //                    Delete Functions
    //----------------------------------------------------
    func deleteInvoice(stripeInvoiceId:String) async throws
    func deleteRecurringServiceStop(companyId:String,recurringServiceStopId : String) async throws
    func deleteRecurringRoute(companyId:String,recurringRouteId : String) async throws

    func deleteJob(companyId:String,jobId:String) async throws
    func deletePart(companyId:String,jobId:String,part:WODBItem,category:String) async throws

    func deleteContract(companyId:String,contractId:String) async throws
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws
    func deleteShoppingListItem(companyId:String,shoppingListItemId:String) async throws
    func deleteServiceStop(companyId:String,serviceStop:ServiceStop)async throws
    func deleteServiceStopById(companyId:String,serviceStopId:String)async throws
    func deleteEquipment(companyId:String,equipmentId:String) async throws
    func deleteCustomer(companyId:String,serviceLocationId:String)async throws
    func deleteAllCustomerSummaries(companyId:String,customer:Customer) async throws
    func deleteCustomer(companyId:String,customer:Customer) throws
    func deleteCustomer(companyId:String,customer:Customer)async throws
    func deleteToDo(companyId:String,toDoId:String) async throws
    func deleteAssociatedBusinessToCompany(companyId:String,businessId:String) async throws
    func deleteBodyOfWater(companyId:String,bodyOfWaterId:String) async throws
    func deleteTaskGroupItem(companyId:String,taskGroupId:String,taskId:String) async throws 
    func updateTaskGroupName(companyId: String, taskGroupId: String, name: String) async throws 
    func updateTaskGroupDescription(companyId: String, taskGroupId: String, description: String) async throws
    func updateTaskGroupNumberOfTasks(companyId: String, taskGroupId: String, numberOfTasks: Int) async throws
    func deleteTaskGroup(companyId:String,taskGroupId:String) async throws
    func deleteRecurringServiceStopTask(companyId:String,recurringServiceStopId:String,taskId:String) async throws 

    //----------------------------------------------------
    //
    //                  Normal Functiuons
    //
    //----------------------------------------------------
    func updateWorkLogEndTime(companyId:String,workLogId:String,endTime:Date) async throws
    func updateWorkLogEndLatAndLong(companyId:String,workLogId:String,lat:Double,long:Double) async throws
    func updateWorkLogActive(companyId:String,workLogId:String,current:Bool) async throws
    func uploadWorkLog(companyId:String,workLog:WorkLog) async throws
    func uploadWorkShift(companyId:String, workShift:WorkShift) async throws
    func updateWorkShiftActive(companyId:String, workShiftId:String,current:Bool) async throws

    func getActiveWorkLogsByUser(companyId:String,userId:String) async throws -> [WorkLog]
    func getCurrentShift(companyId:String,userId:String) async throws -> [WorkShift]

    func getRecentActiveRouteForTech(companyId: String,techId:String,days:Int) async throws -> [ActiveRoute]

    func RegenerateCustomerSummaries(companyId:String,customers:[Customer],dosageTemplates:[DosageTemplate]) async throws
    func RegenerateSingleCustomer(companyId:String,customer:Customer,dosageTemplates:[DosageTemplate]) async throws
    func convertDatabaseItemToCSVStruct(contents: String) async throws -> [CSVDataBaseItem]
    func changeDBServiceStopsToServiceStops(DBServiceStops:[ServiceStop]) async throws ->[ServiceStop]
    func searchForCustomersLocations(searchTerm:String,serviceLocation:[ServiceLocation])->[ServiceLocation]
    func convertCustomerCSVToStruct(contents: String) async throws -> [CSVCustomer]
    func getCompanysBySearchTerm(searchTerm: String) async throws -> [Company]
    func getWorkLogByShift(companyId:String,shiftId:String,userId:String) async throws -> [WorkLog] 
    func getPreviousShiftByUserId(companyId:String, userId:String, count:Int) async throws -> [WorkShift]
    func getShiftByUserIdBetweenDates(companyId:String, userId:String, start:Date, end:Date) async throws -> [WorkShift]
    func getNextShiftByUserId(companyId:String, userId:String, count:Int) async throws -> [WorkShift]

    //----------------------------------------------------
    //                    Listeners
    //----------------------------------------------------
    func uploadCustomer(companyId:String,customer : Customer) async throws
    func addListenerForAllCustomers(companyId:String,storeId:String,completion:@escaping (_ serviceStops:[DataBaseItem]) -> Void)
    func addListenerForUnreadChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void)
    func addListenerForAllMessages(chatId: String,amount:Int, completion: @escaping ([Message]) -> Void)
    func addListenerForAllRepairRequests(companyId:String,status:[RepairRequestStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[RepairRequest]) -> Void)

    func addListenerForAllJobsBilling(companyId:String,status:[JobBillingStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void)
    func addListenerForAllJobsOperations(companyId:String,status:[JobOperationStatus],requesterIds:[String],startDate:Date,endDate:Date,completion:@escaping (_ serviceStops:[Job]) -> Void)

    func addListenerForAllChats(userId:String,completion:@escaping (_ serviceStops:[Chat]) -> Void)
    func addListenerForAllServiceStops(companyId:String,completion:@escaping (_ serviceStops:[ServiceStop]) -> Void)
    func addListenerForAllEquipment(companyId: String,amount:Int, completion: @escaping ([Equipment]) -> Void)
    func addListenerForAllCustomers(companyId:String, sort:CustomerSortOptions,filter:CustomerFilterOptions,completion:@escaping (_ customers:[Customer]) -> Void)
    
    func addListenerForSentLaborContracts(companyId:String,status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void)
    func addListenerForReceivedLaborContracts(companyId:String,status:[LaborContractStatus], isInvoiced:Bool, completion:@escaping (_ customers:[LaborContract]) -> Void)
    func addListenerForReceivedLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void)
    func addListenerForSentLaborContractsAllInvoiceStatus(companyId:String, status:[LaborContractStatus], completion:@escaping (_ customers:[LaborContract]) -> Void)
    
    func removeListenerForSentLaborContracts()
    func removeListenerForReceivedLaborContracts()

    func removeListenerForJobs()

    func removeListenerForAllCustomers()
    func removeListenerForMessages()
    func removeListenerForChats()
    func removeListenerForRequests()
    func removeListenerForAllServiceStops()
    func removeEquipmentListener()
}
