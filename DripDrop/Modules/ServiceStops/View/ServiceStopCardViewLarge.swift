//
//  ServiceStopCardViewLarge.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 12/30/23.
//

import SwiftUI

struct ServiceStopCardViewLarge: View {
    
    @State var serviceStop: ServiceStop
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            // MARK: Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 54, height: 54)
                
                Image(systemName: serviceStop.typeImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            // MARK: Main Content
            VStack(alignment: .leading, spacing: 6) {
                
                Text(serviceStop.customerName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(fullDateAndDay(date: serviceStop.serviceDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Tech: \(serviceStop.tech)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // MARK: Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 12)
    }
}
