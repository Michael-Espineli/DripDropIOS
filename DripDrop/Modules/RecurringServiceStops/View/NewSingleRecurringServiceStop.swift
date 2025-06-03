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
    @Published private(set) var RSSList: [RecurringServiceStop] = []
    @Published private(set) var locations: [ServiceLocation] = []
    @Published var companyUsers: [CompanyUser] = []
    @Published var days: [String] = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    ]
    
    @Published var showSnapshot: Bool = false
    @Published var startOn: Date = Date()
    @Published var frequency: LaborContractFrequency = .weekly
    @Published var selectedDay: String = "Monday"
    @Published var selectedUser: CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
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
        customerName: ""
    )



    func onLoad(companyId:String,customerId:String) {
        Task{
            do {
                self.companyUsers = try await dataService.getAllCompanyUsersByStatus(companyId: companyId, status: "Active")
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
                if selectedLocation.id != "" {
                    do {
                        var name = ""
                        let customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
                        if customer.displayAsCompany {
                            name = customer.firstName + " " + customer.lastName
                        }else {
                            name = customer.company ?? customer.firstName + " " + customer.lastName
                        }
                        let rssCount = try await dataService.getRecurringServiceStopCount(companyId: companyId)
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
                            daysOfWeek: selectedDay,
                            description: "",
                            lastCreated: Date(),
                            serviceLocationId: selectedLocation.id,
                            estimatedTime: "15",
                            otherCompany: false
                        )
                        let id = try await dataService.addNewRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
//                        try await dataService.uploadRecurringServiceStop(companyId: companyId, recurringServiceStop: rss)
                        //Developer Add RSS Tasks
                        self.selectedUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
                        self.selectedDay = ""
                        self.startOn = Date()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
struct NewSingleRecurringServiceStop: View {
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var VM : NewSingleRecurringServiceStopViewModel
    
    @State var customerId:String

    init(dataService: any ProductionDataServiceProtocol,customerId:String) {
        _customerId = State(wrappedValue: customerId)
        _VM = StateObject(wrappedValue: NewSingleRecurringServiceStopViewModel(dataService: dataService))
    }
    var body: some View {
        
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                form
                snapshot
            }
            .padding(8)
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
    }
}

#Preview {
    NewSingleRecurringServiceStop(dataService: MockDataService(),customerId: "")
}
extension NewSingleRecurringServiceStop {
    var form : some View {
        VStack(alignment: .leading){
            HStack{
                Text("Service Location : ")
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
                            customerName: ""
                        )
                    )
                    ForEach(VM.locations){ datum in
                        Text(datum.address.streetAddress).tag(datum)
                    }
                }
            }
            HStack{
                Text("User : ")
                
                Picker("Picker User", selection: $VM.selectedUser) {
                    Text("Select User").tag(
                        CompanyUser(
                            id: "",
                            userId: "",
                            userName: "",
                            roleId: "",
                            roleName: "",
                            dateCreated: Date(),
                            status: .active,
                            workerType: .contractor
                        )
                    )
                    ForEach(VM.companyUsers){ datum in
                        Text(datum.userName).tag(datum)
                    }
                }
            }
            HStack{
                Text("Day : ")
            Picker("Pick Day", selection: $VM.selectedDay) {
                Text("Select Day").tag("")
                ForEach(VM.days, id: \.self){ day in
                    Text(day).tag(day)
                }
            }
            }
            HStack{
                Text("Frequency : ")
                Picker("Pick Frequency", selection: $VM.frequency) {
                    ForEach(LaborContractFrequency.allCases, id: \.self){ day in
                        Text(day.rawValue).tag(day)
                    }
                }
            }
            DatePicker("Start On : ", selection: $VM.startOn, in: Date()...,displayedComponents: .date)
            Button(action: {
                if let currentCompany = masterDataManager.currentCompany {
                    VM.submit(companyId: currentCompany.id, customerId: customerId)
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
    var snapshot : some View {
        VStack{
            HStack{
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
