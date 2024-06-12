//
//  ReceiptView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct ReceiptView: View {
    @Binding var showSignInView: Bool
    @State var user:DBUser
    @State var company:Company

    var body: some View {
        ZStack{
            #if os(iOS)
            ReceiptListView()
            #endif
        }
    }
}

