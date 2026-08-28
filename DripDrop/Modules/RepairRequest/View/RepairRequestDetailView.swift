//
//  RepairRequestDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI
@MainActor
final class RepairRequestDetailViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    @Published private(set) var repairRequest: RepairRequest
    init(dataService:any ProductionDataServiceProtocol,repairRequest:RepairRequest){
        self.dataService = dataService
        self.repairRequest = repairRequest
    }
    @Published private(set) var workOrder: Job? = nil
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var serviceLocation: ServiceLocation? = nil
    @Published private(set) var bodyOfWater: BodyOfWater? = nil
    @Published private(set) var equipment: Equipment? = nil
    @Published private(set) var comments: [JobComment] = []
    
    @Published var status:RepairRequestStatus = .unresolved
    @Published var equipmentStatus: EquipmentStatus = .operational
    @Published var photoUrls:[DripDropStoredImage] = []
    
    @Published var newPhotoUrls:[DripDropImage] = []
    @Published var jobIdList:[String] = []
    @Published var jobId:String = ""
    @Published var returnJobId:String = ""
    @Published var description:String = ""
    @Published var newComment:String = ""
    @Published var commentsLoading:Bool = false
    @Published var isAddingComment:Bool = false
    @Published var commentMessage:String? = nil
    
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var job:Job = Job(
        id: "",
        internalId: "",
        type: "",
        dateCreated: Date(),
        description: "",
        operationStatus: .estimatePending,
        billingStatus: .draft,
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceStopIds: [],
        laborContractIds: [],
        adminId: "",
        adminName: "",
        rate: 0,
        laborCost: 0,
        otherCompany: true,
        receivedLaborContractId: "",
        receiverId: "",
        senderId : "",
        dateEstimateAccepted: nil,
        estimateAcceptedById: nil,
        estimateAcceptType: nil,
        estimateAcceptedNotes: nil,
        invoiceDate: nil,
        invoiceRef: nil,
        invoiceType: nil,
        invoiceNotes: nil
    )

    func onLoad(companyId: String?){
        Task{
            await applyRepairRequestState(companyId: companyId)
        }
    }

    func refreshRepairRequest(companyId: String?) async {
        guard let companyId else {
            await applyRepairRequestState(companyId: nil)
            return
        }

        do {
            self.repairRequest = try await dataService.getSpecificRepairRequest(companyId: companyId, repairRequestId: repairRequest.id)
        } catch {
            print("[RepairRequestDetailViewModel][refreshRepairRequest] Error: \(error)")
        }

        await applyRepairRequestState(companyId: companyId)
    }

    private func applyRepairRequestState(companyId: String?) async {
        self.status = repairRequest.status.selectableValue
        self.photoUrls = repairRequest.photoUrls
        self.jobIdList = repairRequest.jobIds
        self.description = repairRequest.description
        self.serviceLocation = nil
        self.bodyOfWater = nil
        self.equipment = nil

        guard let companyId else { return }

        do {
            if repairRequest.customerId != "" {
                self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: repairRequest.customerId)
            }
        } catch {
            print("[RepairRequestDetailViewModel][applyRepairRequestState][customer] Error: \(error)")
        }

        await loadSiteContext(companyId: companyId)
        await loadComments(companyId: companyId)
    }

    func loadSiteContext(companyId: String) async {
        let locationId = cleanId(repairRequest.locationId)
        let bodyOfWaterId = cleanId(repairRequest.bodyOfWaterId)
        let equipmentId = cleanId(repairRequest.equipmentId)

        if !locationId.isEmpty {
            do {
                self.serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: locationId)
            } catch {
                print("[RepairRequestDetailViewModel][loadSiteContext][location] Error: \(error)")
            }
        }

        if !bodyOfWaterId.isEmpty {
            do {
                self.bodyOfWater = try await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: bodyOfWaterId)
            } catch {
                print("[RepairRequestDetailViewModel][loadSiteContext][bodyOfWater] Error: \(error)")
            }
        }

        if !equipmentId.isEmpty {
            do {
                let equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: equipmentId)
                self.equipment = equipment
                self.equipmentStatus = equipment.status

                if self.serviceLocation == nil, !equipment.serviceLocationId.isEmpty {
                    self.serviceLocation = try? await dataService.getServiceLocationById(companyId: companyId, locationId: equipment.serviceLocationId)
                }

                if self.bodyOfWater == nil, !equipment.bodyOfWaterId.isEmpty {
                    self.bodyOfWater = try? await dataService.getSpecificBodyOfWater(companyId: companyId, bodyOfWaterId: equipment.bodyOfWaterId)
                }
            } catch {
                print("[RepairRequestDetailViewModel][loadSiteContext][equipment] Error: \(error)")
            }
        }
    }

    func loadComments(companyId: String?) async {
        guard let companyId else { return }

        commentsLoading = true
        defer { commentsLoading = false }

        do {
            comments = try await dataService.getRepairRequestComments(companyId: companyId, repairRequestId: repairRequest.id)
        } catch {
            commentMessage = "Could not load comments"
            print("[RepairRequestDetailViewModel][loadComments] Error: \(error)")
        }
    }

    func addComment(companyId: String?, userId: String?, userName: String) async {
        let trimmedComment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedComment.isEmpty else { return }
        guard let companyId else {
            commentMessage = "Missing company"
            return
        }
        guard let userId, !userId.isEmpty else {
            commentMessage = "Missing signed-in user"
            return
        }

        isAddingComment = true
        defer { isAddingComment = false }

        let comment = JobComment(
            id: "comp_rr_com_" + UUID().uuidString,
            jobId: repairRequest.id,
            companyId: companyId,
            userId: userId,
            userName: userName,
            authorId: userId,
            authorName: userName,
            date: Date(),
            comment: trimmedComment,
            resolved: false
        )

        do {
            try await dataService.addRepairRequestComment(
                companyId: companyId,
                repairRequestId: repairRequest.id,
                comment: comment
            )
            newComment = ""
            commentMessage = "Comment added"
            comments.insert(comment, at: 0)
        } catch {
            commentMessage = "Could not add comment"
            print("[RepairRequestDetailViewModel][addComment] Error: \(error)")
        }
    }

    private func cleanId(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    func onChangeOfSeletectedImage(companyId:String?){
        for image in newPhotoUrls {
            saveImage(companyId: companyId,image: image)
        }
    }
    func saveImage(companyId:String?, image:DripDropImage){
        Task{
            do {
                if let companyId {
                    let result = try await dataService.uploadRepairRequestImage(companyId: companyId, requestId: repairRequest.id, image: image)
                    try await dataService.updateRepairRequestPhotoUrl(companyId: companyId, repairRequestId: repairRequest.id, photoUrl: result.path)
                    self.photoUrls.append(DripDropStoredImage(id: UUID().uuidString, description: "", imageURL: result.path))
                    self.newPhotoUrls.remove(image)
                    self.alertMessage = "SuccesssFully Uploaded, Add Another"
                    self.showAlert = true
                } else {
                    print("[RepairRequestDetailViewModel][saveImage] No companyId: ")
                    self.alertMessage = "No Company"
                    self.showAlert = true
                }
            } catch {
                print("[RepairRequestDetailViewModel][saveImage] Error: \(error)")
                self.alertMessage = "Failed To Load, Try again"
                self.showAlert = true
            }
        }
    }
    func onDissmissShowCustomer(companyId:String?){
        updateStatus(companyId: companyId)
        updateRepairRequestJobList(companyId: companyId)
    }
    func updateStatus(companyId:String?){
        Task{
            do {
                if let companyId {
                    if status != repairRequest.status {
                        try await dataService.updateRepairRequestStatus(companyId: companyId, repairRequestId: repairRequest.id, status: status)
                        if status == .resolved, let equipmentId = repairRequest.equipmentId, !equipmentId.isEmpty {
                            try dataService.updateEquipmentStatus(
                                companyId: companyId,
                                equipmentId: equipmentId,
                                status: equipmentStatus
                            )
                        }
                        print("[RepairRequestViewModel][updateRepairRequestNotes] Updated Status")
                    }
                }
            } catch {
                print("[RepairRequestViewModel][updateStatus] Error \(error)")
            }
        }
    }
    func updateEquipmentStatus(companyId:String?) {
        Task {
            do {
                if let companyId, let equipmentId = repairRequest.equipmentId, !equipmentId.isEmpty {
                    try dataService.updateEquipmentStatus(
                        companyId: companyId,
                        equipmentId: equipmentId,
                        status: equipmentStatus
                    )
                }
            } catch {
                print("[RepairRequestViewModel][updateEquipmentStatus] Error: \(error)")
            }
        }
    }
    func updateDescription(companyId:String?) {
        Task{
            do {
                if let companyId {
                    if description != repairRequest.description {
                        try await dataService.updateRepairRequestDescription(companyId: companyId, repairRequestId: repairRequest.id, description: description)
                        print("[RepairRequestViewModel][updateRepairRequestNotes] Updated Description")
                    }
                }
            } catch {
                print("[RepairRequestViewModel][updateDescription] Error: \(error)")
            }
        }
    }
    func updateRepairRequestJobList(companyId:String?) {
            Task{
                do {
                    if let companyId{
                        if job.id != "" {
                            jobIdList.append(job.id)
                            try await dataService.updateRepairRequestJobList(companyId: companyId, repairRequestId: repairRequest.id, jobId: job.id)
                        }
                    }
                } catch {
                    print("[RepairRequestViewModel][updateRepairRequestJobList] Error \(error)")
                }
            }
    }
    func ondelete(companyId: String?){
        Task{
            if let companyId {
                do {
                    //I dont think I want to delete all of thes things
//                    for job in repairRequest.jobIds {
//                        try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: job)
//                        if let job = jobVM.workOrder {
//                            for stop in job.serviceStopIds {
//                                try await dataService.deleteServiceStopById(companyId: company.id, serviceStopId: stop)
//                            }
//                        }
//                        try await jobVM.deleteJob(companyId: company.id, jobId: job)
//                    }
                    
                    try await dataService.deleteRepairRequest(companyId: companyId, repairRequestId: repairRequest.id)
                } catch {
                    print("[RepairRequestDetailViewModel][ondelete] Error: \(error)")
                }
            }
        }
    }
}
struct RepairRequestDetailView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    
    @State var repairRequest:RepairRequest
    @StateObject private var VM : RepairRequestDetailViewModel

    init(dataService:any ProductionDataServiceProtocol,repairRequest:RepairRequest){
        _VM = StateObject(wrappedValue: RepairRequestDetailViewModel(dataService: dataService,repairRequest: repairRequest))
        _repairRequest = State(wrappedValue: repairRequest)

    }
    @State var showJobConfirmation:Bool = false
    @State var showCustomer:Bool = false
    @State var showDeleteConfirmation:Bool = false
    @State var showAddJobToRepairRequest:Bool = false
    @State var showEdit:Bool = false
    @State private var showStatusPicker: Bool = false

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    header
                    formCard
                    siteContextCard
                    commentsCard
                    jobList
                    currentPhotos
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            Task {
                await VM.refreshRepairRequest(companyId: masterDataManager.currentCompany?.id)
                repairRequest = VM.repairRequest
            }
        }, content: {
            EditRepairRequest(dataService: dataService, repairRequest: VM.repairRequest)
        })
        .toolbar{
            Button(action: {
                showEdit.toggle()
//                VM.alertMessage = "Confirm Delete"
//                print(VM.alertMessage)
//                showDeleteConfirmation.toggle()
            }, label: {
                Text("Edit")
            })
        }
        .task{
            VM.onLoad(companyId: masterDataManager.currentCompany?.id)
        }
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                    VM.ondelete(companyId: masterDataManager.currentCompany?.id)
                },
                secondaryButton: .cancel()
            )
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.newPhotoUrls, perform: { image in
            VM.onChangeOfSeletectedImage(companyId: masterDataManager.currentCompany?.id)
        })
        .onChange(of: VM.status, perform: { stat in
            VM.updateStatus(companyId: masterDataManager.currentCompany?.id)
        })
        .onChange(of: VM.equipmentStatus, perform: { _ in
            VM.updateEquipmentStatus(companyId: masterDataManager.currentCompany?.id)
        })
    }
}
extension RepairRequestDetailView {
    var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Repair Request")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Customer: \(repairRequest.customerName) • Requester: \(repairRequest.requesterName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                statusChip
            }

            HStack(spacing: 8) {
                contextChip(fullDate(date: repairRequest.date), systemImage: "calendar")

                if !VM.jobIdList.isEmpty {
                    contextChip("\(VM.jobIdList.count) Jobs", systemImage: "briefcase")
                }

                if !VM.photoUrls.isEmpty {
                    contextChip("\(VM.photoUrls.count) Photos", systemImage: "photo")
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Overview", systemImage: "person.text.rectangle")

            VStack(alignment: .leading, spacing: 8) {
                Label("Status", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    showStatusPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(statusTint(VM.status))
                            .frame(width: 10, height: 10)

                        Text(VM.status.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .confirmationDialog("Change Status", isPresented: $showStatusPicker, titleVisibility: .visible) {
                    ForEach(RepairRequestStatus.allCases, id: \.self) { stat in
                        Button(stat.displayName) {
                            VM.status = stat
                        }
                    }

                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Current status: \(VM.status.displayName)")
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            detailRow(
                title: "Request Date",
                value: fullDate(date:repairRequest.date),
                systemImage: "calendar"
            )

            detailRow(title: "Customer", value: repairRequest.customerName, systemImage: "person")
            detailRow(title: "Requested By", value: repairRequest.requesterName, systemImage: "person.crop.circle")

            VStack(alignment: .leading, spacing: 8) {
                Label("Issue", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(VM.description.isEmpty ? "No description added." : VM.description)
                    .font(.subheadline)
                    .foregroundStyle(VM.description.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var siteContextCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Site", systemImage: "mappin.and.ellipse")

            if let serviceLocation = VM.serviceLocation {
                detailRow(
                    title: "Location",
                    value: locationSummary(serviceLocation),
                    systemImage: "house"
                )

                if let notes = serviceLocation.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    detailRow(title: "Location Notes", value: notes, systemImage: "note.text")
                }
            } else {
                emptyState("No location selected.", systemImage: "mappin.slash")
            }

            if let bodyOfWater = VM.bodyOfWater {
                detailRow(
                    title: "Body of Water",
                    value: bodyOfWaterSummary(bodyOfWater),
                    systemImage: "drop"
                )
            }

            if let equipment = VM.equipment {
                detailRow(
                    title: "Equipment",
                    value: equipmentSummary(equipment),
                    systemImage: "wrench.and.screwdriver"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Label("Equipment Status", systemImage: "gauge.with.dots.needle.bottom.50percent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Equipment Status", selection: $VM.equipmentStatus) {
                        ForEach(EquipmentStatus.operationalStatusCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var commentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Comments", systemImage: "text.bubble")

                Spacer()

                Button {
                    Task {
                        await VM.loadComments(companyId: masterDataManager.currentCompany?.id)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Refresh repair request comments")
            }

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $VM.newComment)
                        .font(.subheadline)
                        .frame(minHeight: 96)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.listColor.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                        }

                    if VM.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Add a note for this repair request...")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

                HStack(spacing: 10) {
                    if let message = VM.commentMessage {
                        Text(message)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(message == "Comment added" ? Color.poolGreen : Color.poolRed)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button {
                        Task {
                            await VM.addComment(
                                companyId: masterDataManager.currentCompany?.id,
                                userId: masterDataManager.user?.id,
                                userName: currentUserDisplayName
                            )
                        }
                    } label: {
                        if VM.isAddingComment {
                            ProgressView()
                                .frame(width: 20, height: 20)
                        } else {
                            Label("Add Comment", systemImage: "plus.message.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(VM.isAddingComment || VM.newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if VM.commentsLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 18)
            } else if VM.comments.isEmpty {
                emptyState("No comments yet.", systemImage: "text.bubble")
            } else {
                VStack(spacing: 10) {
                    ForEach(VM.comments.sorted(by: commentSort)) { comment in
                        commentRow(comment)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var jobIdListView: some View {
        HStack(spacing: 12) {
            sectionHeader("Connected Jobs", systemImage: "briefcase")

            Spacer()

            Button(action: {
                showJobConfirmation.toggle()
            }, label: {
                Label("Add Job", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            })
            .buttonStyle(.plain)
            .confirmationDialog("Select Type", isPresented: self.$showJobConfirmation, actions: {
                Button(action: {
                    showCustomer.toggle()
                }, label: {
                    Text("Create Job")
                })
                Button(action: {
                    showAddJobToRepairRequest.toggle()
                }, label: {
                    Text("Connect Existing Job")
                })
            })
            .sheet(isPresented: $showAddJobToRepairRequest, onDismiss: {
                VM.updateRepairRequestJobList(companyId: masterDataManager.currentCompany?.id )
            }, content: {
                JobPickerScreen(dataService: dataService, job: $VM.job)
            })
            .sheet(
                isPresented: $showCustomer,
                onDismiss: {
                    VM.onDissmissShowCustomer(companyId:masterDataManager.currentCompany?.id)
                },
                content: {
                    AddNewJobFromRepairRequest(
                        repairRequest:repairRequest,
                        dataService: dataService,
                        returnJobId: $VM.jobId
                    )
            })
        }
    }

    var jobList: some View {
        VStack(alignment: .leading, spacing: 14) {
            jobIdListView

            if VM.jobIdList.isEmpty {
                emptyState("No connected jobs.", systemImage: "briefcase")
            } else {
                VStack(spacing: 10) {
                    ForEach(VM.jobIdList,id:\.self) { id in
                        if let company = masterDataManager.currentCompany, UIDevice.isIPhone {
                            JobNavigationLink(dataService: dataService, companyId: company.id, jobId: id)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            detailRow(title: "Job", value: id, systemImage: "briefcase")
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var currentPhotos: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Photos", systemImage: "camera")

                Spacer()

                Text("\(VM.photoUrls.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            PhotoContentView(selectedImages: $VM.newPhotoUrls)

            if !VM.newPhotoUrls.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if VM.photoUrls.isEmpty {
                emptyState("No uploaded photos yet.", systemImage: "photo.on.rectangle.angled")
            } else {
                DripDropStoredImageRow(images:VM.photoUrls)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var statusChip: some View {
        let tint = statusTint(VM.status)

        return Text(VM.status.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.14), in: Capsule())
    }

    func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    func contextChip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.thinMaterial, in: Capsule())
    }

    func detailRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value.isEmpty ? "Not set" : value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func emptyState(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func commentRow(_ comment: JobComment) -> some View {
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
            }

            Text(comment.comment)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var currentUserDisplayName: String {
        let first = masterDataManager.user?.firstName ?? ""
        let last = masterDataManager.user?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? "Technician" : name
    }

    func locationSummary(_ location: ServiceLocation) -> String {
        let title = location.nickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? location.address.streetAddress
            : location.nickName
        let address = addressSummary(location.address)
        let gateCode = location.gateCode.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts = [title.isEmpty ? "Location" : title]
        if !address.isEmpty, address != title {
            parts.append(address)
        }
        if !gateCode.isEmpty {
            parts.append("Gate: \(gateCode)")
        }

        return parts.joined(separator: "\n")
    }

    func addressSummary(_ address: Address) -> String {
        let cityLine = [address.city, address.state, address.zip]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return [address.streetAddress, cityLine]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    func bodyOfWaterSummary(_ bodyOfWater: BodyOfWater) -> String {
        let name = bodyOfWater.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Body of water"
            : bodyOfWater.name

        let details = [bodyOfWater.gallons, bodyOfWater.material]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        return details.isEmpty ? name : "\(name)\n\(details)"
    }

    func equipmentSummary(_ equipment: Equipment) -> String {
        let name = equipment.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? equipment.type.rawValue
            : equipment.name
        let details = [equipment.type.rawValue, equipment.make, equipment.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        if details.isEmpty {
            return "\(name)\n\(equipment.status.displayName)"
        }

        return "\(name)\n\(details)\n\(equipment.status.displayName)"
    }

    func commentSort(_ lhs: JobComment, _ rhs: JobComment) -> Bool {
        (lhs.date ?? .distantPast) > (rhs.date ?? .distantPast)
    }

    func commentDateText(_ date: Date?) -> String {
        guard let date else { return "Pending" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    func statusTint(_ status: RepairRequestStatus) -> Color {
        switch status.selectableValue {
        case .resolved:
            return Color.poolGreen
        case .convertedToJob:
            return Color.gray
        case .cancelled, .unresolved:
            return Color.poolRed
        case .inprogress, .legacyPending, .legacyPendingCapitalized:
            return Color.yellow
        }
    }
    var info: some View {
        ZStack{
            Color.darkGray.ignoresSafeArea()
            VStack(alignment: .leading){
                    Text("Customer : \(repairRequest.customerName)")
                    HStack{
                        Picker("Status", selection: $VM.status) {
                            ForEach(RepairRequestStatus.allCases,id: \.self){ stat in
                                Text(stat.displayName).tag(stat)
                            }
                        }
                    }
                
                    Text("Tech: \(repairRequest.requesterName)")
                    Text("Date: \(fullDate(date:repairRequest.date))")
                HStack{
                    Text("Description:")
                    Spacer()
                }
                TextField("Description", text: $VM.description)
                    .modifier(PlainTextFieldModifier())
            }
            .padding(8)
        }
    }
    func getColor(status:String)->Color {
        var color:Color = Color.gray
        switch status {
        case "Resolved":
            color = Color.green
        case "Unresolved":
            color = Color.red
        case "Inprogress":
            color = Color.yellow
        default:
            color = Color.gray
        }
        return color
    }
}
