//
//  ShoppingListView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct ShoppingListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataService: ProductionDataService

    @EnvironmentObject var navigationManager : NavigationStateManager
    @EnvironmentObject var masterDataManager : MasterDataManager

    @StateObject var shoppingVM : ShoppingListViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
    }
    @State var showAddNewShoppingListItem:Bool = false
    var body: some View {
        VStack{
            ScrollView{
                personalItemList
                customerItemList
                jobItemList
            }
        }
        .toolbar{
            ToolbarItem{
                Button(action: {
                    showAddNewShoppingListItem.toggle()
                }, label: {
                    Image(systemName: "plus.square.fill")
                })
                .sheet(isPresented: $showAddNewShoppingListItem, content: {
                    AddNewItemToShoppingList(dataService: dataService)
                })
            }
        }
        .task {
            if let company = masterDataManager.selectedCompany, let user = masterDataManager.user {
                do{
                    try await shoppingVM.getAllShoppingListItemsByUserForJobs(companyId: company.id, userId: user.id)
                } catch {
                    print("failed to get All Shopping ListItems By User For Jobs")
                }
                do{
                    try await shoppingVM.getAllShoppingListItemsByUserForPersonal(companyId: company.id, userId: user.id)
                } catch {
                    print("failed to get All Shopping List Items By User For Personal")
                }
                do{
                    try await shoppingVM.getAllShoppingListItemsByUserForCustomers(companyId: company.id, userId: user.id)
                } catch {
                    print("failed to get All Shopping List Items By User For Customers")
                    print(error)
                }
            }
        }
    }
}
extension ShoppingListView {
    var personalItemList: some View {
        VStack{
            Text("List of Personal Items")
                .font(.headline)
            Divider()
            ForEach(shoppingVM.personalShoppingItems){ item in
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.shoppingListDetail(dataService: dataService), label: {
                        ShoppingListItemCardView(shoppingListItem: item)

                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedShoppingListItem = item
                    }, label: {
                        
                        ShoppingListItemCardView(shoppingListItem: item)
                    })
                }
                Divider()

            }
        }
    }
    var customerItemList: some View {
        VStack{
            Text("List of Items for Customers")
                .font(.headline)
            Divider()
            ForEach(shoppingVM.customerShoppingItems){ item in
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.shoppingListDetail(dataService: dataService), label: {
                        ShoppingListItemCardView(shoppingListItem: item)

                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedShoppingListItem = item
                    }, label: {
                        
                        ShoppingListItemCardView(shoppingListItem: item)
                    })
                }
                Divider()

            }
        }
    }
    var jobItemList: some View {
        VStack{
            Text("List of Items for Jobs")
                .font(.headline)
            Divider()
            ForEach(Array(shoppingVM.jobShoppingItems.keys)){ key in
                VStack{
                    HStack{
                        Spacer()
                        Text("\(key.id) ")
                    }
                    if let shoppingListItems = shoppingVM.jobShoppingItems[key] {
                        
                        ForEach(shoppingListItems){ data in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.shoppingListDetail(dataService: dataService), label: {
                                    ShoppingListItemCardView(shoppingListItem: data)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedShoppingListItem = data
                                }, label: {
                                    
                                    ShoppingListItemCardView(shoppingListItem: data)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
  
}
