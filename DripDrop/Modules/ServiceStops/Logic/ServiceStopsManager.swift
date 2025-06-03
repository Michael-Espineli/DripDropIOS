//
//  rootView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/14/23.
//
import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift


struct ServiceStop:Identifiable, Codable,Equatable, Hashable{
    var id : String = "comp_ss_" + UUID().uuidString
    var internalId : String
    var companyId : String
    var companyName : String
    var customerId : String //Seen
    var customerName : String //Seen
    var address: Address //Seenv
    
    var dateCreated : Date //Seen
    var serviceDate : Date //Seen
    var startTime : Date? //Seen
    var endTime : Date? //Seen
    var duration : Int //Minutes
    var estimatedDuration : Int //Minutes
    
    var tech : String
    var techId : String
    
    var recurringServiceStopId : String //Seen
    var description : String //Seen
    var serviceLocationId : String //Seen
    
    var typeId : String
    var type : String //Recurring Service Stop, Job, Start Up?
    var typeImage : String //
    
    var jobId : String //Seen
    var jobName : String? //Seen
    
    var operationStatus : ServiceStopOperationStatus
    var billingStatus : ServiceStopBillingStatus
    
    var includeReadings : Bool //Seen
    var includeDosages : Bool //Seen
    let otherCompany : Bool
    let laborContractId : String //Actually Optional
    let contractedCompanyId : String //Actually Optional

    var photoUrls:[DripDropStoredImage]?
    
    let mainCompanyId : String? //Actually Optional
    let isInvoiced : Bool
    init(
        id: String,
        internalId: String,
        companyId : String,
        companyName : String,
        customerId : String,
        customerName : String,
        address : Address,
        dateCreated : Date,
        serviceDate : Date,
        startTime : Date? = nil,
        endTime : Date? = nil,
        duration :  Int,
        estimatedDuration :  Int,
        tech : String,
        techId : String,
        recurringServiceStopId : String,
        description : String,
        serviceLocationId : String,
        typeId : String,
        type : String,
        typeImage : String,
        jobId : String,
        jobName : String? = nil,
        operationStatus :ServiceStopOperationStatus,
        billingStatus: ServiceStopBillingStatus,
        includeReadings :Bool,
        includeDosages :Bool,
        otherCompany :Bool,
        laborContractId :String,
        contractedCompanyId :String,
        photoUrls : [DripDropStoredImage]? = nil,
        mainCompanyId :String? = nil,
        isInvoiced :Bool

    ){
        
        self.id = id
        self.internalId = internalId
        self.companyId = companyId
        self.companyName = companyName
        self.customerId = customerId
        self.customerName = customerName
        self.address = address
        self.dateCreated = dateCreated
        self.serviceDate = serviceDate
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.estimatedDuration = estimatedDuration
        self.tech = tech
        self.techId = techId
        self.recurringServiceStopId = recurringServiceStopId
        self.description = description
        self.serviceLocationId = serviceLocationId
        self.typeId = typeId
        self.type = type
        self.typeImage = typeImage
        self.jobId = jobId
        self.jobName = jobName
        self.operationStatus = operationStatus
        self.billingStatus = billingStatus
        self.includeReadings = includeReadings
        self.includeDosages = includeDosages
        self.otherCompany = otherCompany
        self.laborContractId = laborContractId
        self.contractedCompanyId = contractedCompanyId
        self.photoUrls = photoUrls
        self.mainCompanyId = mainCompanyId
        self.isInvoiced = isInvoiced
    }
    
