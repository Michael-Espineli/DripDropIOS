//
//  LaborContractListViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/10/24.
//
import Foundation
import SwiftUI

@MainActor
final class LaborContractListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var searchTerm:String = ""

    @Published var showSearch:Bool = false
    @Published var showFilters:Bool = false
    @Published var showAddNewLaborContract:Bool = false
    @Published var selectedStatus:LaborContractStatus = .accepted

    @Published var statusList:[LaborContractStatus] = [.accepted]

    @Published private(set) var laborContractList:[RepeatingLaborContract] = []

    //Get
    func getLaborContracts(companyId:String) async throws {
        self.laborContractList = try await dataService.getLaborContracts(companyId: companyId)
    }
}
