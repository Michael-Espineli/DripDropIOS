//
//  Finance.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/2/24.
//

import SwiftUI
import MapKit
import Firebase
import Charts

struct Finance: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM: MyCompanyViewModel

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: MyCompanyViewModel(dataService: dataService))
    }

    @State private var showOperations: Bool = false
    @State private var showFinance: Bool = false
    @State private var showManagement: Bool = false
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if let role = masterDataManager.role {
                        if role.permissionIdList.contains("400") {
                            financeOverview
                        } else {
                            emptyState(
                                title: "No finance access.",
                                message: "Your role does not currently include finance permissions.",
                                systemImage: "lock.shield"
                            )
                        }
                    } else {
                        emptyState(
                            title: "Loading role.",
                            message: "Finance tools will appear after your role permissions load.",
                            systemImage: "person.badge.key"
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }

//            if isLoading {
//                loadingOverlay
//            }
        }
        .onAppear {
            if !UIDevice.isIPhone {
                showOperations = true
                showFinance = true
                showManagement = true
            }
        }
        .task {
            await masterDataManager.loadFeatureFlags()
            await loadFinance()
        }
        .onChange(of: masterDataManager.currentCompany) { _ in
            Task {
                await loadFinance()
            }
        }
        .onChange(of: VM.isLoading) { loading in
            if loading {
                isLoading = loading
            } else {
                withAnimation(.linear(duration: 0.1)) {
                    isLoading = loading
                }
            }
        }
    }

    private func loadFinance() async {
        guard let company = masterDataManager.currentCompany,
              let user = masterDataManager.user else {
            return
        }

        do {
            try await VM.onLoad(
                companyId: company.id,
                userId: user.id,
                category: "Finance"
            )
        } catch {
            print("[Finance][loadFinance]")
            print(error)
        }
    }
}

// MARK: - Main Sections

extension Finance {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "dollarsign.circle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Finance")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(masterDataManager.currentCompany?.name ?? "Review payroll, purchases, invoices, payables, receivables, vendors, and contracts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Label(masterDataManager.mainScreenDisplayType.rawValue, systemImage: "rectangle.grid.1x2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var financeOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Finance Overview", systemImage: "slider.horizontal.3")
                Spacer()
            }

            if masterDataManager.isFeatureEnabled(.sales) {
                sales
            }
            payroll
            purchases
            receipts
            vendors

            /*
             Roll these back in when they are ready for production:
             invoices

             accountsPayable
             accountsReceivable
             contracts
             recurringContracts
             sentLaborContract
             receivedLaborContract
             sentRecurringLaborContract
             receivedRecurringLaborContract
            */
        }
    }

    var snapshot: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Snapshot", systemImage: "chart.bar")

            Chart(VM.buildActivities) { buildActivity in
                BarMark(
                    x: .value("Date", buildActivity.date, unit: .month),
                    y: .value("Total Count", buildActivity.numberOfUnits)
                )
                .foregroundStyle(by: .value("Name", buildActivity.name))
            }
            .chartForegroundStyleScale([
                "Jobs": .blue,
                "Monthly Service": .green,
                "Items Purchased": .red,
                "Labor": .orange
            ])
            .frame(height: 220)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Finance Cards

extension Finance {

    var sales: some View {
        financeCard(
            title: "Sales",
            subtitle: "Customer billing for monthly service and one-off jobs.",
            systemImage: "dollarsign.arrow.circlepath",
            countText: nil,
            seeMore: {
                AnyView(
                    NavigationLink(value: Route.sales(dataService: dataService)) {
                        seeMoreLabel
                    }
                    .buttonStyle(.plain)
                )
            },
            stats: {
                VStack(spacing: 8) {
                    statRow(
                        title: "Recurring Billing",
                        value: "Monthly",
                        systemImage: "calendar"
                    )

                    statRow(
                        title: "One-Off Billing",
                        value: "Jobs",
                        systemImage: "briefcase"
                    )
                }
            },
            preview: {
                if shouldShowFullPreview {
                    horizontalPreviewList {
                        previewTile(
                            title: "Service Agreements",
                            subtitle: "Monthly pool service",
                            systemImage: "repeat.circle.fill"
                        )

                        previewTile(
                            title: "Job Billing",
                            subtitle: "Materials and labor",
                            systemImage: "doc.text.fill"
                        )
                    }
                }
            }
        )
    }

