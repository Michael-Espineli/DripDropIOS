//
//  AddNewReceipt.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 7/22/23.
//

import SwiftUI
import Darwin

struct AddNewReceipt: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    
    @StateObject private var viewModel = ReceiptViewModel()
    @StateObject private var techViewModel = TechViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var receiptDataBaseViewModel = ReceiptDatabaseViewModel()
    //DEV get ride of later
    @State var user:DBUser = DBUser(id: "1", exp: 0)
    @State var showSignInView:Bool = false
    
    
    @State var invoiceNum:String = ""
    @State var date:Date = Date()
    @State var storeId:String = ""
    @State var storeName:String = ""
    @State var store:Vender = Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))
    @State var tech:DBUser = DBUser(id: "", exp: 0)
    @State var techId:String = ""
    @State var techName:String = ""
    
    @State var quantity:String = ""
    
    @State var linequantity = ""
    @State var linename = ""
    @State var linerate = ""
    @State var linetotal = ""
    
    @State var lineItems:[LineItem] = []
    @State var displayItems: [DataBaseItem] = []
    @State var lineItem:LineItem = LineItem(id: UUID().uuidString,receiptId:"", invoiceNum: "",storeId:"", storeName: "", techId: "", techName: "", itemId: "", name: "", price: 0.00, quantityString:"", date: Date(),billable: true,invoiced: false,customerId: "",customerName: "",sku: "",notes:"")
    
    @State private var pickerSelection: String = ""
    @State private var searchTerm: String = ""
    @State private var showingAlert = false
    
    @State private var alertMessage:String = ""
    
    
    @State private var showNewItem = false
    @State private var addItemToReceipt = false
    
    @State private var editLineItem = false
    @State private var editDataBaseItem = false
    
    
    var filteredItems: [DataBaseItem] {
        receiptDataBaseViewModel.dataBaseItems.filter {
            searchTerm.isEmpty ? true : $0.name.lowercased().contains(searchTerm.lowercased())
        }
    }
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            VStack{
                if UIDevice.isIPhone {
                    ScrollView{
                        LazyVStack(alignment: .center, pinnedViews: [.sectionHeaders], content: {
                            Section(content: {
                                
                                listOfItems
                                    .padding(.leading,20)
                                
                            }, header: {
                                receipt
                            })
                        })
                        .padding(.top,20)
                        .clipped()
                    }
                } else {
                    HStack{
                        receipt
                            .padding(5)
                        Divider()
                        //                search
                        listOfItems
                            .border(.gray, width: 2)
                            .padding(5)
                    }
                    Spacer()
                }
            }
            .padding(5)
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $addItemToReceipt, content: {
            ChooseLineItemView(showSignInView: $showSignInView, user: user,company: masterDataManager.selectedCompany!, lineItems: $lineItems,addNewItem:$addItemToReceipt, store: store)
//                .presentationDetents([.medium])
        })
        .toolbar{
            button
        }
        .onChange(of: searchTerm) {search in
            print(search)
            if search == "" {
                displayItems = receiptDataBaseViewModel.dataBaseItems
                
            } else {
                Task{
                    try? await receiptDataBaseViewModel.filterDataBaseList( filterTerm: search, items: receiptDataBaseViewModel.dataBaseItems)
                    displayItems = receiptDataBaseViewModel.dataBaseItemsFiltered
                    
                }
            }
        }
        .onChange(of: store) {newValue in
            storeName = store.name ?? "something"
            print("Store Changed")
            Task{
                if let company = masterDataManager.selectedCompany {
                    do {
                        try await receiptDataBaseViewModel.removeListenerForAllDataBaseItems()
                        
                        try await receiptDataBaseViewModel.addListenerForAllDatabaseItems(companyId: company.id, storeId: store.id)
                        sleep(1)
                        displayItems = receiptDataBaseViewModel.dataBaseItems
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .task{
            if let company = masterDataManager.selectedCompany{
                do {
                    try await techViewModel.getAllCompanyTechs(companyId: company.id)
                    if techViewModel.techList.count != 0 {
                        tech = techViewModel.techList.first!
                    }
                    try await storeViewModel.getAllStores(companyId: company.id)
                    if storeViewModel.stores.count != 0 {
                        store = storeViewModel.stores.first!
                    }
                } catch {
                    print("Error Gettings Compay Tecgs")
                }
            }
        }
        .alert("Please use Numbers where appropriate", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .navigationTitle("New Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackground()
        .onDisappear(perform: {
            Task{
                try? await receiptDataBaseViewModel.removeListenerForAllDataBaseItems()
            }
        })
        
    }
    func deleteLineItem(at offsets: IndexSet) {
        lineItems.remove(atOffsets: offsets)
    }
}

extension AddNewReceipt {
    var button: some View{
        Button(action: {
            if store.id == "" {
                alertMessage = "Please Select Store"
                print(alertMessage)
                showingAlert = true
                return
                
            }
            if tech.id == "" {
                alertMessage = "Please Select Tech"
                print(alertMessage)
                showingAlert = true
                return
                
            }
            if lineItems.count == 0 {
                alertMessage = "Please Add Items to Receive"
                print(alertMessage)
                showingAlert = true
                return
                
            }
            
            let pushInvoiceNum = invoiceNum
            let pushStoreId = store.id
            let pushStoreName = store.name
            
            let pushDate = date
            let pushTechId = tech.id
            let pushTechName = (tech.firstName ?? "") + " " + (tech.lastName ?? "")
            
            let pushLineItems = lineItems
            Task{
                do {
                    try await viewModel.addNewReceipt(companyId: masterDataManager.selectedCompany!.id,receipt: Receipt(id: UUID().uuidString,invoiceNum: pushInvoiceNum,date: pushDate,storeId: pushStoreId,storeName: pushStoreName,tech: pushTechName,techId: pushTechId,purchasedItemIds:[],numberOfItems:0,cost:0,costAfterTax:0),date: pushDate,lineItems: pushLineItems)
                    tech = DBUser(id: "", exp: 0)
                    invoiceNum = ""
                    techId = ""
                    searchTerm = ""
                    quantity = ""
                    lineItems = []
                    alertMessage = "Sucessfully Uploaded"
                    print(alertMessage)
                    showingAlert = true
                } catch {
                    alertMessage = "Failure to upload Receipt"
                    print(alertMessage)
                    showingAlert = true
                    return
                }
            }

        }, label: {
            Text("Save")
                .foregroundColor(Color.white)
                .padding(5)
                .background(Color.blue)
                .cornerRadius(5)
        })
    }
    var receipt: some View {
            VStack{
                DatePicker("Purchase Date: ", selection: $date, in: ...Date(),displayedComponents: .date)

                HStack{
                    Text("Refrence: ")
                    TextField(
                        "Refrence",
                        text: $invoiceNum
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                    Spacer()
                }
                HStack{
                    Text("Vender: ")
                    Spacer()
                    Picker("", selection: $store) {
                        Text("Pick store")
                        ForEach(storeViewModel.stores) {
                            Text($0.name ?? "no Name").tag($0)
                        }
                    }
                    Spacer()
                }
                HStack{
                    Text("Tech: ")
                    Spacer()
                    Picker("", selection: $tech) {
                        Text("Pick Tech")
                        ForEach(techViewModel.techList) {
                            Text(($0.firstName ?? "no Name") + " " +  ($0.lastName ?? "no Name")).tag($0)
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            .background(Color.listColor)
        
        
    }
    
    var listOfItems : some View{
        VStack{
            HStack{
                Text("Items")
                    .font(.headline)
            }
            .padding(5)
            Spacer()
            if lineItems.count == 0 {
                HStack{
                    
                    Spacer()
                    Button(action: {
                        if store.id == "" {
                            alertMessage = "Please Select Store"
                            print(alertMessage)
                            showingAlert = true
                            return
                        }
                        addItemToReceipt = true
                    }, label: {
                        Text("Add First Item To Receipt")
                            .foregroundColor(Color.basicFontText)
                            .padding(8)
                            .background(Color.poolBlue)
                            .cornerRadius(8)
                    })
                    Spacer()
                }
                Spacer()
            } else {
                HStack{
                    
                    Spacer()
                    Button(action: {
                        if store.id == "" {
                            alertMessage = "Please Select Store"
                            print(alertMessage)
                            showingAlert = true
                            return
                        }
                        addItemToReceipt = true
                    }, label: {
                        Text("Add Another")
                            .foregroundColor(Color.basicFontText)
                            .padding(5)
                            .background(Color.poolBlue)
                            .cornerRadius(5)
                    })
                    Spacer()
                }

                    
                    ForEach($lineItems){ line in
                        HStack{
                            ReceiptLineItemView(showSignInView: $showSignInView, user: user, company: masterDataManager.selectedCompany!, line: line)
                            Button(action: {
                                lineItems.removeAll(where: {$0.id == line.id})
                            }, label: {
                                ZStack{
                                    Image(systemName: "circlebadge.fill")
                                        .foregroundColor(Color.white)
                                    Image(systemName: "trash")
                                        .foregroundColor(Color.red)
                                }
                            })
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        Divider()
                    }
                
            }
        }
    }
    
}
