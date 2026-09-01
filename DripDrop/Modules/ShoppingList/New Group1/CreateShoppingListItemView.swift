//
//  CreateShoppingListItemView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/22/25.
//

import SwiftUI

struct CreateShoppingListItemView: View {
    @EnvironmentObject var dataService : ProductionDataService
    @Binding var itemType : ShoppingListSubCategory
    @Binding var name : String
    @Binding var quantity : String
    @Binding var addNewItem:Bool
    @Binding var dataBaseItem:DataBaseItem
    @Binding var productItem: GenericItem

    init(
        itemType: Binding<ShoppingListSubCategory>,
        name: Binding<String>,
        quantity: Binding<String>,
        addNewItem: Binding<Bool>,
        dataBaseItem: Binding<DataBaseItem>,
        productItem: Binding<GenericItem> = .constant(.emptyProductCatalogItem)
    ) {
        _itemType = itemType
        _name = name
        _quantity = quantity
        _addNewItem = addNewItem
        _dataBaseItem = dataBaseItem
        _productItem = productItem
    }

    var body: some View {
        VStack{
            HStack{
                Picker("Item Type", selection: $itemType) {
//                    ForEach(ShoppingListSubCategory.allCases,id:\.self) { category in
//                        Text(category.rawValue).tag(category)
//                    }
                    Text(ShoppingListSubCategory.product.rawValue).tag(ShoppingListSubCategory.product)
                    Text(ShoppingListSubCategory.custom.rawValue).tag(ShoppingListSubCategory.custom)

                }
                .pickerStyle(.segmented)
            }
            switch itemType {
            case .product:
                VStack{
                    HStack{
                        Button(action: {
                            addNewItem.toggle()
                        }, label: {
                            ZStack{
                                if productItem.id == "" {
                                    Text("Select Product")
                                } else {
                                    Text(productItem.productDisplayName)
                                }
                            }
                            .modifier(AddButtonModifier())
                        })
                        Spacer()
                    }
                    .sheet(isPresented: $addNewItem, content: {
                        ProductCatalogPicker(dataService: dataService, product: $productItem, onlyPartPurchaseAvailable: true)
                    })
                }
            case .chemical:
                VStack{
                    Text("chemical View")
                }
            case .part:
                VStack{
                    Text("part View")
                    
                }
            case .custom:
                HStack{
                    Text("Name:")
                    TextField(
                        text: $name,
                        prompt: Text("Name"),
                        label: {
                            Text("Name: ")
                        })
                    .padding(3)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(3)
                    Spacer()
                }
            case .dataBase:
                VStack{
                    HStack{
                        Button(action: {
                            addNewItem.toggle()
                        }, label: {
                            ZStack{
                                if dataBaseItem.id == "" {
                                    Text("Select Vendor Item")
                                } else {
                                    Text(dataBaseItem.name)
                                }
                            }
                            .modifier(AddButtonModifier())
                        })
                        Spacer()
                    }
                    .sheet(isPresented: $addNewItem, content: {
                        ReceiptDataBaseItemPicker(dataService: dataService, addNewItem: $addNewItem, dBItem: $dataBaseItem)
                    })
                }
            }
            HStack{
                Text("Quantity:")
                TextField(
                    text: $quantity,
                    prompt: Text("Quantity"),
                    label: {
                        Text("Quantity: ")
                    })
                .padding(3)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(3)
                .keyboardType(.decimalPad)
                Spacer()
            }
        }
    }
}

//#Preview {
//    CreateShoppingListItemView()
//}
