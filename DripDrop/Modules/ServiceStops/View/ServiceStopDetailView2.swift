//
//  ServiceStopDetailView 2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/3/26.
//
// For Route
import SwiftUI
import UniformTypeIdentifiers
import WebKit
import MessageUI

struct ServiceStopDetailView2: View {
    init(dataService:any ProductionDataServiceProtocol,serviceStopId:String) {
        _VM = StateObject(wrappedValue: ServiceStopDetailViewModel(dataService: dataService))
        _serviceStopId = State(wrappedValue: serviceStopId)
    }
    @EnvironmentObject var masterDataManager: MasterDataManager
    @EnvironmentObject private var dataService: ProductionDataService
    @EnvironmentObject private var navigationManager : NavigationStateManager
    @EnvironmentObject private var vm: MobileDailyRouteDisplayViewModel
    
    @StateObject private var VM : ServiceStopDetailViewModel
    

    @State var serviceStopId: String
    @State var opStatus:ServiceStopOperationStatus?
    @State private var isSaving = false
    @State var showSkipReason:Bool = false
    @State var skipReason:String = ""
    @State private var finishErrorMessage:String? = nil
    @State private var statusActionInProgress: ServiceStopOperationStatus? = nil
    @State var expandScreenSelector:Bool = false
    @State var selectedScreen:serviceStopScreen = .waterDetails
    @State var stopData:StopData = StopData(
        id: "",
        date: Date(),
        serviceStopId: "",
        readings: [],
        dosages: [],
        observation: [],
        bodyOfWaterId: "",
        customerId: "",
        serviceLocationId: "",
        userId: "",
        equipmentMeasurements: []
    )
    @State var dropDropImages:[DripDropImage] = []
    @State var title:String = ""

 
//Recap Variables
    @State var showPhotoSelectionOptions:Bool = false
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var images:[UIImage] = []
    @State private var showTesterStripCamera = false
    @State private var testerStripScanImage: UIImage? = nil
    @State private var testerStripScanToken: UUID? = nil
    @State private var testerStripCameraError: DripDropPicker.CameraErrorType? = nil
    @State private var showTesterStripCameraAlert = false
    @State private var selectedTab = "Water"
    @State private var serviceNotes = ""
    @State private var lastSavedServiceNotes = ""
    @State private var serviceNotesSaveMessage: String? = nil
    @State private var showCustomerNotes = false
    @State private var customerNotes: [CustomerNote] = []
    @State private var isLoadingCustomerNotes = false
    @State private var customerNotesErrorMessage: String? = nil
    @State private var lastViewedCustomerNotesAt: Date = .distantPast
    @State private var showServiceStopInfo = false
    @State private var followUpItems: [ServiceStopFollowUpItem] = []
    @State private var isLoadingFollowUps = false
    @State private var followUpErrorMessage: String? = nil
    @State private var linkedJobCompletionFlow: FieldJobCompletionFlow? = nil
    @State private var shouldNavigateBackAfterLinkedJobFlowDismiss = false
    @State private var isCompletingLinkedJob = false
    
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }

    private var isFinishingOrSkippingStop: Bool {
        statusActionInProgress == .finished || statusActionInProgress == .skipped
    }

    private var currentContinuationGate: ServiceStopContinuationGate? {
        guard let serviceStop else { return nil }
        return continuationGate(for: serviceStop)
    }

    private var equipmentAttentionCount: Int {
        VM.listOfEquipment.filter { equipment in
            equipment.currentlyNeedsMaintenanceFollowUp ||
            equipment.status == .needsRepair ||
            equipment.status == .needsMaintenance ||
            equipment.status == .nonoperational
        }.count
    }

    private var followUpCount: Int {
        followUpItems.count
    }

    private var unfinishedTaskCount: Int {
        VM.taskList.filter { $0.status != .finished }.count
    }

    private var newCustomerNotesCount: Int {
        customerNotes.filter { $0.displayDate > lastViewedCustomerNotesAt }.count
    }

    private var unresolvedFieldCustomerNotesCount: Int {
        customerNotes.filter {
            $0.isVisibleFromFieldStop &&
            !($0.resolved ?? false)
        }.count
    }

    private var customerNotesSeenStorageKey: String? {
        guard let companyId = masterDataManager.currentCompany?.id,
              let serviceStop else {
            return nil
        }

        let userId = masterDataManager.user?.id ?? "shared"
        return "ServiceStopCustomerNotesLastViewed.\(companyId).\(serviceStop.customerId).\(userId)"
    }

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack(spacing: 0){
                if let stop = serviceStop {
                    fieldCategoryHeader(for: stop)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .padding(.bottom, 6)

                    if VM.isLoadingInitialDetails {
                        detailLoadingBanner(for: stop)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }

                    TabView(selection: $selectedTab) {
                        categoryTabs(for: stop)
                     }
                } else {
                    serviceStopLoadingState
                }
            }

            if isFinishingOrSkippingStop {
                finishOrSkipLoadingOverlay
                    .transition(.opacity)
                    .zIndex(1)
            }
        
        }
        .navigationTitle(title)
        .navigationBarBackButtonHidden(isFinishingOrSkippingStop)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                serviceStopInfoToolbarButton
                customerNotesToolbarButton
            }
        }
        .interactiveDismissDisabled(isFinishingOrSkippingStop)
        .environmentObject(VM)
        .sheet(isPresented: $showServiceStopInfo) {
            NavigationStack {
                ServiceStopInfoView(dataService: dataService, serviceStopId: serviceStopId)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showServiceStopInfo = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCustomerNotes) {
            ServiceStopCustomerNotesSheet(
                dataService: dataService,
                serviceStop: serviceStop,
                notes: $customerNotes,
                isLoading: $isLoadingCustomerNotes,
                errorMessage: $customerNotesErrorMessage,
                onRefresh: {
                    await loadCustomerNotes()
                    await MainActor.run {
                        markCustomerNotesViewed()
                    }
                }
            )
        }
        .fullScreenCover(isPresented: $showTesterStripCamera) {
            TesterStripCameraView(selectedImage: $testerStripScanImage) {
                testerStripScanToken = UUID()
            }
                .ignoresSafeArea()
        }
        .onAppear {
            if let stop = serviceStop {
                
                opStatus = stop.operationStatus
                selectedTab = defaultTab(for: stop)
                serviceNotes = stop.serviceNotes ?? ""
                lastSavedServiceNotes = stop.serviceNotes ?? ""
            }
        }
        .onChange(of: serviceStop?.id, perform: { _ in
            if let stop = serviceStop {
                opStatus = stop.operationStatus
                selectedTab = defaultTab(for: stop)
                title = stop.customerName
                serviceNotes = stop.serviceNotes ?? ""
                lastSavedServiceNotes = stop.serviceNotes ?? ""
            }
        })
        .task(id: serviceStop?.id) {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user, let serviceStop {
                title = serviceStop.customerName
                serviceNotes = serviceStop.serviceNotes ?? ""
                lastSavedServiceNotes = serviceStop.serviceNotes ?? ""
                do {
                    try await VM.onInitalLoad(companyId: company.id,  serviceStop: serviceStop, userId: user.id)
                    if let bodyOfWater = VM.selectedBOW {
                        stopData = VM.serviceLocationStopData.first(where: {
                            $0.serviceStopId == serviceStop.id &&
                            $0.serviceLocationId == serviceStop.serviceLocationId &&
                            $0.bodyOfWaterId == bodyOfWater.id
                        }) ?? StopData(
                            id: UUID().uuidString,
                            date: serviceStop.serviceDate,
                            serviceStopId: serviceStop.id,
                            readings: [],
                            dosages: [],
                            observation: [],
                            bodyOfWaterId: bodyOfWater.id,
                            customerId: serviceStop.customerId,
                            serviceLocationId: serviceStop.serviceLocationId,
                            userId: user.id,
                            equipmentMeasurements: []
                        )
                    } else {
                        print("[ServiceStopDetailView][task] No Bodies Of Water")
                    }
                } catch {
                    print("[ServiceStopDetailView][task]Error Getting Service stop")
                    print(error)
                }
            }
        }
        .task(id: serviceStop?.customerId) {
            await loadCustomerNotes()
            await loadFollowUps()
        }
        .onChange(of: stopData, perform: { datum in
            Task{
                print("[ServiceStopDetailView][onChange:stopData]Change in Stop Data")
                if let comapny = masterDataManager.currentCompany, let serviceStop {
                    do {
                        try await VM.updateStopData(companyId: comapny.id,serviceStop: serviceStop, stopData: stopData)
                        print("[ServiceStopDetailView][onChange:stopData] Updated")
                    } catch {
                        print("[ServiceStopDetailView][onChange:stopData] Failed to update Stop Data")
                        print(error)
                    }
                }
            }
        })
        .onChange(of: serviceNotes, perform: { notes in
            if notes != lastSavedServiceNotes {
                serviceNotesSaveMessage = nil
            }
        })
        .onChange(of: VM.selectedDripDropPhotos, perform: { photo in
            if let currentCompany = masterDataManager.currentCompany, let serviceStop {
//                if serviceStop.otherCompany && serviceStop.contractedCompanyId != "" {
//                    VM.updatePhotoUrl(companyId: serviceStop.contractedCompanyId, serviceStopId: serviceStop.id)
//                }
                VM.updatePhotoUrl(companyId: currentCompany.id, serviceStopId: serviceStop.id)

            }
            
        })
        .alert("Provide skip reason", isPresented: $showSkipReason) {
            TextField("reason", text: $skipReason)
            Button("OK", action: submitSkipReason)
                .disabled(isFinishingOrSkippingStop)
            Button("Cancel", role: .cancel) {
                skipReason = ""
            }
            .disabled(isFinishingOrSkippingStop)
        } message: {
            Text("Reason will be saved with the stop.")
                .font(.footnote)
        }
        .alert(
            "Camera Unavailable",
            isPresented: $showTesterStripCameraAlert,
            presenting: testerStripCameraError
        ) { error in
            error.button
        } message: { error in
            Text(error.message)
        }
        .alert(
            "Unable To Finish",
            isPresented: Binding(
                get: { finishErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        finishErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                finishErrorMessage = nil
            }
        } message: {
            Text(finishErrorMessage ?? "")
        }
        .sheet(
            isPresented: Binding(
                get: { linkedJobCompletionFlow != nil },
                set: { isPresented in
                    if !isPresented {
                        linkedJobCompletionFlow = nil
                    }
                }
            ),
            onDismiss: {
                guard shouldNavigateBackAfterLinkedJobFlowDismiss else { return }
                shouldNavigateBackAfterLinkedJobFlowDismiss = false
                navigationManager.goBack()
            }
        ) {
            Group {
                switch linkedJobCompletionFlow {
                case .decision(let prompt):
                    LinkedJobCompletionDecisionSheet(
                        prompt: prompt,
                        isFinishing: isCompletingLinkedJob,
                        onFinishJob: {
                            completeLinkedJob(prompt)
                        },
                        onScheduleAnotherStop: {
                            linkedJobCompletionFlow = .schedule(prompt)
                        },
                        onKeepJobOpen: {
                            linkedJobCompletionFlow = nil
                        }
                    )
                case .schedule(let prompt):
                    ScheduleServiceStopView(
                        dataService: dataService,
                        companyId: prompt.companyId,
                        job: prompt.job,
                        customerId: prompt.job.customerId,
                        customerName: prompt.job.customerName,
                        serviceLocationId: prompt.job.serviceLocationId,
                        description: prompt.job.description,
                        jobTaskList: prompt.jobTasks,
                        plannedServiceStops: prompt.plannedServiceStops,
                        prefilledJobTaskIds: prompt.prefilledJobTaskIds,
                        handoffSourceServiceStop: prompt.serviceStop,
                        serviceStopTypeUseCase: .jobVisit
                    )
                case .none:
                    EmptyView()
                }
            }
            .presentationDetents([.medium, .large])
            .interactiveDismissDisabled(isCompletingLinkedJob)
        }
    }
    func submitSkipReason() {
        guard !isFinishingOrSkippingStop else { return }
        guard let serviceStop else { return }

        let reason = skipReason
        skipReason = ""
        markSkipped(serviceStop, reason: reason)
    }

    private var customerNotesToolbarButton: some View {
        Button {
            showCustomerNotes = true
            markCustomerNotesViewed()
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "text.bubble")
                    .font(.body.weight(.semibold))
                    .frame(width: 30, height: 30)

                if unresolvedFieldCustomerNotesCount > 0 {
                    Text(unresolvedFieldCustomerNotesCount > 9 ? "9+" : "\(unresolvedFieldCustomerNotesCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.poolRed, in: Capsule())
                        .offset(x: 8, y: -6)
                }
            }
        }
        .accessibilityLabel("\(unresolvedFieldCustomerNotesCount) unresolved customer notes")
        .disabled(isFinishingOrSkippingStop)
    }

    private var serviceStopInfoToolbarButton: some View {
        Button {
            showServiceStopInfo = true
        } label: {
            Image(systemName: "info.circle")
                .font(.body.weight(.semibold))
                .frame(width: 30, height: 30)
        }
        .accessibilityLabel("Service stop info")
        .disabled(isFinishingOrSkippingStop)
    }

    @MainActor
    private func loadCustomerNotes() async {
        syncCustomerNotesViewedDate()

        guard let companyId = masterDataManager.currentCompany?.id,
              let serviceStop else {
            customerNotes = []
            return
        }

        isLoadingCustomerNotes = true
        customerNotesErrorMessage = nil

        do {
            customerNotes = try await dataService.getCustomerNotes(
                companyId: companyId,
                customerId: serviceStop.customerId,
                visibleFromFieldOnly: true,
                limit: 20
            )
        } catch {
            customerNotesErrorMessage = "Unable to load customer notes."
            print("[ServiceStopDetailView2][loadCustomerNotes] Error: \(error)")
        }

        isLoadingCustomerNotes = false
    }

    @MainActor
    private func loadFollowUps() async {
        guard let companyId = masterDataManager.currentCompany?.id,
              let serviceStop else {
            followUpItems = []
            return
        }

        isLoadingFollowUps = true
        followUpErrorMessage = nil

        do {
            async let jobs = dataService.getAllJobsByCustomer(
                companyId: companyId,
                customerId: serviceStop.customerId
            )
            async let repairRequests = dataService.getRepairRequestsByCustomer(
                companyId: companyId,
                customerId: serviceStop.customerId
            )
            async let partApprovals = dataService.getCustomerPartApprovals(
                companyId: companyId,
                customerId: serviceStop.customerId
            )

            let loadedJobs = try await jobs
            let loadedRepairRequests = try await repairRequests
            let loadedPartApprovals = try await partApprovals

            var nextItems: [ServiceStopFollowUpItem] = []
            nextItems.append(contentsOf: loadedJobs.filter(ServiceStopFollowUpItem.isOpenJob).map { ServiceStopFollowUpItem(job: $0) })
            nextItems.append(contentsOf: loadedRepairRequests.filter(ServiceStopFollowUpItem.isOpenRepairRequest).map { ServiceStopFollowUpItem(repairRequest: $0) })
            nextItems.append(contentsOf: loadedPartApprovals.filter(\.isOpen).map { ServiceStopFollowUpItem(partApproval: $0) })

            followUpItems = nextItems.sorted { $0.sortDate > $1.sortDate }
        } catch {
            followUpErrorMessage = "Unable to load follow-up work."
            print("[ServiceStopDetailView2][loadFollowUps] Error: \(error)")
        }

        isLoadingFollowUps = false
    }

    @MainActor
    private func syncCustomerNotesViewedDate() {
        guard let customerNotesSeenStorageKey else {
            lastViewedCustomerNotesAt = .distantPast
            return
        }

        let timestamp = UserDefaults.standard.double(forKey: customerNotesSeenStorageKey)
        lastViewedCustomerNotesAt = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : .distantPast
    }

    @MainActor
    private func markCustomerNotesViewed() {
        guard let customerNotesSeenStorageKey else { return }

        let viewedAt = Date()
        UserDefaults.standard.set(viewedAt.timeIntervalSince1970, forKey: customerNotesSeenStorageKey)
        lastViewedCustomerNotesAt = viewedAt
    }

    private func openTesterStripCamera() {
        do {
            try DripDropPicker.checkPermissions()
            showTesterStripCamera = true
        } catch let error as DripDropPicker.PickerError {
            testerStripCameraError = DripDropPicker.CameraErrorType(error: error)
            showTesterStripCameraAlert = true
        } catch {
            testerStripCameraError = DripDropPicker.CameraErrorType(error: .unavailable)
            showTesterStripCameraAlert = true
        }
    }

    private func save(companyId:String?, _ stop: ServiceStop) {
//        guard let newStatus = opStatus else { return }
        guard let companyId else { return }
        guard let opStatus else { return }
        isSaving = true

        vm.updateServiceStopStatus(
            companyId: companyId,
            stopId: stop.id,
            status: opStatus
        )
        print("[ServiceStopDetailView2][updateServiceStopStatus]")
        isSaving = false
        
    }
}

private extension ServiceStopDetailView2 {
    var serviceStopLoadingState: some View {
        Group {
            if vm.serviceStopList.isEmpty {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 12) {
                            ProgressView()
                                .controlSize(.regular)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Loading Service Stop")
                                    .font(.headline.weight(.semibold))

                                Text("Getting bodies of water, stop data, and tasks.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }

                        VStack(spacing: 10) {
                            detailLoadingRow(width: 210)
                            detailLoadingRow(width: 168)
                            detailLoadingRow(width: 190)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(.separator).opacity(0.25), lineWidth: 1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .padding(.top, 18)
            } else {
                ContentUnavailableView(
                    "Service Stop Unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This stop is no longer in the current route.")
                )
            }
        }
    }

    func detailLoadingBanner(for stop: ServiceStop) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ProgressView()
                .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text("Loading Service Stop Details")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)

