//
//  EmailConfigurationViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 9/26/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class EmailConfigurationViewModel: ObservableObject {
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