    var payroll: some View {
        financeCard(
            title: "Payroll",
            subtitle: "Review technician pay, payroll statements, line items, and exports.",
            systemImage: "person.crop.circle.badge.dollar",
            countText: nil,
            seeMore: {
                AnyView(
                    NavigationLink(value: Route.payRoll(dataService: dataService)) {
                        seeMoreLabel
                    }
                    .buttonStyle(.plain)
                )
            },
            stats: {
                VStack(spacing: 8) {
                    statRow(
                        title: "Open Jobs",
                        value: String(VM.openJobs ?? 0),
                        systemImage: "briefcase"
                    )

                    statRow(
                        title: "Recently Finished",
                        value: String(VM.recentlyFinishedJobs ?? 0),
                        systemImage: "checkmark.circle"
                    )
                }
            },
            preview: {
                EmptyView()
            }
        )
    }

    var finishedJobs: some View {
        financeCard(
            title: "Finished Jobs",
            subtitle: "Jobs ready for billing review, invoice prep, or final closeout.",
            systemImage: "checkmark.seal",
            countText: VM.recentlyFinishedJobs == nil ? nil : "\(VM.recentlyFinishedJobs ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.billingJobs(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .jobs
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    statRow(
                        title: "Open",
                        value: String(VM.openJobs ?? 0),
                        systemImage: "folder"
                    )

                    statRow(
                        title: "Recently Finished",
                        value: String(VM.recentlyFinishedJobs ?? 0),
                        systemImage: "checkmark.circle"
                    )
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.jobs.isEmpty {
                        emptyPreviewTile("No Jobs", systemImage: "briefcase")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.jobs) { job in
                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.job(
                                            job: job,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: job.internalId.isEmpty ? job.id : job.internalId,
                                            subtitle: job.customerName,
                                            systemImage: "wrench.adjustable.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedJob = job
                                        masterDataManager.selectedCategory = .jobs
                                    } label: {
                                        previewTile(
                                            title: job.internalId.isEmpty ? job.id : job.internalId,
                                            subtitle: job.customerName,
                                            systemImage: "wrench.adjustable.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    var invoices: some View {
        financeCard(
            title: "Invoices",
            subtitle: "Customer invoices, billable work, and billed material tracking.",
            systemImage: "doc.text",
            countText: VM.itemsPurchasedAndBilled == nil ? nil : "\(String(format: "%.0f", VM.itemsPurchasedAndBilled ?? 0))",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.invoices(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .purchases
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let items = VM.itemsPurchased {
                        statRow(
                            title: "Total Items",
                            value: String(format: "%.0f", items),
                            systemImage: "cart"
                        )
                    }

                    if let amount = VM.totalSpent {
                        statRow(
                            title: "Total Spent",
                            value: currency(amount),
                            systemImage: "dollarsign.circle"
                        )
                    }

                    if let items = VM.itemsPurchasedBillable {
                        statRow(
                            title: "Billable Items",
                            value: String(format: "%.0f", items),
                            systemImage: "tag"
                        )
                    }

                    if let amount = VM.totalSpentOnBillables {
                        statRow(
                            title: "Billable Cost",
                            value: currency(amount),
                            systemImage: "creditcard"
                        )
                    }

                    if let amount = VM.totalBilled {
                        statRow(
                            title: "Billed",
                            value: currency(amount),
                            systemImage: "checkmark.seal"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Invoice Items")
                }
            }
        )
    }

    var purchases: some View {
        financeCard(
            title: "Purchases",
            subtitle: "Purchased items from receipts, vendors, jobs, and customer work.",
            systemImage: "cart",
            countText: VM.itemsPurchased == nil ? nil : "\(String(format: "%.0f", VM.itemsPurchased ?? 0))",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.purchases(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .purchases
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let items = VM.itemsPurchased {
                        statRow(
                            title: "Total Items",
                            value: String(format: "%.0f", items),
                            systemImage: "cart"
                        )
                    }

                    if let amount = VM.totalSpent {
                        statRow(
                            title: "Total Spent",
                            value: currency(amount),
                            systemImage: "dollarsign.circle"
                        )
                    }

                    if let items = VM.itemsPurchasedBillable {
                        statRow(
                            title: "Billable Items",
                            value: String(format: "%.0f", items),
                            systemImage: "tag"
                        )
                    }

                    if let amount = VM.totalBilled {
                        statRow(
                            title: "Billed",
                            value: currency(amount),
                            systemImage: "checkmark.seal"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Purchases")
                }
            }
        )
    }

    var receipts: some View {
        financeCard(
            title: "Receipts",
            subtitle: "Uploaded vendor receipts and purchase history.",
            systemImage: "receipt",
            countText: VM.purchasedItems.isEmpty ? nil : "\(VM.purchasedItems.count)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.receipts(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .receipts
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let items = VM.itemsPurchased {
                        statRow(
                            title: "Items Purchased",
                            value: String(format: "%.0f", items),
                            systemImage: "cart"
                        )
                    }

                    if let amount = VM.totalSpent {
                        statRow(
                            title: "Total Spent",
                            value: currency(amount),
                            systemImage: "dollarsign.circle"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Receipts")
                }
            }
        )
    }

    var accountsPayable: some View {
        financeCard(
            title: "Accounts Payable",
            subtitle: "Outstanding vendor or contractor invoices owed by the company.",
            systemImage: "arrow.up.doc",
            countText: VM.APOutstandingCount == nil ? nil : "\(VM.APOutstandingCount ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.accountsPayableList(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .accountsPayable
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.APOutstandingCount {
                        statRow(
                            title: "Outstanding",
                            value: String(count),
                            systemImage: "tray"
                        )
                    }

                    if let amount = VM.APTotal {
                        statRow(
                            title: "Total",
                            value: currency(amount),
                            systemImage: "dollarsign.circle"
                        )
                    }

                    if let count = VM.APOutstandingLateCount {
                        statRow(
                            title: "Late",
                            value: String(count),
                            systemImage: "exclamationmark.triangle"
                        )
                    }

                    if let amount = VM.APTotalOutstandingLate {
                        statRow(
                            title: "Late Total",
                            value: centsCurrency(amount),
                            systemImage: "clock.badge.exclamationmark"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.APInvoiceList.isEmpty {
                        emptyPreviewTile("No AP Invoices", systemImage: "doc.text")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.APInvoiceList) { invoice in
                                let title = invoice.senderName
                                let subtitle = centsCurrency(invoice.total)

                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.accountsPayableDetail(
                                            invoice: invoice,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: title,
                                            subtitle: subtitle,
                                            systemImage: "creditcard.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedAccountsPayableInvoice = invoice
                                    } label: {
                                        previewTile(
                                            title: title,
                                            subtitle: subtitle,
                                            systemImage: "creditcard.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    var accountsReceivable: some View {
        financeCard(
            title: "Accounts Receivable",
            subtitle: "Customer invoices and receivables owed to the company.",
            systemImage: "arrow.down.doc",
            countText: VM.AROutstandingCount == nil ? nil : "\(VM.AROutstandingCount ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.accountsReceivableList(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .accountsReceivable
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.AROutstandingCount {
                        statRow(
                            title: "Receivable Invoices",
                            value: String(count),
                            systemImage: "tray"
                        )
                    }

                    if let amount = VM.ARTotal {
                        statRow(
                            title: "Receivable Total",
                            value: currency(amount),
                            systemImage: "dollarsign.circle"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.ARInvoiceList.isEmpty {
                        emptyPreviewTile("No AR Invoices", systemImage: "doc.text")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.ARInvoiceList) { invoice in
                                let title = invoice.senderName
                                let subtitle = centsCurrency(invoice.total)

                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.accountsReceivableDetail(
                                            invoice: invoice,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: title,
                                            subtitle: subtitle,
                                            systemImage: "creditcard.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        masterDataManager.selectedAccountsReceivableInvoice = invoice
                                    } label: {
                                        previewTile(
                                            title: title,
                                            subtitle: subtitle,
                                            systemImage: "creditcard.fill"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }

    var vendors: some View {
        financeCard(
            title: "Vendors",
            subtitle: "Vendors used for parts, chemicals, equipment, and services.",
            systemImage: "building.2",
            countText: VM.venderCount == nil ? nil : "\(VM.venderCount ?? 0)",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.venders(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .vender
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.venderCount {
                        statRow(
                            title: "Vendors",
                            value: String(count),
                            systemImage: "building.2"
                        )
                    }
                }
            },
            preview: {
                if shouldShowFullPreview {
                    if VM.listOfVenders.isEmpty {
                        emptyPreviewTile("No Vendors", systemImage: "building.2")
                    } else {
                        horizontalPreviewList {
                            ForEach(VM.listOfVenders) { vendor in
                                let text = vendor.name ?? "Vendor"

                                if UIDevice.isIPhone {
                                    NavigationLink(
                                        value: Route.vender(
                                            vender: vendor,
                                            dataService: dataService
                                        )
                                    ) {
                                        previewTile(
                                            title: text,
                                            subtitle: "",
                                            systemImage: "building.2"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Button {
                                        navigationManager.routes.append(
                                            Route.vender(
                                                vender: vendor,
                                                dataService: dataService
                                            )
                                        )
                                    } label: {
                                        previewTile(
                                            title: text,
                                            subtitle: "",
                                            systemImage: "building.2"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        )
    }
}

struct SalesFinanceView: View {
    let dataService: any ProductionDataServiceProtocol

    private let recurringItems = [
        "Service agreements",
        "Monthly billing runs",
        "Draft invoice review",
        "Payment status"
    ]

    private let oneOffItems = [
        "Job billing lifecycle",
        "Service stop labor",
        "Assigned purchased items",
        "Job-owned invoice totals"
    ]

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    billingSection(
                        title: "Recurring Billing",
                        subtitle: "Monthly pool service",
                        systemImage: "calendar",
                        tint: .green,
                        items: recurringItems
                    )
                    billingSection(
                        title: "One-Off Billing",
                        subtitle: "Job detail billing",
                        systemImage: "briefcase",
                        tint: .blue,
                        items: oneOffItems
                    )
                    roadmap
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Sales")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sales")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Text("Customer billing starts here, split between monthly service agreements and one-off job invoices.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func billingSection(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        items: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            ForEach(items, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(tint)
                    Text(item)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var roadmap: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Next Build Pieces", systemImage: "list.bullet.rectangle")
                .font(.headline.weight(.semibold))

            Text("Billing accounts, service agreements, billing runs, invoices, and invoice line items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Optional Future Finance Cards

extension Finance {

    var contracts: some View {
        financeCard(
            title: "Contracts",
            subtitle: "Customer contracts and contract revenue.",
            systemImage: "doc.text.fill",
            countText: VM.contractCount == nil ? nil : "\(String(format: "%.0f", VM.contractCount ?? 0))",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.contracts(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .contracts
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.contractCount {
                        statRow(title: "Open Contracts", value: String(format: "%.0f", count), systemImage: "doc.text")
                    }

                    if let count = VM.pendingContractCount {
                        statRow(title: "Pending", value: String(format: "%.0f", count), systemImage: "clock")
                    }

                    if let total = VM.contractTotal {
                        statRow(title: "Total", value: currency(total), systemImage: "dollarsign.circle")
                    }
                }
            },
            preview: {
                EmptyView()
            }
        )
    }

    var recurringContracts: some View {
        financeCard(
            title: "Recurring Contracts",
            subtitle: "Recurring customer contracts and scheduled contract work.",
            systemImage: "repeat",
            countText: VM.contractCount == nil ? nil : "\(String(format: "%.0f", VM.contractCount ?? 0))",
            seeMore: {
                if UIDevice.isIPhone {
                    AnyView(
                        NavigationLink(value: Route.recurringContracts(dataService: dataService)) {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                } else {
                    AnyView(
                        Button {
                            masterDataManager.selectedCategory = .contracts
                        } label: {
                            seeMoreLabel
                        }
                        .buttonStyle(.plain)
                    )
                }
            },
            stats: {
                VStack(spacing: 8) {
                    if let count = VM.contractCount {
                        statRow(title: "Open Contracts", value: String(format: "%.0f", count), systemImage: "doc.text")
                    }

                    if let count = VM.pendingContractCount {
                        statRow(title: "Pending", value: String(format: "%.0f", count), systemImage: "clock")
                    }

                    if let total = VM.contractTotal {
                        statRow(title: "Total", value: currency(total), systemImage: "dollarsign.circle")
                    }
                }
            },
            preview: {
                EmptyView()
            }
        )
    }
}

// MARK: - Reusable Card UI

extension Finance {

    var shouldShowStats: Bool {
        masterDataManager.mainScreenDisplayType == .fullPreview ||
        masterDataManager.mainScreenDisplayType == .preview
    }

    var shouldShowFullPreview: Bool {
        masterDataManager.mainScreenDisplayType == .fullPreview
    }

    var seeMoreLabel: some View {
        Label("See More", systemImage: "arrow.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.poolRed)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.poolRed.opacity(0.10), in: Capsule())
    }

    func financeCard<Stats: View, Preview: View, SeeMore: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        countText: String?,
        @ViewBuilder seeMore: () -> SeeMore,
        @ViewBuilder stats: () -> Stats,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    if let countText {
                        Text(countText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.thinMaterial, in: Capsule())
                    }

                    seeMore()
                }
            }

            if shouldShowStats {
                stats()
            }

            preview()
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    func statRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func horizontalPreviewList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                content()
            }
            .padding(.vertical, 2)
        }
    }

    func previewTile(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.isEmpty ? "-" : title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(width: 142, height: 118)
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    func emptyPreviewTile(_ title: String, systemImage: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func emptyState(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()

                Text("Loading finance...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    func purchasedItemsPreview(emptyTitle: String) -> some View {
        Group {
            if VM.purchasedItems.isEmpty {
                emptyPreviewTile(emptyTitle, systemImage: "cart")
            } else {
                horizontalPreviewList {
                    ForEach(VM.purchasedItems) { item in
                        if UIDevice.isIPhone {
                            NavigationLink(
                                value: Route.purchase(
                                    purchasedItem: item,
                                    dataService: dataService
                                )
                            ) {
                                previewTile(
                                    title: item.name,
                                    subtitle: centsCurrency(Int(item.totalAfterTax * 100)),
                                    systemImage: "cart.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                masterDataManager.selectedPurchases = item
                                masterDataManager.selectedCategory = .purchases
                            } label: {
                                previewTile(
                                    title: item.name,
                                    subtitle: centsCurrency(Int(item.totalAfterTax * 100)),
                                    systemImage: "cart.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    func currency(_ amount: Double) -> String {
        amount.formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }

    func centsCurrency(_ cents: Int) -> String {
        (Double(cents) / 100.0).formatted(
            .currency(code: "USD")
            .precision(.fractionLength(0))
        )
    }
}
