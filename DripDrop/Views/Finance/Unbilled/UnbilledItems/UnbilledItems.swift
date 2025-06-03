//
//  UnbilledItems.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/14/23.
//

import SwiftUI

struct UnbilledItems: View{
    @Binding var showSignInView:Bool
    @State var user:DBUser
    var body: some View{
        ZStack{
            VStack{
                UnbilledItemsList(showSignInView: $showSignInView,user: user)
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
