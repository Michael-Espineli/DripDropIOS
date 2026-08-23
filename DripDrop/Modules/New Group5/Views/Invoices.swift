//
//  Invoices.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/29/25.
//

import SwiftUI

@MainActor
final class SalesListViewModel: ObservableObject {
    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    @Published private(set) var agreements: [SalesAgreement] = []
    @Published private(set) var invoices: [SalesInvoice] = []
    @Published private(set) var subscriptions: [SalesBillingSubscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func loadAgreements(companyId: String?) async {
        guard let companyId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            agreements = try await dataService
                .getSalesAgreements(companyId: companyId)
                .sorted { salesAgreementDate($0) > salesAgreementDate($1) }
        } catch {
            errorMessage = "Unable to load service agreements."
            print("[SalesListViewModel][loadAgreements] \(error)")
        }
    }

    func loadInvoices(companyId: String?) async {
        guard let companyId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            invoices = try await dataService
                .getSalesInvoices(companyId: companyId)
                .sorted { salesInvoiceDate($0) > salesInvoiceDate($1) }
        } catch {
            errorMessage = "Unable to load invoices."
            print("[SalesListViewModel][loadInvoices] \(error)")
        }
    }

    func loadSubscriptions(companyId: String?) async {
        guard let companyId else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            subscriptions = try await dataService
                .getSalesBillingSubscriptions(companyId: companyId)
                .sorted { salesSubscriptionDate($0) > salesSubscriptionDate($1) }
        } catch {
            errorMessage = "Unable to load billing subscriptions."
            print("[SalesListViewModel][loadSubscriptions] \(error)")
        }
    }
}

enum SalesAgreementListMode {
    case estimates
    case serviceAgreements

    var title: String {
        switch self {
        case .estimates:
            return "Estimates"
        case .serviceAgreements:
            return "Service Agreements"
        }
    }

    var subtitle: String {
        switch self {
        case .estimates:
            return "Job and service estimate approvals."
        case .serviceAgreements:
            return "Customer-facing recurring service agreements."
        }
    }

    var systemImage: String {
        switch self {
        case .estimates:
            return "doc.text.magnifyingglass"
        case .serviceAgreements:
            return "doc.text.fill"
        }
    }

    var tint: Color {
        switch self {
        case .estimates:
            return .pink
        case .serviceAgreements:
            return .poolGreen
        }
    }

    var defaultScope: SalesEstimateScope {
        switch self {
        case .estimates:
            return .job
        case .serviceAgreements:
            return .service
        }
    }

    var createPath: String {
        "/company/sales/agreements/new"
    }
}

enum SalesEstimateScope: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case job = "Job"
    case service = "Service"
    case all = "All"
}

struct SalesAgreementsListView: View {
    let mode: SalesAgreementListMode

    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var VM: SalesListViewModel
    @State private var showSearch = false
    @State private var searchTerm = ""
    @State private var scope: SalesEstimateScope

