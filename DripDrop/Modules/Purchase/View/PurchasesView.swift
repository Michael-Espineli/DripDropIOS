//
//  PurchasesView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/15/23.
//

import SwiftUI

struct PurchasesView: View{
    init(dataService:any ProductionDataServiceProtocol){
        _purchaseVM = StateObject(wrappedValue: PurchasesViewModel(dataService: dataService))

    }
    @EnvironmentObject var dataService: ProductionDataService
    @StateObject var purchaseVM : PurchasesViewModel
    @State private var selected = Set<PurchasedItem.ID>()
    @State private var isPresented = false

    var body: some View{
        ZStack{
            Color.listColor.ignoresSafeArea()
            PurchaseListView(dataService: dataService)
        }
//        .toolbar{
//            NavigationLink{
//                AddNewReceipt(dataService: dataService)
//            } label: {
//                Image(systemName: "plus")
//                    .font(.headline)
//            }
//        }
        .navigationTitle("Purchased Items")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}




