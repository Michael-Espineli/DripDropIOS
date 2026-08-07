//
//  ReportCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/17/24.
//

import SwiftUI

struct ReportCardView: View {
    let report: ReportType
    var selected: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: report.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(selected ? Color.white : report.tint)
                .frame(width: 40, height: 40)
                .background(
                    selected ? Color.white.opacity(0.16) : report.tint.opacity(0.13),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(report.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    Text(report.generationStatusTitle)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(selected ? Color(.sRGB, red: 15/255, green: 23/255, blue: 42/255, opacity: 1) : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(selected ? Color.white : Color.primary.opacity(0.06), in: Capsule())
                }

                Text(report.source)
                    .font(.caption)
                    .foregroundStyle(selected ? Color.white.opacity(0.78) : Color.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: selected ? "checkmark.circle.fill" : "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.white.opacity(0.9) : Color.secondary.opacity(0.55))
                .padding(.top, 4)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(
            selected ? AnyShapeStyle(Color(.sRGB, red: 15/255, green: 23/255, blue: 42/255, opacity: 1)) : AnyShapeStyle(.background),
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(selected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}