    init(dataService: any ProductionDataServiceProtocol, mode: SalesAgreementListMode) {
        self.mode = mode
        _VM = StateObject(wrappedValue: SalesListViewModel(dataService: dataService))
        _scope = State(initialValue: mode.defaultScope)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                salesHeader

                if mode == .estimates {
                    scopePicker
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                if showSearch {
                    SalesSearchBar(text: $searchTerm, placeholder: "Search \(mode.title.lowercased())")
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if VM.isLoading {
                            ProgressView()
                                .padding(.top, 48)
                        } else if let errorMessage = VM.errorMessage {
                            SalesEmptyState(
                                title: errorMessage,
                                message: "Pull to refresh or try again from the action menu.",
                                systemImage: "exclamationmark.triangle"
                            )
                            .padding(.top, 42)
                        } else if displayAgreements.isEmpty {
                            SalesEmptyState(
                                title: "No \(mode.title.lowercased()) found.",
                                message: "Create or update sales records from the web app to populate this list.",
                                systemImage: mode.systemImage
                            )
                            .padding(.top, 42)
                        } else {
                            ForEach(displayAgreements) { agreement in
                                Button {
                                    salesOpenWeb(path: "/company/sales/agreements/\(agreement.id)")
                                } label: {
                                    SalesAgreementCard(agreement: agreement)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Color.clear.frame(height: UIDevice.isIPhone ? 96 : 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .refreshable {
                    await reload()
                }
            }

            if UIDevice.isIPhone {
                SalesActionDock(
                    showCreate: true,
                    showSearch: showSearch,
                    createTint: mode.tint,
                    onReload: { Task { await reload() } },
                    onCreate: { salesOpenWeb(path: mode.createPath) },
                    onSearch: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            showSearch.toggle()
                        }
                    }
                )
            }
        }
        .navigationTitle(mode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        salesOpenWeb(path: mode.createPath)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await reload()
        }
    }
}

extension SalesAgreementsListView {
    private var displayAgreements: [SalesAgreement] {
        scopedAgreements.filter { agreement in
            let cleanSearch = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !cleanSearch.isEmpty else { return true }

            return [
                agreement.title,
                agreement.customerName,
                agreement.email,
                agreement.status.rawValue,
                agreement.termsTemplateName ?? "",
                agreement.sourceType.rawValue,
                agreement.sourceId
            ]
            .map { $0.lowercased() }
            .contains { $0.contains(cleanSearch) }
        }
    }

    private var scopedAgreements: [SalesAgreement] {
        switch scope {
        case .job:
            return VM.agreements.filter { salesAgreementIsJobEstimate($0) }
        case .service:
            return VM.agreements.filter { !salesAgreementIsJobEstimate($0) }
        case .all:
            return VM.agreements
        }
    }

    private var salesHeader: some View {
        SalesListHeader(
            title: mode.title,
            subtitle: mode.subtitle,
            systemImage: mode.systemImage,
            tint: mode.tint,
            metrics: [
                SalesListMetric(title: "Showing", value: "\(displayAgreements.count)", tint: mode.tint),
                SalesListMetric(title: "Active", value: "\(scopedAgreements.filter { $0.status == .accepted }.count)", tint: .poolGreen),
                SalesListMetric(title: "Total", value: salesCents(salesAgreementTotalCents).formatted(.currency(code: "USD").precision(.fractionLength(0))), tint: .orange)
            ]
        )
    }

    private var scopePicker: some View {
        Picker("Estimate Type", selection: $scope) {
            ForEach(SalesEstimateScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    private var salesAgreementTotalCents: Int {
        displayAgreements.reduce(0) { $0 + salesAgreementAmountCents($1) }
    }

    @MainActor
    private func reload() async {
        await VM.loadAgreements(companyId: masterDataManager.currentCompany?.id)
    }
}

struct Invoices: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var VM: SalesListViewModel
    @State private var showSearch = false
    @State private var searchTerm = ""

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: SalesListViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                invoiceHeader

                if showSearch {
                    SalesSearchBar(text: $searchTerm, placeholder: "Search invoices")
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if VM.isLoading {
                            ProgressView()
                                .padding(.top, 48)
                        } else if let errorMessage = VM.errorMessage {
                            SalesEmptyState(
                                title: errorMessage,
                                message: "Pull to refresh or try again from the action menu.",
                                systemImage: "exclamationmark.triangle"
                            )
                            .padding(.top, 42)
                        } else if displayInvoices.isEmpty {
                            SalesEmptyState(
                                title: "No invoices found.",
                                message: "Create or send sales invoices from the web app to populate this list.",
                                systemImage: "receipt"
                            )
                            .padding(.top, 42)
                        } else {
                            ForEach(displayInvoices) { invoice in
                                Button {
                                    salesOpenWeb(path: "/company/sales/invoices/\(invoice.id)")
                                } label: {
                                    SalesInvoiceCard(invoice: invoice)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Color.clear.frame(height: UIDevice.isIPhone ? 96 : 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .refreshable {
                    await reload()
                }
            }

            if UIDevice.isIPhone {
                SalesActionDock(
                    showCreate: true,
                    showSearch: showSearch,
                    createTint: .purple,
                    onReload: { Task { await reload() } },
                    onCreate: { salesOpenWeb(path: "/company/sales/invoices/new") },
                    onSearch: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            showSearch.toggle()
                        }
                    }
                )
            }
        }
        .navigationTitle("Invoices")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }

                    Button {
                        salesOpenWeb(path: "/company/sales/invoices/new")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .task {
            await reload()
        }
    }
}

extension Invoices {
    private var displayInvoices: [SalesInvoice] {
        VM.invoices.filter { invoice in
            let cleanSearch = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !cleanSearch.isEmpty else { return true }

            return [
                invoice.invoiceNumber,
                invoice.customerName ?? "",
                invoice.email ?? "",
                invoice.status.rawValue,
                invoice.type?.rawValue ?? "",
                invoice.memo ?? ""
            ]
            .map { $0.lowercased() }
            .contains { $0.contains(cleanSearch) }
        }
    }

    private var invoiceHeader: some View {
        SalesListHeader(
            title: "Invoices",
            subtitle: "Sales invoices from agreements, jobs, and manual billing.",
            systemImage: "receipt.fill",
            tint: .purple,
            metrics: [
                SalesListMetric(title: "Showing", value: "\(displayInvoices.count)", tint: .purple),
                SalesListMetric(title: "Open", value: "\(displayInvoices.filter { salesInvoiceNeedsAttention($0) }.count)", tint: .orange),
                SalesListMetric(title: "Balance", value: salesCents(openBalanceCents).formatted(.currency(code: "USD").precision(.fractionLength(0))), tint: .poolGreen)
            ]
        )
    }

    private var openBalanceCents: Int {
        displayInvoices.reduce(0) { $0 + salesInvoiceBalanceCents($1) }
    }

    @MainActor
    private func reload() async {
        await VM.loadInvoices(companyId: masterDataManager.currentCompany?.id)
    }
}

struct SalesBillingSubscriptionsListView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var VM: SalesListViewModel
    @State private var showSearch = false
    @State private var searchTerm = ""

    init(dataService: any ProductionDataServiceProtocol) {
        _VM = StateObject(wrappedValue: SalesListViewModel(dataService: dataService))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                subscriptionHeader

                if showSearch {
                    SalesSearchBar(text: $searchTerm, placeholder: "Search subscriptions")
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        if VM.isLoading {
                            ProgressView()
                                .padding(.top, 48)
                        } else if let errorMessage = VM.errorMessage {
                            SalesEmptyState(
                                title: errorMessage,
                                message: "Pull to refresh or try again from the action menu.",
                                systemImage: "exclamationmark.triangle"
                            )
                            .padding(.top, 42)
                        } else if displaySubscriptions.isEmpty {
                            SalesEmptyState(
                                title: "No billing subscriptions found.",
                                message: "Accepted recurring agreements will create customer billing subscriptions.",
                                systemImage: "repeat.circle"
                            )
                            .padding(.top, 42)
                        } else {
                            ForEach(displaySubscriptions) { subscription in
                                Button {
                                    salesOpenWeb(path: "/company/sales/subscriptions/\(subscription.id)")
                                } label: {
                                    SalesBillingSubscriptionCard(subscription: subscription)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Color.clear.frame(height: UIDevice.isIPhone ? 96 : 24)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
                .refreshable {
                    await reload()
                }
            }

            if UIDevice.isIPhone {
                SalesActionDock(
                    showCreate: false,
                    showSearch: showSearch,
                    createTint: .pink,
                    onReload: { Task { await reload() } },
                    onCreate: {},
                    onSearch: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            showSearch.toggle()
                        }
                    }
                )
            }
        }
        .navigationTitle("Billing Subscriptions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSearch.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

                    Button {
                        Task { await reload() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await reload()
        }
    }
}

extension SalesBillingSubscriptionsListView {
    private var displaySubscriptions: [SalesBillingSubscription] {
        VM.subscriptions.filter { subscription in
            let cleanSearch = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !cleanSearch.isEmpty else { return true }

            return [
                subscription.customerName ?? "",
                subscription.email ?? "",
                subscription.status.rawValue,
                subscription.stripeStatus,
                subscription.interval,
                subscription.stripeSubscriptionId
            ]
            .map { $0.lowercased() }
            .contains { $0.contains(cleanSearch) }
        }
    }

    private var subscriptionHeader: some View {
        SalesListHeader(
            title: "Billing Subscriptions",
            subtitle: "Customer recurring billing created from accepted agreements.",
            systemImage: "repeat.circle.fill",
            tint: .pink,
            metrics: [
                SalesListMetric(title: "Showing", value: "\(displaySubscriptions.count)", tint: .pink),
                SalesListMetric(title: "Active", value: "\(displaySubscriptions.filter { $0.status == .active }.count)", tint: .poolGreen),
                SalesListMetric(title: "MRR", value: salesCents(monthlyRecurringRevenueCents).formatted(.currency(code: "USD").precision(.fractionLength(0))), tint: .orange)
            ]
        )
    }

    private var monthlyRecurringRevenueCents: Int {
        displaySubscriptions
            .filter { $0.status == .active }
            .reduce(0) { $0 + salesMonthlyAmountCents($1) }
    }

    @MainActor
    private func reload() async {
        await VM.loadSubscriptions(companyId: masterDataManager.currentCompany?.id)
    }
}

private struct SalesListMetric {
    let title: String
    let value: String
    let tint: Color
}

private struct SalesListHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let metrics: [SalesListMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.value)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(metric.tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(metric.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(metric.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

private struct SalesSearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct SalesEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SalesActionDock: View {
    let showCreate: Bool
    let showSearch: Bool
    let createTint: Color
    let onReload: () -> Void
    let onCreate: () -> Void
    let onSearch: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onReload) {
                dockIcon(systemName: "arrow.clockwise", tint: .orange, isSelected: false)
            }
            .buttonStyle(.plain)

            if showCreate {
                Button(action: onCreate) {
                    dockIcon(systemName: "plus", tint: createTint, isSelected: false)
                }
                .buttonStyle(.plain)
            }

            Button(action: onSearch) {
                dockIcon(systemName: "magnifyingglass", tint: .poolBlue, isSelected: showSearch)
            }
            .buttonStyle(.plain)
        }
        .padding(7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .padding(.trailing, 14)
        .padding(.bottom, 18)
    }

    private func dockIcon(systemName: String, tint: Color, isSelected: Bool) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }
}

private struct SalesAgreementCard: View {
    let agreement: SalesAgreement

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(salesAgreementTint(agreement))
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(agreement.title.isEmpty ? "Service Agreement" : agreement.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(agreement.customerName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(salesCents(salesAgreementAmountCents(agreement)), format: .currency(code: "USD"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(salesDateDisplay(salesAgreementDate(agreement)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 7) {
                    SalesStatusPill(title: salesLabel(agreement.status.rawValue), tint: salesAgreementTint(agreement))

                    SalesInfoPill(
                        title: salesAgreementIsJobEstimate(agreement) ? "Job Estimate" : "Service Agreement",
                        systemImage: salesAgreementIsJobEstimate(agreement) ? "briefcase" : "repeat"
                    )

                    SalesInfoPill(title: salesCadenceLabel(agreement), systemImage: "calendar")
                }

                if let templateName = agreement.termsTemplateName, !templateName.isEmpty {
                    Text(templateName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SalesInvoiceCard: View {
    let invoice: SalesInvoice

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(salesInvoiceTint(invoice))
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.invoiceNumber.isEmpty ? "Invoice" : invoice.invoiceNumber)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(invoice.customerName ?? "Customer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(salesCents(salesInvoiceBalanceCents(invoice)), format: .currency(code: invoice.currency.uppercased()))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(invoice.dueDate.map { "Due \(salesDateDisplay($0))" } ?? salesDateDisplay(salesInvoiceDate(invoice)))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 7) {
                    SalesStatusPill(title: salesLabel(invoice.status.rawValue), tint: salesInvoiceTint(invoice))

                    if let type = invoice.type {
                        SalesInfoPill(title: salesLabel(type.rawValue), systemImage: "doc.text")
                    }

                    SalesInfoPill(title: "\(invoice.lineItems.count) line\(invoice.lineItems.count == 1 ? "" : "s")", systemImage: "list.bullet")
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SalesBillingSubscriptionCard: View {
    let subscription: SalesBillingSubscription

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(salesSubscriptionTint(subscription))
                .frame(width: 5)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscription.customerName ?? "Customer")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(subscription.email ?? subscription.stripeSubscriptionId)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(salesCents(subscription.amountCents), format: .currency(code: subscription.currency.uppercased()))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(subscription.currentPeriodEnd.map { "Renews \(salesDateDisplay($0))" } ?? salesIntervalLabel(subscription))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 7) {
                    SalesStatusPill(title: salesLabel(subscription.status.rawValue), tint: salesSubscriptionTint(subscription))
                    SalesInfoPill(title: salesIntervalLabel(subscription), systemImage: "repeat")

                    if subscription.cancelAtPeriodEnd {
                        SalesStatusPill(title: "Canceling", tint: .orange)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SalesStatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct SalesInfoPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.thinMaterial, in: Capsule())
    }
}

private func salesOpenWeb(path: String) {
    guard let url = URL(string: "https://dripdrop-poolapp.com\(path)") else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}

private func salesCents(_ cents: Int) -> Double {
    Double(cents) / 100
}

private func salesLabel(_ value: String) -> String {
    value
        .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .capitalized
}

private func salesDateDisplay(_ date: Date) -> String {
    if date == Date.distantPast {
        return "Not set"
    }

    return shortDate(date: date)
}

private func salesAgreementDate(_ agreement: SalesAgreement) -> Date {
    agreement.updatedAt ?? agreement.sentAt ?? agreement.createdAt ?? agreement.startDate ?? .distantPast
}

private func salesInvoiceDate(_ invoice: SalesInvoice) -> Date {
    invoice.updatedAt ?? invoice.sentAt ?? invoice.createdAt ?? invoice.dueDate ?? .distantPast
}

private func salesSubscriptionDate(_ subscription: SalesBillingSubscription) -> Date {
    subscription.updatedAt ?? subscription.currentPeriodEnd ?? subscription.createdAt ?? .distantPast
}

private func salesAgreementAmountCents(_ agreement: SalesAgreement) -> Int {
    agreement.totalAmountCents ?? agreement.subtotalAmountCents ?? agreement.rateAmountCents
}

private func salesAgreementIsJobEstimate(_ agreement: SalesAgreement) -> Bool {
    agreement.sourceType == .oneOffJob ||
    agreement.rateType == "oneTime" ||
    agreement.serviceCadence == "oneTime"
}

private func salesCadenceLabel(_ agreement: SalesAgreement) -> String {
    if salesAgreementIsJobEstimate(agreement) {
        return "One Time"
    }

    let interval = agreement.serviceCadence.isEmpty ? agreement.rateType : agreement.serviceCadence
    let count = max(agreement.serviceCadenceCount, 1)

    if interval.isEmpty || interval == "recurring" {
        return "Recurring"
    }

    if count > 1 {
        return "Every \(count) \(salesLabel(interval).lowercased())s"
    }

    return salesLabel(interval)
}

private func salesAgreementTint(_ agreement: SalesAgreement) -> Color {
    switch agreement.status {
    case .accepted:
        return .poolGreen
    case .sent, .revised:
        return .poolBlue
    case .rejected, .expired, .canceled:
        return .poolRed
    case .draft:
        return .orange
    }
}

private func salesInvoiceBalanceCents(_ invoice: SalesInvoice) -> Int {
    if let amountDue = invoice.amountDueCents {
        return max(amountDue, 0)
    }

    return max(invoice.totalAmountCents - (invoice.amountPaidCents ?? 0), 0)
}

private func salesInvoiceNeedsAttention(_ invoice: SalesInvoice) -> Bool {
    switch invoice.status {
    case .open, .partiallyPaid, .overdue:
        return true
    default:
        return false
    }
}

private func salesInvoiceTint(_ invoice: SalesInvoice) -> Color {
    switch invoice.status {
    case .paid:
        return .poolGreen
    case .open, .partiallyPaid:
        return .poolBlue
    case .overdue, .uncollectible:
        return .poolRed
    case .void:
        return .secondary
    case .draft:
        return .orange
    }
}

private func salesMonthlyAmountCents(_ subscription: SalesBillingSubscription) -> Int {
    let count = max(subscription.intervalCount, 1)

    switch subscription.interval.lowercased() {
    case "year", "yearly", "annual":
        return subscription.amountCents / (12 * count)
    case "week", "weekly":
        return Int(Double(subscription.amountCents) * 52 / 12 / Double(count))
    default:
        return subscription.amountCents / count
    }
}

private func salesIntervalLabel(_ subscription: SalesBillingSubscription) -> String {
    let interval = subscription.interval.isEmpty ? "month" : subscription.interval
    let count = max(subscription.intervalCount, 1)

    if count > 1 {
        return "Every \(count) \(salesLabel(interval).lowercased())s"
    }

    return salesLabel(interval)
}

private func salesSubscriptionTint(_ subscription: SalesBillingSubscription) -> Color {
    switch subscription.status {
    case .active:
        return .poolGreen
    case .pendingPaymentMethod, .pendingStripe, .notStarted:
        return .orange
    case .pastDue:
        return .poolRed
    case .paused:
        return .poolBlue
    case .canceled:
        return .secondary
    }
}

#Preview {
    Invoices(dataService: MockDataService())
}
