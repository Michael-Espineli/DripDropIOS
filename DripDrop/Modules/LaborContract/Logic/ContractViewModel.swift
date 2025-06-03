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
    @Published private(set) var contract: RecurringContract? = nil
    @Published private(set) var count: Int? = nil
    @Published private(set) var formDisabled: Bool = true

    //ARRAYS
    @Published private(set) var listOfContrats:[RecurringContract] = []
    @Published private(set) var filteredContractList:[RecurringContract] = []

    //----------------------------------------------------
    //------------------  CRUD  --------------------------
    //----------------------------------------------------
    
    //----------------------------------------------------
    //                    CREATE
    //----------------------------------------------------
    func uploadContract(companyId:String,contract:RecurringContract) async throws {
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
    func updateContract(companyId:String,contract:RecurringContract) async throws {
        try await dataService.updateContract(companyId: companyId, contract: contract)
    }
    func updateContractWithValidation(
        companyId : String,
        contract : RecurringContract,
        dateToAccept : Date,
        status : RecurringContractStatus,
        locations : Double,
        rate : String,
        rateType : RecurringContractRateType,
        laborType : RecurringContractLaborType,
        chemType : RecurringContractChemType,
        cleaningPlan : RecurringContractCleaningPlan,
        filterServiceType : BillingType,
        repairType : BillingType,
        repairMax : String,
        serviceFrequency : RecurringContractServiceFrequency,
        serviceFrequencyAmount : String,
        internalNotes : String,
        externalNotes : String
    ) async throws {
        if contract.status != status {
            try await dataService.updateContractStatus(companyId: companyId, contractId: contract.id, status: status)

        } else {
            print("No Change in Status")
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
    func filterContractList(list:[RecurringContract],filterTerm:String) {
        var contractList:[RecurringContract] = []
        for contract in list {
            if contract.internalCustomerName.lowercased().contains(filterTerm.lowercased()) {
                contractList.append(contract)
            }
        }
        self.filteredContractList = contractList
    }
    func totalContracts(contracts:[RecurringContract]) -> Double {
        var total:Double = 0
        for contract in contracts {
            total = total + Double(contract.rate)/100
        }
        return total
    }
    func checkContractForm(customerId:String,customerName:String,terms:String,notes:String,rate:String,laborRate:String){
        if customerId == "" || customerName == "" || terms == "" || notes == "" || rate == "" || laborRate == "" {
            self.formDisabled = true

        } else {
            self.formDisabled = false

        }
    }
}
