//
//  MasterRoleManager.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/8/26.
//

import Foundation
@MainActor
final class MasterRoleManager:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    func onLoad(companyId:String?,userId:String?){
        dataService.addListenerForAllCustomers(companyId: companyId, sort: customerSortOption, filter: customerFilterOption) { [weak self] customers in
            print(customers.count)
            self?.displayCustomers = customers
            self?.customers = customers
        }
    }
}
