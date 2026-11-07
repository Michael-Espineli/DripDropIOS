//
//  TechnicianSelfScheduleWorkOfferView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//

import SwiftUI

struct WorkOfferScheduleContent<Tasks: View>: View {
    let offer: WorkOffer
    let dataService: any ProductionDataServiceProtocol
    let workerName: String
    let estimatedMinutes: Int
    @Binding var serviceDate: Date
    let isLoading: Bool
    let isSaving: Bool
    let canSchedule: Bool
    let scheduleAction: () -> Void
    @ViewBuilder let tasks: () -> Tasks

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 0) {
                    WorkOfferAreaMap(offer: offer, dataService: dataService, height: 160, showsPanel: false)
                    VStack(alignment: .leading, spacing: 16) {
                        WorkOfferCardHeading(offer: offer)
                        HStack(alignment: .top, spacing: 12) {
                            WorkOfferSummaryFact(title: "Assigned technician", value: workerName, systemImage: "person.crop.circle")
                            WorkOfferSummaryFact(title: "Estimated time", value: "\(estimatedMinutes) min", systemImage: "clock")
                        }
                    }
                    .padding(16)
                }
                .workOfferSurface()

                TechnicianWorkPanel(title: "Service time", systemImage: "calendar") {
                    Text("Choose when this work will take place.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DatePicker("Service date", selection: $serviceDate, displayedComponents: [.date, .hourAndMinute])
                        .tint(.poolBlue)
                        .disabled(isSaving)

                    if let start = offer.proposedStartDate {
                        TechnicianWorkDetailRow(title: "Available from", value: TechnicianWorkDateFormatter.shortDateTime(start))
                    }
                    if let deadline = offer.completionDeadlineAt ?? offer.proposedEndDate {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Complete by").font(.caption.weight(.semibold))
                                Text(TechnicianWorkDateFormatter.shortDateTime(deadline))
                                    .font(.subheadline.weight(.semibold))
                            }
                        } icon: {
                            Image(systemName: "flag.checkered").foregroundStyle(Color.poolBlue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                    if !offer.containsServiceDate(serviceDate) {
                        Label("Choose a time within the offer’s available dates and deadline.", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(Color.poolRed)
                    }
                }

                TechnicianWorkPanel(title: "Accepted pay type", systemImage: "dollarsign.circle") {
                    Text(offer.serviceStopTypeName ?? (offer.workPurpose == "diagnostic" ? "Job Estimate" : "Job Visit"))
                        .font(.subheadline.weight(.semibold))
                    Text("Your accepted pay type and rate carry over to the scheduled work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TechnicianWorkPanel(title: "Scope of work", systemImage: "checklist") {
                    if isLoading {
                        ProgressView("Loading work details…")
                            .frame(maxWidth: .infinity)
                    } else {
                        tasks()
                    }
                }
            }
            .padding(14)
        }
        .background(Color.listColor.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                Button(action: scheduleAction) {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().tint(.white) }
                        Label(isSaving ? "Scheduling…" : "Schedule work", systemImage: "calendar.badge.plus")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(WorkspaceOutlinedButtonStyle(tone: .blue))
                .buttonBorderShape(.capsule)
                .tint(.poolGreen)
                .disabled(!canSchedule || isLoading || isSaving || !offer.containsServiceDate(serviceDate))
                Text("Creates a service stop for the accepted work and moves it to Scheduled.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
    }
}

struct WorkOfferScheduleTasks: View {
    let tasks: [JobTask]
    let isDiagnostic: Bool

    var body: some View {
        if tasks.isEmpty {
            Text(isDiagnostic ? "Diagnostic / estimate visit. Execution tasks are added after the assessment." : "This offer has no matching job tasks.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            ForEach(tasks) { task in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(Color.poolBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name).font(.subheadline.weight(.semibold))
                        Text("\(task.type.rawValue) · \(task.estimatedTime) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct TechnicianSelfScheduleWorkOfferView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let companyUser: CompanyUser
    let offer: WorkOffer
    let dataService: any ProductionDataServiceProtocol
    let onScheduled: () -> Void

    @State private var serviceDate: Date
    @State private var job: Job?
    @State private var jobTasks: [JobTask] = []
    @State private var serviceLocation: ServiceLocation?
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        companyId: String,
        companyUser: CompanyUser,
        offer: WorkOffer,
        dataService: any ProductionDataServiceProtocol,
        onScheduled: @escaping () -> Void
    ) {
        self.companyId = companyId
        self.companyUser = companyUser
        self.offer = offer
        self.dataService = dataService
        self.onScheduled = onScheduled

        _serviceDate = State(initialValue: max(offer.proposedStartDate ?? Date(), Date()))
    }

    private var selectedTasks: [JobTask] {
        jobTasks.filter { offer.jobTaskIds.contains($0.id) }
    }

    var body: some View {
        WorkOfferScheduleContent(
            offer: offer, dataService: dataService, workerName: companyUser.userName,
            estimatedMinutes: offer.estimatedMinutes, serviceDate: $serviceDate,
            isLoading: isLoading, isSaving: isSaving,
            canSchedule: job != nil && (!selectedTasks.isEmpty || offer.workPurpose == "diagnostic"),
            scheduleAction: { Task { await schedule() } }
        ) {
            WorkOfferScheduleTasks(tasks: selectedTasks, isDiagnostic: offer.workPurpose == "diagnostic")
        }
        .navigationTitle("Schedule Work")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isSaving)
        .task { await load() }
        .alert("Schedule Work", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let loadedJob = try await dataService.getWorkOrderById(
                companyId: companyId,
                workOrderId: offer.jobId
            )

            let loadedTasks = try await dataService.getJobTasks(
                companyId: companyId,
                jobId: offer.jobId
            )

            let loadedLocation = loadedJob.serviceLocationId.isEmpty ? nil : try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: loadedJob.serviceLocationId
            )

            self.job = loadedJob
            self.jobTasks = loadedTasks
            self.serviceLocation = loadedLocation
        } catch {
            alertMessage = "Could not load offer details. \(error.userFacingMessage)"
            showAlert = true
        }
    }

    private func schedule() async {
        guard !isSaving, offer.containsServiceDate(serviceDate) else { return }
        guard offer.allowsTechnicianSelfScheduling == true else {
            alertMessage = "This offer does not allow technician self-scheduling."
            showAlert = true
            return
        }

        guard let job else {
            alertMessage = "Missing job."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                selectedType: selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase
            )

            let schedulingService = WorkOfferSchedulingService(
                dataService: dataService
            )

            try await schedulingService.createServiceStopFromAcceptedOffer(
                companyId: companyId,
                companyName: masterDataManager.currentCompany?.name ?? "",
                job: job,
                offer: offer,
                allJobTasks: jobTasks,
                serviceLocation: serviceLocation,
                serviceStopTypeFields: typeFields,
                serviceDate: serviceDate
            )

            onScheduled()
            dismiss()
        } catch {
            alertMessage = "Could not schedule work. \(error.userFacingMessage)"
            showAlert = true
        }
    }
}
