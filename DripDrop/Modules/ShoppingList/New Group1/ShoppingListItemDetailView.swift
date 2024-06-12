//
//  ShoppingListItemDetailView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/8/24.
//

import SwiftUI

struct ShoppingListItemDetailView: View {
    @EnvironmentObject var masterDataManager : MasterDataManager
    @StateObject var jobVM : JobViewModel
    @StateObject var shoppingVM : ShoppingListViewModel
    @StateObject var customerVM : CustomerViewModel

    init(dataService:any ProductionDataServiceProtocol){
        _jobVM = StateObject(wrappedValue: JobViewModel(dataService: dataService))
        _shoppingVM = StateObject(wrappedValue: ShoppingListViewModel(dataService: dataService))
        _customerVM = StateObject(wrappedValue: CustomerViewModel(dataService: dataService))
    }
    
    @State var shoppingListItem : ShoppingListItem? = nil
    @State var alertMessage:String = ""
    @State var showAlert:Bool = false
    @State var showDeleteConfirmation:Bool = false
    var body: some View {
        ScrollView{
            if let shoppingListItem = shoppingListItem {
                HStack{
                    Spacer()
                    Button(action: {
                        showDeleteConfirmation = true
                    }, label: {
                        Text("Delete")
                            .padding(5)
                            .foregroundColor(Color.white)
                            .background(Color.red)
                            .cornerRadius(5)
                            .padding(5)
                    })
                }
                Text("\(shoppingListItem.name)")
                    .bold(true)
                if let date = shoppingListItem.datePurchased {
                    Text("\(fullDate(date:date ))")
                }
                Text("\(shoppingListItem.purchaserName)")

                HStack{
                    Spacer()
                    switch shoppingListItem.status {
                    case .installed:
                        Text("\(shoppingListItem.status)")
                            .font(.footnote)
                            .padding(5)
                            .background(Color.green)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                        
                            .padding(5)
                    case .purchased:
                        Text("\(shoppingListItem.status)")
                            .font(.footnote)
                            .padding(5)
                            .background(Color.yellow)
                            .foregroundColor(Color.black)
                            .cornerRadius(5)
                        
                            .padding(5)
                    case .needToPurchase:
                        Text("\(shoppingListItem.status)")
                            .font(.footnote)
                            .padding(5)
                            .background(Color.red)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                        
                            .padding(5)
                    default:
                        Text("\(shoppingListItem.status)")
                            .font(.footnote)
                            .padding(5)
                            .background(Color.gray)
                            .foregroundColor(Color.white)
                            .cornerRadius(5)
                        
                            .padding(5)
                    }
                }
                Text("\(shoppingListItem.description)")
             
                VStack{
                    switch shoppingListItem.category {
                    case .customer:
                        Text("\(shoppingListItem.category)")
                        Text("\(shoppingListItem.subCategory)")
                        if let customerName = shoppingListItem.customerName {
                            Text("\(customerName)")
                        }
                    case .personal:
                        Text("\(shoppingListItem.category)")
                        Text("\(shoppingListItem.subCategory)")

                    case .job:
                        Text("\(shoppingListItem.category)")
                        Text("\(shoppingListItem.subCategory)")
                        if let job = shoppingListItem.jobId {
                            Text("\(job)")
                        }
                    default:
                        Text("\(shoppingListItem.category)")
                        Text("\(shoppingListItem.subCategory)")

                    }
                }
                //End Of unwrapping
            }
        }
        
        .alert(isPresented:$showDeleteConfirmation) {
            Alert(
                title: Text("Alert"),
                message: Text("\(alertMessage)"),
                primaryButton: .destructive(Text("Delete")) {
                    Task{
                        print("Deleting...")
                        if let company = masterDataManager.selectedCompany, let item = masterDataManager.selectedShoppingListItem {
                            do {
                                try await shoppingVM.deleteShoppingListItem(companyId: company.id, shoppingListItemId: item.id)
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
        .task {
            shoppingListItem = masterDataManager.selectedShoppingListItem
        }
    }
}

struct ShoppingListItemDetailView_Previews: PreviewProvider {
    static let dataService = ProductionDataService()
    static var previews: some View {
        ShoppingListItemDetailView(dataService: dataService)
    }
}
