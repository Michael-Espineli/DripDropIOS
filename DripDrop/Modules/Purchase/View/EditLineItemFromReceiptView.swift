//
//  EditLineItemFromReceiptView.swift
//  Pool-Sec-Mac-V2
//
//  Created by Michael Espineli on 8/29/23.
//





import SwiftUI

struct EditLineItemFromReceiptView: View {
    @StateObject private var viewModel = ReceiptDatabaseViewModel()
    @StateObject private var storeViewModel = StoreViewModel()

    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State var company:Company

 
    @State var name:String = ""
    @State var rate:String = ""
    @State var store:Vender = Vender(id: "",address: Address(streetAddress: "", city: "", state: "", zip: "", latitude: 0, longitude: 0))

    @State var storeId:String = ""
    @State var storeName:String = ""

    @State var category:DataBaseItemCategory = .misc
    @State var subCategory:DataBaseItemSubCategory = .misc
    @State var UOM:UnitOfMeasurment = .unit

    @State var description:String = ""
    @State var dateUpdated:Date = Date()
    @State var billable:Bool = true

    @State var sku:String = ""
    @Binding var newItemView:Bool
    
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Button(action: {
                    newItemView = false
                }, label: {
                    Image(systemName: "xmark")
                })
            }
            ScrollView{
                HStack{
                    Text("name")
                    TextField(
                        "012345",
                        text: $name
                    ).padding()

                    Text("sku")
                    TextField(
                        "sku",
                        text: $sku
                    ).padding()
                }
                HStack{
                    Text("rate")
                    TextField(
                        "rate",
                        text: $rate
                    ).padding()
                    Toggle("Billable", isOn: $billable)

                }
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
                    Text("Store")
                    
                    Picker("", selection: $store) {
                        Text("Pick store")
                        ForEach(storeViewModel.stores) {
                            
                            Text($0.name ?? "no Name").tag($0)
                            
                        }
                    }
                }
                HStack{
                    Text("description")
                    TextField(
                        "description",
                        text: $description
                    ).padding()
                }
 
                
                Button(action: {
                    
                    let pushName = name
                    let pushRate = rate
                    let pushStoreId = store.id
                    let pushStoreName = store.name
                    
                    let pushCategory = category
                    let pushDescription = description
                    let pushDateUpdated = dateUpdated
                    let pushSku = sku
                    let pushBillable = billable
                    
                    
                    Task{
                        //DEVELOPER
                        try? await viewModel.addDataBaseItem(
                            companyId: company.id,
                            dataBaseItem: DataBaseItem(
                                id: UUID().uuidString,
                                name: pushName,
                                rate: Double(
                                    pushRate
                                ) ?? 0.00,
                                storeName: pushStoreName ?? "Unknown",
                                venderId: pushStoreId,
                                category: pushCategory,
                                subCategory: subCategory,
                                description: pushDescription,
                                dateUpdated: pushDateUpdated,
                                sku: pushSku,
                                billable: pushBillable,
                                color: "",
                                size: "",
                                UOM: UOM
                            )
                        )
                        newItemView = false
                    }
                    
                    name = ""
                    rate = ""
                    storeId = ""
                    category = .misc
                    description = ""
                    dateUpdated = Date()
                    sku = ""
                    
                },
                       label: {
                    Text("Submit")
                })
                
            }
        }
        .padding(.init(top: 40, leading: 20, bottom: 0, trailing: 0))
        .task{
            try? await storeViewModel.getAllStores(companyId:company.id)
        }
        .navigationTitle("Add Item To DataBase")
    }
    
}

