//
//  CompanyCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/6/24.
//

import SwiftUI

struct CompanyCardView: View {
    let company:Company
    var body: some View {
        HStack{
            Spacer()
            Text(company.name)
            Spacer()
        }
        .modifier(ListButtonModifier())
    }
}

//#Preview {
//    CompanyCardView()
//}
