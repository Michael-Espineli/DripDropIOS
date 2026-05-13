//
//  RepairRequestCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/13/24.
//

import SwiftUI

struct RepairRequestCardView: View {
    
    @EnvironmentObject var masterDataManager: MasterDataManager
    let repairRequest: RepairRequest

    var body: some View {
        
        HStack(spacing: 0) {
            
            // Status color bar
            Rectangle()
                .fill(getColor(status: repairRequest.status))
                .frame(width: 5)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            
            HStack(spacing: 14) {
                
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getColor(status: repairRequest.status).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(getColor(status: repairRequest.status))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    // Top row
                    HStack {
                        Text(repairRequest.customerName)
                            .font(.headline)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        statusChip
                    }
                    
                    // Meta row
                    HStack(spacing: 10) {
                        Text("Tech: \(repairRequest.requesterName)")
                        Text("•")
                        Text(fullDate(date: repairRequest.date))
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    // Description
                    Text(repairRequest.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 12)
    }
    
    func getColor(status:RepairRequestStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .resolved:
            color = Color.poolGreen
        case .unresolved, .cancelled:
            color = Color.poolRed
        case .inprogress:
            color = Color.yellow
        }
        return color
    }
    func getForgroundColor(status:RepairRequestStatus)->Color {
        var color:Color = Color.gray
        switch status {
        case .resolved, .cancelled:
            color = Color.white
        case .unresolved:
            color = Color.white
        case .inprogress:
            color = Color.black
        }
        return color
    }
    private var statusChip: some View {
        Text(repairRequest.status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(getColor(status: repairRequest.status).opacity(0.15))
            .foregroundStyle(getColor(status: repairRequest.status))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

}
