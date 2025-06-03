//
//  ManagementTablesView.swift
//  DripDrop
//
//  Created by Michael Espineli on 12/5/24.
//

import SwiftUI
struct CustomerManagement:Identifiable,Codable,Hashable{
    var id : String = UUID().uuidString
    var customerId : String
    var customerName : String
    var customerEmail : String
    var customerPhone : String

    var active : Bool
    var serviceLocationId : String
    var serviceLocationName : String
    var serviceLocationAddress : String
    var underContract : Bool
    var contractId : String
    var contractMonthlyAmountCents : Int
    var routingSetUp : Bool
    var rssIds : [String]
    var days : String
    var techIds : [String]
    var techNames : String
    var owesMoney : Bool
    var outStandingBalance : Int
    
}
enum CustomerManagementType : String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case yes = "Yes"
    case no = "No"
    case both = "Both"
}
@MainActor
final class ManagementTablesViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var searchTerm: String = ""
    @Published var showUnderContract: CustomerManagementType = .both
    @Published var showHasRouting: CustomerManagementType = .both
    @Published var showOwesMoney: CustomerManagementType = .both
    @Published var showsActive: CustomerManagementType = .yes
    
    @Published private(set) var customerCount: Int = 0
    @Published private(set) var serviceLocationCount: Int = 0
    @Published private(set) var routedCount: Int = 0

    @Published var showDetailSheet: Bool = false
    @Published var showDetails: Bool = false
    @Published var showRouteBuilder: Bool = false
    
    @Published var selection: CustomerManagement.ID? = nil
    @Published var selected: CustomerManagement? = nil
    
    @Published private(set) var customerManagementList:[CustomerManagement] = []
    @Published private(set) var displayCustomerManagementList:[CustomerManagement] = []
    
    @Published var sortOrder = [KeyPathComparator(\CustomerManagement.customerName)]
    
    func onLoad(companyId:String) async throws {
        print("On Load")
        let customerList = try await dataService.GetCustomersByLastName(companyId: companyId, LastNameHigh: false)
        let serviceLocationList = try await dataService.getAllCompanyServiceLocations(companyId: companyId)
        let recurringServiceStopList = try await dataService.getAllRecurringServiceStop(companyId: companyId)
        let recurringContractList = try await dataService.getAllContrats(companyId: companyId)
        print(customerCount)
        self.customerCount = customerList.count
        var count = 0
        for customer in customerList {
            var name = ""
            if customer.displayAsCompany {
                name = customer.company ?? ""
            } else {
                name = customer.firstName + " " + customer.lastName
            }
            count += 1
            print("Customer \(name) \(count)")
            
                //            let locations = try await dataService.getAllCustomerServiceLocationsId(companyId: companyId, customerId: customer.id)
            let locations = serviceLocationList.filter({$0.customerId == customer.id})
            self.serviceLocationCount = serviceLocationCount + locations.count
            
                //            let recurringServiceStops:[RecurringServiceStop] = try await dataService.getAllRecurringServiceStopByCustomerId(companyId: companyId, customerId: customer.id)
            let recurringServiceStops = recurringServiceStopList.filter({$0.customerId == customer.id})
            
                //            let recurringContracts = try await dataService.getContractsByCustomer(companyId: companyId, customerId: customer.id)
            let recurringContracts = recurringContractList.filter({$0.internalCustomerId == customer.id})
            
            print("locations \(locations.count)")
            print("recurringServiceStops \(recurringServiceStops.count)")
            print("recurringContracts \(recurringContracts.count)")
            
            for location in locations {
                var fullAddresss = ""
                
                if location.address.streetAddress != "" {
                    fullAddresss = fullAddresss + location.address.streetAddress
                }
                if location.address.city != "" {
                    fullAddresss = fullAddresss + " " + location.address.city
                }
                if location.address.state != "" {
                    fullAddresss = fullAddresss + " " + location.address.state
                }
                if location.address.zip != "" {
                    fullAddresss = fullAddresss + " " + location.address.zip
                }
                print(fullAddresss)
                var days:String = ""
                var rssIds:[String] = []
                var techIds:[String] = []
                var techNames:String = ""
                var setUp:Bool = false
                var contractMonthlyAmountCents : Int = 0
                var underContract:Bool = false
                
                let owesMoney:Bool = false
                
                if recurringServiceStops.contains(where: {$0.serviceLocationId == location.id}) {
                    setUp = true
                    let list = recurringServiceStops.filter({$0.serviceLocationId == location.id})
                    for rss in list {
                        days = rss.daysOfWeek
                        rssIds.append(rss.id)
                        techIds.append(rss.techId)
                        if !techNames.contains(rss.tech) {
                            techNames = techNames + rss.tech + " "
                        }
                    }
                } else {
                    setUp = false
                }
                if recurringContracts.contains(where: {$0.serviceLocationIds.contains(location.id)}) {
                    let list = recurringContracts.filter({$0.serviceLocationIds.contains(location.id)})
                    if !list.isEmpty {
                        for item in list {
                            var monthlyRate:Int = 0
                            switch item.rateType {
                            case .perYear:
                                monthlyRate = item.rate/12
                            case .perMonth:
                                monthlyRate = item.rate
                            case .perWeek:
                                monthlyRate = item.rate*4
                            case .perStop:
                                monthlyRate = 0
                            case .perDay:
                                monthlyRate = item.rate*(365/12)
                            }
                            contractMonthlyAmountCents = contractMonthlyAmountCents + monthlyRate
                            contractMonthlyAmountCents = contractMonthlyAmountCents / item.serviceLocationIds.count
                            underContract = true
                        }
                    } else {
                        underContract = false
                    }
                } else {
                    underContract = false
                }
                self.customerManagementList.append(
                    CustomerManagement(
                        customerId: customer.id,
                        customerName: name,
                        customerEmail: customer.email,
                        customerPhone: customer.phoneNumber ?? "NA",
                        active: customer.active,
                        serviceLocationId: location.id,
                        serviceLocationName: location.nickName,
                        serviceLocationAddress: fullAddresss,
                        underContract : underContract,
                        contractId : "",
                        contractMonthlyAmountCents: contractMonthlyAmountCents,
                        routingSetUp : setUp,
                        rssIds : rssIds,
                        days : days,
                        techIds : techIds,
                        techNames : techNames,
                        owesMoney : owesMoney,
                        outStandingBalance : 69420
                    )
                )
                self.displayCustomerManagementList = customerManagementList
                
            }
        }
        filterList()
    }
    func sortList(){
        print("Sort List")
        var list = customerManagementList
        list = list.sorted(by: {$0.customerName > $1.customerName})
        self.displayCustomerManagementList = list
        
    }
    func filterList() {
        var list = customerManagementList
        switch showsActive {
        case .yes:
            list = list.filter({$0.active == true})
        case .no:
            list = list.filter({$0.active == false})
        case .both:
            print("")
        }
        
        switch showUnderContract {
        case .yes:
            list = list.filter({$0.underContract == true})
        case .no:
            list = list.filter({$0.underContract == false})
        case .both:
            print("")
        }
        
        
        switch showHasRouting {
        case .yes:
            list = list.filter({$0.routingSetUp == true})
        case .no:
            list = list.filter({$0.routingSetUp == false})
        case .both:
            print("")
        }
        
        switch showOwesMoney {
        case .yes:
            list = list.filter({$0.owesMoney == true})
        case .no:
            list = list.filter({$0.owesMoney == false})
        case .both:
            print("")
        }
        if searchTerm != "" {
            var filteredItems:[CustomerManagement] = []
            for item in list {
                if item.customerName.lowercased().contains(searchTerm.lowercased()) || item.serviceLocationAddress.lowercased().contains(searchTerm.lowercased()) || item.techNames.lowercased().contains(searchTerm.lowercased()){
                    filteredItems.append(item)
                }
            }
            self.displayCustomerManagementList = filteredItems
        } else {
            self.displayCustomerManagementList = list
        }
        self.routedCount = 0

        for cus in displayCustomerManagementList {
            if cus.routingSetUp {
                self.routedCount += 1
            }
        }
    }
    func updateCustomerStatus(companyId:String,selectedCustomer:CustomerManagement,active:Bool) async throws {
        var customer:CustomerManagement = selectedCustomer
        customer.active = active
        self.customerManagementList.removeAll(where: {$0.id == customer.id})
        self.customerManagementList.append(customer)
        self.displayCustomerManagementList = customerManagementList
        try await dataService.updateCustomerActive(companyId: companyId, customerId: selectedCustomer.customerId, active: active)
        self.selected = customer
        self.selection = customer.id
        filterList()
        sortList()
            //        print("Sort List")
            //        var list = customerManagementList
            //        list = list.sorted(by: {$0.customerName > $1.customerName})
            //        self.displayCustomerManagementList = list
    }
    func checkRoutingStatus(companyId:String,selectedCustomer:CustomerManagement) async throws {
        var customer:CustomerManagement = selectedCustomer
            //        customer.active = active
        let RSSList = try await dataService.getRecurringServiceStopByServiceLocationId(companyId: companyId, serviceLocationId: selectedCustomer.serviceLocationId)
        var days:String = ""
        var rssIds:[String] = []
        var techIds:[String] = []
        var techNames:String = ""
        var setUp:Bool = false
        self.routedCount = 0
        if !RSSList.isEmpty {
            if RSSList.count != customer.rssIds.count {
                setUp = true
                self.routedCount += 1
                for rss in RSSList {
                    days = rss.daysOfWeek
                    rssIds.append(rss.id)
                    techIds.append(rss.techId)
                    if !techNames.contains(rss.tech) {
                        techNames = techNames + rss.tech + " "
                    }
                }
                customer.days = days
                customer.rssIds = rssIds
                customer.techIds = techIds
                customer.techNames = techNames
                customer.routingSetUp = setUp
                
                self.customerManagementList.removeAll(where: {$0.id == customer.id})
                self.customerManagementList.append(customer)
                self.displayCustomerManagementList = customerManagementList
                self.selected = customer
                self.selection = customer.id
                filterList()
                sortList()
            }
        }
    }
}
struct ManagementTablesView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject var VM : ManagementTablesViewModel
    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: ManagementTablesViewModel(dataService: dataService))
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack {
                filterOptions
                tableView
            }
            Text("")
                .sheet(isPresented: $VM.showDetailSheet, onDismiss: {
                    VM.selection = nil
                    VM.selected = nil
                    
                }, content: {
                    detailSheet
                })
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    print("Management Table")
                    try await VM.onLoad(companyId: currentCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: VM.searchTerm, perform: { term in
            VM.filterList()
        })
        .onChange(of: VM.showUnderContract, perform: { show in
            VM.filterList()
        })
        .onChange(of: VM.showHasRouting, perform: { show in
            VM.filterList()
        })
        .onChange(of: VM.showOwesMoney, perform: { show in
            VM.filterList()
        })
        .onChange(of: VM.showsActive, perform: { show in
            VM.filterList()
        })
        .onChange(of: VM.selection, perform: { selection in
            if let selection {
                print(selection)
                VM.selected = VM.customerManagementList.first(where: {$0.id == selection})
                VM.showDetailSheet.toggle()
            }
        })
    }
}

