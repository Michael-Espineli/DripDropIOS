//
//  BuisnessCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BuisnessCardView: View {
    let buisness:Company
    var body: some View {
        HStack{
            Text("\(buisness.name ?? "")")
        }
    }
}

#Preview {
    BuisnessCardView(buisness: Company(id: ""))
}
