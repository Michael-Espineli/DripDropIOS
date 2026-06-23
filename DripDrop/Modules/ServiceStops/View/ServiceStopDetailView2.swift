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
    @State private var selectedTab = "Water"
    @State private var serviceNotes = ""
    @State private var lastSavedServiceNotes = ""
    @State private var serviceNotesSaveMessage: String? = nil
    
    private var serviceStop: ServiceStop? {
        vm.serviceStopList.first { $0.id == serviceStopId }
    }

    private var currentContinuationGate: ServiceStopContinuationGate? {
        guard let serviceStop else { return nil }
        return continuationGate(for: serviceStop)
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
        .environmentObject(VM)
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
                        stopData = VM.serviceLocationStopData.first(where: { $0.serviceLocationId == serviceStop.serviceLocationId }) ?? StopData(
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
    }
    func submitSkipReason() {
        if skipReason == "" {
            print("Did not Provide a Reason")
        } else {
            print("You skipped because \(skipReason)")
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
            return "Info"
        }
    }

    @ViewBuilder
    func categoryTabs(for stop: ServiceStop) -> some View {
        switch stop.resolvedCategory {
        case .route:
            infoTab
            taskTab
            waterTab
            equipmentTab(for: stop)
            finishTab
        case .job:
            infoTab
            taskTab
            jobCommentsTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .jobEstimate:
            infoTab
            taskTab
            jobCommentsTab(for: stop)
            equipmentTab(for: stop)
            finishTab
        case .serviceAgreementEstimate:
            infoTab
            serviceAgreementSurveyTab(for: stop)
            finishTab
        case .customerRelationship:
            infoTab
            taskTab
            finishTab
        }
    }

    var infoTab: some View {
        ServiceStopInfoView(dataService: dataService, serviceStopId: serviceStopId)
            .tabItem {
                Image(systemName: "info.circle")
                Text("Info")
            }
            .tag("Info")
    }

    var taskTab: some View {
        ServiceStopTaskView(dataService: dataService, taskList: $VM.taskList, serviceStopId: serviceStopId)
            .tabItem {
                Image(systemName: "chart.bar.doc.horizontal")
                Text("Tasks")
            }
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
        ServiceStopUtilityView(stopData: $stopData, serviceStopId: serviceStopId)
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
            .disabled(vm.activeRoute?.status != .inProgress)
            .disabled(serviceStop?.startTime == nil)
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

                    if serviceNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Work performed, customer conversation, follow-up notes...")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
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
                    .disabled(VM.isSavingServiceNotes || serviceNotes == lastSavedServiceNotes)
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
                        recapActionButton("Finish", systemImage: "checkmark", tint: Color.poolGreen, foreground: .black) {
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
        lastSavedServiceNotes = serviceNotesToSave
        serviceNotesSaveMessage = "Saved"
    }
}
