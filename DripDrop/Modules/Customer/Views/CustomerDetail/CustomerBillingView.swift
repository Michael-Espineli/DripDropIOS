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
        Group {
            if UIDevice.isIPhone {
                iphone
            } else {
                ScrollView {
                    largeScreen
                }
            }
        }
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
        .sheet(isPresented: $VM.isPresentedOldContract, content: {
            Text("Is Presented Old Contract")
        })
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
        VStack(alignment: .leading, spacing: 12) {
            billingInfoSmall
            billingStats
            serviceAgreements
            contracts
            paymentHistory
            outStandingInvoices
        }
    }

    var largeScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                billingInfoLarge
                billingStats
            }
            serviceAgreements
            contracts
            paymentHistory
            outStandingInvoices
        }
        .padding(12)
    }

    var billingInfoSmall: some View {
        billingSection(
            title: "Billing Notes",
            systemImage: "note.text",
            tint: Color.poolBlue
        ) {
            TextField(
                "Add billing notes",
                text: $VM.billingNotes,
                axis: .vertical
            )
            .font(.subheadline)
            .padding(10)
            .frame(minHeight: 76, alignment: .topLeading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )

            Label("Last raised 03/14/2024", systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    var billingInfoLarge: some View {
        billingInfoSmall
            .frame(maxWidth: .infinity)
    }

    var billingStats: some View {
        billingSection(
            title: "Billing Snapshot",
            systemImage: "chart.bar.fill",
            tint: Color.poolGreen
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                billingStatTile(
                    title: "Outstanding",
                    value: currencyString(cents: VM.openInvoiceTotalCents),
                    tint: Color.orange,
                    systemImage: "exclamationmark.circle.fill"
                )

                billingStatTile(
                    title: "Paid 30 Days",
                    value: currencyString(cents: VM.recentlyPaidTotalCents),
                    tint: Color.poolGreen,
                    systemImage: "checkmark.circle.fill"
                )

                billingStatTile(
                    title: "Accepted",
                    value: "\(VM.acceptedAgreementCount)",
                    tint: Color.poolBlue,
                    systemImage: "doc.text.fill"
                )

                billingStatTile(
                    title: "Subscriptions",
                    value: "\(VM.activeSubscriptionCount)",
                    tint: Color.purple,
                    systemImage: "arrow.triangle.2.circlepath"
                )

                billingStatTile(
                    title: "Agreements",
                    value: currencyString(cents: VM.serviceAgreementTotalCents),
                    tint: Color.poolBlue,
                    systemImage: "signature"
                )

                billingStatTile(
                    title: "Legacy",
                    value: currencyString(dollars: VM.total),
                    tint: Color.secondary,
                    systemImage: "clock.arrow.circlepath"
                )
            }
        }
    }

    var serviceAgreements: some View {
        billingSection(
            title: "Service Agreements",
            systemImage: "doc.text.fill",
            tint: Color.poolBlue
        ) {
            if VM.salesAgreements.isEmpty {
                billingEmptyText("No service agreements yet.")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(VM.salesAgreements.prefix(5))) { agreement in
                        agreementRow(agreement)
                    }
                }
            }
        }
    }
    
    var contracts: some View {
        billingSection(
            title: "Legacy Contracts",
            systemImage: "calendar.badge.clock",
            tint: Color.secondary
        ) {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Button(action: {
                        VM.isPresented.toggle()
                    }, label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(Color.poolBlue, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    })
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        VM.isPresentedOldContract.toggle()
                    }, label: {
                        Label("Past", systemImage: "archivebox.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.poolRed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.poolRed.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    })
                    .buttonStyle(.plain)
                }

                if VM.listOfContrats.isEmpty {
                    billingEmptyText("No legacy contracts found.")
                } else {
                    VStack(spacing: 8) {
                        ForEach(VM.listOfContrats) { contract in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.contract(contract: contract, dataService: dataService), label: {
                                    contractRow(contract)
                                })
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .contract
                                    masterDataManager.selectedID = contract.id
                                }, label: {
                                    contractRow(contract)
                                })
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    var outStandingInvoices: some View {
        billingSection(
            title: "Outstanding Invoices",
            systemImage: "doc.richtext.fill",
            tint: Color.orange
        ) {
            if VM.openInvoices.isEmpty {
                billingEmptyText("No outstanding sales invoices.")
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.openInvoices) { invoice in
                        invoiceRow(invoice)
                    }
                }
            }
        }
    }

    var paymentHistory: some View {
        billingSection(
            title: "Payment History",
            systemImage: "creditcard.fill",
            tint: Color.poolGreen
        ) {
            if VM.salesPayments.isEmpty {
                billingEmptyText("No sales payments recorded.")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(VM.salesPayments.prefix(5))) { payment in
                        paymentRow(payment)
                    }
                }
            }
        }
    }

    private func billingSection<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.13), in: Circle())

                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private func billingStatTile(
        title: String,
        value: String,
        tint: Color,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)

                Spacer()
            }

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func agreementRow(_ agreement: SalesAgreement) -> some View {
        let total = Double(agreement.totalAmountCents ?? agreement.rateAmountCents) / 100
        let status = agreement.status.rawValue.capitalized

        return billingRowCard {
            HStack(alignment: .top, spacing: 10) {
                rowIcon(systemName: "doc.text.fill", tint: statusTint(status))

                VStack(alignment: .leading, spacing: 5) {
                    Text(agreement.title.isEmpty ? "Service Agreement" : agreement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(agreement.serviceCadence.isEmpty ? agreementDateText(agreement) : agreement.serviceCadence)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(total, format: .currency(code: "USD").precision(.fractionLength(2)))")
                        .font(.subheadline.weight(.semibold))

                    statusChip(status)
                }
            }
        }
    }

    private func contractRow(_ contract: RecurringContract) -> some View {
        billingRowCard {
            HStack(alignment: .top, spacing: 10) {
                rowIcon(systemName: "calendar.badge.clock", tint: statusTint(contract.status.rawValue))

                VStack(alignment: .leading, spacing: 5) {
                    Text(contract.serviceFrequency.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(contract.locationCount) \(contract.locationCount == 1 ? "location" : "locations")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(Double(contract.rate) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                        .font(.subheadline.weight(.semibold))

                    statusChip(contract.status.rawValue.capitalized)
                }
            }
        }
    }

    private func invoiceRow(_ invoice: SalesInvoice) -> some View {
        billingRowCard {
            HStack(alignment: .top, spacing: 10) {
                rowIcon(systemName: "doc.richtext.fill", tint: statusTint(invoice.status.rawValue))

                VStack(alignment: .leading, spacing: 5) {
                    Text(invoice.memo ?? invoice.invoiceNumber)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(invoice.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "No due date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(Double(invoice.amountDueCents ?? invoice.totalAmountCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                        .font(.subheadline.weight(.semibold))

                    statusChip(invoice.status.rawValue.capitalized)
                }
            }
        }
    }

    private func paymentRow(_ payment: SalesPayment) -> some View {
        billingRowCard {
            HStack(alignment: .top, spacing: 10) {
                rowIcon(systemName: "creditcard.fill", tint: statusTint(payment.status.rawValue))

                VStack(alignment: .leading, spacing: 5) {
                    Text(payment.method.rawValue.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(payment.receivedAt?.formatted(date: .abbreviated, time: .omitted) ?? "No date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(Double(payment.amountCents) / 100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                        .font(.subheadline.weight(.semibold))

                    statusChip(payment.status.rawValue.capitalized)
                }
            }
        }
    }

    private func billingRowCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(10)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.055), lineWidth: 1)
            )
    }

    private func rowIcon(systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 28, height: 28)
            .background(tint.opacity(0.11), in: Circle())
    }

    private func statusChip(_ status: String) -> some View {
        Text(status)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(statusTint(status))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusTint(status).opacity(0.11), in: Capsule())
    }

    private func billingEmptyText(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
    }

    private func agreementDateText(_ agreement: SalesAgreement) -> String {
        if let sentAt = agreement.sentAt {
            return "Sent \(sentAt.formatted(date: .abbreviated, time: .omitted))"
        }

        if let acceptedAt = agreement.acceptedAt {
            return "Accepted \(acceptedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        return "Cadence not set"
    }

    private func currencyString(cents: Int) -> String {
        currencyString(dollars: Double(cents) / 100)
    }

    private func currencyString(dollars: Double) -> String {
        dollars.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }

    private func statusTint(_ status: String) -> Color {
        let normalized = status.lowercased()

        if normalized.contains("accept") || normalized.contains("active") || normalized.contains("paid") || normalized.contains("posted") {
            return Color.poolGreen
        }

        if normalized.contains("open") || normalized.contains("pending") || normalized.contains("partial") {
            return Color.orange
        }

        if normalized.contains("reject") || normalized.contains("overdue") || normalized.contains("past") || normalized.contains("cancel") {
            return Color.poolRed
        }

        return Color.secondary
    }
}
