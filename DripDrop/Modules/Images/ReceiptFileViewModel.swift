//
//  ReceiptFileViewModel.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/4/23.
//

import Foundation
import SwiftUI
import PhotosUI
#if os(iOS)

@MainActor
final class ReceiptFileViewModel: ObservableObject{
    
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var imageData: Data? = nil
    @Published private(set) var image: UIImage? = nil
    @Published private(set) var iamgeUrl: URL? = nil
    @Published private(set) var imageUrlString: String? = nil
    
    func saveReceiptFile(companyId:String,receipt:Receipt,documentUrl:URL) {
        Task{
//            guard let data = try? Data(contentsOf: documentUrl, options: .alwaysMapped) else {
//                print("Error Getting File")
//                return
//            }
            //DEVELOPER UNSAFE VERSION ABOVE IS SAFE< BUT IS NOT WORKING
            do {
                guard documentUrl.startAccessingSecurityScopedResource() else { // Notice this line right here
                     return
                }
                let data  = try Data(contentsOf:documentUrl)
                print("Converted Photo Picker Item to Data")
                let (path,name) = try await ReceiptFileManager.shared.savePdf(companyId: companyId, receipt: receipt, data: data)
                print("SUCCESS 2")
                print("Path \(path)")
                print("Name \(name)")
                let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)
                try ReceiptManager.shared.updateReceiptPDFPath(companyId: companyId, receiptItemId: receipt.id, path: url.absoluteString)
                self.iamgeUrl = url
                self.imageUrlString = url.absoluteString
            }catch{
                print(error)
                return
            }


        }
    }
    
    func saveReceiptPhoto(companyId:String,receipt:Receipt,receiptPhoto:UIImage) {
        Task{
            guard let data = receiptPhoto.pngData() else {
                print("Error Converting Photo Picker Item to Data")
                return
            }
//            guard let data = try await receiptPhoto.loadTransferable(type: Data.self) else{
//                print("Error Converting Photo Picker Item to Data")
//                return
//            }
            print("Converted Photo Picker Item to Data")
            let (path,name) = try await ReceiptFileManager.shared.saveImage(companyId: companyId, receipt: receipt, data: data)
            print("SUCCESS 2")
            print("Path \(path)")
            print("Name \(name)")
            let url  = try await ReceiptFileManager.shared.getUrlForReceipt(path: path)

            try ReceiptManager.shared.updateReceiptPDFPath(companyId: companyId, receiptItemId: receipt.id, path: url.absoluteString)
            self.iamgeUrl = url
            self.imageUrlString = url.absoluteString
        }
    }
}
#endif
