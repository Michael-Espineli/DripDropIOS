//
//  GenericLoadingView.swift
//  DripDrop
//
//  Created by Michael Espineli on 11/14/25.
//

import SwiftUI

struct GenericLoadingView: View {
    var body: some View {
        VStack{
            Text("Loading...")
            ProgressView()
        }
        .padding(16)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    GenericLoadingView()
}
