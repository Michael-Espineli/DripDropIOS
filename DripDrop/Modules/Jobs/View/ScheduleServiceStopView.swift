    //
    //  ScheduleServiceStopView.swift
    //  DripDrop
    //
    //  Created by Michael Espineli on 11/23/24.
    //

import MapKit
import SwiftUI

@MainActor
final class ScheduleServiceStopViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var totalStops: Int = 0
    @Published private(set) var finishedStops: Int = 0
    @Published private(set) var routeStatus: String = "In Progress"
    @Published private(set) var estimatedTimeMin: Int = 6000
    @Published private(set) var estimatedTimeMiles: Int = 40
    
    @Published var description: String = ""
    @Published var estimatedTime: Int = 0

    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var showRouteSnapShot: Bool = false
    @Published var serviceDate: Date = Date()
    
    @Published var selectedUser: CompanyUser = CompanyUser(
        id : "",
        userId : "",
        userName : "",
        roleId : "",
        roleName : "",
        dateCreated :Date(),
        status : .active,
        workerType : .notAssigned
    )
    @Published private(set) var companyUserList: [CompanyUser] = []
    @Published private(set) var jobTaskList: [JobTask] = []
    @Published var selectedJobTaskList: [JobTask] = []
    
    func onLoad(
        companyId:String,
        serviceLocationId:String,
        description:String,
        jobTaskList: [JobTask]
    ) async throws {
        self.description = description
        self.jobTaskList = jobTaskList
        self.companyUserList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
        if !companyUserList.isEmpty {
            self.selectedUser = companyUserList.first!
        }
    }
    func onChangeOfDayOrTech(companyId:String) async throws {
        if selectedUser.id != "" {
            self.finishedStops = 4
            self.totalStops = 7
            self.routeStatus = "In Progress"
            self.estimatedTimeMin = 4200
            self.estimatedTimeMiles = 69
            
        }
    }
    func scheduleNewServiceStop(
        companyId : String,
        jobId : String,
        customerId : String,
        customerName : String,
        serviceLocationId : String
    ) async throws {
        print("")
        print("---------- Create Job ------")

        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }
            self.isLoading = true
            var durationMin = 0
            for task in selectedJobTaskList {
                durationMin = durationMin + task.estimatedTime
            }
            //Developer maybe get ride of this call to save on calls
            let jobInternalId = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId).internalId
            
            let serviceStopCount : Int = try await dataService.getServiceOrderCount(companyId: companyId)
            let serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceLocationId)
            print("serviceLocation: \(serviceLocation)")
            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS"+String(serviceStopCount)
            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")
            
            let serviceStop = ServiceStop(
                id : serviceStopId,
                internalId : "SS"+String(serviceStopCount),
                companyId : companyId,
                companyName : "",
                customerId : customerId,
                customerName : customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationMin,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: "",
                type: "",
                typeImage: "",
                jobId: jobId,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )
            print(serviceStop)
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
            print("----  Service Stop uploaded  -----")
            for task in selectedJobTaskList {
                
                //Create Service Stop Tasks
                let serviceStopTask = ServiceStopTask(
                    name : task.name,
                    type : task.type,
                    status: .scheduled,
                    contractedRate : task.contractedRate,
                    estimatedTime : task.estimatedTime,
                    customerApproval : true,
                    actualTime : 0,
                    workerId : selectedUser.userId,
                    workerType : .employee,
                    workerName : selectedUser.userName,
                    laborContractId : "",
                    serviceStopId : IdInfo(id: serviceStopId, internalId: internalId),
                    jobId : IdInfo(id: jobId, internalId: jobInternalId),
                    recurringServiceStopId : IdInfo(id: "", internalId: ""),
                    jobTaskId: task.id,
                    recurringServiceStopTaskId : "",
                    equipmentId : task.equipmentId,
                    serviceLocationId : serviceLocationId,
                    bodyOfWaterId : task.bodyOfWaterId,
                    shoppingListItemId : task.dataBaseItemId
                )
                
                try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: serviceStopId, task: serviceStopTask)
                    //Update Job Task
                try dataService.updateJobTaskWorkerId(companyId: companyId, jobId: jobId, taskId: task.id, workerId: selectedUser.userId)
                try dataService.updateJobTaskWorkerName(companyId: companyId, jobId: jobId, taskId: task.id, workerName: selectedUser.userName)
                try dataService.updateJobTaskWorkerType(companyId: companyId, jobId: jobId, taskId: task.id, workerType: .employee)
                try dataService.updateJobTaskServiceStopId(companyId: companyId, jobId: jobId, taskId: task.id, serviceStopId: IdInfo(id: serviceStopId, internalId: internalId))
                try dataService.updateJobTaskStatus(companyId: companyId, jobId: jobId, taskId: task.id, status: .scheduled)
            }
            
            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }
    
    func scheduleNewServiceStopNewJob(
        companyId : String,
        jobId : String,
        customerId : String,
        customerName : String,
        serviceLocationId : String
    ) async throws ->(ServiceStop,[ServiceStopTask]){
        print("")
        print("---------- Create Job ------")

        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }
            self.isLoading = true
            var durationMin = 0
            for task in selectedJobTaskList {
                durationMin = durationMin + task.estimatedTime
            }
            //Developer maybe get ride of this call to save on calls
            let jobInternalId = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId).internalId
            
            let serviceStopCount : Int = try await dataService.getServiceOrderCount(companyId: companyId)
            let serviceLocation = try await dataService.getServiceLocationById(companyId: companyId, locationId: serviceLocationId)
            print("serviceLocation: \(serviceLocation)")
            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS"+String(serviceStopCount)
            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")
            var tasks:[ServiceStopTask] = []

            let serviceStop = ServiceStop(
                id : serviceStopId,
                internalId : "SS"+String(serviceStopCount),
                companyId : companyId,
                companyName : "",
                customerId : customerId,
                customerName : customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationMin,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: "",
                type: "",
                typeImage: "",
                jobId: jobId,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: false,
                laborContractId: "",
                contractedCompanyId: "",
                isInvoiced: false
            )
            print(serviceStop)
            print("----  Service Stop uploaded  -----")
            for task in selectedJobTaskList {
                //Create Service Stop Tasks
                let serviceStopTask = ServiceStopTask(
                    name : task.name,
                    type : task.type,
                    status: .scheduled,
                    contractedRate : task.contractedRate,
                    estimatedTime : task.estimatedTime,
                    customerApproval : true,
                    actualTime : 0,
                    workerId : selectedUser.userId,
                    workerType : .employee,
                    workerName : selectedUser.userName,
                    laborContractId : "",
                    serviceStopId : IdInfo(id: serviceStopId, internalId: internalId),
                    jobId : IdInfo(id: jobId, internalId: jobInternalId),
                    recurringServiceStopId : IdInfo(id: "", internalId: ""),
                    jobTaskId: task.id,
                    recurringServiceStopTaskId : "",
                    equipmentId : task.equipmentId,
                    serviceLocationId : serviceLocationId,
                    bodyOfWaterId : task.bodyOfWaterId,
                    shoppingListItemId : task.dataBaseItemId
                )
                tasks.append(serviceStopTask)

            }
            
            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
            return (serviceStop,tasks)
        }
        throw FireBaseRead.unableToRead
    }

    func estimateTime(tasks : [JobTask]){
        var durationMin = 0
        for task in selectedJobTaskList {
            durationMin = durationMin + task.estimatedTime
        }
        self.estimatedTime = durationMin
    }
    func scheduleNewServiceStopOtherCompany(
        companyId : String,
        job : Job,
        customerId : String,
        customerName : String,
        serviceLocationId : String
    ) async throws {
        print("")
        print("---------- Create SS Other Company ------")
        if !isLoading {
            if selectedUser.id == "" {
                throw FireBasePublish.unableToPublish
            }
            
            guard let senderId = job.senderId else {
                print("senderId error")
                throw FireBasePublish.unableToPublish
            }
            
            guard let receiverId = job.receiverId else {
                print("receiverId error")
                throw FireBasePublish.unableToPublish
            }
            
            guard let receivedLaborContractId = job.receivedLaborContractId else {
                print("receivedLaborContractId error")
                throw FireBasePublish.unableToPublish
            }
            self.isLoading = true
            var durationSeconds = 0
            for task in selectedJobTaskList {
                durationSeconds = durationSeconds + task.estimatedTime
            }
            //Developer maybe get ride of this call to save on calls
            let jobInternalId = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: job.id).internalId

            let serviceStopCount : Int = try await dataService.getServiceOrderCount(companyId: companyId)
            
            let serviceLocation = try await dataService.getServiceLocationById(companyId: senderId, locationId: serviceLocationId)

            let laborContract = try await dataService.getLaborContract(laborContractId: receivedLaborContractId)
            print("serviceLocation: \(serviceLocation)")
            let serviceStopId = "comp_ss_" + UUID().uuidString
            let internalId = "SS"+String(serviceStopCount)
            print("serviceStopId: \(serviceStopId)")
            print("internalId: \(internalId)")
            
            let serviceStop = ServiceStop(
                id : serviceStopId,
                internalId : internalId,
                companyId : companyId,
                companyName : "",
                customerId : customerId,
                customerName : customerName,
                address: serviceLocation.address,
                dateCreated: Date(),
                serviceDate: serviceDate,
                duration: 0,
                estimatedDuration: durationSeconds,
                tech: selectedUser.userName,
                techId: selectedUser.userId,
                recurringServiceStopId: "",
                description: description,
                serviceLocationId: serviceLocation.id,
                typeId: "",
                type: "",
                typeImage: "",
                jobId: job.id,
                operationStatus: .notFinished,
                billingStatus: .notInvoiced,
                includeReadings: true,
                includeDosages: true,
                otherCompany: true,
                laborContractId: receivedLaborContractId,
                contractedCompanyId: receiverId,
                mainCompanyId: senderId,
                isInvoiced: false
            )
            print(serviceStop)
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: serviceStop)
            print("----  Service Stop uploaded  -----")
            for task in selectedJobTaskList {
                durationSeconds = durationSeconds + task.estimatedTime
                
                //Create Service Stop Tasks
                let serviceStopTask = ServiceStopTask(
                    name : task.name,
                    type : task.type,
                    status: .scheduled,
                    contractedRate : task.contractedRate,
                    estimatedTime : task.estimatedTime,
                    customerApproval : true,
                    actualTime : 0,
                    workerId : selectedUser.userId,
                    workerType : .employee,
                    workerName : selectedUser.userName,
                    laborContractId : "",
                    serviceStopId : IdInfo(
                        id: serviceStopId,
                        internalId: internalId
                    ),
                    jobId : IdInfo(
                        id: job.id,
                        internalId: job.internalId
                    ),
                    recurringServiceStopId : IdInfo(
                        id: "",
                        internalId: ""
                    ),
                    jobTaskId: task.id,
                    recurringServiceStopTaskId : "",
                    equipmentId : task.equipmentId,
                    serviceLocationId : serviceLocationId,
                    bodyOfWaterId : task.bodyOfWaterId,
                    shoppingListItemId : task.dataBaseItemId
                )
                
                try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: serviceStopId, task: serviceStopTask)
                
                //Update Receiver Job Task
                try dataService.updateJobTaskWorkerId(companyId: companyId, jobId: job.id, taskId: task.id, workerId: selectedUser.userId)
                try dataService.updateJobTaskWorkerName(companyId: companyId, jobId: job.id, taskId: task.id, workerName: selectedUser.userName)
                try dataService.updateJobTaskWorkerType(companyId: companyId, jobId: job.id, taskId: task.id, workerType: .employee)
                try dataService.updateJobTaskServiceStopId(companyId: companyId, jobId: job.id, taskId: task.id, serviceStopId: IdInfo(id: serviceStopId, internalId: internalId))
                try dataService.updateJobTaskStatus(companyId: companyId, jobId: job.id, taskId: task.id, status: .scheduled)

            }
                //Update Receiver Job
                try await dataService.updateJobOperationStatus(companyId: companyId, jobId: job.id, operationStatus: .scheduled)

                //Update Sender Job
                
                try await dataService.updateJobOperationStatus(companyId: senderId, jobId: laborContract.senderJobId.id, operationStatus: .scheduled)
                //Update Sender Job Task
                let senderLaborTasks = try await dataService.getLaborContractWork(companyId: "Does not matter, Maybe remove", laborContractId: laborContract.senderJobId.id)
                for laborTask in senderLaborTasks {
                    if selectedJobTaskList.contains(where: {$0.laborContractId == laborContract.id}) {
                        try dataService.updateJobTaskStatus(companyId: senderId, jobId: laborContract.senderJobId.id, taskId: laborTask.senderJobTaskId, status: .scheduled)
                    }
                }
            self.alertMessage = "Successfully Uploaded"
            self.showAlert = true
            self.isLoading = false
        }
    }
}

