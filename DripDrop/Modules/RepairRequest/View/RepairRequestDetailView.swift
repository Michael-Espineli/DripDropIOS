//
//  RepairRequestDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct RepairRequestDetailView: View {
    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService : ProductionDataService
    
    @State var repairRequest:RepairRequest
    @StateObject private var repairRequestVM : RepairRequestViewModel
    @StateObject private var jobVM : JobViewModel

    @StateObject private var customerVM : CustomerViewModel
    @StateObject private var serviceLocationVM : ServiceLocationViewModel
    
    init(dataService:any ProductionDataServiceProtocol,repairRequest:RepairRequest){
        _repairRequestVM = StateObject(wrappedValue: RepairRequestViewModel(dataService: dataService))
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _repairRequest = State(wrappedValue: repairRequest)
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))

    }
    @State var showJobConfirmation:Bool = false
    
    @State var photoUrls:[DripDropStoredImage] = []
    @State var newPhotoUrls:[DripDropStoredImage] = []

    @State var selectedImage:DripDropStoredImage? = nil

    @State var status:RepairRequestStatus = .unresolved
    @State var showCustomer:Bool = false
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    
    @State var showAddJobToRepairRequest:Bool = false

    @State var jobId:String = ""
    @State var returnJobId:String = ""
    @State var job:Job = Job(
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

    @State var jobIdList:[String] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            jobList
                            Rectangle()
                                .frame(height: 2)
                            Text("Current Phtos")
                            DripDropStoredImageRow(images:photoUrls)
                            Rectangle()
                                .frame(height: 2)
                            Text("NEw Photos")
                            PhotoStoredContent(selectedStoredImages: $newPhotoUrls)
                        }
                        .background(Color.listColor.ignoresSafeArea())
                    }, header: {
                        ZStack{
                            info
                        }
                    })
                })
            }
        }
        .toolbar{
            Button(action: {
                alertMessage = "Confirm Delete"
                print(alertMessage)
                showDeleteConfirmation.toggle()
            }, label: {
                Text("Delete")
            })
        }
        .task{
            if let company = masterDataManager.currentCompany {
                status = repairRequest.status
                photoUrls = repairRequest.photoUrls
                
                jobIdList = repairRequest.jobIds
                do {
                    try await customerVM.getCustomer(companyId: company.id, customerId: repairRequest.customerId)

                } catch {
                    print(error)
                }
            }
        }
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        print("Deleting...")
                        if let company = masterDataManager.currentCompany {
                            do {
                                for job in repairRequest.jobIds {
                                    try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: job)
                                    if let job = jobVM.workOrder {
                                        for stop in job.serviceStopIds {
                                            try await dataService.deleteServiceStopById(companyId: company.id, serviceStopId: stop)
                                        }
                                    }
                                    try await jobVM.deleteJob(companyId: company.id, jobId: job)
                                }
                                try await repairRequestVM.deleteRepairRequest(companyId: company.id, repairRequestId: repairRequest.id)
                            } catch {
                                print(error)
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
        .onChange(of: masterDataManager.selectedRepairRequest, perform: { repair in
            if let repair = repair {
                status = repair.status
                photoUrls = repair.photoUrls
                jobIdList = repair.jobIds
            }
        })

        .onChange(of: selectedImage, perform: { image in
            Task{
                do {
                    if let image = image {
                        if let company = masterDataManager.currentCompany {
                            alertMessage = "Attempting To Load"
                            showAlert = true
//                            try await repairRequestVM.saveRepairRequestImage(companyId: company.id,requestId: repairRequest.id, photo: image)
                            alertMessage = "SuccesssFully Uploaded, Add Another"
                            showAlert = true
                        } else {
                            print("Invalid Company")
                            alertMessage = "Failed To Load, Try again"
                            showAlert = true
                        }
                    } else {
                        print("Invalid Photo")
                        alertMessage = "Failed To Load, Try again"
                        showAlert = true
                    }
                } catch {
                    print("Error")
                    alertMessage = "Failed To Load, Try again"
                    showAlert = true
                }
            }
        })
        .onChange(of: status, perform: { stat in
            if let company = masterDataManager.currentCompany {
                
                    print("Change of Status")
                    Task{
                        try await repairRequestVM.updateRepairRequestStatus(companyId:company.id, repairReuqestId: repairRequest.id,status:stat)
                        
                    }
                    
                
            }
        })
        
    }
}
extension RepairRequestDetailView {
    
    
    var jobIdListView: some View {
        VStack{
            HStack{
                Text("Job List")
                    .sheet(isPresented: $showAddJobToRepairRequest, onDismiss: {
                        print("Add to repairRequest Logic")
                        Task{
                            if let company = masterDataManager.currentCompany {
                                do {
                                    try await repairRequestVM.updateRepairRequestJobList(companyId: company.id, repairReuqestId: repairRequest.id, jobId: jobId)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }, content: {
                        Text("Add Job Selector Logic")
                        JobPickerScreen(dataService: dataService, job: $job)
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
                        Text("Conecect Existing Job")
                    })
                })
                .sheet(isPresented: $showCustomer, onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany {
                                if jobId != "" {
                                    try await repairRequestVM.updateRepairRequestStatus(companyId:company.id, repairReuqestId: repairRequest.id, status:.inprogress)
                                    try await repairRequestVM.updateRepairRequestJobList(companyId: company.id, repairReuqestId: repairRequest.id, jobId: jobId)
                                } else {
                                    print("No Job Id")
                                }
                                jobId = ""
                            
                        }
                    }
                }, content: {
                    AddNewJobFromRepairRequest(customer:customerVM.customer,dataService: dataService,returnJobId: $jobId)
                })
            }
            
        }
    }
    var jobList: some View {
        VStack{
            jobIdListView
            VStack{
                ForEach(jobIdList,id:\.self) { id in
                    //            NavigationLink(value: Route.job(job: Job), label: {
                    //                Text
                    //            })
                        if let company = masterDataManager.currentCompany {
                            
                            if UIDevice.isIPhone {
                                JobNavigationLink(dataService: dataService, companyId: company.id, jobId: id)
                                
                            } else {
                                Button(action: {
                                    Task{
                                        try await jobVM.getSingleWorkOrder(companyId:company.id,WorkOrderId:id)
                                        masterDataManager.selectedJob = jobVM.workOrder
                                        masterDataManager.selectedCategory = .jobs
                                        masterDataManager.selectedID = id
                                    }
                                }, label: {
                                    Text("\(id)")
                                        .foregroundColor(Color.basicFontText)
                                        .padding(5)
                                        .background(Color.accentColor)
                                        .cornerRadius(5)
                                })
                            }
                        }
                }
            }
            
        }
    }
 
    var info: some View {
        ZStack{
            Color.darkGray.ignoresSafeArea()
            VStack(alignment: .leading){
                    Text("Customer : \(repairRequest.customerName)")
                    HStack{
                        Picker("Status", selection: $status) {
                            ForEach(RepairRequestStatus.allCases,id: \.self){ stat in
                                Text(stat.rawValue).tag(stat)
                            }
                        }
                    }
                
                    Text("Tech: \(repairRequest.requesterName)")
                    Text("Date: \(fullDate(date:repairRequest.date))")
                    Text("Description : \(repairRequest.description)")
                
                
            }
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
