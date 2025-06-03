//
//  BuisnessCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/3/24.
//

import SwiftUI

struct BusinessCardView: View {
    let business:AssociatedBusiness
    var body: some View {
        HStack{
            Text("\(business.companyName)")
        }
        .frame(maxWidth: .infinity)
        .modifier(ListButtonModifier())
    }
}

#Preview {
    BusinessCardView(business: AssociatedBusiness(companyId: "", companyName: ""))
}
