//
//  CustomerBillingView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI
@MainActor
final class CustomerBillingViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var listOfContrats:[RecurringContract] = []
    @Published private(set) var salesAgreements:[SalesAgreement] = []
    @Published private(set) var salesBillingSubscriptions:[SalesBillingSubscription] = []
    @Published private(set) var salesInvoices:[SalesInvoice] = []
    @Published private(set) var salesPayments:[SalesPayment] = []

    @Published private(set) var total:Double = 0
    
    @Published var billingNotes = ""
    @Published var isPresented:Bool = false
    @Published var isPresentedOldContract:Bool = false
    
    func onLoad(companyId:String,customerId:String) async throws {
        self.listOfContrats = try await dataService.getContractsByCustomer(companyId: companyId, customerId: customerId)
        self.total = listOfContrats.reduce(0) { partialResult, contract in
            partialResult + Double(contract.rate) / 100
        }
        self.salesAgreements = try await dataService.getSalesAgreements(companyId: companyId, customerId: customerId)
            .sorted { agreementDate($0) > agreementDate($1) }
        self.salesBillingSubscriptions = try await dataService.getSalesBillingSubscriptions(companyId: companyId, customerId: customerId)
            .sorted { subscriptionDate($0) > subscriptionDate($1) }
        self.salesInvoices = try await dataService.getSalesInvoices(companyId: companyId, customerId: customerId)
            .sorted { invoiceDate($0) > invoiceDate($1) }
        self.salesPayments = try await dataService.getSalesPayments(companyId: companyId, customerId: customerId)
            .sorted { paymentDate($0) > paymentDate($1) }
    }
    func onChangeBillingNotes(companyId:String,customerId:String) async throws {
        try await dataService.updateCustomerBillingNotes(companyId: companyId, customerId: customerId, billingNotes: billingNotes)
        print("Update Billing Notes - \(billingNotes)")
    }
    
    var acceptedAgreementCount: Int {
        salesAgreements.filter { $0.status == .accepted }.count
    }
    
    var openInvoices: [SalesInvoice] {
        salesInvoices.filter { invoice in
            [.open, .partiallyPaid, .overdue].contains(invoice.status)
        }
    }
    
    var openInvoiceTotalCents: Int {
        openInvoices.reduce(0) { partialResult, invoice in
            partialResult + (invoice.amountDueCents ?? invoice.totalAmountCents)
        }
    }
    
    var recentlyPaidTotalCents: Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return salesPayments
            .filter { $0.status == .posted && ($0.receivedAt ?? $0.createdAt ?? Date.distantPast) >= thirtyDaysAgo }
            .reduce(0) { $0 + $1.amountCents }
    }
    
    var activeSubscriptionCount: Int {
        salesBillingSubscriptions.filter { subscription in
            subscription.status == .active || subscription.stripeStatus.lowercased() == "active" || subscription.stripeStatus.lowercased() == "trialing"
        }.count
    }
    
    var serviceAgreementTotalCents: Int {
        salesAgreements.reduce(0) { partialResult, agreement in
            partialResult + (agreement.totalAmountCents ?? agreement.rateAmountCents)
        }
    }
    
    private func agreementDate(_ agreement: SalesAgreement) -> Date {
        agreement.updatedAt ?? agreement.sentAt ?? agreement.acceptedAt ?? agreement.createdAt ?? agreement.startDate ?? Date.distantPast
    }
    
    private func subscriptionDate(_ subscription: SalesBillingSubscription) -> Date {
        subscription.updatedAt ?? subscription.createdAt ?? subscription.currentPeriodStart ?? Date.distantPast
    }
    
    private func invoiceDate(_ invoice: SalesInvoice) -> Date {
        invoice.updatedAt ?? invoice.sentAt ?? invoice.dueDate ?? invoice.createdAt ?? Date.distantPast
    }
    
    private func paymentDate(_ payment: SalesPayment) -> Date {
        payment.receivedAt ?? payment.updatedAt ?? payment.createdAt ?? Date.distantPast
    }
}
struct CustomerBillingView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject var VM : CustomerBillingViewModel

    @State var customer:Customer? = nil
    
    init(dataService: any ProductionDataServiceProtocol,customer:Customer) {
        _VM = StateObject(wrappedValue: CustomerBillingViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
    }
    
    var body: some View {
        ScrollView{
            if UIDevice.isIPhone {
                iphone
            } else {
                largeScreen
            }
            Text("")
                .sheet(isPresented: $VM.isPresented,
                       onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                            if let customer = masterDataManager.selectedCustomer {
                                do {
                                    print("Get Contractacts For Customer Id: \(customer.id)")
                                    try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                    print("Successfully Got Contracts")
                                } catch{
                                    print("No Contracts")
                                    print(error)
                                }
                            } else {
                                if let customer = customer {
                                    do {
                                        print("Get Contractacts For Customer Id: \(customer.id)")
                                        try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                        print("Successfully Got Contracts")
                                    } catch{
                                        print("No Contracts")
                                        print(error)
                                    }
                                } else {
                                    print("No Selected Customer")
                                }
                            }
                        }
                    }
                },
                       content: {
                    if let customer = customer {
                        AddNewContractView(
                            dataService: dataService,
                            customer: customer
                        )
                    } else {
                        if let selectedCustomer = masterDataManager.selectedCustomer {
                            AddNewContractView(
                                dataService: dataService,
                                customer: selectedCustomer
                            )
                        } else {
                            AddNewContractView(
                                dataService: dataService,
                                customer: nil
                            )
                        }
                    }
                })
            Text("")
                .sheet(isPresented: $VM.isPresentedOldContract, content: {
                    Text("Is Presented Old Contract")
                })
        }
        .task{
            VM.billingNotes = customer?.billingNotes ?? ""
            if let company = masterDataManager.currentCompany {
                if let customer = masterDataManager.selectedCustomer {
                    do {
                        print("Get Contractacts For Customer Id: \(customer.id)")
                        try await VM.onLoad(companyId: company.id, customerId: customer.id)
                        print("Successfully Got Contracts")
                    } catch{
                        print("No Contracts")
                        print(error)
                    }
                } else {
                    if let customer = customer {
                        do {
                            print("Get Contractacts For Customer Id: \(customer.id)")
                            try await VM.onLoad(companyId: company.id, customerId: customer.id)
                            print("Successfully Got Contracts")
                        } catch{
                            print("No Contracts")
                            print(error)
                        }
                    } else {
                        print("No Selected Customer")
                    }
                }
            }
            
        }
        .onChange(of: masterDataManager.selectedCustomer, perform: { cus in
            Task{
                guard let selectedCustomer = cus else {
                    print("Error For Change in Customer With New Valid Selected Customer ")
                    return
                }
                print("Selected Customer Changed \(selectedCustomer.firstName)")

                VM.billingNotes = customer?.billingNotes ?? ""
                if let company = masterDataManager.currentCompany {
                    if let customer = masterDataManager.selectedCustomer {
                        do {
                            print("Get Contractacts For Customer Id: \(customer.id)")
                            try await VM.onLoad(companyId: company.id, customerId: customer.id)
                            print("Successfully Got Contracts")
                        } catch{
                            print("No Contracts")
                            print(error)
                        }
                    } else {
                        if let customer = customer {
                            do {
                                print("Get Contractacts For Customer Id: \(customer.id)")
                                try await VM.onLoad(companyId: company.id, customerId: customer.id)
                                print("Successfully Got Contracts")
                            } catch{
                                print("No Contracts")
                                print(error)
                            }
                        } else {
                            print("No Selected Customer")
                        }
                    }
                }
            }
        })
        .onChange(of: VM.billingNotes, perform: { notes in
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    if let customer = masterDataManager.selectedCustomer {
                        if customer.billingNotes != notes {
                            do {
                                try await VM.onChangeBillingNotes(companyId: currentCompany.id, customerId: customer.id)
                            } catch {
                                print(error)
                            }
                        }
                    } else {
                        if let customer = customer {
                            if customer.billingNotes != notes {
                                do {
                                    try await VM.onChangeBillingNotes(companyId: currentCompany.id, customerId: customer.id)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
        })
    }
}
extension CustomerBillingView {
    var iphone: some View {
        VStack(alignment: .leading){
            billingInfoSmall
            Rectangle()
                .frame(height: 1)
            billingStats
            Rectangle()
                .frame(height: 1)
            serviceAgreements
            Rectangle()
                .frame(height: 1)
            contracts
            Rectangle()
                .frame(height: 1)
            paymentHistory
            Rectangle()
                .frame(height: 1)
            outStandingInvoices
        }
    }
    var largeScreen: some View {
        VStack{
            HStack{
                billingInfoLarge
                billingStats
            }
            serviceAgreements
            Rectangle()
                .frame(height: 1)
            contracts
            Rectangle()
                .frame(height: 1)
            paymentHistory
            Rectangle()
                .frame(height: 1)
            outStandingInvoices
        }
        
    }
    var billingInfoSmall: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextField(
                    "",
                    text: $VM.billingNotes,
                    axis: .vertical
                )
                .padding(4)
                .padding(.horizontal,4)
                .background(Color.poolBlue.opacity(0.2))
                .cornerRadius(5.0)
                .padding(8)
            }
            Text("Last Raised: 03/14/2024")
        }
    }
    var billingInfoLarge: some View {
        VStack{
            VStack{
                Text("Billing Notes:")
                TextField(
                    "",
                    text: $VM.billingNotes,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.poolBlue.opacity(0.2))
                .cornerRadius(5.0)
                .padding()
            }
            Text("Last Raised: 03/14/2024")
            Text("")
            Spacer()
        }
    }
    var billingStats: some View {
        VStack{
            HStack{
                Text("Total Outstanding : ")
                Spacer()
                Text("\(Double(VM.openInvoiceTotalCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
            }
            HStack{
                Text("Recently Paid (30 Days) : ")
                Spacer()
                Text("\(Double(VM.recentlyPaidTotalCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            HStack{
                Text("Accepted Agreements : ")
                Spacer()
                Text("\(VM.acceptedAgreementCount)")

            }
            HStack{
                Text("Active Subscriptions : ")
                Spacer()
                Text("\(VM.activeSubscriptionCount)")

            }
            HStack{
                Text("Agreement Total : ")
                Spacer()
                Text("\(Double(VM.serviceAgreementTotalCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            HStack{
                Text("Legacy Contract Total : ")
                Spacer()
                Text(" \(VM.total, format: .currency(code: "USD").precision(.fractionLength(2)))")

            }
            
        }
    }
    var serviceAgreements: some View {
        VStack(alignment: .leading, spacing: 10){
            HStack{
                Spacer()
                Text("Service Agreements")
                    .font(.headline)
                Spacer()
            }
            
            if VM.salesAgreements.isEmpty {
                Text("No service agreements yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(VM.salesAgreements.prefix(5))){ agreement in
                    VStack(alignment: .leading, spacing: 6){
                        HStack{
                            VStack(alignment: .leading, spacing: 2){
                                Text(agreement.title.isEmpty ? "Service Agreement" : agreement.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(agreement.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Double(agreement.totalAmountCents ?? agreement.rateAmountCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                                .font(.subheadline.weight(.semibold))
                        }
                        HStack{
                            Text(agreement.serviceCadence.isEmpty ? "Cadence not set" : agreement.serviceCadence)
                            Spacer()
                            if let sentAt = agreement.sentAt {
                                Text("Sent \(sentAt.formatted(date: .abbreviated, time: .omitted))")
                            } else if let acceptedAt = agreement.acceptedAt {
                                Text("Accepted \(acceptedAt.formatted(date: .abbreviated, time: .omitted))")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    var contracts: some View {
        VStack{
            ScrollView(showsIndicators: false){
                
                HStack{
                    Spacer()
                    Text("Legacy Recurring Contracts")
                        .font(.headline)
                    
                    Spacer()
                    
                }
                HStack{
                    Button(action: {
                        VM.isPresented.toggle()
                    }, label: {
                        
                        Text("Add New")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                            .fontDesign(.monospaced)
                    })
                    Spacer()
                    Button(action: {
                        VM.isPresentedOldContract.toggle()
                    }, label: {
                        Text("See Past")
                            .foregroundColor(Color.poolRed)
                            .padding(3)
                    })
                }
                
                ForEach(VM.listOfContrats){ contract in
                    if UIDevice.isIPhone {
                        NavigationLink(value: Route.contract(contract: contract, dataService: dataService), label: {
                            ContractCardView(contract: contract)
                        })
                    } else {
                        HStack{
                            ContractCardView(contract: contract)
                            Button(action: {
                                masterDataManager.selectedCategory = .contract
                                masterDataManager.selectedID = contract.id
                            }, label: {
                                Text("See More")
                                    .foregroundColor(Color.basicFontText)
                                    .padding(5)
                                    .background(Color.poolBlue)
                                    .cornerRadius(5)
                            })
                        }
                    }
                }
            }
        }
    }
    var outStandingInvoices: some View {
        VStack{
            HStack{
                Spacer()
                Text("Outstanding Invoices")
                    .font(.headline)
                Spacer()
                
            }
            HStack{
                Text("Description")
                Spacer()
                Text("Amount")
            }
            Divider()
            if VM.openInvoices.isEmpty {
                Text("No outstanding Sales invoices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(VM.openInvoices){ invoice in
                    HStack{
                        Text(invoice.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "No due date")
                        Text(invoice.memo ?? invoice.invoiceNumber)
                        Spacer()
                        Text("\(Double(invoice.amountDueCents ?? invoice.totalAmountCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                        Button(action: {
                            
                        }, label: {
                            Image(systemName: "chevron.right")
                        })
                    }
                    .padding(.vertical,4)
                }
            }
        }
    }
    var paymentHistory: some View {
        VStack{
            HStack{
                Spacer()
                Text("Payment History")
                    .font(.headline)
                
                Spacer()
                
            }
            if VM.salesPayments.isEmpty {
                Text("No Sales payments recorded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(Array(VM.salesPayments.prefix(5))){ payment in
                    HStack{
                        Text(payment.receivedAt?.formatted(date: .abbreviated, time: .omitted) ?? "No date")
                        Text(payment.method.rawValue.capitalized)
                        Spacer()
                        Text("\(Double(payment.amountCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
