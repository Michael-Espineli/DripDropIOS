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
    
    @StateObject var receiptDatabaseVM : ReceiptDatabaseViewModel
    @StateObject var jobVM : JobViewModel
    @StateObject var shoppingVM : ShoppingListViewModel
    
    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _receiptDatabaseVM = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))

    }
    @State var description:String = ""
    @State var type:ShoppingListCategory = .customer
    @State var itemType:ShoppingListSubCategory = .dataBase
    @State var quantity:String = "1"
    
    @State var search:String = ""
    @State var name:String = ""
    
    
    @State var selectCustomer:Bool = false
    @State var addNewItem:Bool = false
    @State var addJob:Bool = false
    @State var addUser:Bool = false

    @State var dataBaseItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .chems,subCategory: .bushing, description: "", dateUpdated: Date(), sku: "", billable: false, color: "", size: "",UOM:.ft)
    @State var customer:Customer = Customer(
        id: "",
        firstName: "",
        lastName: "",
        email: "",
        billingAddress: Address(
            streetAddress: "",
            city: "",
            state: "",
            zip: "",
            latitude: 0,
            longitude: 0
        ),
        active: true,
        displayAsCompany: true,
        hireDate: Date(),
        billingNotes: "",
        linkedInviteId: UUID().uuidString
    )
    @State var job:Job = Job(
        id: "",
        internalId: "",      
        type: "",
        dateCreated: Date(),
        description: "",
        operationStatus: .estimatePending,
        billingStatus: .draft,
        customerId: "",
        customerName: "",
        serviceLocationId: "",
        serviceStopIds: [],
        laborContractIds: [],
        adminId: "",
        adminName: "",
        rate: 0,
        laborCost: 0,
        otherCompany: false,
        receivedLaborContractId: "",
        receiverId: "",
        senderId : "",
        dateEstimateAccepted: nil,
        estimateAcceptedById: nil,
        estimateAcceptType: nil,
        estimateAcceptedNotes: nil,
        invoiceDate: nil,
        invoiceRef: nil,
        invoiceType: nil,
        invoiceNotes: nil
    )
    @State var companyUser:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
    var body: some View {
        VStack{
            ScrollView{
                form
                submitButton
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
            if let company = masterDataManager.currentCompany {
                do {
                    try await receiptDatabaseVM.getAllDataBaseItems(companyId: company.id)
                    try await jobVM.getAllWorkOrders(companyId: company.id)
                    if receiptDatabaseVM.dataBaseItems.count != 0 {
                        dataBaseItem = receiptDatabaseVM.dataBaseItems.first!
                    }
                    try await shoppingVM.getCompanyUsers(companyId: company.id)
                    //This way when any user first wants to add an item to a shopping list it selectes them first.
                    if let user = masterDataManager.user {
                        if let firstCompanyUser = shoppingVM.companyUsers.first(where: {$0.userId == user.id}) {
                            companyUser = firstCompanyUser
                        } else {
                            companyUser = shoppingVM.companyUsers.first! //Developer FIX
                        }
                    } else {
                        companyUser = shoppingVM.companyUsers.first! //Developer FIX
                    }
                } catch {
                    print("Error")
                    print(error)
                }
            }
            if let selectedCustomer = masterDataManager.selectedCustomer{
                customer = selectedCustomer
            }
        }
        .onChange(of: dataBaseItem, perform: { item in
            if item.id != "" {
                name = item.name
            }
            
        })
        .onChange(of: search, perform: { term in
            if term != "" {
                receiptDatabaseVM.filterDataBaseList(filterTerm: term, items: receiptDatabaseVM.dataBaseItems)
                if receiptDatabaseVM.dataBaseItemsFiltered.count != 0 {
                    dataBaseItem = receiptDatabaseVM.dataBaseItemsFiltered.first!
                }
            }
        })
        .onChange(of: jobVM.searchTerm, perform: { term in
            Task{
                if term != "" {
                    jobVM.filterWorkOrderList()
                }
            }
        })
        
    }
}

extension AddNewItemToShoppingList{
    var form: some View {
        VStack{
            HStack{
                Text(fullDate(date: Date()))
                Spacer()
            }
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
                
            }
            CreateShoppingListItemView(
                itemType: $itemType,
                name: $name,
                quantity: $quantity,
                addNewItem: $addNewItem,
                dataBaseItem: $dataBaseItem
            )
        }
    }
    var customerItem: some View {
        VStack(alignment:.leading){
            HStack{
                Button(action: {
                    selectCustomer.toggle()
                }, label: {
                    ZStack{
                        if customer.id == "" {
                            Text("Select Customer")
                        } else {
                            Text("\(customer.firstName) \(customer.lastName)")
                        }
                    }
                    .modifier(AddButtonModifier())
                })
                
                Spacer()
                
            }
            .sheet(isPresented: $selectCustomer, content: {
                CustomerPickerScreen(dataService: dataService, customer: $customer)
            })
        }
    }
    var personalItem: some View {
        HStack{
            Button(action: {
                addUser.toggle()

            }, label: {
                ZStack{
                    if companyUser.id == "" {
                        Text("Select User")
                    } else {
                        Text("\(companyUser.userName) - \(companyUser.roleName)")
                    }
                }
                .modifier(AddButtonModifier())
            })
            .sheet(isPresented: $addUser, content: {
                CompanyUserPicker(dataService: dataService, companyUser: $companyUser)
            })
            Spacer()
        }
    }
    var jobItem: some View {
        VStack(alignment:.leading){
            HStack{
                Button(action: {
                    addJob.toggle()
                }, label: {
                    ZStack{
                        if job.id == "" {
                            Text("Select Job")
                        } else {
                            Text("\(job.id) - \(job.customerName) - \(fullDate(date:job.dateCreated))")
                        }
                    }
                    .modifier(AddButtonModifier())
                })
                Spacer()
            }
            .sheet(isPresented: $addJob, content: {
                JobPickerScreen(dataService: dataService, job: $job)
                
            })
        }
    }

    var submitButton: some View {
        Button(action: {
            Task{
                if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                    
                    do {
                        var customerName = ""
                        if customer.firstName != "" || customer.lastName != ""{
                            customerName = customer.firstName + " " + customer.lastName
                        }
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
                        print("Sucessfully Added")
                        dismiss()
                        
                    } catch {
                        print("Error Uploading New shopping List Item")
                        print(error)
                    }
                }
            }
        }, label: {
            Text("Submit")
                .frame(maxWidth: .infinity)
                .modifier(SubmitButtonModifier())
            
                .clipShape(Capsule())
            
        })
        .padding(.horizontal,16)
    }
 
}
