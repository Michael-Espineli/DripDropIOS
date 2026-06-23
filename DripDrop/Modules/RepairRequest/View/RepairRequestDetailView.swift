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
    let repairRequest: RepairRequest
    init(dataService:any ProductionDataServiceProtocol,repairRequest:RepairRequest){
        self.dataService = dataService
        self.repairRequest = repairRequest
    }
    @Published private(set) var workOrder: Job? = nil
    @Published private(set) var customer: Customer? = nil
    
    @Published var status:RepairRequestStatus = .unresolved
    @Published var equipmentStatus: EquipmentStatus = .operational
    @Published var photoUrls:[DripDropStoredImage] = []
    
    @Published var newPhotoUrls:[DripDropImage] = []
    @Published var jobIdList:[String] = []
    @Published var jobId:String = ""
    @Published var returnJobId:String = ""
    @Published var description:String = ""
    
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
            self.status = repairRequest.status.selectableValue
            self.photoUrls = repairRequest.photoUrls
            self.jobIdList = repairRequest.jobIds
            self.description = repairRequest.description
                do {
                    if let companyId {
                        if repairRequest.customerId != "" {
                            self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: repairRequest.customerId)
                        }
                        if let equipmentId = repairRequest.equipmentId, !equipmentId.isEmpty {
                            let equipment = try await dataService.getSinglePieceOfEquipment(companyId: companyId, equipmentId: equipmentId)
                            self.equipmentStatus = equipment.status
                        }
                    }
                } catch {
                    print("[RepairRequestDetailViewModel][onLoad] Error: \(error)")
                }
        }
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

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    header
                    formCard
                    jobList
                    currentPhotos
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showEdit, onDismiss: {
            
        }, content: {
            EditRepairRequest(dataService: dataService, repairRequest: repairRequest)
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
        .onChange(of: VM.description, perform: { change in
            VM.updateDescription(companyId: masterDataManager.currentCompany?.id)
        })
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
            sectionHeader("Request Details", systemImage: "person.text.rectangle")

            VStack(alignment: .leading, spacing: 8) {
                Label("Status", systemImage: "checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Picker("Status", selection: $VM.status) {
                    ForEach(RepairRequestStatus.allCases,id: \.self){ stat in
                        Text(stat.displayName).tag(stat)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            detailRow(
                title: "Request Date",
                value: fullDate(date:repairRequest.date),
                systemImage: "calendar"
            )

            VStack(alignment: .leading, spacing: 6) {
                Label("Description", systemImage: "text.alignleft")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Description", text: $VM.description, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(5, reservesSpace: true)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Group {
                detailRow(title: "Customer", value: repairRequest.customerName, systemImage: "person")

                if let id = repairRequest.locationId {
                    detailRow(title: "Location ID", value: id, systemImage: "mappin.and.ellipse")
                }

                if let id = repairRequest.bodyOfWaterId {
                    detailRow(title: "Body of Water ID", value: id, systemImage: "drop")
                }

                if let id = repairRequest.equipmentId {
                    detailRow(title: "Equipment ID", value: id, systemImage: "wrench.and.screwdriver")

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
