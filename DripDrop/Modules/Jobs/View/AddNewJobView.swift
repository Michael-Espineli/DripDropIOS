//
//  AddNewJobView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/11/24.
//

import SwiftUI
@MainActor
final class AddNewJobViewModel:ObservableObject{
    
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }    
    @Published private(set) var techList: [CompanyUser] = []
    @Published private(set) var serviceLocations: [ServiceLocation] = []
    @Published private(set) var bodiesOfWater: [BodyOfWater] = []
    @Published private(set) var equipmentList:[Equipment] = []
    @Published var description:String = ""
    @Published var tech:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor,
        linkedCompanyId: "",
        linkedCompanyName: ""
    )
    @Published var serviceDate:Date = Date()

    @Published var includeReadings:Bool = false
    @Published var includeDosages:Bool = false
    @Published var duration:String = "0"
    @Published var rate:String = "0"
    @Published var laborCost:String = "0"
    

    @Published var jobId:String = ""
    @Published var jobInternalId:String = ""

    @Published var isEdit: Bool = false
    @Published var isAddTask: Bool = false
    @Published var isAddShoppingList: Bool = false

    @Published var isPresentServiceStop: Bool = false
    @Published var isPresentLaborContract: Bool = false

    @Published var chosenView: String = "Info"
    @Published private(set) var viewOptionList:[String] = ["Info","Tasks","Shopping List","Schedule","Review"]
    
    
    @Published var jobTaskList:[JobTask] = []
    @Published var shoppingItemList:[ShoppingListItem] = []
    @Published var serviceStops:[ServiceStop] = []
    @Published var serviceStopTasks:[ServiceStop:[ServiceStopTask]] = [:]

    @Published var laborContracts:[LaborContract] = []

    @Published private(set) var taskTypes:[String] = []
    @Published private(set) var serviceStopIds:[String] = []
    @Published private(set) var laborContractIds:[String] = []
    
    @Published var showAdminSelector:Bool = false
    @Published var showCustomerSelector:Bool = false
    @Published var showLocationSelector:Bool = false
    @Published var showBodyOfWaterSelector:Bool = false
    
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showBodyOfWaterSheet:Bool = false
    @Published var admin:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor,
        linkedCompanyId: "",
        linkedCompanyName: ""
    )

    @Published var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @Published var serviceLocation:ServiceLocation = ServiceLocation(
        id: "",
        nickName: "",
        address: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        gateCode: "",
        mainContact: Contact(
            id: "",
            name: "",
            phoneNumber: "",
            email: ""
        ),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        preText: false
    )
    @Published var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: "",
        lastFilled: Date()
    )
    @Published var equipment:Equipment = Equipment(
        id : "",
        name: "",
        category: .filter,
        make: "",
        model: "",
        dateInstalled: Date(),
        status: .operational,
        needsService: true,
        notes: "",
        customerName: "",
        customerId: "",
        serviceLocationId: "",
        bodyOfWaterId: "", isActive: true
    )
    @Published var jobTemplate:JobTemplate = JobTemplate(id: "", name: "")
    @Published var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")
    
    @Published var dateCreated:Date = Date()
    
    @Published var operationStatus:JobOperationStatus = .estimatePending
    
    @Published var billingStatus:JobBillingStatus = .draft
    
    
    @Published var installationParts:[WODBItem] = []
    @Published var installationPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @Published var showInstallationParts:Bool = false
    @Published var pvcParts:[WODBItem] = []
    @Published var pvcPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @Published var showPvcParts:Bool = false
    @Published var electricalParts:[WODBItem] = []
    @Published var electricalPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @Published var showElectricalParts:Bool = false
    @Published var chemicals:[WODBItem] = []
    @Published var chemical:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @Published var showChemicals:Bool = false
    @Published var miscParts:[WODBItem] = []
    @Published var miscPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @Published var showMiscParts:Bool = false

    @Published var showTreeSheet:Bool = false
    @Published var showBushSheet:Bool = false
    
    //Service Stop

    
    @Published var serviceStopList:[ServiceStop] = []
    
    @Published var expandJobDetails:Bool = false
    @Published var jobDetailType:String = "Complex"
    @Published var jobDetailTypes:[String] = ["Simple","Complex"]

    //Keyboard Info

    
    
    
    func onLoad(companyId:String) async throws {
        let workOrderCount = try await dataService.getWorkOrderCount(companyId: companyId)
        self.jobId = "comp_wo_" + UUID().uuidString
        self.jobInternalId = "J" + String(workOrderCount)
        self.techList = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")

        /*self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)*/
        //Get Task Types
        self.taskTypes = ["Basic","Clean","Clean Filter","Empty Water","Fill Water","Inspection","Install","Remove","Replace"]
        //Labor Contractor Id and Service Stop Id
        self.serviceStopIds = []
        self.laborContractIds = []
        for task in jobTaskList {
            self.serviceStopIds.append(task.serviceStopId.internalId)
            self.laborContractIds.append(task.laborContractId)
        }
        self.serviceStopIds.removeDuplicates()
        self.laborContractIds.removeDuplicates()
        
        self.serviceStopIds.remove("")
        self.laborContractIds.remove("")
    }
    func onChangeOfCustomer(companyId:String)async throws {
        if customer.id != "" {
            self.serviceLocations = try await dataService.getAllCustomerServiceLocationsId(
                companyId: companyId,
                customerId: customer.id
            )
        }
    }
    func onChangeOfServiceLocation(companyId:String)async throws {
        if serviceLocation.id != "" {
            self.bodiesOfWater = try await dataService.getAllBodiesOfWaterByServiceLocationId(companyId: companyId, serviceLocationId: serviceLocation.id)

        }
    }
    func onChangeOfBodyOfWater(companyId:String)async throws {
        if bodyOfWater.id != "" {
            self.equipmentList = try await dataService.getEquipmentByBodyOfWater(companyId: companyId, bodyOfWater: bodyOfWater)

        }
    }
    func addNewJob(companyId:String) async throws {
        if customer.id == "" {
            throw JobError.invalidCustomer
        }
        if serviceLocation.id == "" {
            throw JobError.invalidServiceLocation
        }
        if admin.userId == "" {
            throw JobError.invalidAdmin
        }
        if admin.id == "" {
            throw JobError.invalidAdmin
        }
        guard let rateDouble = Double(rate) else {
            throw JobError.invalidRate

        }
        let rateInt = Int(rateDouble*100)
        guard let laborCostDouble = Double(laborCost) else {
            throw JobError.invalidLaborCost

        }
        let laborCostInt = Int(laborCostDouble*100)

        let fullCustomerName = customer.firstName + " " + customer.lastName
        let job = Job(
            id: jobId,
            internalId: jobInternalId,
            type: "",
            dateCreated: Date(),
            description: description,
            operationStatus: operationStatus,
            billingStatus: billingStatus,
            customerId: customer.id,
            customerName: fullCustomerName,
            serviceLocationId: serviceLocation.id,
            serviceStopIds: [],
            laborContractIds: [],
            adminId: admin.userId,
            adminName: admin.userName,
            rate: rateInt,
            laborCost: laborCostInt,
            otherCompany: false,
            receivedLaborContractId: "",
            receiverId: "",
            senderId : companyId,
            dateEstimateAccepted: nil,
            estimateAcceptedById: nil,
            estimateAcceptType: nil,
            estimateAcceptedNotes: "",
            invoiceDate: nil,
            invoiceRef: nil,
            invoiceType: nil,
            invoiceNotes: nil
        )
        try await dataService.uploadWorkOrder(companyId: companyId, workOrder: job)
        
        //Add Tasks
        for task in jobTaskList {
            try await dataService.uploadJobTask(companyId:companyId,jobId:jobId,task:task)
        }
        //Add ShoppingList Items
        for item in shoppingItemList {
            try await dataService.addNewShoppingListItem(companyId: companyId, shoppingListItem: item)
        }
        //Add Service Stops
        for stop in serviceStops {
            try await dataService.uploadServiceStop(companyId: companyId, serviceStop: stop)
            let tasks: [ServiceStopTask] = serviceStopTasks[stop] ?? []
            for task in tasks {
                try await dataService.uploadServiceStopTask(companyId: companyId, serviceStopId: stop.id, task: task)
                
                //Update Receiver Job Task
                try dataService.updateJobTaskWorkerId(companyId: companyId, jobId: job.id, taskId: task.id, workerId: stop.techId)
                try dataService.updateJobTaskWorkerName(companyId: companyId, jobId: job.id, taskId: task.id, workerName: stop.tech)
                try dataService.updateJobTaskWorkerType(companyId: companyId, jobId: job.id, taskId: task.id, workerType: .employee)
                try dataService.updateJobTaskServiceStopId(companyId: companyId, jobId: job.id, taskId: task.id, serviceStopId: IdInfo(id: stop.id, internalId: stop.internalId))
                try dataService.updateJobTaskStatus(companyId: companyId, jobId: job.id, taskId: task.id, status: .scheduled)
            }
        }
        //Add Labor Contracts
        
        
        
        self.alertMessage = "Successfully Uploaded"
        self.showAlert = true
    }
    func addNewJobSimple(companyId:String) async throws {
        /*
         guard let company = masterDataManager.currentCompany else {
             return
         }
         let customerFullName = VM.customer.firstName + " " + VM.customer.lastName
         let adminFullName = (VM.admin.firstName) + " " + (VM.admin.lastName)
         let techFullName = (VM.tech.firstName) + " " + (VM.tech.lastName)

         try await jobVM.addNewJobWithValidation(companyId: company.id,
                                                 jobId: jobId,
                                                 jobTemplate: jobTemplate,
                                                 dateCreated: dateCreated,
                                                 description: description,
                                                 operationStatus: operationStatus,
                                                 billingStatus: billingStatus,
                                                 customerId: customer.id,
                                                 customerName: customerFullName,
                                                 serviceLocationId: serviceLocation.id,
                                                 serviceStopIds: serviceStopIds,
                                                 adminId: admin.id,
                                                 adminName: adminFullName,
                                                 installationParts: installationParts,
                                                 pvcParts: pvcParts,
                                                 electricalParts: electricalParts,
                                                 chemicals: chemicals,
                                                 miscParts: miscParts,
                                                 rate: rate,
                                                 laborCost: laborCost,
                                                 bodyOfWater: bodyOfWater,
                                                 equipment: equipment)
         //DEVELOPER INVEASTIGATE WORK FLOW
//                            try await servicestopVM.addNewServiceStopWithValidation(companyId: company.id,
//                                                                                    typeId: jobTemplate.id,
//                                                                                    customerName: customerFullName,
//                                                                                    customerId: customer.id,
//                                                                                    address: serviceLocation.address,
//                                                                                    dateCreated: Date(),
//                                                                                    serviceDate: serviceDate,
//                                                                                    duration: duration,
//                                                                                    rate: rate,
//                                                                                    tech: techFullName,
//                                                                                    techId: tech.id,
//                                                                                    recurringServiceStopId: "",
//                                                                                    description: description,
//                                                                                    serviceLocationId: serviceLocation.id,
//                                                                                    type: jobTemplate.name,
//                                                                                    typeImage: jobTemplate.typeImage ?? "",
//                                                                                    jobId: jobId,
//                                                                                    finished: false,
//                                                                                    skipped: false,
//                                                                                    invoiced: false,
//                                                                                    checkList: checkList,
//                                                                                    includeReadings: includeReadings,
//                                                                                    includeDosages: includeDosages)

         alertMessage = "Successfully Created Job"
         print(alertMessage)
         showAlert = true
//                            receivedJobId = jobId
         dismiss()
         
         */
    }
    func onDismissAddTaskShet(companyId:String,serviceLocationId:String,jobId:String) async throws {
        self.jobTaskList = try await dataService.getJobTasks(companyId: companyId, jobId: jobId)
        print("jobTaskList")
        print(jobTaskList)
    }
    func delete(
        companyId:String,
        jobId:String,
        serviceStopIds:[String],
        laborContractIds:[String]
    ) async throws {
        //DEVELOPER BUILD GUARD STATEMENTS
        for stopId in serviceStopIds {
            try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stopId)
        }
        for id in laborContractIds{
//            try await dataService.deleteServiceStopById(companyId: companyId, serviceStopId: stopId)
        }
        try await dataService.deleteJob(companyId: companyId, jobId: jobId)
    }
    func getTotal()->Double {
        var total:Double = 0
        if let labor = Double(self.laborCost) {
            for part in installationParts {
                total = part.total + total
            }
            for part in pvcParts {
                total = part.total + total
            }
            for part in electricalParts {
                total = part.total + total
            }
            for part in chemicals {
                total = part.total + total
            }
            for part in miscParts {
                total = part.total + total
            }
            total = total + labor
        }
        
        return total
    }
}
struct AddNewJobView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM : AddNewJobViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: AddNewJobViewModel(dataService: dataService))

    }
    @FocusState private var focusedField: String?

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                    //----------------------------------------
                    //Add Back in During Roll out of Phase 2
                    //----------------------------------------

