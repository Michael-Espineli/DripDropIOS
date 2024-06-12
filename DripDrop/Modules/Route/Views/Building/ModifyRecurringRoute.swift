//
//  ModifyRecurringRoute.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/24/24.
//

import SwiftUI

struct ModifyRecurringRoute: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    @StateObject private var customerVM : CustomerViewModel
    @StateObject var locationVM : ServiceLocationViewModel
    @StateObject var recurringServiceStopVM = RecurringStopViewModel()
    @StateObject var companyUserVM = CompanyUserViewModel()

    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser,day:String,recurringRoute:RecurringRoute){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        
        _tech = State(wrappedValue: tech)
        _day = State(wrappedValue: day)
        _recurringRoute = State(wrappedValue: recurringRoute)
    }
    @StateObject var techVM = TechViewModel()
    @StateObject var settingsVM = SettingsViewModel()
    @StateObject var recurringStopVM = RecurringStopViewModel()
    @StateObject var recurringRouteVM = RecurringRouteViewModel()
    
    
    @State var tech:CompanyUser
    @State var day:String
    @State var recurringRoute:RecurringRoute
    
    @State var listOfRecurringStops:[RecurringServiceStop] = []
    @State var jobType:JobTemplate = JobTemplate(id: "",
                                                 name: "Job Template",
                                                 type: "",
                                                 typeImage: "",
                                                 dateCreated: Date(),
                                                 rate: "",
                                                 color: "")
    @State var customer:Customer = Customer(id: "",
                                            firstName: "",
                                            lastName: "",
                                            email: "",
                                            billingAddress: Address(streetAddress: "",
                                                                    city: "",
                                                                    state: "",
                                                                    zip: "0",
                                                                    latitude: 0,
                                                                    longitude: 0),
                                            active: false,
                                            displayAsCompany: false,
                                            hireDate: Date(),
                                            billingNotes: "")
    @State var customerSearch:String = ""
    @State var listOfCustomers:[Customer] = []
    
    @State var location:ServiceLocation = ServiceLocation(id: "", nickName: "Location",
                                                                  address: Address(streetAddress: "",
                                                                                   city: "",
                                                                                   state: "",
                                                                                   zip: "0",
                                                                                   latitude: 0,
                                                                                   longitude: 0),
                                                                  gateCode: "",
                                                                  mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
                                                                  bodiesOfWaterId: [],
                                                                  rateType: "", laborType: "",
                                                                  chemicalCost: "",
                                                                  laborCost: "",
                                                                  rate: "",
                                                                  customerId: "",
                                                                  customerName: "",
                                                          preText: false)
    
    @State var techEntity:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active)
    @State var techList:[CompanyUser] = []
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    @State var transitionDate:Date = Date()

    @State var noEndDate:Bool = true
    @State var standardFrequencyType:String = "Weekly"
    
    @State var customMeasurmentsOfTime:String = "Daily"
    @State var customEvery:Int = 1
    @State var showCustomSheet:Bool = false
    @State var showCustomerSheet:Bool = false
    @State var showAddNewCustomer:Bool = false
    
    @State var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @State var measurementsOfTime:[String] = ["Daily","WeekDay","Weekly","Bi-Weekly","Monthly","Custom"]
    
    @State var description:String = "description"
    @State var estimatedTime:String = "15"
    @State var selectedDay:String = ""
    //errors
    @State var showAlert:Bool = false
    @State var alertMessage:String = "Error"
    @State var isLoading:Bool = false
    
    var body: some View {
        ZStack{
            VStack{
                ScrollView{
                    if UIDevice.isIPad{
                        HStack{
                            Spacer()
                            Button(action: {
                                masterDataManager.routeBuilderTech = nil
                                masterDataManager.routeBuilderDay = nil
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                    }
                    form
                    button
                }
            }
            if isLoading {
                ProgressView()
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        /*
        .onAppear(perform: {
            Task{
                print("On Appear")
                techEntity = tech
                
                if let company = masterDataManager.selectedCompany {
                    let RecurringRouteId = selectedDay + techEntity.id
                    print("Recurring Route Id >> \(RecurringRouteId)")
                    try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: RecurringRouteId)
                    print("Recurring Route Successful Id >> \(recurringRouteVM.recurringRoute?.id)")
                    if recurringRouteVM.recurringRoute != nil {
                        print("Recurring Route is not nil")
                        var listOfRSS :[RecurringServiceStop] = []
                        print("Recurring Route Order List >> \(recurringRouteVM.recurringRoute?.order.count)")
                        for RSS in recurringRouteVM.recurringRoute?.order ?? [] {
                            do {
                                try await locationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: RSS.customerId, locationId: RSS.locationId)
                                try await recurringServiceStopVM.getReucrringServiceStopById(companyId: company.id, recurringServiceStopId: RSS.recurringServiceStopId)
                                
                                if let recurringStop = recurringServiceStopVM.recurringServiceStop {
                                    listOfRSS.append(recurringStop)
                                }
                            } catch {
                                print("No Location at spot")
                                //Maybe Remove Order from Recurring Route (Binder)
                            }
                        }
                        listOfRecurringStops = listOfRSS
                    } else {
                        print("Recurring Route is Nil")
                    }
                } else {
                    print("No Company Selected")
                }
            }
        })
        */
        .task {
            print("on arrival task")
            isLoading = true
            if let company = masterDataManager.selectedCompany {
                print("Company - \(company)")
                print("Day - \(day)")
                print("Tech - \(tech.userName)")
                techEntity = tech
                selectedDay = day
                //Get Customers
                do {
                    try await customerVM.getAllCustomers(companyId: company.id)
                    listOfCustomers = customerVM.customers
                    if customerVM.customers.count != 0 {
                        customer = customerVM.customers.first!
                        print("Received \(customerVM.customers.count) Customers")
                    } else {
                        print("No Customers")
                    }
                } catch {
                    print("Error Getting Customers")
                }
                //Get Techs
                do {
                    
                    try await companyUserVM.getAllCompanyUsersByStatus(companyId: company.id, status: "Active")
                    if companyUserVM.companyUsers.count != 0 {
                        
                        print("Received \(techVM.techList.count) Techs")
                        techList = companyUserVM.companyUsers
                    } else {
                        print("No Techs Received")
                    }
                }catch{
                    print("Error Getting Techs")
                }
                //Get Jobs
                do{
                    try await settingsVM.getWorkOrderTemplates(companyId: company.id)
                    if settingsVM.jobTemplates.count != 0 {
                        jobType = settingsVM.jobTemplates.first(where: {$0.name == "Weekly Cleaning"})! //DEVELOPER FIX THIS EXPLICIT UNWRAP
                        print("Received \(settingsVM.jobTemplates.count) Job Templates")
                        
                    } else {
                        print("No Jobs")
                    }
                } catch {
                    print("Error Getting Jobs")
                }
                //Get Route if it exists
                do {
                let RecurringRouteId = selectedDay + techEntity.id
                print("Recurring Route Id >> \(RecurringRouteId)")
                try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: RecurringRouteId)
                print("Recurring Route Successful Id >> \(recurringRouteVM.recurringRoute?.id)")
                    if recurringRouteVM.recurringRoute != nil {
                        print("Recurring Route is not nil")
                        var listOfRSS :[RecurringServiceStop] = []
                        print("Recurring Route Order List >> \(recurringRouteVM.recurringRoute?.order.count)")
                        for RSS in recurringRouteVM.recurringRoute?.order ?? [] {
                            try await locationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: RSS.customerId, locationId: RSS.locationId)
                            try await recurringServiceStopVM.getReucrringServiceStopById(companyId: company.id, recurringServiceStopId: RSS.recurringServiceStopId)
                            
                            if let recurringStop = recurringServiceStopVM.recurringServiceStop {
                                listOfRSS.append(recurringStop)
                            }
                            
                        }
                        listOfRecurringStops = listOfRSS
                 
                } else {
                    print("Recurring Route is Nil")
                }
                } catch {
                    print("Error in setting up Modifying Recurring Route")
                }
            } else {
                print("Company is invalid")
            }
            isLoading = false
            
        }
        .onChange(of: standardFrequencyType, perform: { freq in
            print(freq)
            if freq == "Custom" {
                showCustomSheet = true
            }
        })
        //Gets customer locations
        .onChange(of: customer, perform: { changedCustomer in
            if !isLoading {
                
                Task{
                    if let company = masterDataManager.selectedCompany {
                        print("Change of Customer")
                        do {
                            try await locationVM.getAllCustomerServiceLocationsById(companyId: company.id, customerId: changedCustomer.id)
                        } catch {
                            print("Error Getting locations")
                        }
                        if locationVM.serviceLocations.count != 0 {
                            location = locationVM.serviceLocations.first!
                        } else {
                            location = ServiceLocation(id: "", nickName: "Location",
                                                           address: Address(streetAddress: "",
                                                                            city: "",
                                                                            state: "",
                                                                            zip: "0",
                                                                            latitude: 0,
                                                                            longitude: 0),
                                                           gateCode: "",
                                                           mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
                                                           bodiesOfWaterId: [],
                                                           rateType: "", laborType: "",
                                                           chemicalCost: "",
                                                           laborCost: "",
                                                           rate: "",
                                                           customerId: "",
                                                           customerName: "",
                                                       preText: false)
                        }
                    }
                }
            }
        })
        .onChange(of: customerSearch, perform: { search in
            if search == "" {
                listOfCustomers = customerVM.customers
            } else {
                customerVM.filterCustomerList(filterTerm: search, customers: customerVM.customers)
                listOfCustomers = customerVM.filteredCustomers
                if listOfCustomers.count != 0 {
                    customer = listOfCustomers.first!
                }
            }
        })
        .onChange(of: selectedDay, perform: { datum in
            //DEVLOPER IMPORT OTHER RECURRING ROUTE SETTINGS
            if !isLoading {
                
                Task{
                    isLoading = true
                    
                    if let company = masterDataManager.selectedCompany {
                        print("Change of Day")
                        
                        if techEntity.id != "" && datum != "" {
                            let RecurringRouteId = datum + techEntity.id
                            do {
                                try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: RecurringRouteId)
                                if recurringRouteVM.recurringRoute != nil {
                                    var listOfRSS :[RecurringServiceStop] = []
                                    for RSS in recurringRouteVM.recurringRoute?.order ?? [] {
                                        do {
                                            try await locationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: RSS.customerId, locationId: RSS.locationId)
                                            try await recurringServiceStopVM.getReucrringServiceStopById(companyId: company.id, recurringServiceStopId: RSS.recurringServiceStopId)
                                            
                                            if let recurringStop = recurringServiceStopVM.recurringServiceStop {
                                                listOfRSS.append(recurringStop)
                                            }
                                            
                                        } catch {
                                            print("No Location at spot")
                                            //Maybe Remove Order from Recurring Route (Binder)
                                        }
                                    }
                                    self.listOfRecurringStops = listOfRSS
                                }
                            } catch {
                                print("Error")
                            }
                        }
                        //Get Route if it exists
                        
                    } else {
                        print("Error")
                    }
                    isLoading = false
                    
                }
                
            }
        })
        .onChange(of: techEntity, perform: { tech in
            if !isLoading {
                Task{
                    isLoading = true
                    
                    if let company = masterDataManager.selectedCompany {
                        print("Change of Tech")
                        
                        if tech.id != "" && selectedDay != "" {
                            let RecurringRouteId = selectedDay + techEntity.id
                            do {
                                try await recurringRouteVM.getSingleRoute(companyId: company.id, recurringRouteId: RecurringRouteId)
                                print("Successfully Received New Recurring Route For \(RecurringRouteId)")
                                if recurringRouteVM.recurringRoute != nil {
                                    var listOfRSS :[RecurringServiceStop] = []
                                    for RSS in recurringRouteVM.recurringRoute?.order ?? [] {
                                        do {
                                            try await locationVM.getServiceLocationByCustomerAndLocationId(companyId: company.id, customerId: RSS.customerId, locationId: RSS.locationId)
                                            try await recurringServiceStopVM.getReucrringServiceStopById(companyId: company.id, recurringServiceStopId: RSS.recurringServiceStopId)
                                            
                                            if let recurringStop = recurringServiceStopVM.recurringServiceStop {
                                                listOfRSS.append(recurringStop)
                                            }
                                            
                                        } catch {
                                            print("No Location at spot")
                                            //Maybe Remove Order from Recurring Route (Binder)
                                        }
                                    }
                                    self.listOfRecurringStops = listOfRSS
                                } else {
                                    print("No Route For This Tech and Day. Resetting Form ...")
                                    //May Need to Reset Additional Values.
                                    listOfRecurringStops = []
                                    print("Reset Recurring Route")
                                }
                            } catch {
                                print("Error No Route For This Tech and Day. Resetting Form ...")
                                //May Need to Reset Additional Values.
                                listOfRecurringStops = []
                                print("Reset Recurring Route")
                            }
                        } else {
                            print("Tech or day value is blank")
                        }
                        //Get Route if it exists
                        
                    } else {
                        print("Error")
                    }
                    isLoading = false
                    
                }
            }
        })
    }
}


