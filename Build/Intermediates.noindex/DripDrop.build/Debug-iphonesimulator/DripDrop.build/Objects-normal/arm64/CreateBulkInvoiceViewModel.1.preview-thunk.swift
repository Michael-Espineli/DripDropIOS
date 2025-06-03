import func SwiftUI.__designTimeFloat
import func SwiftUI.__designTimeString
import func SwiftUI.__designTimeInteger
import func SwiftUI.__designTimeBoolean

#sourceLocation(file: "/Users/michaelespineli/Desktop/DripDrop/DripDrop/Modules/Invoices/CreateBulkInvoiceViewModel.swift", line: 1)
//
//  CreateBulkInvoiceViewModel.swift
//  DripDrop
//
//  Created by Michael Espineli on 6/1/25.
//

import Foundation

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
    @Published private(set) var totalAmount: Int = 42000
    
    func onLoad(companyId: String,associatedBusiness:AssociatedBusiness) async throws {
        //Get All Outstanding Invoices
        self.laborContracts = try await dataService.getLaborContractsBySenderReceiverIsInvoicedStatus(
            senderId: associatedBusiness.companyId,
            receiverId: companyId,
            isInvoiced: __designTimeBoolean("#17522_0", fallback: false),
            status: .finished
        )
        self.laborContracts = [
            LaborContract(
                id: UUID().uuidString,
                senderName: __designTimeString("#17522_1", fallback: "Sender Name"),
                senderId: UUID().uuidString,
                senderAcceptance: __designTimeBoolean("#17522_2", fallback: false),
                receiverName: __designTimeString("#17522_3", fallback: "Receiver Name"),
                receiverId: UUID().uuidString,
                receiverAcceptance: __designTimeBoolean("#17522_4", fallback: false),
                type: .businessToBusiness,
                dateSent: Date(),
                lastDateToAccept: Date(),
                dateAccepted: Date(),
                status: .accepted,
                terms: [
                    
                ],
                notes: __designTimeString("#17522_5", fallback: "Notes"),
                rate: __designTimeInteger("#17522_6", fallback: 0),
                senderJobId: IdInfo(
                    id: UUID().uuidString,
                    internalId: __designTimeString("#17522_7", fallback: "J123")
                ),
                customerId: UUID().uuidString,
                customerName: __designTimeString("#17522_8", fallback: "Customer Name"),
                serviceLocationId: UUID().uuidString,
                serviceLocationName: __designTimeString("#17522_9", fallback: "Location Name"),
                jobTemplateId: UUID().uuidString,
                jobTemplateName: __designTimeString("#17522_10", fallback: "Job Template Name"),
                isInvoiced: __designTimeBoolean("#17522_11", fallback: true)
            ),
            
            LaborContract(
                id: UUID().uuidString,
                senderName: __designTimeString("#17522_12", fallback: "Sender Name"),
                senderId: UUID().uuidString,
                senderAcceptance: __designTimeBoolean("#17522_13", fallback: false),
                receiverName: __designTimeString("#17522_14", fallback: "Receiver Name"),
                receiverId: UUID().uuidString,
                receiverAcceptance: __designTimeBoolean("#17522_15", fallback: false),
                type: .businessToBusiness,
                dateSent: Date(),
                lastDateToAccept: Date(),
                dateAccepted: Date(),
                status: .accepted,
                terms: [
                    
                ],
                notes: __designTimeString("#17522_16", fallback: "Notes"),
                rate: __designTimeInteger("#17522_17", fallback: 0),
                senderJobId: IdInfo(
                    id: UUID().uuidString,
                    internalId: __designTimeString("#17522_18", fallback: "J123")
                ),
                customerId: UUID().uuidString,
                customerName: __designTimeString("#17522_19", fallback: "Customer Name"),
                serviceLocationId: UUID().uuidString,
                serviceLocationName: __designTimeString("#17522_20", fallback: "Location Name"),
                jobTemplateId: UUID().uuidString,
                jobTemplateName: __designTimeString("#17522_21", fallback: "Job Template Name"),
                isInvoiced: __designTimeBoolean("#17522_22", fallback: true)
            )
        ]
        self.recurringLaborContracts = [
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: __designTimeString("#17522_23", fallback: "Murdock Pool Service"),
                senderId: UUID().uuidString,
                senderAcceptance: __designTimeBoolean("#17522_24", fallback: true),
                receiverName: __designTimeString("#17522_25", fallback: "Michael Espineli"),
                receiverId: UUID().uuidString,
                receiverAcceptance: __designTimeBoolean("#17522_26", fallback: false),
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: __designTimeString("#17522_27", fallback: "Notes"),
                atWill:__designTimeBoolean("#17522_28", fallback: false)
            )
            ,
            
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: __designTimeString("#17522_29", fallback: "Murdock Pool Service"),
                senderId: UUID().uuidString,
                senderAcceptance: __designTimeBoolean("#17522_30", fallback: true),
                receiverName: __designTimeString("#17522_31", fallback: "Michael Espineli"),
                receiverId: UUID().uuidString,
                receiverAcceptance: __designTimeBoolean("#17522_32", fallback: false),
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: __designTimeString("#17522_33", fallback: "Notes"),
                atWill:__designTimeBoolean("#17522_34", fallback: false)
            )
            ,
            
            ReccuringLaborContract(
                id: UUID().uuidString,
                senderName: __designTimeString("#17522_35", fallback: "Murdock Pool Service"),
                senderId: UUID().uuidString,
                senderAcceptance: __designTimeBoolean("#17522_36", fallback: true),
                receiverName: __designTimeString("#17522_37", fallback: "Michael Espineli"),
                receiverId: UUID().uuidString,
                receiverAcceptance: __designTimeBoolean("#17522_38", fallback: false),
                dateSent: Date(),
                lastDateToAccept: Date(),
                startDate: Date(),
                endDate: Date(),
                status: .accepted,
                terms:[],
                notes: __designTimeString("#17522_39", fallback: "Notes"),
                atWill:__designTimeBoolean("#17522_40", fallback: false)
            )
        ]
    }
    func onChangeOfContracts(contracts:[LaborContract]){
        createSummary(contracts: contracts, recurringContracts: selectedRecurringLaborContracts)
    }
    func onChangeOfRecurringContracts(recurringContracts:[ReccuringLaborContract]){
        createSummary(contracts: selectedLaborContracts, recurringContracts: recurringContracts)
    }
    func createSummary(contracts:[LaborContract],recurringContracts:[ReccuringLaborContract]){
        var total:Int = __designTimeInteger("#17522_41", fallback: 0)
        for contract in recurringContracts {
            total += __designTimeInteger("#17522_42", fallback: 10000)
        }
        for contract in contracts {
            total += contract.rate
        }
        self.totalAmount = total
    }
}
