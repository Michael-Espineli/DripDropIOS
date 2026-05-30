//
//  TechnicianWorkCenterView.swift
//  DripDrop
//

import SwiftUI

enum TechnicianWorkCenterTab: String, CaseIterable, Identifiable {
    case directOffers = "Offers"
    case workBoard = "Board"
    case accepted = "Accepted"

    var id: String { rawValue }
}

@MainActor
final class TechnicianWorkCenterViewModel: ObservableObject {

    @Published var directOffers: [WorkOffer] = []
    @Published var boardOffers: [WorkOffer] = []

    @Published var selectedTab: TechnicianWorkCenterTab = .directOffers

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyId: String
    let companyUser: CompanyUser
    let dataService: any ProductionDataServiceProtocol

    private var hasLoaded = false

    init(
        companyId: String,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyId = companyId
        self.companyUser = companyUser
        self.dataService = dataService
    }

    var openDirectOffers: [WorkOffer] {
        directOffers
            .filter {
                $0.status == .sent ||
                $0.status == .viewed ||
                $0.status == .posted
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var acceptedOffers: [WorkOffer] {
        let allOffers = directOffers + boardOffers

        return allOffers
            .filter {
                $0.status == .accepted ||
                $0.status == .scheduled ||
                $0.status == .inProgress ||
                $0.status == .completed
            }
            .filter {
                $0.acceptedByUserId == companyUser.userId ||
                $0.offeredToUserId == companyUser.userId
            }
            .uniqueById()
            .sorted { $0.createdAt > $1.createdAt }
    }

    var openBoardOffers: [WorkOffer] {
        boardOffers
            .filter {
                $0.status == .posted ||
                $0.status == .viewed
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var directOfferCount: Int {
        openDirectOffers.count
    }

    var boardOfferCount: Int {
        openBoardOffers.count
    }

    var acceptedOfferCount: Int {
        acceptedOffers.count
    }

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let directTask = dataService.fetchWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )

            async let boardTask = dataService.fetchOpenBoardWorkOffers(
                companyId: companyId,
                workerType: companyUser.workerType
            )

            directOffers = try await directTask
            boardOffers = try await boardTask
        } catch {
            alertMessage = "Could not load work offers. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func acceptOffer(_ offer: WorkOffer) async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.acceptWorkOffer(
                companyId: companyId,
                workOfferId: offer.id,
                acceptedByUserId: companyUser.userId,
                acceptedByUserName: companyUser.userName
            )

            alertMessage = "Work accepted."
            showAlert = true

            await load(forceRefresh: true)
        } catch {
            alertMessage = "Could not accept work. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func rejectOffer(
        _ offer: WorkOffer,
        reason: String
    ) async {
        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.rejectWorkOffer(
                companyId: companyId,
                workOfferId: offer.id,
                rejectedByUserId: companyUser.userId,
                rejectedByUserName: companyUser.userName,
                reason: reason
            )

            alertMessage = "Work offer rejected."
            showAlert = true

            await load(forceRefresh: true)
        } catch {
            alertMessage = "Could not reject work. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct TechnicianWorkCenterView: View {

    @StateObject private var viewModel: TechnicianWorkCenterViewModel

    init(
        companyId: String,
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TechnicianWorkCenterViewModel(
                companyId: companyId,
                companyUser: companyUser,
                dataService: dataService
            )
        )
    }

    var body: some View {
        List {
            summarySection
            tabSection
            selectedContentSection
        }
        .navigationTitle("My Work")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading work...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("My Work", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 10) {
                TechnicianWorkSummaryChip(
                    title: "Offers",
                    value: "\(viewModel.directOfferCount)",
                    systemImage: "paperplane"
                )

                TechnicianWorkSummaryChip(
                    title: "Board",
                    value: "\(viewModel.boardOfferCount)",
                    systemImage: "list.bullet.clipboard"
                )

                TechnicianWorkSummaryChip(
                    title: "Accepted",
                    value: "\(viewModel.acceptedOfferCount)",
                    systemImage: "checkmark.circle"
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.companyUser.userName)
                    .font(.headline)

                Text(viewModel.companyUser.workerType.rawValue.isEmpty ? "Worker type not assigned" : viewModel.companyUser.workerType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Work Center")
        } footer: {
            Text("Accepting work does not create payroll by itself. Payroll is generated later from completed service stop work.")
        }
    }

    private var tabSection: some View {
        Section {
            Picker("View", selection: $viewModel.selectedTab) {
                ForEach(TechnicianWorkCenterTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var selectedContentSection: some View {
        switch viewModel.selectedTab {
        case .directOffers:
            directOffersSection

        case .workBoard:
            workBoardSection

        case .accepted:
            acceptedWorkSection
        }
    }

    private var directOffersSection: some View {
        Section {
            if viewModel.openDirectOffers.isEmpty {
                ContentUnavailableView(
                    "No Direct Offers",
                    systemImage: "paperplane",
                    description: Text("Work offered directly to you will appear here.")
                )
            } else {
                ForEach(viewModel.openDirectOffers) { offer in
                    NavigationLink {
                        TechnicianWorkOfferDetailView(
                            offer: offer,
                            companyUser: viewModel.companyUser,
                            canReject: true,
                            canAccept: true,
                            acceptAction: {
                                Task {
                                    await viewModel.acceptOffer(offer)
                                }
                            },
                            rejectAction: { reason in
                                Task {
                                    await viewModel.rejectOffer(
                                        offer,
                                        reason: reason
                                    )
                                }
                            }
                        )
                    } label: {
                        TechnicianWorkOfferRow(
                            offer: offer,
                            rowStyle: .directOffer
                        )
                    }
                }
            }
        } header: {
            Text("Direct Offers")
        }
    }

    private var workBoardSection: some View {
        Section {
            if viewModel.openBoardOffers.isEmpty {
                ContentUnavailableView(
                    "No Board Work",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Open internal board work will appear here when you are eligible.")
                )
            } else {
                ForEach(viewModel.openBoardOffers) { offer in
                    NavigationLink {
                        TechnicianWorkOfferDetailView(
                            offer: offer,
                            companyUser: viewModel.companyUser,
                            canReject: false,
                            canAccept: true,
                            acceptAction: {
                                Task {
                                    await viewModel.acceptOffer(offer)
                                }
                            },
                            rejectAction: { _ in }
                        )
                    } label: {
                        TechnicianWorkOfferRow(
                            offer: offer,
                            rowStyle: .boardPost
                        )
                    }
                }
            }
        } header: {
            Text("Internal Board")
        } footer: {
            Text("For now, the first worker to accept a board post claims it. Later you can add a claims/review flow.")
        }
    }

    private var acceptedWorkSection: some View {
        Section {
            if viewModel.acceptedOffers.isEmpty {
                ContentUnavailableView(
                    "No Accepted Work",
                    systemImage: "checkmark.circle",
                    description: Text("Accepted, scheduled, and completed work will appear here.")
                )
            } else {
                ForEach(viewModel.acceptedOffers) { offer in
                    NavigationLink {
                        TechnicianWorkOfferDetailView(
                            offer: offer,
                            companyUser: viewModel.companyUser,
                            canReject: false,
                            canAccept: false,
                            acceptAction: { },
                            rejectAction: { _ in }
                        )
                    } label: {
                        TechnicianWorkOfferRow(
                            offer: offer,
                            rowStyle: .accepted
                        )
                    }
                }
            }
        } header: {
            Text("Accepted Work")
        }
    }
}

// MARK: - Detail

struct TechnicianWorkOfferDetailView: View {

    let offer: WorkOffer
    let companyUser: CompanyUser

    let canReject: Bool
    let canAccept: Bool

    let acceptAction: () -> Void
    let rejectAction: (String) -> Void

    @State private var showRejectDialog: Bool = false
    @State private var rejectionReason: String = ""

    var body: some View {
        List {
            statusSection
            jobSection
            scopeSection
            paySection
            scheduleSection
            notesSection
            actionSection
        }
        .navigationTitle("Work Offer")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reject Work", isPresented: $showRejectDialog) {
            TextField("Reason", text: $rejectionReason)

            Button("Reject", role: .destructive) {
                rejectAction(rejectionReason)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add an optional reason for rejecting this offer.")
        }
    }

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Label(offer.offerType.title, systemImage: offer.offerType.systemImage)

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            TechnicianWorkDetailRow(title: "Worker", value: companyUser.userName)
            TechnicianWorkDetailRow(title: "Worker Type", value: companyUser.workerType.rawValue)
        }
    }

    private var jobSection: some View {
        Section("Job") {
            TechnicianWorkDetailRow(title: "Title", value: offer.title)
            TechnicianWorkDetailRow(title: "Job", value: "\(offer.jobInternalId) • \(offer.jobName)")
            TechnicianWorkDetailRow(title: "Customer", value: offer.customerName)

            if !offer.serviceLocationName.isEmpty {
                TechnicianWorkDetailRow(title: "Location", value: offer.serviceLocationName)
            }

            if let address = offer.address {
                TechnicianWorkDetailRow(title: "Address", value: address.streetAddress)
            }
        }
    }

    private var scopeSection: some View {
        Section("Scope") {
            TechnicianWorkDetailRow(title: "Tasks", value: "\(offer.jobTaskIds.count)")
            TechnicianWorkDetailRow(title: "Estimated Time", value: "\(offer.estimatedMinutes) min")
        }
    }

    private var paySection: some View {
        Section("Pay Snapshot") {
            TechnicianWorkDetailRow(title: "Pay Source", value: offer.paySource.title)
            TechnicianWorkDetailRow(title: "Estimated Labor", value: TechnicianWorkMoneyFormatter.money(offer.estimatedLaborCents))

            if offer.offeredAmountCents > 0 {
                TechnicianWorkDetailRow(title: "Offered Amount", value: TechnicianWorkMoneyFormatter.money(offer.offeredAmountCents))
            }

            Text("Final payroll is calculated from completed service stop work.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            if let proposedStartDate = offer.proposedStartDate {
                TechnicianWorkDetailRow(
                    title: "Proposed",
                    value: TechnicianWorkDateFormatter.shortDateTime(proposedStartDate)
                )
            } else {
                TechnicianWorkDetailRow(title: "Proposed", value: "-")
            }

            if !offer.serviceStopId.isEmpty {
                TechnicianWorkDetailRow(
                    title: "Service Stop",
                    value: offer.serviceStopInternalId.isEmpty ? offer.serviceStopId : offer.serviceStopInternalId
                )
            } else {
                Text("This offer is not linked to a scheduled service stop yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        if !offer.description.isEmpty ||
            !offer.adminNotes.isEmpty ||
            !offer.workerNotes.isEmpty {
            Section("Notes") {
                if !offer.description.isEmpty {
                    TechnicianWorkNoteBlock(title: "Description", value: offer.description)
                }

                if !offer.adminNotes.isEmpty {
                    TechnicianWorkNoteBlock(title: "Admin Notes", value: offer.adminNotes)
                }

                if !offer.workerNotes.isEmpty {
                    TechnicianWorkNoteBlock(title: "Worker Notes", value: offer.workerNotes)
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            if canAccept {
                Button {
                    acceptAction()
                } label: {
                    Label("Accept Work", systemImage: "checkmark.circle")
                }
            }

            if canReject {
                Button(role: .destructive) {
                    showRejectDialog = true
                } label: {
                    Label("Reject Work", systemImage: "xmark.circle")
                }
            }
        } header: {
            Text("Actions")
        } footer: {
            Text("Accepted work still needs to be scheduled or completed through service stops.")
        }
    }
}

// MARK: - Rows

enum TechnicianWorkOfferRowStyle {
    case directOffer
    case boardPost
    case accepted
}

struct TechnicianWorkOfferRow: View {
    var offer: WorkOffer
    var rowStyle: TechnicianWorkOfferRowStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.body.weight(.semibold))
                    .frame(width: 34, height: 34)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(offer.title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Label("\(offer.jobTaskIds.count) task(s)", systemImage: "checklist")
                Label("\(offer.estimatedMinutes) min", systemImage: "clock")

                if offer.offeredAmountCents > 0 {
                    Label(TechnicianWorkMoneyFormatter.money(offer.offeredAmountCents), systemImage: "dollarsign.circle")
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch rowStyle {
        case .directOffer:
            return "paperplane"
        case .boardPost:
            return "list.bullet.clipboard"
        case .accepted:
            return "checkmark.circle"
        }
    }

    private var subtitle: String {
        switch offer.offerType {
        case .directUser:
            return "Direct offer • \(offer.customerName)"
        case .internalBoard:
            return "Board post • \(offer.boardVisibility.title)"
        case .externalCompany:
            return offer.externalCompanyName.isEmpty ? "External company offer" : offer.externalCompanyName
        }
    }
}

struct TechnicianWorkSummaryChip: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct TechnicianWorkDetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TechnicianWorkNoteBlock: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
        }
    }
}

// MARK: - Formatters / Helpers

enum TechnicianWorkMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

enum TechnicianWorkDateFormatter {
    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension Array where Element == WorkOffer {
    func uniqueById() -> [WorkOffer] {
        var seen: Set<String> = []
        var result: [WorkOffer] = []

        for offer in self {
            if !seen.contains(offer.id) {
                result.append(offer)
                seen.insert(offer.id)
            }
        }

        return result
    }
}