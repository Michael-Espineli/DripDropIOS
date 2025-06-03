//
//  CreateBulkInvoiceViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/1/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import Darwin
import FirebaseFunctions

@MainActor
final class CreateBulkInvoiceViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }

    @Published private(set) var laborContracts: [LaborContract] = []
    @Published var selectedLaborContracts: [LaborContract] = []
    @Published private(set) var recurringLaborContracts: [ReccuringLaborContract] = []
    @Published var selectedRecurringLaborContracts: [ReccuringLaborContract] = []

    //Invoice Summary
    @Published private(set) var totalAmount: Int = 0
    @Published var isLoading: Bool = false
    @Published var terms: AcountingTermsTypes = .net15
    @Published var isConfirmSendInvoice: Bool = false
    @Published var invoice: StripeInvoice? = nil
    
    @Published var showAlertMessage: Bool = false
    @Published var alertMessage: String = ""

    func onLoad(companyId: String,associatedBusiness:AssociatedBusiness) async throws {
        //Get All Outstanding Invoices
        self.laborContracts = try await dataService.getLaborContractsBySenderReceiverIsInvoicedStatus(
            senderId: associatedBusiness.companyId,
            receiverId: companyId,
            isInvoiced: false,
            status: .finished
        )
        self.recurringLaborContracts = try await dataService.getLaborContractsByAssociatedBusinessIsActive(companyId: companyId, associatedBusinessCompanyId: associatedBusiness.companyId, isActive: true)
        /*
        self.laborContracts = [
            LaborContract(
                id: UUID().uuidString,
                senderName: "Sender Name",
                senderId: UUID().uuidString,
                senderAcceptance: false,
                receiverName: "Receiver Name",
                receiverId: UUID().uuidString,
                receiverAcceptance: false,
                type: .businessToBusiness,
                dateSent: Date(),
                lastDateToAccept: Date(),
                dateAccepted: Date(),
                status: .accepted,
                terms: [
                    
                ],
                notes: "Notes",
                rate: 0,
                senderJobId: IdInfo(
                    id: UUID().uuidString,
                    internalId: "J123"
                ),
                customerId: UUID().uuidString,
                customerName: "Customer Name",
                serviceLocationId: UUID().uuidString,
                serviceLocationName: "Location Name",
                jobTemplateId: UUID().uuidString,
                jobTemplateName: "Job Template Name",
                isInvoiced: true
            ),
            
            LaborContract(
                id: UUID().uuidString,
                senderName: "Sender Name",
                senderId: UUID().uuidString,
                senderAcceptance: false,
                receiverName: "Receiver Name",
                receiverId: UUID().uuidString,
                receiverAcceptance: false,
                type: .businessToBusiness,
                dateSent: Date(),
                lastDateToAccept: Date(),
                dateAccepted: Date(),
                status: .accepted,
                terms: [
                    
                ],
                notes: "Notes",
                rate: 0,
                senderJobId: IdInfo(
                    id: UUID().uuidString,
                    internalId: "J123"
                ),
                customerId: UUID().uuidString,
                customerName: "Customer Name",
                serviceLocationId: UUID().uuidString,
                serviceLocationName: "Location Name",
                jobTemplateId: UUID().uuidString,
                jobTemplateName: "Job Template Name",
                isInvoiced: true
            )
        ]
        self.recurringLaborContracts = [
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: "Murdock Pool Service",
                senderId: UUID().uuidString,
                senderAcceptance: true,
                receiverName: "Michael Espineli",
                receiverId: UUID().uuidString,
                receiverAcceptance: false,
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: "Notes",
                atWill:false
            )
            ,
            
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: "Murdock Pool Service",
                senderId: UUID().uuidString,
                senderAcceptance: true,
                receiverName: "Michael Espineli",
                receiverId: UUID().uuidString,
                receiverAcceptance: false,
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: "Notes",
                atWill:false
            )
            ,
            
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: "Murdock Pool Service",
                senderId: UUID().uuidString,
                senderAcceptance: true,
                receiverName: "Michael Espineli",
                receiverId: UUID().uuidString,
                receiverAcceptance: false,
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: "Notes",
                atWill:false
            )
        ]
         */
    }
    func onChangeOfContracts(companyId: String, contracts:[LaborContract]) async throws{
        self.isLoading = true
        try await createSummary(companyId: companyId, contracts: contracts, recurringContracts: selectedRecurringLaborContracts)
        self.isLoading = false
    }
    func onChangeOfRecurringContracts(companyId: String, recurringContracts:[ReccuringLaborContract]) async throws{
        self.isLoading = true
        try await createSummary(companyId: companyId, contracts: selectedLaborContracts, recurringContracts: recurringContracts)
        self.isLoading = false
    }
    func createSummary(companyId: String, contracts: [LaborContract],recurringContracts: [ReccuringLaborContract]) async throws{
        var total:Int = 0
        print("Creating Summary")
        print("recurring Contracts \(recurringContracts.count)")
        print("contracts \(contracts.count)")
        for contract in recurringContracts {
            var weeklyTotal: Int = 0
            var recurringWork = try await dataService.getLaborContractRecurringWorkList(companyId: companyId, laborContractId: contract.id)
            print("Received recurringWork for \(contract.id) - \(recurringWork.count)")
            for work in recurringWork {
                //Get Service Stops Since Last Billed
                if work.isActive {
                    for rssIds in work.recurringServiceStopIdList {
                        let serviceStops = try await dataService.getServiceStopsByRecurringsServiceStopBetweenDates(
                            companyId: companyId,
                            recurringsServicestopId: rssIds.id,
                            startDate: work.lastBilled,
                            endDate: Date()
                        )
                        print("received serviceStops for \(rssIds.id) - \(serviceStops.count)")
                        for stop in serviceStops {
                            if !stop.isInvoiced {
                                // if stop.operationStatus == .finished {}//DEVELOPER MAYBE ADD COMPANY SETTING REQUIRE FINISH
                                total += Int(work.rate)
                                //Update Service Stop once Sent
                            }
                        }
                    }
                    //Update work once sent to billed as Date()
                } else {
                    print("Work is Inactive")
                }
                //for stop in serviceStops {
                // add total += work.timesPerFrequency * Int(work.rate)
                // mark service stops as billed
                //}
                //Mark Recurring work last Billed as Date()
            }
        }
        for contract in contracts {
            total += contract.rate
        }
        self.totalAmount = total
    }
    func generateInvoice(company: Company, associatedBusiness:AssociatedBusiness)async throws {
        self.isLoading = true
        var total:Int = 0
        let invoiceCount = try await dataService.getInvoiceCount(companyId: company.id)
        let internalId = "I" + String(invoiceCount)
        let id = "inv_" + UUID().uuidString
        let invoiceRef = IdInfo(id: id, internalId: internalId)
        
        var invoiceLineItems:[StripeInvoiceLineItems] = []
        for contract in selectedRecurringLaborContracts {
            var weeklyTotal: Int = 0
            var recurringWork = try await dataService.getLaborContractRecurringWorkList(companyId: company.id, laborContractId: contract.id)

            for work in recurringWork {
                //Get Service Stops Since Last Billed
                if work.isActive {
                    for rssIds in work.recurringServiceStopIdList {
                        let serviceStops = try await dataService.getServiceStopsByRecurringsServiceStopBetweenDates(
                            companyId: company.id,
                            recurringsServicestopId: rssIds.id,
                            startDate: work.lastBilled,
                            endDate: Date()
                        )
                        var serviceStopToal = 0
                        for stop in serviceStops {
                            if !stop.isInvoiced {
                                // if stop.operationStatus == .finished {}//DEVELOPER MAYBE ADD COMPANY SETTING REQUIRE FINISH
                                total += Int(work.rate)
                                serviceStopToal += Int(work.rate)
                                //Update Service Stop once Sent
                                try await dataService.updateServiceStopIsInvoiced(companyId: company.id, serviceStopId: stop.id, isInvoiced: true)
                            }
                        }
                        
                        let lineItem = StripeInvoiceLineItems(id: "inv_li_" + UUID().uuidString, itemId: "", description: "\(work.customerName) \(work.jobTemplateName) \(work.timesPerFrequency) per \(work.frequency.rawValue)", induvidualCost: Int(work.rate), total: serviceStopToal)
                        invoiceLineItems.append(lineItem)
                    }
                    try await dataService.updateLaborContractRecurringWorkLastBilled(companyId: company.id, laborContractId: contract.id, laborContractRecurringWorkId: work.id, lastBilled: Date())
                    //Update work once sent to billed as Date()
                } else {
                    print("Work is Inactive")
                }
            }
        }
        for contract in selectedLaborContracts {
            let tasks = try await dataService.getLaborContractTasks(companyId: company.id, laborContractId: contract.id)
            var description: String = contract.customerName + " - \(contract.senderJobId.internalId):"
            for task in tasks {
                description = description + " \(task.name)"
            }
            total += contract.rate
                //Update Billing Rate
                //Update Labor Contract As Billed
            //DEVELOPER MAYBE Create Individual Line Items for each Task
            let lineItem = StripeInvoiceLineItems(id: "inv_li_" + UUID().uuidString, itemId: "", description: description, induvidualCost: contract.rate, total: contract.rate)
            invoiceLineItems.append(lineItem)
            try await dataService.updateLaborContractIsInvoiced(companyId: company.id, contractId: contract.id, isInvoiced: true)
            try await dataService.updateLaborContractInvoiceRef(companyId: company.id, contractId: contract.id, invoiceInfo: invoiceRef)
        }
        print("total")
        let invoice = StripeInvoice(
            id: id,
            internalIdenifier: internalId,
            senderId: company.id,
            senderName: company.name,
            receiverId: associatedBusiness.companyId,
            receiverName: associatedBusiness.companyName,
            dateSent: Date(),
            total: total,
            terms: terms,
            paymentStatus: .unpaid,
            paymentType: nil,
            paymentRefrence: "",
            paymentDate: nil,
            lineItems: invoiceLineItems
        )
        try await dataService.createInvoice(stripeInvoice: invoice)
        self.invoice = invoice
        self.isLoading = false
        
       print("Sending Email")
        
       let data = [
            "companyId" : company.id,
           "invoiceId" : "inv_E3988AC7-4A73-41EB-915F-F59FEEA19029", //Developer Fix Later add id
       ]
        
       let result = try await Functions.functions().httpsCallable("sendInvoiceEmail").call(data)
       guard let json = result.data as? [String: Any] else {
           print("json")
           throw FireBaseRead.unableToRead
       }
        self.alertMessage = "Successfully Sent"
        self.showAlertMessage.toggle()

       print(json)
    }
}
