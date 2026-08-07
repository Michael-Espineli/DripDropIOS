    //
    //  CustomerListView.swift
    //  Pool-Secretary-V2
    //
    //  Created by Michael Espineli on 9/9/23.
    //

import SwiftUI
import Contacts
enum NewCustomerPickerType:Identifiable{
    case new, contacts, upload
    var id:Int {
        hashValue
    }
}
@MainActor
final class CustomerListViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private(set) var customer: Customer? = nil
    @Published private(set) var customers:[Customer] = []
    @Published var displayCustomers:[Customer] = []
    
    @Published var selectedDocumentUrl:URL? = nil
    @Published var isPresented: Bool = false
    @Published var editing: Bool = false
    @Published var isLoading: Bool = false
    @Published var searchTerm:String = ""
    @Published var nav: Bool = false
    @Published var showActive:Bool = true
    
    @Published var showAlert:Bool = false
    @Published var alertMessage:String = ""
    @Published var showCustomerPicker:Bool = false
    
    @Published var showSearch:Bool = false
    @Published var showAddNew:Bool = false
    @Published var pickerType:NewCustomerPickerType? = nil
    @Published var selectedPickerType:NewCustomerPickerType? = nil
    @Published var showConfirmationSheet:Bool = false
    @Published var showSelectedContact:Bool = false
    
    @Published var selectedContact:CNContact? = nil
    @Published var showFilters:Bool = false
    @Published var showCustomerUploadScreen:Bool = false
    
    @Published var customerSortOption: CustomerSortOptions = .lastNameHigh
    @Published var customerFilterOption : CustomerFilterOptions = .active
    @Published var tags:[String] = []
    @Published var tag:String = "All"
    
    func onLoad(companyId:String){
        print("")
        print("On Load")
        dataService.addListenerForAllCustomers(companyId: companyId, sort: customerSortOption, filter: customerFilterOption) { [weak self] customers in
            print(customers.count)
            self?.displayCustomers = customers
            self?.customers = customers
        }
        
        filterCustomerList()
    }
    func getCustomer(companyId: String,customerId:String) async throws{
        self.customer = try await dataService.getCustomerById(companyId: companyId, customerId: customerId)
        
    }
    func changeSortOrFilter(companyId:String) {
        dataService.addListenerForAllCustomers(companyId: companyId, sort: customerSortOption, filter: customerFilterOption) { [weak self] customers in
             self?.displayCustomers = customers
            self?.customers = customers
        }
    }
    func removeListener(){
        dataService.removeListenerForAllCustomers()
    }
    func filterCustomerList() {
        //very facncy Search Bar
        print("Filtering Customers: \(searchTerm)")
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.displayCustomers = customers
        } else {
            var filteredListOfCustomers:[Customer] = []
            for customer in customers {
                let phone = customer.phoneNumber ?? "0"
                let replacedPhone1 = phone.replacingOccurrences(of: ".", with: "")
                let replacedPhone2 = replacedPhone1.replacingOccurrences(of: "-", with: "")
                let replacedPhone3 = replacedPhone2.replacingOccurrences(of: " ", with: "")
                let replacedPhone4 = replacedPhone3.replacingOccurrences(of: ".", with: "")
                let replacedPhone5 = replacedPhone4.replacingOccurrences(of: "(", with: "")
                let replacedPhone6 = replacedPhone5.replacingOccurrences(of: ")", with: "")
                
                let address = (customer.billingAddress.streetAddress ) + " " + (customer.billingAddress.city ) + " " + (customer.billingAddress.state ) + " " + (customer.billingAddress.zip )
                let company:String = customer.company ?? "0"
                let fullName = customer.firstName + " " + customer.lastName
                if customer.firstName.lowercased().contains(searchTerm.lowercased()) || customer.lastName.lowercased().contains(searchTerm.lowercased()) || replacedPhone6.lowercased().contains(searchTerm.lowercased()) || customer.email.lowercased().contains(searchTerm.lowercased()) || address.lowercased().contains(searchTerm.lowercased()) || company.lowercased().contains(searchTerm.lowercased()) || fullName.lowercased().contains(searchTerm.lowercased()){
                    filteredListOfCustomers.append(customer)
                }
            }
            self.displayCustomers = filteredListOfCustomers
            
            print("Customer Count: \(filteredListOfCustomers.count)")
        }
    }
    
    func addContact(){
            //        self.showConfirmationSheet = true
        self.showSelectedContact = true
    }
    func uploadCustomer(){
        self.showCustomerUploadScreen = true
    }
}
struct CustomerListView: View{
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var dataService: ProductionDataService
    
