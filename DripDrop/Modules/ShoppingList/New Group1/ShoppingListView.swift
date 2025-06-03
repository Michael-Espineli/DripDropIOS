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
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                personalItemList
                customerItemList
                jobItemList
                Text("")                
                    .sheet(isPresented: $showAddNewShoppingListItem,onDismiss: {
                    Task{
                        if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
                      
                            do{
                                try await shoppingVM.getAllShoppingListItemsByUserForPersonal(companyId: company.id, userId: user.id)
                                try await shoppingVM.getAllShoppingListItemsByUserForCustomers(companyId: company.id, userId: user.id)
                                try await shoppingVM.getAllShoppingListItemsByCompanyForJobs(companyId: company.id)
                            } catch {
                                print("failed to get All Shopping List Items By User For Personal")
                            }
                        }
                    }
                }, content: {
                    ZStack{
                        Color.listColor.ignoresSafeArea()
                        VStack{
                            HStack{
                                Spacer()
                                Button(action: {
                                    showAddNewShoppingListItem.toggle()
                                }, label: {
                                    Text("X")
                                        .modifier(DismissButtonModifier())
                                })
                            }
                            .padding(.horizontal,8)
                            AddNewItemToShoppingList(dataService: dataService)
                        }
                    }
                })
            }
        }
        .fontDesign(.monospaced)
        .toolbar{
            ToolbarItem{
                Button(action: {
                    showAddNewShoppingListItem.toggle()
                }, label: {
                    Text("Add")
                        .fontDesign(.monospaced)
                    
                })

            }
        }
        .task {
            if let company = masterDataManager.currentCompany, let user = masterDataManager.user {
            
                do{
                    try await shoppingVM.getAllShoppingListItemsByUserForPersonal(companyId: company.id, userId: user.id)
                    try await shoppingVM.getAllShoppingListItemsByUserForCustomers(companyId: company.id, userId: user.id)
                    try await shoppingVM.getAllShoppingListItemsByCompanyForJobs(companyId: company.id)
                } catch {
                    print("failed to get All Shopping List Items By User")
                    print(error)

                }
            }
        }
    }
}
extension ShoppingListView {
    var personalItemList: some View {
        ShoppingList(list: shoppingVM.personalShoppingItems, header: "List of Personal Items",icon:"figure.stand.line.dotted.figure.stand")
    }
    var customerItemList: some View {
        ShoppingList(list: shoppingVM.customerShoppingItems, header: "List of Items for Customers",icon:"testtube.2")
    }
    var jobItemList: some View {
        VStack{
            HStack{
                Image(systemName: "spigot.fill")
                Spacer()
                Text("List of Items for Jobs")
                Spacer()
            }
                .font(.headline)
            Divider()
            ForEach(Array(shoppingVM.jobShoppingItems.keys)){ key in
                VStack{
                    JobIdCardView(dataService: dataService, jobId: key.id)
                    if let shoppingListItems = shoppingVM.jobShoppingItems[key] {
                        ForEach(shoppingListItems){ data in
                            if UIDevice.isIPhone {
                                NavigationLink(value: Route.shoppingListDetail(item:data,dataService: dataService), label: {
                                    ShoppingListItemCardView(dataService: dataService, shoppingListItem: data)
                                })
                            } else {
                                Button(action: {
                                    masterDataManager.selectedShoppingListItem = data
                                }, label: {
                                    ShoppingListItemCardView(dataService: dataService, shoppingListItem: data)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
  
}
struct ShoppingList: View {
    //Enviromental
    @EnvironmentObject var dataService: ProductionDataService
    @EnvironmentObject var masterDataManager : MasterDataManager

    //Received
    let list:[ShoppingListItem]
    let header:String
    let icon:String

    var body: some View {
        VStack{
            HStack{
                Image(systemName: icon)
                Spacer()
                Text(header)
                Spacer()
            }
                .font(.headline)
            Divider()
            ForEach(list){ item in
                if UIDevice.isIPhone {
                    NavigationLink(value: Route.shoppingListDetail(item:item,dataService: dataService), label: {
                        ShoppingListItemCardView(dataService: dataService, shoppingListItem: item)
                    })
                } else {
                    Button(action: {
                        masterDataManager.selectedShoppingListItem = item
                    }, label: {
                        ShoppingListItemCardView(dataService: dataService, shoppingListItem: item)
                    })
                }
                Divider()
            }
        }
    }
}
