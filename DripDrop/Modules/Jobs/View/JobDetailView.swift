//
//  JobDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//
//
//DEVELOPER NOTES - I ADDED UPDATES TO THE FIRST PAGE (INFO) I NEED TO ADD UPDATES TO CUSTOMER, PARTS, SCHEDULE


import SwiftUI

struct JobDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var settingsVM = SettingsViewModel()
    @StateObject var jobVM : JobViewModel
    @StateObject var customerVM : CustomerViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var servicestopVM : ServiceStopsViewModel

    @StateObject var techVM = TechViewModel()
    @State var job:Job
    init(job:Job,dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _servicestopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _job = State(wrappedValue: job)
    }
    @State var view:String = "Info"
    @State var viewList:[String] = ["Info","Customer","Parts","Schedule","Review"]
    @State var jobId:String = "J"
//Body Of Water
    @State var jobTemplate:JobTemplate = JobTemplate(id: "", name: "")
    @State var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")

    @State var dateCreated:Date = Date()
    @State var description:String = ""

    @State var operationStatus:JobOperationStatus = .estimatePending
    
    @State var billingStatus:JobBillingStatus = .draft
    
    @State var customer:Customer = Customer(
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
        billingNotes: ""
    )
    
    @State var serviceLocations:[ServiceLocation] = []
    @State var serviceLocation:ServiceLocation = ServiceLocation(
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
    
    @State var bodyOfWaterList:[BodyOfWater] = []
    @State var bodyOfWater:BodyOfWater = BodyOfWater(
        id: "",
        name: "",
        gallons: "",
        material: "",
        customerId: "",
        serviceLocationId: ""
    )
    
    @State var equipmentList:[Equipment] = []
    @State var equipment:Equipment = Equipment(
        id: "",
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
        bodyOfWaterId: ""
    )

    @State var admin:DBUser = DBUser(id: "",exp: 0)
    @State var tech:DBUser = DBUser(id: "",exp: 0)

    @State var serviceStopIds:[String] = []
    
    @State var installationParts:[WODBItem] = []
    @State var installationPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showInstallationParts:Bool = false
    @State var pvcParts:[WODBItem] = []
    @State var pvcPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showpvcParts:Bool = false
    @State var electricalParts:[WODBItem] = []
    @State var electricalPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showelectricalParts:Bool = false
    @State var chemicals:[WODBItem] = []
    @State var chemical:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showchemicals:Bool = false
    @State var miscParts:[WODBItem] = []
    @State var miscPart:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var showmiscParts:Bool = false

    
    @State var rate:String = "0"
    @State var laborCost:String = "0"
    @State var showCustomerSelector:Bool = false
    @State var showPurchasedItemSelector:Bool = false


    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    @State var showDeleteConfirmation:Bool = false
    //Service Stop
    @State var showAddNewServiceStop:Bool = false
    @State var serviceDate:Date = Date()
    @State var includeReadings:Bool = false
    @State var includeDosages:Bool = false
    @State var checkList:[String] = []
    @State var duration:String = "0"
    @State var serviceStopDescription:String = "0"

    @State var serviceStopList:[ServiceStop] = []
    @State var workingJob:Job? = nil
    @State var isLoading:Bool = false
    
    @State var bodyOfWaterPicker:Bool = false
    @State var equipmentPicker:Bool = false
    @State var showCostBreakDown:Bool = false

    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeletePartConfirmation:Bool = false
    @State var partToDelete:WODBItem = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
    @State var categoryToDeleteFrom:String = ""
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{

                HStack{
                  
                    Picker("", selection: $view) {
                        ForEach(viewList,id: \.self){ datum in
                            Text(datum).tag(datum)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                    switch view {
                    case "Info":
                        info
                        
                    case "Customer":
                        customerView
                
                    case "Parts":
                        part
                        
                    case "Schedule":
                        schedule
                        
                    case "Review":
                        review
                        
                    default:
                        info
                    }
  
            }
        }
        .navigationTitle("Job Id: \(job.id)")

        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
 
            do {
                if let company = masterDataManager.selectedCompany {
                    workingJob = job
                    dateCreated = job.dateCreated
                    jobTemplate.id = job.jobTemplateId
                    jobTemplate.name = job.type

                    description = job.description
                    operationStatus = job.operationStatus
                    billingStatus = job.billingStatus
                    customer.id = job.customerId
                    customer.firstName = job.customerName
                    
                    serviceStopIds = job.serviceStopIds
                    admin.id = job.adminId
                    admin.firstName = job.adminName
                    
                    installationParts = job.installationParts
                    pvcParts = job.pvcParts
                    electricalParts = job.electricalParts
                    chemicals = job.chemicals
                    miscParts = job.miscParts
                    laborCost = String(job.laborCost)
                    print(job.rate)
                    rate = String(job.rate)
                    print(rate)
                    try await serviceLocationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: job.customerId, locationId: job.serviceLocationId)
                    if let location = serviceLocationVM.serviceLocation {
                        serviceLocation = location
                    }
                    try await bodyOfWaterVM.getSpecificBodyOfWater(companyId: company.id, bodyOfWaterId: job.bodyOfWaterId ?? "0")
                    if let BOW = bodyOfWaterVM.bodyOfWater {
                        bodyOfWater = BOW
                    }
                    try await equipmentVM.getSinglePieceOfEquipmentWithId(companyId: company.id, equipmentId: job.equipmentId ?? "0")
                    if let eq = equipmentVM.equipment {
                        equipment = eq
                    }
                    try await servicestopVM.getserviceStopsByJobId(companyId: company.id, jobId: job.id)
                    serviceStopList = servicestopVM.serviceStops
                        //DEVELOPER CAN GET RID OF THIS LATER, BUT THIS IS BECAUSE I AM NOT MAKRING ALL OF MY JOBS WITH THE SERVICE STOPS ASSOCIATED WITH THEM, I WILL NEED TO DO THAT LATER
                    if job.serviceStopIds.count != serviceStopList.count {
                        for stop in serviceStopList{
                            try await jobVM.addServiceIdToJob(companyId: company.id, jobId: job.id, serviceStopId: stop.id)
                        }
                    }
                }
            } catch {
                print("")
                print("Job Detail ViewError")
                print(error)
                print("")
            }

            do {
                if let company = masterDataManager.selectedCompany {
                    try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                    try await settingsVM.getSrerviceStopTemplates(companyId: company.id)

                    try await techVM.getAllCompanyTechs(companyId: company.id)
                } else {
                    print("No Companies")
                }
            } catch {
                print("Error")
            }
        }
        .onChange(of: masterDataManager.selectedWorkOrder, perform: { job1 in
            Task {
     
                do {
                    if let company = masterDataManager.selectedCompany,let job = job1 {
                        workingJob = job
                        dateCreated = job.dateCreated
                        jobTemplate.id = job.jobTemplateId
                        jobTemplate.name = job.type

                        description = job.description
                        operationStatus = job.operationStatus
                        billingStatus = job.billingStatus
                        customer.id = job.customerId
                        customer.firstName = job.customerName
                        
                        serviceStopIds = job.serviceStopIds
                        admin.id = job.adminId
                        admin.firstName = job.adminName
                        
                        installationParts = job.installationParts
                        pvcParts = job.pvcParts
                        electricalParts = job.electricalParts
                        chemicals = job.chemicals
                        miscParts = job.miscParts
                        
                        rate = String(job.rate)
                        laborCost = String(job.laborCost)
                        try await serviceLocationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: job.customerId, locationId: job.serviceLocationId)
                        if let location = serviceLocationVM.serviceLocation {
                            serviceLocation = location
                        }
                        try await bodyOfWaterVM.getSpecificBodyOfWater(companyId: company.id, bodyOfWaterId: job.bodyOfWaterId ?? "0")
                        if let BOW = bodyOfWaterVM.bodyOfWater {
                            bodyOfWater = BOW
                        }
                        try await equipmentVM.getSinglePieceOfEquipmentWithId(companyId: company.id, equipmentId: job.equipmentId ?? "0")
                        if let eq = equipmentVM.equipment {
                            equipment = eq
                        }
                        try await jobVM.getPurchaseCost(companyId: company.id, purchaseIds: job.purchasedItemsIds ?? [])
                    }
                } catch {
                    print("Error")
                }

                do {
                    if let company = masterDataManager.selectedCompany {
                        try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                        try await settingsVM.getSrerviceStopTemplates(companyId: company.id)

                        try await techVM.getAllCompanyTechs(companyId: company.id)
                    } else {
                        print("No Companies")
                    }
                } catch {
                    print("Error")
                }
            }
            
        })
        .onChange(of: jobTemplate, perform: { template in
            rate = template.rate ?? "0"
        })
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        if let company = masterDataManager.selectedCompany{
                            do {
                                        for stop in job.serviceStopIds {
                                            try await ServiceStopManager.shared.deleteServiceStop(companyId: company.id, serviceStopId: stop)
                                        }
                                    
                                try await jobVM.deleteJob(companyId: company.id, jobId: job.id)
                                alertMessage = "Deleted"
                                print(alertMessage)
                                showAlert = true
                            } catch {
                                print(error)
                            }
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: customer, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
                        if cus.id != "" {
                            try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: customer.id)
                            serviceLocations = serviceLocationVM.serviceLocations
                            if serviceLocations.count != 0 {
                                serviceLocation = serviceLocations.first!
                            } else {
                                serviceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "", preText: false)
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })

        .onChange(of: serviceLocation, perform: { loc in
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
                        if loc.id != "" {
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: loc)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            
                            if bodyOfWaterList.count != 0 {
                                bodyOfWater = bodyOfWaterList.first!
                            } else {
                                bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "")
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })
        .onChange(of: bodyOfWater,
                  perform: {
            BOW in
            Task{
                do {
                    if let company = masterDataManager.selectedCompany {
                        if BOW.id != "" {
                            try await equipmentVM.getAllEquipmentFromBodyOfWater(companyId: company.id, bodyOfWater: BOW)
                            equipmentList = equipmentVM.listOfEquipment
                            
                            if equipmentList.count != 0 {
                                equipment = equipmentList.first!
                            } else {
                                equipment = Equipment(
                                    id: "",
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
                                    bodyOfWaterId: ""
                                )
                            }
                        }
                    }
                } catch {
                    print("Error")
                }
            }
        })
    }
    func getTotalParts(installation:[WODBItem], pvc:[WODBItem], electrical:[WODBItem], chems:[WODBItem], misc:[WODBItem])->Double {
        var total:Double = 0
            for part in installation {
                total = part.total + total
            }
            for part in pvc {
                total = part.total + total
            }
            for part in electrical {
                total = part.total + total
            }
            for part in chems {
                total = part.total + total
            }
            for part in misc {
                total = part.total + total
            }
        
        return total
    }
    func getTotal(installation:[WODBItem], pvc:[WODBItem], electrical:[WODBItem], chems:[WODBItem], misc:[WODBItem], labor:String)->Double {
        var total:Double = 0
        if let labor = Double(labor) {
            for part in installation {
                total = part.total + total
            }
            for part in pvc {
                total = part.total + total
            }
            for part in electrical {
                total = part.total + total
            }
            for part in chems {
                total = part.total + total
            }
            for part in misc {
                total = part.total + total
            }
            total = total + labor
        }
        return total
    }
}

