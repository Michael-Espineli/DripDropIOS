//
//  OtherCompanyProfileViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class OtherCompanyProfileViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var buisnessList : [AssociatedBusiness] = []

    func getAssociatedBuisnesses(companyId:String) async throws {
        self.buisnessList = try await dataService.getAssociatedBusinesses(companyId: companyId)
    }
}
