//
//  ScheduleAcceptedWorkOfferView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/26.
//

import SwiftUI

struct ScheduleAcceptedWorkOfferView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager: MasterDataManager

    let companyId: String
    let currentUserId: String
    let currentUserName: String
    let offer: WorkOffer
    let jobTasks: [JobTask]
    let dataService: any ProductionDataServiceProtocol
    let onScheduled: () -> Void

    @State private var serviceDate: Date
    @State private var selectedCompanyServiceStopType: CompanyServiceStopType?
    @State private var serviceStopTypeUseCase: ServiceStopTypeUseCase = .jobVisit

    @State private var job: Job?
    @State private var serviceLocation: ServiceLocation?

    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(
        companyId: String,
        currentUserId: String,
        currentUserName: String,
        offer: WorkOffer,
        jobTasks: [JobTask],
        dataService: any ProductionDataServiceProtocol,
        onScheduled: @escaping () -> Void
    ) {
        self.companyId = companyId
        self.currentUserId = currentUserId
        self.currentUserName = currentUserName
        self.offer = offer
        self.jobTasks = jobTasks
        self.dataService = dataService
        self.onScheduled = onScheduled

        _serviceDate = State(initialValue: offer.proposedStartDate ?? Date())
    }

    private var selectedTasks: [JobTask] {
        jobTasks.filter { offer.jobTaskIds.contains($0.id) }
    }

    private var estimatedMinutes: Int {
        selectedTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    var body: some View {
        NavigationStack {
            Form {
                summarySection
                scheduleSection
                serviceStopTypeSection
                taskSection
                saveSection
            }
            .navigationTitle("Schedule Offer")
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
            .alert("Schedule Offer", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var summarySection: some View {
        Section("Offer") {
            WorkOfferDetailRow(title: "Title", value: offer.title)
            WorkOfferDetailRow(title: "Worker", value: resolvedWorkerName)
            WorkOfferDetailRow(title: "Customer", value: offer.customerName)
            WorkOfferDetailRow(title: "Estimated Time", value: "\(estimatedMinutes) min")
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
                subtitle: "Payroll uses this to determine the base work type for this scheduled stop."
            )
        } header: {
            Text("Service Stop Type")
        }
    }

    private var taskSection: some View {
        Section {
            if selectedTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("This offer has no matching job tasks.")
                )
            } else {
                ForEach(selectedTasks) { task in
                    WorkOfferTaskRow(task: task)
                }
            }
        } header: {
            Text("Tasks")
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
            Text("This creates a service stop, copies the selected job tasks into the service stop, assigns them to the accepted worker, and marks the offer scheduled.")
        }
    }

    private var resolvedWorkerName: String {
        if !offer.acceptedByUserName.isEmpty {
            return offer.acceptedByUserName
        }

        return offer.offeredToUserName
    }

    private func load() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            job = try await dataService.getWorkOrderById(
                companyId: companyId,
                workOrderId: offer.jobId
            )

            serviceLocation = try await dataService.getServiceLocationById(
                companyId: companyId,
                locationId: offer.serviceLocationId
            )

            if let rawValue = offer.serviceStopTypeUseCaseRawValue,
               let useCase = ServiceStopTypeUseCase(rawValue: rawValue) {
                serviceStopTypeUseCase = useCase
            }

            if let typeId = offer.serviceStopTypeId,
               !typeId.isEmpty {
                selectedCompanyServiceStopType = try? await dataService.fetchCompanyServiceStopType(
                    companyId: companyId,
                    serviceStopTypeId: typeId
                )
            }
        } catch {
            alertMessage = "Could not load job details. \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func schedule() async {
        guard let job else {
            alertMessage = "Missing job."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let typeFields: ServiceStopTypeFields

            if let selectedCompanyServiceStopType {
                typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                    selectedType: selectedCompanyServiceStopType,
                    useCase: serviceStopTypeUseCase
                )
            } else if let typeName = offer.serviceStopTypeName,
                      !typeName.isEmpty {
                typeFields = ServiceStopTypeFields(
                    typeId: offer.serviceStopTypeId ?? "",
                    type: typeName,
                    typeImage: offer.serviceStopTypeImage ?? ""
                )
            } else {
                typeFields = ServiceStopTypeResolver.serviceStopTypeFields(
                    selectedType: nil,
                    useCase: serviceStopTypeUseCase
                )
            }

            let service = WorkOfferSchedulingService(
                dataService: dataService
            )

            try await service.createServiceStopFromAcceptedOffer(
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
            alertMessage = "Could not schedule work offer. \(error.localizedDescription)"
            showAlert = true
        }
    }
}
