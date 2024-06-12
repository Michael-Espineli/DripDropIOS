//
//  ContractViewModel.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/22/23.
//
import Foundation
import SwiftUI
import FirebaseFirestore
import MapKit

@MainActor
final class ContractViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    //----------------------------------------------------
    //                    VARIABLES
    //----------------------------------------------------
    
    //SINGLES
    @Published private(set) var contract: Contract? = nil
    @Published private(set) var count: Int? = nil

    //ARRAYS
    @Published private(set) var listOfContrats:[Contract] = []
    @Published private(set) var filteredContractList:[Contract] = []

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadContract(companyId:String,contract:Contract) async throws {
        try await dataService.uploadContact(companyId: companyId, contract: contract)
    }
    //----------------------------------------------------
    //                    READ
    //----------------------------------------------------
    func getAllContracts(companyId: String) async throws {
        self.listOfContrats = try await dataService.getAllContrats(companyId: companyId)
    }
    func getSpecificContract(companyId: String,contractId:String) async throws {
        self.contract = try await dataService.getSpecificContract(companyId: companyId, contractId: contractId)
    }
    func getContractsByCustomer(companyId: String,customerId:String) async throws {
        self.listOfContrats = try await dataService.getContractsByCustomer(companyId: companyId, customerId: customerId)
    }
    func getContractsByCustomerCount(companyId: String,customerId:String) async throws{
        self.count = try await dataService.getContractsByCustomerCount(companyId: companyId, customerId: customerId)

    }
    //----------------------------------------------------
    //                    UPDATE
    //----------------------------------------------------
    func updateContract(companyId:String,contract:Contract) async throws {
        try await dataService.updateContract(companyId: companyId, contract: contract)
    }
    func updateContractWithValidation(companyId:String,contract:Contract,dateToAccept:Date,status:String,locations:Double,rate:Double,rateType:String,laborType:String,chemType:String,terms:String,notes:String,startDate:Date?,endDate:Date?) async throws {
        if contract.status != status {
            try await dataService.updateContractStatus(companyId: companyId, contractId: contract.id, status: status)

        } else {
            print("No Change in Status")
        }
        if contract.startDate != startDate {
            if let date = startDate {
                try await dataService.updateContractStartDate(companyId: companyId, contractId: contract.id, startDate: date)
            }
        } else {
            print("No Change in Start Date")
        }
        if contract.endDate != endDate {
            if let date = startDate {
                
                try await dataService.updateContractEndDate(companyId: companyId, contractId: contract.id, endDate: date)
            }
        } else {
            print("No Change in End Date")
        }
    }
    //----------------------------------------------------
    //                    DELETE
    //----------------------------------------------------
    func deleteContract(companyId:String,contractId:String) async throws{
        try await dataService.deleteContract(companyId: companyId, contractId: contractId)
    }
    //----------------------------------------------------
    //                    FUNCTIONS
    //----------------------------------------------------
    func filterContractList(list:[Contract],filterTerm:String) {
        var contractList:[Contract] = []
        for contract in list {
            if contract.customerName.lowercased().contains(filterTerm.lowercased()) {
                contractList.append(contract)
            }
        }
        self.filteredContractList = contractList
    }
    func totalContracts(contracts:[Contract]) -> Double {
        var total:Double = 0
        for contract in contracts {
            total = total + contract.rate
        }
        return total
    }
}
