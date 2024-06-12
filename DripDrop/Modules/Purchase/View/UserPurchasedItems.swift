//
//  UserPurchasedItems.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/26/24.
//


import SwiftUI

struct UserPurchasedItems: View{
    //VMs
    @EnvironmentObject var masterDataManager : MasterDataManager

    @EnvironmentObject var dataService : ProductionDataService

    @StateObject private var purchaseVM = PurchasesViewModel()
    @StateObject private var receiptViewModel = ReceiptViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var techVM = TechViewModel()


    @State private var showEditView : Bool = false
    @State private var showDetailsView : Bool = false
    @State private var selected: PurchasedItem.ID?
    @State private var purchasedItems:[PurchasedItem] = []
    @State private var sortOrder = [KeyPathComparator(\PurchasedItem.invoiceNum, order: .reverse)]
    @State private var serviceStopDetail: PurchasedItem? = nil
    
    @State var workOrderTemplate:JobTemplate = JobTemplate(id: "", name: "sum",type: "all")
    
    @State var startViewingDate: Date = Calendar.current.date(byAdding: .day, value: -200, to: Date())!
    
    @State var endViewingDate: Date =  Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    @State private var selection: PurchasedItem.ID? = nil
    
    @State var purchaseFilterOption:PurchaseFilterOptions = .billableAndNotInvoiced
    @State var purchaseSortOption:PurchaseSortOptions = .purchaseDateFirst
    @State var techIds:[String] = []
    @State var showSummary = false
    
    @State var showFilerOptions = false
    @State var showAddNew = false
    @State var showSearch = false
    @State var searchTerm:String = ""
    @State var showCustomerAssignment = false
    @State var selectedPurchase:PurchasedItem = PurchasedItem(id: "", receiptId: "", invoiceNum: "", venderId: "", venderName: "", techId: "", techName: "", itemId: "", name: "", price: 0, quantityString: "", date: Date(), billable: false, invoiced: false, customerId: "", customerName: "", sku: "", notes: "", jobId: "")
    @State var customerEntity:Customer = Customer(id: "", firstName: "", lastName: "", email: "", billingAddress: Address(streetAddress: "", city: "", state: "", zip: "",latitude: 0,longitude: 0), active: true, displayAsCompany: false, hireDate: Date(), billingNotes: "")
    
    var body: some View{
        ZStack{
            list
            icons
        }
        //Initial Loading of the purchase Items
        .task{
            if let company = masterDataManager.selectedCompany,let tech = masterDataManager.user {
                do {
                    try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: [tech.id])
                    purchasedItems = purchaseVM.purchasedItems
                    try await techVM.getAllCompanyTechs(companyId: company.id)
                } catch {
                    print(error)
                    
                }
            }
            
        }
        //Loading new Purchase Items with Change in sorting Options
        
