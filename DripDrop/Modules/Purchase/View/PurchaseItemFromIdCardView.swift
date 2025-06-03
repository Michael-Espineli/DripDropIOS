//
//  PurchaseItemFromIdCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/16/24.
//

import SwiftUI

struct PurchaseItemFromIdCardView: View {
    init(dataService:any ProductionDataServiceProtocol,id:String){
        _purchaseVM = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))
        _id = State(wrappedValue: id)
    }
    @StateObject var purchaseVM : PurchasesViewModel
    @EnvironmentObject var masterDataManager : MasterDataManager

    @State var id:String
    var body: some View {
        VStack{
            if let item = purchaseVM.purchasedItem {
                HStack{
                    Text("\(item.name)")
                    Spacer()
                    Text("\(String(format: "%0.f",item.quantity))")
                    Text("X")
                    Text("$ \(String(format: "%2.f",item.price))")
                    Text("$ \(String(format: "%2.f",item.price * item.quantity))")
                        .padding(.leading,8)
                }
            }
        }
            .task{
                if let selectedCompany = masterDataManager.currentCompany {
                    do {
                        try await purchaseVM.getPurchaseById(companyId: selectedCompany.id, purchaseId: id)
                    } catch {
                        print("")
                        print("Purchase Item From Id Card View Failure")
                        print(error)
                        print("")

                    }
                }
            }
    }
}

#Preview {
    PurchaseItemFromIdCardView(dataService: MockDataService(), id:"1")
}
