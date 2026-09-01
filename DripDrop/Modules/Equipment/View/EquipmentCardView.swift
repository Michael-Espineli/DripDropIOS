//
//  EquipmentCardView.swift
//  ThePoolApp
//
//  Created by Michael Espineli on 4/21/24.
//

import SwiftUI

struct EquipmentCardView: View {
    let equipment: Equipment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusTint)
                .frame(width: 44, height: 44)
                .background(statusTint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(equipmentTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(equipment.customerName.isEmpty ? "No customer assigned" : equipment.customerName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }

                Text(makeModelText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        equipmentPill(equipment.status.displayName, tint: statusTint, systemImage: "checkmark.seal")
                        equipmentPill(equipment.typeDisplayName, tint: .poolBlue, systemImage: "tag")
                        if equipment.needsService {
                            equipmentPill("Routine service", tint: .orange, systemImage: "calendar.badge.clock")
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            equipmentPill(equipment.status.displayName, tint: statusTint, systemImage: "checkmark.seal")
                            equipmentPill(equipment.typeDisplayName, tint: .poolBlue, systemImage: "tag")
                        }

                        if equipment.needsService {
                            equipmentPill("Routine service", tint: .orange, systemImage: "calendar.badge.clock")
                        }
                    }
                }

                if equipment.needsService {
                    serviceSummary
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(statusTint)
                .frame(width: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var serviceSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Label("Last \(shortDate(date: equipment.lastServiceDate))", systemImage: "clock.arrow.circlepath")
                    .lineLimit(1)

                if let nextDate = equipment.maintenanceDueDateForFollowUp {
                    Label("Next \(shortDate(date: nextDate))", systemImage: "calendar")
                        .lineLimit(1)
                }
            }

            HStack(spacing: 8) {
                if let frequency = equipment.serviceFrequency,
                   let every = equipment.serviceFrequencyEvery {
                    Text("Every \(frequency) \(every.rawValue)\(frequency == 1 ? "" : "s")")
                        .lineLimit(1)
                }

                if let filterPressureText {
                    Text(filterPressureText)
                        .lineLimit(1)
                }

                if equipment.currentlyNeedsMaintenanceFollowUp {
                    Text("Service due")
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
    }

    private var equipmentTitle: String {
        let name = equipment.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? equipment.typeDisplayName : name
    }

    private var makeModelText: String {
        let makeModel = [equipment.make, equipment.model]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return makeModel.isEmpty ? "No make or model on file" : makeModel
    }

    private var filterPressureText: String? {
        guard equipment.isFilterEquipment,
              let cleanPressure = equipment.cleanFilterPressure,
              let currentPressure = equipment.currentPressure else {
            return nil
        }

        let dirtyPercent = max(0, Double(currentPressure - cleanPressure) / 15 * 100)
        return "Dirty \(String(format: "%.0f", dirtyPercent))%"
    }

    private var statusTint: Color {
        switch equipment.status {
        case .operational:
            return .poolGreen
        case .needsRepair:
            return .red
        case .needsMaintenance:
            return .orange
        case .nonoperational, .replaced:
            return .secondary
        }
    }

    private var iconName: String {
        switch equipment.type {
        case .pump:
            return "drop.circle.fill"
        case .filter:
            return "line.3.horizontal.decrease.circle.fill"
        case .heater:
            return "flame.fill"
        case .saltCell:
            return "sparkles"
        case .light:
            return "lightbulb.fill"
        case .cleaner:
            return "wand.and.stars"
        case .controlSystem:
            return "switch.2"
        case .autoChlorinator:
            return "testtube.2"
        case .other:
            return "wrench.and.screwdriver"
        }
    }

    private func equipmentPill(_ text: String, tint: Color, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

#Preview {
    EquipmentCardView(
        equipment: Equipment(
            id: "",
            name: "Main Filter",
            type: .filter,
            typeId: "",
            make: "Pentair",
            makeId: "",
            model: "Clean & Clear",
            modelId: "",
            dateInstalled: Date(),
            status: .operational,
            needsService: true,
            lastServiceDate: Date(),
            serviceFrequency: 6,
            serviceFrequencyEvery: .monthly,
            notes: "",
            customerName: "Sample Customer",
            customerId: "",
            serviceLocationId: "",
            bodyOfWaterId: "",
            isActive: true
        )
    )
}
