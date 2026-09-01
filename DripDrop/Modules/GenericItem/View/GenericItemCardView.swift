//
//  GenericItemCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/27/24.
//

import SwiftUI

struct GenericItemCardView: View {
    let genericItem : GenericItem
    var body: some View {
        VStack{
            HStack{
                Text("Product: \(genericItem.productDisplayName)")
                Text("Category: \(genericItem.category)")
            }
            HStack{
                Text("Sell Price: \(DataBaseItemMoneyFormatter.moneyFromCents(genericItem.productSellPriceCents))")
            }
        }
    }
}
