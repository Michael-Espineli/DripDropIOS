//
//  NewReucrringStopView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct NewReucrringStopView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject private var customerVM : CustomerViewModel
    @StateObject var locationVM : ServiceLocationViewModel
    @StateObject var recurringStopVM : RecurringStopViewModel
    @StateObject var settingsVM : SettingsViewModel


    init(dataService:any ProductionDataServiceProtocol,tech:DBUser,day:String){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _locationVM = StateObject(wrappedValue: ServiceLocationViewModel(dataService: dataService))
        _recurringStopVM = StateObject(wrappedValue: RecurringStopViewModel(dataService: dataService))
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(dataService: dataService))

        self.tech = tech
        self.day = day
    }
    @StateObject var techVM = TechViewModel()

    @State var tech:DBUser? = nil
    @State var day:String? = nil
    
    @State var jobType:JobTemplate = JobTemplate(id: "",
                                                 name: "Job Template",
                                                 type: "",
                                                 typeImage: "",
                                                 dateCreated: Date(),
                                                 rate: "",
                                                 color: "")
    @State var customer:Customer = Customer(
        id: "",
        firstName: "Ron",
        lastName: "Palace",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "0",
            latitude: 0,
            longitude: 0
        ),
        active: false,
        displayAsCompany: false,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
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
    
    @State var techEntity:DBUser = DBUser(id: "", email: "",firstName: "Michael",lastName: "Espineli", exp: 0,recentlySelectedCompany: "")
    @State var startDate:Date = Date()
    @State var endDate:Date = Date()
    
    @State var noEndDate:Bool = true
    @State var standardFrequencyType:String = "Weekly"
    @State var standardFrequencyNumber:Int = 0
    @State var frequency:LaborContractFrequency = .daily

    @State var customFrequency:String = "Daily"
    @State var customEvery:Int = 1

    @State var showCustomSheet:Bool = false
    
    @State var days:[String] = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    @State var selectedDays:[String] = []
    @State var description:String = "description"
    @State var estimatedTime:String = "15"
    
    //errors
    @State var showAlert:Bool = false
    @State var alertMessage:String = "Error"
    
    var body: some View {
        VStack{
            ScrollView{
                form
                button
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $showCustomSheet, content: {
            CustomRecurringStopSettingsView(customEvery: $customEvery, customFrequency: $customFrequency,selectedDays: $selectedDays)
        })
        .task {
            if let company = masterDataManager.currentCompany {
                try? await customerVM.getAllCustomers(companyId: company.id)
                listOfCustomers = customerVM.customers
                if customerVM.customers.count != 0 {
                    customer = customerVM.customers.first!
                }
                try? await techVM.getAllCompanyTechs(companyId: company.id)
                if techVM.techList.count != 0 {
                    techEntity = techVM.techList.first!
                }
                try? await settingsVM.getWorkOrderTemplates(companyId: company.id)
                if settingsVM.jobTemplates.count != 0 {
                    jobType = settingsVM.jobTemplates.first!
                }
            }
        }
        .onChange(of: standardFrequencyNumber, perform: { freq in
            print(freq)
            if freq == 5 {
                showCustomSheet = true
            }
        })
        .onChange(of: customer, perform: { changedCustomer in
            Task{
                if let company = masterDataManager.currentCompany{
                    try? await locationVM.getAllCustomerServiceLocationsById(companyId:company.id, customerId: changedCustomer.id)
                    if locationVM.serviceLocations.count != 0 {
                        location = locationVM.serviceLocations.first!
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
            }
        })
    }
}


extension NewReucrringStopView {
    var button: some View {
        VStack{
            Button(action: {
                Task{
                    print("DEVELOPER ADD SOME VALIDATION TO ADD NEW RECURRING SERVICE STOP")
                    if jobType.id == "" {
                        alertMessage = "No Job Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let jobId = jobType.name
                    if jobType.name == "" {
                        alertMessage = "No Job title Available, selected different job or update job title"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let jobName = jobType.name
                    let jobImage = jobType.typeImage
                    
                    if customer.id == "" || customer.firstName == "" ||  customer.lastName == ""{
                        alertMessage = "No Customer Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let customerName = customer.firstName + " " + customer.lastName
                    let customerId = customer.id
                    if location.id == "" || location.nickName == "" ||  location.address.streetAddress == ""{
                        alertMessage = "No Location Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let locationId = location.id
                    let address = location.address
                    guard let tech = tech else {
                        alertMessage = "No Tech Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                   
                    let techFullName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
                    let techId = tech.id
                    var pushSelectedDays = selectedDays

                    if selectedDays.isEmpty {
                        pushSelectedDays = ["Friday"]
                    }
                    guard let company = masterDataManager.currentCompany else {
                        return 
                    }
                    let pushEndDate = noEndDate
                    let pushStandardFrequencyNumber = standardFrequencyNumber
                    let pushCustomFrequency = customFrequency
                    let pushCustomEvery = customEvery
                    let pushDescription = description
                    let pushEstimatedTime = estimatedTime
                    //DEVELOPER
//                    try? await recurringStopVM
//                        .addNewRecurringServiceStop(
//                            companyId: company.id,
//                            recurringServiceStop: RecurringServiceStop(
//                                id: UUID().uuidString,
//                                type: jobName,
//                                typeId: jobId ,
//                                typeImage: jobImage ?? "",
//                                customerName: customerName,
//                                customerId: customerId,
//                                address: address,
//                                tech: techFullName,
//                                techId: techId,
//                                dateCreated: Date(),
//                                startDate: Date(),
//                                endDate: nil,
//                                noEndDate: pushEndDate,
//                                frequency: frequency,
//                                timesPerFrequency: customEvery,
//                                daysOfWeek: pushSelectedDays,
//                                description: pushDescription,
//                                lastCreated: Date(),
//                                serviceLocationId:locationId,
//                                estimatedTime: pushEstimatedTime,
//                                otherCompany: false,
//                                receivedLaborContractId: "",
//                                contractedCompanyId: ""
//                            ),
//                            standardFrequencyNumber: pushStandardFrequencyNumber,
//                            customFrequencyType: pushCustomFrequency,
//                            CustomFrequency: customFrequency,
//                            daysOfWeek: pushSelectedDays
//                        )
                    
                }
            },
                   label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
        }
    }
    var form: some View {
        VStack{
            info
            technical
        }
    }
    var info: some View {
        VStack{
            Picker("Job Type", selection: $jobType) {
                Text("Pick Job Type")
                ForEach(settingsVM.jobTemplates){ job in
                    Text("\(job.name)").tag(job)
                }
            }
            TextField(
                "Customer Search",
                text: $customerSearch
            )
            .padding(5)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(5)
            
            Picker("?", selection: $customer) {
                Text("Pick Customer")
                ForEach(listOfCustomers){ customer in
                    Text("\(customer.firstName) \(customer.lastName)").tag(customer)
                }
            }
            
            Picker("?", selection: $location) {
                Text("Pick Location")
                ForEach(locationVM.serviceLocations){ location in
                    Text("\(location.address.streetAddress)").tag(location)
                }
            }
            .disabled(customer.id == "")
            Picker("?", selection: $techEntity) {
                Text("Pick Tech")
                ForEach(techVM.techList){ tech in
                    Text("\(tech.firstName ?? "") \(tech.lastName ?? "")").tag(tech)
                }
            }
        }
    }
    var technical: some View {
        VStack{
            DatePicker(selection: $startDate, displayedComponents: .date) {
                Text("Start Date")
            }
            Toggle("Never Ends", isOn: $noEndDate)
            if !noEndDate {
                DatePicker(selection: $endDate, displayedComponents: .date) {
                    Text("End Date")
                }
            }
            Picker("Repeat", selection: $frequency) {
                Text("Every Day").tag(LaborContractFrequency.daily)
                Text("Every Week").tag(LaborContractFrequency.weekly)
                Text("Every Month").tag(LaborContractFrequency.monthly)
                Text("Every Year").tag(LaborContractFrequency.yearly)
                Text("Every Week Day").tag(LaborContractFrequency.weekDay)
            }
            HStack{
                Text("customEvery \(customEvery)")
                VStack{
                    Button(action: {
                        customEvery += 1
                    }, label: {
                        Text("+ 1")
                    })
                    Button(action: {
                        customEvery += -1
                    }, label: {
                        Text("- 1")
                    })
                }
            }
            HStack{
                ForEach(selectedDays,id:\.self){
                    Text($0)
                }
            }
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
}
