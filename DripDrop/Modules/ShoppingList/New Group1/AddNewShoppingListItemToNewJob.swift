//
//  AddNewShoppingListItemToNewJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/31/25.
//


 import SwiftUI

struct AddNewShoppingListItemToNewJob: View {

    init(dataService:any ProductionDataServiceProtocol,jobId:String,customerId:String,customerName:String, shoppingList:Binding<[ShoppingListItem]>){
         _VM = StateObject(wrappedValue: AddNewShoppingListItemToJobViewModel(dataService: dataService))
         _jobId = State(wrappedValue: jobId)
        _customerId = State(wrappedValue: customerId)
        _customerName = State(wrappedValue: customerName)
        self._shoppingList = shoppingList
     }
     @Environment(\.dismiss) private var dismiss
     @EnvironmentObject var masterDataManager : MasterDataManager
     @EnvironmentObject var dataService : ProductionDataService
     
     @StateObject var VM : AddNewShoppingListItemToJobViewModel

     @State var jobId: String
     @Binding var shoppingList: [ShoppingListItem]
    
     @State var customerId:String
     @State var customerName:String
    
     @State var description:String = ""
     @State var type:ShoppingListCategory = .job
     @State var itemType:ShoppingListSubCategory = .dataBase
     @State var quantity:String = "1"
     
     @State var search:String = ""
     @State var name:String = ""
     
     @State var jobSearch:String = ""
     
     @State var selectCustomer:Bool = false
     @State var addNewItem:Bool = false
     @State var addJob:Bool = false
     @State var addUser:Bool = false

     @State var dataBaseItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .chems, subCategory: .bushing, description: "", dateUpdated: Date(), sku: "", billable: false, color: "", size: "",UOM:.ft)
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

     @State var companyUser:CompanyUser = CompanyUser(id: "", userId: "", userName: "", roleId: "", roleName: "", dateCreated: Date(), status: .active, workerType: .employee)
     var body: some View {
         VStack{
             ScrollView{
                 form
                 Rectangle()
                     .frame(height: 1)
                 submitButton
             }
         }
         .padding(8)
         .navigationTitle("Add Item To Job")
         .toolbar{
             ToolbarItem{
                 submitButton
             }
         }
         .task {
             if let company = masterDataManager.currentCompany {
                 do {
                     try await VM.onLoad(companyId: company.id, jobId: jobId)
                 } catch {
                     print("Error - [AddNewShoppingListItemToJob]")
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
                 VM.filterDataBaseList(filterTerm: term, items: VM.dataBaseItems)
                 if VM.dataBaseItemsFiltered.count != 0 {
                     dataBaseItem = VM.dataBaseItemsFiltered.first!
                 }
             }
         })
     }
 }

 extension AddNewShoppingListItemToNewJob{
     var form: some View {
         VStack{
             HStack{
                 Text(fullDate(date: Date()))
                 Spacer()
//                 Text(job.internalId)
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

     var submitButton: some View {
         Button(action: {
             Task{
                 if let company = masterDataManager.currentCompany,let user = masterDataManager.user {
                     
                     do {
                         let purchaserName = (user.firstName) + " " + (user.lastName)
                         let item = try await VM.addNewShoppingListItemToList(companyId: company.id,
                                                                                   datePurchased: Date(),
                                                                                   category: type,
                                                                                   subCategory: itemType,
                                                                                   purchaserId: user.id,
                                                                                   itemId: dataBaseItem.id,
                                                                                   quantiy: quantity,
                                                                                   description: description,
                                                                                   jobId: jobId,
                                                                                   customerId: customerId,
                                                                                   customerName: customerName,
                                                                                   purchaserName: purchaserName,
                                                                                   name: name)
                         shoppingList.append(item)
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
             
         })
         .padding(.horizontal,8)
     }

 }

