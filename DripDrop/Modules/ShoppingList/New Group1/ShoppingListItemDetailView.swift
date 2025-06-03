//
//  ShoppingListItemDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ShoppingListItemDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject private var navigationManager: NavigationStateManager

    @StateObject var jobVM : JobViewModel
    @StateObject var shoppingVM : ShoppingListViewModel
    @StateObject var customerVM : CustomerViewModel
    
    init(item:ShoppingListItem,dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
        _receivedItem = State(wrappedValue: item)
    }
    
    @State var receivedItem : ShoppingListItem? = nil
    @State var shoppingListItem : ShoppingListItem? = nil
    
    @State var description:String = ""
    
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    var body: some View {
        ZStack{
            Color.listColor.ignoresSafeArea()
            ScrollView{
                info
                details
            }
        }
        .fontDesign(.monospaced)
        .task {
            shoppingListItem = receivedItem
            if let shoppingListItem {
                masterDataManager.selectedShoppingListItem = shoppingListItem
                description = shoppingListItem.description
            }
        }
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Please Confirm Delete"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        print("Deleting...")
                        if let company = masterDataManager.currentCompany, let item = masterDataManager.selectedShoppingListItem {
                            do {
                                try await shoppingVM.deleteShoppingListItem(companyId: company.id, shoppingListItemId: item.id)
                                print("Successfully Deleted")
                                navigationManager.routes.removeLast()
                                masterDataManager.selectedShoppingListItem = nil
                            } catch {
                                print(error)
                            }
                        } else {
                            print("Not Selected Propperly Company or Shopping List item")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .onChange(of: masterDataManager.selectedShoppingListItem, perform: { item in
            shoppingListItem = item
            if let shoppingListItem {
                description = shoppingListItem.description
            }
        })
        .onChange(of: description, perform:{ datum in
            Task{
                if let selectedCompany = masterDataManager.currentCompany ,let item = shoppingListItem {
                    if datum != item.description {
                        print("Developer Add Change Info")
                        do {
                            try await shoppingVM.updateShoppingListDescription(companyId: selectedCompany.id, shoppingListItemId: item.id, newDescription: datum)
                            shoppingListItem?.description = datum
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                }
            }
        })
    }
}

struct ShoppingListItemDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ShoppingListItemDetailView(item: MockDataService.mockShoppingListItem, dataService: dataService)
    }
}
extension ShoppingListItemDetailView {
    var info: some View {
        VStack{
            if let shoppingListItem = shoppingListItem {
                HStack{
                    Spacer()
                    Text("Status: ")
                    switch shoppingListItem.status {
                    case .installed:
                        Text("\(shoppingListItem.status.rawValue)")
                            .padding(5)
                            .background(Color.green)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(5)
                    case .purchased:
                        Text("\(shoppingListItem.status.rawValue)")
                            .padding(5)
                            .background(Color.yellow)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                            .padding(5)
                    case .needToPurchase:
                        Text("\(shoppingListItem.status.rawValue)")
                            .padding(5)
                            .background(Color.poolRed)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                            .padding(5)
                    }
                }
                Text("\(shoppingListItem.name)")
                    .bold(true)
                if let date = shoppingListItem.datePurchased {
                    Text("\(fullDate(date:date ))")
                }
                Text("\(shoppingListItem.purchaserName)")
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.darkGray)
        .foregroundColor(Color.white)
    }
    var details: some View {
        VStack{
            if let shoppingListItem = shoppingListItem {
                category
                HStack{
                    Text("Description")
                    TextField(
                        "Description",
                        text: $description,
                        axis: .vertical
                    )
                    .padding(5)
                    .background(Color.white)
                    .foregroundColor(Color.basicFontText)
                    .cornerRadius(5)
                    .padding(5)
                }
                if let quantiy = shoppingListItem.quantiy {
                    Text("Qunatity: \(quantiy)")
                }

            }
        }
        .padding(8)
    }
    var category: some View {
        VStack{
            if let shoppingListItem = shoppingListItem {
                
                switch shoppingListItem.category {
                case .personal:
                    Text("Personal")
                    Text("Category: \(shoppingListItem.category.rawValue)")
                    Text("Sub-Category: \(shoppingListItem.subCategory.rawValue)")
                    
                case .customer:
                    Text("Customer")
                    Text("Category: \(shoppingListItem.category.rawValue)")
                    Text("Sub-Category: \(shoppingListItem.subCategory.rawValue)")
                    if let customerName = shoppingListItem.customerName {
                        Text("\(customerName)")
                    }
                case .job:
                    Text("Job")
                    Text("Category: \(shoppingListItem.category.rawValue)")
                    Text("Sub-Category: \(shoppingListItem.subCategory.rawValue)")
                    if let job = shoppingListItem.jobId {
                        Text("\(job)")
                    }
                }
            }
        }
    }
}