struct ScheduleServiceStopView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : ScheduleServiceStopViewModel
    @State var job:Job
    @State var customerId:String
    @State var customerName:String
    
    @State var serviceLocationId:String
    @State var description:String
    @State var jobTaskList:[JobTask]
    
    init(
        dataService:any ProductionDataServiceProtocol,
        job:Job,
        customerId:String,
        customerName:String,
        serviceLocationId:String,
        description:String,
        jobTaskList:[JobTask]
        
    ){
        _VM = StateObject(wrappedValue: ScheduleServiceStopViewModel(dataService: dataService))
        _job = State(wrappedValue: job)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        _serviceLocationId = State(wrappedValue: serviceLocationId)
        _description = State(wrappedValue: description)
        _jobTaskList = State(wrappedValue: jobTaskList)
        
    }
    
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            formView
                .padding(8)
            if VM.isLoading {
                VStack{
                    ProgressView()
                    Text("Loading...")
                }
                .padding(8)
                .background(Color.gray)
                .cornerRadius(8)
            }
        }
        .task {
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    VM.description = description
                    try await VM.onLoad(companyId: currentCompany.id, serviceLocationId: serviceLocationId, description: description,jobTaskList:jobTaskList)
                } catch {
                    print(error)
                }
            }
        }
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: VM.serviceDate, perform: { date in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedUser, perform: { user in
            Task {
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        try await VM.onChangeOfDayOrTech(companyId: currentCompany.id)
                    } catch {
                        print(error)
                    }
                }
            }
        })
        .onChange(of: VM.selectedJobTaskList, perform: { tasks in
            VM.estimateTime(tasks: tasks)
            
        })
    }
}

    //#Preview {
    //    ScheduleServiceStopView(jobId: "", description: "")
    //}