extension ModifyRecurringRoute {
    var button: some View {
        HStack{
            Button(action: {
                Task{
                    isLoading = true
                    
                    if techEntity.id == "" || techEntity.userName == ""{
                        alertMessage = "No Tech Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let techFullName = (techEntity.userName)
                    print("techFullName \(techFullName)")
                    let techId = techEntity.id
                    print("techId \(techId)")
                    
                    let pushTechEntity = techEntity
                    
                    let pushDay = selectedDay
                    print("pushDay \(pushDay)")
                    
                    let pushStartDate = startDate
                    print("pushStartDate \(pushStartDate)")
                    
                    let pushEndDate = endDate
                    print("pushEndDate \(pushEndDate)")
                    
                    let pushStandardFrequencyType = standardFrequencyType
                    print("pushStandardFrequencyType \(pushStandardFrequencyType)")
                    
                    let pushNoEndDate = noEndDate
                    print("pushNoEndDate \(pushNoEndDate)")
                    
                    let pushCustomMeasurmentOfTime = customMeasurmentsOfTime
                    print("pushCustomMeasurmentOfTime \(pushCustomMeasurmentOfTime)")
                    
                    let pushCustomEvery:Int = Int(customEvery)
                    print("techFullName \(techFullName)")
                    
                    let pushDescription = description
                    print("pushDescription \(pushDescription)")
                    
                    let pushEstimatedTime = estimatedTime
                    print("pushEstimatedTime \(pushEstimatedTime)")
                    
                    let pushRecurringServiceStopList = listOfRecurringStops
                    print("pushRecurringServiceStopList \(pushRecurringServiceStopList)")
                    
                    print("list Of Selected Locations >> \(listOfRecurringStops.count)")
                    let pushJob = jobType
                    var recurringRoute:RecurringRoute? = nil
                    if recurringRouteVM.recurringRoute != nil {
                        recurringRoute = recurringRouteVM.recurringRoute
                    } else {
                        recurringRoute = nil
                    }
                    guard let company = masterDataManager.selectedCompany else {
                        isLoading = false
                        alertMessage = "Failed to Upload"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    do {
                        if let recurringRoute = recurringRoute {
                            try await recurringRouteVM.modifyRecurringRouteWithVerification(companyId: company.id,
                                                                                            tech: pushTechEntity,
                                                                                            noEndDate: pushNoEndDate,
                                                                                            day: day,
                                                                                            standardFrequencyType: pushStandardFrequencyType,
                                                                                            customFrequencyType: pushCustomMeasurmentOfTime,
                                                                                            customFrequencyNumber: pushCustomEvery,
                                                                                            transitionDate: transitionDate,
                                                                                            newEndDate: endDate,
                                                                                            description: pushDescription,
                                                                                            jobTemplate: jobType,
                                                                                            recurringStopList: pushRecurringServiceStopList,
                                                                                            currentRecurringRoute: recurringRoute)
                        }
                        
                        
                        isLoading = false
                        alertMessage = "Success"
                        print(alertMessage)
                        showAlert = true
                        masterDataManager.routeBuilderTech = nil
                        masterDataManager.routeBuilderDay = nil
                        masterDataManager.reloadBuilderView = true
                    } catch {
                        isLoading = false
                        alertMessage = "Failed to Upload"
                        print(alertMessage)
                        showAlert = true
                        
                    }
                }
            }, label: {
                Text("Submit")
                    .padding(5)
                    .background(Color.blue)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
            })
            Button(action: {
                dismiss()
            }, label: {
                Text("Discard Changes")
                    .padding(5)
                    .background(Color.blue)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
            })
        }
    }
    var form: some View {
        ScrollView{
            Text("Modify Recurring Route")
            technical
            info
        }
    }
    func deleteCustomers(at offsets: IndexSet) {
        listOfRecurringStops.remove(atOffsets: offsets)
    }
    var info: some View {
        VStack{
            Text(jobType.name)
            //            Picker("Job Type", selection: $jobType) {
            ////                Text("Pick Job Type")
            //                ForEach(settingsVM.jobTemplates){ job in
            //                    Text("\(job.name)").tag(job)
            //                }
            //            }
            HStack{
                Button(action: {
                    Task{
                        if let company = masterDataManager.selectedCompany{
                            do {
                                try await customerVM.getAllCustomers(companyId: company.id)
                                listOfCustomers = customerVM.customers
                                if customerVM.customers.count != 0 {
                                    customer = customerVM.customers.first!
                                    print("Received \(customerVM.customers.count) Customers")
                                } else {
                                    print("No Customers")
                                }
                            } catch {
                                print("Error Getting Customers")
                            }
                        }
                    }
                }, label: {
                    Text("Refresh")
                })
                .foregroundColor(Color.basicFontText)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
                Button(action: {
                    customerSearch = ""
                }, label: {
                    Image(systemName: "xmark")
                })
                TextField(
                    "Customer Search",
                    text: $customerSearch
                )
                .padding(5)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(5)
                
                Spacer()
                
                Button(action: {
                    showCustomerSheet.toggle()
                }, label: {
                    if listOfRecurringStops.count == 0 {
                        Text("Pick Location")
                    } else {
                        Text("Recurring Stop List - \(listOfRecurringStops.count)")
                    }
                })
                .disabled(listOfRecurringStops.count == 0)
                .sheet(isPresented: $showCustomerSheet, content: {
                    VStack{
                        List{
                            ForEach(listOfRecurringStops){ location in
                                HStack{
                                    VStack{
                                        Text("\(location.customerName)")
                                        Text("\(location.address.streetAddress)")
                                            .font(.footnote)
                                    }
                                    Text(location.frequency ?? "")
                                    if !UIDevice.isIPhone {
                                        Button(action: {
                                            listOfRecurringStops.removeAll(where: {$0.id == location.id})
                                        }, label: {
                                            Image(systemName: "trash.fill")
                                        })
                                    }
                                }
                            }
                            .onDelete(perform: deleteCustomers)
                        }
                    }
                })
            }
            .padding(10)
            if listOfCustomers.count == 0 {
                Button(action: {
                    showAddNewCustomer.toggle()
                }, label: {
                    Text("Add New Customer")
                })
                .sheet(isPresented: $showAddNewCustomer, content: {
                    AddNewCustomerView(dataService: dataService)
                        .onDisappear(perform: {
                            //Get Customers
                            Task{
                                if let company = masterDataManager.selectedCompany{
                                    do {
                                        try await customerVM.getAllCustomers(companyId: company.id)
                                        listOfCustomers = customerVM.customers
                                        if customerVM.customers.count != 0 {
                                            customer = customerVM.customers.first!
                                            print("Received \(customerVM.customers.count) Customers")
                                        } else {
                                            print("No Customers")
                                        }
                                    } catch {
                                        print("Error Getting Customers")
                                    }
                                }
                            }
                        })
                })
                
            } else {
                HStack{
                    Picker("Customer", selection: $customer) {
                        //                    Text("Pick Customer")
                        Text("Customer").tag(Customer(id: "",
                                                      firstName: "Ron",
                                                      lastName: "Palace",
                                                      email: "",
                                                      billingAddress: Address(streetAddress: "",
                                                                              city: "",
                                                                              state: "",
                                                                              zip: "0",
                                                                              latitude: 0,
                                                                              longitude: 0),
                                                      active: false,
                                                      displayAsCompany: false,
                                                      hireDate: Date(),
                                                      billingNotes: ""))
                        ForEach(listOfCustomers){ customer in
                            if customer.displayAsCompany {
                                Text("\(customer.company ?? "")").tag(customer)

                            } else {
                                Text("\(customer.firstName) \(customer.lastName)").tag(customer)
                            }
                        }
                    }
                    
                    Picker("Location", selection: $location) {
                        //                    Text("Pick Location")
                        Text("Location").tag(ServiceLocation(id: "", nickName: "Location",
                                                                 address: Address(streetAddress: "",
                                                                                  city: "",
                                                                                  state: "",
                                                                                  zip: "0",
                                                                                  latitude: 0,
                                                                                  longitude: 0),
                                                                 gateCode: "",
                                                                 mainContact: Contact(id: "", name: "", phoneNumber: "", email: ""),
                                                                 bodiesOfWaterId: [],
                                                                 rateType: "", laborType: "",
                                                                 chemicalCost: "",
                                                                 laborCost: "",
                                                                 rate: "",
                                                                 customerId: "",
                                                                 customerName: "",
                                                             preText: false))
                        ForEach(locationVM.serviceLocations){ location in
                            Text("\(location.address.streetAddress)").tag(location)
                        }
                    }
                    .disabled(customer.id == "")
                    Button(action: {
                        //                    if !listOfSelectedLocations.contains(where: {$0 == location}) {
                        //                        listOfSelectedLocations.append(location)
                        //                        print(listOfSelectedLocations)
                        //                    }
                        if jobType.id == "" {
                            return
                        }
                        if location.id == "" {
                            return
                        }
                        
                        let techFullName = (tech.userName)
                        listOfRecurringStops.append(RecurringServiceStop(id: UUID().uuidString,
                                                                         type: jobType.name,
                                                                         typeId: jobType.id,
                                                                         typeImage: jobType.typeImage ?? "gear",
                                                                         customerName: location.customerName,
                                                                         customerId: location.customerId,
                                                                         locationId: location.id,
                                                                         frequency: standardFrequencyType,
                                                                         address: location.address,
                                                                         dateCreated: Date(),
                                                                         tech: techFullName,
                                                                         endDate: endDate,
                                                                         startDate: startDate,
                                                                         techId: tech.id,
                                                                         noEndDate: noEndDate,
                                                                         customMeasuresOfTime: customMeasurmentsOfTime,
                                                                         customEvery: String(customEvery),
                                                                         daysOfWeek: [selectedDay],
                                                                         description: description,
                                                                         lastCreated: Date(),
                                                                         serviceLocationId: location.id,
                                                                         estimatedTime: "15"))
                        customerSearch = ""
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
                .padding(5)
            }
        }
    }
    var technical: some View {
        VStack{
            HStack{
                Picker("Tech", selection: $techEntity) {
                    Text("Tech").tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active))
                    ForEach(companyUserVM.companyUsers){ tech in
                        Text("\(tech.userName)").tag(tech)
                    }
                }
                Picker("Day", selection: $selectedDay) {
                    Text("Day").tag("")
                    ForEach(days,id:\.self){ day in
                        Text("\(day)").tag(day)
                    }
                }
            }
            Picker("Frequency", selection: $standardFrequencyType) {
                ForEach(measurementsOfTime,id:\.self){
                    Text($0).tag($0)
                }
            }
            DatePicker(selection: $startDate, displayedComponents: .date) {
                Text("Start Date")
            }
            Toggle("Never Ends", isOn: $noEndDate)
            if !noEndDate {
                DatePicker(selection: $endDate, displayedComponents: .date) {
                    Text("End Date")
                }
            }
            //            Picker("Repeat", selection: $standardFrequencyNumber) {
            //                Text("Every Week").tag(1)
            //                Text("Every Day").tag(0)
            //                Text("Every Month").tag(2)
            //                Text("Every Year").tag(3)
            //                Text("Every Week Day").tag(4)
            //                Text("Custom").tag(5)
            //
            //            }
            //            .sheet(isPresented: $showCustomSheet, content: {
            //                CustomRecurringStopSettingsView(customEvery: $customEvery, customFrequency: $customFrequency,selectedDays: $selectedDays)
            //            })
            //            if standardFrequencyNumber == 5{
            //                HStack{
            //                    Text("Every \(String(customEvery)) \(customFrequency)")
            //                    Button(action: {
            //                        showCustomSheet.toggle()
            //                    }, label: {
            //                        Image(systemName: "square.and.pencil")
            //                    })
            //                }
            //            }
            //            HStack{
            //                ForEach(selectedDays,id:\.self){
            //                    Text($0)
            //                }
            //            }
            TextField(
                "Description",
                text: $description
            )
            .padding(3)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(3)
            TextField(
                "Estimated Time",
                text: $estimatedTime
            )
            .padding(3)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(3)
        }
        .padding()
    }
    /*
     var daySelector: some View {
     VStack{
     ScrollView(.horizontal,showsIndicators: false){
     HStack{
     ForEach(days,id:\.self){ day in
     Button(action: {
     if selectedDays.contains(day) {
     selectedDays.removeAll(where: {$0 == day})
     print(selectedDays)
     } else {
     selectedDays.append(day)
     print(selectedDays)
     }
     }, label: {
     if selectedDays.contains(day) {
     Text("\(day)")
     .padding(5)
     .background(Color.green)
     .cornerRadius(5)
     .foregroundColor(Color.white)
     } else {
     Text("\(day)")
     .padding(5)
     .background(Color.blue)
     .cornerRadius(5)
     .foregroundColor(Color.white)
     }
     })
     }
     }
     }
     }
     }
     */
}
