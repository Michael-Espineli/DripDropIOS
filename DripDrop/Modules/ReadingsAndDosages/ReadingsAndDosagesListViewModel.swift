//
//  ReadingsAndDosagesListViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 1/28/26.
//

import Foundation
@MainActor
final class ReadingsAndDosagesListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
}