#Preview {
    ManagementTablesView(dataService: MockDataService())
}

extension ManagementTablesView {
    var tableView: some View{
        Table(of: CustomerManagement.self, selection: $VM.selection, sortOrder: $VM.sortOrder){
            TableColumn(""){
                Text($0.active ? "Active":"Inactive" )
                    .padding(4)
                    .padding(.horizontal,4)
                    .background($0.active ? Color.poolGreen : Color.poolRed)
                    .clipShape(.capsule)
                    .foregroundColor($0.active ? Color.black : Color.black)
            }
            .width(min: 60, ideal: 70, max: 80)
            TableColumn("Customer Name", value: \.customerName){
                Text($0.customerName)
            }
            TableColumn("Phone", value: \.customerPhone){
                Text($0.customerPhone )
            }
            TableColumn("Address", value: \.serviceLocationAddress){
                Text($0.serviceLocationAddress )
            }
            TableColumn("Under Contract"){
                Text($0.underContract ? "Yes":"No" )
                    .padding(4)
                    .padding(.horizontal,4)
                    .background($0.underContract ? Color.poolGreen : Color.poolRed)
                    .clipShape(.capsule)
                    .foregroundColor($0.underContract ? Color.black : Color.black)
            }
            .width(min: 45, ideal: 50, max: 60)
            TableColumn("Monthly", value: \.contractMonthlyAmountCents){
                Text("\(Double($0.contractMonthlyAmountCents)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
            }
            TableColumn("Routing"){
                Text($0.routingSetUp ? "Set Up":"No" )
                    .padding(4)
                    .padding(.horizontal,4)
                    .background($0.routingSetUp ? Color.poolGreen : Color.poolRed)
                    .clipShape(.capsule)
                    .foregroundColor($0.routingSetUp ? Color.black : Color.black)
            }
            .width(min: 60, ideal: 70, max: 80)
            TableColumn("Tech Name", value: \.techNames){
                Text($0.techNames )
            }
            TableColumn("Days", value: \.days){
                Text($0.days )
            }
//            TableColumn("Owes Money"){
//                Text($0.owesMoney ? "Yes":"No" )
//                    .padding(4)
//                    .padding(.horizontal,4)
//                    .background($0.owesMoney ? Color.poolRed : Color.poolGreen)
//                    .clipShape(.capsule)
//                    .foregroundColor($0.owesMoney ? Color.black : Color.black)
//            }
            TableColumn("Outstanding Balance", value: \.outStandingBalance){
                Text("\(Double($0.outStandingBalance)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
            }
        } rows: {
            ForEach(VM.displayCustomerManagementList) { item in
                TableRow(item)
                    .contextMenu {
                        Button(action: {
                            masterDataManager.selectedID = item.customerId
                            masterDataManager.selectedCategory = .customers
                        }, label: {
                            Text("Customer Profile")
                        })
                        Button(action: {
                            
                        }, label: {
                            Text("Send Contract")
                        })
                        Button(action: {
                            
                        }, label: {
                            Text("Set Up Routing")
                        })
                    }
            }
        }
        .onChange(of: VM.sortOrder) { newOrder in
            VM.sortList()
        }
    }
    var filterOptions: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    VM.showDetails.toggle()
                }, label: {
                    Text(VM.showDetails ? "Collapse" : "Expand" )
                        .foregroundColor(VM.showDetails ? Color.blue : Color.poolRed)
                })
            }
            if VM.showDetails {
                
                HStack{
                    Text("Filter")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal,8)
                HStack{
                    Text("Active : ")
                        .font(.headline)
                    Picker("Show Active", selection: $VM.showsActive) {
                        ForEach(CustomerManagementType.allCases){ datum in
                            Text(datum.rawValue).tag(datum)
                        }
                    }
                    Text("Under Contract : ")
                        .font(.headline)
                    Picker("Show Under Contract", selection: $VM.showUnderContract) {
                        ForEach(CustomerManagementType.allCases){ datum in
                            Text(datum.rawValue).tag(datum)
                        }
                    }
                    Text("Has Routing : ")
                        .font(.headline)
                    Picker("Show Has Routing", selection: $VM.showHasRouting) {
                        ForEach(CustomerManagementType.allCases){ datum in
                            Text(datum.rawValue).tag(datum)
                        }
                    }
                    Text("Has Balance: ")
                        .font(.headline)
                    Picker("Show Owes Money", selection: $VM.showOwesMoney) {
                        ForEach(CustomerManagementType.allCases){ datum in
                            Text(datum.rawValue).tag(datum)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal,8)
                HStack{
                    Text("Sort")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal,8)
                
                HStack{
                    Button(action: {
                        
                    }, label: {
                        Text("Customer Name :")
                    })
                    Spacer()
                }
                .padding(.horizontal,8)
                HStack{
                    TextField(
                        "Search Term",
                        text: $VM.searchTerm,
                        axis: .vertical
                    )
                    Button(action: {
                        VM.searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                VStack(alignment:.leading){
                    HStack{
                        Text("Customers : ")
                            .font(.headline)
                        Text("\(VM.displayCustomerManagementList.count)")
                        Text("Routed : ")
                            .font(.headline)
                        Text("\(String(VM.routedCount))")

                        Spacer()
                    }
                }
            }
        }
        .padding(.top,8)
    }
    var detailSheet: some View {
        ScrollView{
            VStack(alignment:.leading){
                if let selected = VM.selected {
                        //Tool Bar
                    HStack{
                        Spacer()
                        Button(action: {
                            VM.showDetailSheet.toggle()
                        }, label: {
                            Image(systemName: "xmark")
                                .modifier(DismissButtonModifier())
                        })
                    }
                        //Customer Info
                    VStack(alignment:.leading){
                        HStack{
                            Spacer()
                            Text("Customer Info")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                masterDataManager.selectedID = selected.customerId
                                masterDataManager.selectedCategory = .customers
                            }, label: {
                                Text("See Details")
                            })
                        }
                        Divider()
                        HStack{
                            Text(selected.active ? "Active" : "Inactive")
                                .padding(4)
                                .padding(.horizontal,4)
                                .background(selected.active ? Color.poolGreen : Color.poolRed)
                                .clipShape(.capsule)
                                .foregroundColor(selected.active ? Color.black : Color.black)
                            Spacer()
                            Button(action: {
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany {
                                        do {
                                            var newActive = selected.active
                                            newActive.toggle()
                                            try await VM.updateCustomerStatus(companyId: currentCompany.id, selectedCustomer: selected, active: newActive)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, label: {
                                Text("Change")
                            })
                        }
                        Text(selected.customerName)
                        Text(selected.customerPhone)
                        Text(selected.customerPhone)

                        Text(selected.serviceLocationAddress)
                    }
                    Rectangle()
                        .frame(height: 1)
                    VStack(alignment:.leading){
                        HStack{
                            Spacer()
                            Text("Contract Info")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                
                            }, label: {
                                
                            })
                        }
                        Divider()
                        Text(selected.underContract ? "Under Contract" : "Not Under Contract")
                            .padding(4)
                            .padding(.horizontal,4)
                            .background(selected.underContract ? Color.poolGreen : Color.poolRed)
                            .clipShape(.capsule)
                            .foregroundColor(selected.underContract ? Color.black : Color.black)
                        Text(selected.contractId)
                        Text("\(Double(selected.contractMonthlyAmountCents)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    }
                    Rectangle()
                        .frame(height: 1)
                    VStack(alignment:.leading){
                        HStack{
                            Spacer()
                            Text("Routing Info")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                VM.showRouteBuilder.toggle()
                            }, label: {
                                Text("Set Up Route")
                            })
                            .sheet(isPresented: $VM.showRouteBuilder,onDismiss: {
                                Task{
                                    if let currentCompany = masterDataManager.currentCompany{
                                        do {
                                            try await VM.checkRoutingStatus(companyId: currentCompany.id,selectedCustomer: selected)
                                        } catch {
                                            print(error)
                                        }
                                    }
                                }
                            }, content: {
                                Text("1")
                                NewSingleRecurringServiceStop(dataService: dataService, customerId: selected.customerId)
                            })
                        }
                        Divider()
                        Text(selected.routingSetUp ? "Routing Set Up" : "Routing Not Set Up")
                            .padding(4)
                            .padding(.horizontal,4)
                            .background(selected.routingSetUp ? Color.poolGreen : Color.poolRed)
                            .clipShape(.capsule)
                            .foregroundColor(selected.routingSetUp ? Color.black : Color.black)
                        Text(selected.days)
                        Text(selected.techNames)
                    }
                    Rectangle()
                        .frame(height: 1)
                    VStack(alignment:.leading){
                        HStack{
                            Spacer()
                            Text("Financial Info")
                                .font(.headline)
                            Spacer()
                        }
                        Divider()
                        Text(selected.owesMoney ? "Has Outstanding Balance" : "No Outstanding Balance")
                            .padding(4)
                            .padding(.horizontal,4)
                            .background(selected.owesMoney ? Color.poolRed : Color.poolGreen)
                            .clipShape(.capsule)
                            .foregroundColor(selected.owesMoney ? Color.black : Color.black)
                        Text("\(Double(selected.outStandingBalance)/100, format: .currency(code: "USD").precision(.fractionLength(2)))")
                    }
                }
            }
            .padding(5)
        }
    }
}
