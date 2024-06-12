//
//  NewRouteView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/8/23.
//

import SwiftUI

struct NewRouteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService: ProductionDataService

    @StateObject var VM : RouteBuilderViewModel
    
    init(dataService:any ProductionDataServiceProtocol,tech:CompanyUser,day:String){
        _VM = StateObject(wrappedValue: RouteBuilderViewModel(dataService: dataService))
        _tech = State(wrappedValue: tech)
        _day = State(wrappedValue: day)

    }

    @State var tech:CompanyUser
    @State var day:String
    
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
    
    @State var noEndDate:Bool = true
    @State var standardFrequencyType:String = "Weekly"
    
    @State var customMeasurmentsOfTime:String = "Daily"
    @State var customEvery:Int = 1
    @State var showCustomSheet:Bool = false
    @State var showCustomerSheet:Bool = false
    @State var showAddNewCustomer:Bool = false
    @State var showCustomerPicker:Bool = false

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
            Color.listColor.ignoresSafeArea()
                ScrollView{
                    form
                    button
                }
                .padding(8)
            if isLoading {
                ProgressView()
            }
        }
        .foregroundColor(Color.basicFontText)
        .fontDesign(.monospaced)
        
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .task {
            print("arrived")
            isLoading = true
            if let company = masterDataManager.selectedCompany {
                print("Company - \(company.name ?? "")")
                    print("Day - \(day)")
                    selectedDay = day
                do {
                    try await VM.initialLoad(companyId: company.id, tech: nil, day: day)
                    techList = VM.companyUsers
                    if !techList.isEmpty {
                        techEntity = techList.first!
                    } else {
                        dismiss()
                    }
                    listOfRecurringStops = VM.listOfRSS
                    if let jobType1 = VM.jobType {
                        jobType = jobType1
                    }
                } catch {
                    print("")
                    print("New Route View Error >>")
                    print(error)
                    print("")
                }
            }
            isLoading = false

        }
        .onChange(of: standardFrequencyType, perform: { freq in
            print(freq)
            if freq == "Custom" {
                showCustomSheet = true
            }
        })
        .onChange(of: VM.companyUser, perform: { tech in
            if let tech {
                techEntity = tech
            }
        })
        .onChange(of: selectedDay, perform: { datum in
            //DEVLOPER IMPORT OTHER RECURRING ROUTE SETTINGS
            if !isLoading {
                Task{
                    isLoading = true
                    if let company = masterDataManager.selectedCompany {
                        print("Change of Day >>\(datum)")
                        do {
                            
                            try await VM.reLoad(companyId: company.id, tech: techEntity, day: datum)
                            
                            listOfRecurringStops = VM.listOfRSS

                        } catch {
                            print(error)
                        }
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
                        print("Change of Tech >>\(tech.userName)")
                        do {
                            
                            try await VM.reLoad(companyId: company.id, tech: tech, day: day)
                            
                            listOfRecurringStops = VM.listOfRSS

                        } catch {
                            print(error)
                        }
                    } else {
                        print("Error")
                    }
                    isLoading = false
                }
            }
        })
    }
}


