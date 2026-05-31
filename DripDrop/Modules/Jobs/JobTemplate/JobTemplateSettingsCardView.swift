//
//  JobTemplateSettingsCardView.swift
//  DripDrop
//
//  Created by Michael Espineli on 5/23/26.
//


import SwiftUI

struct JobTemplateSettingsCardView: View {
    let template: JobTemplate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: template.jobTypeImage ?? "doc.text")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(template.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()

                    if template.locked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !template.description.isEmpty {
                    Text(template.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if !template.jobType.isEmpty {
                        Text(template.jobType)
                    }

                    if template.defaultRateCents > 0 {
                        Text("•")
                        Text(JobTemplateSettingsMoneyFormatter.money(template.defaultRateCents))
                    }

                    if !template.isActive {
                        Text("•")
                        Text("Inactive")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Image(systemName: UIDevice.isIPhone ? "chevron.right" : "circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private enum JobTemplateSettingsMoneyFormatter {
    static func money(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}