//                HStack{
//                    Picker("", selection: $VM.jobDetailType) {
//                        Text("Simple").tag("Simple")
//                        Text("Complex").tag("Complex")
//                    }
//                    .pickerStyle(.segmented)
//                }
                if  VM.jobDetailType == "Complex" {
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack{
                            ForEach(VM.viewOptionList,id: \.self){ datum in
                                if VM.chosenView == datum {
                                    Text(datum)
                                        .modifier(SubmitButtonModifier())
                                    
                                } else {
                                    let index = (VM.viewOptionList.firstIndex(where: {$0 == datum}) ?? 0)
                                    let selectedIndex = (VM.viewOptionList.firstIndex(where: {$0 == VM.chosenView}) ?? 0)
                                    
                                    Button(action: {
                                        VM.chosenView = datum
                                    }, label: {
                                        
                                        if index > selectedIndex {
                                            Text(datum)
                                                .modifier(ListButtonModifier())
                                            
                                        } else {
                                            Text(datum)
                                                .modifier(FadedGreenButtonModifier())
                                        }
                                        
                                    })
                                    .lineLimit(1)
                                    
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    switch VM.chosenView {
                    case "Customer":
                        customerView
                    case "Info":
                        info
                    case "Tasks":
                        taskView
                    case "Shopping List":
                        shoppingListView
                    case "Schedule":
                        schedule
                    case "Review":
                        review
                    default:
                        info
                    }
                } else {
                    simpleJobView
                }
            }
            .padding(4)
            .padding(.horizontal,4)
        }
        .navigationTitle("ID : \(VM.jobInternalId)")
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar{
            if !UIDevice.isIPhone {
                Button(action: {
                    if VM.jobDetailType == "Simple" {
                        VM.jobDetailType = "Complex"
                    } else {
                        VM.jobDetailType = "Simple"
                    }
                }, label: {
                    Text(VM.expandJobDetails ? "Simplify": "Expand")
                        .padding(8)
                        .background(Color.poolBlue)
                        .cornerRadius(8)
                        .foregroundColor(Color.basicFontText)
                })
            }
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    try await VM.onLoad(companyId: company.id)
                } else {
                    print("No Companies")
                }
                if let selectedCustomer = masterDataManager.selectedCustomer {
                    VM.customer = selectedCustomer
                }
            } catch {
                print("Error")
            }
        }
 
        .onChange(of: VM.admin, perform: { admin in
            VM.tech = admin
        })
        .onChange(of: VM.customer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                            try await VM.onChangeOfCustomer(companyId: company.id)
                    }
                } catch {
                    print("Error")
                }
            }
        })
        
        .onChange(of: VM.serviceLocation, perform: { loc in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeOfServiceLocation(companyId: company.id)
                    }
                } catch {
                    print("Error")
                }
            }
        })
        .onChange(of: VM.bodyOfWater,perform: { BOW in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        try await VM.onChangeOfBodyOfWater(companyId: company.id)
                    }
                } catch {
                    print("Error")
                }
            }
        })
        .onChange(of: VM.rate, perform: { datum in
            if datum != "" {
                if let number = Double(datum) {
                    print("Is Number")
                    print(number)
                    let cents = number*100
                    print(cents)
                    print(Int(cents))
                } else {
                    VM.rate = String(datum.dropLast())
                }
            }
        })
        .onChange(of: VM.laborCost, perform: { datum in
            if datum != "" {
                if let number = Double(datum) {
                    print("Is Number")
                    print(number)
                    let cents = number*100
                    print(cents)
                    print(Int(cents))
                } else {
                    VM.laborCost = String(datum.dropLast())
                    
                }
            }
        })
    }
  
}

