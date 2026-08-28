//
//  PerformanceHistoryCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 7/3/24.
//

import SwiftUI

struct PerformanceHistoryCardView: View {
    let performanceHistory:PerformaceHistory
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                performanceTypeBadge
                visibilityBadge
                Spacer()
                Text(shortDate(date: performanceHistory.date))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if !performanceHistory.title.isEmpty {
                Text(performanceHistory.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Text(performanceHistory.description.isEmpty ? "No notes recorded." : performanceHistory.description)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Label("\(performanceHistory.references.totalCount) refs", systemImage: "list.bullet.rectangle")
                Label("\(performanceHistory.fileAndReportCount) items", systemImage: "paperclip")
                Spacer()
                Text(performanceHistory.createdByName.isEmpty ? "Management" : performanceHistory.createdByName)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var performanceTypeBadge: some View {
        Label(performanceHistory.performaceHistoryType.displayName, systemImage: performanceHistory.performaceHistoryType.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(typeColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(typeColor.opacity(0.12), in: Capsule())
    }

    private var visibilityBadge: some View {
        Label(performanceHistory.visibleToTechnician ? "Technician" : "Internal", systemImage: performanceHistory.visibleToTechnician ? "eye" : "eye.slash")
            .font(.caption.weight(.semibold))
            .foregroundStyle(performanceHistory.visibleToTechnician ? Color.poolBlue : Color.secondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: Capsule())
    }

    private var typeColor: Color {
        switch performanceHistory.performaceHistoryType {
        case .kudo:
            return Color.poolGreen
        case .complaint:
            return Color.poolRed
        case .coaching:
            return Color.poolBlue
        case .observation:
            return Color.orange
        }
    }
}
//
//#Preview {
//    PerformanceHistoryCardView(performanceHistory: <#PerformaceHistory#>)
//}
