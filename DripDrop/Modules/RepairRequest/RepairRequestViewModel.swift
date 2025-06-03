//
//  RepairRequestViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
import FirebaseStorage
import AVFoundation

@MainActor
final class RepairRequestViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var contract: RepairRequest? = nil

    @Published private(set) var count: Int? = nil
    
    @Published private(set) var iamgeUrl: URL? = nil
    @Published private(set) var imageUrlString: String? = nil
    //ARRAYS
    @Published private(set) var listOfContrats:[RepairRequest] = []

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------

    func uploadRepairRequestWithValidation(companyId:String,repairRequestId:String,customerId:String,customerName:String,requesterId:String,requesterName:String,date:Date,status:RepairRequestStatus,description:String,jobIds:[String],images:[DripDropImage],serviceLocationId:String?,bodyOfWaterId:String?,equipmentId:String?) async throws {
        var photoUrls:[DripDropStoredImage] = []
        
        if status == .inprogress || status == .unresolved || status == .inprogress {
            print("Good Repair Request Status")
            
        } else {
            throw RepairRequestError.invalidStatus

        }
        if customerId == "" {
            throw RepairRequestError.invalidCustomer

        }
        if requesterId == "" {
            throw RepairRequestError.invalidUser

        }
        if description == "" {
            throw RepairRequestError.noDescription
        }
        var pushServiceLocationId:String? = nil
        if let serviceLocationId {
            if serviceLocationId != "" {
                pushServiceLocationId = serviceLocationId
            }
        }
        
        var pushBodyOfWaterId:String? = nil
        if let bodyOfWaterId {
            if bodyOfWaterId != "" {
                pushBodyOfWaterId = bodyOfWaterId
            }
        }
        
        var pushEquipmentId:String? = nil
        if let equipmentId {
            if equipmentId != "" {
                pushEquipmentId = equipmentId
            }
        }
        // Images

        print("trying to upLoad \(images.count)Images")
        for image in images {
            guard let data = image.image.pngData() else {
                print("Error Converting Photo Picker Item to Data")
                return
            }
            print("Converted Photo Picker Item to Data")
            let (path,name) = try await StorageManager.shared.saveRepairRequestImage(companyId: companyId, requestId: repairRequestId, data: data)
            print("SUCCESS 2")
            print("Path \(path)")
            print("Name \(name)")
            let url = try await Storage.storage().reference(withPath: path).downloadURL() //DEVELOPER FIX This. EITHER MAKE INTO BACKGROUND TASK
            
            photoUrls.append(DripDropStoredImage(description: image.name, imageURL: url.absoluteString))
        }
        if images.count == photoUrls.count {
            print("All photoUrls Uploaded")
        } else {
            print("Missing Images Please wait until Processed")
            throw RepairRequestError.imagesNotLoaded
        }
        //Get Repair Request ID
        try await dataService.uploadRepairRequest(companyId: companyId, repairRequest: RepairRequest(id: repairRequestId, customerId: customerId, customerName: customerName, requesterId: requesterId, requesterName: requesterName, date: date, status: status, description: description,jobIds: jobIds,photoUrls: photoUrls,locationId:pushServiceLocationId,bodyOfWaterId: pushBodyOfWaterId,equipmentId:pushEquipmentId))
    }
    
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    
    func getAllRepairRequestsSnapShot(companyId: String) async throws {
        self.listOfContrats = try await dataService.getAllRepairRequests(companyId: companyId)
    }
    func getAllRepairRequests(companyId: String) async throws {
        self.listOfContrats = try await dataService.getAllRepairRequests(companyId: companyId)
    }
    func getAllRepairRequestsWithFilters(companyId: String,open:Bool) async throws {
        self.listOfContrats = try await dataService.getAllRepairRequests(companyId: companyId)
    }
    func getSpecificRepairRequest(companyId: String,repairRequestId:String) async throws {
        self.contract = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: repairRequestId)
    }
    func getRepairRequestsByCustomer(companyId: String,customerId:String) async throws {
        self.listOfContrats = try await dataService.getRepairRequestsByCustomer(companyId: companyId, customerId: customerId)
    }
    func getRepairRequestsByCustomerCount(companyId: String,customerId:String) async throws{
        self.count = try await dataService.getRepairRequestsByCustomerCount(companyId: companyId, customerId: customerId)

    }
    func getRepairRequestByUserCount(companyId: String,userId:String) async throws{
        self.count = try await dataService.getRepairRequestsByUserCount(companyId: companyId, userId: userId)

    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateRepairRequest(companyId:String,repairRequest:RepairRequest) async throws {
        try await dataService.updateRepairRequest(companyId: companyId, repairRequest: repairRequest)
    }
    func updateRepairRequestStatus(companyId:String,repairReuqestId:String,status:RepairRequestStatus) async throws {
        try await dataService.updateRepairRequestStatus(companyId: companyId, repairRequestId: repairReuqestId, status: status)
    }
    func updateRepairRequestJobList(companyId:String,repairReuqestId:String,jobId:String) async throws {
        try await dataService.updateRepairRequestJobList(companyId: companyId, repairRequestId: repairReuqestId, jobId: jobId)
    }
    func updateRepairRequestPhotoUrls(companyId:String,repairReuqestId:String,photoUrl:String) async throws {
        try await dataService.updateRepairRequestPhotoUrl(companyId: companyId, repairRequestId: repairReuqestId, photoUrl: photoUrl)
    }    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteRepairRequest(companyId:String,repairRequestId:String) async throws{
        try await dataService.deleteRepairRequest(companyId: companyId, repairRequestId: repairRequestId)
    }
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func saveRepairRequestImage(companyId:String,requestId:String,photo:DripDropImage) async throws{

        let result = try await dataService.uploadRepairRequestImage(companyId: companyId, requestId: requestId, image: photo)
        try await dataService.updateRepairRequestPhotoUrl(companyId: companyId, repairRequestId: requestId, photoUrl: result.path)

    }

    //----------------------------------------------------
    //                    Listeners
    //----------------------------------------------------
    func addListenerForAllRequests(companyId: String, status: [RepairRequestStatus], requesterIds: [String], startDate: Date, endDate: Date){
        print("Adding Repair Request Listener")

         dataService.addListenerForAllRepairRequests(companyId: companyId, status: status, requesterIds: requesterIds, startDate: startDate, endDate: endDate) { [weak self] chats in
            self?.listOfContrats = chats
        }
    }
    func removeListenerForRepairRequest(){
        print("Removing Request Listener")

        dataService.removeListenerForRequests()
    }

}