        enum CodingKeys:String, CodingKey {
            case id = "id"
            case internalId = "internalId"
            case companyId = "companyId"
            case companyName = "companyName"
            case customerId = "customerId"
            case customerName = "customerName"
            case address = "address"
            case dateCreated = "dateCreated"
            case serviceDate = "serviceDate"
            case startTime = "startTime"
            case endTime = "endTime"
            case duration = "duration"
            case estimatedDuration = "estimatedDuration"
            case tech = "tech"
            case techId = "techId"
            case recurringServiceStopId = "recurringServiceStopId"
            case description = "description"
            case serviceLocationId = "serviceLocationId"
            case typeId = "typeId"
            case type = "type"
            case typeImage = "typeImage"
            case jobId = "jobId"
            case jobName = "jobName"
            case operationStatus = "operationStatus"
            case billingStatus = "billingStatus"
            case includeReadings = "includeReadings"
            case includeDosages = "includeDosages"
            case otherCompany = "otherCompany"
            case laborContractId = "laborContractId"
            case contractedCompanyId = "contractedCompanyId"
            case photoUrls = "photoUrls"
            case mainCompanyId = "mainCompanyId"
            case isInvoiced = "isInvoiced"
        }
    static func == (lhs: ServiceStop, rhs: ServiceStop) -> Bool {
        return lhs.id == rhs.id &&
        lhs.typeId == rhs.typeId &&
        lhs.customerId == rhs.customerId &&
        lhs.techId == rhs.techId &&
        lhs.serviceLocationId == rhs.serviceLocationId &&
        lhs.serviceDate == rhs.serviceDate
    }

}

struct ServiceStopTaskTemplate:Identifiable, Codable,Equatable, Hashable{
    var id:String
    var description:String
}

//Keep This One




enum serviceStopScreen: String,Identifiable,Hashable,CaseIterable{
     case info
    case waterDetails
    case tasks
    case equipmentDetails
    case photoSelection
    case recap
    case locationStartUp
    case checkList

