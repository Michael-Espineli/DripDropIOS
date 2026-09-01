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
    case discover = "Pending"
    case available = "Boards"
    case current = "Current"
    case rejected = "Rejected"

    var id: String { rawValue }
}

@MainActor
final class TechnicianWorkCenterViewModel: ObservableObject {

    @Published var acceptedUserOffers: [WorkOffer] = []
    @Published var directOffers: [WorkOffer] = []
    @Published var boardOffers: [WorkOffer] = []

    @Published var selectedTab: TechnicianWorkCenterTab = .discover

    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false

    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published private var skippedBoardOfferIds: Set<String> = []

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
    
    var discoveryOffers: [WorkOffer] {
        (openDirectOffers + openBoardOffers)
            .filter { !skippedBoardOfferIds.contains($0.id) }
            .uniqueById()
            .sorted { ($0.proposedStartDate ?? $0.createdAt) < ($1.proposedStartDate ?? $1.createdAt) }
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
            .filter(\.isWorkOfferRecord)
            .filter {
                $0.status == .sent ||
                $0.status == .viewed ||
                $0.status == .posted
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var acceptedOffers: [WorkOffer] {
        let allOffers = (directOffers + boardOffers + acceptedUserOffers)
            .filter(\.isWorkOfferRecord)

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
            .filter(\.isWorkOfferRecord)
            .filter {
                $0.status == .posted ||
                $0.status == .viewed
            }
            .filter { !skippedBoardOfferIds.contains($0.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var rejectedOffers: [WorkOffer] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        return (directOffers + acceptedUserOffers)
            .filter(\.isWorkOfferRecord)
            .filter { $0.status == .rejected }
            .filter { ($0.rejectedAt ?? $0.createdAt) >= cutoffDate }
            .filter {
                $0.acceptedByUserId == companyUser.userId ||
                $0.offeredToUserId == companyUser.userId
            }
            .uniqueById()
            .sorted { ($0.rejectedAt ?? $0.createdAt) > ($1.rejectedAt ?? $1.createdAt) }
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

    var rejectedOfferCount: Int {
        rejectedOffers.count
    }

    func load(companyId:String, forceRefresh: Bool = false) async {
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
            async let acceptedTask = dataService.fetchAcceptedWorkOffersForUser(
                companyId: companyId,
                userId: companyUser.userId
            )

            directOffers = (try await directTask)
                .filter(\.isWorkOfferRecord)
            let fetchedBoardOffers = try await boardTask
            boardOffers = fetchedBoardOffers
                .filter(\.isWorkOfferRecord)
                .filter { !skippedBoardOfferIds.contains($0.id) }
            acceptedUserOffers = (try await acceptedTask)
                .filter(\.isWorkOfferRecord)
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

    func skipBoardOffer(_ offer: WorkOffer) {
        skippedBoardOfferIds.insert(offer.id)
    }
}

struct TechnicianWorkCenterView: View {
    @EnvironmentObject var masterDataManager: MasterDataManager
    @StateObject private var viewModel: TechnicianWorkCenterViewModel
    @State private var showSwipeReview: Bool = false

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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                headerPanel
                selectedContent
                Color.clear.frame(height: 90)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle("Work Offered")
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
        .fullScreenCover(isPresented: $showSwipeReview) {
            if let currentCompany = masterDataManager.currentCompany {
                NavigationStack {
                    TechnicianOfferSwipeReviewView(
                        offers: viewModel.discoveryOffers,
                        companyUser: viewModel.companyUser,
                        isSaving: viewModel.isSaving,
                        acceptAction: { offer in
                            Task {
                                await viewModel.acceptOffer(companyId: currentCompany.id, offer)
                            }
                        },
                        rejectAction: { offer, reason in
                            Task {
                                await viewModel.rejectOffer(
                                    companyId: currentCompany.id,
                                    offer,
                                    reason: reason
                                )
                            }
                        },
                        skipAction: { offer in
                            viewModel.skipBoardOffer(offer)
                        }
                    )
                }
            } else {
                ContentUnavailableView(
                    "Company Unavailable",
                    systemImage: "building.2",
                    description: Text("Select a company before reviewing jobs.")
                )
            }
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Work Offered")
                        .font(.title2.weight(.bold))

                    Text("\(viewModel.companyUser.userName) · Pool jobs ready to pick up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    Task {
                        if let currentCompany = masterDataManager.currentCompany {
                            await viewModel.load(companyId: currentCompany.id, forceRefresh: true)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                        .frame(width: 36, height: 36)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }

            HStack(spacing: 10) {
                ForEach(TechnicianWorkCenterTab.allCases) { tab in
                    workSummaryTabButton(for: tab)
                }
            }

            HStack(spacing: 8) {
                Label("\(viewModel.directOfferCount) direct", systemImage: "paperplane")
                Label("\(viewModel.boardOfferCount) board", systemImage: "list.bullet.clipboard")
                Spacer(minLength: 0)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func workSummaryTabButton(for tab: TechnicianWorkCenterTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        let tint = tabTint(for: tab)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tabIcon(for: tab))
                    .font(.caption.weight(.bold))
                    .foregroundColor(isSelected ? .white : tint)
                    .frame(width: 28, height: 28)
                    .background(
                        isSelected ? Color.white.opacity(0.16) : tint.opacity(0.12),
                        in: Circle()
                    )

                Text("\(tabCount(for: tab))")
                    .font(.headline.weight(.bold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .monospacedDigit()

                Text(tab.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(isSelected ? .white.opacity(0.88) : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: 86)
            .background(
                isSelected ? tint : tint.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.clear : tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.rawValue), \(tabCount(for: tab))")
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch viewModel.selectedTab {
        case .discover:
            discoverSection
        case .available:
            availableWorkSection
        case .current:
            currentWorkSection
        case .rejected:
            rejectedWorkSection
        }
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TechnicianWorkPanel(
                title: "Pending Jobs",
                systemImage: "bolt.fill"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        showSwipeReview = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.poolBlue, in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Review Pending Jobs")
                                    .font(.headline.weight(.semibold))

                                Text("Swipe right to accept, left to pass, and scroll each card for the deadline and timeline.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Text("\(viewModel.discoveryOffers.count)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.poolGreen, in: Circle())
                        }
                        .padding(14)
                        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.discoveryOffers.isEmpty || masterDataManager.currentCompany == nil)
                    .opacity(viewModel.discoveryOffers.isEmpty ? 0.6 : 1)

                    if viewModel.discoveryOffers.isEmpty {
                        ContentUnavailableView(
                            "No Pending Jobs",
                            systemImage: "tray",
                            description: Text("Direct offers and eligible board jobs will show up here.")
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.discoveryOffers.prefix(4)) { offer in
                                TechnicianWorkOfferRow(
                                    offer: offer,
                                    rowStyle: offer.offerType == .internalBoard ? .boardPost : .directOffer
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private var availableWorkSection: some View {
        TechnicianWorkPanel(
            title: "Job Board",
            systemImage: "list.bullet.clipboard"
        ) {
            if viewModel.openBoardOffers.isEmpty {
                ContentUnavailableView(
                    "No Board Jobs",
                    systemImage: "tray",
                    description: Text("Available board work will appear here for eligible technicians to pick up.")
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Browse open board posts and pick up the work that fits your route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.openBoardOffers) { offer in
                        NavigationLink {
                            offerDetailDestination(
                                offer,
                                canReject: false,
                                canAccept: true
                            )
                        } label: {
                            TechnicianWorkOfferRow(
                                offer: offer,
                                rowStyle: .boardPost
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var currentWorkSection: some View {
        TechnicianWorkPanel(
            title: "Current Work",
            systemImage: "briefcase"
        ) {
            if viewModel.acceptedOffers.isEmpty {
                ContentUnavailableView(
                    "No Current Work",
                    systemImage: "briefcase",
                    description: Text("Accepted and scheduled work offers will appear here.")
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if !viewModel.acceptedOffersReadyForSelfScheduling.isEmpty {
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
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    let otherAccepted = viewModel.acceptedOffers.filter { offer in
                        !viewModel.acceptedOffersReadyForSelfScheduling.contains(where: { $0.id == offer.id })
                    }

                    if !otherAccepted.isEmpty {
                        Text("Accepted Offers")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(otherAccepted) { offer in
                            NavigationLink {
                                offerDetailDestination(
                                    offer,
                                    canReject: false,
                                    canAccept: false
                                )
                            } label: {
                                TechnicianWorkOfferRow(
                                    offer: offer,
                                    rowStyle: .accepted
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var rejectedWorkSection: some View {
        TechnicianWorkPanel(
            title: "Recently Rejected",
            systemImage: "xmark.circle"
        ) {
            if viewModel.rejectedOffers.isEmpty {
                ContentUnavailableView(
                    "No Rejected Jobs",
                    systemImage: "xmark.circle",
                    description: Text("Rejected offers from the last 30 days will appear here.")
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.rejectedOffers) { offer in
                        NavigationLink {
                            offerDetailDestination(
                                offer,
                                canReject: false,
                                canAccept: false
                            )
                        } label: {
                            TechnicianWorkOfferRow(
                                offer: offer,
                                rowStyle: .rejected
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func offerDetailDestination(
        _ offer: WorkOffer,
        canReject: Bool,
        canAccept: Bool
    ) -> some View {
        if let currentCompany = masterDataManager.currentCompany {
            TechnicianWorkOfferDetailView(
                offer: offer,
                companyUser: viewModel.companyUser,
                canReject: canReject,
                canAccept: canAccept,
                acceptAction: {
                    Task {
                        await viewModel.acceptOffer(companyId: currentCompany.id, offer)
                    }
                },
                rejectAction: { reason in
                    Task {
                        await viewModel.rejectOffer(
                            companyId: currentCompany.id,
                            offer,
                            reason: reason
                        )
                    }
                }
            )
        } else {
            ContentUnavailableView(
                "Company Unavailable",
                systemImage: "building.2",
                description: Text("Select a company before opening this work offer.")
            )
        }
    }

    private func tabCount(for tab: TechnicianWorkCenterTab) -> Int {
        switch tab {
        case .discover:
            return viewModel.discoveryOffers.count
        case .available:
            return viewModel.boardOfferCount
        case .current:
            return viewModel.acceptedOfferCount
        case .rejected:
            return viewModel.rejectedOfferCount
        }
    }

    private func tabIcon(for tab: TechnicianWorkCenterTab) -> String {
        switch tab {
        case .discover:
            return "bolt.fill"
        case .available:
            return "list.bullet.clipboard"
        case .current:
            return "briefcase"
        case .rejected:
            return "xmark.circle"
        }
    }

    private func tabTint(for tab: TechnicianWorkCenterTab) -> Color {
        switch tab {
        case .discover:
            return .poolBlue
        case .available:
            return .poolGreen
        case .current:
            return .orange
        case .rejected:
            return .red
        }
    }
}

private struct TechnicianWorkPanel<Content: View>: View {
    let title: String
    let systemImage: String
    private let content: () -> Content

    init(
        title: String,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))

            content()
        }
        .technicianPanel()
    }
}

private extension Color {
    static var workOfferCardSurface: Color {
        Color(.secondarySystemGroupedBackground)
    }

    static var workOfferCardBase: Color {
        Color(.systemBackground)
    }

    static var workOfferInsetSurface: Color {
        Color(.tertiarySystemGroupedBackground)
    }
}

private extension View {
    func technicianPanel() -> some View {
        self
            .padding(16)
            .background(Color.workOfferCardSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    @ViewBuilder
    func swipeCardGesture<SwipeGesture: Gesture>(
        _ isActive: Bool,
        gesture: SwipeGesture
    ) -> some View {
        if isActive {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

private struct TechnicianOfferSwipeReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let offers: [WorkOffer]
    let companyUser: CompanyUser
    let isSaving: Bool
    let acceptAction: (WorkOffer) -> Void
    let rejectAction: (WorkOffer, String) -> Void
    let skipAction: (WorkOffer) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pending Jobs")
                        .font(.title2.weight(.bold))

                    Text("Swipe right to accept, left to pass. Scroll up inside a card for service details, deadline, and timeline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 2)

                TechnicianOfferSwipeDeck(
                    offers: offers,
                    companyUser: companyUser,
                    isSaving: isSaving,
                    acceptAction: acceptAction,
                    rejectAction: rejectAction,
                    skipAction: skipAction
                )
            }
            .padding(16)
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle("Review Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct TechnicianOfferSwipeDeck: View {
    let offers: [WorkOffer]
    let companyUser: CompanyUser
    let isSaving: Bool
    let acceptAction: (WorkOffer) -> Void
    let rejectAction: (WorkOffer, String) -> Void
    let skipAction: (WorkOffer) -> Void

    @State private var activeIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var pendingRejectOffer: WorkOffer?
    @State private var rejectionReason: String = ""

    private var visibleOffers: [WorkOffer] {
        Array(offers.dropFirst(activeIndex).prefix(3))
    }

    private var activeOffer: WorkOffer? {
        guard activeIndex < offers.count else { return nil }
        return offers[activeIndex]
    }

    var body: some View {
        VStack(spacing: 14) {
            deckBody

            if let activeOffer {
                HStack(spacing: 16) {
                    Button(role: activeOffer.offerType == .directUser ? .destructive : nil) {
                        handleLeftAction(activeOffer)
                    } label: {
                        Label(activeOffer.offerType == .directUser ? "Reject" : "Skip", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isSaving)

                    Button {
                        acceptAndAdvance(activeOffer)
                    } label: {
                        Label("Accept", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)
                }
            }
        }
        .onChange(of: offers.map(\.id)) { _, _ in
            if activeIndex >= offers.count {
                activeIndex = max(offers.count - 1, 0)
            }
        }
        .alert("Reject Work", isPresented: rejectDialogBinding) {
            TextField("Reason", text: $rejectionReason)

            Button("Reject", role: .destructive) {
                if let pendingRejectOffer {
                    rejectAction(pendingRejectOffer, rejectionReason)
                    advance()
                }
                pendingRejectOffer = nil
                rejectionReason = ""
            }

            Button("Cancel", role: .cancel) {
                pendingRejectOffer = nil
                rejectionReason = ""
            }
        } message: {
            Text("Add an optional reason for rejecting this offer.")
        }
    }

    @ViewBuilder
    private var deckBody: some View {
        if offers.isEmpty {
            ContentUnavailableView(
                "No Jobs To Review",
                systemImage: "tray",
                description: Text("New direct offers and eligible board jobs will appear here.")
            )
            .frame(maxWidth: .infinity, minHeight: 420)
            .technicianPanel()
        } else {
            ZStack {
                ForEach(Array(visibleOffers.enumerated()), id: \.element.id) { index, offer in
                    TechnicianOfferSwipeCard(
                        offer: offer,
                        companyUser: companyUser,
                        acceptAction: {
                            acceptAndAdvance(offer)
                        },
                        rejectAction: {
                            handleLeftAction(offer)
                        }
                    )
                    .offset(x: index == 0 ? dragOffset.width : CGFloat(index) * 8)
                    .offset(y: CGFloat(index) * 12)
                    .scaleEffect(index == 0 ? 1 : 1 - CGFloat(index) * 0.035)
                    .rotationEffect(.degrees(index == 0 ? Double(dragOffset.width / 20) : 0))
                    .zIndex(Double(visibleOffers.count - index))
                    .swipeCardGesture(index == 0, gesture: dragGesture(for: offer))
                    .allowsHitTesting(index == 0)
                }
            }
            .frame(height: 560)
        }
    }

    private var rejectDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingRejectOffer != nil },
            set: { isPresented in
                if !isPresented {
                    pendingRejectOffer = nil
                    rejectionReason = ""
                }
            }
        )
    }

    private func dragGesture(for offer: WorkOffer) -> some Gesture {
        DragGesture(minimumDistance: 18)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                dragOffset = value.translation
            }
            .onEnded { value in
                let width = value.translation.width

                if width > 110 {
                    acceptAndAdvance(offer)
                } else if width < -110 {
                    handleLeftAction(offer)
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func handleLeftAction(_ offer: WorkOffer) {
        if offer.offerType == .directUser {
            pendingRejectOffer = offer
        } else {
            skipAction(offer)
            advance()
        }
    }

    private func acceptAndAdvance(_ offer: WorkOffer) {
        acceptAction(offer)
        advance()
    }

    private func advance() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            dragOffset = .zero
            activeIndex = min(activeIndex + 1, offers.count)
        }
    }
}

private struct TechnicianOfferSwipeCard: View {
    let offer: WorkOffer
    let companyUser: CompanyUser
    let acceptAction: () -> Void
    let rejectAction: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                topMatter
                quickFacts
                detailBlock
                notesBlock
                actionRail
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    cardTint.opacity(0.18),
                    Color.workOfferCardSurface,
                    Color.workOfferCardBase
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(cardTint.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 12)
    }

    private var topMatter: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Label(offer.offerType == .internalBoard ? "Board" : "Direct", systemImage: offer.offerType.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cardTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(cardTint.opacity(0.12), in: Capsule())

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.thinMaterial, in: Capsule())
            }

            Text(offer.title.isEmpty ? "Offered Work" : offer.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(offer.customerName.isEmpty ? offer.jobName : offer.customerName)
                    .font(.headline.weight(.semibold))

                Text(locationLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private var quickFacts: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            TechnicianOfferFactPill(
                title: "Pay",
                value: TechnicianWorkMoneyFormatter.money(offer.technicianDisplayPayCents),
                systemImage: "dollarsign.circle"
            )
            TechnicianOfferFactPill(
                title: "ETA",
                value: "\(offer.estimatedMinutes) min",
                systemImage: "clock"
            )
            TechnicianOfferFactPill(
                title: "Tasks",
                value: "\(offer.jobTaskIds.count)",
                systemImage: "checklist"
            )
            TechnicianOfferFactPill(
                title: "Due By",
                value: deadlineLine,
                systemImage: "flag.checkered"
            )
        }
    }

    private var detailBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            TechnicianSwipeDetailRow(title: "Job", value: jobLine)
            TechnicianSwipeDetailRow(title: "Worker", value: companyUser.userName)
            TechnicianSwipeDetailRow(title: "Pay Source", value: offer.paySource.title)
            TechnicianSwipeDetailRow(title: "Timeline", value: timelineLine)

            if offer.allowsTechnicianSelfScheduling == true {
                TechnicianSwipeDetailRow(title: "Scheduling", value: "Technician self-schedule")
            } else {
                TechnicianSwipeDetailRow(title: "Scheduling", value: "Admin schedules")
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var notesBlock: some View {
        let noteText = [
            offer.description,
            offer.adminNotes
        ]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")

        if !noteText.isEmpty {
            VStack(alignment: .leading, spacing: 7) {
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(noteText)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
    }

    private var actionRail: some View {
        HStack(spacing: 12) {
            Button(role: offer.offerType == .directUser ? .destructive : nil) {
                rejectAction()
            } label: {
                Image(systemName: offer.offerType == .directUser ? "xmark" : "forward")
                    .font(.headline.weight(.bold))
                    .frame(width: 54, height: 54)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                acceptAction()
            } label: {
                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(Color.poolGreen, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var cardTint: Color {
        offer.offerType == .internalBoard ? .poolGreen : .poolBlue
    }

    private var locationLine: String {
        if !offer.serviceLocationName.isEmpty {
            return offer.serviceLocationName
        }

        if let address = offer.address,
           !address.streetAddress.isEmpty {
            return address.streetAddress
        }

        return offer.offerType == .internalBoard ? offer.boardVisibility.title : offer.offeredToUserName
    }

    private var jobLine: String {
        [offer.jobInternalId, offer.jobName]
            .filter { !$0.isEmpty }
            .joined(separator: " - ")
    }

    private var deadlineLine: String {
        offer.technicianDeadlineSummary
    }

    private var timelineLine: String {
        offer.technicianTimelineSummary
    }
}

private struct TechnicianOfferFactPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(12)
        .background(Color.workOfferInsetSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct TechnicianSwipeDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.isEmpty ? "-" : value)
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.trailing)
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
        Section("Timeline") {
            if let proposedStartDate = offer.proposedStartDate {
                TechnicianWorkDetailRow(
                    title: "Available From",
                    value: TechnicianWorkDateFormatter.shortDateTime(proposedStartDate)
                )
            } else {
                TechnicianWorkDetailRow(title: "Available From", value: "-")
            }

            if let deadline = offer.workOfferDeadlineAt {
                TechnicianWorkDetailRow(
                    title: "Complete By",
                    value: TechnicianWorkDateFormatter.shortDateTime(deadline)
                )
            } else {
                TechnicianWorkDetailRow(title: "Complete By", value: "No deadline set")
            }

            if !offer.workOfferTimelineNotes.isEmpty {
                TechnicianWorkDetailRow(title: "Timeline Notes", value: offer.workOfferTimelineNotes)
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
    case rejected
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
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

            Label(offer.technicianTimelineSummary, systemImage: "flag.checkered")
                .font(.caption2)
                .foregroundStyle(offer.workOfferDeadlineAt == nil ? .tertiary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var iconName: String {
        switch rowStyle {
        case .directOffer:
            return "paperplane"
        case .boardPost:
            return "list.bullet.clipboard"
        case .accepted:
            return "checkmark.circle"
        case .rejected:
            return "xmark.circle"
        }
    }

    private var subtitle: String {
        switch offer.offerType {
        case .directUser:
            return "Direct offer • \(offer.customerName)"
        case .internalBoard:
            return "Board post • \(offer.workOfferBoardDisplayName)"
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

                if $0.workOfferDeadlineAt != nil || $1.workOfferDeadlineAt != nil {
                    guard let leftDeadline = $0.workOfferDeadlineAt else { return false }
                    guard let rightDeadline = $1.workOfferDeadlineAt else { return true }
                    if leftDeadline != rightDeadline { return leftDeadline < rightDeadline }
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

            Label(offer.technicianDeadlineSummary, systemImage: "flag.checkered")
                .font(.caption2)
                .foregroundStyle(offer.workOfferDeadlineAt == nil ? .tertiary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
    var technicianDisplayPayCents: Int {
        if let estimatedPayTotalCents {
            return estimatedPayTotalCents
        }

        if offeredAmountCents > 0 {
            return offeredAmountCents
        }

        return estimatedLaborCents
    }

    var companyEstimatedPayCents: Int {
        if let estimatedPayTotalCents {
            return estimatedPayTotalCents
        }

        if offeredAmountCents > 0 {
            return offeredAmountCents
        }

        return estimatedLaborCents
    }

    var workOfferDeadlineAt: Date? {
        completionDeadlineAt ?? proposedEndDate
    }

    var workOfferTimelineNotes: String {
        timelineNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var workOfferBoardDisplayName: String {
        if let boardName = boardName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !boardName.isEmpty {
            return boardName
        }

        if let boardNames,
           !boardNames.isEmpty {
            return boardNames.joined(separator: ", ")
        }

        return boardVisibility.title
    }

    var technicianDeadlineSummary: String {
        guard let deadline = workOfferDeadlineAt else {
            return "No deadline"
        }

        return TechnicianWorkDateFormatter.shortDateTime(deadline)
    }

    var technicianTimelineSummary: String {
        switch (proposedStartDate, workOfferDeadlineAt) {
        case let (start?, deadline?):
            return "\(TechnicianWorkDateFormatter.shortDateTime(start)) → \(TechnicianWorkDateFormatter.shortDateTime(deadline))"
        case let (start?, nil):
            return "Starts \(TechnicianWorkDateFormatter.shortDateTime(start))"
        case let (nil, deadline?):
            return "Due \(TechnicianWorkDateFormatter.shortDateTime(deadline))"
        case (nil, nil):
            return "No timeline set"
        }
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
