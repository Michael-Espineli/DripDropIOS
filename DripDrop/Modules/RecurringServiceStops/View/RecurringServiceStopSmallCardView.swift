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
        HStack(alignment: .top, spacing: 14) {
//            icon

            VStack(alignment: .leading, spacing: 9) {
                topRow
                scheduleRow
                repeatRow

                if !recurringServiceStop.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    descriptionRow
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.poolGray.opacity(0.15))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }

    var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.12))
                .frame(width: 44, height: 44)

            Image(systemName: "repeat")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.blue)
        }
    }

    var topRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(recurringServiceStop.tech.isEmpty ? "No Technician" : recurringServiceStop.tech)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text("#\(recurringServiceStop.internalId)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            Spacer(minLength: 0)
        }
    }

    var scheduleRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(shortDate(date: recurringServiceStop.startDate))
                .font(.subheadline)
                .foregroundStyle(.primary)

            Text("to")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(endDateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    var repeatRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(recurringServiceStop.frequency.rawValue)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("•")
                .font(.footnote)
                .foregroundStyle(.tertiary)

            Text(recurringServiceStop.day.rawValue)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    var descriptionRow: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "text.alignleft")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text(recurringServiceStop.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    var endDateText: String {
        if recurringServiceStop.noEndDate {
            return "No end date"
        }

        if let endDate = recurringServiceStop.endDate {
            return shortDate(date: endDate)
        }

        return "No end date"
    }
}
