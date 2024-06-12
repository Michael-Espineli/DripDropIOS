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
                Text("Name: \(genericItem.commonName)")
                Text("Category: \(genericItem.category)")
            }
            HStack{
                Text("Rate: \(genericItem.rate, format: .currency(code: "USD").precision(.fractionLength(0)))")
            }
        }
    }
}
