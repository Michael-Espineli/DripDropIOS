//
//  CompanyImageManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/3/23.
//


import Foundation
import FirebaseStorage
#if os(iOS)
import UIKit
final class CompanyImageManager {
    static let shared = CompanyImageManager()
    private init(){}
    
    var storage = Storage.storage().reference()

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            STORAGE REFRENCES
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    private func companyReference(user:DBUser)->StorageReference {
        storage.child("companies").child(user.id)
    }
    private func getPathForImage(path:String) -> StorageReference {
        Storage.storage().reference(withPath: path)
        
    }
    func getUrlForImage(path:String) async throws-> URL {
        try await getPathForImage(path: path).downloadURL()
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func saveImage(user:DBUser,data:Data) async throws ->(path:String, name:String) {
        
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
            let returnedMetaData = try await companyReference(user: user).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        return (returnedPath,returnedName)
    }
    func saveImage(user:DBUser,image:UIImage) async throws ->(path:String, name:String) {
        // image.pngData
        // DEVELOPER look into image compression
        // extension resize images
        guard let data = image.jpegData(compressionQuality: 1) else {
            throw URLError(.badURL)
        }
        return try await saveImage(user: user, data: data)
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getData(user:DBUser,path:String) async throws -> Data {
        print("Arrived at get Data attemping to get Image Data")
        
//        let data = try await customerReference(user: user).child(path).data(maxSize: 3 * 800 * 800)
        let data = try await storage.child(path).data(maxSize: 3 * 800 * 800)

        print("Data in getData Function >>\(data)")
        return data
    }
    func getImage(user:DBUser,path:String) async throws -> UIImage{
        print("Arrived at get Image attemping to use get Data")
        print("Path in getImage function >> \(path)")
        print("User in getImage function >> \(user)")

        let data = try await getData(user: user, path: path)
        print("Image for get data >>\(data)")
        guard let image = UIImage(data: data) else {
            print("Could not convert image data to image ")
            throw URLError(.badServerResponse)
        }
        return image
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func deleteImage(path:String)async throws{
        try await getPathForImage(path: path).delete()
    }
}

#endif
