//
//  WorkOfferDetailView.swift
//  DripDrop
//

import SwiftUI

struct WorkOfferDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let offer: WorkOffer
    let jobTasks: [JobTask]
    let dataService: any ProductionDataServiceProtocol
    let onChanged: () -> Void

    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    @State private var showCancelConfirmation: Bool = false
    @State private var cancelReason: String = ""

    private var selectedTasks: [JobTask] {
        jobTasks.filter { offer.jobTaskIds.contains($0.id) }
    }

    private var selectedTaskTotalCents: Int {
        selectedTasks.reduce(0) { $0 + $1.contractedRate }
    }

    private var selectedTaskMinutes: Int {
        selectedTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    private var canMarkAccepted: Bool {
        offer.status == .sent ||
        offer.status == .posted ||
        offer.status == .viewed
    }

    private var canCancel: Bool {
        offer.status == .draft ||
        offer.status == .sent ||
        offer.status == .posted ||
        offer.status == .viewed ||
        offer.status == .accepted
    }

    private var canMarkScheduled: Bool {
        offer.status == .accepted
    }

    private var canMarkCompleted: Bool {
        offer.status == .scheduled ||
        offer.status == .inProgress
    }

    var body: some View {
        List {
            statusSection
            receiverSection
            scopeSection
            paySection
            scheduleSection
            notesSection
            actionsSection
        }
        .navigationTitle("Work Offer")
        .navigationBarTitleDisplayMode(.inline)
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

            WorkOfferDetailRow(title: "Title", value: offer.title)
            WorkOfferDetailRow(title: "Job", value: "\(offer.jobInternalId) • \(offer.jobName)")
            WorkOfferDetailRow(title: "Customer", value: offer.customerName)

            if !offer.serviceLocationName.isEmpty {
                WorkOfferDetailRow(title: "Location", value: offer.serviceLocationName)
            }

            WorkOfferDetailRow(title: "Created", value: WorkOfferDetailDateFormatter.shortDateTime(offer.createdAt))
            WorkOfferDetailRow(title: "Created By", value: offer.createdByUserName)
        }
    }

    @ViewBuilder
    private var receiverSection: some View {
        Section("Receiver") {
            switch offer.offerType {
            case .directUser:
                WorkOfferDetailRow(
                    title: "Offered To",
                    value: offer.offeredToUserName.isEmpty ? "Missing Worker" : offer.offeredToUserName
                )

                WorkOfferDetailRow(
                    title: "Worker Type",
                    value: offer.offeredToWorkerType.rawValue.isEmpty ? "-" : offer.offeredToWorkerType.rawValue
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
        Section {
            if selectedTasks.isEmpty {
                ContentUnavailableView(
                    "No Matching Tasks",
                    systemImage: "checklist",
                    description: Text("This offer references tasks that were not found on the current job.")
                )
            } else {
                ForEach(selectedTasks) { task in
                    WorkOfferTaskRow(task: task)
                }
            }
        } header: {
            Text("Scope")
        } footer: {
            Text("These are the job tasks included in this work offer.")
        }
    }

    private var paySection: some View {
        Section("Pay Snapshot") {
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
        Section("Schedule") {
            if let proposedStartDate = offer.proposedStartDate {
                WorkOfferDetailRow(
                    title: "Proposed Start",
                    value: WorkOfferDetailDateFormatter.shortDateTime(proposedStartDate)
                )
            } else {
                WorkOfferDetailRow(title: "Proposed Start", value: "-")
            }

            if let proposedEndDate = offer.proposedEndDate {
                WorkOfferDetailRow(
                    title: "Proposed End",
                    value: WorkOfferDetailDateFormatter.shortDateTime(proposedEndDate)
                )
            }

            if !offer.serviceStopId.isEmpty {
                WorkOfferDetailRow(title: "Service Stop", value: offer.serviceStopInternalId.isEmpty ? offer.serviceStopId : offer.serviceStopInternalId)
            } else {
                Text("No service stop is linked yet.")
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
            Section("Notes") {
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
        Section {
            if canMarkAccepted {
                Button {
                    Task {
                        await markAccepted()
                    }
                } label: {
                    Label("Mark Accepted", systemImage: "checkmark.circle")
                }
                .disabled(isSaving)
            }

            if canMarkScheduled {
                Button {
                    Task {
                        await updateStatus(.scheduled)
                    }
                } label: {
                    Label("Mark Scheduled", systemImage: "calendar.badge.checkmark")
                }
                .disabled(isSaving)
            }

            if canMarkCompleted {
                Button {
                    Task {
                        await updateStatus(.completed)
                    }
                } label: {
                    Label("Mark Completed", systemImage: "checkmark.seal")
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
        } header: {
            Text("Actions")
        } footer: {
            Text("This only changes the work offer status. Scheduling and payroll still happen through service stops and completed work.")
        }
    }

    private func markAccepted() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let acceptedId: String
            let acceptedName: String

            if offer.offerType == .directUser {
                acceptedId = offer.offeredToUserId
                acceptedName = offer.offeredToUserName
            } else {
                acceptedId = currentUserId
                acceptedName = currentUserName
            }

            try await dataService.acceptWorkOffer(
                companyId: companyId,
                workOfferId: offer.id,
                acceptedByUserId: acceptedId,
                acceptedByUserName: acceptedName
            )

            onChanged()
            dismiss()
        } catch {
            alertMessage = "Could not accept offer. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func updateStatus(_ status: WorkOfferStatus) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await dataService.updateWorkOfferStatus(
                companyId: companyId,
                workOfferId: offer.id,
                status: status
            )

            onChanged()
            dismiss()
        } catch {
            alertMessage = "Could not update offer. \(error.localizedDescription)"
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
            alertMessage = "Could not cancel offer. \(error.localizedDescription)"
            showAlert = true
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