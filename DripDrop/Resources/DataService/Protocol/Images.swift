//
//  Images.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/7/24.
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
        //Needs Organizing
    
    
    func getPathForImage(path:String) -> StorageReference {
        Storage.storage().reference(withPath: path)
        
    }
    func getUrlForImage(path:String) async throws-> URL {
        try await getPathForImage(path: path).downloadURL()
    }
   
    
    
   
    
  
}
