    //
    //  CustomerUpcomingWork.swift
    //  ThePoolApp
    //
    //  Aesthetic-only refresh:
    //  - system grouped background
    //  - “page header” feel
    //  - section cards with soft shadow + rounded corners
    //  - consistent header controls (icon buttons)
    //  - better spacing + typography
    //

    import SwiftUI

    struct CustomerUpcomingWork: View {
        @EnvironmentObject var masterDataManager: MasterDataManager
        @EnvironmentObject var dataService: ProductionDataService

        @EnvironmentObject var VM: CustomerProfileViewModel
        @EnvironmentObject var customerListVM: CustomerListViewModel

        private var customer: Customer? {
            customerListVM.customers.first { $0.id == customerId }
        }

        @State var customerId: String

        init(dataService: any ProductionDataServiceProtocol, customerId: String) {
            _customerId = State(wrappedValue: customerId)
        }

        @State var editRSS: Bool = false
        @State var addRSS: Bool = false
        @State var addRepairRequest: Bool = false
        @State var addJob: Bool = false
        @State var addItem: Bool = false
        @State var addServiceStop: Bool = false

        @State var alertMessage: String = ""
        @State var showAlert: Bool = false
        @State var showDeleteConfirmation: Bool = false
        @State var rssID: String = ""
        @State var selectedJob: Job? = nil

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        pageHeader

                        repairRequests
                        jobs
                        recurringServiceStops
                        serviceStops
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
            .task {
                startLiveUpcomingWork()
            }
            .onAppear {
                startLiveUpcomingWork()

                Task {
                    await refreshUpcomingWorkBackup()
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Alert"),
                    message: Text("\(alertMessage)"),
                    primaryButton: .destructive(Text("Delete")) {
                        if rssID != "" {
                            Task {
                                if let company = masterDataManager.currentCompany {
                                    do {
                                        try await VM.deleteRecurringServiceStop(
                                            companyId: company.id,
                                            RecurringServiceStopId: rssID
                                        )

                                        rssID = ""

                                        try await VM.reloadRecurringServiceStops(
                                            companyId: company.id,
                                            customerId: customerId
                                        )
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            }
        }

        private func startLiveUpcomingWork() {
            guard let company = masterDataManager.currentCompany else { return }

            VM.startUpcomingWorkListeners(
                companyId: company.id,
                customerId: customerId
            )
        }

        private func refreshUpcomingWorkBackup() async {
            guard let company = masterDataManager.currentCompany else { return }

            do {
                try await VM.reloadRecurringServiceStops(
                    companyId: company.id,
                    customerId: customerId
                )

                try await VM.reloadRepairRequests(
                    companyId: company.id,
                    customerId: customerId
                )

                try await VM.reloadJobs(
                    companyId: company.id,
                    customerId: customerId
                )
            } catch {
                print("[CustomerUpcomingWork][refreshUpcomingWorkBackup] Error: \(error)")
            }
        }
    }

    // MARK: - Header

    extension CustomerUpcomingWork {
        private var pageHeader: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text("Upcoming Work")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)

                Text("Repairs, jobs, recurring stops, and scheduled service stops.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 2)
        }
    }

    // MARK: - Sections

    extension CustomerUpcomingWork {

        var recurringServiceStops: some View {
            SectionCard(
                title: "Recurring Service Stops",
                leadingButton: SectionIconButton(systemName: "square.and.pencil") {
                    self.editRSS.toggle()
                },
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addRSS.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.recurringServiceStops.isEmpty {
                        Text("No recurring service stops found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.recurringServiceStops) { RSS in
                            NavigationLink(
                                value: Route.recurringServiceStopDetail(
                                    dataService: dataService,
                                    recurringServiceStop: RSS
                                )
                            ) {
                                RecurringServiceStopSmallCardView(recurringServiceStop: RSS)
                                    .id(rssCardRefreshId(RSS))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .sheet(isPresented: $addRSS, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                NewSingleRecurringServiceStop(dataService: dataService, customerId: customerId)
            }
        }

        var repairRequests: some View {
            SectionCard(
                title: "Repair Requests",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addRepairRequest.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.repairRequest.isEmpty {
                        Text("No repair requests found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.repairRequest) { repair in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.repairRequest(repairRequest: repair, dataService: dataService)) {
                                    RepairRequestCardView(repairRequest: repair)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .jobs
                                    masterDataManager.selectedRepairRequest = repair
                                }) {
                                    RepairRequestCardView(repairRequest: repair)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $addRepairRequest, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                AddNewRepairRequest(
                    dataService: dataService,
                    isPresented: $addRepairRequest,
                    customer: customer
                )
            }
        }

        var jobs: some View {
            SectionCard(
                title: "Jobs",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addJob.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.jobs.isEmpty {
                        Text("No jobs found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.jobs) { job in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.job(job: job, dataService: dataService)) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    masterDataManager.selectedCategory = .jobs
                                    masterDataManager.selectedJob = job
                                }) {
                                    JobCardView(job: job)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $addJob, onDismiss: {
                Task {
                    await refreshUpcomingWorkBackup()
                }
            }) {
                AddNewJobView(dataService: dataService, customerId: customerId)
            }
        }

        var serviceStops: some View {
            SectionCard(
                title: "Service Stops",
                trailingButton: SectionIconButton(systemName: "plus") {
                    self.addServiceStop.toggle()
                }
            ) {
                VStack(spacing: 12) {
                    if VM.serviceStops.isEmpty {
                        Text("No service stops found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(VM.serviceStops) { ss in
                            NavigationLink(value: Route.serviceStop(serviceStop: ss, dataService: dataService)) {
                                ServiceStopCardViewLarge(serviceStop: ss)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .sheet(isPresented: $addServiceStop, onDismiss: {
                Task {
                    if let company = masterDataManager.currentCompany {
                        do {
                            try await VM.reloadShoppingListItem(
                                companyId: company.id,
                                customerId: customerId
                            )
                        } catch {
                            print(error)
                        }
                    }
                }
            }) {
                AddNewServiceStop(dataService: dataService)
            }
        }

        func rssCardRefreshId(_ rss: RecurringServiceStop) -> String {
            [
                rss.id,
                rss.tech,
                rss.techId,
                rss.day.rawValue,
                rss.frequency.rawValue,
                rss.description,
                String(rss.noEndDate),
                String(rss.endDate?.timeIntervalSince1970 ?? 0)
            ].joined(separator: "_")
        }
    }

    // MARK: - Reusable UI

    private struct SectionCard<Content: View>: View {
        let title: String
        var leadingButton: AnyView? = nil
        var trailingButton: AnyView? = nil
        let content: Content

        init(
            title: String,
            leadingButton: AnyView? = nil,
            trailingButton: AnyView? = nil,
            @ViewBuilder content: () -> Content
        ) {
            self.title = title
            self.leadingButton = leadingButton
            self.trailingButton = trailingButton
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                header
                content
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)
        }

        private var header: some View {
            HStack(spacing: 10) {
                if let leadingButton {
                    leadingButton
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if let trailingButton {
                    trailingButton
                }
            }
            .padding(.bottom, 2)
        }
    }

    private func SectionIconButton(systemName: String, action: @escaping () -> Void) -> AnyView {
        AnyView(
            Button(action: action) {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        )
    }
