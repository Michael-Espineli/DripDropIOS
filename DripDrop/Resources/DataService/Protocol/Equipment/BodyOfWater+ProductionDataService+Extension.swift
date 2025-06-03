//
//  BodyOfWater+ProductionDataService+Extension.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/6/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import SwiftUI
import CoreLocation
import MapKit
import FirebaseStorage

extension ProductionDataService {
    
    func bodyOfWaterCollection(companyId:String) -> CollectionReference{
        db.collection("companies/\(companyId)/bodiesOfWater")
    }
    
    func bodyOfWaterDoc(companyId:String,bodyOfWaterId:String)-> DocumentReference{
        bodyOfWaterCollection(companyId: companyId).document(bodyOfWaterId)
    }
    func bodyOfWaterImageRefrence(id:String)->StorageReference {
        storage.child("bodyOfWater").child(id)
    }
    //Create
    
    //Read
    //Update
    func uploadBodyOfWaterImage(companyId: String,bodyOfWaterId:String, image: DripDropImage) async throws ->(path:String, name:String){
        guard let data = image.image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
        let returnedMetaData = try await bodyOfWaterImageRefrence(id: bodyOfWaterId).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        
        let urlString = try await Storage.storage().reference(withPath: returnedPath).downloadURL().absoluteString
        return (path:urlString,name:returnedName)
    }
    func updateBodyOfWaterPhotoURLs(companyId: String, bodyOfWaterId: String, photoUrls: [DripDropStoredImage]) async throws {
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId)

        for image in photoUrls {
            try await bodyOfWaterRef.updateData([
                BodyOfWater.CodingKeys.photoUrls.rawValue: FieldValue.arrayUnion([
                    [
                    "id":image.id,
                    "description":image.description,
                    "imageURL":image.imageURL
                    ]
                ])
            ])
        }
    }
    func updateBodyOfWaterLastFilledDate(companyId: String, bodyOfWaterId: String, lastFilled: Date) async throws {
        let bodyOfWaterRef = bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
        try await bodyOfWaterRef.updateData([
            BodyOfWater.CodingKeys.lastFilled.rawValue: lastFilled
        ])
    }
    //Delete
    func deleteBodyOfWater(companyId:String,bodyOfWaterId:String) async throws {
        try await bodyOfWaterDoc(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
            .delete()
    }
}
