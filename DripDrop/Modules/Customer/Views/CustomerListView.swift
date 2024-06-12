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
struct CustomerListView: View{
    @EnvironmentObject var navigationManager: NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @EnvironmentObject var customerViewModel: CustomerViewModel
    @EnvironmentObject var customerEnviromentalObject: CustomerViewModel
    @EnvironmentObject var dataService: ProductionDataService
    
    @StateObject private var customerVM : CustomerViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
    }
    
    
    @State var selectedDocumentUrl:URL? = nil
    
    //    @State private var selected = Set<Customer.ID>()
    //    @State private var selection: Customer.ID? = nil
    //    @State private var selectedCustomer: Customer? = nil
    
    
    @State private var customers:[Customer] = []
    //    @State private var sortOrder = [KeyPathComparator(\Customer.lastName, order: .forward)]
    
    @State private var isPresented: Bool = false
    @State private var editing: Bool = false
    @State private var isLoading: Bool = false
    @State var searchTerm:String = ""
    @State private var nav: Bool = false
    @State var showActive:Bool = true
    
    @State var showAlert:Bool = false
    @State var alertMessage:String = ""
    @State var showCustomerPicker:Bool = false
    
    @State var showSearch:Bool = false
    @State var showAddNew:Bool = false
    @State private var pickerType:NewCustomerPickerType? = nil
    @State private var selectedPickerType:NewCustomerPickerType? = nil
    @State var showConfirmationSheet:Bool = false
    @State var showSelectedContact:Bool = false
    
    @State var selectedContact:CNContact? = nil
    @State var showFilters:Bool = false
    @State var showCustomerUploadScreen:Bool = false
    
    @State var customerSortOption: CustomerSortOptions = .lastNameHigh
    @State var customerFilterOption : CustomerFilterOptions = .active
    @State var tags:[String] = []
    @State var tag:String = "All"
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
        .navigationTitle("Customer - \(customers.count)")
        //        .onChange(of: showAddNew, perform: { show in
        //            print(show)
        //            showAddNew = false
        //        })
        .task {
            if let company = masterDataManager.selectedCompany {
                //On Arrival if the selcetd ID is not nil get the customer and push to the screen. This is how I wanna handle Deeplinking through an auth screen. it passes through an id and then when it receives the Id then it gets it
                /*
                 if let loadedCustomer = navigationManager.selectedCustomer {
                 print("Customer is already Loaded")
                 } else {
                 if let id = navigationManager.selectedID {
                 do {
                 print("Selected ID \(id)")
                 print("Company Id \(company.id)")
                 try await customerVM.getCustomer(companyId: company.id, customerId: id)
                 
                 if let customer = customerVM.customer {
                 print("Customer Successfully Received")
                 navigationManager.selectedCustomer = customer
                 navigationManager.push(to: .customer(customer:customer))
                 }
                 } catch {
                 print("Customer does not Exist")
                 }
                 } else {
                 print("Selected ID is nil")
                 }
                 }
                 */
                //Add Subscriber
                
                customerVM.addListenerForAllCustomers(companyId: company.id, filter: customerFilterOption, sort: customerSortOption)
                
            }
        }
        .alert(isPresented:$showAlert) {
            Alert(
                title: Text("\(alertMessage)"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    print("Deleting...")
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: masterDataManager.selectedID, perform: { id in
            if let selectedId = id {
                Task{
                    do {
                        if let company = masterDataManager.selectedCompany {
                            try await customerVM.getCustomer(companyId : company.id, customerId : selectedId)
                            masterDataManager.selectedCustomer = customerVM.customer
                            print("Successfully Get Customer")
                        }
                    } catch {
                        print("Failed to Get Customer")
                    }
                }
            }
        })
        .onChange(of: selectedDocumentUrl, perform: { doc in
            showCustomerUploadScreen = true
        })
        .onChange(of: customerSortOption, perform: { sort in
            if let company = masterDataManager.selectedCompany {
                customerVM.removeListener()
                customerVM.addListenerForAllCustomers(companyId: company.id, filter: customerFilterOption, sort: sort)
            }
        })
        .onChange(of: customerFilterOption, perform: { filter in
            if let company = masterDataManager.selectedCompany {
                customerVM.removeListener()
                customerVM.addListenerForAllCustomers(companyId: company.id, filter: filter, sort: customerSortOption)
            }
        })
        .onChange(of: customerVM.customers, perform: { list in
            customers = list
        })
        .onChange(of: searchTerm){ term in
            if term == "" {
                customers = customerVM.customers
            } else {
                customerVM.filterCustomerList(filterTerm: term, customers: customerVM.customers)
                customers = customerVM.filteredCustomers
            }
        }
        .onDisappear(perform: {
            customerVM.removeListener()
        })
    }
    func createNew(){
        //DEVELOEPR FIX ROUTE
        navigationManager.routes.append(Route.createCustomer(dataService: dataService))
    }
    func addContact(){
        //        self.showConfirmationSheet = true
        self.showSelectedContact = true
    }
    func uploadCustomer(){
        self.showCustomerUploadScreen = true
    }
}
extension CustomerListView {
    var mobileList: some View{
        VStack{
            if customers.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("3") {
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Text("Add New Customer")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                        })
                        .fullScreenCover(isPresented: $showAddNew, content: {
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        showAddNew = false
                                    }, label: {
                                        Image(systemName: "xmark")
                                    })
                                }
                                .padding(16)
                                AddNewCustomerView(dataService: dataService)
                            }
                        })
                    }}
            } else {
                switch customerSortOption {
                case .firstNameHigh:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            if customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                Section(content: {
                                    ForEach(customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            if customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            if customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            if customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                    .listStyle(.insetGrouped)
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
                            
                            ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            
                            ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
    
    var macList: some View{
        VStack{
            if customers.count == 0 {
                if let role = masterDataManager.role {
                    if role.permissionIdList.contains("3") {
                        Button(action: {
                            showAddNew.toggle()
                        }, label: {
                            Text("Add New Customer")
                                .padding(10)
                                .background(Color.blue)
                                .foregroundColor(Color.white)
                                .cornerRadius(10)
                        })
                        .fullScreenCover(isPresented: $showAddNew, content: {
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        showAddNew = false
                                    }, label: {
                                        Image(systemName: "xmark")
                                    })
                                }
                                .padding(16)
                                AddNewCustomerView(dataService: dataService)
                            }
                        })
                        
                    }}
            } else {
                switch customerSortOption {
                case .firstNameHigh:
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            if customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                Section(content: {
                                    ForEach(customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            if customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.firstName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            if customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                    List(selection:$masterDataManager.selectedID){
                        ForEach(Alphebet.allCases) { letter in
                            if customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())}).count != 0 {
                                
                                Section(content: {
                                    ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                    .listStyle(.insetGrouped)
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
                            
                            ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                            
                            ForEach(customers.filter({$0.lastName.lowercased().starts(with: letter.lowerCase())})){ customer in
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
                        if customers.filter({$0.firstName.lowercased().starts(with: " ")}).count != 0 {
                            Section(content: {
                                ForEach(customers.filter({$0.firstName.lowercased().starts(with: " ")})){ customer in
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
                    Text("")
                        .fullScreenCover(isPresented: $showCustomerUploadScreen,onDismiss: {
                            selectedDocumentUrl = nil
                        }, content: {
                            if let doc = selectedDocumentUrl {
                                UploadXLSXFileForCustomer(selectedDocumentUrl: doc)
                            } else {
                                DocumentPicker(filePath: self.$selectedDocumentUrl)
                            }
                        })
                    if UIDevice.isIPhone {
                        Spacer()
                    }
                    VStack{
                        Button(action: {
                            showFilters.toggle()
                        }, label: {
                            ZStack{
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "slider.horizontal.3")
                                            .resizable()
                                            .frame(width: 25, height: 25)
                                            .foregroundColor(Color.white)
                                    )
                            }
                        })
                        .padding(10)
                        .fullScreenCover(isPresented: $showFilters, content: {
                            VStack{
                                HStack{
                                    Spacer()
                                    Button(action: {
                                        showFilters = false
                                    }, label: {
                                        Image(systemName: "xmark")
                                    })
                                }
                                .padding(16)
                                VStack{
                                    HStack{
                                        Text("Filters")
                                            .font(.title)
                                    }
                                    Picker("Sort: ", selection: $customerSortOption) {
                                        ForEach(CustomerSortOptions.allCases,id:\.self) {
                                            Text($0.display()).tag($0)
                                        }
                                    }
                                    Picker("Filter:", selection: $customerFilterOption) {
                                        ForEach(CustomerFilterOptions.allCases,id:\.self) {
                                            Text($0.display()).tag($0)
                                        }
                                    }
                                    Picker("Tags:", selection: $tag) {
                                        Text("Tag")
                                        ForEach(tags,id:\.self) {
                                            Text($0).tag($0)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        })
                        
                        if let role = masterDataManager.role {
                            if role.permissionIdList.contains("3") {
                                Button(action: {
                                    Task{
                                        self.showCustomerPicker = true
                                    }
                                }, label: {
                                    ZStack{
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color.green)
                                    }
                                })
                                .padding(10)
                                //                                .fullScreenCover(isPresented: $showCustomerPicker, content: {
                                //                                    VStack{
                                //                                        HStack{
                                //                                            Spacer()
                                //                                            Button(action: {
                                //                                                showCustomerPicker = false
                                //                                            }, label: {
                                //                                                Image(systemName: "xmark")
                                //                                            })
                                //                                        }
                                //                                        .padding(16)
                                //                                        CustomConfirmationDialog(actions: [
                                //                                            "New":createNew,
                                //                                            "Add Contact":addContact,
                                //                                            "Upload":uploadCustomer
                                //                                        ])
                                //
                                //                                    }
                                //                                })
                                
                                /*
                                 .fullScreenCover(isPresented: $showCustomerPicker, content: {
                                 VStack{
                                 HStack{
                                 Spacer()
                                 Button(action: {
                                 showCustomerPicker = false
                                 }, label: {
                                 Image(systemName: "xmark")
                                 })
                                 }
                                 .padding(16)
                                 AddNewCustomerView(dataService: dataService)
                                 }
                                 })
                                 */
                                
                                //DEVELOPER CHANGE BACK TO AFTER FIXING MY BUG THATS CAUSING THE SHEET
                                
                                .confirmationDialog("Select Type", isPresented: self.$showCustomerPicker, actions: {
                                    Button(action: {
                                        self.pickerType = .new
                                        self.selectedPickerType = .new
                                    }, label: {
                                        Text("New")
                                    })
                                    Button(action: {
                                        self.pickerType = .contacts
                                        self.selectedPickerType = .contacts
                                        
                                    }, label: {
                                        Text("From Contacts")
                                    })
                                    Button(action: {
                                        self.pickerType = .upload
                                        self.selectedPickerType = .upload
                                        
                                    }, label: {
                                        Text("Upload")
                                    })
                                })
                                .sheet(item: self.$pickerType,onDismiss: {
                                    print("dismiss")
                                    if selectedContact != nil {
                                        print("Show Confirmation Sheet")
                                        showConfirmationSheet = true
                                    }
                                }){ item in
                                    switch item {
                                    case .new:
                                        NavigationView{
                                            AddNewCustomerView(dataService: dataService)
                                        }
                                    case .contacts:
                                        NavigationView{
                                            if let contact = selectedContact{
                                                AddNewCustomerConfirmationScreen(dataService: dataService,contact : contact)
                                            } else {
                                                ContactPicker(selectedContact: self.$selectedContact)
                                            }
                                        }
                                    case .upload:
                                        NavigationView{
                                            if let doc = selectedDocumentUrl {
                                                UploadXLSXFileForCustomer(selectedDocumentUrl: doc)
                                            } else {
                                                DocumentPicker(filePath: self.$selectedDocumentUrl)
                                            }
                                        }
                                    }
                                }
                                
                                
                                
                                Button(action: {
                                    showSearch.toggle()
                                }, label: {
                                    ZStack{
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "magnifyingglass.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                            .foregroundColor(Color.blue)
                                    }
                                })
                                .padding(10)
                                .fullScreenCover(isPresented: $showSelectedContact,onDismiss: {
                                    //                                    selectedContact = nil
                                    self.showConfirmationSheet = true
                                }, content: {
                                    ZStack{
                                        Color.listColor.ignoresSafeArea()
                                        VStack{
                                            HStack{
                                                Spacer()
                                                Button(action: {
                                                    showSelectedContact = false
                                                    selectedContact = nil
                                                }, label: {
                                                    Image(systemName: "xmark")
                                                })
                                            }
                                            .padding(16)
                                            NavigationView{
                                                ContactPicker(selectedContact: self.$selectedContact)
                                            }
                                        }
                                    }
                                })
                                .fullScreenCover(isPresented: $showConfirmationSheet,onDismiss: {
                                    selectedContact = nil
                                }, content: {
                                    ZStack{
                                        Color.listColor.ignoresSafeArea()
                                        VStack{
                                            HStack{
                                                Spacer()
                                                Button(action: {
                                                    showConfirmationSheet = false
                                                    selectedContact = nil
                                                }, label: {
                                                    Image(systemName: "xmark")
                                                })
                                            }
                                            .padding(16)
                                            if selectedContact != nil {
                                                AddNewCustomerConfirmationScreen(dataService: dataService,contact:selectedContact!)
                                            }
                                        }
                                    }
                                })
                            }
                            if !UIDevice.isIPhone {
                                Spacer()
                            }
                        }
                    }
                    
                }
                if showSearch {
                    HStack{
                        TextField(
                            "Search",
                            text: $searchTerm
                        )
                        Button(action: {
                            searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                }
            }
        }
    }
}