                Text(detailLoadingStatusText(for: stop))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.poolBlue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.poolBlue.opacity(0.18), lineWidth: 1)
        }
    }

    func detailLoadingStatusText(for stop: ServiceStop) -> String {
        switch stop.resolvedCategory {
        case .route:
            return "Getting bodies of water, stop data, and tasks."
        case .job:
            return "Getting linked job tasks and stop records."
        case .jobEstimate:
            return "Getting plan details and task records."
        case .serviceAgreementEstimate:
            return "Getting survey details and field records."
        case .customerRelationship:
            return "Getting tasks and follow-up records."
        }
    }

    func detailLoadingRow(width: CGFloat) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.secondary.opacity(0.16))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 7) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(width: width, height: 10)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: max(96, width - 52), height: 8)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.listColor.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func fieldCategoryHeader(for stop: ServiceStop) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Label(stop.resolvedCategory.title, systemImage: stop.resolvedCategory.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            if !stop.type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(stop.type)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func defaultTab(for stop: ServiceStop) -> String {
        switch stop.resolvedCategory {
        case .route:
            return "Water"
        case .serviceAgreementEstimate:
            return "Survey"
        case .jobEstimate:
            return "Create Plan"
        case .job, .customerRelationship:
            return "Tasks"
        }
    }

    @ViewBuilder
    func categoryTabs(for stop: ServiceStop) -> some View {
        switch stop.resolvedCategory {
        case .route:
            waterTab
            taskTab
            followUpTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .job:
            taskTab
            followUpTab(for: stop)
            jobCommentsTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .jobEstimate:
            createPlanTab(for: stop)
            taskTab
            followUpTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .serviceAgreementEstimate:
            serviceAgreementSurveyTab(for: stop)
            serviceAgreementWorkflowTab(for: stop)
            followUpTab(for: stop)
            finishTab
        case .customerRelationship:
            taskTab
            followUpTab(for: stop)
            finishTab
        }
    }

    func followUpTab(for stop: ServiceStop) -> some View {
        ServiceStopFollowUpView(
            dataService: dataService,
            serviceStop: stop,
            items: followUpItems,
            isLoading: isLoadingFollowUps,
            errorMessage: followUpErrorMessage,
            onRefresh: {
                await loadFollowUps()
            }
        )
            .tabItem {
                Image(systemName: "list.bullet.clipboard")
                Text("Follow Up")
            }
            .badge(followUpCount)
            .tag("Follow Up")
    }

    var taskTab: some View {
        ServiceStopTaskView(
            dataService: dataService,
            taskList: $VM.taskList,
            serviceStopId: serviceStopId,
            isLoadingTasks: VM.isLoadingTasks
        )
            .tabItem {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("Tasks")
            }
            .badge(unfinishedTaskCount)
            .tag("Tasks")
    }

    func jobCommentsTab(for stop: ServiceStop) -> some View {
        ServiceStopJobCommentsView(dataService: dataService, serviceStop: stop)
            .tabItem {
                Image(systemName: "text.bubble")
                Text("Comments")
            }
            .tag("Comments")
    }

    func createPlanTab(for stop: ServiceStop) -> some View {
        ServiceStopEstimatePlanView(dataService: dataService, serviceStop: stop)
            .tabItem {
                Image(systemName: "list.clipboard")
                Text("Create Plan")
            }
            .tag("Create Plan")
    }

    var waterTab: some View {
        ServiceStopUtilityView(
            stopData: $stopData,
            serviceStopId: serviceStopId,
            testerStripScanImage: $testerStripScanImage,
            testerStripScanToken: testerStripScanToken,
            onScanTesterStrip: openTesterStripCamera
        )
            .tabItem {
                Image(systemName: "spigot.fill")
                Text("Water")
            }
            .tag("Water")
    }

    func equipmentTab(for stop: ServiceStop) -> some View {
        ServiceStopEquipmentView(serviceStop: stop, stopData: $stopData)
            .tabItem {
                Image(systemName: "wrench.and.screwdriver.fill")
                Text("Equipment")
            }
            .badge(equipmentAttentionCount)
            .tag("Equipment")
    }

    func serviceAgreementSurveyTab(for stop: ServiceStop) -> some View {
        ServiceLocationStartUpViewInField(
            dataService: dataService,
            customerId: stop.customerId,
            serviceLocationId: stop.serviceLocationId,
            serviceStop: stop,
            serviceLocation: VM.location,
            onOpenServiceAgreementWorkflow: {
                selectedTab = "Agreement"
            }
        )
        .tabItem {
            Image(systemName: "list.clipboard")
            Text("Survey")
        }
        .tag("Survey")
    }

    func serviceAgreementWorkflowTab(for stop: ServiceStop) -> some View {
        ServiceStopAgreementWorkflowView(
            dataService: dataService,
            serviceStop: stop,
            onOpenSurvey: {
                selectedTab = "Survey"
            }
        )
        .tabItem {
            Image(systemName: "doc.text")
            Text("Agreement")
        }
        .tag("Agreement")
    }

    var finishTab: some View {
        recap
            .tabItem {
                Image(systemName: "checkerboard.rectangle")
                Text("Finish")
            }
            .tag("Finish")
    }
}

private enum ServiceStopFollowUpKind: String, CaseIterable {
    case job
    case repairRequest
    case partApproval

    var title: String {
        switch self {
        case .job:
            return "Jobs"
        case .repairRequest:
            return "Repair Requests"
        case .partApproval:
            return "Part Approvals"
        }
    }

    var systemImage: String {
        switch self {
        case .job:
            return "briefcase.fill"
        case .repairRequest:
            return "wrench.and.screwdriver"
        case .partApproval:
            return "checkmark.seal.fill"
        }
    }

    var tint: Color {
        switch self {
        case .job:
            return Color.poolBlue
        case .repairRequest:
            return Color.orange
        case .partApproval:
            return Color.poolGreen
        }
    }
}

private enum FieldJobCompletionFlow {
    case decision(FieldJobCompletionPrompt)
    case schedule(FieldJobCompletionPrompt)
}

private struct FieldJobCompletionPrompt: Identifiable {
    let id = UUID()
    let companyId: String
    let jobId: String
    let job: Job
    let serviceStop: ServiceStop
    let jobLabel: String
    let serviceStopLabel: String
    let userId: String
    let userName: String
    let taskCount: Int
    let unfinishedTaskCount: Int
    let prefilledJobTaskIds: Set<String>
    let jobTasks: [JobTask]
    let plannedServiceStops: [JobPlannedServiceStop]

    var sortedPlannedServiceStops: [JobPlannedServiceStop] {
        plannedServiceStops.sorted { $0.sortOrder < $1.sortOrder }
    }

    var canFinishJob: Bool {
        unfinishedTaskCount == 0
    }
}

