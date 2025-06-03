//
//  CreateLaborContractInvoice.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

@MainActor
final class CreateLaborContractInvoiceViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private (set) var tasks: [LaborContractTask] = []
    @Published private (set) var jobs: [Job] = []
    @Published private (set) var jobIds: [IdInfo] = []
    
    @Published var showInvoiceInfo: Bool = false

    @Published private (set) var isInvoiced: Bool = false
    @Published private (set) var invoiceRef: IdInfo? = nil
    @Published var terms: AcountingTermsTypes = .net15

    @Published private (set) var invoice: StripeInvoice =  StripeInvoice(
        id: UUID().uuidString,
        internalIdenifier: "",
        
        senderId: UUID().uuidString,
        senderName: "Michael Espineli",
        receiverId: UUID().uuidString,
        receiverName: "Murdock Pool Service",
        dateSent: Date(),
        total: 1_000_00,
        terms: .net45,
        paymentStatus: .paid,
        paymentType: .cash,
        paymentRefrence: "",
        paymentDate: nil,
        lineItems: [
        ]
    )
    func onLoad(companyId: String, laborContract:LaborContract) async throws {
        self.isInvoiced = laborContract.isInvoiced
        
        self.tasks = try await dataService.getLaborContractWork(companyId: companyId, laborContractId: laborContract.id)
        for task in tasks {
            for idInfo in task.receiverJobId {
                if !jobIds.contains(idInfo) {
                    self.jobIds.append(idInfo)
                    let job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: idInfo.id)
                    self.jobs.append(job)
                }
            }
        }
    }
    func sendInvoice(companyId:String,laborContract:LaborContract) async throws {
        // Create Invoice
        let total = laborContract.rate
        var lineItems:[StripeInvoiceLineItems] = []
        for task in tasks {
            //Update invoice
            let lineItem = StripeInvoiceLineItems(id: UUID().uuidString, itemId: "1", description: task.name, induvidualCost: task.contractedRate, total: task.contractedRate)
            lineItems.append(lineItem)
        }
        let invoiceCount = try await dataService.getInvoiceCount(companyId: companyId)
        let internalId = "I" + String(invoiceCount)
        let id = "inv_" + UUID().uuidString
        let invoice = StripeInvoice(
            id: id,
            internalIdenifier: internalId,
            senderId: laborContract.receiverId,
            senderName: laborContract.receiverName,
            receiverId: laborContract.senderId,
            receiverName: laborContract.senderName,
            dateSent: Date(),
            total: total,
            terms: terms,
            paymentStatus: .unpaid,
            paymentType: nil,
            paymentRefrence: "",
            paymentDate: nil,
            lineItems: lineItems
        )
        self.invoice = invoice
        try await dataService.createInvoice(stripeInvoice: invoice)
        
        // Update View
        self.isInvoiced = true
        let invoiceRef = IdInfo(id: id, internalId: internalId)
        self.invoiceRef = invoiceRef
        
        // Update Labor Contract
        try await dataService.updateLaborContractIsInvoiced(companyId: companyId, contractId: laborContract.id, isInvoiced: true)
        try await dataService.updateLaborContractInvoiceRef(companyId: companyId, contractId: laborContract.id, invoiceInfo: invoiceRef)
        print("Successfully Sent Invoice")
        
        //Developer either create call function on send email reminder
    }
}

struct CreateLaborContractInvoice: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : CreateLaborContractInvoiceViewModel

    init(dataService:any ProductionDataServiceProtocol,laborContract:LaborContract){
        _VM = StateObject(wrappedValue: CreateLaborContractInvoiceViewModel(dataService: dataService))
        _laborContract = State(wrappedValue: laborContract)
    }
    @State var laborContract: LaborContract

    var body: some View {
        ZStack{
            Color.darkGray.ignoresSafeArea()

            ScrollView{
                header
                info
                    .background(Color.listColor)
            }
            .background(Color.listColor)

            button
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id, laborContract: laborContract)
                } catch {
                    print(error)
                }
            }
        }
    }
}

//#Preview {
//    CreateLaborContractInvoice()
//}
extension CreateLaborContractInvoice {

    var header: some View {
        VStack{
            HStack{
                Text("To: \(laborContract.senderName)")
                Spacer()
            }
            HStack{
                Text("\(Double(laborContract.rate)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                Spacer()
            }
            HStack{
                Text(laborContract.status.rawValue)
                Spacer()
                Text(laborContract.isInvoiced ? "Invoiced" : "Not Invoiced")
            }
        }
        .padding(8)
        .background(Color.darkGray)
    }
    var info: some View {
        VStack{
            Text("Invoice Summary")
                .font(.headline)
            Divider()
            Text("Task Break Down")
            ForEach(VM.tasks){ task in
                HStack{
                    Text("\(task.name): \(task.contractedRate)")
                    Spacer()
                    if task.status == .finished {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.poolGreen)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(Color.basicFontText)
                    }
                }
            }
        }
        .padding(8)
    }
    var button: some View {
        VStack{
            Spacer()
            if VM.isInvoiced {
                if let invoiceRef = VM.invoiceRef {
                    NavigationLink(value: Route.accountsReceivableDetail(invoice: VM.invoice, dataService: dataService), label: {
                        Text("See Invoice \(invoiceRef.internalId)")
                            .modifier(SubmitButtonModifier())
                    })
                }
            } else {
                Button(action: {
                    VM.showInvoiceInfo.toggle()
                }, label: {
                    Text("Send Invoice")
                        .modifier(SubmitButtonModifier())
                })
                .sheet(isPresented: $VM.showInvoiceInfo, content: {
                    VStack{
                        
                        Picker("Type", selection: $VM.terms) {
                            ForEach(AcountingTermsTypes.allCases, id:\.self){ datum in
                                Text(datum.rawValue).tag(datum)
                            }
                        }
                        
                        Button(action: {
                            Task{
                                if let currentCompany = masterDataManager.currentCompany {
                                    do {
                                        try await VM.sendInvoice(companyId: currentCompany.id, laborContract: laborContract)
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }, label: {
                            Text("Send Invoice")
                                .modifier(SubmitButtonModifier())
                        })
                    }
                    .presentationDetents([.fraction(0.4)])
                })
            }
        }
    }
}