extension AddNewJobView {
    var info: some View {
        ScrollView{
            VStack(alignment: .leading,spacing: 8){
                HStack{
                    Text("Admin")
                        .bold(true)
                    Spacer()
                    Button(action: {
                        VM.showAdminSelector.toggle()
                    }, label: {
                        if VM.admin.id == "" {
                            Text("Select Admin")
                        } else {
                            Text("\(VM.admin.userName)")
                        }
                    })
                    .modifier(AddButtonModifier())
                    .sheet(isPresented: $VM.showAdminSelector, content: {
                        CompanyUserPicker(dataService: dataService, companyUser: $VM.admin)
                    })
                }
                HStack{
                    Text("Customer")
                        .bold(true)
                    Spacer()
                    Button(action: {
                        VM.showCustomerSelector.toggle()
                    }, label: {
                        if VM.customer.id == "" {
                            Text("Select Customer")
                        } else {
                            Text("\(VM.customer.firstName) \(VM.customer.lastName)")
                        }
                    })
                    .modifier(AddButtonModifier())
                    .sheet(isPresented: $VM.showCustomerSelector, content: {
                        CustomerAndLocationPicker(dataService: dataService, customer: $VM.customer, location: $VM.serviceLocation)
                    })
                }
                HStack{
                    Text("Service Location")
                        .bold(true)
                    Spacer()
                    Button(action: {
                        VM.showLocationSelector.toggle()
                    }, label: {
                        if VM.serviceLocation.id == "" {
                            Text("Select Location")
                        } else {
                            Text("\(VM.serviceLocation.address.streetAddress)")
                        }
                    })
                    .disabled(VM.customer.id == "")
                    .opacity(VM.customer.id == "" ? 0.75 : 1.0)
                    
                    .modifier(AddButtonModifier())
                    .sheet(isPresented: $VM.showLocationSelector, content: {
                        ServiceLocationPicker(dataService: dataService, customerId: VM.customer.id, location: $VM.serviceLocation)
                    })
                }
//                HStack{
//                    Text("Body Of Water")
//                        .bold(true)
//                    Spacer()
//                    Button(action: {
//                        VM.showBodyOfWaterSelector.toggle()
//                    }, label: {
//                        if VM.bodyOfWater.id == "" {
//                            Text("Select Body Of Water")
//                        } else {
//                            Text("\(VM.bodyOfWater.name)")
//                        }
//                    })
//                    .disabled(VM.bodyOfWater.id == "")
//                .opacity(VM.bodyOfWater.id == "" ? 0.75 : 1.0)
//                    .modifier(AddButtonModifier())
//                    .sheet(isPresented: $VM.showBodyOfWaterSelector, content: {
//                        BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.serviceLocation.id, bodyOfWater: $VM.bodyOfWater)
//                    })
//                }
            }
            VStack(alignment: .leading,spacing: 8){

                HStack{
                    Text("Operation: ")
                        .bold(true)
                    Spacer()
                    Text(VM.operationStatus.rawValue)
                }
                HStack{
                    Text("Billing: ")
                        .bold(true)
                    Spacer()
                    Text(VM.billingStatus.rawValue)
                }
                HStack{
                    Text("Rate:")
                        .bold(true)
                    TextField(
                        "Rate...",
                        text: $VM.rate
                    )
                    .keyboardType(.decimalPad)
                    .modifier(PlainTextFieldModifier())
                }
                HStack{
                    Text("Labor Cost:")
                        .bold(true)
                    TextField(
                        "Labor Cost...",
                        text: $VM.laborCost
                    )
                    .keyboardType(.decimalPad)
                    .modifier(PlainTextFieldModifier())
                }
                HStack{
                    Text("Description")
                        .bold(true)
                    Spacer()
                    Button(action: {
                        VM.description = ""
                    }, label: {
                        Text("Clear")
                            .modifier(DismissButtonModifier())
                    })
                }
                TextField(
                    "Description",
                    text: $VM.description,
                    axis:.vertical
                )
                .lineLimit(5, reservesSpace: true)
                .modifier(PlainTextFieldModifier())
            }
            HStack{
                Spacer()
                Button(action: {
                    VM.chosenView = "Tasks"
                }, label: {
                    Text("Next")
                        .modifier(AddButtonModifier())
                })
              
            }
        }
    }
    
