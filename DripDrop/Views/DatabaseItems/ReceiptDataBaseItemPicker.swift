//
//  ReceiptDataBaseItemPicker.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/5/24.
//


import SwiftUI

struct ReceiptDataBaseItemPicker: View {
    //Init
    init(
        dataService:any ProductionDataServiceProtocol,
        addNewItem:Binding<Bool>,
        dBItem:Binding<DataBaseItem>
    ){
        self._addNewItem = addNewItem
        self._dBItem = dBItem
        _receiptDataBaseViewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }
    //Enviromental
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService

    //View Models Declared
    @StateObject private var viewModel = ReceiptViewModel()
    @StateObject private var techViewModel = TechViewModel()
    @StateObject private var storeViewModel = StoreViewModel()
    @StateObject private var receiptDataBaseViewModel : ReceiptDatabaseViewModel
    
    //Variables Received
    @Binding var addNewItem:Bool
    @Binding var dBItem:DataBaseItem

    //Variables Declared For Use
    @State private var searchTerm: String = ""
    @State var displayItems: [DataBaseItem] = []
    @State var showNewItem:Bool = false
    @State var quantity:String = "1"
    @State var date:Date = Date()
    @State var tech:DBUser = DBUser(id: "",email:"",firstName: "",lastName: "", exp: 0, recentlySelectedCompany: "")
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
        .alert("Please Enter Number", isPresented: $showQuantityAlert) {
            Button("OK", role: .cancel) { }
        }
        .task{
            if let selectedCompany = masterDataManager.currentCompany {
                do {
                    try await receiptDataBaseViewModel.getAllDataBaseItems(companyId: selectedCompany.id)
                    displayItems = receiptDataBaseViewModel.dataBaseItems
                } catch {
                    print(error)
                }
                do {
                    try await receiptDataBaseViewModel.getCommonDataBaseItems(companyId: selectedCompany.id)
                } catch {
                    print(error)
                }
            }
        }
        .onChange(of: quantity, perform: { quantity1 in
            if let amount = Int(quantity1) {
                quantity = String(amount)
            } else {
                quantity = "0"
            }
            
        })
        .onChange(of: searchTerm) {search in
            print(search)
            if search == "" {
                displayItems = receiptDataBaseViewModel.dataBaseItems
                
            } else {
                Task{
                    do {
                        try await receiptDataBaseViewModel.filterDataBaseList(filterTerm: search, items: receiptDataBaseViewModel.dataBaseItems)
                        displayItems = receiptDataBaseViewModel.dataBaseItemsFiltered
                        if displayItems.count != 0 {
                            dBItem = displayItems.first!
                        }
                    } catch {
                        print("Error")
                        print(error)
                    }
                }
            }
        }
  

    }
}

extension ReceiptDataBaseItemPicker {
    var header: some View {
            VStack(spacing: 20){
                VStack{
                    HStack{
                        Button(action: {
                            Task{
                                if let selectedCompany = masterDataManager.currentCompany {
                                    do {
                                        if searchTerm == "" {
                                            try await receiptDataBaseViewModel.getAllDataBaseItems(companyId: selectedCompany.id)
                                            displayItems = receiptDataBaseViewModel.dataBaseItems
                                            
                                        } else {
                                            try await receiptDataBaseViewModel.getAllDataBaseItems(companyId: selectedCompany.id)
                                            try await receiptDataBaseViewModel.filterDataBaseList(filterTerm: searchTerm, items: receiptDataBaseViewModel.dataBaseItems)
                                            displayItems = receiptDataBaseViewModel.dataBaseItemsFiltered
                                            
                                        }
                                        if displayItems.count != 0 {
                                            dBItem = displayItems.first!
                                        }
                                    } catch {
                                        print("Error")
                                        print(error)
                                    }
                                }
                            }
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                        TextField(
                            "Search",
                            text: $searchTerm
                        )
                        .autocorrectionDisabled()
                        Button(action: {
                            searchTerm = ""
                        }, label: {
                            Image(systemName: "xmark")
                        })
                    }
                    .modifier(SearchTextFieldModifier())
                    .padding(8)
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
                        dBItem = item
                        addNewItem = false
                    }, label: {
                        HStack{
                            Spacer()
                            Text(item.name + " " + item.sku)
                            Spacer()
                            if item == dBItem {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.poolGreen)
                            }
                        }
                        .padding(.horizontal,8)
                        .padding(.vertical,3)
                        .background(item == dBItem ? Color.poolBlue : Color.clear)
                        .foregroundColor(item == dBItem ? Color.white : Color.black)
                        .cornerRadius(8)
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
                            newDataBaseItemFromReceiptView(dataService: dataService, newItemView: $showNewItem, id:searchTerm)
                        })
                    } else {
                        
                        ForEach(displayItems) { item in
                            Button(action: {
                                dBItem = item
                                addNewItem = false

                            }, label: {
                                HStack{
                                    Spacer()
                                    Text(item.name + " " + item.sku)
                                    Spacer()
                                    if item == dBItem {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.poolGreen)
                                    }
                                }
                                .padding(.horizontal,8)
                                .padding(.vertical,3)
                                .background(item == dBItem ? Color.poolBlue : Color.clear)
                                .foregroundColor(item == dBItem ? Color.white : Color.black)
                                .cornerRadius(8)
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
