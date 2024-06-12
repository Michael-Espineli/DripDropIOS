//
//  ChooseLineItemView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 9/7/23.
//


import SwiftUI

struct ChooseLineItemView: View {
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    
    //View Models Declared
    @StateObject private var viewModel = ReceiptViewModel()
    @StateObject private var techViewModel = TechViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var receiptDataBaseViewModel = ReceiptDatabaseViewModel()
    
    //Variables Received
    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company
    
    @Binding var lineItems:[LineItem]
    @Binding var addNewItem:Bool
    @State var store:Vender
    
    //Variables Declared For Use
    @State private var searchTerm: String = ""
    @State var DBItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: true, color: "", size: "",UOM:.ft)
    @State var displayItems: [DataBaseItem] = []
    @State var showNewItem:Bool = false
    @State var quantity:String = "1"
    @State var date:Date = Date()
    @State var tech:DBUser = DBUser(id: "", exp: 0)
    //    @State var store:Store = Store(id: "")
    @State var storeName:String = ""
    @State var showQuantityAlert:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                    Section(content: {
                        detail
                            .padding(.leading,20)

                    }, header: {
                        header
                            .padding(.horizontal,20)

                    })
                })
                .padding(.top,20)
                .clipped()
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Dismiss")
                            .foregroundStyle(Color.red)
                    })
                }
            }
          
        }
        .alert("Please Enter Number", isPresented: $showQuantityAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            //            receiptDataBaseViewModel.removeListenerForAllDataBaseItems()
            
            //            receiptDataBaseViewModel.addListenerForAllDatabaseItems(companyId: company.id, storeId: store.id)
            do {
                try await receiptDataBaseViewModel.getAllDataBaseItems(companyId: company.id)
                displayItems = receiptDataBaseViewModel.dataBaseItems
            } catch {
                print(error)
            }
            do {
                try await receiptDataBaseViewModel.getCommonDataBaseItems(companyId: company.id)
            } catch {
                print(error)
            }
        }
        .onChange(of: searchTerm) {search in
            print(search)
            if search == "" {
                displayItems = receiptDataBaseViewModel.dataBaseItems
                
            } else {
                Task{
                    try? await receiptDataBaseViewModel.filterDataBaseList(filterTerm: search, items: receiptDataBaseViewModel.dataBaseItems)
                    displayItems = receiptDataBaseViewModel.dataBaseItemsFiltered
                    if displayItems.count != 0 {
                        DBItem = displayItems.first!
                    }
                }
            }
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
                                if searchTerm == "" {
                                    try? await receiptDataBaseViewModel.getAllDataBaseItems(companyId: company.id)
                                    displayItems = receiptDataBaseViewModel.dataBaseItems
                                    
                                } else {
                                    try? await receiptDataBaseViewModel.getAllDataBaseItems(companyId: company.id)
                                    try? await receiptDataBaseViewModel.filterDataBaseList(filterTerm: searchTerm, items: receiptDataBaseViewModel.dataBaseItems)
                                    displayItems = receiptDataBaseViewModel.dataBaseItemsFiltered
                                   
                                }
                                if displayItems.count != 0 {
                                    DBItem = displayItems.first!
                                }
                            }
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                        TextField(
                            "search",
                            text: $searchTerm
                        )
                        .padding(.vertical,8)
                        .font(.headline)
                        .autocorrectionDisabled()
                        Button(action: {
                            searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .padding(.horizontal,16)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    /*
                    if displayItems.count == 0 {
                        Button(action: {
                            showNewItem = true
                        }, label: {
                            Text("Create New Item")
                        })
                        .sheet(isPresented: $showNewItem, content: {
                            newDataBaseItemFromReceiptView(id:searchTerm, newItemView: $showNewItem)

                        })
                    } else {
                        Picker(selection: $DBItem, label: Text("")) {
                            ForEach(displayItems) { item in
                                Text(item.name + " " + item.sku).tag(item)
                            }
                        }
                    }
                     */
                }
                // Add section here to input the rate after it gets autofilled so that I can update the rate while entering invoice from Alpha
                HStack{
                    Text("Quantity : ")
                    TextField(
                        "quantity",
                        text: $quantity
                    )
                    .font(.headline)
                    .keyboardType(.decimalPad)
                    .padding(.leading,16)
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                }
                HStack{
                    Spacer()
                    Button(action: {
                        
                        let pushQuantity = quantity
                        if pushQuantity.contains("0123456789") {
                            showQuantityAlert = true
                            return
                        }
                        let pushItemId = DBItem.id
                        let pushName = DBItem.name
                        let pushPrice = DBItem.rate
                        let pushDate = date
                        let pushSku = DBItem.sku
                        
                        lineItems.append(LineItem(id: UUID().uuidString,
                                                  receiptId:"",
                                                  invoiceNum: "",
                                                  storeId:store.id,
                                                  storeName: store.name ?? "",
                                                  techId: tech.id,
                                                  techName:((tech.firstName ?? "") + " " + (tech.lastName ?? "")),
                                                  itemId: pushItemId,
                                                  name:pushName ,
                                                  price: pushPrice,
                                                  quantityString:pushQuantity,
                                                  date: pushDate,
                                                  billable: DBItem.billable,
                                                  invoiced: false,
                                                  customerId: "",
                                                  customerName: "",
                                                  sku: pushSku,
                                                  notes: ""))
                        addNewItem = false
                    }, label: {
                        HStack{
                            Text("Submit")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.poolBlue)
                                .cornerRadius(5)
                        }
                    })
                    Spacer()
                    Button(action: {
                        
                        let pushQuantity = quantity
                        if pushQuantity.contains("0123456789") {
                            showQuantityAlert = true
                            return
                        }
                        let pushItemId = DBItem.id
                        let pushName = DBItem.name
                        let pushPrice = DBItem.rate
                        let pushDate = date
                        let pushSku = DBItem.sku
                        
                        lineItems.append(LineItem(id: UUID().uuidString,
                                                  receiptId:"",
                                                  invoiceNum: "",
                                                  storeId:store.id,
                                                  storeName: store.name ?? "",
                                                  techId: tech.id,
                                                  techName:((tech.firstName ?? "") + " " + (tech.lastName ?? "")),
                                                  itemId: pushItemId,
                                                  name:pushName ,
                                                  price: pushPrice,
                                                  quantityString:pushQuantity,
                                                  date: pushDate,
                                                  billable: DBItem.billable,
                                                  invoiced: false,
                                                  customerId: "",
                                                  customerName: "",
                                                  sku: pushSku,
                                                  notes: ""))
                        searchTerm = ""
                        quantity = "1"
                        DBItem = DataBaseItem(id: "", name: "", rate: 0.00, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: false,color:"",size:"",UOM: .unit)

                    }, label: {
                        HStack{
                            Text("Submit And Add Another")
                                .foregroundColor(Color.basicFontText)
                                .padding(5)
                                .background(Color.poolGreen)
                                .cornerRadius(5)
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
            if searchTerm == "" {
                common
            }
            all
        }
    }
    var common : some View {
        VStack{
   
            Section(content: {
                ForEach(receiptDataBaseViewModel.commonDataBaseItems) { item in
                    Button(action: {
                        DBItem = item
                    }, label: {
                        HStack{
                            Text(item.name + " " + item.sku)
                                .background(item == DBItem ? Color.poolBlue : Color.clear)
                                .foregroundColor(item == DBItem ? Color.basicFontText : Color.poolBlue)
                            if item == DBItem {
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
                    if displayItems.count == 0 {
                        Button(action: {
                            showNewItem = true
                        }, label: {
                            Text("Create New Item")
                                .padding(8)
                                .background(Color.poolBlue)
                                .foregroundColor(Color.basicFontText)
                                .cornerRadius(8)
                        })
                        .sheet(isPresented: $showNewItem, content: {
                            newDataBaseItemFromReceiptView(id:searchTerm, newItemView: $showNewItem)

                        })
                    } else {
                        
                        ForEach(displayItems) { item in
                            Button(action: {
                                DBItem = item
                            }, label: {
                                HStack{
                                    Text(item.name + " " + item.sku)
                                        .background(item == DBItem ? Color.poolBlue : Color.clear)
                                        .foregroundColor(item == DBItem ? Color.basicFontText : Color.poolBlue)
                                    if item == DBItem {
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
                }, header: {
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
