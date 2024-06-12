//
//  ContractAlert.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/23/23.
//

import Foundation


import SwiftUI

struct ContractAlert: View {
    
    let count: Int
    
    var body: some View {
            Image(systemName: "doc.text")
                .symbolVariant(.fill)
                .padding(4)
        
        .overlay(alignment: .topTrailing) {
                badge
            
        }
    }
}

private extension ContractAlert {
    
    var badge: some View {
        Text("\(count)")
            .foregroundColor(.white)
            .padding(3)
            .font(.caption2.bold())
            .monospacedDigit()
            .background(
                Circle()
                    .fill(.red)
            )
            .offset(x: 3, y: -3)
    }
}

