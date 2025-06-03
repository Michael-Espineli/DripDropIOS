//
//  ChooseLineItemView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/7/23.
//


import SwiftUI
@MainActor
final class ChooseLineItemViewModel:ObservableObject{

    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published var searchTerm:String = ""
    @Published var DBItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: true, color: "", size: "",UOM:.ft)
    @Published private(set) var dataServiceDisplayItems: [DataBaseItem] = []
    @Published private(set) var commonDataBaseItems: [DataBaseItem] = []

    @Published var displayItems: [DataBaseItem] = []
    @Published var showNewItem:Bool = false
    @Published var quantityStr:String = "1"
    @Published var quantity:Int = 1

    @Published var date:Date = Date()
    @Published var storeName:String = ""
    @Published var showQuantityAlert:Bool = false

    @Published var tech:DBUser = DBUser(
        id: "",
        email:"",
        firstName: "",
        lastName: "",
        exp: 0,recentlySelectedCompany: ""
    )
    @Published var companyUser:CompanyUser = CompanyUser(
        id: "",
        userId: "",
        userName: "",
        roleId: "",
        roleName: "",
        dateCreated: Date(),
        status: .active,
        workerType: .contractor,
        linkedCompanyId: "",
        linkedCompanyName: ""
    )
    func onLoad(companyId:String) async throws {
        self.dataServiceDisplayItems = try await DatabaseManager.shared.getAllDataBaseItems(companyId: companyId)
        self.displayItems = dataServiceDisplayItems
        self.commonDataBaseItems = try await DatabaseManager.shared.getCommonDataBaseItems(companyId: companyId)
    }
    func filterDataBaseList() {
        //very facncy Search Bar
        if searchTerm != "" {
            var filteredListOfCustomers:[DataBaseItem] = []
            for item in dataServiceDisplayItems {
                let rateString = String(item.rate)
                
                if item.sku.lowercased().contains(
                    searchTerm.lowercased()
                ) || item.name.lowercased().contains(
                    searchTerm.lowercased()
                ) || rateString.lowercased().contains(
                    searchTerm.lowercased()
                ) || item.description.lowercased().contains(
                    searchTerm.lowercased()
                ) {
                    filteredListOfCustomers.append(item)
                }
            }
            self.displayItems = filteredListOfCustomers
            if !filteredListOfCustomers.isEmpty {
                self.DBItem = filteredListOfCustomers.first!
            }
        } else {
            self.displayItems = dataServiceDisplayItems
        }
    }
}
struct ChooseLineItemView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService : ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager
    //View Models Declared
    @StateObject private var VM : ChooseLineItemViewModel
    
    init(
        dataService: any ProductionDataServiceProtocol,
        lineItems:Binding<[LineItem]>,
        addNewItem:Binding<Bool>,
        store:Vender,
        companyUser:CompanyUser
    ) {
        _VM = StateObject(wrappedValue: ChooseLineItemViewModel(dataService: dataService))
        self._lineItems = lineItems
        self._addNewItem = addNewItem
        _store = State(wrappedValue: store)
        _companyUser = State(wrappedValue: companyUser)
    }
    
    @Binding var lineItems:[LineItem]
    @Binding var addNewItem:Bool
    @State var store:Vender
    @State var companyUser:CompanyUser

    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        detail
                            .padding(.leading,20)

                    }, header: {
                        HStack{
                            Spacer()
                            Button(action: {
                                dismiss()
                            }, label: {
                                Image(systemName: "xmark")
                                    .modifier(DismissButtonModifier())
                            })
                        }
                        header
                            .padding(16)
                    })
                })
                .padding(.top,20)
                .clipped()
  
            }
          
        }
        .alert("Please Enter Number", isPresented: $VM.showQuantityAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            if let currentCompany = masterDataManager.currentCompany {
                do {
                    try await VM.onLoad(companyId: currentCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: VM.quantityStr, perform: { quantity1 in
            if let amount = Int(quantity1) {
                VM.quantityStr = String(amount)
                VM.quantity = amount
            } else {
                VM.quantityStr = "0"
                VM.quantity = 0

            }
            
        })
        .onChange(of: VM.searchTerm) {search in
            VM.filterDataBaseList()
        }
    }
}

extension ChooseLineItemView {
    var header: some View {
            VStack(spacing: 20){
                VStack{
                    HStack{
                        Button(action: {
                            Task{
                                if let currentCompany = masterDataManager.currentCompany {
                                    do {
                                        try await VM.onLoad(companyId: currentCompany.id)
                                    } catch {
                                        print(error)
                                    }
                                }
                            }
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                        TextField(
                            "search",
                            text: $VM.searchTerm
                        )
                        .foregroundColor(Color.basicFontText)
                        .autocorrectionDisabled()
                        Button(action: {
                            VM.searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .modifier(SearchTextFieldModifier())
                    .padding(8)
                }
                // Add section here to input the rate after it gets autofilled so that I can update the rate while entering invoice from Alpha
                HStack{
                    Text("Quantity : ")
                    TextField(
                        "quantity",
                        text: $VM.quantityStr
                    )
                    .font(.headline)
                    .keyboardType(.decimalPad)
                    .padding(.leading,16)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    Button(action: {
                        VM.quantityStr = "0"
                    }, label: {
                        Image(systemName: "x.square")
                            .modifier(DismissButtonModifier())
                    })
                    VStack{
                        HStack{
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount += 1
                                    VM.quantity = amount
                                    VM.quantityStr = String(amount)
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "plus")
                                    Text("1")
                                }
                                    .modifier(SubmitButtonModifier())
                            })
                            .padding(3)
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount += 5
                                    VM.quantity = amount
                                    VM.quantityStr = String(amount)
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "plus")
                                    Text("5")
                                }
                                    .modifier(SubmitButtonModifier())
                            })
                            .padding(3)
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount += 10
                                    VM.quantity = amount
                                    VM.quantityStr = String(amount)
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "plus")
                                    Text("10")
                                }
                                    .modifier(SubmitButtonModifier())
                            })
                            .padding(3)
                        }
                        HStack{
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount -= 1
                                    if amount >= 0 {
                                        VM.quantityStr = String(amount)
                                        VM.quantity = amount

                                    } else {
                                        VM.quantityStr = "0"
                                        VM.quantity = 0
                                    }
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "minus")
                                    Text("1")
                                }
                                    .modifier(DismissButtonModifier())
                            })
                            .padding(3)
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount -= 5
                                    if amount >= 0 {
                                        VM.quantityStr = String(amount)
                                        VM.quantity = amount

                                    } else {
                                        VM.quantityStr = "0"
                                        VM.quantity = 0
                                    }
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "minus")
                                    Text("5")
                                }
                                    .modifier(DismissButtonModifier())
                            })
                            .padding(3)
                            Button(action: {
                                if var amount = Int(VM.quantityStr) {
                                    amount -= 10
                                    if amount >= 0 {
                                        VM.quantityStr = String(amount)
                                        VM.quantity = amount

                                    } else {
                                        VM.quantityStr = "0"
                                        VM.quantity = 0
                                    }
                                }
                            }, label: {
                                HStack{
                                    Image(systemName: "minus")
                                    Text("10")
                                }
                                    .modifier(DismissButtonModifier())
                            })
                            .padding(3)
                        }
                    }
                }
                HStack{
                    Spacer()
                    Button(action: {
                        
                        let pushQuantity = String(VM.quantity)
                        let pushItemId = VM.DBItem.id
                        let pushName = VM.DBItem.name
                        let pushPrice = VM.DBItem.rate
                        let pushDate = VM.date
                        let pushSku = VM.DBItem.sku
                        
                        lineItems.append(LineItem(id: UUID().uuidString,
                                                  receiptId:"",
                                                  invoiceNum: "",
                                                  storeId:store.id,
                                                  storeName: store.name ?? "",
                                                  techId: companyUser.userId,
                                                  techName:companyUser.userName,
                                                  itemId: pushItemId,
                                                  name:pushName ,
                                                  price: pushPrice,
                                                  quantityString:pushQuantity,
                                                  date: pushDate,
                                                  billable: VM.DBItem.billable,
                                                  invoiced: false,
                                                  customerId: "",
                                                  customerName: "",
                                                  sku: pushSku,
                                                  notes: ""))
                        addNewItem = false
                    }, label: {
                        HStack{
                            Text("Submit")
                                .modifier(SubmitButtonModifier())

                        }
                    })
                    Spacer()
                    Button(action: {
                        
                        let pushQuantity = String(VM.quantity)
                        let pushItemId = VM.DBItem.id
                        let pushName = VM.DBItem.name
                        let pushPrice = VM.DBItem.rate
                        let pushDate = VM.date
                        let pushSku = VM.DBItem.sku
                        
                        lineItems.append(LineItem(id: UUID().uuidString,
                                                  receiptId:"",
                                                  invoiceNum: "",
                                                  storeId:store.id,
                                                  storeName: store.name ?? "",
                                                  techId: companyUser.userId,
                                                  techName:companyUser.userName,
                                                  itemId: pushItemId,
                                                  name:pushName ,
                                                  price: pushPrice,
                                                  quantityString:pushQuantity,
                                                  date: pushDate,
                                                  billable: VM.DBItem.billable,
                                                  invoiced: false,
                                                  customerId: "",
                                                  customerName: "",
                                                  sku: pushSku,
                                                  notes: ""))
                        VM.searchTerm = ""
                        VM.quantityStr = "1"
                        VM.quantity = 1

                        VM.DBItem = DataBaseItem(
                            id: "",
                            name: "",
                            rate: 0.00,
                            storeName: "",
                            venderId: "",
                            category: .misc,
                            subCategory: .misc,
                            description: "",
                            dateUpdated: Date(),
                            sku: "",
                            billable: false,
                            color:"",
                            size:"",
                            UOM: .unit
                        )
                        
                    },
                           label: {
                        HStack{
                            Text("Submit And Add Another")
                                .modifier(SubmitButtonModifier())
                        }
                    })
                    Spacer()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.listColor)
    }
    var detail : some View {
        VStack{
            if VM.searchTerm == "" {
                common
            }
            all
        }
    }
    var common : some View {
        VStack{
   
            Section(content: {
                ForEach(VM.commonDataBaseItems) { item in
                    Button(action: {
                        VM.DBItem = item
                    }, label: {
                        HStack{
                            Text(item.name + " - " + item.sku)
                                .padding(.horizontal,8)
                                .padding(.vertical,3)
                                .background(item == VM.DBItem ? Color.poolYellow : Color.clear)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(8)
                            if item == VM.DBItem {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.poolGreen)
                            }
                            Spacer()
                        }
                        .padding(.leading,8)
                        .frame(maxWidth: .infinity)
                    })
                    Divider()
                }
            }, header: {
                HStack{
                    Text("Common Items")
                        .font(.headline)
                    Spacer()
                }
                Divider()

            })
          
        }
    }
        var all : some View {
            VStack{
                Section(content: {
                    if VM.displayItems.count == 0 {
                        Button(action: {
                            VM.showNewItem = true
                        }, label: {
                            Text("Create New Item")
                                .padding(8)
                                .background(Color.poolBlue)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(8)
                        })
                        .sheet(isPresented: $VM.showNewItem,content: {
                            newDataBaseItemFromReceiptView(
                                dataService: dataService,
                                newItemView: $VM.showNewItem,
                                id:VM.searchTerm
                            )
                        })
                    } else {
                        
                        ForEach(VM.displayItems) { item in
                            Button(action: {
                                VM.DBItem = item
                            }, label: {
                                HStack{
                                    Text(item.name + " - " + item.sku)
                                        .padding(.horizontal,8)
                                        .padding(.vertical,3)
                                        .background(item == VM.DBItem ? Color.poolYellow : Color.clear)
                                        .foregroundColor(Color.basicFontText)
                                        .cornerRadius(8)
                                    if item == VM.DBItem {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.poolGreen)
                                    }
                                    Spacer()
                                }
                                .padding(.leading,8)
                                .frame(maxWidth: .infinity)
                            })
                            Divider()
                        }
                    }
                },
                        header: {
                    HStack{
                        Text("All Items")
                            .font(.headline)
                        Spacer()
                    }
                    Divider()
                })
            }
        }
}
