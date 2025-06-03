//
//  ServiceStop+ProductionDataService+Extension.swift
//  DripDrop
// 
//  Created by Michael Espineli on 12/2/24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import CoreLocation
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import CoreLocation
import MapKit
import Darwin

extension ProductionDataService {
    //Refrences
    func serviceStopCollection(companyId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/serviceStops")
   }
    func readingCollectionForServiceStop(serviceStopId:String,companyId:String) -> CollectionReference{
       db.collection("companies/\(companyId)/serviceStops/\(serviceStopId)/stores")
   }
    func ServiceStopImageRefrence(id:String)->StorageReference {
        storage.child("serviceStop").child(id)
    }
    func serviceStopDocument(serviceStopId:String,companyId:String)-> DocumentReference{
       serviceStopCollection(companyId: companyId).document(serviceStopId)
   }
    //CREATE
    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws {
        try serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).setData(from:serviceStop, merge: false)
        let homeOwnerServiceStopId = companyId + "-" + serviceStop.id
        var homeOwnerServiceStop = serviceStop
        homeOwnerServiceStop.id = homeOwnerServiceStopId
        try homeownerServiceStopDocument(serviceStopId: homeOwnerServiceStop.id).setData(from:homeOwnerServiceStop, merge: false)
    }
    //READ
    
    func getServiceStopByJobId(companyId: String, jobId: String) async throws -> [ServiceStop] {
        //DEVELOPER
        return []
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
    func getBillableServiceStopsByDate(startDate: Date,endDate:Date,companyId:String) async throws -> [ServiceStop]{
        _ = try await UserManager.shared.loadCurrentUser()
        
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
        //MEMORY LEAK
        
        print("Getting All Service Stops By Tech For \(tech.firstName) \(tech.lastName) and Day by \(fullDate(date: date)) - [Data Service]")
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .getDocuments(as:ServiceStop.self)
        //        return []
    }
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ServiceStop] {
        print("Getting All Service Stops By Tech For \(tech.userName)and Day by \(fullDate(date: date))- [Data Service]")
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.userId)
            .getDocuments(as:ServiceStop.self)
        //        return []
    }
    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        //MEMORY LEAK
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .count.getAggregation(source: .server).count as! Int
        //        return 0
        
    }
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .whereField(ServiceStop.CodingKeys.operationStatus.stringValue, isEqualTo: ServiceStopOperationStatus.finished.rawValue)
            .getDocuments(as:ServiceStop.self).count
        
    }
    func getAllServiceStopsSortedByRecurringServiceStops(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField("recurringServiceStopId", isEqualTo: recurringServiceStopId )
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsByRecurringServiceStopsAfterToday(companyId:String,recurringServiceStopId: String) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThan: Date().startOfDay())
            .whereField(ServiceStop.CodingKeys.recurringServiceStopId.stringValue, isEqualTo: recurringServiceStopId )
            .getDocuments(as:ServiceStop.self)
        
    }
    func getAllServiceStopsSortedByPrice(companyId:String,descending: Bool) async throws -> [ServiceStop]{
        return try await serviceStopCollection(companyId: companyId)
            .order(by: "rate", descending: descending).getDocuments(as:ServiceStop.self)
        
    }
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
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThan: startDate.startOfDay())
            .whereField("serviceDate", isGreaterThan: endDate.endOfDay())
            .whereField("recurringServiceStopId", isEqualTo: recurringsServicestopId)
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
    func getServiceStopByServiceLocationId(companyId: String, serviceLocationId: String) async throws -> [ServiceStop] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let date = calendar.date(from: components)!
        let start = calendar.date(byAdding: .day, value: -7, to: date)!
        
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.rawValue, isGreaterThan: start)
            .whereField(ServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: serviceLocationId)
            .getDocuments(as:ServiceStop.self)
    }
    
    //UPDATE
    func uploadServiceStopImage(companyId: String,serviceStopId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await ServiceStopImageRefrence(id: serviceStopId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (urlString,returnedName)
    }
    func updateServiceStopPhotoURLs(companyId: String, serviceStopId: String, photoUrls: [DripDropStoredImage]) async throws {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        for image in photoUrls {
            try await serviceStopRef.updateData([
                ServiceStop.CodingKeys.photoUrls.rawValue: FieldValue.arrayUnion([
                    [
                    "id":image.id,
                    "description":image.description,
                    "imageURL":image.imageURL
                    ]
                ])
            ])
        }
    }
    func updateServiceStopAddress(companyId: String, serviceStopId: String, address: Address) async throws  {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        try await serviceStopRef.updateData(
            [
                ServiceStop.CodingKeys.address.stringValue: [
                    Address.CodingKeys.streetAddress.stringValue: address.streetAddress,
                    Address.CodingKeys.city.stringValue: address.city,
                    Address.CodingKeys.state.stringValue: address.state,
                    Address.CodingKeys.zip.stringValue: address.zip,
                    Address.CodingKeys.latitude.stringValue:address.latitude ,
                    Address.CodingKeys.longitude.stringValue:address.longitude ,
                ] as [String : Any]
            ]
        )
    }
    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) async throws{
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        try await ref.updateData([
            ServiceStop.CodingKeys.serviceDate.rawValue: serviceDate,
            ServiceStop.CodingKeys.techId.rawValue: companyUser.userId,
            ServiceStop.CodingKeys.tech.rawValue: companyUser.userName,
        ])
    }
    func updateServiceStopIsInvoiced(companyId:String,serviceStopId:String,isInvoiced:Bool) async throws{
        let ref = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        try await ref.updateData([
            ServiceStop.CodingKeys.isInvoiced.rawValue: isInvoiced,
        ])
    }
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
    func skipServicestop(companyId:String,serviceStop:ServiceStop,skip:Bool) async throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        try await itemRef.updateData([
            "skip":skip
        ])
    }
    func updateHomeOwnerServiceStopFinish(companyId: String, serviceStop: ServiceStop, finished: Bool) async throws {
       
    }
    func updateServicestopOperationStatus(companyId: String, serviceStop: ServiceStop, operationStatus: ServiceStopOperationStatus) async throws {
        print("updateServicestopOperationStatus  - [dataService]")
        print("Service Stop Id : \(serviceStop.id)")
        
        print("Company Id : \(companyId)")
            let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
            
            try await itemRef.updateData([
                ServiceStop.CodingKeys.operationStatus.rawValue:operationStatus.rawValue
            ])
    }
    func updateServicestopBillingStatus(companyId: String, serviceStop: ServiceStop, billingStatus: ServiceStopBillingStatus) async throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        
        try await itemRef.updateData([
            ServiceStop.CodingKeys.billingStatus.rawValue:billingStatus.rawValue
        ])
    }
    //Delete

    func deleteServiceStop(companyId:String,serviceStop:ServiceStop)async throws {
        try await serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).delete()

    }
    func deleteServiceStopById(companyId:String,serviceStopId:String)async throws {
        try await serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId).delete()

    }
}
