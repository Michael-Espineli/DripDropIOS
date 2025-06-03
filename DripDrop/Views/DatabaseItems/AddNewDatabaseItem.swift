//
//  AddNewDatabaseItem.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/21/23.
//

import SwiftUI

struct AddNewDatabaseItem: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var masterDataManager : MasterDataManager
    init(dataService: any ProductionDataServiceProtocol){
        _viewModel = StateObject(wrappedValue: ReceiptDatabaseViewModel(dataService: dataService))
    }
    @StateObject private var viewModel : ReceiptDatabaseViewModel
    @StateObject private var storeViewModel = StoreViewModel()
 
    @State var store:Vender = Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))

    @State var name:String = ""
    @State var rate:String = ""
    @State var sellPrice:String = ""
    @State var storeId:String = ""
    @State var storeName:String = ""
    @State var category:DataBaseItemCategory = .misc
    @State var subCategory:DataBaseItemSubCategory = .misc
    @State var description:String = ""
    @State var dateUpdated:Date = Date()
    @State var billable:Bool = true
    @State var sku:String = ""
    @State var size:String = ""
    @State var UOM:UnitOfMeasurment = .unit
    @State var color:String = ""

    
    var body: some View {
        ScrollView{
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        dismiss()
                        
                    }, label: {
                        Image(systemName: "xmark")
                            .modifier(DismissButtonTextModifier())
                    })
                    .modifier(DismissButtonModifier())
                    
                }
                HStack{
                    Text("name")
                    TextField(
                        "012345",
                        text: $name
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                
                HStack{
                    Text("rate")
                    TextField(
                        "rate",
                        text: $rate
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("SellPrice")
                    TextField(
                        "SellPrice",
                        text: $sellPrice
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("Store")
                    
                    Picker("", selection: $store) {
                        Text("Pick store")
                        ForEach(storeViewModel.stores) {
                            
                            Text($0.name ?? "no Name").tag($0)
                            
                        }
                    }
                }
            }
            VStack{
                Picker("", selection: $category) {
                    Text("Pick tech").tag("Tech")
                    ForEach(DataBaseItemCategory.allCases,id:\.self) { UOM in
                        Text(UOM.rawValue).tag(UOM)
                    }
                }
                HStack{

                    Picker("", selection: $subCategory) {
                        Text("Pick tech").tag("Tech")
                        ForEach(DataBaseItemSubCategory.allCases,id:\.self) { UOM in
                            Text(UOM.rawValue).tag(UOM)
                        }
                    }
                }

                HStack{
                    Text("UOM: ")
                    Picker("", selection: $UOM) {
                        Text("Pick tech").tag("Tech")
                        ForEach(UnitOfMeasurment.allCases,id:\.self) { UOM in
                            Text(UOM.rawValue).tag(UOM)
                        }
                    }
                }
                HStack{
                    Text("size")
                    TextField(
                        "size",
                        text: $size
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("color")
                    TextField(
                        "color",
                        text: $color
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("sku")
                    TextField(
                        "sku",
                        text: $sku
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                HStack{
                    Text("description")
                    TextField(
                        "description",
                        text: $description
                    )
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    
                }
                Toggle("Billable", isOn: $billable)
            }
            Button(action: {
                Task{
                    if let company = masterDataManager.currentCompany {
                        do {
                            let pushName = name
                            let pushRate = rate
                            let pushStoreId = store.id
                            let pushStoreName = store.name
                            
                            let pushCategory = category
                            let pushDescription = description
                            let pushDateUpdated = dateUpdated
                            let pushSku = sku
                            let pushBillable = billable
                            let pushSellPrice = Double(sellPrice)
                            let pushUOM = UOM
                            let pushSize = size
                            let pushSubCategory = subCategory
                            let pushColor = color
                            
                            
                            try await viewModel.addDataBaseItem(companyId: company.id,dataBaseItem:DataBaseItem(id: UUID().uuidString,
                                                                                                                name: pushName,
                                                                                                                rate: Double(pushRate) ?? 0.00,
                                                                                                                storeName: pushStoreName ?? "Unknown",
                                                                                                                venderId: pushStoreId,
                                                                                                                category: pushCategory,
                                                                                                                subCategory: pushSubCategory,
                                                                                                                description: pushDescription,
                                                                                                                dateUpdated: pushDateUpdated,
                                                                                                                sku: pushSku,
                                                                                                                billable: pushBillable,
                                                                                                                color: pushColor,
                                                                                                                size: pushSize,
                                                                                                                UOM: pushUOM,
                                                                                                                sellPrice: pushSellPrice))
                            
                            
                            name = ""
                            rate = ""
                            storeId = ""
                            category = .misc
                            subCategory = .misc
                            UOM = .unit
                            description = ""
                            dateUpdated = Date()
                            sku = ""
                        } catch {
                            print(error)
                        }
                    }
                }
            }, label: {
                Text("Submit")
                    .modifier(SubmitButtonModifier())

            })
            
        }
        .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
        .task{
            if let company = masterDataManager.currentCompany {
                do {
                    try await storeViewModel.getAllStores(companyId:company.id)
                    if storeViewModel.stores.count != 0 {
                        store = storeViewModel.stores.first!
                    }
                } catch {
                    print(error)
                }
            }
        }
        .navigationTitle("Add Item To DataBase")
    }
    
}