    var taskView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .center,spacing: 8){
                    Text("Task List")
                        .font(.headline)
                    ForEach(VM.jobTaskList){ task in
                            //                        Text("\(task.name)")
                        JobTaskCardView(dataService: dataService, jobId: "", jobTask: task)
                    }
                    HStack{
                        if VM.customer.id != "" && VM.serviceLocation.id != "" {
                            Button(action: {
                                VM.isAddTask.toggle()
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text("Add New Task")
                                    Spacer()
                                }
                                .modifier(AddButtonModifier())
                            })
                            .sheet(isPresented: $VM.isAddTask, onDismiss: {
                            }, content: {
                                AddNewTaskToNewJob(dataService: dataService, jobId: VM.jobId, taskTypes: VM.taskTypes, customerId: VM.customer.id, serviceLocationId: VM.serviceLocation.id, tasks: $VM.jobTaskList,shoppingList: $VM.shoppingItemList)
                                    .presentationDetents([.medium])
                            })
                            Spacer()
                        } else {
                            Button(action: {
                                VM.chosenView = "Info"
                            }, label: {
                                Text("Add Customer Info")
                            })
                        }
                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
                            .modifier(SubmitButtonModifier())
                    })
                    Spacer()
                    Button(action: {
                        VM.chosenView = "Shopping List"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }

    
    var shoppingListView: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading,spacing: 8){
                    Text("Shopping List")
                    HStack{
                        if VM.customer.id != ""{
                            
                            Button(action: {
                                VM.isAddShoppingList.toggle()
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text("Add New Shopping List Item")
                                    Spacer()
                                }
                                .modifier(AddButtonModifier())
                            })
                            .sheet(isPresented: $VM.isAddShoppingList){
                                AddNewShoppingListItemToNewJob(dataService: dataService, jobId: VM.jobId, customerId: VM.customer.id, customerName: VM.customer.firstName + " " + VM.customer.lastName, shoppingList: $VM.shoppingItemList)
                                    .presentationDetents([.medium, .large])
                            }
                            Spacer()
                        } else {
                            Button(action: {
                                VM.chosenView = "Info"
                            }, label: {
                                Text("Add Customer Info")
                            })
                        }
                    }
                    ForEach(VM.shoppingItemList){ item in
                        
                        ShoppingListItemCardView(dataService: dataService, shoppingListItem: item)

                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Button(action: {
                        VM.isEdit = true
                    }, label: {
                        Text("Edit")
                            .modifier(SubmitButtonModifier())
                    })
                    
                    Spacer()
                    Button(action: {
                        VM.chosenView = "Schedule"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }

    var schedule: some View {
        ZStack{
            ScrollView{
                VStack(alignment: .center,spacing: 8){
                    Text("Service Stops")
                        .font(.headline)
                    Divider()
                    Text("List Of Service Stops")
                    ForEach(VM.serviceStops) { serviceStop in
                        VStack(spacing: 0){
                            HStack{
                                Text(serviceStop.customerName )
                            }
                            HStack{
                                Text(fullDateAndDay(date:serviceStop.serviceDate))
                                    .font(.footnote)
                                Spacer()
                                Text("Tech: \(serviceStop.tech)")
                                    .font(.footnote)
                            }
                            HStack{
                                Spacer()
                                Text(serviceStop.operationStatus.rawValue)
                            }
                        }
                        .modifier(ListButtonModifier())
                    }
                    if VM.customer.id != "" && VM.serviceLocation.id != "" {
                        
                        Button(action: {
                            VM.isPresentServiceStop.toggle()
                        }, label: {
                            Text("Schedule Service Stop")
                                .modifier(AddButtonModifier())
                        })
                        .sheet(isPresented: $VM.isPresentServiceStop){
                            AddNewScheduleServiceStopToNewJobView(
                                dataService: dataService,
                                jobId: VM.jobId,
                                customerId: VM.customer.id,
                                customerName: VM.customer.firstName + " " + VM.customer.lastName,
                                serviceLocationId: VM.serviceLocation.id,
                                description: VM.description,
                                jobTaskList: VM.jobTaskList,
                                serviceStops: $VM.serviceStops,
                                serviceStopTasks: $VM.serviceStopTasks
                            )
                            Text("ScheduleServiceStopView")
                                .presentationDetents([.medium])
                        }
                    } else {
                        Button(action: {
                            VM.chosenView = "Info"
                        }, label: {
                            Text("Add Customer Info")
                        })
                    }
                    Rectangle()
                        .frame(height: 1)
                    Text("Labor Contracts")
                        .font(.headline)
                    Divider()
                    Text("List Of Labor Contracts")
                    ForEach(VM.laborContractIds, id: \.self) { id in
                        Text(id)
                    }
                    Button(action: {
                        VM.isPresentLaborContract.toggle()
                    }, label: {
                        Text("Offer New Labor Contract")
                            .modifier(AddButtonModifier())
                    })
                    .sheet(isPresented: $VM.isPresentLaborContract){
                        Text("Add After Creating Job")
                            .presentationDetents([.medium,.large])
                    }
                }
                .padding(5)
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        VM.chosenView = "Review"
                    }, label: {
                        Text("Next")
                            .modifier(AddButtonModifier())
                    })
                }
                .padding(.horizontal,8)
            }
        }
        .padding(5)
    }


    var part: some View {
        VStack(alignment: .leading,spacing: 10){
            Text("Parts: ")
            VStack{
                HStack{
                    Text("Installation Parts")
                    Spacer()
                    Button(action: {
                        VM.showInstallationParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $VM.showInstallationParts,onDismiss: {
                        VM.installationParts.append(VM.installationPart)

                    }, content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $VM.installationPart, category: "Equipment")
                        
                    })
                }
                ForEach(VM.installationParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("PVC Parts")
                    Spacer()
                    Button(action: {
                        VM.showPvcParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $VM.showPvcParts,onDismiss: {
                        VM.pvcParts.append(VM.pvcPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $VM.pvcPart, category: "PVC")
                    })
                }
                ForEach(VM.pvcParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Electrical Parts")
                    Spacer()
                    Button(action: {
                        VM.showElectricalParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $VM.showElectricalParts,onDismiss: {
                        VM.electricalParts.append(VM.electricalPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $VM.electricalPart, category: "Electrical")
                    })
                }
                ForEach(VM.electricalParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Chemicals")
                    Spacer()
                    Button(action: {
                        VM.showChemicals.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $VM.showChemicals,onDismiss: {
                        VM.chemicals.append(VM.chemical)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $VM.chemical, category: "Chems")
                    })
                }
                ForEach(VM.chemicals){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Misc")
                    Spacer()
                    Button(action: {
                        VM.showMiscParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $VM.showMiscParts,onDismiss: {
                        VM.miscParts.append(VM.miscPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $VM.miscPart, category: "")
                    })
                }
                ForEach(VM.miscParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            HStack{
                Spacer()
                Button(action: {
                    VM.chosenView = "Schedule"
                }, label: {
                    Text("Next")
                })
                .padding(5)
                .background(Color.accentColor)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }

    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Customer")
                    .bold(true)
                Spacer()
                Button(action: {
                    VM.showCustomerSelector.toggle()
                }, label: {
                    if VM.customer.id == "" {
                        Text("Select Customer")
                    } else {
                        Text("\(VM.customer.firstName) \(VM.customer.lastName)")
                    }
                })
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $VM.showCustomerSelector, content: {
//                    CustomerPickerScreen(dataService: dataService, customer: $VM.customer)
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.customer, location: $VM.serviceLocation)
                })
            }
            HStack{
                Text("Service Location")
                    .bold(true)
                Spacer()
                Button(action: {
                    VM.showCustomerSelector.toggle()
                }, label: {
                    if VM.serviceLocation.id == "" {
                        Text("Select Location")
                    } else {
                        Text("\(VM.serviceLocation.nickName): \(VM.serviceLocation.address.streetAddress)")
                    }
                })
                .disabled(VM.customer.id == "")
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $VM.showCustomerSelector, content: {
                    ServiceLocationPicker(dataService: dataService, customerId: VM.customer.id, location: $VM.serviceLocation)
                })
            }
            HStack{
                Text("Body Of Water")
                    .bold(true)
                Spacer()
                Button(action: {
                    VM.showCustomerSelector.toggle()
                }, label: {
                    if VM.bodyOfWater.id == "" {
                        Text("Select Body Of Water")
                    } else {
                        Text("\(VM.bodyOfWater.name)")
                    }
                })
                .disabled(VM.serviceLocation.id == "")
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $VM.showCustomerSelector, content: {
                    BodyOfWaterPicker(dataService: dataService, serviceLocationId: VM.serviceLocation.id, bodyOfWater: $VM.bodyOfWater)
                })
            }
            HStack{
                Spacer()
                Button(action: {
                    VM.chosenView = "Parts"
                }, label: {
                    Text("Next")
                })
                .padding(5)
                .background(Color.accentColor)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
        
    }

    var review: some View {
        ScrollView{
            VStack(alignment: .leading,spacing: 8){
                
                Text("Review")
                    .font(.headline)
                HStack{
                    Text("Admin : \(VM.admin.userName)")
                    Spacer()
                    Button(action: {
                        VM.chosenView = "Info"
                    }, label: {
                        Image(systemName: "pencil")
                    })
                }
                HStack{
                    Text("Customer : \(VM.customer.firstName) \(VM.customer.lastName)")
                    Spacer()
                    Button(action: {
                        VM.chosenView = "Customer"
                    }, label: {
                        Image(systemName: "pencil")
                    })
                }
                Text("Address : \(VM.serviceLocation.address.streetAddress) \(VM.serviceLocation.address.city)")
                Text("Body Of Water : \(VM.bodyOfWater.name)")
                Text("Equipment : \(VM.equipment.name)")
            }
            if VM.installationParts.count != 0 || VM.pvcParts.count != 0 || VM.electricalParts.count != 0 || VM.chemicals.count != 0 || VM.miscParts.count != 0 {
                VStack(alignment: .leading,spacing: 10){
                    
                    Text("Parts")
                        .font(.headline)
                    if VM.installationParts.count != 0 {
                        Text(" Installation Parts: ")
                        ForEach(VM.installationParts){ datum in
                            Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                        }
                    }
                    if VM.pvcParts.count != 0 {
                        Text(" Installation Parts: ")
                        ForEach(VM.pvcParts){ datum in
                            Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                        }
                    }
                    if VM.electricalParts.count != 0 {
                        Text(" Installation Parts: ")
                        ForEach(VM.electricalParts){ datum in
                            Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                        }
                    }
                    if VM.chemicals.count != 0 {
                        Text(" Installation Parts: ")
                        ForEach(VM.installationParts){ datum in
                            Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                        }
                    }
                    if VM.miscParts.count != 0 {
                        Text(" Installation Parts: ")
                        ForEach(VM.installationParts){ datum in
                            Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                        }
                    }
                }
            }
            VStack(alignment: .leading,spacing: 10){
                HStack{
                    Text("Labor Cost: ")
                    Spacer()
                    Text("$\(VM.laborCost).00")

                }
                HStack{
                    Text("Rate: ")
                    Spacer()
                    Text("$\(VM.rate).00")

                }
                HStack{
                    Text("Estimated Cost: ")
                    Spacer()
                    Text("\(Double(VM.getTotal())/100, format: .currency(code: "USD").precision(.fractionLength(2)))")

                }
            }
            submitButton
        }
        .padding(5)
    }

    var submitButton: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.addNewJob(companyId: currentCompany.id)
                            } catch {
                                print(error)
                            }
                        }
                    }
                }, label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .modifier(SubmitButtonModifier())

                        .clipShape(Capsule())
                })
                .padding(.horizontal,16)

            }
        }
    }
    
    
    var simpleJobView: some View {
        VStack{
            HStack{
                Text("Tech :")
                    .bold(true)
                Spacer()
                Picker("Tech", selection: $VM.tech) {
                    Text("Pick Tech").tag(CompanyUser(
                        id: "",
                        userId: "",
                        userName: "",
                        roleId: "",
                        roleName: "",
                        dateCreated: Date(),
                        status: .active,
                        workerType: .contractor,
                        linkedCompanyId: "",
                        linkedCompanyName: ""
                    ))
                    ForEach(VM.techList){ user in
                        Text(user.userName).tag(user)
                    }
                }
            }
            HStack{
                Text("Customer :")
                    .bold(true)
                Spacer()
                Button(action: {
                    VM.showCustomerSelector.toggle()
                }, label: {
                    ZStack{
                        if VM.customer.id == "" {
                            Text("Select Customer")
                        } else {
                            Text("\(VM.customer.firstName) \(VM.customer.lastName)")
                        }
                    }
                    .modifier(AddButtonModifier())
                })
                .padding(5)
                .sheet(isPresented: $VM.showCustomerSelector, content: {
//                    VStack{
//                        HStack{
//                            Spacer()
//                            Button(action: {
//                                showCustomerSelector = false
//                            }, label: {
//
//                            })
//                        }
//                        CustomerPickerScreen(dataService: dataService, customer: $customer)
//                    }
                    CustomerAndLocationPicker(dataService: dataService, customer: $VM.customer, location: $VM.serviceLocation)
                })
            }
            HStack{
                Text("Service Date :")
                    .bold(true)
                DatePicker(selection: $VM.serviceDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("Description :")
                    .bold(true)
                Spacer()
            }
            HStack{
                TextField("Description", text: $VM.description) {
                    
                    UIApplication.shared.endEditing()
                }
                Button(action: {
                    VM.description = ""
                }, label: {
                    Text("Clear")
                        .modifier(DismissButtonModifier())
                })
            }
            .textFieldStyle(PlainTextFieldStyle())
            .padding(5)
            .background(Color.gray.opacity(0.5))
            .foregroundColor(Color.black)
            .cornerRadius(5)
            .padding(5)
            .focused($focusedField, equals: "Description")
            .submitLabel(.join)
            .onSubmit {
                switch focusedField {
                case "Description":
                    focusedField = ""
                default:
                    print("Creating account…")
                }
            }
            Spacer()
            submitButtonSimple
            
        }
    }

    var submitButtonSimple: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.addNewJobSimple(companyId: currentCompany.id)
                            } catch JobError.invalidRate{
                                VM.alertMessage = "Invalid Rate"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidLaborCost{
                                VM.alertMessage = "Invalid Labor Cost"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidAdmin{
                                VM.alertMessage = "Invalid Admin Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidCustomer{
                                VM.alertMessage = "Invalid Customer Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidJobType{
                                VM.alertMessage = "Invalid Job Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidServiceLocation{
                                VM.alertMessage = "Invalid Service Location Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch  {
                                VM.alertMessage = "Invalid Something"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            }
                        }
                    }
                }, label: {
                    Text("Save")
                        .modifier(InvertedSubmitButtonModifier())
                })
                .padding(.horizontal,8)
                Button(action: {
                    Task{
                        if let currentCompany = masterDataManager.currentCompany {
                            do {
                                try await VM.addNewJobSimple(companyId: currentCompany.id)
                            } catch JobError.invalidRate{
                                VM.alertMessage = "Invalid Rate"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidLaborCost{
                                VM.alertMessage = "Invalid Labor Cost"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidAdmin{
                                VM.alertMessage = "Invalid Admin Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidCustomer{
                                VM.alertMessage = "Invalid Customer Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidJobType{
                                VM.alertMessage = "Invalid Job Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch JobError.invalidServiceLocation{
                                VM.alertMessage = "Invalid Service Location Selected"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            } catch  {
                                VM.alertMessage = "Invalid Something"
                                print(VM.alertMessage)
                                VM.showAlert = true
                            }
                        }
                    }
                }, label: {
                    Text("Save And Send")
                        .modifier(SubmitButtonModifier())
                })
                .padding(.horizontal,8)
            }
        }
    }

}