    @EnvironmentObject var VM : CustomerListViewModel

    init(dataService:any ProductionDataServiceProtocol){
    }
    func createNew(){
            //DEVELOEPR FIX ROUTE
        navigationManager.routes.append(Route.createCustomer(dataService: dataService))
    }
    @FocusState var searchField:Bool

    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            if UIDevice.isIPhone {
                mobileList
            } else {
                macList
            }
            icons
        }
        .navigationTitle("Customers")
        .toolbar {
            if !UIDevice.isIPhone {
                ToolbarItem {
                    Button {
                        VM.showCustomerPicker = true
                    } label: {
                        Text("Add")
                            .foregroundColor(Color.poolBlue)
                    }
                }
            }
        }
        .alert(isPresented:$VM.showAlert) {
            Alert(
                title: Text("\(VM.alertMessage)"),
                message: Text("\(VM.alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        .task {
            if let company = masterDataManager.currentCompany {
                if let term = masterDataManager.customerSearchTerm {
                    VM.searchTerm = term
                }
                VM.onLoad(companyId: company.id)
                searchField = false
                VM.showSearch = false
            }
        }
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                if selectedId != "" {
                    Task{
                        do {
                            if let company = masterDataManager.currentCompany {
                                try await VM.getCustomer(companyId : company.id, customerId : selectedId)
                                masterDataManager.selectedCustomer = VM.customer
                                print("Successfully Get Customer")
                                VM.filterCustomerList()
                            }
                        } catch {
                            print("Failed to Get Customer")
                        }
                    }
                }
            }
        })
        .onChange(of: VM.selectedDocumentUrl, perform: { doc in
            VM.showCustomerUploadScreen = true
        })
        .onChange(of: VM.customerSortOption, perform: { sort in
            if let company = masterDataManager.currentCompany {
                VM.changeSortOrFilter(companyId: company.id)
            }
        })
        .onChange(of: VM.customerFilterOption, perform: { filter in
            if let company = masterDataManager.currentCompany {
                VM.changeSortOrFilter(companyId: company.id)
            }
        })
        .onChange(of: VM.searchTerm){ term in
            print("on Change of Search Term")
            masterDataManager.customerSearchTerm = term
            VM.filterCustomerList()
        }
        .onChange(of: VM.customers, perform: { list in
            print("Change in Customer List")
            if let term = masterDataManager.customerSearchTerm {
                VM.searchTerm = term
            }
            VM.filterCustomerList()
        })
        .onDisappear(perform: {
            VM.showSearch = false
            searchField = false
            VM.removeListener()
        })
    }

}
extension CustomerListView {
    var mobileList: some View{
        VStack(spacing: 0){
            mobileCustomerHeader

            if VM.showSearch {
                mobileSearchField
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }

            if VM.displayCustomers.count == 0 {
                ScrollView(showsIndicators: false) {
                    mobileEmptyState
                        .padding(.horizontal, 14)
                        .padding(.top, 14)

                    Color.clear.frame(height: 120)
                }
            } else {
                ScrollView(showsIndicators: false){
                    LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                        ForEach(displayedAlphabetLetters) { letter in
                            let customers = groupedCustomers(for: letter)

                            if !customers.isEmpty {
                                Section {
                                    ForEach(customers){ customer in
                                        mobileCustomerLink(customer)
                                    }
                                } header: {
                                    mobileSectionHeader(letter.upperCase())
                                }
                            }
                        }

                        if !customersWithoutGroupName.isEmpty {
                            Section {
                                ForEach(customersWithoutGroupName){ customer in
                                    mobileCustomerLink(customer)
                                }
                            } header: {
                                mobileSectionHeader("No Name")
                            }
                        }

                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var mobileCustomerHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.poolBlue)
                    .frame(width: 48, height: 48)
                    .background(Color.poolBlue.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Customers")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(customerListSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                customerSummaryMetric(
                    title: "Showing",
                    value: "\(VM.displayCustomers.count)",
                    tint: .poolBlue
                )

                customerSummaryMetric(
                    title: "Active",
                    value: "\(VM.displayCustomers.filter { $0.active }.count)",
                    tint: .poolGreen
                )

                customerSummaryMetric(
                    title: "Filter",
                    value: VM.customerFilterOption.display(),
                    tint: .orange
                )
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var mobileSearchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField("Search customers", text: $VM.searchTerm)
                .focused($searchField, equals: true)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    VM.filterCustomerList()
                }

            if !VM.searchTerm.isEmpty {
                Button {
                    VM.searchTerm = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.thinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var mobileEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(VM.searchTerm.isEmpty ? "No customers found." : "No matches found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(VM.searchTerm.isEmpty ? "Add a customer to start building this list." : "Try a different name, phone, email, or address.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if VM.searchTerm.isEmpty, let role = masterDataManager.role, role.permissionIdList.contains("12") {
                        Button(action: {
                            VM.showCustomerPicker = true
                        }, label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Customer")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.poolGreen, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        })
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func customerSummaryMetric(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func mobileSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)

            Spacer()
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 7)
        .background(Color.listColor)
    }

    private func mobileCustomerLink(_ customer: Customer) -> some View {
        NavigationLink(value: Route.customer(customer: customer,dataService:dataService)) {
            CustomerCardViewSmall(customer: customer)
        }
        .buttonStyle(.plain)
        .onTapGesture {
            VM.showSearch = false
            searchField = false
        }
    }

    private var customerListSubtitle: String {
        let sort = VM.customerSortOption.display()
        let filter = VM.customerFilterOption.display()

        if VM.searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(filter) customers sorted by \(sort.lowercased())."
        }

        return "Search results for \"\(VM.searchTerm)\"."
    }

    private var displayedAlphabetLetters: [Alphebet] {
        switch VM.customerSortOption {
        case .firstNameLow, .lastNameLow:
            return Array(Alphebet.allCases.reversed())
        case .durationLow, .durationHigh, .firstNameHigh, .lastNameHigh:
            return Alphebet.allCases
        }
    }

    private var usesFirstNameGrouping: Bool {
        switch VM.customerSortOption {
        case .firstNameHigh, .firstNameLow:
            return true
        case .durationLow, .durationHigh, .lastNameHigh, .lastNameLow:
            return false
        }
    }

    private func groupedCustomers(for letter: Alphebet) -> [Customer] {
        VM.displayCustomers.filter {
            customerGroupingName($0)
                .lowercased()
                .starts(with: letter.lowerCase())
        }
    }

    private var customersWithoutGroupName: [Customer] {
        VM.displayCustomers.filter {
            customerGroupingName($0)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        }
    }

    private func customerGroupingName(_ customer: Customer) -> String {
        if usesFirstNameGrouping {
            return customer.firstName
        }

        if !customer.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customer.lastName
        }

        if customer.displayAsCompany {
            return customer.company ?? ""
        }

        return customer.firstName
    }
    
    var macList: some View{
        VStack{
            if VM.showSearch && !UIDevice.isIPhone{
                HStack{
                    TextField(
                        "Search",
                        text: $VM.searchTerm
                    )
                    Button(action: {
                        VM.searchTerm = ""
                    }, label: {
                        Image(systemName: "xmark")
                    })
                }
                .modifier(SearchTextFieldModifier())
                .padding(8)
            }
            if VM.displayCustomers.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("12") {
                        Button(action: {
                            VM.showAddNew.toggle()
                        }, label: {
                            Text("Add New Customer")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                        })
                        .sheet(isPresented: $VM.showAddNew, content: {
                            AddNewCustomerView(dataService: dataService)

                        })
                        Spacer()
                    }
                }
            } else {
                switch VM.customerSortOption {
                case .firstNameHigh:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            if VM.displayCustomers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                Section(content: {
                                    ForEach(VM.displayCustomers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                        if UIDevice.isIPhone {
                                            NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCustomer = customer
                                                navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                            }, label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        }
                                    }
                                    
                                }, header: {
                                    Text(letter.upperCase())
                                        .foregroundColor(Color.accentColor)
                                    
                                })
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                                
                            })
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .listStyle(.plain)
                case .firstNameLow:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases.reversed()) { letter in
                            if VM.displayCustomers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(VM.displayCustomers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                        if UIDevice.isIPhone {
                                            NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCustomer = customer
                                                navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                            }, label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        }
                                    }
                                    
                                }, header: {
                                    Text(letter.upperCase())
                                        .foregroundColor(Color.accentColor)
                                    
                                })
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                                
                            })
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .listStyle(.plain)
                    
                case .lastNameLow:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases.reversed()) { letter in
                            if VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                        if UIDevice.isIPhone {
                                            NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCustomer = customer
                                                navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                            }, label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        }
                                    }
                                    
                                }, header: {
                                    Text(letter.upperCase())
                                        .foregroundColor(Color.accentColor)
                                    
                                })
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                                
                            })
                        }
                    }
                    .background(Color.gray.opacity(0.5))
                    .listStyle(.plain)
                case .lastNameHigh:
                    ScrollView{
                        ForEach(Alphebet.allCases) { letter in
                            if VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                        if UIDevice.isIPhone {
                                            NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCustomer = customer
                                                    //                                                navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                            }, label: {
                                                CustomerCardViewSmall(customer: customer)
                                            })
                                            .padding(.horizontal,8)
                                            .padding(.vertical,3)
                                            Divider()
                                        }
                                    }
                                    
                                }, header: {
                                    HStack{
                                        Text(letter.upperCase())
                                            .foregroundColor(Color.accentColor)
                                        Spacer()
                                    }
                                })
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                            })
                        }
                    }
                    .padding(8)
                    .background(Color.listColor)
                case .durationHigh:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            HStack{
                                Text(letter.upperCase())
                                    .foregroundColor(Color.accentColor)
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                Spacer()
                            }
                            .background(Color.gray.opacity(0.5))
                            
                            ForEach(VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                        CustomerCardViewSmall(customer: customer)
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCustomer = customer
                                        navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                    }, label: {
                                        CustomerCardViewSmall(customer: customer)
                                    })
                                }
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                                
                            })
                        }
                    }
                    .listStyle(.plain)
                case .durationLow:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            HStack{
                                Text(letter.upperCase())
                                    .foregroundColor(Color.accentColor)
                                    .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                                Spacer()
                            }
                            .background(Color.gray.opacity(0.5))
                            
                            ForEach(VM.displayCustomers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
                                if UIDevice.isIPhone {
                                    NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                        CustomerCardViewSmall(customer: customer)
                                    })
                                } else {
                                    Button(action: {
                                        masterDataManager.selectedCustomer = customer
                                        navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                    }, label: {
                                        CustomerCardViewSmall(customer: customer)
                                    })
                                }
                            }
                        }
                        if VM.displayCustomers.filter({$0.firstName.lowercased() == ""}).count != 0 {
                            Section(content: {
                                ForEach(VM.displayCustomers.filter({$0.firstName.lowercased() == ""})){ customer in
                                    if UIDevice.isIPhone {
                                        NavigationLink(value: Route.customer(customer: customer,dataService:dataService), label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                        })
                                    }
                                }
                                
                            }, header: {
                                Text("No Name")
                                    .foregroundColor(Color.accentColor)
                                
                            })
                        }
                    }
                    .listStyle(.plain)
                }
                
            }
        }
    }
    var icons: some View{
        ZStack{
            if let role = masterDataManager.role {
                VStack{
                    Spacer()
                    HStack{
                        Spacer()
                        Text("")
                            .sheet(isPresented: $VM.showCustomerUploadScreen,onDismiss: {
                                VM.selectedDocumentUrl = nil
                            }, content: {
                                if let doc = VM.selectedDocumentUrl {
                                    UploadXLSXFileForCustomer(selectedDocumentUrl: doc)
                                } else {
                                    DocumentPicker(filePath: self.$VM.selectedDocumentUrl)
                                }
                            })
                            .sheet(isPresented: $VM.showSelectedContact,onDismiss: {
                                    //                                    selectedContact = nil
                                VM.showConfirmationSheet = true
                            }, content: {
                                ContactPicker(selectedContact: self.$VM.selectedContact)
                            })
                            .sheet(isPresented: $VM.showConfirmationSheet,onDismiss: {
                                VM.selectedContact = nil
                            }, content: {
                                ZStack{
                                    if VM.selectedContact != nil {
                                        AddNewCustomerConfirmationScreen(dataService: dataService,contact:VM.selectedContact!)
                                    }
                                }
                            })

                        VStack(spacing: 10){
                            Button {
                                VM.showFilters.toggle()
                            } label: {
                                mobileDockIcon(
                                    systemImage: "slider.horizontal.3",
                                    tint: .orange,
                                    isSelected: VM.showFilters
                                )
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $VM.showFilters, onDismiss: {
                                if let company = masterDataManager.currentCompany {
                                    VM.removeListener()
                                    VM.changeSortOrFilter(companyId: company.id)
                                }
                            }, content: {
                                customerFilterSheet
                            })

                            if role.permissionIdList.contains("12") {
                                Button {
                                    VM.showCustomerPicker = true
                                } label: {
                                    mobileDockIcon(
                                        systemImage: "plus",
                                        tint: .poolGreen,
                                        isSelected: false
                                    )
                                }
                                .buttonStyle(.plain)
                                .confirmationDialog("Select Type", isPresented: self.$VM.showCustomerPicker, actions: {
                                    Button(action: {
                                        VM.pickerType = .new
                                        VM.selectedPickerType = .new
                                    }, label: {
                                        Text("New")
                                    })
                                    Button(action: {
                                        VM.pickerType = .contacts
                                        VM.selectedPickerType = .contacts
                                        
                                    }, label: {
                                        Text("From Contacts")
                                    })
                                    Button(action: {
                                        VM.pickerType = .upload
                                        VM.selectedPickerType = .upload
                                        
                                    }, label: {
                                        Text("Upload")
                                    })
                                })
                                .sheet(item: self.$VM.pickerType,onDismiss: {
                                    print("dismiss")
                                    if VM.selectedContact != nil {
                                        print("Show Confirmation Sheet")
                                        VM.showConfirmationSheet = true
                                    }
                                }){ item in
                                    switch item {
                                    case .new:
                                        NavigationView{
                                            AddNewCustomerView(dataService: dataService)
                                        }
                                    case .contacts:
                                        NavigationView{
                                            if let contact = VM.selectedContact{
                                                AddNewCustomerConfirmationScreen(dataService: dataService,contact : contact)
                                            } else {
                                                ContactPicker(selectedContact: self.$VM.selectedContact)
                                            }
                                        }
                                    case .upload:
                                        NavigationView{
                                            if let doc = VM.selectedDocumentUrl {
                                                UploadXLSXFileForCustomer(selectedDocumentUrl: doc)
                                            } else {
                                                DocumentPicker(filePath: self.$VM.selectedDocumentUrl)
                                            }
                                        }
                                    }
                                }
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    VM.showSearch.toggle()
                                }
                                searchField = VM.showSearch
                                VM.filterCustomerList()
                            }, label: {
                                mobileDockIcon(
                                    systemImage: "magnifyingglass",
                                    tint: .poolBlue,
                                    isSelected: VM.showSearch
                                )
                            })
                            .buttonStyle(.plain)
                        }
                        .padding(7)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.trailing, 14)
                        .padding(.bottom, UIDevice.isIPhone ? 18 : 14)
                    }
                }
            }
        }
    }

    private func mobileDockIcon(
        systemImage: String,
        tint: Color,
        isSelected: Bool
    ) -> some View {
        Image(systemName: systemImage)
            .font(.body.weight(.semibold))
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(width: 40, height: 40)
            .background(
                isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.13)),
                in: Circle()
            )
    }

    private var customerFilterSheet: some View {
        DripDropFilterSheet(
            title: "Sort & Filter",
            isPresented: $VM.showFilters,
            isResetDisabled: customerActiveFilterCount == 0,
            onReset: resetCustomerFilters
        ) {
            DripDropFilterSummaryCard(
                title: "\(VM.displayCustomers.count) customers showing",
                subtitle: customerActiveFilterCount == 0 ? "Using the default customer list settings." : "\(customerActiveFilterCount) list setting\(customerActiveFilterCount == 1 ? "" : "s") changed.",
                systemImage: "person.2.fill",
                tint: .orange
            )

            DripDropFilterSection(
                title: "Customer List",
                systemImage: "person.text.rectangle",
                tint: .orange
            ) {
                DripDropFilterRow(
                    title: "Sort",
                    subtitle: "List order",
                    systemImage: "arrow.up.arrow.down",
                    tint: .poolBlue
                ) {
                    Picker("Sort", selection: $VM.customerSortOption) {
                        ForEach(CustomerSortOptions.allCases, id: \.self) { option in
                            Text(option.display()).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                DripDropFilterRow(
                    title: "Filter",
                    subtitle: "Account status",
                    systemImage: "line.3.horizontal.decrease.circle",
                    tint: .orange
                ) {
                    Picker("Filter", selection: $VM.customerFilterOption) {
                        ForEach(CustomerFilterOptions.allCases, id: \.self) { option in
                            Text(option.display()).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
        .presentationDetents([.fraction(0.35), .medium])
    }

    private var customerActiveFilterCount: Int {
        var count = 0

        if VM.customerSortOption != .lastNameHigh { count += 1 }
        if VM.customerFilterOption != .active { count += 1 }

        return count
    }

    private func resetCustomerFilters() {
        VM.customerSortOption = .lastNameHigh
        VM.customerFilterOption = .active
    }
}