extension ScheduleServiceStopView {
    var formView : some View {
        ScrollView{
            
            HStack{
                Text("Employee : ")
                    .bold(true)
                Picker("Employee", selection: $VM.selectedUser) {
                    Text("Select User").tag(CompanyUser(
                        id : "",
                        userId : "",
                        userName : "",
                        roleId : "",
                        roleName : "",
                        dateCreated :Date(),
                        status : .active,
                        workerType : .notAssigned
                    ))
                    ForEach(VM.companyUserList){ type in
                        Text("\(type.userName) \(type.roleName)").tag(type)
                        
                    }
                }
                .frame(maxWidth: .infinity)
            }
            DatePicker("Service Date", selection: $VM.serviceDate, in: Date()...,displayedComponents: .date)
                .bold()
            HStack{
                Text("Description:")
                    .bold(true)
                TextField(
                    "Description",
                    text: $VM.description
                )
                .padding(.leading,4)
                .padding(4)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .padding(4)
            }
            
            HStack{
                Text("Estimated Time:")
                    .bold(true)
                Text(displayMinAsMinAndHour(min: VM.estimatedTime))

            }
            Rectangle()
                .frame(height: 1)
            HStack{
                Button(action: {
                    VM.showRouteSnapShot.toggle()
                }, label: {
                    if VM.showRouteSnapShot {
                        Text("Collapse")
                            .foregroundColor(Color.poolBlue)
                        
                    } else  {
                        Text("Expand")
                            .foregroundColor(Color.poolRed)
                    }
                })
                .sheet(isPresented: $VM.showRouteSnapShot, content: {
                    VStack{
                        Text("Show Route Snap Shot")
                            .font(.headline)
                        Rectangle()
                            .frame(height: 1)
                        HStack{
                            Text("Stops: ")
                                .bold()
                            Spacer()
                            Text("\(String(VM.finishedStops))/\(String(VM.totalStops))")
                        }
                        Text("If Clocked in: 5 Hours")
                        
                        HStack{
                            Text("Status: ")
                                .bold()
                            Spacer()
                            Text("\(VM.routeStatus)")
                        }
                        
                        HStack{
                            Text("Estimated Time: ")
                                .bold()
                            Spacer()
                            Text("\(displayMinAsMinAndHour(min: VM.estimatedTimeMin)) hrs")
                        }
                        
                        HStack{
                            Text("Estimated Milage: ")
                                .bold()
                            Spacer()
                            Text("\(String(VM.estimatedTimeMiles)) mi")
                        }
                        Spacer()
                    }.padding(8)
                    .presentationDetents([.fraction(0.4)])
                })
                Spacer()
                Text("Route Snap Shot For User and Day")
            }
            Rectangle()
                .frame(height: 1)
            Text("Select Tasks List")
                .font(.headline)
            Divider()
            ForEach(VM.jobTaskList){ type in
                switch type.status{
                case .accepted, .offered, .scheduled, .finished, .inProgress:
                    HStack{
                        Spacer()
                        Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                            .lineLimit(1)
                    }
                    .modifier(ListButtonModifier())
                    .opacity(0.5)
                case .unassigned, .rejected, .draft:
                    
                    Button(action: {
                        if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                            VM.selectedJobTaskList.removeAll(where: {$0.id == type.id})
                        } else {
                            VM.selectedJobTaskList.append(type)
                        }
                    }, label: {
                        HStack{
                            if VM.selectedJobTaskList.contains(where: {$0.id == type.id}) {
                                Image(systemName: "checkmark.square")     
                                    .lineLimit(1)
                            } else {
                                Image(systemName: "square")
                            }
                            Spacer()
                            Text("\(type.type) - \(type.status.rawValue) : \(type.name)")
                                .lineLimit(1)
                        }
                    })
                        //                    .modifier(VM.selectedJobTaskList.contains(where: {$0.id == type.id}) ? SubmitButtonModifier(): ListButtonModifier())
                    .modifier(ListButtonModifier())
                }
                
            }
            
            Button(action: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            if job.otherCompany {
                                
                                try await VM.scheduleNewServiceStopOtherCompany(
                                    companyId: currentCompany.id,
                                    job: job,
                                    customerId: customerId,
                                    customerName: customerName,
                                    serviceLocationId: serviceLocationId
                                )
                            } else {
                                try await VM.scheduleNewServiceStop(
                                    companyId: currentCompany.id,
                                    jobId: job.id,
                                    customerId: customerId,
                                    customerName: customerName,
                                    serviceLocationId: serviceLocationId
                                )
                            }
                            dismiss()
                        } catch {
                            print(error)
                        }
                    }
                }
            },
                   label: {
                HStack{
                    Spacer()
                    Text("Schedule New Service Stop")
                    Spacer()
                }
                .modifier(SubmitButtonModifier())
            })
            .disabled(VM.isLoading)
            .opacity(VM.isLoading ? 0.75 : 1)
        }
    }
}
