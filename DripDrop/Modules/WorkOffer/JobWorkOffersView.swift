//
//  JobWorkOffersView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

struct JobWorkOffersView: View {

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceLocation: ServiceLocation?
    let workOffers: [WorkOffer]
    let dataService: any ProductionDataServiceProtocol
    let onReload: () -> Void

    @State private var showCreateOffer: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerCard
            offerActionsCard
            offersListCard
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .sheet(isPresented: $showCreateOffer, onDismiss: {
            onReload()
        }) {
            CreateJobWorkOfferView(
                companyId: companyId,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                job: job,
                jobTasks: jobTasks,
                serviceLocation: serviceLocation,
                dataService: dataService
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Work Offers", systemImage: "person.crop.circle.badge.plus")
                    .font(.title3.weight(.semibold))

                Spacer()

                Text("\(workOffers.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }

            Text("Offer planned job work to contractors, schedule employees directly later, or post work to the internal board.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .jobWorkOfferCard()
    }

    private var offerActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline.weight(.semibold))

            Button {
                showCreateOffer = true
            } label: {
                JobWorkOfferActionRow(
                    title: "Create Work Offer",
                    subtitle: "Send work to a contractor or post it to the internal board.",
                    systemImage: "plus.circle"
                )
            }
            .buttonStyle(.plain)
        }
        .jobWorkOfferCard()
    }

    private var offersListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Offers")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(openOfferSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if workOffers.isEmpty {
                ContentUnavailableView(
                    "No Work Offers",
                    systemImage: "tray",
                    description: Text("Create an offer when you want a contractor to accept work or when you want to post this job to the internal work board.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            } else {
                VStack(spacing: 10) {
                    ForEach(workOffers.sorted(by: { $0.createdAt > $1.createdAt })) { offer in
                        JobWorkOfferCardView(offer: offer)
                    }
                }
            }
        }
        .jobWorkOfferCard()
    }

    private var openOfferSummary: String {
        let openCount = workOffers.filter { $0.status.isOpen }.count
        return "\(openCount) open"
    }
}

// MARK: - Create Offer View

struct CreateJobWorkOfferView: View {

    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let job: Job
    let jobTasks: [JobTask]
    let serviceLocation: ServiceLocation?
    let dataService: any ProductionDataServiceProtocol

