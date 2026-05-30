//
//  TechnicianSelfScheduleWorkOfferView.swift
//  DripDrop
//

import SwiftUI

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

        _serviceDate = State(initialValue: offer.proposedStartDate ?? Date())
    }

    private var selectedTasks: [JobTask] {
        jobTasks.filter { offer.jobTaskIds.contains($0.id) }
    }

    var body: some View {
        Form {
            offerSection
            scheduleSection
            serviceStopTypeSection
            taskSection
            saveSection
        }
        .navigationTitle("Schedule Work")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .alert("Schedule Work", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private var offerSection: some View {
        Section("Offer") {
            TechnicianWorkDetailRow(title: "Title", value: offer.title)
            TechnicianWorkDetailRow(title: "Customer", value: offer.customerName)
            TechnicianWorkDetailRow(title: "Worker", value: companyUser.userName)
            TechnicianWorkDetailRow(title: "Estimated Time", value: "\(offer.estimatedMinutes) min")
        }
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker(
                "Service Date",
                selection: $serviceDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var serviceStopTypeSection: some View {
        Section {
            CompanyServiceStopTypePickerView(
                companyId: companyId,
                dataService: dataService,
                selectedType: $selectedCompanyServiceStopType,
                useCase: serviceStopTypeUseCase,
                title: "Service Stop Type",
                subtitle: "This controls the work type used for route/payroll rules."
            )
        } header: {
            Text("Service Stop Type")
        }
    }

    private var taskSection: some View {
        Section("Tasks") {
            if selectedTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("This offer has no matching job tasks.")
                )
            } else {
                ForEach(selectedTasks) { task in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name)
                            .font(.subheadline.weight(.semibold))

                        Text("\(task.type.rawValue) • \(task.estimatedTime) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task {
                    await schedule()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Create Service Stop", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
            }
            .disabled(isSaving || isLoading || job == nil || selectedTasks.isEmpty)
        } footer: {
            Text("This will create a service stop assigned to you and move the offer to Scheduled.")
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

            let loadedLocation = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: offer.serviceLocationId
            )

            self.job = loadedJob
            self.jobTasks = loadedTasks
            self.serviceLocation = loadedLocation
        } catch {
            alertMessage = "Could not load offer details. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func schedule() async {
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
            alertMessage = "Could not schedule work. \(error.localizedDescription)"
            showAlert = true
        }
    }
}