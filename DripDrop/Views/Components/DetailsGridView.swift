//
//  DetailsGridView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/3/24.
//

import SwiftUI

struct DetailsGridView: View {
    let jobDescriptors: [JobDescriptors]
    
    let columns = [
        GridItem(.fixed(100)),
        GridItem(.flexible()),
    ]
    var body: some View {
        ZStack{
            LazyVGrid(columns: columns, spacing: 4) {
                
                ForEach(jobDescriptors) { descriptor in
                    DetailsPillView(iconName: descriptor.iconName, emoji: descriptor.emoji, text: descriptor.text)
                    
                }
            }
        }
    }
}

struct DetailsGridView_Previews: PreviewProvider {
    static var previews: some View {
        DetailsGridView(jobDescriptors: [])
    }
}