        .onChange(of: purchaseSortOption, perform: { sort in
            Task{
                print("Change in purchaseSortOption")

                if let company = masterDataManager.selectedCompany,let tech = masterDataManager.user {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: sort, startDate: startViewingDate, endDate: endViewingDate, techIds: [tech.id])
                        purchasedItems = purchaseVM.purchasedItems
                        
                    } catch {
                        print(error)
                    }
                    
                }
            }
        })
        //Loading new Purchase Items with Change in Filter Options
        
        .onChange(of: purchaseFilterOption, perform: { filter in
            Task {
                print("Change in purchaseFilterOption")

                if let company = masterDataManager.selectedCompany,let tech = masterDataManager.user {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: filter, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: [tech.id])
                        purchasedItems = purchaseVM.purchasedItems
                        
                    } catch {
                        print(error)
                        
                    }
                }
            }
        })
        //Loading new Purchase Items with Change in Start Date
        .onChange(of: startViewingDate) { date in
            Task {
                print("Change in start date")

                if let company = masterDataManager.selectedCompany,let tech = masterDataManager.user {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: date, endDate: endViewingDate, techIds: [tech.id])
                        purchasedItems = purchaseVM.purchasedItems
                        
                    } catch {
                        print(error)
                        
                    }
                }
            }
        }
        //Loading new Purchase Items with Change in End Date
        
        .onChange(of: endViewingDate) { date in
            Task {
                print("Change in End date")
                if let company = masterDataManager.selectedCompany,let tech = masterDataManager.user {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: date, techIds: [tech.id])
                        purchasedItems = purchaseVM.purchasedItems
                        
                    } catch {
                        print(error)
                        
                    }
                }
            }
        }

        //Searches through the purchase item list
        .onChange(of: searchTerm){ term in
            if searchTerm == "" {
                purchasedItems = purchaseVM.purchasedItems
            } else {
                purchaseVM.filterPurchaseList(filterTerm: searchTerm, purchasedItems: purchaseVM.purchasedItems)
                purchasedItems = purchaseVM.filteredPurchasedItems
            }
        }

        
        .onChange(of: selection) { selected in
            print("selected Purchase")
            let purchasesObject = purchasedItems.filter{ $0.id == selected }.first
            masterDataManager.selectedPurchases = purchasesObject
            
        }
        .onChange(of: selected) { selected in
            print(selected)
            if selected != nil {
                showEditView = true
            }
        }
        .onChange(of: purchasedItems){ purchasedItemsList in
            purchaseVM.summaryOfPurchasedItems(purchasedItems: purchasedItemsList)
        }
    }
    
}
extension UserPurchasedItems {
    var list: some View{
        VStack{
            
            List(selection:$masterDataManager.selectedID){
                ForEach(purchasedItems) { item in
                    Button(action: {
                        selectedPurchase = item
                        showCustomerAssignment.toggle()
                    }, label: {
                        PurchasesCardView(item: item)
                    })
                    .sheet(isPresented: $showCustomerAssignment, onDismiss: {
                        Task{
                            if let company = masterDataManager.selectedCompany {
                                if customerEntity.id != "" {
                                    do {
                                        
                                        try await purchaseVM.updateReceiptCustomer(currentItem: selectedPurchase, newCustomer: customerEntity, companyId: company.id)
                                        customerEntity.id = ""
                                    } catch {
                                        print(error)
                                    }
                                } else {
                                    print("no Customer Selected")
                                }
                            }
                        }
                    }, content: {
                        CustomerPickerScreen(dataService: dataService, customer: $customerEntity)
                    })
                }
            }
   
            .refreshable {
                if let company = masterDataManager.selectedCompany,let user = masterDataManager.user {
                    do {
                        try await purchaseVM.filterAndSortSelected(companyId: company.id, filter: purchaseFilterOption, sort: purchaseSortOption, startDate: startViewingDate, endDate: endViewingDate, techIds: [user.id])
                        purchasedItems = purchaseVM.purchasedItems
                        
                    } catch {
                        print(error)
                        
                    }
                }
            }
        }
        
    }
    var icons: some View{
        VStack{
            Spacer()
            HStack{
                VStack{
                    Button(action: {
                        showFilerOptions.toggle()
                    }, label: {
                        
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.orange)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                            )
                    })
                    
                    .sheet(isPresented: $showFilerOptions, content: {
                        ScrollView{
                            HStack{
                                Spacer()
                                Text("Filters")
                                    .font(.title)
                                Spacer()
                                Button(action: {
                                    showFilerOptions = false
                                }, label: {
                                    Text("Dismiss")
                                        .foregroundColor(Color.red)
                                })
                            }
                            HStack{
                                Text("Start Date: ")
                                DatePicker(selection: $startViewingDate, displayedComponents: .date) {
                                }
                            }
                            HStack{
                                Text("End Date: ")
                                
                                DatePicker(selection: $endViewingDate, displayedComponents: .date) {
                                }
                            }
                            
                            
                            HStack{
                                Text("Sort : ")
                                Picker("Sort: ", selection: $purchaseSortOption) {

                                    ForEach(PurchaseSortOptions.allCases,id:\.self) {
                                        Text($0.display()).tag($0)
                                    }
                                }
                                Spacer()
                            }
                            HStack{
                                Text("Filter : ")
                                Picker("Filter:", selection: $purchaseFilterOption) {
                                    Text(PurchaseFilterOptions.billableAndInvoiced.display()).tag(PurchaseFilterOptions.billableAndInvoiced)
                                    Text(PurchaseFilterOptions.billable.display()).tag(PurchaseFilterOptions.billable)
                                    Text(PurchaseFilterOptions.billableAndNotInvoiced.display()).tag(PurchaseFilterOptions.billableAndNotInvoiced)
//
//                                    ForEach(PurchaseFilterOptions.allCases,id:\.self) {
//                                        Text($0.display()).tag($0)
//                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding(10)
                        .presentationDetents([.medium])
                    })
                    NavigationLink{
                        AddNewReceipt()
                        
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.green)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                            )
                    }
                    .padding(10)
                    Button(action: {
                        showSearch.toggle()
                    }, label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(Color.blue)
                            .background(
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(Color.white)
                            )
                    })
                    .padding(10)
                    
                }
                Spacer()
            }
            if showSearch {
                HStack{
                    TextField(
                        "CustomerName",
                        text: $searchTerm
                    )
                    .padding()
                    .background(Color.basicFontText.opacity(0.5))
                    .cornerRadius(10)
                    
                }
            }
        }
        
    }
}