private struct LinkedJobCompletionDecisionSheet: View {
    let prompt: FieldJobCompletionPrompt
    let isFinishing: Bool
    let onFinishJob: () -> Void
    let onScheduleAnotherStop: () -> Void
    let onKeepJobOpen: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    plannedStopsSection
                    actionsSection
                }
                .padding(16)
                .padding(.bottom, 12)
            }
            .background(Color.listColor.ignoresSafeArea())
            .navigationTitle("Linked Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onKeepJobOpen()
                    }
                    .disabled(isFinishing)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Service stop finished", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.green)

            Text(prompt.jobLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(prompt.canFinishJob
                ? "All \(prompt.taskCount) linked job task(s) are finished from \(prompt.serviceStopLabel). Choose what happens next."
                : "\(prompt.unfinishedTaskCount) linked job task(s) still need work. Schedule another stop to carry them forward."
            )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var plannedStopsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Planned Stops", systemImage: "calendar.badge.clock")
                .font(.headline)

            if prompt.sortedPlannedServiceStops.isEmpty {
                Text("No planned stops are set up for this job yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(prompt.sortedPlannedServiceStops) { plannedStop in
                        plannedStopRow(plannedStop)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                onScheduleAnotherStop()
            } label: {
                actionLabel(
                    title: "Schedule Another Stop",
                    subtitle: "Use a planned stop or create a blank follow-up.",
                    systemImage: "calendar.badge.plus"
                )
            }
            .buttonStyle(.plain)
            .disabled(isFinishing)

            if prompt.canFinishJob {
                Button {
                    onFinishJob()
                } label: {
                    actionLabel(
                        title: isFinishing ? "Finishing Job..." : "Finish Job",
                        subtitle: "Close the linked job and keep the service stop finished.",
                        systemImage: "checkmark.seal"
                    )
                }
                .buttonStyle(.plain)
                .disabled(isFinishing)
            }

            Button {
                onKeepJobOpen()
            } label: {
                actionLabel(
                    title: "Keep Job Open",
                    subtitle: "Leave the job active and return to the route.",
                    systemImage: "briefcase"
                )
            }
            .buttonStyle(.plain)
            .disabled(isFinishing)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func plannedStopRow(_ plannedStop: JobPlannedServiceStop) -> some View {
        HStack(spacing: 12) {
            Image(systemName: plannedStop.serviceStopTypeImage.isEmpty ? "calendar" : plannedStop.serviceStopTypeImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.accent)
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(plannedStop.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(plannedStop.serviceStopTypeName) - \(plannedStop.estimatedMinutes) min - \(plannedStop.taskIds.count) task(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func actionLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.accent)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ServiceStopFollowUpItem: Identifiable, Hashable {
    let id: String
    let kind: ServiceStopFollowUpKind
    let title: String
    let detail: String
    let status: String
    let sortDate: Date
    let amountCents: Int?
    let partApproval: CustomerPartApproval?

    init(job: Job) {
        let titleText = [job.internalId, job.type]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " - ")

        self.id = "job-\(job.id)"
        self.kind = .job
        self.title = titleText.isEmpty ? "Job" : titleText
        self.detail = job.description
        self.status = job.operationStatus.rawValue
        self.sortDate = job.dateCreated
        self.amountCents = job.rate
        self.partApproval = nil
    }

    init(repairRequest: RepairRequest) {
        self.id = "repair-\(repairRequest.id)"
        self.kind = .repairRequest
        self.title = "Repair Request"
        self.detail = repairRequest.description
        self.status = repairRequest.status.displayName
        self.sortDate = repairRequest.date
        self.amountCents = nil
        self.partApproval = nil
    }

    init(partApproval: CustomerPartApproval) {
        self.id = "part-\(partApproval.id)"
        self.kind = .partApproval
        self.title = partApproval.displayTitle
        self.detail = partApproval.description ?? ""
        self.status = partApproval.displayStatus.capitalized
        self.sortDate = partApproval.displayDate
        self.amountCents = partApproval.displayTotalCents > 0 ? partApproval.displayTotalCents : nil
        self.partApproval = partApproval
    }

    static func isOpenJob(_ job: Job) -> Bool {
        guard job.operationStatus != .finished else { return false }
        return ![.invoiced, .paid, .comped, .expired, .rejected].contains(job.billingStatus)
    }

    static func isOpenRepairRequest(_ repairRequest: RepairRequest) -> Bool {
        ![.resolved, .convertedToJob, .cancelled].contains(repairRequest.status)
    }
}

private struct ServiceStopFollowUpView: View {
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop
    let items: [ServiceStopFollowUpItem]
    let isLoading: Bool
    let errorMessage: String?
    let onRefresh: () async -> Void

    @State private var showPartApprovalSheet = false
    @State private var showShoppingItemSheet = false
    @State private var showRepairRequestSheet = false
    @State private var showJobSheet = false
    @State private var selectedPartApproval: CustomerPartApproval?
    @State private var deliveringPartApprovalIds: Set<String> = []
    @State private var followUpActionMessage: String?

    private var groupedItems: [(kind: ServiceStopFollowUpKind, items: [ServiceStopFollowUpItem])] {
        ServiceStopFollowUpKind.allCases.map { kind in
            (kind, items.filter { $0.kind == kind })
        }
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if let followUpActionMessage {
                        messageCard(
                            followUpActionMessage,
                            systemImage: followUpActionMessage.contains("Unable") ? "exclamationmark.triangle" : "checkmark.circle",
                            tint: followUpActionMessage.contains("Unable") ? Color.poolRed : Color.poolGreen
                        )
                    }

                    if isLoading {
                        loadingCard
                    } else if let errorMessage {
                        messageCard(errorMessage, systemImage: "exclamationmark.triangle")
                    } else if items.isEmpty {
                        emptyCard
                    } else {
                        ForEach(groupedItems, id: \.kind) { group in
                            if !group.items.isEmpty {
                                followUpSection(group.kind, items: group.items)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .refreshable {
            await onRefresh()
        }
        .sheet(isPresented: $showPartApprovalSheet) {
            ServiceStopPartApprovalSheet(
                dataService: dataService,
                serviceStop: serviceStop,
                equipment: nil,
                onCreated: onRefresh
            )
        }
        .sheet(isPresented: $showShoppingItemSheet) {
            ServiceStopShoppingListItemSheet(
                dataService: dataService,
                serviceStop: serviceStop,
                onCreated: onRefresh
            )
        }
        .sheet(isPresented: $showRepairRequestSheet, onDismiss: {
            Task { await onRefresh() }
        }) {
            AddNewRepairRequest(
                dataService: dataService,
                isPresented: $showRepairRequestSheet,
                customer: nil,
                customerId: serviceStop.customerId,
                serviceLocationId: serviceStop.serviceLocationId,
                description: "Follow-up repair request from \(serviceStop.internalId)"
            )
        }
        .sheet(isPresented: $showJobSheet, onDismiss: {
            Task { await onRefresh() }
        }) {
            AddNewJobView(
                dataService: dataService,
                customerId: serviceStop.customerId,
                isTechnicianCreateFlow: true,
                canScheduleServiceStopsForOthers: false
            )
        }
        .sheet(item: $selectedPartApproval) { approval in
            ServiceStopPartApprovalResponseSheet(
                dataService: dataService,
                approval: approval,
                serviceStop: serviceStop,
                onSaved: onRefresh
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 42, height: 42)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Pending & Outstanding Work")
                        .font(.title3.weight(.semibold))

                    Text("Bring up open jobs, repair requests, and part approvals while you are onsite.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                followUpMetric("\(items.count)", title: "Follow Up", systemImage: "exclamationmark.circle")
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                followUpActionButton(
                    title: "Part Approval",
                    systemImage: "checkmark.seal",
                    tint: Color.poolGreen
                ) {
                    showPartApprovalSheet = true
                }

                followUpActionButton(
                    title: "Shopping Item",
                    systemImage: "cart.badge.plus",
                    tint: Color.poolBlue
                ) {
                    showShoppingItemSheet = true
                }

                followUpActionButton(
                    title: "Repair Request",
                    systemImage: "wrench.and.screwdriver",
                    tint: Color.orange
                ) {
                    showRepairRequestSheet = true
                }

                followUpActionButton(
                    title: "Job",
                    systemImage: "briefcase.badge.plus",
                    tint: Color.indigo
                ) {
                    showJobSheet = true
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var loadingCard: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical, 28)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var emptyCard: some View {
        ContentUnavailableView(
            "Nothing Open",
            systemImage: "checkmark.seal",
            description: Text("No jobs, repair requests, or part approvals need customer follow-up.")
        )
        .padding(.vertical, 18)
    }

    private func messageCard(
        _ message: String,
        systemImage: String,
        tint: Color = Color.poolRed
    ) -> some View {
        Label(message, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func followUpSection(_ kind: ServiceStopFollowUpKind, items: [ServiceStopFollowUpItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(kind.title, systemImage: kind.systemImage)
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(items.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(kind.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(kind.tint.opacity(0.12), in: Capsule())
            }

            ForEach(items) { item in
                followUpRow(item)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func followUpRow(_ item: ServiceStopFollowUpItem) -> some View {
        let isPartApproval = item.kind == .partApproval

        return VStack(alignment: .leading, spacing: isPartApproval ? 6 : 10) {
            HStack(alignment: .top, spacing: isPartApproval ? 8 : 10) {
                Image(systemName: item.kind.systemImage)
                    .font((isPartApproval ? Font.caption : Font.body).weight(.semibold))
                    .foregroundStyle(item.kind.tint)
                    .frame(width: isPartApproval ? 24 : 28, height: isPartApproval ? 24 : 28)
                    .background(item.kind.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: isPartApproval ? 2 : 4) {
                    Text(item.title)
                        .font((isPartApproval ? Font.caption : Font.subheadline).weight(.semibold))
                        .lineLimit(isPartApproval ? 1 : 2)

                    Text(item.sortDate.formatted(date: .abbreviated, time: .omitted))
                        .font(isPartApproval ? .caption2 : .caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(item.status)
                    .font((isPartApproval ? Font.caption2 : Font.caption).weight(.semibold))
                    .foregroundStyle(item.kind.tint)
                    .padding(.horizontal, isPartApproval ? 7 : 8)
                    .padding(.vertical, isPartApproval ? 3 : 4)
                    .background(item.kind.tint.opacity(0.12), in: Capsule())
            }

            if !item.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if isPartApproval {
                    Text(item.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(item.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let amountCents = item.amountCents, !isPartApproval {
                Text(DataBaseItemMoneyFormatter.moneyFromCents(amountCents))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if item.kind == .partApproval, let approval = item.partApproval {
                HStack(spacing: 8) {
                    if let amountCents = item.amountCents {
                        Text(DataBaseItemMoneyFormatter.moneyFromCents(amountCents))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Button {
                        selectedPartApproval = approval
                    } label: {
                        Label("Details", systemImage: "info.circle")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Color.poolGreen)

                    if partApprovalCanBeDelivered(approval) {
                        let isDelivering = deliveringPartApprovalIds.contains(approval.id)

                        Button {
                            markPartApprovalDelivered(approval)
                        } label: {
                            HStack(spacing: 5) {
                                if isDelivering {
                                    ProgressView()
                                        .controlSize(.mini)
                                } else {
                                    Image(systemName: "shippingbox")
                                }

                                Text("Delivered")
                            }
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color.poolBlue)
                        .disabled(isDelivering)
                    }
                }
            }
        }
        .padding(isPartApproval ? 9 : 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var targetCompanyId: String? {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return masterDataManager.currentCompany?.id
    }

    private func partApprovalCanBeDelivered(_ approval: CustomerPartApproval) -> Bool {
        guard linkedShoppingListItemId(for: approval) != nil,
              !partApprovalIsDelivered(approval) else {
            return false
        }

        let approvalStatus = normalizedFollowUpStatus(approval.approvalStatus ?? approval.status)
        let fulfillmentStatus = normalizedFollowUpStatus(approval.fulfillmentStatus)

        return approvalStatus == "approved" ||
            approvalStatus == "readytopurchase" ||
            approvalStatus == "purchased" ||
            fulfillmentStatus.contains("approved") ||
            fulfillmentStatus.contains("purchase")
    }

    private func partApprovalIsDelivered(_ approval: CustomerPartApproval) -> Bool {
        let fulfillmentStatus = normalizedFollowUpStatus(approval.fulfillmentStatus)
        let status = normalizedFollowUpStatus(approval.status)

        return [
            "delivered",
            "installed",
            "invoiced",
            "paid",
            "completed",
            "fulfilled"
        ].contains(fulfillmentStatus) || [
            "delivered",
            "installed",
            "invoiced",
            "paid",
            "completed",
            "fulfilled"
        ].contains(status)
    }

    private func linkedShoppingListItemId(for approval: CustomerPartApproval) -> String? {
        if let shoppingListItemId = approval.shoppingListItemId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !shoppingListItemId.isEmpty {
            return shoppingListItemId
        }

        let path = approval.shoppingListPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return path.split(separator: "/").last.map(String.init)
    }

    private func normalizedFollowUpStatus(_ status: String?) -> String {
        (status ?? "")
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private func markPartApprovalDelivered(_ approval: CustomerPartApproval) {
        guard let companyId = targetCompanyId,
              let shoppingListItemId = linkedShoppingListItemId(for: approval) else {
            followUpActionMessage = "Unable to find a linked shopping item for this approval."
            return
        }

        guard !deliveringPartApprovalIds.contains(approval.id) else {
            return
        }

        Task { @MainActor in
            deliveringPartApprovalIds.insert(approval.id)
            defer { deliveringPartApprovalIds.remove(approval.id) }

            let userId = masterDataManager.user?.id ?? ""
            let userName = [
                masterDataManager.user?.firstName ?? "",
                masterDataManager.user?.lastName ?? ""
            ]
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try await dataService.markCustomerPartApprovalDelivered(
                    approval: approval,
                    companyId: companyId,
                    shoppingListItemId: shoppingListItemId,
                    actorUserId: userId,
                    actorUserName: userName
                )
                followUpActionMessage = "Part marked delivered."
                await onRefresh()
            } catch {
                followUpActionMessage = "Unable to mark this part delivered."
                print("[ServiceStopFollowUpView][markPartApprovalDelivered] \(error)")
            }
        }
    }

    private func followUpActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func followUpMetric(_ value: String, title: String, systemImage: String) -> some View {
        Label {
            Text("\(value) \(title)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }
}

private struct ServiceStopPartApprovalResponseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let approval: CustomerPartApproval
    let serviceStop: ServiceStop
    let onSaved: () async -> Void

    @State private var responseNote = ""
    @State private var isSaving = false
    @State private var message: String?

    private var targetCompanyId: String? {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return masterDataManager.currentCompany?.id
    }

    private var statusKey: String {
        normalizedStatus(approval.approvalStatus ?? approval.status ?? "pending")
    }

    private var canRespond: Bool {
        ["pending", "awaitingcustomerapproval", "needscustomerapproval"].contains(statusKey)
    }

    private var historyItems: [CustomerPartApprovalHistoryItem] {
        var items: [CustomerPartApprovalHistoryItem] = []
        let explicitHistory = approval.history ?? []
        let hasRequestedHistory = explicitHistory.contains {
            normalizedStatus($0.action ?? "") == "requested"
        }

        if !hasRequestedHistory, let requestedAt = approval.requestedAt ?? approval.createdAt {
            items.append(
                CustomerPartApprovalHistoryItem(
                    action: "requested",
                    status: "pending",
                    note: approval.description,
                    source: "technicianRequest",
                    sourceLabel: "Approval requested",
                    actorUserId: approval.requestedByUserId,
                    actorUserName: approval.requestedByUserName,
                    actorEmail: nil,
                    createdAt: requestedAt
                )
            )
        }

        if !explicitHistory.isEmpty {
            items.append(contentsOf: explicitHistory)
        } else if let respondedAt = approval.respondedAt {
            let respondedByTechnician = approval.respondedOnBehalfOfCustomer == true ||
                approval.approvedInPerson == true ||
                approval.deniedInPerson == true

            items.append(
                CustomerPartApprovalHistoryItem(
                    action: approval.response ?? approval.displayStatus,
                    status: approval.approvalStatus ?? approval.status,
                    note: approval.responseNote,
                    source: respondedByTechnician ? "technicianOnBehalfOfCustomer" : "customerApp",
                    sourceLabel: respondedByTechnician ? "Technician on behalf of customer" : "Customer through app",
                    actorUserId: approval.respondedByUserId,
                    actorUserName: approval.respondedByUserName,
                    actorEmail: approval.respondedByEmail,
                    createdAt: respondedAt
                )
            )
        }

        return items.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        responseCard
                        historyCard

                        if let message {
                            Text(message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(message.contains("Could") ? Color.poolRed : Color.poolGreen)
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Part Approval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                responseNote = approval.responseNote ?? ""
            }
        }
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
                    .frame(width: 42, height: 42)
                    .background(Color.poolGreen.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(approval.displayTitle)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)

                    Text(approval.customerName ?? serviceStop.customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(displayStatus(approval.displayStatus))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }

            if approval.displayTotalCents > 0 {
                Text(DataBaseItemMoneyFormatter.moneyFromCents(approval.displayTotalCents))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var responseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Customer Conversation", systemImage: "person.2.wave.2")
                .font(.headline.weight(.semibold))

            if canRespond {
                TextEditor(text: $responseNote)
                    .font(.subheadline)
                    .frame(minHeight: 96)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    responseButton(
                        title: "Approved",
                        systemImage: "checkmark.circle.fill",
                        tint: Color.poolGreen
                    ) {
                        Task { await saveResponse(approved: true) }
                    }

                    responseButton(
                        title: "Denied",
                        systemImage: "xmark.circle.fill",
                        tint: Color.poolRed
                    ) {
                        Task { await saveResponse(approved: false) }
                    }
                }
            } else {
                Text("This approval already has a recorded response.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("History", systemImage: "clock.arrow.circlepath")
                .font(.headline.weight(.semibold))

            if historyItems.isEmpty {
                Text("No history recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(historyItems) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(historyTitle(item))
                                .font(.subheadline.weight(.semibold))

                            Spacer()

                            if let createdAt = item.createdAt {
                                Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(item.sourceLabel ?? "Approval activity")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if let actor = item.actorUserName, !actor.isEmpty {
                            Text(actor)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let note = item.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var statusColor: Color {
        switch statusKey {
        case "approved":
            return Color.poolGreen
        case "rejected", "denied", "declined":
            return Color.poolRed
        case "resolved", "installed":
            return Color.poolBlue
        default:
            return Color.orange
        }
    }

    private func responseButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                } else {
                    Image(systemName: systemImage)
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func saveResponse(approved: Bool) async {
        guard let companyId = targetCompanyId else {
            message = "Missing company."
            return
        }

        guard !isSaving else { return }

        isSaving = true
        defer { isSaving = false }

        let userId = masterDataManager.user?.id ?? ""
        let userName = [
            masterDataManager.user?.firstName ?? "",
            masterDataManager.user?.lastName ?? ""
        ]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackNote = approved ? "Approved in person" : "Denied in person"

        do {
            try await dataService.recordCustomerPartApprovalTechnicianResponse(
                approval: approval,
                companyId: companyId,
                approved: approved,
                note: responseNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallbackNote : responseNote,
                actorUserId: userId,
                actorUserName: userName,
                actorEmail: masterDataManager.user?.email ?? "",
                serviceStop: serviceStop
            )
            message = approved ? "Approval recorded." : "Denial recorded."
            await onSaved()
            dismiss()
        } catch {
            message = "Could not save response."
            print("[ServiceStopPartApprovalResponseSheet][saveResponse] \(error)")
        }
    }

    private func historyTitle(_ item: CustomerPartApprovalHistoryItem) -> String {
        let rawTitle = item.status ?? item.action ?? "Activity"
        return displayStatus(rawTitle)
    }

    private func displayStatus(_ status: String) -> String {
        let normalized = normalizedStatus(status)
        switch normalized {
        case "rejected":
            return "Denied"
        case "approved":
            return "Approved"
        case "pending":
            return "Pending"
        default:
            return status
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }
    }

    private func normalizedStatus(_ status: String) -> String {
        status
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }
}

struct ServiceStopShoppingListItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop
    let onCreated: () async -> Void

    @State private var draft = ShoppingListItemDraft()
    @State private var isSaving = false
    @State private var message: String?
    @State private var didConfigure = false

    private var targetCompanyId: String? {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return masterDataManager.currentCompany?.id
    }

    private var canSave: Bool {
        targetCompanyId != nil && draft.canSubmit && !isSaving
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header

                        ShoppingListItemDraftForm(
                            draft: $draft,
                            title: "Shopping Item",
                            showCategoryPicker: false,
                            showDescription: true
                        )
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        if let message {
                            Text(message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(message.contains("Could") ? Color.poolRed : Color.poolGreen)
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Shopping Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveItem() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                configureDraftIfNeeded()
            }
        }
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(serviceStop.customerName, systemImage: "cart.badge.plus")
                .font(.headline.weight(.semibold))

            Text(serviceStop.address.streetAddress)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func configureDraftIfNeeded() {
        guard !didConfigure else { return }
        didConfigure = true
        draft.category = serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .customer : .job
        draft.status = .needToPurchase
    }

    private func saveItem() async {
        guard let companyId = targetCompanyId,
              let user = masterDataManager.user else {
            message = "Missing company or user."
            return
        }

        guard canSave else {
            message = "Select an item and quantity."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let purchaserName = [
            user.firstName,
            user.lastName
        ]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let itemId = "comp_shop_\(UUID().uuidString)"
        let jobId = serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines)
        let category: ShoppingListCategory = jobId.isEmpty ? .customer : .job
        let prepKeys = uniqueNonEmpty([
            jobId.isEmpty ? "" : "job:\(jobId)",
            "customer:\(serviceStop.customerId)",
            serviceStop.serviceLocationId.isEmpty ? "" : "serviceLocation:\(serviceStop.serviceLocationId)",
            "serviceStop:\(serviceStop.id)",
            serviceStop.techId.isEmpty ? "" : "user:\(serviceStop.techId)"
        ])
        let productId = draft.selectedProductId
        let vendorItemId = draft.selectedDataBaseItemId

        let item = ShoppingListItem(
            id: itemId,
            category: category,
            subCategory: draft.subCategory,
            status: .needToPurchase,
            purchaserId: user.id,
            purchaserName: purchaserName.isEmpty ? serviceStop.tech : purchaserName,
            genericItemId: productId ?? draft.selectedDataBaseItem.linkedProductId,
            productId: productId,
            productName: productId == nil ? nil : draft.selectedProduct.productDisplayName,
            name: draft.displayName,
            description: draft.description,
            datePurchased: nil,
            quantity: draft.quantity,
            jobId: jobId.isEmpty ? nil : jobId,
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            userId: serviceStop.techId,
            userName: serviceStop.tech,
            serviceStopId: serviceStop.id,
            serviceStopInternalId: serviceStop.internalId,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationName: serviceStop.address.streetAddress,
            scheduledDate: serviceStop.serviceDate,
            prepKeys: prepKeys,
            needsAction: true,
            actionDate: serviceStop.serviceDate,
            assignedTechIds: uniqueNonEmpty([serviceStop.techId, user.id]),
            dbItemId: draft.subCategory == .dataBase ? vendorItemId : nil,
            dbItemName: draft.subCategory == .dataBase ? draft.selectedDataBaseItem.name : nil,
            itemId: productId ?? (draft.subCategory == .dataBase ? vendorItemId : nil),
            itemType: draft.subCategory.rawValue,
            purchasedItem: nil,
            invoiced: false,
            plannedUnitCostCents: draft.plannedUnitCostCents,
            plannedUnitPriceCents: draft.plannedUnitPriceCents,
            plannedTotalCostCents: draft.plannedTotalCostCents,
            plannedTotalPriceCents: draft.plannedTotalPriceCents
        )

        do {
            try await dataService.addNewShoppingListItem(
                companyId: companyId,
                shoppingListItem: item
            )
            message = "Shopping item created."
            await onCreated()
            dismiss()
        } catch {
            message = "Could not create shopping item."
            print("[ServiceStopShoppingListItemSheet][saveItem] \(error)")
        }
    }

    private func uniqueNonEmpty(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }
}

private enum ServiceStopPartApprovalItemMode: String, CaseIterable, Identifiable {
    case manual = "Manual"
    case database = "Product"

    var id: String { rawValue }
}

struct ServiceStopPartApprovalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop
    let equipment: Equipment?
    let onCreated: () async -> Void

    @State private var customer: Customer?
    @State private var itemMode: ServiceStopPartApprovalItemMode = .manual
    @State private var selectedProduct = GenericItem.emptyProductCatalogItem
    @State private var showProductPicker = false
    @State private var manualName = ""
    @State private var manualUnitCost = ""
    @State private var manualUnitPrice = ""
    @State private var quantity = "1"
    @State private var customerNote = ""
    @State private var isSaving = false
    @State private var message: String?
    @State private var didPrefill = false

    private var targetCompanyId: String? {
        if serviceStop.otherCompany, let mainCompanyId = serviceStop.mainCompanyId {
            return mainCompanyId
        }

        return masterDataManager.currentCompany?.id
    }

    private var itemName: String {
        switch itemMode {
        case .manual:
            return manualName.trimmingCharacters(in: .whitespacesAndNewlines)
        case .database:
            return selectedProduct.productDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var itemDescription: String {
        let trimmedNote = customerNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNote.isEmpty { return trimmedNote }
        if itemMode == .database { return selectedProduct.productDescription }
        return ""
    }

    private var quantityValue: Double {
        Double(quantity.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var unitCostCents: Int {
        switch itemMode {
        case .manual:
            return cents(fromDollarInput: manualUnitCost)
        case .database:
            return Int(selectedProduct.rate.rounded())
        }
    }

    private var unitPriceCents: Int {
        switch itemMode {
        case .manual:
            return cents(fromDollarInput: manualUnitPrice)
        case .database:
            return selectedProduct.productSellPriceCents
        }
    }

    private var totalCostCents: Int {
        Int((Double(unitCostCents) * quantityValue).rounded())
    }

    private var totalPriceCents: Int {
        Int((Double(unitPriceCents) * quantityValue).rounded())
    }

    private var canSave: Bool {
        targetCompanyId != nil &&
        !serviceStop.customerId.isEmpty &&
        !itemName.isEmpty &&
        quantityValue > 0 &&
        unitPriceCents > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        itemCard
                        pricingCard
                        noteCard

                        if let message {
                            Text(message)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(message == "Part approval created." ? Color.poolGreen : Color.poolRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(14)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Part Approval")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveApproval() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .task {
                await loadCustomer()
            }
            .onAppear {
                prefillIfNeeded()
            }
            .sheet(isPresented: $showProductPicker) {
                ProductCatalogPicker(
                    dataService: dataService,
                    product: $selectedProduct,
                    onlyPartPurchaseAvailable: true
                )
            }
        }
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(serviceStop.customerName, systemImage: "person.crop.circle")
                .font(.headline.weight(.semibold))

            Text(equipment?.name ?? "Create a customer-facing approval for a part before purchase or installation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var itemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Part", systemImage: "shippingbox")
                .font(.headline.weight(.semibold))

            Picker("Item Type", selection: $itemMode) {
                ForEach(ServiceStopPartApprovalItemMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch itemMode {
            case .manual:
                TextField("Part name", text: $manualName)
                    .textFieldStyle(.roundedBorder)
            case .database:
                Button {
                    showProductPicker = true
                } label: {
                    HStack {
                        Text(selectedProduct.id.isEmpty ? "Select product" : selectedProduct.productDisplayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedProduct.id.isEmpty ? .secondary : .primary)
                            .lineLimit(2)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            TextField("Quantity", text: $quantity)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pricing", systemImage: "dollarsign.circle")
                .font(.headline.weight(.semibold))

            if itemMode == .manual {
                TextField("Internal unit cost", text: $manualUnitCost)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Customer unit price", text: $manualUnitPrice)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                approvalMetric("Unit Price", value: DataBaseItemMoneyFormatter.moneyFromCents(unitPriceCents))
                approvalMetric("Customer Total", value: DataBaseItemMoneyFormatter.moneyFromCents(totalPriceCents))
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Customer Note", systemImage: "text.bubble")
                .font(.headline.weight(.semibold))

            TextEditor(text: $customerNote)
                .font(.subheadline)
                .frame(minHeight: 110)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func approvalMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadCustomer() async {
        guard let companyId = targetCompanyId else { return }

        do {
            customer = try await dataService.getCustomerById(
                companyId: companyId,
                customerId: serviceStop.customerId
            )
        } catch {
            print("[ServiceStopPartApprovalSheet][loadCustomer] \(error)")
        }
    }

    private func saveApproval() async {
        guard let companyId = targetCompanyId else {
            message = "Missing company."
            return
        }

        guard canSave else {
            message = "Select a part, quantity, and customer price."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let approvalId = "cpa_\(UUID().uuidString)"
        let customerEmail = customer?.email ?? ""
        let linkedUserId = customer?.linkedCustomerUserId
            ?? customer?.linkedHomeownerUserId
            ?? customer?.linkedCustomerIds?.first
        let userId = masterDataManager.user?.id ?? ""
        let userName = [
            masterDataManager.user?.firstName ?? "",
            masterDataManager.user?.lastName ?? ""
        ]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let approval = CustomerPartApproval(
            id: approvalId,
            companyId: companyId,
            companyName: masterDataManager.currentCompany?.name ?? serviceStop.companyName,
            customerApprovalUrl: "https://dripdrop-poolapp.com/customer/part-approvals/\(approvalId)",
            customerId: serviceStop.customerId,
            customerUserId: linkedUserId,
            customerName: serviceStop.customerName,
            customerEmail: customerEmail,
            email: customerEmail,
            billingEmail: customerEmail,
            serviceLocationId: serviceStop.serviceLocationId,
            serviceLocationName: serviceStop.address.streetAddress,
            serviceLocationAddress: serviceStop.address.streetAddress,
            shoppingListItemId: "",
            shoppingListPath: "",
            itemName: itemName,
            name: itemName,
            description: itemDescription,
            quantity: String(quantityValue),
            dbItemId: "",
            dbItemName: "",
            genericItemId: itemMode == .database ? selectedProduct.id : "",
            productId: itemMode == .database ? selectedProduct.id : "",
            productName: itemMode == .database ? selectedProduct.productDisplayName : "",
            itemId: itemMode == .database ? selectedProduct.id : "",
            itemType: itemMode == .database ? "Product" : "Part",
            subCategory: itemMode == .database ? "Product" : "Part",
            plannedUnitCostCents: unitCostCents,
            plannedUnitPriceCents: unitPriceCents,
            plannedTotalCostCents: totalCostCents,
            plannedTotalPriceCents: totalPriceCents,
            status: "pending",
            approvalStatus: "pending",
            fulfillmentStatus: "awaitingCustomerApproval",
            sourceType: "partApprovalRequest",
            requestedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            requestedByUserId: userId,
            requestedByUserName: userName.isEmpty ? "Technician" : userName,
            jobId: serviceStop.jobId,
            jobName: serviceStop.jobName ?? "",
            jobInternalId: serviceStop.jobName ?? serviceStop.jobId,
            serviceStopId: serviceStop.id,
            serviceStopInternalId: serviceStop.internalId,
            scheduledServiceStopId: serviceStop.id,
            scheduledServiceStopInternalId: serviceStop.internalId,
            scheduledDate: serviceStop.serviceDate,
            techId: serviceStop.techId,
            techName: serviceStop.tech,
            assignedTechId: serviceStop.techId,
            assignedTechName: serviceStop.tech,
            assignedToUserId: serviceStop.techId,
            assignedToUserName: serviceStop.tech,
            assignedTechIds: serviceStop.techId.isEmpty ? [] : [serviceStop.techId],
            assignedTechNames: serviceStop.tech.isEmpty ? [] : [serviceStop.tech],
            purchaserId: serviceStop.techId,
            purchaserName: serviceStop.tech,
            prepKeys: [
                serviceStop.jobId.isEmpty ? "" : "job:\(serviceStop.jobId)",
                "customer:\(serviceStop.customerId)",
                serviceStop.serviceLocationId.isEmpty ? "" : "serviceLocation:\(serviceStop.serviceLocationId)",
                "serviceStop:\(serviceStop.id)",
                serviceStop.techId.isEmpty ? "" : "user:\(serviceStop.techId)"
            ].filter { !$0.isEmpty },
            history: [
                CustomerPartApprovalHistoryItem(
                    action: "requested",
                    status: "pending",
                    note: itemDescription,
                    source: "technicianRequest",
                    sourceLabel: "Approval requested",
                    actorUserId: userId,
                    actorUserName: userName.isEmpty ? "Technician" : userName,
                    actorEmail: masterDataManager.user?.email ?? "",
                    createdAt: Date()
                )
            ]
        )

        do {
            try await dataService.uploadCustomerPartApproval(approval)
            message = "Part approval created."
            await onCreated()
            dismiss()
        } catch {
            message = "Could not create part approval."
            print("[ServiceStopPartApprovalSheet][saveApproval] \(error)")
        }
    }

    private func prefillIfNeeded() {
        guard !didPrefill else { return }
        didPrefill = true

        if let equipment {
            manualName = equipment.name
            customerNote = "Approval requested for \(equipment.name)."
        }
    }

    private func cents(fromDollarInput text: String) -> Int {
        let filtered = text.filter { ".0123456789".contains($0) }
        let dollars = Double(filtered) ?? 0
        return Int((dollars * 100).rounded())
    }

}

private struct ServiceStopJobCommentsView: View {
    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var comments: [JobComment] = []
    @State private var newComment: String = ""
    @State private var isLoading: Bool = false
    @State private var isAddingComment: Bool = false
    @State private var message: String? = nil

    private var jobId: String {
        serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var openComments: Int {
        comments.filter { !$0.resolved }.count
    }

    private var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? "Technician" : name
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if jobId.isEmpty {
                ContentUnavailableView(
                    "No Linked Job",
                    systemImage: "briefcase",
                    description: Text("This service stop is not attached to a job.")
                )
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        composer
                        commentList
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .task(id: jobId) {
            await loadComments()
        }
        .refreshable {
            await loadComments()
        }
        .safeAreaInset(edge: .bottom) {
            dismissCommentsBar
        }
    }

    private var dismissCommentsBar: some View {
        Button {
            dismiss()
        } label: {
            Label("Dismiss Comments", systemImage: "xmark.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 42, height: 42)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Job Comments")
                        .font(.title3.weight(.semibold))

                    Text(serviceStop.jobName?.isEmpty == false ? serviceStop.jobName ?? serviceStop.type : serviceStop.type)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {
                    Task { await loadComments() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh job comments")
            }

            HStack(spacing: 8) {
                commentMetric("\(comments.count)", title: "Total", systemImage: "text.bubble")
                commentMetric("\(openComments)", title: "Open", systemImage: "exclamationmark.circle")
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add Field Note", systemImage: "square.and.pencil")
                .font(.headline.weight(.semibold))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $newComment)
                    .font(.subheadline)
                    .frame(minHeight: 112)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }

                if newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Add a job note for the admin, office, or next technician...")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                if let message {
                    Text(message)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(message == "Comment added" ? Color.poolGreen : Color.poolRed)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    Task { await addComment() }
                } label: {
                    if isAddingComment {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Label("Add Comment", systemImage: "plus.message.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAddingComment || newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var commentList: some View {
        if isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 24)
        } else if comments.isEmpty {
            ContentUnavailableView(
                "No Comments",
                systemImage: "text.bubble",
                description: Text("Comments added here will also appear on the linked job.")
            )
            .padding(.vertical, 20)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Recent Comments", systemImage: "clock.arrow.circlepath")
                    .font(.headline.weight(.semibold))

                ForEach(comments.sorted(by: commentSort)) { comment in
                    commentRow(comment)
                }
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func commentMetric(_ value: String, title: String, systemImage: String) -> some View {
        Label {
            Text("\(value) \(title)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private func commentRow(_ comment: JobComment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(comment.userName ?? comment.authorName ?? "Unknown")
                        .font(.subheadline.weight(.semibold))

                    Text(commentDateText(comment.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(comment.resolved ? "Resolved" : "Open")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(comment.resolved ? Color.green : Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((comment.resolved ? Color.green : Color.orange).opacity(0.12), in: Capsule())
            }

            Text(comment.comment)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadComments() async {
        guard let companyId = masterDataManager.currentCompany?.id, !jobId.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            comments = try await dataService.getWorkOrderComments(
                companyId: companyId,
                workOrderId: jobId
            )
        } catch {
            message = "Could not load comments"
            print("[ServiceStopJobCommentsView][loadComments] \(error)")
        }
    }

    private func addComment() async {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else { return }
        guard let companyId = masterDataManager.currentCompany?.id else {
            message = "Missing company"
            return
        }
        guard let userId = masterDataManager.user?.id, !userId.isEmpty else {
            message = "Missing signed-in user"
            return
        }

        isAddingComment = true
        defer { isAddingComment = false }

        let comment = JobComment(
            id: "comp_wo_com_" + UUID().uuidString,
            jobId: jobId,
            companyId: companyId,
            userId: userId,
            userName: currentUserDisplayName,
            authorId: userId,
            authorName: currentUserDisplayName,
            date: Date(),
            comment: trimmedComment,
            resolved: false
        )

        do {
            try await dataService.addWorkOrderComment(
                companyId: companyId,
                workOrderId: jobId,
                comment: comment
            )
            newComment = ""
            message = "Comment added"
            await loadComments()
        } catch {
            message = "Could not add comment"
            print("[ServiceStopJobCommentsView][addComment] \(error)")
        }
    }

    private func commentSort(_ lhs: JobComment, _ rhs: JobComment) -> Bool {
        (lhs.date ?? .distantPast) > (rhs.date ?? .distantPast)
    }

    private func commentDateText(_ date: Date?) -> String {
        guard let date else { return "Pending" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct ServiceStopAgreementWorkflowView: View {
    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop
    let onOpenSurvey: () -> Void

    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var agreements: [SalesAgreement] = []
    @State private var isLoading: Bool = false
    @State private var isSending: Bool = false
    @State private var message: String? = nil
    @State private var showPreview: Bool = false
    @State private var showSendSheet: Bool = false
    @State private var showMessageComposer: Bool = false
    @State private var lastSentAgreementUrl: String = ""

    private var companyId: String {
        masterDataManager.currentCompany?.id ?? serviceStop.companyId
    }

    private var linkedAgreement: SalesAgreement? {
        let linkedAgreementId = [
            serviceStop.serviceAgreementId,
            serviceStop.salesAgreementId,
            serviceStop.agreementId
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        if let linkedAgreementId,
           let linked = agreements.first(where: { $0.id == linkedAgreementId }) {
            return linked
        }

        return agreements
            .filter(linksServiceStop)
            .sorted(by: agreementSort)
            .first
    }

    private var canSendAgreement: Bool {
        hasRolePermission("400") ||
        hasRolePermission("438") ||
        hasRolePermission("628")
    }

    private var hasLinkedInspectionReport: Bool {
        guard let agreement = linkedAgreement else { return false }
        return [
            agreement.inspectionServiceStopId,
            agreement.serviceAgreementEstimateServiceStopId,
            agreement.sourceId
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .contains(serviceStop.id) ||
        agreement.serviceStopIds?.contains(serviceStop.id) == true ||
        !(agreement.emailDelivery?.inspectionReportUrl ?? agreement.inspectionReportUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var shouldIncludeInspectionReport: Bool {
        linkedAgreement?.includeInspectionReport == true ||
        linkedAgreement?.emailDelivery?.includeInspectionReport == true ||
        hasLinkedInspectionReport
    }

    private var reviewUrlText: String {
        let deliveryUrl = linkedAgreement?.emailDelivery?.agreementUrl ?? ""
        let preferredUrl = lastSentAgreementUrl.isEmpty ? deliveryUrl : lastSentAgreementUrl
        let trimmedPreferred = preferredUrl.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedPreferred.isEmpty {
            return trimmedPreferred
        }

        guard let linkedAgreement else { return "" }
        return "https://dripdrop-poolapp.com/customer/service-agreements/\(linkedAgreement.id)"
    }

    private var textMessageBody: String {
        let companyName = masterDataManager.currentCompany?.name ?? serviceStop.companyName
        return "Please review your service agreement from \(companyName): \(reviewUrlText)"
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if isLoading && agreements.isEmpty {
                        ProgressView("Loading agreement")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                    } else if let agreement = linkedAgreement {
                        previewSection(for: agreement)
                        deliverySection(for: agreement)
                        agreementDetailsSection(for: agreement)
                        lineItemsSection(for: agreement)
                        termsSection(for: agreement)
                    } else {
                        emptyAgreementState
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 28)
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: serviceStop.id) {
            await reloadAgreements()
        }
        .refreshable {
            await reloadAgreements()
        }
        .sheet(isPresented: $showPreview) {
            if let agreement = linkedAgreement {
                NavigationStack {
                    ServiceAgreementHTMLPreview(html: printableAgreementHtml(for: agreement))
                        .navigationTitle("Agreement PDF Preview")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    showPreview = false
                                }
                            }
                        }
                }
            }
        }
        .sheet(isPresented: $showSendSheet) {
            if let agreement = linkedAgreement {
                ServiceAgreementMobileSendSheet(
                    agreement: agreement,
                    sending: isSending,
                    includeInspectionReport: shouldIncludeInspectionReport,
                    hasLinkedInspectionReport: hasLinkedInspectionReport,
                    onCancel: {
                        showSendSheet = false
                    },
                    onSend: { primaryEmail, additionalEmails in
                        Task {
                            await sendAgreement(
                                agreement: agreement,
                                primaryEmail: primaryEmail,
                                additionalEmails: additionalEmails
                            )
                        }
                    }
                )
                .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showMessageComposer) {
            if MFMessageComposeViewController.canSendText() {
                ServiceAgreementMessageComposer(body: textMessageBody)
            } else {
                NavigationStack {
                    ContentUnavailableView(
                        "Messages Unavailable",
                        systemImage: "message",
                        description: Text("This device cannot send text messages.")
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showMessageComposer = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 42, height: 42)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Service Agreement")
                        .font(.title3.weight(.semibold))

                    Text(linkedAgreement?.title ?? serviceStop.serviceAgreementTitle ?? "Preview and send the agreement from the field.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {
                    Task { await reloadAgreements() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh service agreement")
            }

            if let message {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(message.lowercased().contains("could not") || message.lowercased().contains("permission") ? Color.poolRed : Color.poolGreen)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var emptyAgreementState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("No Agreement Draft Linked", systemImage: "doc.badge.plus")
                .font(.headline.weight(.semibold))

            Text("Complete the survey recommendation, then connect or create the agreement draft so it can be previewed and sent here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onOpenSurvey()
            } label: {
                Label("Open Survey", systemImage: "list.clipboard")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func previewSection(for agreement: SalesAgreement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Preview", systemImage: "doc.richtext")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(agreement.status.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusTint(agreement.status))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(statusTint(agreement.status).opacity(0.12), in: Capsule())
            }

            Button {
                showPreview = true
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.poolBlue)
                            .frame(width: 44, height: 54)
                            .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(agreement.title.isEmpty ? "Service Agreement" : agreement.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Text("\(formattedMoney(totalCents(for: agreement))) • \(formattedCadence(for: agreement))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }

                    Text("Tap to open the in-app PDF-style agreement preview before sending.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func deliverySection(for agreement: SalesAgreement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Send Agreement", systemImage: "paperplane.fill")
                .font(.headline.weight(.semibold))

            VStack(spacing: 8) {
                agreementInfoRow("Primary Email", value: agreement.email.isEmpty ? "No email saved" : agreement.email, systemImage: "envelope")
                agreementInfoRow("Review Link", value: reviewUrlText.isEmpty ? "Generated after send" : reviewUrlText, systemImage: "link")
                agreementInfoRow("Last Sent", value: formattedDate(agreement.sentAt ?? agreement.emailDelivery?.lastSentAt), systemImage: "clock")
            }

            if shouldIncludeInspectionReport {
                Label(hasLinkedInspectionReport ? "Inspection report will be included." : "No linked inspection report was found yet.", systemImage: hasLinkedInspectionReport ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(hasLinkedInspectionReport ? Color.poolGreen : Color.poolYellow)
            }

            HStack(spacing: 10) {
                Button {
                    showSendSheet = true
                } label: {
                    if isSending {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Email", systemImage: "envelope.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSendAgreement || isSending)

                Button {
                    showMessageComposer = true
                } label: {
                    Label("Text", systemImage: "message.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(reviewUrlText.isEmpty)
            }

            if !canSendAgreement {
                Label("Your role can preview this agreement but cannot send it.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func agreementDetailsSection(for agreement: SalesAgreement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Agreement Details", systemImage: "info.circle")
                .font(.headline.weight(.semibold))

            VStack(spacing: 8) {
                agreementInfoRow("Customer", value: agreement.customerName, systemImage: "person")
                agreementInfoRow("Location", value: serviceLocationText(for: agreement), systemImage: "mappin.and.ellipse")
                agreementInfoRow("Payment Terms", value: labelize(agreement.paymentTerms ?? ""), systemImage: "calendar.badge.clock")
                agreementInfoRow("Invoice Delivery", value: labelize(agreement.invoiceDeliveryMethod?.rawValue ?? ""), systemImage: "tray.and.arrow.down")
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func lineItemsSection(for agreement: SalesAgreement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Services And Products", systemImage: "list.bullet.rectangle")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(formattedMoney(totalCents(for: agreement)))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
            }

            if agreement.lineItems?.isEmpty != false {
                Text("No services or products were included yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(agreement.lineItems ?? []) { item in
                        agreementLineItemRow(item)
                    }
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func termsSection(for agreement: SalesAgreement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Terms", systemImage: "text.page")
                .font(.headline.weight(.semibold))

            if let termsList = agreement.termsList, !termsList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(termsList.enumerated()), id: \.offset) { index, term in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(term)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else if !agreement.terms.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(agreement.terms)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No terms were added yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func agreementInfoRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 24, height: 24)
                .background(Color.poolBlue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : value)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 3)
    }

    private func agreementLineItemRow(_ item: SalesInvoiceLineItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 24, height: 24)
                .background(Color.poolBlue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name ?? item.description)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                if !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   item.name != item.description {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text("Qty \(item.quantity) • \(formattedMoney(item.unitAmountCents))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(formattedMoney(item.totalAmountCents))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @MainActor
    private func reloadAgreements() async {
        guard !companyId.isEmpty else {
            agreements = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            agreements = try await dataService.getSalesAgreements(
                companyId: companyId,
                customerId: serviceStop.customerId
            )
            message = nil
        } catch {
            agreements = []
            message = "Could not load service agreement"
            print("[ServiceStopAgreementWorkflowView][reloadAgreements] \(error)")
        }
    }

    @MainActor
    private func sendAgreement(
        agreement: SalesAgreement,
        primaryEmail: String,
        additionalEmails: [String]
    ) async {
        guard canSendAgreement else {
            message = "Your role does not have permission to send agreements."
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let result = try await FunctionsManager.shared.sendServiceAgreement(
                companyId: companyId,
                agreementId: agreement.id,
                primaryEmail: primaryEmail,
                additionalEmails: additionalEmails,
                includeInspectionReport: shouldIncludeInspectionReport
            )
            lastSentAgreementUrl = result.agreementUrl
            message = result.userFacingMessage
            showSendSheet = false
            await reloadAgreements()
        } catch {
            message = error.localizedDescription.isEmpty ? "Could not send service agreement" : error.localizedDescription
            print("[ServiceStopAgreementWorkflowView][sendAgreement] \(error)")
        }
    }

    private func linksServiceStop(_ agreement: SalesAgreement) -> Bool {
        let stopId = serviceStop.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationId = serviceStop.serviceLocationId.trimmingCharacters(in: .whitespacesAndNewlines)

        let directIds = [
            agreement.sourceId,
            agreement.serviceAgreementEstimateServiceStopId,
            agreement.inspectionServiceStopId,
            agreement.jobId,
            agreement.workOrderId
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }

        if !stopId.isEmpty && directIds.contains(stopId) {
            return true
        }

        if agreement.serviceStopIds?.contains(stopId) == true {
            return true
        }

        return agreement.sourceType == .serviceAgreementSurvey &&
        !locationId.isEmpty &&
        agreement.serviceLocationIds.contains(locationId)
    }

    private func agreementSort(_ lhs: SalesAgreement, _ rhs: SalesAgreement) -> Bool {
        (lhs.updatedAt ?? lhs.createdAt ?? .distantPast) > (rhs.updatedAt ?? rhs.createdAt ?? .distantPast)
    }

    private func hasRolePermission(_ permissionId: String) -> Bool {
        masterDataManager.role?.permissionIdList.contains(permissionId) == true
    }

    private func statusTint(_ status: SalesAgreementStatus) -> Color {
        switch status {
        case .accepted:
            return Color.poolGreen
        case .sent, .revised:
            return Color.poolBlue
        case .rejected, .expired, .canceled:
            return Color.poolRed
        case .draft:
            return .secondary
        }
    }

    private func totalCents(for agreement: SalesAgreement) -> Int {
        agreement.totalAmountCents ??
        agreement.subtotalAmountCents ??
        agreement.rateAmountCents
    }

    private func serviceLocationText(for agreement: SalesAgreement) -> String {
        if let snapshot = agreement.serviceLocationSnapshots?.first {
            let address = [
                snapshot.streetAddress,
                snapshot.address02,
                [snapshot.city, snapshot.state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "),
                snapshot.zip
            ]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            return [snapshot.nickName, address]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " - ")
        }

        return [
            serviceStop.address.streetAddress,
            [serviceStop.address.city, serviceStop.address.state].filter { !$0.isEmpty }.joined(separator: ", "),
            serviceStop.address.zip
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func formattedCadence(for agreement: SalesAgreement) -> String {
        let count = max(agreement.serviceCadenceCount, 1)
        let cadence = labelize(agreement.serviceCadence)

        if count == 1 {
            return cadence.isEmpty ? "Service" : cadence
        }

        return "Every \(count) \(cadence.lowercased())"
    }

    private func formattedMoney(_ cents: Int) -> String {
        ServiceStopEstimatePlanMoneyFormatter.money(cents)
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "-" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private func labelize(_ value: String) -> String {
        let spaced = value
            .replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return spaced.isEmpty ? "-" : spaced.capitalized
    }

    private func printableAgreementHtml(for agreement: SalesAgreement) -> String {
        let termsHtml: String
        if let termsList = agreement.termsList, !termsList.isEmpty {
            termsHtml = "<ol>\(termsList.map { "<li>\(escapeHtml($0))</li>" }.joined())</ol>"
        } else {
            termsHtml = "<p class=\"preline\">\(escapeHtml(agreement.terms))</p>"
        }

        let rows = (agreement.lineItems ?? []).isEmpty
            ? "<tr><td colspan=\"4\" class=\"muted\">No services or products were included.</td></tr>"
            : (agreement.lineItems ?? []).map { item in
                """
                <tr>
                  <td><strong>\(escapeHtml(item.name ?? item.description))</strong><div class="muted">\(escapeHtml(item.description))</div></td>
                  <td>\(item.quantity)</td>
                  <td>\(escapeHtml(formattedMoney(item.unitAmountCents)))</td>
                  <td><strong>\(escapeHtml(formattedMoney(item.totalAmountCents)))</strong></td>
                </tr>
                """
            }.joined()

        return """
        <!doctype html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              * { box-sizing: border-box; }
              body { margin: 0; background: #f8fafc; color: #0f172a; font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif; font-size: 12px; line-height: 1.45; }
              .page { background: #fff; margin: 12px auto; max-width: 780px; min-height: 100vh; padding: 28px; }
              header { border-bottom: 2px solid #0f172a; margin-bottom: 20px; padding-bottom: 14px; }
              h1 { font-size: 22px; letter-spacing: 0; margin: 0 0 8px; text-transform: uppercase; }
              h2 { border-top: 1px solid #94a3b8; font-size: 12px; letter-spacing: 0; margin: 18px 0 8px; padding-top: 10px; text-transform: uppercase; }
              p { margin: 0 0 8px; }
              table { border-collapse: collapse; width: 100%; }
              th, td { border: 1px solid #cbd5e1; padding: 7px; text-align: left; vertical-align: top; }
              th { background: #f1f5f9; color: #475569; font-size: 10px; text-transform: uppercase; }
              ol { margin: 0; padding-left: 18px; }
              li { margin-bottom: 6px; }
              .meta { color: #475569; display: flex; flex-wrap: wrap; gap: 10px; font-size: 10px; text-transform: uppercase; }
              .grid { display: grid; gap: 8px; grid-template-columns: repeat(2, minmax(0, 1fr)); margin-top: 10px; }
              .cell { border: 1px solid #cbd5e1; padding: 8px; }
              .cell span { color: #475569; display: block; font-size: 10px; font-weight: 700; text-transform: uppercase; }
              .cell strong { display: block; margin-top: 3px; }
              .muted { color: #475569; font-size: 10px; font-weight: 400; margin-top: 3px; }
              .preline { white-space: pre-line; }
            </style>
          </head>
          <body>
            <div class="page">
              <header>
                <h1>\(escapeHtml(agreement.title.isEmpty ? "Service Agreement" : agreement.title))</h1>
                <div class="meta">
                  <span>Agreement: \(escapeHtml(agreement.id))</span>
                  <span>Prepared: \(escapeHtml(formattedDate(agreement.sentAt ?? agreement.createdAt)))</span>
                  <span>Status: \(escapeHtml(agreement.status.rawValue.capitalized))</span>
                </div>
              </header>
              <h2>1. Parties And Service Location</h2>
              <p>This service agreement is between \(escapeHtml(agreement.companyName.isEmpty ? serviceStop.companyName : agreement.companyName)), the service provider, and \(escapeHtml(agreement.customerName.isEmpty ? serviceStop.customerName : agreement.customerName)), the client.</p>
              <div class="grid">
                <div class="cell"><span>Service Provider</span><strong>\(escapeHtml(agreement.companyName.isEmpty ? serviceStop.companyName : agreement.companyName))</strong></div>
                <div class="cell"><span>Client</span><strong>\(escapeHtml(agreement.customerName.isEmpty ? serviceStop.customerName : agreement.customerName))</strong></div>
                <div class="cell"><span>Client Email</span><strong>\(escapeHtml(agreement.email.isEmpty ? "Not provided" : agreement.email))</strong></div>
                <div class="cell"><span>Service Location</span><strong>\(escapeHtml(serviceLocationText(for: agreement)))</strong></div>
              </div>
              <h2>2. Term And Billing Summary</h2>
              <div class="grid">
                <div class="cell"><span>Start Date</span><strong>\(escapeHtml(formattedDate(agreement.startDate)))</strong></div>
                <div class="cell"><span>Service Frequency</span><strong>\(escapeHtml(formattedCadence(for: agreement)))</strong></div>
                <div class="cell"><span>Payment Terms</span><strong>\(escapeHtml(labelize(agreement.paymentTerms ?? "")))</strong></div>
                <div class="cell"><span>Total</span><strong>\(escapeHtml(formattedMoney(totalCents(for: agreement))))</strong></div>
              </div>
              <h2>3. Services And Products</h2>
              <p class="preline">\(escapeHtml(agreement.description))</p>
              <table>
                <thead><tr><th>Service Or Product</th><th>Qty</th><th>Unit</th><th>Total</th></tr></thead>
                <tbody>\(rows)</tbody>
              </table>
              <h2>4. Terms And Conditions</h2>
              \(termsHtml)
            </div>
          </body>
        </html>
        """
    }

    private func escapeHtml(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

private struct ServiceAgreementMobileSendSheet: View {
    let agreement: SalesAgreement
    let sending: Bool
    let includeInspectionReport: Bool
    let hasLinkedInspectionReport: Bool
    let onCancel: () -> Void
    let onSend: (String, [String]) -> Void

    @State private var primaryEmail: String
    @State private var additionalEmailText: String = ""

    init(
        agreement: SalesAgreement,
        sending: Bool,
        includeInspectionReport: Bool,
        hasLinkedInspectionReport: Bool,
        onCancel: @escaping () -> Void,
        onSend: @escaping (String, [String]) -> Void
    ) {
        self.agreement = agreement
        self.sending = sending
        self.includeInspectionReport = includeInspectionReport
        self.hasLinkedInspectionReport = hasLinkedInspectionReport
        self.onCancel = onCancel
        self.onSend = onSend
        _primaryEmail = State(initialValue: agreement.email)
    }

    private var primaryEmailValue: String {
        primaryEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var additionalEmails: [String] {
        let primaryKey = primaryEmailValue.lowercased()
        var seen = Set<String>()

        return additionalEmailText
            .components(separatedBy: CharacterSet(charactersIn: ",; \n\t"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { email in
                let key = email.lowercased()
                guard key != primaryKey, !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
    }

    private var invalidAdditionalEmails: [String] {
        additionalEmails.filter { !isValidEmail($0) }
    }

    private var primaryEmailInvalid: Bool {
        !primaryEmailValue.isEmpty && !isValidEmail(primaryEmailValue)
    }

    private var recipients: [String] {
        [primaryEmailValue] + additionalEmails
    }

    private var canSend: Bool {
        !primaryEmailValue.isEmpty &&
        !primaryEmailInvalid &&
        invalidAdditionalEmails.isEmpty &&
        !sending
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Verify Email Recipients", systemImage: "envelope.fill")
                            .font(.title3.weight(.semibold))

                        Text(agreement.title.isEmpty ? "Service Agreement" : agreement.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary Recipient")
                            .font(.subheadline.weight(.semibold))

                        TextField("customer@example.com", text: $primaryEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color.listColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .disabled(sending)

                        if primaryEmailInvalid {
                            Text("Enter a valid primary email.")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.poolRed)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Recipients")
                            .font(.subheadline.weight(.semibold))

                        TextEditor(text: $additionalEmailText)
                            .frame(minHeight: 96)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.listColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                            }
                            .disabled(sending)

                        if invalidAdditionalEmails.isEmpty == false {
                            Text("Check: \(invalidAdditionalEmails.joined(separator: ", "))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.poolRed)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Will Send To")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(recipients.filter { !$0.isEmpty }.isEmpty ? "Add a primary recipient." : recipients.filter { !$0.isEmpty }.joined(separator: ", "))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .background(Color.poolBlue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if includeInspectionReport {
                        Label(hasLinkedInspectionReport ? "Inspection report will be included." : "No linked inspection report was found yet.", systemImage: hasLinkedInspectionReport ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(hasLinkedInspectionReport ? Color.poolGreen : Color.poolYellow)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Send Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .disabled(sending)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        onSend(primaryEmailValue, additionalEmails)
                    } label: {
                        if sending {
                            ProgressView()
                        } else {
                            Text("Send")
                        }
                    }
                    .disabled(!canSend)
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}

private struct ServiceAgreementHTMLPreview: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

private struct ServiceAgreementMessageComposer: UIViewControllerRepresentable {
    let body: String

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onDismiss: DismissAction

        init(onDismiss: DismissAction) {
            self.onDismiss = onDismiss
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            onDismiss()
        }
    }
}

private struct ServiceStopEstimatePlanView: View {
    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop

    @EnvironmentObject private var masterDataManager: MasterDataManager

    @State private var jobTasks: [JobTask] = []
    @State private var plannedStops: [JobPlannedServiceStop] = []
    @State private var shoppingItems: [ShoppingListItem] = []
    @State private var planNotes: [JobComment] = []
    @State private var linkedJob: Job? = nil
    @State private var recommendedPrice: String = ""
    @State private var planTitle: String = ""
    @State private var planDescription: String = ""
    @State private var selectedPlanTier: Int = 2
    @State private var didSeedPlanForm: Bool = false
    @State private var newPlanNote: String = ""
    @State private var isLoading: Bool = false
    @State private var isSavingPlan: Bool = false
    @State private var isSendingEstimate: Bool = false
    @State private var isAddingPlanNote: Bool = false
    @State private var showAddTaskSheet: Bool = false
    @State private var showAddProductSheet: Bool = false
    @State private var showEstimatePreview: Bool = false
    @State private var message: String? = nil

    private var jobId: String {
        serviceStop.jobId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var companyId: String {
        masterDataManager.currentCompany?.id ?? serviceStop.companyId
    }

    private var totalTaskMinutes: Int {
        jobTasks.reduce(0) { $0 + $1.estimatedTime }
    }

    private var jobDescriptionText: String {
        let jobDescription = linkedJob?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !jobDescription.isEmpty {
            return jobDescription
        }

        return serviceStop.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPlanDescription: String {
        planDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var planDisplayTitle: String {
        let trimmedTitle = planTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedTitle.isEmpty ? "Resolution Plan" : trimmedTitle
    }

    private var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty {
            return name
        }

        return masterDataManager.user?.email ?? "Estimator"
    }

    private var canBuildFieldEstimatePlan: Bool {
        hasRolePermission("72") ||
        hasRolePermission("24") ||
        hasRolePermission("400")
    }

    private var canSendFieldEstimate: Bool {
        hasRolePermission("74") ||
        hasRolePermission("622") ||
        hasRolePermission("400")
    }

    private var recommendedPriceCents: Int {
        centsFromCurrencyInput(recommendedPrice)
    }

    private var hasEstimatePlanContent: Bool {
        recommendedPriceCents > 0 ||
        !trimmedPlanDescription.isEmpty ||
        !jobTasks.isEmpty ||
        !shoppingItems.isEmpty
    }

    private var estimateTotalText: String {
        if recommendedPriceCents > 0 {
            return ServiceStopEstimatePlanMoneyFormatter.money(recommendedPriceCents)
        }

        if let linkedJob,
           linkedJob.rate > 0 {
            return "\(ServiceStopEstimatePlanMoneyFormatter.money(linkedJob.rate)) job price"
        }

        return "Not set"
    }

    private var successMessages: Set<String> {
        [
            "Plan note added",
            "Resolution plan saved",
            "Estimate sent to customer"
        ]
    }

    var body: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            if jobId.isEmpty {
                ContentUnavailableView(
                    "No Linked Job",
                    systemImage: "briefcase",
                    description: Text("Create Plan needs a linked estimate job.")
                )
                .padding()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        jobDescriptionCard
                        fieldPlanEditor
                        quickActions
                        servicesToDo
                        productsNeeded
                        planNotesCard
                        estimateDelivery
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .task(id: jobId) {
            await reloadPlan()
        }
        .refreshable {
            await reloadPlan()
        }
        .sheet(isPresented: $showAddTaskSheet, onDismiss: {
            Task { await reloadPlan() }
        }) {
            AddNewTaskToJob(
                dataService: dataService,
                jobId: jobId,
                taskTypes: JobTaskType.allCases.map(\.rawValue),
                customerId: serviceStop.customerId,
                serviceLocationId: serviceStop.serviceLocationId
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddProductSheet, onDismiss: {
            Task { await reloadPlan() }
        }) {
            if let linkedJob {
                AddNewShoppingListItemToJob(
                    dataService: dataService,
                    job: linkedJob
                )
                .presentationDetents([.medium, .large])
            } else {
                ContentUnavailableView(
                    "Job Still Loading",
                    systemImage: "briefcase",
                    description: Text("Refresh the plan before adding products.")
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showEstimatePreview) {
            NavigationStack {
                ServiceStopEstimatePlanPreview(
                    title: planDisplayTitle,
                    customerName: serviceStop.customerName,
                    jobName: linkedJob?.type ?? serviceStop.jobName ?? serviceStop.type,
                    jobDescription: jobDescriptionText,
                    recommendedPriceCents: recommendedPriceCents,
                    planTierLabel: planTierLabel(selectedPlanTier),
                    planDescription: planDescription,
                    jobTasks: jobTasks,
                    shoppingItems: shoppingItems,
                    planNotes: planNotes
                )
                .navigationTitle("Estimate Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showEstimatePreview = false
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "list.clipboard.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 42, height: 42)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Assemble Plan")
                        .font(.title3.weight(.semibold))

                    Text(serviceStop.jobName?.isEmpty == false ? serviceStop.jobName ?? serviceStop.type : serviceStop.type)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {
                    Task { await reloadPlan() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .background(.thinMaterial, in: Circle())
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh estimate plan")
            }

            HStack(spacing: 8) {
                planMetric("\(jobTasks.count)", title: "Services", systemImage: "checklist")
                planMetric("\(shoppingItems.count)", title: "Products", systemImage: "shippingbox")
                planMetric("\(totalTaskMinutes)", title: "Min", systemImage: "timer")
            }

            if let message {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(successMessages.contains(message) ? Color.poolGreen : Color.poolRed)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var jobDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Job Description", systemImage: "doc.text")
                .font(.headline.weight(.semibold))

            Text(jobDescriptionText.isEmpty ? "No job description has been added yet." : jobDescriptionText)
                .font(.subheadline)
                .foregroundStyle(jobDescriptionText.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fieldPlanEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Label("Resolution Plan", systemImage: "list.bullet.clipboard")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text(planTierLabel(selectedPlanTier))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.poolBlue.opacity(0.1), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Plan Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Repair existing system", text: $planTitle)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(Color.listColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .disabled(!canBuildFieldEstimatePlan || isSavingPlan)
            }

            Picker("Plan Option", selection: $selectedPlanTier) {
                ForEach([1, 2, 3], id: \.self) { tier in
                    Text(planTierLabel(tier)).tag(tier)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!canBuildFieldEstimatePlan || isSavingPlan)

            VStack(alignment: .leading, spacing: 8) {
                Text("What needs to happen")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $planDescription)
                        .font(.subheadline)
                        .frame(minHeight: 112)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.listColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(!canBuildFieldEstimatePlan || isSavingPlan)

                    if trimmedPlanDescription.isEmpty {
                        Text("Write the field plan: diagnose, repair or replace, assemble parts, test the system, and confirm the issue is resolved.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Customer Estimate Total")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("$")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)

                    TextField("Optional", text: $recommendedPrice)
                        .keyboardType(.decimalPad)
                        .font(.subheadline.weight(.semibold))
                        .disabled(!canBuildFieldEstimatePlan || isSavingPlan)
                }
                .padding(12)
                .background(Color.listColor.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            HStack(spacing: 10) {
                Button {
                    showEstimatePreview = true
                } label: {
                    Label("Preview", systemImage: "doc.text.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!hasEstimatePlanContent)

                Button {
                    Task { _ = await saveFieldPlan() }
                } label: {
                    if isSavingPlan {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canBuildFieldEstimatePlan || isSavingPlan || !hasEstimatePlanContent)
            }

            if !canBuildFieldEstimatePlan {
                Label("Your role can review this field plan but cannot edit services, products, or resolution notes.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Assemble Plan", systemImage: "plus.circle")
                .font(.headline.weight(.semibold))

            Button {
                showAddTaskSheet = true
            } label: {
                actionRow(
                    title: "Add Service Step",
                    subtitle: "Add a repair, install, maintenance, inspection, or other step to the todo list.",
                    systemImage: "checklist"
                )
            }
            .buttonStyle(.plain)
            .disabled(!canBuildFieldEstimatePlan)

            Button {
                showAddProductSheet = true
            } label: {
                actionRow(
                    title: "Add Product / Part",
                    subtitle: "Add equipment, parts, materials, or chemicals needed to finish the job.",
                    systemImage: "shippingbox"
                )
            }
            .buttonStyle(.plain)
            .disabled(!canBuildFieldEstimatePlan || linkedJob == nil)

            if !canBuildFieldEstimatePlan {
                Label("Plan-building permission is required to add services or products from the field.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var estimateDelivery: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Label("Send Estimate", systemImage: "paperplane.fill")
                    .font(.headline.weight(.semibold))

                Spacer()

                if let billingStatus = linkedJob?.billingStatus {
                    Text(billingStatus.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.poolYellow)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.poolYellow.opacity(0.14), in: Capsule())
                }
            }

            VStack(spacing: 8) {
                estimateInfoRow("Plan", value: planDisplayTitle, systemImage: "doc.text")
                estimateInfoRow("Services", value: "\(jobTasks.count) service step(s)", systemImage: "checklist")
                estimateInfoRow("Products", value: "\(shoppingItems.count) product/part line(s)", systemImage: "shippingbox")
                estimateInfoRow("Estimate Total", value: estimateTotalText, systemImage: "dollarsign.circle")
            }

            HStack(spacing: 10) {
                Button {
                    showEstimatePreview = true
                } label: {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!hasEstimatePlanContent)

                Button {
                    Task { await sendEstimate() }
                } label: {
                    if isSendingEstimate {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Send", systemImage: "paperplane.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.poolYellow)
                .disabled(!canSendFieldEstimate || isSendingEstimate || !hasEstimatePlanContent)
            }

            if !canSendFieldEstimate {
                Label("Your role can build the plan but cannot send job estimates.", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var servicesToDo: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Services To Do", systemImage: "checklist")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(totalTaskMinutes) min")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if isLoading && jobTasks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if jobTasks.isEmpty {
                ContentUnavailableView(
                    "No Services Yet",
                    systemImage: "checklist.unchecked",
                    description: Text("Add the service steps needed to resolve the job.")
                )
                .padding(.vertical, 10)
            } else {
                ForEach(jobTasks) { task in
                    planTaskRow(task)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var productsNeeded: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Parts & Products", systemImage: "shippingbox")
                    .font(.headline.weight(.semibold))

                Spacer()

                Text("\(shoppingItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if isLoading && shoppingItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if shoppingItems.isEmpty {
                ContentUnavailableView(
                    "No Parts Added",
                    systemImage: "shippingbox",
                    description: Text("Add the parts, equipment, chemicals, or materials needed to complete the plan.")
                )
                .padding(.vertical, 10)
            } else {
                ForEach(shoppingItems) { item in
                    planProductRow(item)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var planNotesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Plan Notes", systemImage: "text.bubble")
                .font(.headline.weight(.semibold))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $newPlanNote)
                    .font(.subheadline)
                    .frame(minHeight: 96)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }

                if newPlanNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Measurements, constraints, access notes, customer concerns, or field discoveries...")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                Spacer()

                Button {
                    Task { await addPlanNote() }
                } label: {
                    if isAddingPlanNote {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Label("Add Plan Note", systemImage: "plus.message.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAddingPlanNote || newPlanNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if planNotes.isEmpty {
                Text("No plan notes yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
            } else {
                VStack(spacing: 8) {
                    ForEach(planNotes.sorted(by: commentSort).prefix(4)) { comment in
                        planNoteRow(comment)
                    }
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func planMetric(_ value: String, title: String, systemImage: String) -> some View {
        Label {
            Text("\(value) \(title)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private func actionRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 36, height: 36)
                .background(Color.poolBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func planTaskRow(_ task: JobTask) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(task.status == .finished ? Color.poolGreen : Color.poolBlue)
                .frame(width: 32, height: 32)
                .background((task.status == .finished ? Color.poolGreen : Color.poolBlue).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(task.type.rawValue) - \(task.estimatedTime) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(task.status.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())

                    if !task.dataBaseItemId.isEmpty || task.shoppingListItemId?.isEmpty == false {
                        Label("Part linked", systemImage: "shippingbox")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.poolGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.poolGreen.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func planProductRow(_ item: ShoppingListItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolGreen)
                .frame(width: 32, height: 32)
                .background(Color.poolGreen.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(productDisplayName(item))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("Qty \(productQuantityText(item)) - \(item.subCategory.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if !item.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(item.status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func productDisplayName(_ item: ShoppingListItem) -> String {
        let options = [
            item.productName,
            item.dbItemName,
            item.name
        ]

        return options
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Product / Part"
    }

    private func productQuantityText(_ item: ShoppingListItem) -> String {
        let quantity = item.quantity?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return quantity.isEmpty ? "1" : quantity
    }

    private func plannedStopRow(_ plannedStop: JobPlannedServiceStop) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: plannedStop.serviceStopTypeImage.isEmpty ? "calendar" : plannedStop.serviceStopTypeImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 32, height: 32)
                .background(Color.poolBlue.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(plannedStop.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(plannedStop.serviceStopTypeName) - \(plannedStop.estimatedMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let plannedLaborCostCents = plannedStop.plannedLaborCostCents,
                   plannedLaborCostCents > 0 {
                    Text(ServiceStopEstimatePlanMoneyFormatter.money(plannedLaborCostCents))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.poolGreen)
                }

                if !plannedStop.taskIds.isEmpty {
                    Label("\(plannedStop.taskIds.count) linked item(s)", systemImage: "checklist")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func planNoteRow(_ comment: JobComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.userName ?? comment.authorName ?? "Unknown")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text(commentDateText(comment.date))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(comment.comment)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func estimateInfoRow(_ title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 24, height: 24)
                .background(Color.poolBlue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : value)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 3)
    }

    private func hasRolePermission(_ permissionId: String) -> Bool {
        masterDataManager.role?.permissionIdList.contains(permissionId) == true
    }

    private func planTierLabel(_ tier: Int) -> String {
        switch tier {
        case 1:
            return "Good"
        case 3:
            return "Best"
        default:
            return "Better"
        }
    }

    private func centsFromCurrencyInput(_ value: String) -> Int {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")

        guard let dollars = Double(cleaned) else { return 0 }
        return max(Int((dollars * 100).rounded()), 0)
    }

    private func currencyInput(from cents: Int) -> String {
        let dollars = Double(cents) / 100
        return dollars.formatted(.number.precision(.fractionLength(2)))
    }

    private func seedPlanFormIfNeeded() {
        guard !didSeedPlanForm else { return }

        let existingPrice = serviceStop.fieldJobPlanRecommendedPriceCents ??
        serviceStop.recommendedJobEstimatePriceCents ??
        linkedJob?.rate ??
        0

        recommendedPrice = existingPrice > 0 ? currencyInput(from: existingPrice) : ""
        planTitle = serviceStop.fieldJobPlanTitle ??
        linkedJob?.type ??
        serviceStop.jobName ??
        "Resolution Plan"
        planDescription = serviceStop.fieldJobPlanNotes ??
        ""
        selectedPlanTier = serviceStop.fieldJobPlanTier ?? 2
        didSeedPlanForm = true
    }

    @MainActor
    private func reloadPlan() async {
        guard !jobId.isEmpty, !companyId.isEmpty else {
            jobTasks = []
            plannedStops = []
            shoppingItems = []
            planNotes = []
            linkedJob = nil
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            async let taskRequest = dataService.getJobTasks(companyId: companyId, jobId: jobId)
            async let plannedStopRequest = dataService.fetchJobPlannedServiceStops(companyId: companyId, jobId: jobId)
            async let shoppingItemRequest = dataService.getAllShoppingListItemsByUserForJob(companyId: companyId, jobId: jobId, category: ShoppingListCategory.job.rawValue)
            async let commentRequest = dataService.getWorkOrderComments(companyId: companyId, workOrderId: jobId)
            async let jobRequest = dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)

            let (loadedTasks, loadedPlannedStops, loadedShoppingItems, loadedComments, loadedJob) = try await (taskRequest, plannedStopRequest, shoppingItemRequest, commentRequest, jobRequest)
            jobTasks = loadedTasks
            plannedStops = loadedPlannedStops
            shoppingItems = loadedShoppingItems
            planNotes = loadedComments
            linkedJob = loadedJob
            seedPlanFormIfNeeded()
            message = nil
        } catch {
            message = "Could not load estimate plan"
            print("[ServiceStopEstimatePlanView][reloadPlan] \(error)")
        }
    }

    @MainActor
    private func saveFieldPlan() async -> Bool {
        guard canBuildFieldEstimatePlan else {
            message = "Your role cannot build field job estimate plans."
            return false
        }

        guard hasEstimatePlanContent else {
            message = "Add a service, product, or resolution note before saving."
            return false
        }

        guard let userId = masterDataManager.user?.id, !userId.isEmpty else {
            message = "Missing signed-in user"
            return false
        }

        isSavingPlan = true
        defer { isSavingPlan = false }

        let title = planTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Resolution Plan"
            : planTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try await dataService.updateFieldJobEstimatePlan(
                companyId: companyId,
                serviceStopId: serviceStop.id,
                planId: "field-plan-\(serviceStop.id)",
                title: title,
                notes: planDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                recommendedPriceCents: recommendedPriceCents,
                planTier: selectedPlanTier,
                taskCount: jobTasks.count,
                plannedStopCount: plannedStops.count,
                materialCount: shoppingItems.count,
                recommendedByUserId: userId,
                recommendedByUserName: currentUserDisplayName
            )
            message = "Resolution plan saved"
            return true
        } catch {
            message = "Could not save field job plan"
            print("[ServiceStopEstimatePlanView][saveFieldPlan] \(error)")
            return false
        }
    }

    @MainActor
    private func sendEstimate() async {
        guard canSendFieldEstimate else {
            message = "Your role cannot send job estimates."
            return
        }

        guard hasEstimatePlanContent else {
            message = "Create a plan before sending an estimate."
            return
        }

        if canBuildFieldEstimatePlan {
            let didSave = await saveFieldPlan()
            guard didSave else { return }
        }

        isSendingEstimate = true
        defer { isSendingEstimate = false }

        do {
            try dataService.updateJobBillingStatus(companyId: companyId, jobId: jobId, billingStatus: .estimate)
            try await FunctionsManager.shared.sendJobEstimate(companyId: companyId, jobId: jobId)
            message = "Estimate sent to customer"
            await reloadPlan()
        } catch {
            message = "Could not send estimate"
            print("[ServiceStopEstimatePlanView][sendEstimate] \(error)")
        }
    }

    @MainActor
    private func addPlanNote() async {
        let trimmedNote = newPlanNote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNote.isEmpty else { return }
        guard !companyId.isEmpty else {
            message = "Missing company"
            return
        }
        guard let userId = masterDataManager.user?.id, !userId.isEmpty else {
            message = "Missing signed-in user"
            return
        }

        isAddingPlanNote = true
        defer { isAddingPlanNote = false }

        let comment = JobComment(
            id: "comp_wo_com_" + UUID().uuidString,
            jobId: jobId,
            companyId: companyId,
            userId: userId,
            userName: currentUserDisplayName,
            authorId: userId,
            authorName: currentUserDisplayName,
            date: Date(),
            comment: trimmedNote,
            resolved: false
        )

        do {
            try await dataService.addWorkOrderComment(
                companyId: companyId,
                workOrderId: jobId,
                comment: comment
            )
            newPlanNote = ""
            message = "Plan note added"
            await reloadPlan()
        } catch {
            message = "Could not add plan note"
            print("[ServiceStopEstimatePlanView][addPlanNote] \(error)")
        }
    }

    private func commentSort(_ lhs: JobComment, _ rhs: JobComment) -> Bool {
        (lhs.date ?? .distantPast) > (rhs.date ?? .distantPast)
    }

    private func commentDateText(_ date: Date?) -> String {
        guard let date else { return "Pending" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct ServiceStopEstimatePlanPreview: View {
    let title: String
    let customerName: String
    let jobName: String
    let jobDescription: String
    let recommendedPriceCents: Int
    let planTierLabel: String
    let planDescription: String
    let jobTasks: [JobTask]
    let shoppingItems: [ShoppingListItem]
    let planNotes: [JobComment]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text([customerName, jobName].filter { !$0.isEmpty }.joined(separator: " - "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    previewMetric(
                        "\(jobTasks.count)",
                        title: "Services",
                        systemImage: "checklist"
                    )
                    previewMetric(
                        "\(shoppingItems.count)",
                        title: "Products",
                        systemImage: "shippingbox"
                    )
                    previewMetric(planTierLabel, title: "Plan", systemImage: "star")
                }

                if !jobDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    previewSection("Issue", systemImage: "exclamationmark.circle") {
                        Text(jobDescription)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !planDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    previewSection("Resolution Notes", systemImage: "text.bubble") {
                        Text(planDescription)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                previewSection("Services To Do", systemImage: "checklist") {
                    if jobTasks.isEmpty {
                        Text("No services were added yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(jobTasks) { task in
                                previewRow(
                                    title: task.name,
                                    subtitle: "\(task.type.rawValue) - \(task.estimatedTime) min",
                                    value: task.status.rawValue,
                                    systemImage: "checkmark.circle"
                                )
                            }
                        }
                    }
                }

                previewSection("Parts & Products", systemImage: "shippingbox") {
                    if shoppingItems.isEmpty {
                        Text("No parts or products were added yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(shoppingItems) { item in
                                previewRow(
                                    title: productDisplayName(item),
                                    subtitle: "Qty \(productQuantityText(item)) - \(item.subCategory.rawValue)",
                                    value: item.status.rawValue,
                                    systemImage: "shippingbox"
                                )
                            }
                        }
                    }
                }

                if recommendedPriceCents > 0 {
                    previewSection("Estimate Total", systemImage: "dollarsign.circle") {
                        Text(ServiceStopEstimatePlanMoneyFormatter.money(recommendedPriceCents))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.poolGreen)
                    }
                }

                previewSection("Plan Notes", systemImage: "note.text") {
                    if planNotes.isEmpty {
                        Text("No plan notes yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(planNotes.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(5)) { note in
                                Text(note.comment)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color.listColor.ignoresSafeArea())
    }

    private func productDisplayName(_ item: ShoppingListItem) -> String {
        let options = [
            item.productName,
            item.dbItemName,
            item.name
        ]

        return options
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Product / Part"
    }

    private func productQuantityText(_ item: ShoppingListItem) -> String {
        let quantity = item.quantity?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return quantity.isEmpty ? "1" : quantity
    }

    private func previewMetric(_ value: String, title: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value.isEmpty ? "-" : value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func previewSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
            content()
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func previewRow(title: String, subtitle: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 24, height: 24)
                .background(Color.poolBlue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if !value.isEmpty {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private enum ServiceStopEstimatePlanMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

private struct ServiceStopCustomerNotesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var masterDataManager: MasterDataManager

    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop?
    @Binding var notes: [CustomerNote]
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let onRefresh: () async -> Void

    @State private var newNote = ""
    @State private var selectedAudience: CustomerNoteAudience = .field
    @State private var newNoteResolved = false
    @State private var isAddingNote = false
    @State private var resolvingNoteIds: Set<String> = []
    @State private var addMessage: String? = nil

    private var fieldAudiences: [CustomerNoteAudience] {
        [.field, .all]
    }

    private var openNotesCount: Int {
        notes.filter {
            $0.isVisibleFromFieldStop &&
            !($0.resolved ?? false)
        }.count
    }

    private var authorName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? "Technician" : name
    }

    private var addMessageTint: Color {
        switch addMessage {
        case "Note added", "Note resolved", "Note reopened":
            return Color.poolGreen
        case .some:
            return Color.poolRed
        case .none:
            return Color.secondary
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.listColor.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        composer
                        notesList
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Customer Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await onRefresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Refresh customer notes")
                }
            }
            .safeAreaInset(edge: .bottom) {
                dismissNotesBar
            }
            .task {
                await onRefresh()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var dismissNotesBar: some View {
        Button {
            dismiss()
        } label: {
            Label("Dismiss Notes", systemImage: "xmark.circle")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 42, height: 42)
                    .background(Color.poolBlue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(serviceStop?.customerName ?? "Customer")
                        .font(.title3.weight(.semibold))

                    Text("Recent notes visible to field teams.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 8) {
                noteMetric("\(notes.count)", title: "Visible", systemImage: "text.bubble")
                noteMetric("\(openNotesCount)", title: "Open", systemImage: "exclamationmark.circle")
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add Customer Note", systemImage: "square.and.pencil")
                .font(.headline.weight(.semibold))

            Picker("Audience", selection: $selectedAudience) {
                ForEach(fieldAudiences) { audience in
                    Label(audience.title, systemImage: audience.systemImage)
                        .tag(audience)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: $newNoteResolved) {
                Label(newNoteResolved ? "Resolved" : "Open", systemImage: newNoteResolved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(Color.poolGreen)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $newNote)
                    .font(.subheadline)
                    .frame(minHeight: 104)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                    }

                if newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Add a note for the next technician or the full team...")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }

            HStack(spacing: 10) {
                if let addMessage {
                    Text(addMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(addMessageTint)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    Task { await addCustomerNote() }
                } label: {
                    if isAddingNote {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Label("Add Note", systemImage: "plus.message.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAddingNote || newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var notesList: some View {
        if isLoading {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 24)
        } else if let errorMessage {
            ContentUnavailableView(
                "Notes Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
            .padding(.vertical, 20)
        } else if notes.isEmpty {
            ContentUnavailableView(
                "No Field Notes",
                systemImage: "text.bubble",
                description: Text("Field and all-team customer notes will show here.")
            )
            .padding(.vertical, 20)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Label("Recent Notes", systemImage: "clock.arrow.circlepath")
                    .font(.headline.weight(.semibold))

                ForEach(notes.sorted { $0.displayDate > $1.displayDate }) { note in
                    noteRow(note)
                }
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func noteMetric(_ value: String, title: String, systemImage: String) -> some View {
        Label {
            Text("\(value) \(title)")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        } icon: {
            Image(systemName: systemImage)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private func noteRow(_ note: CustomerNote) -> some View {
        let isResolved = note.resolved ?? false
        let noteId = note.storedId ?? note.id
        let isResolving = resolvingNoteIds.contains(noteId)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.displayAuthor)
                        .font(.subheadline.weight(.semibold))

                    Text(note.displayDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Label(note.displayAudience.title, systemImage: note.displayAudience.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())

                    Text(isResolved ? "Resolved" : "Open")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isResolved ? Color.poolGreen : Color.poolRed)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((isResolved ? Color.poolGreen : Color.poolRed).opacity(0.12), in: Capsule())
                }
            }

            Text(note.displayText)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await toggleCustomerNoteResolved(note) }
            } label: {
                if isResolving {
                    ProgressView()
                        .frame(width: 18, height: 18)
                } else {
                    Label(
                        isResolved ? "Reopen" : "Mark Resolved",
                        systemImage: isResolved ? "arrow.uturn.left.circle" : "checkmark.circle"
                    )
                    .font(.caption.weight(.semibold))
                }
            }
            .buttonStyle(.bordered)
            .tint(isResolved ? Color.poolBlue : Color.poolGreen)
            .disabled(isResolving)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @MainActor
    private func toggleCustomerNoteResolved(_ note: CustomerNote) async {
        guard let serviceStop else {
            addMessage = "Missing service stop"
            return
        }

        let companyId = masterDataManager.currentCompany?.id ?? serviceStop.companyId
        let userId = masterDataManager.user?.id ?? ""
        let noteId = note.storedId ?? note.id

        guard !companyId.isEmpty, !userId.isEmpty, !noteId.isEmpty else {
            addMessage = "Missing note details"
            return
        }

        let nextResolved = !(note.resolved ?? false)
        resolvingNoteIds.insert(noteId)
        defer { resolvingNoteIds.remove(noteId) }

        do {
            try await dataService.updateCustomerNoteResolved(
                companyId: companyId,
                customerId: serviceStop.customerId,
                noteId: noteId,
                resolved: nextResolved,
                authorId: userId,
                authorName: authorName
            )

            if let index = notes.firstIndex(where: { ($0.storedId ?? $0.id) == noteId }) {
                notes[index].resolved = nextResolved
                notes[index].updatedAt = Date()
                notes[index].updatedAtMillis = Date().timeIntervalSince1970 * 1000
            }

            addMessage = nextResolved ? "Note resolved" : "Note reopened"
            await onRefresh()
        } catch {
            addMessage = "Could not update note"
            print("[ServiceStopCustomerNotesSheet][toggleCustomerNoteResolved] \(error)")
        }
    }

    @MainActor
    private func addCustomerNote() async {
        let trimmedNote = newNote.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNote.isEmpty else { return }
        guard let serviceStop else {
            addMessage = "Missing service stop"
            return
        }

        let companyId = masterDataManager.currentCompany?.id ?? serviceStop.companyId
        let userId = masterDataManager.user?.id ?? ""

        guard !companyId.isEmpty, !userId.isEmpty else {
            addMessage = "Missing company or user"
            return
        }

        isAddingNote = true
        defer { isAddingNote = false }

        let note = CustomerNote(
            storedId: "comp_cus_note_\(UUID().uuidString)",
            companyId: companyId,
            customerId: serviceStop.customerId,
            customerName: serviceStop.customerName,
            serviceLocationId: serviceStop.serviceLocationId,
            userId: userId,
            userName: authorName,
            authorId: userId,
            authorName: authorName,
            note: trimmedNote,
            comment: trimmedNote,
            audience: selectedAudience,
            visibility: selectedAudience.rawValue,
            resolved: newNoteResolved,
            date: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await dataService.uploadCustomerNote(
                companyId: companyId,
                customerId: serviceStop.customerId,
                note: note
            )
            newNote = ""
            newNoteResolved = false
            addMessage = "Note added"
            await onRefresh()
        } catch {
            addMessage = "Could not add note"
            print("[ServiceStopCustomerNotesSheet][addCustomerNote] \(error)")
        }
    }
}

extension ServiceStopDetailView2 {
    var verticalScreenSelector: some View {
        HStack(alignment:.top){
            VStack(alignment: .trailing, spacing: 16) {
                    //Info
                if  selectedScreen == .info {
                    Button(action: {
                        selectedScreen = .info
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "info.circle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Info")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .info
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "info.circle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Info")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .tasks {
                    Button(action: {
                        selectedScreen = .tasks
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "chart.bar.doc.horizontal")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Tasks")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .tasks
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "chart.bar.doc.horizontal")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Tasks")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if  selectedScreen == .waterDetails {
                    Button(action: {
                        selectedScreen = .waterDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "drop.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Water Details")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .waterDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "drop.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Water Details")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .equipmentDetails {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "spigot.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Equipment")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .equipmentDetails
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "spigot.fill")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Equipment")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
                if selectedScreen == .recap {
                    Button(action: {
                        selectedScreen = .recap
                        expandScreenSelector.toggle()
                    }, label: {
                        HStack{
                            Image(systemName: "checkerboard.rectangle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Recap")
                            }
                        }
                        .modifier(BlueButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                } else {
                    Button(action: {
                        selectedScreen = .recap
                        expandScreenSelector.toggle()
                        
                    }, label: {
                        HStack{
                            Image(systemName: "checkerboard.rectangle")
                            ZStack{
                                Text("Water Details")
                                    .foregroundColor(Color.clear)
                                Text("Recap")
                            }
                        }
                        .modifier(ListButtonModifier())
                        .modifier(OutLineButtonModifier())
                    })
                }
            }
            .padding(16)
        }
    }
    
    // Recap Screen information based on Recap View
    var recap: some View {
        ZStack {
            Color.listColor.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    if let stop = serviceStop {
                        VStack(alignment: .leading, spacing: 14) {
                            recapHeader(for: stop)
                            if stop.resolvedCategory == .serviceAgreementEstimate {
                                serviceAgreementFinishSummary(for: stop)
                            } else {
                                recapBody(for: stop)
                                serviceNotesRecap(for: stop)
                                observationRecap
                                taskRecap
                                photos
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 12)
                        .padding(.bottom, 18)
                    }
                }

                if currentContinuationGate == nil {
                    statusActionBar
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            finishGateOverlay
        }
    }

    @ViewBuilder
    private func recapBody(for stop: ServiceStop) -> some View {
        if stop.typeId == "2" {
            startUpRecap
        } else if stop.includeReadings || stop.includeDosages {
            waterRecap(for: stop)
        }
    }

    private func serviceAgreementFinishSummary(for stop: ServiceStop) -> some View {
        recapSection(title: "Survey Finish", systemImage: "list.clipboard") {
            VStack(alignment: .leading, spacing: 10) {
                finishSummaryRow(
                    title: "Survey",
                    value: "Body of water, equipment, photos, and recommendations are handled on the Survey tab.",
                    systemImage: "checklist"
                )

                finishSummaryRow(
                    title: "Agreement",
                    value: "Preview, email, and text the linked service agreement from the Agreement tab.",
                    systemImage: "doc.text"
                )

                if let price = stop.fieldRecommendedServiceAgreementPriceCents ?? stop.recommendedServiceAgreementPriceCents,
                   price > 0 {
                    finishSummaryRow(
                        title: "Recommended Price",
                        value: ServiceStopEstimatePlanMoneyFormatter.money(price),
                        systemImage: "dollarsign.circle"
                    )
                }
            }
        }
    }

    private func finishSummaryRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 26, height: 26)
                .background(Color.poolBlue.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    private func serviceNotesRecap(for stop: ServiceStop) -> some View {
        recapSection(title: "Service Notes", systemImage: "text.bubble.fill") {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $serviceNotes)
                        .font(.subheadline)
                        .frame(minHeight: 120)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                        }
                        .disabled(currentContinuationGate != nil)

                    if serviceNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Work performed, customer conversation, follow-up notes...")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                if currentContinuationGate != nil {
                    Label("Start the route or service stop before editing recap notes.", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 10) {
                    if let serviceNotesSaveMessage {
                        Text(serviceNotesSaveMessage)
                            .font(.caption)
                            .foregroundStyle(serviceNotesSaveMessage == "Saved" ? Color.poolGreen : Color.poolRed)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button(action: {
                        saveServiceNotes(for: stop)
                    }) {
                        if VM.isSavingServiceNotes {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Label(serviceNotes == lastSavedServiceNotes ? "Saved" : "Save", systemImage: "square.and.arrow.down")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(VM.isSavingServiceNotes || serviceNotes == lastSavedServiceNotes || currentContinuationGate != nil)
                }
            }
        }
    }

    private func recapHeader(for stop: ServiceStop) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Service Stop Recap")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(stop.customerName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(opStatus?.rawValue ?? stop.operationStatus.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    recapChip(shortDate(date: stop.serviceDate), systemImage: "calendar")
                    recapChip("\(VM.taskList.count) Tasks", systemImage: "checklist")
                    recapChip("\(VM.loadedImages.count + VM.selectedDripDropPhotos.count) Photos", systemImage: "photo")
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func recapChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    private var statusActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.35)

            HStack(spacing: 12) {
                switch opStatus {
                case .finished:
                    recapActionButton("Skip", systemImage: "forward", tint: Color.poolYellow, foreground: .black) {
                        showSkipReason = true
                    }

                    if let serviceStop {
                        recapActionButton("Reopen", systemImage: "arrow.uturn.left", tint: Color.poolRed, foreground: .white) {
                            markNotFinished(serviceStop)
                        }
                    }

                case .notFinished:
                    recapActionButton("Skip", systemImage: "forward", tint: Color.poolYellow, foreground: .black) {
                        showSkipReason = true
                    }

                    if let serviceStop {
                        recapActionButton("Finish", systemImage: "checkmark", tint: Color.poolGreen, foreground: .white) {
                            markFinished(serviceStop)
                        }
                    }

                case .skipped:
                    if let serviceStop {
                        recapActionButton("Unskip", systemImage: "arrow.uturn.left", tint: Color.poolYellow, foreground: .black) {
                            markNotFinished(serviceStop)
                        }
                    }

                case .none:
                    Text("Status unavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
    }

    private func recapActionButton(
        _ title: String,
        systemImage: String,
        tint: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard !isFinishingOrSkippingStop else { return }
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isFinishingOrSkippingStop)
        .opacity(isFinishingOrSkippingStop ? 0.65 : 1)
    }

    private var finishGateOverlay: some View {
        Group {
            if let serviceStop,
               let continuationGate = continuationGate(for: serviceStop) {
                ServiceStopContinuationBanner(title: continuationGate.title) {
                    handleContinuationGate(continuationGate, serviceStop: serviceStop)
                }
            }
        }
    }

    private var finishOrSkipLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.poolBlue)

                Text("Wait patiently \(currentUserFirstName)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .combine)
    }

    private func continuationGate(for serviceStop: ServiceStop) -> ServiceStopContinuationGate? {
        if vm.activeRoute?.status.requiresStartToContinueServiceStopWork == true {
            return .startRoute
        }

        if serviceStop.startTime == nil {
            return .startServiceStop
        }

        return nil
    }

    private func handleContinuationGate(_ gate: ServiceStopContinuationGate, serviceStop: ServiceStop) {
        switch gate {
        case .startRoute:
            vm.startActiveRoute(
                companyId: masterDataManager.currentCompany?.id,
                companyName: masterDataManager.currentCompany?.name,
                user: masterDataManager.user
            )
        case .startServiceStop:
            vm.startServiceStop(
                companyId: masterDataManager.currentCompany?.id,
                serviceStopId: serviceStop.id,
                startTime: vm.arrivalTimeForServiceStop(serviceStop.id) ?? Date()
            )
        }
    }

    private func waterRecap(for stop: ServiceStop) -> some View {
        recapSection(title: "Water Recap", systemImage: "drop.fill") {
            if VM.bodiesOfWater.isEmpty {
                emptyState(
                    title: "No Bodies Of Water",
                    message: "There is no water data to summarize for this stop.",
                    systemImage: "drop.triangle"
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(VM.bodiesOfWater) { BOW in
                            bodyOfWaterRecapCard(BOW, serviceStop: stop)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func bodyOfWaterRecapCard(_ BOW: BodyOfWater, serviceStop: ServiceStop) -> some View {
        let data = stopData(for: BOW)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(BOW.name)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                Text(data == nil ? "No Data" : "Recorded")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(data == nil ? Color.secondary : Color.poolGreen)
            }

            Divider()

            if serviceStop.includeReadings {
                waterValueGroup(title: "Readings", systemImage: "testtube.2") {
                    readingRows(for: data)
                }
            }

            if serviceStop.includeReadings && serviceStop.includeDosages {
                Divider()
            }

            if serviceStop.includeDosages {
                waterValueGroup(title: "Dosages", systemImage: "drop.degreesign") {
                    dosageRows(for: data)
                }
            }
        }
        .padding(14)
        .frame(width: 280, alignment: .topLeading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func waterValueGroup<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(spacing: 7) {
                content()
            }
        }
    }

    @ViewBuilder
    private func readingRows(for data: StopData?) -> some View {
        if sortedReadingTemplates.isEmpty {
            if let readings = data?.readings, !readings.isEmpty {
                ForEach(readings) { reading in
                    waterValueRow(
                        name: reading.name ?? "Reading",
                        value: formattedAmount(reading.amount, unit: reading.UOM),
                        isWarning: false
                    )
                }
            } else {
                waterValueRow(name: "Readings", value: "-", isWarning: false)
            }
        } else {
            ForEach(sortedReadingTemplates) { template in
                waterValueRow(
                    name: template.name,
                    value: readingValue(for: template, in: data),
                    isWarning: readingIsOutsideWarning(for: template, in: data)
                )
            }
        }
    }

    @ViewBuilder
    private func dosageRows(for data: StopData?) -> some View {
        if sortedDosageTemplates.isEmpty {
            if let dosages = data?.dosages, !dosages.isEmpty {
                ForEach(dosages) { dosage in
                    waterValueRow(
                        name: dosage.name ?? "Dosage",
                        value: formattedAmount(dosage.amount, unit: dosage.UOM),
                        isWarning: false
                    )
                }
            } else {
                waterValueRow(name: "Dosages", value: "-", isWarning: false)
            }
        } else {
            ForEach(sortedDosageTemplates) { template in
                waterValueRow(
                    name: template.name ?? "Dosage",
                    value: dosageValue(for: template, in: data),
                    isWarning: false
                )
            }
        }
    }

    private func waterValueRow(name: String, value: String, isWarning: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isWarning ? Color.poolRed : Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func readingValue(for template: SavedReadingsTemplate, in data: StopData?) -> String {
        guard let data else { return "-" }
        let reading = reading(for: template, in: data)

        return formattedAmount(reading?.amount, unit: reading?.UOM)
    }

    private func dosageValue(for template: SavedDosageTemplate, in data: StopData?) -> String {
        guard let data else { return "-" }
        let dosage = dosage(for: template, in: data)

        return formattedAmount(dosage?.amount, unit: dosage?.UOM)
    }

    private var sortedReadingTemplates: [SavedReadingsTemplate] {
        VM.readingTemplates.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.name < rhs.name
            }

            return lhs.order < rhs.order
        }
    }

    private var sortedDosageTemplates: [SavedDosageTemplate] {
        VM.dosageTemplates.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return (lhs.name ?? "") < (rhs.name ?? "")
            }

            return lhs.order < rhs.order
        }
    }

    private func stopData(for BOW: BodyOfWater) -> StopData? {
        let loadedData = VM.serviceLocationStopData.first { $0.bodyOfWaterId == BOW.id }

        if stopData.bodyOfWaterId == BOW.id && (loadedData == nil || hasRecapContent(stopData)) {
            return stopData
        }

        return loadedData
    }

    private func hasRecapContent(_ data: StopData) -> Bool {
        !data.readings.isEmpty ||
        !data.dosages.isEmpty ||
        !data.observation.isEmpty ||
        !data.equipmentMeasurements.isEmpty
    }

    private func reading(for template: SavedReadingsTemplate, in data: StopData) -> Reading? {
        let templateKeys = [
            template.id,
            template.readingsTemplateId,
            template.name
        ]

        return data.readings.first { reading in
            guard itemMatchesBodyOfWater(reading.bodyOfWaterId, dataBodyOfWaterId: data.bodyOfWaterId) else { return false }

            return templateKeys.contains { key in
                matches(key, reading.templateId) ||
                matches(key, reading.universalTemplateId) ||
                matches(key, reading.name)
            }
        }
    }

    private func dosage(for template: SavedDosageTemplate, in data: StopData) -> Dosage? {
        let templateKeys = [
            template.id,
            template.dosageTemplateId,
            template.name ?? ""
        ]

        return data.dosages.first { dosage in
            guard itemMatchesBodyOfWater(dosage.bodyOfWaterId, dataBodyOfWaterId: data.bodyOfWaterId) else { return false }

            return templateKeys.contains { key in
                matches(key, dosage.templateId) ||
                matches(key, dosage.universalTemplateId) ||
                matches(key, dosage.name)
            }
        }
    }

    private func itemMatchesBodyOfWater(_ itemBodyOfWaterId: String, dataBodyOfWaterId: String) -> Bool {
        let itemId = normalizedTemplateKey(itemBodyOfWaterId)
        let dataId = normalizedTemplateKey(dataBodyOfWaterId)

        return itemId.isEmpty || itemId == dataId
    }

    private func matches(_ lhs: String?, _ rhs: String?) -> Bool {
        let left = normalizedTemplateKey(lhs)
        let right = normalizedTemplateKey(rhs)

        return !left.isEmpty && left == right
    }

    private func normalizedTemplateKey(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func formattedAmount(_ amount: String?, unit: String?) -> String {
        let value = (amount ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let unit = (unit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else { return "-" }
        guard !unit.isEmpty else { return value }

        return "\(value) \(unit)"
    }

    private func readingIsOutsideWarning(_ reading: Reading?, template: SavedReadingsTemplate) -> Bool {
        guard
            let reading,
            let amountText = reading.amount,
            let amount = Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            return false
        }

        if let highWarning = template.highWarning, amount > highWarning {
            return true
        }

        if let lowWarning = template.lowWarning, amount < lowWarning {
            return true
        }

        return false
    }

    private func readingIsOutsideWarning(for template: SavedReadingsTemplate, in data: StopData?) -> Bool {
        guard let data else { return false }
        return readingIsOutsideWarning(reading(for: template, in: data), template: template)
    }

    var photos: some View {
        recapSection(title: "Photos", systemImage: "camera.fill") {
            if VM.isUploadingPhotos || !VM.selectedDripDropPhotos.isEmpty {
                DripDropPhotoUploadIndicator(count: max(VM.selectedDripDropPhotos.count, 1))
            }

            if let uploadError = VM.photoUploadErrorMessage {
                Label(uploadError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.poolRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.poolRed.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if VM.loadedImages.isEmpty && VM.selectedDripDropPhotos.isEmpty {
                DripDropCompactPhotoEmptyState(title: "No photos added for this stop")
            } else {
                DripDropStoredImageRow(images: VM.loadedImages)
            }

            PhotoContentView(selectedImages: $VM.selectedDripDropPhotos)
                .disabled(currentContinuationGate != nil)
                .opacity(currentContinuationGate == nil ? 1 : 0.55)
        }
    }

    var taskRecap: some View {
        recapSection(title: "Tasks", systemImage: "checklist") {
            if VM.taskList.isEmpty {
                emptyState(
                    title: "No Tasks",
                    message: "There are no tasks to recap for this stop.",
                    systemImage: "checklist.unchecked"
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(VM.taskList, id:\.self) { task in
                        HStack(spacing: 10) {
                            Image(systemName: task.status == .finished ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.status == .finished ? Color.poolGreen : .secondary)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)

                                Text(task.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    var observationRecap: some View {
        let observations = combinedObservations

        return recapSection(title: "Observations", systemImage: "eye.fill") {
            if observations.isEmpty {
                emptyState(
                    title: "No Observations",
                    message: "There are no observations recorded for this stop.",
                    systemImage: "eye.slash"
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(observations, id:\.self) { observation in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 3)

                            Text(observation)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private var combinedObservations: [String] {
        let observations = VM.serviceLocationStopData
            .flatMap(\.observation)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var seen = Set<String>()

        return (observations + stopData.observation).filter { observation in
            let trimmedObservation = observation.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedObservation.isEmpty else { return false }

            return seen.insert(trimmedObservation).inserted
        }
    }

    var startUpRecap: some View {
        recapSection(title: "Start Up Recap", systemImage: "power") {
            emptyState(
                title: "Start Up Recap",
                message: "Start up recap details will appear here.",
                systemImage: "sparkles"
            )
        }
    }

    private func recapSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title, systemImage: systemImage)
            content()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? masterDataManager.user?.email ?? "Technician" : name
    }

    private var currentUserFirstName: String {
        let firstName = masterDataManager.user?.firstName ?? ""
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedFirstName.isEmpty ? "there" : trimmedFirstName
    }

    private func linkedJobId(for stop: ServiceStop) -> String {
        stop.jobId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func serviceStopLabel(_ stop: ServiceStop) -> String {
        let internalId = stop.internalId.trimmingCharacters(in: .whitespacesAndNewlines)
        return internalId.isEmpty ? stop.id : internalId
    }

    private func addLinkedJobComment(
        companyId: String,
        stop: ServiceStop,
        comment: String,
        resolved: Bool = false
    ) async throws {
        let jobId = linkedJobId(for: stop)
        guard !jobId.isEmpty else { return }

        let userId = masterDataManager.user?.id ?? ""
        let authorName = currentUserDisplayName
        let jobComment = JobComment(
            id: "comp_wo_com_" + UUID().uuidString,
            jobId: jobId,
            companyId: companyId,
            userId: userId,
            userName: authorName,
            authorId: userId,
            authorName: authorName,
            date: Date(),
            comment: comment,
            resolved: resolved
        )

        try await dataService.addWorkOrderComment(
            companyId: companyId,
            workOrderId: jobId,
            comment: jobComment
        )
    }

    private func serviceNotesJobComment(for stop: ServiceStop, notes: String) -> String {
        """
        Service notes from field service stop \(serviceStopLabel(stop)) by \(currentUserDisplayName):

        \(notes)
        """
    }

    private func jobCompletionPromptIfEligible(
        companyId: String,
        userId: String,
        stop: ServiceStop
    ) async throws -> FieldJobCompletionPrompt? {
        let jobId = linkedJobId(for: stop)
        guard !jobId.isEmpty else { return nil }

        let job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
        guard job.operationStatus != .finished else { return nil }

        let jobTasks = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)
        let plannedServiceStops = (try? await dataService.fetchJobPlannedServiceStops(
            companyId: companyId,
            jobId: jobId
        )) ?? []
        let loadedStopTasks = VM.taskList.isEmpty
            ? ((try? await dataService.getServiceStopTasks(companyId: companyId, serviceStopId: stop.id)) ?? [])
            : VM.taskList
        let finishedStopJobTaskIds = Set(loadedStopTasks.compactMap { task -> String? in
            let jobTaskId = task.jobTaskId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !jobTaskId.isEmpty, task.status == .finished else { return nil }
            return jobTaskId
        })
        let unfinishedStopJobTaskIds = Set(loadedStopTasks.compactMap { task -> String? in
            let jobTaskId = task.jobTaskId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !jobTaskId.isEmpty, task.status != .finished else { return nil }
            return jobTaskId
        })
        let unfinishedJobTaskIds = Set(jobTasks.compactMap { task -> String? in
            if finishedStopJobTaskIds.contains(task.id) {
                return nil
            }

            return task.status == .finished ? nil : task.id
        })
        let prefilledJobTaskIds = unfinishedStopJobTaskIds.intersection(unfinishedJobTaskIds)
        guard unfinishedJobTaskIds.isEmpty || !prefilledJobTaskIds.isEmpty else { return nil }

        let jobLabel = [job.internalId, job.type]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " - ")

        return FieldJobCompletionPrompt(
            companyId: companyId,
            jobId: jobId,
            job: job,
            serviceStop: stop,
            jobLabel: jobLabel.isEmpty ? jobId : jobLabel,
            serviceStopLabel: serviceStopLabel(stop),
            userId: userId,
            userName: currentUserDisplayName,
            taskCount: jobTasks.count,
            unfinishedTaskCount: unfinishedJobTaskIds.count,
            prefilledJobTaskIds: prefilledJobTaskIds,
            jobTasks: jobTasks,
            plannedServiceStops: plannedServiceStops
        )
    }

    private func markFinished(_ stop: ServiceStop) {
        guard !isFinishingOrSkippingStop else { return }
        guard let company = masterDataManager.currentCompany, let user = masterDataManager.user else {
            print("Either Invalid Company or active Route")
            return
        }

        finishErrorMessage = nil
        statusActionInProgress = .finished
        opStatus = .finished
        let previousStop = vm.optimisticallyFinishServiceStop(stop)

        Task {
            var shouldNavigateBack = false
            defer {
                statusActionInProgress = nil

                if shouldNavigateBack {
                    navigationManager.goBack()
                }
            }

            do {
                print("")
                print("Finishing Screen")
                print("-----------------")

                try await VM.updateServicestopOperationStatus(
                    companyId: company.id,
                    currentUserId: user.id,
                    stop: stop,
                    operationStatus: .finished
                )
            } catch {
                print("Failed To Updated Finish Stops \(stop.id)")
                print(error)
                finishErrorMessage = error.localizedDescription
                if let previousStop {
                    vm.restoreServiceStopAfterOptimisticUpdate(previousStop)
                    opStatus = previousStop.operationStatus
                } else {
                    opStatus = stop.operationStatus
                }
                vm.alertMessage = error.localizedDescription
                vm.showAlert = true
                print("")
                return
            }

            do {
                try await saveServiceNotesIfNeeded(companyId: company.id, stop: stop)
            } catch {
                print("Finished service stop \(stop.id), but failed to save service notes")
                print(error)
                finishErrorMessage = error.localizedDescription
                vm.alertMessage = "Stop finished, but service notes did not save: \(error.localizedDescription)"
                vm.showAlert = true
            }

            shouldNavigateBack = true
        }
    }

    private func markNotFinished(_ stop: ServiceStop) {
        guard !isFinishingOrSkippingStop else { return }
        guard let company = masterDataManager.currentCompany, let user = masterDataManager.user else {
            print("Either Invalid Company or active Route")
            return
        }

        finishErrorMessage = nil
        opStatus = .notFinished
        let previousStop = vm.optimisticallyReopenServiceStop(stop)

        Task {
            do {
                print("")
                try await saveServiceNotesIfNeeded(companyId: company.id, stop: stop)

                try await VM.updateServicestopOperationStatus(
                    companyId: company.id,
                    currentUserId: user.id,
                    stop: stop,
                    operationStatus: .notFinished
                )

                if stop.otherCompany && stop.contractedCompanyId != "" {
                    try await VM.updateServicestopOperationStatus(
                        companyId: stop.contractedCompanyId,
                        currentUserId: user.id,
                        stop: stop,
                        operationStatus: .notFinished
                    )
                }

                print("Un finished")
                print("Successful")
                print("")
            } catch {
                print("Failed To Updated Finish Stops \(stop.id)")
                print(error)
                finishErrorMessage = error.localizedDescription
                if let previousStop {
                    vm.restoreServiceStopAfterOptimisticUpdate(previousStop)
                    opStatus = previousStop.operationStatus
                } else {
                    opStatus = stop.operationStatus
                }
                print("")
            }
        }
    }

    private func markSkipped(_ stop: ServiceStop, reason: String) {
        guard !isFinishingOrSkippingStop else { return }
        guard let company = masterDataManager.currentCompany, let user = masterDataManager.user else {
            print("Either Invalid Company or active Route")
            return
        }

        finishErrorMessage = nil
        statusActionInProgress = .skipped
        opStatus = .skipped
        let previousStop = vm.optimisticallySkipServiceStop(stop)

        Task {
            var shouldNavigateBack = false
            defer {
                statusActionInProgress = nil

                if shouldNavigateBack {
                    navigationManager.goBack()
                }
            }

            do {
                try await VM.updateServicestopOperationStatus(
                    companyId: company.id,
                    currentUserId: user.id,
                    stop: stop,
                    operationStatus: .skipped
                )

                if stop.otherCompany && stop.contractedCompanyId != "" {
                    try await VM.updateServicestopOperationStatus(
                        companyId: stop.contractedCompanyId,
                        currentUserId: user.id,
                        stop: stop,
                        operationStatus: .skipped
                    )
                }
            } catch {
                print("Failed To Skip Service Stop \(stop.id)")
                print(error)
                finishErrorMessage = error.localizedDescription
                if let previousStop {
                    vm.restoreServiceStopAfterOptimisticUpdate(previousStop)
                    opStatus = previousStop.operationStatus
                } else {
                    opStatus = stop.operationStatus
                }
                vm.alertMessage = error.localizedDescription
                vm.showAlert = true
                print("")
                return
            }

            do {
                try await saveServiceNotesForSkipIfNeeded(
                    companyId: company.id,
                    stop: stop,
                    reason: reason
                )
            } catch {
                print("Skipped service stop \(stop.id), but failed to save skip reason")
                print(error)
                finishErrorMessage = error.localizedDescription
                vm.alertMessage = "Stop skipped, but the skip reason did not save: \(error.localizedDescription)"
                vm.showAlert = true
            }

            shouldNavigateBack = true
        }
    }

    private func completeLinkedJob(_ prompt: FieldJobCompletionPrompt) {
        guard !isCompletingLinkedJob else { return }

        Task {
            isCompletingLinkedJob = true
            defer { isCompletingLinkedJob = false }

            do {
                let jobCompletionViewModel = JobDetailViewModel(dataService: dataService)
                try await jobCompletionViewModel.markJobAsFinished(
                    companyId: prompt.companyId,
                    job: prompt.job,
                    jobTasks: prompt.jobTasks,
                    completedByUserId: prompt.userId,
                    completedByUserName: prompt.userName,
                    addCompletionComment: false
                )

                let comment = """
                Job finished in field by \(prompt.userName).

                Service stop: \(prompt.serviceStopLabel)
                Job tasks complete: \(prompt.taskCount)
                """

                let jobComment = JobComment(
                    id: "comp_wo_com_" + UUID().uuidString,
                    jobId: prompt.jobId,
                    companyId: prompt.companyId,
                    userId: prompt.userId,
                    userName: prompt.userName,
                    authorId: prompt.userId,
                    authorName: prompt.userName,
                    date: Date(),
                    comment: comment,
                    resolved: true
                )

                try await dataService.addWorkOrderComment(
                    companyId: prompt.companyId,
                    workOrderId: prompt.jobId,
                    comment: jobComment
                )

                linkedJobCompletionFlow = nil
            } catch {
                finishErrorMessage = error.localizedDescription
                print("[ServiceStopDetailView2][completeLinkedJob] \(error)")
            }
        }
    }

    private func saveServiceNotes(for stop: ServiceStop) {
        guard let companyId = masterDataManager.currentCompany?.id else {
            serviceNotesSaveMessage = "Unable to save"
            return
        }

        let notesToSave = serviceNotes
        serviceNotesSaveMessage = nil

        Task {
            do {
                try await saveServiceNotesIfNeeded(companyId: companyId, stop: stop, notesToSave: notesToSave)
            } catch {
                serviceNotesSaveMessage = "Unable to save"
                print("Failed to save service notes for \(stop.id)")
                print(error)
            }
        }
    }

    private func saveServiceNotesIfNeeded(
        companyId: String,
        stop: ServiceStop,
        notesToSave: String? = nil
    ) async throws {
        let serviceNotesToSave = notesToSave ?? serviceNotes
        guard serviceNotesToSave != lastSavedServiceNotes else { return }

        try await VM.updateServiceNotes(
            companyId: companyId,
            serviceStopId: stop.id,
            serviceNotes: serviceNotesToSave
        )

        let trimmedNotes = serviceNotesToSave.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty, !linkedJobId(for: stop).isEmpty {
            try await addLinkedJobComment(
                companyId: companyId,
                stop: stop,
                comment: serviceNotesJobComment(for: stop, notes: trimmedNotes)
            )
        }

        lastSavedServiceNotes = serviceNotesToSave
        serviceNotesSaveMessage = "Saved"
    }

    private func saveServiceNotesForSkipIfNeeded(
        companyId: String,
        stop: ServiceStop,
        reason: String
    ) async throws {
        let notesToSave = serviceNotesAddingSkipReason(reason)
        try await saveServiceNotesIfNeeded(
            companyId: companyId,
            stop: stop,
            notesToSave: notesToSave
        )
        serviceNotes = notesToSave
    }

    private func serviceNotesAddingSkipReason(_ reason: String) -> String {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReason.isEmpty else { return serviceNotes }

        let skipNote = "Skipped: \(trimmedReason)"
        let trimmedNotes = serviceNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedNotes.isEmpty else { return skipNote }
        guard !trimmedNotes.contains(skipNote) else { return serviceNotes }

        return "\(serviceNotes)\n\n\(skipNote)"
    }
}