    var id: String {
        return self.rawValue
    }
    func title() -> String {
        switch self {
        case .info:
            return "Info"
        case .waterDetails:
            return "Water"

        case .tasks:
            return "Tasks"

        case .equipmentDetails:
            return "Equipment"

        case .photoSelection:
            return "Photos"

        case .recap:
            return "Recap"

        case .locationStartUp:
            return "Start Up"
        case .checkList:
            return "Check List"
        }
    }
}
/*
protocol ServiceStopManagerProtocol {

    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws
    //----------------------------------------------------
    //                    Update
    //----------------------------------------------------
    func updateServiceStopLocations(newServiceStop:ServiceStop,serviceLocation:ServiceLocation,companyId:String) async throws
    
    func updateServiceStopFinish(companyId:String,serviceStop:ServiceStop,finished:Bool) throws
    
    func updateServiceStopSkipped(companyId:String,serviceStop:ServiceStop,skipped:Bool) throws
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------

    func getAllServiceStops(companyId:String) async throws -> [ServiceStop]
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:DBUser) async throws -> [ServiceStop]
    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int
    func getAllServiceStopsSortedByRecurringServiceStops(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]
    func getAllServiceStopsSortedByPrice(companyId:String,descending: Bool) async throws -> [ServiceStop]
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
    func getAllServiceStopsByDate(companyId:String,date: Date) async throws -> [ServiceStop]
    func getAllServiceStopsSortedByTime(companyId:String,descending: Bool,count:Int) async throws -> [ServiceStop]
    func getAllServiceStopsBetweenDate(companyId:String,startDate: Date,endDate:Date) async throws -> [ServiceStop]
    func getServiceStopsByRecurringsServiceStop(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]
    func getServiceStopsByRecurringsServiceStopNotFinished(companyId:String,recurringsServicestop:RecurringServiceStop) async throws -> [ServiceStop]
    func getUnfinishedServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]
    func getUnfinished4ServiceStopsByCustomer(companyId:String,customer:Customer) async throws -> [ServiceStop]
    
    func getServiceStopsBetweenDatesAndByCustomer(companyId:String,startDate: Date,endDate:Date,customer:Customer) async throws -> [ServiceStop]
    
    func getServiceStopsBetweenDatesAndByType(companyId:String,startDate: Date,endDate:Date,workOrderType:String) async throws -> [ServiceStop]
    
    func getAllUnfinishedServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]
    func getAllServiceStopsByDayAndTech(companyId:String,date: Date,techId:String) async throws -> [ServiceStop]
    func getServiceStopBySomething(companyId:String,count:Int,lastDocument:DocumentSnapshot?) async throws -> (serviceStops:[ServiceStop],lastDocument:DocumentSnapshot?)
    func updateBillingStatusOfServiceStop(companyId:String,serviceStop:ServiceStop,billingStatus:Bool) throws
    func getServiceStopById(serviceStopId:String,companyId:String) async throws -> ServiceStop
 
    func updateServiceStop(companyId:String,user:DBUser,originalServiceStop:ServiceStop,newServiceStop:ServiceStop) throws
    
    
    func getHistoryServiceStopsBy(companyId:String,serviceStop: ServiceStop) async throws -> [History]
    func getBillableServiceStopsByDate(startDate: Date,endDate:Date,companyId:String) async throws -> [ServiceStop]
    //Listeners
    func finishServicestop(companyId:String,serviceStop:ServiceStop,finish:Bool) throws
    func skipServicestop(companyId:String,serviceStop:ServiceStop,skip:Bool) throws
    func addListenerForAllServiceStops(companyId:String,completion:@escaping (_ serviceStops:[ServiceStop]) -> Void)
    func removeListenerForAllServiceStops()
    func changeDBServiceStopsToServiceStops(DBServiceStops:[ServiceStop]) async throws ->[ServiceStop]
    func deleteServiceStop(companyId:String,serviceStopId:String)async throws
    func getAllServiceStopsByCustoer(companyId: String,customerId:String,startDate:Date,endDate:Date) async throws -> [ServiceStop]
    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) throws


}
final class MockServiceStopManager:ServiceStopManagerProtocol {
    let mockServiceStops:[ServiceStop] = []
    private var serviceStopListener: ListenerRegistration? = nil

    func uploadServiceStop(companyId: String, serviceStop: ServiceStop) async throws {
        print("Successfully Uplaoded")
    }
    
    func updateServiceStopLocations(newServiceStop: ServiceStop, serviceLocation: ServiceLocation, companyId: String) async throws {
        print("Successfully Updated")
    }
    
    func updateServiceStopFinish(companyId: String, serviceStop: ServiceStop, finished: Bool) throws {
        print("Successfully Updated")
    }
    
    func updateServiceStopSkipped(companyId: String, serviceStop: ServiceStop, skipped: Bool) throws {
        print("Successfully Updated")
    }
    
    func getAllServiceStops(companyId: String) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsByTechAndDate(companyId: String, date: Date, tech: DBUser) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsByTechAndDateCount(companyId: String, date: Date, tech: DBUser) async throws -> Int {
        return 1
    }
    
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String, date: Date, tech: DBUser) async throws -> Int {
        return 1
    }
    
    func getAllServiceStopsSortedByRecurringServiceStops(companyId: String, recurringServiceStopId: String) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsSortedByPrice(companyId: String, descending: Bool) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsByDate(companyId: String, date: Date) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsSortedByTime(companyId: String, descending: Bool, count: Int) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsBetweenDate(companyId: String, startDate: Date, endDate: Date) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) throws{
    }
    func getServiceStopsByRecurringsServiceStop(companyId: String, recurringsServicestop: RecurringServiceStop) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getServiceStopsByRecurringsServiceStopNotFinished(companyId: String, recurringsServicestop: RecurringServiceStop) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getUnfinishedServiceStopsByCustomer(companyId: String, customer: Customer) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getUnfinished4ServiceStopsByCustomer(companyId: String, customer: Customer) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getServiceStopsBetweenDatesAndByCustomer(companyId: String, startDate: Date, endDate: Date, customer: Customer) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getServiceStopsBetweenDatesAndByType(companyId: String, startDate: Date, endDate: Date, workOrderType: String) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllUnfinishedServiceStopsByDayAndTech(companyId: String, date: Date, techId: String) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getAllServiceStopsByDayAndTech(companyId: String, date: Date, techId: String) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func getServiceStopBySomething(companyId: String, count: Int, lastDocument: DocumentSnapshot?) async throws -> (serviceStops: [ServiceStop], lastDocument: DocumentSnapshot?) {
        throw FireBaseRead.unableToRead
    }
    
    func updateBillingStatusOfServiceStop(companyId: String, serviceStop: ServiceStop, billingStatus: Bool) throws {
        print("Sucessful")
    }
    
    func getServiceStopById(serviceStopId: String, companyId: String) async throws -> ServiceStop {
        var serviceStop:ServiceStop? = nil
        guard let validatedServiceStop = serviceStop else {
            throw FireBaseRead.unableToRead
        }
        return validatedServiceStop
    }
    
    func updateServiceStop(companyId: String, user: DBUser, originalServiceStop: ServiceStop, newServiceStop: ServiceStop) throws {
        print("Sucessfully Updated")
    }
    
    func getHistoryServiceStopsBy(companyId: String, serviceStop: ServiceStop) async throws -> [History] {
        return []
    }
    
    func getBillableServiceStopsByDate(startDate: Date, endDate: Date, companyId: String) async throws -> [ServiceStop] {
        return mockServiceStops

    }
    func getAllServiceStopsByCustoer(companyId: String,customerId:String,startDate:Date,endDate:Date) async throws -> [ServiceStop]{
        return []
    }
    func finishServicestop(companyId: String, serviceStop: ServiceStop, finish: Bool) throws {
        print("Successfully Updated")
    }
    
    func skipServicestop(companyId: String, serviceStop: ServiceStop, skip: Bool) throws {
        print("Successfully Updated")

    }
    
    func addListenerForAllServiceStops(companyId: String, completion: @escaping ([ServiceStop]) -> Void) {
        
   print("Hellow")
    }
    
    func removeListenerForAllServiceStops() {
        print("Something")
    }
    
    func changeDBServiceStopsToServiceStops(DBServiceStops: [ServiceStop]) async throws -> [ServiceStop] {
        return mockServiceStops
    }
    
    func deleteServiceStop(companyId:String,serviceStopId:String)async throws {
        print("Successfully Deleted")
    }
    
    
}

final class ServiceStopManager:ServiceStopManagerProtocol {
    
    static let shared = ServiceStopManager()
    init(){}
    private let db = Firestore.firestore()
    
    
    //DEVELOPER THESE ARE DUPLICATES
    private func serviceStopCollection(companyId:String) -> CollectionReference{
        Firestore.firestore().collection("companies/\(companyId)/serviceStops")
    }
 
    private func serviceStopDocument(serviceStopId:String,companyId:String)-> DocumentReference{
        
        serviceStopCollection(companyId: companyId).document(serviceStopId)
        
    }

    private var serviceStopListener: ListenerRegistration? = nil
    
    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws {
        try serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).setData(from:serviceStop, merge: false)
  
    }
    //----------------------------------------------------
    //                    Update
    //----------------------------------------------------
    func updateServiceStopLocations(newServiceStop:ServiceStop,serviceLocation:ServiceLocation,companyId:String) async throws{
    }
    
    func updateServiceStopFinish(companyId:String,serviceStop:ServiceStop,finished:Bool) throws {
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        ref.updateData([
            ServiceStop.CodingKeys.finished.rawValue: finished
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    func updateServiceStopSkipped(companyId:String,serviceStop:ServiceStop,skipped:Bool) throws {
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        ref.updateData([
            ServiceStop.CodingKeys.skipped.rawValue: skipped
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
        
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------

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
        //MEMORY LEAK
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        //MEMORY LEAK
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .count.getAggregation(source: .server).count as! Int
        
    }
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        //MEMORY LEAK
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.rawValue, isEqualTo: tech.id)
            .whereField(ServiceStop.CodingKeys.finished.rawValue, isEqualTo: true)
            .count.getAggregation(source: .server).count as! Int
        
    }
    func getAllServiceStopsSortedByRecurringServiceStops(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]{
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
    func updateBillingStatusOfServiceStop(companyId:String,serviceStop:ServiceStop,billingStatus:Bool) throws{
        
//        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        
//        let history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
        var historyArray:[String] = []
        let _:[String] = []
        
        
//        let historyText = ""
//        var dateAndTech = ""
        var valueChange = ""
        //check if there was a chnage in tech
//        dateAndTech = " ** " + (serviceStop.invoiced.description.capitalized) + " on " + fullDate(date: Date()) + " changed ** "
        valueChange = " **" + (serviceStop.invoiced.description.capitalized) + " ** "
        historyArray.append(valueChange)
        
        let ref = db.collection("serviceStops").document(serviceStop.id)
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
    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) throws{
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
    func getServiceStopById(serviceStopId:String,companyId:String) async throws -> ServiceStop{
        try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).getDocument(as: ServiceStop.self)
        
    }
    func getServiceStopByJobId(companyId:String,jobId:String) async throws -> [ServiceStop]{
        try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.jobId.rawValue, isEqualTo: jobId)
            .getDocuments(as: ServiceStop.self)
        
    }
    func getAllServiceStopsByRecurringServiceStopIdAfterDate(companyId: String,recurringServiceStopId:String,date:Date) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.recurringServiceStopId.rawValue, isEqualTo: recurringServiceStopId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: date.startOfDay())
            .getDocuments(as:ServiceStop.self)
        
    }
    //UPDATE
    func updateServiceStop(companyId:String,user:DBUser,originalServiceStop:ServiceStop,newServiceStop:ServiceStop) throws{
        
//        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        
        var history:History =  History(id: UUID().uuidString, date: Date(), tech: user.firstName ?? "UNKNOWN", changes: [])
        var historyArray:[String] = []
        var pushHistoryArray:[String] = []
        
        
        let historyText = ""
        var dateAndTech = ""
        var valueChange = ""
        var counter = 0
        //check if there was a chnage in tech
        if originalServiceStop.tech != newServiceStop.tech {
            counter = counter + 1
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.tech ?? "") + " --> " + (newServiceStop.tech ?? "") + " ** "
            historyArray.append(valueChange)
            
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            ref.updateData([
                "tech": newServiceStop.tech ?? ""
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
        if originalServiceStop.description != newServiceStop.description {
            
            counter = counter + 1
            print(counter)
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.description ) + " --> " + (newServiceStop.description ) + " ** "
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
        
        if originalServiceStop.typeId != newServiceStop.typeId {
            
            counter = counter + 1
            dateAndTech = " ** " + (originalServiceStop.tech ?? "") + " on " + fullDate(date: Date()) + " changed ** "
            valueChange = " ** " + (originalServiceStop.typeId ) + " --> " + (newServiceStop.typeId ) + " ** "
            print(valueChange)
            
            historyArray.append(valueChange)
            let ref = db.collection("serviceStops").document(originalServiceStop.id)
            ref.updateData([
                "typeId": newServiceStop.typeId
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
            valueChange = " ** " + (originalServiceStop.finished.description.capitalized ) + " --> " + (newServiceStop.finished.description.capitalized ) + " ** "
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
    
    //Listeners
    func finishServicestop(companyId:String,serviceStop:ServiceStop,finish:Bool) throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        itemRef.updateData([
            "finish":finish
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func skipServicestop(companyId:String,serviceStop:ServiceStop,skip:Bool) throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        itemRef.updateData([
            "skip":skip
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    func updateServiceStopDate(companyId:String,serviceStop:ServiceStop,date:Date) throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        itemRef.updateData([
            ServiceStop.CodingKeys.serviceDate.rawValue:date
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Service Stop successfully updated to \(fullDate(date:date))")
            }
        }
    }
    func updateServiceStopTech(companyId:String,serviceStop:ServiceStop,techId:String,tech:String) throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        itemRef.updateData([
            ServiceStop.CodingKeys.techId.rawValue:techId,
            ServiceStop.CodingKeys.tech.rawValue:tech
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Service Stop successfully updated to \(tech) \(techId)")
            }
        }
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
    
    func removeListenerForAllServiceStops(){
        self.serviceStopListener?.remove()
    }
    func changeDBServiceStopsToServiceStops(DBServiceStops:[ServiceStop]) async throws ->[ServiceStop] {
        let liveServiceStopsList: [ServiceStop] = []
        return liveServiceStopsList
    }
    func deleteServiceStop(companyId:String,serviceStopId:String)async throws {
        try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).delete()
        
    }
}
*/

