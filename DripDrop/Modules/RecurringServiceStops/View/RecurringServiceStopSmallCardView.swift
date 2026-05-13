//
//  RecurringServiceStopSmallCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 5/12/24.
//

import SwiftUI

struct RecurringServiceStopSmallCardView: View {
    
    let recurringServiceStop: RecurringServiceStop
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "repeat")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                
                // Top row
                HStack(spacing: 8) {
                    Text(recurringServiceStop.tech)
                        .font(.headline)
                    
                    Text("#\(recurringServiceStop.internalId)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                }
                
                // Date row
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    
                    Text(shortDate(date: recurringServiceStop.startDate))
                        .font(.subheadline)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    if recurringServiceStop.noEndDate {
                        Text("No end date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(shortDate(date: recurringServiceStop.endDate))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Repeat row
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                    
                    Text(recurringServiceStop.day.rawValue)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 12)
    }
}
