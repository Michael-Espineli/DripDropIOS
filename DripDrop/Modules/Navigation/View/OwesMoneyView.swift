//
//  OwesMoneyView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/30/25.
//

import SwiftUI
import MapKit
import Firebase
import Charts

struct OwesMoneyView: View {
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

    @State private var selectedSection: String = ""

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    headerCard

                    if !masterDataManager.featureFlagsLoaded {
                        emptyState(
                            title: "Loading feature flags.",
                            message: "Sales availability will appear after feature flags load.",
                            systemImage: "flag"
                        )
                    } else if let role = masterDataManager.role {
                        if role.permissionIdList.contains("400") && masterDataManager.isFeatureEnabled(.sales) {
                            salesOverview
                        } else if !masterDataManager.isFeatureEnabled(.sales) {
                            emptyState(
                                title: "Sales unavailable.",
                                message: "Sales is currently turned off by feature flag 4.",
                                systemImage: "flag.slash"
                            )
                        } else {
                            emptyState(
                                title: "No sales access.",
                                message: "Your role does not currently include finance or sales permissions.",
                                systemImage: "lock.shield"
                            )
                        }
                    } else {
                        emptyState(
                            title: "Loading role.",
                            message: "Sales tools will appear after your role permissions load.",
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
            print("[OwesMoneyView][loadFinance]")
            print(error)
        }
    }
}

// MARK: - Main Sections

extension OwesMoneyView {

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: "arrow.down.doc")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Sales")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(masterDataManager.currentCompany?.name ?? "Review finished jobs, invoices, accounts receivable, and billable customer work.")
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

                if let role = masterDataManager.role {
                    Label("\(role.permissionIdList.count) Permissions", systemImage: "lock.shield")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }

                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var quickAccess: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let role = masterDataManager.role {
                if role.permissionIdList.contains("400") {
                    snapshot
                    salesOverview
                }
            }
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

    var salesOverview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Sales Overview", systemImage: "slider.horizontal.3")
                Spacer()
            }

            if let role = masterDataManager.role {
                if role.permissionIdList.contains("410") {
                    finishedJobs
                }

                /*
                 Roll these back in when ready:
                 contracts
                 recurringContracts
                 invoices
                 accountsReceivable
                 receivedLaborContract
                 receivedRecurringLaborContract
                */
            }
        }
    }
}

// MARK: - Sales Cards

extension OwesMoneyView {

