//
//  WorkOfferDetailView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

struct WorkOfferDetailView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let offer: WorkOffer
    let jobTasks: [JobTask]
    let dataService: any ProductionDataServiceProtocol
    let onChanged: () -> Void
    var startsEditing = false

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showCancelConfirmation: Bool = false
    @State private var cancelReason: String = ""
    @State private var returningClaim: WorkOfferClaim?
    @State private var showReturnConfirmation = false
    @State private var canManageReturns = false
    @State private var canEditOffer = false
    @State private var canDeleteOffer = false
    @State private var canIncentivize = false
    @State private var incentiveLocked = true
    @State private var detailedScope: WorkOfferScope?
    @State private var routeSummary: WorkOfferRouteSummary?
    @State private var showDeleteConfirmation = false
    @State private var showIncentiveSheet = false
    @State private var hasOpenedInitialEdit = false
    @State private var termsLocked = true
    @State private var showEditSheet = false
    @State private var returnReason = ""
    
    @State private var showScheduleSheet: Bool = false
    
    private var selectedTasks: [JobTask] {
        jobTasks.filter { offer.jobTaskIds.contains($0.id) }
    }

    private var selectedTaskTotalCents: Int {
        selectedTasks.reduce(0) { $0 + $1.contractedRate }
    }

    private var selectedTaskMinutes: Int {
        selectedTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    private var canCancel: Bool { canEditOffer && offer.status.isOpen }
    private var canMarkScheduled: Bool {
        offer.isReadyToSchedule
    }
    private var canApprove: Bool {
        canManageReturns || masterDataManager.role?.permissionIdList.contains("330") == true ||
            masterDataManager.currentCompany?.ownerId == currentUserId
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                offerHero
                statusSection
                receiverSection
                scopeSection
                paySection
                scheduleSection
                notesSection
                actionsSection
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(Color.listColor.ignoresSafeArea())
        .navigationTitle("Work Offer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if canEditOffer {
                    Button("Edit", systemImage: "pencil") { showEditSheet = true }
                }
            }
        }
        .task {
            if let capabilities = try? await FunctionsManager.shared.technicianWorkflow("manageTechnicianWork", payload: ["companyId": companyId, "action": "capabilities"]) {
                canManageReturns = capabilities["canPostForOthers"] as? Bool ?? false
            }
            do {
                let result = try await FunctionsManager.shared.manageWork(companyId: companyId, offerId: offer.id, action: "details")
                if let management = result["management"] as? [String: Any] {
                    canEditOffer = management["canEdit"] as? Bool ?? false
                    canDeleteOffer = management["canDelete"] as? Bool ?? false
                    canIncentivize = management["canIncentivize"] as? Bool ?? false
                    incentiveLocked = management["incentiveLocked"] as? Bool ?? true
                    termsLocked = management["termsLocked"] as? Bool ?? true
                    if startsEditing && canEditOffer && !hasOpenedInitialEdit {
                        hasOpenedInitialEdit = true
                        showEditSheet = true
                    }
                }
                routeSummary = WorkOfferRouteSummary.decode(result["routeSummary"])
                if let scope = result["scope"] as? [String: Any] {
                    detailedScope = try JSONDecoder().decode(WorkOfferScope.self, from: JSONSerialization.data(withJSONObject: scope))
                }
            } catch {
                alertMessage = "Could not load offer management details. \(error.userFacingMessage)"
                showAlert = true
            }
        }
        .sheet(isPresented: $showIncentiveSheet) {
            WorkOfferIncentiveEditor(offer: offer) {
                onChanged()
                dismiss()
            }
        }
        .alert("Delete work offer?", isPresented: $showDeleteConfirmation) {
            Button("Delete offer", role: .destructive) { Task { await managementAction("delete") } }
            Button("Keep offer", role: .cancel) { }
        } message: {
            Text("This removes the offer and releases its unaccepted reservations. The job, tasks, and service stops remain available.")
        }
        .sheet(isPresented: $showEditSheet) {
            EditWorkOfferView(offer: offer, termsLocked: termsLocked, dataService: dataService) {
                onChanged()
                dismiss()
            }
        }
        .sheet(isPresented: $showScheduleSheet) {
            ScheduleAcceptedWorkOfferView(
                companyId: companyId,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
                offer: offer,
                jobTasks: jobTasks,
                dataService: dataService,
                onScheduled: {
                    onChanged()
                    dismiss()
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Work Offer", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Cancel Offer", isPresented: $showCancelConfirmation) {
            TextField("Reason", text: $cancelReason)

            Button("Cancel Offer", role: .destructive) {
                Task {
                    await cancelOffer()
                }
            }

            Button("Keep Offer", role: .cancel) { }
        } message: {
            Text("Add a note explaining why this work offer was cancelled.")
        }
        .alert("Return accepted work?", isPresented: $showReturnConfirmation) {
            TextField("Reason (required)", text: $returnReason)
            Button("Return work", role: .destructive) {
                guard let claim = returningClaim else { return }
                Task { await returnWork(claim) }
            }
            .disabled(returnReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Keep work", role: .cancel) { returningClaim = nil }
        } message: {
            Text("Unstarted work will become unassigned for the office to arrange replacement. The accepted offer and return reason stay in history.")
        }
    }

    private var offerHero: some View {
        VStack(spacing: 0) {
            WorkOfferAreaMap(offer: offer, dataService: dataService, height: 220, showsPanel: false)
            VStack(alignment: .leading, spacing: 16) {
                WorkOfferCardHeading(offer: offer)
                if offer.isRouteOffer {
                    WorkOfferRouteSummaryView(offer: offer, summary: routeSummary ?? offer.routeSummary)
                } else {
                    WorkOfferSummaryFact(title: "Estimated time", value: "\(offer.estimatedMinutes) min", systemImage: "clock")
                }
                WorkOfferAttribution(offer: offer)
            }
            .padding(16)
        }
        .workOfferSurface(tint: offer.offerType == .internalBoard ? .poolGreen : .poolBlue)
    }

    private var statusSection: some View {
        TechnicianWorkPanel(title: "Offer", systemImage: "info.circle") {
            HStack {
                Label(offer.offerType.title, systemImage: offer.offerType.systemImage)
                Spacer()
                Text(offer.status.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            WorkOfferDetailRow(title: "Title", value: offer.title)
            WorkOfferDetailRow(title: "Job", value: "\(offer.jobInternalId) • \(offer.jobName)")
            WorkOfferDetailRow(title: "Customer", value: offer.customerName)

            if !offer.serviceLocationName.isEmpty {
                WorkOfferDetailRow(title: "Location", value: offer.serviceLocationName)
            }

            WorkOfferDetailRow(title: "Created", value: WorkOfferDetailDateFormatter.shortDateTime(offer.createdAt))
            WorkOfferDetailRow(title: "Created By", value: offer.createdByUserName)
            ForEach((offer.claims ?? []).filter { $0.withdrawnAt != nil }) { claim in
                WorkOfferDetailRow(title: "Returned by", value: claim.workerName)
                WorkOfferDetailRow(title: "Return reason", value: claim.withdrawalReason ?? "")
            }
        }
    }

    @ViewBuilder
    private var receiverSection: some View {
        TechnicianWorkPanel(title: "Receiver", systemImage: "person.crop.circle") {
            switch offer.offerType {
            case .directUser:
                WorkOfferDetailRow(
                    title: "Offered To",
                    value: offer.offeredToUserName.isEmpty ? "Missing Worker" : offer.offeredToUserName
                )

            case .internalBoard:
                WorkOfferDetailRow(title: "Board", value: offer.boardVisibility.title)
                WorkOfferDetailRow(title: "Board Post ID", value: offer.boardPostId.isEmpty ? "-" : offer.boardPostId)

            case .externalCompany:
                WorkOfferDetailRow(
                    title: "External Company",
                    value: offer.externalCompanyName.isEmpty ? "Not Set" : offer.externalCompanyName
                )
            }

            if !offer.acceptedByUserName.isEmpty {
                WorkOfferDetailRow(title: "Accepted By", value: offer.acceptedByUserName)
            }

            if let acceptedAt = offer.acceptedAt {
                WorkOfferDetailRow(title: "Accepted", value: WorkOfferDetailDateFormatter.shortDateTime(acceptedAt))
            }
        }
    }

    private var scopeSection: some View {
        TechnicianWorkPanel(title: "The work", systemImage: "checklist") {
            if let scope = detailedScope ?? offer.scopeSnapshot {
                scopeRows("Route stops", items: scope.stops)
                scopeRows("Tasks", items: scope.tasks)
                scopeRows("Services", items: scope.services)
                scopeRows("Products", items: scope.products)
                if scope.tasks.isEmpty && scope.services.isEmpty && scope.products.isEmpty && scope.stops.isEmpty {
                    Text(offer.workPurpose == "diagnostic" ? "Diagnostic / estimate visit." : "No work items are attached to this offer.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            } else if !selectedTasks.isEmpty {
                ForEach(selectedTasks) { WorkOfferTaskRow(task: $0) }
            } else {
                Text(offer.workPurpose == "diagnostic" ? "Diagnostic / estimate visit." : "Detailed scope is unavailable.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func scopeRows(_ title: String, items: [WorkOfferScopeItem]) -> some View {
        if !items.isEmpty { Text(title).font(.subheadline.weight(.semibold)) }
        ForEach(items) { item in
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.subheadline)
                if let description = item.description, !description.isEmpty { Text(description).font(.caption).foregroundStyle(.secondary) }
                if let quantity = item.quantity { Text("Quantity: \(quantity.formatted())").font(.caption).foregroundStyle(.secondary) }
                if let status = item.status { Text(status).font(.caption).foregroundStyle(.secondary) }
            }
        }
    }

    private var paySection: some View {
        TechnicianWorkPanel(title: "Pay Snapshot", systemImage: "dollarsign.circle") {
            WorkOfferDetailRow(title: "Pay Source", value: offer.paySource.title)
            WorkOfferDetailRow(title: "Estimated Labor", value: WorkOfferDetailMoneyFormatter.money(offer.estimatedLaborCents))
            WorkOfferDetailRow(title: "Selected Task Labor", value: WorkOfferDetailMoneyFormatter.money(selectedTaskTotalCents))
            WorkOfferDetailRow(title: "Estimated Minutes", value: "\(offer.estimatedMinutes)")

            if offer.offeredAmountCents > 0 {
                WorkOfferDetailRow(title: "Offered Amount", value: WorkOfferDetailMoneyFormatter.money(offer.offeredAmountCents))
            }
        }
    }

    private var scheduleSection: some View {
        TechnicianWorkPanel(title: "Timeline", systemImage: "calendar") {
            if let proposedStartDate = offer.proposedStartDate {
                WorkOfferDetailRow(
                    title: "Available From",
                    value: WorkOfferDetailDateFormatter.shortDateTime(proposedStartDate)
                )
            } else {
                WorkOfferDetailRow(title: "Available From", value: "-")
            }

            if let completionDeadline = offer.completionDeadlineAt ?? offer.proposedEndDate {
                WorkOfferDetailRow(
                    title: "Complete By",
                    value: WorkOfferDetailDateFormatter.shortDateTime(completionDeadline)
                )
            } else {
                WorkOfferDetailRow(title: "Complete By", value: "No deadline set")
            }

            if let timelineNotes = offer.timelineNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
               !timelineNotes.isEmpty {
                WorkOfferDetailRow(title: "Timeline Notes", value: timelineNotes)
            }

            if !offer.serviceStopId.isEmpty {
                TechnicianWorkDetailRow(
                    title: "Service Stop",
                    value: offer.serviceStopInternalId.isEmpty ? offer.serviceStopId : offer.serviceStopInternalId
                )
            } else if offer.status == .accepted {
                Text("Accepted. Waiting for admin to schedule the service stop.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
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
                    WorkOfferNoteBlock(title: "Description", value: offer.description)
                }

                if !offer.adminNotes.isEmpty {
                    WorkOfferNoteBlock(title: "Admin Notes", value: offer.adminNotes)
                }

                if !offer.workerNotes.isEmpty {
                    WorkOfferNoteBlock(title: "Worker Notes", value: offer.workerNotes)
                }

                if !offer.rejectionReason.isEmpty {
                    WorkOfferNoteBlock(title: "Rejection / Cancel Reason", value: offer.rejectionReason)
                }
            }
        }
    }

    private var actionsSection: some View {
        TechnicianWorkPanel(title: "Actions", systemImage: "bolt") {
            if canEditOffer {
                Button { showEditSheet = true } label: {
                    Label("Edit offer", systemImage: "pencil")
                }
                .disabled(isSaving)
            }
            if canIncentivize && !incentiveLocked {
                Button { showIncentiveSheet = true } label: {
                    Label("Edit incentive", systemImage: "gift")
                }
                .disabled(isSaving)
            }
            if canApprove && offer.status == .pendingApproval {
                Button { Task { await managementAction("approve") } } label: {
                    Label("Approve offer", systemImage: "checkmark.seal")
                }
                .disabled(isSaving)
            }
            if canApprove {
                ForEach((offer.claims ?? []).filter { $0.status == "Acceptance Pending Approval" }) { claim in
                    Button { Task { await managementAction("approve", extra: ["claimId": claim.id]) } } label: {
                        Label("Approve \(claim.workerName)’s acceptance", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .disabled(isSaving)
                }
            }
            if canMarkScheduled {
                Button {
                    showScheduleSheet = true
                } label: {
                    Label("Create Scheduled Service Stop", systemImage: "calendar.badge.plus")
                }
                .disabled(isSaving)
            }

            if canDeleteOffer {
                Button(role: .destructive) { showDeleteConfirmation = true } label: {
                    Label("Delete offer", systemImage: "trash")
                }
                .disabled(isSaving)
            }

            if canCancel {
                Button(role: .destructive) {
                    showCancelConfirmation = true
                } label: {
                    Label("Cancel Offer", systemImage: "xmark.circle")
                }
                .disabled(isSaving)
            }
            ForEach((offer.claims ?? []).filter { ["Accepted", "Scheduled"].contains($0.status) && (canManageReturns || $0.workerId == currentUserId) }) { claim in
                Button(role: .destructive) {
                    returnReason = ""
                    returningClaim = claim
                    showReturnConfirmation = true
                } label: {
                    Label("Return \(claim.workerName)'s work", systemImage: "arrow.uturn.backward")
                }
                .disabled(isSaving)
            }
            Text("Technicians accept offers. Service stops record the scheduled and completed work.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .slate))
    }

    private func managementAction(_ action: String, extra: [String: Any] = [:]) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        var payload = extra
        payload["revision"] = offer.revision ?? 1
        do {
            _ = try await FunctionsManager.shared.manageWork(companyId: companyId, offerId: offer.id, action: action, extra: payload)
            onChanged()
            dismiss()
        } catch {
            alertMessage = "Could not update this offer. \(error.userFacingMessage)"
            showAlert = true
        }
    }

    private func cancelOffer() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.cancelWorkOffer(
                companyId: companyId,
                workOfferId: offer.id,
                reason: cancelReason
            )

            onChanged()
            dismiss()
        } catch {
            alertMessage = "Could not cancel offer. \(error.userFacingMessage)"
            showAlert = true
        }
    }

    private func returnWork(_ claim: WorkOfferClaim) async {
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await FunctionsManager.shared.manageWork(companyId: companyId, offerId: offer.id, action: "withdraw", extra: ["claimId": claim.id, "reason": returnReason])
            onChanged()
            dismiss()
        } catch {
            alertMessage = "Could not return work. \(error.userFacingMessage)"
            showAlert = true
        }
    }
}

struct WorkOfferTimingFields: View {
    @Binding var includeAvailableFrom: Bool
    @Binding var availableFrom: Date
    @Binding var includeDeadline: Bool
    @Binding var deadline: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Include available-from time", isOn: $includeAvailableFrom)
            if includeAvailableFrom {
                DatePicker("Available from", selection: $availableFrom, displayedComponents: [.date, .hourAndMinute])
            }
            Toggle("Set completion deadline", isOn: $includeDeadline)
            if includeDeadline {
                DatePicker("Complete by", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
            }
            if !WorkOfferTiming.isValid(availableFrom: includeAvailableFrom ? availableFrom : nil, deadline: includeDeadline ? deadline : nil) {
                Label("The deadline must follow the available-from time.", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(Color.poolRed)
            }
        }
        .tint(.poolBlue)
    }
}

struct WorkOfferIncentiveEditor: View {
    @Environment(\.dismiss) private var dismiss
    let offer: WorkOffer
    let onSaved: () -> Void

    @State private var type: String
    @State private var amountCents: Int
    @State private var percentage: Double
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage = ""

    init(offer: WorkOffer, onSaved: @escaping () -> Void) {
        self.offer = offer
        self.onSaved = onSaved
        _type = State(initialValue: offer.incentive?.type ?? "none")
        _amountCents = State(initialValue: offer.incentive?.amountCents ?? 0)
        _percentage = State(initialValue: offer.incentive?.percentage ?? 0)
        _notes = State(initialValue: offer.incentive?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Offer") { Text(offer.title) }
                Section("Incentive") {
                    Picker("Type", selection: $type) {
                        Text("None").tag("none")
                        Text("Flat amount").tag("flat")
                        Text("Percentage").tag("percentage")
                    }
                    if type == "flat" { MoneyTextField(cents: $amountCents) }
                    if type == "percentage" {
                        LabeledContent("Percentage") {
                            TextField("Percent", value: $percentage, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    if type != "none" { TextField("Incentive notes", text: $notes, axis: .vertical) }
                }
                if !errorMessage.isEmpty {
                    Text(errorMessage).font(.subheadline).foregroundStyle(Color.poolRed)
                }
                Section {
                    Button { Task { await save() } } label: {
                        HStack {
                            if isSaving { ProgressView() }
                            Text(isSaving ? "Saving…" : "Save incentive")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .disabled(isSaving || amountCents < 0 || !percentage.isFinite || percentage < 0)
                }
            }
            .disabled(isSaving)
            .navigationTitle("Offer Incentive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func save() async {
        guard !isSaving, amountCents >= 0, percentage.isFinite, percentage >= 0 else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await FunctionsManager.shared.manageWork(
                companyId: offer.companyId, offerId: offer.id, action: "incentive",
                extra: ["revision": offer.revision ?? 1, "incentive": [
                    "type": type, "amountCents": type == "flat" ? amountCents : 0,
                    "percentage": type == "percentage" ? percentage : 0,
                    "notes": type == "none" ? "" : notes
                ]]
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Could not save the incentive. \(error.userFacingMessage)"
        }
    }
}

struct EditWorkOfferView: View {
    @Environment(\.dismiss) private var dismiss

    let offer: WorkOffer
    let termsLocked: Bool
    let dataService: any ProductionDataServiceProtocol
    let onSaved: () -> Void

    @State private var title: String
    @State private var notes: String
    @State private var adminNotes: String
    @State private var offerType: WorkOfferType
    @State private var workerId: String
    @State private var boardVisibility: WorkOfferBoardVisibility
    @State private var paySource: WorkOfferPaySource
    @State private var offeredAmountCents: Int
    @State private var estimatedMinutes: Int
    @State private var selectedTaskIds: Set<String>
    @State private var workers: [CompanyUser] = []
    @State private var tasks: [JobTask] = []
    @State private var reservedTaskIds = Set<String>()
    @State private var isLoadingOptions = false
    @State private var optionsError = ""
    @State private var includeAvailableFrom: Bool
    @State private var availableFrom: Date
    @State private var includeDeadline: Bool
    @State private var deadline: Date
    @State private var timelineNotes: String
    @State private var allowsSelfScheduling: Bool
    @State private var isSaving = false
    @State private var errorMessage = ""

    init(offer: WorkOffer, termsLocked: Bool, dataService: any ProductionDataServiceProtocol, onSaved: @escaping () -> Void) {
        self.offer = offer
        self.termsLocked = termsLocked
        self.dataService = dataService
        self.onSaved = onSaved
        let completion = offer.completionDeadlineAt ?? offer.proposedEndDate
        _title = State(initialValue: offer.title)
        _notes = State(initialValue: offer.description)
        _adminNotes = State(initialValue: offer.adminNotes)
        _offerType = State(initialValue: offer.offerType)
        _workerId = State(initialValue: offer.offeredToUserId)
        _boardVisibility = State(initialValue: offer.boardVisibility)
        _paySource = State(initialValue: offer.paySource)
        _offeredAmountCents = State(initialValue: offer.offeredAmountCents)
        _estimatedMinutes = State(initialValue: offer.estimatedMinutes)
        _selectedTaskIds = State(initialValue: Set(offer.jobTaskIds))
        _includeAvailableFrom = State(initialValue: offer.proposedStartDate != nil)
        _availableFrom = State(initialValue: offer.proposedStartDate ?? Date())
        _includeDeadline = State(initialValue: completion != nil)
        _deadline = State(initialValue: completion ?? Calendar.current.date(byAdding: .day, value: 1, to: max(offer.proposedStartDate ?? Date(), Date())) ?? Date())
        _timelineNotes = State(initialValue: offer.timelineNotes ?? "")
        _allowsSelfScheduling = State(initialValue: offer.allowsTechnicianSelfScheduling == true)
    }

    private var assignmentChanged: Bool {
        offerType != offer.offerType || workerId != offer.offeredToUserId || boardVisibility != offer.boardVisibility
    }
    private var scopeChanged: Bool { selectedTaskIds != Set(offer.jobTaskIds) }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isLoadingOptions else { return false }
        if termsLocked { return true }
        guard WorkOfferTiming.isValid(availableFrom: includeAvailableFrom ? availableFrom : nil, deadline: includeDeadline ? deadline : nil),
              estimatedMinutes >= 0, offeredAmountCents >= 0 else { return false }
        if offerType == .directUser && workerId.isEmpty { return false }
        if assignmentChanged && offerType == .directUser && !workers.contains(where: { $0.userId == workerId }) { return false }
        if (assignmentChanged || scopeChanged) && !optionsError.isEmpty { return false }
        if !offer.jobId.isEmpty && offer.workPurpose != "diagnostic" && selectedTaskIds.isEmpty { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    WorkOfferCardHeading(offer: offer)
                        .padding(16)
                        .workOfferSurface()
                    TechnicianWorkPanel(title: "Offer details", systemImage: "doc.text") {
                        TextField("Offer title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        TextField("Notes for worker", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                        TextField("Internal management notes", text: $adminNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                    }
                    assignmentSection
                    if !offer.jobId.isEmpty && offer.workPurpose != "diagnostic" { scopeSection }
                    paySection
                    TechnicianWorkPanel(title: "Deadline & scheduling", systemImage: "calendar") {
                        WorkOfferTimingFields(
                            includeAvailableFrom: $includeAvailableFrom, availableFrom: $availableFrom,
                            includeDeadline: $includeDeadline, deadline: $deadline
                        )
                        .disabled(termsLocked)
                        TextField("Timeline notes", text: $timelineNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                            .disabled(termsLocked)
                        Toggle("Allow technician self-scheduling", isOn: $allowsSelfScheduling)
                            .disabled(termsLocked)
                        if termsLocked {
                            Text("Accepted or closed offer terms are fixed. You can still update the title and worker notes.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !optionsError.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(optionsError).font(.caption).foregroundStyle(Color.poolRed)
                            Button("Reload assignment and scope") { Task { await loadOptions() } }
                        }
                        .technicianPanel()
                    }
                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(Color.poolRed)
                            .technicianPanel()
                    }
                }
                .padding(14)
                .disabled(isSaving)
            }
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Edit Work Offer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button { Task { await save() } } label: {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "Saving…" : "Save changes")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
                .buttonBorderShape(.capsule)
                .tint(.poolBlue)
                .disabled(isSaving || !canSave)
                .padding(16)
                .background(Color(.systemBackground))
            }
            .interactiveDismissDisabled(isSaving)
            .task { await loadOptions() }
            .onChange(of: selectedTaskIds) { ids in
                guard !termsLocked, !isLoadingOptions else { return }
                estimatedMinutes = tasks.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.estimatedTime }
            }
        }
    }

    private var assignmentSection: some View {
        TechnicianWorkPanel(title: "Assignment", systemImage: "person.2") {
            Picker("Offer type", selection: $offerType) {
                Text("Direct technician").tag(WorkOfferType.directUser)
                Text("Work board").tag(WorkOfferType.internalBoard)
                if offerType == .externalCompany { Text("External company").tag(WorkOfferType.externalCompany) }
            }
            if offerType == .directUser {
                Picker("Technician", selection: $workerId) {
                    Text("Select technician").tag("")
                    if !offer.offeredToUserId.isEmpty && !workers.contains(where: { $0.userId == offer.offeredToUserId }) {
                        Text(offer.offeredToUserName.isEmpty ? "Current technician" : offer.offeredToUserName).tag(offer.offeredToUserId)
                    }
                    ForEach(workers) { Text($0.userName).tag($0.userId) }
                }
            } else if offerType == .internalBoard {
                Picker("Visibility", selection: $boardVisibility) {
                    ForEach(WorkOfferBoardVisibility.allCases) { Text($0.title).tag($0) }
                }
                if let boardNames = offer.boardNames, !boardNames.isEmpty {
                    Text("Boards: " + boardNames.joined(separator: ", "))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if isLoadingOptions { ProgressView("Loading technicians…") }
        }
        .disabled(termsLocked || isLoadingOptions || !optionsError.isEmpty)
    }

    private var scopeSection: some View {
        TechnicianWorkPanel(title: "Offered tasks", systemImage: "checklist") {
            if isLoadingOptions { ProgressView("Loading tasks…") }
            ForEach(tasks) { task in
                let reserved = reservedTaskIds.contains(task.id) && !offer.jobTaskIds.contains(task.id)
                Toggle(isOn: Binding(get: { selectedTaskIds.contains(task.id) }, set: { selected in
                    if selected { selectedTaskIds.insert(task.id) } else { selectedTaskIds.remove(task.id) }
                })) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name).font(.subheadline.weight(.semibold))
                        Text(reserved ? "Already included in another offer" : "\(task.estimatedTime) min")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .disabled(reserved)
            }
        }
        .disabled(termsLocked || isLoadingOptions || !optionsError.isEmpty)
    }

    private var paySection: some View {
        TechnicianWorkPanel(title: "Pay & duration", systemImage: "dollarsign.circle") {
            Picker("Pay source", selection: $paySource) {
                ForEach(WorkOfferPaySource.allCases) { Text($0.title).tag($0) }
            }
            if paySource == .offeredAmount { MoneyTextField(cents: $offeredAmountCents) }
            LabeledContent("Estimated minutes") {
                TextField("Minutes", value: $estimatedMinutes, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 88)
            }
        }
        .disabled(termsLocked)
    }

    private func loadOptions() async {
        guard !termsLocked else { return }
        isLoadingOptions = true
        optionsError = ""
        defer { isLoadingOptions = false }
        do {
            async let loadedWorkers = dataService.getAllCompanyUsersByStatus(companyId: offer.companyId, status: "Active")
            if !offer.jobId.isEmpty {
                async let loadedTasks = dataService.getJobTasks(companyId: offer.companyId, jobId: offer.jobId)
                async let otherOffers = dataService.fetchWorkOffers(companyId: offer.companyId, jobId: offer.jobId)
                tasks = try await loadedTasks
                reservedTaskIds = Set(try await otherOffers.filter {
                    $0.id != offer.id && ![WorkOfferStatus.rejected, .cancelled, .expired].contains($0.status)
                }.flatMap(\.jobTaskIds))
            }
            workers = try await loadedWorkers
        } catch {
            optionsError = "Assignment and scope could not load. Existing assignment and tasks will be kept until you reload. \(error.userFacingMessage)"
        }
    }

    private func save() async {
        guard !isSaving, canSave else { return }
        isSaving = true
        errorMessage = ""
        defer { isSaving = false }
        var changes: [String: Any] = ["title": title.trimmingCharacters(in: .whitespacesAndNewlines), "description": notes, "adminNotes": adminNotes]
        if !termsLocked {
            changes.merge(WorkOfferTiming.changes(
                availableFrom: includeAvailableFrom ? availableFrom : nil,
                deadline: includeDeadline ? deadline : nil,
                notes: timelineNotes
            )) { _, updated in updated }
            changes["allowsTechnicianSelfScheduling"] = allowsSelfScheduling
            changes["estimatedMinutes"] = estimatedMinutes
            changes["paySource"] = paySource.rawValue
            changes["offeredAmountCents"] = paySource == .offeredAmount ? offeredAmountCents : 0
            if scopeChanged { changes["jobTaskIds"] = Array(selectedTaskIds).sorted() }
            if assignmentChanged {
                let worker = workers.first { $0.userId == workerId }
                changes["offerType"] = offerType.rawValue
                changes["postedToBoard"] = offerType == .internalBoard
                changes["boardVisibility"] = boardVisibility.rawValue
                changes["offeredToUserId"] = offerType == .directUser ? workerId : ""
                changes["offeredToUserName"] = offerType == .directUser ? (worker?.userName ?? offer.offeredToUserName) : ""
                changes["offeredToWorkerType"] = (offerType == .directUser ? (worker?.workerType ?? offer.offeredToWorkerType) : .notAssigned).rawValue
            }
        }
        do {
            _ = try await FunctionsManager.shared.manageWork(
                companyId: offer.companyId, offerId: offer.id, action: "update",
                extra: ["revision": offer.revision ?? 1, "changes": changes]
            )
            onSaved()
            dismiss()
        } catch {
            errorMessage = "Could not update this offer. \(error.userFacingMessage)"
        }
    }
}

// MARK: - Detail Components

struct WorkOfferTaskRow: View {
    var task: JobTask

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(task.name)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(WorkOfferDetailMoneyFormatter.money(task.contractedRate))
                    .font(.subheadline.weight(.semibold))
            }

            HStack {
                Text(task.type.rawValue)
                Spacer()
                Text("\(task.estimatedTime) min")
                Spacer()
                Text(task.status.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !task.workerName.isEmpty {
                Text("Assigned: \(task.workerName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct WorkOfferDetailRow: View {
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

struct WorkOfferNoteBlock: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
        }
    }
}

enum WorkOfferDetailMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

enum WorkOfferDetailDateFormatter {
    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
