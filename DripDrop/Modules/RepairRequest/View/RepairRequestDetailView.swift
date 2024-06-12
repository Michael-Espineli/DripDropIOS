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
    @State var showAddPhoto:Bool = false
    @State var showJobConfirmation:Bool = false
    
    @State var pickerType:photoPickerType? = nil
    @State var selectedNewPicker:photoPickerType? = nil
    @State var selectedImage:UIImage? = nil
    @State var photoUrls:[String] = []
    @State var fullSizedPhoto:String? = nil
    
    @State var status:RepairRequestStatus = .unresolved
    @State var showCustomer:Bool = false
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    
    @State var showAddJobToRepairRequest:Bool = false
    
    @State var jobId:String = ""
    @State var returnJobId:String = ""
    @State var job:Job = Job(id: "", type: "", dateCreated: Date(), description: "", operationStatus: .estimatePending, billingStatus: .draft, customerId: "", customerName: "", serviceLocationId: "", serviceStopIds: [], adminId: "", adminName: "", jobTemplateId: "", installationParts: [], pvcParts: [], electricalParts: [], chemicals: [], miscParts: [], rate: 0, laborCost: 0)

    @State var jobIdList:[String] = []
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        VStack{
                            jobList
                            photoList
                        }
                        .padding(.leading,20)
                        .background(Color.listColor.ignoresSafeArea())
                    }, header: {
                        info
                    })
                })
                .padding(.top,20)
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
            if let company = masterDataManager.selectedCompany {
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
                        if let company = masterDataManager.selectedCompany {
                            do {
                                for job in repairRequest.jobIds {
                                    try await jobVM.getSingleWorkOrder(companyId: company.id, WorkOrderId: job)
                                    if let job = jobVM.workOrder {
                                        for stop in job.serviceStopIds {
                                            try await ServiceStopManager.shared.deleteServiceStop(companyId: company.id, serviceStopId: stop)
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

        .onChange(of: repairRequestVM.imageUrlString, perform: { imageUrl in
            Task{
                if let url = imageUrl {
                    photoUrls.append(url)
                    alertMessage = "SuccesssFully Uploaded, Add Another"
                    showAlert = true
                    showAddPhoto = false
                }else {
                    print("Invalid URL")
                    
                }
            }
        })
        .onChange(of: selectedImage, perform: { image in
            Task{
                do {
                    if let image = image {
                        if let company = masterDataManager.selectedCompany {
                            alertMessage = "Attempting To Load"
                            showAlert = true
                            try await repairRequestVM.saveRepairRequestImage(companyId: company.id,requestId: repairRequest.id, photo: image)
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
            if let company = masterDataManager.selectedCompany {
                
                    print("Change of Status")
                    Task{
                        try await repairRequestVM.updateRepairRequestStatus(companyId:company.id, repairReuqestId: repairRequest.id,status:stat)
                        
                    }
                    
                
            }
        })
        
    }
}
extension RepairRequestDetailView {
    var photoListView: some View {
        VStack{
            Text("Photos")
                .font(.title)
            VStack{
                ForEach(photoUrls,id:\.self){ photo in
                    VStack{
                        if let url = URL(string: photo){
                            AsyncImage(url: url){ image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.gray)
                            } placeholder: {
                                Image(systemName:"photo.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.gray)
                                    .frame(maxWidth:100 ,maxHeight:100)
                                    .cornerRadius(100)
                            }
                        } else {
                            Image(systemName:"photo.circle")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.gray)
                                .frame(maxWidth:100 ,maxHeight:100)
                                .cornerRadius(100)
                        }
                    }
                    .padding(5)
                }
            }
            
        }
    }
    
    var imageSelector: some View {
        HStack{
            
            Text("Add Photo")
            
            Button(action: {
                print("Add Photo Picker Logic")
                showAddPhoto.toggle()
                
            }, label: {
                Image(systemName: "photo.fill.on.rectangle.fill")
            })
            .padding(10)
            .confirmationDialog("Select Type", isPresented: self.$showAddPhoto, actions: {
                Button(action: {
                    self.pickerType = .album
                    self.selectedNewPicker = .album
                }, label: {
                    Text("Album")
                })
                Button(action: {
                    self.pickerType = .camera
                    self.selectedNewPicker = .camera
                    
                }, label: {
                    Text("Camera")
                })
                
            })
            .sheet(item: self.$pickerType,onDismiss: {
                
            }){ item in
                switch item {
                case .album:
                    NavigationView{
                        ImagePicker(image: self.$selectedImage)
                    }
                case .camera:
                    NavigationView{
                        Text("Add Camera Logic")
                    }
                    
                }
                
            }}
        
    }
    
    var jobIdListView: some View {
        VStack{
            HStack{
                Text("Job List")
                    .sheet(isPresented: $showAddJobToRepairRequest, onDismiss: {
                        print("Add to repairRequest Logic")
                        Task{
                            if let company = masterDataManager.selectedCompany {
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
                        if let company = masterDataManager.selectedCompany {
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
                        if let company = masterDataManager.selectedCompany {
                            
                            if UIDevice.isIPhone {
                                JobNavigationLink(dataService: dataService, companyId: company.id, jobId: id)
                                
                            } else {
                                Button(action: {
                                    Task{
                                        try await jobVM.getSingleWorkOrder(companyId:company.id,WorkOrderId:id)
                                        masterDataManager.selectedWorkOrder = jobVM.workOrder
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
    var photoList: some View {
        VStack{
            imageSelector
            photoListView
        }
    }
    var info: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                HStack{
                    Text("Customer : \(repairRequest.customerName)")
                    HStack{
                        Picker("Status", selection: $status) {
                            ForEach(RepairRequestStatus.allCases,id: \.self){ stat in
                                Text(stat.rawValue).tag(stat)
                            }
                        }
                    }
                }
                VStack{
                    Text("Tech: \(repairRequest.requesterName)")
                    Text("Date: \(fullDate(date:repairRequest.date))")
                    Text("Description : \(repairRequest.description)")
                }
                
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
