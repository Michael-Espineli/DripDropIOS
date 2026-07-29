//
//  VehicleCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 1/21/24.
//

import SwiftUI

struct VehicleCardView: View {
    @Environment(\.locale) var locale

    let vehical: Vehical

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: vehicleIconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.poolBlue)
                .frame(width: 48, height: 48)
                .background(Color.poolBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(vehical.nickName.isEmpty ? "Unnamed Vehicle" : vehical.nickName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(vehicleDescription.isEmpty ? vehical.vehicalType.rawValue : vehicleDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text(vehical.status.rawValue)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(statusTint)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(statusTint.opacity(0.13), in: Capsule())
                }

                HStack(spacing: 8) {
                    vehicleMetric("Plate", vehical.plate.isEmpty ? "None" : vehical.plate, "rectangle.on.rectangle")
                    vehicleMetric("Miles", mileageText, "gauge.with.dots.needle.bottom.50percent")
                    vehicleMetric("Purchased", shortDate(date: vehical.datePurchased), "calendar")
                }
            }
        }
        .modifier(ListButtonModifier())

    }
}

private extension VehicleCardView {
    var vehicleIconName: String {
        switch vehical.vehicalType {
        case .car:
            return "car.fill"
        case .truck:
            return "box.truck.fill"
        case .van:
            return "bus.fill"
        }
    }

    var vehicleDescription: String {
        [
            vehical.color,
            vehical.year,
            vehical.make,
            vehical.model
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: " ")
    }

    var mileageText: String {
        Measurement(value: vehical.miles, unit: UnitLength.miles)
            .formatted(.measurement(width: .abbreviated, usage: .road).locale(locale))
    }

    var statusTint: Color {
        switch vehical.status {
        case .active:
            return .green
        case .retired:
            return .secondary
        }
    }

    func vehicleMetric(_ title: String, _ value: String, _ systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct VehicleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleCardView(vehical: MockDataService.mockVehical)
    }
}
