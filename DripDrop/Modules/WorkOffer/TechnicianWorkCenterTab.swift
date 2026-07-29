//
//  TechnicianWorkCenterTab.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


//
//  TechnicianWorkCenterView.swift
//  DripDrop
//

import SwiftUI

enum TechnicianWorkCenterTab: String, CaseIterable, Identifiable {
    case directOffers = "Offers"
    case workBoard = "Board"
    case accepted = "Accepted"
    case scheduled = "Scheduled"

    var id: String { rawValue }
}

@MainActor
final class TechnicianWorkCenterViewModel: ObservableObject {

    @Published var scheduledServiceStops: [ServiceStop] = []
    @Published var acceptedUserOffers: [WorkOffer] = []
    @Published var directOffers: [WorkOffer] = []
    @Published var boardOffers: [WorkOffer] = []

    @Published var selectedTab: TechnicianWorkCenterTab = .directOffers

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let companyUser: CompanyUser
    let dataService: any ProductionDataServiceProtocol

    private var hasLoaded = false

    init(
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        self.companyUser = companyUser
        self.dataService = dataService
    }
    
    var scheduledServiceStopCount: Int {
        scheduledServiceStops.count
    }
    
    var acceptedOffersReadyForSelfScheduling: [WorkOffer] {
        acceptedOffers
            .filter {
                $0.status == .accepted &&
                $0.serviceStopId.isEmpty &&
                $0.allowsTechnicianSelfScheduling == true
            }
            .sorted { ($0.acceptedAt ?? $0.createdAt) > ($1.acceptedAt ?? $1.createdAt) }
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
        let allOffers = directOffers + boardOffers + acceptedUserOffers

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

    func load(companyId:String, forceRefresh: Bool = false) async {
        guard forceRefresh || !hasLoaded else { return }

        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let now = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            let endDate = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now

            async let directTask = dataService.fetchWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )

            async let boardTask = dataService.fetchOpenBoardWorkOffers(
                companyId: companyId,
                workerType: companyUser.workerType
            )

            async let stopsTask = dataService.fetchServiceStopsForTechnician(
                companyId: companyId,
                technicianId: companyUser.userId,
                startDate: startDate,
                endDate: endDate
            )
            async let acceptedTask = dataService.fetchAcceptedWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )

            directOffers = try await directTask
            boardOffers = try await boardTask
            acceptedUserOffers = try await acceptedTask

