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

    var body: some View {
        VStack{
            HStack{
                Picker("Item Type", selection: $itemType) {
                    ForEach(ShoppingListSubCategory.allCases,id:\.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                    
                }
                .pickerStyle(.segmented)
            }
            switch itemType {
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
                                    Text("Add New Item")
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
