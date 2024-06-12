//
//  ReassignRouteView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/24/24.
//

import SwiftUI

struct ReassignRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

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
    @State var transitionDate:Date = Date()
    @State var endDate:Date = Date()
    
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
    @State var showChangeConfirmation : Bool = false
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
                        .padding()
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
        .alert(isPresented:$showChangeConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Confirm")) {
                    Task{
                        print("Changing Route...")
                        if let company = masterDataManager.selectedCompany{
                            do {
                                isLoading = true
                                try await recurringRouteVM.reassigndRecurringRouteWithVerification(companyId: company.id,
                                                                                                   tech: techEntity,
                                                                                                   noEndDate: noEndDate,
                                                                                                   day: selectedDay,
                                                                                                   standardFrequencyType: standardFrequencyType,
                                                                                                   customFrequencyType: standardFrequencyType,
                                                                                                   customFrequencyNumber: customEvery,
                                                                                                   transitionDate: transitionDate,
                                                                                                   newEndDate: endDate,
                                                                                                   description: description,
                                                                                                   jobTemplate: jobType,
                                                                                                   recurringStopList: listOfRecurringStops,
                                                                                                   currentRecurringRoute: recurringRoute)
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
                        } else {
                            print("Attempting to Change Route, but no Company selected")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear(perform: {
            Task{
                techEntity = tech

                if let company = masterDataManager.selectedCompany {
                    let RecurringRouteId = selectedDay + techEntity.id
                    
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
                            }
                        }
                        self.listOfRecurringStops = listOfRSS
                    }
                }
            }
        })
        .task {
            print("arrived")
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
                      
                            print("Received \(companyUserVM.companyUsers.count) Techs")
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
    }
}


extension ReassignRouteView {
    var button: some View {
        HStack{
            
            Button(action: {
                //Check if day is same
                if !isLoading {
                    if day != selectedDay && tech != techEntity {
                        alertMessage = "Please confirm, \(tech.userName) -> \(techEntity.userName) and \(day) -> \(selectedDay)"
                        showChangeConfirmation = true
                    } else if day != selectedDay {
                        alertMessage = "Please confirm, \(tech.userName) and \(day) -> \(selectedDay)"
                        showChangeConfirmation = true
                    } else if tech != techEntity {
                        alertMessage = "Please confirm, \(tech.userName) -> \(techEntity.userName)"
                        showChangeConfirmation = true
                    } else {
                        alertMessage = "No Change in Day or Tech"
                        print(alertMessage)
                        showAlert = true
                    }
                } else {
                    print("Already Loading")
                }

            }, label: {
                Text("Save Changes")
                    .padding(5)
                    .background(Color.blue)
                    .cornerRadius(5)
                    .foregroundColor(Color.white)
            })
            if selectedDay != day || tech != techEntity {
                Button(action: {
                    selectedDay = day
                    techEntity = tech
                }, label: {
                    Text("Discard Changes")
                        .foregroundColor(Color.white)
                        .padding(5)
                        .background(Color.red)
                        .cornerRadius(5)
                        .padding(5)
                })
            }
       
        }
    }
    var form: some View {
        ScrollView{
            Text("Reassign Route View")
                .font(.title)
            technical
            changes
        }
    }
    func deleteCustomers(at offsets: IndexSet) {
        listOfRecurringStops.remove(atOffsets: offsets)
    }
    var changes: some View {
        HStack{
            VStack{
                if selectedDay != day {
                    Text("\(day) -> \(selectedDay)")
                }
                if tech != techEntity {
                    Text("\(tech.userName) -> \(techEntity.userName)")
                    
                }
            }

        }
    }
    var technical: some View {
        VStack{
                Picker("Tech", selection: $techEntity) {
                    Text("Tech").tag(DBUser(id: "",exp: 0))
                    ForEach(techVM.techList){ tech in
                        Text("\(tech.firstName ?? "?") \(tech.lastName ?? "?")").tag(tech)
                    }
                }
                Picker("Day", selection: $selectedDay) {
                    Text("Day").tag("")
                    ForEach(days,id:\.self){ day in
                        Text("\(day)").tag(day)
                    }
                }
            
            DatePicker(selection: $transitionDate, displayedComponents: .date) {
                Text("Transition Date")
            }
            Toggle("Never Ends", isOn: $noEndDate)
            if !noEndDate {
                DatePicker(selection: $endDate, displayedComponents: .date) {
                    Text("New End Date")
                }
            }
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