    var finishedJobs: some View {
        salesCard(
            title: "Finished Jobs",
            subtitle: "Jobs ready for billing review, customer invoicing, or closeout.",
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
        salesCard(
            title: "Invoices",
            subtitle: "Customer invoices, billed items, and billable purchase tracking.",
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
                purchaseStats
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Invoice Items")
                }
            }
        )
    }

    var purchases: some View {
        salesCard(
            title: "Purchases",
            subtitle: "Purchased items connected to customer work and billable jobs.",
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
                purchaseStats
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Purchases")
                }
            }
        )
    }

    var receipts: some View {
        salesCard(
            title: "Receipts",
            subtitle: "Uploaded receipts related to sales, jobs, and customer materials.",
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
                purchaseStats
            },
            preview: {
                if shouldShowFullPreview {
                    purchasedItemsPreview(emptyTitle: "No Receipts")
                }
            }
        )
    }

    var accountsReceivable: some View {
        salesCard(
            title: "Accounts Receivable",
            subtitle: "Money owed to your company from customer invoices.",
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
                            value: "\(count)",
                            systemImage: "tray"
                        )
                    }

                    if let total = VM.ARTotal {
                        statRow(
                            title: "Receivable Total",
                            value: currency(total),
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
}

// MARK: - Optional / Future Cards

extension OwesMoneyView {

    var accountsPayable: some View {
        salesCard(
            title: "Accounts Payable",
            subtitle: "Money the company owes to vendors or contractors.",
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
                            value: "\(count)",
                            systemImage: "tray"
                        )
                    }

                    if let total = VM.APTotal {
                        statRow(
                            title: "Total",
                            value: currency(total),
                            systemImage: "dollarsign.circle"
                        )
                    }

                    if let late = VM.APOutstandingLateCount {
                        statRow(
                            title: "Late",
                            value: "\(late)",
                            systemImage: "exclamationmark.triangle"
                        )
                    }

                    if let lateTotal = VM.APTotalOutstandingLate {
                        statRow(
                            title: "Late Total",
                            value: centsCurrency(lateTotal),
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

    var contracts: some View {
        salesCard(
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
                contractStats
            },
            preview: {
                contractsPreview(emptyTitle: "No Contracts")
            }
        )
    }

    var recurringContracts: some View {
        salesCard(
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
                contractStats
            },
            preview: {
                contractsPreview(emptyTitle: "No Recurring Contracts")
            }
        )
    }

    var sentLaborContract: some View {
        laborContractCard(
            title: "Sent Labor Contracts",
            subtitle: "Labor contracts sent from your company.",
            systemImage: "paperplane",
            route: .sent
        )
    }

    var receivedLaborContract: some View {
        laborContractCard(
            title: "Received Labor Contracts",
            subtitle: "Labor contracts received by your company.",
            systemImage: "tray.and.arrow.down",
            route: .received
        )
    }

    var sentRecurringLaborContract: some View {
        recurringLaborContractCard(
            title: "Sent Recurring Labor Contracts",
            subtitle: "Recurring labor contracts sent from your company.",
            systemImage: "paperplane.circle",
            route: .sent
        )
    }

    var receivedRecurringLaborContract: some View {
        recurringLaborContractCard(
            title: "Received Recurring Labor Contracts",
            subtitle: "Recurring labor contracts received by your company.",
            systemImage: "tray.and.arrow.down.fill",
            route: .received
        )
    }
}

// MARK: - Reusable Card UI

extension OwesMoneyView {

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

    func salesCard<Stats: View, Preview: View, SeeMore: View>(
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
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if let countText {
                            Text(countText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                seeMore()
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

                Text("Loading sales...")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(22)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    var purchaseStats: some View {
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

            if let items = VM.itemsPurchasedAndBilled {
                statRow(
                    title: "Billed Items",
                    value: String(format: "%.0f", items),
                    systemImage: "checkmark.seal"
                )
            }

            if let amount = VM.totalBilled {
                statRow(
                    title: "Total Billed",
                    value: currency(amount),
                    systemImage: "checkmark.circle"
                )
            }
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

    var contractStats: some View {
        VStack(spacing: 8) {
            if let count = VM.contractCount {
                statRow(
                    title: "Open Contracts",
                    value: String(format: "%.0f", count),
                    systemImage: "doc.text"
                )
            }

            if let count = VM.pendingContractCount {
                statRow(
                    title: "Pending Contracts",
                    value: String(format: "%.0f", count),
                    systemImage: "clock"
                )
            }

            if let total = VM.contractTotal {
                statRow(
                    title: "Contract Total",
                    value: currency(total),
                    systemImage: "dollarsign.circle"
                )
            }
        }
    }

    func contractsPreview(emptyTitle: String) -> some View {
        Group {
            if VM.contractList.isEmpty {
                emptyPreviewTile(emptyTitle, systemImage: "doc.text")
            } else {
                horizontalPreviewList {
                    ForEach(VM.contractList) { contract in
                        if UIDevice.isIPhone {
                            NavigationLink(
                                value: Route.contract(
                                    contract: contract,
                                    dataService: dataService
                                )
                            ) {
                                previewTile(
                                    title: contract.internalCustomerName,
                                    subtitle: "",
                                    systemImage: "doc.text.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                masterDataManager.selectedCategory = .contracts
                                masterDataManager.selectedContract = contract
                            } label: {
                                previewTile(
                                    title: contract.internalCustomerName,
                                    subtitle: "",
                                    systemImage: "doc.text.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    enum LaborContractRouteStyle {
        case sent
        case received
    }

    func laborContractCard(
        title: String,
        subtitle: String,
        systemImage: String,
        route: LaborContractRouteStyle
    ) -> some View {
        salesCard(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            countText: VM.laborContractList.isEmpty ? nil : "\(VM.laborContractList.count)",
            seeMore: {
                switch route {
                case .sent:
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.sentLaborContracts(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .sentLaborContracts
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }

                case .received:
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.receivedLaborContracts(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .receivedLaborContracts
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                }
            },
            stats: {
                laborContractStats(route: route)
            },
            preview: {
                laborContractPreview(emptyTitle: "No Labor Contracts")
            }
        )
    }

    func recurringLaborContractCard(
        title: String,
        subtitle: String,
        systemImage: String,
        route: LaborContractRouteStyle
    ) -> some View {
        salesCard(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            countText: VM.laborContractList.isEmpty ? nil : "\(VM.laborContractList.count)",
            seeMore: {
                switch route {
                case .sent:
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.sentRecurringLaborContracts(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .sentLaborContracts
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }

                case .received:
                    if UIDevice.isIPhone {
                        AnyView(
                            NavigationLink(value: Route.receivedRecurringLaborContracts(dataService: dataService)) {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    } else {
                        AnyView(
                            Button {
                                masterDataManager.selectedCategory = .receivedLaborContracts
                            } label: {
                                seeMoreLabel
                            }
                            .buttonStyle(.plain)
                        )
                    }
                }
            },
            stats: {
                laborContractStats(route: route)
            },
            preview: {
                laborContractPreview(emptyTitle: "No Recurring Labor Contracts")
            }
        )
    }

    func laborContractStats(route: LaborContractRouteStyle) -> some View {
        VStack(spacing: 8) {
            switch route {
            case .sent:
                if let count = VM.sentAcceptedLaborContractCount {
                    statRow(
                        title: "Accepted",
                        value: String(format: "%.0f", count),
                        systemImage: "checkmark.circle"
                    )
                }

                if let count = VM.sentPendingLaborContractCount {
                    statRow(
                        title: "Pending",
                        value: String(format: "%.0f", count),
                        systemImage: "clock"
                    )
                }

                if let count = VM.sentPastLaborContractCount {
                    statRow(
                        title: "Past",
                        value: String(format: "%.0f", count),
                        systemImage: "calendar.badge.exclamationmark"
                    )
                }

                if let total = VM.sentLaborContractTotal {
                    statRow(
                        title: "Total",
                        value: currency(total),
                        systemImage: "dollarsign.circle"
                    )
                }

            case .received:
                if let count = VM.receivedLaborContractCount {
                    statRow(
                        title: "Total Contracts",
                        value: String(format: "%.0f", count),
                        systemImage: "doc.text"
                    )
                }

                if let count = VM.receivedAcceptedLaborContractCount {
                    statRow(
                        title: "Accepted",
                        value: String(format: "%.0f", count),
                        systemImage: "checkmark.circle"
                    )
                }

                if let count = VM.receivedPendingLaborContractCount {
                    statRow(
                        title: "Pending",
                        value: String(format: "%.0f", count),
                        systemImage: "clock"
                    )
                }

                if let count = VM.receivedPastLaborContractCount {
                    statRow(
                        title: "Past",
                        value: String(format: "%.0f", count),
                        systemImage: "calendar.badge.exclamationmark"
                    )
                }
            }
        }
    }

    func laborContractPreview(emptyTitle: String) -> some View {
        Group {
            if VM.laborContractList.isEmpty {
                emptyPreviewTile(emptyTitle, systemImage: "doc.text")
            } else {
                horizontalPreviewList {
                    ForEach(VM.laborContractList) { contract in
                        if UIDevice.isIPhone {
                            NavigationLink(
                                value: Route.recurringLaborContractDetailView(
                                    contract: contract,
                                    dataService: dataService
                                )
                            ) {
                                previewTile(
                                    title: contract.senderName,
                                    subtitle: "",
                                    systemImage: "doc.text.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                masterDataManager.selectedCategory = .receivedLaborContracts
                                masterDataManager.selectedRecurringLaborContract = contract
                            } label: {
                                previewTile(
                                    title: contract.senderName,
                                    subtitle: "",
                                    systemImage: "doc.text.fill"
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
