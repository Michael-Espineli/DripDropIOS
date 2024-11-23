//
//  LaborContractViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/7/24.
//

import Foundation
import SwiftUI

@MainActor
final class LaborContractViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    //Sheet Variables
    @Published var showOfferNewRate:Bool = false
    
    @Published var showEditLaborContract:Bool = false
    
    @Published var showGenerateLaborContract:Bool = false

    //Form Variables
    @Published var notes:String = ""
    @Published var offerNewRate:String = ""

    //Alert Variables
    @Published var alertMessage:String = ""
    
    @Published var showAlert:Bool = false

    //View Variables
    @Published var selectedLaborContract:RepeatingLaborContract? = nil // Maybe Delete

    @Published var selectedRecurringServiceId:String = "" // Maybe Delete
    
    @Published var selectedRecurringWorkId:String = ""

    @Published var selectedJobTemplate:JobTemplate = JobTemplate(
        id: "",
        name: "",
        type: "",
        typeImage: "",
        dateCreated: Date(),
        rate: "",
        color: "",
        locked: false
    )
    @Published var weeklyCleaning:JobTemplate = JobTemplate(
        id: "",
        name: "",
        type: "",
        typeImage: "",
        dateCreated: Date(),
        rate: "",
        color: "",
        locked: false
    )
    @Published var selectedRecurringWork:LaborContractRecurringWork = LaborContractRecurringWork(
        id: "",
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceLocationName: "",
        jobTemplateId: "",
        jobTemplateName: "",
        rate: 0,
        laborType: .hour,
        frequency: .daily,
        timesPerFrequency: 0,
        timesPerFrequencySetUp: 0,
        routeSetUp: false,
        recurringServiceStopIdList: []
    )

    
    @Published private(set) var submitButtonDisabled:Bool = false

    //Received Varaibles From DataService
    @Published private(set) var termsTemplate:TermsTemplate? = nil
    @Published private(set) var contractTerm:ContractTerms? = nil
    
    @Published private(set) var termsTemplateList:[TermsTemplate] = []
    @Published private(set) var contractTermList:[ContractTerms] = []
    @Published private(set) var laborContractList:[RepeatingLaborContract] = []

    @Published private(set) var laborContractRecurringWorkList:[LaborContractRecurringWork] = []

    
    //View Side Variables
    @Published var generateRouteFromLaborContract:Bool = false

    func onLoadDetailView(companyId:String,laborContractId:String) async throws {
        self.laborContractRecurringWorkList = try await dataService.getLaborContractRecurringWork(companyId: companyId, laborContractId: laborContractId)
    }
    func onLoadGenerateRouteFromLaborContract(companyId:String,laborContractId:String) async throws {
        self.laborContractRecurringWorkList = try await dataService.getLaborContractRecurringWork(companyId: companyId, laborContractId: laborContractId)
    }
    func onLoadLaborContractRecurringWorkPicker(companyId:String) async throws {
        let templates = try await dataService.getAllWorkOrderTemplates(companyId: companyId)
        if let firstTemplate = templates.first(where: {$0.id == "1"}) {
            self.selectedJobTemplate = firstTemplate
        } else {
            if !templates.isEmpty {
                self.selectedJobTemplate = templates.first!
            }
        }
        self.weeklyCleaning = self.selectedJobTemplate
        
    }
    //Add
    func addNewTermsTemplate(companyId:String,termsTemplate:TermsTemplate,terms:[ContractTerms]) async throws {
        try await dataService.addTermsTemplate(companyId: companyId, termsTemplate: termsTemplate)
        for term in terms {
            try await dataService.addTermsToTermsTemplate(companyId: companyId, termsTemplateId: termsTemplate.id, terms: term)
        }
    }
    func addNewTermsToTemplateId(companyId:String,termsTemplateId:String,terms:[ContractTerms]) async throws {
        for term in terms {
            try await dataService.addTermsToTermsTemplate(companyId: companyId, termsTemplateId: termsTemplateId, terms: term)
        }
    }
    //Get
    func getLaborContracts(companyId:String) async throws {
        self.laborContractList = try await dataService.getLaborContracts(companyId: companyId)
    }
    func getInfoForTermsTemplate(companyId:String,termsTemplateId:String) async throws {
        self.termsTemplate = try await dataService.getTermsTemplate(companyId: companyId, termsTemplateId: termsTemplateId)
        self.contractTermList = try await dataService.getTermsByTermsTemplate(companyId: companyId, termsTemplateId: termsTemplateId)
    }
    func getTermsTemplates(companyId:String) async throws {
        self.termsTemplateList = try await dataService.getTermsTemplateList(companyId: companyId)
    }
    func getContractTermsForTermsTemplate(companyId:String,termsTemplateId:String) async throws {
        self.contractTermList = try await dataService.getTermsByTermsTemplate(companyId: companyId, termsTemplateId: termsTemplateId)
    }
    //Update
    func markLaborContractAsAcceptedByReceiver(companyId:String,laborContract:RepeatingLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        print("Accepted Labor Contract on Receiver Side")
        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, contractId: laborContract.id, accepted: true)
        
        //Mark Sending Company Contract
        print("Accepted Labor Contract on Sender Side")
        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, contractId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        print("Accepted Labor Contract Alert on Receiver Side")

        try await dataService.addDripDropAlert(
            companyId: laborContract.senderId,
            dripDropAlert: DripDropAlert(
                category: .laborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Accepted Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                date: Date()
            )
        )
    }
    func markLaborContractAsRejectedByReceiver(companyId:String,laborContract:RepeatingLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, contractId: laborContract.id, accepted: false)
        
        //Mark Sending Company Contract
        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, contractId: laborContract.id, accepted: false)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .laborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Rejected Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                date: Date()
            )
        )
    }
    func sendRevisedLaborContractFromReceiver(companyId:String,laborContract:RepeatingLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, termsTemplateId: laborContract.id, accepted: true)
        
        //Mark Sending Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, termsTemplateId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .laborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Counter Offer Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                date: Date()
            )
        )
    }
    
    func sendRevisedLaborContractFromSender(companyId:String,laborContract:RepeatingLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, termsTemplateId: laborContract.id, accepted: true)
        
        //Mark Sending Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, termsTemplateId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .laborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Counter Offer Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.senderName)",
                date: Date()
            )
        )
    }
    
    func offerNewRate(laborContract : RepeatingLaborContract,recurringWork : LaborContractRecurringWork) async throws {
        print("Please Figure out how to Offer new rate. ")
    }
    //Delete
    func deleteLaborContract(companyId:String,laborContract:RepeatingLaborContract) async throws {
        try await dataService.deleteLaborContract(companyId: laborContract.senderId, contractId: laborContract.id)
        try await dataService.deleteLaborContract(companyId: laborContract.receiverId, contractId: laborContract.id)
        if companyId == laborContract.senderId {
            try await dataService.addDripDropAlert(
                companyId: laborContract.receiverId,
                dripDropAlert: DripDropAlert(
                    category: .laborContracts,
                    route: .laborContractDetailView,
                    itemId: laborContract.id,
                    name: "Labor Contract Deleted",
                    description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                    date: Date()
                )
            )
        } else if companyId == laborContract.receiverId {
            try await dataService.addDripDropAlert(
                companyId: laborContract.senderId,
                dripDropAlert: DripDropAlert(
                    category: .laborContracts,
                    route: .laborContractDetailView,
                    itemId: laborContract.id,
                    name: "Labor Contracted Deleted",
                    description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                    date: Date()
                )
            )
        }
    }
    //Functions
    func checkSubmitButtonStatus(name:String,termsList:[ContractTerms]){
        if name == "" {
            self.submitButtonDisabled = true
        } else {
            if termsList.isEmpty{
                self.submitButtonDisabled = true
            } else {
                self.submitButtonDisabled = false
            }
        }
    }
    func getBackGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolGreen
        case .past:
            return Color.poolRed
        case .pending:
            return Color.poolYellow
        }
    }
    func getForeGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolWhite
        case .past:
            return Color.poolWhite
        case .pending:
            return Color.poolBlack

        }
    }
}
