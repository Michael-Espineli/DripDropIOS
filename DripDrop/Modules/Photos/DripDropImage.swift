//
//  DripDropImage.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/25/24.
//


import UIKit

struct DripDropImage: Identifiable, Codable,Equatable {
    var id = UUID()
    var name: String
    
    var image: UIImage {
        do {
            return try FileManager().readImage(with: id)
        } catch {
            return UIImage(systemName: "photo.fill")!
        }
    }
    //Var Date Taken?
    //var CCLocationCordinates?
}
struct DripDropStoredImage: Identifiable, Codable,Equatable, Hashable {
    var id = UUID().uuidString
    var description: String
    var imageURL: String
    //Var Date Taken?
    //var CCLocationCordinates?
}
