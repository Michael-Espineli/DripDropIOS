//
//  MobileHomeViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/27/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
@MainActor
final class MobileHomeViewModel: ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var companyUser: CompanyUser? = nil
    
    @Published private(set) var listOfCompanies: [Company] = []
    @Published private(set) var company: Company? = nil
    
    func initalLoad() async throws{
    }
  
}