extension NewRouteView {
    var button: some View {
        VStack{
            Button(action: {
                Task{
                    isLoading = true

                    if techEntity.id == "" || techEntity.userName == "" {
                        alertMessage = "No Tech Selected"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    let techFullName = (techEntity.userName)
                    print("techFullName \(techFullName)")
                    let techId = techEntity.userId
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
                 
                    guard let company = masterDataManager.selectedCompany else {
                        isLoading = false
                        alertMessage = "Failed to Upload"
                        print(alertMessage)
                        showAlert = true
                        return
                    }
                    if let recurringRoute1 = VM.recurringRoute{
                        recurringRoute = recurringRoute1
                        do {
                            try await VM.modifyRecurringRouteWithVerification(
                                companyId: company.id,
                                tech: pushTechEntity,
                                noEndDate: pushNoEndDate,
                                day: day,
                                standardFrequencyType: pushStandardFrequencyType,
                                customFrequencyType: pushCustomMeasurmentOfTime,
                                customFrequencyNumber: pushCustomEvery,
                                transitionDate: pushStartDate,
                                newEndDate: pushEndDate,
                                description: pushDescription,
                                jobTemplate: jobType,
                                recurringStopList: pushRecurringServiceStopList,
                                currentRecurringRoute: recurringRoute1
                            )
                            
                            isLoading = false
                            alertMessage = "Success"
                            print(alertMessage)
                            showAlert = true
                            
                            masterDataManager.routeBuilderTech = nil
                            masterDataManager.routeBuilderDay = nil
                            masterDataManager.reloadBuilderView = true
                            dismiss()
                        } catch {
                            isLoading = false
                            alertMessage = "Failed to Upload"
                            print(alertMessage)
                            showAlert = true
                        }
                    } else {
                        do {
                            try await VM.createAndUploadRecurringRouteWithVerification(
                                companyId: company.id,
                                tech: pushTechEntity,
                                recurringStopsList: pushRecurringServiceStopList,
                                job:pushJob,
                                noEndDate:pushNoEndDate,
                                description : pushDescription,
                                day: day,
                                standardFrequencyType: pushStandardFrequencyType,
                                customFrequencyType: pushCustomMeasurmentOfTime,
                                customFrequencyNumber: pushCustomEvery,
                                startDate:pushStartDate,
                                endDate: pushEndDate,
                                currentRecurringRoute: recurringRoute
                            )
                            isLoading = false
                            alertMessage = "Success"
                            print(alertMessage)
                            showAlert = true
                            
                            masterDataManager.routeBuilderTech = nil
                            masterDataManager.routeBuilderDay = nil
                            masterDataManager.reloadBuilderView = true
                            dismiss()
                        } catch {
                            isLoading = false
                            alertMessage = "Failed to Upload"
                            print(alertMessage)
                            showAlert = true
                        }
                    }
                    
                }
            },
                   label: {
                HStack{
                    Text(VM.recurringRoute == nil ? "Submit" : "Update")
                }
                .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.poolBlue)
                    .cornerRadius(8)
                    .foregroundColor(Color.white)
            })
        }
    }
    var form: some View {
        VStack{
//            Text("Change Recurring Service stop Id to be not based on day and tech ID")
            technical
            info
        }
        .padding(.horizontal,16)

    }
    func deleteCustomers(at offsets: IndexSet) {
        listOfRecurringStops.remove(atOffsets: offsets)
    }
    var info: some View {
        VStack{
//            Text(jobType.name)
            //            Picker("Job Type", selection: $jobType) {
            ////                Text("Pick Job Type")
            //                ForEach(settingsVM.jobTemplates){ job in
            //                    Text("\(job.name)").tag(job)
            //                }
            //            }
            HStack{
                Button(action: {
                    self.showCustomerPicker.toggle()
                }, label: {
                    Text(listOfRecurringStops.isEmpty ? "Add First Customer":"Add Another")
                        .padding(8)
                        .background(Color.poolBlue)
                        .foregroundColor(Color.basicFontText)
                        .cornerRadius(8)
                })
                .sheet(isPresented: $showCustomerPicker, onDismiss: {
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
                    if customer.id == "" {
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
                                                                     techId: tech.userId,
                                                                     noEndDate: noEndDate,
                                                                     customMeasuresOfTime: customMeasurmentsOfTime,
                                                                     customEvery: String(customEvery),
                                                                     daysOfWeek: [selectedDay],
                                                                     description: description,
                                                                     lastCreated: Date(),
                                                                     serviceLocationId: location.id,
                                                                     estimatedTime: "15"))
                    customer.id = ""
                    location.id = ""
                }, content: {
                    CustomerAndLocationPicker(dataService: dataService, customer: $customer,location: $location)
                })
                Spacer()
                if !listOfRecurringStops.isEmpty {
                    Button(action: {
                        showCustomerSheet.toggle()
                    }, label: {
                            Text("Customers - \(listOfRecurringStops.count)")
                            .padding(8)
                            .background(Color.poolBlue)
                            .foregroundColor(Color.basicFontText)
                            .cornerRadius(8)
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
                                    }
                                }
                                .onDelete(perform: deleteCustomers)
                            }
                        }
                    })
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
            HStack{
                Picker("Tech", selection: $techEntity) {
                    Text("Tech").tag(CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active))
                    ForEach(VM.companyUsers){ tech in
                        Text("\(tech.userName)").tag(tech)
                    }
                }
                Spacer()
            }
            HStack{
                Picker("Day", selection: $selectedDay) {
                    Text("Day").tag("")
                    ForEach(days,id:\.self){ day in
                        Text("\(day)").tag(day)
                    }
                }
                Spacer()
            }
            HStack{
            Picker("Frequency", selection: $standardFrequencyType) {
                ForEach(measurementsOfTime,id:\.self){
                    Text($0).tag($0)
                }
            }
            Spacer()
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
    
        }
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
