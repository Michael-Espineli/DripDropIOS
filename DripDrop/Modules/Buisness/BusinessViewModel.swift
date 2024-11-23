//
//  BuisnessViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
final class BuisnessViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var buisness : AssociatedBuisness? = nil
    @Published private(set) var buisnessList : [AssociatedBuisness] = []

    func getAssociatedBuisnesses(companyId:String){
        self.buisnessList = []
    }
    func getAssociatedBuisness(companyId:String,buisnessId:String){
        self.buisnessList = []
    }
}
