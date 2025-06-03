//
//  LaborContractViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/25.
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
    @Published var selectedLaborContract:ReccuringLaborContract? = nil // Maybe Delete

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
        recurringServiceStopIdList: [],
        isActive: true,
        lastBilled: Date()
    )

    
    @Published private(set) var submitButtonDisabled:Bool = false

    //Received Varaibles From DataService
    @Published private(set) var termsTemplate:TermsTemplate? = nil
    @Published private(set) var associatedBusiness:AssociatedBusiness? = nil

    @Published private(set) var contractTerm:ContractTerms? = nil
    @Published private(set) var job:Job? = nil
    @Published private(set) var invoice:StripeInvoice? = nil

    @Published private(set) var termsTemplateList:[TermsTemplate] = []
    @Published private(set) var contractTermList:[ContractTerms] = []
    @Published private(set) var laborContractList:[ReccuringLaborContract] = []

    @Published private(set) var laborContractTaskList:[LaborContractTask] = []

    @Published private(set) var status:LaborContractStatus = .accepted
    @Published var senderAcceptance:Bool = false
    @Published var receiverAcceptance:Bool = false

    //View Side Variables
    @Published var generateRouteFromLaborContract:Bool = false
    @Published private(set) var companyUsers: [CompanyUser] = []
    @Published  var selectedAdmin: CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .contractor)

    func onLoadDetailView(companyId:String,laborContract:LaborContract) async throws {
        print("")
        print("------- On Load - onLoadDetailView - [LaborContractViewModel] --------")
        print("laborContractId: \(laborContract.id)")
        self.status = laborContract.status
        self.notes = laborContract.notes
        self.senderAcceptance = laborContract.senderAcceptance
        self.receiverAcceptance = laborContract.receiverAcceptance
        self.laborContractTaskList = try await dataService.getLaborContractWork(companyId: companyId, laborContractId: laborContract.id)
        print("laborContractTaskList \(laborContractTaskList)")
        if let first = laborContractTaskList.first {
            if let firstTaskJobId = first.receiverJobId.first {
                self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: firstTaskJobId.id)
            }
        }
        self.associatedBusiness = try? await dataService.getAssociatedBusinessByCompanyId(companyId: companyId, businessCompanyId: laborContract.senderId)
        print("Associated Business: \(associatedBusiness)")
        if let invoiceRef = laborContract.invoiceRef {
            self.invoice = try await dataService.getAccountsReceivableInvoice(companyId: companyId, invoiceId: invoiceRef.id)
        }
        print("")
    }
    func onLoadGenerateJobFromLaborContract(companyId:String,laborContractId:String) async throws {
        self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        if !companyUsers.isEmpty {
            self.selectedAdmin = companyUsers.first!
        }
        if let user = companyUsers.first {
            self.selectedAdmin = user
        }
        self.laborContractTaskList = try await dataService.getLaborContractWork(companyId: companyId, laborContractId: laborContractId)
    }
    func generateJobFromLaborContract(laborContract:LaborContract) async throws {
        //Admin Picker
        if selectedAdmin.id == "" {
            throw FireBaseRead.unableToRead
        }
        //Optional Schedule First Service Stop
    
        //Create Job
        let id = "comp_wo_" + UUID().uuidString
        let internalCount = try await dataService.getWorkOrderCount(companyId: laborContract.receiverId)
        let internalId = "J" + String(internalCount)
        let job = Job(
            id: id,
            internalId: internalId,
            type: "",
            dateCreated: Date(),
            description: laborContract.notes,
            operationStatus: .unscheduled,
            billingStatus: .accepted,
            customerId: laborContract.customerId,
            customerName: laborContract.customerName,
            serviceLocationId: laborContract.serviceLocationId,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: selectedAdmin.id,
            adminName: selectedAdmin.userName,
            rate: 0,
            laborCost: 0,
            otherCompany: true,
            receivedLaborContractId: laborContract.id,
            receiverId: laborContract.receiverId,
            senderId : laborContract.senderId,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: .company,
            estimateAcceptedNotes: "",
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
        print("job: \(job)")
        try await dataService.uploadWorkOrder(companyId: laborContract.receiverId, workOrder: job)
        print("Successfully Updated")
        //Create Tasks For job
        
        for task in laborContractTaskList {
            
            let jobTask = JobTask(
                name: task.name,
                type: task.type,
                contractedRate: task.contractedRate,
                estimatedTime: task.estimatedTime,
                status: JobTaskStatus.unassigned,
                customerApproval: task.customerApproval,
                actualTime: 0,
                workerId: "",
                workerType: .notAssigned,
                workerName: "",
                laborContractId: "",
                serviceStopId: IdInfo(id: "", internalId: ""),
                equipmentId: task.equipmentId,
                serviceLocationId: task.serviceLocationId,
                bodyOfWaterId: task.bodyOfWaterId,
                dataBaseItemId: task.shoppingListItemId
            )
            print("jobTask: \(jobTask)")
            try await dataService.uploadJobTask(companyId: laborContract.receiverId, jobId: id, task: jobTask)
            
                //Update Labor Contract
            try await dataService.updateLaborContractTaskStatus(laborContractId: laborContract.id, laborContractTaskId: task.id, status: .accepted)
            try await dataService.updateLaborContractTaskJobIsCreated(laborContractId: laborContract.id, laborContractTaskId: task.id, jobIsCreated: true)
            try await dataService.updateLaborContractTaskReceiverJobId(laborContractId: laborContract.id, laborContractTaskId: task.id, jobIdInfo: IdInfo(id: job.id, internalId: job.internalId))
                //Update Sender Job?
            //Devloper
            try dataService.updateJobTaskStatus(companyId: laborContract.senderId, jobId: laborContract.senderJobId.id, taskId: task.senderJobTaskId, status: .accepted)
            print("successfully Updated Labor Contract")

        }
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
    func markLaborContractAsAcceptedByReceiver(companyId:String,laborContract:LaborContract) async throws {
        //Update Display
        self.status = .accepted
        self.senderAcceptance = true
        self.receiverAcceptance = true
        
        //Updating same contract
        print("Accepted Labor Contract on Receiver Side")
        try await dataService.updateOneTimeLaborContractAsAcceptedBySender(contractId: laborContract.id, accepted: true)
        
        print("Accepted Labor Contract on Sender Side")
        try await dataService.updateOneTimeLaborContractAsAcceptedByReceiver(contractId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        print("Accepted Labor Contract Alert on Receiver Side")

//        try await dataService.addDripDropAlert(
//            companyId: laborContract.senderId,
//            dripDropAlert: DripDropAlert(
//                category: .receivedLaborContracts,
//                route: .laborContractDetailView,
//                itemId: laborContract.id,
//                name: "Accepted Labor Contract",
//                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
//                date: Date()
//            )
//        )
    }
    func markLaborContractAsRejectedByReceiver(companyId:String,laborContract:LaborContract) async throws {
            //Updating same contract
            print("Accepted Labor Contract on Receiver Side")
            try await dataService.updateOneTimeLaborContractAsAcceptedBySender(contractId: laborContract.id, accepted: false)
            
            print("Accepted Labor Contract on Sender Side")
            try await dataService.updateOneTimeLaborContractAsAcceptedByReceiver(contractId: laborContract.id, accepted: false)
            
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
//        try await dataService.addDripDropAlert(
//            companyId: laborContract.receiverId,
//            dripDropAlert: DripDropAlert(
//                category: .receivedLaborContracts,
//                route: .laborContractDetailView,
//                itemId: laborContract.id,
//                name: "Rejected Labor Contract",
//                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
//                date: Date()
//            )
//        )
    }
    func sendRevisedLaborContractFromReceiver(companyId:String,laborContract:ReccuringLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, termsTemplateId: laborContract.id, accepted: true)
        
        //Mark Sending Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, termsTemplateId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .receivedLaborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Counter Offer Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
                date: Date()
            )
        )
    }
    
    func sendRevisedLaborContractFromSender(companyId:String,laborContract:ReccuringLaborContract) async throws {
        //Labor Contracts Are stored in two places so we need to update the information twice.
        
        //Mark Receiving Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: companyId, termsTemplateId: laborContract.id, accepted: true)
        
        //Mark Sending Company Contract
        
//        try await dataService.updateLaborContractAsAcceptedByReceiver(companyId: laborContract.senderId, termsTemplateId: laborContract.id, accepted: true)
        
        //Send an Alert to the Sending Company So they See that The other company Accepted it.
        try await dataService.addDripDropAlert(
            companyId: laborContract.receiverId,
            dripDropAlert: DripDropAlert(
                category: .receivedLaborContracts,
                route: .laborContractDetailView,
                itemId: laborContract.id,
                name: "Counter Offer Labor Contract",
                description: "Check Details of New Labor Contract from \(laborContract.senderName)",
                date: Date()
            )
        )
    }
    
    func offerNewRate(laborContract : ReccuringLaborContract,recurringWork : LaborContractRecurringWork) async throws {
        print("Please Figure out how to Offer new rate. ")
    }
    
    //Delete
    func deleteLaborContract(companyId:String,laborContract:LaborContract,taskList:[LaborContractTask]) async throws {
        //Delte Contract
        try await dataService.deleteLaborContract(contractId: laborContract.id)
        self.alertMessage = "Successfully Deleted"
        
        //Update sender company Job tasks
        for task in taskList {
            try dataService.updateJobTaskWorkerId(companyId: laborContract.senderId, jobId: laborContract.senderJobId.id, taskId: task.id, workerId: "")
            try dataService.updateJobTaskWorkerName(companyId: laborContract.senderId, jobId: laborContract.senderJobId.id, taskId: task.id, workerName: "")
            try dataService.updateJobTaskWorkerType(companyId: laborContract.senderId, jobId: laborContract.senderJobId.id, taskId: task.id, workerType: .notAssigned)
            try dataService.updateJobTaskStatus(companyId: laborContract.senderId, jobId: laborContract.senderJobId.id, taskId: task.id, status: .unassigned)
        }

        self.showAlert.toggle()
        
        //Send alert to other company that labor contract has been deleted
        
//        if companyId == laborContract.senderId {
//            try await dataService.addDripDropAlert(
//                companyId: laborContract.receiverId,
//                dripDropAlert: DripDropAlert(
//                    category: .receivedLaborContracts,
//                    route: .laborContractDetailView,
//                    itemId: laborContract.id,
//                    name: "Labor Contract Deleted",
//                    description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
//                    date: Date()
//                )
//            )
//        } else if companyId == laborContract.receiverId {
//            try await dataService.addDripDropAlert(
//                companyId: laborContract.senderId,
//                dripDropAlert: DripDropAlert(
//                    category: .receivedLaborContracts,
//                    route: .laborContractDetailView,
//                    itemId: laborContract.id,
//                    name: "Labor Contracted Deleted",
//                    description: "Check Details of New Labor Contract from \(laborContract.receiverName)",
//                    date: Date()
//                )
//            )
//        }
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
        case .finished, .rejected:
            return Color.poolRed
        case .pending:
            return Color.poolYellow
        }
    }
    func getForeGroundColor(status:LaborContractStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolWhite
        case .finished, .rejected:
            return Color.poolWhite
        case .pending:
            return Color.poolBlack

        }
    }
}
