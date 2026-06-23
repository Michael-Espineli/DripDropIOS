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
    func createLocation(
        companyId: String,
        customerId: String,
        serviceLocationId: String,
        bodyOfWaterList: [BodyOfWater],
        equipmentList: [Equipment],
        bodyOfWaterImages: [String:[DripDropImage]],
        equipmentImages: [String:[DripDropImage]],
        locationNickName: String? = nil,
        gateCode: String? = nil,
        locationNotes: String? = nil,
        serviceLocationPhotos: [DripDropImage] = []
    ) async throws {
        self.isLoading = true
        defer { self.isLoading = false }
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

        let existingBodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(
            companyId: companyId,
            serviceLocationId: serviceLocationId
        )
        let existingEquipment = try await dataService.getEquipmentByServiceLocationId(
            companyId: companyId,
            serviceLocationId: serviceLocationId
        )
        let reconciledBodiesOfWater = reconciledBodyOfWaterList(
            incoming: bodyOfWaterList,
            existing: existingBodiesOfWater,
            customerId: customerId,
            serviceLocationId: serviceLocationId
        )
        var bodyOfWaterIdMap: [String:String] = [:]
        for (incomingBodyOfWater, reconciledBodyOfWater) in zip(bodyOfWaterList, reconciledBodiesOfWater) {
            bodyOfWaterIdMap[incomingBodyOfWater.id] = reconciledBodyOfWater.id
        }
        let reconciledEquipment = reconciledEquipmentList(
            incoming: equipmentList,
            existing: existingEquipment,
            bodyOfWaterIdMap: bodyOfWaterIdMap,
            customerId: customerId,
            serviceLocationId: serviceLocationId
        )

        if let locationNickName {
            try await dataService.updateServiceLocationNickName(
                companyId: companyId,
                serviceLocationId: serviceLocationId,
                nickName: locationNickName
            )
        }

        if let gateCode {
            try await dataService.updateServiceLocationGateCode(
                companyId: companyId,
                serviceLocationId: serviceLocationId,
                gateCode: gateCode
            )
        }

        if let locationNotes {
            try await dataService.updateServiceLocationNotes(
                companyId: companyId,
                serviceLocationId: serviceLocationId,
                notes: locationNotes
            )
        }

        if !serviceLocationPhotos.isEmpty {
            var storedServiceLocationImages: [DripDropStoredImage] = []

            for image in serviceLocationPhotos {
                let result = try await dataService.uploadServiceLocationImage(
                    companyId: companyId,
                    serviceLocationId: serviceLocationId,
                    image: image
                )
                storedServiceLocationImages.append(
                    DripDropStoredImage(description: image.name, imageURL: result.path)
                )
            }

            try await dataService.updateServiceLocationPhotoURLs(
                companyId: companyId,
                serviceLocationId: serviceLocationId,
                photoUrls: storedServiceLocationImages
            )
        }

        for BOW in reconciledBodiesOfWater {
            //Upload Body Of Water Images
            var storedBOWImages:[DripDropStoredImage] = []
            let bodyOfWaterImageKey = bodyOfWaterImages.keys.first { imageKey in
                imageKey == BOW.id || bodyOfWaterIdMap[imageKey] == BOW.id
            }
            if let BOWImageKey = bodyOfWaterImageKey,let BOWDripDropImages = bodyOfWaterImages[BOWImageKey] {
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

            uploadBodyOfWater.photoUrls = mergedStoredImages(
                existing: uploadBodyOfWater.photoUrls,
                new: storedBOWImages
            )
            print("uploadBodyOfWater \(uploadBodyOfWater)")

            print("")

            //Upload Body Of Water
            try await dataService.uploadBodyOfWaterByServiceLocation(companyId: companyId, bodyOfWater: uploadBodyOfWater)
            let selectedEquipmentList = reconciledEquipment.filter({$0.bodyOfWaterId == BOW.id})
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
                uploadEquipment.photoUrls = mergedStoredImages(
                    existing: uploadEquipment.photoUrls,
                    new: storedEquipmentImages
                )
                //Upload Equipment

                try await dataService.uploadEquipment(companyId: companyId, equipment: uploadEquipment)
            }
        }
    }

    private func reconciledBodyOfWaterList(
        incoming: [BodyOfWater],
        existing: [BodyOfWater],
        customerId: String,
        serviceLocationId: String
    ) -> [BodyOfWater] {
        var unmatchedExisting = existing

        return incoming.map { bodyOfWater in
            var uploadBodyOfWater = bodyOfWater

            if let match = matchBodyOfWater(
                bodyOfWater,
                existing: unmatchedExisting,
                incomingCount: incoming.count
            ) {
                uploadBodyOfWater.id = match.id
                uploadBodyOfWater.photoUrls = match.photoUrls
                unmatchedExisting.removeAll { $0.id == match.id }
            }

            uploadBodyOfWater.customerId = customerId
            uploadBodyOfWater.serviceLocationId = serviceLocationId
            return uploadBodyOfWater
        }
    }

    private func matchBodyOfWater(
        _ bodyOfWater: BodyOfWater,
        existing: [BodyOfWater],
        incomingCount: Int
    ) -> BodyOfWater? {
        if let exact = existing.first(where: { $0.id == bodyOfWater.id }) {
            return exact
        }

        let incomingName = normalizedSurveyName(bodyOfWater.name)
        if let sameName = existing.first(where: { normalizedSurveyName($0.name) == incomingName }) {
            return sameName
        }

        if incomingCount == 1, existing.count == 1 {
            return existing[0]
        }

        return nil
    }

    private func reconciledEquipmentList(
        incoming: [Equipment],
        existing: [Equipment],
        bodyOfWaterIdMap: [String:String],
        customerId: String,
        serviceLocationId: String
    ) -> [Equipment] {
        var unmatchedExisting = existing

        return incoming.map { equipment in
            let resolvedBodyOfWaterId = bodyOfWaterIdMap[equipment.bodyOfWaterId] ?? equipment.bodyOfWaterId
            var uploadEquipment = equipment
            uploadEquipment.bodyOfWaterId = resolvedBodyOfWaterId

            if let match = matchEquipment(
                uploadEquipment,
                existing: unmatchedExisting,
                incoming: incoming,
                bodyOfWaterIdMap: bodyOfWaterIdMap
            ) {
                uploadEquipment.id = match.id
                uploadEquipment.photoUrls = match.photoUrls
                unmatchedExisting.removeAll { $0.id == match.id }
            }

            uploadEquipment.customerId = customerId
            uploadEquipment.serviceLocationId = serviceLocationId
            return uploadEquipment
        }
    }

    private func matchEquipment(
        _ equipment: Equipment,
        existing: [Equipment],
        incoming: [Equipment],
        bodyOfWaterIdMap: [String:String]
    ) -> Equipment? {
        if let exact = existing.first(where: { $0.id == equipment.id }) {
            return exact
        }

        let sameBodyAndType = existing.filter {
            $0.bodyOfWaterId == equipment.bodyOfWaterId &&
            $0.type == equipment.type
        }
        let incomingSameBodyAndType = incoming.filter {
            (bodyOfWaterIdMap[$0.bodyOfWaterId] ?? $0.bodyOfWaterId) == equipment.bodyOfWaterId &&
            $0.type == equipment.type
        }
        let incomingName = normalizedSurveyName(equipment.name)

        if let sameName = sameBodyAndType.first(where: { normalizedSurveyName($0.name) == incomingName }) {
            return sameName
        }

        if sameBodyAndType.count == 1, incomingSameBodyAndType.count == 1 {
            return sameBodyAndType[0]
        }

        return nil
    }

    private func mergedStoredImages(
        existing: [DripDropStoredImage]?,
        new: [DripDropStoredImage]
    ) -> [DripDropStoredImage] {
        var seenImageURLs: Set<String> = []

        return ((existing ?? []) + new).filter { image in
            seenImageURLs.insert(image.imageURL).inserted
        }
    }

    private func normalizedSurveyName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