extension JobDetailView {
    var review: some View {
        ZStack{
            ScrollView {
                VStack(alignment: .leading){
                    VStack(alignment: .leading,spacing: 10){
                        
                        Text("Review")
                            .font(.headline)
                        HStack{
                            Text("Admin: \(admin.firstName ?? "") \(admin.lastName ?? "")")
                            Spacer()
                            Button(action: {
                                view = "Info"
                            }, label: {
                                Image(systemName: "pencil")
                            })
                        }
                        HStack{
                            Text("Customer: \(customer.firstName) \(customer.lastName)")
                            Spacer()
                            Button(action: {
                                view = "Customer"
                            }, label: {
                                Image(systemName: "pencil")
                            })
                        }
                        Text("Address: \(serviceLocation.address.streetAddress) \(serviceLocation.address.city)")
                        if bodyOfWater.id == "" {
                            Text("\(bodyOfWater.name)")
                        }
                        if equipment.id == "" {
                            Text("\(equipment.name)")
                        }
                        Text("Equipment: \(equipment.name)")
                    }
                    if installationParts.count != 0 || pvcParts.count != 0 || electricalParts.count != 0 || chemicals.count != 0 || miscParts.count != 0 {
                        VStack(alignment: .leading,spacing: 10){
                            
                            Text("Parts")
                                .font(.headline)
                            if installationParts.count != 0 {
                                Text(" Installation Parts: ")
                                ForEach(installationParts){ datum in
                                    Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                                }
                            }
                            if pvcParts.count != 0 {
                                Text(" Installation Parts: ")
                                ForEach(pvcParts){ datum in
                                    Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                                }
                            }
                            if electricalParts.count != 0 {
                                Text(" Installation Parts: ")
                                ForEach(electricalParts){ datum in
                                    Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                                }
                            }
                            if chemicals.count != 0 {
                                Text(" Installation Parts: ")
                                ForEach(installationParts){ datum in
                                    Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                                }
                            }
                            if miscParts.count != 0 {
                                Text(" Installation Parts: ")
                                ForEach(installationParts){ datum in
                                    Text(" -\(datum.name) \(String(datum.quantity)) \(String(datum.total))")
                                }
                            }
                        }
                    }
                    Rectangle()
                        .frame(height: 2)
                    VStack(alignment: .leading,spacing: 10){
                        Text("Estimate Break down")
                            .font(.headline)
                        VStack{
                            HStack{
                                Text("Rate")
                                Spacer()
                                Text("$\(rate)")
                            }
                            HStack{
                                Text("Labor Cost: ")
                                Spacer()
                                Text("$\(laborCost)")
                            }
                            HStack{
                                Text("Estimated Material Cost: ")
                                Spacer()
                                Text("$\(String(format:"%2.f",getTotalParts(installation: installationParts, pvc: pvcParts, electrical: electricalParts, chems: chemicals, misc: miscParts)))")
                            }
                        }
                        .padding(.leading,16)
                    }
                    Rectangle()
                        .frame(height: 2)
                    VStack(alignment: .leading,spacing: 10){
                        Text("Cost Review")
                            .font(.headline)
                        if let purchase = jobVM.purchasedPartCost, let rate = Double(rate), let labor = Double(laborCost) {

                        VStack{
                            HStack{
                                Text("Rate")
                                Spacer()
                                Text("$\(String(format:"%2.f",rate))")

                            }
                            HStack{
                                Text("Ideal Rate: ")
                                Spacer()
                                Text("$\(String(format:"%2.f",2.4*(purchase + labor)))")
                            }
                            .font(.footnote)
                            .padding(.horizontal,8)
                            HStack{
                                Text("Total Cost: ")
                                Spacer()
                                Text("$\(String(format:"%2.f",purchase + labor))")

                            }
                            HStack{
                                Spacer()
                                Button(action: {
                                    self.showCostBreakDown.toggle()
                                }, label: {
                                    
                                    Text("Show Break Down")
                                        .font(.footnote)
                                    Image(systemName: showCostBreakDown ? "chevron.down" : "chevron.forward")
                                })
                            }
                            if showCostBreakDown {
                                
                                HStack{
                                    Text("Labor Cost: ")
                                    Spacer()
                                    Text("$\(laborCost)")
                                }
                                
                                HStack{
                                    Text("Purchases Cost: ")
                                    Spacer()
                                    Text("$\(String(format:"%2.f",purchase))")
                                    
                                }
                            }
                            Rectangle()
                                .frame(height: 1)
                                HStack{
                                    Text("Profit: ")
                                    Spacer()
                                    Text("$\(String(format:"%2.f",rate - purchase - labor))")
                                }
                            }
                        .padding(.leading,16)
                        }
                    }
                }
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        showDeleteConfirmation.toggle()
                    }, label: {
                        Text("Delete")
                            .foregroundColor(Color.white)
                            .padding(.horizontal,8)
                            .padding(.vertical,3)
                            .background(Color.red)
                            .cornerRadius(8)
                    })
                }
            }
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }
    var newServiceStopForm: some View {
        VStack{
            HStack{
                Text("Service Date: ")
                DatePicker(selection: $serviceDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("Service Type")
                    .bold(true)
                Picker("Service Stop Type", selection: $serviceStopTemplate) {
                    Text("Pick Type").tag(ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: ""))
                    ForEach(settingsVM.serviceStopTemplates){ template in
                        Text(template.name).tag(template)
                    }
                }
            }
            VStack{
                HStack{
                    Text("\(serviceLocation.address.streetAddress)")
                }
                HStack{
                    Text("\(serviceLocation.address.city)")
                    Text("\(serviceLocation.address.state)")
                    Text("\(serviceLocation.address.zip)")
                    
                }
            }
            HStack{
                Text("Tech")
                    .bold(true)
                Picker("Tech", selection: $tech) {
                    Text("Pick Tech").tag(DBUser(id: "",exp: 0))
                    ForEach(techVM.techList){ template in
                        let fullName = (template.firstName ?? "") + " " + (template.lastName ?? "")
                        Text(fullName).tag(template)
                    }
                }
            }
            Toggle(isOn: $includeDosages, label: {
                Text("Include Dosages")
            })
            Toggle(isOn: $includeReadings, label: {
                Text("Include Readings")
            })
            HStack{
                Text("Duration: ")
                TextField(
                    "Duration",
                    text: $duration,
                    axis: .vertical
                    
                )
                .padding(5)
                .background(Color.gray.opacity(0.5))
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
            HStack{
                Text("Description: ")
                TextField(
                    "Service Stop Description",
                    text: $serviceStopDescription,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.gray.opacity(0.5))
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                            let customerFullName = customer.firstName + " " + customer.lastName
                            let techFullName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
                            let serviceStopId = try await servicestopVM.addNewServiceStopWithValidation(companyId: company.id,
                                                                                    typeId: jobTemplate.id,
                                                                                    customerName: customerFullName,
                                                                                    customerId: customer.id,
                                                                                    address: serviceLocation.address,
                                                                                    dateCreated: Date(),
                                                                                    serviceDate: serviceDate,
                                                                                    duration: duration,
                                                                                    rate: rate,
                                                                                    tech: techFullName,
                                                                                    techId: tech.id,
                                                                                    recurringServiceStopId: "",
                                                                                    description: serviceStopDescription,
                                                                                    serviceLocationId: serviceLocation.id,
                                                                                    type: jobTemplate.name,
                                                                                    typeImage: jobTemplate.typeImage ?? "",
                                                                                    jobId: job.id,
                                                                                    finished: false,
                                                                                    skipped: false,
                                                                                    invoiced: false,
                                                                                    checkList: checkList,
                                                                                    includeReadings: includeReadings,
                                                                                    includeDosages: includeDosages)
                            try await jobVM.addServiceIdToJob(companyId: company.id, jobId: job.id, serviceStopId: serviceStopId)
                            operationStatus = .estimatePending
                            
                            billingStatus = .estimate
                            alertMessage = "Successfully Added Service Stop"
                            showAlert = true
                            showAddNewServiceStop.toggle()
                        }
                    } catch {
                        print(error)
                    }
                }
            }, label: {
                Text("Add Service stop")
                    .padding(8)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(8)
            })
       
        }
    }
    var schedule: some View {
        ZStack{
            ScrollView{
                VStack(alignment: .leading){
                    if serviceStopList.count == 0 {
                        Text("Schedule First Service Stop")
                        
                        newServiceStopForm
                    } else {
                        HStack{
                            Text("Stops: \(serviceStopList.count)")
                            Spacer()
                            Button(action: {
                                showAddNewServiceStop.toggle()
                            }, label: {
                                Text("Add Service Stop")
                                    .padding(8)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(8)
                            })
                            .sheet(isPresented: $showAddNewServiceStop, content: {
                                newServiceStopForm
                            })
                        }
                        ForEach(serviceStopList){ stop in
                            HStack{
                                Text("\(stop.type) - \(fullDate(date:stop.dateCreated)) - ")
                                Text("\(stop.finished ? "Finished" : "Unfinished")")
                                    .foregroundColor(stop.finished ? Color.green : Color.red)
                            }
                        }
                    }
                    
                }
            }
            VStack{
        Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        view = "Review"
                    }, label: {
                        Text("Next")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(5)
                    .padding(5)
                }
            }
    }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }
    var part: some View {
        ZStack{
            ScrollView{
                VStack(spacing: 10){
                    Text("Shopping List Items")
                        .font(.title)
                    Rectangle()
                        .frame(height: 1)
                    
                    VStack(alignment: .leading){
                        HStack{
                            Text("Installation Parts:")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showInstallationParts.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(8)
                            })
                            .sheet(isPresented: $showInstallationParts,onDismiss: {
                                Task{
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await jobVM.updateInstallationJobParts(companyId: company.id, jobId: job.id, installationPart: installationPart)
                                            installationParts.append(installationPart)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, content: {
                                jobItemPicker(jobDBItems: $installationPart, category: "Equipment")
                                
                            })
                        }
                        ForEach(installationParts){ datum in
                            Divider()
                            HStack{
                                Text("\(datum.name)")
                                Text("\(String(datum.quantity))")
                                Text("\(String(datum.cost))")
                                Button(action: {
                                    categoryToDeleteFrom = "installationParts"
                                    partToDelete = datum
                                    alertMessage = "Please Confirm Delete"
                                    Task{
                                        if let company = masterDataManager.selectedCompany {
                                            if categoryToDeleteFrom != "" {
                                                do {
                                                    print("Deleting...")
                                                    print(partToDelete)
                                                    try await jobVM.deletePart(companyId: company.id, jobId: job.id, part: partToDelete,category:categoryToDeleteFrom)
                                                    partToDelete = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
                                                    categoryToDeleteFrom = ""
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    Image(systemName: "trash.circle.fill")
                                })
                            }
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("PVC Parts:")
                                .font(.headline)
                            
                            Spacer()
                            Button(action: {
                                showpvcParts.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                            .sheet(isPresented: $showpvcParts,onDismiss: {
                                Task{
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await jobVM.updatePVCobParts(companyId: company.id, jobId: job.id, pvc: pvcPart)
                                            pvcParts.append(pvcPart)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            },  content: {
                                jobItemPicker(jobDBItems: $pvcPart, category: "PVC")
                            })
                        }
                        ForEach(pvcParts){ datum in
                            Divider()
                            
                            HStack{
                                Text("\(datum.name)")
                                Text("\(String(datum.quantity))")
                                Text("\(String(datum.cost))")
                                Button(action: {
                                    categoryToDeleteFrom = "pvcParts"
                                    partToDelete = datum
                                    alertMessage = "Please Confirm Delete"
                                    
                                    Task{
                                        if let company = masterDataManager.selectedCompany {
                                            if categoryToDeleteFrom != "" {
                                                do {
                                                    print("Deleting...")
                                                    print(partToDelete)
                                                    try await jobVM.deletePart(companyId: company.id, jobId: job.id, part: partToDelete,category:categoryToDeleteFrom)
                                                    partToDelete = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
                                                    categoryToDeleteFrom = ""
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    Image(systemName: "trash.circle.fill")
                                })
                            }
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("Electrical Parts:")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showelectricalParts.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                            .sheet(isPresented: $showelectricalParts,onDismiss: {
                                Task{
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await jobVM.updatePVCobParts(companyId: company.id, jobId: job.id, pvc: electricalPart)
                                            electricalParts.append(electricalPart)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            },  content: {
                                jobItemPicker(jobDBItems: $electricalPart, category: "Electrical")
                            })
                        }
                        ForEach(electricalParts){ datum in
                            Divider()
                            
                            HStack{
                                Text("\(datum.name)")
                                Text("\(String(datum.quantity))")
                                Text("\(String(datum.cost))")
                                Button(action: {
                                    categoryToDeleteFrom = "electricalParts"
                                    partToDelete = datum
                                    alertMessage = "Please Confirm Delete"
                                    
                                    Task{
                                        if let company = masterDataManager.selectedCompany {
                                            if categoryToDeleteFrom != "" {
                                                do {
                                                    print("Deleting...")
                                                    print(partToDelete)
                                                    try await jobVM.deletePart(companyId: company.id, jobId: job.id, part: partToDelete,category:categoryToDeleteFrom)
                                                    partToDelete = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
                                                    categoryToDeleteFrom = ""
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    Image(systemName: "trash.circle.fill")
                                })
                            }
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("Chemicals:")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                showchemicals.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                            .sheet(isPresented: $showchemicals,onDismiss: {
                                Task{
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await jobVM.updateChemicalsJobParts(companyId: company.id, jobId: job.id, chemical: chemical)
                                            chemicals.append(chemical)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            },  content: {
                                jobItemPicker(jobDBItems: $chemical, category: "Chems")
                            })
                        }
                        ForEach(chemicals){ datum in
                            Divider()
                            
                            HStack{
                                Text("\(datum.name)")
                                Text("\(String(datum.quantity))")
                                Text("\(String(datum.cost))")
                                Button(action: {
                                    categoryToDeleteFrom = "chemicals"
                                    partToDelete = datum
                                    alertMessage = "Please Confirm Delete"
                                    
                                    Task{
                                        if let company = masterDataManager.selectedCompany {
                                            if categoryToDeleteFrom != "" {
                                                do {
                                                    print("Deleting...")
                                                    print(partToDelete)
                                                    try await jobVM.deletePart(companyId: company.id, jobId: job.id, part: partToDelete,category:categoryToDeleteFrom)
                                                    partToDelete = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
                                                    categoryToDeleteFrom = ""
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                    }
                                    
                                }, label: {
                                    Image(systemName: "trash.circle.fill")
                                })
                            }
                        }
                    }
                    VStack(alignment: .leading){
                        HStack{
                            Text("Misc:")
                                .font(.headline)
                            
                            Spacer()
                            Button(action: {
                                showmiscParts.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                            .sheet(isPresented: $showmiscParts,onDismiss: {
                                Task{
                                    if let company = masterDataManager.selectedCompany {
                                        do {
                                            try await jobVM.updateMiscJobParts(companyId: company.id, jobId: job.id, misc: miscPart)
                                            miscParts.append(miscPart)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            },  content: {
                                jobItemPicker(jobDBItems: $miscPart, category: "")
                            })
                        }
                        ForEach(miscParts){ datum in
                            Divider()
                            HStack{
                                Text("\(datum.name)")
                                Text("\(String(datum.quantity))")
                                Text("\(String(datum.cost))")
                                Button(action: {
                                    categoryToDeleteFrom = "miscParts"
                                    partToDelete = datum
                                    alertMessage = "Please Confirm Delete"
                                    
                                    Task{
                                        if let company = masterDataManager.selectedCompany {
                                            if categoryToDeleteFrom != "" {
                                                do {
                                                    print("Deleting...")
                                                    print(partToDelete)
                                                    try await jobVM.deletePart(companyId: company.id, jobId: job.id, part: partToDelete,category:categoryToDeleteFrom)
                                                    partToDelete = WODBItem(id: "", name: "", quantity: 0, cost: 0, genericItemId: "")
                                                    categoryToDeleteFrom = ""
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                    }
                                }, label: {
                                    Image(systemName: "trash.circle.fill")
                                })
                            }
                        }
                    }
                    Text("Purchased Items")
                        .font(.title)
                    
                    Rectangle()
                        .frame(height: 1)
                    VStack{
                        HStack{
                            Spacer()
                            Button(action: {
                                self.showPurchasedItemSelector.toggle()
                            }, label: {
                                Text("Select Purchased Items")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(8)
                            })
                            .sheet(isPresented: $showPurchasedItemSelector, content: {
                                PurchaseItemPicker()
                            })
                        }
                        if let array = job.purchasedItemsIds {
                            ForEach(array,id:\.self) { id in
                                PurchaseItemFromIdCardView(id:id)
                            }
                        }
                    }
                }
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        view = "Schedule"
                    }, label: {
                        Text("Next")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(5)
                    .padding(5)
                }
            }
    }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }
    var customerView: some View {
        
        ZStack{
            ScrollView{
                VStack(alignment: .leading,spacing:16){
                    HStack{
                        Text("Customer")
                            .bold(true)
                        Spacer()
                        Text("\(customer.firstName) \(customer.lastName)")
                    }
                    HStack{
                        Text("Service Location")
                            .bold(true)
                        Spacer()
                        Text("\(serviceLocation.address.streetAddress)")
                        
                    }
                    HStack{
                        Text("Body Of Water")
                            .bold(true)
                        Spacer()
                        if bodyOfWater.id == "" {
                            Text("\(bodyOfWater.name)")
                            Button(action: {
                                bodyOfWaterPicker.toggle()
                            }, label: {
                                Image(systemName: "gobackward")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                        } else {
                            Button(action: {
                                bodyOfWaterPicker.toggle()
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                        }
                    }
                    .sheet(isPresented: $bodyOfWaterPicker, content: {
                        Text("Developer Create Body Of Water Picker")
                        
                    })
                    HStack{
                        Text("Equipment")
                            .bold(true)
                        Spacer()
                        if equipment.id == "" {
                            Text("\(equipment.name)")
                            Button(action: {
                                equipmentPicker.toggle()
                            }, label: {
                                Image(systemName: "gobackward")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                        } else {
                            Button(action: {
                                equipmentPicker.toggle()
                                
                            }, label: {
                                Text("Add")
                                    .padding(.horizontal,8)
                                    .padding(.vertical,3)
                                    .background(Color.poolBlue)
                                    .foregroundColor(Color.basicFontText)
                                    .cornerRadius(3)
                            })
                        }
                    }
                    .sheet(isPresented: $equipmentPicker, content: {
                        Text("Developer Create Equipment Picker")
                    })
                }
            }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        view = "Parts"
                    }, label: {
                        Text("Next")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(5)
                    .padding(5)
                }
            }
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)

    }
    var info: some View {
        ZStack{
            ScrollView {
            VStack(alignment: .leading){
                HStack{
                    Text("Admin")
                        .bold(true)
                    Picker("Admin", selection: $admin) {
                        Text("Pick Admin").tag(DBUser(id: "",exp: 0))
                        ForEach(techVM.techList){ template in
                            let fullName = (template.firstName ?? "") + " " + (template.lastName ?? "")
                            Text(fullName).tag(template)
                        }
                    }
                }
                
                HStack{
                    Text("Job Type")
                        .bold(true)
                    Picker("Job Type", selection: $jobTemplate) {
                        Text("Pick Type").tag(JobTemplate(id: "", name: ""))
                        ForEach(settingsVM.jobTemplates){ template in
                            Text(template.name).tag(template)
                        }
                    }
                }
                HStack{
                    Text("Operation")
                        .bold(true)
                    Picker("Operation", selection: $operationStatus) {
                        ForEach(JobOperationStatus.allCases,id: \.self){ status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                HStack{
                    Text("Billing")
                        .bold(true)
                    Picker("Billing", selection: $billingStatus) {
                        ForEach(JobBillingStatus.allCases,id: \.self){ status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                HStack{
                    Text("Rate")
                        .bold(true)
                    TextField(
                        "Rate",
                        text: $rate
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Labor Cost")
                        .bold(true)
                    TextField(
                        "laborCost",
                        text: $laborCost
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Text("Description")
                        .bold(true)
                    TextField(
                        "Description",
                        text: $description
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Button(action: {
                        print("Build in Save Changes")
                        Task{
                            if let company = masterDataManager.selectedCompany{
                                do {
                                    if admin.id != job.adminId || admin.firstName != job.adminName ||  jobTemplate.id != job.jobTemplateId ||  jobTemplate.name != job.type || operationStatus != job.operationStatus || billingStatus != job.billingStatus  || String(job.rate) != rate || laborCost != String(job.laborCost) || description != job.description{
                                        try await jobVM.updateJobInfo(companyId:company.id,updatingJob: job,
                                                                      admin: admin,
                                                                      jobTemplate: jobTemplate,
                                                                      operationStatus: operationStatus,
                                                                      billingStatus: billingStatus,
                                                                      rate: rate,
                                                                      laborCost: laborCost,
                                                                      description: description)
                                    } else {
                                        
                                        alertMessage = "No Change Made"
                                        print(alertMessage)
                                        showAlert = true
                                    }
                                } catch {
                                    
                                    print("Error Updating Job")
                                }
                            }
                        }
                    }, label: {
                        Text("Save Changes")
                    })
                    .padding(5)
                    .background(Color.accentColor)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
                    .padding(5)
                    //Check For Changes in Admin, jobTemplate, operationStatus, billingStatus, Rate, laborRate, and Description
                    if admin.id != job.adminId || admin.firstName != job.adminName ||  jobTemplate.id != job.jobTemplateId ||  jobTemplate.name != job.type || operationStatus != job.operationStatus || billingStatus != job.billingStatus  || String(job.rate) != rate || laborCost != String(job.laborCost) || description != job.description{
                        Button(action: {
                            admin.id = job.adminId
                            admin.firstName = job.adminName
                            
                            jobTemplate.id = job.jobTemplateId
                            jobTemplate.name = job.type
                            
                            operationStatus = job.operationStatus
                            billingStatus = job.billingStatus
                            rate = String(job.rate)
                            laborCost = String(job.laborCost)
                            description = job.description
                        }, label: {
                            Text("Undo")
                                .foregroundColor(Color.black)
                                .padding(5)
                                .background(Color.red)
                                .padding(5)
                                .cornerRadius(5)
                        })
                    }
                    Spacer()

                }
            }
            
        }
            VStack{
                Spacer()
                HStack{
                    Spacer()
                    Button(action: {
                        view = "Customer"
                    }, label: {
                        Text("Next")
                    })
                    .padding(5)
                    .background(Color.poolBlue)
                    .foregroundColor(Color.white)
                    .cornerRadius(5)
                    .padding(5)
                }
            }
        }
            .padding(5)
            .cornerRadius(5)
            .border(Color.realYellow)
    }
    var submitButton: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    Task{
                        do {
                            guard let company = masterDataManager.selectedCompany else {
                                return
                            }
                            let customerFullName = customer.firstName + " " + customer.lastName
                            let adminFullName = (admin.firstName ?? "") + " " + (admin.lastName ?? "")
                            
                            try await jobVM.addNewJobWithValidation(companyId: company.id,
                                                                    jobId: jobId,
                                                                    jobTemplate: jobTemplate,
                                                                    dateCreated: dateCreated,
                                                                    description: description,
                                                                    operationStatus: operationStatus,
                                                                    billingStatus: billingStatus,
                                                                    customerId: customer.id,
                                                                    customerName: customerFullName,
                                                                    serviceLocationId: "",
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
                            alertMessage = "Successfully Updated"
                            print(alertMessage)
                            showAlert = true
                            dismiss()
                        } catch JobError.invalidRate{
                            alertMessage = "Invalid Rate"
                            print(alertMessage)
                            showAlert = true
                        } catch JobError.invalidLaborCost{
                            alertMessage = "Invalid Labor Cost"
                            print(alertMessage)
                            showAlert = true
                        } catch JobError.invalidAdmin{
                            alertMessage = "Invalid Admin Selected"
                            print(alertMessage)
                            showAlert = true
                        } catch JobError.invalidCustomer{
                            alertMessage = "Invalid Customer Selected"
                            print(alertMessage)
                            showAlert = true
                        } catch JobError.invalidJobType{
                            alertMessage = "Invalid Job Selected"
                            print(alertMessage)
                            showAlert = true
                        } catch JobError.invalidServiceLocation{
                            alertMessage = "Invalid Service Location Selected"
                            print(alertMessage)
                            showAlert = true
                        } catch  {
                            alertMessage = "Invalid Something"
                            print(alertMessage)
                            showAlert = true
                        }
                    }
                }, label: {
                    Text("Submit")
                })
                .foregroundColor(Color.basicFontText)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
            }
        }
    }
}