            scheduledServiceStops = try await stopsTask
        } catch {
            alertMessage = "Could not load work offers. \(error.localizedDescription)"
            showAlert = true
        }
        
    }

    func acceptOffer(companyId:String, _ offer: WorkOffer) async {
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

            await load(companyId:companyId,forceRefresh: true)
        } catch {
            alertMessage = "Could not accept work. \(error.localizedDescription)"
            showAlert = true
        }
    }

    func rejectOffer(
        companyId:String,
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

            await load(companyId: companyId, forceRefresh: true)
        } catch {
            alertMessage = "Could not reject work. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct TechnicianWorkCenterView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var viewModel: TechnicianWorkCenterViewModel

    init(
        companyUser: CompanyUser,
        dataService: any ProductionDataServiceProtocol
    ) {
        _viewModel = StateObject(
            wrappedValue: TechnicianWorkCenterViewModel(
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
            if let currentCompany = masterDataManager.currentCompany {
                await viewModel.load(companyId: currentCompany.id)
            }
        }
        .refreshable {
            if let currentCompany = masterDataManager.currentCompany {
                    await viewModel.load(companyId:currentCompany.id, forceRefresh: true)
            }
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
            LazyVGrid(columns: workTabColumns, spacing: 10) {
                ForEach(TechnicianWorkCenterTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            viewModel.selectedTab = tab
                        }
                    } label: {
                        workTabBox(for: tab)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text("View")
        }
    }

    private var workTabColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private func workTabBox(for tab: TechnicianWorkCenterTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        let tint = tabTint(for: tab)

        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: tabIcon(for: tab))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(isSelected ? .white : tint)
                    .frame(width: 28, height: 28)
                    .background(
                        isSelected ? Color.white.opacity(0.16) : tint.opacity(0.13),
                        in: Circle()
                    )

                Spacer()

                Text("\(tabCount(for: tab))")
                    .font(.title3.weight(.bold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .monospacedDigit()
            }

            Text(tabName(for: tab))
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(12)
        .background(
            isSelected ? tint : Color.primary.opacity(0.045),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.clear : tint.opacity(0.16), lineWidth: 1)
        )
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

        case .scheduled:
            scheduledWorkSection
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
                if let currentCompany = masterDataManager.currentCompany {
                    ForEach(viewModel.openDirectOffers) { offer in
                        NavigationLink {
                            TechnicianWorkOfferDetailView(
                                offer: offer,
                                companyUser: viewModel.companyUser,
                                canReject: true,
                                canAccept: true,
                                acceptAction: {
                                    Task {
                                        await viewModel.acceptOffer(companyId:currentCompany.id,offer)
                                    }
                                },
                                rejectAction: { reason in
                                    Task {
                                        await viewModel.rejectOffer(
                                            companyId:currentCompany.id,
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
                if let currentCompany = masterDataManager.currentCompany {

                    ForEach(viewModel.openBoardOffers) { offer in
                        NavigationLink {
                            TechnicianWorkOfferDetailView(
                                offer: offer,
                                companyUser: viewModel.companyUser,
                                canReject: false,
                                canAccept: true,
                                acceptAction: {
                                    Task {
                                        await viewModel.acceptOffer(companyId:currentCompany.id,offer)
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
                if !viewModel.acceptedOffersReadyForSelfScheduling.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready To Schedule")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        if let currentCompany = masterDataManager.currentCompany {
                            ForEach(viewModel.acceptedOffersReadyForSelfScheduling) { offer in
                                NavigationLink {
                                    TechnicianSelfScheduleWorkOfferView(
                                        companyId: currentCompany.id,
                                        companyUser: viewModel.companyUser,
                                        offer: offer,
                                        dataService: viewModel.dataService,
                                        onScheduled: {
                                            Task {
                                                await viewModel.load(
                                                    companyId: currentCompany.id,
                                                    forceRefresh: true
                                                )
                                            }
                                        }
                                    )
                                } label: {
                                    TechnicianWorkOfferRow(
                                        offer: offer,
                                        rowStyle: .accepted
                                    )
                                }
                            }
                        }
                    }
                }

                let otherAccepted = viewModel.acceptedOffers.filter { offer in
                    !viewModel.acceptedOffersReadyForSelfScheduling.contains(where: { $0.id == offer.id })
                }

                if !otherAccepted.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accepted / Scheduled")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(otherAccepted) { offer in
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
                }
            }
        } header: {
            Text("Accepted Work")
        } footer: {
            Text("Some accepted offers may allow you to schedule the service stop yourself.")
        }
    }
    
    private func tabName(for tab: TechnicianWorkCenterTab) -> String {
        switch tab {
        case .directOffers:
            return "Offers"
        case .workBoard:
            return "Board"
        case .accepted:
            return "Accepted"
        case .scheduled:
            return "Scheduled"
        }
    }

    private func tabCount(for tab: TechnicianWorkCenterTab) -> Int {
        switch tab {
        case .directOffers:
            return viewModel.directOfferCount
        case .workBoard:
            return viewModel.boardOfferCount
        case .accepted:
            return viewModel.acceptedOfferCount
        case .scheduled:
            return viewModel.scheduledServiceStopCount
        }
    }

    private func tabIcon(for tab: TechnicianWorkCenterTab) -> String {
        switch tab {
        case .directOffers:
            return "paperplane"
        case .workBoard:
            return "list.bullet.clipboard"
        case .accepted:
            return "checkmark.circle"
        case .scheduled:
            return "calendar"
        }
    }

    private func tabTint(for tab: TechnicianWorkCenterTab) -> Color {
        switch tab {
        case .directOffers:
            return .poolBlue
        case .workBoard:
            return .poolGreen
        case .accepted:
            return .orange
        case .scheduled:
            return .purple
        }
    }

    private var scheduledWorkSection: some View {
        Section {
            if viewModel.scheduledServiceStops.isEmpty {
                ContentUnavailableView(
                    "No Scheduled Work",
                    systemImage: "calendar",
                    description: Text("Service stops assigned to you will appear here.")
                )
            } else {
                ForEach(viewModel.scheduledServiceStops.sorted(by: { $0.serviceDate < $1.serviceDate })) { stop in
                    NavigationLink(
                        value: Route.serviceStop(
                            serviceStop: stop,
                            dataService: viewModel.dataService
                        )
                    ) {
                        TechnicianScheduledServiceStopRow(serviceStop: stop)
                    }
                }
            }
        } header: {
            Text("Scheduled Service Stops")
        } footer: {
            Text("Payroll is generated after completed work is finished and processed.")
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
            } else if offer.status == .accepted {
                if offer.allowsTechnicianSelfScheduling == true {
                    Text("Accepted. You can schedule this work from the Accepted tab.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                } else {
                    Text("Accepted. Waiting for admin to schedule the service stop.")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
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
struct TechnicianScheduledServiceStopRow: View {
    var serviceStop: ServiceStop

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(serviceStop.internalId)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(serviceStop.operationStatus.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(serviceStop.type.isEmpty ? "Service Stop" : serviceStop.type)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label(TechnicianWorkDateFormatter.shortDateTime(serviceStop.serviceDate), systemImage: "calendar")
                Spacer()
                Label("\(serviceStop.duration) min", systemImage: "clock")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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

// MARK: - Company Offered Work

private enum CompanyOfferedWorkStatusFilter: String, CaseIterable, Identifiable {
    case open = "Open"
    case ready = "Ready"
    case accepted = "Accepted"
    case scheduled = "Scheduled"
    case final = "Final"
    case all = "All"

    var id: String { rawValue }

    func includes(_ offer: WorkOffer) -> Bool {
        switch self {
        case .open:
            return offer.status.isOpen
        case .ready:
            return offer.status == .accepted && offer.serviceStopId.isEmpty
        case .accepted:
            return offer.status == .accepted
        case .scheduled:
            return offer.status == .scheduled ||
            offer.status == .inProgress ||
            offer.status == .completed ||
            !offer.serviceStopId.isEmpty
        case .final:
            return offer.status.isFinal
        case .all:
            return true
        }
    }
}

private enum CompanyOfferedWorkTypeFilter: String, CaseIterable, Identifiable {
    case all = "All Types"
    case direct = "Direct"
    case board = "Board"
    case external = "External"

    var id: String { rawValue }

    func includes(_ offer: WorkOffer) -> Bool {
        switch self {
        case .all:
            return true
        case .direct:
            return offer.offerType == .directUser
        case .board:
            return offer.offerType == .internalBoard
        case .external:
            return offer.offerType == .externalCompany
        }
    }
}

private enum CompanyOfferedWorkSchedulingFilter: String, CaseIterable, Identifiable {
    case all = "All Scheduling"
    case selfSchedule = "Tech Can Schedule"
    case adminSchedule = "Admin Schedules"
    case scheduled = "Scheduled"
    case unscheduled = "Unscheduled"

    var id: String { rawValue }

    func includes(_ offer: WorkOffer) -> Bool {
        switch self {
        case .all:
            return true
        case .selfSchedule:
            return offer.allowsTechnicianSelfScheduling == true
        case .adminSchedule:
            return offer.allowsTechnicianSelfScheduling != true && offer.serviceStopId.isEmpty
        case .scheduled:
            return offer.status == .scheduled ||
            offer.status == .inProgress ||
            offer.status == .completed ||
            !offer.serviceStopId.isEmpty
        case .unscheduled:
            return offer.serviceStopId.isEmpty
        }
    }
}

fileprivate struct CompanyOfferedWorkSummary {
    var total: Int
    var open: Int
    var ready: Int
    var accepted: Int
    var scheduled: Int
    var estimatedPayCents: Int
}

@MainActor
final class CompanyOfferedWorkViewModel: ObservableObject {
    @Published private(set) var offers: [WorkOffer] = []
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let dataService: any ProductionDataServiceProtocol

    init(dataService: any ProductionDataServiceProtocol) {
        self.dataService = dataService
    }

    fileprivate var summary: CompanyOfferedWorkSummary {
        CompanyOfferedWorkSummary(
            total: offers.count,
            open: offers.filter { $0.status.isOpen }.count,
            ready: offers.acceptedReadyToScheduleCount,
            accepted: offers.filter { $0.status == .accepted }.count,
            scheduled: offers.scheduledOfferCount,
            estimatedPayCents: offers.reduce(0) { $0 + $1.companyEstimatedPayCents }
        )
    }

    func load(companyId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            offers = try await dataService.fetchAllWorkOffers(companyId: companyId)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            offers = []
            alertMessage = "Could not load offered work. \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct CompanyOfferedWorkView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    @StateObject private var viewModel: CompanyOfferedWorkViewModel

    @State private var statusFilter: CompanyOfferedWorkStatusFilter = .open
    @State private var typeFilter: CompanyOfferedWorkTypeFilter = .all
    @State private var schedulingFilter: CompanyOfferedWorkSchedulingFilter = .all
    @State private var workerFilter: String = "All"
    @State private var searchText: String = ""

    init(dataService: any ProductionDataServiceProtocol) {
        _viewModel = StateObject(wrappedValue: CompanyOfferedWorkViewModel(dataService: dataService))
    }

    private var workerOptions: [String] {
        let workers = viewModel.offers
            .map(\.companyOfferTargetName)
            .filter { !$0.isEmpty }
            .uniqueSorted()

        return ["All"] + workers
    }

    private var filteredOffers: [WorkOffer] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return viewModel.offers
            .filter { statusFilter.includes($0) }
            .filter { typeFilter.includes($0) }
            .filter { schedulingFilter.includes($0) }
            .filter {
                workerFilter == "All" ||
                $0.companyOfferTargetName == workerFilter
            }
            .filter {
                term.isEmpty ||
                $0.companyOfferSearchText.localizedCaseInsensitiveContains(term)
            }
            .sorted {
                if statusFilter != .ready {
                    let leftReady = $0.status == .accepted && $0.serviceStopId.isEmpty
                    let rightReady = $1.status == .accepted && $1.serviceStopId.isEmpty
                    if leftReady != rightReady { return leftReady }
                }

                return $0.createdAt > $1.createdAt
            }
    }

    var body: some View {
        List {
            summarySection
            filtersSection
            offersSection
        }
        .navigationTitle("Offered Work")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search offered work")
        .task(id: masterDataManager.currentCompany?.id) {
            if let company = masterDataManager.currentCompany {
                await viewModel.load(companyId: company.id)
            }
        }
        .refreshable {
            if let company = masterDataManager.currentCompany {
                await viewModel.load(companyId: company.id)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading offered work...")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .alert("Offered Work", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private var summarySection: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                TechnicianWorkSummaryChip(title: "Open", value: "\(viewModel.summary.open)", systemImage: "paperplane")
                TechnicianWorkSummaryChip(title: "Ready", value: "\(viewModel.summary.ready)", systemImage: "calendar.badge.plus")
                TechnicianWorkSummaryChip(title: "Accepted", value: "\(viewModel.summary.accepted)", systemImage: "checkmark.circle")
                TechnicianWorkSummaryChip(title: "Est. Pay", value: TechnicianWorkMoneyFormatter.money(viewModel.summary.estimatedPayCents), systemImage: "dollarsign.circle")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Summary")
        } footer: {
            Text("\(viewModel.summary.total) total offered work item\(viewModel.summary.total == 1 ? "" : "s").")
        }
    }

    private var filtersSection: some View {
        Section("Filters") {
            Picker("Status", selection: $statusFilter) {
                ForEach(CompanyOfferedWorkStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }

            Picker("Type", selection: $typeFilter) {
                ForEach(CompanyOfferedWorkTypeFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }

            Picker("Scheduling", selection: $schedulingFilter) {
                ForEach(CompanyOfferedWorkSchedulingFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }

            Picker("Worker", selection: $workerFilter) {
                ForEach(workerOptions, id: \.self) { worker in
                    Text(worker).tag(worker)
                }
            }
        }
    }

    private var offersSection: some View {
        Section {
            if filteredOffers.isEmpty {
                ContentUnavailableView(
                    "No Offered Work",
                    systemImage: "tray",
                    description: Text("No offers match the current view.")
                )
            } else if let company = masterDataManager.currentCompany {
                ForEach(filteredOffers) { offer in
                    NavigationLink {
                        CompanyOfferedWorkDetailLoader(
                            companyId: company.id,
                            currentUserId: currentUserId,
                            currentUserName: currentUserName,
                            offer: offer,
                            dataService: viewModel.dataService,
                            onChanged: {
                                Task {
                                    await viewModel.load(companyId: company.id)
                                }
                            }
                        )
                    } label: {
                        CompanyOfferedWorkRow(offer: offer)
                    }
                }
            }
        } header: {
            Text("\(filteredOffers.count) Offer\(filteredOffers.count == 1 ? "" : "s")")
        }
    }

    private var currentUserId: String {
        masterDataManager.companyUser?.userId ??
        masterDataManager.user?.id ??
        ""
    }

    private var currentUserName: String {
        if let companyUserName = masterDataManager.companyUser?.userName,
           !companyUserName.isEmpty {
            return companyUserName
        }

        return [
            masterDataManager.user?.firstName,
            masterDataManager.user?.lastName
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

private struct CompanyOfferedWorkDetailLoader: View {
    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let offer: WorkOffer
    let dataService: any ProductionDataServiceProtocol
    let onChanged: () -> Void

    @State private var jobTasks: [JobTask] = []
    @State private var isLoading: Bool = false
    @State private var taskLoadError: String?

    var body: some View {
        WorkOfferDetailView(
            companyId: companyId,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
            offer: offer,
            jobTasks: jobTasks,
            dataService: dataService,
            onChanged: onChanged
        )
        .task {
            await loadTasks()
        }
        .overlay(alignment: .bottom) {
            if isLoading {
                ProgressView("Loading tasks...")
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 12)
            } else if let taskLoadError {
                Text("Tasks unavailable: \(taskLoadError)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 12)
            }
        }
    }

    private func loadTasks() async {
        guard !offer.jobId.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            jobTasks = try await dataService.getJobTasks(companyId: companyId, jobId: offer.jobId)
            taskLoadError = nil
        } catch {
            jobTasks = []
            taskLoadError = error.localizedDescription
        }
    }
}

private struct CompanyOfferedWorkRow: View {
    let offer: WorkOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: offer.offerType.systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 34, height: 34)
                    .background(iconColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(offer.title.isEmpty ? "Offered Work" : offer.title)
                        .font(.subheadline.weight(.semibold))

                    Text("\(offer.jobInternalId) • \(offer.customerName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            HStack(spacing: 10) {
                Label(offer.companyOfferTargetName, systemImage: "person")
                Label("\(offer.jobTaskIds.count) task(s)", systemImage: "checklist")
                Label(TechnicianWorkMoneyFormatter.money(offer.companyEstimatedPayCents), systemImage: "dollarsign.circle")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var iconColor: Color {
        switch offer.offerType {
        case .directUser:
            return .poolBlue
        case .internalBoard:
            return .poolGreen
        case .externalCompany:
            return .orange
        }
    }
}

private extension WorkOffer {
    var companyEstimatedPayCents: Int {
        if let estimatedPayTotalCents {
            return estimatedPayTotalCents
        }

        if offeredAmountCents > 0 {
            return offeredAmountCents
        }

        return estimatedLaborCents
    }

    var companyOfferTargetName: String {
        if !offeredToUserName.isEmpty {
            return offeredToUserName
        }

        if !acceptedByUserName.isEmpty {
            return acceptedByUserName
        }

        if offerType == .internalBoard {
            return "Internal Board"
        }

        if !externalCompanyName.isEmpty {
            return externalCompanyName
        }

        return "Unassigned"
    }

    var companyOfferSearchText: String {
        [
            id,
            title,
            description,
            adminNotes,
            workerNotes,
            jobInternalId,
            jobName,
            customerName,
            serviceLocationName,
            serviceStopTypeName ?? "",
            status.title,
            offerType.title,
            companyOfferTargetName
        ]
            .joined(separator: " ")
            .lowercased()
    }
}

private extension Array where Element == String {
    func uniqueSorted() -> [String] {
        Array(Set(self)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
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
