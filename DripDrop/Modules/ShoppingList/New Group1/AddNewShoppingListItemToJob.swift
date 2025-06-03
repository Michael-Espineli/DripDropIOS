//
//  AddNewShoppingListItemToJob.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/23/24.
//
//


 import SwiftUI
@MainActor
final class AddNewShoppingListItemToJobViewModel:ObservableObject{
    private var dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    
    @Published  var job: Job? = nil
    @Published private(set) var dataBaseItems: [DataBaseItem] = []
    @Published private(set) var dataBaseItemsFiltered: [DataBaseItem] = []

    func onLoad(companyId:String,jobId:String) async throws {
//        self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
//        self.dataBaseItems = try await DatabaseManager.shared.getAllDataBaseItems(companyId: companyId)
    }
    func addNewShoppingListItemWithValidation(
        companyId:String,
        datePurchased:Date?,
        category:ShoppingListCategory,
        subCategory:ShoppingListSubCategory,
        purchaserId:String,
        itemId:String?,
        quantiy:String?,
        description:String,
        jobId:String?,
        customerId:String?,
        customerName:String?,
        purchaserName:String?,
        name:String
    ) async throws{

        let id = UUID().uuidString
        //, Purchased, Installed
        let shoppingListItem = ShoppingListItem(
            id: id,
            category: category,
            subCategory: subCategory,
            status: .needToPurchase,
            purchaserId: purchaserId,
            purchaserName: purchaserName ?? "",
            genericItemId: "",
            name: name,
            description: description,
            datePurchased: datePurchased,
            quantiy: quantiy,
            jobId: jobId,
            customerId: customerId ?? "",
            customerName: customerName ?? "",
            dbItemId: itemId
        )
        try await dataService.addNewShoppingListItem(companyId: companyId, shoppingListItem: shoppingListItem)
    }
    func addNewShoppingListItemToList(
        companyId:String,
        datePurchased:Date?,
        category:ShoppingListCategory,
        subCategory:ShoppingListSubCategory,
        purchaserId:String,
        itemId:String?,
        quantiy:String?,
        description:String,
        jobId:String?,
        customerId:String?,
        customerName:String?,
        purchaserName:String?,
        name:String
    ) async throws -> ShoppingListItem {

        let id = UUID().uuidString
        //, Purchased, Installed
        let shoppingListItem = ShoppingListItem(
            id: id,
            category: category,
            subCategory: subCategory,
            status: .needToPurchase,
            purchaserId: purchaserId,
            purchaserName: purchaserName ?? "",
            genericItemId: "",
            name: name,
            description: description,
            datePurchased: datePurchased,
            quantiy: quantiy,
            jobId: jobId,
            customerId: customerId ?? "",
            customerName: customerName ?? "",
            dbItemId: itemId
        )
        return shoppingListItem
    }
    func filterDataBaseList(filterTerm:String,items:[DataBaseItem]) {
        //very facncy Search Bar
        
        var dataBaseItemsFiltered:[DataBaseItem] = []
        for item in items {
            let rateString = String(item.rate)

            if item.sku.lowercased().contains(
                filterTerm.lowercased()
            ) || item.name.lowercased().contains(
                filterTerm.lowercased()
            ) || rateString.lowercased().contains(
                filterTerm.lowercased()
            ) || item.description.lowercased().contains(
                filterTerm.lowercased()
            ) {
                dataBaseItemsFiltered.append(item)
            }
        }

        self.dataBaseItemsFiltered = dataBaseItemsFiltered
    }
}
 struct AddNewShoppingListItemToJob: View {

     init(dataService:any ProductionDataServiceProtocol,job:Job){
         _VM = StateObject(wrappedValue: AddNewShoppingListItemToJobViewModel(dataService: dataService))
         _job = State(wrappedValue: job)
     }
     @Environment(\.dismiss) private var dismiss
     @EnvironmentObject var masterDataManager : MasterDataManager
     @EnvironmentObject var dataService : ProductionDataService
     
     @StateObject var VM : AddNewShoppingListItemToJobViewModel

     @State var job:Job

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
                     try await VM.onLoad(companyId: company.id, jobId: job.id)
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

 extension AddNewShoppingListItemToJob{
     var form: some View {
         VStack{
             HStack{
                 Text(fullDate(date: Date()))
                 Spacer()
                 Text(job.internalId)
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
                         try await VM.addNewShoppingListItemWithValidation(companyId: company.id,
                                                                                   datePurchased: Date(),
                                                                                   category: type,
                                                                                   subCategory: itemType,
                                                                                   purchaserId: user.id,
                                                                                   itemId: dataBaseItem.id,
                                                                                   quantiy: quantity,
                                                                                   description: description,
                                                                                   jobId: job.id,
                                                                                   customerId: job.customerId,
                                                                                   customerName: job.customerName,
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
             
         })
         .padding(.horizontal,8)
     }

 }

