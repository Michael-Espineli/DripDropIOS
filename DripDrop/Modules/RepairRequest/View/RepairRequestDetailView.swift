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
            self.status = repairRequest.status
            self.photoUrls = repairRequest.photoUrls
            self.jobIdList = repairRequest.jobIds
            self.description = repairRequest.description
                do {
                    if let companyId {
                        if repairRequest.customerId != "" {
                            self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: repairRequest.customerId)
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
                        print("[RepairRequestViewModel][updateRepairRequestNotes] Updated Status")
                    }
                }
            } catch {
                print("[RepairRequestViewModel][updateStatus] Error \(error)")
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
                                //Function
                            print("Add Job Selector Logic")
                            
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
                VStack(spacing: 16) {
                    header
                    formCard
                    jobList
                    currentPhotos
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
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
    }
}
extension RepairRequestDetailView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Repair Request")
                .font(.title3.weight(.semibold))
            Text("Customer: \(repairRequest.customerName) • Requester: \(repairRequest.requesterName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Status
            LabeledContent("Status") {
                Picker("Status", selection: $VM.status) {
                    ForEach(RepairRequestStatus.allCases,id: \.self){ stat in
                        Text(stat.rawValue).tag(stat)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Date
            LabeledContent("Request Date") {
                Text(fullDate(date:repairRequest.date))

            }

            // Description
            VStack(alignment: .leading, spacing: 6) {
                Text("Description")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Description", text: $VM.description)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.poolGray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            }
            // Optional IDs
            Group {
                LabeledContent("Customer") { Text(repairRequest.customerName).foregroundStyle(.secondary) }
                if let id = repairRequest.locationId {
                    LabeledContent("Location ID") { Text(id).foregroundStyle(.secondary) }
                }
                if let id = repairRequest.bodyOfWaterId {
                    LabeledContent("Body of Water ID") { Text(id).foregroundStyle(.secondary) }
                }
                if let id = repairRequest.equipmentId {
                    LabeledContent("Equipment ID") { Text(id).foregroundStyle(.secondary) }
                }
            }

            // Read-only context
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    var jobIdListView: some View {
        VStack{
            HStack{
                Text("Job List")
                    .sheet(isPresented: $showAddJobToRepairRequest, onDismiss: {
                        VM.updateRepairRequestJobList(companyId: masterDataManager.currentCompany?.id )
                    }, content: {
                        JobPickerScreen(dataService: dataService, job: $VM.job)
                    })
                Spacer()
                Button(action: {
                    showJobConfirmation.toggle()
                }, label: {
                    Text("Add Job")
                        .foregroundColor(Color.basicFontText)
                        .padding(5)
                        .background(Color.poolBlue)
                        .cornerRadius(5)
                        .padding(5)
                })
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
                .sheet(isPresented: $showCustomer, onDismiss: {
                    VM.onDissmissShowCustomer(companyId:masterDataManager.currentCompany?.id)
                }, content: {
                    AddNewJobFromRepairRequest(customer:VM.customer,dataService: dataService,returnJobId: $VM.jobId)
                })
            }
        }
    }
    var jobList: some View {
        VStack{
            jobIdListView
            VStack{
                ForEach(VM.jobIdList,id:\.self) { id in
                    if let company = masterDataManager.currentCompany {
                        if UIDevice.isIPhone {
                            JobNavigationLink(dataService: dataService, companyId: company.id, jobId: id)
                        }
                    }
                }
            }
            
        }
    }
    var currentPhotos: some View {
        VStack{
            Text("Current Photos")
            DripDropStoredImageRow(images:VM.photoUrls)
            PhotoContentView(selectedImages: $VM.newPhotoUrls)
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
                                Text(stat.rawValue).tag(stat)
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
