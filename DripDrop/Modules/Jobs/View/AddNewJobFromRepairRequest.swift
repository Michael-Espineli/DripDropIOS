//
//  AddNewJobFromRepairRequest.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/4/24.
//

import SwiftUI

struct AddNewJobFromRepairRequest: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var settingsVM = SettingsViewModel(dataService: ProductionDataService())
    @StateObject var jobVM : JobViewModel
    @StateObject var customerVM : CustomerViewModel
    @StateObject var serviceLocationVM : ServiceLocationViewModel
    @StateObject var bodyOfWaterVM : BodyOfWaterViewModel
    @StateObject var equipmentVM : EquipmentViewModel
    @StateObject var servicestopVM : ServiceStopsViewModel
    
    @StateObject var techVM = TechViewModel()
    @State var customer:Customer?
    @Binding var returnJobId:String
    init(customer:Customer?,dataService:any ProductionDataServiceProtocol,returnJobId:Binding<String>){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _serviceLocationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _bodyOfWaterVM = StateObject(wrappedValue: BodyOfWaterViewModel(dataService: dataService))
        _equipmentVM = StateObject(wrappedValue: EquipmentViewModel(dataService: dataService))
        _servicestopVM = StateObject(wrappedValue: ServiceStopsViewModel(dataService: dataService))
        _customer = State(wrappedValue: customer)
        _returnJobId = returnJobId
    }
    @State var view:String = "Info"
    @State var viewList:[String] = ["Info","Customer","Parts","Schedule","Review"]
    @State var jobId:String = "Job Id"
    //Body Of Water
    @State var jobTemplate:JobTemplate = JobTemplate(id: "", name: "")
    @State var serviceStopTemplate:ServiceStopTemplate = ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: "")
    
    @State var dateCreated:Date = Date()
    @State var description:String = ""
    
    @State var operationStatus:JobOperationStatus = .estimatePending
    
    @State var billingStatus:JobBillingStatus = .draft
    
    @State var customerEntity:Customer = Customer(
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
        serviceLocationId: "",
        lastFilled: Date()
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
        bodyOfWaterId: "",
        isActive: true
    )
    
    @State var admin:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    @State var tech:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: "")
    
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
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showBodyOfWaterSheet:Bool = false
    
    @State var showTreeSheet:Bool = false
    @State var showBushSheet:Bool = false
    
    //Service Stop
    @State var serviceDate:Date = Date()
    @State var includeReadings:Bool = false
    @State var includeDosages:Bool = false
    @State var checkList:[String] = []
    @State var duration:String = "0"
    
    @State var serviceStopList:[ServiceStop] = []
    
    @State var expandJobDetails:Bool = false
    
    //Keyboard Info
    @FocusState private var focusedField: String?

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                if  expandJobDetails {
                    HStack{
                        
                        Picker("", selection: $view) {
                            ForEach(viewList,id: \.self){ datum in
                                Text(datum).tag(datum)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    switch view {
                    case "Customer":
                        customerView
                    case "Info":
                        info
                    case "Parts":
                        part
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
            .padding(.horizontal,10)
        }
        .navigationTitle("ID : \(jobId)")
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .toolbar{
            Button(action: {
                expandJobDetails.toggle()
            }, label: {
                Text(expandJobDetails ? "Simplify": "Expand")
                    .padding(8)
                    .background(Color.poolBlue)
                    .cornerRadius(8)
                    .foregroundColor(Color.basicFontText)
            })
        
        }
        .task {
            do {
                if let company = masterDataManager.currentCompany {
                    let id = try await settingsVM.getWorkOrderCount(companyId: company.id)
                    jobId = "J" + String(id)
                    if let customer1 = customer {
                        customerEntity  = customer1
                    }
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
        .onChange(of: view, perform: { datum in
            print(datum)
            switch datum {
            case "Customer":
                if admin.id == "" {
                    view = "Info"
                } else  if jobTemplate.id == "" {
                    view = "Info"
                }
            case "Parts":
                if admin.id == "" {
                    view = "Info"
                } else  if jobTemplate.id == "" {
                    view = "Info"
                } else if customerEntity.id == "" {
                    view = "Customer"
                } else if serviceLocation.id == "" {
                    view = "Customer"
                } else  if bodyOfWater.id == "" {
                    view = "Customer"
                } else if equipment.id == "" {
                    view = "Customer"
                }
            case "Schedule":
                if admin.id == "" {
                    view = "Info"
                } else  if jobTemplate.id == "" {
                    view = "Info"
                } else if customerEntity.id == "" {
                    view = "Customer"
                } else if serviceLocation.id == "" {
                    view = "Customer"
                } else  if bodyOfWater.id == "" {
                    view = "Customer"
                } else if equipment.id == "" {
                    view = "Customer"
                }
            case "Review":
                if admin.id == "" {
                    view = "Info"
                } else  if jobTemplate.id == "" {
                    view = "Info"
                } else if customerEntity.id == "" {
                    view = "Customer"
                } else if serviceLocation.id == "" {
                    view = "Customer"
                } else  if bodyOfWater.id == "" {
                    view = "Customer"
                } else if equipment.id == "" {
                    view = "Customer"
                }
            default:
                view = "Info"
            }
            @State var viewList:[String] = ["Info","Customer","Parts","Schedule","Review"]
            
        })
        .onChange(of: jobTemplate, perform: { template in
            rate = template.rate ?? "0"
        })
        .onChange(of: admin, perform: { admin in
            tech = admin
        })
        .onChange(of: customerEntity, perform: { cus in
            Task{
                do {
                    if let company = masterDataManager.currentCompany {
                        if cus.id != "" {
                            try await serviceLocationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: cus.id)
                            serviceLocations = serviceLocationVM.serviceLocations
                            if serviceLocations.count != 0 {
                                serviceLocation = serviceLocations.first!
                            } else {
                                serviceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "")
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
                    if let company = masterDataManager.currentCompany {
                        if loc.id != "" {
                            try await bodyOfWaterVM.getAllBodiesOfWaterByServiceLocation(companyId: company.id, serviceLocation: loc)
                            bodyOfWaterList = bodyOfWaterVM.bodiesOfWater
                            
                            if bodyOfWaterList.count != 0 {
                                bodyOfWater = bodyOfWaterList.first!
                            } else {
                                bodyOfWater = BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date())
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
                    if let company = masterDataManager.currentCompany {
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
                                    bodyOfWaterId: "",
                                    isActive:true
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

extension AddNewJobFromRepairRequest {
    var review: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading,spacing: 10){
                
                Text("Review")
                    .font(.headline)
                HStack{
                    Text("Admin : \(admin.firstName ?? "") \(admin.lastName ?? "")")
                    Spacer()
                    Button(action: {
                        view = "Info"
                    }, label: {
                        Image(systemName: "pencil")
                    })
                }
                HStack{
                    Text("Customer : \(customerEntity.firstName) \(customerEntity.lastName)")
                    Spacer()
                    Button(action: {
                        view = "Customer"
                    }, label: {
                        Image(systemName: "pencil")
                    })
                }
                Text("Address : \(serviceLocation.address.streetAddress) \(serviceLocation.address.city)")
                Text("Body Of Water : \(bodyOfWater.name)")
                Text("Equipment : \(equipment.name)")
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
            VStack(alignment: .leading,spacing: 10){
                Text("Labor Cost: $\(laborCost).00")
                Text("Rate: $\(rate).00")
                HStack{
                    Text("Estimated Cost: \(getTotal(installation: installationParts, pvc: pvcParts, electrical: electricalParts, chems: chemicals, misc: miscParts, labor: laborCost))")
                }
            }
            submitButton
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }
    var schedule: some View {
        VStack(alignment: .leading){
            Text("Schedule First Service Stop")
            HStack{
                Text("Service Date: ")
                DatePicker(selection: $serviceDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("Job Type")
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
                    Text("Pick Tech").tag( DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
                    ForEach(techVM.techList){ template in
                        let fullName = (template.firstName ?? "") + " " + (template.lastName ?? "")
                        Text(fullName).tag(template)
                    }
                }
            }
            VStack{
                Toggle(isOn: $includeReadings, label: {
                    Text("Include Readings")
                })
                Toggle(isOn: $includeDosages, label: {
                    Text("Include Dosages")
                })
                TextField(
                    "Duration",
                    text: $duration,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.white)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                TextField(
                    "Description",
                    text: $description,
                    axis: .vertical
                )
                .padding(5)
                .background(Color.white)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.currentCompany {
                            let customerFullName = customerEntity.firstName + " " + customerEntity.lastName
                            let techFullName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
                            try await servicestopVM.addNewServiceStopWithValidation(
                                companyId: company.id,
                                typeId: jobTemplate.id,
                                customerName: customerFullName,
                                customerId: customerEntity.id,
                                address: serviceLocation.address,
                                dateCreated: Date(),
                                serviceDate: serviceDate,
                                duration: duration,
                                tech: techFullName,
                                techId: tech.id,
                                recurringServiceStopId: "",
                                description: description,
                                serviceLocationId: serviceLocation.id,
                                type: jobTemplate.name,
                                typeImage: jobTemplate.typeImage ?? "",
                                jobId: jobId,
                                operationStatus: .notFinished,
                                billingStatus: .notInvoiced,
                                includeReadings: true,
                                includeDosages: true
                            )
                            operationStatus = .estimatePending
                            billingStatus = .estimate
                            alertMessage = "Successfully Added Service Stop"
                            showAlert = true
                        }
                    } catch {
                        print(error)
                    }
                }
            },
                   label: {
                Text("Add Service stop")
            })
            HStack{
                Spacer()
                Button(action: {
                    view = "Review"
                }, label: {
                    Text("Next")
                })
                .padding(5)
                .background(Color.accentColor)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
            }
            if serviceStopList.count == 0 {
                Text("Please Schedule First Service Stop")
            } else {
                ForEach(serviceStopList){ stop in
                    HStack{
                        Text("\(stop.type) - \(fullDate(date:stop.dateCreated)) - ")
                        Text("\(stop.operationStatus.rawValue)")
                            .foregroundColor(stop.operationStatus == .finished ? Color.green : Color.red)
                    }
                }
            }
        }
        .padding(5)
        .cornerRadius(5)
        .border(Color.realYellow)
    }
    var part: some View {
        VStack(alignment: .leading,spacing: 10){
            Text("Parts: ")
            VStack{
                HStack{
                    Text("Installation Parts")
                    Spacer()
                    Button(action: {
                        showInstallationParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $showInstallationParts,onDismiss: {
                        installationParts.append(installationPart)

                    }, content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $installationPart, category: "Equipment")
                        
                    })
                }
                ForEach(installationParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("PVC Parts")
                    Spacer()
                    Button(action: {
                        showpvcParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $showpvcParts,onDismiss: {
                        pvcParts.append(pvcPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $pvcPart, category: "PVC")
                    })
                }
                ForEach(pvcParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Electrical Parts")
                    Spacer()
                    Button(action: {
                        showelectricalParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $showelectricalParts,onDismiss: {
                        electricalParts.append(electricalPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $electricalPart, category: "Electrical")
                    })
                }
                ForEach(electricalParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Chemicals")
                    Spacer()
                    Button(action: {
                        showchemicals.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $showchemicals,onDismiss: {
                        chemicals.append(chemical)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $chemical, category: "Chems")
                    })
                }
                ForEach(chemicals){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            VStack{
                HStack{
                    Text("Misc")
                    Spacer()
                    Button(action: {
                        showmiscParts.toggle()
                    }, label: {
                        Text("Add")
                    })
                    .sheet(isPresented: $showmiscParts,onDismiss: {
                        miscParts.append(miscPart)

                    },  content: {
                        jobItemPicker(dataService: dataService, jobDBItems: $miscPart, category: "")
                    })
                }
                ForEach(miscParts){ datum in
                    Text("\(datum.name) \(String(datum.quantity)) \(String(datum.cost))")
                }
            }
            HStack{
                Spacer()
                Button(action: {
                    view = "Schedule"
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
    var simpleJobView: some View {
        VStack{
            HStack{
                Text("Tech :")
                    .bold(true)
                Spacer()
                Picker("Tech", selection: $admin) {
                    Text("Pick Tech").tag( DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
                    ForEach(techVM.techList){ template in
                        let fullName = (template.firstName ?? "") + " " + (template.lastName ?? "")
                        Text(fullName).tag(template)
                    }
                }
            }

            HStack{
                Text("Customer :")
                    .bold(true)
                Spacer()
                Button(action: {
                    showCustomerSelector.toggle()
                }, label: {
                    if customerEntity.id == "" {
                        Text("Select Customer")
                    } else {
                        Text("\(customerEntity.firstName) \(customerEntity.lastName)")
                    }
                })
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $showCustomerSelector, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customerEntity)

                })
            }
            HStack{
                Text("Service Location :")
                    .bold(true)
                Spacer()
                Picker("Location", selection: $serviceLocation) {
                    Text("Pick Location").tag(ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: ""))
                    ForEach(serviceLocations){ template in
                        Text(template.address.streetAddress).tag(template)
                    }
                }
            }
            HStack{
                Text("Service Date :")
                    .bold(true)
                DatePicker(selection: $serviceDate, displayedComponents: .date) {
                }
            }
            HStack{
                Text("Job Type :")
                    .bold(true)
                Spacer()
                Picker("Job Type", selection: $jobTemplate) {
                    Text("Pick Type").tag(JobTemplate(id: "", name: ""))
                    ForEach(settingsVM.jobTemplates){ template in
                        Text(template.name).tag(template)
                    }
                }
            }
            HStack{
                Text("Service Type :")
                    .bold(true)
                Spacer()
                Picker("Service Stop Type", selection: $serviceStopTemplate) {
                    Text("Pick Type").tag(ServiceStopTemplate(id: "", name: "", type: "", typeImage: "", dateCreated: Date(), color: ""))
                    ForEach(settingsVM.serviceStopTemplates){ template in
                        Text(template.name).tag(template)
                    }
                }
            }
            HStack{
                Text("Description :")
                    .bold(true)
                Spacer()
                Button(action: {
                    description = ""
                }, label: {
                    Text("Clear")
                        .foregroundStyle(Color.basicFontText)
                })
            }
      
   //DEVELOPER MULTI LINE
//            TextField(
//                "Description",
//                text: $description,
//                axis: .vertical
//            )
            TextField("Description...", text: $description) {

                UIApplication.shared.endEditing()
            }
            .textFieldStyle(PlainTextFieldStyle())
            .foregroundColor(Color.black)
            .padding(8)
            .background(Color.poolWhite)
            .cornerRadius(8)
            .padding(8)
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
            submitButtonSimple
        }
    }
    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Customer")
                    .bold(true)
                Spacer()
                Button(action: {
                    showCustomerSelector.toggle()
                }, label: {
                    if customerEntity.id == "" {
                        Text("Select Customer")
                    } else {
                        Text("\(customerEntity.firstName) \(customerEntity.lastName)")
                    }
                })
                .padding(5)
                .background(Color.poolBlue)
                .foregroundColor(Color.basicFontText)
                .cornerRadius(5)
                .padding(5)
                .sheet(isPresented: $showCustomerSelector, content: {
                    CustomerPickerScreen(dataService: dataService, customer: $customerEntity)

                })
            }
                HStack{
                    Text("Service Location")
                        .bold(true)
                    Picker("Location", selection: $serviceLocation) {
                        Text("Pick Location").tag(ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: ""))
                        ForEach(serviceLocations){ template in
                            Text(template.address.streetAddress).tag(template)
                        }
                    }
                }
                HStack{
                    Text("Body Of Water")
                        .bold(true)
                    Picker("BOW", selection: $bodyOfWater) {
                        Text("Pick Location").tag(BodyOfWater(id: "", name: "", gallons: "", material: "", customerId: "", serviceLocationId: "", lastFilled: Date()))
                        ForEach(bodyOfWaterList){ BOW in
                            Text(BOW.name).tag(BOW)
                        }
                    }
                }
                HStack{
                    Text("Equipmnet")
                        .bold(true)
                    Picker("Equipment", selection: $equipment) {
                        Text("Pick Equipment").tag(
                            Equipment(
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
                                bodyOfWaterId: "",
                                isActive: true
                            )
                        )
                        ForEach(equipmentList){ equipment in
                            Text(equipment.name).tag(equipment)
                        }
                    }
                }
            HStack{
                Spacer()
                Button(action: {
                    view = "Parts"
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
    var info: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Admin")
                    .bold(true)
                Picker("Admin", selection: $admin) {
                    Text("Pick Admin").tag( DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0,recentlySelectedCompany: ""))
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
                Spacer()
                Button(action: {
                    view = "Customer"
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
    var submitButton: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        do {
                            guard let company = masterDataManager.currentCompany else {
                                return
                            }
                            let customerFullName = customerEntity.firstName + " " + customerEntity.lastName
                            let adminFullName = (admin.firstName ?? "") + " " + (admin.lastName ?? "")
                            
                            try await jobVM.addNewJobWithValidation(companyId: company.id,
                                                                    jobId: jobId,
                                                                    jobTemplate: jobTemplate,
                                                                    dateCreated: dateCreated,
                                                                    description: description,
                                                                    operationStatus: operationStatus,
                                                                    billingStatus: billingStatus,
                                                                    customerId: customerEntity.id,
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
                            alertMessage = "Successfully Created Job"
                            returnJobId = jobId
                            print(alertMessage)
                            showAlert = true
//                            receivedJobId = jobId
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
                        .frame(maxWidth: .infinity)
                        .modifier(SubmitButtonModifier())
                        .clipShape(Capsule())
                })
    
            }
        }
    }
    var submitButtonSimple: some View {
        VStack{
            HStack{
                Button(action: {
                    Task{
                        do {
                            guard let company = masterDataManager.currentCompany else {
                                return
                            }
                            let customerFullName = customerEntity.firstName + " " + customerEntity.lastName
                            let adminFullName = (admin.firstName ?? "") + " " + (admin.lastName ?? "")
                            let techFullName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
                            let SSID = try await servicestopVM.addNewServiceStopWithValidation(
                                companyId: company.id,
                                typeId: jobTemplate.id,
                                customerName: customerFullName,
                                customerId: customerEntity.id,
                                address: serviceLocation.address,
                                dateCreated: Date(),
                                serviceDate: serviceDate,
                                duration: duration,
                                tech: techFullName,
                                techId: tech.id,
                                recurringServiceStopId: "",
                                description: description,
                                serviceLocationId: serviceLocation.id,
                                type: jobTemplate.id,
                                typeImage: jobTemplate.typeImage ?? "",
                                jobId: jobId,
                                operationStatus: .notFinished,
                                billingStatus: .notInvoiced,
                                includeReadings: true,
                                includeDosages: true
                            )
                            serviceStopIds.append(SSID)
                            try await jobVM.addNewJobWithValidation(
                                companyId: company.id,
                                jobId: jobId,
                                jobTemplate: jobTemplate,
                                dateCreated: dateCreated,
                                description: description,
                                operationStatus: operationStatus,
                                billingStatus: billingStatus,
                                customerId: customerEntity.id,
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
                                equipment: equipment
                            )
                            returnJobId = jobId
                            
                            alertMessage = "Successfully Created Job"
                            print(alertMessage)
                            showAlert = true
                                //                            receivedJobId = jobId
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
                },
                       label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .modifier(SubmitButtonModifier())

                        .clipShape(Capsule())
                })
    
            }
        }
    }

}