    @State private var offerType: WorkOfferType = .directUser
    @State private var selectedWorker: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .notAssigned
    )

    @State private var companyUsers: [CompanyUser] = []
    @State private var selectedTaskIds: Set<String> = []

    @State private var boardVisibility: WorkOfferBoardVisibility = .contractorsOnly
    @State private var paySource: WorkOfferPaySource = .technicianRate
    @State private var offeredAmountCents: Int = 0

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var proposedStartDate: Date = Date()
    @State private var includeDate: Bool = false

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    private var selectedTasks: [JobTask] {
        jobTasks.filter { selectedTaskIds.contains($0.id) }
    }

    private var estimatedMinutes: Int {
        selectedTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    private var estimatedLaborCents: Int {
        selectedTasks.reduce(0) { $0 + $1.contractedRate }
    }

    private var defaultTitle: String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(job.internalId) - \(job.customerName)"
        }

        return title
    }

    private var canSave: Bool {
        guard !selectedTaskIds.isEmpty else { return false }

        switch offerType {
        case .directUser:
            return !selectedWorker.userId.isEmpty
        case .internalBoard:
            return true
        case .externalCompany:
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                offerTypeSection
                workerSection
                taskScopeSection
                paySection
                scheduleSection
                notesSection
                saveSection
            }
            .navigationTitle("Create Work Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await load()
            }
            .alert("Work Offer", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var offerTypeSection: some View {
        Section {
            Picker("Offer Type", selection: $offerType) {
                Text("Direct User").tag(WorkOfferType.directUser)
                Text("Internal Board").tag(WorkOfferType.internalBoard)
            }
            .pickerStyle(.segmented)

            Text(offerTypeHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Offer Type")
        }
    }

    @ViewBuilder
    private var workerSection: some View {
        if offerType == .directUser {
            Section {
                if companyUsers.isEmpty {
                    ContentUnavailableView(
                        "No Contractors",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text("No active contractors were found.")
                    )
                } else {
                    Picker("Contractor", selection: $selectedWorker) {
                        Text("Select Contractor").tag(emptyCompanyUser)

                        ForEach(companyUsers.filter { $0.workerType == .contractor }) { user in
                            Text(user.userName).tag(user)
                        }
                    }

                    if !selectedWorker.userId.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedWorker.userName)
                                .font(.headline)

                            Text(selectedWorker.workerType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Send To")
            }
        }

        if offerType == .internalBoard {
            Section {
                Picker("Visibility", selection: $boardVisibility) {
                    ForEach(WorkOfferBoardVisibility.allCases) { visibility in
                        Text(visibility.title).tag(visibility)
                    }
                }
            } header: {
                Text("Board")
            } footer: {
                Text("The work will be posted so eligible company users can claim or request it later.")
            }
        }
    }

    private var taskScopeSection: some View {
        Section {
            if jobTasks.isEmpty {
                ContentUnavailableView(
                    "No Job Tasks",
                    systemImage: "checklist",
                    description: Text("Add planned work tasks before creating a work offer.")
                )
            } else {
                Button {
                    if selectedTaskIds.count == jobTasks.count {
                        selectedTaskIds.removeAll()
                    } else {
                        selectedTaskIds = Set(jobTasks.map { $0.id })
                    }
                } label: {
                    Text(selectedTaskIds.count == jobTasks.count ? "Deselect All" : "Select All")
                }

                ForEach(jobTasks) { task in
                    Button {
                        toggleTask(task)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: selectedTaskIds.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedTaskIds.contains(task.id) ? .green : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text("\(task.type.rawValue) • \(task.estimatedTime) min • \(money(task.contractedRate)) planned labor")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Work Scope")
        } footer: {
            Text("Selected tasks define the scope of this offer. Payroll will still be generated from completed service stop work later.")
        }
    }

    private var paySection: some View {
        Section {
            Picker("Pay Source", selection: $paySource) {
                ForEach(WorkOfferPaySource.allCases) { source in
                    Text(source.title).tag(source)
                }
            }

            if paySource == .offeredAmount {
                MoneyTextField(cents: $offeredAmountCents)
            }

            WorkOfferSummaryRow(title: "Estimated Minutes", value: "\(estimatedMinutes)")
            WorkOfferSummaryRow(title: "Planned Labor", value: money(estimatedLaborCents))

            if paySource == .offeredAmount {
                WorkOfferSummaryRow(title: "Offered Amount", value: money(offeredAmountCents))
            }
        } header: {
            Text("Pay")
        } footer: {
            Text("This is a work-offer snapshot. The payroll engine still calculates final pay from completed work unless you later choose to support offered-amount overrides.")
        }
    }

    private var scheduleSection: some View {
        Section {
            Toggle("Include proposed date", isOn: $includeDate)

            if includeDate {
                DatePicker(
                    "Proposed Date",
                    selection: $proposedStartDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        } header: {
            Text("Proposed Schedule")
        }
    }

    private var notesSection: some View {
        Section {
            TextField("Offer title", text: $title)

            TextField("Notes for worker", text: $notes, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
        } header: {
            Text("Details")
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await save()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Create Offer", systemImage: "paperplane")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(!canSave || isSaving)
        }
    }

    private var offerTypeHelpText: String {
        switch offerType {
        case .directUser:
            return "Send this work directly to one contractor."
        case .internalBoard:
            return "Post this work so eligible company users can claim or request it."
        case .externalCompany:
            return "External company offers can be added later."
        }
    }

    private var emptyCompanyUser: CompanyUser {
        CompanyUser(
            id: "",
            userId: "",
            userName: "",
            roleId: "",
            roleName: "",
            dateCreated: Date(),
            status: .active,
            workerType: .notAssigned
        )
    }

    private func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            companyUsers = try await dataService.getAllCompanyUsersByStatus(
                companyId: companyId,
                status: "Active"
            )

            if selectedTaskIds.isEmpty {
                selectedTaskIds = Set(jobTasks.map { $0.id })
            }
        } catch {
            alertMessage = "Could not load company users. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func toggleTask(_ task: JobTask) {
        if selectedTaskIds.contains(task.id) {
            selectedTaskIds.remove(task.id)
        } else {
            selectedTaskIds.insert(task.id)
        }
    }

    private func save() async {
        guard canSave else {
            alertMessage = "Select a contractor or board option and at least one task."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let status: WorkOfferStatus = offerType == .internalBoard ? .posted : .sent

            let offer = WorkOffer(
                companyId: companyId,
                jobId: job.id,
                jobInternalId: job.internalId,
                jobName: job.type,
                offerType: offerType,
                status: status,
                title: defaultTitle,
                description: notes.isEmpty ? job.description : notes,
                offeredToUserId: offerType == .directUser ? selectedWorker.userId : "",
                offeredToUserName: offerType == .directUser ? selectedWorker.userName : "",
                offeredToWorkerType: offerType == .directUser ? selectedWorker.workerType : .notAssigned,
                postedToBoard: offerType == .internalBoard,
                boardVisibility: offerType == .internalBoard ? boardVisibility : .contractorsOnly,
                boardPostId: offerType == .internalBoard ? WorkOfferIdFactory.boardPostId() : "",
                jobTaskIds: Array(selectedTaskIds),
                customerId: job.customerId,
                customerName: job.customerName,
                serviceLocationId: job.serviceLocationId,
                serviceLocationName: serviceLocation?.nickName ?? "",
                address: serviceLocation?.address,
                proposedStartDate: includeDate ? proposedStartDate : nil,
                proposedEndDate: nil,
                estimatedMinutes: estimatedMinutes,
                paySource: paySource,
                offeredAmountCents: paySource == .offeredAmount ? offeredAmountCents : 0,
                estimatedLaborCents: estimatedLaborCents,
                createdByUserId: currentUserId,
                createdByUserName: currentUserName,
                sentAt: offerType == .directUser ? Date() : nil,
                postedAt: offerType == .internalBoard ? Date() : nil,
                adminNotes: notes
            )

            try await dataService.saveWorkOffer(offer)
            dismiss()
        } catch {
            alertMessage = "Could not create work offer. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Rows / Cards

struct JobWorkOfferCardView: View {
    var offer: WorkOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                Image(systemName: offer.offerType.systemImage)
                    .frame(width: 28, height: 28)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(offer.title)
                        .font(.subheadline.weight(.semibold))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            HStack {
                Label("\(offer.jobTaskIds.count) task(s)", systemImage: "checklist")
                Spacer()
                Label("\(offer.estimatedMinutes) min", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if offer.offeredAmountCents > 0 {
                Text("Offered: \(money(offer.offeredAmountCents))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var subtitle: String {
        switch offer.offerType {
        case .directUser:
            return offer.offeredToUserName.isEmpty ? "Direct offer" : "Offered to \(offer.offeredToUserName)"
        case .internalBoard:
            return "Posted to board • \(offer.boardVisibility.title)"
        case .externalCompany:
            return offer.externalCompanyName.isEmpty ? "External company offer" : offer.externalCompanyName
        }
    }

    private func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

struct JobWorkOfferActionRow: View {
    var title: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 32)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct WorkOfferSummaryRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

private extension View {
    func jobWorkOfferCard() -> some View {
        self
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
