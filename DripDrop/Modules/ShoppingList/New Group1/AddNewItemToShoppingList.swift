//
//  AddNewItemToShoppingList.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct AddNewItemToShoppingList: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    @Environment(\.dismiss) private var dismiss

    @StateObject var receiptDatabaseVM = ReceiptDatabaseViewModel()
    @StateObject var jobVM : JobViewModel
    @StateObject var shoppingVM : ShoppingListViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
    }
    @State var description:String = ""
    @State var type:ShoppingListCategory = .customer
    @State var itemType:ShoppingListSubCategory = .dataBase
    @State var quantity:String = "1"

    @State var search:String = ""
    @State var name:String = ""

    @State var jobSearch:String = ""

    @State var selectCustomer:Bool = false

    @State var dataBaseItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .chems,subCategory: .bushing, description: "", dateUpdated: Date(), sku: "", billable: false, color: "", size: "",UOM:.ft)
    @State var customer:Customer = Customer(id: "", firstName: "", lastName: "", email: "", billingAddress: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0), active: true, displayAsCompany: true, hireDate: Date(), billingNotes: "")
    @State var job:Job = Job(
        id: "",
        type: "",
        dateCreated: Date(),
        description: "",
        operationStatus: .estimatePending,
        billingStatus: .draft,
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceStopIds: [],
        adminId: "",
        adminName: "",
        jobTemplateId: "",
        installationParts: [],
        pvcParts: [],
        electricalParts: [],
        chemicals: [],
        miscParts: [],
        rate: 0,
        laborCost: 0
    )
    var body: some View {
        VStack{
            ScrollView{
                form
            }
        }
        .padding(10)
               .navigationTitle("Add Item To Shopping List")
            .toolbar{
                ToolbarItem{
                    submitButton
                }
            }
            .task {
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await receiptDatabaseVM.getAllDataBaseItems(companyId: company.id)
                        try await jobVM.getAllWorkOrders(companyId: company.id)
                        if receiptDatabaseVM.dataBaseItems.count != 0 {
                            dataBaseItem = receiptDatabaseVM.dataBaseItems.first!
                        }
                    } catch {
                        
                    }
                }
            }
            .onChange(of: dataBaseItem, perform: { item in
                if item.id != "" {
                    name = item.name
                }
                
            })
            .onChange(of: search, perform: { term in
                Task{
                    if term != "" {
                        if let company = masterDataManager.selectedCompany {
                            do {
                                try await receiptDatabaseVM.filterDataBaseList(filterTerm: term, items: receiptDatabaseVM.dataBaseItems)
                                if receiptDatabaseVM.dataBaseItemsFiltered.count != 0 {
                                    dataBaseItem = receiptDatabaseVM.dataBaseItemsFiltered.first!
                                }
                            } catch {
                                print("Print")
                            }
                        }
                    }
                }
            })
            .onChange(of: jobSearch, perform: { term in
                Task{
                    if term != "" {
                        if let company = masterDataManager.selectedCompany {
                                jobVM.filterWorkOrderList(filterTerm: term, workOrders: jobVM.workOrders)
                         
                        }
                    }
                }
            })

    }
}

