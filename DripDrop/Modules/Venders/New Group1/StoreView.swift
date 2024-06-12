//
//  StoreView.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//

import SwiftUI

struct StoreView: View {
    var body: some View {
        ZStack{
#if os(iOS)
            StoreListView()
#endif
        }
    }
}
