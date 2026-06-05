//
//  AddRepairRequestViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/2/25.
//

import Foundation
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit
import FirebaseStorage
import AVFoundation

@MainActor
final class AddRepairRequestViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    private static var emptyEquipment: Equipment {
        Equipment(
            id: "",
            name: "",
            type: .filter,
            typeId: "",
            make: "",
            makeId: "",
            model: "",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: false,
            notes: "",
            customerName: "",
            customerId: "",
            serviceLocationId: "",
            bodyOfWaterId: "",
            isActive: true
        )
    }
    
    @Published var selectedCustomer: Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var selectedLocation: ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0),
        gateCode: "",
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        isActive: true
    )
    @Published var selectedBodyOfWater: BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled:Date(),
        isActive: true
    )

    @Published var customerList: [Customer] = []
    @Published var serviceLocationList: [ServiceLocation] = []
    @Published var bodyOfWaterList: [BodyOfWater] = []
    @Published var equipmentList: [Equipment] = []
    @Published var selectedEquipment: Equipment = AddRepairRequestViewModel.emptyEquipment {
        didSet {
            if selectedEquipment.id != "" {
                selectedEquipmentStatus = selectedEquipment.status == .operational ? .needsRepair : selectedEquipment.status
            }
        }
    }
    @Published var selectedEquipmentStatus: EquipmentStatus = .needsRepair

    //Form
    @Published var repairRequestId: String = ""
    @Published var selectedPhotos:[PhotoAsset] = []
    @Published var loadImages:Bool = true
    @Published var screenLoading:Bool = false
    @Published var selectedDripDropPhotos:[DripDropImage] = []
    @Published var savedDripDropPhotos:[DripDropStoredImage] = []
    @Published var description:String = ""
    @Published var showCustomerSelector:Bool = false
    @Published var showLocationSelector:Bool = false
    @Published var showBodyOfWaterSelector:Bool = false
    @Published var showEquipmentSelector: Bool = false
    @Published var showEquipmentStatusSelector: Bool = false

    @Published var showAddPhoto:Bool = false
//    @Published var pickerType:photoPickerType? = nil
//    @Published var selectedNewPicker:photoPickerType? = nil
    @Published var selectedImage:UIImage? = nil
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    
    @State var photoUrls:[String] = []
    
    func onLoad(companyId:String,customer: Customer?) async throws {
        let customerList = try await dataService.getCustomersActiveAndLastName(companyId: companyId, active: true, lastNameHigh: false)
        if let customer {
            if let firstCustomer = customerList.first(where: {$0.id == customer.id}) {
                self.selectedCustomer = firstCustomer
            }
        }
    }
    func onChangeCustomer(companyId:String,_ customer: Customer) async throws{
        if customer.id != "" {
            self.serviceLocationList = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId,customerId: customer.id)
            if let firstLocation = self.serviceLocationList.first {
                self.selectedLocation = firstLocation
            }
        }
    }
    func onChangeLocation(companyId:String,_ location: ServiceLocation) async throws{
        if location.id != "" {
            self.bodyOfWaterList = try await dataService.getAllBodiesOfWaterByServiceLocation(companyId: companyId, serviceLocation: location)
            if let firstBodyOfWater = self.bodyOfWaterList.first {
                self.selectedBodyOfWater = firstBodyOfWater
            }
            self.equipmentList = try await dataService.getEquipmentByServiceLocationId(companyId: companyId, serviceLocationId: location.id)
            self.selectedEquipment = AddRepairRequestViewModel.emptyEquipment
            self.selectedEquipmentStatus = .needsRepair
        }
    }
    func uploadRepairRequestWithValidation(
        companyId:String,
        requesterId:String,
        requesterName:String
//        ,
//        repairRequestId:String,
//        customerId:String,
//        customerName:String,
//        date:Date,
//        status:RepairRequestStatus,
//        description:String,
//        jobIds:[String],
//        images:[DripDropImage],
//        serviceLocationId:String?,
//        bodyOfWaterId:String?,
//        equipmentId:String?
    ) async throws {
        self.repairRequestId = "com_rr_" + UUID().uuidString
        var photoUrls:[DripDropStoredImage] = []
        var status = RepairRequestStatus.unresolved
        if status == .inprogress || status == .unresolved || status == .inprogress {
            print("Good Repair Request Status")
            
        } else {
            throw RepairRequestError.invalidStatus

        }
        if selectedCustomer.id == "" {
            throw RepairRequestError.invalidCustomer

        }
        if requesterId == "" {
            throw RepairRequestError.invalidUser

        }
        if description == "" {
            throw RepairRequestError.noDescription
        }
        var pushServiceLocationId = ""
        if selectedLocation.id != "" {
            pushServiceLocationId = selectedLocation.id
        }
        var pushBodyOfWaterId = ""
        if selectedBodyOfWater.id != "" {
            pushBodyOfWaterId = selectedBodyOfWater.id
        }
        var pushEquipmentId = ""
        if selectedEquipment.id != "" {
            pushEquipmentId = selectedEquipment.id
        }
        
        // Images

        print("trying to upLoad \(selectedDripDropPhotos.count)Images")
        for image in selectedDripDropPhotos {
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
        if selectedDripDropPhotos.count == photoUrls.count {
            print("All photoUrls Uploaded")
        } else {
            print("Missing Images Please wait until Processed")
            throw RepairRequestError.imagesNotLoaded
        }
        let fullName = selectedCustomer.firstName + " " + selectedCustomer.lastName
        //Get Repair Request ID
        try await dataService.uploadRepairRequest(
            companyId: companyId,
            repairRequest: RepairRequest(
                id: repairRequestId,
                customerId: selectedCustomer.id,
                customerName: fullName,
                requesterId: requesterId,
                requesterName: requesterName,
                date: Date(),
                status: status,
                description: description,
                jobIds: [],
                photoUrls: photoUrls,
                locationId: pushServiceLocationId,
                bodyOfWaterId: pushBodyOfWaterId,
                equipmentId: pushEquipmentId
            )
        )
        if pushEquipmentId != "" {
            try dataService.updateEquipmentStatus(
                companyId: companyId,
                equipmentId: pushEquipmentId,
                status: selectedEquipmentStatus
            )
        }
        self.repairRequestId = ""
    }
    
}
