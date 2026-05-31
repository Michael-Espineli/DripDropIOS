//
//  ServiceStopCardViewSmall.swift
//  BuisnessSide
//
//  Created by Michael Espineli on 12/2/23.
//



import SwiftUI

struct ServiceStopCardViewSmall: View {
    let serviceStop: ServiceStop
    
    private var statusColor: Color {
        serviceStop.operationStatus == .finished ? .poolGreen : .yellow
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 54, height: 54)
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 42, height: 42)
                
                Image(systemName: serviceStop.typeImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(serviceStop.customerName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.basicFontText)
                    .lineLimit(1)
                
                Text(fullDateAndDay(date: serviceStop.serviceDate))
                    .font(.caption)
                    .foregroundColor(.basicFontText.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(serviceStop.operationStatus == .finished ? "Finished" : "Pending")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.18))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
                
                Text(serviceStop.tech)
                    .font(.caption)
                    .foregroundColor(.basicFontText.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}
