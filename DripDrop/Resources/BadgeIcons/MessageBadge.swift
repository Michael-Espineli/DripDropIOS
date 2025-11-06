//
//  MessageBadge.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/20/25.
//

import Foundation
import SwiftUI

struct MessageBadge: View {
    
    let count: Int
    
    var body: some View {
            Image(systemName: "message")
                .symbolVariant(.fill)
                .padding(4)
        
        .overlay(alignment: .topTrailing) {
                badge
            
        }
    }
}

private extension MessageBadge {
    
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
