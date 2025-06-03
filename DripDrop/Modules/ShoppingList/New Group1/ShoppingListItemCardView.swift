//
//  ShoppingListItemCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/19/24.
//

import SwiftUI

@MainActor
final class ShoppingListItemCardViewModel:ObservableObject{
    let dataService:any ProductionDataServiceProtocol
    init(dataService:any ProductionDataServiceProtocol){
        self.dataService = dataService
    }
    @Published private (set) var dataBaseItem: DataBaseItem? = nil
    @Published private (set) var job: Job? = nil
    func onLoad(companyId:String,shoppingListItem:ShoppingListItem) async throws {
        switch shoppingListItem.category {
        case .personal:
            print("personal")
        case .customer:
            print("personal")
        case .job:
            if let jobId = shoppingListItem.jobId {
                self.job = try await dataService.getWorkOrderById(companyId: companyId, workOrderId: jobId)
                print("personal")
            }
        }
        switch shoppingListItem.subCategory {
        case .dataBase:
            print("personal")
        case .chemical:
            print("personal")
        case .part:
            print("personal")
        case .custom:
            print("personal")
        }
    }
    func updateShoppingListItemStatus(companyId:String,shoppingListItemId:String,status:ShoppingListStatus) async throws {
        try await dataService.updateShoppingListItemStatus(companyId: companyId, shoppingListItemId: shoppingListItemId, status: status)
    }
}
struct ShoppingListItemCardView: View {    
    @EnvironmentObject var masterDataManager : MasterDataManager
    @EnvironmentObject var dataService : ProductionDataService
    @StateObject var VM : ShoppingListItemCardViewModel
    init(dataService:any ProductionDataServiceProtocol,shoppingListItem:ShoppingListItem){
        _VM = StateObject(wrappedValue: ShoppingListItemCardViewModel(dataService: dataService))
        _shoppingListItem = State(wrappedValue: shoppingListItem)
    }
    @State var showStatusPicker : Bool = false
    @State var status : ShoppingListStatus = .needToPurchase
    @State var shoppingListItem: ShoppingListItem
    var body: some View {
        VStack(alignment: .leading){

                if UIDevice.isIPhone {
                    VStack{
                        HStack{
                            colorIcon
                            Spacer()
                            statusView
                        }
                        HStack{
                            details
                            Spacer()
                            Text(shoppingListItem.quantiy ?? "")
                        }
//                        cat
                    }
                } else {
                    HStack{
                        colorIcon
                        Spacer()
                        statusView
                    }
                    VStack(alignment: .leading){
                            details
                            cat
                        }
                    
                }
            }
        .modifier(ListButtonModifier())
        .padding(.horizontal,8)
        .task {
            Task{
                if let currentCompany = masterDataManager.currentCompany {
                    do {
                        status = shoppingListItem.status
                        try await VM.onLoad(companyId: currentCompany.id, shoppingListItem: shoppingListItem)
                    } catch {
                        print("Error - [ShoppingListItemCardView]")
                        print(error)
                    }
                }
            }
        }
    }
}
extension ShoppingListItemCardView{
    // Data Base , Chemical , Part , Custom
  
    var details: some View {
        VStack{
            switch shoppingListItem.category {
            case .personal:
                HStack{
                    Text("\(shoppingListItem.name)")
                    Spacer()
                }
            case .customer:
                HStack{
                    Text("\(shoppingListItem.name)")
                    Spacer()
                }
            case .job:
                VStack{
                    if let dataBaseItem = VM.dataBaseItem {
                        HStack{
                            Text("\(dataBaseItem.name)")
                            Spacer()
                        }
                        Text("\(dataBaseItem.description)")
                            .font(.footnote)
                    } else {
                        HStack{
                            Text("\(shoppingListItem.name)")
                            Spacer()
                        }
                    }
                }
            }         }
    }
    var statusView: some View {
        ZStack{
            Button(action: {
                print("Show Status PIcker")
                showStatusPicker.toggle()
            }, label: {
                switch status {
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
                    Text("Not Purchased")
                        .lineLimit(1)
                        .padding(5)
                        .background(Color.poolRed)
                        .foregroundColor(Color.white)
                        .cornerRadius(5)
                        .padding(5)
                }
            })
            .sheet(isPresented: $showStatusPicker, onDismiss: {
                Task{
                    if let currentCompany = masterDataManager.currentCompany {
                        do {
                            try await VM.updateShoppingListItemStatus(companyId: currentCompany.id,shoppingListItemId:shoppingListItem.id, status: status)
                        } catch {
                            print("Error")
                            print(error)
                        }
                    }
                }
                print("Update Shopping List Item Status")
            }, content: {
                ShoppingListItemStatusPicker(dataService: dataService, status: $status)
                    .presentationDetents([.fraction(0.6)])
            })
        }
    }
    
    var cat: some View {
        HStack{
            switch shoppingListItem.category {
            case .customer:
                    Text("\(shoppingListItem.category.rawValue)")
                    if let customerName = shoppingListItem.customerName {
                        Text("\(customerName)")
                    }
                
            case .personal:
                Text("\(shoppingListItem.category.rawValue)")
            case .job:
                if let job = VM.job {
                    Text(job.internalId)
                }
            }
            Spacer()
        }
    }
    var colorIcon: some View {
        VStack{
            switch shoppingListItem.category{
            case .personal:
                Image(systemName: "figure.stand.line.dotted.figure.stand")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            case .job:
                Image(systemName: "wrench.fill")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            case .customer:
                Image(systemName: "testtube.2")
                    .foregroundColor(getColor(subCategory: shoppingListItem.subCategory))
            }
        }
    }
    func getColor(subCategory:ShoppingListSubCategory) -> Color{
        switch subCategory{
        case .dataBase:
            return Color.blue
        case .chemical:
            return Color.green
        case .part:
            return Color.yellow
        case .custom:
            return Color.purple
     
        }
    }
}
