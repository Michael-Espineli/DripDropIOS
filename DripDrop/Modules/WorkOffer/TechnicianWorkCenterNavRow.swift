//
//  TechnicianWorkCenterNavRow.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//
import SwiftUI

struct TechnicianWorkCenterNavRow: View {
    var directOfferCount: Int
    var boardOfferCount: Int
    var acceptedCount: Int

    private var totalAttentionCount: Int {
        directOfferCount + boardOfferCount
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "briefcase")
                .font(.body.weight(.semibold))
                .frame(width: 34, height: 34)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("My Work Offers")
                    .font(.subheadline.weight(.semibold))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if totalAttentionCount > 0 {
                Text("\(totalAttentionCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.red, in: Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if totalAttentionCount > 0 {
            return "\(directOfferCount) direct • \(boardOfferCount) board"
        }

        if acceptedCount > 0 {
            return "\(acceptedCount) accepted work item(s)"
        }

        return "View offers, board posts, and accepted work"
    }
}
