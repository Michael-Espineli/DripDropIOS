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
    func ServiceStopImageRefrence(companyId:String,id:String)->StorageReference {
        storage
            .child("companies")
            .child(companyId)
            .child("serviceStops")
            .child(id)
    }
    func serviceStopDocument(serviceStopId:String,companyId:String)-> DocumentReference{
       serviceStopCollection(companyId: companyId).document(serviceStopId)
    }
    //CREATE
    func uploadServiceStop(companyId:String,serviceStop : ServiceStop) async throws {
        print("[ServiceStopTypeDebug][uploadServiceStop] companyId=\(companyId) serviceStopId=\(serviceStop.id) typeId=\(serviceStop.typeId) type=\(serviceStop.type) typeImage=\(serviceStop.typeImage) jobId=\(serviceStop.jobId) recurringServiceStopId=\(serviceStop.recurringServiceStopId) techId=\(serviceStop.techId)")
        try serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).setData(from:serviceStop, merge: false)
        let homeOwnerServiceStopId = companyId + "-" + serviceStop.id
        var homeOwnerServiceStop = serviceStop
        homeOwnerServiceStop.id = homeOwnerServiceStopId
        try homeownerServiceStopDocument(serviceStopId: homeOwnerServiceStop.id).setData(from:homeOwnerServiceStop, merge: false)
    }
    //READ
    
    func getServiceStopByJobId(companyId: String, jobId: String) async throws -> [ServiceStop] {
        try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.jobId.rawValue, isEqualTo: jobId)
            .getDocuments(as: ServiceStop.self)
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
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .getDocuments(as:ServiceStop.self)
        //        return []
    }
    func getAllServiceStopsByTechAndDate(companyId: String,date:Date,tech:CompanyUser) async throws -> [ServiceStop] {
        print("Getting All Service Stops By Tech For \(tech.userName)and Day by \(fullDate(date: date))- [Data Service]")
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.userId)
            .getDocuments(as:ServiceStop.self)
        //        return []
    }
    func getAllServiceStopsByTechAndDateCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        //MEMORY LEAK
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThanOrEqualTo: date.startOfDay())
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isLessThan: date.endOfDay())
            .whereField(ServiceStop.CodingKeys.techId.stringValue, isEqualTo: tech.id)
            .count.getAggregation(source: .server).count as! Int
        //        return 0
        
    }
    func getAllServiceStopsByTechAndDateAndFinishedCount(companyId: String,date:Date,tech:DBUser) async throws -> Int{
        return try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceDate.stringValue, isGreaterThanOrEqualTo: date.startOfDay())
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
    func getFutureerviceStopsByCustomer(companyId:String,customerId:String) async throws -> [ServiceStop] {
        return try await serviceStopCollection(companyId:companyId)
            .whereField("customerId", isEqualTo: customerId)
            .whereField("serviceDate", isGreaterThan: Date().startOfDay())
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
        
        print("[ProductionDataService][getAllServiceStopsByDayAndTech] query companyId: \(companyId) techId: \(techId) start: \(start) end: \(end)")
        let snapshot = try await serviceStopCollection(companyId: companyId)
            .whereField("serviceDate", isGreaterThanOrEqualTo: start)
            .whereField("serviceDate", isLessThan: end)
            .whereField("techId", isEqualTo: techId)
            .getDocuments()
        print("[ProductionDataService][getAllServiceStopsByDayAndTech] rawDocs: \(snapshot.documents.count) ids: \(snapshot.documents.map { $0.documentID })")

        var serviceStops: [ServiceStop] = []
        for document in snapshot.documents {
            do {
                let stop = try document.data(as: ServiceStop.self)
                print("[ProductionDataService][getAllServiceStopsByDayAndTech] decoded stop id: \(stop.id) techId: \(stop.techId) serviceDate: \(stop.serviceDate) operationStatus: \(stop.operationStatus.rawValue) billingStatus: \(stop.billingStatus.rawValue) category: \(stop.resolvedCategory.rawValue)")
                serviceStops.append(stop)
            } catch {
                let data = document.data()
                print("[ProductionDataService][getAllServiceStopsByDayAndTech] decode error docId: \(document.documentID) error: \(error)")
                print("[ProductionDataService][getAllServiceStopsByDayAndTech] raw fields docId: \(document.documentID) techId: \(String(describing: data[ServiceStop.CodingKeys.techId.stringValue])) serviceDate: \(String(describing: data[ServiceStop.CodingKeys.serviceDate.stringValue])) operationStatus: \(String(describing: data[ServiceStop.CodingKeys.operationStatus.stringValue])) billingStatus: \(String(describing: data[ServiceStop.CodingKeys.billingStatus.stringValue])) category: \(String(describing: data[ServiceStop.CodingKeys.category.stringValue])) typeId: \(String(describing: data[ServiceStop.CodingKeys.typeId.stringValue])) jobId: \(String(describing: data[ServiceStop.CodingKeys.jobId.stringValue]))")
            }
        }
        print("[ProductionDataService][getAllServiceStopsByDayAndTech] decodedStops: \(serviceStops.count)")
        return serviceStops
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
        
        let returnedMetaData = try await ServiceStopImageRefrence(companyId: companyId, id: serviceStopId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (urlString,returnedName)
    }
    func uploadServiceStopImages(
        companyId: String,
        serviceStopId: String,
        images: [DripDropImage]
    ) async throws -> [DripDropStoredImage] {

        try await withThrowingTaskGroup(of: DripDropStoredImage.self) { group in

            for image in images {
                group.addTask {
                    let (url, name) = try await self.uploadServiceStopImage(
                        companyId: companyId,
                        serviceStopId: serviceStopId,
                        image: image
                    )

                    return DripDropStoredImage(
                        id: UUID().uuidString,
                        description: name,
                        imageURL: url
                    )
                }
            }

            var uploadedImages: [DripDropStoredImage] = []

            for try await uploadedImage in group {
                uploadedImages.append(uploadedImage)
            }

            return uploadedImages
        }
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
    func updateServiceStopServiceNotes(companyId: String, serviceStopId: String, serviceNotes: String) async throws {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        try await serviceStopRef.updateData([
            ServiceStop.CodingKeys.serviceNotes.rawValue: serviceNotes
        ])
    }

    func updateInitialSurveyServiceAgreementRecommendation(
        companyId: String,
        serviceStopId: String,
        recommendedPriceCents: Int,
        rateType: String,
        notes: String,
        recommendedByUserId: String,
        recommendedByUserName: String
    ) async throws {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        let recommendedAt = Date()
        let recommendation: [String: Any] = [
            "recommendedPriceCents": recommendedPriceCents,
            "rateType": rateType,
            "notes": notes,
            "recommendedByUserId": recommendedByUserId,
            "recommendedByUserName": recommendedByUserName,
            "recommendedAt": recommendedAt
        ]

        try await serviceStopRef.updateData([
            "fieldEstimateWorkflow.initialSurveyRecommendation": recommendation,
            ServiceStop.CodingKeys.recommendedServiceAgreementPriceCents.rawValue: recommendedPriceCents,
            ServiceStop.CodingKeys.recommendedServiceAgreementRateType.rawValue: rateType,
            ServiceStop.CodingKeys.recommendedServiceAgreementNotes.rawValue: notes,
            ServiceStop.CodingKeys.recommendedServiceAgreementByUserId.rawValue: recommendedByUserId,
            ServiceStop.CodingKeys.recommendedServiceAgreementByUserName.rawValue: recommendedByUserName,
            ServiceStop.CodingKeys.recommendedServiceAgreementAt.rawValue: recommendedAt,
            "updatedAt": recommendedAt
        ])
    }

    func updateFieldJobEstimatePlan(
        companyId: String,
        serviceStopId: String,
        planId: String,
        title: String,
        notes: String,
        recommendedPriceCents: Int,
        planTier: Int,
        taskCount: Int,
        plannedStopCount: Int,
        materialCount: Int,
        recommendedByUserId: String,
        recommendedByUserName: String
    ) async throws {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        let updatedAt = Date()
        let plan: [String: Any] = [
            "planId": planId,
            "title": title,
            "notes": notes,
            "recommendedPriceCents": recommendedPriceCents,
            "planTier": planTier,
            "taskCount": taskCount,
            "plannedStopCount": plannedStopCount,
            "materialCount": materialCount,
            "shoppingItemCount": materialCount,
            "updatedAt": updatedAt,
            "updatedByUserId": recommendedByUserId,
            "updatedByUserName": recommendedByUserName
        ]

        var updateData: [String: Any] = [
            "fieldEstimateWorkflow.jobEstimatePlan": plan,
            "fieldJobPlanTitle": title,
            "fieldJobPlanNotes": notes,
            "fieldJobPlanTier": planTier,
            "updatedAt": updatedAt
        ]

        if recommendedPriceCents > 0 {
            updateData["recommendedJobEstimatePriceCents"] = recommendedPriceCents
            updateData["fieldJobPlanRecommendedPriceCents"] = recommendedPriceCents
        }

        try await serviceStopRef.updateData(updateData)
    }

    func updateServiceStopServiceDate(companyId:String,serviceStop:ServiceStop,serviceDate:Date,companyUser:CompanyUser) async throws{
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        try await ref.updateData([
            ServiceStop.CodingKeys.serviceDate.rawValue: serviceDate,
            ServiceStop.CodingKeys.techId.rawValue: companyUser.userId,
            ServiceStop.CodingKeys.tech.rawValue: companyUser.userName,
        ])

        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: serviceStop.serviceDate,
            techId: serviceStop.techId,
            techName: serviceStop.tech
        )

        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: serviceDate,
            techId: companyUser.userId,
            techName: companyUser.userName
        )
    }

    func updateScheduledJobServiceStop(
        companyId:String,
        serviceStop:ServiceStop,
        serviceDate:Date,
        companyUser:CompanyUser,
        description:String,
        estimatedDuration:Int,
        manualPayOverrideCents:Int?,
        manualPayOverrideNotes:String?,
        serviceStopTypeFields:ServiceStopTypeFields
    ) async throws {
        let ref = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        var updateData: [String: Any] = [
            ServiceStop.CodingKeys.serviceDate.rawValue: serviceDate,
            ServiceStop.CodingKeys.techId.rawValue: companyUser.userId,
            ServiceStop.CodingKeys.tech.rawValue: companyUser.userName,
            ServiceStop.CodingKeys.description.rawValue: description,
            ServiceStop.CodingKeys.estimatedDuration.rawValue: estimatedDuration,
            ServiceStop.CodingKeys.typeId.rawValue: serviceStopTypeFields.typeId,
            ServiceStop.CodingKeys.type.rawValue: serviceStopTypeFields.type,
            ServiceStop.CodingKeys.typeImage.rawValue: serviceStopTypeFields.typeImage,
            ServiceStop.CodingKeys.category.rawValue: serviceStopTypeFields.category.rawValue
        ]

        if let manualPayOverrideCents {
            updateData[ServiceStop.CodingKeys.manualPayOverrideCents.rawValue] = manualPayOverrideCents
        } else {
            updateData[ServiceStop.CodingKeys.manualPayOverrideCents.rawValue] = FieldValue.delete()
        }

        if let manualPayOverrideNotes {
            updateData[ServiceStop.CodingKeys.manualPayOverrideNotes.rawValue] = manualPayOverrideNotes
        } else {
            updateData[ServiceStop.CodingKeys.manualPayOverrideNotes.rawValue] = FieldValue.delete()
        }

        try await ref.updateData(updateData)

        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: serviceStop.serviceDate,
            techId: serviceStop.techId,
            techName: serviceStop.tech
        )

        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: serviceDate,
            techId: companyUser.userId,
            techName: companyUser.userName
        )
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
    func updateServicestopOperationStatus(companyId: String, serviceStopId: String, operationStatus: ServiceStopOperationStatus) async throws {
        print("updateServicestopOperationStatus  - [dataService]")
        print("Service Stop Id : \(serviceStopId)")
        
        print("Company Id : \(companyId)")
            let itemRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
            
        try await itemRef.updateData([
            ServiceStop.CodingKeys.operationStatus.rawValue:operationStatus.rawValue
        ])

        let updatedStop = try await itemRef.getDocument(as: ServiceStop.self)
        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: updatedStop.serviceDate,
            techId: updatedStop.techId,
            techName: updatedStop.tech
        )
    }
    func updateServiceStopStartTime(companyId:String,serviceStopId:String,startTime:Date) async throws{
        let itemRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)

        try await itemRef.updateData([
            ServiceStop.CodingKeys.startTime.rawValue:startTime
        ])
    }
    func updateServiceStopEndTime(companyId:String,serviceStopId:String,endTime:Date) async throws{
        let itemRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        let existingStop = try? await itemRef.getDocument(as: ServiceStop.self)
        var data: [String: Any] = [
            ServiceStop.CodingKeys.endTime.rawValue: endTime
        ]

        if let existingStop,
           let durationMinutes = actualServiceStopDurationMinutes(
            startTime: existingStop.startTime,
            endTime: endTime
           ) {
            data[ServiceStop.CodingKeys.duration.rawValue] = durationMinutes
        }

        try await itemRef.updateData(data)

        let updatedStop = try await itemRef.getDocument(as: ServiceStop.self)

        if updatedStop.operationStatus == .finished {
            _ = try? await updateFutureServiceStopEstimatedDurationsFromHistory(
                companyId: companyId,
                sourceStop: updatedStop
            )
        }

        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: updatedStop.serviceDate,
            techId: updatedStop.techId,
            techName: updatedStop.tech
        )
    }
    func finishServiceStopImmediately(
        companyId: String,
        serviceStop: ServiceStop,
        endTime: Date,
        duration: Int?,
        completedByUserId: String,
        sendServiceReport: Bool
    ) async throws {
        let serviceStopRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        let completionWorkRef = db
            .collection("companies")
            .document(companyId)
            .collection("serviceStopCompletionWork")
            .document(serviceStop.id)

        let requestId = "comp_ss_completion_" + UUID().uuidString
        var serviceStopUpdate: [String: Any] = [
            ServiceStop.CodingKeys.operationStatus.rawValue: ServiceStopOperationStatus.finished.rawValue,
            ServiceStop.CodingKeys.endTime.rawValue: endTime,
            "completionWorkStatus": "queued",
            "completionWorkRequestId": requestId,
            "completionWorkQueuedAt": FieldValue.serverTimestamp(),
            "completionWorkQueuedByUserId": completedByUserId,
            "completionWorkSendServiceReport": sendServiceReport
        ]

        if let duration {
            serviceStopUpdate[ServiceStop.CodingKeys.duration.rawValue] = duration
        }

        let completionWork: [String: Any] = [
            "id": serviceStop.id,
            "requestId": requestId,
            "companyId": companyId,
            "serviceStopId": serviceStop.id,
            "status": "queued",
            "queuedAt": FieldValue.serverTimestamp(),
            "queuedByUserId": completedByUserId,
            "sendServiceReport": sendServiceReport,
            "operationStatus": ServiceStopOperationStatus.finished.rawValue,
            "serviceDate": serviceStop.serviceDate,
            "techId": serviceStop.techId,
            "techName": serviceStop.tech,
            "attempts": 0
        ]

        let batch = db.batch()
        batch.updateData(serviceStopUpdate, forDocument: serviceStopRef)
        batch.setData(completionWork, forDocument: completionWorkRef, merge: true)
        try await batch.commit()
    }

    private func updateFutureServiceStopEstimatedDurationsFromHistory(
        companyId: String,
        sourceStop: ServiceStop
    ) async throws -> Int {
        guard let estimate = try await historicalServiceStopDurationEstimate(
            companyId: companyId,
            sourceStop: sourceStop
        ) else {
            return 0
        }

        let candidates = try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: sourceStop.serviceLocationId)
            .getDocuments(as: ServiceStop.self)

        let futureStops = candidates.filter { stop in
            stop.id != sourceStop.id &&
            stop.operationStatus == .notFinished &&
            stop.serviceDate > sourceStop.serviceDate &&
            serviceStopMatchesDurationProfile(stop, sourceStop: sourceStop) &&
            stop.estimatedDuration != estimate
        }

        for stop in futureStops {
            try await serviceStopDocument(serviceStopId: stop.id, companyId: companyId)
                .updateData([
                    ServiceStop.CodingKeys.estimatedDuration.rawValue: estimate
                ])
        }

        return futureStops.count
    }

    private func historicalServiceStopDurationEstimate(
        companyId: String,
        sourceStop: ServiceStop
    ) async throws -> Int? {
        guard !sourceStop.serviceLocationId.isEmpty else { return nil }

        let candidates = try await serviceStopCollection(companyId: companyId)
            .whereField(ServiceStop.CodingKeys.serviceLocationId.rawValue, isEqualTo: sourceStop.serviceLocationId)
            .getDocuments(as: ServiceStop.self)

        let durations = candidates
            .filter { stop in
                stop.id == sourceStop.id ||
                (
                    stop.operationStatus == .finished &&
                    stop.serviceDate <= sourceStop.serviceDate &&
                    serviceStopMatchesDurationProfile(stop, sourceStop: sourceStop)
                )
            }
            .compactMap { actualDurationMinutes(for: $0) }
            .sorted()

        guard !durations.isEmpty else { return nil }

        let middleIndex = durations.count / 2
        if durations.count.isMultiple(of: 2) {
            return max(1, Int((Double(durations[middleIndex - 1] + durations[middleIndex]) / 2.0).rounded()))
        }

        return max(1, durations[middleIndex])
    }

    private func serviceStopMatchesDurationProfile(_ stop: ServiceStop, sourceStop: ServiceStop) -> Bool {
        guard stop.serviceLocationId == sourceStop.serviceLocationId else { return false }

        if !sourceStop.recurringServiceStopId.isEmpty {
            return stop.recurringServiceStopId == sourceStop.recurringServiceStopId
        }

        if !sourceStop.typeId.isEmpty {
            return stop.typeId == sourceStop.typeId
        }

        let stopType = stop.type.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceType = sourceStop.type.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sourceType.isEmpty else { return true }

        return stopType.caseInsensitiveCompare(sourceType) == .orderedSame
    }

    private func actualDurationMinutes(for stop: ServiceStop) -> Int? {
        if stop.duration > 0 {
            return stop.duration
        }

        return actualServiceStopDurationMinutes(
            startTime: stop.startTime,
            endTime: stop.endTime
        )
    }

    private func actualServiceStopDurationMinutes(startTime: Date?, endTime: Date?) -> Int? {
        guard let startTime,
              let endTime,
              endTime > startTime else {
            return nil
        }

        return max(1, Int(ceil(endTime.timeIntervalSince(startTime) / 60)))
    }
    func updateServicestopBillingStatus(companyId: String, serviceStop: ServiceStop, billingStatus: ServiceStopBillingStatus) async throws {
        let itemRef = serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId)
        
        try await itemRef.updateData([
            ServiceStop.CodingKeys.billingStatus.rawValue:billingStatus.rawValue
        ])
    }
    //Delete

    func deleteServiceStop(companyId:String,serviceStop:ServiceStop)async throws {
        if serviceStop.operationStatus == .finished || serviceStop.endTime != nil {
            throw DeleteProtectionError.finishedServiceStop
        }

        try await deleteServiceStopRelatedData(companyId: companyId, serviceStopId: serviceStop.id)
        try await serviceStopDocument(serviceStopId: serviceStop.id, companyId: companyId).delete()
        _ = try? await syncActiveRouteForServiceStops(
            companyId: companyId,
            date: serviceStop.serviceDate,
            techId: serviceStop.techId,
            techName: serviceStop.tech
        )

    }
    func deleteServiceStopById(companyId:String,serviceStopId:String)async throws {
        let ref = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)
        let serviceStopSnapshot = try await ref.getDocument()
        let serviceStop: ServiceStop?
        if serviceStopSnapshot.exists {
            serviceStop = try serviceStopSnapshot.data(as: ServiceStop.self)
        } else {
            serviceStop = nil
        }

        if let serviceStop,
           serviceStop.operationStatus == .finished || serviceStop.endTime != nil {
            throw DeleteProtectionError.finishedServiceStop
        }

        try await deleteServiceStopRelatedData(companyId: companyId, serviceStopId: serviceStopId)
        try await ref.delete()

        if let serviceStop {
            _ = try? await syncActiveRouteForServiceStops(
                companyId: companyId,
                date: serviceStop.serviceDate,
                techId: serviceStop.techId,
                techName: serviceStop.tech
            )
        }

    }

    private func deleteServiceStopRelatedData(companyId: String, serviceStopId: String) async throws {
        let batch = db.batch()
        let stopRef = serviceStopDocument(serviceStopId: serviceStopId, companyId: companyId)

        let tasks = try await stopRef.collection("tasks").getDocuments()
        for document in tasks.documents {
            batch.deleteDocument(document.reference)
        }

        let stores = try await stopRef.collection("stores").getDocuments()
        for document in stores.documents {
            batch.deleteDocument(document.reference)
        }

        let history = try await stopRef.collection("history").getDocuments()
        for document in history.documents {
            batch.deleteDocument(document.reference)
        }

        let stopData = try await stopDataCollection(companyId: companyId)
            .whereField("serviceStopId", isEqualTo: serviceStopId)
            .getDocuments()
        for document in stopData.documents {
            batch.deleteDocument(document.reference)
        }

        try await batch.commit()
    }
}
