//
//  JobDetailViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/22/24.
//

import Foundation
import Foundation
import SwiftUI
//import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import MapKit

@MainActor
final class JobDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
}
