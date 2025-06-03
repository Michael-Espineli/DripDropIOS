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
        if searchTerm != "" {
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
    
    @StateObject private var VM : CustomerListViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _VM = StateObject(wrappedValue: CustomerListViewModel(dataService: dataService))
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
                VM.onLoad(companyId: company.id)
                searchField = false
                VM.showSearch = false
                if let term = masterDataManager.customerSearchTerm {
//                    VM.filterCustomerList()
                    VM.searchTerm = term
                }
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
        VStack{
            if VM.displayCustomers.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("3") {
                        Button(action: {
                            VM.showCustomerPicker = true
                        }, label: {
                            Text("Add New Customer")
                                .modifier(AddButtonModifier())
                        })
                    }}
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
                                            .onTapGesture(perform: {
                                                VM.showSearch = false
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
                                        .onTapGesture(perform: {
                                            VM.showSearch = false
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
                                            .onTapGesture(perform: {
                                                VM.showSearch = false
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
                                        .onTapGesture(perform: {
                                            VM.showSearch = false
                                            searchField = false
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
                                            .onTapGesture(perform: {
                                                VM.showSearch = false
                                                searchField = false
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
                                        .onTapGesture(perform: {
                                            VM.showSearch = false
                                            searchField = false
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
                                                    .padding(.vertical,8)
                                            })
                                            .onTapGesture(perform: {
                                                VM.showSearch = false
                                                searchField = false
                                            })
                                        } else {
                                            Button(action: {
                                                masterDataManager.selectedCustomer = customer
                                                navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                            }, label: {
                                                CustomerCardViewSmall(customer: customer)
                                                    .padding(.vertical,8)
                                            })
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
                                                .padding(.vertical,8)
                                        })
                                        .onTapGesture(perform: {
                                            VM.showSearch = false
                                            searchField = false
                                        })
                                    } else {
                                        Button(action: {
                                            masterDataManager.selectedCustomer = customer
                                            navigationManager.routes.append(Route.customer(customer: customer,dataService:dataService))
                                        }, label: {
                                            CustomerCardViewSmall(customer: customer)
                                                .padding(.vertical,8)
                                        })
                                    }
                                }
                                
                            }, header: {
                                HStack{
                                    Text("No Name")
                                        .foregroundColor(Color.accentColor)
                                    Spacer()
                                }
                            })
                        }
                    }
                    .padding(8)
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
                                    .onTapGesture(perform: {
                                        VM.showSearch = false
                                        searchField = false
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
                                    .onTapGesture(perform: {
                                        VM.showSearch = false
                                        searchField = false
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
                                        .onTapGesture(perform: {
                                            VM.showSearch = false
                                            searchField = false
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
                    if role.permissionIdList.contains("3") {
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
                    
                    VStack{
                        Button(action: {
                            VM.showFilters.toggle()
                        }, label: {
                            Image(systemName: "slider.horizontal.3")
                                .modifier(FilterIconModifer())
                        })
                        .padding(8)
                        .sheet(isPresented: $VM.showFilters, onDismiss: {
                            Task{
                                if let company = masterDataManager.currentCompany {
                                    do {
                                        VM.removeListener()
                                        try await VM.changeSortOrFilter(companyId: company.id)
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }, content: {
                            ZStack{
                                Color.listColor.ignoresSafeArea()
                                VStack{
                                    HStack{
                                        Text("Sort & Filter")
                                            .font(.title)
                                    }
                                    Rectangle()
                                        .frame(height: 1)
                                    HStack{
                                        Text("Sort")
                                        Spacer()
                                        Picker("Sort: ", selection: $VM.customerSortOption) {
                                            ForEach(CustomerSortOptions.allCases,id:\.self) {
                                                Text($0.display()).tag($0)
                                            }
                                        }
                                    }
                                    HStack{
                                        Text("Filter")
                                        Spacer()
                                        Picker("Filter:", selection: $VM.customerFilterOption) {
                                            ForEach(CustomerFilterOptions.allCases,id:\.self) {
                                                Text($0.display()).tag($0)
                                            }
                                        }
                                    }
                                        //----------------------------------------
                                        //Add Back in During Roll out of Phase 2
                                        //----------------------------------------
//                                    HStack{
//                                        Text("Tags")
//                                        Spacer()
//                                        Picker("Tags:", selection: $VM.tag) {
//                                            Text("Tag")
//                                            ForEach(VM.tags,id:\.self) {
//                                                Text($0).tag($0)
//                                            }
//                                        }
//                                    }
                                    Spacer()
                                }
                            }
                            .presentationDetents([.fraction(0.3), .medium])
                        })
                        if let role = masterDataManager.role {
                            if role.permissionIdList.contains("3") {
                                Button(action: {
                                    Task{
                                        VM.showCustomerPicker = true
                                    }
                                }, label: {
                                    Image(systemName: "plus")
                                        .modifier(PlusIconModifer())
                                })
                                .padding(8)
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
                                Button(action: {
                                    VM.showSearch.toggle()
                                    
                                    searchField.toggle()
                                }, label: {
                                    Image(systemName: "magnifyingglass")
                                        .modifier(SearchIconModifer())
                                })
                                .padding(10)
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
                            }
                        }
                    }
                    
                }
                if VM.showSearch && UIDevice.isIPhone{
                    HStack{
                        HStack{
                            TextField(
                                "Search",
                                text: $VM.searchTerm
                            )
                            .focused($searchField, equals: true)
                            .submitLabel(.search)
                            .onSubmit {
                                VM.filterCustomerList()
                            }
                            Spacer()
                            Button(action: {
                                VM.searchTerm = ""
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                        .modifier(SearchTextFieldModifier())
                        .padding(8)
                    }
                    .background(Color.listColor)
                }
            }
        }
    }
}
