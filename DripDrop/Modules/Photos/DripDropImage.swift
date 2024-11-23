//
//  DripDropImage.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/25/24.
//


import UIKit

struct DripDropImage: Identifiable, Codable {
    var id = UUID()
    var name: String
    
    var image: UIImage {
        do {
            return try FileManager().readImage(with: id)
        } catch {
            return UIImage(systemName: "photo.fill")!
        }
    }
}
