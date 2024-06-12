//
//  ReceiptFileManager.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//
import Foundation
import FirebaseStorage
#if os(iOS)
import UIKit
#endif
final class ReceiptFileManager {
    static let shared = ReceiptFileManager()
    private init(){}
    
    var storage = Storage.storage().reference()

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            STORAGE REFRENCES
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    private func receiptReference(receipt:Receipt)->StorageReference {
        storage.child("receipts").child(receipt.id)
    }
    private func getPathForImage(path:String) -> StorageReference {
        Storage.storage().reference(withPath: path)
        
    }
    func getUrlForReceipt(path:String) async throws-> URL {
        try await getPathForImage(path: path).downloadURL()
    }

    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            CREATE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func savePdf(companyId:String,receipt:Receipt,data:Data) async throws ->(path:String, name:String) {
        
        let path = "\(UUID().uuidString).pdf"
        
        let meta = StorageMetadata()
        meta.contentType = "application/pdf"
        
            let returnedMetaData = try await receiptReference(receipt: receipt).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        return (returnedPath,returnedName)
    }
    func saveImage(companyId:String,receipt:Receipt,data:Data) async throws ->(path:String, name:String) {
        
        let path = "\(UUID().uuidString).jpeg"
        print("path >> \(path)")
        
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        print("meta >> \(meta)")
        
            let returnedMetaData = try await receiptReference(receipt: receipt).child(path)
            .putDataAsync(data,metadata: meta)
        print("returnedMetaData >> \(returnedMetaData)")
        
        guard let returnedPath = returnedMetaData.path, let returnedName = returnedMetaData.name else {
            throw URLError(.badServerResponse)
        }
        
        print("SUCCESS 1")
        return (returnedPath,returnedName)
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            READ
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    func getData(user:DBUser,path:String) async throws -> Data {
        print("Arrived at get Data attemping to get Image Data")
        
        let data = try await storage.child(path).data(maxSize: 3 * 800 * 800)

        print("Data in getData Function >>\(data)")
        return data
    }
#if os(iOS)

    func getPdf(user:DBUser,path:String) async throws -> UIImage{
        
        let data = try await getData(user: user, path: path)
        print("Image for get data >>\(data)")
        guard let image = UIImage(data: data) else {
            print("Could not convert image data to image ")
            throw URLError(.badServerResponse)
        }
        return image
    }
    #endif
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //                            DELETE
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    func deleteImage(path:String)async throws{
        try await getPathForImage(path: path).delete()
    }
}

