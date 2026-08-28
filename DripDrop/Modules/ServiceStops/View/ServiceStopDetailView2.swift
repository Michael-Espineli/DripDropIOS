//
//  ServiceStopDetailView 2.swift
//  DripDrop
//
//  Created by Michael Espineli on 2/3/26.
//
// For Route
import SwiftUI
import UniformTypeIdentifiers

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

    private var oneOffTaskCount: Int {
        VM.taskList.filter(isOneOffServiceStopTask).count
    }

    private func isOneOffServiceStopTask(_ task: ServiceStopTask) -> Bool {
        let recurringTaskId = task.recurringServiceStopTaskId.trimmingCharacters(in: .whitespacesAndNewlines)
        let jobTaskId = task.jobTaskId.trimmingCharacters(in: .whitespacesAndNewlines)

        return recurringTaskId.isEmpty && jobTaskId.isEmpty && task.status != .finished
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

                    TabView(selection: $selectedTab) {
                        categoryTabs(for: stop)
                     }
                    
                }
            }
        
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                serviceStopInfoToolbarButton
                customerNotesToolbarButton
            }
        }
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
        .task {
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
        } message: {
            Text("Will send to customer and manager")
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
        if skipReason == "" {
            print("Did not Provide a Reason")
        } else {
            print("You skipped because \(skipReason)")
        }
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
        case .job, .jobEstimate, .customerRelationship:
            return "Follow Up"
        }
    }

    @ViewBuilder
    func categoryTabs(for stop: ServiceStop) -> some View {
        switch stop.resolvedCategory {
        case .route:
            followUpTab(for: stop)
            taskTab
            waterTab
            equipmentTab(for: stop)
            finishTab
        case .job:
            followUpTab(for: stop)
            taskTab
            jobCommentsTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .jobEstimate:
            followUpTab(for: stop)
            taskTab
            jobCommentsTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .serviceAgreementEstimate:
            followUpTab(for: stop)
            serviceAgreementSurveyTab(for: stop)
            finishTab
        case .customerRelationship:
            followUpTab(for: stop)
            taskTab
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
        ServiceStopTaskView(dataService: dataService, taskList: $VM.taskList, serviceStopId: serviceStopId)
            .tabItem {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("Tasks")
            }
            .badge(oneOffTaskCount)
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
            serviceLocation: VM.location
        )
        .tabItem {
            Image(systemName: "list.clipboard")
            Text("Survey")
        }
        .tag("Survey")
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

        let item = ShoppingListItem(
            id: itemId,
            category: category,
            subCategory: draft.subCategory,
            status: .needToPurchase,
            purchaserId: user.id,
            purchaserName: purchaserName.isEmpty ? serviceStop.tech : purchaserName,
            genericItemId: draft.selectedDataBaseItem.universalEquipmentId ?? "",
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
            dbItemId: draft.selectedDataBaseItemId,
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
    case database = "Database"

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
    @State private var selectedDatabaseItem = ServiceStopPartApprovalSheet.emptyDataBaseItem
    @State private var showDatabasePicker = false
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
            return selectedDatabaseItem.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var itemDescription: String {
        let trimmedNote = customerNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNote.isEmpty { return trimmedNote }
        if itemMode == .database { return selectedDatabaseItem.description }
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
            return Int(selectedDatabaseItem.rate.rounded())
        }
    }

    private var unitPriceCents: Int {
        switch itemMode {
        case .manual:
            return cents(fromDollarInput: manualUnitPrice)
        case .database:
            return Int((selectedDatabaseItem.sellPrice ?? 0).rounded())
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
            .sheet(isPresented: $showDatabasePicker) {
                DataBaseItemPicker(
                    dataService: dataService,
                    DBItem: $selectedDatabaseItem,
                    category: .equipment
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
                    showDatabasePicker = true
                } label: {
                    HStack {
                        Text(selectedDatabaseItem.id.isEmpty ? "Select database item" : selectedDatabaseItem.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedDatabaseItem.id.isEmpty ? .secondary : .primary)
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
            dbItemId: itemMode == .database ? selectedDatabaseItem.id : "",
            dbItemName: itemMode == .database ? selectedDatabaseItem.name : "",
            genericItemId: itemMode == .database ? selectedDatabaseItem.universalEquipmentId ?? "" : "",
            subCategory: itemMode == .database ? "Data Base" : "Part",
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

    private static var emptyDataBaseItem: DataBaseItem {
        DataBaseItem(
            id: "",
            name: "",
            rate: 0,
            storeName: "",
            venderId: "",
            category: .equipment,
            subCategory: .misc,
            description: "",
            dateUpdated: Date(),
            sku: "",
            billable: false,
            color: "",
            size: "",
            UOM: .unit
        )
    }
}

private struct ServiceStopJobCommentsView: View {
    let dataService: any ProductionDataServiceProtocol
    let serviceStop: ServiceStop

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
            .task {
                await onRefresh()
            }
        }
        .presentationDetents([.medium, .large])
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
                            recapBody(for: stop)
                            serviceNotesRecap(for: stop)
                            observationRecap
                            taskRecap
                            photos
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
                        opStatus = .skipped
                        showSkipReason = true
                    }

                    if let serviceStop {
                        recapActionButton("Reopen", systemImage: "arrow.uturn.left", tint: Color.poolRed, foreground: .white) {
                            markNotFinished(serviceStop)
                        }
                    }

                case .notFinished:
                    recapActionButton("Skip", systemImage: "forward", tint: Color.poolYellow, foreground: .black) {
                        opStatus = .skipped
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
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tint, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
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
            templateKeys.contains { key in
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
            templateKeys.contains { key in
                matches(key, dosage.templateId) ||
                matches(key, dosage.universalTemplateId) ||
                matches(key, dosage.name)
            }
        }
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
            if VM.isUploadingPhotos {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Uploading photos")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if VM.loadedImages.isEmpty && VM.selectedDripDropPhotos.isEmpty {
                emptyState(
                    title: "No Photos",
                    message: "Add a photo if this stop needs one for completion.",
                    systemImage: "photo"
                )
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
        Task {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                opStatus = .finished
                do {
                    print("")
                    print("Finishing Screen")
                    print("-----------------")

                    try await saveServiceNotesIfNeeded(companyId: company.id, stop: stop)

                    try await VM.updateServicestopOperationStatus(
                        companyId: company.id,
                        currentUserId: user.id,
                        stop: stop,
                        operationStatus: .finished
                    )

                    if let prompt = try await jobCompletionPromptIfEligible(
                        companyId: company.id,
                        userId: user.id,
                        stop: stop
                    ) {
                        shouldNavigateBackAfterLinkedJobFlowDismiss = true
                        linkedJobCompletionFlow = .decision(prompt)
                        return
                    }

                    navigationManager.goBack()
                } catch {
                    print("Failed To Updated Finish Stops \(stop.id)")
                    print(error)
                    finishErrorMessage = error.localizedDescription
                    print("")
                }
            } else {
                print("Either Invalid Company or active Route")
            }
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

    private func markNotFinished(_ stop: ServiceStop) {
        Task {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                opStatus = .notFinished
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
                    print("")
                }

                navigationManager.goBack()
            } else {
                print("Either Invalid Company or active Route")
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
}
