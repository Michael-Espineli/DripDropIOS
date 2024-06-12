//
//  jobItemPicker.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//


import SwiftUI

struct jobItemPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var dataBaseVM = ReceiptDatabaseViewModel()
    @State var category:String
    @Binding var jobDBItems : WODBItem
    
    init(jobDBItems:Binding<WODBItem>,category:String){
        
        self._jobDBItems = jobDBItems
        _category = State(wrappedValue: category)
    }
    
    @State var dataBaseItem:DataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: true, color: "", size: "",UOM:.ft)
    @State var dataBaseItems:[DataBaseItem] = []
    
    @State var search:String = ""
    @State var quantity:String = ""

    var body: some View {
        VStack{
            if dataBaseItem.id == "" {
                dataBaseList
                searchBar
            } else {
                itemInfo
            }
        }
        .padding()
        .task {
            do {
                if let company = masterDataManager.selectedCompany {
                    if category != "" {
                        try await dataBaseVM.getAllDataBaseItemsByCategory(companyId: company.id, category: category)
                        dataBaseItems = dataBaseVM.dataBaseItems
                    }
                }
            } catch {
                print("Error")

            }
        }
        .onChange(of: search, perform: { term in
            if term == "" {
                        dataBaseItems = dataBaseVM.dataBaseItems
            } else {
                            dataBaseVM.filterDataBaseList(filterTerm: term, items: dataBaseVM.dataBaseItems)
                            dataBaseItems = dataBaseVM.dataBaseItemsFiltered

            }
        })
    }
}
extension jobItemPicker {
    var itemInfo: some View {
        VStack{
            Button(action: {
                dataBaseItem = DataBaseItem(id: "", name: "", rate: 0, storeName: "", venderId: "", category: .misc,subCategory: .misc, description: "", dateUpdated: Date(), sku: "", billable: true, color: "", size: "",UOM:.ft)
            }, label: {
                Text("Name: \(dataBaseItem.name) - \(String(dataBaseItem.rate)) - \(String(dataBaseItem.sellPrice ?? 0))")
                    
            })
            TextField(
                text: $quantity,
                label: {
                    Text("Quantity: ")
                })
            .keyboardType(.decimalPad)
            Button(action: {
                if let quantity = Double(quantity) {
                    
                    let item = WODBItem(id: UUID().uuidString, name: dataBaseItem.name, quantity: quantity, cost: dataBaseItem.rate, genericItemId: dataBaseItem.id)
                    jobDBItems = item
                }
                dismiss()
            }, label: {
                Text("Add")
            })
        }
    }
    var searchBar: some View {
        HStack{
            TextField(
                text: $search,
                label: {
                    Text("Search: ")
                })
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.black)
                .padding(.vertical, 5)
                .padding(.horizontal, 20)
                .background(Color.poolWhite)
                .clipShape(Capsule())

        }
        .foregroundColor(Color.white)
        .background(Color.darkGray)
    }
    var dataBaseList: some View {
        ScrollView{
            ForEach(dataBaseItems){ datum in
                Button(action: {
                    dataBaseItem = datum
                }, label: {
                    HStack{
                        Text("\(datum.name)")
                    }
                    .padding(5)
                    .foregroundColor(Color.basicFontText)
                    .frame(maxWidth: .infinity)
                })
             Divider()
            }
        }
    }
}
