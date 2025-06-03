//
//  Dashboard.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 3/21/24.
//

import SwiftUI

struct Dashboard: View {
    @EnvironmentObject var navigationManager: NavigationStateManager

    
    let data = (1...100).map { "Item \($0)" }

    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(data, id: \.self) { item in
                    Text(item)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard()
    }
}
