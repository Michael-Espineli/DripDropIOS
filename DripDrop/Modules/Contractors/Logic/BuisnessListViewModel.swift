//
//  BuisnessListViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class BuisnessListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //LOADING
    @Published var buisnesses:[Company] = []
}
