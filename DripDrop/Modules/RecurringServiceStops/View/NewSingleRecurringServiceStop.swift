//
//  NewSingleRecurringServiceStop.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/7/24.
//

import SwiftUI
@MainActor
final class NewSingleRecurringServiceStopViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var showAlert: Bool = false
    @Published private(set) var alertMessage: String = ""

    @Published private(set) var RSSList: [RecurringServiceStop] = []
    @Published private(set) var locations: [ServiceLocation] = []
    @Published var companyUsers: [CompanyUser] = []

    @Published var showSnapshot: Bool = false
    @Published var startOn: Date = Date()
    @Published var frequency: LaborContractFrequency = .weekly
    @Published var selectedDay: DaysOfWeek = .monday
    @Published var selectedUser: CompanyUser = CompanyUser(
        id: "2",
        userId: "2",
        userName: "2",
        roleId: "2",
        roleName: "2",
        dateCreated: Date(),
        status: .active,
        workerType: .employee
    )
    @Published var selectedLocation : ServiceLocation = ServiceLocation(
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
        mainContact: Contact(id: "", name: "", phoneNumber: "", email: "", notes: ""),
        bodiesOfWaterId: [],
        rateType: "",
        laborType: "",
        chemicalCost: "",
        laborCost: "",
        rate: "",
        customerId: "",
        customerName: "",
        isActive: true
    )



    func onLoad(companyId:String,customerId:String) {
        Task{
            do {
                self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
                if !companyUsers.isEmpty  {
                    self.selectedUser = companyUsers.first!
                }
                self.locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customerId)
                if !locations.isEmpty  {
                    self.selectedLocation = locations.first!
                }
            } catch {
                print(error)
            }
        }
    }
    func onChange(companyId:String) {
        Task{
            if selectedUser.id != "" {
                do {
                    self.RSSList = try await dataService.getRecurringServiceStopsByDayAndTech(companyId: companyId, techId: selectedUser.userId, day: selectedDay)
                } catch {
                    print(error)
                }
            }
        }
    }
    func submit(companyId:String,customerId:String) {
        Task{
            if selectedUser.id != "" {
                print("")
                print("[NewSingleRecurringServiceStopViewModel][submit] selectedUserId: \(selectedUser.id)")
                if selectedLocation.id != "" {
                    print("")
                    print("[NewSingleRecurringServiceStopViewModel][submit] selectedLocationId: \(selectedLocation.id)")
                    do {
                        var name = ""
                        let customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
                        if customer.displayAsCompany {
                            name = customer.company ?? "Company Name"
                        }else {
                            name = customer.firstName + " " + customer.lastName
                        }
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] 1")
                        let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)
                        
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] New Count \(rssCount)")
                        let rss = RecurringServiceStop(
                            id: "comp_rss_" + UUID().uuidString,
                            internalId: "RSS" + String(rssCount),
                            type: "",
                            typeId: "",
                            typeImage: "",
                            customerName: name,
                            customerId: customer.id,
                            address: selectedLocation.address,
                            tech: selectedUser.userName,
                            techId: selectedUser.userId,
                            dateCreated: Date(),
                            startDate: startOn,
                            endDate: nil,
                            noEndDate: true,
                            frequency: frequency,
                            day: selectedDay,
                            description: "",
                            lastCreated: Date(),
                            serviceLocationId: selectedLocation.id,
                            estimatedTime: selectedLocation.estimatedTime ?? 15,
                            otherCompany: false
                        )
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] rss \(rss)")
                        let id = try await dataService.addNewRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
                        
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] successfully loaded RSS: \(String(describing: id))")
                        
