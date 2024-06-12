//
//  PurchasesView.swift
//  Pool-Secretary-V2
//
//  Created by Michael Espineli on 5/15/23.
//

import SwiftUI

struct PurchasesView: View{
    @StateObject private var viewModel = PurchasesViewModel()

    @State private var selected = Set<PurchasedItem.ID>()
    @State private var isPresented = false

    var body: some View{
        ZStack{
                PurchaseListView()
        }
        .toolbar{
            NavigationLink{
                AddNewReceipt()
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
            }
        }
        .navigationTitle("Purchased Items")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}




