//
//  UnbilledJobs.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct UnbilledJobs: View{
    @StateObject private var viewModel = PurchasesViewModel()

    @Binding var showSignInView:Bool
    @State var user:DBUser
    @State private var selected = Set<PurchasedItem.ID>()
    @State private var isPresented = false

    var body: some View{
        ZStack{
            VStack{
                UnbilledJobsList(showSignInView: $showSignInView,user: user)
            }
        }
        .toolbar{
            NavigationLink{

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