extension AddNewItemToShoppingList{
    var form: some View {
        VStack{
      
                Text("Add Item to Shopping List")
                Text(fullDate(date: Date()))
                HStack{
                    Picker("Type", selection: $type) {
                        ForEach(ShoppingListCategory.allCases,id:\.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                switch type {
                case .customer:
                    customerItem
                case .personal:
                    personalItem
                case .job:
                    jobItem
                default:
                    customerItem
                }
                itemSelector
            quantityInput
                submitButton
            }
    }
    var customerItem: some View {
        HStack{
            Text("\(customer.firstName) \(customer.lastName)")
            Button(action: {
                selectCustomer.toggle()
            }, label: {
                if customer.id == "" {
                    Text("Select Customer")
                } else {
                    Text("Change Customer")
                }
            })
            .foregroundColor(Color.basicFontText)
            .padding(5)
            .background(Color.accentColor)
            .cornerRadius(5)
            .padding(5)
            .sheet(isPresented: $selectCustomer, content: {
                CustomerPickerScreen(dataService: dataService, customer: $customer)
            })
        }
    }
    var personalItem: some View {
        VStack{
            Text("Personal")
        }
    }
    var jobItem: some View {
        VStack{
            Text("Job")
            HStack{
                TextField(
                    text: $jobSearch,
                    prompt: Text("Search"),
                    label: {
                        Text("Search: ")
                    })
                if jobSearch == "" {
                    HStack{
                        Picker("", selection: $job) {
                            ForEach(jobVM.filteredWorkOrders) {
                                Text("\($0.id) : \($0.customerName)").tag($0)
                            }
                        }
                    }
                } else {
                    HStack{
                        Picker("", selection: $dataBaseItem) {
                            ForEach(jobVM.workOrders) {
                                Text("\($0.id) : \($0.customerName)").tag($0)
                            }
                        }
                    }
                }
            }
        }
    }
    var itemSelector: some View {
        VStack{
            HStack{
                Picker("Item Type", selection: $itemType) {
                    ForEach(ShoppingListSubCategory.allCases,id:\.self) { category in
                        Text(category.rawValue).tag(category)
                    }

                }
                .pickerStyle(.segmented)
            }
            switch itemType {
            case .chemical:
                chemicalView
            case .part:
                partView
            case .custom:
                custom
            case .dataBase:
                datBaseItemView
            default:
                customerItem
            }
 
        }
    }
    var submitButton: some View {
        Button(action: {
            Task{
                if let company = masterDataManager.selectedCompany,let user = masterDataManager.user {

                    do {
                        let customerName = customer.firstName + " " + customer.lastName
                        let purchaserName = (user.firstName ?? "") + " " + (user.lastName ?? "")
                        try await shoppingVM.addNewShoppingListItemWithValidation(companyId: company.id,
                                                                                  datePurchased: Date(),
                                                                                  category: type,
                                                                                  subCategory: itemType,
                                                                                  purchaserId: user.id,
                                                                                  itemId: dataBaseItem.id,
                                                                                  quantiy: quantity,
                                                                                  description: description,
                                                                                  jobId: job.id,
                                                                                  customerId: customer.id,
                                                                                  customerName: customerName,
                                                                                  purchaserName: purchaserName,
                                                                                  name: name)
                        dismiss()

                    } catch {
                        print("Error Uploading New shopping List Item")
                    }
                }
            }
        }, label: {
            Text("Submit")
                .foregroundColor(Color.basicFontText)
                .padding(5)
                .background(Color.accentColor)
                .cornerRadius(5)
                .padding(5)
        })
    }
    var datBaseItemView: some View {
        VStack{
            HStack{
                Button(action: {
                    print("Refresh")
                }, label: {
                    Image(systemName: "magnifyingglass.circle")
                })
                TextField(
                    text: $search,
                    prompt: Text("Search"),
                    label: {
                        Text("Search: ")
                    })
                Button(action: {
                    search = ""
                }, label: {
                    Image(systemName: "xmark")
                })
            }
            if search == "" {
                HStack{
                    Picker("Item: ", selection: $dataBaseItem) {
                        ForEach(receiptDatabaseVM.dataBaseItems) {
                            Text("\($0.name) - \($0.category.rawValue) - \($0.subCategory.rawValue)").tag($0)
                        }
                    }
                }
      
            } else {
                HStack{
                    Picker("Item: ", selection: $dataBaseItem) {
                        ForEach(receiptDatabaseVM.dataBaseItemsFiltered) {
                            Text("\($0.name) - \($0.category.rawValue) - \($0.subCategory.rawValue)").tag($0)
                        }
                    }
                }
            }
        }
       
    }
    var chemicalView: some View {
        VStack{
            Text("chemicalView")
        }
    }
    var partView: some View {
        VStack{
            Text("partView")

        }
    }
    var custom: some View {
        VStack{
            nameInput
        }
    }
    var nameInput: some View {
        VStack{
            TextField(
                text: $name,
                prompt: Text("Name"),
                label: {
                    Text("Name: ")
                })
        }
    }
    var quantityInput: some View {
        VStack{
            TextField(
                text: $quantity,
                prompt: Text("Quantity"),
                label: {
                    Text("Quantity: ")
                })
            .keyboardType(.decimalPad)
        }
    }
}