//                        try await dataService.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
                        //Developer Add RSS Tasks
                        
                        self.selectedUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
                        self.selectedDay = .monday
                        self.startOn = Date()
                        self.alertMessage = "Successfully Uplaoded"
                        print(alertMessage)
                        self.showAlert.toggle()
                    } catch {
                        print("")
                        print("[NewSingleRecurringServiceStopViewModel][submit] Error \(error)")
                        
                        self.alertMessage = "Failed To Uplaoded"
                        print(alertMessage)
                        self.showAlert.toggle()
                    }
                } else {
                    
                    print("")
                    print("[NewSingleRecurringServiceStopViewModel][submit] no selected Location Id")
                }
            } else {
                print("")
                print("[NewSingleRecurringServiceStopViewModel][submit] no selected user Id")
                
            }
        }
    }
}
struct NewSingleRecurringServiceStop: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var VM : NewSingleRecurringServiceStopViewModel
    @State var customerId:String
    @Environment(\.dismiss) var dismiss
    
    init(dataService: any ProductionDataServiceProtocol,customerId:String) {
        _customerId = State(wrappedValue: customerId)
        _VM = StateObject(wrappedValue: NewSingleRecurringServiceStopViewModel(dataService: dataService))
    }
    var body: some View {
        
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                form
                Divider()
                snapshot
            }
            .padding(8)
            .padding(.horizontal,16)

        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                VM.onLoad(companyId: currentCompany.id,customerId: customerId)
            }
        }
        .onChange(of: VM.selectedDay, perform: { datum in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChange(companyId: currentCompany.id)
            }
        })
        .onChange(of: VM.selectedUser, perform: { datum in
            if let currentCompany = masterDataManager.currentCompany {
                VM.onChange(companyId: currentCompany.id)
            }
        })
        
        .alert(VM.alertMessage, isPresented: $VM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    NewSingleRecurringServiceStop(dataService: MockDataService(),customerId: "")
}
extension NewSingleRecurringServiceStop {
    var form : some View {
        VStack{
            
            Text("Add New Recurring Service Stop")
                .font(.headline)
            Divider()
            VStack{
                HStack{
                    Text("Service Location:")
                    Spacer()
                }
                Picker("Select Location", selection: $VM.selectedLocation) {
                    Text("Select Location").tag(
                        ServiceLocation(
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
                            mainContact: Contact(id: "", name: "", phoneNumber: "", email: "", notes: ""),
                            bodiesOfWaterId: [],
                            rateType: "",
                            laborType: "",
                            chemicalCost: "",
                            laborCost: "",
                            rate: "",
                            customerId: "",
                            customerName: "",
                            isActive: true
                        )
                    )
                    ForEach(VM.locations){ datum in
                        Text(datum.address.streetAddress).tag(datum)
                    }
                }
            
                HStack{
                    Text("User:")
                    Spacer()
                }
                Picker("Picker User", selection: $VM.selectedUser) {
                    Text("Select User").tag(
                        CompanyUser(
                            id: "1",
                            userId: "1",
                            userName: "1",
                            roleId: "1",
                            roleName: "1",
                            dateCreated: Date(),
                            status: .active,
                            workerType: .contractor
                        )
                    )
                    ForEach(VM.companyUsers){ datum in
                        Text(datum.userName).tag(datum)
                    }
                    
                }
                HStack{
                    Text("Day:")
                    Spacer()
                }
                Picker("Pick Day", selection: $VM.selectedDay) {
                    ForEach(DaysOfWeek.allCases, id: \.self){ day in
                        Text(day.rawValue).tag(day)
                    }
                }
                HStack{
                    Text("Frequency:")
                    Spacer()
                }
                
                Picker("Pick Frequency", selection: $VM.frequency) {
                    ForEach(LaborContractFrequency.allCases, id: \.self){ day in
                        Text(day.rawValue).tag(day)
                    }
                }
                DatePicker("Start On:", selection: $VM.startOn, in: Date()...,displayedComponents: .date)
                Button(action: {
                    if let currentCompany = masterDataManager.currentCompany {
                        VM.submit(companyId: currentCompany.id, customerId: customerId)
                        dismiss()
                    }
                }, label: {
                    HStack{
                        Spacer()
                        Text("Add")
                        Spacer()
                    }
                    .modifier(AddButtonModifier())
                })
            }
        }
    }
    var snapshot : some View {
        ScrollView{
            HStack{
                Text("Route Snapshot")
                Spacer()
                Button(action: {
                    VM.showSnapshot.toggle()
                }, label: {
                    Text(VM.showSnapshot ? "Collapse" : "Expand")
                        .modifier(ListButtonModifier())
                })
            }
            if VM.showSnapshot {
                ForEach(VM.RSSList){ rss in
                    Text("\(rss.customerName)")
                        .modifier(ListButtonModifier())
                }
            }
        }
    }
}
