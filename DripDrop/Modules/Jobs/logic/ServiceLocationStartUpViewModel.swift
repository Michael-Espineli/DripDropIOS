//
//  ServiceLocationStartUpViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/30/24.
//

import Foundation
import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

@MainActor
final class ServiceLocationStartUpViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var isLoading:Bool = false
    func createLocation(companyId:String,customerId:String,serviceLocationId:String,bodyOfWaterList:[BodyOfWater],equipmentList:[Equipment],bodyOfWaterImages:[String:[DripDropImage]],equipmentImages:[String:[DripDropImage]])async throws {
        self.isLoading = true
        print("")
        print("Set up Service Location for \(serviceLocationId)")
        print("")
        print("companyId \(companyId)")
        print("")
        print("customerId \(customerId)")
        print("")
        print("serviceLocationId \(serviceLocationId)")
        print("")
        print("bodyOfWaterList \(bodyOfWaterList)")
        print("")
        print("equipmentList \(equipmentList)")
        print("")
        print("bodyOfWaterImages \(bodyOfWaterImages)")
        print("")
        print("equipmentImages \(equipmentImages)")
        print("")

        for BOW in bodyOfWaterList {
            //Upload Body Of Water Images
            var storedBOWImages:[DripDropStoredImage] = []
            if let BOWImageKey = bodyOfWaterImages.keys.first(where: {$0 == BOW.id}),let BOWDripDropImages = bodyOfWaterImages[BOWImageKey] {
                for image in BOWDripDropImages {
                    let result = try await dataService.uploadBodyOfWaterImage(companyId: companyId, bodyOfWaterId: BOW.id, image: image)
                    print("")
                    print("result \(result)")
                    storedBOWImages.append(DripDropStoredImage(description: image.name, imageURL: result.path))
                }
                
            }
            //Create Body Of Water
            var uploadBodyOfWater = BOW
            uploadBodyOfWater.serviceLocationId = serviceLocationId
            uploadBodyOfWater.customerId = customerId
            print("")

            print("Converted Images \(storedBOWImages)")
            print("")

            uploadBodyOfWater.photoUrls = storedBOWImages
            print("uploadBodyOfWater \(uploadBodyOfWater)")

            print("")

            //Upload Body Of Water
            try await dataService.uploadBodyOfWaterByServiceLocation(companyId: companyId, bodyOfWater: uploadBodyOfWater)
            let selectedEquipmentList = equipmentList.filter({$0.bodyOfWaterId == BOW.id})
            for equipment in selectedEquipmentList {
                //Upload Equipment Images
                var storedEquipmentImages:[DripDropStoredImage] = []
                if let equipmentImageKey = equipmentImages.keys.first(where: {$0 == equipment.id}),let equipmentDripDropImages = equipmentImages[equipmentImageKey] {
                    for image in equipmentDripDropImages {
                        let result = try await dataService.uploadEquipmentImage(companyId: companyId, equipmentId: equipment.id, image: image)
                        storedEquipmentImages.append(DripDropStoredImage(description: image.name, imageURL: result.path))
                    }
                    
                }
                //Create Equipment
                var uploadEquipment = equipment
                uploadEquipment.photoUrls = storedEquipmentImages
                //Upload Equipment

                try await dataService.uploadEquipment(companyId: companyId, equipment: uploadEquipment)
            }
            self.isLoading = false
        }
    }
}
