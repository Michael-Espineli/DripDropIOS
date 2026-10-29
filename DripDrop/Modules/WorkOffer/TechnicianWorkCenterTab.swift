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
    case previous = "Previous"

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
            .filter { $0.isCurrentWork(for: companyUser.userId) }
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
            .sorted { $0.createdAt > $1.createdAt }
    }

    var previousOffers: [WorkOffer] {
        (directOffers + boardOffers + acceptedUserOffers)
            .filter(\.isWorkOfferRecord)
            .filter { $0.isPreviousWork(for: companyUser.userId) }
            .uniqueById()
            .sorted { $0.workOfferHistoryDate > $1.workOfferHistoryDate }
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
            acceptedUserOffers = (try await acceptedTask)
                .filter(\.isWorkOfferRecord)
        } catch {
            alertMessage = "Could not load work offers. \(error.localizedDescription)"
            showAlert = true
        }
        
    }

    func acceptOffer(companyId:String, _ offer: WorkOffer, stopIds: [String] = []) async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await FunctionsManager.shared.manageWork(companyId: companyId, offerId: offer.id, action: "accept", extra: ["claimId":UUID().uuidString, "revision":offer.revision ?? 1, "stopIds":stopIds])

            await load(companyId:companyId,forceRefresh: true)
            return true
        } catch {
            alertMessage = "Could not accept work. \(error.localizedDescription)"
            return false
        }
    }

    func rejectOffer(
        companyId:String,
        _ offer: WorkOffer,
        reason: String
    ) async -> Bool {
        guard !isSaving else { return false }

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

            await load(companyId: companyId, forceRefresh: true)
            return true
        } catch {
            alertMessage = "Could not reject work. \(error.localizedDescription)"
            return false
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
    @State private var reviewStartingOfferId: String?
    @State private var reviewBoardOnly = false

    private var reviewOffers: [WorkOffer] {
        let offers = reviewBoardOnly ? viewModel.openBoardOffers : viewModel.discoveryOffers
        guard let first = offers.first(where: { $0.id == reviewStartingOfferId }) else { return offers }
        return [first] + offers.filter { $0.id != first.id }
    }

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
            VStack(spacing: 14) {
                headerPanel
                workTabs
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
                        offers: reviewOffers,
                        companyUser: viewModel.companyUser,
                        isSaving: viewModel.isSaving,
                        acceptAction: { offer, stopIds in
                            await viewModel.acceptOffer(companyId: currentCompany.id, offer, stopIds: stopIds)
                        },
                        rejectAction: { offer, reason in
                            await viewModel.rejectOffer(
                                    companyId: currentCompany.id,
                                    offer,
                                    reason: reason
                            )
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
                Image(systemName: "tray.full")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 38, height: 38)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Work Offered")
                        .font(.title2.weight(.bold))

                    Text("Find work that fits your route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            HStack(spacing: 8) {
                Label("\(viewModel.directOfferCount) direct", systemImage: "paperplane")
                Label("\(viewModel.boardOfferCount) board", systemImage: "list.bullet.clipboard")
                Label("\(viewModel.acceptedOfferCount) current", systemImage: "briefcase")
                Spacer(minLength: 0)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var workTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TechnicianWorkCenterTab.allCases) { tab in
                    workSummaryTabButton(for: tab)
                }
            }
        }
    }

    private func workSummaryTabButton(for tab: TechnicianWorkCenterTab) -> some View {
        let isSelected = viewModel.selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                viewModel.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Label(tab.rawValue, systemImage: tabIcon(for: tab)).lineLimit(1)
                Text("\(tabCount(for: tab))").monospacedDigit()
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .background(
                isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(tab.rawValue), \(tabCount(for: tab))")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
        case .previous:
            previousWorkSection
        }
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TechnicianWorkPanel(
                title: "Pending Offers",
                systemImage: "bolt.fill"
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        reviewStartingOfferId = nil
                        reviewBoardOnly = false
                        showSwipeReview = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.poolBlue)
                                .frame(width: 38, height: 38)
                                .background(Color.poolBlue.opacity(0.12), in: Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Review Pending Offers")
                                    .font(.headline.weight(.semibold))

                                Text("Swipe through your offers. Find your next great fit.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Text("\(viewModel.discoveryOffers.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.poolBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.poolBlue.opacity(0.12), in: Capsule())
                        }
                        .padding(14)
                        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.discoveryOffers.isEmpty || masterDataManager.currentCompany == nil)
                    .opacity(viewModel.discoveryOffers.isEmpty ? 0.6 : 1)

                    if viewModel.discoveryOffers.isEmpty {
                        ContentUnavailableView(
                            "No Pending Offers",
                            systemImage: "tray",
                            description: Text("Direct offers and eligible board work will show up here.")
                        )
                    } else {
                        VStack(spacing: 10) {
                            ForEach(viewModel.discoveryOffers.prefix(4)) { offer in
                                Button {
                                    reviewStartingOfferId = offer.id
                                    reviewBoardOnly = false
                                    showSwipeReview = true
                                } label: {
                                    TechnicianWorkOfferRow(
                                        offer: offer,
                                        rowStyle: offer.offerType == .internalBoard ? .boardPost : .directOffer
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var availableWorkSection: some View {
        TechnicianWorkPanel(
            title: "Work Board",
            systemImage: "list.bullet.clipboard"
        ) {
            if viewModel.openBoardOffers.isEmpty {
                ContentUnavailableView(
                    "No Board Work",
                    systemImage: "tray",
                    description: Text("Available board work will appear here for eligible technicians to pick up.")
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Browse open board posts and pick up the work that fits your route.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.openBoardOffers) { offer in
                        Button {
                            reviewStartingOfferId = offer.id
                            reviewBoardOnly = true
                            showSwipeReview = true
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

    private var previousWorkSection: some View {
        TechnicianWorkPanel(
            title: "Previous Offers",
            systemImage: "clock.arrow.circlepath"
        ) {
            if viewModel.previousOffers.isEmpty {
                ContentUnavailableView(
                    "No Previous Offers",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed, rejected, cancelled, and expired work offers will be saved here.")
                )
            } else {
                Text("Your offer history, with the most recent activity first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.previousOffers) { offer in
                        NavigationLink {
                            offerDetailDestination(
                                offer,
                                canReject: false,
                                canAccept: false
                            )
                        } label: {
                            TechnicianWorkOfferRow(
                                offer: offer,
                                rowStyle: .previous
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
                acceptAction: { stopIds in
                    await viewModel.acceptOffer(companyId: currentCompany.id, offer, stopIds: stopIds)
                },
                rejectAction: { reason in
                    await viewModel.rejectOffer(
                            companyId: currentCompany.id,
                            offer,
                            reason: reason
                    )
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
        case .previous:
            return viewModel.previousOffers.count
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
        case .previous:
            return "clock.arrow.circlepath"
        }
    }

}

struct TechnicianWorkPanel<Content: View>: View {
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
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 32, height: 32)
                    .background(Color.poolBlue.opacity(0.12), in: Circle())
                Text(title)
                    .font(.headline.weight(.semibold))
            }

            content()
        }
        .technicianPanel()
    }
}

struct WorkOfferLocationHeader: View {
    let offer: WorkOffer
    var status: String? = nil

    private var location: String {
        let candidates = [offer.serviceLocationName, offer.address?.streetAddress ?? "", offer.routeName ?? "", offer.customerName]
        return candidates.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? "Location to be confirmed"
    }

    private var addressLine: String {
        guard let address = offer.address else { return "" }
        return [address.streetAddress, [address.city, address.state, address.zip]
            .filter { !$0.isEmpty }.joined(separator: " ")]
            .filter { !$0.isEmpty && $0 != location }.joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(offer.routeId == nil ? "WORK LOCATION" : "ROUTE COVERAGE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(location)
                        .font(.title2.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    if !addressLine.isEmpty {
                        Text(addressLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }

            Divider()

            Text(offer.title.isEmpty ? "Offered Work" : offer.title)
                .font(.headline)
            if !offer.customerName.isEmpty && offer.customerName != location {
                Text(offer.customerName).font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label(offer.offerType.title, systemImage: offer.offerType.systemImage)
                    .foregroundStyle(Color.poolBlue)
                Spacer(minLength: 0)
                Text(status ?? offer.status.title)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private extension Color {
    static var workOfferCardSurface: Color {
        Color(.systemBackground)
    }

    static var workOfferCardBase: Color {
        Color(.systemBackground)
    }

    static var workOfferInsetSurface: Color {
        Color(.tertiarySystemGroupedBackground)
    }
}

extension View {
    func technicianPanel() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
            }
    }

    @ViewBuilder
    func swipeCardGesture<SwipeGesture: Gesture>(
        _ isActive: Bool,
        gesture: SwipeGesture
    ) -> some View {
        if isActive {
            self.simultaneousGesture(gesture)
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
    let acceptAction: (WorkOffer, [String]) async -> Bool
    let rejectAction: (WorkOffer, String) async -> Bool
    let skipAction: (WorkOffer) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pending Offers")
                        .font(.title2.weight(.bold))

                    Text("Swipe right to review and accept. Swipe left to pass. Your next opportunity is one card away.")
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
        .navigationTitle("Review Offers")
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let offers: [WorkOffer]
    let companyUser: CompanyUser
    let isSaving: Bool
    let acceptAction: (WorkOffer, [String]) async -> Bool
    let rejectAction: (WorkOffer, String) async -> Bool
    let skipAction: (WorkOffer) -> Void

    @State private var reviewedOfferIds: Set<String> = []
    @State private var reviewingOffer: WorkOffer?
    @State private var dragOffset: CGSize = .zero
    @State private var pendingRejectOffer: WorkOffer?
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    @State private var actionError: String?
    @State private var acceptingCard = false

    private var remainingOffers: [WorkOffer] { offers.filter { !reviewedOfferIds.contains($0.id) } }
    private var activeOffer: WorkOffer? { remainingOffers.first }
    private var isBusy: Bool { isSaving || isProcessing }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Label("\(remainingOffers.count) to explore", systemImage: "rectangle.stack")
                Spacer()
                if !reviewedOfferIds.isEmpty { Text("\(reviewedOfferIds.count) reviewed") }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            deckBody

            if let activeOffer {
                HStack(spacing: 14) {
                    Button(role: activeOffer.offerType == .directUser ? .destructive : nil) {
                        handleLeftAction(activeOffer)
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: "xmark").font(.title3.weight(.bold))
                                .frame(width: 54, height: 54)
                                .background(.background, in: Circle())
                                .overlay(Circle().stroke(Color.primary.opacity(0.08)))
                            Text(activeOffer.offerType == .directUser ? "Reject" : "Skip for now").font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button { openDetails(activeOffer) } label: {
                        Label("Review & accept", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 22)
                            .frame(minHeight: 54)
                            .foregroundStyle(.white)
                            .background(Color.poolGreen, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .disabled(isBusy)
            }
        }
        .alert("Reject Work", isPresented: rejectDialogBinding) {
            TextField("Reason (optional)", text: $rejectionReason)
            Button("Reject", role: .destructive) {
                guard let offer = pendingRejectOffer else { return }
                let reason = rejectionReason
                pendingRejectOffer = nil
                rejectionReason = ""
                Task {
                    isProcessing = true
                    let rejected = await rejectAction(offer, reason)
                    isProcessing = false
                    if rejected { advance(offer) }
                    else { actionError = "Could not reject this offer. Please try again." }
                }
            }
            Button("Keep Offer", role: .cancel) { pendingRejectOffer = nil; resetDrag() }
        } message: {
            Text("This will move the offer to Previous.")
        }
        .alert("Offer unchanged", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: { Text(actionError ?? "") }
        .sheet(item: $reviewingOffer) { offer in
            NavigationStack {
                TechnicianWorkOfferDetailView(
                    offer: offer, companyUser: companyUser,
                    canReject: offer.offerType == .directUser, canAccept: true,
                    acceptAction: { stops in
                        acceptingCard = true
                        let accepted = await acceptAction(offer, stops)
                        if accepted { advance(offer) }
                        return accepted
                    },
                    rejectAction: { reason in
                        acceptingCard = false
                        let rejected = await rejectAction(offer, reason)
                        if rejected { advance(offer) }
                        return rejected
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { reviewingOffer = nil }.disabled(isSaving)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: reviewedOfferIds.count)
    }

    @ViewBuilder private var deckBody: some View {
        if activeOffer == nil {
            ContentUnavailableView(
                reviewedOfferIds.isEmpty ? "No Offers To Review" : "You're all caught up!",
                systemImage: reviewedOfferIds.isEmpty ? "tray" : "checkmark.seal.fill",
                description: Text("New offers will appear here. Accepted work is in Current, and your offer history is in Previous.")
            )
            .frame(maxWidth: .infinity, minHeight: 360)
            .technicianPanel()
        } else {
            ZStack {
                ForEach(Array(remainingOffers.prefix(3).enumerated()), id: \.element.id) { index, offer in
                    TechnicianOfferSwipeCard(
                        offer: offer, companyUser: companyUser,
                        acceptAction: { openDetails(offer) }
                    )
                    .overlay(alignment: dragOffset.width >= 0 ? .topLeading : .topTrailing) {
                        if index == 0 && abs(dragOffset.width) > 24 {
                            Text(dragOffset.width > 0 ? "LET'S GO" : (offer.offerType == .directUser ? "PASS" : "LATER"))
                                .font(.title2.weight(.heavy))
                                .foregroundStyle(dragOffset.width > 0 ? Color.poolGreen : Color.poolRed)
                                .padding(12)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                                .padding(18)
                                .opacity(min(abs(dragOffset.width) / 100, 1))
                                .allowsHitTesting(false)
                        }
                    }
                    .offset(x: index == 0 ? dragOffset.width : 0, y: CGFloat(index) * 12)
                    .scaleEffect(index == 0 ? 1 : 1 - CGFloat(index) * 0.045)
                    .rotationEffect(.degrees(index == 0 && !reduceMotion ? Double(dragOffset.width / 24) : 0))
                    .zIndex(Double(3 - index))
                    .swipeCardGesture(index == 0 && !isBusy, gesture: dragGesture(for: offer))
                    .allowsHitTesting(index == 0 && !isBusy)
                    .accessibilityHidden(index != 0)
                    .accessibilityAction(named: "Review offer") { openDetails(offer) }
                    .accessibilityAction(named: offer.offerType == .directUser ? "Reject offer" : "Skip offer") { handleLeftAction(offer) }
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .offset(x: acceptingCard ? 500 : -500, y: 30).combined(with: .opacity)
                    ))
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82), value: remainingOffers.map(\.id))
            .frame(height: 520)
            .padding(.bottom, 24)
        }
    }

    private var rejectDialogBinding: Binding<Bool> {
        Binding(get: { pendingRejectOffer != nil }, set: { if !$0 { pendingRejectOffer = nil; resetDrag() } })
    }

    private func dragGesture(for offer: WorkOffer) -> some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                guard !isBusy, abs(value.translation.width) > abs(value.translation.height) * 1.2 else { return }
                dragOffset = CGSize(width: value.translation.width, height: 0)
            }
            .onEnded { value in
                guard !isBusy, abs(value.translation.width) > abs(value.translation.height) * 1.2 else { resetDrag(); return }
                if value.translation.width > 110 { openDetails(offer) }
                else if value.translation.width < -110 { handleLeftAction(offer) }
                else { resetDrag() }
            }
    }

    private func openDetails(_ offer: WorkOffer) {
        guard !isBusy else { return }
        acceptingCard = false
        resetDrag()
        reviewingOffer = offer
    }

    private func handleLeftAction(_ offer: WorkOffer) {
        guard !isBusy else { return }
        acceptingCard = false
        resetDrag()
        if offer.offerType == .directUser { pendingRejectOffer = offer }
        else { advance(offer); skipAction(offer) }
    }

    private func resetDrag() {
        withAnimation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.76)) { dragOffset = .zero }
    }

    private func advance(_ offer: WorkOffer) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82)) {
            dragOffset = .zero
            _ = reviewedOfferIds.insert(offer.id)
        }
    }
}

private struct TechnicianOfferSwipeCard: View {
    let offer: WorkOffer
    let companyUser: CompanyUser
    let acceptAction: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                topMatter
                quickFacts
                detailBlock
                notesBlock
                Button { acceptAction() } label: {
                    Label("View full offer", systemImage: "arrow.up.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
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
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(cardTint.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 12)
    }

    private var topMatter: some View {
        WorkOfferLocationHeader(offer: offer)
    }

    private var quickFacts: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ], spacing: 10) {
            TechnicianOfferFactPill(
                title: "Pay",
                value: offer.paySource == .technicianRate && offer.estimatedPayTotalCents == nil ? "Your Rate" : TechnicianWorkMoneyFormatter.money(offer.technicianDisplayPayCents),
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
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        .background(Color.workOfferInsetSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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

    let acceptAction: ([String]) async -> Bool
    let rejectAction: (String) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var quoteScope: WorkOfferScope?
    @State private var quotedBase: Int?
    @State private var quotedBonus = 0
    @State private var quotedLines: [WorkOfferPayEstimateLine] = []
    @State private var hourlySource = ""
    @State private var quotedTotal: Int?
    @State private var quoteNeedsReview = false
    @State private var quoteError = ""
    @State private var isAccepting = false
    @State private var isRejecting = false
    @State private var isLoadingQuote = false
    @State private var quoteRequestId = UUID()
    @State private var hasLoadedQuote = false
    @State private var selectedStopIds = Set<String>()
    @State private var showRejectDialog: Bool = false
    @State private var rejectionReason: String = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                WorkOfferLocationHeader(offer: offer, status: personalClaimStatus)
                quickFacts
                scopeSection
                paySection
                scheduleSection
                jobSection
                statusSection
                notesSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.listColor.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if canAccept || canReject { actionSection }
        }
        .task { await loadQuote() }
        .navigationTitle("Work Offer")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isAccepting || isRejecting)
        .alert("Reject Work", isPresented: $showRejectDialog) {
            TextField("Reason (optional)", text: $rejectionReason)
            Button("Reject", role: .destructive) {
                Task {
                    isRejecting = true
                    let rejected = await rejectAction(rejectionReason)
                    isRejecting = false
                    if rejected { dismiss() }
                    else { quoteError = "Could not reject this offer. Please try again." }
                }
            }
            Button("Keep Offer", role: .cancel) { }
        } message: {
            Text("This will move the offer to Previous.")
        }
    }

    private var quickFacts: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            TechnicianOfferFactPill(title: "Your pay", value: quotedTotal.map(TechnicianWorkMoneyFormatter.money) ?? (canAccept ? "Calculating…" : "See pay details"), systemImage: "dollarsign.circle")
            TechnicianOfferFactPill(title: "Estimated time", value: "\(offer.estimatedMinutes) min", systemImage: "clock")
        }
    }

    private var personalClaimStatus: String { offer.technicianStatus(for: companyUser.userId).title }

    private var statusSection: some View {
        TechnicianWorkPanel(title: "Offer", systemImage: "person.crop.circle") {
            HStack {
                Label(offer.offerType.title, systemImage: offer.offerType.systemImage)

                Spacer()

                Text(personalClaimStatus)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            TechnicianWorkDetailRow(title: "Worker", value: companyUser.userName)
            TechnicianWorkDetailRow(title: "Worker Type", value: companyUser.workerType.rawValue)
            TechnicianWorkDetailRow(title: "Offered", value: TechnicianWorkDateFormatter.shortDateTime(offer.createdAt))
            if offer.isPreviousWork(for: companyUser.userId) {
                TechnicianWorkDetailRow(title: "Last activity", value: TechnicianWorkDateFormatter.shortDateTime(offer.workOfferHistoryDate))
            }
        }
    }

    private var jobSection: some View {
        TechnicianWorkPanel(title: "Job details", systemImage: "briefcase") {
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
        TechnicianWorkPanel(title: "The work", systemImage: "checklist") {
            Text(offer.workPurpose == "diagnostic" ? "Diagnostic / estimate visit" : "Perform planned work").font(.headline)
            TechnicianWorkDetailRow(title: "Estimated Time", value: "\(offer.estimatedMinutes) min")
            if let scope = quoteScope ?? offer.scopeSnapshot {
                scopeRows("Services", items: scope.services)
                scopeRows("Tasks", items: scope.tasks)
                scopeRows("Products", items: scope.products)
                ForEach(scope.stops) { stop in
                    if offer.routeSplitAllowed == true && canAccept {
                        Toggle(stop.name, isOn: Binding(get: { selectedStopIds.contains(stop.id) }, set: { value in
                            if value { selectedStopIds.insert(stop.id) } else { selectedStopIds.remove(stop.id) }
                            Task { await loadQuote(keepSelection: true) }
                        }))
                        .disabled(isLoadingQuote || isAccepting || isRejecting)
                    } else { Text(stop.name) }
                }
            } else {
                Text(isLoadingQuote ? "Loading detailed scope…" : "Detailed scope is unavailable. Refresh the offer to try again.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
    @ViewBuilder private func scopeRows(_ title: String, items: [WorkOfferScopeItem]) -> some View {
        if !items.isEmpty { Text(title).font(.subheadline.bold()) }
        ForEach(items) { item in
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                if let description = item.description, !description.isEmpty { Text(description).font(.caption) }
                if let quantity = item.quantity { Text("Quantity: \(quantity.formatted())").font(.caption) }
                if let equipment = item.equipmentName, !equipment.isEmpty { Text(equipment).font(.caption) }
                if let status = item.status { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }
    @MainActor private func loadQuote(keepSelection: Bool = false) async {
        let requestId = UUID()
        quoteRequestId = requestId
        isLoadingQuote = true
        defer { if quoteRequestId == requestId { isLoadingQuote = false } }

        if !canAccept {
            let terms = offer.claims?.first { $0.workerId == companyUser.userId }?.agreement ?? offer.acceptedTerms
            quotedBase = terms?.baseCents
            quotedTotal = terms?.totalCents
        }
        do {
            let preserveSelection = keepSelection && hasLoadedQuote
            let extra: [String: Any] = preserveSelection ? ["stopIds": Array(selectedStopIds)] : [:]
            let result = try await FunctionsManager.shared.manageWork(
                companyId: offer.companyId, offerId: offer.id,
                action: canAccept ? "preview" : "details", extra: extra
            )
            guard quoteRequestId == requestId else { return }
            let scope = try (result["scope"] as? [String: Any]).map {
                try JSONDecoder().decode(WorkOfferScope.self, from: JSONSerialization.data(withJSONObject: $0))
            }
            let pay = canAccept ? result : (result["pay"] as? [String: Any] ?? [:])
            let lines = try (pay["lines"] as? [[String: Any]]).map {
                try JSONDecoder().decode([WorkOfferPayEstimateLine].self, from: JSONSerialization.data(withJSONObject: $0))
            } ?? []
            quoteScope = scope
            quotedBase = (pay["baseCents"] as? NSNumber)?.intValue ?? (canAccept ? nil : quotedBase)
            quotedTotal = (pay["totalCents"] as? NSNumber)?.intValue ?? (canAccept ? nil : quotedTotal)
            quotedBonus = (pay["incentiveCents"] as? NSNumber)?.intValue ?? 0
            quotedLines = lines
            quoteNeedsReview = pay["needsReview"] as? Bool ?? false
            hourlySource = pay["hourlyPaySource"] as? String ?? ""
            if !preserveSelection {
                selectedStopIds = Set(offer.remainingStopIds ?? scope?.stops.map(\.id) ?? [])
            }
            hasLoadedQuote = true
            quoteError = result["scopeChanged"] as? Bool == true
                ? "The job plan has changed. Confirm any additional work with management." : ""
        } catch {
            guard quoteRequestId == requestId else { return }
            quoteError = "Could not load offer details. \(error.localizedDescription)"
        }
    }

    private func payLineDescription(_ line: WorkOfferPayEstimateLine) -> String {
        let rate = line.rateType == .percentage ? (Double(line.rateAmountCents) / 100).formatted() + "%" : TechnicianWorkMoneyFormatter.money(line.rateAmountCents)
        let suffix = line.rateType == .hourly ? "/hr" : ""
        let quantity = line.quantity.formatted() + " " + line.quantityUnit.rawValue
        let total = TechnicianWorkMoneyFormatter.money(line.totalAmountCents)
        return "\(rate)\(suffix) · \(quantity) · \(total)"
    }

    private var paySection: some View {
        TechnicianWorkPanel(title: "Your pay", systemImage: "dollarsign.circle") {
            TechnicianWorkDetailRow(title: "Pay Source", value: offer.paySource.title)

            if offer.offeredAmountCents > 0 {
                TechnicianWorkDetailRow(title: "Offered Amount", value: TechnicianWorkMoneyFormatter.money(offer.offeredAmountCents))
            }

            if let quotedTotal { TechnicianWorkDetailRow(title: "Your Pay", value: TechnicianWorkMoneyFormatter.money(quotedTotal)) }
            if let quotedBase { TechnicianWorkDetailRow(title: "Base", value: TechnicianWorkMoneyFormatter.money(quotedBase)) }
            if quotedBonus > 0 { TechnicianWorkDetailRow(title: "Incentive", value: TechnicianWorkMoneyFormatter.money(quotedBonus)) }
            if !hourlySource.isEmpty { TechnicianWorkDetailRow(title: "Hourly Time Source", value: hourlySource) }
            ForEach(quotedLines) { line in
                VStack(alignment: .leading,spacing:4) {
                    Text(line.title).font(.subheadline)
                    Text(payLineDescription(line)).font(.caption).foregroundStyle(.secondary)
                }
            }
            if isLoadingQuote {
                ProgressView("Updating pay…").font(.caption)
            }
            if quoteNeedsReview {
                Label("Management needs to review this pay before you can accept.", systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.orange)
            }
            if !quoteError.isEmpty {
                Text(quoteError).font(.caption).foregroundStyle(.red)
                Button("Refresh offer") { Task { await loadQuote(keepSelection: true) } }
                    .disabled(isLoadingQuote || isAccepting || isRejecting)
            }
            Text("Accepted rates are preserved. Fixed pay and incentives are earned once the agreed scope is complete. Hourly totals depend on recorded time.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var scheduleSection: some View {
        TechnicianWorkPanel(title: "Timeline", systemImage: "calendar") {
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
                    Text("Accepted. You can schedule this work from the Current tab.")
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
            !offer.workerNotes.isEmpty ||
            !offer.rejectionReason.isEmpty {
            TechnicianWorkPanel(title: "Notes", systemImage: "text.alignleft") {
                if !offer.description.isEmpty {
                    TechnicianWorkNoteBlock(title: "Description", value: offer.description)
                }

                if !offer.adminNotes.isEmpty {
                    TechnicianWorkNoteBlock(title: "Admin Notes", value: offer.adminNotes)
                }

                if !offer.workerNotes.isEmpty {
                    TechnicianWorkNoteBlock(title: "Worker Notes", value: offer.workerNotes)
                }

                if !offer.rejectionReason.isEmpty {
                    TechnicianWorkNoteBlock(title: "Rejection / cancellation reason", value: offer.rejectionReason)
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if canReject {
                    Button(role: .destructive) { showRejectDialog = true } label: {
                        Label(isRejecting ? "Rejecting…" : "Reject", systemImage: "xmark")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isAccepting || isRejecting)
                }
                if canAccept {
                    Button {
                        Task {
                            isAccepting = true
                            let accepted = await acceptAction(Array(selectedStopIds))
                            isAccepting = false
                            if accepted { dismiss() }
                            else { quoteError = "Could not accept this work. Refresh the offer and review any changes." }
                        }
                    } label: {
                        HStack {
                            if isAccepting { ProgressView().tint(.white) }
                            Label(isAccepting ? "Accepting…" : "Accept Work", systemImage: "checkmark")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.poolGreen)
                    .disabled(isAccepting || isRejecting || isLoadingQuote || quoteNeedsReview || quotedTotal == nil || !quoteError.isEmpty || (!(quoteScope?.stops.isEmpty ?? true) && selectedStopIds.isEmpty))
                }
            }
            Text("Review the scope and pay before accepting.")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

// MARK: - Rows

enum TechnicianWorkOfferRowStyle {
    case directOffer
    case boardPost
    case accepted
    case rejected
    case previous
}

struct TechnicianWorkOfferRow: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager
    private var ownClaim: WorkOfferClaim? { offer.claims?.first { $0.workerId == masterDataManager.user?.id } }
    var offer: WorkOffer
    var rowStyle: TechnicianWorkOfferRowStyle

    private var displayedStopIds: [String] {
        if let claim = ownClaim, !claim.stopIds.isEmpty { return claim.stopIds }
        return offer.remainingStopIds ?? offer.routeServiceStopIds ?? []
    }

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

                Text(offer.technicianStatus(for: masterDataManager.user?.id ?? "").title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            HStack(spacing: 10) {
                if !displayedStopIds.isEmpty {
                    Label("\(displayedStopIds.count) stop\(displayedStopIds.count == 1 ? "" : "s")", systemImage: "mappin.and.ellipse")
                } else {
                    Label("\(offer.jobTaskIds.count) task(s)", systemImage: "checklist")
                }
                Label("\(offer.estimatedMinutes) min", systemImage: "clock")

                if let total = ownClaim?.agreement.totalCents {
                    Label(TechnicianWorkMoneyFormatter.money(total), systemImage: "dollarsign.circle")
                } else if offer.offeredAmountCents > 0 {
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

            if rowStyle == .previous {
                Text(offer.workOfferHistoryDate, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        case .previous:
            return "clock.arrow.circlepath"
        }
    }

    private var subtitle: String {
        if let routeName = offer.routeName {
            return routeName.isEmpty ? "Route coverage" : "Route coverage · \(routeName)"
        }
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
    case final = "Previous"
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
                if statusFilter == .final { return $0.workOfferHistoryDate > $1.workOfferHistoryDate }
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                summarySection
                statusTabs
                filtersSection
                offersSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.listColor.ignoresSafeArea())
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
        TechnicianWorkPanel(title: "Offered Work", systemImage: "tray.full") {
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
            Text("\(viewModel.summary.total) total offers · Review active work or open Previous for offer history.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var statusTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CompanyOfferedWorkStatusFilter.allCases) { filter in
                    Button { withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) { statusFilter = filter } } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusFilter == filter ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .background(statusFilter == filter ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.background), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(statusFilter == filter ? .isSelected : [])
                }
            }
        }
    }

    private var filtersSection: some View {
        TechnicianWorkPanel(title: "Filters", systemImage: "line.3.horizontal.decrease") {
            LabeledContent("Type") {
                Picker("Type", selection: $typeFilter) {
                    ForEach(CompanyOfferedWorkTypeFilter.allCases) { Text($0.rawValue).tag($0) }
                }.labelsHidden()
            }
            LabeledContent("Scheduling") {
                Picker("Scheduling", selection: $schedulingFilter) {
                    ForEach(CompanyOfferedWorkSchedulingFilter.allCases) { Text($0.rawValue).tag($0) }
                }.labelsHidden()
            }
            LabeledContent("Worker") {
                Picker("Worker", selection: $workerFilter) {
                    ForEach(workerOptions, id: \.self) { Text($0).tag($0) }
                }.labelsHidden()
            }
        }
        .pickerStyle(.menu)
    }

    private var offersSection: some View {
        TechnicianWorkPanel(title: statusFilter == .final ? "Previous Offers" : "\(filteredOffers.count) Offers", systemImage: statusFilter == .final ? "clock.arrow.circlepath" : "tray.full") {
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
                        HStack(spacing: 10) {
                            CompanyOfferedWorkRow(offer: offer)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
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
