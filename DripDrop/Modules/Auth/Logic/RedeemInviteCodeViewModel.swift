//
//  RedeemInviteCodeViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 8/29/24.
//

import Foundation
import Foundation
import CoreLocation
import MapKit
import Contacts
@MainActor
final class RedeemInviteCodeViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
