//
//  EditJobView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/15/24.
//

import SwiftUI

struct EditJobView: View {
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
    var body: some View {
        VStack{
            ScrollView{

                HStack{
                  
                    Picker("", selection: $view) {
                        ForEach(viewList,id: \.self){ datum in
                            Text(datum).tag(datum)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Text("Job ID: \(jobId)")
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
            }
            .padding()
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
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
            do {
                if let company = masterDataManager.selectedCompany {
                    try await serviceLocationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: job.customerId, locationId: job.serviceLocationId)
                    if let location = serviceLocationVM.serviceLocation {
                        serviceLocation = location
                    }
                    try await bodyOfWaterVM.getSpecificBodyOfWater(companyId: company.id, bodyOfWaterId: job.bodyOfWaterId ?? "")
                    if let BOW = bodyOfWaterVM.bodyOfWater {
                        bodyOfWater = BOW
                    }
                    try await equipmentVM.getSinglePieceOfEquipmentWithId(companyId: company.id, equipmentId: job.equipmentId ?? "")
                    if let eq = equipmentVM.equipment {
                        equipment = eq
                    }
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
                } else if customer.id == "" {
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
                } else if customer.id == "" {
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
                } else if customer.id == "" {
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
                                serviceLocation = ServiceLocation(id: "", nickName: "", address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), gateCode: "", mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""), bodiesOfWaterId: [], rateType: "", laborType: "", chemicalCost: "", laborCost: "", rate: "", customerId: "", customerName: "",preText:false)
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

extension EditJobView {
    var review: some View {
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
                Text("Body Of Water: \(bodyOfWater.name)")
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
            VStack(alignment: .leading,spacing: 10){
                
                Text("Labor Cost: $\(laborCost).00")
                Text("Rate: $\(rate).00")
                HStack{
                    Text("Estimated Cost: \(getTotal(installation: installationParts, pvc: pvcParts, electrical: electricalParts, chems: chemicals, misc: miscParts, labor: laborCost))")
                }
            }
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
                    Text("Pick Tech").tag(DBUser(id: "",exp: 0))
                    ForEach(techVM.techList){ template in
                        let fullName = (template.firstName ?? "") + " " + (template.lastName ?? "")
                        Text(fullName).tag(template)
                    }
                }
            }
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
            Button(action: {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                            let customerFullName = customer.firstName + " " + customer.lastName
                            let techFullName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
                            try await servicestopVM.addNewServiceStopWithValidation(companyId: company.id,
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
                                                                                    description: description,
                                                                                    serviceLocationId: serviceLocation.id,
                                                                                    type: jobTemplate.name,
                                                                                    typeImage: jobTemplate.typeImage ?? "",
                                                                                    jobId: jobId,
                                                                                    finished: false,
                                                                                    skipped: false,
                                                                                    invoiced: false,
                                                                                    checkList: checkList,
                                                                                    includeReadings: includeReadings,
                                                                                    includeDosages: includeDosages)
                            operationStatus = .estimatePending

                            billingStatus = .estimate
                            alertMessage = "Successfully Added Service Stop"
                            showAlert = true
                        }
                    } catch {
                        
                    }
                }
            }, label: {
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
                        Text("\(stop.finished ? "Finished" : "Unfinished")")
                            .foregroundColor(stop.finished ? Color.green : Color.red)
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
    var customerView: some View {
        VStack(alignment: .leading){
            HStack{
                Text("Customer")
                    .bold(true)
                Spacer()
                Text("\(customer.firstName) \(customer.lastName)")
            }
            HStack{
                Text("Service Location")
                    .bold(true)
                Text("\(serviceLocation.address.streetAddress)")

            }
            HStack{
                Text("Body Of Water")
                    .bold(true)
                if serviceLocation.id == "" {
                    Text("\(serviceLocation.address.streetAddress)")
                }
            }
            HStack{
                Text("Equipmnet")
                    .bold(true)
                if equipment.id == "" {
                    Text("\(equipment.name)")
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
